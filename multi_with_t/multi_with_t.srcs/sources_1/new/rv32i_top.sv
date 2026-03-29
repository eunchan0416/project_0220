`timescale 1ns / 1ps

module rv32i_mcu (
    input               clk,
    input               rst,
    inout  logic [15:0] gpio,
    output logic [ 7:0] gpo,
    input        [ 7:0] gpi,
    output logic [ 3:0] fnd_digit,
    output logic [ 7:0] fnd_data,
      input  logic        uart_rx,
    output logic        uart_tx
);

    logic [31:0] instr_addr, instr_data;
    logic bus_ready, bus_wreq, bus_rreq;
    logic [2:0] c2dm_funct3;
    logic [31:0] bus_addr, bus_wdata, bus_rdata;

    logic psel0, psel1, psel2, psel3, psel4, psel5;
    logic pready0, pready1, pready2, pready3, pready4, pready5;
    logic [31:0] prdata0, prdata1, prdata2, prdata3, prdata4, prdata5;
    logic [31:0] paddr, pwdata;
    logic penable, pwrite;

    instruction_mem U_INST_MEM (.*);

    rv32i_cpu U_RV32I (.*);

    APB_MASTER U_APB_MASTER (
        .*,
        .pclk  (clk),
        .preset(rst),
        .addr  (bus_addr),
        .wdata (bus_wdata),
        .wreq  (bus_wreq),
        .rreq  (bus_rreq),
        .ready (bus_ready),
        .rdata (bus_rdata)
    );

    BRAM U_BRAM (
        .*,
        .pclk  (clk),
        .psel  (psel0),
        .prdata(prdata0),
        .pready(pready0)
    );

    APB_GPO U_APB_GPO (
        .*,
        .pclk(clk),
        .preset(rst),
        .psel(psel1),
        .pready(pready1),
        .prdata(prdata1),
        .gpo_out(gpo)
    );

    APB_GPI U_APB_GPI (
        .*,
        .pclk(clk),
        .preset(rst),
        .psel(psel2),
        .pready(pready2),
        .prdata(prdata2),
        .gpi(gpi)
    );

    APB_GPIO U_APB_GPIO (
        .*,
        .pclk  (clk),
        .preset(rst),
        .psel  (psel3),
        .pready(pready3),
        .prdata(prdata3),
        .gpio  (gpio)
    );


    APB_FND U_FND(
     .*,
        .pclk  (clk),
        .preset(rst),
        .psel  (psel4),
        .pready(pready4),
        .prdata(prdata4)
    );

    APB_UART U_UART(
    .*,
        .pclk  (clk),
        .preset(rst),
        .psel  (psel5),
        .pready(pready5),
        .prdata(prdata5)
);
endmodule