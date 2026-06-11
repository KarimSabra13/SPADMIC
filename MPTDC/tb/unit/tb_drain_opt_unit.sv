// SPDX-FileCopyrightText: 2026 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// Focused row-skip and stride-2 drain tests. Packet/acq record fields are
// intentionally checked against the baseline ordering contract.
`timescale 1ps/1ps
`default_nettype none

module tb_drain_opt_unit;
  import mptdc_pkg::*;

  logic clk_sys;
  initial clk_sys = 1'b0;
  always #3125 clk_sys = ~clk_sys;

  logic [N_CTX-1:0]       ctx_drain_sync;
  ctx_id_t                read_ctx;
  mptdc_ctx_snapshot_t    snapshot;
  logic                   fifo_wr_en;
  mptdc_acq_rec_t         fifo_wr_data;
  logic                   fifo_wr_full;
  logic [N_CTX-1:0]       ctx_release;
  logic                   conv_done;
  drain_state_e           state;
  logic                   rst_n;
  int                     pass_cnt;
  int                     fail_cnt;
  int                     hit_indices [0:15];
  int                     hit_count_expected;

  mptdc_drain_ctrl u_dut (
    .clk_sys          (clk_sys),
    .rst_n            (rst_n),
    .ctx_drain_sync_i (ctx_drain_sync),
    .read_ctx_o       (read_ctx),
    .snapshot_i       (snapshot),
    .fifo_wr_en_o     (fifo_wr_en),
    .fifo_wr_data_o   (fifo_wr_data),
    .fifo_wr_full_i   (fifo_wr_full),
    .ctx_release_o    (ctx_release),
    .conv_done_o      (conv_done),
    .state_o          (state)
  );

  function automatic logic [NFAST_W-1:0] tag_for_idx(input int idx);
    tag_for_idx = NFAST_W'((idx * 3 + 5) & ((1 << NFAST_W) - 1));
  endfunction

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

  task automatic reset_dut();
    rst_n = 1'b0;
    ctx_drain_sync = '0;
    fifo_wr_full = 1'b0;
    repeat (3) tick();
    rst_n = 1'b1;
    repeat (2) tick();
    check(state == ST_D_IDLE, "reset leaves drain in IDLE");
  endtask

  task automatic clear_snapshot();
    snapshot = '0;
    hit_count_expected = 0;
    for (int i = 0; i < 16; i++)
      hit_indices[i] = 0;
    snapshot.nslow_snap = 7'd21;
    snapshot.nfast_snap = 7'd37;
    snapshot.nfast_stop = 7'd41;
    snapshot.phase0_snap = 1'b1;
    snapshot.stop_slow_phase_disc = 3'b010;
    snapshot.slow_boundary_inc = 1'b0;
    snapshot.flags = '{reserved: 1'b0, closed_by_fast_maxhit: 1'b0,
                       closed_by_maxhits: 1'b0, closed_by_watchdog: 1'b0};
  endtask

  task automatic add_hit(input int idx);
    hit_indices[hit_count_expected] = idx;
    hit_count_expected++;
    snapshot.hit_count = MAX_HITS_W'(hit_count_expected);
    snapshot.hit_level[idx] = 1'b1;
    snapshot.nfast_hit_packed[idx*NFAST_W +: NFAST_W] = tag_for_idx(idx);
`ifdef MPTDC_DRAIN_ROW_SKIP
    snapshot.row_nonzero[idx / NE] = 1'b1;
`endif
  endtask

  task automatic add_bitmap_only_hit(input int idx);
    snapshot.hit_level[idx] = 1'b1;
    snapshot.nfast_hit_packed[idx*NFAST_W +: NFAST_W] = tag_for_idx(idx);
