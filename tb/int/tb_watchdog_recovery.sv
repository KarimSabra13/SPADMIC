// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// tb_watchdog_recovery.sv — Integration test: watchdog timeout and recovery
//
// Tests the dual-level watchdog mechanism:
//   Test 1: Per-context watchdog timeout (START only, no STOP)
//   Test 2: Clean recovery after per-context watchdog trip
//   Test 3: Global watchdog timeout and recovery after global trip
//
// Actual 16-bit header layout (from narrow TX concatenation):
//   [15:14]=2'b10, [13:12]=ctx_id, [11]=phase0,
//   [10:7]=hit_count, [6:3]=flags, [2:1]=out_mode, [0]=0
// Flags packed struct (MSB→LSB): overflow, firsthit, maxhits, watchdog

`timescale 1ns / 1ps
`default_nettype none

module tb_watchdog_recovery;
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

  // ── CSR helpers ─────────────────────────────────────────────────
  task automatic csr_wr(
    input logic [CSR_ADDR_W-1:0] addr,
    input logic [CSR_DATA_W-1:0] data
  );
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata, addr, data);
  endtask

  task automatic csr_rd(
    input  logic [CSR_ADDR_W-1:0] addr,
    output logic [CSR_DATA_W-1:0] data
  );
    tb_csr_read(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                csr_rvalid, csr_rdata, addr, data);
  endtask

  // ── Header field extraction (actual narrow TX format) ───────────
  // hit_count at [10:7], flags at [6:3]
  function automatic logic [3:0] hdr_hits(input logic [NARROW_W-1:0] w);
    return w[10:7];
  endfunction

  function automatic tdc_conv_flags_t hdr_flags(input logic [NARROW_W-1:0] w);
    return w[6:3];
  endfunction

  // ── Packet storage ──────────────────────────────────────────────
  logic [NARROW_W-1:0] pkt_words [$];
  int pkt_word_count;

  // ── Global simulation timeout ───────────────────────────────────
  initial begin
    #500_000ns;
    $error("[TB] GLOBAL TIMEOUT at 500us");
    $finish;
  end

  // ── Main test sequence ──────────────────────────────────────────
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

    // ================================================================
    // TEST 1: Per-context watchdog timeout
    // ================================================================
    $display("[TB] ──────────────────────────────────────────────────");
    $display("[TB] TEST 1: Per-context watchdog timeout");
    $display("[TB] ──────────────────────────────────────────────────");

    // Configure: MULTI_HIT, SPAD input, RAW_FEATURES
    // max_hits=0 disables the max-hits close condition, ensuring only
    // the watchdog can force closure.
    csr_wr(CSR_MODE,       32'h0000_0000);
    csr_wr(CSR_MAX_HITS,   32'h0000_0000);       // disabled
    csr_wr(CSR_WDT_CTX,    32'h0000_0064);       // 100 sys clk cycles = 625ns
    csr_wr(CSR_WDT_GLOBAL, 32'h0000_2710);       // 10000 cycles (large, won't fire)
    #50ns;

    // Arm
    $display("[TB] Arming conversion...");
    csr_wr(CSR_CTRL, 32'h0000_0001);
    #50ns;

    // Inject START only — no STOP triggers per-context watchdog
    $display("[TB] Injecting START only (no STOP)...");
    start_spad = 1'b1;
    #1ns;
    start_spad = 1'b0;

    // Collect watchdog-forced packet
    $display("[TB] Waiting for per-context watchdog to trip...");
    fork
      begin
        collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data,
                       pkt_words, pkt_word_count);
      end
      begin
        #10_000ns;
        $error("[TB] TIMEOUT waiting for watchdog packet (Test 1)");
        $finish;
      end
    join_any
    disable fork;

    // Verify watchdog packet
    begin
      logic [NARROW_W-1:0] hdr, eoc_w;
      tdc_conv_flags_t flags;
      int unsigned hc, expected_total;

      if (pkt_word_count < 2) begin
        $error("[TB] FAIL Test 1: packet too short (%0d words)", pkt_word_count);
        $finish;
      end

      hdr   = pkt_words[0];
      eoc_w = pkt_words[pkt_word_count-1];

      assert (is_header(hdr)) else begin
        $error("[TB] FAIL Test 1: first word 0x%04h is not a header", hdr);
        $finish;
      end

      assert (is_eoc(eoc_w)) else begin
        $error("[TB] FAIL Test 1: last word 0x%04h is not EOC", eoc_w);
        $finish;
      end

      flags = hdr_flags(hdr);
      hc    = hdr_hits(hdr);

      $display("[TB] Test 1 header: 0x%04h  hits=%0d  flags=%04b (wdt=%b)",
               hdr, hc, flags, flags.closed_by_watchdog);

      // Watchdog flag must be set
      assert (flags.closed_by_watchdog) else begin
        $error("[TB] FAIL Test 1: watchdog flag not set! flags=%04b", flags);
        $finish;
      end

      // Word count: 1 header + hits*3 + 1 EOC
      expected_total = 1 + hc * 3 + 1;
      assert (pkt_word_count == int'(expected_total)) else begin
        $error("[TB] FAIL Test 1: word count %0d != expected %0d",
               pkt_word_count, expected_total);
        $finish;
      end

      $display("[TB] TEST 1 PASSED: per-context watchdog tripped correctly");
    end

    #200ns;

    // ================================================================
    // TEST 2: Recovery after per-context watchdog
    // ================================================================
    $display("[TB] ──────────────────────────────────────────────────");
    $display("[TB] TEST 2: Recovery after per-context watchdog");
    $display("[TB] ──────────────────────────────────────────────────");

    // Re-arm (watchdog config unchanged — large enough not to trip
    // for a normal 10ns conversion)
    $display("[TB] Re-arming after watchdog...");
    csr_wr(CSR_CTRL, 32'h0000_0001);
    #50ns;

    // Normal conversion: START + STOP with 10ns delay
    $display("[TB] Injecting START + STOP (10ns delay)...");
    start_spad = 1'b1;
    #1ns;
    start_spad = 1'b0;
    #10ns;
    stop_spad = 1'b1;
    #1ns;
    stop_spad = 1'b0;

    // Collect packet
    $display("[TB] Waiting for recovery packet...");
    fork
      begin
        collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data,
                       pkt_words, pkt_word_count);
      end
      begin
        #10_000ns;
        $error("[TB] TIMEOUT waiting for recovery packet (Test 2)");
        $finish;
      end
    join_any
    disable fork;

    // Verify normal packet — no watchdog flag
    begin
      logic [NARROW_W-1:0] hdr, eoc_w;
      tdc_conv_flags_t flags;
      int unsigned hc, expected_total;

      if (pkt_word_count < 2) begin
        $error("[TB] FAIL Test 2: packet too short (%0d words)", pkt_word_count);
        $finish;
      end

      hdr   = pkt_words[0];
      eoc_w = pkt_words[pkt_word_count-1];

      assert (is_header(hdr)) else begin
        $error("[TB] FAIL Test 2: first word 0x%04h is not a header", hdr);
        $finish;
      end

      assert (is_eoc(eoc_w)) else begin
        $error("[TB] FAIL Test 2: last word 0x%04h is not EOC", eoc_w);
        $finish;
      end

      flags = hdr_flags(hdr);
      hc    = hdr_hits(hdr);

      $display("[TB] Test 2 header: 0x%04h  hits=%0d  flags=%04b", hdr, hc, flags);

      // Watchdog flag must NOT be set
      assert (!flags.closed_by_watchdog) else begin
        $error("[TB] FAIL Test 2: watchdog flag set on recovery! flags=%04b", flags);
        $finish;
      end

      // Should have at least one hit from normal conversion
      assert (hc > 0) else begin
        $error("[TB] FAIL Test 2: no hits in recovery conversion");
        $finish;
      end

      // Word count
      expected_total = 1 + hc * 3 + 1;
      assert (pkt_word_count == int'(expected_total)) else begin
        $error("[TB] FAIL Test 2: word count %0d != expected %0d",
               pkt_word_count, expected_total);
        $finish;
      end

      $display("[TB] TEST 2 PASSED: recovery after per-context watchdog OK");
    end

    #200ns;

    // ================================================================
    // TEST 3: Global watchdog timeout + recovery
    // ================================================================
    $display("[TB] ──────────────────────────────────────────────────");
    $display("[TB] TEST 3: Global watchdog timeout + recovery");
    $display("[TB] ──────────────────────────────────────────────────");

    // Reconfigure: per-context timeout large, global timeout small
    // max_hits stays 0 (disabled)
    csr_wr(CSR_WDT_CTX,    32'h0000_C350);       // 50000 cycles (won't fire)
    csr_wr(CSR_WDT_GLOBAL, 32'h0000_00C8);       // 200 cycles = 1250ns
    #50ns;

    // Arm
    $display("[TB] Arming for global watchdog test...");
    csr_wr(CSR_CTRL, 32'h0000_0001);
    #50ns;

    // Inject START only — global watchdog fires before per-context
    $display("[TB] Injecting START only (no STOP)...");
    start_spad = 1'b1;
    #1ns;
    start_spad = 1'b0;

    // Collect watchdog-forced packet
    $display("[TB] Waiting for global watchdog to trip...");
    fork
      begin
        collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data,
                       pkt_words, pkt_word_count);
      end
      begin
        #20_000ns;
        $error("[TB] TIMEOUT waiting for global watchdog packet (Test 3)");
        $finish;
      end
    join_any
    disable fork;

    // Verify global watchdog packet
    begin
      logic [NARROW_W-1:0] hdr, eoc_w;
      tdc_conv_flags_t flags;
      int unsigned hc, expected_total;

      if (pkt_word_count < 2) begin
        $error("[TB] FAIL Test 3: packet too short (%0d words)", pkt_word_count);
        $finish;
      end

      hdr   = pkt_words[0];
      eoc_w = pkt_words[pkt_word_count-1];

      assert (is_header(hdr)) else begin
        $error("[TB] FAIL Test 3: first word 0x%04h is not a header", hdr);
        $finish;
      end

      assert (is_eoc(eoc_w)) else begin
        $error("[TB] FAIL Test 3: last word 0x%04h is not EOC", eoc_w);
        $finish;
      end

      flags = hdr_flags(hdr);
      hc    = hdr_hits(hdr);

      $display("[TB] Test 3 header: 0x%04h  hits=%0d  flags=%04b (wdt=%b)",
               hdr, hc, flags, flags.closed_by_watchdog);

      // Watchdog flag must be set
      assert (flags.closed_by_watchdog) else begin
        $error("[TB] FAIL Test 3: watchdog flag not set! flags=%04b", flags);
        $finish;
      end

      // Word count
      expected_total = 1 + hc * 3 + 1;
      assert (pkt_word_count == int'(expected_total)) else begin
        $error("[TB] FAIL Test 3: word count %0d != expected %0d",
               pkt_word_count, expected_total);
        $finish;
      end

      $display("[TB] Test 3a PASSED: global watchdog tripped correctly");
    end

    #200ns;

    // ── Test 3b: Recovery after global watchdog ───────────────────
    $display("[TB] Testing recovery after global watchdog...");

    // Restore large global timeout for clean recovery
    csr_wr(CSR_WDT_GLOBAL, 32'h0000_2710);       // 10000 cycles
    #50ns;

    // Arm
    csr_wr(CSR_CTRL, 32'h0000_0001);
    #50ns;

    // Normal conversion
    $display("[TB] Injecting START + STOP (10ns delay)...");
    start_spad = 1'b1;
    #1ns;
    start_spad = 1'b0;
    #10ns;
    stop_spad = 1'b1;
    #1ns;
    stop_spad = 1'b0;

    // Collect packet
    fork
      begin
        collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data,
                       pkt_words, pkt_word_count);
      end
      begin
        #10_000ns;
        $error("[TB] TIMEOUT waiting for recovery packet (Test 3b)");
        $finish;
      end
    join_any
    disable fork;

    // Verify normal packet
    begin
      logic [NARROW_W-1:0] hdr, eoc_w;
      tdc_conv_flags_t flags;
      int unsigned hc, expected_total;

      if (pkt_word_count < 2) begin
        $error("[TB] FAIL Test 3b: packet too short (%0d words)", pkt_word_count);
        $finish;
      end

      hdr   = pkt_words[0];
      eoc_w = pkt_words[pkt_word_count-1];

      assert (is_header(hdr)) else begin
        $error("[TB] FAIL Test 3b: first word 0x%04h is not a header", hdr);
        $finish;
      end

      assert (is_eoc(eoc_w)) else begin
        $error("[TB] FAIL Test 3b: last word 0x%04h is not EOC", eoc_w);
        $finish;
      end

      flags = hdr_flags(hdr);
      hc    = hdr_hits(hdr);

      $display("[TB] Test 3b header: 0x%04h  hits=%0d  flags=%04b", hdr, hc, flags);

      assert (!flags.closed_by_watchdog) else begin
        $error("[TB] FAIL Test 3b: watchdog flag set on recovery! flags=%04b", flags);
        $finish;
      end

      assert (hc > 0) else begin
        $error("[TB] FAIL Test 3b: no hits in recovery conversion");
        $finish;
      end

      expected_total = 1 + hc * 3 + 1;
      assert (pkt_word_count == int'(expected_total)) else begin
        $error("[TB] FAIL Test 3b: word count %0d != expected %0d",
               pkt_word_count, expected_total);
        $finish;
      end

      $display("[TB] Test 3b PASSED: recovery after global watchdog OK");
    end

    // ── Read WDT status to confirm trip counters incremented ──────
    begin
      logic [CSR_DATA_W-1:0] wdt_status;
      csr_rd(CSR_WDT_STATUS, wdt_status);
      $display("[TB] WDT_STATUS: ctx_trip_cnt=%0d, global_trip_cnt=%0d",
               wdt_status[7:0], wdt_status[15:8]);
      assert (wdt_status[7:0] > 0) else
        $error("[TB] ctx_trip_cnt is 0 — expected > 0 after Test 1");
      assert (wdt_status[15:8] > 0) else
        $error("[TB] global_trip_cnt is 0 — expected > 0 after Test 3");
    end

    $display("[TB] ──────────────────────────────────────────────────");
    $display("[TB] ===== TEST PASSED =====");
    #100;
    $finish;
  end

endmodule

`default_nettype wire
