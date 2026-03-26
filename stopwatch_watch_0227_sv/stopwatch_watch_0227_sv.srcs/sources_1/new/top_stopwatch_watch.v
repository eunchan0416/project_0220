`timescale 1ns / 1ps

module top_stopwatch_watch (
    input        clk,
    input        reset,
    input  [2:0] sw,
    input        btn_r,      // run_stop
    input        btn_l,      // clear
    output [23:0] watch_time,
    output [23:0] stopwatch_time
);
    wire [13:0] w_counter;
    wire w_mode, w_run_stop, w_clear;
    wire w_up_l, w_up_r, w_change;
    wire o_btn_run_stop, o_btn_clear;
    wire [23:0] w_stopwatch_time;
    wire [23:0] w_watch_time;


    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_sel_mode(sw[1]),
        .i_mode(sw[0]),
        .i_run_stop(btn_r),
        .i_clear(btn_l),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),
        .o_mode(w_mode),
        .o_watch_up_r(w_up_r),
        .o_watch_up_l(w_up_l),
        .o_watch_change(w_change)
    );


    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
        .mode(w_mode),
        .clear(w_clear),
        .run_stop(w_run_stop),
        .msec(stopwatch_time[6:0]),  //7bit
        .sec(stopwatch_time[12:7]),
        .min(stopwatch_time[18:13]),
        .hour(stopwatch_time[23:19])
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
        .sel_display(sw[2]),
        .up_l(w_up_l),  // left time
        .up_r(w_up_r),  // right time
        .change(w_change),  // sw[0] = 1 change
        .msec(watch_time[6:0]),
        .sec(watch_time[12:7]),
        .min(watch_time[18:13]),
        .hour(watch_time[23:19])
    );



endmodule



module stopwatch_datapath (
    input clk,
    input reset,
    input mode,
    input clear,
    input run_stop,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;


    tick_gen_100hz U_TICK (
        .clk(clk),
        .reset(reset),
        .run_stop(run_stop),
        .o_tick_100hz(w_tick_100hz)
    );



    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES(24)
    ) hour_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .mode(mode),
        .run_stop(run_stop),
        .i_tick(w_hour_tick),
        .o_tick(),
        .o_count(hour)
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) min_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .mode(mode),
        .run_stop(run_stop),
        .i_tick(w_min_tick),
        .o_tick(w_hour_tick),
        .o_count(min)

    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) sec_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .mode(mode),
        .run_stop(run_stop),
        .i_tick(w_sec_tick),
        .o_tick(w_min_tick),
        .o_count(sec)

    );


    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES(100)
    ) msec_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .mode(mode),
        .run_stop(run_stop),
        .i_tick(w_tick_100hz),
        .o_tick(w_sec_tick),
        .o_count(msec)

    );


endmodule






module tick_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input clk,
    input reset,
    input i_tick,
    input mode,
    input clear,
    input run_stop,
    output reg o_tick,
    output [BIT_WIDTH-1:0] o_count
);

    //counter reg
    reg [BIT_WIDTH-1 : 0] counter_reg, counter_next;

    assign o_count = counter_reg;

    //state reg
    always @(posedge clk, posedge reset) begin
        if (reset || clear) begin
            counter_reg <= 0;
        end else counter_reg <= counter_next;
    end

    //next counter
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 0;
        if (i_tick && run_stop) begin
            if (mode == 1) begin
                //down
                if (counter_reg == 0) begin
                    o_tick = 1;
                    counter_next = TIMES - 1;
                end else begin
                    counter_next = counter_reg - 1;
                    o_tick = 0;

                end
            end else begin
                //up
                if (counter_reg == (TIMES - 1)) begin
                    o_tick = 1;
                    counter_next = 0;
                end else begin
                    counter_next = counter_reg + 1;
                    o_tick = 0;

                end
            end


        end else begin
            counter_next = counter_reg;
            o_tick = 0;

        end
    end


endmodule
