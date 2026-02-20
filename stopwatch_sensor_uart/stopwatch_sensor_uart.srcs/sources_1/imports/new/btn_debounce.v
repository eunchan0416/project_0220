`timescale 1ns / 1ps

module btn_debounce (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);

    parameter F_COUNT = 1000_000;
    reg [$clog2(F_COUNT)-1:0] counter_reg;
    reg r_tick;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            r_tick  <= 0;
        end else begin
            counter_reg <= counter_reg + 1;

            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                r_tick  <= 1;
            end else begin
                r_tick <= 0;
            end

        end
    end

    reg [7:0] q_reg;
    wire [7:0] q_next;
    wire debounce;

    assign q_next = {i_btn, q_reg[7:1]};
    assign debounce = &q_reg;
    always @(posedge r_tick, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

reg r_btn_prev;
    
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_btn_prev <= 0;
        end else begin
            r_btn_prev <= debounce;
        end
    end


    assign o_btn = debounce & ~r_btn_prev;

endmodule



