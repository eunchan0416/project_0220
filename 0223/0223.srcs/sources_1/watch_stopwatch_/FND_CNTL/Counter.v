`timescale 1ns / 1ps

module Counter #(
   parameter BIT_WIDTH = 3
) (
    input        clk,
    input        reset,
    output [BIT_WIDTH-1:0] digit_sel
);

    reg [BIT_WIDTH-1:0] counter_r;

    assign digit_sel =counter_r;
    
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            // init counter_r
            counter_r <=0;
        end else begin
            // to do 
            counter_r <= counter_r+1; 
        end

    end

endmodule