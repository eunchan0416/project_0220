`timescale 1ns / 1ps
`include "define.vh"


module rv32i_datapath (
    input logic        clk,
    input logic        rst,
    input logic        alusrcsel,
    input logic [ 3:0] alucontrol,
    input logic        jump,
    input logic        pc_en,
    input logic        rf_we,
    input logic        branch,
    input logic        jal,
    input logic [ 2:0] rfwdsrcsel,
    input logic [31:0] bus_rdata,
    input logic [31:0] instr_data,  // Stable from Instruction Memory

    output logic [31:0] instr_addr,
    output logic [31:0] bus_addr,
    output logic [31:0] bus_wdata
);

    logic btaken;
    logic [31:0]
        i_dec_RD1,
        o_dec_RD1,
        i_dec_RD2,
        o_dec_RD2,
        alu_result,
        o_exe_alu_result,
        i_dec_imm,
        o_dec_imm,
        alurs2_data,
        o_exe_RD2,
        o_mem_drdata,
        rf_wb_data,
        pc_imm_sum,
        pc_4_sum;

    assign bus_addr  = o_exe_alu_result;
    assign bus_wdata = o_exe_RD2;

    register_file U_REG_FILE (
        .clk  (clk),
        .rst  (rst),
        .rf_we(rf_we),
        .RA1  (instr_data[19:15]),
        .RA2  (instr_data[24:20]),
        .WA   (instr_data[11:7]),
        .Wdata(rf_wb_data),
        .RD1  (i_dec_RD1),
        .RD2  (i_dec_RD2)
    );

    register U_DEC_REG_RS1 (
        .clk     (clk),
        .rst     (rst),
        .data_in (i_dec_RD1),
        .data_out(o_dec_RD1)
    );

    register U_DEC_REG_RDATA (
        .clk     (clk),
        .rst     (rst),
        .data_in (bus_rdata),
        .data_out(o_mem_drdata)
    );

    register U_MEM_REG_RS2 (
        .clk     (clk),
        .rst     (rst),
        .data_in (i_dec_RD2),
        .data_out(o_dec_RD2)
    );


    imm_extender U_IMM_EXT (
        .instr_data(instr_data),
        .imm_data  (i_dec_imm)
    );

    register U_DEC_REG_IMM (
        .clk     (clk),
        .rst     (rst),
        .data_in (i_dec_imm),
        .data_out(o_dec_imm)
    );

    mux_2x1 U_MUX_ALUSRC (
        .in0    (o_dec_RD2),
        .in1    (o_dec_imm),
        .sel    (alusrcsel),
        .out_mux(alurs2_data)
    );

    program_counter U_PC (
        .clk            (clk),
        .rst            (rst),
        .pc_en          (pc_en),
        .imm            (o_dec_imm),
        .branch_sel     ((btaken & branch) || jump),
        .program_counter(instr_addr),
        .pc_imm_sum     (pc_imm_sum),
        .jal            (jal),
        .rs1_imm_sum    (alu_result),
        .pc_4_sum       (pc_4_sum)
    );

    alu U_ALU (
        .RD1       (o_dec_RD1),
        .RD2       (alurs2_data),
        .alucontrol(alucontrol),
        .alu_result(alu_result),
        .btaken    (btaken)
    );

    register U_EXE_ALU_RESULT (
        .clk     (clk),
        .rst     (rst),
        .data_in (alu_result),
        .data_out(o_exe_alu_result)
    );

    register U_EXE_REG_RS2 (
        .clk     (clk),
        .rst     (rst),
        .data_in (o_dec_RD2),
        .data_out(o_exe_RD2)
    );

    mux_5x1 U_RW_MUX (
        .in0    (alu_result),
        .in1    (o_mem_drdata),
        .in2    (o_dec_imm),
        .in3    (pc_imm_sum),
        .in4    (pc_4_sum),
        .sel    (rfwdsrcsel),
        .out_mux(rf_wb_data)
    );

endmodule
module register_file (
    input               clk,
    input               rst,
    input               rf_we,
    input        [ 4:0] RA1,
    input        [ 4:0] RA2,
    input        [ 4:0] WA,
    input        [31:0] Wdata,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);

    //register gen
    logic [31:0] register_file[1:31];

    //read CL
    assign RD1 = (RA1 == 0) ? 32'b0 : register_file[RA1];
    assign RD2 = (RA2 == 0) ? 32'b0 : register_file[RA2];

    //address[0] register_file[0]<=0  or assgin rd1= wa==0 ? 32'b0 : regiseter_file[RA1];

    //write AL
    always_ff @(posedge clk) begin
        begin

            if (!rst && rf_we) begin
                register_file[WA] <= Wdata;
            end
        end

    end


    //simulation test
`ifdef SIMULATION
    initial begin

        for (int i = 1; i < 32; i++) begin
            register_file[i] = i;
        end

    end
`endif

endmodule


