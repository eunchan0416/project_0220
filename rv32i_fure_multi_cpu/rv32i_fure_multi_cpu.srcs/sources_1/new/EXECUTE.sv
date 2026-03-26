`timescale 1ns / 1ps



module EXECUTE(
    input logic [31:0] i_RD1,
    input logic [31:0] i_RD2,
    input logic [31:0] imm_data,
    input logic        alusrcsel,
    input logic [ 3:0] alucontrol,
    input logic [31:0] o_addr,
    output logic [31:0] addr_sum_imm_pc,
    output logic [31:0] alu_result,
    output logic [31:0] o_RD2
    );
    logic [31:0] alu_indata;

    assign addr_sum_imm_pc= imm_data+ o_addr;
    assign alu_indata= alusrcsel ?  imm_data : i_RD2;
    assign o_RD2= i_RD2;

       alu U_ALU (
        .RD1(i_RD1),
        .RD2(alu_indata),
        .alucontrol(alucontrol),
        .alu_result(alu_result),
        .btaken(btaken)
    );




endmodule
