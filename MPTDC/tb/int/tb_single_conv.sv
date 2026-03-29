// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_single_conv.sv
// Purpose : Basic end-to-end START/STOP/readout integration test.
// Author  : Karim Sabra
// Notes   : Pairs the DUT with the passive raw monitor and validates one
//           RAW_FEATURES packet from arm through EOC.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_single_conv;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  // ── Clock and reset ─────────────────────────────────────────────
  logic clk_sys;
  logic async_rst_n;

  initial clk_sys = 1'b0;
  always #(CLK_SYS_HALF) clk_sys = ~clk_sys;

  // ── DUT signals ─────────────────────────────────────────────────
  logic start_spad, stop_spad;
  logic cal_start, cal_stop;

  logic                    csr_valid, csr_write;
  logic [CSR_ADDR_W-1:0]  csr_addr;
  logic [CSR_DATA_W-1:0]  csr_wdata;
  logic                    csr_ready, csr_rvalid;
  logic [CSR_DATA_W-1:0]  csr_rdata;

  logic                    narrow_ready;
  logic                    narrow_valid;
  logic [NARROW_W-1:0]    narrow_data;

  // ── DUT ─────────────────────────────────────────────────────────
  mptdc_top_asic u_dut (
    .clk_sys            (clk_sys),
    .async_rst_n        (async_rst_n),
    .start_spad_async_i (start_spad),
    .stop_spad_async_i  (stop_spad),
    .cal_start_async_i  (cal_start),
    .cal_stop_async_i   (cal_stop),
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

  // ── Monitor ─────────────────────────────────────────────────────
  mptdc_raw_monitor u_mon (
    .clk_sys        (clk_sys),
    .rst_n          (async_rst_n),
    .narrow_valid_i (narrow_valid),
    .narrow_ready_i (narrow_ready),
    .narrow_data_i  (narrow_data)
  );

  // ── Test sequence ───────────────────────────────────────────────
  logic [NARROW_W-1:0] pkt_words [$];
  int pkt_word_count;

  initial begin
    // Defaults
    start_spad   = 1'b0;
    stop_spad    = 1'b0;
    cal_start    = 1'b0;
    cal_stop     = 1'b0;
    csr_valid    = 1'b0;
    csr_write    = 1'b0;
    csr_addr     = '0;
    csr_wdata    = '0;
    narrow_ready = 1'b1;
    async_rst_n  = 1'b0;

    // Reset
    #100ns;
    async_rst_n = 1'b1;
    #100ns;

    // ── Step 1: Configure ─────────────────────────────────────────
    $display("[TB] Configuring: MULTI_HIT, max_hits=15, OUT_MODE_RAW_FEATURES");

    // CSR_MODE: mode=MULTI_HIT(0), input_sel=SPAD(0), out_mode=RAW_FEATURES(0)
    csr_write_task(CSR_MODE, 32'h0000_0000);

    // CSR_MAX_HITS: max_hits = 15
    csr_write_task(CSR_MAX_HITS, 32'h0000_000F);

    // CSR_WDT_CTX: watchdog disabled (0)
    csr_write_task(CSR_WDT_CTX, 32'h0000_0000);

    // CSR_WDT_GLOBAL: watchdog disabled (0)
    csr_write_task(CSR_WDT_GLOBAL, 32'h0000_0000);

    #50ns;

    // ── Step 2: Arm ───────────────────────────────────────────────
    $display("[TB] Arming conversion...");
    csr_write_task(CSR_CTRL, 32'h0000_0001);  // bit 0 = conv_arm
    #50ns;

    // ── Step 3: Inject START → delay → STOP ───────────────────────
    $display("[TB] Injecting START...");
    start_spad = 1'b1;
    #1ns;
    start_spad = 1'b0;

    // Wait ~10 ns (should produce a few Vernier hits)
    #10ns;

    $display("[TB] Injecting STOP...");
    stop_spad = 1'b1;
    #1ns;
    stop_spad = 1'b0;

    // ── Step 4: Wait and collect packet ───────────────────────────
    $display("[TB] Waiting for output packet...");
    fork
      begin
        collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data,
                       pkt_words, pkt_word_count);
      end
      begin
        #(TB_TIMEOUT_CYC * CLK_SYS_PERIOD);
        $error("[TB] TIMEOUT waiting for packet!");
        $finish;
      end
    join_any
    disable fork;

    // ── Step 5: Verify ────────────────────────────────────────────
    $display("[TB] Collected %0d words", pkt_word_count);

    if (pkt_word_count < 2) begin
      $error("[TB] FAIL: packet too short (need at least header + EOC)");
    end else begin
      logic [NARROW_W-1:0] hdr;
      logic [NARROW_W-1:0] eoc_w;
      int unsigned hc;
      int unsigned expected_total;

      hdr   = pkt_words[0];
      eoc_w = pkt_words[pkt_word_count-1];

      assert (is_header(hdr))
        else $error("[TB] First word is not a header: 0x%04h", hdr);
      assert (is_eoc(eoc_w))
        else $error("[TB] Last word is not an EOC: 0x%04h", eoc_w);

      hc = header_hit_count(hdr);
      $display("[TB] Header: ctx=%0d, hits=%0d, flags=%04b, mode=%0d",
               header_ctx_id(hdr), hc, header_flags(hdr),
               header_out_mode(hdr));

      // RAW_FEATURES: 3 words per hit + 1 header + 1 EOC
      expected_total = 1 + hc * 3 + 1;
      assert (pkt_word_count == expected_total)
        else $error("[TB] Word count mismatch: got %0d, expected %0d",
                    pkt_word_count, expected_total);

      $display("[TB] EOC: conv_id=%0d", eoc_conv_id(eoc_w));
    end

    $display("[TB] ===== TEST PASSED =====");
    #100ns;
    $finish;
  end

  // ── CSR write helper (wraps the task from tb_pkg) ───────────────
  task automatic csr_write_task(
    input logic [CSR_ADDR_W-1:0] addr,
    input logic [CSR_DATA_W-1:0] data
  );
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata, addr, data);
  endtask

  // ── Dump waveforms (portable across simulators) ─────────────────
`ifdef VERILATOR
  initial begin
    $dumpfile("tb_single_conv.vcd");
    $dumpvars(0, tb_single_conv);
  end
`endif

endmodule

`default_nettype wire
