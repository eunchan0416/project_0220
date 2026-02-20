`timescale 1ns / 1ps

module tb_acsii_decoder();

    reg clk, rst, rx_done;
    reg [7:0] rx_data;
    wire [3:0] control_in;

    ascii_decoder dut(
        .clk(clk),
        .rst(rst),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .control_in(control_in) 
    );

    always #5 clk = ~clk;

    initial begin
        // 시뮬레이션 시작 확인용 메시지 (이게 안 나오면 툴 문제)
        $display("Simulation Start!"); 

        // 초기화
        clk = 0;
        rst = 1;
        rx_done = 0;
        rx_data = 0;
        
        #10;
        rst = 0;
        #10;

        // --- 'r' Test (우측 버튼) ---
        rx_data = 8'h72;
        rx_done = 1;      // 신호 켜기
        
       
        #10;               // 엣지 직후 안전하게 값 확인을 위해 1ns 대기
        rx_done=0;
         @(posedge clk);
        // [중요] rx_done을 끄기 전에 값을 확인해야 함!
        if(control_in == 4'b0001) 
            $display ("%t : pass : 'r' tick, rx_data = %h", $time, rx_data);
        else 
            $display ("%t : fail : 'r' tick. Expected 0001, Got %b", $time, control_in);
            
        rx_done = 0;      // 확인 끝났으니 끄기
        #20;

        // --- 'l' Test (좌측 버튼) ---
        rx_data = 8'h6C;
        rx_done = 1;
        
        @(posedge clk);
        #1; 
        
        if(control_in == 4'b0010) 
            $display ("%t : pass : 'l' tick, rx_data = %h", $time, rx_data);
        else 
            $display ("%t : fail : 'l' tick. Expected 0010, Got %b", $time, control_in);
            
        rx_done = 0;
        #20;

        // --- 'u' Test (위쪽 버튼) ---
        rx_data = 8'h75;
        rx_done = 1;
        
        @(posedge clk);
        #1;
        
        if(control_in == 4'b0100) 
            $display ("%t : pass : 'u' tick, rx_data = %h", $time, rx_data);
        else 
            $display ("%t : fail : 'u' tick. Expected 0100, Got %b", $time, control_in);
            
        rx_done = 0;
        #20;

        // --- 'd' Test (아래쪽 버튼) ---
        rx_data = 8'h64;
        rx_done = 1;
        
        @(posedge clk);
        #1;
        
        if(control_in == 4'b1000) 
            $display ("%t : pass : 'd' tick, rx_data = %h", $time, rx_data);
        else 
            $display ("%t : fail : 'd' tick. Expected 1000, Got %b", $time, control_in);
            
        rx_done = 0;
        #20;

        $display("Simulation Done!");
        $stop;
    end

endmodule