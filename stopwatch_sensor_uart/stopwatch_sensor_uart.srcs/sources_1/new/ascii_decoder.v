`timescale 1ns / 1ps


module ascii_decoder (
    input clk,
    input rst,
    input [7:0] rx_data,
    input rx_done,
    output [4:0] control_in // [0]: btn_r, [1]: btn_l, [2]: btn_u, [3]: btn_d,   [4] s: time

);

reg [4:0] control_ct, control_nt;

assign control_in= control_ct; 

always @(posedge clk, posedge rst) begin
    if (rst) begin
        control_ct<=5'd0;
    end else begin
        if(rx_done) control_ct <= control_nt;
        else control_ct<=5'd0;
    end

end
 
always@(*) begin
control_nt= 0;
case (rx_data)
  8'h72  : begin control_nt[0]=1; end
  8'h6C  : begin control_nt[1]=1; end
  8'h75  : begin control_nt[2]=1; end
  8'h64  : begin control_nt[3]=1; end
  8'h73  : begin control_nt[4]=1; end
    default: control_nt=0;
endcase

end




endmodule
