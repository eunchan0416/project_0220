`timescale 1ns / 1ps
`include "define.vh"


module rv32i_cpu (
    input         clk,
    input         rst,
    input  [31:0] instr_data,
    input  [31:0] drdata,
    output [31:0] instr_addr,
    output        dwe,
    output [31:0] daddr,
    output [ 2:0] c2dm_funct3,
    output [31:0] dwdata
);

    logic rf_we, alusrcsel, branch,jal,jump;
    logic [2:0] rfwdsrcsel;
    logic [3:0] alucontrol;


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
        .alucontrol(alucontrol),
        .c2dm_funct3(c2dm_funct3),
        .branch(branch)
    );

    rv32i_datapath U_DATAPATH (.*);


endmodule





module control_unit (
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    output logic       rf_we,
    output logic       dwe,
    output logic       jump,
    output logic [2:0] rfwdsrcsel,
    output logic       alusrcsel,
    output logic [2:0] c2dm_funct3,
    output logic [3:0] alucontrol,
    output logic       branch,
    output logic       jal
    
);



    always_comb begin

        case (opcode)

            `R_TYPE: begin
                jump=0;
                jal=0;
                dwe = 0;
                rf_we = 1'b1;
                alusrcsel = 1'b0;
                alucontrol = {funct7[5], funct3};
                rfwdsrcsel = 0;
                c2dm_funct3 = 0;
                branch = 0;
            end
            `S_TYPE: begin
                jump=0;
                jal=0;
                dwe = 1;
                alusrcsel = 1'b1;
                alucontrol = 0;
                rf_we = 0;
                rfwdsrcsel = 0;
                c2dm_funct3 = funct3;
                branch = 0;
            end
            `IL_TYPE: begin
                jump=0;
                jal=0;
                branch = 0;
                dwe = 0;
                alusrcsel = 1'b1;
                alucontrol = 0;  //ADD
                rf_we = 1;
                rfwdsrcsel = 1;
                c2dm_funct3 = funct3;
            end
            `I_TYPE: begin
                jump=0;
                jal=0;
                branch = 0;
                dwe = 0;
                alusrcsel = 1'b1;
                rf_we = 1;
                rfwdsrcsel = 0;
                c2dm_funct3 = funct3;
                if (funct3 == 3'b101) begin
                    alucontrol = {funct7[5], funct3};
                end else alucontrol = {1'b0, funct3};

            end

            `B_TYPE: begin
                jump=0;
                jal=0;
                branch = 1;
                rfwdsrcsel = 0;
                dwe = 0;
                rf_we = 1'b0;
                alusrcsel = 1'b0;
                c2dm_funct3 = 0;
                alucontrol = {1'b0, funct3};


            end
            `U_LUI: begin
                //LUI
                jal=0;
                jump=0;
                rfwdsrcsel = 2;
                branch = 0;
                dwe = 0;
                rf_we = 1'b1;
                alusrcsel = 1'b0;
                c2dm_funct3 = 0;
                alucontrol = 0;
            end

            `U_AUIPC: begin
                //AUIPC
                jal=0;
                jump=0;
                rfwdsrcsel = 3;
                branch = 0;
                dwe = 0;
                rf_we = 1'b1;
                alusrcsel = 1'b0;
                c2dm_funct3 = 0;
                alucontrol = 0;
            end
            `JL_TYPE :  begin
                jal=1;
                jump=0;
                rfwdsrcsel=4;
                branch = 0;
                dwe = 0;
                rf_we = 1'b1;
                alusrcsel = 1'b1;
                c2dm_funct3 = 0;
                alucontrol = 0;
            end
            `J_TYPE : begin
                jump=1;
                jal=0;
                rfwdsrcsel=4;
                branch = 0;
                dwe = 0;
                rf_we = 1'b1;
                alusrcsel = 1'b0;
                c2dm_funct3 = 0;
                alucontrol = 0;
            end

            default: begin
                jal=0;
                jump=0;
                branch = 0;
                rfwdsrcsel = 0;
                dwe = 0;
                rf_we = 1'b1;
                alusrcsel = 1'b1;
                alucontrol = 4'b0000;
                c2dm_funct3 = 0;
            end
        endcase

    end

endmodule


