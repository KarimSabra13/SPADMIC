// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_start_wdt.sv
// Purpose : Verifies START-only watchdog closure and clean recovery.
// Author  : Karim Sabra
// Notes   : Checks the watchdog flag on the forced packet, then confirms a normal
//           conversion succeeds immediately afterward.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_start_wdt;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  // ── Clock and reset ─────────────────────────────────────────────
  logic clk_sys;
  logic async_rst_n;
  initial clk_sys = 1'b0;
  always #(CLK_SYS_HALF) clk_sys = ~clk_sys;

  // ── DUT signals ─────────────────────────────────────────────────
  logic start_spad, stop_spad, cal_start, cal_stop;
  logic                    csr_valid, csr_write;
  logic [CSR_ADDR_W-1:0]  csr_addr;
  logic [CSR_DATA_W-1:0]  csr_wdata;
  logic                    csr_ready, csr_rvalid;
  logic [CSR_DATA_W-1:0]  csr_rdata;
  logic                    narrow_ready, narrow_valid;
  logic [NARROW_W-1:0]    narrow_data;

  mptdc_top_asic u_dut (
    .clk_sys(clk_sys), .async_rst_n(async_rst_n),
    .start_spad_async_i(start_spad), .stop_spad_async_i(stop_spad),
    .cal_start_async_i(cal_start), .cal_stop_async_i(cal_stop),
    .csr_valid_i(csr_valid), .csr_write_i(csr_write),
    .csr_addr_i(csr_addr), .csr_wdata_i(csr_wdata),
    .csr_ready_o(csr_ready), .csr_rvalid_o(csr_rvalid),
    .csr_rdata_o(csr_rdata),
    .narrow_ready_i(narrow_ready), .narrow_valid_o(narrow_valid),
    .narrow_data_o(narrow_data)
  );

  // ── CSR helpers ─────────────────────────────────────────────────
  task automatic csr_wr(input logic [CSR_ADDR_W-1:0] a, input logic [CSR_DATA_W-1:0] d);
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata, a, d);
  endtask

  // ── Packet collection ───────────────────────────────────────────
  logic [NARROW_W-1:0] pkt [$];
  int wc;

  // ── Main test ───────────────────────────────────────────────────
  initial begin
    start_spad = 0; stop_spad = 0; cal_start = 0; cal_stop = 0;
    csr_valid = 0; csr_write = 0; csr_addr = 0; csr_wdata = 0;
    narrow_ready = 1'b1;
    async_rst_n = 1'b0;
    #100_000; async_rst_n = 1'b1; #100_000;

    $display("[TB] === tb_start_wdt: START-only watchdog test ===");

    // Configure: max_hits=0 (disabled), per-ctx wdt=100 fast cycles
    csr_wr(CSR_MODE,       32'h0000_0000);
    csr_wr(CSR_MAX_HITS,   32'h0000_0000);  // disabled
    csr_wr(CSR_WDT_CTX,    32'h0000_0064);  // 100 fast cycles
    csr_wr(CSR_WDT_GLOBAL, 32'h0000_2710);  // 10000 (backup)
    #50_000;

    // ── Test 1: START only → slow watchdog → packet with wdt flag ──
    $display("[TB] Test 1: Inject START without STOP...");
    csr_wr(CSR_CTRL, 32'h0000_0001);
    #50_000;

    start_spad = 1'b1; #1000; start_spad = 1'b0;

    // Wait for packet (slow wdt ~255ns + per-ctx wdt + drain)
    fork
      collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data, pkt, wc);
      begin #5_000_000; $error("[TB] TIMEOUT Test 1"); $finish; end
    join_any
    disable fork;

    // Verify watchdog flag
    begin
      tdc_conv_flags_t flags;
      assert (wc >= 2) else begin $error("[TB] packet too short"); $finish; end
      assert (is_header(pkt[0])) else begin $error("[TB] no header"); $finish; end
      assert (is_eoc(pkt[wc-1])) else begin $error("[TB] no EOC"); $finish; end

      flags = header_flags(pkt[0]);
      $display("[TB] Test 1: flags=%04b wdt=%b hits=%0d wc=%0d",
               flags, flags.closed_by_watchdog, header_hit_count(pkt[0]), wc);

      assert (flags.closed_by_watchdog) else begin
        $error("[TB] FAIL: watchdog flag not set!"); $finish;
      end
      $display("[TB] Test 1 PASSED: START-only → watchdog close");
    end

    #200_000;

    // ── Test 2: Recovery — normal conversion after watchdog ─────────
    $display("[TB] Test 2: Recovery after watchdog...");
    csr_wr(CSR_MAX_HITS, 32'h0000_000F);
    csr_wr(CSR_WDT_CTX,  32'h0000_FFFF);
    #50_000;

    csr_wr(CSR_CTRL, 32'h0000_0001);
    #50_000;

    start_spad = 1'b1; #1000; start_spad = 1'b0;
    #10_000;
    stop_spad = 1'b1; #1000; stop_spad = 1'b0;

    fork
      collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data, pkt, wc);
      begin #5_000_000; $error("[TB] TIMEOUT Test 2"); $finish; end
    join_any
    disable fork;

    begin
      tdc_conv_flags_t flags;
      assert (wc >= 2) else begin $error("[TB] packet too short"); $finish; end
      flags = header_flags(pkt[0]);
      $display("[TB] Test 2: flags=%04b hits=%0d", flags, header_hit_count(pkt[0]));
      assert (!flags.closed_by_watchdog) else begin
        $error("[TB] FAIL: watchdog flag set on normal conv!"); $finish;
      end
      assert (header_hit_count(pkt[0]) > 0) else begin
        $error("[TB] FAIL: no hits on recovery conv!"); $finish;
      end
      $display("[TB] Test 2 PASSED: clean recovery after watchdog");
    end

    $display("[TB] ===== TEST PASSED =====");
    $finish;
  end

  initial begin #50_000_000; $fatal(1, "TB global timeout"); end
endmodule

`default_nettype wire
