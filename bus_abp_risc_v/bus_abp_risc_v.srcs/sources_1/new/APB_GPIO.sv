`timescale 1ns / 1ps

module APB_GPIO (
    input               pclk,
    input               preset,
    input        [31:0] paddr,
    input        [31:0] pwdata,
    input               penable,
    input               pwrite,
    input               psel,
    output logic        pready,
    output logic [31:0] prdata,
    inout  logic [15:0] gpio

);
    localparam [11:0] gpio_ctl_addr = 12'h000;
    localparam [11:0] gpio_odata_addr = 12'h004;
    localparam [11:0] gpio_idata_addr = 12'h008;
    logic [15:0] gpio_ctl_reg, gpio_odata_reg, gpio_idata;

    assign pready = (penable & psel) ? 1 : 0;

    assign prdata=  (paddr[11:0] ==gpio_ctl_addr)  ? {16'd0,gpio_ctl_reg} : 
                    (paddr[11:0] ==gpio_odata_addr) ? {16'd0,gpio_odata_reg} : 
                    (paddr[11:0] ==gpio_idata_addr) ? {16'd0,gpio_idata} : 32'dx;

    always_ff @(posedge pclk, posedge preset) begin
        if (preset) begin
            gpio_ctl_reg   <= 16'd0;
            gpio_odata_reg <= 16'd0;
        end else begin
            if (pready && pwrite) begin
                case (paddr[11:0])
                    gpio_ctl_addr:   gpio_ctl_reg <= pwdata[15:0];
                    gpio_odata_addr: gpio_odata_reg <= pwdata[15:0];
                endcase
            end
        end
    end

    GPIO U_GPIO (
        .ctl(gpio_ctl_reg),
        .o_data(gpio_odata_reg),
        .i_data(gpio_idata),
        .gpio(gpio)
    );

endmodule


module GPIO (
    input        [15:0] ctl,
    input        [15:0] o_data,
    output logic [15:0] i_data,
    inout  logic [15:0] gpio
);

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign gpio[i]   = ctl[i] ? o_data[i] : 1'bz;
            assign i_data[i] = ~ctl[i] ? gpio[i] : 1'bz;
        end
    endgenerate

endmodule
