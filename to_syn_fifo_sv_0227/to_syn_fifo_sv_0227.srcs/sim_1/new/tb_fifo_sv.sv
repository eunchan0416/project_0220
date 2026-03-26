`timescale 1ns / 1ps


interface fifo_interface (
    input logic clk
);

    logic       rst;
    logic [7:0] wdata;
    logic       we;
    logic       re;
    logic [7:0] rdata;
    logic       full;
    logic       empty;

endinterface


class transaction;

    rand bit [7:0] wdata;
    rand bit       we;
    rand bit       re;
    bit            rst;

    logic    [7:0] rdata;
    logic          full;
    logic          empty;

    function void display(string name);
        $display(
            "%t : [%s] push= %d, wdata= %2h, full = %d, pop= %d, rdata= %2h, empty =%d ",
            $time, name, we, wdata, full, re, rdata, empty);
    endfunction

endclass

class generator;


    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run(int run_count);

        repeat (run_count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.display("generator");
            @(gen_next_ev);
        end
    endtask
endclass


class driver;
    virtual fifo_interface fifo_if;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;


    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual fifo_interface fifo_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.fifo_if = fifo_if;
    endfunction

    task reset();
        fifo_if.rst = 1;
        fifo_if.wdata = 0;
        fifo_if.we = 0;
        ;
        fifo_if.re = 0;

        @(negedge fifo_if.clk);
        @(negedge fifo_if.clk);
        fifo_if.rst = 0;
        @(negedge fifo_if.clk);

        //add SVA
    endtask



    task push();
        fifo_if.we = tr.we;
        fifo_if.wdata = tr.wdata;
        fifo_if.re = tr.re;
    endtask

    task pop();
        fifo_if.re = tr.re;
        fifo_if.we = tr.we;
        fifo_if.wdata = tr.wdata;
    endtask


    task run();

        forever begin
            gen2drv_mbox.get(tr);

            @(posedge fifo_if.clk);
            #1;
            if (tr.we) push();
            else fifo_if.we = 0;

            if (tr.re) pop();
            else fifo_if.re = 0;

            tr.display("driver");

        end
    endtask
endclass


class monitor;

    virtual fifo_interface fifo_if;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;


    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual fifo_interface fifo_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_if = fifo_if;
    endfunction

    task run();

        forever begin
            @(negedge fifo_if.clk);
            tr       = new();
            tr.wdata = fifo_if.wdata;
            tr.rdata = fifo_if.rdata;
            tr.we    = fifo_if.we;
            tr.re    = fifo_if.re;
            tr.full  = fifo_if.full;
            tr.empty = fifo_if.empty;
            // tr.rst   = fifo_if.rst;
            mon2scb_mbox.put(tr);
            tr.display("monitor");
        end


    endtask

endclass


class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;
    logic [7:0] fifo_queue[$:16];
    logic [7:0] expected_data;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run();

        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scoreboard");
            if (tr.we ) begin
                fifo_queue.push_front(tr.wdata);
            end

            if (tr.re &&(!tr.empty)) begin
                expected_data = fifo_queue.pop_back();
                if (expected_data == tr.rdata) begin
                    $display("pass");
                end
                else  $display("fail");
            end else if(tr.re && tr.empty) begin
                $display("not data");
            end


            ->gen_next_ev;

        end

    endtask

endclass


class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;


    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;


    function new(virtual fifo_interface fifo_if);

        gen2drv_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, fifo_if);
        mon = new(mon2scb_mbox, fifo_if);
        scb = new(mon2scb_mbox, gen_next_ev);


    endfunction


    task run();
        drv.reset();

        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any

        #10;
        $stop;
    endtask

endclass

module tb_fifo_sv ();

    logic clk;
    fifo_interface fifo_if (clk);
    environment env;
    fifo dut (
        .clk(clk),
        .rst(fifo_if.rst),
        .wdata(fifo_if.wdata),
        .we(fifo_if.we),
        .re(fifo_if.re),
        .rdata(fifo_if.rdata),
        .full(fifo_if.full),
        .empty(fifo_if.empty)
    );

    always #5 clk = ~clk;


    initial begin
        clk = 0;
        env = new(fifo_if);

        env.run();

    end


endmodule
