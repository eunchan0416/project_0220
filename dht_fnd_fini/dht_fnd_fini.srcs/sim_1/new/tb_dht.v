`timescale 1ns / 1ps

module tb_dht11 ();

    reg clk, rst, start;
    reg dht11_sensor_io, sensor_io_sel;
    reg [39:0] dht_sensor_data;
    wire dhtio;
    wire [15:0] humidity;
    wire [15:0] temperture;
    wire dht_done, dht_valid;
    wire [2:0] debug;
    integer i;
    assign dhtio = (sensor_io_sel) ? 1'bz : dht11_sensor_io;

    dht dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .humidity(humidity),
        .temperature(temperture),
        .dht_done(dht_done),
        .dht_valid(dht_valid),
        .debug(debug),
        .dhtio(dhtio)
    );

    always #5 clk = ~clk;

    initial begin

        #0;
        i = 0;
        clk = 0;
        rst = 1;
        start = 0;
        dht11_sensor_io = 1'b0;
        sensor_io_sel = 1'b1;
        // huminity int, decimal, temparture int, deci
        dht_sensor_data = {8'h32, 8'h00, 8'h19, 8'h00, 8'h4b};
        // reset
        #20;
        rst = 0;
        #20;
        start = 1;
        #10;
        start = 0;

        // 19msec + 30usec
        #(1900 * 10 * 1000 + 30_000);
        sensor_io_sel   = 0;

        //sync_l, sync_h
        dht11_sensor_io = 1'b0;
        #80_000;
        dht11_sensor_io = 1;
        #80_000;

        //data sync
        dht11_sensor_io = 0;
        #50_000;

        for (i = 39; i > -1; i = i - 1) begin

            if (dht_sensor_data[i] == 0) begin
                dht11_sensor_io = 1;
                #20_000;
            end else begin
                dht11_sensor_io = 1;
                #70_000;
            end

            dht11_sensor_io = 0;
            #50_000;

        end
        sensor_io_sel = 1'b0;
        #50_000;
        sensor_io_sel = 1'b1;
        #100_000;

        $stop;
    end



endmodule
