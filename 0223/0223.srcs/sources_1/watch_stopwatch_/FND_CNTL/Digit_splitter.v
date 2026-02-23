`timescale 1ns / 1ps

module Digit_splitter #(
    parameter BIT_WIDTH = 7
)
(
    input  [BIT_WIDTH-1:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10
);
    
    assign digit_1    = in_data % 10;  // 1의 자리 추출
    assign digit_10   = (in_data / 10) % 10;  // 10의 자리 추출

endmodule