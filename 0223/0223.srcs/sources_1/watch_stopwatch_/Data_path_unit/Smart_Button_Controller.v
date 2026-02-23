// Watch_Datapath.v 파일의 맨 끝부분(endmodule 뒤)에 붙여넣으세요.

`timescale 1ns / 1ps

module Smart_Button_Controller (
    input clk,
    input reset,
    input i_btn_level,     // 꾹 누르고 있는 신호
    output reg o_pulse     // 가속된 펄스 출력
);

    reg [27:0] hold_timer;    // 전체 누른 시간
    reg [24:0] repeat_timer;  // 반복 주기 측정용

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hold_timer <= 0;
            repeat_timer <= 0;
            o_pulse <= 0;
        end else begin
            if (i_btn_level) begin
                // 1. 전체 시간 측정
                if (hold_timer < 300_000_000) 
                    hold_timer <= hold_timer + 1;

                // 2. 가속 로직 (나머지 연산 제거 -> 카운터 리셋 방식)
                
                // [Phase 1] 막 눌렀을 때 (0초)
                if (hold_timer == 0) begin
                    o_pulse <= 1;
                    repeat_timer <= 0;
                end
                
                // [Phase 2] 0.5초 ~ 2초 : 0.2초 주기 (20M)
                else if (hold_timer > 50_000_000 && hold_timer <= 200_000_000) begin
                    if (repeat_timer >= 19_999_999) begin
                        o_pulse <= 1;
                        repeat_timer <= 0;
                    end else begin
                        o_pulse <= 0;
                        repeat_timer <= repeat_timer + 1;
                    end
                end
                
                // [Phase 3] 2초 이후 : 0.05초 주기 (5M)
                else if (hold_timer > 200_000_000) begin
                    if (repeat_timer >= 4_999_999) begin
                        o_pulse <= 1;
                        repeat_timer <= 0;
                    end else begin
                        o_pulse <= 0;
                        repeat_timer <= repeat_timer + 1;
                    end
                end
                
                else begin
                    o_pulse <= 0;
                end

            end else begin
                // 버튼 떼면 초기화
                hold_timer <= 0;
                repeat_timer <= 0;
                o_pulse <= 0;
            end
        end
    end
endmodule