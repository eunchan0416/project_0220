`timescale 1ns / 1ps



module IF_ID(
input clk,
input [31:0] instr_addr,
input [31:0] instr_data,
output logic [31:0] pc,
output logic [31:0] data
    );

always_ff @( posedge clk ) begin 
    pc<= instr_addr;
    data<= instr_data;
end

endmodule
