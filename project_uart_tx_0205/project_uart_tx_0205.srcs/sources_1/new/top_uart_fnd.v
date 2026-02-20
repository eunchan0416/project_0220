`timescale 1ns / 1ps

module top_uart_fnd (
    input  clk,
    input  rst,
    input  uart_rx,
    input  [2:0] sw,
    input        btn_r,      
    input        btn_l,      
    input        btn_u,
    input        btn_d,
    output uart_tx,
     output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire w_rx_done;
    wire [7:0] w_rx_data;
    wire [3:0] w_control_in;


    uart_top U_UART_TOP (

        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .rx_data(w_rx_data),
        .rx_done( w_rx_done)
    );


    ascii_decoder U_ASCII_DECODER (
        .clk(clk),
        .rst(rst),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .control_in(w_control_in)  

    );


top_stopwatch_watch U_STOPWATCH_WATCH (
    .clk(clk),
    .reset(rst),
    .sw(sw),
    .btn_r(btn_r),      // run_stop
    .btn_l(btn_l),      // clear
    .btn_u(btn_u),
    .btn_d(btn_d),
    .control_in(w_control_in),     
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data)
);


endmodule
