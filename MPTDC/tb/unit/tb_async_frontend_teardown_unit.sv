// SPDX-FileCopyrightText: 2026 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// Focused teardown hardening test for mptdc_async_frontend_v2.
`timescale 1ps/1ps
`default_nettype none

module tb_async_frontend_teardown_unit;
  import mptdc_pkg::*;

  logic rst_n;
  logic conv_arm;
  logic start_async;
  logic stop_async;
  logic fe_clear_async;
  logic frontend_teardown_busy;
  logic start_timeout_async;
  logic [N_CTX-1:0] ctx_release_async;
  logic capture_en;
  logic osc_keep_alive;
  logic start_latched;
  logic stop_latched;
  logic osc_slow_en_async;
  logic osc_fast_en_async;
  logic pd_enable_async;
  ctx_id_t active_ctx;
  ctx_state_e ctx_state [N_CTX];
  logic [N_CTX-1:0] ctx_drain;
  logic all_ctx_busy;
  logic start_rejected;
  int pass_cnt;
  int fail_cnt;

  mptdc_async_frontend_v2 u_dut (
    .rst_n                    (rst_n),
    .conv_arm_i               (conv_arm),
    .start_async_i            (start_async),
    .stop_async_i             (stop_async),
    .fe_clear_async_i         (fe_clear_async),
    .frontend_teardown_busy_i (frontend_teardown_busy),
    .start_timeout_async_i    (start_timeout_async),
    .ctx_release_async_i      (ctx_release_async),
    .capture_en_i             (capture_en),
    .osc_keep_alive_i         (osc_keep_alive),
    .start_latched_o          (start_latched),
    .stop_latched_o           (stop_latched),
    .osc_slow_en_async_o      (osc_slow_en_async),
    .osc_fast_en_async_o      (osc_fast_en_async),
    .pd_enable_async_o        (pd_enable_async),
    .active_ctx_o             (active_ctx),
    .ctx_state_o              (ctx_state),
    .ctx_drain_o              (ctx_drain),
    .all_ctx_busy_o           (all_ctx_busy),
    .start_rejected_o         (start_rejected)
  );

  task automatic settle();
    #25;
  endtask

  task automatic check(input bit cond, input string label);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s", label);
      fail_cnt++;
    end
  endtask

  task automatic clear_inputs();
    rst_n = 1'b0;
    conv_arm = 1'b1;
    start_async = 1'b0;
    stop_async = 1'b0;
    fe_clear_async = 1'b0;
    frontend_teardown_busy = 1'b0;
    start_timeout_async = 1'b0;
    ctx_release_async = '0;
    capture_en = 1'b0;
    osc_keep_alive = 1'b0;
  endtask

  task automatic pulse_start(input string label, output bit latched_seen, output bit rejected_seen);
    start_async = 1'b1;
    settle();
    latched_seen = start_latched;
    rejected_seen = start_rejected;
    $display("[INFO] START pulse: %s start_latched=%0b rejected=%0b",
             label, latched_seen, rejected_seen);
    start_async = 1'b0;
    settle();
  endtask

  initial begin
`ifndef MPTDC_SAFE_TEARDOWN
    $display("[SKIP] MPTDC_SAFE_TEARDOWN not enabled");
    $finish;
`else
    bit latched_seen;
    bit rejected_seen;

    pass_cnt = 0;
    fail_cnt = 0;
    clear_inputs();
    settle();
    rst_n = 1'b1;
    settle();

    frontend_teardown_busy = 1'b1;
    pulse_start("teardown busy", latched_seen, rejected_seen);
    check(!latched_seen, "START during teardown_busy is not accepted");
    check(rejected_seen, "START during teardown_busy is rejected");

    frontend_teardown_busy = 1'b0;
    settle();
    pulse_start("normal acceptance", latched_seen, rejected_seen);
    check(latched_seen, "START accepted after teardown_busy clears");
    check(!rejected_seen, "accepted START is not rejected");

    fe_clear_async = 1'b1;
    settle();
    check(!start_latched, "fe_clear clears accepted START");
    fe_clear_async = 1'b0;
    frontend_teardown_busy = 1'b1;
    settle();

    pulse_start("pd clear teardown", latched_seen, rejected_seen);
    check(!latched_seen, "START during pd-clear teardown is not accepted");
    check(rejected_seen, "START during pd-clear teardown is rejected");

    frontend_teardown_busy = 1'b0;
    settle();
    pulse_start("post clear rearm", latched_seen, rejected_seen);
    check(latched_seen, "START accepted after clear release");
    check(ctx_state[active_ctx] == CTX_CAPTURING, "accepted START owns active context");

    fe_clear_async = 1'b1;
    settle();
    fe_clear_async = 1'b0;
    settle();
    check(!pd_enable_async, "PD enable remains low after clear without STOP");

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_async_frontend_teardown_unit failed");
    $display("TEST PASSED");
    $finish;
`endif
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_async_frontend_teardown_unit timeout");
  end

endmodule

`default_nettype wire
