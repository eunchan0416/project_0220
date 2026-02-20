`timescale 1ns / 1ps

module top_sr04(
    input clk,
    input rst,
    input echo,
    input start,
    //input btn_r,
    output trigger,
    output [11:0] dist
    //output [7:0] fnd_data,
    //output [3:0] fnd_digit
    );

//wire [11:0] w_dist;
wire w_tick;
//wire w_btn_r;
   tick_gen U_TICK(
   .clk(clk),
   .rst(rst),
   .tick(w_tick)
    );


    sr04_controller U_SR04(
    .clk(clk),
    .rst(rst),
    .tick(w_tick),
    .start(start),
    .echo(echo),
    .dist(dist),
    .trigger(trigger)
    );

/*
btn_debounce U_BTN(
    .clk(clk),
    .reset(rst),
    .i_btn(btn_r),
    .o_btn(w_btn_r)
);

    
fnd_controller UDT(
     .fnd_in_data(w_dist),
     .clk(clk),
     .reset(rst),
     .fnd_digit(fnd_digit),
     .fnd_data(fnd_data)
);

    */
endmodule
