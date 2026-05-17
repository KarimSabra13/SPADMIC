// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Characterization Collateral
// File    : tb_char_deadtime_persistent.sv
// Purpose : Persistent-arm double-pulse deadtime characterization.
// =============================================================================
`timescale 1ps/1ps

module tb_char_deadtime_persistent;
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

  int cfg_seed, cfg_gap_min_ps, cfg_gap_max_ps, cfg_gap_step_ps;
  int cfg_trials_per_gap, cfg_delay_ps, cfg_max_hits, cfg_input_sel, cfg_out_mode;
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
    if (!$value$plusargs("CHAR_GAP_MIN_PS=%d", cfg_gap_min_ps)) cfg_gap_min_ps = 0;
    if (!$value$plusargs("CHAR_GAP_MAX_PS=%d", cfg_gap_max_ps)) cfg_gap_max_ps = 80_000;
    if (!$value$plusargs("CHAR_GAP_STEP_PS=%d", cfg_gap_step_ps)) cfg_gap_step_ps = 1000;
    if (!$value$plusargs("CHAR_TRIALS_PER_GAP=%d", cfg_trials_per_gap)) cfg_trials_per_gap = 10;
    if (!$value$plusargs("CHAR_DELAY_PS=%d", cfg_delay_ps)) cfg_delay_ps = 10_000;
    if (!$value$plusargs("CHAR_MAX_HITS=%d", cfg_max_hits)) cfg_max_hits = 1;
    if (!$value$plusargs("CHAR_INPUT_SEL=%d", cfg_input_sel)) cfg_input_sel = int'(INPUT_CAL);
    if (!$value$plusargs("CHAR_OUT_MODE=%d", cfg_out_mode)) cfg_out_mode = int'(OUT_MODE_RAW_FEATURES);
    if (!$value$plusargs("CHAR_OUTPUT_FILE=%s", cfg_output_file)) cfg_output_file = "char_deadtime.csv";
    if (!$value$plusargs("CHAR_CONFIG=%s", cfg_config)) cfg_config = "deadtime_persistent";
  endtask

  task automatic pulse_start(input int input_sel, output longint t_start_ps);
    begin
      if (input_sel == int'(INPUT_CAL)) begin
        cal_start = 1'b1; t_start_ps = longint'($realtime); #(CHAR_PULSE_W_PS); cal_start = 1'b0;
      end else begin
        start_spad = 1'b1; t_start_ps = longint'($realtime); #(CHAR_PULSE_W_PS); start_spad = 1'b0;
      end
    end
  endtask

  task automatic pulse_stop(input int input_sel, output longint t_stop_ps);
    begin
      if (input_sel == int'(INPUT_CAL)) begin
        cal_stop = 1'b1; t_stop_ps = longint'($realtime); #(CHAR_PULSE_W_PS); cal_stop = 1'b0;
      end else begin
        stop_spad = 1'b1; t_stop_ps = longint'($realtime); #(CHAR_PULSE_W_PS); stop_spad = 1'b0;
      end
    end
  endtask

  initial begin
    int fd;
    int trial_id;
    int gap_req_ps;
    longint t_start1, t_stop1, t_start2, t_stop2;
    logic [CHAR_PKT_BITS-1:0] pkt1;
    logic [CHAR_PKT_BITS-1:0] pkt2;
    int wc1, wc2;
    bit ok1, ok2;
    logic [CSR_DATA_W-1:0] ovf_before, ovf_after;
    string extra1, extra2;

    read_plusargs();
    async_rst_n = 1'b0;
    start_spad = 1'b0; stop_spad = 1'b0; cal_start = 1'b0; cal_stop = 1'b0;
    csr_valid = 1'b0; csr_write = 1'b0; csr_addr = '0; csr_wdata = '0;
    narrow_ready = 1'b1;
    #100_000; async_rst_n = 1'b1; #100_000;

    fd = $fopen(cfg_output_file, "w");
    if (fd == 0)
      $fatal(1, "[CHAR] Cannot open %s", cfg_output_file);
    char_write_header(fd, "gap_req_ps,gap_meas_ps,pair_index,ovf_before,ovf_after,meas_state,ctx_state_packed,fifo_level");

    trial_id = 0;
    for (gap_req_ps = cfg_gap_min_ps; gap_req_ps <= cfg_gap_max_ps; gap_req_ps += cfg_gap_step_ps) begin
      for (int tr = 0; tr < cfg_trials_per_gap; tr++) begin
        char_configure(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                       cfg_max_hits, cfg_input_sel, cfg_out_mode, 16'd500, 16'd0);
        char_arm(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata);
        #20_000;
        char_csr_read(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                      csr_rvalid, csr_rdata, CSR_OVF_COUNT, ovf_before);

        wc1 = 0; wc2 = 0; ok1 = 0; ok2 = 0;
        fork
          begin
            char_collect_packet_timeout(clk_sys, narrow_valid, narrow_ready,
                                        narrow_data, pkt1, wc1, ok1);
            char_collect_packet_timeout(clk_sys, narrow_valid, narrow_ready,
                                        narrow_data, pkt2, wc2, ok2);
          end
        join_none

        pulse_start(cfg_input_sel, t_start1);
        #(cfg_delay_ps);
        pulse_stop(cfg_input_sel, t_stop1);
        #(gap_req_ps);
        pulse_start(cfg_input_sel, t_start2);
        #(cfg_delay_ps);
        pulse_stop(cfg_input_sel, t_stop2);

        #(200_000);
        disable fork;
        char_csr_read(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                      csr_rvalid, csr_rdata, CSR_OVF_COUNT, ovf_after);

        extra1 = $sformatf("%0d,%0d,0,%0d,%0d,%0d,%0d,%0d",
                           gap_req_ps, 0, ovf_before[15:0], ovf_after[15:0],
                           int'(u_dut.u_core.meas_state),
                           int'(u_dut.u_core.status_o.ctx_state_packed),
                           int'(u_dut.u_core.status_o.fifo_level));
        if (ok1)
          char_write_packet_rows(fd, 2, 0, cfg_seed, trial_id,
                                 cfg_delay_ps, t_start1, t_stop1, 1, 0,
                                 cfg_max_hits, cfg_input_sel, cfg_out_mode,
                                 wc1, pkt1, extra1);

        extra2 = $sformatf("%0d,%0d,1,%0d,%0d,%0d,%0d,%0d",
                           gap_req_ps, int'(t_start2 - t_stop1),
                           ovf_before[15:0], ovf_after[15:0],
                           int'(u_dut.u_core.meas_state),
                           int'(u_dut.u_core.status_o.ctx_state_packed),
                           int'(u_dut.u_core.status_o.fifo_level));
        if (ok2) begin
          char_write_packet_rows(fd, 2, 0, cfg_seed, trial_id,
                                 cfg_delay_ps, t_start2, t_stop2, 1, 0,
                                 cfg_max_hits, cfg_input_sel, cfg_out_mode,
                                 wc2, pkt2, extra2);
        end else begin
          char_write_summary_row(fd, 2, 0, cfg_seed, trial_id,
                                 -1, cfg_delay_ps, t_start2, t_stop2, 0, 1,
                                 cfg_max_hits, cfg_input_sel, cfg_out_mode, extra2);
        end

        trial_id++;
        tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                     CSR_CTRL, 32'h6);
        #50_000;
      end
    end

    $fclose(fd);
    $display("[CHAR] deadtime complete -> %s", cfg_output_file);
    $finish;
  end

  initial begin
    #500ms;
    $fatal(1, "[CHAR] tb_char_deadtime_persistent timeout");
  end
endmodule
