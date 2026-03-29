`timescale 1ns / 1ps

module gpi (
    input               pclk,
    input               preset,
    input        [31:0] paddr,
    input        [31:0] pwdata,
    input               penable,
    input               pwrite,
    input               psel,
    output logic        pready,
    output logic [31:0] prdata,
    input        [15:0] gpi_in
);

    localparam [11:0] gpi_ctl_addr = 12'h000;
    localparam [11:0] gpi_data_addr = 12'h004;
    logic [15:0] gpi_idata_reg, gpi_ctl_reg;

    assign pready = 1;

    assign prdata=  (paddr[11:0] ==gpi_ctl_addr)  ? {16'd0,gpi_ctl_reg} : 
                    (paddr[11:0] ==gpi_data_addr) ? {16'd0,gpi_idata_reg} : 32'd0;

    always_ff @(posedge pclk, posedge preset) begin
        if (preset) begin
            gpi_idata_reg <= 16'd0;
            gpi_ctl_reg   <= 16'd0;
        end else begin
            gpi_idata_reg <= gpi_in & gpi_ctl_reg;
            if (penable && psel && pwrite) begin
                case (paddr[11:0])
                    gpi_ctl_addr: gpi_ctl_reg <= pwdata[15:0];
                endcase
            end
        end
    end
endmodule
