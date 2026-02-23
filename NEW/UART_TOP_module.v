`timescale 1ns / 1ps

module UART_Top_Module (
    input        clk,
    input        reset,
    input  [7:0] i_tx_data,
    input        i_tx_start,
    input        i_uart_rx,
    output       o_uart_tx,
    output [7:0] o_rx_data,
    output       o_rx_done,
    output       o_tx_busy
);

    wire w_b_tick;

    // btn 송신기(Tx)
    Tx U_TX (
        .clk       (clk),
        .reset     (reset),
        .i_tx_data (i_tx_data),
        .baud_tick (w_b_tick),
        .i_tx_start(i_tx_start),
        .o_tx_data (o_uart_tx),
        .o_tx_done (),
        .o_tx_busy (o_tx_busy)

    );

    //btn 수신기(rx)
    Rx U_RX (
        .clk      (clk),
        .reset    (reset),
        .i_rx_data(i_uart_rx),
        .baud_tick(w_b_tick),
        .o_rx_data(o_rx_data),
        .o_rx_done(o_rx_done)
    );

    // Baud_tick
    baud_tick_16 U_BAUD_TICK_16 (
        .clk(clk),
        .reset(reset),
        .baud_tick(w_b_tick)
    );


endmodule
