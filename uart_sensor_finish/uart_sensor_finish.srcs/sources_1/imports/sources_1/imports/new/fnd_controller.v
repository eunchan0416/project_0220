`timescale 1ns / 1ps

module fnd_controller (
    input [23:0] fnd_in_data,
    input clk,
    input reset,
    input sel_display,
    input [1:0] sel_mode,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output [31:0] now_fnd_data
);
    wire [2:0] w_digit_sel;
    wire [3:0] w_digit_msec_1, w_digit_msec_10;
    wire [3:0] w_digit_sec_1, w_digit_sec_10;
    wire [3:0] w_digit_min_1, w_digit_min_10;
    wire [3:0] w_digit_hour_1, w_digit_hour_10;
    wire [3:0] w_mux_hour_min_out, w_mux_sec_msec_out;
    wire [3:0] w_mux_2x1_out;
    
    wire [3:0] w_sr_digit_1;
    wire [3:0] w_sr_digit_10;
    wire [3:0] w_sr_digit_100;
    wire [3:0] w_sr_digit_1000;
    wire [3:0] w_mux_out_sr;
    wire [3:0] w_dht_digit_1;
    wire [3:0] w_dht_digit_10;
    wire [3:0] w_dht_digit_100;
    wire [3:0] w_dht_digit_1000;
     wire [3:0] w_mux_out_dht;
 wire [3:0] w_mux_out_mode;

    wire [3:0] w_mux_out;
    wire w_1kz;
    wire w_dot_on_off;
wire [3:0] w_dot_code;
    assign w_dot_code = w_dot_on_off ? 4'd14 : 4'd15;
assign now_fnd_data = {w_digit_hour_10,w_digit_hour_1 ,w_digit_min_10 , w_digit_min_1,w_digit_sec_10, w_digit_sec_1,w_digit_msec_10,w_digit_msec_1};
    clk_div U_CLK_DIV (
        .clk(clk),
        .reset(reset),
        .o_1khz(w_1kz)
    );

    dot_onoff U_DOT_COMP (
        .msec(fnd_in_data[6:0]),
        .dot_onoff(w_dot_on_off)
    );
    counter_8 U_COUNTER_8 (
        .clk(w_1kz),
        .reset(reset),
        .digit_sel(w_digit_sel)
    );

    decoder_2_4 U_DECODER_2_4 (
        .btn(w_digit_sel[1:0]),
        .fnd_digit(fnd_digit)
    );

    mux8_1 U_MUX_SEC_MSEC (
        .digit_1(w_digit_msec_1),
        .digit_10(w_digit_msec_10),
        .digit_100(w_digit_sec_1),
        .digit_1000(w_digit_sec_10),
        .digit_dot_1(4'hf),
        .digit_dot_10(4'hf),
        .digit_dot_100(w_dot_code),
        .digit_dot_1000(4'hf),
        .sel(w_digit_sel),
        .mux_out(w_mux_sec_msec_out)
    );

    mux8_1 U_MUX_HOUR_MIN (
        .digit_1(w_digit_min_1),
        .digit_10(w_digit_min_10),
        .digit_100(w_digit_hour_1),
        .digit_1000(w_digit_hour_10),
        .digit_dot_1(4'hf),
        .digit_dot_10(4'hf),
        .digit_dot_100(w_dot_code),
        .digit_dot_1000(4'hf),
        .sel(w_digit_sel),
        .mux_out(w_mux_hour_min_out)
    );

    mux_2_1 U_MUX_2X1 (
        .sel(sel_display),
        .i_sel0(w_mux_sec_msec_out),
        .i_sel1(w_mux_hour_min_out),
        .o_mux(w_mux_2x1_out)
    );
    
    //dht
    digit_splitter_dht U_DHT (
        .in_data(fnd_in_data[15:0]),
        .digit_1(w_dht_digit_1),
        .digit_10(w_dht_digit_10),
        .digit_100(w_dht_digit_100),
        .digit_1000(w_dht_digit_1000)
    );



    //sr04 
 digit_splitter_sr04 U_SR04 (
        .in_data(fnd_in_data[11:0]),
        .digit_1(w_sr_digit_1),
        .digit_10(w_sr_digit_10),
        .digit_100(w_sr_digit_100),
        .digit_1000(w_sr_digit_1000)
    );



    //hour
    digit_splitter #(
        .BIT_WIDTH(5)
    ) U_HOUR_DS (
        .in_data (fnd_in_data[23:19]),
        .digit_1 (w_digit_hour_1),
        .digit_10(w_digit_hour_10)
    );

    //min
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_MIN_DS (
        .in_data (fnd_in_data[18:13]),
        .digit_1 (w_digit_min_1),
        .digit_10(w_digit_min_10)
    );


    //sec
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_SEC_DS (
        .in_data (fnd_in_data[12:7]),
        .digit_1 (w_digit_sec_1),
        .digit_10(w_digit_sec_10)
    );

    //msec
    digit_splitter #(
        .BIT_WIDTH(7)
    ) U_MSEC_DS (
        .in_data (fnd_in_data[6:0]),
        .digit_1 (w_digit_msec_1),
        .digit_10(w_digit_msec_10)
    );


    bcd U_BCD (
        .bcd(w_mux_out_mode),
        .fnd_data(fnd_data)
    );


    mux_4_1 sr04 (
        .digit_1(w_sr_digit_1),
        .digit_10(w_sr_digit_10),
        .digit_100(w_sr_digit_100),
        .digit_1000(w_sr_digit_1000),
        .sel(w_digit_sel[1:0]),
        .o_mux(w_mux_out_sr)
    );

 mux_4_1 dht (
        .digit_1(w_dht_digit_1),
        .digit_10(w_dht_digit_10),
        .digit_100(w_dht_digit_100),
        .digit_1000(w_dht_digit_1000),
        .sel(w_digit_sel[1:0]),
        .o_mux(w_mux_out_dht)
    );

    //to bcd mux
    mux_4_1 MODE (
        .digit_1(w_mux_2x1_out),
        .digit_10(w_mux_2x1_out),
        .digit_100(w_mux_out_sr),
        .digit_1000(w_mux_out_dht),
        .sel(sel_mode),
        .o_mux(w_mux_out_mode)
    );

endmodule





module clk_div (
    input clk,
    input reset,
    output reg o_1khz
);
    reg [16:0] counter_r;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 1'b0;
            o_1khz <= 1'b0;
        end else begin
            if (counter_r == 99999) begin
                counter_r <= 0;
                o_1khz <= 1'b1;
            end else begin
                counter_r <= counter_r + 1;
                o_1khz <= 1'b0;
            end
        end
    end
endmodule
module counter_8 (
    input        clk,
    input        reset,
    output [2:0] digit_sel
);
    reg [2:0] counter_r;
    assign digit_sel = counter_r;
    always @(posedge clk, posedge reset) begin
        if (reset) counter_r <= 0;
        else begin
            counter_r <= counter_r + 1;
        end
    end
endmodule


module decoder_2_4 (
    input [1:0] btn,
    output reg [3:0] fnd_digit
);

    always @(*) begin
        case (btn)
            2'b00:   fnd_digit = 4'b1110;
            2'b01:   fnd_digit = 4'b1101;
            2'b10:   fnd_digit = 4'b1011;
            default: fnd_digit = 4'b0111;
        endcase
    end

endmodule

module mux_2_1 (
    input        sel,
    input  [3:0] i_sel0,
    input  [3:0] i_sel1,
    output [3:0] o_mux
);

    //sel 1: output sel1, sel 0 : sel0
    assign o_mux = sel ? i_sel1 : i_sel0;

endmodule


module mux8_1 (
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    input [3:0] digit_dot_1,
    input [3:0] digit_dot_10,
    input [3:0] digit_dot_100,
    input [3:0] digit_dot_1000,
    input [2:0] sel,
    output reg [3:0] mux_out
);
    always @(*) begin
        case (sel)
            3'b000:  mux_out = digit_1;
            3'b001:  mux_out = digit_10;
            3'b010:  mux_out = digit_100;
            3'b011:  mux_out = digit_1000;
            3'b100:  mux_out = digit_dot_1;
            3'b101:  mux_out = digit_dot_10;
            3'b110:  mux_out = digit_dot_100;
            3'b111:  mux_out = digit_dot_1000;
            default: mux_out = 4'hf;
        endcase


    end

endmodule






module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH-1:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10

);

    assign digit_1  = (in_data) % 10;
    assign digit_10 = (in_data / 10) % 10;


endmodule


module digit_splitter_dht (
    input [15:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);


    assign digit_1  = (in_data[7:0]) % 10;
    assign digit_10 = (in_data[7:0] / 10) % 10;
    assign digit_100 = (in_data[15:8] ) % 10;
    assign digit_1000 = (in_data[15:8] / 10) % 10;

endmodule

module digit_splitter_sr04 (

    input [11:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);

    assign digit_1  = (in_data) % 10;
    assign digit_10 = (in_data / 10) % 10;
    assign digit_100 = (in_data / 100) % 10;
    assign digit_1000 = (in_data / 1000) % 10;
endmodule



module bcd (
    input      [3:0] bcd,
    output reg [7:0] fnd_data
);

    always @(*) begin
        case (bcd)
            4'd0:  fnd_data = 8'hC0;
            4'd1:  fnd_data = 8'hf9;
            4'd2:  fnd_data = 8'ha4;
            4'd3:  fnd_data = 8'hB0;
            4'd4:  fnd_data = 8'h99;
            4'd5:  fnd_data = 8'h92;
            4'd6:  fnd_data = 8'h82;
            4'd7:  fnd_data = 8'hf8;
            4'd8:  fnd_data = 8'h80;
            4'd9:  fnd_data = 8'h90;
            4'd14: fnd_data = 8'h7F;
            4'd15: fnd_data = 8'hFF;

            default: fnd_data = 8'hFF;
        endcase
    end
endmodule


module dot_onoff (
    input [6:0] msec,
    output dot_onoff
);

    assign dot_onoff = (msec < 50);



endmodule

module mux_4_1 (
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    input [1:0] sel,
    output reg [3:0] o_mux

);

    always @(*) begin
        case (sel)
            0: o_mux = digit_1;
            1: o_mux = digit_10;
            2: o_mux = digit_100;
            default: o_mux = digit_1000;
        endcase
    end

endmodule