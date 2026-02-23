`timescale 1ns / 1ps

module tick_gen_1us #(parameter FCOUNT = 100) (
    input clk,
    input reset,
    output reg o_tick_1us
);
   

    reg [$clog2(FCOUNT)-1:0] r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter  <= 0;
            o_tick_1us <= 1'b0;
        end else begin

            r_counter  <= r_counter + 1;
            o_tick_1us <= 1'b0;
            if (r_counter == ((FCOUNT) - 1)) begin
                r_counter  <= 0;
                o_tick_1us <= 1'b1;
            end else begin
                o_tick_1us <= 1'b0;
            end

        end

    end


endmodule