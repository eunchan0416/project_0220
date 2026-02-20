`timescale 1ns / 1ps

module top_uart_fnd (
    input        clk,
    input        rst,
    input        uart_rx,
    input  [3:0] sw,
    input        btn_r,
    input        btn_l,
    input        btn_u,
    input        btn_d,
    input        echo,

    output       uart_tx,
    output [9:0] led,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output trigger,
    inout dhtio
);

    wire w_rx_done;
    wire [7:0] w_rx_data, w_rx_popdata, w_tx_popdata;
    wire [4:0] w_control_in;
    wire w_tx_start;
    wire [7:0] w_tx_data;
    wire w_tx_busy;
    wire [31:0] w_now_fnd_data;
    wire o_btn_run_stop, o_btn_clear;
    wire o_btn_u, o_btn_d;
    wire w_mode, w_run_stop, w_clear;
    wire w_up_l, w_up_r, w_change;
    wire [23:0] w_stopwatch_time;
    wire [23:0] w_watch_time;
    wire [23:0] w_fnd_in_data;
    
    wire w_start_sr04;
    wire w_dht_start;
    wire [11:0] w_dist;
    wire w_fifo_rx_empty;
wire [15:0] w_humidity, w_temperature;
wire [2:0] debug;
wire w_pop_decoder;
wire w_tx_empty,  w_fifo_tx_full;
 assign led[0] = (debug == 0) ? 1 : 0;
    assign led[1] = (debug == 1) ? 1 : 0;
    assign led[2] = (debug == 2) ? 1 : 0;
    assign led[3] = (debug == 3) ? 1 : 0;
    assign led[4] = (debug == 4) ? 1 : 0;
    assign led[5] = (debug == 5) ? 1 : 0;
    assign led[6] = (debug == 6) ? 1 : 0;
    assign led[7] = (debug == 7) ? 1 : 0;


    uart_top U_UART_TOP (

        .clk(clk),
        .rst(rst),

        .uart_rx(uart_rx),
        .tx_start(w_tx_start),
        .tx_data(w_tx_data),


        .uart_tx(uart_tx),
        .tx_busy(w_tx_busy),

        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );



fifo  U_FIFO_RX 
(
    .clk(clk),
    .rst(rst),

    .push(w_rx_done),
    .push_data(w_rx_data),
    .pop(w_pop_decoder),


    .pop_data(w_rx_popdata),
    .empty(w_fifo_rx_empty),
    .full()

);


    ascii_decoder U_ASCII_DECODER (
        .clk(clk),
        .rst(rst),
        .empty(w_fifo_rx_empty),
        .rx_data(w_rx_popdata),
        .pop(w_pop_decoder),
        .control_in(w_control_in)

    );


    ascii_sender U_ASCII_SENDER 
    (
        .clk       (clk),
        .rst       (rst),
        .fnd_data  (w_now_fnd_data),
        .control_in(w_control_in[4]),  
        .tx_busy   (w_tx_busy),        
        .tx_start  (w_tx_start),
        .tx_data   (w_tx_data)
    );

fifo #(.DEPTH(12), .BIT_WIDTH(8))
U_FIFO_TX 
(
    .clk(clk),
    .rst(rst),
    
    .push(!w_fifo_rx_empty),
    .pop(!w_tx_busy),
    .push_data(w_rx_popdata),
    .pop_data(w_tx_popdata),
    .empty(w_tx_empty),
    .full(w_fifo_tx_full)

);

    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );
    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_l),
        .o_btn(o_btn_clear)
    );
    btn_debounce U_BD_U (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_u),
        .o_btn(o_btn_u)
    );
    btn_debounce U_BD_D (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_d),
        .o_btn(o_btn_d)
    );




    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .reset(rst),
        .i_sel_mode(sw[2:1]),
        .i_mode(sw[0]),
        .i_run_stop(o_btn_run_stop || w_control_in[0]),
        .i_clear(o_btn_clear || w_control_in[1]),
        .i_btn_up_l(o_btn_d || w_control_in[3]),
        .i_btn_up_r(o_btn_u || w_control_in[2]),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),
        .o_mode(w_mode),
        .o_watch_up_r(w_up_r),
        .o_watch_up_l(w_up_l),
        .o_watch_change(w_change),
        .o_sr04_start(w_start_sr04),
        .o_dht_start(w_dht_start)
    );



    sr04_controller U_SR04 (
        .clk(clk),
        .rst(rst),
        
        .start(w_start_sr04),  //control to sr04
        .echo(echo),
        .dist(w_dist),
        .trigger(trigger)
    );

dht U_DHT (
        .clk(clk),
        .rst(rst),
        .start(w_dht_start),
        .humidity(w_humidity),
        .temperature(w_temperature),
        .dht_done(led[8]),
        .dht_valid(led[9]),
        .debug(debug),
        .dhtio(dhtio)
    );


    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk(clk),
        .reset(rst),
        .mode(w_mode),
        .clear(w_clear),
        .run_stop(w_run_stop),
        .msec(w_stopwatch_time[6:0]),  //7bit
        .sec(w_stopwatch_time[12:7]),
        .min(w_stopwatch_time[18:13]),
        .hour(w_stopwatch_time[23:19])
    );


    watch_datapath U_WATCH_DATAPATH (
        .clk(clk),
        .reset(rst),
        .sel_display(sw[3]),
        .up_l(w_up_l),  // left time
        .up_r(w_up_r),  // right time
        .change(w_change),  // sw[0] = 1 change
        .msec(w_watch_time[6:0]),
        .sec(w_watch_time[12:7]),
        .min(w_watch_time[18:13]),
        .hour(w_watch_time[23:19])
    );

    mux_sel_stopwatch_watch U_SEL_TYPE (
        .stopwatch_time(w_stopwatch_time),
        .watch_time(w_watch_time),
        .dht({w_humidity[15:8], w_temperature[15:8]}),
        .dist(w_dist),
        .sel(sw[2:1]),
        .fnd_in_data(w_fnd_in_data)
    );





    fnd_controller U_FND_CNTL (
        .fnd_in_data (w_fnd_in_data),
        .fnd_digit   (fnd_digit),
        .fnd_data    (fnd_data),
        .clk         (clk),
        .sel_mode(sw[2:1]),
        .reset       (rst),
        .sel_display (sw[3]),
        .now_fnd_data(w_now_fnd_data)
    );



 

endmodule
