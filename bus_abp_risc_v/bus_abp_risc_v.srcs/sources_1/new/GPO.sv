`timescale 1ns / 1ps


module GPO (
    input               pclk,
    input               preset,
    input        [31:0] paddr,
    input        [31:0] pwdata,
    input               penable,
    input               pwrite,
    input               psel,
    output logic        pready,
    //led
    output logic [15:0] oled
);

    logic we0, we1;
    logic [15:0] oreg_data;
    logic [15:0] ctl_reg_data;
    assign pready = 1;
    assign oled   = ctl_reg_data[0] ? oreg_data : 16'dz;
   
    always_comb begin
        we0 = 0;
        we1 = 0;
        if (psel && penable && pwrite) begin
            case (paddr[11:0])
                12'h000: we0 = 1;
                12'h004: we1 = 1;
            endcase

        end
    end

    oreg U_ODATA_REG (
        .*,
        .wdata(pwdata[15:0]),
        .we(we1),
        .odata(oreg_data)
    );


    oreg U_CTL_REG (
        .*,
        .wdata(pwdata[15:0]),
        .we(we0),
        .odata(ctl_reg_data)
    );
endmodule

module oreg (
    input pclk,
    input [15:0] wdata,
    input preset,
    input we,
    output logic [15:0] odata

);

    always_ff @(posedge pclk, posedge preset) begin
        if (preset) odata <= 16'd0;
        else begin
            if (we) odata <= wdata;
        end
    end

endmodule



