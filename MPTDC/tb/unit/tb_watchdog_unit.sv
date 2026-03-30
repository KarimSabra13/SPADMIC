// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_watchdog_unit.sv
// Purpose : Unit test for the global watchdog pulse and trip counter.
// Author  : Karim Sabra
// Notes   : Confirms timeout firing, reset/disable behavior, and counter
//           saturation semantics.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_watchdog_unit;
  import mptdc_pkg::*;

  // ── Clock: 160 MHz ────────────────────────────────────────────────
  logic clk_sys;
  initial clk_sys = 0;
  always #3_125 clk_sys = ~clk_sys;

  // ── DUT signals ───────────────────────────────────────────────────
  logic        rst_n;
  logic        conv_done;
  logic [15:0] wdt_global_timeout;
  logic        wdt_force_reset;
  logic [7:0]  wdt_global_trip_cnt;

  // ── DUT ───────────────────────────────────────────────────────────
  mptdc_watchdog u_dut (
    .clk_sys               (clk_sys),
    .rst_n                 (rst_n),
    .conv_done_i           (conv_done),
    .wdt_global_timeout_i  (wdt_global_timeout),
    .wdt_force_reset_o     (wdt_force_reset),
    .wdt_global_trip_cnt_o (wdt_global_trip_cnt)
  );

  // ── Scoreboard ────────────────────────────────────────────────────
  int pass_cnt = 0;
  int fail_cnt = 0;

  task automatic check(input string name, input int cond);
    if (cond) begin
      $display("[PASS] %s", name);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s (fr=%0b glb_tc=%0d)",
               name, wdt_force_reset, wdt_global_trip_cnt);
      fail_cnt++;
    end
  endtask

  // ── Reset ─────────────────────────────────────────────────────────
  task automatic reset_dut();
    rst_n              = 1'b0;
    conv_done          = 1'b0;
    wdt_global_timeout = 16'd0;
    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    @(posedge clk_sys);
  endtask

  // ── Main test sequence ────────────────────────────────────────────
  initial begin
    $display("========================================");
    $display(" tb_watchdog_unit — v2.2 global-only");
    $display("========================================");

    // ── Test 1: Global timeout fires ────────────────────────────────
    $display("\n--- Test 1: Global timeout fires ---");
    reset_dut();
    wdt_global_timeout = 16'd200;
    repeat (200) @(posedge clk_sys);
    @(posedge clk_sys);
    check("force_reset pulses high", wdt_force_reset === 1'b1);
    @(posedge clk_sys);
    check("force_reset single-cycle pulse", wdt_force_reset === 1'b0);

    // ── Test 2: Global counter reset by conv_done ───────────────────
    $display("\n--- Test 2: Global reset by conv_done ---");
    reset_dut();
    wdt_global_timeout = 16'd200;
    repeat (100) @(posedge clk_sys);
    conv_done = 1'b1;
    @(posedge clk_sys);
    conv_done = 1'b0;
    repeat (100) @(posedge clk_sys);
    check("No timeout after conv_done", wdt_force_reset === 1'b0);
    check("global_trip_cnt = 0",        wdt_global_trip_cnt === 8'd0);

    // ── Test 3: Global disabled (timeout = 0) ───────────────────────
    $display("\n--- Test 3: Global disabled ---");
    reset_dut();
    wdt_global_timeout = 16'd0;
    repeat (500) @(posedge clk_sys);
    check("force_reset stays low when disabled", wdt_force_reset === 1'b0);
    check("global_trip_cnt remains 0",           wdt_global_trip_cnt === 8'd0);

    // ── Test 4: Global trip counter accumulates ─────────────────────
    $display("\n--- Test 4: Global trip counter ---");
    reset_dut();
    wdt_global_timeout = 16'd200;
    // Trip 1 at ~cycle 201, auto-reset → trip 2 at ~cycle 402
    repeat (410) @(posedge clk_sys);
    check("global_trip_cnt = 2 after 2 trips", wdt_global_trip_cnt === 8'd2);

    // ── Test 5: Trip counter saturation at 255 ──────────────────────
    $display("\n--- Test 5: Trip counter saturation ---");
    reset_dut();
    wdt_global_timeout = 16'd10;
    // ~11 cycles/trip × 256+ trips
    repeat (3500) @(posedge clk_sys);
    check("Global counter saturates at 255", wdt_global_trip_cnt === 8'hFF);
    repeat (200) @(posedge clk_sys);
    check("Global counter stays at 255",     wdt_global_trip_cnt === 8'hFF);

    // ── Test 6: Reset clears everything ─────────────────────────────
    $display("\n--- Test 6: Reset clears state ---");
    // Don't call reset_dut — manually check mid-count
    wdt_global_timeout = 16'd100;
    repeat (50) @(posedge clk_sys);
    rst_n = 1'b0;
    repeat (2) @(posedge clk_sys);
    check("Reset clears force_reset",    wdt_force_reset === 1'b0);
    check("Reset clears trip_cnt",       wdt_global_trip_cnt === 8'd0);
    rst_n = 1'b1;
    repeat (50) @(posedge clk_sys);
    check("No premature trip after reset", wdt_force_reset === 1'b0);

    // ── Summary ─────────────────────────────────────────────────────
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
    #5ms;
    $fatal(1, "TB timeout — simulation exceeded 5 ms");
  end

endmodule

`default_nettype wire
