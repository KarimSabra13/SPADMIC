`timescale 1ns/1ps

// =============================================================================
// Self-checking unit testbench for mptdc_ctrl_fsm_v2
// =============================================================================
module tb_fsm_v2_unit;
  import mptdc_pkg::*;

  // -----------------------------------------------------------
  // Clock (160 MHz)
  // -----------------------------------------------------------
  logic clk_sys;
  initial clk_sys = 0;
  always #3.125 clk_sys = ~clk_sys;

  // -----------------------------------------------------------
  // DUT signals
  // -----------------------------------------------------------
  logic                   rst_n;
  logic                   conv_arm_i;
  logic                   start_seen_sync_i;
  logic                   stop_seen_sync_i;
  logic                   writer_done_sync_i;
  logic [MAX_HITS_W-1:0]  hit_count_sync_i;
  logic [NFAST_W-1:0]     nfast_cnt_sync_i;
  mode_e                  mode_cfg_i;
  logic [MAX_HITS_W-1:0]  max_hits_cfg_i;
  logic                   all_ctx_busy_i;
  logic                   wdt_force_close_i;

  logic                   ready_o;
  logic                   busy_o;
  logic                   osc_slow_en_o;
  logic                   osc_fast_en_o;
  logic                   pd_enable_o;
  logic                   capture_pulse_o;
  logic                   fe_clear_o;
  logic                   conv_done_o;
  tdc_conv_flags_t        flags_o;
  fsm_state_e             state_o;

  // -----------------------------------------------------------
  // DUT
  // -----------------------------------------------------------
  mptdc_ctrl_fsm_v2 dut (.*);

  // -----------------------------------------------------------
  // VCD
  // -----------------------------------------------------------
  initial begin
    $dumpfile("tb_fsm_v2_unit.vcd");
    $dumpvars(0, tb_fsm_v2_unit);
  end

  // -----------------------------------------------------------
  // Registered pulse shadows (Verilator evaluates comb only at
  // posedge, so capture combinational pulses in FFs)
  // -----------------------------------------------------------
  logic conv_done_q;
  logic capture_pulse_q;
  logic [7:0] conv_done_cnt;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      conv_done_q     <= 1'b0;
      capture_pulse_q <= 1'b0;
      conv_done_cnt   <= '0;
    end else begin
      conv_done_q     <= conv_done_o;
      capture_pulse_q <= capture_pulse_o;
      if (conv_done_o) conv_done_cnt <= conv_done_cnt + 8'd1;
    end
  end

  // -----------------------------------------------------------
  // Scoreboard
  // -----------------------------------------------------------
  int fail_count;
  int pass_count;

  // -----------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------
  task automatic init_inputs();
    conv_arm_i         = 0;
    start_seen_sync_i  = 0;
    stop_seen_sync_i   = 0;
    writer_done_sync_i = 0;
    hit_count_sync_i   = '0;
    nfast_cnt_sync_i   = '0;
    mode_cfg_i         = MODE_MULTI_HIT;
    max_hits_cfg_i     = 4'd15;
    all_ctx_busy_i     = 0;
    wdt_force_close_i  = 0;
  endtask

  task automatic do_reset();
    rst_n = 0;
    init_inputs();
    repeat (4) @(posedge clk_sys);
    rst_n = 1;
    @(posedge clk_sys);
  endtask

  task automatic check(string name, logic cond);
    if (cond) begin
      $display("[PASS] %s", name);
      pass_count++;
    end else begin
      $display("[FAIL] %s", name);
      fail_count++;
    end
  endtask

  // ARM → START → wait one edge so state_q = ST_ACTIVE
  task automatic arm_and_start();
    @(posedge clk_sys);
    conv_arm_i = 1;
    @(posedge clk_sys);         // armed_q latched
    conv_arm_i = 0;
    start_seen_sync_i = 1;
    @(posedge clk_sys);         // state_q → ST_ACTIVE
    start_seen_sync_i = 0;
  endtask

  // Writer done → back to IDLE
  task automatic complete_drain();
    writer_done_sync_i = 1;
    @(posedge clk_sys);
    writer_done_sync_i = 0;
  endtask

  // =========================================================
  // Test 1: Normal conversion lifecycle
  // =========================================================
  task automatic test_normal_conversion();
    $display("\n=== Test 1: Normal conversion ===");
    do_reset();

    check("T1.1 Initial ST_IDLE",       state_o == ST_IDLE);
    check("T1.2 Initial ready=1",       ready_o == 1'b1);
    check("T1.3 Initial busy=0",        busy_o  == 1'b0);

    // ARM
    @(posedge clk_sys);
    conv_arm_i = 1;
    @(posedge clk_sys);
    conv_arm_i = 0;
    check("T1.4 IDLE after arm",        state_o == ST_IDLE);
    check("T1.5 ready=0 (armed)",       ready_o == 1'b0);

    // START
    start_seen_sync_i = 1;
    @(posedge clk_sys);
    start_seen_sync_i = 0;
    check("T1.6 ST_ACTIVE after start", state_o == ST_ACTIVE);
    check("T1.7 busy=1",               busy_o  == 1'b1);

    repeat (3) @(posedge clk_sys);

    // STOP
    stop_seen_sync_i = 1;
    @(posedge clk_sys);
    stop_seen_sync_i = 0;
    check("T1.8 ST_DRAIN_WAIT",        state_o == ST_DRAIN_WAIT);

    // WRITER DONE
    writer_done_sync_i = 1;
    @(posedge clk_sys);
    writer_done_sync_i = 0;
    check("T1.9 conv_done pulsed",      conv_done_q == 1'b1);
    check("T1.10 ST_IDLE after done",   state_o == ST_IDLE);
    check("T1.11 ready=1",             ready_o == 1'b1);
    @(posedge clk_sys);
    check("T1.12 conv_done cleared",   conv_done_q == 1'b0);
  endtask

  // =========================================================
  // Test 2: First-hit early closure
  // =========================================================
  task automatic test_first_hit_closure();
    $display("\n=== Test 2: First-hit early closure ===");
    do_reset();
    mode_cfg_i = MODE_FIRST_HIT;

    arm_and_start();
    check("T2.1 ST_ACTIVE",             state_o == ST_ACTIVE);

    // Inject hit_count >= 1
    hit_count_sync_i = 4'd1;
    @(posedge clk_sys);
    hit_count_sync_i = '0;
    check("T2.2 capture_pulse fired",   capture_pulse_q == 1'b1);
    check("T2.3 ST_DRAIN_WAIT",         state_o == ST_DRAIN_WAIT);
    check("T2.4 firsthit flag",         flags_o.closed_by_firsthit == 1'b1);
    check("T2.5 maxhits=0",             flags_o.closed_by_maxhits  == 1'b0);

    complete_drain();
    check("T2.6 Back to IDLE",          state_o == ST_IDLE);
  endtask

  // =========================================================
  // Test 3: Max-hits early closure
  // =========================================================
  task automatic test_max_hits_closure();
    $display("\n=== Test 3: Max-hits early closure ===");
    do_reset();
    mode_cfg_i     = MODE_MULTI_HIT;
    max_hits_cfg_i = 4'd5;

    arm_and_start();
    check("T3.1 ST_ACTIVE",             state_o == ST_ACTIVE);

    hit_count_sync_i = 4'd5;
    @(posedge clk_sys);
    check("T3.2 capture_pulse fired",   capture_pulse_q == 1'b1);
    check("T3.3 ST_DRAIN_WAIT",         state_o == ST_DRAIN_WAIT);
    check("T3.4 maxhits flag",          flags_o.closed_by_maxhits  == 1'b1);
    check("T3.5 firsthit=0",            flags_o.closed_by_firsthit == 1'b0);

    hit_count_sync_i = '0;
    complete_drain();
    check("T3.6 Back to IDLE",          state_o == ST_IDLE);
  endtask

  // =========================================================
  // Test 4: Watchdog force close
  // =========================================================
  task automatic test_watchdog_close();
    $display("\n=== Test 4: Watchdog force close ===");
    do_reset();

    arm_and_start();
    check("T4.1 ST_ACTIVE",             state_o == ST_ACTIVE);

    wdt_force_close_i = 1;
    @(posedge clk_sys);
    wdt_force_close_i = 0;
    check("T4.2 capture_pulse fired",   capture_pulse_q == 1'b1);
    check("T4.3 ST_DRAIN_WAIT",         state_o == ST_DRAIN_WAIT);
    check("T4.4 watchdog flag",          flags_o.closed_by_watchdog == 1'b1);

    complete_drain();
    check("T4.5 Back to IDLE",          state_o == ST_IDLE);
  endtask

  // =========================================================
  // Test 5: All contexts busy blocks arming
  // =========================================================
  task automatic test_all_ctx_busy();
    $display("\n=== Test 5: All contexts busy ===");
    do_reset();
    all_ctx_busy_i = 1;

    // ARM attempt — should be blocked
    @(posedge clk_sys);
    conv_arm_i = 1;
    @(posedge clk_sys);
    conv_arm_i = 0;
    check("T5.1 ready=1 (not armed)",   ready_o == 1'b1);
    check("T5.2 Still IDLE",            state_o == ST_IDLE);

    // START without arm should do nothing
    start_seen_sync_i = 1;
    @(posedge clk_sys);
    start_seen_sync_i = 0;
    check("T5.3 Still IDLE",            state_o == ST_IDLE);

    // Release busy — arm should now work
    all_ctx_busy_i = 0;
    @(posedge clk_sys);
    conv_arm_i = 1;
    @(posedge clk_sys);
    conv_arm_i = 0;
    check("T5.4 ready=0 (armed)",       ready_o == 1'b0);
  endtask

  // =========================================================
  // Test 6: Ready/busy tracking
  // =========================================================
  task automatic test_ready_busy_tracking();
    $display("\n=== Test 6: Ready/busy tracking ===");
    do_reset();

    check("T6.1 IDLE: r=1,b=0",         ready_o == 1 && busy_o == 0);

    @(posedge clk_sys);
    conv_arm_i = 1;
    @(posedge clk_sys);
    conv_arm_i = 0;
    check("T6.2 Armed: r=0,b=0",        ready_o == 0 && busy_o == 0);

    start_seen_sync_i = 1;
    @(posedge clk_sys);
    start_seen_sync_i = 0;
    check("T6.3 Active: r=0,b=1",       ready_o == 0 && busy_o == 1);

    stop_seen_sync_i = 1;
    @(posedge clk_sys);
    stop_seen_sync_i = 0;
    check("T6.4 Drain: r=0,b=1",        ready_o == 0 && busy_o == 1);

    complete_drain();
    check("T6.5 Done: r=1,b=0",         ready_o == 1 && busy_o == 0);
  endtask

  // =========================================================
  // Test 7: conv_done is single-cycle pulse
  // =========================================================
  task automatic test_conv_done_pulse();
    $display("\n=== Test 7: conv_done single-cycle pulse ===");
    do_reset();

    arm_and_start();

    stop_seen_sync_i = 1;
    @(posedge clk_sys);
    stop_seen_sync_i = 0;

    // Idle in DRAIN_WAIT — conv_done must be 0
    repeat (3) @(posedge clk_sys);
    check("T7.1 conv_done=0 during drain", conv_done_o == 1'b0);

    // Assert writer_done — pulse appears
    writer_done_sync_i = 1;
    @(posedge clk_sys);
    writer_done_sync_i = 0;
    check("T7.2 conv_done pulsed",      conv_done_q == 1'b1);

    // Cleared next cycle
    @(posedge clk_sys);
    check("T7.3 conv_done=0 next cycle", conv_done_q == 1'b0);

    // Stays low and exactly 1 pulse total
    repeat (2) @(posedge clk_sys);
    check("T7.4 stays 0",               conv_done_q == 1'b0);
    check("T7.5 exactly 1 pulse",       conv_done_cnt == 8'd1);
  endtask

  // =========================================================
  // Test 8: fe_clear level during DRAIN_WAIT
  // =========================================================
  task automatic test_fe_clear_level();
    $display("\n=== Test 8: fe_clear level ===");
    do_reset();

    check("T8.1 fe_clear=0 in IDLE",    fe_clear_o == 1'b0);

    arm_and_start();
    check("T8.2 fe_clear=0 in ACTIVE",  fe_clear_o == 1'b0);

    stop_seen_sync_i = 1;
    @(posedge clk_sys);
    stop_seen_sync_i = 0;
    check("T8.3 fe_clear=1 entering DRAIN", fe_clear_o == 1'b1);

    repeat (5) @(posedge clk_sys);
    check("T8.4 fe_clear=1 sustained",  fe_clear_o == 1'b1);

    complete_drain();
    check("T8.5 fe_clear=0 in IDLE",    fe_clear_o == 1'b0);
  endtask

  // =========================================================
  // Test 9: Flags correctness
  // =========================================================
  task automatic test_flags_correctness();
    $display("\n=== Test 9: Flags correctness ===");

    // 9a: Normal stop — no flags set
    do_reset();
    arm_and_start();
    stop_seen_sync_i = 1;
    @(posedge clk_sys);
    stop_seen_sync_i = 0;
    check("T9.1 Normal: flags=0",       flags_o == '0);
    complete_drain();

    // 9b: First-hit
    do_reset();
    mode_cfg_i = MODE_FIRST_HIT;
    arm_and_start();
    hit_count_sync_i = 4'd1;
    @(posedge clk_sys);
    check("T9.2 firsthit=1",            flags_o.closed_by_firsthit == 1'b1);
    check("T9.3 maxhits=0",             flags_o.closed_by_maxhits  == 1'b0);
    check("T9.4 watchdog=0",            flags_o.closed_by_watchdog == 1'b0);
    hit_count_sync_i = '0;
    complete_drain();

    // 9c: Max-hits
    do_reset();
    mode_cfg_i     = MODE_MULTI_HIT;
    max_hits_cfg_i = 4'd3;
    arm_and_start();
    hit_count_sync_i = 4'd3;
    @(posedge clk_sys);
    check("T9.5 maxhits=1",             flags_o.closed_by_maxhits  == 1'b1);
    check("T9.6 firsthit=0",            flags_o.closed_by_firsthit == 1'b0);
    hit_count_sync_i = '0;
    complete_drain();

    // 9d: Watchdog
    do_reset();
    arm_and_start();
    wdt_force_close_i = 1;
    @(posedge clk_sys);
    wdt_force_close_i = 0;
    check("T9.7 watchdog=1",            flags_o.closed_by_watchdog == 1'b1);
    complete_drain();

    // 9e: Overflow (hit_count >= MAX_HITS=15)
    do_reset();
    mode_cfg_i     = MODE_MULTI_HIT;
    max_hits_cfg_i = 4'd15;
    arm_and_start();
    hit_count_sync_i = 4'd15;
    @(posedge clk_sys);
    check("T9.8 overflow=1",            flags_o.overflow == 1'b1);
    check("T9.9 maxhits=1 at overflow", flags_o.closed_by_maxhits == 1'b1);
    hit_count_sync_i = '0;
    complete_drain();
  endtask

  // =========================================================
  // Main
  // =========================================================
  initial begin
    fail_count = 0;
    pass_count = 0;

    test_normal_conversion();
    test_first_hit_closure();
    test_max_hits_closure();
    test_watchdog_close();
    test_all_ctx_busy();
    test_ready_busy_tracking();
    test_conv_done_pulse();
    test_fe_clear_level();
    test_flags_correctness();

    $display("\n========================================");
    $display("  %0d checks passed, %0d failed", pass_count, fail_count);
    $display("========================================");
    if (fail_count == 0) begin
      $display("TEST PASSED");
    end else begin
      $display("TEST FAILED");
      $fatal(1, "%0d check(s) failed", fail_count);
    end
    $finish;
  end

endmodule
