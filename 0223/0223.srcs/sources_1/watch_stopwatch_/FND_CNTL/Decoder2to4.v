`timescale 1ns / 1ps

module Decoder2to4 (
    input      [1:0] digit_sel,
    output reg [3:0] decoderOut
);

    always @(digit_sel)
        case (digit_sel)
            2'b00: decoderOut = 4'b1110;
            2'b01: decoderOut = 4'b1101;
            2'b10: decoderOut = 4'b1011;
            2'b11: decoderOut = 4'b0111;

        endcase
endmodule

