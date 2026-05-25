// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Characterization Collateral
// File    : tb_char_code_density.sv
// Purpose : Code-density data collection bench.  The default configuration is
//           strict mono-hit (max_hits=1) for raw INL/DNL characterization.
// =============================================================================
`timescale 1ps/1ps

module tb_char_code_density;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;
  import mptdc_char_tb_pkg::*;

  logic clk_sys = 1'b0;
  always #(CLK_SYS_HALF) clk_sys = ~clk_sys;

  logic async_rst_n;
  logic start_spad, stop_spad, cal_start, cal_stop;
  logic csr_valid, csr_write;
  logic [CSR_ADDR_W-1:0] csr_addr;
  logic [CSR_DATA_W-1:0] csr_wdata;
  logic csr_ready, csr_rvalid;
  logic [CSR_DATA_W-1:0] csr_rdata;
  logic narrow_ready, narrow_valid;
  logic [NARROW_W-1:0] narrow_data;

  int cfg_seed;
  int cfg_n_conv;
  int cfg_delay_min_ps;
  int cfg_delay_max_ps;
  int cfg_max_hits;
  int cfg_input_sel;
  int cfg_out_mode;
  int cfg_post_gap_ps;
  string cfg_output_file;
  string cfg_config;

  mptdc_top_asic u_dut (
    .clk_sys(clk_sys), .async_rst_n(async_rst_n),
    .start_spad_async_i(start_spad), .stop_spad_async_i(stop_spad),
    .cal_start_async_i(cal_start), .cal_stop_async_i(cal_stop),
    .input_sel_override_en_i(1'b0), .input_sel_override_i(INPUT_SPAD),
    .out_mode_override_en_i(1'b0), .out_mode_override_i(OUT_MODE_RAW_FEATURES),
    .csr_valid_i(csr_valid), .csr_write_i(csr_write),
    .csr_addr_i(csr_addr), .csr_wdata_i(csr_wdata),
    .csr_ready_o(csr_ready), .csr_rvalid_o(csr_rvalid), .csr_rdata_o(csr_rdata),
    .narrow_ready_i(narrow_ready), .narrow_valid_o(narrow_valid),
    .narrow_data_o(narrow_data),
    .shared_readout_en_i(1'b0), .acq_ready_i(1'b0),
    .acq_valid_o(), .acq_data_o(), .fifo_full_o()
  );

  task automatic read_plusargs();
    if (!$value$plusargs("CHAR_SEED=%d", cfg_seed)) cfg_seed = 1;
    if (!$value$plusargs("CHAR_N_CONV=%d", cfg_n_conv)) cfg_n_conv = 1000;
    if (!$value$plusargs("CHAR_DELAY_MIN_PS=%d", cfg_delay_min_ps)) cfg_delay_min_ps = 20;
    if (!$value$plusargs("CHAR_DELAY_MAX_PS=%d", cfg_delay_max_ps)) cfg_delay_max_ps = 30000;
    if (!$value$plusargs("CHAR_MAX_HITS=%d", cfg_max_hits)) cfg_max_hits = 1;
    if (!$value$plusargs("CHAR_INPUT_SEL=%d", cfg_input_sel)) cfg_input_sel = int'(INPUT_CAL);
    if (!$value$plusargs("CHAR_OUT_MODE=%d", cfg_out_mode)) cfg_out_mode = int'(OUT_MODE_RAW_FEATURES);
    if (!$value$plusargs("CHAR_POST_GAP_PS=%d", cfg_post_gap_ps)) cfg_post_gap_ps = 200_000;
    if (!$value$plusargs("CHAR_OUTPUT_FILE=%s", cfg_output_file)) cfg_output_file = "char_code_density.csv";
    if (!$value$plusargs("CHAR_CONFIG=%s", cfg_config)) cfg_config = "code_density";
  endtask

  initial begin
    int fd;
    int unsigned rng;
    int delay_ps;
    int skew_ps;
    int stim_phase_bin;
    int stim_uniformity_bin;
    longint t_start_ps, t_stop_ps;
    logic [CHAR_PKT_BITS-1:0] pkt;
    int pkt_wc;
    bit pkt_ok;
    string extra;

    read_plusargs();
    rng = cfg_seed;

    async_rst_n = 1'b0;
    start_spad = 1'b0; stop_spad = 1'b0;
    cal_start = 1'b0; cal_stop = 1'b0;
    csr_valid = 1'b0; csr_write = 1'b0; csr_addr = '0; csr_wdata = '0;
    narrow_ready = 1'b0;

    #100_000; async_rst_n = 1'b1; #100_000;
    char_configure(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                   cfg_max_hits, cfg_input_sel, cfg_out_mode, 16'd500, 16'd0);

    fd = $fopen(cfg_output_file, "w");
    if (fd == 0)
      $fatal(1, "[CHAR] Cannot open %s", cfg_output_file);
    char_write_header(fd, "stim_phase_bin,stim_uniformity_bin");

    for (int trial = 0; trial < cfg_n_conv; trial++) begin
      rng = char_lcg_next(rng);
      delay_ps = char_rand_range(rng ^ (trial * 32'd9973), cfg_delay_min_ps, cfg_delay_max_ps);
      delay_ps = cfg_delay_min_ps
               + ((delay_ps + (trial * 9973) + ((trial * trial) % 7919))
                  % (cfg_delay_max_ps - cfg_delay_min_ps + 1));

      char_arm(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata);
      #(20_000 + (trial % 37));

      rng = char_lcg_next(rng);
      skew_ps = char_rand_range(rng, 0, int'(SYS_CLK_PS - 1));
      #(skew_ps);

      char_inject_pair(start_spad, stop_spad, cal_start, cal_stop,
                       cfg_input_sel, delay_ps, t_start_ps, t_stop_ps);
      char_collect_packet_timeout(clk_sys, narrow_valid, narrow_ready, narrow_data,
                                   pkt, pkt_wc, pkt_ok);

      stim_phase_bin = delay_ps % int'(SLOW_HALF_PERIOD_PS);
      stim_uniformity_bin = int'((t_start_ps % SYS_CLK_PS) * 64 / SYS_CLK_PS);
      extra = $sformatf("%0d,%0d", stim_phase_bin, stim_uniformity_bin);
      char_write_packet_rows(fd, 1, 0, cfg_seed, trial,
                             delay_ps, t_start_ps, t_stop_ps, pkt_ok, !pkt_ok,
                             cfg_max_hits, cfg_input_sel, cfg_out_mode, pkt_wc,
                             pkt, extra);
      char_disarm(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata);
      #(cfg_post_gap_ps);
    end

    $fclose(fd);
    $display("[CHAR] code_density complete: %0d conversions -> %s",
             cfg_n_conv, cfg_output_file);
    $finish;
  end

  initial begin
    #500ms;
    $fatal(1, "[CHAR] tb_char_code_density timeout");
  end
endmodule
