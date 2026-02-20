`timescale 1ns / 1ps

module clk_div (
    input clk,
    input reset,
    output reg clk_2,
    output reg clk_10

);

    reg [2:0] counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            clk_2   <= 0;
            clk_10  <= 0;
            counter <= 0;

        end else begin
            clk_2   <= ~clk_2;

            if (counter == 4) begin
                clk_10 <=1;
                counter <= 0;

            end else  begin
            counter <= counter + 1;
            clk_10<=0;
            end

        end


    end



endmodule
