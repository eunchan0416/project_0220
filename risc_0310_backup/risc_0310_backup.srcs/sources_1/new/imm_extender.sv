`timescale 1ns / 1ps
`include "define.vh"

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
            `IL_TYPE: begin
                imm_data = {{10{instr_data[31]}}, instr_data[31:20]};
            end

            /* `B_TYPE:
            imm_data = { {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]}; */
            default: imm_data = 32'd0;
        endcase

    end
endmodule
