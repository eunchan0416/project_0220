`timescale 1ns / 1ps


module tb_fsm(

    );

reg clk,reset;
reg [2:0] sw;
wire [2:0] led;
    fsm dut (
    .clk(clk),
    .reset(reset),
    .sw(sw),
    .led(led)
);

always #5 clk=~clk;


initial begin
#0;
clk=0;
reset=1;
sw=0;

#10;
reset=0;

#20;
sw=1;
#20;
sw=2;
#20;
sw=4;
#20;
sw=3;
#20;
sw=2;
#20;
sw=3;
#20;
sw=4;
#20;
sw=0;
#20;
sw=2;
#20;
sw=4;
#20;
sw=7;
#20;
sw=0;
#20;

$stop;



end
endmodule
