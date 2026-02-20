`timescale 1ns / 1ps


module tb_acsii_decoder(

    );

reg clk,rst, rx_done;
reg [7:0] rx_data;
wire [3:0] control_in;


ascii_decoder  dut(
    .clk(clk),
    .rst(rst),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .control_in(control_in) // [0]: btn_r, [1]: btn_l, [2]: btn_u, [4]: btn_d,   

);



always #5 clk=~clk;


initial begin
    #0;
    clk=0;
    rst=1;
    rx_done=0;
    rx_data=0;
    #10;
    rst=0;
    #10;
 rx_data=8'h72;
 #10;
 rx_done=1;
 #10;
 rx_done=0;
 #10;

 rx_data=8'h6C;
 #10;
 rx_done=1;
 #10;
 rx_done=0;
 #10;

 rx_data=8'h75;
 #10;
 rx_done=1;
 #10;
 rx_done=0;

 #10;
  rx_data=8'h64;
 #10;
 rx_done=1;
 #10;
 rx_done=0;
 #10;
  rx_data=8'h00;
 #10;
 rx_done=1;
 #10;
 rx_done=0;
 $stop;
 



end



endmodule
