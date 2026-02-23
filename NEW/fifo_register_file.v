`timescale 1ns / 1ps


module register_file #(
    parameter DEPTH = 4,
    BIT_WIDTH = 8
) (
    // FIFO는 사용자가 정의한 WORD(data length) 단위로 처리한다. 
    // WORD에서 어디가 LSB인지 MSB인지를 정하는 것도 사용자의 마음이다. 
    // 이를 엔디안이라고 하고 빅엔디안 리틀 엔디안 등으로 나뉜다. 
    // FIFO는 단지 입력된 데이터 프레임(WORD)을 순서대로 보관하고 보내는 구조.
    
    input                      clk,
    input  [    BIT_WIDTH-1:0] push_data,
    input  [$clog2(DEPTH)-1:0] w_addr,
    input  [$clog2(DEPTH)-1:0] r_addr,
    input                      we, //write enable 
    output  [    BIT_WIDTH-1:0] pop_data
);

    // ram 
    reg [BIT_WIDTH-1:0] register_file[0:DEPTH-1];
    //push, to register_file
    always @(posedge clk) begin
        if (we) begin
            //push
            register_file[w_addr] <= push_data;  
        end else begin
            //pop_data <= register_file [r_addr]; // 조합출력
        end
    end

    //pop
    assign pop_data = register_file[r_addr]; //순차출력
    //이러면 끝 ram 설계랑 똑같음. 이게 듀얼 포트?
endmodule
