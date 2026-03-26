`timescale 1ns / 1ps


module rv23i_datapath(
input         clk,
    input         rst,
    input  [31:0] instr_data,
    output [31:0] instr_addr 
    );


    logic rf_we;
    logic [31:0] RD1, RD2, alu_result;
    logic [2:0] alucontrol;

    register_file U_REG_FILE (
        .clk(clk),
        .rst(rst),
        .rf_we(rf_we),
        .RA1(instr_data[19:15]),
        .RA2(instr_data[24:20]),
        .WA(instr_data[11:7]),
        .Wdata(alu_result),
        .RD1(RD1),
        .RD2(RD2)
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

    logic [31:0] reg_mem [0:31];

    assign RD1 = reg_mem[RA1];
    assign RD2 = reg_mem[RA2];

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin 
            //addr [0] = fixed zero
                reg_mem[0] <= 32'b0;
            
        end else begin
            
            if (rf_we ) begin
                reg_mem[WA] <= Wdata;
            end
        end
    end

endmodule


module alu (
    input  [31:0] RD1,
    input  [31:0] RD2,
    input  [ 2:0] alucontrol,
    output logic [31:0] alu_result
);

    always @(*) begin
        case(alucontrol)
            3'b000 : alu_result = RD1 + RD2;
            3'b001 : alu_result = RD1 - RD2;
            3'b010 : alu_result = RD1 & RD2; 
            3'b011 : alu_result = RD1 | RD2;
            3'b100 : alu_result = ($signed(RD1) < $signed(RD2)) ? 32'b1 : 32'b0; 
            default : alu_result = 32'b0; 
        endcase
    end

endmodule


module pc (
    input clk,
    input rst,
    output logic [31:0] instr_addr 
);

    always @(posedge clk or posedge rst) begin
        if(rst) begin 
            instr_addr <= 32'b0; 
        end else begin
            instr_addr <= instr_addr + 4; 
        end
    end

endmodule