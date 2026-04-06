// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_backpressure.sv
// Purpose : Integration test for narrow ready/valid backpressure handling.
// Author  : Karim Sabra
// Notes   : Exercises intermittent stalls, full stalls, and packet-integrity
//           comparisons without changing DUT sequencing.
// =============================================================================
`timescale 1ps/1ps

module tb_backpressure;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  // ── Parameters ──────────────────────────────────────────────────
  localparam realtime CLK_SYS_PERIOD = 6.25ns;
  localparam realtime CLK_SYS_HALF   = CLK_SYS_PERIOD / 2;
  localparam int      GLOBAL_TIMEOUT = 500_000;  // ns

  // ── DUT signals ─────────────────────────────────────────────────
  logic                    clk_sys;
  logic                    async_rst_n;
  logic                    start_spad;
  logic                    stop_spad;

  logic                    csr_valid;
  logic                    csr_write;
  logic [CSR_ADDR_W-1:0]  csr_addr;
  logic [CSR_DATA_W-1:0]  csr_wdata;
  logic                    csr_ready;
  logic                    csr_rvalid;
  logic [CSR_DATA_W-1:0]  csr_rdata;

  logic                    narrow_ready;
  logic                    narrow_valid;
  logic [NARROW_W-1:0]    narrow_data;

  // ── Backpressure control ────────────────────────────────────────
  // 0 = always ready, 1 = random 50%, 2 = always stalled
  logic [1:0] bp_mode;

  initial begin
    bp_mode      = 2'd0;
    narrow_ready = 1'b1;
  end

  always @(posedge clk_sys) begin
    case (bp_mode)
      2'd0: narrow_ready <= 1'b1;
      2'd1: narrow_ready <= $urandom_range(0,1);
      2'd2: narrow_ready <= 1'b0;
      default: narrow_ready <= 1'b1;
    endcase
  end

  // ── Clock generation ────────────────────────────────────────────
  initial clk_sys = 1'b0;
  always #(CLK_SYS_HALF) clk_sys = ~clk_sys;

  // ── DUT instantiation ──────────────────────────────────────────
  mptdc_top_asic u_dut (
    .clk_sys            (clk_sys),
    .async_rst_n        (async_rst_n),
    .start_spad_async_i (start_spad),
    .stop_spad_async_i  (stop_spad),
    .cal_start_async_i  (1'b0),
    .cal_stop_async_i   (1'b0),
    .csr_valid_i        (csr_valid),
    .csr_write_i        (csr_write),
    .csr_addr_i         (csr_addr),
    .csr_wdata_i        (csr_wdata),
    .csr_ready_o        (csr_ready),
    .csr_rvalid_o       (csr_rvalid),
    .csr_rdata_o        (csr_rdata),
    .narrow_ready_i     (narrow_ready),
    .narrow_valid_o     (narrow_valid),
    .narrow_data_o      (narrow_data)
  );

  // ── Global timeout ─────────────────────────────────────────────
  initial begin
    #(GLOBAL_TIMEOUT * 1ns);
    $error("[TB] Global timeout after %0d ns", GLOBAL_TIMEOUT);
    $finish;
  end

  // ── Passive packet collector (does NOT drive narrow_ready) ─────
  task automatic collect_packet_passive(
    ref logic                      clk,
    ref logic                      valid,
    ref logic                      ready,
    ref logic [NARROW_W-1:0]      data,
    output logic [NARROW_W-1:0]   words [$],
    output int                     word_count,
    input  int                     timeout_cycles = 80_000
  );
    logic [NARROW_W-1:0] w;
    int cyc;
    words = {};
    word_count = 0;
    cyc = 0;

    // Wait for header
    while (1) begin
      @(posedge clk);
      cyc++;
      if (cyc > timeout_cycles) begin
        $error("[TB] collect_packet_passive: timed out waiting for header");
        return;
      end
      if (valid && ready) begin
        w = data;
        if (is_header(w)) begin
          words.push_back(w);
          word_count++;
          break;
        end
      end
    end

    // Collect until EOC
    while (1) begin
      @(posedge clk);
      cyc++;
      if (cyc > timeout_cycles) begin
        $error("[TB] collect_packet_passive: timed out waiting for EOC");
        return;
      end
      if (valid && ready) begin
        w = data;
        words.push_back(w);
        word_count++;
        if (is_eoc(w)) break;
      end
    end
  endtask

  // ── Helper: fire one START/STOP conversion ─────────────────────
  task automatic fire_conversion(
    input realtime start_stop_delay
  );
    start_spad = 1'b1;
    #1ns;
    start_spad = 1'b0;
    #(start_stop_delay);
    stop_spad = 1'b1;
    #1ns;
    stop_spad = 1'b0;
  endtask

  // ── Helper: configure DUT and arm ──────────────────────────────
  task automatic configure_and_arm();
    // OUT_MODE_RAW_FEATURES = 0, MODE_MULTI_HIT = 0, INPUT_SPAD = 0
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                 CSR_MODE, 32'h0000_0000);
    // Max hits = 15
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                 CSR_MAX_HITS, 32'h0000_000F);
    // Disable watchdogs
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                 CSR_WDT_CTX, 32'h0000_0000);
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                 CSR_WDT_GLOBAL, 32'h0000_0000);
    #50ns;
    // Arm
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                 CSR_CTRL, 32'h0000_0001);
    #50ns;
  endtask

  // ── Helper: arm only (config already done) ─────────────────────
  task automatic arm_only();
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                 CSR_CTRL, 32'h0000_0001);
    #50ns;
  endtask

  // ── Helper: FIFO clear + settle ────────────────────────────────
  task automatic fifo_clear_and_settle();
    // Soft reset (resets FSM + narrow TX) and FIFO clear
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                 CSR_CTRL, 32'h0000_0006);   // bit2=soft_rst, bit1=fifo_clr
    #500ns;
    // Second FIFO clear to catch any phantom data from soft_rst glitch
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                 CSR_CTRL, 32'h0000_0002);   // bit1=fifo_clr
    #100ns;
  endtask

  // ── Helper: validate a single packet ───────────────────────────
  task automatic validate_packet(
    input logic [NARROW_W-1:0] words [$],
    input int                  word_count,
    input string               label
  );
    int hc;
    int expected_wc;

    if (word_count < 2) begin
      $error("[TB] %s: packet too short (%0d words)", label, word_count);
      $finish;
    end

    if (!is_header(words[0])) begin
      $error("[TB] %s: first word 0x%04h is not a header", label, words[0]);
      $finish;
    end

    if (!is_eoc(words[word_count-1])) begin
      $error("[TB] %s: last word 0x%04h is not EOC", label,
             words[word_count-1]);
      $finish;
    end

    hc = header_hit_count(words[0]);
    // v2.3: header + sub-header + 3*hits + EOC
    expected_wc = 1 + 1 + hc * 3 + 1;
    if (word_count != expected_wc) begin
      $error("[TB] %s: word count %0d != expected %0d (hits=%0d)",
             label, word_count, expected_wc, hc);
      $finish;
    end

    $display("[TB] %s: PASS — %0d words, %0d hits, conv_id=%0d",
             label, word_count, hc, eoc_conv_id(words[word_count-1]));
  endtask

  // ══════════════════════════════════════════════════════════════
  // Main test sequence
  // ══════════════════════════════════════════════════════════════
  initial begin
    logic [NARROW_W-1:0] pkt_a [$];    int wc_a;
    logic [NARROW_W-1:0] pkt_b0 [$];   int wc_b0;
    logic [NARROW_W-1:0] pkt_b1 [$];   int wc_b1;
    logic [NARROW_W-1:0] pkt_c_ref [$]; int wc_c_ref;
    logic [NARROW_W-1:0] pkt_c_bp  [$]; int wc_c_bp;
    int conv_id_b0, conv_id_b1;

    // ── Init ──────────────────────────────────────────────────
    async_rst_n  = 1'b0;
    start_spad   = 1'b0;
    stop_spad    = 1'b0;
    csr_valid    = 1'b0;
    csr_write    = 1'b0;
    csr_addr     = '0;
    csr_wdata    = '0;
    bp_mode      = 2'd0;           // always ready during reset

    // ── Reset ─────────────────────────────────────────────────
    #100ns;
    async_rst_n = 1'b1;
    #1000ns;               // let CDC glitches from oscillator model settle

    // Flush any phantom data from post-reset glitches
    fifo_clear_and_settle();

    // ══════════════════════════════════════════════════════════
    // Scenario A: Intermittent stall (random 50 % backpressure)
    // ══════════════════════════════════════════════════════════
    $display("[TB] ──── Scenario A: intermittent stall ────");

    configure_and_arm();

    bp_mode = 2'd1;                // random backpressure ON
    fire_conversion(10ns);         // START then STOP after 10 ns

    collect_packet_passive(clk_sys, narrow_valid, narrow_ready,
                           narrow_data, pkt_a, wc_a);
    bp_mode = 2'd0;                // back to always-ready
    validate_packet(pkt_a, wc_a, "ScenA");

    // Clean slate for next scenario
    #200ns;
    fifo_clear_and_settle();

    // ══════════════════════════════════════════════════════════
    // Scenario B: Full stall then release (2 back-to-back)
    // ══════════════════════════════════════════════════════════
    $display("[TB] ──── Scenario B: full stall then release ────");

    bp_mode = 2'd2;                // consumer completely frozen

    // Fire conversion 1
    configure_and_arm();
    fire_conversion(10ns);
    #5000ns;                       // wait for conversion to finish

    // Fire conversion 2 (arm only — config already done)
    arm_only();
    fire_conversion(10ns);
    #5000ns;

    // Now release consumer
    bp_mode = 2'd0;

    collect_packet_passive(clk_sys, narrow_valid, narrow_ready,
                           narrow_data, pkt_b0, wc_b0);
    validate_packet(pkt_b0, wc_b0, "ScenB pkt0");

    collect_packet_passive(clk_sys, narrow_valid, narrow_ready,
                           narrow_data, pkt_b1, wc_b1);
    validate_packet(pkt_b1, wc_b1, "ScenB pkt1");

    // Verify sequential conv_ids
    conv_id_b0 = eoc_conv_id(pkt_b0[wc_b0-1]);
    conv_id_b1 = eoc_conv_id(pkt_b1[wc_b1-1]);
    if (conv_id_b1 != conv_id_b0 + 1) begin
      $error("[TB] ScenB: conv_ids not sequential: %0d then %0d",
             conv_id_b0, conv_id_b1);
      $finish;
    end
    $display("[TB] ScenB: sequential conv_ids OK (%0d, %0d)",
             conv_id_b0, conv_id_b1);

    // Clean slate for next scenario
    #200ns;
    fifo_clear_and_settle();

    // ══════════════════════════════════════════════════════════
    // Scenario C: Data integrity (reference vs backpressure)
    // ══════════════════════════════════════════════════════════
    $display("[TB] ──── Scenario C: data integrity ────");

    // C.1 — reference packet (no backpressure)
    bp_mode = 2'd0;
    configure_and_arm();
    fire_conversion(10ns);
    collect_packet_passive(clk_sys, narrow_valid, narrow_ready,
                           narrow_data, pkt_c_ref, wc_c_ref);
    validate_packet(pkt_c_ref, wc_c_ref, "ScenC ref");

    // Clean slate
    #200ns;
    fifo_clear_and_settle();

    // C.2 — same conversion under random backpressure
    bp_mode = 2'd1;
    configure_and_arm();
    fire_conversion(10ns);
    collect_packet_passive(clk_sys, narrow_valid, narrow_ready,
                           narrow_data, pkt_c_bp, wc_c_bp);
    bp_mode = 2'd0;
    validate_packet(pkt_c_bp, wc_c_bp, "ScenC bp");

    // Compare word counts
    if (wc_c_ref != wc_c_bp) begin
      $error("[TB] ScenC: word count mismatch ref=%0d bp=%0d",
             wc_c_ref, wc_c_bp);
      $finish;
    end

    // Compare header hit counts
    if (header_hit_count(pkt_c_ref[0]) != header_hit_count(pkt_c_bp[0])) begin
      $error("[TB] ScenC: hit count mismatch ref=%0d bp=%0d",
             header_hit_count(pkt_c_ref[0]),
             header_hit_count(pkt_c_bp[0]));
      $finish;
    end

    $display("[TB] ScenC: data integrity OK — both packets have %0d words, %0d hits",
             wc_c_ref, header_hit_count(pkt_c_ref[0]));

    // ══════════════════════════════════════════════════════════
    $display("[TB] ===== TEST PASSED =====");
    #100ns;
    $finish;
  end

endmodule
