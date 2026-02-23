`timescale 1ns / 1ps

module fifo #(
    parameter DEPTH = 4,
    parameter BIT_WIDTH = 8
) (
    input        clk,
    input        rst,
    input        push,
    input        pop,
    input  [7:0] push_data,
    output [7:0] pop_data,
    output       full,
    output       empty
);

    wire [$clog2(DEPTH)-1:0] w_wptr, w_rptr;

    register_file #(
        .DEPTH(DEPTH),
        .BIT_WIDTH(BIT_WIDTH)
    ) U_REG_FILE (
        .clk      (clk),
        .push_data(push_data),
        .w_addr   (w_wptr),
        .r_addr   (w_rptr),
        .we       (push & (~full)),
        .pop_data (pop_data)
    );

    fifo_control_unit #(
        .DEPTH(DEPTH)
    ) U_CONTROL_UNIT (
        .clk  (clk),
        .rst  (rst),
        .push (push),
        .pop  (pop),
        .wptr (w_wptr),
        .rptr (w_rptr),
        .full (full),
        .empty(empty)
    );
endmodule


