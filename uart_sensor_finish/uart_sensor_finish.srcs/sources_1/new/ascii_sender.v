`timescale 1ns / 1ps

module ascii_sender (
    input clk,
    input rst,
    input [31:0] fnd_data,
    input control_in,      // 's' 키 입력 시 1 pulse
    
    // [수정됨] 이름과 역할을 FIFO에 맞게 변경
    input fifo_full,       // FIFO 꽉 참 상태 (기존 tx_busy 역할)
    output reg fifo_push,  // FIFO에 넣기 (기존 tx_start 역할)
    output [7:0] tx_data
);

    localparam IDLE = 2'd0;
    localparam SEND = 2'd1;
    // localparam WAIT = 2'd2; // [수정됨] WAIT 상태는 더 이상 필요 없습니다!

    reg [1:0] state;
    reg [3:0] buf_fnd_data [0:7];
    reg [3:0] counter;
    reg [7:0] ascii_data;

    // (기존과 동일한 ASCII 변환 로직 및 콜론 처리)
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
            default: ascii_data = 8'h20;
        endcase
    end

    assign tx_data = (counter == 2 || counter == 5 || counter == 8) ? 8'h3A : ascii_data;

    // ---------------------------------------------------------
    // 2. FIFO 맞춤형 메인 상태 머신
    // ---------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            counter <= 0;
            fifo_push <= 0;
        end else begin
            case (state)
                IDLE: begin
                    fifo_push <= 0;
                    counter <= 0;
                    
                    if (control_in) begin
                        buf_fnd_data[0] <= fnd_data[31:28];
                        buf_fnd_data[1] <= fnd_data[27:24];
                        buf_fnd_data[2] <= fnd_data[23:20];
                        buf_fnd_data[3] <= fnd_data[19:16];
                        buf_fnd_data[4] <= fnd_data[15:12];
                        buf_fnd_data[5] <= fnd_data[11:8]; 
                        buf_fnd_data[6] <= fnd_data[7:4];  
                        buf_fnd_data[7] <= fnd_data[3:0];  
                        
                        state <= SEND;
                    end
                end

                SEND: begin
                    // [수정됨] FIFO가 꽉 차지 않았다면 즉시 연속으로 밀어 넣음
                    if (!fifo_full) begin
                        fifo_push <= 1; // 이번 클럭에 FIFO에 데이터 들어감!

                        // 11글자 다 넣었으면 끝냄
                        if (counter == 10) begin
                            state <= IDLE;
                            counter <= 0; // 다음 펄스를 위해 카운터 초기화는 IDLE에서 보장됨
                        end else begin
                            // 다음 글자 준비
                            if (counter != 2 && counter != 5 && counter != 8) begin
                                buf_fnd_data[0] <= buf_fnd_data[1];
                                buf_fnd_data[1] <= buf_fnd_data[2];
                                buf_fnd_data[2] <= buf_fnd_data[3];
                                buf_fnd_data[3] <= buf_fnd_data[4];
                                buf_fnd_data[4] <= buf_fnd_data[5];
                                buf_fnd_data[5] <= buf_fnd_data[6];
                                buf_fnd_data[6] <= buf_fnd_data[7];
                                buf_fnd_data[7] <= 4'h0;
                            end
                            counter <= counter + 1;
                            // state <= SEND; // 계속 SEND 상태 유지 (다음 클럭에 바로 다음 데이터 push)
                        end
                    end else begin
                        fifo_push <= 0; // 꽉 찼으면 잠시 멈춤
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule