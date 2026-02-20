`timescale 1ns / 1ps


module dht_top (
    input clk,
    input rst,
    input btn_r, //start
    output [9:0] led,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,

    inout dhtio
);

    wire w_btn;
    wire [2:0] debug;
    wire [15:0] w_humidity, w_temperature;
    assign led[0] = (debug == 0) ? 1 : 0;
    assign led[1] = (debug == 1) ? 1 : 0;
    assign led[2] = (debug == 2) ? 1 : 0;
    assign led[3] = (debug == 3) ? 1 : 0;
    assign led[4] = (debug == 4) ? 1 : 0;
    assign led[5] = (debug == 5) ? 1 : 0;
    assign led[6] = (debug == 6) ? 1 : 0;
    assign led[7] = (debug == 7) ? 1 : 0;


    btn_debounce U_btn (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_r),
        .o_btn(w_btn)
    );



    dht U_DHT (
        .clk(clk),
        .rst(rst),
        .start(w_btn),
        .humidity(w_humidity),
        .temperature(w_temperature),
        .dht_done(led[8]),
        .dht_valid(led[9]),
        .debug(debug),
        .dhtio(dhtio)
    );


    fnd_controller U_FND (

        .fnd_in_data({w_humidity[15:8], w_temperature[15:8]}),
        .clk(clk),
        .reset(rst),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)

    );

endmodule
