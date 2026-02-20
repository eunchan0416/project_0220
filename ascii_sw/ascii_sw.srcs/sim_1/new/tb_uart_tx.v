`timescale 1ns / 1ps

module tb_uart_tx(
    );

reg clk,rst, btn_down; //btn_down 100msec
wire uart_tx;


uart_top dut (

    .clk(clk),
    .rst(rst),
    .btn_down(btn_down), 
    .uart_tx(uart_tx)
   
);


always #5 clk=~clk;


initial begin
    #0;
    clk=0;
    rst=1;
    btn_down=0;

    #20;
    rst=0;
    btn_down=1;

    #100_000_000;
    btn_down=0;

    $stop;






end




endmodule
