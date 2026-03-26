`timescale 1ns / 1ps

module tb_rv32i(
    );

    logic clk,rst;

    rv32i_top dut(
    .clk(clk),
    .rst(rst)
    );

always #5 clk= ~clk;

initial begin
    clk=0;
    rst=1;
    #22;
    rst=0;
    repeat(200) @(posedge clk);

    $stop;
    
end
endmodule
