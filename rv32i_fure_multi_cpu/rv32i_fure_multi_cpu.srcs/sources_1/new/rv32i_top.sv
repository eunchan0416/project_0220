`timescale 1ns / 1ps

module rv32i_top (
    input clk,
    input rst
    //output led
);

    logic [31:0] w_fetch_data,w_fetch_addr, w_addr, w_instr_data, w_daddr, w_dwdata,w_drdata;
    logic dwe, branch;
    logic [2:0] c2dm_funct3;
    logic [31:0] o_dec_rd1, o_dec_rd2,o_dec_imm;
    logic o_dec_alusrcsel;
    logic [3:0] o_dec_alucontrol;
    logic [31:0] o_dec_addr;


FETCH U_FETCH (
    .clk(clk),
    .rst(rst),
    .i_imm_pc_summ(),
    .o_data(w_fetch_data),
    .o_addr(w_fetch_addr)
);


    IF_ID U_IF_ID_REG(
.clk(clk),
.instr_addr(w_fetch_addr),
.instr_data(w_fetch_data),
.pc(w_addr),
.data(w_instr_data)
    );
   
    DECODE U_DECODE (
    .i_addr(w_addr),
    .instr_data(w_instr_data),
    .wdata(),
    .o_RD1(o_dec_rd1),
    .o_RD2(o_dec_rd2),
    .o_imm_data(o_dec_imm),
    .o_alusrcsel(o_dec_alusrcsel),
    .o_alucontrol(o_dec_alucontrol),
    .o_addr(o_dec_addr)
);

ID_EX U_ID_EX_REG(
    .clk(clk),
    .i_RD1(o_dec_rd1),
    .i_RD2(o_dec_rd2),
    .i_imm_data(o_dec_imm),
    .i_alusrcsel(o_dec_alusrcsel),
    .i_alucontrol(o_dec_alucontrol),
    .i_addr(o_dec_addr),
    .o_RD1(),
    .o_RD2(),
    .o_imm_data(),
    .o_alusrcsel(),
    .o_alucontrol(),
    .o_addr()

);




EXECUTE U_EXE(
    .i_RD1(),
    .i_RD2(),
    .imm_data(),
    .alusrcsel(),
    .alucontrol(),
    .o_addr(),
    .addr_sum_imm_pc(),
    .alu_result(),
    .o_RD2()
    );


EX_MEM U_EX_MEM_REG(
.clk(),
.i_alu_result(),
.i_RD2(),
.o_alu_result(),
.o_RD2()
    );

MEM U_MEM(
    .i_alu_result(),
    .i_RD2(),
    .o_rdata(),
    .o_alu_result()
);

MEM_WB U_MEM_WB_REG(
    .clk(),
    .i_rdata(),
    .i_alu_result(),   
    .o_data()
    );


endmodule



