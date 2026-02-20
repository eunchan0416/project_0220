`timescale 1ns / 1ps


module tb_btn(

    );

reg clk, reset;

reg up_l, up_r, change, sel_display;

wire [6:0]msec;
wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

watch_datapath dut (
    .clk(clk),
    .reset(reset),
    .sel_display(sel_display),
    .up_l(up_l),         // left time
    .up_r(up_r),         // right time
    .change(change),       // sw[0] = 1 change, sw[0] =0 ongoing
    .msec(msec),
    .sec(sec),
    .min(min),
    .hour(hour)
);

always #5 clk=~clk;

initial begin
    #0;
    clk=0;
    reset=1;
   up_l=0;
   up_r=0;
   change=0;
    sel_display=0;
    #10;
    reset=0;

#100;
up_r=1;
#10;
up_r=0;
#10;
up_l=1;
#10;
up_l=0;

#100;
change=1;
#100;

sel_display=0;

#10;
up_r=1;
#10;
up_r=0;
#10;
up_l=1;
#10;
up_l=0;


#100;

sel_display=1;

#10;
up_r=1;
#10;
up_r=0;
#10;
up_l=1;
#10;
up_l=0;

#1000000;
change=0;

#5000000;
/*
mode=0;
#1000000;
run_stop=1;
#1000000;
mode=1;
#1000000;
mode=0;
run_stop=0;
clear=1;

*/

#100000000;

    $stop;

    



end
endmodule
