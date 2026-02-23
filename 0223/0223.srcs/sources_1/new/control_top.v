`timescale 1ns / 1ps

module control_unit_top(
    input clk,
    input reset,
    input [3:0] sw, // sw[0] : up,down, sw[1] : hour, sec display, sw[2] : watch,stopwatch, sw[3]: 초음파, 온습도
    input i_btn_L, 
    input i_btn_R, 
    input i_btn_C, 
    //stopwatch_watch
    output o_sw_run_stop,
    output o_sw_clear,
    output o_sw_mode,        // sw[0] 패스스루
    output [2:0] o_w_cursor, // 0:Idle, 1~4:수정위치
    output o_w_blink_en,      // 깜빡임 활성화 신호
    //sr04
    input i_sr_start,
    input i_sr_echo,
    output o_sr_trigger,
    output [8:0] o_distance,
    //dht11
    input         start,
    output [15:0] humidity,
    output [15:0] temperature,
    output        dht11_done,
    output        dht11_valid,
    output [ 2:0] debug,
    inout         dhtio
    );



SR04_controller U_SRO4_CNRL (
    .clk(clk),
    .reset(reset),
    .i_sr_start(i_sr_start),
    .i_sr_echo(i_sr_echo),
    .o_sr_trigger(o_sr_trigger),
    .o_distance(o_distance)
);

dht11_controller U_DHT11_CNRL(
    .clk(clk),
    .rst(rst),
    .start(start),
    .humidity(humidity),
    .temperature(temperature),
    .dht11_done(),
    .dht11_valid(dht11_valid),
    .debug(debug),
    .dhtio(dhtio)
);


control_unit U_TOP_CTRL (
        .clk(clk),
        .reset(reset),
        .i_sw_watch_stopwatch(sw[2]),
        .i_sw_up_down(sw[0]),
        .i_btn_L(i_btn_L),
        .i_btn_R(i_btn_R),
        .i_btn_C(i_btn_C),
        .o_sw_run_stop(o_sw_run_stop),
        .o_sw_clear(o_sw_clear),
        .o_sw_mode(o_sw_mode),
        .o_w_cursor(o_w_cursor),
        .o_w_blink_en(o_w_blink_en)
    );





endmodule
