// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_top_v1.sv
// Purpose  : Chip-level shell integrating I2C control, three TDC axes,
//            position capture, shared TDC readout, and the shared chip TX path.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_top_v1 (
  input  wire                                clk_sys,
  input  wire                                clk_ref_40m,
  input  wire                                async_rst_n,

  input  wire                                i2c_scl_i,
  input  wire                                i2c_sda_i,
  output wire                                i2c_sda_oe_o,

  input  wire                                spad_x_event_async_i,
  input  wire                                spad_y_event_async_i,
  input  wire                                spad_z_event_async_i,
  input  wire                                cal_x_start_async_i,
  input  wire                                cal_x_stop_async_i,
  input  wire                                cal_y_start_async_i,
  input  wire                                cal_y_stop_async_i,
  input  wire                                cal_z_start_async_i,
  input  wire                                cal_z_stop_async_i,
  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] x_lines_i,
  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] y_lines_i,
  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] z_lines_i,

  output wire                                chip_tx_clk_o,
  output wire                                chip_tx_valid_o,
  output wire [spadmic_pkg::SPADMIC_TX_PHY_W-1:0] chip_tx_data_o,
  output wire                                spad_matrix_rst_o,

  output wire [2:0]                          tdc_stop_armed_o,
  output wire                                tdc_shared_busy_o,
  output wire                                position_busy_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  wire rst_sys_n;

  wire i2c_cmd_valid;
  wire i2c_cmd_write;
  wire [SPADMIC_CSR_ADDR_W-1:0] i2c_cmd_addr;
  wire [SPADMIC_CSR_DATA_W-1:0] i2c_cmd_wdata;
  wire i2c_cmd_ready;
  wire i2c_rsp_valid;
  wire [SPADMIC_CSR_DATA_W-1:0] i2c_rsp_rdata;
  wire i2c_rsp_err;
  wire i2c_rsp_ready;

  wire csr_req_valid;
  wire csr_req_write;
  wire [SPADMIC_CSR_ADDR_W-1:0] csr_req_addr;
  wire [SPADMIC_CSR_DATA_W-1:0] csr_req_wdata;
  wire csr_req_ready;
  wire csr_rsp_valid;
  wire [SPADMIC_CSR_DATA_W-1:0] csr_rsp_rdata;
  wire csr_rsp_err;
  wire csr_rsp_ready;

  wire global_csr_valid;
  wire global_csr_write;
  wire [SPADMIC_CSR_ADDR_W-1:0] global_csr_addr;
  wire [SPADMIC_CSR_DATA_W-1:0] global_csr_wdata;
  wire global_csr_ready;
  wire global_csr_rvalid;
  wire [SPADMIC_CSR_DATA_W-1:0] global_csr_rdata;

  wire pos_csr_valid;
  wire pos_csr_write;
  wire [SPADMIC_CSR_ADDR_W-1:0] pos_csr_addr;
  wire [SPADMIC_CSR_DATA_W-1:0] pos_csr_wdata;
  wire pos_csr_ready;
  wire pos_csr_rvalid;
  wire [SPADMIC_CSR_DATA_W-1:0] pos_csr_rdata;

  wire x_csr_valid, x_csr_write, x_csr_ready, x_csr_rvalid;
  wire y_csr_valid, y_csr_write, y_csr_ready, y_csr_rvalid;
  wire z_csr_valid, z_csr_write, z_csr_ready, z_csr_rvalid;
  wire [CSR_ADDR_W-1:0] x_csr_addr, y_csr_addr, z_csr_addr;
  wire [CSR_DATA_W-1:0] x_csr_wdata, y_csr_wdata, z_csr_wdata;
  wire [CSR_DATA_W-1:0] x_csr_rdata, y_csr_rdata, z_csr_rdata;

  wire req_global_enable;
  wire [2:0] req_axis_enable;
  wire req_position_enable;
  spadmic_tx_sel_e req_shared_tx_sel;
  input_sel_e      req_tdc_input_sel;
  out_mode_e       req_tdc_out_mode;
  wire             global_cfg_update;
  wire             seq_cfg_accept;
  wire             seq_transition_busy;

  wire global_enable;
  wire [2:0] axis_enable;
  wire position_enable;
  spadmic_tx_sel_e shared_tx_sel;
  input_sel_e      tdc_input_sel;
  out_mode_e       tdc_out_mode;

  wire [2:0] axis_acq_valid;
  wire [ACQ_REC_W-1:0] axis_acq_data [3];
  wire [2:0] axis_acq_ready;
  wire [2:0] axis_fifo_full;
  wire [2:0] tdc_conv_pending;
  mptdc_acq_rec_t axis_acq_rec [3];

  wire tdc_tx_ready_mux;
  wire tdc_tx_valid_mux;
  wire [NARROW_W-1:0] tdc_tx_data_mux;
  wire pos_tx_ready_mux;
  wire pos_tx_valid_mux;
  wire [NARROW_W-1:0] pos_tx_data_mux;
  wire chip_tx_word_ready;
  wire chip_tx_word_valid;
  wire [NARROW_W-1:0] chip_tx_word_data;
  wire position_pkt_pending;
  wire position_drop_sticky;
  wire position_glitch_sticky;
  wire correlation_overflow_sticky;

  // System-reset entry for all clk_sys-domain glue.
  mptdc_reset_sync #(.STAGES(2)) u_rst_sync (
    .clk         (clk_sys),
    .async_rst_n (async_rst_n),
    .rst_n_o     (rst_sys_n)
  );

  // I2C front end and CSR transport into the local request/response bus.
  spadmic_i2c_slave u_i2c_slave (
    .clk_sys         (clk_sys),
    .rst_n           (rst_sys_n),
    .i2c_scl_i       (i2c_scl_i),
    .i2c_sda_i       (i2c_sda_i),
    .i2c_sda_oe_o    (i2c_sda_oe_o),
    .txn_valid_o     (i2c_cmd_valid),
    .txn_write_o     (i2c_cmd_write),
    .txn_addr_o      (i2c_cmd_addr),
    .txn_wdata_o     (i2c_cmd_wdata),
    .txn_ready_i     (i2c_cmd_ready),
    .txn_rsp_valid_i (i2c_rsp_valid),
    .txn_rsp_rdata_i (i2c_rsp_rdata),
    .txn_rsp_err_i   (i2c_rsp_err),
    .txn_rsp_ready_o (i2c_rsp_ready)
  );

  spadmic_i2c_csr_bridge u_i2c_bridge (
    .clk_sys         (clk_sys),
    .rst_n           (rst_sys_n),
    .i2c_cmd_valid_i (i2c_cmd_valid),
    .i2c_cmd_write_i (i2c_cmd_write),
    .i2c_cmd_addr_i  (i2c_cmd_addr),
    .i2c_cmd_wdata_i (i2c_cmd_wdata),
    .i2c_cmd_ready_o (i2c_cmd_ready),
    .i2c_rsp_valid_o (i2c_rsp_valid),
    .i2c_rsp_rdata_o (i2c_rsp_rdata),
    .i2c_rsp_err_o   (i2c_rsp_err),
    .i2c_rsp_ready_i (i2c_rsp_ready),
    .csr_req_valid_o (csr_req_valid),
    .csr_req_write_o (csr_req_write),
    .csr_req_addr_o  (csr_req_addr),
    .csr_req_wdata_o (csr_req_wdata),
    .csr_req_ready_i (csr_req_ready),
    .csr_rsp_valid_i (csr_rsp_valid),
    .csr_rsp_rdata_i (csr_rsp_rdata),
    .csr_rsp_err_i   (csr_rsp_err),
    .csr_rsp_ready_o (csr_rsp_ready)
  );

  spadmic_csr_decoder u_csr_decoder (
    .clk_sys            (clk_sys),
    .rst_n              (rst_sys_n),
    .csr_req_valid_i    (csr_req_valid),
    .csr_req_write_i    (csr_req_write),
    .csr_req_addr_i     (csr_req_addr),
    .csr_req_wdata_i    (csr_req_wdata),
    .csr_req_ready_o    (csr_req_ready),
    .csr_rsp_valid_o    (csr_rsp_valid),
    .csr_rsp_rdata_o    (csr_rsp_rdata),
    .csr_rsp_err_o      (csr_rsp_err),
    .csr_rsp_ready_i    (csr_rsp_ready),
    .global_csr_valid_o (global_csr_valid),
    .global_csr_write_o (global_csr_write),
    .global_csr_addr_o  (global_csr_addr),
    .global_csr_wdata_o (global_csr_wdata),
    .global_csr_ready_i (global_csr_ready),
    .global_csr_rvalid_i(global_csr_rvalid),
    .global_csr_rdata_i (global_csr_rdata),
    .pos_csr_valid_o    (pos_csr_valid),
    .pos_csr_write_o    (pos_csr_write),
    .pos_csr_addr_o     (pos_csr_addr),
    .pos_csr_wdata_o    (pos_csr_wdata),
    .pos_csr_ready_i    (pos_csr_ready),
    .pos_csr_rvalid_i   (pos_csr_rvalid),
    .pos_csr_rdata_i    (pos_csr_rdata),
    .x_csr_valid_o      (x_csr_valid),
    .x_csr_write_o      (x_csr_write),
    .x_csr_addr_o       (x_csr_addr),
    .x_csr_wdata_o      (x_csr_wdata),
    .x_csr_ready_i      (x_csr_ready),
    .x_csr_rvalid_i     (x_csr_rvalid),
    .x_csr_rdata_i      (x_csr_rdata),
    .y_csr_valid_o      (y_csr_valid),
    .y_csr_write_o      (y_csr_write),
    .y_csr_addr_o       (y_csr_addr),
    .y_csr_wdata_o      (y_csr_wdata),
    .y_csr_ready_i      (y_csr_ready),
    .y_csr_rvalid_i     (y_csr_rvalid),
    .y_csr_rdata_i      (y_csr_rdata),
    .z_csr_valid_o      (z_csr_valid),
    .z_csr_write_o      (z_csr_write),
    .z_csr_addr_o       (z_csr_addr),
    .z_csr_wdata_o      (z_csr_wdata),
    .z_csr_ready_i      (z_csr_ready),
    .z_csr_rvalid_i     (z_csr_rvalid),
    .z_csr_rdata_i      (z_csr_rdata)
  );

  spadmic_global_csr u_global_csr (
    .clk_sys           (clk_sys),
    .rst_n             (rst_sys_n),
    .csr_valid_i       (global_csr_valid),
    .csr_write_i       (global_csr_write),
    .csr_addr_i        (global_csr_addr),
    .csr_wdata_i       (global_csr_wdata),
    .csr_ready_o       (global_csr_ready),
    .csr_rvalid_o      (global_csr_rvalid),
    .csr_rdata_o       (global_csr_rdata),
    .tdc_tx_busy_i     (tdc_shared_busy_o),
    .tdc_pkt_pending_i (tdc_conv_pending),
    .tdc_pkt_full_i    (axis_fifo_full),
    .position_busy_i   (position_busy_o),
    .position_pending_i(position_pkt_pending),
    .position_drop_sticky_i(position_drop_sticky),
    .position_glitch_sticky_i(position_glitch_sticky),
    .correlation_overflow_i(correlation_overflow_sticky),
    .cfg_accept_i      (seq_cfg_accept),
    .transition_busy_i (seq_transition_busy),
    .active_global_enable_i(global_enable),
    .active_axis_enable_i(axis_enable),
    .active_position_enable_i(position_enable),
    .active_shared_tx_sel_i(shared_tx_sel),
    .active_tdc_input_sel_i(tdc_input_sel),
    .active_tdc_out_mode_i(tdc_out_mode),
    .req_global_enable_o(req_global_enable),
    .req_axis_enable_o  (req_axis_enable),
    .req_position_enable_o(req_position_enable),
    .req_shared_tx_sel_o(req_shared_tx_sel),
    .req_tdc_input_sel_o(req_tdc_input_sel),
    .req_tdc_out_mode_o (req_tdc_out_mode),
    .cfg_update_o       (global_cfg_update)
  );

  // The sequencer owns the active image; the CSR block only stores requests.
  spadmic_top_sequencer u_top_sequencer (
    .clk_sys             (clk_sys),
    .rst_n               (rst_sys_n),
    .cfg_update_i        (global_cfg_update),
    .req_global_enable_i (req_global_enable),
    .req_axis_enable_i   (req_axis_enable),
    .req_position_enable_i(req_position_enable),
    .req_shared_tx_sel_i (req_shared_tx_sel),
    .req_tdc_input_sel_i (req_tdc_input_sel),
    .req_tdc_out_mode_i  (req_tdc_out_mode),
    .tdc_tx_busy_i       (tdc_shared_busy_o),
    .tdc_pkt_pending_i   (tdc_conv_pending),
    .position_busy_i     (position_busy_o),
    .position_pending_i  (position_pkt_pending),
    .cfg_accept_o        (seq_cfg_accept),
    .transition_busy_o   (seq_transition_busy),
    .active_global_enable_o(global_enable),
    .active_axis_enable_o(axis_enable),
    .active_position_enable_o(position_enable),
    .active_shared_tx_sel_o(shared_tx_sel),
    .active_tdc_input_sel_o(tdc_input_sel),
    .active_tdc_out_mode_o(tdc_out_mode)
  );

  // Per-axis wrappers preserve the existing MPTDC kernels and export acquisition
  // records into the shared readout path.
  spadmic_tdc_axis_wrapper u_tdc_x (
    .clk_sys          (clk_sys),
    .clk_ref_40m      (clk_ref_40m),
    .async_rst_n      (async_rst_n),
    .global_enable_i  (global_enable & (shared_tx_sel == SPADMIC_TX_TDC)),
    .axis_enable_i    (axis_enable[0]),
    .spad_event_async_i(spad_x_event_async_i),
    .cal_start_async_i(cal_x_start_async_i),
    .cal_stop_async_i (cal_x_stop_async_i),
    .input_sel_override_i(tdc_input_sel),
    .out_mode_override_i(tdc_out_mode),
    .csr_valid_i      (x_csr_valid),
    .csr_write_i      (x_csr_write),
    .csr_addr_i       (x_csr_addr),
    .csr_wdata_i      (x_csr_wdata),
    .csr_ready_o      (x_csr_ready),
    .csr_rvalid_o     (x_csr_rvalid),
    .csr_rdata_o      (x_csr_rdata),
    .acq_ready_i      (axis_acq_ready[0]),
    .acq_valid_o      (axis_acq_valid[0]),
    .acq_data_o       (axis_acq_data[0]),
    .fifo_full_o      (axis_fifo_full[0]),
    .stop_armed_o     (tdc_stop_armed_o[0])
  );

  spadmic_tdc_axis_wrapper u_tdc_y (
    .clk_sys          (clk_sys),
    .clk_ref_40m      (clk_ref_40m),
    .async_rst_n      (async_rst_n),
    .global_enable_i  (global_enable & (shared_tx_sel == SPADMIC_TX_TDC)),
    .axis_enable_i    (axis_enable[1]),
    .spad_event_async_i(spad_y_event_async_i),
    .cal_start_async_i(cal_y_start_async_i),
    .cal_stop_async_i (cal_y_stop_async_i),
    .input_sel_override_i(tdc_input_sel),
    .out_mode_override_i(tdc_out_mode),
    .csr_valid_i      (y_csr_valid),
    .csr_write_i      (y_csr_write),
    .csr_addr_i       (y_csr_addr),
    .csr_wdata_i      (y_csr_wdata),
    .csr_ready_o      (y_csr_ready),
    .csr_rvalid_o     (y_csr_rvalid),
    .csr_rdata_o      (y_csr_rdata),
    .acq_ready_i      (axis_acq_ready[1]),
    .acq_valid_o      (axis_acq_valid[1]),
    .acq_data_o       (axis_acq_data[1]),
    .fifo_full_o      (axis_fifo_full[1]),
    .stop_armed_o     (tdc_stop_armed_o[1])
  );

  spadmic_tdc_axis_wrapper u_tdc_z (
    .clk_sys          (clk_sys),
    .clk_ref_40m      (clk_ref_40m),
    .async_rst_n      (async_rst_n),
    .global_enable_i  (global_enable & (shared_tx_sel == SPADMIC_TX_TDC)),
    .axis_enable_i    (axis_enable[2]),
    .spad_event_async_i(spad_z_event_async_i),
    .cal_start_async_i(cal_z_start_async_i),
    .cal_stop_async_i (cal_z_stop_async_i),
    .input_sel_override_i(tdc_input_sel),
    .out_mode_override_i(tdc_out_mode),
    .csr_valid_i      (z_csr_valid),
    .csr_write_i      (z_csr_write),
    .csr_addr_i       (z_csr_addr),
    .csr_wdata_i      (z_csr_wdata),
    .csr_ready_o      (z_csr_ready),
    .csr_rvalid_o     (z_csr_rvalid),
    .csr_rdata_o      (z_csr_rdata),
    .acq_ready_i      (axis_acq_ready[2]),
    .acq_valid_o      (axis_acq_valid[2]),
    .acq_data_o       (axis_acq_data[2]),
    .fifo_full_o      (axis_fifo_full[2]),
    .stop_armed_o     (tdc_stop_armed_o[2])
  );

  assign axis_acq_rec[0] = axis_acq_data[0];
  assign axis_acq_rec[1] = axis_acq_data[1];
  assign axis_acq_rec[2] = axis_acq_data[2];
  assign tdc_conv_pending[0] = axis_acq_valid[0] & (axis_acq_rec[0].kind == ACQ_REC_META);
  assign tdc_conv_pending[1] = axis_acq_valid[1] & (axis_acq_rec[1].kind == ACQ_REC_META);
  assign tdc_conv_pending[2] = axis_acq_valid[2] & (axis_acq_rec[2].kind == ACQ_REC_META);

  // Shared TDC serializer keeps packets atomic by granting only on META records.
  spadmic_tdc_shared_readout u_tdc_shared_readout (
    .clk_sys       (clk_sys),
    .rst_n         (rst_sys_n),
    .acq_valid_i   (axis_acq_valid),
    .acq_data_i    (axis_acq_data),
    .acq_ready_o   (axis_acq_ready),
    .out_mode_i    (tdc_out_mode),
    .shared_ready_i(tdc_tx_ready_mux),
    .shared_valid_o(tdc_tx_valid_mux),
    .shared_data_o (tdc_tx_data_mux),
    .busy_o        (tdc_shared_busy_o),
    .packet_src_o  (/* unused */)
  );

  // Position capture is packetized locally, then muxed onto the shared chip TX.
  spadmic_position_block u_position (
    .clk_sys        (clk_sys),
    .rst_n          (rst_sys_n),
    .global_enable_i(global_enable & position_enable),
    .x_lines_i      (x_lines_i),
    .y_lines_i      (y_lines_i),
    .z_lines_i      (z_lines_i),
    .csr_valid_i    (pos_csr_valid),
    .csr_write_i    (pos_csr_write),
    .csr_addr_i     (pos_csr_addr),
    .csr_wdata_i    (pos_csr_wdata),
    .csr_ready_o    (pos_csr_ready),
    .csr_rvalid_o   (pos_csr_rvalid),
    .csr_rdata_o    (pos_csr_rdata),
    .pos_ready_i    (pos_tx_ready_mux),
    .pos_valid_o    (pos_tx_valid_mux),
    .pos_data_o     (pos_tx_data_mux),
    .busy_o         (position_busy_o),
    .packet_pending_o(position_pkt_pending),
    .drop_sticky_o  (position_drop_sticky),
    .glitch_reject_sticky_o(position_glitch_sticky),
    .spad_matrix_rst_o(spad_matrix_rst_o)
  );

  // One physical bus is exposed at the chip boundary. TDC-only, position-only,
  // and correlated both-active export are derived from the committed control
  // image without changing the external CSR width.
  spadmic_correlated_tx u_correlated_tx (
    .clk_sys       (clk_sys),
    .rst_n         (rst_sys_n),
    .tx_sel_i      (shared_tx_sel),
    .axis_enable_i (axis_enable),
    .position_enable_i(position_enable),
    .tdc_valid_i   (tdc_tx_valid_mux),
    .tdc_data_i    (tdc_tx_data_mux),
    .tdc_ready_o   (tdc_tx_ready_mux),
    .pos_valid_i   (pos_tx_valid_mux),
    .pos_data_i    (pos_tx_data_mux),
    .pos_ready_o   (pos_tx_ready_mux),
    .shared_ready_i(chip_tx_word_ready),
    .shared_valid_o(chip_tx_word_valid),
    .shared_data_o (chip_tx_word_data),
    .correlation_overflow_o(correlation_overflow_sticky)
  );

  // The logical correlated packet stream is repacked onto the silicon-facing DDR
  // interface here. All elasticity stays on-chip; the forwarded clock is the
  // physical receiver timing reference.
  spadmic_ddr_tx u_ddr_tx (
    .clk_sys         (clk_sys),
    .rst_n           (rst_sys_n),
    .word_valid_i    (chip_tx_word_valid),
    .word_data_i     (chip_tx_word_data),
    .word_ready_o    (chip_tx_word_ready),
    .chip_tx_clk_o   (chip_tx_clk_o),
    .chip_tx_valid_o (chip_tx_valid_o),
    .chip_tx_data_o  (chip_tx_data_o)
  );

endmodule

`default_nettype wire
