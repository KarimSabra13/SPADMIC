// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_top_matrix_v1.sv
// Purpose  : Phase 2/3 matrix-top shell with final matrix, CSR/I2C, and DDR16
//            boundary ports. MPTDC/position packet integration remains Phase 4.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_top_matrix_v1 (
  input  wire                                clk_sys,
  input  wire                                clk_ref_40m,
  input  wire                                clk_cfg_40m,
  input  wire                                async_rst_n,

  input  wire                                i2c_rst_i,
  input  wire                                i2c_scl_i,
  input  wire                                i2c_sda_i,
  output wire                                i2c_sda_oe_o,

  input  wire                                pll_lock_i,
  output wire [7:0]                          pll_fint_sel_o,
  output wire [4:0]                          pll_ro_sw_o,
  output wire                                pll_sel_pulse_pfd_o,
  output wire                                pll_enable_div_o,
  output wire                                pll_sel_40m_o,
  output wire                                clk_160m_ext_select_o,
  output wire [3:0]                          slvs_s_drv_o,
  output wire                                slvs_en_vref_ext_o,
  output wire                                slvs_en_drv_o,
  output wire                                slvs_vref_adj_b_o,
  output wire                                slvs_en_vref_400mv_o,
  output wire                                slvs_en_ref_drv_b_o,
  output wire [3:0]                          rx_s_rx_o,
  output wire                                rx_en_rx_o,
  output wire                                rx_en_term_o,

  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] R_i,
  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] Y_i,
  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] B_i,

  output wire [spadmic_pkg::SPADMIC_LINE_W-1:0] Rz_o,
  output wire [spadmic_pkg::SPADMIC_LINE_W-1:0] Yz_o,
  output wire [spadmic_pkg::SPADMIC_LINE_W-1:0] Bz_o,

  output wire [spadmic_pkg::SPADMIC_MATRIX_COLUMN_COUNT-1:0] matrix_din_o,
  output wire [spadmic_pkg::SPADMIC_MATRIX_COLUMN_COUNT-1:0] matrix_cin_o,
  input  wire [spadmic_pkg::SPADMIC_MATRIX_COLUMN_COUNT-1:0] matrix_dout_i,
  input  wire [spadmic_pkg::SPADMIC_MATRIX_COLUMN_COUNT-1:0] matrix_cout_i,

  input  wire                                cal_r_start_async_i,
  input  wire                                cal_r_stop_async_i,
  input  wire                                cal_y_start_async_i,
  input  wire                                cal_y_stop_async_i,
  input  wire                                cal_b_start_async_i,
  input  wire                                cal_b_stop_async_i,

  output wire [spadmic_pkg::SPADMIC_DDR16_PHY_W-1:0] ddr_data_l_o,
  output wire [spadmic_pkg::SPADMIC_DDR16_PHY_W-1:0] ddr_data_h_o,
  output wire                                ddr_pair_valid_o,
  output wire                                ddr_clk_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  wire rst_sys_n;
  wire rst_cfg_n;
  wire rst_i2c_n;
  wire i2c_async_rst_n;

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

  spadmic_operating_mode_e requested_mode;
  spadmic_operating_mode_e active_mode;
  wire global_enable;
  wire [2:0] requested_axis_mask;
  wire [2:0] active_axis_mask;
  wire auto_reset_enable;
  wire [15:0] settle_cycles;
  wire [15:0] watchdog_cycles;
  wire [15:0] reset_width;
  wire snapshot_clear_csr;
  wire [MAX_HITS_W-1:0] shared_tdc_max_hits;
  wire [7:0] shared_tdc_ro_slow_code;
  wire [7:0] shared_tdc_ro_fast_code;
  wire shared_tdc_soft_reset;
  wire shared_tdc_fifo_clr;
  wire [2:0] calib_axis_mask;
  spadmic_pos_mode_e position_mode;
  wire cfg_accept;

  wire r_matrix_event;
  wire y_matrix_event;
  wire b_matrix_event;
  wire matrix_activity;
  wire cal_activity;
  wire mode_uses_matrix;
  wire matrix_event_allowed;
  logic [2:0] snapshot_required_direction_mask;
  wire [2:0] matrix_event_vector;
  wire [2:0] cal_start_vector;

  wire snapshot_valid;
  wire [SPADMIC_LINE_W-1:0] snapshot_R;
  wire [SPADMIC_LINE_W-1:0] snapshot_Y;
  wire [SPADMIC_LINE_W-1:0] snapshot_B;
  wire snapshot_busy;
  wire snapshot_timeout;
  wire snapshot_overlap;
  wire snapshot_reject;
  wire snapshot_rearm_ready;

  wire reset_busy;
  wire reset_done;
  wire reset_disabled;

  wire event_open;
  wire [13:0] event_id;
  wire [3:0] required_packet_mask;
  wire [2:0] required_tdc_mask;
  wire [3:0] required_reset_ack_mask;
  wire [3:0] observed_reset_ack_mask;
  wire reset_start;
  wire bundle_start;
  wire event_accept_enable;
  wire event_rejected_not_ready;
  wire event_id_valid;
  wire event_busy;
  wire event_idle;
  wire [3:0] packet_pending_mask;
  wire [3:0] bundle_completed_packet_mask;
  wire [3:0] completed_packet_status_mask;

  wire mode_has_matrix_tdc;
  wire mode_has_tdc;
  wire mode_has_position_packet;
  wire [2:0] normal_tdc_required_mask;
  wire [2:0] tdc_resource_required_mask;
  wire [2:0] tdc_ready;
  wire [2:0] tdc_busy;
  wire [2:0] tdc_fifo_full;
  wire [2:0] tdc_stop_armed;
  wire [2:0] tdc_packet_active;
  wire [2:0] tdc_packet_pending;
  wire [2:0] tdc_pkt_valid;
  wire [2:0] tdc_pkt_ready;
  wire [2:0] tdc_pkt_sop;
  wire [2:0] tdc_pkt_eop;
  wire [NARROW_W-1:0] tdc_pkt_data [SPADMIC_AXIS_COUNT];
  logic [2:0] tdc_start_seen_q;
  logic [2:0] tdc_start_sync1_q;
  logic [2:0] tdc_start_sync2_q;
  wire [2:0] tdc_start_async_to_core;
  wire [2:0] tdc_axis_enable;
  wire [2:0] tdc_conv_arm;
  input_sel_e tdc_input_sel;
  wire [2:0] tdc_path_busy_mask;
  wire tdc_required_path_idle;
  wire active_position_path_idle;
  wire tdc_required_ready;
  wire tdc_required_fifo_ok;
  wire pre_event_resources_ready;
  wire output_path_idle;

  wire matrix_cfg_cmd_start;
  wire [2:0] matrix_cfg_cmd_op;
  wire [5:0] matrix_cfg_col_idx;
  wire [63:0] matrix_cfg_wdata;
  wire matrix_cfg_busy;
  wire matrix_cfg_done;
  wire matrix_cfg_error;
  wire [3:0] matrix_cfg_last_error;
  wire [63:0] matrix_cfg_rdata;
  wire matrix_cfg_readback_valid;
  wire matrix_cfg_valid;

  wire ddr_word_ready;
  wire ddr_busy;
  wire ddr_empty;
  wire ddr_padded;
  wire bundle_word_valid;
  wire bundle_word_ready;
  wire [NARROW_W-1:0] bundle_word_data;
  wire bundle_flush;
  wire output_fifo_push_valid;
  wire output_fifo_push_ready;
  wire [NARROW_W:0] output_fifo_push_data;
  wire output_fifo_pop_valid;
  wire output_fifo_pop_ready;
  wire output_fifo_pop_fire;
  wire [NARROW_W:0] output_fifo_pop_data;
  wire output_fifo_pop_is_flush;
  wire [SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level;
  wire [SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words;
  wire output_fifo_empty;
  wire output_fifo_full;
  wire output_fifo_almost_full;
  wire output_fifo_overflow;
  logic bundle_flush_pending_q;
  wire output_capacity_available;
  wire ddr_flush;
  wire ddr_word_valid;
  wire [NARROW_W-1:0] ddr_word_data;

  wire pos_pkt_valid;
  wire pos_pkt_ready;
  wire [NARROW_W-1:0] pos_pkt_data;
  wire pos_pkt_sop;
  wire pos_pkt_eop;
  wire pos_packet_pending;
  wire pos_packet_busy;
  wire pos_snapshot_captured;
  logic pos_snapshot_captured_seen_q;
  wire pos_packet_done;
  wire pos_packet_drop;
  logic pos_packet_started_q;
  wire pos_packet_start;
  wire [SPADMIC_LINE_COUNT_W-1:0] position_gap_threshold;
  wire [SPADMIC_LINE_COUNT_W-1:0] position_min_cluster_span;

  wire [SPADMIC_SRC_COUNT-1:0] src_valid;
  wire [SPADMIC_SRC_COUNT-1:0] src_ready;
  wire [NARROW_W-1:0] src_data [SPADMIC_SRC_COUNT];
  wire [SPADMIC_SRC_COUNT-1:0] src_sop;
  wire [SPADMIC_SRC_COUNT-1:0] src_eop;
  wire bundle_done;
  wire bundle_busy;
  wire bundle_idle;
  wire bundle_missing_source_error;

  wire safe_idle;
  wire reset_or_csr_snapshot_clear;

  assign mode_uses_matrix =
      (active_mode == SPADMIC_MODE_TDC_ONLY) ||
      (active_mode == SPADMIC_MODE_POSITION_ONLY) ||
      (active_mode == SPADMIC_MODE_BOTH);
  always_comb begin
    unique case (active_mode)
      SPADMIC_MODE_TDC_ONLY: begin
        snapshot_required_direction_mask = active_axis_mask;
      end
      SPADMIC_MODE_POSITION_ONLY,
      SPADMIC_MODE_BOTH: begin
        snapshot_required_direction_mask = 3'b111;
      end
      default: begin
        snapshot_required_direction_mask = 3'b000;
      end
    endcase
  end

  assign matrix_event_allowed = global_enable && mode_uses_matrix && !matrix_cfg_busy;
  assign matrix_event_vector = {b_matrix_event, y_matrix_event, r_matrix_event};
  assign matrix_activity = matrix_event_allowed &&
                           (|(matrix_event_vector & snapshot_required_direction_mask));
  assign cal_start_vector = {cal_b_start_async_i, cal_y_start_async_i, cal_r_start_async_i};
  assign cal_activity = global_enable &&
                        (active_mode == SPADMIC_MODE_CALIBRATION) &&
                        (|(cal_start_vector & active_axis_mask));

  assign mode_has_matrix_tdc =
      (active_mode == SPADMIC_MODE_TDC_ONLY) ||
      (active_mode == SPADMIC_MODE_BOTH);
  assign mode_has_tdc = mode_has_matrix_tdc ||
      (active_mode == SPADMIC_MODE_CALIBRATION);
  assign mode_has_position_packet =
      (active_mode == SPADMIC_MODE_POSITION_ONLY) ||
      (active_mode == SPADMIC_MODE_BOTH);
  assign normal_tdc_required_mask = mode_has_matrix_tdc ? active_axis_mask : 3'b000;
  assign tdc_resource_required_mask = mode_has_tdc ? active_axis_mask : 3'b000;
  assign tdc_required_ready =
      ((tdc_ready & tdc_resource_required_mask) == tdc_resource_required_mask);
  assign tdc_required_fifo_ok =
      ((~tdc_fifo_full & tdc_resource_required_mask) == tdc_resource_required_mask);
  assign tdc_path_busy_mask = tdc_busy | tdc_packet_active | tdc_packet_pending;
  assign tdc_required_path_idle =
      ((tdc_path_busy_mask & tdc_resource_required_mask) == 3'b000);
  assign active_position_path_idle =
      !mode_has_position_packet || (!pos_packet_busy && !pos_packet_pending);
  assign output_capacity_available =
      (output_fifo_free_words >=
       SPADMIC_OUTPUT_FIFO_LEVEL_W'(SPADMIC_OUTPUT_FIFO_RESERVE_ENTRIES));
  assign output_path_idle = bundle_idle && output_fifo_empty &&
                            !bundle_flush_pending_q &&
                            ddr_empty && !ddr_pair_valid_o;
  assign pre_event_resources_ready =
    event_idle && !snapshot_busy && !reset_busy && !matrix_cfg_busy &&
      output_capacity_available &&
      active_position_path_idle &&
      (!mode_has_tdc || (tdc_required_path_idle && tdc_required_ready &&
                         tdc_required_fifo_ok));
  assign packet_pending_mask = {
      pos_packet_pending,
      tdc_packet_pending
  };
  assign completed_packet_status_mask =
      packet_pending_mask | bundle_completed_packet_mask;
  assign safe_idle = event_idle && !snapshot_busy && !reset_busy &&
                     !matrix_cfg_busy && output_path_idle &&
                     (!mode_has_tdc || tdc_required_path_idle) &&
                     active_position_path_idle;
  assign reset_or_csr_snapshot_clear = snapshot_clear_csr || reset_done;

  assign tdc_input_sel =
      (active_mode == SPADMIC_MODE_CALIBRATION) ? INPUT_CAL : INPUT_SPAD;
  assign tdc_axis_enable =
      mode_has_tdc ? active_axis_mask : 3'b000;
  assign tdc_conv_arm = tdc_axis_enable;
  assign tdc_start_async_to_core[0] =
    r_matrix_event && normal_tdc_required_mask[0] &&
      !tdc_start_seen_q[0] &&
      ((event_idle && pre_event_resources_ready) ||
       (event_open && required_tdc_mask[0]));
  assign tdc_start_async_to_core[1] =
    y_matrix_event && normal_tdc_required_mask[1] &&
      !tdc_start_seen_q[1] &&
      ((event_idle && pre_event_resources_ready) ||
       (event_open && required_tdc_mask[1]));
  assign tdc_start_async_to_core[2] =
    b_matrix_event && normal_tdc_required_mask[2] &&
      !tdc_start_seen_q[2] &&
      ((event_idle && pre_event_resources_ready) ||
       (event_open && required_tdc_mask[2]));

  assign pos_packet_start =
      event_open && event_id_valid && required_packet_mask[3] &&
      snapshot_valid && !pos_packet_started_q && !pos_packet_busy &&
      !pos_packet_pending;
  assign position_gap_threshold = SPADMIC_LINE_COUNT_W'(2);
  assign position_min_cluster_span = SPADMIC_LINE_COUNT_W'(1);

  assign src_valid[TDC_ID_X] = tdc_pkt_valid[0];
  assign src_valid[TDC_ID_Y] = tdc_pkt_valid[1];
  assign src_valid[TDC_ID_Z] = tdc_pkt_valid[2];
  assign src_valid[SPADMIC_SRC_POSITION] = pos_pkt_valid;
  assign tdc_pkt_ready[0] = src_ready[TDC_ID_X];
  assign tdc_pkt_ready[1] = src_ready[TDC_ID_Y];
  assign tdc_pkt_ready[2] = src_ready[TDC_ID_Z];
  assign pos_pkt_ready = src_ready[SPADMIC_SRC_POSITION];
  assign bundle_word_ready = !bundle_flush_pending_q && output_fifo_push_ready;
  assign output_fifo_push_valid = bundle_flush_pending_q || bundle_word_valid;
  assign output_fifo_push_data =
      bundle_flush_pending_q ? {1'b1, {NARROW_W{1'b0}}} :
                               {1'b0, bundle_word_data};
  assign output_fifo_pop_is_flush = output_fifo_pop_data[NARROW_W];
  assign output_fifo_pop_fire = output_fifo_pop_valid && output_fifo_pop_ready;
  assign ddr_word_valid = output_fifo_pop_fire && !output_fifo_pop_is_flush;
  assign ddr_word_data = output_fifo_pop_data[NARROW_W-1:0];
  assign ddr_flush = output_fifo_pop_fire && output_fifo_pop_is_flush;
  assign output_fifo_pop_ready = output_fifo_pop_is_flush ? 1'b1 : ddr_word_ready;
  assign src_data[TDC_ID_X] = tdc_pkt_data[0];
  assign src_data[TDC_ID_Y] = tdc_pkt_data[1];
  assign src_data[TDC_ID_Z] = tdc_pkt_data[2];
  assign src_data[SPADMIC_SRC_POSITION] = pos_pkt_data;
  assign src_sop[TDC_ID_X] = tdc_pkt_sop[0];
  assign src_sop[TDC_ID_Y] = tdc_pkt_sop[1];
  assign src_sop[TDC_ID_Z] = tdc_pkt_sop[2];
  assign src_sop[SPADMIC_SRC_POSITION] = pos_pkt_sop;
  assign src_eop[TDC_ID_X] = tdc_pkt_eop[0];
  assign src_eop[TDC_ID_Y] = tdc_pkt_eop[1];
  assign src_eop[TDC_ID_Z] = tdc_pkt_eop[2];
  assign src_eop[SPADMIC_SRC_POSITION] = pos_pkt_eop;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      tdc_start_sync1_q <= '0;
      tdc_start_sync2_q <= '0;
      tdc_start_seen_q  <= '0;
    end else begin
      tdc_start_sync1_q <= tdc_start_async_to_core;
      tdc_start_sync2_q <= tdc_start_sync1_q;

      if (!event_open)
        tdc_start_seen_q <= '0;
      else
        tdc_start_seen_q <= tdc_start_seen_q | tdc_start_sync2_q;
    end
  end

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      bundle_flush_pending_q <= 1'b0;
    end else begin
      if (bundle_flush)
        bundle_flush_pending_q <= 1'b1;
      else if (bundle_flush_pending_q && output_fifo_push_ready)
        bundle_flush_pending_q <= 1'b0;
    end
  end

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      pos_packet_started_q <= 1'b0;
      pos_snapshot_captured_seen_q <= 1'b0;
    end else if (!event_open) begin
      pos_packet_started_q <= 1'b0;
      pos_snapshot_captured_seen_q <= 1'b0;
    end else if (pos_packet_start) begin
      pos_packet_started_q <= 1'b1;
      pos_snapshot_captured_seen_q <= 1'b0;
    end else if (pos_snapshot_captured) begin
      pos_snapshot_captured_seen_q <= 1'b1;
    end
  end

  mptdc_reset_sync #(.STAGES(2)) u_rst_sys_sync (
    .clk         (clk_sys),
    .async_rst_n (async_rst_n),
    .rst_n_o     (rst_sys_n)
  );

  mptdc_reset_sync #(.STAGES(2)) u_rst_cfg_sync (
    .clk         (clk_cfg_40m),
    .async_rst_n (async_rst_n),
    .rst_n_o     (rst_cfg_n)
  );

  assign i2c_async_rst_n = async_rst_n & ~i2c_rst_i;

  mptdc_reset_sync #(.STAGES(2)) u_rst_i2c_sync (
    .clk         (clk_sys),
    .async_rst_n (i2c_async_rst_n),
    .rst_n_o     (rst_i2c_n)
  );

  spadmic_i2c_slave u_i2c_slave (
    .clk_sys         (clk_sys),
    .rst_n           (rst_i2c_n),
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
    .rst_n           (rst_i2c_n),
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

  spadmic_matrix_top_csr u_matrix_top_csr (
    .clk_sys                     (clk_sys),
    .rst_n                       (rst_sys_n),
    .csr_valid_i                 (csr_req_valid),
    .csr_write_i                 (csr_req_write),
    .csr_addr_i                  (csr_req_addr),
    .csr_wdata_i                 (csr_req_wdata),
    .csr_ready_o                 (csr_req_ready),
    .csr_rvalid_o                (csr_rsp_valid),
    .csr_rdata_o                 (csr_rsp_rdata),
    .csr_err_o                   (csr_rsp_err),
    .safe_idle_i                 (safe_idle),
    .transition_busy_i           (1'b0),
    .event_busy_i                (event_busy),
    .event_id_i                  (event_id),
    .required_packet_mask_i      (required_packet_mask),
    .completed_packet_mask_i     (completed_packet_status_mask),
    .required_reset_ack_mask_i   (required_reset_ack_mask),
    .observed_reset_ack_mask_i   (observed_reset_ack_mask),
    .event_rejected_not_ready_i  (event_rejected_not_ready),
    .snapshot_valid_i            (snapshot_valid),
    .snapshot_busy_i             (snapshot_busy),
    .snapshot_timeout_i          (snapshot_timeout),
    .snapshot_overlap_i          (snapshot_overlap),
    .snapshot_reject_i           (snapshot_reject),
    .snapshot_rearm_ready_i      (snapshot_rearm_ready),
    .snapshot_R_i                (snapshot_R),
    .snapshot_Y_i                (snapshot_Y),
    .snapshot_B_i                (snapshot_B),
    .reset_busy_i                (reset_busy),
    .reset_done_i                (reset_done),
    .reset_disabled_i            (reset_disabled),
    .matrix_cfg_busy_i           (matrix_cfg_busy),
    .matrix_cfg_done_i           (matrix_cfg_done),
    .matrix_cfg_error_i          (matrix_cfg_error),
    .matrix_cfg_last_error_i     (matrix_cfg_last_error),
    .matrix_cfg_rdata_i          (matrix_cfg_rdata),
    .matrix_cfg_readback_valid_i (matrix_cfg_readback_valid),
    .matrix_cfg_valid_i          (matrix_cfg_valid),
    .ddr_empty_i                 (ddr_empty),
    .ddr_busy_i                  (ddr_busy),
    .ddr_pair_valid_i            (ddr_pair_valid_o),
    .ddr_padded_i                (ddr_padded),
    .output_fifo_level_i         (output_fifo_level),
    .output_fifo_free_words_i    (output_fifo_free_words),
    .output_fifo_empty_i         (output_fifo_empty),
    .output_fifo_full_i          (output_fifo_full),
    .output_fifo_almost_full_i   (output_fifo_almost_full),
    .output_fifo_overflow_i      (output_fifo_overflow),
    .bundle_missing_source_i     (bundle_missing_source_error),
    .position_packet_drop_i      (pos_packet_drop),
    .pll_lock_i                  (pll_lock_i),
    .global_enable_o             (global_enable),
    .requested_mode_o            (requested_mode),
    .active_mode_o               (active_mode),
    .requested_axis_mask_o       (requested_axis_mask),
    .active_axis_mask_o          (active_axis_mask),
    .auto_reset_enable_o         (auto_reset_enable),
    .settle_cycles_o             (settle_cycles),
    .watchdog_cycles_o           (watchdog_cycles),
    .reset_width_o               (reset_width),
    .snapshot_clear_o            (snapshot_clear_csr),
    .tdc_max_hits_o              (shared_tdc_max_hits),
    .tdc_ro_slow_code_o          (shared_tdc_ro_slow_code),
    .tdc_ro_fast_code_o          (shared_tdc_ro_fast_code),
    .tdc_soft_reset_o            (shared_tdc_soft_reset),
    .tdc_fifo_clr_o              (shared_tdc_fifo_clr),
    .calib_axis_mask_o           (calib_axis_mask),
    .position_mode_o             (position_mode),
    .pll_fint_sel_o              (pll_fint_sel_o),
    .pll_ro_sw_o                 (pll_ro_sw_o),
    .pll_sel_pulse_pfd_o         (pll_sel_pulse_pfd_o),
    .pll_enable_div_o            (pll_enable_div_o),
    .pll_sel_40m_o               (pll_sel_40m_o),
    .clk_160m_ext_select_o       (clk_160m_ext_select_o),
    .slvs_s_drv_o                (slvs_s_drv_o),
    .slvs_en_vref_ext_o          (slvs_en_vref_ext_o),
    .slvs_en_drv_o               (slvs_en_drv_o),
    .slvs_vref_adj_b_o           (slvs_vref_adj_b_o),
    .slvs_en_vref_400mv_o        (slvs_en_vref_400mv_o),
    .slvs_en_ref_drv_b_o         (slvs_en_ref_drv_b_o),
    .rx_s_rx_o                   (rx_s_rx_o),
    .rx_en_rx_o                  (rx_en_rx_o),
    .rx_en_term_o                (rx_en_term_o),
    .matrix_cfg_cmd_start_o      (matrix_cfg_cmd_start),
    .matrix_cfg_cmd_op_o         (matrix_cfg_cmd_op),
    .matrix_cfg_col_idx_o        (matrix_cfg_col_idx),
    .matrix_cfg_wdata_o          (matrix_cfg_wdata),
    .cfg_accept_o                (cfg_accept)
  );

  spadmic_matrix_or_tree #(.LINE_W(SPADMIC_LINE_W)) u_or_r (
    .lines_i (R_i),
    .event_o (r_matrix_event)
  );

  spadmic_matrix_or_tree #(.LINE_W(SPADMIC_LINE_W)) u_or_y (
    .lines_i (Y_i),
    .event_o (y_matrix_event)
  );

  spadmic_matrix_or_tree #(.LINE_W(SPADMIC_LINE_W)) u_or_b (
    .lines_i (B_i),
    .event_o (b_matrix_event)
  );

  spadmic_matrix_snapshot_frontend #(.LINE_W(SPADMIC_LINE_W)) u_snapshot (
    .clk_sys            (clk_sys),
    .rst_n              (rst_sys_n),
    .enable_i           (matrix_event_allowed),
    .clear_i            (reset_or_csr_snapshot_clear),
    .required_direction_mask_i(snapshot_required_direction_mask),
    .R_i                (R_i),
    .Y_i                (Y_i),
    .B_i                (B_i),
    .settle_cycles_i    (settle_cycles),
    .watchdog_cycles_i  (watchdog_cycles),
    .snapshot_valid_o   (snapshot_valid),
    .snapshot_R_o       (snapshot_R),
    .snapshot_Y_o       (snapshot_Y),
    .snapshot_B_o       (snapshot_B),
    .busy_o             (snapshot_busy),
    .timeout_o          (snapshot_timeout),
    .overlap_o          (snapshot_overlap),
    .reject_o           (snapshot_reject),
    .rearm_ready_o      (snapshot_rearm_ready)
  );

  spadmic_matrix_reset_ctrl #(.LINE_W(SPADMIC_LINE_W)) u_matrix_reset (
    .clk_sys        (clk_sys),
    .rst_n          (rst_sys_n),
    .enable_i       (auto_reset_enable),
    .start_i        (reset_start),
    .reset_width_i  (reset_width),
    .snapshot_R_i   (snapshot_R),
    .snapshot_Y_i   (snapshot_Y),
    .snapshot_B_i   (snapshot_B),
    .Rz_o           (Rz_o),
    .Yz_o           (Yz_o),
    .Bz_o           (Bz_o),
    .busy_o         (reset_busy),
    .done_o         (reset_done),
    .disabled_o     (reset_disabled)
  );

  spadmic_event_coordinator u_event_coordinator (
    .clk_sys                    (clk_sys),
    .rst_n                      (rst_sys_n),
    .active_mode_i              (active_mode),
    .global_enable_i            (global_enable),
    .active_axis_mask_i         (active_axis_mask),
    .matrix_activity_i          (matrix_activity),
    .cal_activity_i             (cal_activity),
    .pre_event_resources_ready_i(pre_event_resources_ready),
    .raw_snapshot_required_i    (1'b1),
    .auto_reset_enable_i        (auto_reset_enable),
    .snapshot_valid_i           (snapshot_valid),
    .position_snapshot_captured_i(pos_snapshot_captured_seen_q ||
                                  pos_snapshot_captured),
    .tdc_start_seen_i           (tdc_start_seen_q),
    .packet_pending_mask_i      (packet_pending_mask),
    .reset_done_i               (reset_done),
    .bundle_done_i              (bundle_done),
    .rearm_ready_i              (snapshot_rearm_ready),
    .event_open_o               (event_open),
    .event_id_o                 (event_id),
    .event_id_valid_o           (event_id_valid),
    .required_packet_mask_o     (required_packet_mask),
    .required_tdc_mask_o        (required_tdc_mask),
    .required_reset_ack_mask_o  (required_reset_ack_mask),
    .observed_reset_ack_mask_o  (observed_reset_ack_mask),
    .reset_start_o              (reset_start),
    .bundle_start_o             (bundle_start),
    .accept_enable_o            (event_accept_enable),
    .rejected_not_ready_o       (event_rejected_not_ready),
    .busy_o                     (event_busy),
    .idle_o                     (event_idle)
  );

  spadmic_tdc_axis_wrapper u_tdc_r (
    .clk_sys           (clk_sys),
    .clk_ref_40m       (clk_ref_40m),
    .async_rst_n       (async_rst_n),
    .global_enable_i   (global_enable && mode_has_tdc),
    .axis_enable_i     (tdc_axis_enable[0]),
    .spad_event_async_i(tdc_start_async_to_core[0]),
    .cal_start_async_i (cal_r_start_async_i),
    .cal_stop_async_i  (cal_r_stop_async_i),
    .input_sel_i       (tdc_input_sel),
    .conv_arm_i        (tdc_conv_arm[0]),
    .fifo_clr_i        (shared_tdc_fifo_clr),
    .soft_reset_i      (shared_tdc_soft_reset),
    .max_hits_i        (shared_tdc_max_hits),
    .ro_slow_code_i    (shared_tdc_ro_slow_code),
    .ro_fast_code_i    (shared_tdc_ro_fast_code),
    .pkt_valid_o       (tdc_pkt_valid[0]),
    .pkt_ready_i       (tdc_pkt_ready[0]),
    .pkt_data_o        (tdc_pkt_data[0]),
    .pkt_sop_o         (tdc_pkt_sop[0]),
    .pkt_eop_o         (tdc_pkt_eop[0]),
    .packet_active_o   (tdc_packet_active[0]),
    .packet_pending_o  (tdc_packet_pending[0]),
    .ready_o           (tdc_ready[0]),
    .busy_o            (tdc_busy[0]),
    .fifo_full_o       (tdc_fifo_full[0]),
    .stop_armed_o      (tdc_stop_armed[0])
  );

  spadmic_tdc_axis_wrapper u_tdc_y (
    .clk_sys           (clk_sys),
    .clk_ref_40m       (clk_ref_40m),
    .async_rst_n       (async_rst_n),
    .global_enable_i   (global_enable && mode_has_tdc),
    .axis_enable_i     (tdc_axis_enable[1]),
    .spad_event_async_i(tdc_start_async_to_core[1]),
    .cal_start_async_i (cal_y_start_async_i),
    .cal_stop_async_i  (cal_y_stop_async_i),
    .input_sel_i       (tdc_input_sel),
    .conv_arm_i        (tdc_conv_arm[1]),
    .fifo_clr_i        (shared_tdc_fifo_clr),
    .soft_reset_i      (shared_tdc_soft_reset),
    .max_hits_i        (shared_tdc_max_hits),
    .ro_slow_code_i    (shared_tdc_ro_slow_code),
    .ro_fast_code_i    (shared_tdc_ro_fast_code),
    .pkt_valid_o       (tdc_pkt_valid[1]),
    .pkt_ready_i       (tdc_pkt_ready[1]),
    .pkt_data_o        (tdc_pkt_data[1]),
    .pkt_sop_o         (tdc_pkt_sop[1]),
    .pkt_eop_o         (tdc_pkt_eop[1]),
    .packet_active_o   (tdc_packet_active[1]),
    .packet_pending_o  (tdc_packet_pending[1]),
    .ready_o           (tdc_ready[1]),
    .busy_o            (tdc_busy[1]),
    .fifo_full_o       (tdc_fifo_full[1]),
    .stop_armed_o      (tdc_stop_armed[1])
  );

  spadmic_tdc_axis_wrapper u_tdc_b (
    .clk_sys           (clk_sys),
    .clk_ref_40m       (clk_ref_40m),
    .async_rst_n       (async_rst_n),
    .global_enable_i   (global_enable && mode_has_tdc),
    .axis_enable_i     (tdc_axis_enable[2]),
    .spad_event_async_i(tdc_start_async_to_core[2]),
    .cal_start_async_i (cal_b_start_async_i),
    .cal_stop_async_i  (cal_b_stop_async_i),
    .input_sel_i       (tdc_input_sel),
    .conv_arm_i        (tdc_conv_arm[2]),
    .fifo_clr_i        (shared_tdc_fifo_clr),
    .soft_reset_i      (shared_tdc_soft_reset),
    .max_hits_i        (shared_tdc_max_hits),
    .ro_slow_code_i    (shared_tdc_ro_slow_code),
    .ro_fast_code_i    (shared_tdc_ro_fast_code),
    .pkt_valid_o       (tdc_pkt_valid[2]),
    .pkt_ready_i       (tdc_pkt_ready[2]),
    .pkt_data_o        (tdc_pkt_data[2]),
    .pkt_sop_o         (tdc_pkt_sop[2]),
    .pkt_eop_o         (tdc_pkt_eop[2]),
    .packet_active_o   (tdc_packet_active[2]),
    .packet_pending_o  (tdc_packet_pending[2]),
    .ready_o           (tdc_ready[2]),
    .busy_o            (tdc_busy[2]),
    .fifo_full_o       (tdc_fifo_full[2]),
    .stop_armed_o      (tdc_stop_armed[2])
  );

  spadmic_position_snapshot_packetizer #(.LINE_W(SPADMIC_LINE_W)) u_pos_packetizer (
    .clk_sys          (clk_sys),
    .rst_n            (rst_sys_n),
    .start_i          (pos_packet_start),
    .mode_i           (position_mode),
    .event_id_i       (event_id),
    .snapshot_R_i     (snapshot_R),
    .snapshot_Y_i     (snapshot_Y),
    .snapshot_B_i     (snapshot_B),
    .gap_threshold_i  (position_gap_threshold),
    .min_cluster_span_i(position_min_cluster_span),
    .pkt_valid_o      (pos_pkt_valid),
    .pkt_ready_i      (pos_pkt_ready),
    .pkt_data_o       (pos_pkt_data),
    .pkt_sop_o        (pos_pkt_sop),
    .pkt_eop_o        (pos_pkt_eop),
    .packet_pending_o (pos_packet_pending),
    .busy_o           (pos_packet_busy),
    .snapshot_captured_o(pos_snapshot_captured),
    .done_o           (pos_packet_done),
    .drop_o           (pos_packet_drop)
  );

  spadmic_event_bundle_tx u_bundle_tx (
    .clk_sys                 (clk_sys),
    .rst_n                   (rst_sys_n),
    .bundle_start_i          (bundle_start),
    .required_packet_mask_i  (required_packet_mask),
    .source_pending_mask_i   (packet_pending_mask),
    .event_id_i              (event_id),
    .src_valid_i             (src_valid),
    .src_ready_o             (src_ready),
    .src_data_i              (src_data),
    .src_sop_i               (src_sop),
    .src_eop_i               (src_eop),
    .word_valid_o            (bundle_word_valid),
    .word_ready_i            (bundle_word_ready),
    .word_data_o             (bundle_word_data),
    .flush_o                 (bundle_flush),
    .completed_packet_mask_o (bundle_completed_packet_mask),
    .done_o                  (bundle_done),
    .busy_o                  (bundle_busy),
    .idle_o                  (bundle_idle),
    .missing_source_error_o  (bundle_missing_source_error)
  );

  spadmic_output_fifo #(
    .DATA_W        (NARROW_W + 1),
    .DEPTH         (SPADMIC_OUTPUT_FIFO_DEPTH),
    .RESERVE_WORDS (SPADMIC_OUTPUT_FIFO_RESERVE_ENTRIES),
    .LEVEL_W       (SPADMIC_OUTPUT_FIFO_LEVEL_W)
  ) u_output_fifo (
    .clk_sys       (clk_sys),
    .rst_n         (rst_sys_n),
    .push_valid_i  (output_fifo_push_valid),
    .push_ready_o  (output_fifo_push_ready),
    .push_data_i   (output_fifo_push_data),
    .pop_valid_o   (output_fifo_pop_valid),
    .pop_ready_i   (output_fifo_pop_ready),
    .pop_data_o    (output_fifo_pop_data),
    .level_o       (output_fifo_level),
    .free_words_o  (output_fifo_free_words),
    .empty_o       (output_fifo_empty),
    .full_o        (output_fifo_full),
    .almost_full_o (output_fifo_almost_full),
    .overflow_o    (output_fifo_overflow)
  );

  spadmic_matrix_cfg_ctrl u_matrix_cfg (
    .clk_sys                  (clk_sys),
    .clk_cfg_40m              (clk_cfg_40m),
    .rst_sys_n                (rst_sys_n),
    .rst_cfg_n                (rst_cfg_n),
    .cmd_start_i              (matrix_cfg_cmd_start),
    .cmd_op_i                 (matrix_cfg_cmd_op),
    .col_idx_i                (matrix_cfg_col_idx),
    .wdata_i                  (matrix_cfg_wdata),
    .busy_o                   (matrix_cfg_busy),
    .done_o                   (matrix_cfg_done),
    .error_o                  (matrix_cfg_error),
    .last_error_o             (matrix_cfg_last_error),
    .rdata_o                  (matrix_cfg_rdata),
    .readback_valid_o         (matrix_cfg_readback_valid),
    .matrix_cfg_valid_o       (matrix_cfg_valid),
    .matrix_din_o             (matrix_din_o),
    .matrix_cin_o             (matrix_cin_o),
    .matrix_dout_i            (matrix_dout_i),
    .matrix_cout_i            (matrix_cout_i)
  );

  spadmic_ddr16_tx_pairer u_ddr16_pairer (
    .clk_sys          (clk_sys),
    .rst_n            (rst_sys_n),
    .word_valid_i     (ddr_word_valid),
    .word_data_i      (ddr_word_data),
    .flush_i          (ddr_flush),
    .word_ready_o     (ddr_word_ready),
    .ddr_data_l_o     (ddr_data_l_o),
    .ddr_data_h_o     (ddr_data_h_o),
    .ddr_pair_valid_o (ddr_pair_valid_o),
    .ddr_padded_o     (ddr_padded),
    .ddr_clk_o        (ddr_clk_o),
    .busy_o           (ddr_busy),
    .empty_o          (ddr_empty)
  );

  wire unused_phase2_inputs =
      event_accept_enable ^ pos_packet_done ^ pos_packet_drop ^
      bundle_busy ^ bundle_missing_source_error ^ cfg_accept ^
      (|requested_axis_mask) ^ (requested_mode != SPADMIC_MODE_DISABLED) ^
      (|completed_packet_status_mask) ^ (|calib_axis_mask);

endmodule

`default_nettype wire
