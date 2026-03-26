`timescale 1ns / 1ps


module DECODE (
    input        [31:0] i_addr,
    input        [31:0] instr_data,
    input        [31:0] wdata,
    output logic [31:0] o_RD1,
    output logic [31:0] o_RD2,
    output logic [31:0] o_imm_data,
    output logic        o_alusrcsel,
    output logic [ 3:0] o_alucontrol,
    output logic [31:0] o_addr,
    output logic [4:0] o_waddr // load 
);
    assign o_addr = i_addr;
    assign o_waddr=instr_data[11:7];
      control_unit U_CONTROL_UNIT (
        .funct7(instr_data[31:25]),
        .funct3(instr_data[14:12]),
        .opcode(instr_data[6:0]),
        .rf_we(rf_we),
        .dwe(dwe),
        .jal(jal),
        .jump(jump),
        .alusrcsel(alusrcsel),
        .rfwdsrcsel(rfwdsrcsel),
        .alucontrol(o_alucontrol),
        .c2dm_funct3(c2dm_funct3),
        .branch(branch)
    );


    register_file U_REG_FILE (
        .clk(clk),
        .rst(rst),
        .rf_we(rf_we),
        .RA1(instr_data[19:15]),
        .RA2(instr_data[24:20]),
        .WA(instr_data[11:7]),
        .Wdata(wdata),
        .RD1(o_RD1),
        .RD2(o_RD2)
    );

    imm_extender U_IMM_EXT (
        .instr_data(instr_data),
        .imm_data  (o_imm_data)
    );
endmodule
