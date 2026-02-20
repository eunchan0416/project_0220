`timescale 1ns / 1ps
module tick_gen_100hz (
    input clk,
    input reset,
    input run_stop,
    output reg o_tick_100hz
);
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            o_tick_100hz <= 0;
        end else begin
            if (run_stop) begin
                if (r_counter == (F_COUNT - 1)) begin
                    r_counter <= 0;
                    o_tick_100hz <= 1;
                end else begin
                    o_tick_100hz <= 0;
                    r_counter <= r_counter + 1;

                end

            end
        end

    end


endmodule

