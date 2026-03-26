`timescale 1ns / 1ps

module rv32i_mcu (
    input logic clk,
    input logic rst,
     output logic[15:0] led
);

    logic [31:0] instr_addr, instr_data;
    logic bus_ready,bus_wreq, bus_rreq;
    logic [2:0] c2dm_funct3;
    logic [31:0] bus_addr, bus_wdata, bus_rdata;

    logic psel0, psel1, psel2, psel3, psel4, psel5;
    logic pready0, pready1, pready2, pready3, pready4, pready5;
    logic [31:0] prdata0, prdata1, prdata2, prdata3, prdata4, prdata5;
    logic [31:0] paddr,pwdata;
    logic        penable,pwrite;

    // assign led = daddr[0];




    instruction_mem U_INST_MEM (.*);


    rv32i_cpu U_RV32I (.*);

    BRAM U_BRAM (
        .*,
        .pclk  (clk),
        .psel  (psel0),
        .prdata(prdata0),
        .pready(pready0)
    );

    APB_MASTER U_APB_MASTER (
        .*,
        .pclk(clk),
        .preset(rst),
        .addr(bus_addr),
        .wdata(bus_wdata),
        .wreq(bus_wreq),
        .rreq(bus_rreq),
        .ready(bus_ready),
        .rdata(bus_rdata)
    );

    APB_GPO U_APB_GPO (
        .*,
    .pclk(clk),
    .preset(rst),
    .psel(psel1),
    .pready(pready1),
    .prdata(prdata1),
    .gpo_out(led)
);
endmodule
