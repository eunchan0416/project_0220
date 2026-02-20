`timescale 1ns / 1ps

module tb_fsm ();
    reg [2:0] sw;
    reg clk, reset;
    wire [1:0] led;


    fsm dut (
        .sw(sw),
        .clk(clk),
        .reset(reset),
        .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        sw = 0;
        clk = 0;
        reset = 1;
        #10;
        reset = 0;

        #20;
        sw = 1;
        #20;
        sw = 2;
        #20;
        sw = 3;
        #20;
        sw = 4;
        #20;
        sw = 5;
        #20;
        sw = 6;
        #20;
        sw = 7;
        #20;
        sw = 0;
        #20;
        $stop;


    end


endmodule
