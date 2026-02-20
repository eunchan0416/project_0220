`timescale 1ns / 1ps

module sr04_controller(
    input clk,
    input rst,
    input tick,
    input start,
    input echo,
    output  [11:0] dist,
    output trigger
    );
localparam MAX= 23200;
localparam MIN= 116;

localparam IDLE = 2'b00, WAIT=2'b01, COUNT=2'b10;
reg [1:0] st_ct, st_nt;
reg tr_ct,tr_nt;
reg [3:0] counter_tick_pulse_ct,counter_tick_pulse_nt;
reg [14:0] counter_time_ct, counter_time_nt;
reg [11:0] dist_ct, dist_nt;
assign trigger = tr_ct;
assign dist= dist_ct;

always @(posedge clk, posedge rst) begin
    if (rst) begin
        st_ct<=IDLE;
        tr_ct<=0;
    counter_time_ct<=0;
    counter_tick_pulse_ct<=0;
    dist_ct<=0;
    end else begin 
    st_ct<= st_nt;
    tr_ct<= tr_nt;
     counter_time_ct<=counter_time_nt;
    counter_tick_pulse_ct <= counter_tick_pulse_nt;
    dist_ct<=dist_nt;
    end
end


always @(*) begin
    tr_nt=tr_ct;
    st_nt=st_ct;
counter_tick_pulse_nt=counter_tick_pulse_ct;
counter_time_nt=counter_time_ct;
dist_nt=dist_ct;
    case (st_ct)
      IDLE  : begin
        counter_tick_pulse_nt=0;
            if(start==1) begin
                st_nt= WAIT;
                tr_nt=1;
            end 

      end 
         WAIT  : begin
          counter_time_nt=0;
            if(tick) begin
                if (counter_tick_pulse_ct == 10) begin
                    tr_nt=0;
                    if (echo==1) begin
                        st_nt= COUNT;
                        counter_tick_pulse_nt=0;
                        counter_time_nt= counter_time_ct+1;
                    end
                end else begin
                counter_tick_pulse_nt= counter_tick_pulse_ct +1;     
                end
            end
        
      end 
         COUNT  : begin
            
               
                    if (echo==1) begin
                        if(tick) begin
                        if (counter_time_ct == (MAX)) begin
                       st_nt= IDLE; 
                       dist_nt=  counter_time_ct /58;
                    end else counter_time_nt= counter_time_ct+1;
                    end 
                    end
                    
                    else begin
                        if(counter_time_ct < MIN) begin
                        st_nt= IDLE; 
                       dist_nt=  MIN /58;
                        end else begin
                    st_nt=IDLE;
                    dist_nt=  counter_time_ct /58;
                    end
                  
                    
                end 
            
        
      end 
    endcase



end




endmodule
