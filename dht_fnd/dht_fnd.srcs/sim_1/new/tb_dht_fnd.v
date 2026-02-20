`timescale 1ns / 1ps



module tb_dht_fnd ();


    reg clk, rst;
    reg btn_r;
    reg dht11_sensor_io, sensor_io_sel;
    reg [39:0] dht_sensor_data;
    wire dhtio;
    wire [9:0] led;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;


    integer i;
    assign dhtio = (sensor_io_sel) ? 1'bz : dht11_sensor_io;

    dht_top udt (
        .clk(clk),
        .rst(rst),
        .btn_r(btn_r),  //start
        .led(led),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data),
        .dhtio(dhtio)
    );

    always #5 clk = ~clk;

    initial begin

        #0;
        i = 0;
        clk = 0;
        rst = 1;
        btn_r = 0;
        dht11_sensor_io = 1'b0;
        sensor_io_sel = 1'b1;
        // huminity int, decimal, temparture int, deci
        dht_sensor_data = {8'h32, 8'h00, 8'h19, 8'h00, 8'h4b};
        // reset
        #20;
        rst = 0;
        #20;
        btn_r = 1;
        #100_000_000;
        btn_r = 0;

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
