`timescale 1ns / 1ps

module CLK_Divider (
    input      clk,
    input      reset,
    output reg o_1khz
);

    // $clog() 는 필요한 bit수 모를때 자동으로 맞춰는 비바도 테스크 
    //모듈 달라서 counter_4에 있는거하곤 상관 x 
    reg [$clog2(100_000):0] counter_r;  

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r        <= 0;
            o_1khz           <= 1'b0;
        end else begin
            if (counter_r == 99_999) begin
                counter_r    <= 0;
                o_1khz       <= 1'b1;
            end else begin
                counter_r    <= counter_r + 1;
                o_1khz       <= 1'b0;
            end
        end
    end
endmodule
