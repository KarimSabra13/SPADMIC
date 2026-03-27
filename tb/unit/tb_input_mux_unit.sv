// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_input_mux_unit.sv
// Purpose : Unit test for SPAD/CAL input selection pass-through and isolation.
// Author  : Karim Sabra
// Notes   : Covers mode switching, combinational response, and cross-talk
//           rejection on the pad-facing mux.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_input_mux_unit;
  import mptdc_pkg::*;

  // ---------- Clock (combinational DUT, but kept for port conventions) ------
  logic clk_sys;
  initial clk_sys = 0;
  always #3_125 clk_sys = ~clk_sys;

  logic rst_n;

  // ---------- DUT signals ---------------------------------------------------
  logic        start_spad_async;
  logic        stop_spad_async;
  logic        cal_start_async;
  logic        cal_stop_async;
  input_sel_e  input_sel;
  logic        start_async_o;
  logic        stop_async_o;

  // ---------- DUT -----------------------------------------------------------
  mptdc_input_mux u_dut (
    .clk_sys            (clk_sys),
    .rst_n              (rst_n),
    .start_spad_async_i (start_spad_async),
    .stop_spad_async_i  (stop_spad_async),
    .cal_start_async_i  (cal_start_async),
    .cal_stop_async_i   (cal_stop_async),
    .input_sel_i        (input_sel),
    .start_async_o      (start_async_o),
    .stop_async_o       (stop_async_o)
  );

  // ---------- Scoreboard ----------------------------------------------------
  int pass_cnt = 0;
  int fail_cnt = 0;

  task automatic check(
    input string tag,
    input logic   actual,
    input logic   expected
  );
    if (actual === expected) begin
      $display("[PASS] %s : got %0b", tag, actual);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s : expected %0b, got %0b", tag, expected, actual);
      fail_cnt++;
    end
  endtask

  // Helper: drive all inputs to a known state
  task automatic drive_all(
    input logic ss, input logic sp,
    input logic cs, input logic cp,
    input input_sel_e sel
  );
    start_spad_async = ss;
    stop_spad_async  = sp;
    cal_start_async  = cs;
    cal_stop_async   = cp;
    input_sel        = sel;
  endtask

  // ---------- Test sequences ------------------------------------------------
  initial begin
    rst_n = 1'b0;
    drive_all(0, 0, 0, 0, INPUT_SPAD);
    #20_000;
    rst_n = 1'b1;
    #10_000;

    // ====================================================================
    // Test 1 — SPAD mode pass-through
    // ====================================================================
    $display("\n--- Test 1: SPAD mode pass-through ---");
    drive_all(1, 0, 0, 0, INPUT_SPAD);
    #1_000;
    check("SPAD start=1 -> start_o", start_async_o, 1'b1);
    check("SPAD start=1 -> stop_o",  stop_async_o,  1'b0);

    drive_all(0, 1, 0, 0, INPUT_SPAD);
    #1_000;
    check("SPAD stop=1 -> stop_o",   stop_async_o,  1'b1);
    check("SPAD stop=1 -> start_o",  start_async_o, 1'b0);

    drive_all(1, 1, 0, 0, INPUT_SPAD);
    #1_000;
    check("SPAD both=1 -> start_o",  start_async_o, 1'b1);
    check("SPAD both=1 -> stop_o",   stop_async_o,  1'b1);

    // ====================================================================
    // Test 2 — CAL mode pass-through
    // ====================================================================
    $display("\n--- Test 2: CAL mode pass-through ---");
    drive_all(0, 0, 1, 0, INPUT_CAL);
    #1_000;
    check("CAL cal_start=1 -> start_o", start_async_o, 1'b1);
    check("CAL cal_start=1 -> stop_o",  stop_async_o,  1'b0);

    drive_all(0, 0, 0, 1, INPUT_CAL);
    #1_000;
    check("CAL cal_stop=1 -> stop_o",   stop_async_o,  1'b1);
    check("CAL cal_stop=1 -> start_o",  start_async_o, 1'b0);

    drive_all(0, 0, 1, 1, INPUT_CAL);
    #1_000;
    check("CAL both=1 -> start_o",  start_async_o, 1'b1);
    check("CAL both=1 -> stop_o",   stop_async_o,  1'b1);

    // ====================================================================
    // Test 3 — Combinational (no clock edge needed)
    // ====================================================================
    $display("\n--- Test 3: Combinational immediacy (no clock edge) ---");
    drive_all(0, 0, 0, 0, INPUT_SPAD);
    #1_000;  // sub-clock-cycle settle; proves no posedge needed
    check("Comb pre: start_o=0",  start_async_o, 1'b0);
    check("Comb pre: stop_o=0",   stop_async_o,  1'b0);

    start_spad_async = 1'b1;
    #1_000;
    check("Comb imm: start_o=1 after #1_000", start_async_o, 1'b1);

    stop_spad_async = 1'b1;
    #1_000;
    check("Comb imm: stop_o=1 after #1_000",  stop_async_o,  1'b1);

    start_spad_async = 1'b0;
    #1_000;
    check("Comb imm: start_o=0 after #1_000", start_async_o, 1'b0);

    // ====================================================================
    // Test 4 — Mode switching (SPAD → CAL while SPAD active)
    // ====================================================================
    $display("\n--- Test 4: Mode switching ---");
    drive_all(1, 1, 0, 0, INPUT_SPAD);
    #1_000;
    check("Pre-switch SPAD start_o", start_async_o, 1'b1);
    check("Pre-switch SPAD stop_o",  stop_async_o,  1'b1);

    // Switch to CAL — SPAD signals still high, CAL inputs low
    input_sel = INPUT_CAL;
    #1_000;
    check("Post-switch CAL start_o (SPAD high, CAL low)", start_async_o, 1'b0);
    check("Post-switch CAL stop_o  (SPAD high, CAL low)", stop_async_o,  1'b0);

    // Now raise CAL inputs
    cal_start_async = 1'b1;
    cal_stop_async  = 1'b1;
    #1_000;
    check("Post-switch CAL start_o (CAL high)", start_async_o, 1'b1);
    check("Post-switch CAL stop_o  (CAL high)", stop_async_o,  1'b1);

    // Switch back to SPAD — SPAD still high
    input_sel = INPUT_SPAD;
    #1_000;
    check("Back to SPAD start_o", start_async_o, 1'b1);
    check("Back to SPAD stop_o",  stop_async_o,  1'b1);

    // ====================================================================
    // Test 5 — All inputs zero
    // ====================================================================
    $display("\n--- Test 5: All inputs zero ---");
    drive_all(0, 0, 0, 0, INPUT_SPAD);
    #1_000;
    check("SPAD all-zero start_o", start_async_o, 1'b0);
    check("SPAD all-zero stop_o",  stop_async_o,  1'b0);

    drive_all(0, 0, 0, 0, INPUT_CAL);
    #1_000;
    check("CAL all-zero start_o",  start_async_o, 1'b0);
    check("CAL all-zero stop_o",   stop_async_o,  1'b0);

    // ====================================================================
    // Test 6 — Cross-talk isolation
    // ====================================================================
    $display("\n--- Test 6: Cross-talk isolation ---");

    // SPAD mode: drive CAL inputs high, SPAD inputs low
    drive_all(0, 0, 1, 1, INPUT_SPAD);
    #1_000;
    check("Xtalk SPAD: cal high -> start_o=0", start_async_o, 1'b0);
    check("Xtalk SPAD: cal high -> stop_o=0",  stop_async_o,  1'b0);

    // CAL mode: drive SPAD inputs high, CAL inputs low
    drive_all(1, 1, 0, 0, INPUT_CAL);
    #1_000;
    check("Xtalk CAL: spad high -> start_o=0", start_async_o, 1'b0);
    check("Xtalk CAL: spad high -> stop_o=0",  stop_async_o,  1'b0);

    // SPAD mode: both sides high — only SPAD should appear
    drive_all(1, 1, 1, 1, INPUT_SPAD);
    #1_000;
    check("Xtalk SPAD both high: start_o=spad", start_async_o, 1'b1);
    check("Xtalk SPAD both high: stop_o=spad",  stop_async_o,  1'b1);

    // CAL mode: both sides high — only CAL should appear
    drive_all(1, 1, 1, 1, INPUT_CAL);
    #1_000;
    check("Xtalk CAL both high: start_o=cal", start_async_o, 1'b1);
    check("Xtalk CAL both high: stop_o=cal",  stop_async_o,  1'b1);

    // ====================================================================
    // Summary
    // ====================================================================
    $display("\n===========================================");
    $display("  Pass: %0d   Fail: %0d", pass_cnt, fail_cnt);
    $display("===========================================");
    if (fail_cnt == 0) begin
      $display("TEST PASSED");
      $finish;
    end else begin
      $display("TEST FAILED");
      $fatal(1, "tb_input_mux_unit: %0d check(s) failed", fail_cnt);
    end
  end

  // Timeout watchdog
  initial begin
    #100_000_000;
    $fatal(1, "TIMEOUT: tb_input_mux_unit did not finish in 100 us");
  end

endmodule

`default_nettype wire
