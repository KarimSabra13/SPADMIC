`timescale 1ns/1ps
`default_nettype none
// =============================================================================
// Testbench : tb_writer_scan_unit
// DUT       : mptdc_writer_scan  (rtl/async/mptdc_writer_scan.sv)
// Purpose   : Self-checking unit tests for the PD-scan writer.
// =============================================================================
module tb_writer_scan_unit;
  import mptdc_pkg::*;

  // =========================================================================
  // Clock (~900 ps period) and async-deassert reset
  // =========================================================================
  logic clk_fast;
  initial clk_fast = 0;
  always #0.450 clk_fast = ~clk_fast;

  logic rst_async_n;

  // =========================================================================
  // DUT interface
  // =========================================================================
  // drain_req is the TB-facing request; drain_start_r is the registered
  // version that feeds the DUT.  This one-cycle pipeline ensures that
  // drain_start_r deasserts in the same NBA phase as state_r advances,
  // which satisfies the DUT's p_no_start_while_active assertion cleanly.
  logic                   drain_req;
  logic                   drain_start_r;
  ctx_id_t                drain_ctx_i;
  mptdc_ctx_snapshot_t    snapshot_i;
  logic                   fifo_full_i;
  logic                   fifo_wr_en_o;
  mptdc_acq_rec_t         fifo_wr_data_o;
  logic                   writer_done_o;
  logic                   ctx_release_o;
  logic                   scan_active_o;

  always_ff @(posedge clk_fast or negedge rst_async_n) begin
    if (!rst_async_n)
      drain_start_r <= 1'b0;
    else
      drain_start_r <= drain_req;
  end

  mptdc_writer_scan dut (
    .clk_fast       (clk_fast),
    .rst_async_n    (rst_async_n),
    .drain_start_i  (drain_start_r),
    .drain_ctx_i    (drain_ctx_i),
    .snapshot_i     (snapshot_i),
    .fifo_full_i    (fifo_full_i),
    .fifo_wr_en_o   (fifo_wr_en_o),
    .fifo_wr_data_o (fifo_wr_data_o),
    .writer_done_o  (writer_done_o),
    .ctx_release_o  (ctx_release_o),
    .scan_active_o  (scan_active_o)
  );

  // =========================================================================
  // Record buffer and scoreboard
  // =========================================================================
  localparam int MAX_REC = 17;          // META + up to 15 HITs + margin
  mptdc_acq_rec_t rec_buf [0:MAX_REC-1];
  int pass_cnt;
  int fail_cnt;

  // =========================================================================
  // Helpers
  // =========================================================================
  task automatic check(input string name, input logic cond);
    if (cond) begin
      $display("[PASS] %s", name);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s", name);
      fail_cnt++;
    end
  endtask

  // Pulse drain_req for one cycle.  Because drain_start_r is registered,
  // the DUT sees drain_start=1 one cycle later.  Both drain_start_r and
  // state_r update via NBA in the same posedge, so the assertion is clean.
  // Snapshot/ctx are held stable from cycle A and remain so when the DUT
  // latches them at cycle A+2.
  task automatic drain_and_collect(
    input  ctx_id_t              ctx,
    input  mptdc_ctx_snapshot_t  snap,
    output int                   count
  );
    count = 0;
    // Cycle A: present request + context/snapshot
    @(posedge clk_fast);
    drain_req   = 1'b1;
    drain_ctx_i = ctx;
    snapshot_i  = snap;
    // Cycle A+1: drain_start_r goes high (NBA); deassert request
    @(posedge clk_fast);
    drain_req   = 1'b0;
    // Collect records at every posedge until writer_done_o fires.
    // In Verilator's cycle-based model, combinational outputs seen by
    // the TB at posedge N reflect state_r after that posedge's settle.
    forever begin
      @(posedge clk_fast);
      if (fifo_wr_en_o) begin
        rec_buf[count] = fifo_wr_data_o;
        count++;
      end
      if (writer_done_o) return;
    end
  endtask

  // =========================================================================
  // Stimulus
  // =========================================================================
  initial begin
    pass_cnt      = 0;
    fail_cnt      = 0;
    rst_async_n   = 1'b0;
    drain_req     = 1'b0;
    drain_ctx_i   = '0;
    snapshot_i    = '0;
    fifo_full_i   = 1'b0;

    repeat (5) @(posedge clk_fast);
    rst_async_n = 1'b1;
    repeat (3) @(posedge clk_fast);

    // =================================================================
    // T1 — Zero hits: expect 1 META, no HITs
    // =================================================================
    $display("\n--- T1: Zero hits ---");
    begin
      mptdc_ctx_snapshot_t s;
      int cnt;
      s            = '0;
      s.nslow_snap = 7'd10;
      s.nfast_snap = 7'd8;
      s.hit_count  = 4'd0;
      drain_and_collect(2'd0, s, cnt);
      check("T1: record count == 1",  cnt == 1);
      check("T1: rec[0] is META",     rec_buf[0].kind == ACQ_REC_META);
    end
    repeat (3) @(posedge clk_fast);

    // =================================================================
    // T2 — Single hit at cell 0
    // =================================================================
    $display("\n--- T2: Single hit (cell 0) ---");
    begin
      mptdc_ctx_snapshot_t s;
      int cnt;
      s = '0;
      s.hit_level[0]                    = 1'b1;
      s.nfast_hit_packed[0 +: NFAST_W]  = 7'd42;
      s.nslow_snap = 7'd10;
      s.nfast_snap = 7'd8;
      s.hit_count  = 4'd1;
      drain_and_collect(2'd1, s, cnt);
      check("T2: record count == 2",    cnt == 2);
      check("T2: rec[0] META",          rec_buf[0].kind == ACQ_REC_META);
      check("T2: rec[1] HIT",           rec_buf[1].kind == ACQ_REC_HIT);
      check("T2: HIT ns == 0",          rec_buf[1].hit.ns == 4'd0);
      check("T2: HIT nf == 0",          rec_buf[1].hit.nf == 4'd0);
      check("T2: HIT nfast == 42",      rec_buf[1].hit.nfast == 7'd42);
      check("T2: HIT event_seq == 0",   rec_buf[1].hit.event_seq == 4'd0);
    end
    repeat (3) @(posedge clk_fast);

    // =================================================================
    // T3 — 3 scattered hits at cells 0, 40, 80
    // =================================================================
    $display("\n--- T3: 3 scattered hits ---");
    begin
      mptdc_ctx_snapshot_t s;
      int cnt;
      s = '0;
      s.hit_level[0]  = 1'b1;
      s.hit_level[40] = 1'b1;
      s.hit_level[80] = 1'b1;
      s.nfast_hit_packed[0*NFAST_W  +: NFAST_W] = 7'd42;
      s.nfast_hit_packed[40*NFAST_W +: NFAST_W] = 7'd77;
      s.nfast_hit_packed[80*NFAST_W +: NFAST_W] = 7'd99;
      s.nslow_snap = 7'd20;
      s.nfast_snap = 7'd15;
      s.hit_count  = 4'd3;
      drain_and_collect(2'd2, s, cnt);
      check("T3: record count == 4",       cnt == 4);
      // Cell  0 → ns=0, nf=0
      check("T3: HIT[0] ns == 0",          rec_buf[1].hit.ns == 4'd0);
      check("T3: HIT[0] nf == 0",          rec_buf[1].hit.nf == 4'd0);
      check("T3: HIT[0] nfast == 42",      rec_buf[1].hit.nfast == 7'd42);
      check("T3: HIT[0] event_seq == 0",   rec_buf[1].hit.event_seq == 4'd0);
      // Cell 40 → 40/9=4, 40%9=4
      check("T3: HIT[1] ns == 4",          rec_buf[2].hit.ns == 4'd4);
      check("T3: HIT[1] nf == 4",          rec_buf[2].hit.nf == 4'd4);
      check("T3: HIT[1] nfast == 77",      rec_buf[2].hit.nfast == 7'd77);
      check("T3: HIT[1] event_seq == 1",   rec_buf[2].hit.event_seq == 4'd1);
      // Cell 80 → 80/9=8, 80%9=8
      check("T3: HIT[2] ns == 8",          rec_buf[3].hit.ns == 4'd8);
      check("T3: HIT[2] nf == 8",          rec_buf[3].hit.nf == 4'd8);
      check("T3: HIT[2] nfast == 99",      rec_buf[3].hit.nfast == 7'd99);
      check("T3: HIT[2] event_seq == 2",   rec_buf[3].hit.event_seq == 4'd2);
    end
    repeat (3) @(posedge clk_fast);

    // =================================================================
    // T4 — Full 15 hits (cells 0..14)
    // =================================================================
    $display("\n--- T4: Full 15 hits ---");
    begin
      mptdc_ctx_snapshot_t s;
      int cnt, ok;
      s = '0;
      s.nslow_snap = 7'd30;
      s.nfast_snap = 7'd25;
      s.hit_count  = 4'd15;
      for (int i = 0; i < 15; i++) begin
        s.hit_level[i] = 1'b1;
        s.nfast_hit_packed[i*NFAST_W +: NFAST_W] = NFAST_W'(i + 10);
      end
      drain_and_collect(2'd0, s, cnt);
      check("T4: record count == 16", cnt == 16);
      ok = 1;
      for (int i = 0; i < 15; i++) begin
        if (rec_buf[i+1].kind          != ACQ_REC_HIT)        ok = 0;
        if (rec_buf[i+1].hit.event_seq != EVENT_SEQ_W'(i))    ok = 0;
        if (rec_buf[i+1].hit.ns        != ph_idx_t'(i / NE))  ok = 0;
        if (rec_buf[i+1].hit.nf        != ph_idx_t'(i % NE))  ok = 0;
        if (rec_buf[i+1].hit.nfast     != NFAST_W'(i + 10))   ok = 0;
      end
      check("T4: all HIT fields correct", ok == 1);
    end
    repeat (3) @(posedge clk_fast);

    // =================================================================
    // T5 — FIFO backpressure stalls and resumes
    // =================================================================
    $display("\n--- T5: FIFO backpressure ---");
    begin
      mptdc_ctx_snapshot_t s;
      int stall_ok;
      s = '0;
      s.hit_level[0] = 1'b1;
      s.hit_level[1] = 1'b1;
      s.hit_level[2] = 1'b1;
      s.nfast_hit_packed[0*NFAST_W +: NFAST_W] = 7'd50;
      s.nfast_hit_packed[1*NFAST_W +: NFAST_W] = 7'd51;
      s.nfast_hit_packed[2*NFAST_W +: NFAST_W] = 7'd52;
      s.hit_count = 4'd3;
      // Start drain (one pipeline cycle for registered drain_start)
      @(posedge clk_fast);
      drain_req   = 1'b1;
      drain_ctx_i = 2'd0;
      snapshot_i  = s;
      @(posedge clk_fast);
      drain_req   = 1'b0;
      // Let the META write happen, then assert full a few cycles later
      repeat (4) @(posedge clk_fast);
      fifo_full_i = 1'b1;
      // Verify: wr_en must stay low while full
      stall_ok = 1;
      repeat (10) begin
        @(posedge clk_fast);
        if (fifo_wr_en_o) stall_ok = 0;
      end
      check("T5: no wr_en while FIFO full",   stall_ok == 1);
      check("T5: scan_active during stall",   scan_active_o == 1'b1);
      // Release
      @(posedge clk_fast);
      fifo_full_i = 1'b0;
      // Verify the DUT completes after stall release (not stuck)
      forever begin
        @(posedge clk_fast);
        if (writer_done_o) break;
      end
      // One more cycle for state to return to IDLE
      @(posedge clk_fast);
      check("T5: writer completed after release", scan_active_o == 1'b0);
    end
    repeat (3) @(posedge clk_fast);

    // =================================================================
    // T6 — scan_active_o tracks busy state
    // =================================================================
    $display("\n--- T6: scan_active_o ---");
    begin
      mptdc_ctx_snapshot_t s;
      s = '0;
      s.hit_level[0]                   = 1'b1;
      s.nfast_hit_packed[0 +: NFAST_W] = 7'd1;
      s.hit_count                      = 4'd1;
      // Idle
      check("T6: idle → scan_active == 0", scan_active_o == 1'b0);
      // Start (one pipeline cycle for registered drain_start)
      @(posedge clk_fast);
      drain_req   = 1'b1;
      drain_ctx_i = 2'd0;
      snapshot_i  = s;
      @(posedge clk_fast);
      drain_req   = 1'b0;
      // Wait a couple of posedges for state to leave IDLE
      repeat (2) @(posedge clk_fast);
      check("T6: active → scan_active == 1", scan_active_o == 1'b1);
      // Wait for done
      forever begin
        @(posedge clk_fast);
        if (writer_done_o) break;
      end
      check("T6: done → scan_active == 1", scan_active_o == 1'b1);
      // After done, back to idle
      @(posedge clk_fast);
      check("T6: post-done → scan_active == 0", scan_active_o == 1'b0);
    end
    repeat (3) @(posedge clk_fast);

    // =================================================================
    // T7 — Context-ID / META field passthrough
    // =================================================================
    $display("\n--- T7: Context ID passthrough ---");
    begin
      mptdc_ctx_snapshot_t s;
      int cnt;
      s              = '0;
      s.nslow_snap   = 7'd33;
      s.hit_count    = 4'd0;
      s.phase0_snap  = 1'b1;
      s.flags        = '0;
      drain_and_collect(2'd2, s, cnt);
      check("T7: META ctx_id == 2",      rec_buf[0].meta.ctx_id == 2'd2);
      check("T7: META nslow == 33",      rec_buf[0].meta.nslow == 7'd33);
      check("T7: META hit_count == 0",   rec_buf[0].meta.hit_count == 4'd0);
      check("T7: META phase0_snap == 1", rec_buf[0].meta.phase0_snap == 1'b1);
    end

    // =================================================================
    // Summary
    // =================================================================
    repeat (5) @(posedge clk_fast);
    $display("");
    $display("=== Results: %0d passed, %0d failed ===", pass_cnt, fail_cnt);
    if (fail_cnt == 0) begin
      $display("TEST PASSED");
      $finish;
    end else begin
      $fatal(1, "TEST FAILED — %0d checks failed", fail_cnt);
    end
  end

  // Global timeout watchdog
  initial begin
    #100_000;
    $fatal(1, "TIMEOUT: simulation exceeded 100 us");
  end

endmodule

`default_nettype wire
