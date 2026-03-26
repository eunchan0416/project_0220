`timescale 1ns / 1ps



module sram (
    input              clk,
    input  logic [3:0] addr,
    input  logic [7:0] wdata,
    input  logic       we,
    output logic [7:0] rdata
);

logic [7:0] ram [0:15];

assign rdata = ram[addr];

always_ff @( posedge clk ) begin 

if(we) begin
ram[addr]= wdata; 
end

end

endmodule
