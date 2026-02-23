`timescale 1ns / 1ps

module btn (
    input  clk,
    input  reset,
    
    input  i_btn_L,
    input  i_btn_R,
    input  i_btn_C,
    input  i_btn_U,
    input  i_btn_D,

    // 기존 펄스 출력 (한 번 톡 누를 때)
    output o_btn_L,
    output o_btn_R,
    output o_btn_C,
    output o_btn_U,
    output o_btn_D,

    // 꾹 누르고 있음을 알리는 신호 (Up/Down만) 
    output o_btn_U_level, 
    output o_btn_D_level
);

    btn_debounce U_BTN_L (
        .clk  (clk),
        .reset(reset),
        .i_btn(i_btn_L),
        .o_btn(o_btn_L),
        .o_btn_level() 
    );

    btn_debounce U_BTN_R (
        .clk  (clk),
        .reset(reset),
        .i_btn(i_btn_R),
        .o_btn(o_btn_R),
        .o_btn_level()
    );

    btn_debounce U_BTN_C (
        .clk  (clk),
        .reset(reset),
        .i_btn(i_btn_C),
        .o_btn(o_btn_C),
        .o_btn_level()
    );

    // ★ Up 버튼: 펄스와 레벨 둘 다 연결 ★
    btn_debounce U_BTN_U (
        .clk  (clk),
        .reset(reset),
        .i_btn(i_btn_U),
        .o_btn(o_btn_U),       // 펄스 
        .o_btn_level(o_btn_U_level) // 레벨 
    );

    // ★ Down 버튼: 펄스와 레벨 둘 다 연결 ★
    btn_debounce U_BTN_D (
        .clk  (clk),
        .reset(reset),
        .i_btn(i_btn_D),
        .o_btn(o_btn_D),            // 펄스 (기존)
        .o_btn_level(o_btn_D_level) // 레벨 (추가됨 -> 밖으로 나감)
    );


endmodule