`timescale 1ns / 1ps


module tb_cpu ();

    logic clk, rst;
    logic [7:0] out;

    cpu_sum DUT (
        .clk(clk),
        .rst(rst),
        .out(out)
    );

    always #5 clk = ~clk;


    initial begin
        clk = 0;
        rst = 1;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        repeat (50) begin
            @(posedge clk);
        end
        $stop;

    end

endmodule
