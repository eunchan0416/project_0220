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
    output [31:0] dwdata
);

    logic rf_we, alusrcsel, rfwdsrcsel;
    logic [ 3:0] alucontrol;
    
    control_unit U_CONTROL_UNIT (
        .funct7(instr_data[31:25]),
        .funct3(instr_data[14:12]),
        .opcode(instr_data[6:0]),
        .rf_we(rf_we),
        .dwe(dwe),
        .alusrcsel(alusrcsel),
        .rfwdsrcsel(rfwdsrcsel),
        .alucontrol(alucontrol)
    );

    rv32i_datapath U_DATAPATH (.*);


endmodule





module control_unit (
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    output logic       rf_we,
    output logic       dwe,
    output logic       rfwdsrcsel,
    output logic       alusrcsel,
    output logic [3:0] alucontrol
);



    always_comb begin

        case (opcode)

            `R_TYPE: begin
                dwe = 0;
                rf_we = 1'b1;
                alusrcsel = 1'b0;
                alucontrol = {funct7[5], funct3};
                rfwdsrcsel = 0;
            end
            `S_TYPE: begin
                dwe = 1;
                alusrcsel = 1'b1;
                alucontrol = 0;
                rf_we = 0;
                rfwdsrcsel = 0;
            end
            `IL_TYPE: begin

                dwe = 0;
                alusrcsel = 1'b1;
                alucontrol = 0;
                rf_we = 1;
                rfwdsrcsel = 1;

            end
            default: begin
                rfwdsrcsel = 0;
                dwe = 0;
                rf_we = 1'b0;
                alusrcsel = 1'b0;
                alucontrol = 4'b0000;
            end
        endcase

    end

endmodule


