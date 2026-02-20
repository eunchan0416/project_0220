`timescale 1ns / 1ps



module tb_uart_top(

    );


parameter BAUD= 9600;
parameter BAUD_PERIOD = (100_000_000 /BAUD)*10;

reg [7:0] test_data;
reg clk,rst,uart_rx;
wire uart_tx;
integer i,j,h;
uart_top dut (

    .clk(clk),
    .rst(rst),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx)
);


task uart_sender();
begin

  uart_rx=0;
    #(BAUD_PERIOD);
    for(i=0; i<8;i= i+1) begin
    uart_rx= test_data[i];
    #(BAUD_PERIOD);
    end
uart_rx=1;
    #(BAUD_PERIOD);
end
endtask


always #5 clk= ~clk;

initial begin
    #0;
    clk=0;
    rst=1;
    uart_rx=1;
    test_data=8'h31; 
    repeat (5) @(posedge clk);
    rst=0;

    repeat (5) @(posedge clk);
    //for(j=0;j<10;j=j+1) begin
    //    test_data=8'h30 + j;
    //    uart_sender();
    //end
 uart_sender();

    for(h=0; h<12;h= i+1) begin
    #(BAUD_PERIOD);
    end


$stop;


end

endmodule
