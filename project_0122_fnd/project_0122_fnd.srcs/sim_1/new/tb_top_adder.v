`timescale 1ns / 1ps



module tb_top_adder ();

    reg [7:0] a, b;
    wire [7:0] fnd_data;
    wire [3:0] fnd_digit;
    wire c;

    top_adder dut (
        .a(a),
        .b(b),
        .fnd_data(fnd_data),
        .fnd_digit(fnd_digit),
        .c(c)
    );

    integer i=0, j=0;

    initial begin
        #0;
        a = 0;
        b = 0;
        i=0;
        j=0;
#100;

        for (i = 0; i < 255; i = i + 1) begin
            for (j = 0; j < 255; j = j + 1) begin
                a = i;
                b = j;
                #10;

            end

        end



        #10;
        $stop;
        #100;
        $finish;


    end



endmodule
