`timescale 1ns / 1ps

module dht11_controller (
    input         clk,
    input         rst,
    input         start,
    output [15:0] humidity,
    output [15:0] temperature,
    output        dht11_done,
    output        dht11_valid,
    output [ 2:0] debug,
    inout         dhtio
);

    wire tick_1u;

    tick_gen_1u U_TICK_1u (
        .clk    (clk),
        .rst    (rst),
        .tick_1u(tick_1u)
    );

    // STATE
    parameter IDLE = 0, START = 1, WAIT = 2, SYNC_L = 3, SYNC_H = 4;
    parameter DATA_SYNC = 5, DATA_C = 6, STOP = 7;

    reg [2:0] c_state, n_state;
    reg dhtio_reg, dhtio_next;
    reg io_sel_reg, io_sel_next;
    reg [39:0] data_reg, data_next;
    reg [5:0] bit_cnt_reg, bit_cnt_next;

    // for 19msec count by 1usec tick
    reg [$clog2(19000)-1:0] tick_cnt_reg, tick_cnt_next;

    assign dhtio = (io_sel_reg) ? dhtio_reg : 1'bz;
    assign debug = c_state;

    // checksum
    wire [7:0] checksum = data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8];

    assign humidity    = data_reg[39:24];
    assign temperature = data_reg[23:8];
    assign dht11_valid = (checksum == data_reg[7:0]) && (data_reg != 0);
    assign dht11_done  = (c_state == STOP);

    // auto timer (2s)
    reg [$clog2(200_000_000)-1:0] auto_timer;
    wire o_auto_timer;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            auto_timer <= 0;
        end else begin
            if (auto_timer == 200_000_000 - 1) begin
                auto_timer <= 0;
            end else begin
                auto_timer <= auto_timer + 1;
            end
        end
    end

    assign o_auto_timer = (auto_timer == 0) ? 1'b1 : 1'b0;

    // dhtio synchronizer, edge detector
    reg dhtio_sync_1, dhtio_sync_2, dhtio_sync_3;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            dhtio_sync_1 <= 1'b1;
            dhtio_sync_2 <= 1'b1;
            dhtio_sync_3 <= 1'b1;
        end else begin
            dhtio_sync_1 <= dhtio;
            dhtio_sync_2 <= dhtio_sync_1;
            dhtio_sync_3 <= dhtio_sync_2;
        end
    end

    wire w_dht_pos_edge = (dhtio_sync_2 == 1'b1 && dhtio_sync_3 == 1'b0);
    wire w_dht_neg_edge = (dhtio_sync_2 == 1'b0 && dhtio_sync_3 == 1'b1);

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= 3'b000;
            dhtio_reg    <= 1'b1;
            tick_cnt_reg <= 1'b0;
            io_sel_reg   <= 1'b1;
            data_reg     <= 0;
            bit_cnt_reg  <= 0;
        end else begin
            c_state      <= n_state;
            dhtio_reg    <= dhtio_next;
            tick_cnt_reg <= tick_cnt_next;
            io_sel_reg   <= io_sel_next;
            data_reg     <= data_next;
            bit_cnt_reg  <= bit_cnt_next;
        end
    end

    // next, output 
    always @(*) begin
        n_state       = c_state;
        tick_cnt_next = tick_cnt_reg;
        dhtio_next    = dhtio_reg;
        io_sel_next   = io_sel_reg;
        data_next     = data_reg;
        bit_cnt_next  = bit_cnt_reg;
        case (c_state)
            IDLE: begin
                if (start || o_auto_timer) begin
                    dhtio_next    = 1'b1;
                    io_sel_next   = 1'b1;
                    tick_cnt_next = 0;
                    bit_cnt_next  = 0;
                    n_state       = START;
                end
            end
            START: begin
                dhtio_next = 1'b0;
                if (tick_1u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 18999) begin  // wait 19ms
                        tick_cnt_next = 0;
                        n_state = WAIT;
                    end
                end
            end
            WAIT: begin
                dhtio_next = 1'b1;
                if (tick_1u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 29) begin  // keep 30us
                        tick_cnt_next = 0;
                        n_state = SYNC_L;
                        // for output to high-z
                        io_sel_next = 1'b0;
                    end
                end
            end
            // Data read (sensor)
            SYNC_L: begin
                if (w_dht_pos_edge == 1) begin  // edge detect
                    tick_cnt_next = 0;
                    n_state = SYNC_H;
                end
                if (tick_1u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 199) begin  // 센서 응답이 없으면 IDLE로 탈출
                        tick_cnt_next = 0;
                        n_state = IDLE;
                    end
                end
            end
            SYNC_H: begin
                if (w_dht_neg_edge == 1) begin  // edge detect
                    tick_cnt_next = 0;
                    n_state = DATA_SYNC;
                end
                if (tick_1u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 199) begin  // 센서 응답이 없으면 IDLE로 탈출
                        tick_cnt_next = 0;
                        n_state = IDLE;
                    end
                end
            end
            DATA_SYNC: begin
                if (w_dht_pos_edge == 1) begin  // edge detect
                    tick_cnt_next = 0;
                    n_state = DATA_C;
                end
                if (tick_1u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 199) begin  // 센서 응답이 없으면 IDLE로 탈출
                        tick_cnt_next = 0;
                        n_state = IDLE;
                    end
                end
            end
            DATA_C: begin
                if (tick_1u) begin
                    if (dhtio_sync_2 == 1) begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
                if (w_dht_neg_edge == 1) begin  // edge detect
                    // data
                    if (tick_cnt_reg > 40) begin  // high '1'
                        data_next = {data_reg[38:0], 1'b1};
                    end else begin
                        data_next = {data_reg[38:0], 1'b0};  // low '0'
                    end
                    tick_cnt_next = 0;

                    if (bit_cnt_reg == 39) begin  // 40 bit
                        bit_cnt_next = 0;
                        n_state = STOP;
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1;
                        n_state      = DATA_SYNC;  // next bit
                    end
                end
            end
            STOP: begin
                if (tick_1u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 49) begin
                        // output mode
                        dhtio_next  = 1'b1;
                        io_sel_next = 1'b1;
                        n_state     = IDLE;
                    end
                end
            end
        endcase
    end

endmodule

module tick_gen_1u (
    input      clk,
    input      rst,
    output reg tick_1u
);

    parameter F_COUNT = 100_000_000 / 1_000_000;

    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_1u    <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_1u    <= 1'b1;
            end else begin
                tick_1u <= 1'b0;
            end
        end
    end

endmodule
