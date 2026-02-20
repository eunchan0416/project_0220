`timescale 1ns / 1ps

module tb_fsm();

reg clk,reset, sw;
wire led;


fsm  dut (
  .clk(clk),
  .reset(reset),
  .sw(sw),
  .led(led)
);


always #5 clk = ~clk;


initial begin
    #0;
    reset=0;
    clk=0;
    sw=0;

    #20;
    reset=1;
    #20;
    reset=0;

    #100;

    sw=1;

    
    #100;
    $stop;




end


endmodule
