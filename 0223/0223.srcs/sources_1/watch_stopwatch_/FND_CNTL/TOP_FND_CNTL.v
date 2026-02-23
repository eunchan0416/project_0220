`timescale 1ns / 1ps

module FND_CNTL #(
    parameter BIT_WIDTH = 3
) (
    input clk,
    input reset,
    input sel_display,
    input [31:0] i_count,
    input  [3:0]  i_blink_mask, // [추가] 1이면 해당 자리를 강제로 끔
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire [3:0] w_digit_splitter_msec_1, w_digit_splitter_msec_10;
    wire [3:0] w_digit_splitter_sec_1, w_digit_splitter_sec_10;
    wire [3:0] w_digit_splitter_min_1, w_digit_splitter_min_10;
    wire [3:0] w_digit_splitter_hour_1, w_digit_splitter_hour_10;

    wire [3:0] w_mux4to1_hour_min_out, w_mux4to1_sec_msec_out;
    wire [3:0] w_mux_2x1_out;
    wire w_dot_onoff;

    wire [BIT_WIDTH-1:0] w_digit_sel;
    wire w_1KHz_clk;
    wire [3:0] w_fnd_digit_raw;  // 마스킹 전 순수 Digit 신호

    // CLK Divider
    CLK_Divider U_CLK_DIVIDER (
        .clk(clk),
        .reset(reset),
        .o_1khz(w_1KHz_clk)
    );

    // Counter
    Counter #(
        .BIT_WIDTH(3)
    ) U_COUNTER_8 (
        .clk(w_1KHz_clk),
        .reset(reset),
        .digit_sel(w_digit_sel)
    );

    // Decoder (출력을 내부 wire로 받음)
    Decoder2to4 U_Decodeer2to4 (
        .digit_sel (w_digit_sel[1:0]),
        .decoderOut(w_fnd_digit_raw)
    );

    // ★ 핵심 수정: 마스크가 1이면 해당 Anode를 1111(OFF)로 만듦 ★
    // w_digit_sel[1:0]은 현재 켜야 할 자리 번호 (0~3)
    assign fnd_digit = (i_blink_mask[w_digit_sel[1:0]] == 1'b1) ? 4'b1111 : w_fnd_digit_raw;

    // Digit Splitters
    
    Digit_splitter #(
        .BIT_WIDTH(8)
    ) U_DIGIT_SPL_MSEC (
        .in_data (i_count[6:0]),
        .digit_1 (w_digit_splitter_msec_1),
        .digit_10(w_digit_splitter_msec_10)
    );
    Digit_splitter #(
        .BIT_WIDTH(8)
    ) U_DIGIT_SPL_SEC (
        .in_data (i_count[12:7]),
        .digit_1 (w_digit_splitter_sec_1),
        .digit_10(w_digit_splitter_sec_10)
    );
    Digit_splitter #(
        .BIT_WIDTH(8)
    ) U_DIGIT_SPL_MIN (
        .in_data (i_count[18:13]),
        .digit_1 (w_digit_splitter_min_1),
        .digit_10(w_digit_splitter_min_10)
    );
    Digit_splitter #(
        .BIT_WIDTH(8)
    ) U_DIGIT_SPL_HOUR (
        .in_data (i_count[23:19]),
        .digit_1 (w_digit_splitter_hour_1),
        .digit_10(w_digit_splitter_hour_10)
    );
    
    

    // MUXes
    MUX_8x1 U_Mux_SEC_MSEC (
        .sel(w_digit_sel),
        .digit_1(w_digit_splitter_msec_1),
        .digit_10(w_digit_splitter_msec_10),
        .digit_100(w_digit_splitter_sec_1),
        .digit_1000(w_digit_splitter_sec_10),
        .digit_dot_1(4'hf),
        .digit_dot_10(4'hf),
        .digit_dot_100({3'b111, w_dot_onoff}),
        .digit_dot_1000(4'hf),
        .mux_out(w_mux4to1_sec_msec_out)
    );

    MUX_8x1 U_Mux_HOUR_MIN (
        .sel(w_digit_sel),
        .digit_1(w_digit_splitter_min_1),
        .digit_10(w_digit_splitter_min_10),
        .digit_100(w_digit_splitter_hour_1),
        .digit_1000(w_digit_splitter_hour_10),
        .digit_dot_1(4'hf),
        .digit_dot_10(4'hf),
        .digit_dot_100({3'b111, w_dot_onoff}),
        .digit_dot_1000(4'hf),
        .mux_out(w_mux4to1_hour_min_out)
    );

    Mux_2x1 U_MUX_2x1 (
        .sel(sel_display),
        .i_sel0(w_mux4to1_sec_msec_out),
        .i_sel1(w_mux4to1_hour_min_out),
        .o_mux(w_mux_2x1_out)
    );

    dot_onoff_ U_COMP (
        .msec(i_count[6:0]),
        .dot_onoff(w_dot_onoff)
    );

    BCD U_BCD (
        .bcd(w_mux_2x1_out),
        .fnd_data(fnd_data)
    );

endmodule


