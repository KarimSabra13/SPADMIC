// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// Focused Verilator smoke for context draining, FIFO backpressure, and record
// ordering. This does not exercise the async frontend or oscillator fabric.
`timescale 1ps/1ps
`default_nettype none

module tb_drain_ctrl_unit;
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

  int pass_cnt;
  int fail_cnt;

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

  task automatic wait_write(output mptdc_acq_rec_t rec, input string label);
    int cycles;
    cycles = 0;
    while (1) begin
      @(negedge clk_sys);
      #1;
      if (fifo_wr_en) begin
        rec = fifo_wr_data;
        $display("[INFO] captured write %s after %0d cycles", label, cycles);
        tick();
        return;
      end
      cycles++;
      if (cycles > 200)
        $fatal(1, "timeout waiting for FIFO write: %s", label);
    end
  endtask

  task automatic wait_release(input ctx_id_t ctx, input string label);
    int cycles;
    cycles = 0;
    while (!ctx_release[ctx]) begin
      tick();
      cycles++;
      if (cycles > 300)
        $fatal(1, "timeout waiting for release: %s", label);
    end
    check(conv_done, {label, ": conv_done with release"});
    tick();
  endtask

  task automatic build_snapshot();
    snapshot = '0;
    snapshot.hit_count = 4'd3;
    snapshot.hit_level[0]  = 1'b1;
    snapshot.hit_level[5]  = 1'b1;
    snapshot.hit_level[63] = 1'b1;
    snapshot.nfast_hit_packed[0*NFAST_W +: NFAST_W]  = 7'd10;
    snapshot.nfast_hit_packed[5*NFAST_W +: NFAST_W]  = 7'd15;
    snapshot.nfast_hit_packed[63*NFAST_W +: NFAST_W] = 7'd73;
    snapshot.nslow_snap = 7'd42;
    snapshot.nfast_snap = 7'd33;
    snapshot.nfast_stop = 7'd0;
    snapshot.phase0_snap = 1'b1;
    snapshot.stop_slow_phase_disc = 3'b101;
    snapshot.slow_boundary_inc = 1'b1;
    snapshot.flags = '{reserved: 1'b0, closed_by_fast_maxhit: 1'b0,
                       closed_by_maxhits: 1'b1, closed_by_watchdog: 1'b0};
  endtask

  initial begin
    mptdc_acq_rec_t rec;

    pass_cnt = 0;
    fail_cnt = 0;
    rst_n = 1'b0;
    ctx_drain_sync = '0;
    fifo_wr_full = 1'b0;
    build_snapshot();

    repeat (3) tick();
    rst_n = 1'b1;
    repeat (2) tick();
    check(state == ST_D_IDLE, "reset leaves drain in IDLE");

    ctx_drain_sync = 2'b01;
    tick();
    check(read_ctx == ctx_id_t'(0), "ctx0 selected");

    fifo_wr_full = 1'b1;
    repeat (3) begin
      tick();
      check(!fifo_wr_en, "no FIFO write while full");
    end
    fifo_wr_full = 1'b0;

    wait_write(rec, "META");
    check(rec.kind == ACQ_REC_META, "first record is META");
    check(rec.meta.nslow == snapshot.nslow_snap, "META nslow matches snapshot");
    check(rec.meta.hit_count == snapshot.hit_count, "META hit_count matches snapshot");
    check(rec.meta.flags == snapshot.flags, "META flags match snapshot");
    check(rec.meta.phase0_snap == snapshot.phase0_snap, "META phase0 matches snapshot");
    check(rec.meta.stop_slow_phase_disc == snapshot.stop_slow_phase_disc,
          "META stop phase discriminator matches");
    check(rec.meta.slow_boundary_inc == snapshot.slow_boundary_inc,
          "META slow boundary increment matches");

    wait_write(rec, "HIT0");
    check(rec.kind == ACQ_REC_HIT, "second record is HIT");
    check(rec.hit.ns == ph_idx_t'(0), "HIT0 ns");
    check(rec.hit.nf == ph_idx_t'(0), "HIT0 nf");
    check(rec.hit.nfast == 7'd10, "HIT0 nfast");
    check(rec.hit.event_seq == EVENT_SEQ_W'(0), "HIT0 event_seq");

    wait_write(rec, "HIT5");
    check(rec.kind == ACQ_REC_HIT, "third record is HIT");
    check(rec.hit.ns == ph_idx_t'(0), "HIT5 ns");
    check(rec.hit.nf == ph_idx_t'(5), "HIT5 nf");
    check(rec.hit.nfast == 7'd15, "HIT5 nfast");
    check(rec.hit.event_seq == EVENT_SEQ_W'(1), "HIT5 event_seq");

    wait_write(rec, "HIT63");
    check(rec.kind == ACQ_REC_HIT, "fourth record is HIT");
    check(rec.hit.ns == ph_idx_t'(7), "HIT63 ns");
    check(rec.hit.nf == ph_idx_t'(7), "HIT63 nf");
    check(rec.hit.nfast == 7'd73, "HIT63 nfast");
    check(rec.hit.event_seq == EVENT_SEQ_W'(2), "HIT63 event_seq");

    wait_release(ctx_id_t'(0), "ctx0 release");
    ctx_drain_sync = '0;
    repeat (4) tick();
    check(state == ST_D_IDLE, "drain returns to IDLE");
    check(!fifo_wr_en, "no extra FIFO write after release");

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_drain_ctrl_unit failed");
    $display("TEST PASSED");
    $finish;
  end

  initial begin
    #2_000_000;
    $fatal(1, "tb_drain_ctrl_unit timeout");
  end

endmodule

`default_nettype wire
