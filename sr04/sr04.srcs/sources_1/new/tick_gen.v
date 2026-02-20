`timescale 1ns / 1ps
//1us time tick
module tick_gen(
    input clk,
    input rst,
    output reg tick
    );


parameter COUNT =100;
reg [9:0] counter;

always @(posedge clk, posedge rst) begin
       if(rst) begin 
       tick<=0;
       counter<=0;
       
       end
 else begin
    if (counter == (COUNT-1)) begin
        counter<=0;
        tick<=1;
    end else
    begin
        tick<=0;
        counter<= counter +1;
    end

end
end

endmodule
