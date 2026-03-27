// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_reset_sync_unit.sv
// Purpose : Unit test for async-assert / sync-deassert reset timing.
// Author  : Karim Sabra
// Notes   : Exercises STAGES=2, STAGES=3, reassertion mid-release, and
//           clock-stopped behavior.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_reset_sync_unit;
  import mptdc_pkg::*;

  // ── Clock ───────────────────────────────────────────────────────
  localparam realtime HALF_PERIOD = 3.125;  // 160 MHz

  logic clk;
  initial clk = 0;
  always #3_125 clk = ~clk;

  // Gated clock for test 6 (clock-independent assert)
  logic clk_en;
  wire  gated_clk;
  assign gated_clk = clk & clk_en;

  // ── DUT signals ─────────────────────────────────────────────────
  logic async_rst_n;

  // STAGES=2 instance driven by normal clk
  wire rst_n_s2;
  mptdc_reset_sync #(.STAGES(2)) u_dut_s2 (
    .clk         (clk),
    .async_rst_n (async_rst_n),
    .rst_n_o     (rst_n_s2)
  );

  // STAGES=3 instance driven by normal clk
  wire rst_n_s3;
  mptdc_reset_sync #(.STAGES(3)) u_dut_s3 (
    .clk         (clk),
    .async_rst_n (async_rst_n),
    .rst_n_o     (rst_n_s3)
  );

  // STAGES=2 instance driven by gated clock (for test 6)
  wire rst_n_gated;
  mptdc_reset_sync #(.STAGES(2)) u_dut_gated (
    .clk         (gated_clk),
    .async_rst_n (async_rst_n),
    .rst_n_o     (rst_n_gated)
  );

  // ── Scoreboard ──────────────────────────────────────────────────
  int pass_cnt = 0;
  int fail_cnt = 0;

  task automatic check(input string tag, input logic actual, input logic expected);
    if (actual === expected) begin
      pass_cnt++;
    end else begin
      $display("[FAIL] %s: expected %b, got %b at %0t", tag, expected, actual, $time);
      fail_cnt++;
    end
  endtask

  // Wait for N posedge clk
  task automatic wait_clks(input int n);
    repeat (n) @(posedge clk);
  endtask

  // ── Helpers ─────────────────────────────────────────────────────
  // Assert reset and let it propagate through both instances fully
  task automatic full_reset();
    async_rst_n <= 1'b0;
    #1_000;
    wait_clks(1);
    async_rst_n <= 1'b1;
    wait_clks(5);  // enough for STAGES=3
  endtask

  // ── Test procedures ─────────────────────────────────────────────

  initial begin
    // Init
    async_rst_n = 1'b0;
    clk_en      = 1'b1;

    // Let simulation settle
    #1_000;

    // ================================================================
    // TEST 1 — Async assert: rst_n_o goes low within 1 ns of async_rst_n=0
    // ================================================================
    $display("\n--- Test 1: Async assert ---");
    // First bring out of reset cleanly
    async_rst_n = 1'b1;
    wait_clks(5);
    check("T1-pre: rst_n_s2 high before assert", rst_n_s2, 1'b1);

    // Assert reset between clock edges (mid-cycle)
    @(posedge clk);
    #(HALF_PERIOD / 2);  // quarter-cycle after posedge — between edges
    async_rst_n = 1'b0;
    #1_000;  // 1 ns propagation
    check("T1: rst_n_s2 low after async assert", rst_n_s2, 1'b0);
    check("T1: rst_n_s3 low after async assert", rst_n_s3, 1'b0);
    $display("[PASS] Test 1: Async assert verified");

    // ================================================================
    // TEST 2 — Sync deassert (STAGES=2): rst_n_o high after 2 clk edges
    // ================================================================
    $display("\n--- Test 2: Sync deassert STAGES=2 ---");
    // Ensure in reset
    async_rst_n = 1'b0;
    #1_000;
    check("T2-pre: rst_n_s2 low in reset", rst_n_s2, 1'b0);

    // Deassert reset just after a posedge so we count edges cleanly
    @(posedge clk);
    #1_000;
    async_rst_n = 1'b1;

    // After 1st posedge: sync_q shifts in one 1 → sync_q = 2'b01, rst_n_o still 0
    @(posedge clk);
    #1_000;
    check("T2: rst_n_s2 still low after 1st edge", rst_n_s2, 1'b0);

    // After 2nd posedge: sync_q = 2'b11, rst_n_o = 1
    @(posedge clk);
    #1_000;
    check("T2: rst_n_s2 high after 2nd edge", rst_n_s2, 1'b1);
    $display("[PASS] Test 2: Sync deassert STAGES=2 verified");

    // ================================================================
    // TEST 3 — Sync deassert (STAGES=3): rst_n_o high after 3 clk edges
    // ================================================================
    $display("\n--- Test 3: Sync deassert STAGES=3 ---");
    // Assert reset
    async_rst_n = 1'b0;
    #1_000;
    check("T3-pre: rst_n_s3 low in reset", rst_n_s3, 1'b0);

    // Deassert
    @(posedge clk);
    #1_000;
    async_rst_n = 1'b1;

    // After 1st edge
    @(posedge clk);
    #1_000;
    check("T3: rst_n_s3 low after 1st edge", rst_n_s3, 1'b0);

    // After 2nd edge
    @(posedge clk);
    #1_000;
    check("T3: rst_n_s3 low after 2nd edge", rst_n_s3, 1'b0);

    // After 3rd edge
    @(posedge clk);
    #1_000;
    check("T3: rst_n_s3 high after 3rd edge", rst_n_s3, 1'b1);
    $display("[PASS] Test 3: Sync deassert STAGES=3 verified");

    // ================================================================
    // TEST 4 — Repeated assert/deassert cycles
    // ================================================================
    $display("\n--- Test 4: Repeated assert/deassert ---");
    begin
      int i;
      for (i = 0; i < 3; i++) begin
        // Assert
        @(posedge clk);
        #(HALF_PERIOD / 2);
        async_rst_n = 1'b0;
        #1_000;
        check($sformatf("T4-iter%0d: assert immediate", i), rst_n_s2, 1'b0);

        // Deassert
        @(posedge clk);
        #1_000;
        async_rst_n = 1'b1;
        @(posedge clk);
        #1_000;
        check($sformatf("T4-iter%0d: still low after 1 edge", i), rst_n_s2, 1'b0);
        @(posedge clk);
        #1_000;
        check($sformatf("T4-iter%0d: high after 2 edges", i), rst_n_s2, 1'b1);
      end
    end
    $display("[PASS] Test 4: Repeated assert/deassert verified");

    // ================================================================
    // TEST 5 — Assert during deassert (re-assert before chain fills)
    // ================================================================
    $display("\n--- Test 5: Assert during deassert ---");
    // Start from reset
    async_rst_n = 1'b0;
    wait_clks(2);
    #1_000;
    check("T5-pre: in reset", rst_n_s2, 1'b0);

    // Begin deasserting
    @(posedge clk);
    #1_000;
    async_rst_n = 1'b1;

    // After 1 edge, rst_n_s2 still 0 (chain not full yet)
    @(posedge clk);
    #1_000;
    check("T5: rst_n_s2 still low mid-deassert", rst_n_s2, 1'b0);

    // Re-assert before the 2nd edge completes the chain
    #(HALF_PERIOD / 2);
    async_rst_n = 1'b0;
    #1_000;
    check("T5: rst_n_s2 low after re-assert", rst_n_s2, 1'b0);

    // Let another edge pass — should still be low since we re-asserted
    @(posedge clk);
    #1_000;
    check("T5: rst_n_s2 remains low after edge", rst_n_s2, 1'b0);
    $display("[PASS] Test 5: Assert during deassert verified");

    // ================================================================
    // TEST 6 — Clock-independent assert (gated clock stopped)
    // ================================================================
    $display("\n--- Test 6: Clock-independent assert ---");
    // First, release reset on gated_clk instance
    async_rst_n = 1'b1;
    clk_en      = 1'b1;
    wait_clks(5);
    check("T6-pre: gated instance out of reset", rst_n_gated, 1'b1);

    // Stop the gated clock
    @(posedge clk);
    clk_en = 1'b0;
    #(HALF_PERIOD * 4);  // wait a few would-be clock periods

    // Assert reset with clock stopped
    async_rst_n = 1'b0;
    #1_000;
    check("T6: rst_n_gated low with clock stopped", rst_n_gated, 1'b0);

    // Re-enable clock and verify it can deassert
    clk_en = 1'b1;
    #1_000;
    async_rst_n = 1'b1;
    wait_clks(4);
    check("T6: rst_n_gated high after clock resumed", rst_n_gated, 1'b1);
    $display("[PASS] Test 6: Clock-independent assert verified");

    // ================================================================
    // Summary
    // ================================================================
    $display("\n========================================");
    $display("  Results: %0d passed, %0d failed", pass_cnt, fail_cnt);
    $display("========================================");
    if (fail_cnt > 0) begin
      $display("TEST FAILED");
      $fatal(1, "tb_reset_sync_unit: %0d checks failed", fail_cnt);
    end else begin
      $display("TEST PASSED");
    end
    $finish;
  end

  // Timeout watchdog
  initial begin
    #100_000_000;
    $fatal(1, "tb_reset_sync_unit: TIMEOUT");
  end

endmodule

`default_nettype wire
