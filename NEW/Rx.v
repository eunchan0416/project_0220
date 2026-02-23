`timescale 1ns / 1ps

module Rx (
    input        clk,
    input        reset,
    input        i_rx_data,
    input        baud_tick,
    output [7:0] o_rx_data,
    output       o_rx_done
);

    parameter IDLE=2'b00, START = 2'b01, DATA=2'b10, STOP=2'b11;

    reg [1:0] c_state, n_state;

    // bit_counter 
    reg [2:0] c_bit_counter, n_bit_counter;

    // 일단 Buf를 선언했다가 다 0으로 초기화 해두고 
    // Serial Input으로 1 bit씩 변수 받아서 
    // {i_rx_data, buf[7:1]} 이런 식으로 하면 입력 데이터가 serial로 1 bit씩 입력되고
    // 출력은 이거 통째로 출력 변수 쪽도 [7:0]으로 선언해서 다시 만들고.
    reg [7:0] c_rx_buf, n_rx_buf;

    // buffer에 저장된 값을 병렬 출력(PO) 하므로 
    assign o_rx_data = c_rx_buf;

    // Rx의 경우는 done, busy가 필요 없음

    // baud_counter
    // 16배 빨라진 baud_tick 신호 들어오는데 통신 속도는 여전히 9600 bps로 할 것이기 때문에 16카운터 필요함. 
    // 아래의 모든 동작이 tick신호의 16번마다 동작하도록 바꿔줌
    // 그리고 c_baud_cnt == 15 가 되면 카운터 값을 0으로 초기화 해주는 것도 잊지 말고.
    reg [3:0] c_baud_cnt, n_baud_cnt;

    //done 신호
    reg c_done, n_done;
    assign o_rx_done = c_done;


    //SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state       <= IDLE;
            c_bit_counter <= 3'b0;
            // rx는 기본 상태 때 high 상태로 유지할 필요는 없는 거 같음(?)
            c_rx_buf      <= 8'h00;
            c_baud_cnt    <= 4'b0;
            c_done        <= 1'b0;
        end else begin
            c_state       <= n_state;
            c_bit_counter <= n_bit_counter;
            c_rx_buf      <= n_rx_buf;
            c_baud_cnt    <= n_baud_cnt;
            c_done        <= n_done;
        end
    end

    //Next CL
    always @(*) begin
        //full case 처리
        n_state       = c_state;
        n_bit_counter = c_bit_counter;
        n_rx_buf      = c_rx_buf;
        n_baud_cnt    = c_baud_cnt;
        n_done        = c_done;
        case (c_state)
            IDLE: begin
                n_bit_counter = 3'b0;
                n_baud_cnt    = 4'b0;
                n_done        = 1'b0;
                //start상태가 되기 전까지 이전 값들을 그대로 계속 출력하는 게 좋은데 일단 원래 코드가 0으로 초기화하고 있으므로.
                if ((baud_tick) & (!i_rx_data)) begin
                    n_state  = START;
                    n_rx_buf = 8'b0;
                end
            end
            //start uart frame 
            START: begin
                if (baud_tick) begin
                    if (c_baud_cnt == 7) begin
                        // 9600bps에 대한 bit -time을 16구간으로 나눈다면 첫번째 인덱스가 0이라고 했을 때 8번째가 정중앙이고 
                        // 정중앙에 있는 값을 rx가 읽도록 하려면 7까지 세고 바로 다음 tick을 읽으면 됨. 
                        // 이때 counter값을 초기화하고 DATA 상태로 넘어가서 이후 16 카운트 해 가면서 값을 읽는다.
                        n_baud_cnt = 4'b0;
                        n_state = DATA;
                    end else n_baud_cnt = c_baud_cnt + 1;

                end
            end
            DATA: begin
                if (baud_tick) begin
                    // START 상태에서 7카운트 딜레이 시켜서 스테이트로 넘어갔기 때문에 중앙에 정렬되어 있음. 
                    // 이후 16카운트 당 데이터를 읽음.  
                    if (c_baud_cnt == 15) begin
                        n_baud_cnt = 4'b0;
                        n_rx_buf   = {i_rx_data, c_rx_buf[7:1]};
                        if (c_bit_counter == 7) begin
                            n_state = STOP; // 8 bit의 데이터 전송이 끝났으므로..
                        end else begin
                            n_bit_counter = c_bit_counter + 1;
                            n_state = DATA;
                        end
                    end else n_baud_cnt = c_baud_cnt + 1;
                end
            end
            STOP: begin
                if (baud_tick) begin
                    if (c_baud_cnt == 15) begin
                        n_baud_cnt = 4'b0; //여기서 초기화해야하나?ㅣ
                        n_state = IDLE;
                        n_done =1'b1;
                    end else n_baud_cnt = c_baud_cnt + 1;
                end
            end
        endcase
    end


endmodule

