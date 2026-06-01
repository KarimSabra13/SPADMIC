// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// Focused Verilator smoke for the held-bus capture bridge.
`timescale 1ps/1ps
`default_nettype none

module tb_hit_capture_bridge_unit;
  import mptdc_pkg::*;

  logic clk_sys;
  initial clk_sys = 1'b0;
  always #3125 clk_sys = ~clk_sys;

  logic                         rst_n;
  logic                         sample_en;
  logic [PD_N-1:0]              pd_hit_level;
  logic [PD_N*NFAST_W-1:0]      pd_nfast_hit_packed;
  logic [SLOW_EPOCH_STAGES-1:0] slow_epoch_johnson_stop;
  logic [NSLOW_W-1:0]           expected_nslow_snap;
  logic [NFAST_W-1:0]           nfast_snap;
  logic [NFAST_W-1:0]           nfast_stop;
  logic                         phase0_snap;
  stop_phase_disc_t             stop_slow_phase_disc;
  logic                         slow_boundary_inc;
  mptdc_ctx_snapshot_t          snapshot;
  mptdc_ctx_snapshot_t          expected;

  int pass_cnt;
  int fail_cnt;

  mptdc_hit_capture_bridge u_dut (
    .clk_sys                (clk_sys),
    .rst_n                  (rst_n),
    .sample_en_i            (sample_en),
    .pd_hit_level_i         (pd_hit_level),
    .pd_nfast_hit_packed_i  (pd_nfast_hit_packed),
    .slow_epoch_johnson_stop_i (slow_epoch_johnson_stop),
    .nfast_snap_i           (nfast_snap),
    .nfast_stop_i           (nfast_stop),
    .phase0_snap_i          (phase0_snap),
    .stop_slow_phase_disc_i (stop_slow_phase_disc),
    .slow_boundary_inc_i    (slow_boundary_inc),
    .snapshot_o             (snapshot)
  );

  task automatic tick();
    @(posedge clk_sys);
    #1;
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

  function automatic logic [SLOW_EPOCH_STAGES-1:0] johnson_from_count(input int unsigned count);
    automatic logic [SLOW_EPOCH_STAGES-1:0] state;
    state = '0;
    for (int i = 0; i < count; i++)
      state = slow_johnson_next(state);
    johnson_from_count = state;
  endfunction

  task automatic drive_image(input int unsigned seed);
    pd_hit_level         = '0;
    pd_nfast_hit_packed  = '0;
    pd_hit_level[seed % PD_N] = 1'b1;
    pd_hit_level[(seed * 7 + 3) % PD_N] = 1'b1;
    pd_hit_level[(seed * 13 + 11) % PD_N] = 1'b1;
    for (int i = 0; i < PD_N; i++)
      pd_nfast_hit_packed[i*NFAST_W +: NFAST_W] = NFAST_W'((seed + i) & 7'h7f);
    expected_nslow_snap = NSLOW_W'((seed + 3) & 7'h7f);
    slow_epoch_johnson_stop = johnson_from_count(expected_nslow_snap);
    nfast_snap = NFAST_W'(seed + 5);
    nfast_stop = NFAST_W'(seed + 7);
    phase0_snap = seed[0];
    stop_slow_phase_disc = stop_phase_disc_t'(seed[STOP_PHASE_DISC_W-1:0]);
    slow_boundary_inc = seed[1];
  endtask

  task automatic capture_expected();
    expected = '0;
    expected.hit_level            = pd_hit_level;
    expected.nfast_hit_packed     = pd_nfast_hit_packed;
    expected.nslow_snap           = expected_nslow_snap;
    expected.nfast_snap           = nfast_snap;
    expected.nfast_stop           = nfast_stop;
    expected.phase0_snap          = phase0_snap;
    expected.stop_slow_phase_disc = stop_slow_phase_disc;
    expected.slow_boundary_inc    = slow_boundary_inc;
  endtask

  task automatic check_snapshot(input mptdc_ctx_snapshot_t exp, input string label);
    check(snapshot.hit_level == exp.hit_level, {label, ": hit_level"});
    check(snapshot.nfast_hit_packed == exp.nfast_hit_packed, {label, ": nfast_hit_packed"});
    check(snapshot.nslow_snap == exp.nslow_snap, {label, ": nslow_snap"});
    check(snapshot.nfast_snap == exp.nfast_snap, {label, ": nfast_snap"});
    check(snapshot.nfast_stop == exp.nfast_stop, {label, ": nfast_stop"});
    check(snapshot.phase0_snap == exp.phase0_snap, {label, ": phase0_snap"});
    check(snapshot.stop_slow_phase_disc == exp.stop_slow_phase_disc, {label, ": stop_slow_phase_disc"});
    check(snapshot.slow_boundary_inc == exp.slow_boundary_inc, {label, ": slow_boundary_inc"});
    check(snapshot.hit_count == '0, {label, ": hit_count cleared by bridge"});
    check(snapshot.flags == '0, {label, ": flags cleared by bridge"});
  endtask

  initial begin
    pass_cnt = 0;
    fail_cnt = 0;
    rst_n = 1'b0;
    sample_en = 1'b0;
    drive_image(1);
    repeat (3) tick();
    rst_n = 1'b1;
    repeat (2) tick();

    capture_expected();
    sample_en = 1'b1;
    tick();
    sample_en = 1'b0;
    check_snapshot(expected, "first sample");

    drive_image(19);
    repeat (4) tick();
    check_snapshot(expected, "held without resample");

    capture_expected();
    sample_en = 1'b1;
    tick();
    sample_en = 1'b0;
    check_snapshot(expected, "second sample");

    rst_n = 1'b0;
    tick();
    check(snapshot == '0, "reset clears snapshot");

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_hit_capture_bridge_unit failed");
    $display("TEST PASSED");
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_hit_capture_bridge_unit timeout");
  end

endmodule

`default_nettype wire
