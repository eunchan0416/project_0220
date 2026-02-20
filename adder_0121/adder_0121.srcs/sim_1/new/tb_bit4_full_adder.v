`timescale 1ns / 1ps


module tb_adder ();
    reg [3:0] a, b;
    wire [3:0] sum;
    wire c;


    adder dut (
        .a  (a),
        .b  (b),
        .sum(sum),
        .c  (c)
    );

    initial begin

        #0;
        a = 0;
        b = 0;
        #10;

        a = 5;
        b = 3;

        #10;
        a = 5;
        b = 9;

        #10;
        a = 2;
        b = 7;

        #10;
        a = 9;
        b = 1;

        #10;
        a = 14;
        b = 2;

          #10;
        a = 14;
        b = 14;
        $stop;
        #100;
        $finish;

    end

endmodule


