`timescale 1ns / 1ps

module watch_datapath (
    input        clk,
    input        reset,
    input        sel_display,
    input        up_l,         // left time
    input        up_r,         // right time
    input        change,       // sw[0] = 1 change, sw[0] =0 ongoing
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;
    tick_gen_100hz U_TICK (
        .clk(clk),
        .reset(reset),
        .run_stop(!change),
        .o_tick_100hz(w_tick_100hz)
    );
    tick_counter_watch #(
        .BIT_WIDTH(5),
        .TIMES(24),
        .FIRST(12)
    ) hour_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_hour_tick),
        .change(change & sel_display),
        .up_r(1'b0),
        .up_l(up_l),
        .o_tick(),
        .o_count(hour)
    );
    tick_counter_watch #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .FIRST(0)
    ) min_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_min_tick),
        .change(change & sel_display),
        .up_r(up_r),
        .up_l(0),
        .o_tick(w_hour_tick),
        .o_count(min)
    );
    tick_counter_watch #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .FIRST(0)
    ) sec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_sec_tick),
        .change(change & !sel_display),
        .up_l(up_l),
        .up_r(1'b0),
        .o_tick(w_min_tick),
        .o_count(sec)
    );
    tick_counter_watch #(
        .BIT_WIDTH(7),
        .TIMES(100),
        .FIRST(0)
    ) msec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        .change(change & !sel_display),
        .up_r(up_r),
        .up_l(1'b0),
        .o_tick(w_sec_tick),
        .o_count(msec)
    );
endmodule

module tick_counter_watch #(
    parameter BIT_WIDTH = 7,
    TIMES = 100,
    FIRST = 12
) (
    input clk,
    input reset,
    input i_tick,
    input change,
    input up_l,
    input up_r,
    output reg o_tick,
    output [BIT_WIDTH-1:0] o_count
);

    //counter reg
    reg [BIT_WIDTH-1 : 0] counter_reg, counter_next;

    assign o_count = counter_reg;

    //state reg
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= FIRST;
        end else counter_reg <= counter_next;
    end



    //next counter
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 0;
        if ((i_tick && !change) || (change && (up_l || up_r))) begin
            //up ongoing
            if (counter_reg == (TIMES - 1)) begin
                o_tick = 1;
                counter_next = 0;
            end else begin
                counter_next = counter_reg + 1;
                o_tick = 0;

            end
        end else begin
            counter_next = counter_reg;
            o_tick = 0;

        end

    end

endmodule