`ifdef MPTDC_DRAIN_ROW_SKIP
    snapshot.row_nonzero[idx / NE] = 1'b1;
`endif
  endtask

  task automatic wait_write(output mptdc_acq_rec_t rec, input string label);
    int cycles;
    cycles = 0;
    while (1) begin
      @(negedge clk_sys);
      #1;
      if (fifo_wr_en) begin
        rec = fifo_wr_data;
        $display("[INFO] %s after %0d cycles", label, cycles);
        tick();
        return;
      end
      cycles++;
      if (cycles > 300)
        $fatal(1, "timeout waiting for FIFO write: %s", label);
    end
  endtask

  task automatic wait_release(input string label);
    int cycles;
    cycles = 0;
    while (!ctx_release[ctx_id_t'(0)]) begin
      tick();
      cycles++;
      if (cycles > 400)
        $fatal(1, "timeout waiting for release: %s", label);
    end
    check(conv_done, {label, ": conv_done with release"});
    ctx_drain_sync = '0;
    tick();
  endtask

  task automatic expect_hit(input mptdc_acq_rec_t rec, input int idx, input int seq, input string label);
    check(rec.kind == ACQ_REC_HIT, {label, ": record kind HIT"});
    check(rec.hit.ns == ph_idx_t'(idx / NE), {label, ": ns"});
    check(rec.hit.nf == ph_idx_t'(idx % NE), {label, ": nf"});
    check(rec.hit.nfast == tag_for_idx(idx), {label, ": nfast tag"});
    check(rec.hit.event_seq == EVENT_SEQ_W'(seq), {label, ": event_seq"});
  endtask

  task automatic run_case(input string label, input bit backpressure_before_hits);
    mptdc_acq_rec_t rec;

    reset_dut();
    ctx_drain_sync = 2'b01;
    tick();
    check(read_ctx == ctx_id_t'(0), {label, ": ctx0 selected"});

    wait_write(rec, {label, " META"});
    check(rec.kind == ACQ_REC_META, {label, ": first record META"});
    check(rec.meta.hit_count == MAX_HITS_W'(hit_count_expected),
          {label, ": META hit_count"});

    if (backpressure_before_hits) begin
      fifo_wr_full = 1'b1;
      repeat (4) begin
        tick();
        check(!fifo_wr_en, {label, ": no write while FIFO full"});
      end
      fifo_wr_full = 1'b0;
    end

    for (int i = 0; i < hit_count_expected; i++) begin
      wait_write(rec, {label, " HIT"});
      expect_hit(rec, hit_indices[i], i, {label, " HIT"});
    end

    wait_release(label);
    repeat (3) tick();
    check(!fifo_wr_en, {label, ": no extra record after release"});
  endtask

  initial begin
`ifndef MPTDC_DRAIN_ROW_SKIP
    $display("[SKIP] MPTDC_DRAIN_ROW_SKIP not enabled");
    $finish;
`else
`ifndef MPTDC_DRAIN_SCAN_STRIDE2
    $display("[SKIP] MPTDC_DRAIN_SCAN_STRIDE2 not enabled");
    $finish;
`else
    pass_cnt = 0;
    fail_cnt = 0;
    rst_n = 1'b0;
    ctx_drain_sync = '0;
    fifo_wr_full = 1'b0;

    clear_snapshot();
    run_case("row_skip_h0", 1'b0);

    for (int row = 0; row < NE; row++) begin
      clear_snapshot();
      add_hit(row * NE + 3);
      run_case($sformatf("row_skip_h1_row%0d", row), 1'b0);
    end

    clear_snapshot();
    for (int idx = 0; idx < 15; idx++)
      add_hit(idx * 4);
    run_case("row_skip_h15_sparse", 1'b0);

    clear_snapshot();
    for (int idx = 0; idx < 15; idx++)
      add_hit(idx);
    add_bitmap_only_hit(15);
    run_case("stride2_saturated_adjacent_pair", 1'b0);

    clear_snapshot();
    add_hit(10);
    add_hit(11);
    run_case("stride2_adjacent_backpressure", 1'b1);

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_drain_opt_unit failed");
    $display("TEST PASSED");
    $finish;
`endif
`endif
  end

  initial begin
    #5_000_000;
    $fatal(1, "tb_drain_opt_unit timeout");
  end

endmodule

`default_nettype wire
