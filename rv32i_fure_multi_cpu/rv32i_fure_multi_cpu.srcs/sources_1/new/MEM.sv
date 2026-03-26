`timescale 1ns / 1ps

module MEM (

    input  [31:0] i_alu_result,
    input  [31:0] i_RD2,
    output [31:0] o_rdata,
    output [31:0] o_alu_result
);

    assign o_alu_result=i_alu_result;

data_mem U_DATAMEM (
   .clk(),
   .rst(),
   .dwe(),
   .dwdata(i_RD2),
   .c2dm_funct3(),
   .daddr(i_alu_result),
   .drdata(o_rdata)

);



endmodule
