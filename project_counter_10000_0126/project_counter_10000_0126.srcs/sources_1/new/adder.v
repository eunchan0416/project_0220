`timescale 1ns / 1ps

module top (

    input        clk,
    input        reset,
    input        sw,
    input        btn_r,      // run_stop
    input        btn_l,      // clear
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire [13:0] w_counter;
    wire w_tick;
    wire w_mode, w_run_stop, w_clear;
    wire o_btn_run_stop, o_btn_clear;

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


    fnd_controller U_FND_CNTL (
        .fnd_in_data(w_counter),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data),
        .clk        (clk),
        .reset      (reset)
    );

    counter_10000 U_COUNTER_10000 (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick),
        .clear(w_clear),
        .mode(w_mode),
        .runstop(w_run_stop),
        .counter(w_counter)
    );

    tick_gen_10hz U_TICK (
        .clk(clk),
        .reset(reset),
        .run_stop(w_run_stop),
        .o_tick_10hz(w_tick)
    );


    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_mode(sw),
        .i_run_stop(o_btn_run_stop),
        .i_clear(o_btn_clear),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),
        .o_mode(w_mode)
    );

endmodule


module counter_10000 (
    input         clk,
    input         reset,
    input         i_tick,
    input         mode,
    input         clear,
    input         runstop,
    output [13:0] counter
);
    reg [13:0] r_counter;

    assign counter = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset || clear) begin
            r_counter <= 0;
        end else begin
            if (runstop) begin
                if (mode) begin
                    if (i_tick) begin
                        if (r_counter == 0) r_counter <= 9999;
                        else r_counter <= r_counter - 1;
                    end
                end else begin
                    if (i_tick) begin
                        if (r_counter == 9999) r_counter <= 0;
                        else r_counter <= r_counter + 1;
                    end
                end
            end
        end
    end
endmodule


module tick_gen_10hz (
    input clk,
    input reset,
    input run_stop,
    output reg o_tick_10hz
);

    reg [$clog2(10_000_000)-1:0] r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter   <= 0;
            o_tick_10hz <= 0;
        end else begin
            if (run_stop) begin
                if (r_counter == (10_000_000 - 1)) begin
                    r_counter   <= 0;
                    o_tick_10hz <= 1;
                end else begin
                    o_tick_10hz <= 0;
                    r_counter   <= r_counter + 1;

                end

            end
        end

    end


endmodule
