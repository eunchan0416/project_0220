`timescale 1ns / 1ps



module fsm_moore (
    input clk,
    input reset,
    input a,
    output reg b
);

    reg [2:0] current_st, next_st;
    parameter s0 = 3'b000, s1 = 3'b001, s2 = 3'b010, s3 = 3'b011, s4 = 3'b100;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= 0;
        end else current_st <= next_st;
    end


    always @(*) begin
        b = 0;
        next_st = current_st;
        case (current_st)
            s0: begin
                b = 0;
                if (a == 0) next_st = s1;
                else next_st = s0;

            end
            s1: begin
                b = 0;
                if (a == 1) next_st = s2;
                else next_st = s1;

            end
            s2: begin
                b = 0;
                if (a == 0) next_st = s3;
                else next_st = s0;

            end
            s3: begin
                b = 0;
                if (a == 1) next_st = s4;
                else next_st = s1;

            end
            s4: begin
                b = 1;
                if (a == 1) next_st = s0;
                else next_st = s1;
            end

            default: begin
                next_st = current_st;
                b = 0;
            end
        endcase
    end


endmodule

module fsm_mealy (
    input  clk,
    input  reset,
    input  a,
    output  b
);

    reg [1:0] current_st, next_st;
    parameter s0 = 2'b00, s1 = 2'b01, s2 = 2'b10, s3 = 2'b11;


 always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= 0;
        end else current_st <= next_st;
    end

always @(*) begin
    next_st= current_st;

    case (current_st)
       s0: begin
                if (a == 0) next_st = s1;
                else next_st = s0;

            end
            s1: begin
                
                if (a == 1) next_st = s2;
                else next_st = s1;

            end
            s2: begin
               
                if (a == 0) next_st = s3;
                else next_st = s0;

            end
            s3: begin
                if (a == 1) next_st = s0;
                else next_st = s1;

            end
            default: begin
                next_st = current_st;
               
            end
    endcase
end

assign b = ( (current_st == s3)&&(a == 1) )? 1 :0;
endmodule
