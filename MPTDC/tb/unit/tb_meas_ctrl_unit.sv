// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// Focused Verilator smoke for the clk_sys measurement controller. This checks
// capture-before-clear ordering and hit-count/flag behavior without touching
// the Vernier fabric.
`timescale 1ps/1ps
`default_nettype none

module tb_meas_ctrl_unit;
  import mptdc_pkg::*;

  logic clk_sys;
  initial clk_sys = 1'b0;
  always #3125 clk_sys = ~clk_sys;

  logic                  rst_n;
  logic                  meas_active;
  logic                  timeout_active;
  logic [PD_N-1:0]       hit_level;
  logic [MAX_HITS_W-1:0] max_hits_cfg;
  logic [15:0]           wdt_timeout;
  logic                  snapshot_en;
  logic                  capture_en;
  logic                  meta_en;
  logic                  fe_clear;
  logic                  pd_clear;
  logic                  pd_gate;
  logic                  osc_keep_alive;
  tdc_conv_flags_t       close_flags;
  logic [MAX_HITS_W-1:0] hit_count;
  meas_state_e           state;

  int pass_cnt;
  int fail_cnt;
  bit sample_seen;
  bit capture_seen;
  bit clear_seen;

  mptdc_meas_ctrl u_dut (
    .clk_sys          (clk_sys),
    .rst_n            (rst_n),
    .meas_active_i    (meas_active),
    .timeout_active_i (timeout_active),
    .hit_level_i      (hit_level),
    .max_hits_cfg_i   (max_hits_cfg),
    .wdt_timeout_i    (wdt_timeout),
    .snapshot_en_o    (snapshot_en),
    .capture_en_o     (capture_en),
    .meta_en_o        (meta_en),
    .fe_clear_o       (fe_clear),
    .pd_clear_o       (pd_clear),
    .pd_gate_o        (pd_gate),
    .osc_keep_alive_o (osc_keep_alive),
    .close_flags_o    (close_flags),
    .hit_count_o      (hit_count),
    .state_o          (state)
  );

  function automatic int unsigned popcount64(input logic [PD_N-1:0] bits);
    int unsigned count;
    count = 0;
    for (int i = 0; i < PD_N; i++)
      if (bits[i]) count++;
    return count;
  endfunction

  task automatic check(input bit cond, input string label);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s", label);
      fail_cnt++;
    end
  endtask

  task automatic tick();
    @(posedge clk_sys);
    #1;
  endtask

  task automatic run_conversion(
    input logic [PD_N-1:0]       hits,
    input logic [MAX_HITS_W-1:0] max_cfg,
    input logic                  timeout_i,
    input logic [15:0]           wdt_i,
    input string                 label
  );
    int unsigned expected_pop;
    int unsigned expected_count;

    expected_pop = popcount64(hits);
    if (max_cfg == '0)
      expected_count = 0;
    else if (expected_pop > int'(max_cfg))
      expected_count = int'(max_cfg);
    else
      expected_count = expected_pop;

    hit_level      = hits;
    max_hits_cfg   = max_cfg;
    timeout_active = timeout_i;
    wdt_timeout    = wdt_i;
    sample_seen    = 1'b0;
    capture_seen   = 1'b0;
    clear_seen     = 1'b0;

    meas_active = 1'b1;
    tick();
    check(state == ST_M_MEASURE, {label, ": IDLE to MEASURE"});
    check(pd_gate, {label, ": PD gate open in MEASURE"});

    meas_active = 1'b0;
    tick();
    check(state == ST_M_SNAPSHOT, {label, ": MEASURE to SNAPSHOT"});
    check(snapshot_en, {label, ": snapshot pulse in SNAPSHOT"});
    check(!pd_clear, {label, ": no clear during SNAPSHOT"});

    tick();
    check(state == ST_M_COUNT, {label, ": SNAPSHOT to COUNT"});
    check(!capture_en, {label, ": no capture while COUNT computes metadata"});
    check(!fe_clear, {label, ": no frontend clear while COUNT computes metadata"});
    check(!pd_clear, {label, ": no PD clear during COUNT"});
    check(hit_count == '0, {label, ": hit_count not published during COUNT"});
    check(!meta_en, {label, ": retired meta_en remains low"});

    tick();
    check(state == ST_M_CAPTURE, {label, ": COUNT to CAPTURE"});
    check(capture_en, {label, ": capture pulse in CAPTURE"});
    check(fe_clear, {label, ": frontend clear in CAPTURE"});
    check(!pd_clear, {label, ": no PD clear during CAPTURE"});
    check(hit_count == MAX_HITS_W'(expected_count), {label, ": registered hit_count held for capture"});
    check(close_flags.closed_by_fast_maxhit == ((max_cfg == MAX_HITS_W'(1)) && (expected_pop != 0)),
          {label, ": fast max-hit flag"});
    check(close_flags.closed_by_maxhits == ((max_cfg > MAX_HITS_W'(1)) && (expected_pop >= int'(max_cfg))),
          {label, ": max-hits flag"});
    check(close_flags.closed_by_watchdog == (timeout_i || ((wdt_i != 16'd0) && (expected_pop == 0))),
          {label, ": watchdog flag"});

    tick();
    check(state == ST_M_CLEAR, {label, ": CAPTURE to CLEAR"});
    check(pd_clear, {label, ": PD clear in CLEAR"});
    check(!snapshot_en && !capture_en && !fe_clear, {label, ": only PD clear in CLEAR"});

    tick();
    check(state == ST_M_IDLE, {label, ": return to IDLE"});
    check(!snapshot_en && !capture_en && !pd_clear, {label, ": outputs low in IDLE"});
  endtask

  always_ff @(posedge clk_sys) begin
    if (!rst_n) begin
      sample_seen  <= 1'b0;
      capture_seen <= 1'b0;
      clear_seen   <= 1'b0;
    end else begin
      if (snapshot_en)
        sample_seen <= 1'b1;
      if (capture_en)
        capture_seen <= 1'b1;
      if (pd_clear) begin
        assert (sample_seen)
          else $fatal(1, "mptdc_meas_ctrl clear occurred before snapshot");
        assert (capture_seen)
          else $fatal(1, "mptdc_meas_ctrl clear occurred before capture");
        assert (!clear_seen)
          else $fatal(1, "mptdc_meas_ctrl produced a double clear");
        clear_seen <= 1'b1;
      end
    end
  end

  initial begin
    pass_cnt       = 0;
    fail_cnt       = 0;
    rst_n          = 1'b0;
    meas_active    = 1'b0;
    timeout_active = 1'b0;
    hit_level      = '0;
    max_hits_cfg   = MAX_HITS_W'(15);
    wdt_timeout    = 16'd0;

    repeat (3) tick();
    rst_n = 1'b1;
    repeat (2) tick();

    check(state == ST_M_IDLE, "reset leaves controller in IDLE");
    check(pd_gate, "PD gate open in IDLE");

    begin
      logic [PD_N-1:0] hits;
      hits = '0;
      hits[0]  = 1'b1;
      hits[9]  = 1'b1;
      hits[63] = 1'b1;
      run_conversion(hits, MAX_HITS_W'(15), 1'b0, 16'd0, "three-hit conversion");
    end

    begin
      logic [PD_N-1:0] hits;
      hits = '1;
      run_conversion(hits, MAX_HITS_W'(4), 1'b0, 16'd0, "saturated conversion");
    end

    begin
      logic [PD_N-1:0] hits;
      hits = '0;
      run_conversion(hits, MAX_HITS_W'(15), 1'b0, 16'd7, "watchdog no-hit conversion");
    end

    begin
      logic [PD_N-1:0] hits;
      hits = '0;
      hits[5] = 1'b1;
      run_conversion(hits, MAX_HITS_W'(1), 1'b0, 16'd0, "fast max-hit conversion");
    end

    meas_active = 1'b1;
    tick();
    check(state == ST_M_MEASURE, "reset test entered MEASURE");
    rst_n = 1'b0;
    tick();
    check(state == ST_M_IDLE, "reset during active sequence returns IDLE");
    rst_n = 1'b1;
    meas_active = 1'b0;
    repeat (2) tick();

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_meas_ctrl_unit failed");
    $display("TEST PASSED");
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_meas_ctrl_unit timeout");
  end

endmodule

`default_nettype wire
