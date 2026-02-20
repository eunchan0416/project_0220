`timescale 1ns / 1ps


module fnd_controller (
    input  [3:0] sum,
    output [3:0] fnd_digit,
    output [7:0] fnd_data


);

    bcd U_BCD (
        .bcd(sum),
        .fnd_data(fnd_data)
    );

    assign fnd_digit = 4'b1110;  // fnd AN


endmodule


module bcd (
    input [3:0] bcd,
    output reg [7:0] fnd_data

);

    always @(bcd) begin
        case (bcd)
            4'd0: fnd_data = 8'hC0;
            4'd1: fnd_data = 8'hF9;
            4'd2: fnd_data = 8'hA4;
            4'd3: fnd_data = 8'hB0;
            4'd4: fnd_data = 8'h99;
            4'd5: fnd_data = 8'h92;
            4'd6: fnd_data = 8'h82;
            4'd7: fnd_data = 8'hF8;
            4'd8: fnd_data = 8'h80;
            4'd9: fnd_data = 8'h90;
            default: fnd_data = 8'hFF;
        endcase
    end


endmodule

