// =============================================================================
// SPADMIC CSR ABI 1.0 aggregation wrapper.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_matrix_top_csr (
  input  logic clk_sys,
  input  logic rst_n,
  input  logic csr_valid_i,
  input  logic csr_write_i,
  input  logic [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] csr_addr_i,
  input  logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_wdata_i,
  output logic csr_ready_o,
  output logic csr_rvalid_o,
  output logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_rdata_o,
  output logic csr_err_o,

  input  logic i2c_error_event_i,
  input  logic i2c_error_write_i,
  input  logic [15:0] i2c_error_addr_i,
  input  logic [31:0] i2c_error_wdata_i,
  input  logic [7:0] i2c_error_cause_i,

  input  logic safe_idle_i,
  input  logic transition_busy_i,
  input  logic event_busy_i,
  input  logic [13:0] event_id_i,
  input  logic [3:0] required_packet_mask_i,
  input  logic [3:0] completed_packet_mask_i,
  input  logic [3:0] required_reset_ack_mask_i,
  input  logic [3:0] observed_reset_ack_mask_i,
  input  logic event_rejected_not_ready_i,
  input  logic snapshot_valid_i,
  input  logic snapshot_busy_i,
  input  logic snapshot_timeout_i,
  input  logic snapshot_overlap_i,
  input  logic snapshot_reject_i,
  input  logic snapshot_rearm_ready_i,
  input  logic [63:0] snapshot_R_i,
  input  logic [63:0] snapshot_Y_i,
  input  logic [63:0] snapshot_B_i,
  input  logic reset_busy_i,
  input  logic reset_done_i,
  input  logic reset_disabled_i,
  input  logic [2:0] tdc_ready_i,
  input  logic [2:0] tdc_busy_i,
  input  logic [2:0] tdc_fifo_full_i,
  input  logic [2:0] tdc_stop_armed_i,
  input  logic [2:0] tdc_packet_active_i,
  input  logic [2:0] tdc_packet_pending_i,
  input  logic position_packet_pending_i,
  input  logic position_packet_busy_i,
  input  logic position_snapshot_captured_i,
  input  logic matrix_cfg_busy_i,
  input  logic matrix_cfg_done_i,
  input  logic matrix_cfg_error_i,
  input  logic [3:0] matrix_cfg_last_error_i,
  input  logic [63:0] matrix_cfg_rdata_i,
  input  logic matrix_cfg_readback_valid_i,
  input  logic matrix_cfg_valid_i,
  input  logic bundle_busy_i,
  input  logic bundle_idle_i,
  input  logic ddr_empty_i,
  input  logic ddr_busy_i,
  input  logic ddr_pair_valid_i,
  input  logic ddr_padded_i,
  input  logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level_i,
  input  logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words_i,
  input  logic output_fifo_empty_i,
  input  logic output_fifo_full_i,
  input  logic output_fifo_almost_full_i,
  input  logic output_fifo_overflow_i,
  input  logic bundle_missing_source_i,
  input  logic position_packet_drop_i,
  input  logic pll_lock_i,

  output logic global_enable_o,
  output spadmic_pkg::spadmic_operating_mode_e requested_mode_o,
  output spadmic_pkg::spadmic_operating_mode_e active_mode_o,
  output logic [2:0] requested_axis_mask_o,
  output logic [2:0] active_axis_mask_o,
  output logic auto_reset_enable_o,
  output logic [15:0] settle_cycles_o,
  output logic [15:0] watchdog_cycles_o,
  output logic [15:0] reset_width_o,
  output logic snapshot_clear_o,
  output logic [mptdc_pkg::MAX_HITS_W-1:0] tdc_max_hits_o,
  output logic [7:0] tdc_ro_slow_code_o,
  output logic [7:0] tdc_ro_fast_code_o,
  output logic tdc_soft_reset_o,
  output logic tdc_fifo_clr_o,
  output logic [2:0] calib_axis_mask_o,
  output spadmic_pkg::spadmic_pos_mode_e position_mode_o,
  output logic [spadmic_pkg::SPADMIC_LINE_COUNT_W-1:0] position_gap_threshold_o,
  output logic [spadmic_pkg::SPADMIC_LINE_COUNT_W-1:0] position_min_cluster_span_o,
  output logic [7:0] pll_fint_sel_o,
  output logic [4:0] pll_ro_sw_o,
  output logic pll_sel_pulse_pfd_o,
  output logic pll_enable_div_o,
  output logic pll_sel_40m_o,
  output logic clk_160m_ext_select_o,
  output logic [3:0] slvs_s_drv_o,
  output logic slvs_en_vref_ext_o,
  output logic slvs_en_drv_o,
  output logic slvs_vref_adj_b_o,
  output logic slvs_en_vref_400mv_o,
  output logic slvs_en_ref_drv_b_o,
  output logic [3:0] rx_s_rx_o,
  output logic rx_en_rx_o,
  output logic rx_en_term_o,
  output logic matrix_cfg_cmd_start_o,
  output logic [2:0] matrix_cfg_cmd_op_o,
  output logic [5:0] matrix_cfg_col_idx_o,
  output logic [63:0] matrix_cfg_wdata_o,
  output logic cfg_accept_o
);
  import spadmic_pkg::*;
  import spadmic_csr_map_pkg::*;

  logic [9:0] bank_req_valid;
  logic [9:0] bank_rsp_valid;
  logic [9:0][31:0] bank_rsp_rdata;
  logic [9:0] bank_rsp_err;
  logic [9:0][7:0] bank_rsp_cause;
  logic router_error_event;
  logic router_error_write;
  logic [15:0] router_error_addr;
  logic [31:0] router_error_wdata;
  logic [7:0] router_error_cause;
  logic combined_error_event;
  logic combined_error_write;
  logic [15:0] combined_error_addr;
  logic [31:0] combined_error_wdata;
  logic [7:0] combined_error_cause;
  logic clear_error_counters;
  logic [2:0] tdc_fault;
  logic position_fault;
  logic event_fault;
  logic matrix_fault;
  logic tx_fault;
  logic pll_fault;
  logic system_fault;
  logic [6:0] page_fault_summary;
  wire config_safe = safe_idle_i && !global_enable_o;

  assign combined_error_event = i2c_error_event_i | router_error_event;
  assign combined_error_write = i2c_error_event_i ? i2c_error_write_i : router_error_write;
  assign combined_error_addr = i2c_error_event_i ? i2c_error_addr_i : router_error_addr;
  assign combined_error_wdata = i2c_error_event_i ? i2c_error_wdata_i : router_error_wdata;
  assign combined_error_cause = i2c_error_event_i ? i2c_error_cause_i : router_error_cause;
  assign page_fault_summary = {pll_fault, tx_fault, matrix_fault, event_fault,
                               position_fault, |tdc_fault, 1'b0};

  spadmic_csr_router u_router (
    .clk_sys(clk_sys), .rst_n(rst_n),
    .csr_valid_i(csr_valid_i), .csr_write_i(csr_write_i),
    .csr_addr_i(csr_addr_i), .csr_wdata_i(csr_wdata_i),
    .csr_ready_o(csr_ready_o), .csr_rvalid_o(csr_rvalid_o),
    .csr_rdata_o(csr_rdata_o), .csr_err_o(csr_err_o),
    .bank_req_valid_o(bank_req_valid), .bank_rsp_valid_i(bank_rsp_valid),
    .bank_rsp_rdata_i(bank_rsp_rdata), .bank_rsp_err_i(bank_rsp_err),
    .bank_rsp_cause_i(bank_rsp_cause),
    .access_error_event_o(router_error_event),
    .access_error_write_o(router_error_write),
    .access_error_addr_o(router_error_addr),
    .access_error_wdata_o(router_error_wdata),
    .access_error_cause_o(router_error_cause)
  );

  spadmic_csr_system_bank u_system_bank (
    .clk_sys(clk_sys), .rst_n(rst_n), .req_valid_i(bank_req_valid[0]),
    .req_write_i(csr_write_i), .req_addr_i(csr_addr_i), .req_wdata_i(csr_wdata_i),
    .safe_idle_i(safe_idle_i && !transition_busy_i), .reset_width_i(reset_width_o),
    .page_fault_summary_i(page_fault_summary),
    .access_error_event_i(combined_error_event),
    .access_error_write_i(combined_error_write), .access_error_addr_i(combined_error_addr),
    .access_error_wdata_i(combined_error_wdata), .access_error_cause_i(combined_error_cause),
    .global_enable_o(global_enable_o), .requested_mode_o(requested_mode_o),
    .active_mode_o(active_mode_o), .requested_axis_mask_o(requested_axis_mask_o),
    .active_axis_mask_o(active_axis_mask_o), .auto_reset_enable_o(auto_reset_enable_o),
    .tdc_max_hits_o(tdc_max_hits_o), .tdc_ro_slow_code_o(tdc_ro_slow_code_o),
    .tdc_ro_fast_code_o(tdc_ro_fast_code_o), .tdc_soft_reset_o(tdc_soft_reset_o),
    .tdc_fifo_clr_o(tdc_fifo_clr_o), .calib_axis_mask_o(calib_axis_mask_o),
    .clear_error_counters_o(clear_error_counters), .cfg_accept_o(cfg_accept_o),
    .fault_summary_o(system_fault), .rsp_valid_o(bank_rsp_valid[0]),
    .rsp_rdata_o(bank_rsp_rdata[0]), .rsp_err_o(bank_rsp_err[0]),
    .rsp_cause_o(bank_rsp_cause[0])
  );

  for (genvar axis = 0; axis < 3; axis++) begin : g_tdc_bank
    spadmic_csr_tdc_bank #(.PAGE(4'(axis + 1))) u_tdc_bank (
      .clk_sys(clk_sys), .rst_n(rst_n), .req_valid_i(bank_req_valid[axis+1]),
      .req_write_i(csr_write_i), .req_addr_i(csr_addr_i), .req_wdata_i(csr_wdata_i),
      .clear_error_counters_i(clear_error_counters), .ready_i(tdc_ready_i[axis]),
      .busy_i(tdc_busy_i[axis]), .fifo_full_i(tdc_fifo_full_i[axis]),
      .stop_armed_i(tdc_stop_armed_i[axis]), .packet_active_i(tdc_packet_active_i[axis]),
      .packet_pending_i(tdc_packet_pending_i[axis]), .fault_summary_o(tdc_fault[axis]),
      .rsp_valid_o(bank_rsp_valid[axis+1]), .rsp_rdata_o(bank_rsp_rdata[axis+1]),
      .rsp_err_o(bank_rsp_err[axis+1]), .rsp_cause_o(bank_rsp_cause[axis+1])
    );
  end

  spadmic_csr_position_bank u_position_bank (
    .clk_sys(clk_sys), .rst_n(rst_n), .req_valid_i(bank_req_valid[4]),
    .req_write_i(csr_write_i), .req_addr_i(csr_addr_i), .req_wdata_i(csr_wdata_i),
    .config_safe_i(config_safe), .clear_error_counters_i(clear_error_counters),
    .packet_pending_i(position_packet_pending_i), .packet_busy_i(position_packet_busy_i),
    .snapshot_captured_i(position_snapshot_captured_i), .packet_drop_i(position_packet_drop_i),
    .position_mode_o(position_mode_o), .gap_threshold_o(position_gap_threshold_o),
    .min_cluster_span_o(position_min_cluster_span_o), .fault_summary_o(position_fault),
    .rsp_valid_o(bank_rsp_valid[4]), .rsp_rdata_o(bank_rsp_rdata[4]),
    .rsp_err_o(bank_rsp_err[4]), .rsp_cause_o(bank_rsp_cause[4])
  );

  spadmic_csr_event_bank u_event_bank (
    .clk_sys(clk_sys), .rst_n(rst_n), .req_valid_i(bank_req_valid[5]),
    .req_write_i(csr_write_i), .req_addr_i(csr_addr_i), .req_wdata_i(csr_wdata_i),
    .config_safe_i(config_safe), .clear_error_counters_i(clear_error_counters),
    .event_busy_i(event_busy_i), .event_id_i(event_id_i),
    .required_packet_mask_i(required_packet_mask_i), .completed_packet_mask_i(completed_packet_mask_i),
    .required_reset_ack_mask_i(required_reset_ack_mask_i),
    .observed_reset_ack_mask_i(observed_reset_ack_mask_i),
    .event_reject_i(event_rejected_not_ready_i), .snapshot_valid_i(snapshot_valid_i),
    .snapshot_busy_i(snapshot_busy_i), .snapshot_timeout_i(snapshot_timeout_i),
    .snapshot_overlap_i(snapshot_overlap_i), .snapshot_reject_i(snapshot_reject_i),
    .snapshot_rearm_ready_i(snapshot_rearm_ready_i), .snapshot_R_i(snapshot_R_i),
    .snapshot_Y_i(snapshot_Y_i), .snapshot_B_i(snapshot_B_i),
    .reset_busy_i(reset_busy_i), .reset_done_i(reset_done_i),
    .reset_disabled_i(reset_disabled_i), .settle_cycles_o(settle_cycles_o),
    .watchdog_cycles_o(watchdog_cycles_o), .reset_width_o(reset_width_o),
    .snapshot_clear_o(snapshot_clear_o), .fault_summary_o(event_fault),
    .rsp_valid_o(bank_rsp_valid[5]), .rsp_rdata_o(bank_rsp_rdata[5]),
    .rsp_err_o(bank_rsp_err[5]), .rsp_cause_o(bank_rsp_cause[5])
  );

  spadmic_csr_matrix_bank u_matrix_bank (
    .clk_sys(clk_sys), .rst_n(rst_n), .req_valid_i(bank_req_valid[6]),
    .req_write_i(csr_write_i), .req_addr_i(csr_addr_i), .req_wdata_i(csr_wdata_i),
    .config_safe_i(config_safe), .clear_error_counters_i(clear_error_counters),
    .cfg_busy_i(matrix_cfg_busy_i), .cfg_done_i(matrix_cfg_done_i),
    .cfg_error_i(matrix_cfg_error_i), .cfg_last_error_i(matrix_cfg_last_error_i),
    .cfg_rdata_i(matrix_cfg_rdata_i), .cfg_readback_valid_i(matrix_cfg_readback_valid_i),
    .cfg_valid_i(matrix_cfg_valid_i), .cfg_cmd_start_o(matrix_cfg_cmd_start_o),
    .cfg_cmd_op_o(matrix_cfg_cmd_op_o), .cfg_col_idx_o(matrix_cfg_col_idx_o),
    .cfg_wdata_o(matrix_cfg_wdata_o), .fault_summary_o(matrix_fault),
    .rsp_valid_o(bank_rsp_valid[6]), .rsp_rdata_o(bank_rsp_rdata[6]),
    .rsp_err_o(bank_rsp_err[6]), .rsp_cause_o(bank_rsp_cause[6])
  );

  spadmic_csr_tx_bank u_tx_bank (
    .clk_sys(clk_sys), .rst_n(rst_n), .req_valid_i(bank_req_valid[7]),
    .req_write_i(csr_write_i), .req_addr_i(csr_addr_i), .req_wdata_i(csr_wdata_i),
    .clear_error_counters_i(clear_error_counters), .bundle_busy_i(bundle_busy_i),
    .bundle_idle_i(bundle_idle_i), .bundle_missing_source_i(bundle_missing_source_i),
    .ddr_empty_i(ddr_empty_i), .ddr_busy_i(ddr_busy_i), .ddr_pair_valid_i(ddr_pair_valid_i),
    .ddr_padded_i(ddr_padded_i), .fifo_level_i(output_fifo_level_i),
    .fifo_free_i(output_fifo_free_words_i), .fifo_empty_i(output_fifo_empty_i),
    .fifo_full_i(output_fifo_full_i), .fifo_almost_full_i(output_fifo_almost_full_i),
    .fifo_overflow_i(output_fifo_overflow_i), .fault_summary_o(tx_fault),
    .rsp_valid_o(bank_rsp_valid[7]), .rsp_rdata_o(bank_rsp_rdata[7]),
    .rsp_err_o(bank_rsp_err[7]), .rsp_cause_o(bank_rsp_cause[7])
  );

  spadmic_csr_pll_bank u_pll_bank (
    .clk_sys(clk_sys), .rst_n(rst_n), .req_valid_i(bank_req_valid[8]),
    .req_write_i(csr_write_i), .req_addr_i(csr_addr_i), .req_wdata_i(csr_wdata_i),
    .config_safe_i(config_safe), .clear_error_counters_i(clear_error_counters),
    .pll_lock_i(pll_lock_i), .pll_fint_sel_o(pll_fint_sel_o), .pll_ro_sw_o(pll_ro_sw_o),
    .pll_sel_pulse_pfd_o(pll_sel_pulse_pfd_o), .pll_enable_div_o(pll_enable_div_o),
    .pll_sel_40m_o(pll_sel_40m_o), .clk_160m_ext_select_o(clk_160m_ext_select_o),
    .fault_summary_o(pll_fault), .rsp_valid_o(bank_rsp_valid[8]),
    .rsp_rdata_o(bank_rsp_rdata[8]), .rsp_err_o(bank_rsp_err[8]),
    .rsp_cause_o(bank_rsp_cause[8])
  );

  spadmic_csr_analog_bank u_analog_bank (
    .clk_sys(clk_sys), .rst_n(rst_n), .req_valid_i(bank_req_valid[9]),
    .req_write_i(csr_write_i), .req_addr_i(csr_addr_i), .req_wdata_i(csr_wdata_i),
    .config_safe_i(config_safe), .slvs_s_drv_o(slvs_s_drv_o),
    .slvs_en_vref_ext_o(slvs_en_vref_ext_o), .slvs_en_drv_o(slvs_en_drv_o),
    .slvs_vref_adj_b_o(slvs_vref_adj_b_o), .slvs_en_vref_400mv_o(slvs_en_vref_400mv_o),
    .slvs_en_ref_drv_b_o(slvs_en_ref_drv_b_o), .rx_s_rx_o(rx_s_rx_o),
    .rx_en_rx_o(rx_en_rx_o), .rx_en_term_o(rx_en_term_o),
    .rsp_valid_o(bank_rsp_valid[9]), .rsp_rdata_o(bank_rsp_rdata[9]),
    .rsp_err_o(bank_rsp_err[9]), .rsp_cause_o(bank_rsp_cause[9])
  );

  wire unused_system_fault = system_fault;
endmodule

`default_nettype wire
