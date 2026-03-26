`timescale 1ns / 1ps


module fifo (
    input              clk,
    input              rst,
    input  logic [7:0] wdata,
    input  logic       we,
    input  logic       re,
    output logic [7:0] rdata,
    output logic       full,
    output logic       empty
);

    logic [4:0] w_waddr, w_raddr;

    control_unit U_CNT (
        .clk(clk),
        .rst(rst),
        .we(we),
        .re(re),
        .full(full),
        .empty(empty),
        .rptr(w_raddr),
        .wptr(w_waddr)
    );

    register_file U_REG (
        .clk(clk),
        .wdata(wdata),
        .waddr(w_waddr[3:0]),
        .we(we && !full),
        .raddr(w_raddr[3:0]),
        .rdata(rdata)
    );



endmodule





module control_unit (
    input clk,
    input rst,
    input logic we,
    input logic re,
    output logic full,
    output logic empty,
    output logic [4:0] rptr,
    output logic [4:0] wptr
);



    assign full  = (rptr[3:0] == wptr[3:0] && rptr[4] != wptr[4]);
    assign empty = (rptr == wptr);

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            rptr <= 0;
            wptr <= 0;

        end else begin

            if (we & !full) begin
                wptr <= wptr + 1;
            end

            if (re & !empty) begin
                rptr <= rptr + 1;
            end
        end

    end

endmodule


module register_file (
    input clk,
    input logic [7:0] wdata,
    input logic [3:0] waddr,
    input logic we,
    input logic [3:0] raddr,
    output logic [7:0] rdata
);

    logic [7:0] register[0:15];


    assign rdata = register[raddr];


    always_ff @(posedge clk) begin
        if (we) begin
            register[waddr] = wdata;
        end
    end

endmodule


/*


module fifo (
    input              clk,
    input              rst,
    input  logic [7:0] wdata,
    input  logic       we,
    input  logic       re,
    output logic [7:0] rdata,
    output logic       full,
    output logic       empty
);

    logic [4:0] w_waddr, w_raddr;
    logic [7:0] register[0:15];

    assign full  = (rptr[3:0] == wptr[3:0] && rptr[4] != wptr[4]);
    assign empty = (rptr == wptr);
    assign rdata = register[raddr];

 always @(posedge clk, posedge rst) begin
        if (rst) begin
            rptr <= 0;
            wptr <= 0;

        end else begin

            if (we & !full) begin
                wptr <= wptr + 1;
                register[waddr] <= wdata;
            end

            if (re & !empty) begin
                rptr <= rptr + 1;
            end
        end

    end


endmodule


*/