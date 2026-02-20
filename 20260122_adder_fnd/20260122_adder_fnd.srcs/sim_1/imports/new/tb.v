`timescale 1ns / 1ps



module tb_top_adder ();

   // reg [7:0] a, b;
    reg clk, reset;
    wire [7:0] fnd_data;
    wire [3:0] fnd_digit;


    integer i, j;

    top_adder dut (
        //.a(a),
        //.b(b),
        .clk(clk),
        .reset(reset),
        .fnd_data(fnd_data),
        .fnd_digit(fnd_digit)
    );




    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        reset = 0;
        #10;
        reset = 1;
        #20;
        reset = 0;
        #10;
        /*
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i;
                b = j;
                #10;
                if ((i == 255) && (j == 255)) begin
                    i = 0;
                    j = 0;
                    #10;
                end else begin
                    a = i;
                    b = j;
                end

                end
            end
        */
       
        #10000000;


        $stop;



    end





endmodule
