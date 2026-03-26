`timescale 1ns / 1ps


module ID_EX (
    input clk,
    input  [31:0] i_RD1,
    input  [31:0] i_RD2,
    input  [31:0] i_imm_data,
    input         i_alusrcsel,
    input  [ 3:0] i_alucontrol,
    input  [31:0] i_addr,
    
    output logic [31:0] o_RD1,
    output logic [31:0] o_RD2,
    output logic [31:0] o_imm_data,
    output logic        o_alusrcsel,
    output logic [ 3:0] o_alucontrol,
    output logic [31:0] o_addr

);

always_ff @( posedge clk ) begin 
    o_RD1<=i_RD1;
    o_RD2<=i_RD2;
    o_imm_data<=i_imm_data;
    o_alusrcsel<=i_alucontrol;
    o_alucontrol<=i_alucontrol;
    o_addr<=i_addr;

end






endmodule
