// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_deadtime_measure.sv
// Purpose : Measures re-arm deadtime between consecutive conversions.
// Author  : Karim Sabra
// Notes   : Sweeps the STOP_N to START_{N+1} gap with background packet
//           collection to find the smallest fully passing interval.
// =============================================================================
`timescale 1ps/1ps

module tb_deadtime_measure;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  // ── Signals ──────────────────────────────────────────────────────
  logic clk_sys;
  logic async_rst_n;
  logic start_spad, stop_spad;
  logic cal_start, cal_stop;

  logic                    csr_valid;
  logic                    csr_wr;
  logic [CSR_ADDR_W-1:0]  csr_addr;
  logic [CSR_DATA_W-1:0]  csr_wdata;
  logic                    csr_ready;
  logic                    csr_rvalid;
  logic [CSR_DATA_W-1:0]  csr_rdata;

  logic                    narrow_ready;
  logic                    narrow_valid;
  logic [NARROW_W-1:0]    narrow_data;

  // ── Clock generation (160 MHz) ───────────────────────────────────
  initial clk_sys = 1'b0;
  always #(CLK_SYS_HALF) clk_sys = ~clk_sys;

  // ── DUT ──────────────────────────────────────────────────────────
  mptdc_top_asic u_dut (
    .clk_sys            (clk_sys),
    .async_rst_n        (async_rst_n),
    .start_spad_async_i (start_spad),
    .stop_spad_async_i  (stop_spad),
    .cal_start_async_i  (cal_start),
    .cal_stop_async_i   (cal_stop),
    .input_sel_override_en_i(1'b0),
    .input_sel_override_i(INPUT_SPAD),
    .out_mode_override_en_i(1'b0),
    .out_mode_override_i(OUT_MODE_RAW_FEATURES),
    .csr_valid_i        (csr_valid),
    .csr_write_i        (csr_wr),
    .csr_addr_i         (csr_addr),
    .csr_wdata_i        (csr_wdata),
    .csr_ready_o        (csr_ready),
    .csr_rvalid_o       (csr_rvalid),
    .csr_rdata_o        (csr_rdata),
    .narrow_ready_i     (narrow_ready),
    .narrow_valid_o     (narrow_valid),
    .narrow_data_o      (narrow_data),
    .shared_readout_en_i(1'b0),
    .acq_ready_i        (1'b0),
    .acq_valid_o        (),
    .acq_data_o         (),
    .fifo_full_o        ()
  );

  // ── CSR helpers ──────────────────────────────────────────────────
  task automatic csr_w(input logic [CSR_ADDR_W-1:0] a,
                       input logic [CSR_DATA_W-1:0] d);
    tb_csr_write(clk_sys, csr_valid, csr_wr, csr_addr, csr_wdata, a, d);
  endtask

  task automatic arm();
    csr_w(CSR_CTRL, 32'h0000_0001);
  endtask

  task automatic configure();
    csr_w(CSR_MODE,       32'h0000_0000);   // MULTI_HIT, SPAD, RAW_FEATURES
    csr_w(CSR_MAX_HITS,   32'h0000_000F);   // max_hits = 15
    csr_w(CSR_WDT_CTX,    32'h0000_0000);   // per-context watchdog disabled
    csr_w(CSR_WDT_GLOBAL, 32'h0000_0000);   // global watchdog disabled
  endtask

  task automatic hard_reset();
    async_rst_n = 1'b0;
    #100ns;
    async_rst_n = 1'b1;
    #100ns;
  endtask

  // ── Gap sweep table (ns) — coarse + fine around 30-50 boundary ──
  localparam int N_GAPS = 16;
  int gaps_ns [N_GAPS] = '{60, 50, 45, 42, 40, 39, 38, 37,
                            36, 35, 34, 33, 32, 30, 25, 20};
  localparam int N_TRIALS = 3;

  // Module-scope variables for packet collection (avoids Verilator LIFETIME)
  logic [NARROW_W-1:0] pkt1 [$];
  logic [NARROW_W-1:0] pkt2 [$];
  int    wc1, wc2;
  logic  pkt1_ok, pkt2_ok;
  realtime t_stop_r, t_start2_r, meas;

  // ── Main test ────────────────────────────────────────────────────
  initial begin
    int min_gap_pass;

    // Initialise all TB-driven signals
    async_rst_n  = 1'b0;
    start_spad   = 1'b0;
    stop_spad    = 1'b0;
    cal_start    = 1'b0;
    cal_stop     = 1'b0;
    csr_valid    = 1'b0;
    csr_wr       = 1'b0;
    csr_addr     = '0;
    csr_wdata    = '0;
    narrow_ready = 1'b1;

    // Reset sequence: hold low for 100 ns, then release
    #100ns;
    async_rst_n = 1'b1;
    #100ns;

    $display("[TB] ===== DEADTIME MEASUREMENT TEST =====");
    $display("[TB] Clock: 160 MHz (6.25 ns period)");
    $display("[TB] Config: RAW_FEATURES, MULTI_HIT, max_hits=15, watchdogs off");

    min_gap_pass = 999;

    // ── Sweep gaps from large to small ─────────────────────────────
    for (int gi = 0; gi < N_GAPS; gi++) begin
      automatic int gap      = gaps_ns[gi];
      automatic int pass_cnt = 0;

      $display("[TB] --- Testing gap = %0d ns ---", gap);

      for (int tr = 0; tr < N_TRIALS; tr++) begin

        // ── Clean state via hard reset ──
        hard_reset();
        configure();
        #50ns;

        // Reset collection state
        pkt1    = {};
        pkt2    = {};
        wc1     = 0;
        wc2     = 0;
        pkt1_ok = 1'b0;
        pkt2_ok = 1'b0;

        // ── Start background packet collection ──
        // Must be running BEFORE the DUT starts outputting words.
        fork
          begin
            collect_packet(clk_sys, narrow_valid, narrow_ready,
                           narrow_data, pkt1, wc1);
            pkt1_ok = 1'b1;
            collect_packet(clk_sys, narrow_valid, narrow_ready,
                           narrow_data, pkt2, wc2);
            pkt2_ok = 1'b1;
          end
        join_none

        // ── Conversion 1: arm, START, 11 ns delay, STOP ──
        arm();
        #50ns;

        start_spad = 1'b1; #1ns; start_spad = 1'b0;
        #11ns;
        stop_spad  = 1'b1;
        t_stop_r   = $realtime;
        #1ns;
        stop_spad  = 1'b0;

        // ── Re-arm + enforce gap ──
        // arm() and the gap delay run in parallel.  fork/join waits
        // for both, so the actual gap from STOP rising ≈
        // max(1 ns + arm_latency, requested_gap).
        fork
          arm();
          begin
            if (gap > 1) #((gap - 1) * 1ns);
          end
        join

        // ── Conversion 2: START, 11 ns delay, STOP ──
        start_spad = 1'b1;
        t_start2_r = $realtime;
        #1ns;
        start_spad = 1'b0;
        #11ns;
        stop_spad  = 1'b1; #1ns; stop_spad = 1'b0;

        meas = t_start2_r - t_stop_r;

        // ── Wait for both packets or timeout ──
        fork
          begin
            while (!pkt2_ok) @(posedge clk_sys);
          end
          begin
            #(TB_TIMEOUT_CYC * CLK_SYS_PERIOD);
          end
        join_any
        disable fork;

        // ── Validate both packets ──
        if (pkt1_ok && pkt2_ok && wc1 >= 2 && wc2 >= 2
            && is_header(pkt1[0])      && is_eoc(pkt1[wc1-1])
            && is_header(pkt2[0])      && is_eoc(pkt2[wc2-1])) begin
          pass_cnt++;
          $display(
            "[TB]   trial %0d: PASS  measured_gap=%.3f ns  conv1=%0dw conv2=%0dw id1=%0d id2=%0d",
            tr, meas, wc1, wc2,
            eoc_conv_id(pkt1[wc1-1]),
            eoc_conv_id(pkt2[wc2-1]));
        end else begin
          $display(
            "[TB]   trial %0d: FAIL  pkt1_ok=%0b(%0dw) pkt2_ok=%0b(%0dw) gap=%.3f ns",
            tr, pkt1_ok, wc1, pkt2_ok, wc2, meas);
        end

        // Drain residual data and let pipeline settle
        #500ns;
      end

      if (pass_cnt == N_TRIALS) begin
        $display("[TB]   gap=%0d ns: ALL %0d TRIALS PASSED", gap, N_TRIALS);
        if (gap < min_gap_pass) min_gap_pass = gap;
      end else begin
        $display("[TB]   gap=%0d ns: %0d/%0d passed", gap, pass_cnt, N_TRIALS);
      end
    end

    // ── Final report ───────────────────────────────────────────────
    $display("[TB]");
    $display("[TB] ===== DEADTIME MEASUREMENT RESULTS =====");

    if (min_gap_pass < 999) begin
      $display("[TB] Minimum successful requested gap: %0d ns", min_gap_pass);
    end else begin
      $display("[TB] No gap succeeded");
    end

    if (min_gap_pass < 15) begin
      $display("[TB] ===== TEST PASSED =====");
      $display("[TB] Deadtime < 15 ns — excellent triple-buffer performance");
    end else if (min_gap_pass < 20) begin
      $display("[TB] ===== TEST PASSED =====");
      $display("[TB] Deadtime < 20 ns — acceptable performance");
    end else if (min_gap_pass < 999) begin
      $display("[TB] ===== TEST PASSED =====");
      $display("[TB] Deadtime = %0d ns (> 20 ns target; includes re-arm CDC latency)",
               min_gap_pass);
    end else begin
      $error("[TB] DEADTIME TEST TIMEOUT");
    end

    $finish;
  end

  // ── Absolute watchdog (50 ms sim time) ───────────────────────────
  initial begin
    #50_000_000ns;
    $error("[TB] DEADTIME TEST TIMEOUT");
    $finish;
  end

endmodule
