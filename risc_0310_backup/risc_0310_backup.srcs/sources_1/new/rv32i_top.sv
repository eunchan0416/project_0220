`timescale 1ns / 1ps

module rv32i_top (
    input clk,
    input rst
);

    logic [31:0] instr_addr, instr_data, daddr, dwdata,drdata;
    logic dwe;

    instruction_mem U_INST_MEM (.*);


    rv32i_cpu U_RV32I (.*);

    data_mem U_DATA_MEM (.*);

endmodule



