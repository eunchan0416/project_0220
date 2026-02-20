`timescale 1ns / 1ps



module adder (
    input [3:0] a,
    input [3:0] b,
    output [7:0] sum,
    output c
);

    wire w_fa4_0_c;
    bit4_full_adder u0 (
        .cin (1'b0),
        .a0  (a[0]),
        .a1  (a[1]),
        .a2  (a[2]),
        .a3  (a[3]),
        .b0  (b[0]),
        .b1  (b[1]),
        .b2  (b[2]),
        .b3  (b[3]),
        .s0  (sum[0]),
        .s1  (sum[1]),
        .s2  (sum[2]),
        .s3  (sum[3]),
        .cout(c)
    );
/*
    bit4_full_adder u1 (
        .cin (w_fa4_0_c),
        .a0  (a[4]),
        .a1  (a[5]),
        .a2  (a[6]),
        .a3  (a[7]),
        .b0  (b[4]),
        .b1  (b[5]),
        .b2  (b[6]),
        .b3  (b[7]),
        .s0  (sum[4]),
        .s1  (sum[5]),
        .s2  (sum[6]),
        .s3  (sum[7]),
        .cout(c)
    );

*/


endmodule



module bit4_full_adder (
    input  cin,
    input  a0,
    input  a1,
    input  a2,
    input  a3,
    input  b0,
    input  b1,
    input  b2,
    input  b3,
    output s0,
    output s1,
    output s2,
    output s3,
    output cout
);
    wire c1, c2, c3;  //half adder0,1,2 carry

    full_adder fa0 (
        .a  (a0),
        .b  (b0),
        .cin(cin),
        .sum(s0),
        .c  (c1)
    );

    full_adder fa1 (
        .a  (a1),
        .b  (b1),
        .cin(c1),
        .sum(s1),
        .c  (c2)
    );

    full_adder fa2 (
        .a  (a2),
        .b  (b2),
        .cin(c2),
        .sum(s2),
        .c  (c3)
    );

    full_adder fa3 (
        .a  (a3),
        .b  (b3),
        .cin(c3),
        .sum(s3),
        .c  (cout)
    );
endmodule



module full_adder (
    input  a,
    input  b,
    input  cin,
    output sum,
    output c
);

    wire w_hs_sum, w_ha1_c, w_ha2_c;  // half_adder output sum
    assign c = w_ha1_c | w_ha2_c;


    half_adder u_ha1 (
        .a    (a),
        .b    (b),
        .sum  (w_hs_sum),
        .carry(w_ha1_c)
    );

    half_adder u_ha2 (
        .a(w_hs_sum),
        .b(cin),
        .sum(sum),
        .carry(w_ha2_c)
    );
endmodule




module half_adder (
    input  a,
    input  b,
    output sum,
    output carry
);

    assign sum   = a ^ b;
    assign carry = a & b;
endmodule
