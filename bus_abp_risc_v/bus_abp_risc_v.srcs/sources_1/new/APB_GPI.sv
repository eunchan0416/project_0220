`timescale 1ns / 1ps



module APB_GPI (
    input               pclk,
    input               preset,
    input        [31:0] paddr,
    input        [31:0] pwdata,
    input               penable,
    input               pwrite,
    input               psel,
    output logic        pready,
    output logic [31:0] prdata,
    input        [7:0] gpi
);


    localparam [11:0] gpi_ctl_addr = 12'h000;
    localparam [11:0] gpi_idata_addr = 12'h004;
    logic [7:0] gpi_idata, gpi_ctl_reg;
    
    genvar i;
    generate
        for (i = 0; i < 8; i++) begin
            assign gpi_idata[i] = gpi_ctl_reg[i] ? gpi[i] : 1'bz;
        end
    endgenerate

    assign pready = (penable && psel) ? 1 : 0;

    assign prdata=  (paddr[11:0] ==gpi_ctl_addr)  ? {24'd0,gpi_ctl_reg} : 
                    (paddr[11:0] ==gpi_idata_addr) ? {24'd0,gpi_idata} : 32'dx;



    always_ff @(posedge pclk, posedge preset) begin
        if (preset) begin
            gpi_ctl_reg <= 8'd0;
        end else begin
            if (pready && pwrite) begin
                case (paddr[11:0])
                    gpi_ctl_addr: gpi_ctl_reg <= pwdata[7:0];

                endcase
            end
        end
    end
endmodule
