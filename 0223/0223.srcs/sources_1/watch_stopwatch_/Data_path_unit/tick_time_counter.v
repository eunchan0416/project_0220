`timescale 1ns / 1ps

//msec, sec, min, hour tick counter 
module tick_time_counter #(
    parameter TIME = 100,  // 기본 카운트 숫자
    parameter COUNT_BITWIDTH = 7,  // 출력시킬 수 있는 최소 bit수 
    parameter INITIAL_VALUE = 0
) (
    input                           clk,
    input                           reset,
    input                           i_tick,
    input                           i_mode,
    input                           i_run_stop,
    input                           i_clear,
    output                          o_tick,
    output     [COUNT_BITWIDTH-1:0] o_count
);


    reg [COUNT_BITWIDTH-1:0] counter_r, counter_next;
    reg tick_output,wire_tick;
     
    assign o_count = counter_r;
    assign o_tick = tick_output;

    //state sl 
    always @(posedge clk, posedge reset) begin
        if (reset | i_clear) begin
            counter_r <= INITIAL_VALUE;
            tick_output <= 0;
        end else begin
            counter_r <= counter_next;
            tick_output <=wire_tick;
        end
    end

    //next cl 
    always @(*) begin
        counter_next=counter_r ;
        wire_tick = 1'b0;
        if (i_tick & i_run_stop == 1) begin
            if (i_mode == 1) begin
                //down count
                if (counter_next == 0) begin
                    counter_next = TIME - 1;
                    wire_tick = 1'b1;
                end else begin
                    counter_next = counter_next - 1;
                    wire_tick = 1'b0;
                end
            end else begin
                // up count
                if (counter_next == TIME - 1) begin
                    counter_next = 0;
                    wire_tick = 1'b1;
                end else begin
                    counter_next = counter_next + 1;
                    wire_tick = 1'b0;
                end
            end
        end 
    end

endmodule







    /*
    // tick_output 신호를 순차 회로에서 정하는 걸로 바꾼 거 같지만 출력을  조합 논리가 결정함. 딜레이가 존재하여 다음 블록이 클락 edge 순간에 제떄 업데이트 못할 가능성 존재 
    always @(posedge clk, posedge reset) begin
        if (reset|i_clear) begin
            counter_r <= 0;
            tick_output <=0; 
        end else begin
            tick_output <= 1'b0;
            if (i_tick & i_run_stop == 1) begin
                    if (i_mode == 1) begin
                        //down count
                        if (counter_r==0)begin
                            counter_r <= TIME-1;
                            tick_output<=1'b1;
                        end else begin
                            counter_r <= counter_r-1;
                            tick_output<=1'b0;
                        end
                    end else begin
                        // up count
                        if (counter_r == TIME - 1) begin
                            counter_r <= 0;
                            tick_output<=1'b1;
                        end else begin
                            counter_r <= counter_r + 1;
                            tick_output<=1'b0;
                        end
                    end
                
            end else begin

            end


        end
    end
*/


