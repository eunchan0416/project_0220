`timescale 1ns / 1ps


module MEM_WB(
 input clk,
    input [31:0] i_rdata,
    input [31:0] i_alu_result,   
    output logic [31:0] o_data
    );
    logic [31:0] reg_o_data;

   // assign reg_o_data= (rfwdsrcsel==0) ? i_alu_result : i_rdata;

    always_ff @( posedge clk ) begin 
       o_data <= reg_o_data;
    end
endmodule
