`timescale 1ns / 1ps

// ============================================================================
// 1. Interface & SVA (하드웨어 타이밍 감시 및 스펙 보호)
// ============================================================================
interface top_interface (input bit clk);
    logic reset;
    logic [2:0] sw;
    logic btn_r, btn_l;
    logic [23:0] watch_time;
    logic [23:0] stopwatch_time;

    // 내부 상태 백도어 모니터링 포트
    logic mon_run_stop;        
    logic mon_clear;         
    logic mon_watch_up_r;    
    logic mon_watch_up_l;    
    logic mon_w_tick_100hz;   
    logic mon_sw_tick_100hz;  

    // 규칙 1: 리셋 초기화 확인
    property p_reset_spec;
        @(posedge clk) reset |=> (stopwatch_time == 24'h0) && (watch_time[23:19] == 5'd12);
    endproperty
    assert_reset: assert property(p_reset_spec) else $error("[SVA FAIL] Reset initialization failed!");

    // 규칙 2: 스톱워치 STOP 상태에서 Clear 정상 동작 확인
    property p_sw_clear_valid;
        @(posedge clk) disable iff(reset)
        (!sw[1] && (mon_run_stop == 0) && btn_l) |=> (stopwatch_time == 24'h0);
    endproperty
    assert_clear_valid: assert property(p_sw_clear_valid) else $error("[SVA FAIL] Clear during STOP state failed!");

    // 규칙 3: 스톱워치 RUN 상태에서 Clear 신호 무시 (보호 로직) 확인
    property p_sw_clear_ignore;
        @(posedge clk) disable iff(reset)
        (!sw[1] && (mon_run_stop == 1) && btn_l) |-> (mon_clear == 0);
    endproperty
    assert_clear_ignore: assert property(p_sw_clear_ignore) else $error("[SVA FAIL] o_clear signal is active during RUN state!");

    // 규칙 4: 시계 수정 모드가 아닐 때, 자연 틱 없이 버튼만으로 시간이 변하지 않아야 함
    property p_watch_protect;
        @(posedge clk) disable iff(reset)
        (sw[1] && !sw[0] && (btn_r || btn_l) && !mon_w_tick_100hz) 
        |=> 
        $stable(watch_time); 
    endproperty
    assert_watch_protect: assert property(p_watch_protect) 
        else $error("[SVA FAIL] Watch time increased by button while NOT in setting mode!");
endinterface

// ============================================================================
// 2. Transaction (데이터 전달 객체 및 Display 함수)
// ============================================================================
class watch_transaction;
    rand bit reset;
    rand logic [2:0] sw;
    rand bit btn_r, btn_l;

    logic [23:0] watch_time;
    logic [23:0] stopwatch_time;
    logic current_run_stop; 
    logic tick_100hz_w;
    logic tick_100hz_sw;

    // 입력(Input) 신호 상태를 출력하는 함수
    function void print_input(string comp_name);
        $display("[%s] Time: %0t | RST:%b SW:%3b R:%b L:%b", 
                 comp_name, $time, reset, sw, btn_r, btn_l);
    endfunction

    // 출력(Output) 시간 상태를 출력하는 함수
    function void print_output(string comp_name);
        $display("[%s] Time: %0t | W_TIME: %02d:%02d:%02d.%02d | SW_TIME: %02d:%02d:%02d.%02d", 
                 comp_name, $time, 
                 watch_time[23:19], watch_time[18:13], watch_time[12:7], watch_time[6:0],
                 stopwatch_time[23:19], stopwatch_time[18:13], stopwatch_time[12:7], stopwatch_time[6:0]);
    endfunction
endclass

// ============================================================================
// 3. Generator (시나리오 사령부)
// ============================================================================
class generator;
    watch_transaction tr;
    mailbox #(watch_transaction) gen2drv_mbox;
    event scb2gen_ev;

    function new(mailbox #(watch_transaction) g2d, event ev);
        this.gen2drv_mbox = g2d; this.scb2gen_ev = ev;
    endfunction

    // 시나리오 1: 기본 시계 워밍업
    task run_normal_watch(int count);
        $display("[GEN] --- Start Normal Watch Scenario ---");
        repeat(count) begin
            tr = new();
            assert(tr.randomize() with {
                reset == 0; sw[1] == 1; sw[0] == 0; 
            });
            tr.print_input("GEN"); 
            gen2drv_mbox.put(tr); 
            @(scb2gen_ev);
        end
    endtask

    // 시나리오 2: 스톱워치 정밀 검증 (충분한 시간 대기)
    task run_stopwatch_test();
        $display("[GEN] --- Start Stopwatch Directed Scenario ---");
        
        // 1. 스톱워치 모드 진입
        tr = new(); assert(tr.randomize() with { reset==0; sw==3'b000; btn_r==0; btn_l==0; });
        gen2drv_mbox.put(tr); @(scb2gen_ev);

        // 2. START 버튼 클릭
        $display("[GEN] Stopwatch START! Waiting for 10ms to see increment...");
        tr = new(); assert(tr.randomize() with { reset==0; sw==3'b000; btn_r==1; btn_l==0; });
        gen2drv_mbox.put(tr); @(scb2gen_ev);

        // 3. 버튼 떼고 1,000,001 클럭 대기 (msec가 0 -> 1이 되는 것을 확인)
        repeat(1000010) begin
            tr = new(); assert(tr.randomize() with { reset==0; sw==3'b000; btn_r==0; btn_l==0; });
            gen2drv_mbox.put(tr); @(scb2gen_ev);
        end

        // 4. STOP 버튼 클릭
        $display("[GEN] Stopwatch STOP!");
        tr = new(); assert(tr.randomize() with { reset==0; sw==3'b000; btn_r==1; btn_l==0; });
        gen2drv_mbox.put(tr); @(scb2gen_ev);

        // 5. CLEAR 버튼 클릭
        $display("[GEN] Stopwatch CLEAR!");
        tr = new(); assert(tr.randomize() with { reset==0; sw==3'b000; btn_r==0; btn_l==1; });
        gen2drv_mbox.put(tr); @(scb2gen_ev);
    endtask

    // 시나리오 3: 무작위 스트레스 폭격 테스트
    task run_random_stress(int count);
        $display("[GEN] --- Start Deep Random Stress Scenario ---");
        repeat(count) begin
            tr = new();
            assert(tr.randomize() with {
                reset dist {1 := 1, 0 := 99};  
                sw[1] dist {1 := 50, 0 := 50}; 
                sw[0] dist {1 := 20, 0 := 80}; 
                btn_r dist {1 := 10, 0 := 90}; 
                btn_l dist {1 := 10, 0 := 90};
            });
            gen2drv_mbox.put(tr); 
            @(scb2gen_ev);
        end
    endtask
endclass

// ============================================================================
// 4. Driver & 5. Monitor
// ============================================================================
class driver;
    virtual top_interface top_if;
    mailbox #(watch_transaction) gen2drv_mbox;

    function new(mailbox #(watch_transaction) g2d, virtual top_interface ifc);
        this.gen2drv_mbox = g2d; this.top_if = ifc;
    endfunction

    task run();
        top_if.reset = 1; top_if.sw = 0; top_if.btn_r = 0; top_if.btn_l = 0;
        repeat(5) @(posedge top_if.clk);
        top_if.reset = 0;

        forever begin
            watch_transaction tr;
            gen2drv_mbox.get(tr);
            @(posedge top_if.clk); #1; // Setup Time 모사
            
            top_if.reset = tr.reset; 
            top_if.sw    = tr.sw;
            top_if.btn_r = tr.btn_r; 
            top_if.btn_l = tr.btn_l;
        end
    endtask
endclass

class monitor;
    virtual top_interface top_if;
    mailbox #(watch_transaction) mon2scb_mbox;
    
    // 이전 값을 저장하여, 값이 변할 때만 출력하기 위한 변수 (콘솔창 과부하 방지)
    logic [2:0] prev_sw;
    logic prev_btn_r, prev_btn_l, prev_reset;
    logic [23:0] prev_w_time, prev_sw_time;

    function new(mailbox #(watch_transaction) m2s, virtual top_interface ifc);
        this.mon2scb_mbox = m2s; this.top_if = ifc;
    endfunction

    task run();
        forever begin
            watch_transaction tr = new();
            @(negedge top_if.clk); // 연산 안정화 후 Hold Time 캡처

            tr.reset = top_if.reset; tr.sw = top_if.sw;
            tr.btn_r = top_if.btn_r; tr.btn_l = top_if.btn_l;
            tr.watch_time = top_if.watch_time;
            tr.stopwatch_time = top_if.stopwatch_time;
            
            tr.current_run_stop = top_if.mon_run_stop; 
            tr.tick_100hz_w     = top_if.mon_w_tick_100hz;
            tr.tick_100hz_sw    = top_if.mon_sw_tick_100hz;
            
            // 입력이나 출력 시간에 변화가 있을 때만 모니터 로그 출력
            if (tr.sw != prev_sw || tr.btn_r != prev_btn_r || tr.btn_l != prev_btn_l || tr.reset != prev_reset ||
                tr.watch_time != prev_w_time || tr.stopwatch_time != prev_sw_time) begin
                tr.print_output("MON");
                prev_sw = tr.sw; prev_btn_r = tr.btn_r; prev_btn_l = tr.btn_l; prev_reset = tr.reset;
                prev_w_time = tr.watch_time; prev_sw_time = tr.stopwatch_time;
            end

            mon2scb_mbox.put(tr);
        end
    endtask
endclass

// ============================================================================
// 6. Scoreboard (백그라운드 시계 동작 및 완벽한 PASS 로깅 추가)
// ============================================================================
class scoreboard;
    mailbox #(watch_transaction) mon2scb_mbox;
    event scb2gen_ev;
    watch_transaction tr;

    logic [4:0] e_w_h; logic [5:0] e_w_m; logic [5:0] e_w_s; logic [6:0] e_w_ms;
    logic [4:0] e_sw_h; logic [5:0] e_sw_m; logic [5:0] e_sw_s; logic [6:0] e_sw_ms;
    bit is_sw_running;

    // 이전 예상값을 저장하여 값이 '변할 때만' 디스플레이하기 위한 변수
    logic [23:0] prev_e_w, prev_e_sw; 

    covergroup cg_signoff;
        cp_run_clear: coverpoint (tr.current_run_stop == 1 && tr.btn_l == 1) { bins hit = {1}; }
        cp_mode_change: coverpoint tr.sw[1] { bins to_watch = (0 => 1); bins to_stopwatch = (1 => 0); }
        cp_enter_setting: coverpoint tr.sw[0] { bins enter = (0 => 1); }
    endgroup

    function new(mailbox #(watch_transaction) m2s, event ev);
        this.mon2scb_mbox = m2s; this.scb2gen_ev = ev;
        cg_signoff = new();
        e_w_h = 12; e_w_m = 0; e_w_s = 0; e_w_ms = 0;
        e_sw_h = 0; e_sw_m = 0; e_sw_s = 0; e_sw_ms = 0;
        prev_e_w = 0; prev_e_sw = 0;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            cg_signoff.sample();

            if (tr.reset) begin
                e_w_h = 12; e_w_m = 0; e_w_s = 0; e_w_ms = 0;
                e_sw_h = 0; e_sw_m = 0; e_sw_s = 0; e_sw_ms = 0;
                is_sw_running = 0;
            end 
            else begin
                // 현재 예측값 묶기
                logic [23:0] current_e_w  = {e_w_h, e_w_m, e_w_s, e_w_ms};
                logic [23:0] current_e_sw = {e_sw_h, e_sw_m, e_sw_s, e_sw_ms};

                // =======================================================
                // [1] Checker (1클럭 딜레이 동기화 및 PASS 디스플레이)
                // =======================================================
                if (tr.stopwatch_time[6:0] !== e_sw_ms) 
                    $error("[SCB FAIL] SW MSEC error! expected:%d, real:%d", e_sw_ms, tr.stopwatch_time[6:0]);
                else if (tr.watch_time[6:0] !== e_w_ms)
                    $error("[SCB FAIL] W MSEC error! expected:%d, real:%d", e_w_ms, tr.watch_time[6:0]);
                else begin
                    // 에러가 없는데 시간 값이 1이라도 변했거나 조작되었다면 로그 출력!
                    if (current_e_w != prev_e_w || current_e_sw != prev_e_sw) begin
                        $display("[SCB PASS] Time:%0t | MATCH! | EXP_W: %02d:%02d:%02d.%02d | EXP_SW: %02d:%02d:%02d.%02d", 
                                 $time, e_w_h, e_w_m, e_w_s, e_w_ms, e_sw_h, e_sw_m, e_sw_s, e_sw_ms);
                        
                        // 현재 값을 이전 값으로 업데이트
                        prev_e_w = current_e_w;
                        prev_e_sw = current_e_sw;
                    end
                end

                // =======================================================
                // [2] 스톱워치 모델 (예상값 연산)
                // =======================================================
                if (tr.sw[1] == 0) begin 
                    if (tr.btn_r) is_sw_running = ~is_sw_running;
                    if (!is_sw_running && tr.btn_l) begin e_sw_h = 0; e_sw_m = 0; e_sw_s = 0; e_sw_ms = 0; end
                end
                
                if (is_sw_running && tr.tick_100hz_sw) begin
                    if (tr.sw[0] == 1) begin if (e_sw_ms == 0) e_sw_ms = 99; else e_sw_ms--; end
                    else begin if (e_sw_ms == 99) begin e_sw_ms = 0; e_sw_s++; end else e_sw_ms++; end
                end

                // =======================================================
                // [3] 시계 모델 (백그라운드 동작 반영)
                // =======================================================
                // 시간 수정 모드
                if (tr.sw[1] == 1 && tr.sw[0] == 1) begin
                    if (tr.sw[2] == 1) begin 
                        if (tr.btn_l) e_w_h = (e_w_h == 23) ? 0 : e_w_h + 1;
                        if (tr.btn_r) e_w_m = (e_w_m == 59) ? 0 : e_w_m + 1;
                    end else begin           
                        if (tr.btn_l) e_w_s = (e_w_s == 59) ? 0 : e_w_s + 1;
                        if (tr.btn_r) e_w_ms = (e_w_ms == 99) ? 0 : e_w_ms + 1;
                    end
                end 
                // 자연 틱 흐름 모드
                else if (tr.tick_100hz_w && (tr.sw[1] == 0 || tr.sw[0] == 0)) begin
                    if (e_w_ms == 99) begin e_w_ms = 0; if (e_w_s == 59) begin e_w_s = 0; e_w_m++; end else e_w_s++; end
                    else e_w_ms++;
                end
            end
            ->scb2gen_ev;
        end
    endtask
endclass

// ============================================================================
// 7. Environment & 8. Top Module
// ============================================================================
class environment;
    generator gen; driver drv; monitor mon; scoreboard scb;
    mailbox #(watch_transaction) g2d, m2s; event ev;

    function new(virtual top_interface ifc);
        g2d = new(); m2s = new();
        gen = new(g2d, ev); drv = new(g2d, ifc);
        mon = new(m2s, ifc); scb = new(m2s, ev);
    endfunction

    task run();
        fork drv.run(); mon.run(); scb.run(); join_none
        
        gen.run_normal_watch(50);     // 1. 워밍업
        gen.run_stopwatch_test();     // 2. 스톱워치 정밀 시나리오
        gen.run_random_stress(1000);  // 3. 랜덤 스트레스 테스트
        
        #100;
        $display("==============================================");
        $display("   TAPE-OUT VERIFICATION SIGN-OFF REPORT      ");
        $display("   Functional Coverage: %.2f %%", scb.cg_signoff.get_inst_coverage());
        $display("==============================================");
        $stop;
    endtask
endclass

module tb_top_watch();
    bit clk;
    top_interface top_if(clk);
    environment env;

    top_stopwatch_watch dut (
        .clk(top_if.clk),
        .reset(top_if.reset),
        .sw(top_if.sw),
        .btn_r(top_if.btn_r),
        .btn_l(top_if.btn_l),
        .watch_time(top_if.watch_time),
        .stopwatch_time(top_if.stopwatch_time)
    );

    // 내부 신호 연결
    assign top_if.mon_run_stop      = dut.U_CONTROL_UNIT.o_run_stop;
    assign top_if.mon_clear         = dut.U_CONTROL_UNIT.o_clear;         
    assign top_if.mon_watch_up_r    = dut.U_CONTROL_UNIT.o_watch_up_r;    
    assign top_if.mon_watch_up_l    = dut.U_CONTROL_UNIT.o_watch_up_l;    
    assign top_if.mon_w_tick_100hz  = dut.U_WATCH_DATAPATH.w_tick_100hz;
    assign top_if.mon_sw_tick_100hz = dut.U_STOPWATCH_DATAPATH.w_tick_100hz;
    
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(top_if);
        env.run();
    end
endmodule
