`timescale 1ns / 1ps


module tb_top_uart_fnd(

    );

parameter BAUD= 9600;
parameter BAUD_PERIOD = (100_000_000 /BAUD)*10;
reg [7:0] test_data;
integer i,j,h;


reg clk, rst, uart_rx;
reg [2:0] sw;
reg btn_d, btn_l, btn_r, btn_u;
wire uart_tx;
wire [3:0] fnd_digit;
wire  [7:0] fnd_data;




top_uart_fnd udt (
    .clk(clk),
    .rst(rst),
    .uart_rx(uart_rx),
    .sw(sw),
    .btn_r(btn_r),      
    .btn_l(btn_l),      
    .btn_u(btn_u),
    .btn_d(btn_d),
    .uart_tx(uart_tx),
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data)
);

task uart_sender();
begin

  uart_rx=0;
    #(BAUD_PERIOD);
    for(i=0; i<8;i= i+1) begin
    uart_rx= test_data[i];
    #(BAUD_PERIOD);
    end
uart_rx=1;
    #(BAUD_PERIOD);
end
endtask



always #5 clk= ~clk;


initial begin
    #0;
    clk=0;
    rst=1;
    uart_rx=1;
    sw=3'b011;
    btn_d=0;
    btn_r=0;
    btn_u=0;
    btn_l=0;
    test_data=8'hff;
      //   sw=3'b000: stopwatch , upmode, sec.msec 
repeat (5) @(posedge clk);
    rst=0;
//btn_u
        test_data=8'h75;
        uart_sender();

#50_000_000;
    //btn_d
  test_data=8'h64;
    uart_sender();
#50_000_000;

  test_data=8'h6c;
        uart_sender();

#50_000_000;
 

$stop;



end








endmodule
