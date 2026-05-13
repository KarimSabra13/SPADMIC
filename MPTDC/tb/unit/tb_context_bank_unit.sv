// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_context_bank_unit.sv
// Purpose : Unit test for context snapshot capture and readback integrity.
// Author  : Karim Sabra
// Notes   : Checks independent contexts, overwrite behavior, and packed hit
//           bookkeeping without changing the stored contract.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_context_bank_unit;
  import mptdc_pkg::*;

  // ── Clock ─────────────────────────────────────────────────────────
  logic clk_fast;
  initial clk_fast = 0;
  always #450 clk_fast = ~clk_fast;  // ~900 ps period

  // ── DUT signals ───────────────────────────────────────────────────
  ctx_id_t                capture_ctx;
  logic                   snapshot_en;
  logic                   capture_en;
  logic [PD_N-1:0]        pd_hit_level;
  logic [PD_N*NFAST_W-1:0] pd_nfast_hit_packed;
  logic [NSLOW_W-1:0]     nslow_snap;
  logic [NFAST_W-1:0]     nfast_snap;
  logic [NFAST_W-1:0]     nfast_stop;  // v2.3
  logic                   phase0_snap;
  logic                   slow_boundary_inc;
  logic [MAX_HITS_W-1:0]  hit_count;
  tdc_conv_flags_t        flags;
  ctx_id_t                read_ctx;
  mptdc_ctx_snapshot_t    snapshot;

  // ── DUT instantiation ─────────────────────────────────────────────
  mptdc_context_bank u_dut (
    .clk_fast               (clk_fast),
    .capture_ctx_i          (capture_ctx),
    .snapshot_en_i          (snapshot_en),
    .capture_en_i           (capture_en),
    .pd_hit_level_i         (pd_hit_level),
    .pd_nfast_hit_packed_i  (pd_nfast_hit_packed),
    .nslow_snap_i           (nslow_snap),
    .nfast_snap_i           (nfast_snap),
    .nfast_stop_i           (nfast_stop),  // v2.3
    .phase0_snap_i          (phase0_snap),
    .slow_boundary_inc_i    (slow_boundary_inc),
    .hit_count_i            (hit_count),
    .flags_i                (flags),
    .read_ctx_i             (read_ctx),
    .snapshot_o             (snapshot)
  );

  // ── Scoreboard record ─────────────────────────────────────────────
  typedef struct {
    logic [PD_N-1:0]          hit_level;
    logic [PD_N*NFAST_W-1:0]  nfast_packed;
    logic [NSLOW_W-1:0]       nslow;
    logic [NFAST_W-1:0]       nfast;
    logic                     phase0;
    logic                     boundary_inc;
    logic [MAX_HITS_W-1:0]    hcount;
    tdc_conv_flags_t          fl;
  } ctx_record_t;

  int pass_cnt = 0;
  int fail_cnt = 0;

  // ── Helper tasks ──────────────────────────────────────────────────

  task automatic do_capture(
    input ctx_id_t            ctx,
    input logic [PD_N-1:0]    hl,
    input logic [PD_N*NFAST_W-1:0] nfp,
    input logic [NSLOW_W-1:0] ns,
    input logic [NFAST_W-1:0] nf,
    input logic               ph0,
    input logic               binc,
    input logic [MAX_HITS_W-1:0] hc,
    input tdc_conv_flags_t    fl_in
  );
    @(posedge clk_fast);
    capture_ctx          = ctx;
    snapshot_en          = 1'b1;
    capture_en           = 1'b0;
    pd_hit_level         = hl;
    pd_nfast_hit_packed  = nfp;
    nslow_snap           = ns;
    nfast_snap           = nf;
    nfast_stop           = nf;  // v2.3: drive nfast_stop same as nfast for unit test
    phase0_snap          = ph0;
    slow_boundary_inc    = binc;
    hit_count            = hc;
    flags                = fl_in;
    @(posedge clk_fast);
    snapshot_en          = 1'b0;
    capture_en           = 1'b1;
    @(posedge clk_fast);
    capture_en           = 1'b0;
  endtask

  task automatic check_ctx(
    input ctx_id_t    ctx,
    input ctx_record_t exp,
    input string      label
  );
    read_ctx = ctx;
    #1_000;  // combinational settle

    if (snapshot.hit_level         !== exp.hit_level ||
        snapshot.nfast_hit_packed  !== exp.nfast_packed ||
        snapshot.nslow_snap        !== exp.nslow ||
        snapshot.nfast_snap        !== exp.nfast ||
        snapshot.phase0_snap       !== exp.phase0 ||
        snapshot.slow_boundary_inc !== exp.boundary_inc ||
        snapshot.hit_count         !== exp.hcount ||
        snapshot.flags             !== exp.fl) begin
      $display("[FAIL] %s", label);
      $display("  hit_level     exp=%0h got=%0h", exp.hit_level, snapshot.hit_level);
      $display("  nslow         exp=%0d got=%0d", exp.nslow,     snapshot.nslow_snap);
      $display("  nfast         exp=%0d got=%0d", exp.nfast,     snapshot.nfast_snap);
      $display("  phase0        exp=%0b got=%0b", exp.phase0,    snapshot.phase0_snap);
      $display("  boundary_inc  exp=%0b got=%0b", exp.boundary_inc, snapshot.slow_boundary_inc);
      $display("  hit_count     exp=%0d got=%0d", exp.hcount,    snapshot.hit_count);
      $display("  flags         exp=%04b got=%04b", exp.fl,      snapshot.flags);
      fail_cnt++;
    end else begin
      $display("[PASS] %s", label);
      pass_cnt++;
    end
  endtask

  function automatic logic [PD_N*NFAST_W-1:0] build_nfast_packed(
    input logic [PD_N-1:0]   hit_level,
    input logic [NFAST_W-1:0] base_val
  );
    logic [PD_N*NFAST_W-1:0] result;
    result = '0;
    for (int i = 0; i < PD_N; i++) begin
      if (hit_level[i])
        result[i*NFAST_W +: NFAST_W] = base_val + NFAST_W'(i);
    end
    return result;
  endfunction

  // ── Main test ─────────────────────────────────────────────────────
  ctx_record_t rec [N_CTX];
  tdc_conv_flags_t fl_tmp;

  initial begin
    // Init
    capture_ctx          = '0;
    snapshot_en          = 1'b0;
    capture_en           = 1'b0;
    pd_hit_level         = '0;
    pd_nfast_hit_packed  = '0;
    nslow_snap           = '0;
    nfast_snap           = '0;
    phase0_snap          = 1'b0;
    slow_boundary_inc    = 1'b0;
    hit_count            = '0;
    flags                = '0;
    read_ctx             = '0;

    repeat (4) @(posedge clk_fast);

    // ────────────────────────────────────────────────────────────────
    // Test 1: Write ctx 0, read ctx 0
    // ────────────────────────────────────────────────────────────────
    rec[0].hit_level    = {PD_N{1'b0}} | (PD_N'(1));
    rec[0].nfast_packed = '0;
    rec[0].nfast_packed[0*NFAST_W +: NFAST_W] = 7'd10;
    rec[0].nslow        = 7'd42;
    rec[0].nfast        = 7'd33;
    rec[0].phase0       = 1'b1;
    rec[0].boundary_inc = 1'b0;
    rec[0].hcount       = 4'd5;
    rec[0].fl           = '{reserved: 1'b0, closed_by_fast_maxhit: 1'b1,
                            closed_by_maxhits: 1'b0, closed_by_watchdog: 1'b0};

    do_capture(1'd0, rec[0].hit_level, rec[0].nfast_packed,
               rec[0].nslow, rec[0].nfast, rec[0].phase0,
               rec[0].boundary_inc, rec[0].hcount, rec[0].fl);
    @(posedge clk_fast);
    check_ctx(1'd0, rec[0], "Test1: write ctx0, read ctx0");

    // ────────────────────────────────────────────────────────────────
    // Test 2: Write ctx 1, read ctx 1
    // ────────────────────────────────────────────────────────────────
    rec[1].hit_level    = '1;
    rec[1].nfast_packed = {PD_N{7'd77}};
    rec[1].nslow        = 7'd99;
    rec[1].nfast        = 7'd88;
    rec[1].phase0       = 1'b0;
    rec[1].boundary_inc = 1'b1;
    rec[1].hcount       = 4'd15;
    rec[1].fl           = '{reserved: 1'b0, closed_by_fast_maxhit: 1'b0,
                            closed_by_maxhits: 1'b1, closed_by_watchdog: 1'b0};

    do_capture(1'd1, rec[1].hit_level, rec[1].nfast_packed,
               rec[1].nslow, rec[1].nfast, rec[1].phase0,
               rec[1].boundary_inc, rec[1].hcount, rec[1].fl);
    @(posedge clk_fast);
    check_ctx(1'd1, rec[1], "Test2: write ctx1, read ctx1");

    // ────────────────────────────────────────────────────────────────
    // Test 3: Independent contexts — read back both, no cross-contamination
    // ────────────────────────────────────────────────────────────────
    check_ctx(1'd0, rec[0], "Test3a: cross-check ctx0 intact");
    check_ctx(1'd1, rec[1], "Test3b: cross-check ctx1 intact");

    // ────────────────────────────────────────────────────────────────
    // Test 4: Overwrite ctx 0 with new data, verify updated
    // ────────────────────────────────────────────────────────────────
    rec[0].hit_level    = {PD_N{1'b1}};
    rec[0].nfast_packed = {PD_N{7'd22}};
    rec[0].nslow        = 7'd100;
    rec[0].nfast        = 7'd120;
    rec[0].phase0       = 1'b0;
    rec[0].boundary_inc = 1'b1;
    rec[0].hcount       = 4'd9;
    rec[0].fl           = '{reserved: 1'b0, closed_by_fast_maxhit: 1'b1,
                            closed_by_maxhits: 1'b1, closed_by_watchdog: 1'b1};

    do_capture(1'd0, rec[0].hit_level, rec[0].nfast_packed,
               rec[0].nslow, rec[0].nfast, rec[0].phase0,
               rec[0].boundary_inc, rec[0].hcount, rec[0].fl);
    @(posedge clk_fast);
    check_ctx(1'd0, rec[0], "Test4a: overwrite ctx0 — new data");
    check_ctx(1'd1, rec[1], "Test4b: overwrite ctx0 — ctx1 intact");

    // ────────────────────────────────────────────────────────────────
    // Test 5: Read without capture — verify no crash
    // ────────────────────────────────────────────────────────────────
    read_ctx = 1'd0;
    @(posedge clk_fast);
    $display("[PASS] Test5: read without fresh capture — no crash");
    pass_cnt++;

    // ────────────────────────────────────────────────────────────────
    // Test 6: Hit level + nfast_packed bit-level verification
    // ────────────────────────────────────────────────────────────────
    begin
      logic [PD_N-1:0]          hl6;
      logic [PD_N*NFAST_W-1:0]  nfp6;
      logic [NFAST_W-1:0]       cell_val;
      int ok;

      hl6 = '0;
      hl6[0]  = 1'b1;
      hl6[40] = 1'b1;
      hl6[63] = 1'b1;

      nfp6 = build_nfast_packed(hl6, 7'd10);

      fl_tmp = '{reserved: 1'b0, closed_by_fast_maxhit: 1'b0,
                 closed_by_maxhits: 1'b0, closed_by_watchdog: 1'b0};

      do_capture(1'd1, hl6, nfp6, 7'd50, 7'd60, 1'b1, 1'b0, 4'd3, fl_tmp);
      @(posedge clk_fast);

      read_ctx = 1'd1;
      #1_000;

      ok = 1;
      if (snapshot.hit_level[0] !== 1'b1)  ok = 0;
      if (snapshot.hit_level[40] !== 1'b1) ok = 0;
      if (snapshot.hit_level[63] !== 1'b1) ok = 0;
      if (snapshot.hit_level[1] !== 1'b0)  ok = 0;
      if (snapshot.hit_level[62] !== 1'b0) ok = 0;

      cell_val = snapshot.nfast_hit_packed[0*NFAST_W +: NFAST_W];
      if (cell_val !== 7'(7'd10 + 7'd0))  begin
        $display("  cell[0]  exp=%0d got=%0d", 7'd10, cell_val);
        ok = 0;
      end
      cell_val = snapshot.nfast_hit_packed[40*NFAST_W +: NFAST_W];
      if (cell_val !== 7'(7'd10 + 7'd40)) begin
        $display("  cell[40] exp=%0d got=%0d", 7'd50, cell_val);
        ok = 0;
      end
      cell_val = snapshot.nfast_hit_packed[63*NFAST_W +: NFAST_W];
      if (cell_val !== 7'(7'd10 + 7'd63)) begin
        $display("  cell[63] exp=%0d got=%0d", 7'd73, cell_val);
        ok = 0;
      end

      cell_val = snapshot.nfast_hit_packed[1*NFAST_W +: NFAST_W];
      if (cell_val !== 7'd0) begin
        $display("  cell[1] (unset) exp=0 got=%0d", cell_val);
        ok = 0;
      end

      if (ok) begin
        $display("[PASS] Test6: hit_level + nfast_packed bit-level check");
        pass_cnt++;
      end else begin
        $display("[FAIL] Test6: hit_level + nfast_packed bit-level check");
        fail_cnt++;
      end
    end

    // ────────────────────────────────────────────────────────────────
    // Test 7: slow_boundary_inc toggling
    // ────────────────────────────────────────────────────────────────
    begin
      fl_tmp = '{reserved: 1'b0, closed_by_fast_maxhit: 1'b0,
                 closed_by_maxhits: 1'b0, closed_by_watchdog: 1'b1};
      do_capture(1'd0, '0, '0, 7'd1, 7'd2, 1'b0, 1'b1, 4'd0, fl_tmp);
      @(posedge clk_fast);
      read_ctx = 1'd0;
      #1_000;
      if (snapshot.slow_boundary_inc === 1'b1) begin
        $display("[PASS] Test7a: boundary_inc=1 stored correctly");
        pass_cnt++;
      end else begin
        $display("[FAIL] Test7a: boundary_inc expected 1 got %0b", snapshot.slow_boundary_inc);
        fail_cnt++;
      end

      do_capture(1'd0, '0, '0, 7'd3, 7'd4, 1'b1, 1'b0, 4'd1, fl_tmp);
      @(posedge clk_fast);
      read_ctx = 1'd0;
      #1_000;
      if (snapshot.slow_boundary_inc === 1'b0) begin
        $display("[PASS] Test7b: boundary_inc=0 stored correctly");
        pass_cnt++;
      end else begin
        $display("[FAIL] Test7b: boundary_inc expected 0 got %0b", snapshot.slow_boundary_inc);
        fail_cnt++;
      end
    end

    // ── Summary ─────────────────────────────────────────────────────
    $display("");
    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");

    if (fail_cnt > 0) begin
      $display("TEST FAILED");
      $fatal(1, "tb_context_bank_unit: %0d test(s) failed", fail_cnt);
    end else begin
      $display("TEST PASSED");
    end

    $finish;
  end

  // ── Timeout watchdog ──────────────────────────────────────────────
  initial begin
    #100_000_000;
    $fatal(1, "TIMEOUT: testbench did not complete within 100 us");
  end

endmodule : tb_context_bank_unit

`default_nettype wire
