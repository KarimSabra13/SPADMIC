// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Characterization Collateral
// File    : tb_char_context_overflow.sv
// Purpose : Context pressure, FIFO stall, and overflow characterization.
// =============================================================================
`timescale 1ps/1ps

module tb_char_context_overflow;
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

  int cfg_seed, cfg_attempts, cfg_delay_ps, cfg_gap_ps, cfg_max_hits;
  int cfg_input_sel, cfg_out_mode;
  string cfg_output_file, cfg_config;

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
    if (!$value$plusargs("CHAR_ATTEMPTS=%d", cfg_attempts)) cfg_attempts = 80;
    if (!$value$plusargs("CHAR_DELAY_PS=%d", cfg_delay_ps)) cfg_delay_ps = 10_000;
    if (!$value$plusargs("CHAR_GAP_PS=%d", cfg_gap_ps)) cfg_gap_ps = 2000;
    if (!$value$plusargs("CHAR_MAX_HITS=%d", cfg_max_hits)) cfg_max_hits = 15;
    if (!$value$plusargs("CHAR_INPUT_SEL=%d", cfg_input_sel)) cfg_input_sel = int'(INPUT_CAL);
    if (!$value$plusargs("CHAR_OUT_MODE=%d", cfg_out_mode)) cfg_out_mode = int'(OUT_MODE_RAW_FEATURES);
    if (!$value$plusargs("CHAR_OUTPUT_FILE=%s", cfg_output_file)) cfg_output_file = "char_context.csv";
    if (!$value$plusargs("CHAR_CONFIG=%s", cfg_config)) cfg_config = "context_overflow";
  endtask

  initial begin
    int fd;
    longint t_start_ps, t_stop_ps;
    logic [CSR_DATA_W-1:0] ovf_before, ovf_after, status_word, fifo_word;
    string extra;

    read_plusargs();
    async_rst_n = 1'b0;
    start_spad = 1'b0; stop_spad = 1'b0; cal_start = 1'b0; cal_stop = 1'b0;
    csr_valid = 1'b0; csr_write = 1'b0; csr_addr = '0; csr_wdata = '0;
    narrow_ready = 1'b0;
    #100_000; async_rst_n = 1'b1; #100_000;

    char_configure(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                   cfg_max_hits, cfg_input_sel, cfg_out_mode, 16'd500, 16'd0);
    char_arm(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata);

    fd = $fopen(cfg_output_file, "w");
    if (fd == 0)
      $fatal(1, "[CHAR] Cannot open %s", cfg_output_file);
    char_write_header(fd, "attempt,ovf_before,ovf_after,status_word,fifo_status,ctx_state_packed,fifo_level,fifo_full");

    for (int attempt = 0; attempt < cfg_attempts; attempt++) begin
      char_csr_read(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                    csr_rvalid, csr_rdata, CSR_OVF_COUNT, ovf_before);
      char_inject_pair(start_spad, stop_spad, cal_start, cal_stop,
                       cfg_input_sel, cfg_delay_ps, t_start_ps, t_stop_ps);
      #(cfg_gap_ps);
      char_csr_read(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                    csr_rvalid, csr_rdata, CSR_OVF_COUNT, ovf_after);
      char_csr_read(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                    csr_rvalid, csr_rdata, CSR_STATUS, status_word);
      char_csr_read(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                    csr_rvalid, csr_rdata, CSR_FIFO_STATUS, fifo_word);
      extra = $sformatf("%0d,%0d,%0d,0x%08h,0x%08h,%0d,%0d,%0d",
                        attempt, ovf_before[15:0], ovf_after[15:0],
                        status_word, fifo_word, status_word[5:2],
                        fifo_word[FIFO_LVL_W-1:0], fifo_word[FIFO_LVL_W]);
      char_write_summary_row(fd, 4, 0, cfg_seed,
                             attempt, -1, cfg_delay_ps, t_start_ps, t_stop_ps,
                             ovf_after == ovf_before, ovf_after > ovf_before,
                             cfg_max_hits, cfg_input_sel, cfg_out_mode);
    end

    narrow_ready = 1'b1;
    #1_000_000;
    $fclose(fd);
    $display("[CHAR] context_overflow complete -> %s", cfg_output_file);
    $finish;
  end

  initial begin
    #500ms;
    $fatal(1, "[CHAR] tb_char_context_overflow timeout");
  end
endmodule
