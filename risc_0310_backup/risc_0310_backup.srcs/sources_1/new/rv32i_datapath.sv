`timescale 1ns / 1ps
`include "define.vh"  //must same directory exist

module rv32i_datapath (
    input         clk,
    input         rst,
    input         alusrcsel,
    input  [ 3:0] alucontrol,
    input         rf_we,
    input         rfwdsrcsel,
    input  [31:0] drdata,
    input  [31:0] instr_data,
    output [31:0] instr_addr,
    output [31:0] daddr,
    output [31:0] dwdata
);

    logic [31:0] RD1, RD2, alu_result, imm_data, alurs2_data, rf_wb_data;

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

    //to register file
    mux_2x1 U_MUX_ALU_DM (
        .in0(alu_result),     //sel 0
        .in1(drdata),     //sel 1
        .sel(rfwdsrcsel),
        .out_mux(rf_wb_data)
    );



    program_counter U_PC (
        .clk(clk),
        .rst(rst),
        .program_counter(instr_addr)
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
        .alu_result(alu_result)
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
        //register_file[8]  = 32'hffff_ffff;
        //register_file[9]  = 32'h0000_0001;
        //register_file[10] = 32'h0000_0000;
    end
`endif

endmodule


module alu (
    input        [31:0] RD1,
    input        [31:0] RD2,
    input        [ 3:0] alucontrol,  //{funct7[6],funct3} :4bit
    output logic [31:0] alu_result
);

    //CL
    always_comb begin
        case (alucontrol)
            `ADD: alu_result = RD1 + RD2;
            `SUB: alu_result = RD1 - RD2;
            `SLL: alu_result = RD1 << RD2[4:0];  // bit width:32bit 
            `SLT: alu_result = ($signed(RD1) < $signed(RD2)) ? 32'b1 : 32'b0;
            `SLTU: alu_result = (RD1 < RD2) ? 32'b1 : 32'b0;  // unsigned 
            `XOR: alu_result = RD1 ^ RD2;
            `SRL: alu_result = RD1 >> RD2[4:0];
            `SRA: alu_result = $signed(RD1) >>> RD2[4:0];  // MSB_EXTEND
            `OR: alu_result = RD1 | RD2;
            `AND: alu_result = RD1 & RD2;
            default: alu_result = 32'b0;
        endcase
    end

endmodule



module program_counter (
    input clk,
    input rst,
    output logic [31:0] program_counter
);

    logic [31:0] pc_alu_out;
    register U_PC_REG (
        .clk(clk),
        .rst(rst),
        .data_in(pc_alu_out),
        .data_out(program_counter)
    );

    pc_alu U_PC_ALU (
        .a(32'd4),
        .b(program_counter),
        .pc_alu_out(pc_alu_out)
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
