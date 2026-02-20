`timescale 1ns / 1ps


module uart_top (

    input  clk,
    input  rst,
    input  uart_rx,
    output uart_tx

);
    
    
    wire w_b_tick, w_rx_done;
    wire [7:0] w_rx_data, w_rx_popdata, w_tx_popdata;
    wire w_fifo_tx_full;
    wire w_fifo_rx_empty;
    wire w_tx_busy, w_tx_empty;

    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick),
        .tx_start(!w_tx_empty),
        .tx_data(w_tx_popdata),
        .tx_busy(w_tx_busy),
        .tx_done(),
        .uart_tx(uart_tx)
    );


    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );


fifo  U_FIFO_RX 
(
    .clk(clk),
    .rst(rst),
    .push(w_rx_done),
    .pop(!w_fifo_tx_full),
    .push_data(w_rx_data),
    .pop_data(w_rx_popdata),
    .empty(w_fifo_rx_empty),
    .full()

);

fifo  U_FIFO_TX 
(
    .clk(clk),
    .rst(rst),
    .push(!w_fifo_rx_empty),
    .pop(!w_tx_busy),
    .push_data(w_rx_popdata),
    .pop_data(w_tx_popdata),
    .empty(w_tx_empty),
    .full(w_fifo_tx_full)

);

    boud_tick U_boud_tick (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
    );





endmodule



module boud_tick (
    input      clk,
    input      rst,
    output reg b_tick
);
    parameter BAUDRATE = 9600 * 16;  //speed x16
    parameter F_COUNT = (100_000_000 / BAUDRATE);
    reg [$clog2(F_COUNT)-1:0] counter;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter <= 0;
            b_tick  <= 0;
        end else begin
            if (counter == (F_COUNT - 1)) begin
                counter <= 0;
                b_tick  <= 1;
            end else begin
                counter <= counter + 1;
                b_tick  <= 0;
            end
        end
    end

endmodule

module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,
    input        b_tick,    // baud_tickgen 에서 가져온 b_tick
    input  [7:0] tx_data,
    output       uart_tx,
    output       tx_busy,
    output       tx_done
);


    localparam IDLE = 2'd0, START = 2'd1;
    localparam DATA = 2'd2, STOP = 2'd3;

    // state reg
    reg [1:0] c_state, n_state;  //current_state, next_state의 준말
    reg tx_reg, tx_next;
    // feedback 구조를 만들게 하기 위해서 ,순차논리 출력을 위해서 ouput을 SL로 내보내려고
    // 새로 추가된거 bit_cnt, 조합논리에서만 값을 바꾸는 것이기 때문에 같이 feedback구조를 만들어서 하는것이 latch를 줄일수있다.
    // reg [3:0] bit_cnt;
    reg [2:0] bit_cnt_reg, bit_cnt_next;  //8개니까 8비트 선언
    // b_tick_cnt 추가
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;

    reg busy_reg, busy_next, done_reg, done_next;  //feedback구조를 위해 
    // busy와 done을 만드는 이유는 신호를 보내는 중에 누군가가 신호를 바꾸거나 보내면 안되기 때문이다.

    // data_in_buf
    reg [7:0] data_in_buf_reg, data_in_buf_next;
    // buf를 만드는 이유는 안정성을 위해 만든다.


    //reg [3:0] b_tick_counter;  //16tick

    //reg b_tick_15;


    assign uart_tx = tx_reg;
    assign tx_busy = busy_reg;  // 연결
    assign tx_done = done_reg;  // 연결


    // state tegister SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            bit_cnt_reg     <= 1'b0;
            busy_reg        <= 1'b0;
            done_reg        <= 1'b0;
            data_in_buf_reg <= 8'h00;
            b_tick_cnt_reg  <= 4'h0;




        end else begin
            c_state         <= n_state;
            tx_reg          <= tx_next;
            bit_cnt_reg     <= bit_cnt_next;
            busy_reg        <= busy_next;
            done_reg        <= done_next;
            data_in_buf_reg <= data_in_buf_next;
            b_tick_cnt_reg  <= b_tick_cnt_next;



        end

    end

    // next_CL
    always @(*) begin
        n_state = c_state;
        tx_next = tx_reg;
        bit_cnt_next = bit_cnt_reg;
        busy_next = busy_reg;
        done_next = done_reg;
        data_in_buf_next = data_in_buf_reg;
        b_tick_cnt_next = b_tick_cnt_reg;


        case (c_state)
            IDLE: begin
                tx_next         = 1'b1;  // 초기화
                bit_cnt_next    = 1'b0;
                b_tick_cnt_next = 4'h0;
                busy_next       = 0;
                done_next       = 0;


                if (tx_start == 1) begin
                    n_state = START;
                    busy_next = 1'b1;
                    data_in_buf_next = tx_data;


                end  //else n_state = c_state;
            end


            START: begin  // start uart frame of start bit
                tx_next = 1'b0;

                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin
                        n_state = DATA;
                        b_tick_cnt_next = 4'h0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            DATA: begin
                tx_next = data_in_buf_reg[0];                // 언제 shift하나 -> 비트 shift가 증가할때

                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin

                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 4'h0;
                            n_state = STOP;
                        end else begin
                            b_tick_cnt_next = 4'h0;
                            bit_cnt_next = bit_cnt_reg + 1;
                            data_in_buf_next = {1'b0, data_in_buf_reg[7:1]};
                            n_state = DATA;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end



            STOP: begin
                tx_next = 1'b1;

                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin
                        done_next = 1'b1;
                        n_state   = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end

                end
            end


        endcase
    end

endmodule

module uart_rx (
    input clk,
    input rst,
    input rx,
    input b_tick,
    output [7:0] rx_data,
    output rx_done
);

    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_next, bit_cnt_reg;
    reg done_reg, done_next;

    reg [7:0] buf_reg, buf_next;

    assign rx_done = done_reg;
    assign rx_data = buf_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= 0;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg    <= 0;
            done_reg       <= 0;
            buf_reg        <= 0;
        end else begin

            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            done_reg       <= done_next;
            buf_reg        <= buf_next;
        end
    end

    always @(*) begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        done_next       = done_reg;
        buf_next        = buf_reg;


        case (c_state)
            IDLE: begin

                done_next       = 0;
                b_tick_cnt_next = 0;
                bit_cnt_next    = 0;
                if (b_tick && (rx == 0)) begin
                    n_state = START;
                    buf_next = 0;
                    b_tick_cnt_next = 0;
                end
            end
            START: begin

                if (b_tick) begin
                    if (b_tick_cnt_reg == 7) begin
                        n_state = DATA;
                        b_tick_cnt_next = 0;

                    end else b_tick_cnt_next = b_tick_cnt_reg + 1;
                end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        buf_next = {rx, buf_reg[7:1]};
                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;

                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                       
                        end
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1;
                end
            end

            STOP: begin

                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        n_state   = IDLE;
                        done_next = 1;
                        b_tick_cnt_next=0;
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1;
                end
            end
            default: begin
                done_next       = 0;
                b_tick_cnt_next = 0;
                bit_cnt_next    = 0;
                buf_next        = 0;
            end
        endcase

    end

endmodule
