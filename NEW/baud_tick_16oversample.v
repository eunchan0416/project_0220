`timescale 1ns / 1ps

// 9600 bps로 통신하는 UART 
// 9600 Hz 속도의 tick_gen 생성

module baud_tick_16 (
    input      clk,
    input      reset,
    output reg baud_tick
);

    parameter SYS_CLK = 100_000_000; //100MHz
    parameter TARGET_CLK = 9600*16; // 
    parameter FRE_COUNTER = SYS_CLK / TARGET_CLK;  // 10,416/16 =651 번 sys clk의 edge 카운트.

    reg [$clog2(FRE_COUNTER)-1:0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            baud_tick <=0 ;
        end else begin
            if (counter_reg == FRE_COUNTER - 1) begin
                counter_reg <= 0;
                baud_tick   <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                baud_tick <=1'b0;
            end
        end
    end

endmodule
