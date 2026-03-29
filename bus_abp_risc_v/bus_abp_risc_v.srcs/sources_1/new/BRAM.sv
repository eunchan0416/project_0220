`timescale 1ns / 1ps

module BRAM (
    input               pclk,
    input        [31:0] paddr,
    input        [31:0] pwdata,
    input               penable,
    input               pwrite,
    input               psel,
    output logic [31:0] prdata,
    output logic        pready
);

    logic [31:0] bmem[0:1023];
    assign pready= 1; 
    
    always_ff @(posedge pclk) begin
        if (pwrite&psel & penable) begin
            bmem[paddr[11:2]] <= pwdata;
        end 
    end

    assign prdata = bmem[paddr[11:2]];
endmodule
