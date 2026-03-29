`timescale 1ns / 1ps
`timescale 1ns / 1ps

module APB_UART(
    input  logic        pclk,
    input  logic        preset,
    input  logic [31:0] paddr,
    input  logic [31:0] pwdata,
    input  logic        pwrite,
    input  logic        penable,
    input  logic        psel,
    output logic [31:0] prdata,
    output logic        pready,

    input  logic        uart_rx,
    output logic        uart_tx
);

    logic w_tx_busy, w_rx_done, w_rx_busy;
    logic [7:0] tx_data_reg, rx_data_reg;
    logic [7:0] ctl_reg, status_reg;
    
    // Shadow & Active Register 분리!
    logic [1:0] baud_shadow_reg;
    logic [1:0] baud_active_reg; 
    logic rx_valid_reg;
    localparam [11:0] uart_ctl_addr    = 12'h000;
    localparam [11:0] uart_baud_addr   = 12'h004;
    localparam [11:0] uart_status_addr = 12'h008;
    localparam [11:0] uart_txdata_addr = 12'h00C;
    localparam [11:0] uart_rxdata_addr = 12'h010;

    uart_top U_UART (
        .clk       (pclk),
        .rst       (preset),
        .uart_rx   (uart_rx),
        .b_control (baud_active_reg), // 활성화된 레지스터만 하드웨어에 연결
        .tx_start  (ctl_reg[0]),
        .tx_data   (tx_data_reg),
        .uart_tx   (uart_tx),
        .rx_data   (rx_data_reg),
        .tx_busy   (w_tx_busy),
        .rx_busy   (w_rx_busy),     // 새로 추가된 RX Busy 신호
        .rx_done   (w_rx_done)
    );

    // Status Register
    assign status_reg = { rx_valid_reg, 6'd0,w_tx_busy};
    assign pready = 1'b1;

    // APB Read Mux
    assign prdata = (paddr[11:0] == uart_ctl_addr)    ? {24'd0, ctl_reg}         : 
                    (paddr[11:0] == uart_baud_addr)   ? {24'd0, 6'd0, baud_shadow_reg} : // 읽을 때는 Shadow 값을 반환
                    (paddr[11:0] == uart_status_addr) ? {24'd0, status_reg}      : 
                    (paddr[11:0] == uart_txdata_addr) ? {24'd0, tx_data_reg}     : 
                    (paddr[11:0] == uart_rxdata_addr) ? {24'd0, rx_data_reg}     : 32'd0;
                
    // APB Write 로직
    always_ff @(posedge pclk or posedge preset) begin
        if (preset) begin
            tx_data_reg     <= 8'd0;
            ctl_reg         <= 8'd0;
            baud_shadow_reg <= 2'b00;
            baud_active_reg <= 2'b00;
        end else begin
            
            if (w_rx_done) begin
                rx_valid_reg <= 1'b1; 
            end
            // CPU가 rxdata 레지스터의 값을 읽어가는 순간 스위치를 0으로 초기화
            else if (psel && penable && !pwrite && (paddr[11:0] == uart_rxdata_addr)) begin
                rx_valid_reg <= 1'b0; 
            end

            // [안전장치] TX, RX가 모두 쉬고 있을 때만 Active 레지스터 업데이트
            if (!w_tx_busy && !w_rx_busy) begin
                baud_active_reg <= baud_shadow_reg;
            end

            // 하드웨어 Auto-Clear 로직
            if (w_tx_busy) begin
                ctl_reg[0] <= 1'b0;
            end

            // APB Write
            if (penable && psel && pwrite) begin
                case (paddr[11:0])
                    uart_ctl_addr    : ctl_reg[0]      <= pwdata[0];
                    uart_txdata_addr : tx_data_reg     <= pwdata[7:0];
                    uart_baud_addr   : baud_shadow_reg <= pwdata[1:0]; // Shadow에만 씀
                endcase
            end
        end
    end            
endmodule



module uart_top (
    input  logic       clk,
    input  logic       rst,
    input  logic       uart_rx,
    input  logic [1:0] b_control,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       uart_tx,
    output logic [7:0] rx_data,
    output logic       tx_busy,
    output logic       rx_busy, 
    output logic       rx_done
);
    
    logic w_b_tick; 

    uart_tx U_UART_TX (
        .clk      (clk),
        .rst      (rst),
        .b_tick   (w_b_tick),
        .tx_start (tx_start),
        .tx_data  (tx_data), 
        .tx_busy  (tx_busy),
        .tx_done  (),        
        .uart_tx  (uart_tx)
    );

    uart_rx U_UART_RX (
        .clk      (clk),
        .rst      (rst),
        .rx       (uart_rx),
        .b_tick   (w_b_tick),
        .rx_data  (rx_data),
        .rx_busy  (rx_busy),  // 추가
        .rx_done  (rx_done)
    );

    baud_tick U_baud_tick ( 
        .clk      (clk),
        .rst      (rst),
        .b_control(b_control),
        .b_tick   (w_b_tick)
    );

endmodule

// ==========================================
// 3. Baud Rate Generator
// ==========================================
module baud_tick (
    input  logic       clk,
    input  logic       rst,
    input  logic [1:0] b_control, 
    output logic       b_tick
);

    logic [9:0] counter;
    logic [9:0] f_count;
    logic [1:0] b_control_reg; 
//fcount = 100_000_000(100MHZ) / (16*BAUDRATE)
    always_comb begin
        case (b_control)
            2'b00: f_count = 10'd651; //9600,
            2'b01: f_count = 10'd325;  //19200
            2'b10: f_count = 10'd54;   //115200
            default: f_count = 10'd651;
        endcase
    end
		
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter       <= 10'd0;
            b_tick        <= 1'b0;
            b_control_reg <= 2'b00;
        end else begin
            b_control_reg <= b_control; 
            if (b_control != b_control_reg) begin
                counter <= 10'd0;
                b_tick  <= 1'b0;
            end else if (counter >= (f_count - 1)) begin
                counter <= 10'd0;
                b_tick  <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                b_tick  <= 1'b0;
            end
        end
    end
endmodule

// ==========================================
// 4. UART TX Module
// ==========================================
module uart_tx (
    input  logic       clk,
    input  logic       rst,
    input  logic       tx_start,
    input  logic       b_tick,    
    input  logic [7:0] tx_data,
    output logic       uart_tx,
    output logic       tx_busy,
    output logic       tx_done
);

    localparam IDLE  = 2'd0, START = 2'd1, DATA  = 2'd2, STOP  = 2'd3;

    logic [1:0] c_state, n_state; 
    logic       tx_reg, tx_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;  
    logic [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    logic       busy_reg, busy_next;
    logic       done_reg, done_next;  
    logic [7:0] data_in_buf_reg, data_in_buf_next;

    assign uart_tx = tx_reg;
    assign tx_busy = busy_reg; 
    assign tx_done = done_reg; 

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            bit_cnt_reg     <= 3'b0;
            busy_reg        <= 1'b0;
            done_reg        <= 1'b0;
            data_in_buf_reg <= 8'h00;
            b_tick_cnt_reg  <= 4'h0;
        end else begin
            c_state         <= n_state;
            tx_reg          <= tx_next;
            bit_cnt_reg     <= bit_cnt_next;
            busy_reg        <= busy_next;
            done_reg        <= done_next;
            data_in_buf_reg <= data_in_buf_next;
            b_tick_cnt_reg  <= b_tick_cnt_next;
        end
    end

    always_comb begin
        n_state          = c_state;
        tx_next          = tx_reg;
        bit_cnt_next     = bit_cnt_reg;
        busy_next        = busy_reg;
        done_next        = 1'b0; 
        data_in_buf_next = data_in_buf_reg;
        b_tick_cnt_next  = b_tick_cnt_reg;

        case (c_state)
            IDLE: begin
                tx_next         = 1'b1;  
                bit_cnt_next    = 3'b0;
                b_tick_cnt_next = 4'h0;
                busy_next       = 1'b0;

                if (tx_start == 1'b1) begin
                    n_state          = START;
                    busy_next        = 1'b1;
                    data_in_buf_next = tx_data;
                end 
            end

            START: begin  
                tx_next = 1'b0;
                if (b_tick == 1'b1) begin
                    if (b_tick_cnt_reg == 4'd15) begin
                        n_state         = DATA;
                        b_tick_cnt_next = 4'h0;
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                end
            end

            DATA: begin
                tx_next = data_in_buf_reg[0];                
                if (b_tick == 1'b1) begin
                    if (b_tick_cnt_reg == 4'd15) begin
                        if (bit_cnt_reg == 3'd7) begin
                            b_tick_cnt_next = 4'h0;
                            n_state         = STOP;
                        end else begin
                            b_tick_cnt_next  = 4'h0;
                            bit_cnt_next     = bit_cnt_reg + 1'b1;
                            data_in_buf_next = {1'b0, data_in_buf_reg[7:1]};
                        end
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                end
            end

            STOP: begin
                tx_next = 1'b1;
                if (b_tick == 1'b1) begin
                    if (b_tick_cnt_reg == 4'd15) begin
                        done_next = 1'b1;
                        n_state   = IDLE;
                        busy_next=0;
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                end
            end
        endcase
    end
endmodule

// ==========================================
// 5. UART RX Module
// ==========================================
module uart_rx (
    input  logic       clk,
    input  logic       rst,
    input  logic       rx,
    input  logic       b_tick,
    output logic [7:0] rx_data,
    output logic       rx_busy, // 새로 추가됨
    output logic       rx_done
);

    localparam IDLE  = 2'd0, START = 2'd1, DATA  = 2'd2, STOP  = 2'd3;

    logic [1:0] c_state, n_state;
    logic [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    logic [2:0] bit_cnt_next, bit_cnt_reg;
    logic       done_reg, done_next;
    logic [7:0] buf_reg, buf_next;

    assign rx_done = done_reg;
    assign rx_data = buf_reg;
    
    // RX가 동작 중인지(IDLE이 아닌지) 밖으로 알려줌
    assign rx_busy = (c_state != IDLE);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            b_tick_cnt_reg <= 4'd0;
            bit_cnt_reg    <= 3'd0;
            done_reg       <= 1'b0;
            buf_reg        <= 8'd0;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            done_reg       <= done_next;
            buf_reg        <= buf_next;
        end
    end

    always_comb begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        done_next       = 1'b0; 
        buf_next        = buf_reg;

        case (c_state)
            IDLE: begin
                b_tick_cnt_next = 4'd0;
                bit_cnt_next    = 3'd0;
                if (b_tick && (rx == 1'b0)) begin
                    n_state         = START;
                    buf_next        = 8'd0;
                    b_tick_cnt_next = 4'd0;
                end
            end
            
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 4'd7) begin 
                        n_state         = DATA;
                        b_tick_cnt_next = 4'd0;
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                end
            end
            
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 4'd15) begin
                        b_tick_cnt_next = 4'd0;
                        buf_next        = {rx, buf_reg[7:1]};
                        if (bit_cnt_reg == 3'd7) begin
                            n_state = STOP;
                        end else bit_cnt_next = bit_cnt_reg + 1'b1;
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                end
            end

            STOP: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 4'd15) begin
                        n_state         = IDLE;
                        done_next       = 1'b1;
                        b_tick_cnt_next = 4'd0;
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                end
            end
        endcase
    end
endmodule