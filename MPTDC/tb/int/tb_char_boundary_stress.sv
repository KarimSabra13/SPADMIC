// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Characterization Collateral
// File    : tb_char_boundary_stress.sv
// Purpose : Boundary and PD-wavefront stress data collection.
// =============================================================================
`timescale 1ps/1ps

module tb_char_boundary_stress;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;
  import mptdc_char_tb_pkg::*;

  logic clk_sys;
  initial clk_sys = 1'b0;
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

  int cfg_seed, cfg_boundaries, cfg_repeats;
  int cfg_offset_min_ps, cfg_offset_max_ps, cfg_offset_step_ps;
  int cfg_base_delay_ps, cfg_max_hits, cfg_input_sel, cfg_out_mode;
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
    if (!$value$plusargs("CHAR_BOUNDARIES=%d", cfg_boundaries)) cfg_boundaries = 16;
    if (!$value$plusargs("CHAR_REPEATS=%d", cfg_repeats)) cfg_repeats = 4;
    if (!$value$plusargs("CHAR_OFFSET_MIN_PS=%d", cfg_offset_min_ps)) cfg_offset_min_ps = -20;
    if (!$value$plusargs("CHAR_OFFSET_MAX_PS=%d", cfg_offset_max_ps)) cfg_offset_max_ps = 20;
    if (!$value$plusargs("CHAR_OFFSET_STEP_PS=%d", cfg_offset_step_ps)) cfg_offset_step_ps = 1;
    if (!$value$plusargs("CHAR_BASE_DELAY_PS=%d", cfg_base_delay_ps)) cfg_base_delay_ps = 5000;
    if (!$value$plusargs("CHAR_MAX_HITS=%d", cfg_max_hits)) cfg_max_hits = 15;
    if (!$value$plusargs("CHAR_INPUT_SEL=%d", cfg_input_sel)) cfg_input_sel = int'(INPUT_CAL);
    if (!$value$plusargs("CHAR_OUT_MODE=%d", cfg_out_mode)) cfg_out_mode = int'(OUT_MODE_FULL);
    if (!$value$plusargs("CHAR_OUTPUT_FILE=%s", cfg_output_file)) cfg_output_file = "char_boundary.csv";
    if (!$value$plusargs("CHAR_CONFIG=%s", cfg_config)) cfg_config = "boundary_stress";
  endtask

  initial begin
    int fd;
    int trial_id;
    int delay_ps;
    int offset_ps;
    longint t_start_ps, t_stop_ps;
    logic [CHAR_PKT_BITS-1:0] pkt;
    int pkt_wc;
    bit pkt_ok;
    string extra;

    read_plusargs();
    async_rst_n = 1'b0;
    start_spad = 1'b0; stop_spad = 1'b0; cal_start = 1'b0; cal_stop = 1'b0;
    csr_valid = 1'b0; csr_write = 1'b0; csr_addr = '0; csr_wdata = '0;
    narrow_ready = 1'b0;
    #100_000; async_rst_n = 1'b1; #100_000;
    char_configure(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                   cfg_max_hits, cfg_input_sel, cfg_out_mode, 16'd500, 16'd0);

    fd = $fopen(cfg_output_file, "w");
    if (fd == 0)
      $fatal(1, "[CHAR] Cannot open %s", cfg_output_file);
    char_write_header(fd, "boundary_target,boundary_offset_ps,pd_hit_bitmap_hex,pd_nfast_hit_packed_hex,nslow_src_count,nslow_stop_latched,nfast_src_count");

    trial_id = 0;
    for (int b = 0; b < cfg_boundaries; b++) begin
      for (offset_ps = cfg_offset_min_ps; offset_ps <= cfg_offset_max_ps; offset_ps += cfg_offset_step_ps) begin
        for (int rep = 0; rep < cfg_repeats; rep++) begin
          delay_ps = cfg_base_delay_ps + b * int'(SLOW_HALF_PERIOD_PS) + offset_ps;
          if (delay_ps < 1)
            delay_ps = 1;

          char_arm(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata);
          #(20_000 + ((trial_id * 17 + cfg_seed) % 313));
          char_inject_pair(start_spad, stop_spad, cal_start, cal_stop,
                           cfg_input_sel, delay_ps, t_start_ps, t_stop_ps);
          char_collect_packet_timeout(clk_sys, narrow_valid, narrow_ready,
                                      narrow_data, pkt, pkt_wc, pkt_ok);

          extra = $sformatf("%0d,%0d,%016h,%0h,%0d,%0d,%0d",
                            b, offset_ps,
                            u_dut.u_core.hit_capture_snapshot.hit_level,
                            u_dut.u_core.hit_capture_snapshot.nfast_hit_packed,
                            int'(u_dut.u_core.nslow_src_count),
                            int'(u_dut.u_core.nslow_stop_latched),
                            int'(u_dut.u_core.nfast_src_count));
          char_write_packet_rows(fd, 3, 0, cfg_seed, trial_id,
                                 delay_ps, t_start_ps, t_stop_ps, pkt_ok, !pkt_ok,
                                 cfg_max_hits, cfg_input_sel, cfg_out_mode,
                                 pkt_wc, pkt, extra);
          char_disarm(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata);
          trial_id++;
          #200_000;
        end
      end
    end

    $fclose(fd);
    $display("[CHAR] boundary complete -> %s", cfg_output_file);
    $finish;
  end

  initial begin
    #500ms;
    $fatal(1, "[CHAR] tb_char_boundary_stress timeout");
  end
endmodule
