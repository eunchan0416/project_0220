`timescale 1ns / 1ps
//ab
interface ram_interface (
    input logic clk
);
    logic       we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface


class transaction;

    logic            we;
    rand logic [7:0] addr;
    rand logic [7:0] wdata;
    logic      [7:0] rdata;

    constraint c_addr {addr inside {[8'h00 : 8'h10]};}
    constraint c_wdata {wdata inside {[8'h10 : 8'h20]};}

    function print(string name);
        $display("[name] we: %0d, addr:0x%0x, wdata:0x%0x, rdata:0x%0x", name,
                 we, addr, wdata, rdata);

    endfunction


endclass



class test;

    virtual ram_interface r_if;

    function new(virtual ram_interface r_if);
        this.r_if = r_if;
    endfunction  //new

    virtual task write(logic [7:0] waddr, logic [7:0] data);

        r_if.we = 1;
        r_if.addr = waddr;
        r_if.wdata = data;
        @(posedge r_if.clk);

    endtask

    task read(logic [7:0] raddr);
        r_if.we   = 0;
        r_if.addr = raddr;
        @(posedge r_if.clk);
    endtask


endclass


class test_rand extends test;
    transaction tr;
    function new(virtual ram_interface r_if);
        super.new(r_if);
    endfunction

    task write_rand(int loop);
        repeat (loop) begin
            tr = new();
            tr.randomize();
            r_if.we = 1;
            r_if.addr = tr.addr;
            r_if.wdata = tr.wdata;
            @(posedge r_if.clk);
        end
    endtask

endclass




class test_burst extends test;


    function new(virtual ram_interface r_if);
        super.new(r_if);
    endfunction

    task write_burst(logic [9:0] waddr, logic [7:0] data, int len);

        for (int i = 0; i < len; i++) begin

            super.write(waddr, data);
            waddr++;
        end
    endtask

    task write(logic [7:0] waddr, logic [7:0] data);

        r_if.we = 1;
        r_if.addr = waddr + 1;
        r_if.wdata = data;
        @(posedge r_if.clk);

    endtask


endclass


module tb ();

    logic clk;
    ram_interface r_if (clk);

    test bts;
    test_rand black;

    ram dut (
        .clk(r_if.clk),
        .we(r_if.we),
        .addr(r_if.addr),
        .wdata(r_if.wdata),
        .rdata(r_if.rdata)


    );

    initial clk = 0;
    always #5 clk = ~clk;


    initial begin
        repeat (5) @(posedge clk);

        bts   = new(r_if);
        black = new(r_if);

        bts.write(8'h00, 8'h01);
        bts.write(8'h01, 8'h02);
        bts.write(8'h02, 8'h03);


        black.write_rand(10);
        bts.read(8'h00);
        bts.read(8'h01);
        bts.read(8'h02);
        //ram_write(8'h00, 8'h01);
        //ram_write(8'h01, 8'h02);
        //ram_write(8'h02, 8'h03);

        //ram_read(8'h00);
        //ram_read(8'h01);
        //ram_read(8'h02);

        #20;
        $finish;

    end


endmodule
