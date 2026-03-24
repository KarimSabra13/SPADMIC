`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// tb_narrow16_tx_v2_unit — Self-checking unit testbench for
//                          mptdc_narrow16_tx_v2 (16-bit ready/valid serializer)
// =============================================================================
module tb_narrow16_tx_v2_unit;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  // ── Clock & reset ─────────────────────────────────────────────────
  logic clk_sys;
  initial clk_sys = 0;
  always #3.125 clk_sys = ~clk_sys;  // 160 MHz

  logic rst_n;

  // ── DUT signals ───────────────────────────────────────────────────
  out_mode_e          out_mode;
  logic               fifo_rd_valid;
  mptdc_acq_rec_t     fifo_rd_data;
  logic               fifo_rd_en;
  logic               narrow_ready;
  logic               narrow_valid;
  logic [NARROW_W-1:0] narrow_data;

  // ── FIFO model ────────────────────────────────────────────────────
  mptdc_acq_rec_t fifo_mem [$];

  assign fifo_rd_valid = (fifo_mem.size() > 0);
  assign fifo_rd_data  = (fifo_mem.size() > 0) ? fifo_mem[0] : '0;

  always_ff @(posedge clk_sys) begin
    if (fifo_rd_en && fifo_mem.size() > 0)
      void'(fifo_mem.pop_front());
  end

  // ── DUT ───────────────────────────────────────────────────────────
  mptdc_narrow16_tx_v2 u_dut (
    .clk_sys        (clk_sys),
    .rst_n          (rst_n),
    .out_mode_i     (out_mode),
    .fifo_rd_valid_i(fifo_rd_valid),
    .fifo_rd_data_i (fifo_rd_data),
    .fifo_rd_en_o   (fifo_rd_en),
    .narrow_ready_i (narrow_ready),
    .narrow_valid_o (narrow_valid),
    .narrow_data_o  (narrow_data)
  );

  // ── Helpers ───────────────────────────────────────────────────────
  int pass_count;
  int fail_count;

  task automatic push_meta(
    input logic [NSLOW_W-1:0]    nslow,
    input logic [MAX_HITS_W-1:0] hit_count,
    input ctx_id_t               ctx_id,
    input logic                  phase0,
    input tdc_conv_flags_t       flags
  );
    mptdc_acq_rec_t rec;
    rec.kind            = ACQ_REC_META;
    rec.meta.nslow      = nslow;
    rec.meta.hit_count  = hit_count;
    rec.meta.ctx_id     = ctx_id;
    rec.meta.phase0_snap = phase0;
    rec.meta.flags      = flags;
    rec.hit             = '0;
    fifo_mem.push_back(rec);
  endtask

  task automatic push_hit(
    input ph_idx_t                ns,
    input ph_idx_t                nf,
    input logic [NFAST_W-1:0]     nfast,
    input logic [EVENT_SEQ_W-1:0] event_seq
  );
    mptdc_acq_rec_t rec;
    rec.kind          = ACQ_REC_HIT;
    rec.hit.ns        = ns;
    rec.hit.nf        = nf;
    rec.hit.nfast     = nfast;
    rec.hit.event_seq = event_seq;
    rec.meta          = '0;
    fifo_mem.push_back(rec);
  endtask

  // Collect exactly one packet (header through EOC) with timeout
  task automatic collect_pkt(
    output logic [NARROW_W-1:0] words [$],
    input  int timeout_cyc = 2000
  );
    int cyc;
    logic [NARROW_W-1:0] w;
    words = {};
    cyc   = 0;

    // Wait for header
    forever begin
      @(posedge clk_sys);
      cyc++;
      if (cyc > timeout_cyc) begin
        $display("[FAIL] Timeout waiting for header");
        fail_count++;
        return;
      end
      if (narrow_valid && narrow_ready) begin
        w = narrow_data;
        words.push_back(w);
        break;
      end
    end

    // Collect remaining words until EOC
    forever begin
      @(posedge clk_sys);
      cyc++;
      if (cyc > timeout_cyc) begin
        $display("[FAIL] Timeout waiting for EOC");
        fail_count++;
        return;
      end
      if (narrow_valid && narrow_ready) begin
        w = narrow_data;
        words.push_back(w);
        if (is_eoc(w)) return;
      end
    end
  endtask

  // Check helper
  task automatic check(input string label, input logic cond);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_count++;
    end else begin
      $display("[FAIL] %s", label);
      fail_count++;
    end
  endtask

  // ── Reset ─────────────────────────────────────────────────────────
  task automatic do_reset();
    rst_n = 1'b0;
    narrow_ready = 1'b0;
    out_mode = OUT_MODE_RAW_FEATURES;
    fifo_mem.delete();
    repeat (5) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);
  endtask

  // ── Compute expected t_raw_ps (must match DUT's formula) ──────────
  function automatic logic signed [31:0] calc_t_raw_ps(
    input logic [NSLOW_W-1:0] nslow,
    input logic [NFAST_W-1:0] nfast,
    input ph_idx_t            ns,
    input ph_idx_t            nf
  );
    int signed coef;
    coef = (int'(nslow) - 1) * int'(K_VERNIER) * int'(NE)
         + (int'(nfast) - 1) * int'(NE)
         + int'(ns) * int'(K_VERNIER)
         - int'(nf) * (int'(K_VERNIER) - 1);
    return 32'(coef * int'(DELTA_LSB));
  endfunction

  // ── Main test sequence ────────────────────────────────────────────
  initial begin
    logic [NARROW_W-1:0] pkt [$];
    logic [NARROW_W-1:0] w;
    logic signed [31:0] t_raw_exp;
    int n;

    pass_count = 0;
    fail_count = 0;

    $display("=== tb_narrow16_tx_v2_unit ===");
    do_reset();

    // ────────────────────────────────────────────────────────────────
    // TEST 1: RAW_FEATURES mode, 1 hit
    // ────────────────────────────────────────────────────────────────
    $display("\n--- Test 1: RAW_FEATURES, 1 hit ---");
    out_mode = OUT_MODE_RAW_FEATURES;
    narrow_ready = 1'b1;
    @(posedge clk_sys);

    push_meta(.nslow(7'd10), .hit_count(4'd1), .ctx_id(2'd0),
              .phase0(1'b1), .flags(4'b0));
    push_hit(.ns(4'd2), .nf(4'd3), .nfast(7'd5), .event_seq(4'd0));

    collect_pkt(pkt);
    n = pkt.size();
    check("T1 word_count==5", n == 5);

    if (n >= 5) begin
      // Header
      w = pkt[0];
      check("T1 header marker",   w[15:14] == 2'b10);
      check("T1 header ctx_id",   w[13:12] == 2'd0);
      check("T1 header phase0",   w[11]    == 1'b1);
      check("T1 header hit_count",w[10:7]  == 4'd1);
      check("T1 header flags",    w[6:3]   == 4'b0);
      check("T1 header out_mode", w[2:1]   == 2'(OUT_MODE_RAW_FEATURES));
      check("T1 header rsvd",     w[0]     == 1'b0);

      // Hit W0: nslow=10, nfast=5
      w = pkt[1];
      check("T1 W0 bit15",  w[15]   == 1'b0);
      check("T1 W0 nslow",  w[14:8] == 7'd10);
      check("T1 W0 nfast",  w[7:1]  == 7'd5);
      check("T1 W0 bit0",   w[0]    == 1'b0);

      // Hit W1 features: ns=2, nf=3, pd_idx=pd_from_phases(2,3)
      w = pkt[2];
      check("T1 W1 bit15",  w[15]    == 1'b0);
      check("T1 W1 ns",     w[14:11] == 4'd2);
      check("T1 W1 nf",     w[10:7]  == 4'd3);
      check("T1 W1 pd_idx", w[6:0]   == pd_from_phases(4'd2, 4'd3));

      // Hit W2: event_seq=0
      w = pkt[3];
      check("T1 W2 bit15",     w[15]    == 1'b0);
      check("T1 W2 event_seq", w[14:11] == 4'd0);
      check("T1 W2 padding",   w[10:0]  == 11'b0);

      // EOC: conv_count=0
      w = pkt[4];
      check("T1 EOC marker",   w[15:14] == 2'b11);
      check("T1 EOC count",    w[13:0]  == 14'd0);
    end

    // ────────────────────────────────────────────────────────────────
    // TEST 2: RAW_FEATURES mode, 0 hits
    // ────────────────────────────────────────────────────────────────
    $display("\n--- Test 2: RAW_FEATURES, 0 hits ---");
    out_mode = OUT_MODE_RAW_FEATURES;
    @(posedge clk_sys);

    push_meta(.nslow(7'd20), .hit_count(4'd0), .ctx_id(2'd1),
              .phase0(1'b0), .flags(4'b0));

    collect_pkt(pkt);
    n = pkt.size();
    check("T2 word_count==2", n == 2);

    if (n >= 2) begin
      w = pkt[0];
      check("T2 header marker",    w[15:14] == 2'b10);
      check("T2 header ctx_id",    w[13:12] == 2'd1);
      check("T2 header hit_count", w[10:7]  == 4'd0);

      w = pkt[1];
      check("T2 EOC marker", w[15:14] == 2'b11);
      check("T2 EOC count",  w[13:0]  == 14'd1);  // second packet
    end

    // ────────────────────────────────────────────────────────────────
    // TEST 3: RAW_TIMESTAMP mode, 2 hits
    // ────────────────────────────────────────────────────────────────
    $display("\n--- Test 3: RAW_TIMESTAMP, 2 hits ---");
    out_mode = OUT_MODE_RAW_TIMESTAMP;
    @(posedge clk_sys);

    push_meta(.nslow(7'd15), .hit_count(4'd2), .ctx_id(2'd2),
              .phase0(1'b1), .flags(4'b0101));
    push_hit(.ns(4'd1), .nf(4'd2), .nfast(7'd8), .event_seq(4'd0));
    push_hit(.ns(4'd4), .nf(4'd5), .nfast(7'd10), .event_seq(4'd1));

    collect_pkt(pkt);
    n = pkt.size();
    // Header + 2*(W0+W1_ts) + EOC = 1 + 4 + 1 = 6
    check("T3 word_count==6", n == 6);

    if (n >= 6) begin
      w = pkt[0];
      check("T3 header marker",    w[15:14] == 2'b10);
      check("T3 header ctx_id",    w[13:12] == 2'd2);
      check("T3 header phase0",    w[11]    == 1'b1);
      check("T3 header hit_count", w[10:7]  == 4'd2);
      check("T3 header flags",     w[6:3]   == 4'b0101);
      check("T3 header out_mode",  w[2:1]   == 2'(OUT_MODE_RAW_TIMESTAMP));

      // Hit 0 W0
      w = pkt[1];
      check("T3 H0 W0 nslow", w[14:8] == 7'd15);
      check("T3 H0 W0 nfast", w[7:1]  == 7'd8);

      // Hit 0 W1 timestamp
      t_raw_exp = calc_t_raw_ps(7'd15, 7'd8, 4'd1, 4'd2);
      w = pkt[2];
      check("T3 H0 W1 t_raw", w == t_raw_exp[15:0]);

      // Hit 1 W0
      w = pkt[3];
      check("T3 H1 W0 nslow", w[14:8] == 7'd15);
      check("T3 H1 W0 nfast", w[7:1]  == 7'd10);

      // Hit 1 W1 timestamp
      t_raw_exp = calc_t_raw_ps(7'd15, 7'd10, 4'd4, 4'd5);
      w = pkt[4];
      check("T3 H1 W1 t_raw", w == t_raw_exp[15:0]);

      // EOC
      w = pkt[5];
      check("T3 EOC marker", w[15:14] == 2'b11);
      check("T3 EOC count",  w[13:0]  == 14'd2);
    end

    // ────────────────────────────────────────────────────────────────
    // TEST 4: FULL mode, 1 hit
    // ────────────────────────────────────────────────────────────────
    $display("\n--- Test 4: FULL mode, 1 hit ---");
    out_mode = OUT_MODE_FULL;
    @(posedge clk_sys);

    push_meta(.nslow(7'd30), .hit_count(4'd1), .ctx_id(2'd0),
              .phase0(1'b0), .flags(4'b1000));
    push_hit(.ns(4'd7), .nf(4'd8), .nfast(7'd20), .event_seq(4'd3));

    collect_pkt(pkt);
    n = pkt.size();
    // Header + W0+W1_feat+W2+W3 + EOC = 1 + 4 + 1 = 6
    check("T4 word_count==6", n == 6);

    if (n >= 6) begin
      w = pkt[0];
      check("T4 header out_mode", w[2:1] == 2'(OUT_MODE_FULL));
      check("T4 header flags",    w[6:3] == 4'b1000);

      // W0
      w = pkt[1];
      check("T4 W0 nslow", w[14:8] == 7'd30);
      check("T4 W0 nfast", w[7:1]  == 7'd20);

      // W1 features (FULL uses features variant)
      w = pkt[2];
      check("T4 W1 ns",     w[14:11] == 4'd7);
      check("T4 W1 nf",     w[10:7]  == 4'd8);
      check("T4 W1 pd_idx", w[6:0]   == pd_from_phases(4'd7, 4'd8));

      // W2
      w = pkt[3];
      check("T4 W2 event_seq", w[14:11] == 4'd3);

      // W3 timestamp
      t_raw_exp = calc_t_raw_ps(7'd30, 7'd20, 4'd7, 4'd8);
      w = pkt[4];
      check("T4 W3 t_raw", w == t_raw_exp[15:0]);

      // EOC
      w = pkt[5];
      check("T4 EOC marker", w[15:14] == 2'b11);
      check("T4 EOC count",  w[13:0]  == 14'd3);
    end

    // ────────────────────────────────────────────────────────────────
    // TEST 5: Backpressure
    // Deassert ready BEFORE the DUT can present the header, so the
    // header is stalled (valid=1, ready=0 → no acceptance).
    // ────────────────────────────────────────────────────────────────
    $display("\n--- Test 5: Backpressure ---");
    out_mode = OUT_MODE_RAW_FEATURES;
    narrow_ready = 1'b0;   // ready OFF before pushing
    @(posedge clk_sys);

    push_meta(.nslow(7'd5), .hit_count(4'd1), .ctx_id(2'd0),
              .phase0(1'b0), .flags(4'b0));
    push_hit(.ns(4'd1), .nf(4'd1), .nfast(7'd3), .event_seq(4'd0));

    // Wait until header appears on output (valid high, but ready=0)
    begin
      int wait_cyc = 0;
      while (wait_cyc < 200) begin
        @(posedge clk_sys);
        wait_cyc++;
        if (narrow_valid) break;
      end
      check("T5 header arrives", narrow_valid == 1'b1);
    end

    // Verify stall: valid stays high, data held, no FIFO pops
    begin
      logic [NARROW_W-1:0] stall_data;
      stall_data = narrow_data;
      repeat (10) @(posedge clk_sys);
      check("T5 valid held during stall", narrow_valid == 1'b1);
      check("T5 data held during stall",  narrow_data == stall_data);
    end

    // Reassert ready and collect the full packet (header through EOC)
    narrow_ready = 1'b1;
    collect_pkt(pkt);
    n = pkt.size();
    check("T5 packet completes after stall", n == 5);

    if (n >= 1) begin
      w = pkt[n-1];
      check("T5 EOC marker", w[15:14] == 2'b11);
    end

    // ────────────────────────────────────────────────────────────────
    // TEST 6: Multiple back-to-back packets — conv_count increments
    // ────────────────────────────────────────────────────────────────
    $display("\n--- Test 6: Back-to-back packets ---");

    // Reset to get a known conv_count baseline
    do_reset();
    out_mode = OUT_MODE_RAW_FEATURES;
    narrow_ready = 1'b1;
    @(posedge clk_sys);

    // Packet A: 0 hits
    push_meta(.nslow(7'd1), .hit_count(4'd0), .ctx_id(2'd0),
              .phase0(1'b0), .flags(4'b0));
    // Packet B: 0 hits
    push_meta(.nslow(7'd2), .hit_count(4'd0), .ctx_id(2'd1),
              .phase0(1'b1), .flags(4'b0));

    collect_pkt(pkt);
    check("T6 pktA size==2", pkt.size() == 2);
    if (pkt.size() >= 2) begin
      check("T6 pktA EOC count==0", pkt[1][13:0] == 14'd0);
    end

    collect_pkt(pkt);
    check("T6 pktB size==2", pkt.size() == 2);
    if (pkt.size() >= 2) begin
      check("T6 pktB EOC count==1", pkt[1][13:0] == 14'd1);
      check("T6 pktB ctx_id==1",    pkt[0][13:12] == 2'd1);
    end

    // ────────────────────────────────────────────────────────────────
    // TEST 7: Header encoding — all fields
    // ────────────────────────────────────────────────────────────────
    $display("\n--- Test 7: Header encoding ---");
    do_reset();
    out_mode = OUT_MODE_RAW_TIMESTAMP;
    narrow_ready = 1'b1;
    @(posedge clk_sys);

    push_meta(.nslow(7'd50), .hit_count(4'd0), .ctx_id(2'd2),
              .phase0(1'b1), .flags(4'b1010));

    collect_pkt(pkt);
    if (pkt.size() >= 1) begin
      w = pkt[0];
      check("T7 ctx_id==2",     w[13:12] == 2'd2);
      check("T7 phase0==1",     w[11]    == 1'b1);
      check("T7 hit_count==0",  w[10:7]  == 4'd0);
      check("T7 flags==1010",   w[6:3]   == 4'b1010);
      check("T7 out_mode==TS",  w[2:1]   == 2'(OUT_MODE_RAW_TIMESTAMP));
      check("T7 bit0==0",       w[0]     == 1'b0);
    end

    // ────────────────────────────────────────────────────────────────
    // TEST 8: EOC marker format
    // ────────────────────────────────────────────────────────────────
    $display("\n--- Test 8: EOC marker ---");
    // Already collected in T7 — check its EOC
    if (pkt.size() >= 2) begin
      w = pkt[1];
      check("T8 EOC [15:14]==11", w[15:14] == 2'b11);
      check("T8 EOC count==0",    w[13:0]  == 14'd0);
    end

    // ────────────────────────────────────────────────────────────────
    // Summary
    // ────────────────────────────────────────────────────────────────
    $display("\n================================");
    $display("  Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
    $display("================================");
    if (fail_count > 0) begin
      $display("TEST FAILED");
      $fatal(1, "Some checks failed");
    end else begin
      $display("TEST PASSED");
    end
    $finish;
  end

  // ── Watchdog ──────────────────────────────────────────────────────
  initial begin
    #200_000;
    $display("[FAIL] Global watchdog timeout");
    $fatal(1, "Watchdog");
  end

endmodule

`default_nettype wire
