`timescale 1ns / 1ps

module Top_module (
    input        clk,
    input        reset,
    input        btn_L,
    input        btn_R,
    input        btn_C,
    input        btn_U,
    input        btn_D,
    input        i_sr_echo,
    input  [4:0] sw,

    input        i_uart_rx,
    output       o_uart_tx,


    output       o_sr_tirgger,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output [7:0] led,
    inout         dhtio
);
 
                      


    wire w_btn_L, w_btn_R, w_btn_C, w_btn_U, w_btn_D; //물리
    wire w_v_btn_L, w_v_btn_R, w_v_btn_C, w_v_btn_U, w_v_btn_D; // DECODER
    wire w_btn_U_level, w_btn_D_level, w_btn_U_level_gated, w_btn_D_level_gated;
    wire w_sw_run_stop, w_sw_clear, w_sw_mode;
    wire [2:0] w_w_cursor;
    wire w_w_blink_en;
    wire [6:0] w_out_msec;
    wire [5:0] w_out_sec;
    wire [5:0] w_out_min;
    wire [4:0] w_out_hour;
    wire [31:0] w_i_fnd_in_data;
    wire [2:0] w_dht_debug;
    wire w_dht11_valid;
    reg [25:0] blink_cnt;
    wire w_blink_off;
    reg [3:0] w_blink_mask;  // ★ FND에게 보낼 "끄기 명령" 신호
    wire [8:0] w_sr_dist;
    wire [15:0] w_humidity;
    wire [15:0] w_temperature;
    wire [7:0] w_i_rx_data;
    wire w_rx_done;
    wire [7:0] w_i_tx_data;
    //assign led[1:0] = (sw[3] == 0) ? 4'b0001 :  4'b1000; //
    // assign led[3:2] = (sw[3] == 0) ? 4'b0001 :  4'b1000; //
    assign led[6:4] = (w_dht_debug == 0) ? 3'd0 : 
                      (w_dht_debug == 1) ? 3'd1 :
                      (w_dht_debug == 2) ? 3'd2 :
                      (w_dht_debug == 3) ? 3'd3 :
                      (w_dht_debug == 4) ? 3'd4 : 3'd0;

    assign led[7] = w_dht11_valid ? 1:0;

UART_Top_Module U_UART_TOP (
    .clk(clk),
    .reset(reset),
    .i_tx_data(w_i_tx_data),
    .i_tx_start(),
    .i_uart_rx(i_uart_rx),
    
    .o_uart_tx(o_uart_tx),
    .o_rx_data(w_i_rx_data),
    .o_rx_done(w_rx_done),
    .o_tx_busy()
);

control_unit_top U_CONTROL_UNIT_TOP(
   .clk(clk),
   .reset(reset),
   .sw(sw[3:0]), // sw[0] : up,down, sw[1] : hour, sec display, sw[2] : watch,stopwatch, sw[3]: 초음파, 온습도
   .i_btn_L(w_btn_L||w_v_btn_L), 
   .i_btn_R(w_btn_R||w_v_btn_R), 
   .i_btn_C(w_btn_C||w_v_btn_C), 
    //stopwatch_watch
    .o_sw_run_stop(w_sw_run_stop),
    .o_sw_clear(w_sw_clear),
    .o_sw_mode(),        // sw[0] 패스스루
    .o_w_cursor(w_w_cursor), // 0:Idle, 1~4:수정위치
    .o_w_blink_en(),      // 깜빡임 활성화 신호
    //sr04
    .i_sr_start(),
    .i_sr_echo(i_sr_echo),
    .o_sr_trigger(o_sr_tirgger),
    .o_distance(w_sr_dist),
    //dht11
    .start(),
    .humidity(w_humidity),
    .temperature(w_temperature),
    .dht11_done(),
    .dht11_valid(w_dht11_valid),
    .debug(w_dht_debug),
    .dhtio(dhtio)
    );

ascii_sender U_ASCII_SENDER (
    .clk(clk),
    .reset(reset),
    .i_send_trig(),
    .i_fifo_full(),   //  UART 바쁨 대기 -> FIFO Full 체크로 변경

    // 모드 스위치
    .i_sw_dht(sw[3]),
    .i_sw_ultra(sw[3]),
    .i_sw_stw(sw[2]),

    // data_path에서 나온 32비트 (8bit 4개)
    .i_byte3(w_i_fnd_in_data[31:24]),
    .i_byte2(w_i_fnd_in_data[23:16]),
    .i_byte1(w_i_fnd_in_data[15:8]),
    .i_byte0(w_i_fnd_in_data[7:0]),

    .o_push_data(w_i_tx_data),  // FIFO 데이터
    .o_push(),       // FIFO Push 신호
    .o_is_sending()
);

ascii_decoder ASCII_DECODER (
    .clk(clk),
    .reset(reset),
    .i_rx_done(w_rx_done),
    .i_rx_data(w_i_rx_data),

    .o_btn_L(w_v_btn_L),
    .o_btn_R(w_v_btn_R),
    .o_btn_C(w_v_btn_C),
    .o_btn_U(w_v_btn_U),
    .o_btn_D(w_v_btn_D),
    .o_sw_0(),  // up/down 카운트(스탑와치용)
    .o_sw_1(),  // 시:분, 초:밀리초
    .o_sw_2(),  // 시계/스톱워치 모드
    .o_sw_3(),  // 초음파 센서 모드
    .o_sw_4(),  // DHT11 센서 모드
    .o_send_trig()
);




    btn U_BTN (
        .clk(clk),
        .reset(reset),
        .i_btn_L(btn_L),
        .i_btn_R(btn_R),
        .i_btn_C(btn_C),
        .i_btn_U(btn_U),
        .i_btn_D(btn_D),
        .o_btn_L(w_btn_L),
        .o_btn_R(w_btn_R),
        .o_btn_C(w_btn_C),
        .o_btn_U(w_btn_U),
        .o_btn_D(w_btn_D),
        .o_btn_U_level(w_btn_U_level),
        .o_btn_D_level(w_btn_D_level)
    );

    assign w_btn_U_level_gated = (sw[2] == 1'b1) ? 1'b0 : w_btn_U_level;
    assign w_btn_D_level_gated = (sw[2] == 1'b1) ? 1'b0 : w_btn_D_level;

  

    data_path U_TOP_DP (
        .clk(clk),
        .reset(reset),
        .i_mode(sw[2]),
        .i_sw_mode(w_sw_mode),
        .i_sw_run_stop(w_sw_run_stop),
        .i_sw_clear(w_sw_clear),
        .i_w_cursor(w_w_cursor),
        .i_w_btn_up_level(w_btn_U_level_gated),
        .i_w_btn_down_level(w_btn_D_level_gated),
        .i_sr_dist(w_sr_dist),
        .i_dht_data({w_humidity[15:8],w_temperature[15:8]}),
        .o_fnd_data(w_i_fnd_in_data)
    );

    // ★ 데이터는 절대 건드리지 않음 (31/63 문제 해결)
   // assign w_time_data_packed = {w_out_hour, w_out_min, w_out_sec, w_out_msec};

    // 깜빡임 타이머
    always @(posedge clk) blink_cnt <= blink_cnt + 1;
    assign w_blink_off = blink_cnt[25];

    // ★ 마스크 신호 생성 (이걸로 깜빡임을 제어)
    always @(*) begin
        w_blink_mask = 4'b0000;
        if (sw[2] == 1'b0 && w_w_blink_en && w_blink_off) begin
            case (w_w_cursor)
                // 시(Hour) 수정 중일 때 (커서가 1이든 2든) -> 앞의 두 자리(Hour)를 다 끔
                3'd1: w_blink_mask = 4'b1100; // Hour 10, Hour 1 둘 다 Mask
                3'd2: w_blink_mask = 4'b1100; // Hour 10, Hour 1 둘 다 Mask
                // 분(Min) 수정 중일 때 (커서가 3이든 4든) -> 뒤의 두 자리(Min)를 다 끔
                3'd3: w_blink_mask = 4'b0011; // Min 10, Min 1 둘 다 Mask
                3'd4: w_blink_mask = 4'b0011; // Min 10, Min 1 둘 다 Mask
                
                default: w_blink_mask = 4'b0000;
            endcase
        end
    end

    // FND Controller (마스크 입력 포트 연결)
    FND_CNTL #(
        .BIT_WIDTH(3)
    ) U_FND_CNTL (
        .clk(clk),
        .reset(reset),
        .sel_display(sw[1]),
        .i_count(w_i_fnd_in_data),  // 데이터는 원본 그대로!
        .i_blink_mask(w_blink_mask),  // 명령은 따로!
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule
