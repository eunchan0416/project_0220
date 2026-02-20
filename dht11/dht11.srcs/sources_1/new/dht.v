`timescale 1ns / 1ps

module dht (
    input         clk,
    input         rst,
    input         start,
    output [15:0] humidity,
    output [15:0] temperature,
    output        dht_done,
    output        dht_valid,
    output [ 2:0] debug,

    inout dhtio
);

    wire w_tick;
    //noise 2 f/f
    reg dhtio_ct, dhtio_nt;
    reg io_sel_ct, io_sel_nt;
    reg [10:0] tick_counter_ct, tick_counter_nt;
    reg [2:0] c_st, n_st;
    reg [39:0] buffer_ct,buffer_nt;
    reg [5:0] counter_nt, counter_ct;
   reg [15:0] humidity_ct, humidity_nt;
   reg [15:0] temperature_ct, temperature_nt;
    localparam IDLE = 0, START=1, WAIT=2, SYNC_L=3, SYNC_H=4, DATA_SYNC=5, DATA=6, STOP=7;


    tick_gen U_TICK (
        .clk (clk),
        .rst (rst),
        .tick(w_tick)
    );

 ila_0 u_lia (
.clk(clk),
.probe0(dhtio),
.probe1(debug)
);






    assign dhtio = (io_sel_ct) ? dhtio_ct : 1'bz;
    assign dht_done = (c_st == STOP) && (tick_counter_ct == 5) ? 1 : 0;
    assign dht_valid = (buffer_ct[7:0] == (buffer_ct[39:32] + buffer_ct[31:24] + buffer_ct[23:16]+buffer_ct[15:8]))&&(c_st== STOP)&&(tick_counter_ct == 5) 
                            ? 1 :0;
    assign debug = c_st;
    assign humidity= humidity_ct;
    assign temperature = temperature_ct;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_st <= 0;
            dhtio_ct <= 1;
            io_sel_ct <= 1;
            tick_counter_ct <= 0;
            counter_ct <= 39;
           buffer_ct<=0;
            temperature_ct<=0;
            humidity_ct<=0;
        end else begin
            c_st <= n_st;
            dhtio_ct <= dhtio_nt;
            io_sel_ct <= io_sel_nt;
            tick_counter_ct <= tick_counter_nt;
            counter_ct <= counter_nt;
            temperature_ct<=temperature_nt;
            humidity_ct<= humidity_nt;
            buffer_ct<= buffer_nt;
        end
    end


    always @(*) begin
        n_st = c_st;
        dhtio_nt = dhtio_ct;
        io_sel_nt = io_sel_ct;
        tick_counter_nt = tick_counter_ct;
        counter_nt = counter_ct;
        buffer_nt= buffer_ct;
        humidity_nt= humidity_ct;
        temperature_nt= temperature_ct;
        case (c_st)
            IDLE: begin


                tick_counter_nt = 0;
                if (start) begin
                    n_st = START;
                end
            end
            START: begin
                dhtio_nt = 0;
                if (w_tick) begin
                    if (tick_counter_ct == (1900)) begin
                        n_st = WAIT;
                        tick_counter_nt = 0;
                    end else tick_counter_nt = tick_counter_ct + 1;
                end

            end
            WAIT: begin
                dhtio_nt = 1;
                if (w_tick) begin
                    if (tick_counter_ct == 3) begin
                        io_sel_nt = 0;
                        if (dhtio == 0) begin
                            n_st = SYNC_L;
                            tick_counter_nt = 0;
                        end

                    end else tick_counter_nt = tick_counter_ct + 1;
                end

            end
            SYNC_L: begin

                if (w_tick) begin
                    if (dhtio == 1) begin
                        n_st = SYNC_H;
                    end else n_st = SYNC_L;
                end

            end

            SYNC_H:
            if (w_tick) begin
                if (dhtio == 0) begin
                    n_st = DATA_SYNC;
                end else n_st = SYNC_H;
            end

            DATA_SYNC:
            if (w_tick) begin
                if (dhtio == 1) begin
                    n_st = DATA;
                    tick_counter_nt = 0;
                end else n_st = DATA_SYNC;
            end

            DATA: begin
                if (w_tick) begin
                    if (dhtio == 1) begin

                        tick_counter_nt = tick_counter_ct + 1;
                    end else begin

                        if (tick_counter_ct < 4) begin
                            buffer_nt[counter_ct] = 0;
                        end else begin
                            buffer_nt[counter_ct] = 1;
                        end

                        tick_counter_nt = 0;

                        if (counter_ct == 0) begin
                            counter_nt = 39;
                            n_st = STOP;
                        end else begin
                            counter_nt = counter_ct - 1;
                            n_st = DATA_SYNC;
                        end
                    end
                end
            end


            STOP: begin
                if (w_tick) begin
                    tick_counter_nt = tick_counter_ct + 1;
                    if (tick_counter_ct == 5) begin
                        dhtio_nt = 1;
                        io_sel_nt = 1;
                        n_st = IDLE;

                        if (buffer_ct[7:0] == (buffer_ct[39:32] +buffer_ct[31:24] + buffer_ct[23:16]+buffer_ct[15:8])) begin
                            humidity_nt= buffer_ct[39:24];
                            temperature_nt = buffer_ct[23:8];

                        end 
                    end
                end
            end

        endcase
    end

endmodule




module tick_gen (
    input      clk,
    input      rst,
    output reg tick
);

    parameter COUNT = 1000;
    //10us
    reg [9:0] counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter <= 0;
            tick    <= 0;
        end else begin
            if (counter == COUNT - 1) begin
                counter <= 0;
                tick    <= 1;
            end else begin
                counter <= counter + 1;
                tick    <= 0;
            end
        end
    end


endmodule
