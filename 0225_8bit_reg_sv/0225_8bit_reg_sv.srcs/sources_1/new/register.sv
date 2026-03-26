`timescale 1ns / 1ps

module register (
    input              clk,
    input              rst,
    input  logic [7:0] wdata,
    input  logic       we,
    output logic [7:0] rdata
);

    always_ff @(posedge clk, posedge rst) begin

        if (rst) rdata <= 0;
        else if (we) begin
            rdata <= wdata;
        end 
        //else rdata <= 0;

    end


endmodule
