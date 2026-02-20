`timescale 1ns / 1ps


module tb_sr04_only(

    );

reg clk, rst, echo, start;
wire [11:0] dist;
wire trigger;

top_sr04 dut(
     .clk(clk),
     .rst(rst),
     .start(start),
     .echo(echo),
     .trigger(trigger),
      .dist(dist)
    );



always #5 clk=~clk;


initial begin
    #0;
    clk=0;
    rst=1;
    start=0;
    echo=0;
    #10;
    rst=0;
    #10;
    start=1;
    #10;
    start=0;
    #100_000;
    echo=1;
     #30_00000;
    echo=0;

    #10;
    $stop;


end

endmodule
