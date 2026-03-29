`timescale 1ns / 1ps


module APB_SLAVE_RAM (
    input               pclk,
    input               preset,
    input               pwrite,
    input               penable,
    input               psel0,
    input        [31:0] pwdata,
    input        [ 2:0] c2dm_funct3,
    input        [31:0] paddr,
    output logic [31:0] prdata,
    output logic        pready
);

    logic        dwe;
    logic [31:0] daddr;
    logic [31:0] dwdata;
    logic [31:0] drdata;

    assign pready = 1;

    always_comb begin
        daddr = 0;
        dwdata = 0;
        prdata = 0;
        dwe = 0;
        if (psel0) begin
            daddr  = paddr;
            dwdata = pwdata;
            prdata = drdata;
            if (pwrite & penable) begin
                dwe =pwrite ;

            end
        end

    end


    data_mem U_RAM (
        .clk(pclk),
        .rst(preset),
        .dwe(dwe),
        .dwdata(dwdata),
        .c2dm_funct3(),
        .daddr(daddr),
        .drdata(drdata)

    );

endmodule
