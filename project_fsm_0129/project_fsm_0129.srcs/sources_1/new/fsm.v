`timescale 1ns / 1ps


module fsm (
    input [2:0] sw,
    input clk,
    input reset,
    output reg [1:0] led
);

    reg [1:0] next_state, current_state;
    parameter s0 = 2'b00, s1 = 2'b01, s2 = 2'b10;


    //state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= s0;
        end else begin
            current_state <= next_state;
        end

    end

    always @(*) begin

        next_state = current_state;

        case (current_state)
            s0:
            if (sw == 3'b001) begin
                next_state = s1;
            end else begin
                next_state = current_state;
            end
            s1:
            if (sw == 3'b010) begin
                next_state = s2;
            end else begin
                next_state = current_state;
            end
            s2:
            if (sw == 3'b100) begin
                next_state = s0;
            end else begin
                next_state = current_state;
            end

            default: next_state = current_state;
        endcase
    end


    always @(*) begin
        
        case (current_state)
            s0: led = 2'b00;
            s1: led = 2'b01;
            s2: led = 2'b11;
            default: led = 2'b00;
        endcase
    end


    /*    assign led = (current_state == s0) ? (2'b00 ) 
                : ( (current_state == s1) ? 2'b01 : 2'b11 ) ;

*/

endmodule
