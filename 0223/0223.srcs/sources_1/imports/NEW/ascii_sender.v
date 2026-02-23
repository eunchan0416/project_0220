`timescale 1ns / 1ps

module ascii_sender (
    input clk,
    input reset,
    input i_send_trig,
    input i_fifo_full,   //  UART 바쁨 대기 -> FIFO Full 체크로 변경

    // 모드 스위치
    input i_sw_dht,
    input i_sw_ultra,
    input i_sw_stw,

    // data_path에서 나온 32비트 (8bit 4개)
    input [7:0] i_byte3,
    input [7:0] i_byte2,
    input [7:0] i_byte1,
    input [7:0] i_byte0,

    output reg [7:0] o_push_data,  // FIFO 데이터
    output reg       o_push,       // FIFO Push 신호
    output           o_is_sending
);
    localparam IDLE = 2'b00;
    localparam SEND = 2'b01;
    localparam DONE = 2'b10;

    reg [1:0] state;
    reg [4:0] char_idx;
    reg [4:0] msg_len;

    // 보낼 문자열을 담을 buffer 
    reg [7:0] char_buf [0:15];
    assign o_is_sending = (state != IDLE);
    // 십의 자리 수 분리. 90 넘거나 같으면 9, 90보다 작고 80보다 크거나 같으면 8...
    function [3:0] get_tens;
        input [7:0] bin;
        begin
            if (bin >= 8'd90) get_tens = 4'd9;
            else if (bin >= 8'd80) get_tens = 4'd8;
            else if (bin >= 8'd70) get_tens = 4'd7;
            else if (bin >= 8'd60) get_tens = 4'd6;
            else if (bin >= 8'd50) get_tens = 4'd5;
            else if (bin >= 8'd40) get_tens = 4'd4;
            else if (bin >= 8'd30) get_tens = 4'd3;
            else if (bin >= 8'd20) get_tens = 4'd2;
            else if (bin >= 8'd10) get_tens = 4'd1;
            else get_tens = 4'd0;
        end
    endfunction
    // 일의 자리 수 분리. 90넘으면 90을 빼고, 90보다 작고 80보다 크거나 같으면 80빼고...
    function [3:0] get_ones;
        input [7:0] bin;
        begin
            if (bin >= 8'd90) get_ones = bin - 8'd90;
            else if (bin >= 8'd80) get_ones = bin - 8'd80;
            else if (bin >= 8'd70) get_ones = bin - 8'd70;
            else if (bin >= 8'd60) get_ones = bin - 8'd60;
            else if (bin >= 8'd50) get_ones = bin - 8'd50;
            else if (bin >= 8'd40) get_ones = bin - 8'd40;
            else if (bin >= 8'd30) get_ones = bin - 8'd30;
            else if (bin >= 8'd20) get_ones = bin - 8'd20;
            else if (bin >= 8'd10) get_ones = bin - 8'd10;
            else get_ones = bin[3:0];
        end
    endfunction
    // =========================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            char_idx <= 0;
            msg_len <= 0;
            o_push <= 0;
        end else begin
            case (state)
                IDLE: begin
                    char_idx <= 0;
                    o_push   <= 0;
                    if (i_send_trig) begin
                        if (i_sw_dht) begin
                            // [DHT 모드]
                            char_buf[0] <= "H";
                            char_buf[1] <= "U";
                            char_buf[2] <= "M";
                            char_buf[3] <= ":";
                            char_buf[4] <= 8'h30 + get_tens(i_byte3); // 8'h30 = ascii '0' 
                            char_buf[5] <= 8'h30 + get_ones(i_byte3);
                            char_buf[6] <= " ";
                            char_buf[7] <= "T";
                            char_buf[8] <= "M";
                            char_buf[9] <= "P";
                            char_buf[10] <= ":";
                            char_buf[11] <= 8'h30 + get_tens(i_byte2);
                            char_buf[12] <= 8'h30 + get_ones(i_byte2);
                            char_buf[13] <= 8'h0D; // (8'h0D = CR:Carriage Return.  \r, 커서를 줄의 맨 앞으로)
                            char_buf[14] <= 8'h0A; // (8'h0A = LF:Line Feed. \n, 줄 바꿈)
                            msg_len <= 15;
                            state <= SEND;
                        end else if (i_sw_ultra) begin
                            // 초음파 모드
                            char_buf[0] <= "D";
                            char_buf[1] <= "I";
                            char_buf[2] <= "S";
                            char_buf[3] <= "T";
                            char_buf[4] <= ":";
                            char_buf[5] <= 8'h30 + i_byte3;
                            char_buf[6] <= 8'h30 + get_tens(i_byte2);
                            char_buf[7] <= 8'h30 + get_ones(i_byte2);
                            char_buf[8] <= 8'h0D;
                            char_buf[9] <= 8'h0A;
                            msg_len <= 10;
                            state <= SEND;
                        end else if (i_sw_stw) begin
                            // 스톱워치 모드
                            char_buf[0] <= "S";
                            char_buf[1] <= "T";
                            char_buf[2] <= "W";
                            char_buf[3] <= ":";
                            char_buf[4] <= 8'h30 + get_tens(i_byte2);
                            char_buf[5] <= 8'h30 + get_ones(i_byte2);
                            char_buf[6] <= ":";
                            char_buf[7] <= 8'h30 + get_tens(i_byte1);
                            char_buf[8] <= 8'h30 + get_ones(i_byte1);
                            char_buf[9] <= ":";
                            char_buf[10] <= 8'h30 + get_tens(i_byte0);
                            char_buf[11] <= 8'h30 + get_ones(i_byte0);
                            char_buf[12] <= 8'h0D;
                            char_buf[13] <= 8'h0A;
                            msg_len <= 14;
                            state <= SEND;
                        end else begin
                            // 시계 모드
                            char_buf[0] <= "W";
                            char_buf[1] <= "T";
                            char_buf[2] <= "C";
                            char_buf[3] <= ":";
                            char_buf[4] <= 8'h30 + get_tens(i_byte3);
                            char_buf[5] <= 8'h30 + get_ones(i_byte3);
                            char_buf[6] <= ":";
                            char_buf[7] <= 8'h30 + get_tens(i_byte2);
                            char_buf[8] <= 8'h30 + get_ones(i_byte2);
                            char_buf[9] <= ":";
                            char_buf[10] <= 8'h30 + get_tens(i_byte1);
                            char_buf[11] <= 8'h30 + get_ones(i_byte1);
                            char_buf[12] <= 8'h0D;
                            char_buf[13] <= 8'h0A;
                            msg_len <= 14;
                            state <= SEND;
                        end
                    end
                end

                // FIFO에 빈자리만 있으면 매 클럭마다 데이터 PUSH
                SEND: begin
                    if (!i_fifo_full) begin
                        o_push_data <= char_buf[char_idx];
                        o_push <= 1'b1;
                        if (char_idx == msg_len - 1) begin
                            state <= DONE;
                        end else begin
                            char_idx <= char_idx + 1;
                        end
                    end else begin
                        o_push <= 1'b0;  // FIFO가 꽉 차면 잠시 대기
                    end
                end

                DONE: begin
                    o_push <= 1'b0;
                    state  <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
