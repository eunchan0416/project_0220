`timescale 1ns / 1ps

module tb_sr04(
    );

reg clk, rst, echo, btn_r;
wire [7:0] fnd_data;
wire [3:0] fnd_digit;
wire trigger;




top_sr04 dut(
     .clk(clk),
     .rst(rst),
     .btn_r(btn_r),
     .echo(echo),
    .trigger(trigger),
    .fnd_data(fnd_data),
    .fnd_digit(fnd_digit)
    );


always #5 clk=~clk;


initial begin
    #0;
    clk=0;
    rst=1;
    btn_r=0;
    echo=0;
    #10;
    rst=0;
    #10;
    btn_r=1;
    #10;
    btn_r=0;
    #100_000;
    echo=1;
     #100_00000;
    echo=0;

    #10;
    $stop;


end



endmodule
