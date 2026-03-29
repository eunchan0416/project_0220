`timescale 1ns / 1ps

module tb_rv32i ();

    logic clk, rst;
    wire  [15:0] gpio;
    wire  [ 7:0] gpo;
    logic [ 7:0] gpi;
    logic [ 3:0] fnd_digit;
    logic [ 7:0] fnd_data;
    logic        uart_rx;
    logic        uart_tx;

    rv32i_mcu dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        gpi = 16'h0000;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        gpi = 8'haa;
        repeat (200) @(negedge clk);
        gpi = 8'h33;
        $stop;

    end
endmodule
