`timescale 1ns / 1ps

module control_unit (
    input      clk,
    input      reset,
    input      i_mode,
    input      i_run_stop,
    input      i_clear,
    output reg o_run_stop,
    output reg o_clear,
    output     o_mode
);

    assign o_mode = i_mode;
    reg [1:0] current_st, next_st;
    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'B10;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= 0;
        end else current_st <= next_st;
    end


    always @(*) begin
        next_st = current_st;
        o_clear = 0;
        o_run_stop = 0;
        case (current_st)
            STOP: begin
                o_run_stop = 0;
                o_clear = 0;
                if (i_run_stop == 1) begin
                    next_st = RUN;
                end else if (i_clear == 1) next_st = CLEAR;

                else next_st = current_st;

            end
            RUN: begin
                o_run_stop = 1;
                o_clear = 0;
                if (i_run_stop == 1) begin
                    next_st = STOP;
                end else next_st = current_st;

            end
            CLEAR: begin
                o_run_stop = 0;
                o_clear = 1;
                next_st = STOP;

            end
            default: begin
                next_st = current_st;
                o_clear = 0;
                o_run_stop = 0;
            end
        endcase

    end

endmodule
