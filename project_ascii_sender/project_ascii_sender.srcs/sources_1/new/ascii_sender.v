`timescale 1ns / 1ps

module ascii_sender (
    input clk,
    input rst,
    input [31:0] fnd_data,
    input control_in,      // 's' 키 입력 시 1 pulse
    input tx_busy,         // uart_tx 상태
    output reg tx_start,
    output [7:0] tx_data
);

    
    localparam IDLE = 2'd0;
    localparam SEND = 2'd1;
    localparam WAIT = 2'd2;

    reg [1:0] state;
    reg [3:0] buf_fnd_data [0:7]; // 4bit 데이터 8개 저장
    reg [3:0] counter;            // 전송 인덱스 카운터 (0~10)
    
    reg [7:0] ascii_data;         // 변환된 ASCII 값

    
    always @(*) begin
        case(buf_fnd_data[0])
            4'h0: ascii_data = 8'h30;
            4'h1: ascii_data = 8'h31;
            4'h2: ascii_data = 8'h32;
            4'h3: ascii_data = 8'h33;
            4'h4: ascii_data = 8'h34;
            4'h5: ascii_data = 8'h35;
            4'h6: ascii_data = 8'h36;
            4'h7: ascii_data = 8'h37;
            4'h8: ascii_data = 8'h38;
            4'h9: ascii_data = 8'h39;
            default: ascii_data = 8'h20; // 공백 (에러 시)
        endcase
    end

    // 카운터가 2, 5, 8 일 때는 콜론(:)을 전송, 나머지는 숫자 전송
    assign tx_data = (counter == 2 || counter == 5 || counter == 8) ? 8'h3A : ascii_data;

    // ---------------------------------------------------------
    // 2. 메인 상태 머신 (Sequential Logic)
    // ---------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            counter <= 0;
            tx_start <= 0;
        
        end else begin
            case (state)
                IDLE: begin
                    tx_start <= 0;
                    counter <= 0; // 카운터 리셋
                    
                    if (control_in) begin
                      
                        buf_fnd_data[0] <= fnd_data[31:28]; // 시 10
                        buf_fnd_data[1] <= fnd_data[27:24]; // 시 1
                        buf_fnd_data[2] <= fnd_data[23:20]; // 분 10
                        buf_fnd_data[3] <= fnd_data[19:16]; // 분 1
                        buf_fnd_data[4] <= fnd_data[15:12]; // 초 10
                        buf_fnd_data[5] <= fnd_data[11:8];  // 초 1
                        buf_fnd_data[6] <= fnd_data[7:4];   // 밀 10
                        buf_fnd_data[7] <= fnd_data[3:0];   // 밀 1
                        
                        state <= SEND;
                    end
                end

                SEND: begin
                    // UART가 바쁘지 않을 때만 전송 시작
                    if (!tx_busy) begin
                        tx_start <= 1; 
                        state <= WAIT;
                    end
                end

                WAIT: begin
                    tx_start <= 0; // 1클럭 펄스 후 내림
                    
                    
                    if (!tx_busy) begin
                        // 총 11글자 (0~10) 전송 완료 체크
                        if (counter == 10) begin
                            state <= IDLE;
                            counter <= 0;
                        end else begin
                            // 콜론(:)을 보내는 타이밍(2,5,8)에는 버퍼 인덱스를 유지해야 함
                            // 왜냐하면 buf_fnd_data는 8개(숫자)뿐이고, 전송할 문자는 11개(:포함)이기 때문
                            if (counter != 2 && counter != 5 && counter != 8) begin
                                // 시프트 레지스터 방식: 데이터를 한 칸씩 당김
                                // buf[0]은 이미 보냈으므로 버림.
                                buf_fnd_data[0] <= buf_fnd_data[1];
                                buf_fnd_data[1] <= buf_fnd_data[2];
                                buf_fnd_data[2] <= buf_fnd_data[3];
                                buf_fnd_data[3] <= buf_fnd_data[4];
                                buf_fnd_data[4] <= buf_fnd_data[5];
                                buf_fnd_data[5] <= buf_fnd_data[6];
                                buf_fnd_data[6] <= buf_fnd_data[7];
                                buf_fnd_data[7] <= 4'h0; // 빈자리는 0 채움
                            end
                            
                            counter <= counter + 1;
                            state <= SEND; // 다음 글자 전송하러 감
                        end
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule