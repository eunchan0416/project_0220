`timescale 1ns / 1ps

module Tick_generator #(parameter  CLK_FREQ=100_000_000, // 입력 주파수 기본값 100MHz
parameter TICK_FREQ =100 ) // 출력 주파수 기본값 100Hz
(
    input      clk,
    input      reset,
    output reg tick_out // always구문에서 출력은 reg타입.
);

    localparam counter_max = CLK_FREQ / TICK_FREQ;
    reg [$clog2(counter_max)-1:0] counter_r;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0;
            tick_out <=1'b0;
        end else begin
            counter_r <= counter_r + 1;
            tick_out <=1'b0;
            if (counter_r == (counter_max - 1)) begin
                counter_r <= 0;
                tick_out <=1'b1;
            end else begin
                tick_out <=1'b0;
            end
        end
    end

endmodule