`timescale 1ns / 1ps


module tb_bit4_full_adder ();

    reg cin, a0, a1, a2, a3, b0, b1, b2, b3;
    wire s0, s1, s2, s3, cout;


    bit4_full_adder dut (
        .cin (cin),
        .a0  (a0),
        .a1  (a1),
        .a2  (a2),
        .a3  (a3),
        .b0  (b0),
        .b1  (b1),
        .b2  (b2),
        .b3  (b3),
        .s0  (s0),
        .s1  (s1),
        .s2  (s2),
        .s3  (s3),
        .cout(cout)

    );

    initial begin

        #0;
        cin=0;

        a0=0;
        a1=0;
        a2=0;
        a3=0;
        b0=0;
        b1=0;
        b2=0;
        b3=0;

        #10;
         a0=1;
        a1=0;
        a2=0;
        a3=0;
        b0=1;
        b1=0;
        b2=0;
        b3=0;
#10;
$stop;

    end

endmodule

