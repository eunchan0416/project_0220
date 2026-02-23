`timescale 1ns / 1ps

module ascii_decoder (
    input       clk,
    input       reset,
    input       i_rx_done,
    input [7:0] i_rx_data,

    output reg o_btn_L,
    output reg o_btn_R,
    output reg o_btn_C,
    output reg o_btn_U,
    output reg o_btn_D,

    output reg o_sw_0,  // up/down 카운트(스탑와치용)
    output reg o_sw_1,  // 시:분, 초:밀리초
    output reg o_sw_2,  // 시계/스톱워치 모드
    output reg o_sw_3,  // 초음파 센서 모드
    output reg o_sw_4,  // DHT11 센서 모드

    output reg o_send_trig
);

    // 펄스 길이를 늘리기 위한 카운터 파라미터 (100MHz 기준 1ms = 100,000 클럭)
    // 펄스 길이 안 늘리고 그냥 하면 동작을 안함. 
    // 트러블 슈팅 할 부분. 
    parameter PULSE_MAX = 100_000;
    reg [19:0] stretch_cnt;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            o_btn_L <= 0;
            o_btn_R <= 0;
            o_btn_C <= 0;
            o_btn_U <= 0;
            o_btn_D <= 0;
            o_sw_0 <= 0;
            o_sw_1 <= 0;
            o_sw_2 <= 0;
            o_sw_3 <= 0;
            o_sw_4 <= 0;
            o_send_trig <= 0;
            stretch_cnt <= 0;
        end else begin
            // 스위치는 매 클럭마다 무조건 0으로 초기화 (딱 1클럭 펄스만 생성되도록)
            o_sw_0 <= 0;
            o_sw_1 <= 0;
            o_sw_2 <= 0;
            o_sw_3 <= 0;
            o_sw_4 <= 0;

            // 타이머 동작 (push 버튼 전용)
            if (stretch_cnt > 0) begin
                stretch_cnt <= stretch_cnt - 1;
            end else begin
                o_btn_L <= 0;
                o_btn_R <= 0;
                o_btn_C <= 0;
                o_btn_U <= 0;
                o_btn_D <= 0;
                o_send_trig <= 0;
            end

            // 키보드 입력 발생 시
            if (i_rx_done) begin
                case (i_rx_data)
                    // 버튼과 트리거: 카운터를 최대치로 셋팅하여 펄스 길이 연장
                    "l", "L": begin
                        o_btn_L <= 1'b1;
                        stretch_cnt <= PULSE_MAX;
                    end
                    "r", "R": begin
                        o_btn_R <= 1'b1;
                        stretch_cnt <= PULSE_MAX;
                    end
                    "c", "C": begin
                        o_btn_C <= 1'b1;
                        stretch_cnt <= PULSE_MAX;
                    end
                    "u", "U": begin
                        o_btn_U <= 1'b1;
                        stretch_cnt <= PULSE_MAX;
                    end
                    "d", "D": begin
                        o_btn_D <= 1'b1;
                        stretch_cnt <= PULSE_MAX;
                    end
                    "p", "P": begin
                        o_send_trig <= 1'b1;
                        stretch_cnt <= PULSE_MAX;
                    end
                    // 스위치: 상태 반전(~)이 아닌 1'b1 대입 (stretch 미적용)
                    "0": o_sw_0 <= 1'b1;
                    "1": o_sw_1 <= 1'b1;
                    "2": o_sw_2 <= 1'b1;
                    "3": o_sw_3 <= 1'b1;
                    "4": o_sw_4 <= 1'b1;
                endcase
            end
        end
    end
endmodule
