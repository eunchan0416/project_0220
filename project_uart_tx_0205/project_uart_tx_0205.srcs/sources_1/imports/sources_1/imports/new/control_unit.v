`timescale 1ns / 1ps

module control_unit (
    input      clk,
    input      reset,
    input      i_sel_mode,     //sw[1] : 0:stopwatch, 1: watch
    input      i_mode,         //sw[0]
    input      i_run_stop,
    input      i_clear,
    input      i_btn_up_r,
    input      i_btn_up_l,
    output reg o_run_stop,
    output reg o_clear,
    output reg o_mode,
    output reg o_watch_up_r,
    output reg o_watch_up_l,
    output reg o_watch_change
);
    //runstop = up_r, claer = up_l, mode= change

    //stop_watch
    reg [1:0] current_st_stop, next_st_stop;
    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'B10;

    //watch

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st_stop <= 0;
        end else begin
            current_st_stop <= next_st_stop;
        end
    end


    always @(*) begin
        next_st_stop = current_st_stop;
        o_clear = 0;
        o_run_stop = 0;
        o_mode = 0;
        o_watch_change = 0;
        o_watch_up_l = 0;
        o_watch_up_r = 0;
        if (i_sel_mode == 0) begin
            o_mode = i_mode;
            case (current_st_stop)
                STOP: begin
                    o_run_stop = 0;
                    o_clear = 0;
                    if (i_run_stop == 1) begin
                        next_st_stop = RUN;
                    end
                    else if (i_clear == 1) next_st_stop = CLEAR;

                    else next_st_stop = current_st_stop;

                end
                RUN: begin
                    o_run_stop = 1;
                    o_clear = 0;
                    if (i_run_stop == 1) begin
                        next_st_stop = STOP;
                    end else next_st_stop = current_st_stop;

                end
                CLEAR: begin
                    o_run_stop = 0;
                    o_clear = 1;
                    next_st_stop = STOP;

                end
                default: begin
                    next_st_stop = current_st_stop;
                    o_clear = 0;
                    o_run_stop = 0;
                end
            endcase
        end else begin
            o_watch_change = i_mode;
            o_watch_up_l   = i_btn_up_l;
            o_watch_up_r   = i_btn_up_r;
        end
    end



endmodule
