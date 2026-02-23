`timescale 1ns / 1ps

module StopWatch_Datapath (
    input        clk,
    input        reset,
    input        i_mode,
    input        i_run_stop,
    input        i_clear,
    output [6:0] o_msec,
    output [5:0] o_sec,
    output [5:0] o_min,
    output [4:0] o_hour
);

    wire w_tick_100HZ;
    wire w_sec_tick, w_min_tick, w_hour_tick;

    Tick_generator #(
        .CLK_FREQ (100_000_000),  // 입력 주파수 기본값 100MHz
        .TICK_FREQ(100)
    ) U_Tick_get_100Hz (
        .clk     (clk),
        .reset   (reset),
        .tick_out(w_tick_100HZ)  // always구문에서 출력은 reg타입.
    );

    /* ---------------------------------------------------------------------------------------------------*/
    //msec counter
    //msec부터 올라가거나 내려가는 카운터
    tick_time_counter #(
        .TIME          (100),  // 기본 카운트 숫자
        .COUNT_BITWIDTH(7)     // 출력시킬 수 있는 최소 bit수 
    ) U_msec_counter (
        .clk       (clk),
        .reset     (reset),
        .i_tick    (w_tick_100HZ),
        .i_mode     (i_mode),
        .i_run_stop(i_run_stop),
        .i_clear   (i_clear),
        .o_tick    (w_sec_tick),
        .o_count   (o_msec)
    );

    /* ---------------------------------------------------------------------------------------------------*/
    //sec counter
    tick_time_counter #(
        .TIME          (60),  // 기본 카운트 숫자
        .COUNT_BITWIDTH(6)    // 출력시킬 수 있는 최소 bit수 
    ) U_sec_counter (
        .clk       (clk),
        .reset     (reset),
        .i_tick    (w_sec_tick),
        .i_mode     (i_mode),
        .i_run_stop(i_run_stop),
        .i_clear   (i_clear),
        .o_tick    (w_min_tick),
        .o_count   (o_sec)
    );

    /* ---------------------------------------------------------------------------------------------------*/
    //min counter
    tick_time_counter #(
        .TIME          (60),  // 기본 카운트 숫자
        .COUNT_BITWIDTH(6)    // 출력시킬 수 있는 최소 bit수 
    ) U_min_counter (
        .clk       (clk),
        .reset     (reset),
        .i_tick    (w_min_tick),
        .i_mode     (i_mode),
        .i_run_stop(i_run_stop),
        .i_clear   (i_clear),
        .o_tick    (w_hour_tick),
        .o_count   (o_min)
    );

    /* ---------------------------------------------------------------------------------------------------*/
    //hour counter
    tick_time_counter #(
        .TIME          (24),  // 기본 카운트 숫자
        .COUNT_BITWIDTH(5)   // 출력시킬 수 있는 최소 bit수 
    ) U_hour_counter (
        .clk       (clk),
        .reset     (reset),
        .i_tick    (w_hour_tick),
        .i_mode     (i_mode),
        .i_run_stop(i_run_stop),
        .i_clear   (i_clear),
        .o_tick    (),
        .o_count   (o_hour)
    );

endmodule


