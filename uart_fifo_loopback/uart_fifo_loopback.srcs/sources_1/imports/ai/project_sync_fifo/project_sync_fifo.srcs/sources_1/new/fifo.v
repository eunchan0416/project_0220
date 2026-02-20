`timescale 1ns / 1ps

module fifo 
 #(parameter DEPTH =4, BIT_WIDTH=8) 
(
    input       clk,
    input       rst,
    input       push,
    input       pop,
    input [7:0] push_data,

    output [7:0] pop_data,
    output       empty,
    output       full

);


wire [$clog2(DEPTH)-1:0] w_wptr, w_rptr;

register_file #( .DEPTH(DEPTH), .BIT_WIDTH(BIT_WIDTH) ) 
U_REG_FILE 
(
    .clk(clk),
    .push_data(push_data),
    .w_addr(w_wptr),
    .we(push & (~full)),
    .r_addr(w_rptr),
    .pop_data(pop_data)
);


control_unit #( .DEPTH(DEPTH))
U_CNT_UNIT
 (
    .clk(clk),
    .rst(rst),
    .push(push),
    .pop(pop),
    .wptr(w_wptr),
    .rptr(w_rptr),
    .full(full),
    .empty(empty)
);
endmodule



module register_file #(
    parameter DEPTH = 4,
    BIT_WIDTH = 8
) (
    input                      clk,
    input  [    BIT_WIDTH-1:0] push_data,
    input  [$clog2(DEPTH)-1:0] w_addr,
    input                      we,
    input  [$clog2(DEPTH)-1:0] r_addr,
    output  [    BIT_WIDTH-1:0] pop_data
);

    reg [BIT_WIDTH-1:0] buffer[0:DEPTH-1];

    always @(posedge clk) begin
        if (we) begin
           buffer[w_addr] <= push_data;
        end 
    end

 assign pop_data = buffer[r_addr];

endmodule


module control_unit #(
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
    reg [$clog2(DEPTH)-1:0] wptr_ct, wptr_nt, rptr_ct, rptr_nt;
    reg full_ct, full_nt, empty_ct, empty_nt;



    assign wptr  = wptr_ct;
    assign rptr  = rptr_ct;
    assign empty = empty_ct;
    assign full  = full_ct;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state  <= 0;
            wptr_ct  <= 0;
            rptr_ct  <= 0;
            full_ct  <= 0;
            empty_ct <= 1;
        end else begin
            c_state  <= n_state;
            wptr_ct  <= wptr_nt;
            rptr_ct  <= rptr_nt;
            full_ct  <= full_nt;
            empty_ct <= empty_nt;
        end
    end

    always @(*) begin
        n_state  = c_state;
        wptr_nt  = wptr_ct;
        rptr_nt  = rptr_ct;
        empty_nt = empty_ct;
        full_nt  = full_ct;


        case ({
            push, pop
        })

            //pop
            2'b01: begin
                
                if(!empty)begin
                full_nt = 0;
                rptr_nt = rptr_ct +1;
                if (rptr_nt == wptr_ct) begin
                    empty_nt = 1;
                end
            end
            end
            
            //push
            2'b10: begin
            if(!full)begin
                     wptr_nt  = wptr_ct+1;
                     empty_nt = 0;
                if (wptr_nt == rptr_ct) begin
                    full_nt = 1;
                end 
            //push&pop
            end
            end
            2'b11: begin
                
                if (full_nt) begin
                    rptr_nt = rptr_ct + 1;
                    full_nt = 0;
                end else if (empty_ct) begin
                    wptr_nt  = wptr_ct + 1;
                    empty_nt = 0;
                end else begin
                    wptr_nt = wptr_ct + 1;
                    rptr_nt = rptr_ct + 1;
                end
            end
        endcase
    end

endmodule
