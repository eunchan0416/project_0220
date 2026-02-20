`timescale 1ns / 1ps

module top_stopwatch_watch (
    input        clk,
    input        reset,
    input  [2:0] sw,
    input        btn_r,      // run_stop
    input        btn_l,      // clear
    input        btn_u,
    input        btn_d,
    input  [3:0] control_in,     
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);
    wire [13:0] w_counter;
    wire w_mode, w_run_stop, w_clear;
    wire w_up_l, w_up_r, w_change;
    wire o_btn_run_stop, o_btn_clear;
    wire [23:0] w_stopwatch_time;
    wire [23:0] w_watch_time;
    wire [23:0] w_fnd_in_data;

    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );
    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(o_btn_clear)
    );
    btn_debounce U_BD_U (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_u),
        .o_btn(o_btn_u)
    );
    btn_debounce U_BD_D (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_d),
        .o_btn(o_btn_d)
    );

    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_sel_mode(sw[1]),
        .i_mode(sw[0]),
        .i_run_stop(o_btn_run_stop || control_in[0] ),
        .i_clear(o_btn_clear || control_in[1]),
        .i_btn_up_l(o_btn_d || control_in[3] ),
        .i_btn_up_r(o_btn_u||  control_in[2]),
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
        .msec(w_stopwatch_time[6:0]),  //7bit
        .sec(w_stopwatch_time[12:7]),
        .min(w_stopwatch_time[18:13]),
        .hour(w_stopwatch_time[23:19])
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
        .sel_display(sw[2]),
        .up_l(w_up_l),  // left time
        .up_r(w_up_r),  // right time
        .change(w_change),  // sw[0] = 1 change
        .msec(w_watch_time[6:0]),
        .sec(w_watch_time[12:7]),
        .min(w_watch_time[18:13]),
        .hour(w_watch_time[23:19])
    );

mux_sel_stopwatch_watch U_SEL_TYPE (
    .stopwatch_time(w_stopwatch_time),
    .watch_time(w_watch_time),
    .sel(sw[1]),
    .fnd_in_data(w_fnd_in_data)
);

    fnd_controller U_FND_CNTL (
        .fnd_in_data(w_fnd_in_data),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data),
        .clk        (clk),
        .reset      (reset),
        .sel_display(sw[2])
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





module mux_sel_stopwatch_watch (
    input [23:0] stopwatch_time,
    input [23:0] watch_time,
    input sel,
    output [23:0] fnd_in_data
);
  assign fnd_in_data = sel ? watch_time : stopwatch_time;
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
