`timescale 1ns / 1ps

interface fifo_if;

bit clk;
bit rst;
logic [7:0] wdata;
logic       we;
logic       re;
logic [7:0] rdata;
logic       full;
logic       empty;

endinterface

class transaction;

rand logic [7:0] wdata;
rand logic       we;
rand logic       re;
rand logic [7:0] rdata;
logic       full;
logic       empty;

endclass


class generator;

transcation tr;
mailbox #(transaction) gen2drv_mbox;
event gen_next_ev;

function new(mailbox #(transaction) gen2drv_mbox,event gen_next_ev);
this.gen2drv_mbox=gen2drv_mbox;
this.gen_next_ev=gen_next_ev;

endfunction

task run(int run_count);

repeat (run_count) begin
@(gen_next_ev);
tr =    new();
tr.randmoize();
gen2drv_mbox.put(tr);
end

endtask


endclass;

class driver;

transcation tr;
virtual fifo_if fifo_if;
mailbox #(transaction) gen2drv_mbox;

function new(mailbox #(transaction) gen2drv_mbox,virtual fifo_if fifo_if);
this.gen2drv_mbox=gen2drv_mbox;
this.fifo_if=fifo_if;
endfunction


task run();
forever begin
gen2drv_mbox.get(tr);
@(negedge fifo_if.clk);
fifo_if.wdata= tr.wdata;
fifo_if.rdata=tr.rdata;
fifo_if.we=tr.we;
fifo_if.re=tr.re;


end

endtask

endclass



class monitor;
   
ranscation      tr;
virtual fifo_if fifo_if;
mailbox #(transaction) mon2scb_mbox;

function new(mailbox #(transaction) mon2scb_mbox,virtual fifo_if fifo_if);
this.mon2scb_mbox=mon2scb_mbox;
this.fifo_if=fifo_if;
endfunction
  

task run();

forever begin

@(posedge fifo_if.clk);
tr=new();
tr.wdata= fifo_if.wdata;
tr.rdata= fifo_if.rdata;
tr.we=fifo_if.we;
tr.re=fifo_if.re;
mon2scb_mbox.put(tr);

end

endtask


endclass //monitor

class scoreboard;

ranscation      tr;
mailbox #(transaction) mon2scb_mbox;
event gen_next_ev;

function new(mailbox #(transaction) mon2scb_mbox,event gen_next_ev);
this.mon2scb_mbox=mon2scb_mbox;
this.gen_next_ev=gen_next_ev;
endfunction


logic [7:0] fifo_que [$];


task run;

forever begin
mon2scb_mbox.get(tr);

if(tr.we) begin
    fifo_que[tr.waddr]=tr.wdata;
end

if(tr.re) begin
    if(fifo_que[tr.raddr]=== tr.rdata) begin
        $display("pass");
    end else  $display("fail");

end


-> gen_next_ev;

end

endtask


endclass





module tb_fifo(

    );

fifo_if fifo_if();

    fifo dut (
    .clk(fifo_if.clk),
    .rst(fifo_if.rst),
    .wdata(fifo_if.wdata),
    .we(fifo_if.we),
    .re(fifo_if.re),
    .rdata(fifo_if.rdata),
    .full(fifo_if.full),
    .empty(fifo_if.empty)
    );  
endmodule
