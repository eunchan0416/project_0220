`timescale 1ns / 1ps


// top module

module gate(
//input a.b
input a,
input b,
//output 
output y0,
output y1,
output y2,
output y3,
output y4,
output y5,
output y6

    );

//and gate
assign y0= a&b;
//NAND
assign y1= ~(a&b);

assign y2= a|b;

assign y3= ~(a|b);

assign y4= a^b;

assign y5= ~(a^b);

assign y6= ~a;


endmodule