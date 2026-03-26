`timescale 1ns / 1ps

class transaction;
    rand bit [31:0] a;
    rand bit [31:0] b;
    bit             mode;

endclass  //transaction


interface adder_interface;
    logic [31:0] a;
    logic [31:0] b;
    logic        mode;
    logic [31:0] sum;
    logic        carry;

endinterface  //adder_interface


class generator;

    transaction tr;  //선언 handle

    virtual adder_interface adder_interf_gen;  //내부  

    //생성(new) 될때, 실행
    function new(virtual adder_interface adder_interf);  //외부(virtual)
        this.adder_interf_gen = adder_interf;
       tr= new(); 
    endfunction


  
    task run();
        tr.randomize();
        tr.mode = 0;
        adder_interf_gen.a = tr.a;
        adder_interf_gen.b = tr.b;
        adder_interf_gen.mode = tr.mode;


        //drive
        #10;
    endtask

endclass  //generator


module tb_adder_sv ();

    adder_interface adder_interf(); //interface instance
    generator gen; //class instance handle
    //dut instance
    //input interface connect
    adder dut (
        .a(adder_interf.a),
        .b(adder_interf.b),
        .mode(adder_interf.mode),
        .sum(adder_interf.sum),
        .carry(adder_interf.carry)
    );



    initial begin
        //
        gen = new(adder_interf);
        gen.run();


    end

endmodule



