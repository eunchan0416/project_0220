`timescale 1ns / 1ps



module tb_b_nb ();

    reg a, b, c;

    initial begin
        #0;
        a = 1;
        b = 0;

        #10;
        
        a = b;
        b = a;
        c = a + b;
        // a=0, b=0, c=0
        #10;
        a = 1;
        b = 0;
        #10;
        a <= b;
        b <= a;
        c <= a + b;
        #10;
        //a=0,b=1, c=1 
        $stop;




    end



endmodule
