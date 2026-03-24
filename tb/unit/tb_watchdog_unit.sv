`timescale 1ns / 1ps
`default_nettype none

module tb_watchdog_unit;
  import mptdc_pkg::*;

  // ---------------------------------------------------------------
  // Clock: 160 MHz → 6.25 ns period → 3.125 ns half-period
  // ---------------------------------------------------------------
  logic clk_sys;
  initial clk_sys = 0;
  always #3.125 clk_sys = ~clk_sys;

  // ---------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------
  logic        rst_n;
  ctx_state_e  ctx_state [N_CTX-1:0];
  logic        conv_done;
  logic [15:0] wdt_ctx_timeout;
  logic [15:0] wdt_global_timeout;
  logic        wdt_force_close;
  logic        wdt_force_reset;
  logic [7:0]  wdt_ctx_trip_cnt;
  logic [7:0]  wdt_global_trip_cnt;

  // ---------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------
  mptdc_watchdog u_dut (
    .clk_sys              (clk_sys),
    .rst_n                (rst_n),
    .ctx_state_i          (ctx_state),
    .conv_done_i          (conv_done),
    .wdt_ctx_timeout_i    (wdt_ctx_timeout),
    .wdt_global_timeout_i (wdt_global_timeout),
    .wdt_force_close_o    (wdt_force_close),
    .wdt_force_reset_o    (wdt_force_reset),
    .wdt_ctx_trip_cnt_o   (wdt_ctx_trip_cnt),
    .wdt_global_trip_cnt_o(wdt_global_trip_cnt)
  );

  // ---------------------------------------------------------------
  // Scoreboard
  // ---------------------------------------------------------------
  int pass_cnt = 0;
  int fail_cnt = 0;

  task automatic check(input string name, input int cond);
    if (cond) begin
      $display("[PASS] %s", name);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s (fc=%0b fr=%0b ctx_tc=%0d glb_tc=%0d)",
               name, wdt_force_close, wdt_force_reset,
               wdt_ctx_trip_cnt, wdt_global_trip_cnt);
      fail_cnt++;
    end
  endtask

  // ---------------------------------------------------------------
  // Reset: async assert, sync deassert, clear all inputs
  // ---------------------------------------------------------------
  task automatic reset_dut();
    rst_n              = 1'b0;
    conv_done          = 1'b0;
    wdt_ctx_timeout    = 16'd0;
    wdt_global_timeout = 16'd0;
    for (int i = 0; i < N_CTX; i++) ctx_state[i] = CTX_FREE;
    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    @(posedge clk_sys);
  endtask

  // ---------------------------------------------------------------
  // Main test sequence
  // ---------------------------------------------------------------
  initial begin
    $display("========================================");
    $display(" tb_watchdog_unit — Self-checking tests");
    $display("========================================");

    // ==========================================================
    // Test 1: Per-context timeout fires
    // ==========================================================
    $display("\n--- Test 1: Per-context timeout fires ---");
    reset_dut();
    wdt_ctx_timeout = 16'd100;
    ctx_state[0]    = CTX_CAPTURING;
    // 100 posedges: cnt reaches 100, ctx_trip fires (comb)
    // +1 posedge:   force_close registered high
    repeat (100) @(posedge clk_sys);
    @(posedge clk_sys);
    check("force_close pulses high", wdt_force_close === 1'b1);
    @(posedge clk_sys);
    check("force_close single-cycle pulse", wdt_force_close === 1'b0);

    // ==========================================================
    // Test 2: Per-context disabled (timeout = 0)
    // ==========================================================
    $display("\n--- Test 2: Per-context disabled ---");
    reset_dut();
    wdt_ctx_timeout = 16'd0;
    ctx_state[0]    = CTX_CAPTURING;
    repeat (500) @(posedge clk_sys);
    check("force_close stays low when disabled", wdt_force_close === 1'b0);
    check("ctx_trip_cnt remains 0",              wdt_ctx_trip_cnt === 8'd0);

    // ==========================================================
    // Test 3: Per-context counter resets on FREE
    // ==========================================================
    $display("\n--- Test 3: Per-context resets on FREE ---");
    reset_dut();
    wdt_ctx_timeout = 16'd100;
    ctx_state[1]    = CTX_DRAINING;
    repeat (50) @(posedge clk_sys);    // cnt≈50
    ctx_state[1] = CTX_FREE;           // resets counter
    repeat (100) @(posedge clk_sys);   // would trip if counter hadn't reset
    check("No timeout after FREE",  wdt_force_close === 1'b0);
    check("ctx_trip_cnt remains 0", wdt_ctx_trip_cnt === 8'd0);

    // ==========================================================
    // Test 4: Per-context trip counter accumulates
    // ==========================================================
    $display("\n--- Test 4: Per-context trip counter ---");
    reset_dut();
    wdt_ctx_timeout = 16'd100;
    for (int t = 0; t < 3; t++) begin
      ctx_state[0] = CTX_CAPTURING;
      repeat (102) @(posedge clk_sys);  // cnt=100 → trip → registered
      ctx_state[0] = CTX_FREE;
      repeat (3) @(posedge clk_sys);    // let counter reset
    end
    check("ctx_trip_cnt = 3 after 3 trips", wdt_ctx_trip_cnt === 8'd3);

    // ==========================================================
    // Test 5: Global timeout fires
    // ==========================================================
    $display("\n--- Test 5: Global timeout fires ---");
    reset_dut();
    wdt_global_timeout = 16'd200;
    // 200 posedges: cnt reaches 200, global_trip (comb)
    // +1 posedge:   force_reset registered high
    repeat (200) @(posedge clk_sys);
    @(posedge clk_sys);
    check("force_reset pulses high", wdt_force_reset === 1'b1);
    @(posedge clk_sys);
    check("force_reset single-cycle pulse", wdt_force_reset === 1'b0);

    // ==========================================================
    // Test 6: Global counter reset by conv_done
    // ==========================================================
    $display("\n--- Test 6: Global reset by conv_done ---");
    reset_dut();
    wdt_global_timeout = 16'd200;
    repeat (100) @(posedge clk_sys);   // cnt≈100
    conv_done = 1'b1;
    @(posedge clk_sys);               // DUT resets global counter
    conv_done = 1'b0;
    repeat (100) @(posedge clk_sys);  // cnt≈100, still < 200
    check("No global timeout after conv_done", wdt_force_reset === 1'b0);
    check("global_trip_cnt = 0",               wdt_global_trip_cnt === 8'd0);

    // ==========================================================
    // Test 7: Global disabled (timeout = 0)
    // ==========================================================
    $display("\n--- Test 7: Global disabled ---");
    reset_dut();
    wdt_global_timeout = 16'd0;
    repeat (500) @(posedge clk_sys);
    check("force_reset stays low when disabled", wdt_force_reset === 1'b0);
    check("global_trip_cnt remains 0",           wdt_global_trip_cnt === 8'd0);

    // ==========================================================
    // Test 8: Global trip counter accumulates
    // ==========================================================
    $display("\n--- Test 8: Global trip counter ---");
    reset_dut();
    wdt_global_timeout = 16'd200;
    // Trip 1 at ~cycle 201, auto-reset → trip 2 at ~cycle 402
    repeat (410) @(posedge clk_sys);
    check("global_trip_cnt = 2 after 2 trips", wdt_global_trip_cnt === 8'd2);

    // ==========================================================
    // Test 9: Both levels fire simultaneously
    // ==========================================================
    $display("\n--- Test 9: Both levels simultaneously ---");
    reset_dut();
    wdt_ctx_timeout    = 16'd100;
    wdt_global_timeout = 16'd100;
    ctx_state[0]       = CTX_CAPTURING;
    repeat (100) @(posedge clk_sys);
    @(posedge clk_sys);
    check("Both — force_close fires", wdt_force_close === 1'b1);
    check("Both — force_reset fires", wdt_force_reset === 1'b1);

    // ==========================================================
    // Test 10: Trip counter saturation at 255
    // ==========================================================
    $display("\n--- Test 10: Trip counter saturation ---");

    // -- Global saturation (auto-repeating, timeout=10) --
    reset_dut();
    wdt_global_timeout = 16'd10;
    // ~11 cycles/trip × 256+ trips
    repeat (3500) @(posedge clk_sys);
    check("Global counter saturates at 255", wdt_global_trip_cnt === 8'hFF);
    repeat (200) @(posedge clk_sys);
    check("Global counter stays at 255",     wdt_global_trip_cnt === 8'hFF);

    // -- Per-context saturation (manual cycling, timeout=10) --
    reset_dut();
    wdt_ctx_timeout = 16'd10;
    for (int t = 0; t < 260; t++) begin
      ctx_state[0] = CTX_CAPTURING;
      repeat (12) @(posedge clk_sys);   // cnt reaches 10 → trip
      ctx_state[0] = CTX_FREE;
      repeat (2) @(posedge clk_sys);    // counter reset
    end
    check("Per-ctx counter saturates at 255", wdt_ctx_trip_cnt === 8'hFF);
    for (int t = 0; t < 5; t++) begin
      ctx_state[0] = CTX_CAPTURING;
      repeat (12) @(posedge clk_sys);
      ctx_state[0] = CTX_FREE;
      repeat (2) @(posedge clk_sys);
    end
    check("Per-ctx counter stays at 255", wdt_ctx_trip_cnt === 8'hFF);

    // ==========================================================
    // Summary
    // ==========================================================
    $display("\n========================================");
    $display("  Results: %0d passed, %0d failed", pass_cnt, fail_cnt);
    $display("========================================");
    if (fail_cnt == 0) begin
      $display("TEST PASSED");
      $finish;
    end else begin
      $fatal(1, "TEST FAILED — %0d check(s) failed", fail_cnt);
    end
  end

  // Safety timeout
  initial begin
    #5_000_000;
    $fatal(1, "TB timeout — simulation exceeded 5 ms");
  end

endmodule

`default_nettype wire
