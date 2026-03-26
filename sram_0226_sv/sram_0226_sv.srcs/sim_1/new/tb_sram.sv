`timescale 1ns / 1ps

interface sram_if ();
    bit         clk;
    logic [3:0] addr;
    logic [7:0] wdata;
    bit         we;
    logic [7:0] rdata;
endinterface  //sram_if


class transaction;

    rand bit [7:0] wdata;
    rand bit       we;
    rand bit [3:0] addr;
    logic    [7:0] rdata;

    //void function return x
    function display(string name);
        $display("%t : [%s] we = %1d, addr = %2h, wdata = %2h, rdata = %2h,",
                 $time, name, we, addr, wdata, rdata);
    endfunction



endclass  //transcation


class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event scb2gen_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event scb2gen_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.scb2gen_ev   = scb2gen_ev;
    endfunction  //new()

    task run(int run_count);
        repeat (run_count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.display("generator");
            @(scb2gen_ev);

        end

    endtask  //


endclass  //generator



class driver;

    virtual sram_if sram_if;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;


    function new(virtual sram_if sram_if, mailbox#(transaction) gen2drv_mbox);
        this.sram_if      = sram_if;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction



    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge sram_if.clk);
            //drive
            sram_if.wdata = tr.wdata;
            sram_if.we    = tr.we;
            sram_if.addr  = tr.addr;
            tr.display("driver");
        end
    endtask


endclass  //driver



class monitor;

    virtual sram_if sram_if;
    transaction tr;

    mailbox #(transaction) mon2scb_mbox;


    function new(virtual sram_if sram_if, mailbox#(transaction) mon2scb_mbox);
        this.sram_if      = sram_if;
        this.mon2scb_mbox = mon2scb_mbox;
    endfunction

    task run();

        forever begin
            @(posedge sram_if.clk);
            //race condition 방지
            #1;
            tr       = new();
            tr.addr  = sram_if.addr;
            tr.we    = sram_if.we;
            tr.wdata = sram_if.wdata;
            tr.rdata = sram_if.rdata;
            mon2scb_mbox.put(tr);
            tr.display("monitor");
        end

    endtask


endclass


class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event scb2gen_ev;

    logic [7:0] expected_ram[0:15];
    int pass_cnt, fail_cnt, write_cnt, non_data_cnt, run_cnt;

    covergroup cg_sram;
        cp_addr: coverpoint tr.addr {
            bins min = {0}; bins mid = {[1 : 14]}; bins max = {15};
        }
    endgroup



    function new(mailbox#(transaction) mon2scb_mbox, event scb2gen_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.scb2gen_ev = scb2gen_ev;
        cg_sram = new();
    endfunction

    task run();
        //pass_cnt=0;
        //fail_cnt=0;
        //write_cnt=0;
        //non_data_cnt=0;
        //run_cnt=0;
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scoreboard");

            cg_sram.sample();
            //run_cnt++;

            if (tr.we == 1) begin
                expected_ram[tr.addr] = tr.wdata;
                $display("write data");
                //write_cnt++
            end else begin

                if ((expected_ram[tr.addr] == tr.rdata)) begin
                    $display("pass");
                    // pass_cnt++;
                end else begin

                    if ((expected_ram[tr.addr] != 8'bx)) begin
                        $display("fail : expected data = %2h, rdata = %2h",
                                 expected_ram[tr.addr], tr.rdata);
                        //  fail_cnt++;
                    end else begin
                        $display("not data rdata: %2h", tr.rdata);
                        // non_data_cnt++;
                    end
                end
            end

            ->scb2gen_ev;
        end
    endtask


endclass

class environmnet;


    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event                  scb2gen_ev;

    function new(virtual sram_if sram_if);

        gen2drv_mbox = new();
        mon2scb_mbox = new();


        gen          = new(gen2drv_mbox, scb2gen_ev);
        drv          = new(sram_if, gen2drv_mbox);
        mon          = new(sram_if, mon2scb_mbox);
        scb          = new(mon2scb_mbox, scb2gen_ev);

    endfunction

    task run();
        fork
            gen.run(6);
            drv.run();
            mon.run();
            scb.run();
        join_any

        #10;
        $display("coverage addr = %d", scb.cg_sram.get_inst_coverage());
        $stop;

    endtask

endclass


module tb_sram ();

    //    logic clk;

    sram_if sram_if ();
    environmnet env;

    sram dut (
        .clk(sram_if.clk),
        .addr(sram_if.addr),
        .wdata(sram_if.wdata),
        .we(sram_if.we),
        .rdata(sram_if.rdata)
    );
    //always #5 clk = ~clk;
    always #5 sram_if.clk = ~sram_if.clk;

    initial begin

        env = new(sram_if);

        env.run();

    end

endmodule
