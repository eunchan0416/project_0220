`timescale 1ns / 1ps


interface adder_interface;
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] sum;
    logic        mode;
    logic        carry;
endinterface  //adder_interface



class transaction;
    randc bit [31:0] a;
    randc bit [31:0] b;
    randc bit        mode;
    logic    [31:0] sum;
    logic           carry;


    task display(string name);
        $display("%t : [%s] a= %h,b= %h, mode= %h,sum= %h,carry= %h,", $time,
                 name, a, b, mode, sum, carry);
    endtask

    /*constraint range {
        a <10;
        b >32'hffff_0000;
    };
    

    constraint dist_pattern {
        a dist {
                0 :=8,
                32'hffff_ffff :=1,
                [1:32'hffff_fffe] :=1
        };
    };
*/


    constraint list_pattern{
        a inside {[0:10]} ;

    };
endclass  //transaction



class generator;

    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    event                  gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run(int count);
        repeat (count) begin
            this.tr = new();  // 
            tr.randomize();  // randomize

            gen2drv_mbox.put(tr);
            tr.display("gen");
            @(gen_next_ev);  //event 신호 전 후, 시간의 영향이 있다.

        end
    endtask

endclass  //generator




class driver;

    transaction             tr;  //genrator에서 받아줄 tr handle 필요
    virtual adder_interface adder_if;  //interface
    mailbox #(transaction)  gen2drv_mbox;
    event                   mon_next_ev;


    function new(mailbox#(transaction) gen2drv_mbox, event mon_next_ev,
                 virtual adder_interface adder_if);

        this.adder_if = adder_if; //this.adder_if는 위에서 만든 class내의 interface,  new()괄호안의 adder_if는 외부에서 입력할 인자
        this.gen2drv_mbox = gen2drv_mbox;
        this.mon_next_ev = mon_next_ev;
    endfunction  //new()

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.display("drv");
            adder_if.a = tr.a;
            adder_if.b = tr.b;
            adder_if.mode = tr.mode;
            #10;
            ->mon_next_ev;  //event 생성
        end
    endtask  //

endclass  //driver


class monitor;

    transaction tr;
    virtual adder_interface adder_if;
    mailbox #(transaction) mon2scb_mbox;
    event mon_next_ev;


    function new(mailbox#(transaction) mon2scb_mbox, event mon_next_ev,
                 virtual adder_interface adder_if);

        this.mon2scb_mbox = mon2scb_mbox;
        this.adder_if = adder_if;
        this.mon_next_ev = mon_next_ev;
    endfunction  //new()

    task run();
        forever begin
            @(mon_next_ev);
            tr = new();
            tr.a = adder_if.a;
            tr.b = adder_if.b;
            tr.mode = adder_if.mode;
            tr.sum = adder_if.sum;
            tr.carry = adder_if.carry;
            mon2scb_mbox.put(tr);
            tr.display("mon");
        end
    endtask  //

endclass  //monitor

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;
    bit [31:0] expected_sum;
    bit expected_carry;
    int pass_cnt, fail_cnt;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);

        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scb");
            //compare,pass,fail
            if (tr.mode) {expected_carry, expected_sum} = tr.a - tr.b;
            else {expected_carry, expected_sum} = tr.a + tr.b;



            if ({expected_carry, expected_sum} == {tr.carry, tr.sum}) begin
                $display("pass");
                pass_cnt++;
            end else begin
                $display("fail");
                fail_cnt++;
                $display("expected sum = %d", expected_sum);
                $display("expected carry = %d", expected_carry);
            end


            ->gen_next_ev;
        end
    endtask

endclass  //scoreboard

class environment;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv_mbox; //mailbox : keyword ,#(transaction) :data type
    mailbox #(transaction) mon2scb_mbox;

    event gen_next_ev;
    event mon_next_ev;
    int i;

    function new(virtual adder_interface adder_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, mon_next_ev, adder_if);
        mon = new(mon2scb_mbox, mon_next_ev, adder_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()


    task run();
        i = 100;
        fork
            gen.run(i);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10; //gen이 연산먼저끝나고,drv,mon,scb의 마지막 data값을 안정적으로 보기위해서
        $display("_________________________________");
        $display("** 32bit adder              *****");
        $display("_________________________________");
        $display("*****test_cnt = %3d         *****", i);
        $display("*****pass_cnt = %3d         *****", scb.pass_cnt);
        $display("*****fail_cnt = %3d         *****", scb.fail_cnt);
        $display("__________________________________");

        $stop;
    endtask

endclass  //enviroment


module tb_adder_sv ();

    adder_interface adder_if ();
    environment env;


    adder dut (
        .a(adder_if.a),
        .b(adder_if.b),
        .mode(adder_if.mode),
        .sum(adder_if.sum),
        .carry(adder_if.carry)
    );

    initial begin
        env = new(adder_if);
        env.run();
    end

endmodule


