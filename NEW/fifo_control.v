`timescale 1ns / 1ps

module fifo_control_unit #(
    parameter DEPTH = 4
) (
    input                      clk,
    input                      rst,
    input                      push,
    input                      pop,
    output [$clog2(DEPTH)-1:0] wptr,
    output [$clog2(DEPTH)-1:0] rptr,
    output                     full,
    output                     empty

);

    reg [1:0] c_state, n_state;
    reg [$clog2(DEPTH)-1:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
    reg full_reg, full_next, empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state   <= 2'b00;
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1'b1;
        end else begin
            c_state   <= n_state;
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    //next state, output
    always @(*) begin
        n_state = c_state;
        wptr_next = wptr_reg;
        rptr_next = rptr_reg;
        full_next = full_reg;
        empty_next = empty_reg;
        case ({
            push, pop
        })
            //push ; 쓰기 
            2'b10: begin
                if(!full) begin 
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            //pop ; 읽기
            2'b01: begin
                if(!empty) begin 
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end
                end
            end
            // push, pop 동시조건
            2'b11: begin
                if (full_reg == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty_reg == 1'b1) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end
endmodule
