`timescale 1ns / 1ps



module tb_top ();
    
    
    reg [2:0] sw;

    reg clk, reset;
      wire [7:0] fnd_data;
     wire [3:0] fnd_digit;

    
    top dut (
      
        .clk(clk),
        .sw(sw),
        .reset(reset),
        .fnd_data(fnd_data),
        .fnd_digit(fnd_digit)
    );


    



 integer i=0;

    always #5 clk = ~clk;
    initial begin
        #0;
        sw =0;
        clk = 0;
        reset = 1;
        #10;
        reset = 0;
        #1000000;

for(i=0;i<1000;i=i+1) begin
sw= sw+1;
        #1000000;
end


        $stop;



    end





endmodule
