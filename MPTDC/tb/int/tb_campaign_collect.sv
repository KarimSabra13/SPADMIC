// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_campaign_collect.sv
// Purpose : Plusarg-configurable data-collection testbench that runs N
//           conversions with random delays in FULL output mode, collecting
//           all raw fields and writing one CSV file per run.
// Author  : Karim Sabra
// =============================================================================
`timescale 1ps/1ps

module tb_campaign_collect;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  // =========================================================================
  //  Plusarg-configurable parameters (with sensible defaults)
  // =========================================================================
  int          cfg_mode;            // 0=multi-hit, 1=fast-close compatibility
  int          cfg_max_hits;
  int          cfg_input_sel;       // 0=SPAD, 1=CAL
  int          cfg_n_conv;
  int          cfg_delay_min_ps;
  int          cfg_delay_max_ps;
  int unsigned cfg_seed;
  int          cfg_out_mode;        // 0=RAW_FEATURES, 2=FULL
  string       cfg_output_file;
  int          cfg_osc_jitter_sigma;
  int          cfg_osc_jitter_bound;

  // =========================================================================
  //  Constants
  // =========================================================================
  localparam int PULSE_W_PS     = 1000;      // 1 ns pulse width
  localparam int POST_CONV_WAIT = 200_000;   // 200 ns post-conversion gap
  localparam int SETTLE_PS      = 20_000;    // 20 ns settle after arm

  // =========================================================================
  //  Clock / reset / DUT signals
  // =========================================================================
  logic clk_sys;
  logic async_rst_n;

  logic start_spad, stop_spad;
  logic cal_start, cal_stop;

  logic                   csr_valid, csr_write;
  logic [CSR_ADDR_W-1:0]  csr_addr;
  logic [CSR_DATA_W-1:0]  csr_wdata;
  logic                   narrow_ready;
  logic                   narrow_valid;
  logic [NARROW_W-1:0]    narrow_data;

  // Logic mirrors of DUT output wires (needed for ref-passing in tasks)
  logic                   csr_ready_l, csr_rvalid_l;
  logic [CSR_DATA_W-1:0]  csr_rdata_l;

  // Clock: 160 MHz = 6250 ps period
  initial clk_sys = 1'b0;
  always #(CLK_SYS_HALF) clk_sys = ~clk_sys;

  // DUT output wires
  wire                    w_csr_ready, w_csr_rvalid;
  wire [CSR_DATA_W-1:0]  w_csr_rdata;
  wire                    w_narrow_valid;
  wire [NARROW_W-1:0]    w_narrow_data;

  // Continuous assignments (wire → logic for task ref passing)
  assign csr_ready_l   = w_csr_ready;
  assign csr_rvalid_l  = w_csr_rvalid;
  assign csr_rdata_l   = w_csr_rdata;
  assign narrow_valid   = w_narrow_valid;
  assign narrow_data    = w_narrow_data;

  // =========================================================================
  //  DUT
  // =========================================================================
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
    .csr_write_i        (csr_write),
    .csr_addr_i         (csr_addr),
    .csr_wdata_i        (csr_wdata),
    .csr_ready_o        (w_csr_ready),
    .csr_rvalid_o       (w_csr_rvalid),
    .csr_rdata_o        (w_csr_rdata),
    .narrow_ready_i     (narrow_ready),
    .narrow_valid_o     (w_narrow_valid),
    .narrow_data_o      (w_narrow_data),
    .shared_readout_en_i(1'b0),
    .acq_ready_i        (1'b0),
    .acq_valid_o        (),
    .acq_data_o         (),
    .fifo_full_o        ()
  );

  // =========================================================================
  //  Passive sanity monitor
  // =========================================================================
  mptdc_raw_monitor u_mon (
    .clk_sys        (clk_sys),
    .rst_n          (async_rst_n),
    .narrow_valid_i (narrow_valid),
    .narrow_ready_i (narrow_ready),
    .narrow_data_i  (narrow_data)
  );

  // =========================================================================
  //  CSR helper — local wrapper for tasks from mptdc_tb_pkg
  // =========================================================================
  task automatic csr_wr(input logic [CSR_ADDR_W-1:0] addr,
                        input logic [CSR_DATA_W-1:0] data);
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata, addr, data);
  endtask

  task automatic csr_rd(input logic [CSR_ADDR_W-1:0] addr,
                        output logic [CSR_DATA_W-1:0] data);
    tb_csr_read(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                csr_rvalid_l, csr_rdata_l, addr, data);
  endtask

  // =========================================================================
  //  Deterministic PRNG (Linear Congruential Generator)
  // =========================================================================
  int unsigned prng_state;

  function automatic int unsigned lcg_next();
    prng_state = prng_state * 32'd1103515245 + 32'd12345;
    return prng_state;
  endfunction

  function automatic int rand_delay();
    int unsigned raw;
    raw = lcg_next();
    return cfg_delay_min_ps
           + int'((raw[30:0]) % (cfg_delay_max_ps - cfg_delay_min_ps + 1));
  endfunction

  function automatic int effective_max_hits();
    if (cfg_mode[0])
      return 1;
    return cfg_max_hits;
  endfunction

  // =========================================================================
  //  Configure DUT for campaign
  // =========================================================================
  task automatic configure_campaign();
    logic [CSR_DATA_W-1:0] mode_word;

    // Disarm first
    csr_wr(CSR_CTRL, 32'h0000_0000);

    // Active v2.4 contract: CSR_MODE[0] is reserved. Campaign "mode" is kept
    // only as a compatibility selector so firsthit-named configs map onto the
    // real fast-close setting (max_hits=1) without programming a dead mode bit.
    mode_word = {28'd0, cfg_out_mode[1:0], cfg_input_sel[0], 1'b0};
    csr_wr(CSR_MODE, mode_word);

    // Fast-close compatibility flows request max_hits=1 regardless of the
    // named max_hits bucket in the config string.
    csr_wr(CSR_MAX_HITS, {28'd0, effective_max_hits()[3:0]});

    // Fast-domain watchdog: 500 fast cycles (~450 ns) safety net
    csr_wr(CSR_WDT_CTX, 32'd500);

    // Global watchdog: 10000 sys cycles (~62.5 us) safety net
    csr_wr(CSR_WDT_GLOBAL, 32'd10000);
  endtask

  // =========================================================================
  //  Inject one conversion (START/STOP on selected source)
  // =========================================================================
  task automatic do_one_conversion(
    input int delay_ps,
    output logic [NARROW_W-1:0] words [$],
    output int word_count
  );
    // Arm
    csr_wr(CSR_CTRL, 32'h0000_0001);
    #(SETTLE_PS);

    // Inject START pulse
    if (cfg_input_sel == 0) begin
      start_spad = 1'b1;
      #(PULSE_W_PS);
      start_spad = 1'b0;
    end else begin
      cal_start = 1'b1;
      #(PULSE_W_PS);
      cal_start = 1'b0;
    end

    // Wait the specified delay
    #(delay_ps);

    // Inject STOP pulse
    if (cfg_input_sel == 0) begin
      stop_spad = 1'b1;
      #(PULSE_W_PS);
      stop_spad = 1'b0;
    end else begin
      cal_stop = 1'b1;
      #(PULSE_W_PS);
      cal_stop = 1'b0;
    end

    // Collect narrow packet
    collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data, words, word_count);

    // Disarm
    csr_wr(CSR_CTRL, 32'h0000_0000);
  endtask

  task automatic parse_and_write_raw_features(
    input int fd,
    input int tref_ps,
    input logic [NARROW_W-1:0] words [$],
    input int word_count,
    output int hits_found,
    output int error_count
  );
    int idx;
    logic [NARROW_W-1:0] w;
    int hdr_hit_count;
    int hdr_ctx_id, hdr_phase0, hdr_boundary_inc;
    tdc_conv_flags_t hdr_flags;
    int eoc_id;

    tb_hit_features_t hf;
    int nslow_i, nfast_hit_i, ns_i, nf_i;
    int signed t_raw_ps_i;

    hits_found  = 0;
    error_count = 0;
    idx         = 0;

    if (word_count < 2) begin
      $display("[ERR] Packet too short (%0d words)", word_count);
      error_count++;
      return;
    end

    w = words[0];
    if (!is_header(w)) begin
      $display("[ERR] First word not header (0x%04x)", w);
      error_count++;
      return;
    end
    hdr_hit_count    = header_hit_count(w);
    hdr_ctx_id       = header_ctx_id(w);
    hdr_phase0       = header_phase0(w);
    hdr_boundary_inc = header_boundary_inc(w);
    hdr_flags        = header_flags(w);
    idx = 1;

    if (is_eoc(words[word_count - 1])) begin
      eoc_id = eoc_conv_id(words[word_count - 1]);
    end else begin
      $display("[WARN] No EOC found at end of packet");
      eoc_id = -1;
    end

    while (idx + 1 < word_count) begin
      w = words[idx];
      if (is_eoc(w)) break;
      if (w[15]) begin
        $display("[ERR] Conv %0d word %0d: unexpected marker 0x%04x", eoc_id, idx, w);
        error_count++;
        idx++;
        continue;
      end

      if (idx + 1 >= word_count) break;

      hf = parse_hit_features(words[idx], words[idx+1]);
      nslow_i      = hf.nslow;
      nfast_hit_i  = hf.nfast;
      ns_i         = hf.ns;
      nf_i         = hf.nf;
      t_raw_ps_i   = vernier_tconv_ps(hf.nslow, hf.nfast, hf.ns, hf.nf,
                                      logic'(hdr_boundary_inc));

      $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",
              eoc_id,                // conv_id
              hits_found,            // hit_idx (0-based)
              tref_ps,               // Tref_ps
              nslow_i,               // nslow
              nfast_hit_i,           // nfast_hit
              ns_i,                  // ns
              nf_i,                  // nf
              hdr_phase0,            // phase0_snap
              hdr_boundary_inc,      // slow_boundary_inc
              hdr_hit_count,         // hit_count
              hdr_flags,             // flags
              hdr_ctx_id,            // ctx_id
              t_raw_ps_i,            // t_raw_ps (reconstructed from RAW_FEATURES fields)
              cfg_mode,              // mode
              effective_max_hits()); // max_hits

      hits_found++;
      idx += 2;
    end

    if (hits_found != hdr_hit_count && hdr_hit_count > 0) begin
      $display("[WARN] Conv %0d: header says %0d hits, parsed %0d",
               eoc_id, hdr_hit_count, hits_found);
    end
  endtask

  // =========================================================================
  //  Parse FULL-mode packet and write CSV rows
  // =========================================================================
  // FULL mode: 3 words per hit (W0-W1 = features, W2 = t_raw_ps[15:0])
  task automatic parse_and_write_full(
    input int fd,
    input int tref_ps,
    input logic [NARROW_W-1:0] words [$],
    input int word_count,
    output int hits_found,
    output int error_count
  );
    int idx;
    logic [NARROW_W-1:0] w;
    int hdr_hit_count;
    int hdr_ctx_id, hdr_phase0, hdr_boundary_inc;
    tdc_conv_flags_t hdr_flags;
    int eoc_id;

    tb_hit_features_t hf;
    int nslow_i, nfast_hit_i, ns_i, nf_i;
    int signed t_raw_ps_i;

    hits_found  = 0;
    error_count = 0;
    idx         = 0;

    // ── Validate minimum packet length ──
    if (word_count < 2) begin
      $display("[ERR] Packet too short (%0d words)", word_count);
      error_count++;
      return;
    end

    // ── Parse header ──
    w = words[0];
    if (!is_header(w)) begin
      $display("[ERR] First word not header (0x%04x)", w);
      error_count++;
      return;
    end
    hdr_hit_count    = header_hit_count(w);
    hdr_ctx_id       = header_ctx_id(w);
    hdr_phase0       = header_phase0(w);
    hdr_boundary_inc = header_boundary_inc(w);
    hdr_flags        = header_flags(w);
    idx = 1;

    // ── Parse EOC (last word) to get conv_id ──
    if (is_eoc(words[word_count - 1])) begin
      eoc_id = eoc_conv_id(words[word_count - 1]);
    end else begin
      $display("[WARN] No EOC found at end of packet");
      eoc_id = -1;
    end

    // ── Parse hit words (FULL mode: 3 words per hit) ──
    while (idx + 2 < word_count) begin
      w = words[idx];
      if (is_eoc(w)) break;
      if (w[15]) begin
        $display("[ERR] Conv %0d word %0d: unexpected marker 0x%04x", eoc_id, idx, w);
        error_count++;
        idx++;
        continue;
      end

      // Need 3 words for this hit
      if (idx + 2 >= word_count) break;

      // W0-W1: features (same as RAW_FEATURES)
      hf = parse_hit_features(words[idx], words[idx+1]);
      nslow_i      = hf.nslow;
      nfast_hit_i  = hf.nfast;
      ns_i         = hf.ns;
      nf_i         = hf.nf;

      // W2: t_raw_ps[15:0] — sign-extend from 16 bits
      t_raw_ps_i = $signed(words[idx+2]);

      // Write CSV row
      $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",
              eoc_id,                // conv_id
              hits_found,            // hit_idx (0-based)
              tref_ps,               // Tref_ps
              nslow_i,               // nslow
              nfast_hit_i,           // nfast_hit
              ns_i,                  // ns
              nf_i,                  // nf
              hdr_phase0,            // phase0_snap
              hdr_boundary_inc,      // slow_boundary_inc
              hdr_hit_count,         // hit_count
              hdr_flags,             // flags
              hdr_ctx_id,            // ctx_id
              t_raw_ps_i,            // t_raw_ps
              cfg_mode,              // mode
              effective_max_hits()); // max_hits

      hits_found++;
      idx += 3;
    end

    // Validate hit count
    if (hits_found != hdr_hit_count && hdr_hit_count > 0) begin
      $display("[WARN] Conv %0d: header says %0d hits, parsed %0d",
               eoc_id, hdr_hit_count, hits_found);
    end
  endtask

  // =========================================================================
  //  Read plusargs with defaults
  // =========================================================================
  task automatic read_plusargs();
    if (!$value$plusargs("CAMPAIGN_MODE=%d",        cfg_mode))           cfg_mode           = 0;
    if (!$value$plusargs("CAMPAIGN_MAX_HITS=%d",    cfg_max_hits))       cfg_max_hits       = 15;
    if (!$value$plusargs("CAMPAIGN_INPUT_SEL=%d",   cfg_input_sel))      cfg_input_sel      = 1;
    if (!$value$plusargs("CAMPAIGN_N_CONV=%d",      cfg_n_conv))         cfg_n_conv         = 50000;
    if (!$value$plusargs("CAMPAIGN_DELAY_MIN_PS=%d",cfg_delay_min_ps))   cfg_delay_min_ps   = 20;
    if (!$value$plusargs("CAMPAIGN_DELAY_MAX_PS=%d",cfg_delay_max_ps))   cfg_delay_max_ps   = 30000;
    if (!$value$plusargs("CAMPAIGN_SEED=%d",        cfg_seed))           cfg_seed           = 12345;
    if (!$value$plusargs("CAMPAIGN_OUT_MODE=%d",    cfg_out_mode))       cfg_out_mode       = OUT_MODE_FULL;
    if (!$value$plusargs("CAMPAIGN_OUTPUT_FILE=%s", cfg_output_file))    cfg_output_file    = "campaign_output.csv";
    // OSC jitter params are consumed directly by mptdc_osc_model via its own plusargs
  endtask

  // =========================================================================
  //  Main test sequence
  // =========================================================================
  initial begin
    int fd;
    int delay_ps;
    int total_hits, total_errors, hits, errs;
    logic [NARROW_W-1:0] pkt [$];
    int pkt_len;
    realtime t_start, t_end;

    // Init signals
    async_rst_n  = 1'b0;
    start_spad   = 1'b0;
    stop_spad    = 1'b0;
    cal_start    = 1'b0;
    cal_stop     = 1'b0;
    csr_valid    = 1'b0;
    csr_write    = 1'b0;
    csr_addr     = '0;
    csr_wdata    = '0;
    narrow_ready = 1'b1;

    // Read plusargs
    read_plusargs();
    prng_state = cfg_seed;

    $display("========================================================");
    $display("[CAMPAIGN] Configuration:");
    $display("[CAMPAIGN]   MODE         = %s", cfg_mode ? "FAST_CLOSE(max_hits=1)" : "MULTI_HIT");
    $display("[CAMPAIGN]   MAX_HITS     = %0d", effective_max_hits());
    $display("[CAMPAIGN]   INPUT_SEL    = %s", cfg_input_sel ? "CAL" : "SPAD");
    $display("[CAMPAIGN]   OUT_MODE     = %s",
             (cfg_out_mode == OUT_MODE_RAW_FEATURES) ? "RAW_FEATURES" :
             (cfg_out_mode == OUT_MODE_FULL) ? "FULL" : "UNSUPPORTED");
    $display("[CAMPAIGN]   N_CONV       = %0d", cfg_n_conv);
    $display("[CAMPAIGN]   DELAY_MIN_PS = %0d", cfg_delay_min_ps);
    $display("[CAMPAIGN]   DELAY_MAX_PS = %0d", cfg_delay_max_ps);
    $display("[CAMPAIGN]   SEED         = %0d", cfg_seed);
    $display("[CAMPAIGN]   OUTPUT_FILE  = %s", cfg_output_file);
    $display("========================================================");

    // Reset
    #(100_000);   // 100 ns
    async_rst_n = 1'b1;
    #(50_000);    // 50 ns settle

    // Open CSV file
    fd = $fopen(cfg_output_file, "w");
    if (fd == 0) begin
      $display("[ERR] Cannot open output file: %s", cfg_output_file);
      $finish;
    end

    $fwrite(fd, "conv_id,hit_idx,Tref_ps,nslow,nfast_hit,ns,nf,phase0_snap,slow_boundary_inc,hit_count,flags,ctx_id,t_raw_ps,mode,max_hits\n");

    if (cfg_out_mode != OUT_MODE_RAW_FEATURES && cfg_out_mode != OUT_MODE_FULL) begin
      $display("[ERR] Unsupported CAMPAIGN_OUT_MODE=%0d (use %0d for RAW_FEATURES or %0d for FULL)",
               cfg_out_mode, OUT_MODE_RAW_FEATURES, OUT_MODE_FULL);
      $fclose(fd);
      $finish;
    end

    // Configure DUT
    configure_campaign();

    // Start timer
    t_start = $realtime;

    total_hits   = 0;
    total_errors = 0;

    // ── Conversion loop ──
    for (int i = 0; i < cfg_n_conv; i++) begin
      delay_ps = rand_delay();

      do_one_conversion(delay_ps, pkt, pkt_len);
      case (cfg_out_mode)
        OUT_MODE_RAW_FEATURES: parse_and_write_raw_features(fd, delay_ps, pkt, pkt_len, hits, errs);
        OUT_MODE_FULL:         parse_and_write_full(fd, delay_ps, pkt, pkt_len, hits, errs);
        default: begin
          hits = 0;
          errs = 1;
        end
      endcase

      total_hits   += hits;
      total_errors += errs;

      // Progress report every 1000 conversions
      if (((i + 1) % 1000) == 0)
        $display("[CAMPAIGN] %0d / %0d conversions complete", i + 1, cfg_n_conv);

      // Post-conversion gap for drain
      #(POST_CONV_WAIT);
    end

    t_end = $realtime;

    $fclose(fd);

    // ── Summary ──
    $display("========================================================");
    $display("[CAMPAIGN] COMPLETE");
    $display("[CAMPAIGN]   Total conversions : %0d", cfg_n_conv);
    $display("[CAMPAIGN]   Total hits        : %0d", total_hits);
    $display("[CAMPAIGN]   Total errors      : %0d", total_errors);
    $display("[CAMPAIGN]   Elapsed sim time  : %0t", t_end - t_start);
    $display("[CAMPAIGN]   Output file       : %s", cfg_output_file);
    $display("========================================================");

    $finish;
  end

  // =========================================================================
  //  Global timeout — 500 ms of sim time
  // =========================================================================
  initial begin
    #500ms;
    $display("[ERR] Global timeout reached!");
    $finish;
  end

endmodule
