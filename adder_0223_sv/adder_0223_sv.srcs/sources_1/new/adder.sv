`timescale 1ns / 1ps

module adder (
    input logic [31:0] a,
    input logic [31:0] b,
    input logic mode,
    output logic [31:0] sum,
    output logic carry
);

    assign {carry, sum} = mode ? a - b : a + b;

endmodule
