`timescale 1ns / 1ps

module rv32i_top (
    input clk,
    input rst,
    output led
);

    logic [31:0] instr_addr, instr_data, daddr, dwdata,drdata;
    logic dwe, branch;
    logic [2:0] c2dm_funct3;
     assign led= daddr[0];
    instruction_mem U_INST_MEM (.*);


    rv32i_cpu U_RV32I (.*);

    data_mem U_DATA_MEM (.*);

endmodule



