// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// mptdc_tb_pkg.sv — Testbench support package
//
// Provides utilities, checkers, and constants for all MPTDC testbenches.

`timescale 1ns / 1ps

package mptdc_tb_pkg;
  import mptdc_pkg::*;

  // =========================================================================
  // Clock generation parameters
  // =========================================================================
  localparam realtime CLK_SYS_PERIOD = 6.25ns;   // 160 MHz
  localparam realtime CLK_SYS_HALF   = CLK_SYS_PERIOD / 2;

  // =========================================================================
  // Timeout limits (in system clock cycles)
  // =========================================================================
  localparam int unsigned TB_TIMEOUT_CYC = 100_000;

  // =========================================================================
  // 16-bit output packet parsing helpers
  // =========================================================================
  function automatic logic is_header(input logic [NARROW_W-1:0] word);
    return (word[15:14] == 2'b10);
  endfunction

  function automatic logic is_eoc(input logic [NARROW_W-1:0] word);
    return (word[15:14] == 2'b11);
  endfunction

  function automatic ctx_id_t header_ctx_id(input logic [NARROW_W-1:0] word);
    return word[13:12];
  endfunction

  function automatic logic header_phase0(input logic [NARROW_W-1:0] word);
    return word[11];
  endfunction

  function automatic logic [MAX_HITS_W-1:0] header_hit_count(
    input logic [NARROW_W-1:0] word
  );
    return word[10:7];
  endfunction

  function automatic tdc_conv_flags_t header_flags(
    input logic [NARROW_W-1:0] word
  );
    return word[6:3];
  endfunction

  function automatic out_mode_e header_out_mode(
    input logic [NARROW_W-1:0] word
  );
    return out_mode_e'(word[2:1]);
  endfunction

  function automatic logic [13:0] eoc_conv_id(
    input logic [NARROW_W-1:0] word
  );
    return word[13:0];
  endfunction

  // =========================================================================
  // Hit word extraction (RAW_FEATURES mode: 3 words)
  // =========================================================================
  typedef struct {
    logic [NSLOW_W-1:0]     nslow;
    logic [NFAST_W-1:0]     nfast;
    ph_idx_t                ns;
    ph_idx_t                nf;
    logic [PD_W-1:0]        pd_idx;
    logic [EVENT_SEQ_W-1:0] event_seq;
  } tb_hit_features_t;

  function automatic tb_hit_features_t parse_hit_features(
    input logic [NARROW_W-1:0] w0,
    input logic [NARROW_W-1:0] w1,
    input logic [NARROW_W-1:0] w2
  );
    tb_hit_features_t h;
    // W0: {1'b0, nslow[6:0], nfast[6:0], 1'b0}
    h.nslow     = w0[14:8];
    h.nfast     = w0[7:1];
    // W1: {1'b0, ns[3:0], nf[3:0], pd_idx[6:0]}
    h.ns        = w1[14:11];
    h.nf        = w1[10:7];
    h.pd_idx    = w1[6:0];
    // W2: {1'b0, event_seq[3:0], 11'b0}
    h.event_seq = w2[14:11];
    return h;
  endfunction

  // =========================================================================
  // Task: CSR write via valid/ready bus
  // =========================================================================
  task automatic tb_csr_write(
    ref logic                       clk,
    ref logic                       csr_valid,
    ref logic                       csr_write,
    ref logic [CSR_ADDR_W-1:0]     csr_addr,
    ref logic [CSR_DATA_W-1:0]     csr_wdata,
    input logic [CSR_ADDR_W-1:0]   addr,
    input logic [CSR_DATA_W-1:0]   data
  );
    @(posedge clk);
    csr_valid  = 1'b1;
    csr_write  = 1'b1;
    csr_addr   = addr;
    csr_wdata  = data;
    @(posedge clk);
    csr_valid  = 1'b0;
    csr_write  = 1'b0;
  endtask

  // =========================================================================
  // Task: CSR read via valid/ready bus
  // =========================================================================
  task automatic tb_csr_read(
    ref logic                       clk,
    ref logic                       csr_valid,
    ref logic                       csr_write,
    ref logic [CSR_ADDR_W-1:0]     csr_addr,
    ref logic [CSR_DATA_W-1:0]     csr_wdata,
    ref logic                       csr_rvalid,
    ref logic [CSR_DATA_W-1:0]     csr_rdata,
    input logic [CSR_ADDR_W-1:0]   addr,
    output logic [CSR_DATA_W-1:0]  data
  );
    @(posedge clk);
    csr_valid = 1'b1;
    csr_write = 1'b0;
    csr_addr  = addr;
    csr_wdata = '0;
    @(posedge clk);
    csr_valid = 1'b0;
    // Wait for rvalid
    while (!csr_rvalid) @(posedge clk);
    data = csr_rdata;
  endtask

  // =========================================================================
  // Task: Generate async START/STOP pulse pair with configurable delay
  // =========================================================================
  task automatic inject_pulse_pair(
    ref logic start_sig,
    ref logic stop_sig,
    input realtime delay_ps,   // Time between START and STOP
    input realtime pulse_w = 1ns
  );
    start_sig = 1'b1;
    #(pulse_w);
    start_sig = 1'b0;
    #(delay_ps);
    stop_sig = 1'b1;
    #(pulse_w);
    stop_sig = 1'b0;
  endtask

  // =========================================================================
  // Task: Collect one complete 16-bit packet
  // =========================================================================
  task automatic collect_packet(
    ref logic                      clk,
    ref logic                      narrow_valid,
    ref logic                      narrow_ready,
    ref logic [NARROW_W-1:0]      narrow_data,
    output logic [NARROW_W-1:0]   words [$],
    output int                     word_count
  );
    logic [NARROW_W-1:0] w;
    words = {};
    word_count = 0;
    narrow_ready = 1'b1;

    // Wait for header
    while (1) begin
      @(posedge clk);
      if (narrow_valid && narrow_ready) begin
        w = narrow_data;
        words.push_back(w);
        word_count++;
        if (is_header(w)) break;
      end
    end

    // Collect until EOC
    while (1) begin
      @(posedge clk);
      if (narrow_valid && narrow_ready) begin
        w = narrow_data;
        words.push_back(w);
        word_count++;
        if (is_eoc(w)) break;
      end
    end
  endtask

endpackage
