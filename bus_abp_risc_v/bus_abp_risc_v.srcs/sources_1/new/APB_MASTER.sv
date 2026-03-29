`timescale 1ns / 1ps


module APB_MASTER (
    //bus global signal
    input               pclk,
    input               preset,
    //soc internal signal with cpu
    input        [31:0] addr,
    input        [31:0] wdata,
    input               wreq,     //DWE, apb_wr
    input               rreq,     //apb_re
    output logic        ready,
    output logic [31:0] rdata,
    //output logic        slverr,
    //APB interface signal
    output logic [31:0] paddr,
    output logic [31:0] pwdata,
    output logic        penable,
    output logic        pwrite,
    input        [31:0] prdata0,  //from RAM
    input               pready0,  //from RAM
    input        [31:0] prdata1,  //from GPO
    input               pready1,  //from GPO
    input        [31:0] prdata2,  //from GPI
    input               pready2,  //from GPI
    input        [31:0] prdata3,  //from GPIO
    input               pready3,  //from GPIO
    input               pready4,  //from FND
    input        [31:0] prdata4,  //from FND
    input               pready5,  //from UART
    input        [31:0] prdata5,  //from UART
    output logic        psel0,    //ram
    output logic        psel1,    //gpo
    output logic        psel2,    //gpi
    output logic        psel3,    //gpio
    output logic        psel4,    //fnd
    output logic        psel5     //uart

);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_st;

    apb_st c_st, n_st;

    logic [31:0] paddr_nt;
    logic [31:0] pwdata_nt;
    logic pwrite_nt;
    logic decode_en;
    logic slv_ready;

    assign ready = slv_ready & penable;
    addr_decoder U_ADDR_DECODE (
        .addr(paddr),
        .en(decode_en),
        .psel0(psel0),
        .psel1(psel1),
        .psel2(psel2),
        .psel3(psel3),
        .psel4(psel4),
        .psel5(psel5)

    );


    APB_MUx U_APB_MUX (
        .sel(paddr),
        .prdata0(prdata0),
        .prdata1(prdata1),
        .prdata2(prdata2),
        .prdata3(prdata3),
        .prdata4(prdata4),
        .prdata5(prdata5),
        .pready0(pready0),
        .pready1(pready1),
        .pready2(pready2),
        .pready3(pready3),
        .pready4(pready4),
        .pready5(pready5),
        .rdata(rdata),
        .ready(slv_ready)
    );

    always_ff @(posedge pclk, posedge preset) begin
        if (preset) begin
            c_st   <= IDLE;
            paddr  <= 0;
            pwdata <= 0;
            pwrite <= 0;
        end else begin
            c_st   <= n_st;
            paddr  <= paddr_nt;
            pwdata <= pwdata_nt;
            pwrite <= pwrite_nt;
        end
    end


    always_comb begin
        n_st = c_st;
        decode_en = 0;
        penable = 0;
        paddr_nt = paddr;
        pwdata_nt = pwdata;
        pwrite_nt = pwrite;
        case (c_st)
            IDLE: begin
                decode_en = 0;
                if ((wreq || rreq)) begin
                    n_st = SETUP;
                    paddr_nt = addr;
                    pwdata_nt = wdata;
                    if (wreq) pwrite_nt = 1;
                    else if (rreq) pwrite_nt = 0;
                end
            end
            SETUP: begin
                decode_en = 1;
                penable = 0;
                n_st = ACCESS;
            end
            ACCESS: begin
                decode_en = 1;
                penable   = 1;
                if (slv_ready) begin
                    n_st = IDLE;
                    pwdata_nt = 0;
                    paddr_nt = 0;
                    pwrite_nt = 0;

                end
            end

        endcase

    end


endmodule

module APB_MUx (
    input        [31:0] sel,
    input        [31:0] prdata0,
    input        [31:0] prdata1,
    input        [31:0] prdata2,
    input        [31:0] prdata3,
    input        [31:0] prdata4,
    input        [31:0] prdata5,
    input               pready0,
    input               pready1,
    input               pready2,
    input               pready3,
    input               pready4,
    input               pready5,
    output logic [31:0] rdata,
    output logic        ready
);
    always_comb begin
        rdata = 32'd0;
        ready = 32'd0;

        case (sel[31:28])
            4'h1: begin
                rdata = prdata0;
                ready = pready0;
            end
            4'h2: begin
                case (sel[15:12])
                    4'h0: begin
                        rdata = prdata1;
                        ready = pready1;
                    end
                    4'h1: begin
                        rdata = prdata2;
                        ready = pready2;
                    end
                    4'h2: begin
                        rdata = prdata3;
                        ready = pready3;
                    end
                    4'h3: begin
                        rdata = prdata4;
                        ready = pready4;
                    end
                    4'h4: begin
                        rdata = prdata5;
                        ready = pready5;
                    end
                endcase

            end
        endcase

    end
endmodule


module addr_decoder (
    input               en,
    input        [31:0] addr,
    output logic        psel0,
    output logic        psel1,
    output logic        psel2,
    output logic        psel3,
    output logic        psel4,
    output logic        psel5

);

    always_comb begin
        psel0 = 0;
        psel1 = 0;
        psel2 = 0;
        psel3 = 0;
        psel4 = 0;
        psel5 = 0;
        if (en) begin
            case (addr[31:28])
                4'h1: psel0 = 1;  //RAM
                4'h2: begin

                    case (addr[15:12])
                        4'h0: psel1 = 1;
                        4'h1: psel2 = 1;
                        4'h2: psel3 = 1;
                        4'h3: psel4 = 1;
                        4'h4: psel5 = 1;
                    endcase

                end
            endcase
        end
    end
endmodule
