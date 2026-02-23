`timescale 1ns / 1ps

module data_path (
    input clk,
    input reset,
    
    // --- 출력 선택 신호 ---
    input [1:0] i_mode, // 0: watch, 1: stopwatch , 2: sr04, 3: dht11

    // --- 스톱와치용 입력 신호 (From Control Unit) ---
    input i_sw_mode,      // Up/Down Count Mode
    input i_sw_run_stop,  // Run/Stop Signal
    input i_sw_clear,     // Clear Signal

    // --- 와치용 입력 신호 (From Control Unit & Top) ---
    input [2:0] i_w_cursor,     // 커서 위치 (Control Unit에서 옴)
    input i_w_btn_up_level,     // ★ Gated Level Input (Top에서 옴)
    input i_w_btn_down_level,   // ★ Gated Level Input (Top에서 옴)

    //--- 초음파용 입력 신호 (From Control Unit & Top) ---
    input [8:0] i_sr_dist,
    
     //--- 온습도용 입력 신호 (From Control Unit & Top) ---
    input [15:0] i_dht_data,
    // --- 최종 출력 (To FND Controller) ---
    output [31:0] o_fnd_data
  
);


    // 1. 내부 와이어 선언 (각 모듈의 출력을 받을 변수들)
    // 스톱와치 데이터
    
    wire [6:0] sw_msec;
    wire [5:0] sw_sec;
    wire [5:0] sw_min;
    wire [4:0] sw_hour;
    wire [31:0] sw_fnd_data = {{3'b000,sw_hour},{2'b00,sw_min},{2'b00,sw_sec},{1'b0,sw_msec}};
    // 와치 데이터
    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;
    wire [31:0] watch_fnd_data = {{3'b000,w_hour},{2'b00,w_min},{2'b00,w_sec},{1'b0,w_msec}};

    wire [31:0] dht_fnd_data= {i_dht_data[15:0],i_dht_data[15:0]};
// sr04 데이터
 reg [7:0] sr_1000_100;
 reg [7:0] sr_10_1;
 always @(*) begin
    if  (i_sr_dist >= 9'd300 ) begin
        sr_1000_100= 8'd3;
        sr_10_1= i_sr_dist-300;
    end
    else if(i_sr_dist >= 9'd200 ) begin
        sr_1000_100= 8'd2;
        sr_10_1= i_sr_dist-200;
    end
    else if(i_sr_dist >= 9'd100 ) begin
        sr_1000_100= 8'd1;
        sr_10_1= i_sr_dist-100;
    end else begin
         sr_1000_100= 8'd0;
        sr_10_1= i_sr_dist;
    end
 end
    
 wire [31:0] sr_fnd_data = { sr_1000_100,sr_10_1,sr_1000_100,sr_10_1};
    
    
    // 2. 모듈 인스턴스화
    // (1) 스톱와치 데이터패스
    StopWatch_Datapath U_SW_DP (
        .clk       (clk),
        .reset     (reset),
        .i_mode    (i_sw_mode),
        .i_run_stop(i_sw_run_stop),
        .i_clear   (i_sw_clear),
        .o_msec    (sw_msec),
        .o_sec     (sw_sec),
        .o_min     (sw_min),
        .o_hour    (sw_hour)
    );

    // (2) 와치 데이터패스 (내부에 가속기 포함됨)
    Watch_Datapath U_WATCH_DP (
        .clk       (clk),
        .reset     (reset),
        .i_cursor  (i_w_cursor),
        .i_btn_up  (i_w_btn_up_level),   // 꾹 누르는 신호 (Gated) 연결
        .i_btn_down(i_w_btn_down_level), // 꾹 누르는 신호 (Gated) 연결
        .o_hour    (w_hour),
        .o_min     (w_min),
        .o_sec     (w_sec),
        .o_msec    (w_msec)
    );

    // 3. 출력 MUX (화면 표시 데이터 선택)
    // sw[3:2]가 3이면 온습도 데이터, 2이면 초음파 길이, 1이면 스톱와치 데이터, 0이면 와치 데이터를 내보냄
  MUX_4x1 U_MUX_4x1 (
     .sel(i_mode),
     .stopwatch_fnd_data(sw_fnd_data),
     .watch_fnd_data(watch_fnd_data),
     .sr04_fnd_data(sr_fnd_data),
     .dht11_fnd_data(dht_fnd_data),
     .mux_out(o_fnd_data)
);

endmodule