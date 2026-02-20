`timescale 1ns / 1ps

module fsm (
    input        clk,
    input        reset,
    input  [2:0] sw,
    output [2:0] led
);
    reg [2:0] current_led, next_led;
    reg [2:0] cur_st, nex_st;
    parameter s0 = 3'b000, s1 = 3'b001, s2 = 3'b010, s3 = 3'b011, s4 = 3'b100;


    assign led = current_led;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            cur_st <= s0;
            current_led <= 0;
        end else begin
            cur_st <= nex_st;
            current_led <= next_led;
        end
    end


    always @(*) begin
        nex_st   = cur_st;
        next_led = current_led;

        case (cur_st)
            s0: begin
                next_led = 3'b000;
                if (sw == 3'b001) begin
                    nex_st = s1;
                end else if (sw == 3'b010) begin
                    nex_st = s2;
                end else nex_st = cur_st;
            end
            s1: begin
                next_led = 3'b001;
                if (sw == 3'b010) begin
                    nex_st = s2;
                end else nex_st = cur_st;
            end
            s2: begin
                next_led = 3'b010;
                if (sw == 3'b100) begin
                    nex_st = s3;
                end else nex_st = cur_st;

            end
            s3: begin
                next_led = 3'b100;
                if (sw == 3'b011) begin
                    nex_st = s0;
                end else if (sw == 3'b111) begin
                    nex_st = s4;
                end else if (sw == 3'b000) begin
                    nex_st = s0;
                end else nex_st = cur_st;
            end
            s4: begin
                next_led = 3'b111;
                if (sw == 3'b000) begin
                    nex_st = s0;
                end else nex_st = cur_st;
            end
            default: begin
                nex_st = cur_st;
            end
        endcase
    end


    /*  always @(*) begin
        case (cur_st)
            s0: led = 3'b000;
            s1: led = 3'b001;
            s2: led = 3'b010;
            s3: led = 3'b100;
            s4: led = 3'b111;

            default: led = 3'b000;
        endcase
    end
*/
endmodule
