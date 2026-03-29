`timescale 1ns / 1ps



module APB_FND(
    input  logic        pclk,
    input  logic        preset,
    input  logic [31:0] paddr,
    input  logic [31:0] pwdata,
    input  logic        pwrite,
    input  logic        penable,
    input  logic        psel,
    output logic [31:0] prdata,
    output logic        pready,

    output logic [ 3:0] fnd_digit,
    output logic [ 7:0] fnd_data
);

    localparam [11:0] fnd_odata_addr = 12'h000;
    logic [13:0] fnd_odata_reg;
    
    assign pready = 1'b1;
    
    assign prdata = (paddr[11:0] == fnd_odata_addr) ? {18'd0, fnd_odata_reg} : 32'd0;

    // APB Write
    always_ff @(posedge pclk or posedge preset) begin
        if (preset) begin
            fnd_odata_reg <= 13'd0; 
        end else begin
            if (penable && psel && pwrite) begin
                if (paddr[11:0] == fnd_odata_addr) begin
                    fnd_odata_reg <= pwdata[13:0];
                end
            end
        end
    end         

    fnd_controller U_FND(
        .clk       (pclk),
        .reset     (preset),
        .sum       (fnd_odata_reg), 
        .fnd_digit (fnd_digit),
        .fnd_data  (fnd_data)
    );

endmodule


module fnd_controller (
    input  logic        clk,
    input  logic        reset,
    input  logic [13:0] sum,
    output logic [ 3:0] fnd_digit,
    output logic [ 7:0] fnd_data
);
    logic [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_mux_4x1_out;
    logic [1:0] w_digital_sel;
    logic       w_1khz;

    digit_splitter U_DIGIT_SPL (
        .in_data   (sum),
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000)
    );

    clk_div U_CLK_DIV (
        .clk   (clk),
        .reset (reset),
        .o_1khz(w_1khz)
    );

    counter_4 U_COUNTER_4 (
        .clk      (clk),         
        .reset    (reset),
        .en       (w_1khz),      
        .digit_sel(w_digital_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .digit_sel(w_digital_sel),
        .fnd_digit(fnd_digit)
    );

    MUX_4x1 U_MUX_4x1 (
        .sel      (w_digital_sel),
        .digit_1  (w_digit_1),
        .digit_10 (w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .mux_out  (w_mux_4x1_out)
    );

    bcd U_BCD (
        .bcd     (w_mux_4x1_out),
        .fnd_data(fnd_data)
    );

endmodule



module clk_div (
    input  logic clk,
    input  logic reset,
    output logic o_1khz
);
    logic [$clog2(100_000)-1:0] counter_r;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_r <= 0;
            o_1khz    <= 1'b0;
        end else begin
            if (counter_r == 100_000 - 1) begin
                counter_r <= 0;
                o_1khz    <= 1'b1;
            end else begin
                counter_r <= counter_r + 1;
                o_1khz    <= 1'b0;
            end
        end
    end
endmodule



module counter_4 (
    input  logic       clk,
    input  logic       reset,
    input  logic       en,
    output logic [1:0] digit_sel
);
    logic [1:0] counter_r;
    assign digit_sel = counter_r;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) counter_r <= 0;
        else if (en) counter_r <= counter_r + 1;
    end
endmodule



module decoder_2x4 (
    input  logic [1:0] digit_sel,
    output logic [3:0] fnd_digit
);
    always_comb begin
        case (digit_sel)
            2'b00: fnd_digit = 4'b1110;
            2'b01: fnd_digit = 4'b1101;
            2'b10: fnd_digit = 4'b1011;
            2'b11: fnd_digit = 4'b0111;
            default: fnd_digit = 4'b1111;
        endcase
    end
endmodule



module MUX_4x1 (
    input  logic [1:0] sel,
    input  logic [3:0] digit_1,
    input  logic [3:0] digit_10,
    input  logic [3:0] digit_100,
    input  logic [3:0] digit_1000,
    output logic [3:0] mux_out
);
    always_comb begin
        case (sel)
            2'b00: mux_out = digit_1;
            2'b01: mux_out = digit_10;
            2'b10: mux_out = digit_100;
            2'b11: mux_out = digit_1000;
            default: mux_out = 4'b0000;
        endcase
    end
endmodule



module digit_splitter (
    input  logic [13:0] in_data,
    output logic [3:0]  digit_1,
    output logic [3:0]  digit_10,
    output logic [3:0]  digit_100,
    output logic [3:0]  digit_1000
);
    assign digit_1    = (in_data % 10);
    assign digit_10   = (in_data / 10) % 10;
    assign digit_100  = (in_data / 100) % 10;
    assign digit_1000 = (in_data / 1000) % 10;
endmodule


module bcd (
    input  logic [3:0] bcd,
    output logic [7:0] fnd_data
);
    always_comb begin
        case (bcd)
            4'd0: fnd_data = 8'hc0;
            4'd1: fnd_data = 8'hf9;
            4'd2: fnd_data = 8'ha4;
            4'd3: fnd_data = 8'hb0;
            4'd4: fnd_data = 8'h99;
            4'd5: fnd_data = 8'h92;
            4'd6: fnd_data = 8'h82;
            4'd7: fnd_data = 8'hf8;
            4'd8: fnd_data = 8'h80;
            4'd9: fnd_data = 8'h90;
            default: fnd_data = 8'hFF;
        endcase
    end
endmodule