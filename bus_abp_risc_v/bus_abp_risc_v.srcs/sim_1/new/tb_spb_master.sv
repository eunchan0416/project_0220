`timescale 1ns / 1ps

//ram test

module tb_spb_master ();

    logic        pclk;
    logic        presetn;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic        wreq;  //DWE, apb_wr
    logic        rreq;  //apb_re
    logic        ready;
    logic [31:0] rdata;
    logic [31:0] paddr;
    logic [31:0] pwdata;
    logic        penable;
    logic        pwrite;
    logic [31:0] prdata0;  //from RAM
    logic        pready0;  //from RAM
    logic [31:0] prdata1;  //from GPO
    logic        pready1;  //from GPO
    logic [31:0] prdata2;  //from GPI
    logic        pready2;  //from GPI
    logic [31:0] prdata3;  //from GPIO
    logic        pready3;  //from GPIO
    logic        pready4;  //from FND
    logic [31:0] prdata4;  //from FND
    logic        pready5;  //from UART
    logic [31:0] prdata5;  //from UART
    logic        psel0;  //ram
    logic        psel1;  //gpo
    logic        psel2;  //gpi
    logic        psel3;  //gpio
    logic        psel4;  //fnd
    logic        psel5;  //uart

    APB_MASTER dut (.*);


    always #5 pclk = ~pclk;



    initial begin
        pclk = 0;
        presetn = 1;
        wreq = 0;
        rreq = 0;
       /*
        prdata0 = 0;
        pready0 = 0;
        prdata1 = 0;
        pready1 = 0;
        prdata2 = 0;
        pready2 = 0;
        prdata3 = 0;
        pready3 = 0;
        pready4 = 0;
        prdata4 = 0;
        pready5 = 0;
        prdata5 = 0;
*/
        @(posedge pclk);
        presetn = 0;
        @(posedge pclk);
        presetn = 1;

        //ram write test
        @(posedge pclk);
        #1;
        wreq  = 1;
        addr  = 32'h1000_0000;
        wdata = 32'h00000041;  //A

        @(psel0 & penable);
        pready0 = 1;
        @(posedge pclk);
        #1;
        pready0 = 0;
         wreq = 0;
        @(posedge pclk);
    
        //uart read

        @(posedge pclk);
        #1;
        rreq = 1;
        addr = 32'h2000_4000;

        @(psel5 & penable);
        @(posedge pclk);
        @(posedge pclk);

        pready5 = 1;
        prdata5 = 32'h00000041;
        @(posedge pclk);
        #1;
        pready5 = 0;
        rreq = 0;
        @(posedge pclk);

        $stop;






    end
endmodule
