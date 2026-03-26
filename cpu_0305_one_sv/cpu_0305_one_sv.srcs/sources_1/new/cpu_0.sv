`timescale 1ns / 1ps


module cpu_0 (
    input        clk,
    input        rst,
    output [7:0] out
);
    logic asrcsel, aload, alt10, outsel;

    control_unit U_CONTROL_UNIT (.*);

    datapath U_DATAPATH (.*);


endmodule


module control_unit (
    input        clk,
    input        rst,
    input        alt10,
    output logic asrcsel,
    output logic aload,
    output logic outsel
);

    typedef enum logic [2:0] {
        S0 = 0,
        S1 = 1,
        S2 = 2,
        S3 = 3,
        S4 = 4
    } state_t;

    state_t n_st, c_st;



    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_st <= S0;

        end else begin
            c_st <= n_st;

        end

    end


    always_comb begin
        n_st = c_st;
        asrcsel = 0;
        aload = 0;
        outsel = 0;
        case (c_st)
            S0: begin
                asrcsel = 0;
                aload = 0;
                outsel = 0;
                n_st = S1;
            end
            S1: begin
                asrcsel = 0;
                aload   = 0;
                outsel  = 0;

                if (alt10) begin
                    n_st = S2;
                end else begin
                    n_st = S4;
                end
            end
            S2: begin
                asrcsel = 0;
                aload = 0;
                outsel = 0;
                n_st = S3;
            end
            S3: begin
                n_st = S1;
                asrcsel = 1;
                aload = 1;
                outsel = 0;
            end
            S4: begin
                outsel  = 1;
                asrcsel = 0;
                aload   = 0;
            end


        endcase



    end



endmodule


module datapath (
    input              clk,
    input              rst,
    input              asrcsel,
    input              aload,
    input              outsel,
    output logic [7:0] out,
    output logic       alt10
);

    logic [7:0]
        w_a_aluout,
        w_a_muxout,
        w_a_regout,
        w_sum_aluout,
        w_sum_regout,
        w_sum_muxout;

    assign out = outsel ? w_sum_regout : 8'hz;



    mux_2x1 U_ASRC_MUX (
        .a(0),
        .b(w_a_aluout),
        .asrcsel(asrcsel),
        .mux_out(w_a_muxout)
    );

    mux_2x1 U_ASRC_SUM_MUX (
        .a(0),
        .b(w_sum_aluout),
        .asrcsel(asrcsel),
        .mux_out(w_sum_muxout)
    );

    areg U_AREG (
        .clk(clk),
        .rst(rst),
        .aload(aload),
        .reg_in(w_a_muxout),
        .reg_out(w_a_regout)
    );

    areg U_SUMREG (
        .clk(clk),
        .rst(rst),
        .aload(aload),
        .reg_in(w_sum_muxout),
        .reg_out(w_sum_regout)
    );

    alu U_ALU_A (
        .a(w_a_regout),
        .b(1),
        .alu_out(w_a_aluout)
    );

    alu U_ALU_SUM (
        .a(w_sum_regout),
        .b(w_a_regout),
        .alu_out(w_sum_aluout)
    );


    alt10_comp U_ALT (
        .in_data(w_a_regout),
        .alt10  (alt10)
    );

endmodule





module areg (
    input        clk,
    input        rst,
    input        aload,
    input  [7:0] reg_in,
    output [7:0] reg_out
);

    logic [7:0] a_reg;
    assign reg_out = a_reg;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            a_reg <= 0;
        end else begin
            if (aload == 1) begin
                a_reg <= reg_in;
            end
        end
    end
endmodule


module alu (
    input        [7:0] a,
    input        [7:0] b,
    output logic [7:0] alu_out
);

    assign alu_out = a + b;
endmodule

module mux_2x1 (
    input  [7:0] a,
    input  [7:0] b,
    input        asrcsel,
    output [7:0] mux_out
);

    assign mux_out = asrcsel ? b : a;

endmodule


module alt10_comp (
    input  [7:0] in_data,
    output       alt10
);
    assign alt10 = in_data < 11;
endmodule
