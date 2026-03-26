`timescale 1ns / 1ps
`include "define.vh"  //must same directory exist

module rv32i_datapath (
    input         clk,
    input         rst,
    input         alusrcsel,
    input  [ 3:0] alucontrol,
    input jump,
    input         rf_we,
    input         branch,
    input jal,
    input  [ 2:0] rfwdsrcsel,
    input  [31:0] drdata,
    input  [31:0] instr_data,
    output [31:0] instr_addr,
    output [31:0] daddr,
    output [31:0] dwdata
);
    logic btaken;
    logic [31:0]
        RD1, RD2, alu_result, imm_data, alurs2_data, rf_wb_data, pc_imm_sum, pc_4_sum;

    assign dwdata = RD2;
    assign daddr  = alu_result;



    imm_extender U_IMM_EXT (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );

    mux_2x1 U_MUX_ALUSRC (
        .in0(RD2),     //sel 0
        .in1(imm_data),     //sel 1
        .sel(alusrcsel),
        .out_mux(alurs2_data)
    );



    program_counter U_PC (
        .clk(clk),
        .rst(rst),
        .imm(imm_data),
        .branch_sel((btaken & branch)||jump),
        .program_counter(instr_addr),
        .pc_imm_sum(pc_imm_sum),
        .jal(jal),
        .rs1_imm_sum(alu_result),
        .pc_4_sum(pc_4_sum)
    );

    register_file U_REG_FILE (
        .clk(clk),
        .rst(rst),
        .rf_we(rf_we),
        .RA1(instr_data[19:15]),
        .RA2(instr_data[24:20]),
        .WA(instr_data[11:7]),
        .Wdata(rf_wb_data),
        .RD1(RD1),
        .RD2(RD2)
    );


    alu U_ALU (
        .RD1(RD1),
        .RD2(alurs2_data),
        .alucontrol(alucontrol),
        .alu_result(alu_result),
        .btaken(btaken)
    );

 
mux_5x1 U_RW_MUX (
    .in0(alu_result),  //sel 0
    .in1(drdata),  //sel 1
    .in2(imm_data),  //sel 2
    .in3(pc_imm_sum),  //sel 3
    .in4(pc_4_sum),  //sel 4
    .sel(rfwdsrcsel),
    .out_mux(rf_wb_data)
);


endmodule


module register_file (
    input         clk,
    input         rst,
    input         rf_we,
    input  [ 4:0] RA1,
    input  [ 4:0] RA2,
    input  [ 4:0] WA,
    input  [31:0] Wdata,
    output [31:0] RD1,
    output [31:0] RD2
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
    input        [31:0] imm,
    input        [31:0] rs1_imm_sum,
    input               branch_sel,
    input               jal,
    output logic [31:0] program_counter,
     output logic [31:0] pc_4_sum,
    output logic [31:0] pc_imm_sum
);
    logic [31:0] pc_mux_alu_out,pc_mux_out;
    logic [31:0] pc_alu_out_4, pc_alu_out_imm;
    assign pc_imm_sum = pc_alu_out_imm;
    assign pc_4_sum = pc_alu_out_4;
    
    


    register U_PC_REG (
        .clk(clk),
        .rst(rst),
        .data_in(pc_mux_out),
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
    input         clk,
    input         rst,
    input  [31:0] data_in,
    output [31:0] data_out
);
    logic [31:0] register;

    assign data_out = register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) register <= 0;
        else register <= data_in;


    end

endmodule

module pc_alu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out
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


module mux_4x1 (
    input        [31:0] in0,     //sel 0
    input        [31:0] in1,     //sel 1
    input        [31:0] in2,     //sel 2
    input        [31:0] in3,     //sel 3
    input        [ 1:0] sel,
    output logic [31:0] out_mux
);

    always_comb begin

        case (sel)
            2'd0: out_mux = in0;
            2'd1: out_mux = in1;
            2'd2: out_mux = in2;
            default: out_mux = in3;
        endcase

    end
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

/*

module imm_extender (
    input [31:0] instr_data,
    output logic [31:0] imm_data
);


    always_comb begin
        case (instr_data[6:0])

            `S_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end
            `I_TYPE , `IL_TYPE, `JL_TYPE: begin
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end

            `B_TYPE:
            imm_data = { {20{instr_data[31]}}, instr_data[7], instr_data[30:25],instr_data[11:8],1'b0}; 

            `U_AUIPC, `U_LUI :
            imm_data = {instr_data[31:12], {12{1'b0}}};

            `J_TYPE :
            imm_data = { {12{instr_data[31]}} ,instr_data[19:12],instr_data[20],  instr_data[30:21], 1'b0 };
            default: imm_data = 32'd0;
        endcase

    end
endmodule

*/