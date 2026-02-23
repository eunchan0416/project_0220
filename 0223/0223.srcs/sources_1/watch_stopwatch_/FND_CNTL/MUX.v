`timescale 1ns / 1ps

module MUX_8x1 (
    input      [2:0] sel,
    input      [3:0] digit_1,
    input      [3:0] digit_10,
    input      [3:0] digit_100,
    input      [3:0] digit_1000,
    input      [3:0] digit_dot_1,
    input      [3:0] digit_dot_10,
    input      [3:0] digit_dot_100,
    input      [3:0] digit_dot_1000,

    output reg [3:0] mux_out
);
    always @(*) begin
        case (sel)
            3'b000: mux_out = digit_1;
            3'b001: mux_out = digit_10;
            3'b010: mux_out = digit_100;
            3'b011: mux_out = digit_1000;
            3'b100: mux_out = digit_dot_1;
            3'b101: mux_out = digit_dot_10;
            3'b110: mux_out = digit_dot_100;
            3'b111: mux_out = digit_dot_1000;
        endcase
    end
endmodule

module MUX_4x1 (
    input      [1:0] sel,
    input      [31:0] stopwatch_fnd_data,
    input      [31:0] watch_fnd_data,
    input      [31:0] sr04_fnd_data,
    input      [31:0] dht11_fnd_data,
  
    output reg [31:0] mux_out
);
    always @(*) begin
        case (sel)
            2'b00: mux_out = stopwatch_fnd_data;
            2'b01: mux_out = watch_fnd_data;
            2'b10: mux_out = sr04_fnd_data;
            2'b11: mux_out = dht11_fnd_data;                                             
        endcase
    end
endmodule


module Mux_2x1 (
    input        sel,
    input  [3:0] i_sel0,
    input  [3:0] i_sel1,
    output [3:0] o_mux
);
    // sel 1: i_sell1 , sel 2:i_sell2
    assign o_mux = (sel) ? i_sel1:i_sel0;
endmodule

