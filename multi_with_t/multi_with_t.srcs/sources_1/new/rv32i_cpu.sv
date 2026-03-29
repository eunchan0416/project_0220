`timescale 1ns / 1ps
`include "define.vh"

module rv32i_cpu (
    input               clk,
    input               rst,
    input        [31:0] instr_data,
    input        [31:0] bus_rdata,
    input               bus_ready,
    output logic [31:0] instr_addr,
    output logic        bus_wreq,
    output logic        bus_rreq,
    output logic [31:0] bus_addr,
    output logic [ 2:0] c2dm_funct3,
    output logic [31:0] bus_wdata
);

    logic rf_we, alusrcsel, branch, jal, jump, pc_en, ir_en;
    logic [2:0] rfwdsrcsel;
    logic [3:0] alucontrol;
    logic [31:0] instr_reg; // Instruction Register 추가

    // FETCH 상태일 때만 명령어를 래치하여 긴 타이밍 경로를 차단
    always_ff @(posedge clk or posedge rst) begin
        if (rst) instr_reg <= 32'b0;
        else if (ir_en) instr_reg <= instr_data;
    end

    control_unit U_CONTROL_UNIT (
        .clk        (clk),
        .rst        (rst),
        .funct7     (instr_reg[31:25]), // 래치된 명령어 사용
        .funct3     (instr_reg[14:12]),
        .opcode     (instr_reg[6:0]),
        .pc_en      (pc_en),
        .ir_en      (ir_en),            // 추가된 제어 신호
        .rf_we      (rf_we),
        .dwe        (bus_wreq),
        .dre        (bus_rreq),
        .ready      (bus_ready),
        .jump       (jump),
        .alusrcsel  (alusrcsel),
        .rfwdsrcsel (rfwdsrcsel),
        .alucontrol (alucontrol),
        .c2dm_funct3(c2dm_funct3),
        .branch     (branch),
        .jal        (jal)
    );

    rv32i_datapath U_DATAPATH (
        .clk       (clk),
        .rst       (rst),
        .alusrcsel (alusrcsel),
        .alucontrol(alucontrol),
        .jump      (jump),
        .pc_en     (pc_en),
        .rf_we     (rf_we),
        .branch    (branch),
        .jal       (jal),
        .rfwdsrcsel(rfwdsrcsel),
        .bus_rdata (bus_rdata),
        .instr_data(instr_reg),         // 래치된 명령어 사용
        .instr_addr(instr_addr),
        .bus_addr  (bus_addr),
        .bus_wdata (bus_wdata)
    );

endmodule

// ==========================================

module control_unit (
    input              clk,
    input              rst,
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    input              ready,
    output logic       pc_en,
    output logic       ir_en, // 추가됨
    output logic       rf_we,
    output logic       dwe,
    output logic       dre,
    output logic       jump,
    output logic [2:0] rfwdsrcsel,
    output logic       alusrcsel,
    output logic [2:0] c2dm_funct3,
    output logic [3:0] alucontrol,
    output logic       branch,
    output logic       jal
);

    typedef enum logic [2:0] {
        FETCH,
        DECODE,
        EXECUTE,
        MEM,
        WB
    } state_e;

    state_e c_st, n_st;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) c_st <= FETCH;
        else c_st <= n_st;
    end

    always_comb begin
        n_st = c_st;  // (Latch 방지)
        case (c_st)
            FETCH: n_st = DECODE;
            DECODE: n_st = EXECUTE;
            EXECUTE: begin
                case (opcode)
                    `R_TYPE, `I_TYPE, `U_LUI, `U_AUIPC, `JL_TYPE, `J_TYPE, `B_TYPE:
                    n_st = FETCH;
                    `S_TYPE, `IL_TYPE:
                    n_st = MEM;  
                    default: n_st = FETCH;
                endcase
            end
            MEM: begin
                case (opcode)
                    `IL_TYPE:
                        if (ready) n_st = WB;    
                    `S_TYPE:
                        if (ready) n_st = FETCH;  
                    default: n_st = FETCH;
                endcase
            end
            WB: begin
                    n_st = FETCH; 
            end
        endcase
    end

    always_comb begin
        pc_en       = 0;
        ir_en       = 0; // 추가됨
        jal         = 0;
        jump        = 0;
        branch      = 0;
        rfwdsrcsel  = 0;
        dwe         = 0;
        dre         = 0;
        rf_we       = 0;
        alusrcsel   = 0;
        alucontrol  = 4'b0000;
        c2dm_funct3 = 0;

        case (c_st)
            FETCH: begin
                ir_en = 1; // 명령어 래치 활성화
                // pc_en = 1; 은 여기서 제거하여 다음 주소로 넘어가는 버그 수정
            end

            DECODE: begin
            end

            EXECUTE: begin
                case (opcode)
                    `R_TYPE: begin
                        rf_we = 1;
                        rfwdsrcsel = 0;
                        alusrcsel = 0;
                        alucontrol = {funct7[5], funct3};
                        pc_en = 1; // 명령어 완료 시 PC 업데이트
                    end
                    `I_TYPE: begin
                        rf_we = 1;
                        rfwdsrcsel = 0;
                        alusrcsel = 1;
                        if (funct3 == 3'b101) alucontrol = {funct7[5], funct3};
                        else alucontrol = {1'b0, funct3};
                        pc_en = 1; // 명령어 완료 시 PC 업데이트
                    end
                    `B_TYPE: begin
                        branch     = 1;
                        alusrcsel  = 0;
                        alucontrol = {1'b0, funct3};
                        pc_en = 1; // 명령어 완료 시 PC 업데이트
                    end
                    `S_TYPE, `IL_TYPE: begin
                        alusrcsel  = 1;
                        alucontrol = 4'b0000;  // ADD 연산
                    end
                    `JL_TYPE: begin
                        rf_we      = 1;
                        rfwdsrcsel = 4;
                        jal        = 1;
                        alusrcsel  = 1;
                        pc_en = 1; // 명령어 완료 시 PC 업데이트
                    end
                    `J_TYPE: begin
                        rf_we      = 1;
                        rfwdsrcsel = 4;
                        jump       = 1;
                        pc_en = 1; // 명령어 완료 시 PC 업데이트
                    end
                    `U_LUI: begin
                        rf_we = 1;
                        rfwdsrcsel = 2;
                        pc_en = 1; // 명령어 완료 시 PC 업데이트
                    end
                    `U_AUIPC: begin
                        rf_we = 1;
                        rfwdsrcsel = 3;  // PC + 상수
                        pc_en = 1; // 명령어 완료 시 PC 업데이트
                    end
                endcase
            end

            MEM: begin
                //il type
                c2dm_funct3 = funct3;
                dre = 1;
                if (opcode == `S_TYPE) begin
                    dwe = 1; 
                    dre = 0; // Store일 때만 쓰기 켬
                    if (ready) pc_en = 1; // Store 완료 시 PC 업데이트
                end
            end

            WB: begin  
                rf_we = 1;
                rfwdsrcsel = 1;  // 메모리에서 읽은 값
                pc_en = 1;       // Load 완료 시 PC 업데이트
            end
        endcase
    end

endmodule