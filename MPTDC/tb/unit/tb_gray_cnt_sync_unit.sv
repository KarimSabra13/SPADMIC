// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_gray_cnt_sync_unit.sv
// Purpose : Unit test for Gray counter startup snapshot semantics.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_gray_cnt_sync_unit;
  import mptdc_pkg::*;

  localparam int unsigned W = 4;

  logic src_clk;
  logic dst_clk;
  logic rst_n;
  logic src_async_clr;
  logic src_latch_p;
  logic src_async_latch_p;

  logic [W-1:0] legacy_src_count;
  logic [W-1:0] legacy_dst_count;
  logic [W-1:0] fixed_src_count;
  logic [W-1:0] fixed_dst_count;

  int pass_cnt;
  int fail_cnt;

  initial begin
    src_clk = 1'b0;
    dst_clk = 1'b0;
  end

  always #25 dst_clk = ~dst_clk;

  mptdc_gray_cnt_sync #(
    .W                 (W),
    .USE_ASYNC_SNAPSHOT(1'b1)
  ) u_legacy (
    .src_clk             (src_clk),
    .src_rst_n           (rst_n),
    .src_async_clr       (src_async_clr),
    .src_en              (1'b1),
    .src_clr             (1'b0),
    .src_latch_p         (src_latch_p),
    .src_async_latch_p   (src_async_latch_p),
    .src_count           (legacy_src_count),
    .dst_clk             (dst_clk),
    .dst_rst_n           (rst_n),
    .dst_latch_p         (1'b0),
    .dst_count_continuous(),
    .dst_count_latched   (legacy_dst_count)
  );

  mptdc_gray_cnt_sync #(
    .W                 (W),
    .USE_ASYNC_SNAPSHOT(1'b1),
    .CLEAR_ON_ENABLE   (1'b0),
    .GRAY_ENCODE_NEXT  (1'b1)
  ) u_fixed (
    .src_clk             (src_clk),
    .src_rst_n           (rst_n),
    .src_async_clr       (src_async_clr),
    .src_en              (1'b1),
    .src_clr             (1'b0),
    .src_latch_p         (src_latch_p),
    .src_async_latch_p   (src_async_latch_p),
    .src_count           (fixed_src_count),
    .dst_clk             (dst_clk),
    .dst_rst_n           (rst_n),
    .dst_latch_p         (1'b0),
    .dst_count_continuous(),
    .dst_count_latched   (fixed_dst_count)
  );

  task automatic check(input string label, input logic cond);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s legacy_dst=%0d fixed_dst=%0d legacy_src=%0d fixed_src=%0d",
               label, legacy_dst_count, fixed_dst_count,
               legacy_src_count, fixed_src_count);
      fail_cnt++;
    end
  endtask

  task automatic pulse_src_edge();
    #10 src_clk = 1'b1;
    #10 src_clk = 1'b0;
    #10;
  endtask

  task automatic take_stop_snapshot();
    src_async_latch_p = 1'b1;
    #1 src_async_latch_p = 1'b0;
    repeat (4) @(posedge dst_clk);
  endtask

  initial begin
    pass_cnt = 0;
    fail_cnt = 0;
    rst_n = 1'b0;
    src_async_clr = 1'b1;
    src_latch_p = 1'b0;
    src_async_latch_p = 1'b0;

    $display("=== tb_gray_cnt_sync_unit ===");

    repeat (4) @(posedge dst_clk);
    rst_n = 1'b1;
    repeat (2) @(posedge dst_clk);
    src_async_clr = 1'b0;
    repeat (2) @(posedge dst_clk);

    take_stop_snapshot();
    check("pre-start snapshot is zero",
          (legacy_dst_count === W'(0)) && (fixed_dst_count === W'(0)));

    pulse_src_edge();
    take_stop_snapshot();
    check("legacy consumes first source edge",
          (legacy_dst_count === W'(0)) && (legacy_src_count === W'(0)));
    check("fixed counts first source edge",
          (fixed_dst_count === W'(1)) && (fixed_src_count === W'(1)));

    pulse_src_edge();
    take_stop_snapshot();
    check("legacy Gray snapshot is still one count stale after second edge",
          legacy_dst_count === W'(0));
    check("fixed Gray snapshot exports second count",
          fixed_dst_count === W'(2));

    pulse_src_edge();
    take_stop_snapshot();
    check("legacy first non-zero snapshot appears after third edge",
          legacy_dst_count === W'(1));
    check("fixed Gray snapshot exports third count",
          fixed_dst_count === W'(3));

    if (fail_cnt != 0)
      $fatal(1, "[TB] tb_gray_cnt_sync_unit failed: %0d failures", fail_cnt);

    $display("[TB] tb_gray_cnt_sync_unit passed: %0d checks", pass_cnt);
    $finish;
  end

endmodule

`default_nettype wire
