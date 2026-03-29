`timescale 1ns / 1ps

module APB_GPO (
    input               pclk,
    input               preset,
    input        [31:0] paddr,
    input        [31:0] pwdata,
    input               penable,
    input               pwrite,
    input               psel,
    output logic        pready,
    output logic [31:0] prdata,
    output logic [7:0] gpo_out
);

    localparam [11:0] gpo_ctl_addr = 12'h000;
    localparam [11:0] gpo_data_addr = 12'h004;
    logic [7:0] gpo_odata_reg, gpo_ctl_reg;
    genvar i;

    assign pready = 1;

    
    generate
        for (i = 0; i < 8; i++) begin 
            assign gpo_out[i] = gpo_ctl_reg[i] ? gpo_odata_reg[i] : 1'bz;
        end
    endgenerate


    assign prdata=  (paddr[11:0] ==gpo_ctl_addr)  ? {24'd0,gpo_ctl_reg} : 
                    (paddr[11:0] ==gpo_data_addr) ? {24'd0,gpo_odata_reg} : 32'dx;


    always_ff @(posedge pclk, posedge preset) begin
        if (preset) begin
            gpo_odata_reg <= 8'd0;
            gpo_ctl_reg   <= 8'd0;
        end else begin
            if (penable && psel && pwrite) begin
                case (paddr[11:0])
                    gpo_ctl_addr:  gpo_ctl_reg <= pwdata[7:0];
                    gpo_data_addr: gpo_odata_reg <= pwdata[7:0];
                endcase
            end
        end
    end
endmodule
