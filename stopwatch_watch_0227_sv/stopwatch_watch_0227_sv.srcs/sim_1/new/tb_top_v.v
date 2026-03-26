`timescale 1ns / 1ps


module tb_top_v( );

reg clk, reset, btn_r,btn_l;
reg [2:0] sw;
wire [23:0] watch_time,stopwatch_time;


top_stopwatch_watch dut (
    .clk(clk),
    .reset(reset),
    .sw(sw),
    .btn_r(btn_r),      // run_stop
    .btn_l(btn_l),      // clear
    .watch_time(watch_time),
    .stopwatch_time(stopwatch_time)
);


always #5 clk= ~clk;


initial begin
#0;
clk=0;
reset=1;
sw=3'b000;
btn_r=0;
btn_l=0;


#10;
reset=0;

// stopwatch 
//run
@(posedge clk);
#1;
btn_r=1;
@(posedge clk);
#1;
btn_r=0;

#100_000_000;

//stop
@(posedge clk);
#1;
btn_r=1;
@(posedge clk);
#1;
btn_r=0;

#1000;
@(posedge clk);
#1;
btn_l=1;
@(posedge clk);
#1;
btn_l=0;

#100;
@(posedge clk);
#1;
//watch
sw=3'b010;

#100_000_000;
@(posedge clk);
#1;
sw=3'b011;
#100;
@(posedge clk);
#1;
btn_r=1;
@(posedge clk);
#1;
btn_r=0;

#20;
@(posedge clk);
#1;
btn_l=1;
@(posedge clk);
#1;
btn_l=0;

@(posedge clk);
#1;
sw=3'b010;

#100_00;
$stop;







end




endmodule
