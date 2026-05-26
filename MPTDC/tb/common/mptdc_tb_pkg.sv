// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : mptdc_tb_pkg.sv
// Purpose : Shared package for CSR helpers, packet parsing, and pulse injection.
// Author  : Karim Sabra
// Notes   : Helper functions mirror the narrow packet contract used by the
//           legacy testbenches and the VIP scoreboard.
// =============================================================================
`timescale 1ps / 1ps

package mptdc_tb_pkg;
  import mptdc_pkg::*;

  // =========================================================================
  // Clock generation parameters
  // =========================================================================
  localparam realtime CLK_SYS_PERIOD = 6250ps;   // 160 MHz
  localparam realtime CLK_SYS_HALF   = CLK_SYS_PERIOD / 2;

  // =========================================================================
  // Timeout limits (in system clock cycles)
  // =========================================================================
  localparam int unsigned TB_TIMEOUT_CYC = 100_000;

  // =========================================================================
  // 16-bit output packet parsing helpers
  // =========================================================================
  // These helpers decode the exact narrow-bus framing consumed by monitors,
  // directed testbenches, and the VIP scoreboard.
  function automatic logic is_header(input logic [NARROW_W-1:0] word);
    return (word[15:13] == 3'b100);
  endfunction

  function automatic logic is_subheader(input logic [NARROW_W-1:0] word);
    return (word[15:13] == 3'b101);
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
    return OUT_MODE_RAW_FEATURES;
  endfunction

  function automatic logic header_boundary_inc(input logic [NARROW_W-1:0] word);
    return 1'b0;
  endfunction

  function automatic logic [13:0] eoc_conv_id(
    input logic [NARROW_W-1:0] word
  );
    return word[13:0];
  endfunction

  // =========================================================================
  // Hit word extraction (RAW_FEATURES mode: 2 words)
  // =========================================================================
  typedef struct {
     logic [NSLOW_W-1:0]     nslow;
     logic [NFAST_W-1:0]     nfast;        // per-hit nfast (from PD cell)
     ph_idx_t                ns;
     ph_idx_t                nf;
     stop_phase_disc_t       stop_phase_disc;
   } tb_hit_features_t;

  function automatic tb_hit_features_t parse_hit_features(
    input logic [NARROW_W-1:0] w0,
    input logic [NARROW_W-1:0] w1
  );
    tb_hit_features_t h;
    // W0: {1'b0, nslow[6:0], nfast[6:0], 1'b0}
    h.nslow      = w0[14:8];
    h.nfast      = w0[7:1];
    // W1: {1'b0, ns[3:0], nf[3:0], 4'b0, stop_phase_disc[2:0]};
    // active 8-tap RTL uses ns/nf values 0..7.
    h.ns         = w1[14:11];
    h.nf         = w1[10:7];
    h.stop_phase_disc = stop_phase_disc_t'(w1[2:0]);
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
    input realtime pulse_w = 1000ps
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
  // Drives narrow_ready high and returns one complete header-to-EOC packet so
  // tests do not have to duplicate the same ready/valid collection loop.
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
