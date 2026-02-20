`timescale 1ns / 1ps

module fsm (
    input  clk,
    input  reset,
    input  sw,
    output led
);

    parameter s0 = 1'b0, s1 = 1'b1;

    reg next_state, current_state;


    //next state CL
    always @(*) begin
        next_state = current_state;
        case (current_state)
            s0: begin
                if (sw == 1) 
                    next_state = s1;
                
               
            end
            s1: begin
                if (sw == 0) begin
                    next_state = s0;
                end 
            end
            default: next_state= current_state;
        endcase
    end


    //state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= 0;
        end else begin
            current_state <= next_state;
        end
    end


assign led = (current_state == s1) ? 1 : 0 ;

endmodule


