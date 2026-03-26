`timescale 1ns / 1ps


module EX_MEM(
input clk,

input  [31:0]       i_alu_result,
input logic [31:0]  i_RD2,

output logic [31:0] o_alu_result,
output logic [31:0]  o_RD2
    );

    always_ff @( posedge clk ) begin

   
        o_alu_result<=i_alu_result;
        o_RD2<=i_RD2;
    end
endmodule
