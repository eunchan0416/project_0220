`timescale 1ns / 1ps

module Watch_Datapath (
    input clk, 
    input reset,
    input [2:0] i_cursor,   
    input i_btn_up, 
    input i_btn_down, // (Level Input)
    output [4:0] o_hour, 
    output [5:0] o_min, 
    output [5:0] o_sec, 
    output [6:0] o_msec
);
    wire w_100hz_tick;
    wire w_msec_carry, w_sec_carry, w_min_carry;
    wire is_setting_mode = (i_cursor != 0); // 설정 중인지 확인
    
    // ★ 핵심: 설정 중에는 시간을 멈춤 (tick_in을 0으로)
    wire tick_in_msec = (is_setting_mode) ? 1'b0 : w_100hz_tick;
    wire tick_in_sec  = w_msec_carry;

    wire w_up_pulse, w_down_pulse;
    Smart_Button_Controller U_ACCEL_UP (
        .clk(clk),
        .reset(reset),
        .i_btn_level(i_btn_up),
        .o_pulse(w_up_pulse));
    Smart_Button_Controller U_ACCEL_DOWN (
        .clk(clk),
        .reset(reset),
        .i_btn_level(i_btn_down),
        .o_pulse(w_down_pulse));

    wire count_mode = w_down_pulse ? 1'b1 : 1'b0; 

    // 버튼 입력 처리 (설정 중일 때만 버튼 적용)
    wire tick_in_min  = (i_cursor == 3'd3 || i_cursor == 3'd4) ? (w_up_pulse | w_down_pulse) : ((is_setting_mode) ? 1'b0 : w_sec_carry);
    wire tick_in_hour = (i_cursor == 3'd1 || i_cursor == 3'd2) ? (w_up_pulse | w_down_pulse) : ((is_setting_mode) ? 1'b0 : w_min_carry);

    Tick_generator #(.CLK_FREQ(100_000_000), .TICK_FREQ(100)) U_TICK_GEN (.clk(clk), .reset(reset), .tick_out(w_100hz_tick));

    tick_time_counter #(
        .TIME(100),
        .COUNT_BITWIDTH(7)
        ) U_CNT_MSEC (
            .clk(clk),
            .reset(reset),
            .i_tick(tick_in_msec),
            .i_mode(1'b0),
            .i_run_stop(1'b1),
            .i_clear(1'b0),
            .o_tick(w_msec_carry),
            .o_count(o_msec));
    
    tick_time_counter #(
        .TIME(60),
        .COUNT_BITWIDTH(6)
        ) U_CNT_SEC (
            .clk(clk),
            .reset(reset),
            .i_tick(tick_in_sec),
            .i_mode(1'b0),
            .i_run_stop(1'b1),
            .i_clear(1'b0),
            .o_tick(w_sec_carry),
            .o_count(o_sec));
    
    tick_time_counter #(
        .TIME(60),
        .COUNT_BITWIDTH(6)
        ) U_CNT_MIN (
            .clk(clk),
            .reset(reset),
            .i_tick(tick_in_min),
            .i_mode(count_mode),
            .i_run_stop(1'b1),
            .i_clear(1'b0),
            .o_tick(w_min_carry),
            .o_count(o_min));

    tick_time_counter #(
        .TIME(24),
        .COUNT_BITWIDTH(5),
        .INITIAL_VALUE  (12)
        ) U_CNT_HOUR (
            .clk(clk),
            .reset(reset),
            .i_tick(tick_in_hour),
            .i_mode(count_mode),
            .i_run_stop(1'b1),
            .i_clear(1'b0),
            .o_tick(),
            .o_count(o_hour));

endmodule