`timescale 1ns / 1ps


module tb_fsm ();

    reg clk, rst, din_bit;
    wire dout_bit;

    fsm dut (
        .clk(clk),
        .rst(rst),
        .din_bit(din_bit),
        .dout_bit(dout_bit)
    );



    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        din_bit = 0;
#20;
rst=0;
#20;

        #10;
        din_bit = 1;
        #10;
        din_bit = 0;
        #10;
        din_bit = 1;

        #10;
        din_bit = 1;
#10;
        din_bit = 1;
#10;
        din_bit = 0;
#10;
        din_bit = 0;
        #10;
        din_bit = 1;


        $stop;





    end
endmodule
