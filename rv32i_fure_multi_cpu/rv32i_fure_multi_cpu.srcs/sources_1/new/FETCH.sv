`timescale 1ns / 1ps


module FETCH (
    input         clk,
    input         rst,
    input  [31:0] i_imm_pc_summ,
    output logic [31:0] o_data,
    output logic [31:0] o_addr    
);

    logic [31:0] pc_mux_out;
    logic [31:0] program_counter;

    logic [31:0] pc_4_sum;
    assign o_addr= program_counter;
    assign pc_4_sum= 4+program_counter;

    register U_PC_REG (
        .clk(clk),
        .rst(rst),
        .data_in(pc_mux_out),
        .data_out(program_counter)
    );



    instruction_mem U_ISR_MEM (
        .instr_addr(program_counter),
        .instr_data(o_data)
    );
endmodule
