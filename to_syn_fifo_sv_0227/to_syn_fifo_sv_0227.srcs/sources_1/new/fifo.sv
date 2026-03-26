`timescale 1ns / 1ps


module fifo (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] wdata,
    input  logic       we,
    input  logic       re,
    output logic [7:0] rdata,
    output logic       full,
    output logic       empty
);

logic [3:0] waddr, raddr;
register_file U_REG (
    .waddr(waddr),
    .raddr(raddr),
    .we(we & ~full),
    .clk(clk),
    .wdata(wdata),
    .rdata(rdata)
);

control_unit U_CNT (
    .wptr(waddr),
    .rptr(raddr),
    .clk(clk),
    .wdata(wdata),
    .we(we),
    .re(re),
    .rst(rst),
    .full(full),
    .empty(empty)
);


endmodule


module register_file (
    input  logic       clk,
    input  logic [7:0] wdata,
    input  logic       we,
    input  logic [3:0] waddr,
    input  logic [3:0] raddr,
    output logic [7:0] rdata
);

    logic [7:0] ram[0:15];

    always_ff @(posedge clk) begin
        if (we) begin
            ram[waddr] <= wdata;
        end
    end

    assign rdata = ram[raddr];

endmodule




module control_unit (

    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] wdata,
    input  logic       we,
    input  logic       re,
    output logic [3:0] wptr,
    output logic [3:0] rptr,
    output logic       full,
    output logic       empty
);

    logic [3:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
    logic full_reg, full_next, empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1;

        end else begin

            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;

        end

    end


    always_comb begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;

    case({we,re})
    //pop
    2'b01 : begin
            if(!empty_reg) begin
                rptr_next= rptr_reg+1;
                full_next=0;
                if(rptr_next == wptr_reg) begin
                        empty_next = 1;
                end
            end
    end
    //push
    2'b10: begin
            if(!full_reg) begin
                wptr_next= wptr_reg+1;
                empty_next=0;
                if(wptr_next == rptr_reg) begin
                        full_next=1;
                end
            end
    end
    //push&pop
    2'b11 : begin
            if(full_reg) begin
                rptr_next= rptr_reg+1;
                
                full_next=0;
                
            end  else if(empty_reg) begin
                wptr_next= wptr_reg+1;
                empty_next=0;
            end else  begin
                wptr_next= wptr_reg+1;
                rptr_next= rptr_reg+1;
            end
            
            
    end

    /*

    2'b11: begin
            if(!full_reg && !empty_reg) begin
                rptr_next= rptr_reg+1;
                wptr_next= wptr_reg+1;
                full_next=0;
                empty_next=0;
            end  else if( full) begin
                rptr_next= rptr_reg+1;
                full_next=0;
            end else if( empty) begin
                wptr_next= 
            end
            
            if begin


            end
    */
    
    
    endcase







    end



endmodule
