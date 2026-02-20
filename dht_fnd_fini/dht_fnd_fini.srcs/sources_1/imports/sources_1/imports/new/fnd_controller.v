`timescale 1ns / 1ps



module fnd_controller (

    input [15:0] fnd_in_data,

    input clk,

    input reset,

    output [3:0] fnd_digit,

    output [7:0] fnd_data

);

    wire [1:0] w_digit_sel;

    wire [3:0] w_digit_1;

    wire [3:0] w_digit_10;

    wire [3:0] w_digit_100;

    wire [3:0] w_digit_1000;



    wire [3:0] w_mux_out;



    wire w_1kz;



    clk_div U_CLK_DIV (

        .clk(clk),

        .reset(reset),

        .o_1khz(w_1kz)

    );





    counter_4 U_COUNTER_4 (

        .clk(w_1kz),

        .reset(reset),

        .digit_sel(w_digit_sel)

    );



    decoder_2_4 U_DECODER_2_4 (

        .btn(w_digit_sel),

        .fnd_digit(fnd_digit)

    );





    digit_splitter_sr U_TEST (

        .in_data(fnd_in_data),

        .digit_1(w_digit_1),

        .digit_10(w_digit_10),

        .digit_100(w_digit_100),

        .digit_1000(w_digit_1000)



    );





    mux_4_1 U (

        .digit_1(w_digit_1),

        .digit_10(w_digit_10),

        .digit_100(w_digit_100),

        .digit_1000(w_digit_1000),

        .sel(w_digit_sel),

        .o_mux(w_mux_out)

    );

    bcd U_BCD (

        .bcd(w_mux_out),

        .fnd_data(fnd_data)

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

module counter_4 (

    input clk,

    input reset,

    output [1:0] digit_sel

);

    reg [1:0] counter_r;

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

            2'b00: fnd_digit = 4'b1110;

            2'b01: fnd_digit = 4'b1101;

            2'b10: fnd_digit = 4'b1011;

            default: fnd_digit = 4'b0111;

        endcase

    end



endmodule





module digit_splitter_sr (

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







module bcd (

    input [3:0] bcd,

    output reg [7:0] fnd_data

);



    always @(*) begin

        case (bcd)

            4'd0: fnd_data = 8'hC0;

            4'd1: fnd_data = 8'hf9;

            4'd2: fnd_data = 8'ha4;

            4'd3: fnd_data = 8'hB0;

            4'd4: fnd_data = 8'h99;

            4'd5: fnd_data = 8'h92;

            4'd6: fnd_data = 8'h82;

            4'd7: fnd_data = 8'hf8;

            4'd8: fnd_data = 8'h80;

            4'd9: fnd_data = 8'h90;

            4'd14: fnd_data = 8'h7F;

            4'd15: fnd_data = 8'hFF;



            default: fnd_data = 8'hFF;

        endcase

    end

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

