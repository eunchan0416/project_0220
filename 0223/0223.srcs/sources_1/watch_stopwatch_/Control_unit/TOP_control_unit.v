`timescale 1ns / 1ps

module control_unit (
    input clk,
    input reset,

    // --- 외부 입력 ---
    input [1:0] i_sw_watch_stopwatch, // sw[2]: 0=Watch, 1=Stopwatch
    input i_sw_up_down,         // sw[0]: Stopwatch Up/Down 모드
    
    input i_btn_L, // Pulse (Edge Detected)
    input i_btn_R, // Pulse (Edge Detected)
    input i_btn_C, // Pulse (Edge Detected) - Watch 설정 진입용

    // --- 스톱와치용 출력 ---
    output o_sw_run_stop,
    output o_sw_clear,
    output o_sw_mode,        // sw[0] 패스스루

    // --- 와치용 출력 ---
    output [2:0] o_w_cursor, // 0:Idle, 1~4:수정위치
    output o_w_blink_en      // 깜빡임 활성화 신호
);

    
    // 1. 입력 신호 MUX (교통정리)
    

    
    // [Stopwatch 입력] sw[2]가 1일 때만 버튼 허용
    wire w_sw_run_stop_in = (i_sw_watch_stopwatch == 2'b1) ? i_btn_R : 1'b0;
    wire w_sw_clear_in    = (i_sw_watch_stopwatch == 2'b1) ? i_btn_L : 1'b0;

    // [Watch 입력] sw[2]가 0일 때만 버튼 허용
    wire w_watch_center_in = (i_sw_watch_stopwatch == 2'b0) ? i_btn_C : 1'b0;
    wire w_watch_left_in   = (i_sw_watch_stopwatch == 2'b0) ? i_btn_L : 1'b0;
    wire w_watch_right_in  = (i_sw_watch_stopwatch == 2'b0) ? i_btn_R : 1'b0;


    
    // 2. 하위 모듈 인스턴스화
    

    // (1) 스톱와치 컨트롤 유닛
    stopwatch_control_unit U_SW_CTRL (
        .clk       (clk),
        .reset     (reset),
        .i_mode    (i_sw_up_down),     // sw[0] 연결
        .i_run_stop(w_sw_run_stop_in), // Gated Button
        .i_clear   (w_sw_clear_in),    // Gated Button
        .o_mode    (o_sw_mode),
        .o_run_stop(o_sw_run_stop),
        .o_clear   (o_sw_clear)
    );

    // (2) 와치 컨트롤 유닛
    watch_control_unit U_WATCH_CTRL (
        .clk         (clk),
        .reset       (reset),
        .i_btn_center(w_watch_center_in), // Gated Button
        .i_btn_left  (w_watch_left_in),   // Gated Button
        .i_btn_right (w_watch_right_in),  // Gated Button
        .o_cursor    (o_w_cursor),
        .o_blink_en  (o_w_blink_en)
    );

endmodule