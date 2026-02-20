`timescale 1ns / 1ps

module ram (
    input clk,
    input we,
    input [9:0] addr,
    input [7:0] wdata,
    output   [7:0] rdata
);


    reg [7:0] ram[0:1023];

    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= wdata;
        end /*else begin
            rdata <= ram[addr];
        end  */
    end

    //assign rdata = !we ? ram[addr] : 0;

    assign rdata = ram[addr];

endmodule
