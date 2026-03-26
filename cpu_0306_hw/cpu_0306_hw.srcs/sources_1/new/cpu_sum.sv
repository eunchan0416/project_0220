`timescale 1ns / 1ps

module cpu_sum (
    input clk,
    input rst,
    output logic [7:0] out
);

logic isrcsel,
     sumsrcsel,
     iload,
     sumload,
     outload,
     alusrcsel, 
     ilq10;



control_unit U_CNT (
    .*
);


datapath U_DATA (
  .*

);

endmodule



module control_unit (
    input clk,
    input rst,
    input ilq10,
    output logic isrcsel,
    output logic sumsrcsel,
    output logic iload,
    output logic sumload,
    output logic outload,
    output logic alusrcsel
);

    typedef enum logic [2:0] {
        S0,
        S1,
        S2,
        S3,
        S4,
        S5
    } state_t;



    state_t c_st, n_st;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin

            c_st <= S0;
        end else begin

            c_st <= n_st;
        end

    end


    always_comb begin
        n_st      = c_st;
        isrcsel   = 0;
        sumsrcsel = 0;
        iload     = 0;
        sumload   = 0;
        outload   = 0;
        alusrcsel = 0;

        case (c_st)
            S0: begin
                n_st      = S1;
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 1;
                sumload   = 1;
                outload   = 0;
                alusrcsel = 0;

            end
            S1: begin

                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                outload   = 0;
                alusrcsel = 0;
                if (ilq10 == 1) n_st = S2;
                else n_st = S5;

            end
            S2: begin
                n_st      = S3;
                isrcsel   = 0;
                sumsrcsel = 1;
                iload     = 0;
                sumload   = 1;
                outload   = 0;
                alusrcsel = 0;

            end
            S3: begin
                n_st      = S4;
                isrcsel   = 1;
                sumsrcsel = 0;
                iload     = 1;
                sumload   = 0;
                outload   = 0;
                alusrcsel = 1;

            end
            S4: begin
                n_st      = S1;
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                outload   = 1;
                alusrcsel = 0;

            end
            S5: begin

                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                outload   = 0;
                alusrcsel = 0;

            end

        endcase


    end


endmodule

module datapath (
    input clk,
    input rst,
    input isrcsel,
    input sumsrcsel,
    input iload,
    input sumload,
    input outload,
    input alusrcsel,
    output ilq10,
    output [7:0] out

);

    logic [7:0]
        ireg_src_data,
        sumreg_src_data,
        ireg_out,
        sumreg_out,
        alu_src_data,
        alu_out;

    

    mux_2x1 U_IREG_SRC_MUX (
        .a(0),
        .b(alu_out),
        .sel(isrcsel),
        .mux_out(ireg_src_data)
    );

    register U_IREG (
        .clk(clk),
        .rst(rst),
        .load(iload),
        .in_data(ireg_src_data),
        .out_data(ireg_out)
    );

    lqt10 U_LQT10(
    .in_data(ireg_out),
    .ilq10(ilq10)
);

    mux_2x1 U_SUMREG_SRC_MUX (
        .a(0),
        .b(alu_out),
        .sel(sumsrcsel),
        .mux_out(sumreg_src_data)
    );

    register U_SUMREG (
        .clk(clk),
        .rst(rst),
        .load(sumload),
        .in_data(sumreg_src_data),
        .out_data(sumreg_out)
    );


    alu U_ALU (
        .a(ireg_out),
        .b(alu_src_data),
        .alu_out(alu_out)
    );

    mux_2x1 U_ALU_SRC_MUX (
        .a(sumreg_out),
        .b(1),
        .sel(alusrcsel),
        .mux_out(alu_src_data)
    );

    register U_OUTREG (
        .clk(clk),
        .rst(rst),
        .load(outload),
        .in_data(sumreg_out),
        .out_data(out)
    );



endmodule





module register (
    input              clk,
    input              rst,
    input              load,
    input        [7:0] in_data,
    output logic [7:0] out_data
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            out_data <= 0;
        end else begin

            if (load) begin
                out_data <= in_data;
            end

        end

    end


endmodule


module alu (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
);

    assign alu_out = a + b;

endmodule



module mux_2x1 (
    input  [7:0] a,       //sel 0
    input  [7:0] b,       // sel 1
    input        sel,
    output [7:0] mux_out
);

    assign mux_out = sel ? b : a;

endmodule

module lqt10 (
    input [7:0] in_data,
    output ilq10
);

    assign ilq10 = in_data < 11;

endmodule
