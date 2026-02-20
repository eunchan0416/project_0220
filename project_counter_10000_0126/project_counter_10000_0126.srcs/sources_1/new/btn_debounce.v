`timescale 1ns / 1ps

module btn_debounce (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);

    parameter CLK_DIV = 100_000;

    parameter F_COUNT = 100_000_000 / CLK_DIV;
    //clock divider for debounce shift register
    //100MHz --> 100kHz .1000 counter
    reg [$clog2(F_COUNT)-1:0] counter_reg;
    reg clk_100khz;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            clk_100khz  <= 0;
        end else begin
            counter_reg <= counter_reg + 1;

            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                clk_100khz  <= 1;
            end else begin
                clk_100khz <= 0;
            end

        end
    end



    //series 8 F/F
    // reg [7:0] debounces_reg; shift

    //feedback
    reg edge_reg;  ////edge detection
    reg [7:0] q_reg;
    wire [7:0] q_next;
    wire debounce;

    assign q_next = {i_btn, q_reg[7:1]};
    assign debounce = &q_reg;
    assign o_btn = (debounce & (~edge_reg));

    // shift
    /*always @(posedge clk, posedge reset) begin
        if (reset) begin
            debounces_reg <= 0;
        end else begin
            debounces_reg <= {i_btn, debounces_reg[7:1]};
        end
    end
*/

    // feedback
    always @(posedge clk_100khz, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
            edge_reg <= 0;
        end else begin
            q_reg <= q_next;
            edge_reg <= debounce;
        end
    end



endmodule