module alu (
    input        [31:0] RD1,
    input        [31:0] RD2,
    input        [ 3:0] alucontrol,  //{funct7[6],funct3} :4bit
    output logic [31:0] alu_result,
    output logic        btaken
);




    //CL


    always_comb begin
        //R_TYPE
        case (alucontrol)
            `ADD:  alu_result = RD1 + RD2;
            `SUB:  alu_result = RD1 - RD2;
            `SLL:  alu_result = RD1 << RD2[4:0];  // bit width:32bit 
            `SLT:  alu_result = ($signed(RD1) < $signed(RD2)) ? 32'b1 : 32'b0;
            `SLTU: alu_result = (RD1 < RD2) ? 32'b1 : 32'b0;  // unsigned 
            `XOR:  alu_result = RD1 ^ RD2;
            `SRL:  alu_result = RD1 >> RD2[4:0];
            `SRA:  alu_result = $signed(RD1) >>> RD2[4:0];  // MSB_EXTEND
            `OR:   alu_result = RD1 | RD2;
            `AND:  alu_result = RD1 & RD2;

            default: alu_result = 32'b0;
        endcase

        //B-TYPE
        case (alucontrol)
            `BEQ: btaken = (RD1 == RD2) ? 1 : 0;  // EQ
            `BNE: btaken = (RD1 != RD2) ? 1 : 0;  // NE
            `BLT: btaken = ($signed(RD1) < $signed(RD2)) ? 1 : 0;
            `BLTU: btaken = (RD1 < RD2) ? 1 : 0;
            `BGE: btaken = ($signed(RD1) >= $signed(RD2)) ? 1 : 0;  //GE
            `BGEU: btaken = (RD1 >= RD2) ? 1 : 0;  // GEU
            default: btaken = 0;
        endcase


    end



endmodule



module program_counter (
    input               clk,
    input               rst,
    input               pc_en,
    input        [31:0] imm,
    input        [31:0] rs1_imm_sum,
    input               branch_sel,
    input               jal,
    output logic [31:0] program_counter,
    output logic [31:0] pc_4_sum,
    output logic [31:0] pc_imm_sum
);
    logic [31:0] pc_mux_alu_out, pc_mux_out, o_exe_pcnext;
    logic [31:0] pc_alu_out_4, pc_alu_out_imm;
    assign pc_imm_sum = pc_alu_out_imm;
    assign pc_4_sum   = pc_alu_out_4;


    register U_PC_REGG (
        .clk(clk),
        .rst(rst),
        .data_in(pc_mux_out),
        .data_out(o_exe_pcnext)
    );

    register_en U_PC_REG (
        .clk(clk),
        .rst(rst),
        .pc_en(pc_en),
        .data_in(o_exe_pcnext),
        .data_out(program_counter)
    );

    pc_alu U_PC_ALU_4 (
        .a(4),
        .b(program_counter),
        .pc_alu_out(pc_alu_out_4)
    );
    pc_alu U_PC_ALU_IMM (
        .a(imm),
        .b(program_counter),
        .pc_alu_out(pc_alu_out_imm)
    );

    mux_2x1 U_PC_ALU_MUX (
        .in0(pc_alu_out_4),
        .in1(pc_alu_out_imm),
        .sel(branch_sel),
        .out_mux(pc_mux_alu_out)
    );

    mux_2x1 U_PC_MUX (
        .in0(pc_mux_alu_out),
        .in1(rs1_imm_sum),
        .sel(jal),
        .out_mux(pc_mux_out)
    );

endmodule

module register (
    input               clk,
    input               rst,
    input        [31:0] data_in,
    output logic [31:0] data_out
);
    logic [31:0] register;

    assign data_out = register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) register <= 0;
        else register <= data_in;


    end

endmodule

module register_en (
    input               clk,
    input               rst,
    input               pc_en,
    input        [31:0] data_in,
    output logic [31:0] data_out
);
    logic [31:0] register;

    assign data_out = register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) register <= 0;
        else begin
            if (pc_en) begin
                register <= data_in;
            end
        end

    end

endmodule

module pc_alu (
    input [31:0] a,
    input [31:0] b,
    output logic [31:0] pc_alu_out
);

    assign pc_alu_out = a + b;


endmodule

module mux_2x1 (
    input        [31:0] in0,     //sel 0
    input        [31:0] in1,     //sel 1
    input               sel,
    output logic [31:0] out_mux
);

    assign out_mux = sel ? in1 : in0;

endmodule




module mux_5x1 (
    input [31:0] in0,  //sel 0
    input [31:0] in1,  //sel 1
    input [31:0] in2,  //sel 2
    input [31:0] in3,  //sel 3
    input [31:0] in4,  //sel 4

    input        [ 2:0] sel,
    output logic [31:0] out_mux
);

    always_comb begin

        case (sel)
            3'd0: out_mux = in0;
            3'd1: out_mux = in1;
            3'd2: out_mux = in2;
            3'd3: out_mux = in3;
            3'd4: out_mux = in4;
            default: out_mux = 32'd0;
        endcase

    end

endmodule

