`timescale 1ns / 1ps


module dot_onoff_ (
    input [6:0] msec,   // 0 ~ 99까지 세는 msec 카운터 값
    output dot_onoff    // 점을 켤지 말지 결정하는 신호
);

    // msec는 0~99까지 돕니다. (100Hz)
    // 50 이상일 때만 점을 켜면, 0.5초 켜지고 0.5초 꺼지는 효과가 납니다.
    assign dot_onoff = (msec >= 50) ? 1'b1 : 1'b0;

endmodule