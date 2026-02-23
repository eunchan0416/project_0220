`timescale 1ns / 1ps
module stopwatch_control_unit (
    input      clk,
    input      reset,
    input      i_mode,
    input      i_run_stop,
    input      i_clear,

    output     o_mode,
    output reg o_run_stop,
    output reg o_clear
);

    localparam stop = 2'b00, run = 2'b01, clear = 2'b10;
    reg [1:0] current_state, next_state;

    //state register 
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= stop;
        end else begin
            current_state <= next_state;
        end
    end

    //output CL
    always @(*) begin
        //full case처리 해야 함. 
        o_run_stop = 1'b0;
        o_clear    = 1'b0;
        next_state = current_state;
        case (current_state)
            stop: begin
                o_run_stop = 1'b0;
                o_clear = 1'b0;
                if (i_run_stop) begin
                    next_state = run;
                end else if(i_clear) begin // else로 하면 i_run_stop = 0이면 바로 clear가 되어 버림.
                    next_state = clear;
                end
            end
            run: begin
                o_run_stop = 1'b1;
                o_clear = 1'b0;
                if (i_run_stop == 1) begin
                    next_state = stop;
                end
            end
            clear: begin
                o_run_stop = 1'b0;
                o_clear    = 1'b1;
                next_state = stop;
            end
        endcase
    end

    // slide switch 
    assign o_mode = i_mode;
endmodule
