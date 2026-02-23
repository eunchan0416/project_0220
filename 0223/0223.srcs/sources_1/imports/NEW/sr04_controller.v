module SR04_controller (
    input clk,
    input reset,
    input i_sr_start,
    input i_sr_echo,
    output reg o_sr_trigger,
    output [8:0] o_distance
);

    wire w_tick_1u;

    tick_gen_1us u_tick (
        .clk(clk),
        .reset(reset),
        .o_tick_1us(w_tick_1u)
    );

    localparam IDLE = 2'd0, TRIGGER = 2'd1, ECHO_WAIT = 2'd2, ECHO_COUNT = 2'd3;
    localparam MAX = 23200;

    reg [1:0] c_state, n_state;

    reg [8:0] dist_reg, dist_next;

    reg [$clog2(MAX)-1:0] counter_dist_reg, counter_dist_next;

    // falling edge

    reg echo_ff1, echo_ff2;
    wire w_tick_60ms;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            echo_ff1 <= 0;
            echo_ff2 <= 0;
        end else begin
            echo_ff1 <= i_sr_echo;
            echo_ff2 <= echo_ff1;
        end
    end

    reg ff2_next; 
    reg ff2_reg;  

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            ff2_next <= 1'b0;
            ff2_reg <= 1'b0;
        end else begin
            ff2_next <= ff2_reg;
            ff2_reg <= echo_ff2;
        end
    end
   
    wire w_falling_edge = (ff2_next & ~ff2_reg);  

  

    assign o_distance = dist_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            dist_reg <= 0;
            counter_dist_reg <= 0;
        end else begin
            c_state <= n_state;
            dist_reg <= dist_next;
            counter_dist_reg <= counter_dist_next;

        end
    end

    always @(*) begin
        n_state = c_state;
        dist_next = dist_reg;
        counter_dist_next = counter_dist_reg;
        o_sr_trigger = 0;

        case (c_state)
            IDLE: begin
                o_sr_trigger = 0;
                counter_dist_next = 0;
                if (i_sr_start) begin
                    n_state = TRIGGER;
                end
            end

            TRIGGER: begin
                o_sr_trigger = 1;
                if (w_tick_1u == 1) begin
                    if (counter_dist_reg == 10) begin
                        counter_dist_next = 0;
                        n_state = ECHO_WAIT;
                    end else counter_dist_next = counter_dist_reg + 1;
                end


            end

            ECHO_WAIT: begin
                if (echo_ff2) begin 
                    counter_dist_next = 0;
                    n_state = ECHO_COUNT;
                end else if (w_tick_1u) begin
                    if (counter_dist_reg == 5000) begin  // 5ms 
                        n_state = IDLE;
                    end else counter_dist_next = counter_dist_reg + 1;
                end
            end



            ECHO_COUNT: begin
                if (w_falling_edge) begin
                    dist_next = (counter_dist_reg * 1130) >> 16;
                    n_state   = IDLE;
                end else if (w_tick_1u) begin
                    counter_dist_next = counter_dist_reg + 1;
                    if (counter_dist_reg == MAX) begin
                        n_state   = IDLE;
                    end 
                    

                end

            end






        endcase
    end
endmodule



