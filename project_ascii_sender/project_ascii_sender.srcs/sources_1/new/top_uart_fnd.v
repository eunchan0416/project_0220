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
    wire [4:0] w_control_in;
    wire w_tx_start;
wire [7:0] w_tx_data;
wire w_tx_busy;
wire [31:0] w_now_fnd_data;
    uart_top U_UART_TOP (

        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .tx_start(w_tx_start),
        .tx_data(w_tx_data),
        .rx_data(w_rx_data),
        .rx_done( w_rx_done),
        .tx_busy(w_tx_busy)
    );


    ascii_decoder U_ASCII_DECODER (
        .clk(clk),
        .rst(rst),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .control_in(w_control_in)  

    );
 ascii_sender U_ASCII_SENDER (
    .clk(clk),
    .rst(rst),
    .fnd_data(w_now_fnd_data),
    .control_in(w_control_in[4]),      // 's' 키 입력 시 1 pulse
    .tx_busy(w_tx_busy),         // uart_tx 상태
    .tx_start(w_tx_start),
    .tx_data(w_tx_data)
);

top_stopwatch_watch U_STOPWATCH_WATCH (
    .clk(clk),
    .reset(rst),
    .sw(sw),
    .btn_r(btn_r),      // run_stop
    .btn_l(btn_l),      // clear
    .btn_u(btn_u),
    .btn_d(btn_d),
    .control_in(w_control_in[3:0]),     
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data),
    .now_fnd_data(w_now_fnd_data)
);


endmodule
