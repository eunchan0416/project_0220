`timescale 1ns / 1ps

module watch_control_unit(
    input clk,
    input reset,
    
    input i_btn_center, // 모드 진입/탈출
    input i_btn_left,   // 커서 왼쪽 이동
    input i_btn_right,  // 커서 오른쪽 이동
    
    output reg [2:0] o_cursor, // 0:평상시, 1:시10, 2:시1, 3:분10, 4:분1
    output o_blink_en          // 1이면 깜빡임 기능 활성화
    );

    // state
    localparam IDLE  = 3'd0; // 평상시. 
    localparam H_10  = 3'd1; // 시 10의 자리 수정
    localparam H_1   = 3'd2; // 시 1의 자리 수정
    localparam M_10  = 3'd3; // 분 10의 자리 수정
    localparam M_1   = 3'd4; // 분 1의 자리 수정

    reg [2:0] current_state, next_state;

    // 설정 모드가 아니면(IDLE) 깜빡임 꺼짐, 그 외엔 켜짐
    assign o_blink_en = (current_state != IDLE); 

    // 1. State Register
    always @(posedge clk or posedge reset) begin
        if(reset) current_state <= IDLE;
        else      current_state <= next_state;
    end

    // 2. Next State Logic
    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: begin
                if(i_btn_center) next_state = H_10; // 설정 진입
            end
            
            H_10: begin
                if(i_btn_center)      next_state = IDLE; // 설정 탈출
                else if(i_btn_right)  next_state = H_1;  // 우측 이동
                else if(i_btn_left)   next_state = M_1;  // 좌측 이동 (Loop)
            end

            H_1: begin
                if(i_btn_center)      next_state = IDLE;
                else if(i_btn_right)  next_state = M_10;
                else if(i_btn_left)   next_state = H_10;
            end

            M_10: begin
                if(i_btn_center)      next_state = IDLE;
                else if(i_btn_right)  next_state = M_1;
                else if(i_btn_left)   next_state = H_1;
            end

            M_1: begin
                if(i_btn_center)      next_state = IDLE;
                else if(i_btn_right)  next_state = H_10; // Loop
                else if(i_btn_left)   next_state = M_10;
            end
            default: next_state = IDLE;
        endcase
    end

    // 3. Output Logic
    always @(*) begin
        o_cursor = current_state;
    end
endmodule