// =============================================================================
// Project  : SPADMIC Top-Level Integration
// Purpose  : Cumulative soft digital-assembly implementation tops, p00-p03.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_digital_assembly_tx_path (
  input  logic                                      clk_sys,
  input  logic                                      clk_160m_i,
  input  logic                                      rst_n,
  input  logic                                      ddrs2_enable_i,
  input  logic                                      bundle_start_i,
  input  logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] required_packet_mask_i,
  input  logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] source_pending_mask_i,
  input  logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_i,
  input  logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_valid_i,
  output logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_ready_o,
  input  logic [63:0]                               src_data_flat_i,
  input  logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_sop_i,
  input  logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_eop_i,
  output logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] completed_packet_mask_o,
  output logic                                      bundle_done_o,
  output logic                                      bundle_busy_o,
  output logic                                      bundle_idle_o,
  output logic                                      bundle_missing_source_error_o,
  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level_o,
  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words_o,
  output logic                                      output_fifo_empty_o,
  output logic                                      output_fifo_full_o,
  output logic                                      output_fifo_almost_full_o,
  output logic                                      output_fifo_overflow_o,
  output logic                                      ddr_pair_valid_o,
  output logic                                      ddr_padded_o,
  output logic                                      ddr_busy_o,
  output logic                                      ddr_empty_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_l_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_h_o,
  output logic                                      ddrs2_clk_160m_o
);
  logic tx_valid;
  logic tx_ready;
  logic [mptdc_pkg::NARROW_W-1:0] tx_data;
  logic tx_flush;

  spadmic_tx_packet_core u_tx_packet_core (
    .clk_sys                       (clk_sys),
    .rst_n                         (rst_n),
    .bundle_start_i                (bundle_start_i),
    .required_packet_mask_i        (required_packet_mask_i),
    .source_pending_mask_i         (source_pending_mask_i),
    .event_id_i                    (event_id_i),
    .src_valid_i                   (src_valid_i),
    .src_ready_o                   (src_ready_o),
    // SPADMIC_TX_SRC_DATA_GENERATED_BEGIN FLAT_CONNECTIONS src_data_flat_i
    .src_data_i_s0_b0      (src_data_flat_i[0]),
    .src_data_i_s0_b1      (src_data_flat_i[1]),
    .src_data_i_s0_b2      (src_data_flat_i[2]),
    .src_data_i_s0_b3      (src_data_flat_i[3]),
    .src_data_i_s0_b4      (src_data_flat_i[4]),
    .src_data_i_s0_b5      (src_data_flat_i[5]),
    .src_data_i_s0_b6      (src_data_flat_i[6]),
    .src_data_i_s0_b7      (src_data_flat_i[7]),
    .src_data_i_s0_b8      (src_data_flat_i[8]),
    .src_data_i_s0_b9      (src_data_flat_i[9]),
    .src_data_i_s0_b10     (src_data_flat_i[10]),
    .src_data_i_s0_b11     (src_data_flat_i[11]),
    .src_data_i_s0_b12     (src_data_flat_i[12]),
    .src_data_i_s0_b13     (src_data_flat_i[13]),
    .src_data_i_s0_b14     (src_data_flat_i[14]),
    .src_data_i_s0_b15     (src_data_flat_i[15]),
    .src_data_i_s1_b0      (src_data_flat_i[16]),
    .src_data_i_s1_b1      (src_data_flat_i[17]),
    .src_data_i_s1_b2      (src_data_flat_i[18]),
    .src_data_i_s1_b3      (src_data_flat_i[19]),
    .src_data_i_s1_b4      (src_data_flat_i[20]),
    .src_data_i_s1_b5      (src_data_flat_i[21]),
    .src_data_i_s1_b6      (src_data_flat_i[22]),
    .src_data_i_s1_b7      (src_data_flat_i[23]),
    .src_data_i_s1_b8      (src_data_flat_i[24]),
    .src_data_i_s1_b9      (src_data_flat_i[25]),
    .src_data_i_s1_b10     (src_data_flat_i[26]),
    .src_data_i_s1_b11     (src_data_flat_i[27]),
    .src_data_i_s1_b12     (src_data_flat_i[28]),
    .src_data_i_s1_b13     (src_data_flat_i[29]),
    .src_data_i_s1_b14     (src_data_flat_i[30]),
    .src_data_i_s1_b15     (src_data_flat_i[31]),
    .src_data_i_s2_b0      (src_data_flat_i[32]),
    .src_data_i_s2_b1      (src_data_flat_i[33]),
    .src_data_i_s2_b2      (src_data_flat_i[34]),
    .src_data_i_s2_b3      (src_data_flat_i[35]),
    .src_data_i_s2_b4      (src_data_flat_i[36]),
    .src_data_i_s2_b5      (src_data_flat_i[37]),
    .src_data_i_s2_b6      (src_data_flat_i[38]),
    .src_data_i_s2_b7      (src_data_flat_i[39]),
    .src_data_i_s2_b8      (src_data_flat_i[40]),
    .src_data_i_s2_b9      (src_data_flat_i[41]),
    .src_data_i_s2_b10     (src_data_flat_i[42]),
    .src_data_i_s2_b11     (src_data_flat_i[43]),
    .src_data_i_s2_b12     (src_data_flat_i[44]),
    .src_data_i_s2_b13     (src_data_flat_i[45]),
    .src_data_i_s2_b14     (src_data_flat_i[46]),
    .src_data_i_s2_b15     (src_data_flat_i[47]),
    .src_data_i_s3_b0      (src_data_flat_i[48]),
    .src_data_i_s3_b1      (src_data_flat_i[49]),
    .src_data_i_s3_b2      (src_data_flat_i[50]),
    .src_data_i_s3_b3      (src_data_flat_i[51]),
    .src_data_i_s3_b4      (src_data_flat_i[52]),
    .src_data_i_s3_b5      (src_data_flat_i[53]),
    .src_data_i_s3_b6      (src_data_flat_i[54]),
    .src_data_i_s3_b7      (src_data_flat_i[55]),
    .src_data_i_s3_b8      (src_data_flat_i[56]),
    .src_data_i_s3_b9      (src_data_flat_i[57]),
    .src_data_i_s3_b10     (src_data_flat_i[58]),
    .src_data_i_s3_b11     (src_data_flat_i[59]),
    .src_data_i_s3_b12     (src_data_flat_i[60]),
    .src_data_i_s3_b13     (src_data_flat_i[61]),
    .src_data_i_s3_b14     (src_data_flat_i[62]),
    .src_data_i_s3_b15     (src_data_flat_i[63]),
    // SPADMIC_TX_SRC_DATA_GENERATED_END FLAT_CONNECTIONS
    .src_sop_i                     (src_sop_i),
    .src_eop_i                     (src_eop_i),
    .completed_packet_mask_o       (completed_packet_mask_o),
    .bundle_done_o                 (bundle_done_o),
    .bundle_busy_o                 (bundle_busy_o),
    .bundle_idle_o                 (bundle_idle_o),
    .bundle_missing_source_error_o (bundle_missing_source_error_o),
    .output_fifo_level_o           (output_fifo_level_o),
    .output_fifo_free_words_o      (output_fifo_free_words_o),
    .output_fifo_empty_o           (output_fifo_empty_o),
    .output_fifo_full_o            (output_fifo_full_o),
    .output_fifo_almost_full_o     (output_fifo_almost_full_o),
    .output_fifo_overflow_o        (output_fifo_overflow_o),
    .tx_valid_o                    (tx_valid),
    .tx_ready_i                    (tx_ready),
    .tx_data_o                     (tx_data),
    .tx_flush_o                    (tx_flush)
  );

  spadmic_tx_ddr_strip u_tx_ddr_strip (
    .clk_sys          (clk_sys),
    .clk_160m_i       (clk_160m_i),
    .rst_n            (rst_n),
    .ddrs2_enable_i   (ddrs2_enable_i),
    .tx_valid_i       (tx_valid),
    .tx_ready_o       (tx_ready),
    .tx_data_i        (tx_data),
    .tx_flush_i       (tx_flush),
    .ddr_pair_valid_o (ddr_pair_valid_o),
    .ddr_padded_o     (ddr_padded_o),
    .ddr_busy_o       (ddr_busy_o),
    .ddr_empty_o      (ddr_empty_o),
    .ddrs2_data_l_o   (ddrs2_data_l_o),
    .ddrs2_data_h_o   (ddrs2_data_h_o),
    .ddrs2_clk_160m_o (ddrs2_clk_160m_o)
  );
endmodule

module spadmic_digital_assembly_v1_p00_tx (
  inout  wire                                         VDD,
  inout  wire                                         VSS,
  input  logic                                        clk_160m_i,
  input  logic                                        clk_sys,
  input  logic                                        async_rst_n,
  input  logic                                        ddrs2_enable_i,
  input  logic                                        bundle_start_i,
  input  logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] required_packet_mask_i,
  input  logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] source_pending_mask_i,
  input  logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_i,
  input  logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0]  src_valid_i,
  output logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0]  src_ready_o,
  // SPADMIC_TX_SRC_DATA_GENERATED_BEGIN PORT_DECLS
  input wire logic src_data_i_s0_b0,
  input wire logic src_data_i_s0_b1,
  input wire logic src_data_i_s0_b2,
  input wire logic src_data_i_s0_b3,
  input wire logic src_data_i_s0_b4,
  input wire logic src_data_i_s0_b5,
  input wire logic src_data_i_s0_b6,
  input wire logic src_data_i_s0_b7,
  input wire logic src_data_i_s0_b8,
  input wire logic src_data_i_s0_b9,
  input wire logic src_data_i_s0_b10,
  input wire logic src_data_i_s0_b11,
  input wire logic src_data_i_s0_b12,
  input wire logic src_data_i_s0_b13,
  input wire logic src_data_i_s0_b14,
  input wire logic src_data_i_s0_b15,
  input wire logic src_data_i_s1_b0,
  input wire logic src_data_i_s1_b1,
  input wire logic src_data_i_s1_b2,
  input wire logic src_data_i_s1_b3,
  input wire logic src_data_i_s1_b4,
  input wire logic src_data_i_s1_b5,
  input wire logic src_data_i_s1_b6,
  input wire logic src_data_i_s1_b7,
  input wire logic src_data_i_s1_b8,
  input wire logic src_data_i_s1_b9,
  input wire logic src_data_i_s1_b10,
  input wire logic src_data_i_s1_b11,
  input wire logic src_data_i_s1_b12,
  input wire logic src_data_i_s1_b13,
  input wire logic src_data_i_s1_b14,
  input wire logic src_data_i_s1_b15,
  input wire logic src_data_i_s2_b0,
  input wire logic src_data_i_s2_b1,
  input wire logic src_data_i_s2_b2,
  input wire logic src_data_i_s2_b3,
  input wire logic src_data_i_s2_b4,
  input wire logic src_data_i_s2_b5,
  input wire logic src_data_i_s2_b6,
  input wire logic src_data_i_s2_b7,
  input wire logic src_data_i_s2_b8,
  input wire logic src_data_i_s2_b9,
  input wire logic src_data_i_s2_b10,
  input wire logic src_data_i_s2_b11,
  input wire logic src_data_i_s2_b12,
  input wire logic src_data_i_s2_b13,
  input wire logic src_data_i_s2_b14,
  input wire logic src_data_i_s2_b15,
  input wire logic src_data_i_s3_b0,
  input wire logic src_data_i_s3_b1,
  input wire logic src_data_i_s3_b2,
  input wire logic src_data_i_s3_b3,
  input wire logic src_data_i_s3_b4,
  input wire logic src_data_i_s3_b5,
  input wire logic src_data_i_s3_b6,
  input wire logic src_data_i_s3_b7,
  input wire logic src_data_i_s3_b8,
  input wire logic src_data_i_s3_b9,
  input wire logic src_data_i_s3_b10,
  input wire logic src_data_i_s3_b11,
  input wire logic src_data_i_s3_b12,
  input wire logic src_data_i_s3_b13,
  input wire logic src_data_i_s3_b14,
  input wire logic src_data_i_s3_b15,
  // SPADMIC_TX_SRC_DATA_GENERATED_END PORT_DECLS
  input  logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0]  src_sop_i,
  input  logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0]  src_eop_i,
  output logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] completed_packet_mask_o,
  output logic                                        bundle_done_o,
  output logic                                        bundle_busy_o,
  output logic                                        bundle_idle_o,
  output logic                                        bundle_missing_source_error_o,
  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level_o,
  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words_o,
  output logic                                        output_fifo_empty_o,
  output logic                                        output_fifo_full_o,
  output logic                                        output_fifo_almost_full_o,
  output logic                                        output_fifo_overflow_o,
  output logic                                        ddr_pair_valid_o,
  output logic                                        ddr_padded_o,
  output logic                                        ddr_busy_o,
  output logic                                        ddr_empty_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_l_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_h_o,
  output logic                                        ddrs2_clk_160m_o
);
  logic rst_sys_n;
  logic [63:0] src_data_flat_i;

  // SPADMIC_TX_SRC_DATA_GENERATED_BEGIN FLAT_ASSIGNMENTS src_data_flat_i
  assign src_data_flat_i[0] = src_data_i_s0_b0;
  assign src_data_flat_i[1] = src_data_i_s0_b1;
  assign src_data_flat_i[2] = src_data_i_s0_b2;
  assign src_data_flat_i[3] = src_data_i_s0_b3;
  assign src_data_flat_i[4] = src_data_i_s0_b4;
  assign src_data_flat_i[5] = src_data_i_s0_b5;
  assign src_data_flat_i[6] = src_data_i_s0_b6;
  assign src_data_flat_i[7] = src_data_i_s0_b7;
  assign src_data_flat_i[8] = src_data_i_s0_b8;
  assign src_data_flat_i[9] = src_data_i_s0_b9;
  assign src_data_flat_i[10] = src_data_i_s0_b10;
  assign src_data_flat_i[11] = src_data_i_s0_b11;
  assign src_data_flat_i[12] = src_data_i_s0_b12;
  assign src_data_flat_i[13] = src_data_i_s0_b13;
  assign src_data_flat_i[14] = src_data_i_s0_b14;
  assign src_data_flat_i[15] = src_data_i_s0_b15;
  assign src_data_flat_i[16] = src_data_i_s1_b0;
  assign src_data_flat_i[17] = src_data_i_s1_b1;
  assign src_data_flat_i[18] = src_data_i_s1_b2;
  assign src_data_flat_i[19] = src_data_i_s1_b3;
  assign src_data_flat_i[20] = src_data_i_s1_b4;
  assign src_data_flat_i[21] = src_data_i_s1_b5;
  assign src_data_flat_i[22] = src_data_i_s1_b6;
  assign src_data_flat_i[23] = src_data_i_s1_b7;
  assign src_data_flat_i[24] = src_data_i_s1_b8;
  assign src_data_flat_i[25] = src_data_i_s1_b9;
  assign src_data_flat_i[26] = src_data_i_s1_b10;
  assign src_data_flat_i[27] = src_data_i_s1_b11;
  assign src_data_flat_i[28] = src_data_i_s1_b12;
  assign src_data_flat_i[29] = src_data_i_s1_b13;
  assign src_data_flat_i[30] = src_data_i_s1_b14;
  assign src_data_flat_i[31] = src_data_i_s1_b15;
  assign src_data_flat_i[32] = src_data_i_s2_b0;
  assign src_data_flat_i[33] = src_data_i_s2_b1;
  assign src_data_flat_i[34] = src_data_i_s2_b2;
  assign src_data_flat_i[35] = src_data_i_s2_b3;
  assign src_data_flat_i[36] = src_data_i_s2_b4;
  assign src_data_flat_i[37] = src_data_i_s2_b5;
  assign src_data_flat_i[38] = src_data_i_s2_b6;
  assign src_data_flat_i[39] = src_data_i_s2_b7;
  assign src_data_flat_i[40] = src_data_i_s2_b8;
  assign src_data_flat_i[41] = src_data_i_s2_b9;
  assign src_data_flat_i[42] = src_data_i_s2_b10;
  assign src_data_flat_i[43] = src_data_i_s2_b11;
  assign src_data_flat_i[44] = src_data_i_s2_b12;
  assign src_data_flat_i[45] = src_data_i_s2_b13;
  assign src_data_flat_i[46] = src_data_i_s2_b14;
  assign src_data_flat_i[47] = src_data_i_s2_b15;
  assign src_data_flat_i[48] = src_data_i_s3_b0;
  assign src_data_flat_i[49] = src_data_i_s3_b1;
  assign src_data_flat_i[50] = src_data_i_s3_b2;
  assign src_data_flat_i[51] = src_data_i_s3_b3;
  assign src_data_flat_i[52] = src_data_i_s3_b4;
  assign src_data_flat_i[53] = src_data_i_s3_b5;
  assign src_data_flat_i[54] = src_data_i_s3_b6;
  assign src_data_flat_i[55] = src_data_i_s3_b7;
  assign src_data_flat_i[56] = src_data_i_s3_b8;
  assign src_data_flat_i[57] = src_data_i_s3_b9;
  assign src_data_flat_i[58] = src_data_i_s3_b10;
  assign src_data_flat_i[59] = src_data_i_s3_b11;
  assign src_data_flat_i[60] = src_data_i_s3_b12;
  assign src_data_flat_i[61] = src_data_i_s3_b13;
  assign src_data_flat_i[62] = src_data_i_s3_b14;
  assign src_data_flat_i[63] = src_data_i_s3_b15;
  // SPADMIC_TX_SRC_DATA_GENERATED_END FLAT_ASSIGNMENTS

  mptdc_reset_sync #(.STAGES(2)) u_rst_sys_sync (
    .clk(clk_sys), .async_rst_n(async_rst_n), .rst_n_o(rst_sys_n)
  );

  spadmic_digital_assembly_tx_path u_tx_path (
    .clk_sys, .clk_160m_i, .rst_n(rst_sys_n), .ddrs2_enable_i,
    .bundle_start_i, .required_packet_mask_i, .source_pending_mask_i,
    .event_id_i, .src_valid_i, .src_ready_o, .src_data_flat_i,
    .src_sop_i, .src_eop_i, .completed_packet_mask_o, .bundle_done_o,
    .bundle_busy_o, .bundle_idle_o, .bundle_missing_source_error_o,
    .output_fifo_level_o, .output_fifo_free_words_o, .output_fifo_empty_o,
    .output_fifo_full_o, .output_fifo_almost_full_o, .output_fifo_overflow_o,
    .ddr_pair_valid_o, .ddr_padded_o, .ddr_busy_o, .ddr_empty_o,
    .ddrs2_data_l_o, .ddrs2_data_h_o, .ddrs2_clk_160m_o
  );
endmodule

module spadmic_digital_assembly_v1_p01_position (
  inout  wire                                         VDD,
  inout  wire                                         VSS,
  input  logic                                        clk_160m_i,
  input  logic                                        clk_sys,
  input  logic                                        async_rst_n,
  input  logic                                        ddrs2_enable_i,
  input  logic                                        bundle_start_i,
  input  logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] required_packet_mask_i,
  input  logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_i,
  input  logic [2:0]                                  tdc_packet_pending_i,
  input  logic [2:0]                                  tdc_pkt_valid_i,
  output logic [2:0]                                  tdc_pkt_ready_o,
  input  logic [47:0]                                 tdc_pkt_data_flat_i,
  input  logic [2:0]                                  tdc_pkt_sop_i,
  input  logic [2:0]                                  tdc_pkt_eop_i,
  input  logic                                        position_start_i,
  input  spadmic_pkg::spadmic_pos_mode_e             position_mode_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     snapshot_R_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     snapshot_Y_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     snapshot_B_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_COUNT_W-1:0] gap_threshold_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_COUNT_W-1:0] min_cluster_span_i,
  output logic                                        position_packet_pending_o,
  output logic                                        position_busy_o,
  output logic                                        position_snapshot_captured_o,
  output logic                                        position_done_o,
  output logic                                        position_drop_o,
  output logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] completed_packet_mask_o,
  output logic                                        bundle_done_o,
  output logic                                        bundle_busy_o,
  output logic                                        bundle_idle_o,
  output logic                                        bundle_missing_source_error_o,
  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level_o,
  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words_o,
  output logic                                        output_fifo_empty_o,
  output logic                                        output_fifo_full_o,
  output logic                                        output_fifo_almost_full_o,
  output logic                                        output_fifo_overflow_o,
  output logic                                        ddr_pair_valid_o,
  output logic                                        ddr_padded_o,
  output logic                                        ddr_busy_o,
  output logic                                        ddr_empty_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_l_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_h_o,
  output logic                                        ddrs2_clk_160m_o
);
  logic rst_sys_n;
  logic position_pkt_valid;
  logic position_pkt_ready;
  logic [mptdc_pkg::NARROW_W-1:0] position_pkt_data;
  logic position_pkt_sop;
  logic position_pkt_eop;
  logic [3:0] src_valid;
  logic [3:0] src_ready;
  logic [3:0] src_sop;
  logic [3:0] src_eop;
  logic [3:0] source_pending;
  logic [63:0] src_data_flat;

  mptdc_reset_sync #(.STAGES(2)) u_rst_sys_sync (
    .clk(clk_sys), .async_rst_n(async_rst_n), .rst_n_o(rst_sys_n)
  );

  spadmic_position_core u_position (
    .clk_sys, .rst_n(rst_sys_n), .start_i(position_start_i),
    .mode_i(position_mode_i), .event_id_i, .snapshot_R_i, .snapshot_Y_i,
    .snapshot_B_i, .gap_threshold_i, .min_cluster_span_i,
    .pkt_valid_o(position_pkt_valid), .pkt_ready_i(position_pkt_ready),
    .pkt_data_o(position_pkt_data), .pkt_sop_o(position_pkt_sop),
    .pkt_eop_o(position_pkt_eop), .packet_pending_o(position_packet_pending_o),
    .busy_o(position_busy_o), .snapshot_captured_o(position_snapshot_captured_o),
    .done_o(position_done_o), .drop_o(position_drop_o)
  );

  assign src_valid = {position_pkt_valid, tdc_pkt_valid_i};
  assign src_sop = {position_pkt_sop, tdc_pkt_sop_i};
  assign src_eop = {position_pkt_eop, tdc_pkt_eop_i};
  assign source_pending = {position_packet_pending_o, tdc_packet_pending_i};
  assign src_data_flat = {position_pkt_data, tdc_pkt_data_flat_i};
  assign tdc_pkt_ready_o = src_ready[2:0];
  assign position_pkt_ready = src_ready[3];

  spadmic_digital_assembly_tx_path u_tx_path (
    .clk_sys, .clk_160m_i, .rst_n(rst_sys_n), .ddrs2_enable_i,
    .bundle_start_i, .required_packet_mask_i,
    .source_pending_mask_i(source_pending), .event_id_i,
    .src_valid_i(src_valid), .src_ready_o(src_ready),
    .src_data_flat_i(src_data_flat), .src_sop_i(src_sop), .src_eop_i(src_eop),
    .completed_packet_mask_o, .bundle_done_o, .bundle_busy_o, .bundle_idle_o,
    .bundle_missing_source_error_o, .output_fifo_level_o,
    .output_fifo_free_words_o, .output_fifo_empty_o, .output_fifo_full_o,
    .output_fifo_almost_full_o, .output_fifo_overflow_o,
    .ddr_pair_valid_o, .ddr_padded_o, .ddr_busy_o, .ddr_empty_o,
    .ddrs2_data_l_o, .ddrs2_data_h_o, .ddrs2_clk_160m_o
  );
endmodule

module spadmic_digital_assembly_v1_p02_event_control (
  inout  wire                                         VDD,
  inout  wire                                         VSS,
  input  logic                                        clk_160m_i,
  input  logic                                        clk_sys,
  input  logic                                        async_rst_n,
  input  logic                                        ddrs2_enable_i,
  input  spadmic_pkg::spadmic_operating_mode_e       active_mode_i,
  input  logic                                        global_enable_i,
  input  logic [2:0]                                  active_axis_mask_i,
  input  logic                                        matrix_activity_i,
  input  logic                                        cal_activity_i,
  input  logic                                        pre_event_resources_ready_i,
  input  logic                                        raw_snapshot_required_i,
  input  logic                                        auto_reset_enable_i,
  input  logic                                        snapshot_valid_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     snapshot_R_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     snapshot_Y_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     snapshot_B_i,
  input  logic                                        reset_done_i,
  input  logic                                        rearm_ready_i,
  input  logic [2:0]                                  tdc_start_seen_i,
  input  logic [2:0]                                  tdc_packet_pending_i,
  input  logic [2:0]                                  tdc_pkt_valid_i,
  output logic [2:0]                                  tdc_pkt_ready_o,
  input  logic [47:0]                                 tdc_pkt_data_flat_i,
  input  logic [2:0]                                  tdc_pkt_sop_i,
  input  logic [2:0]                                  tdc_pkt_eop_i,
  input  spadmic_pkg::spadmic_pos_mode_e             position_mode_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_COUNT_W-1:0] gap_threshold_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_COUNT_W-1:0] min_cluster_span_i,
  output logic                                        rst_sys_n_o,
  output logic                                        event_open_o,
  output logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_o,
  output logic                                        event_id_valid_o,
  output logic [3:0]                                  required_packet_mask_o,
  output logic [2:0]                                  required_tdc_mask_o,
  output logic [3:0]                                  required_reset_ack_mask_o,
  output logic [3:0]                                  observed_reset_ack_mask_o,
  output logic                                        reset_start_o,
  output logic                                        event_accept_enable_o,
  output logic                                        event_rejected_not_ready_o,
  output logic                                        event_busy_o,
  output logic                                        event_idle_o,
  output logic                                        position_packet_pending_o,
  output logic                                        position_busy_o,
  output logic                                        position_drop_o,
  output logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] completed_packet_mask_o,
  output logic                                        bundle_done_o,
  output logic                                        bundle_busy_o,
  output logic                                        bundle_idle_o,
  output logic                                        bundle_missing_source_error_o,
  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level_o,
  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words_o,
  output logic                                        output_fifo_empty_o,
  output logic                                        output_fifo_full_o,
  output logic                                        output_fifo_almost_full_o,
  output logic                                        output_fifo_overflow_o,
  output logic                                        ddr_pair_valid_o,
  output logic                                        ddr_padded_o,
  output logic                                        ddr_busy_o,
  output logic                                        ddr_empty_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_l_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_h_o,
  output logic                                        ddrs2_clk_160m_o
);
  logic rst_sys_n;
  logic bundle_start;
  logic position_start;
  logic position_snapshot_captured;
  logic position_done;
  logic position_snapshot_seen_q;
  logic [3:0] packet_pending;

  mptdc_reset_sync #(.STAGES(2)) u_rst_sys_sync (
    .clk(clk_sys), .async_rst_n(async_rst_n), .rst_n_o(rst_sys_n)
  );
  assign rst_sys_n_o = rst_sys_n;
  assign packet_pending = {position_packet_pending_o, tdc_packet_pending_i};
  assign position_start = event_open_o && event_id_valid_o &&
                          required_packet_mask_o[3] && snapshot_valid_i &&
                          !position_snapshot_seen_q && !position_busy_o &&
                          !position_packet_pending_o;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n || !event_open_o)
      position_snapshot_seen_q <= 1'b0;
    else if (position_snapshot_captured)
      position_snapshot_seen_q <= 1'b1;
  end

  spadmic_event_coordinator u_event (
    .clk_sys, .rst_n(rst_sys_n), .active_mode_i, .global_enable_i,
    .active_axis_mask_i, .matrix_activity_i, .cal_activity_i,
    .pre_event_resources_ready_i, .raw_snapshot_required_i,
    .auto_reset_enable_i, .snapshot_valid_i,
    .position_snapshot_captured_i(position_snapshot_seen_q || position_snapshot_captured),
    .tdc_start_seen_i, .packet_pending_mask_i(packet_pending), .reset_done_i,
    .bundle_done_i(bundle_done_o), .rearm_ready_i,
    .event_open_o, .event_id_o, .event_id_valid_o, .required_packet_mask_o,
    .required_tdc_mask_o, .required_reset_ack_mask_o,
    .observed_reset_ack_mask_o, .reset_start_o, .bundle_start_o(bundle_start),
    .accept_enable_o(event_accept_enable_o),
    .rejected_not_ready_o(event_rejected_not_ready_o),
    .busy_o(event_busy_o), .idle_o(event_idle_o)
  );

  spadmic_digital_assembly_v1_p01_position u_phase_p01 (
    .VDD, .VSS, .clk_160m_i, .clk_sys, .async_rst_n, .ddrs2_enable_i,
    .bundle_start_i(bundle_start), .required_packet_mask_i(required_packet_mask_o),
    .event_id_i(event_id_o), .tdc_packet_pending_i, .tdc_pkt_valid_i,
    .tdc_pkt_ready_o, .tdc_pkt_data_flat_i, .tdc_pkt_sop_i, .tdc_pkt_eop_i,
    .position_start_i(position_start), .position_mode_i, .snapshot_R_i,
    .snapshot_Y_i, .snapshot_B_i, .gap_threshold_i, .min_cluster_span_i,
    .position_packet_pending_o, .position_busy_o,
    .position_snapshot_captured_o(position_snapshot_captured),
    .position_done_o(position_done), .position_drop_o,
    .completed_packet_mask_o, .bundle_done_o, .bundle_busy_o, .bundle_idle_o,
    .bundle_missing_source_error_o, .output_fifo_level_o,
    .output_fifo_free_words_o, .output_fifo_empty_o, .output_fifo_full_o,
    .output_fifo_almost_full_o, .output_fifo_overflow_o,
    .ddr_pair_valid_o, .ddr_padded_o, .ddr_busy_o, .ddr_empty_o,
    .ddrs2_data_l_o, .ddrs2_data_h_o, .ddrs2_clk_160m_o
  );
endmodule

module spadmic_digital_assembly_v1_p03_matrix_interface (
  inout  wire                                         VDD,
  inout  wire                                         VSS,
  input  logic                                        clk_160m_i,
  input  logic                                        clk_sys,
  input  logic                                        clk_cfg_40m,
  input  logic                                        clk_ref_40m,
  input  logic                                        async_rst_n,
  input  logic                                        ddrs2_enable_i,
  input  logic                                        global_enable_i,
  input  spadmic_pkg::spadmic_operating_mode_e       active_mode_i,
  input  logic [2:0]                                  active_axis_mask_i,
  input  logic                                        auto_reset_enable_i,
  input  logic [15:0]                                 settle_cycles_i,
  input  logic [15:0]                                 watchdog_cycles_i,
  input  logic [15:0]                                 reset_width_i,
  input  logic                                        snapshot_clear_i,
  input  spadmic_pkg::spadmic_pos_mode_e             position_mode_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_COUNT_W-1:0] gap_threshold_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_COUNT_W-1:0] min_cluster_span_i,
  input  logic                                        matrix_cfg_cmd_start_i,
  input  logic [2:0]                                  matrix_cfg_cmd_op_i,
  input  logic [5:0]                                  matrix_cfg_col_idx_i,
  input  logic [63:0]                                 matrix_cfg_wdata_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     R_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     Y_i,
  input  logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     B_i,
  output logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     Rz_o,
  output logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     Yz_o,
  output logic [spadmic_pkg::SPADMIC_LINE_W-1:0]     Bz_o,
  output logic [spadmic_pkg::SPADMIC_MATRIX_COLUMN_COUNT-1:0] matrix_din_o,
  output logic [spadmic_pkg::SPADMIC_MATRIX_COLUMN_COUNT-1:0] matrix_cin_o,
  input  logic [spadmic_pkg::SPADMIC_MATRIX_COLUMN_COUNT-1:0] matrix_dout_i,
  input  logic [spadmic_pkg::SPADMIC_MATRIX_COLUMN_COUNT-1:0] matrix_cout_i,
  input  logic [2:0]                                  cal_start_async_i,
  input  logic [2:0]                                  mptdc_ready_i,
  input  logic [2:0]                                  mptdc_busy_i,
  input  logic [2:0]                                  mptdc_fifo_full_i,
  input  logic [2:0]                                  mptdc_packet_active_i,
  input  logic [2:0]                                  mptdc_packet_pending_i,
  input  logic [2:0]                                  mptdc_start_seen_i,
  input  logic [2:0]                                  mptdc_pkt_valid_i,
  output logic [2:0]                                  mptdc_pkt_ready_o,
  input  logic [47:0]                                 mptdc_pkt_data_flat_i,
  input  logic [2:0]                                  mptdc_pkt_sop_i,
  input  logic [2:0]                                  mptdc_pkt_eop_i,
  output logic [2:0]                                  mptdc_start_async_o,
  output logic                                        snapshot_valid_o,
  output logic                                        snapshot_busy_o,
  output logic                                        snapshot_timeout_o,
  output logic                                        snapshot_overlap_o,
  output logic                                        snapshot_reject_o,
  output logic                                        snapshot_rearm_ready_o,
  output logic                                        reset_busy_o,
  output logic                                        reset_done_o,
  output logic                                        reset_disabled_o,
  output logic                                        matrix_cfg_busy_o,
  output logic                                        matrix_cfg_done_o,
  output logic                                        matrix_cfg_error_o,
  output logic [3:0]                                  matrix_cfg_last_error_o,
  output logic [63:0]                                 matrix_cfg_rdata_o,
  output logic                                        matrix_cfg_readback_valid_o,
  output logic                                        matrix_cfg_valid_o,
  output logic                                        event_open_o,
  output logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_o,
  output logic                                        event_id_valid_o,
  output logic [3:0]                                  required_packet_mask_o,
  output logic [2:0]                                  required_tdc_mask_o,
  output logic                                        event_rejected_not_ready_o,
  output logic                                        event_busy_o,
  output logic                                        event_idle_o,
  output logic                                        position_packet_pending_o,
  output logic                                        position_busy_o,
  output logic                                        position_drop_o,
  output logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] completed_packet_mask_o,
  output logic                                        bundle_done_o,
  output logic                                        bundle_busy_o,
  output logic                                        bundle_idle_o,
  output logic                                        bundle_missing_source_error_o,
  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level_o,
  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words_o,
  output logic                                        output_fifo_empty_o,
  output logic                                        output_fifo_full_o,
  output logic                                        output_fifo_almost_full_o,
  output logic                                        output_fifo_overflow_o,
  output logic                                        ddr_pair_valid_o,
  output logic                                        ddr_padded_o,
  output logic                                        ddr_busy_o,
  output logic                                        ddr_empty_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_l_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_h_o,
  output logic                                        ddrs2_clk_160m_o
);
  logic rst_sys_n;
  logic rst_cfg_n;
  logic r_event;
  logic y_event;
  logic b_event;
  logic matrix_activity;
  logic cal_activity;
  logic mode_uses_matrix;
  logic mode_has_tdc;
  logic matrix_event_allowed;
  logic [2:0] snapshot_required_mask;
  logic [spadmic_pkg::SPADMIC_LINE_W-1:0] snapshot_R;
  logic [spadmic_pkg::SPADMIC_LINE_W-1:0] snapshot_Y;
  logic [spadmic_pkg::SPADMIC_LINE_W-1:0] snapshot_B;
  logic reset_start;
  logic event_accept_enable;
  logic pre_event_resources_ready;
  logic [3:0] required_reset_ack_mask;
  logic [3:0] observed_reset_ack_mask;
  logic tdc_path_idle;
  logic tdc_ready;
  logic tdc_fifo_ok;
  logic position_path_idle;
  logic output_capacity_available;

  assign mode_uses_matrix = (active_mode_i == spadmic_pkg::SPADMIC_MODE_TDC_ONLY) ||
                            (active_mode_i == spadmic_pkg::SPADMIC_MODE_POSITION_ONLY) ||
                            (active_mode_i == spadmic_pkg::SPADMIC_MODE_BOTH);
  assign mode_has_tdc = (active_mode_i == spadmic_pkg::SPADMIC_MODE_TDC_ONLY) ||
                        (active_mode_i == spadmic_pkg::SPADMIC_MODE_BOTH) ||
                        (active_mode_i == spadmic_pkg::SPADMIC_MODE_CALIBRATION);
  always_comb begin
    case (active_mode_i)
      spadmic_pkg::SPADMIC_MODE_TDC_ONLY: snapshot_required_mask = active_axis_mask_i;
      spadmic_pkg::SPADMIC_MODE_POSITION_ONLY,
      spadmic_pkg::SPADMIC_MODE_BOTH: snapshot_required_mask = 3'b111;
      default: snapshot_required_mask = 3'b000;
    endcase
  end
  assign matrix_event_allowed = global_enable_i && mode_uses_matrix && !matrix_cfg_busy_o;
  assign matrix_activity = matrix_event_allowed &&
                           (|({b_event, y_event, r_event} & snapshot_required_mask));
  assign cal_activity = global_enable_i &&
                        (active_mode_i == spadmic_pkg::SPADMIC_MODE_CALIBRATION) &&
                        (|(cal_start_async_i & active_axis_mask_i));
  assign tdc_path_idle = (((mptdc_busy_i | mptdc_packet_active_i |
                            mptdc_packet_pending_i) & active_axis_mask_i) == 3'b000);
  assign tdc_ready = ((mptdc_ready_i & active_axis_mask_i) == active_axis_mask_i);
  assign tdc_fifo_ok = (((~mptdc_fifo_full_i) & active_axis_mask_i) == active_axis_mask_i);
  assign position_path_idle = !position_busy_o && !position_packet_pending_o;
  assign output_capacity_available =
      output_fifo_free_words_o >= spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W'(
          spadmic_pkg::SPADMIC_OUTPUT_FIFO_RESERVE_ENTRIES);
  assign pre_event_resources_ready = event_idle_o && !snapshot_busy_o &&
      !reset_busy_o && !matrix_cfg_busy_o && output_capacity_available &&
      position_path_idle && (!mode_has_tdc || (tdc_path_idle && tdc_ready && tdc_fifo_ok));
  assign mptdc_start_async_o[0] = r_event && required_tdc_mask_o[0] &&
      ((event_idle_o && pre_event_resources_ready) || event_open_o);
  assign mptdc_start_async_o[1] = y_event && required_tdc_mask_o[1] &&
      ((event_idle_o && pre_event_resources_ready) || event_open_o);
  assign mptdc_start_async_o[2] = b_event && required_tdc_mask_o[2] &&
      ((event_idle_o && pre_event_resources_ready) || event_open_o);

  mptdc_reset_sync #(.STAGES(2)) u_rst_cfg_sync (
    .clk(clk_cfg_40m), .async_rst_n(async_rst_n), .rst_n_o(rst_cfg_n)
  );
  spadmic_matrix_or_tree u_matrix_or_r (.lines_i(R_i), .event_o(r_event));
  spadmic_matrix_or_tree u_matrix_or_y (.lines_i(Y_i), .event_o(y_event));
  spadmic_matrix_or_tree u_matrix_or_b (.lines_i(B_i), .event_o(b_event));

  spadmic_matrix_snapshot_frontend u_matrix_snapshot (
    .clk_sys, .rst_n(rst_sys_n), .enable_i(matrix_event_allowed),
    .clear_i(snapshot_clear_i || reset_done_o),
    .required_direction_mask_i(snapshot_required_mask), .R_i, .Y_i, .B_i,
    .settle_cycles_i, .watchdog_cycles_i, .snapshot_valid_o,
    .snapshot_R_o(snapshot_R), .snapshot_Y_o(snapshot_Y), .snapshot_B_o(snapshot_B),
    .busy_o(snapshot_busy_o), .timeout_o(snapshot_timeout_o),
    .overlap_o(snapshot_overlap_o), .reject_o(snapshot_reject_o),
    .rearm_ready_o(snapshot_rearm_ready_o)
  );

  spadmic_matrix_reset_ctrl u_matrix_reset (
    .clk_sys, .rst_n(rst_sys_n), .enable_i(auto_reset_enable_i),
    .start_i(reset_start), .reset_width_i, .snapshot_R_i(snapshot_R),
    .snapshot_Y_i(snapshot_Y), .snapshot_B_i(snapshot_B), .Rz_o, .Yz_o, .Bz_o,
    .busy_o(reset_busy_o), .done_o(reset_done_o), .disabled_o(reset_disabled_o)
  );

  spadmic_matrix_cfg_ctrl u_matrix_cfg (
    .clk_sys, .clk_cfg_40m, .rst_sys_n, .rst_cfg_n,
    .cmd_start_i(matrix_cfg_cmd_start_i), .cmd_op_i(matrix_cfg_cmd_op_i),
    .col_idx_i(matrix_cfg_col_idx_i), .wdata_i(matrix_cfg_wdata_i),
    .busy_o(matrix_cfg_busy_o), .done_o(matrix_cfg_done_o),
    .error_o(matrix_cfg_error_o), .last_error_o(matrix_cfg_last_error_o),
    .rdata_o(matrix_cfg_rdata_o), .readback_valid_o(matrix_cfg_readback_valid_o),
    .matrix_cfg_valid_o(matrix_cfg_valid_o), .matrix_din_o, .matrix_cin_o,
    .matrix_dout_i, .matrix_cout_i
  );

  spadmic_digital_assembly_v1_p02_event_control u_phase_p02 (
    .VDD, .VSS, .clk_160m_i, .clk_sys, .async_rst_n, .ddrs2_enable_i,
    .active_mode_i, .global_enable_i, .active_axis_mask_i, .matrix_activity_i(matrix_activity),
    .cal_activity_i(cal_activity), .pre_event_resources_ready_i(pre_event_resources_ready),
    .raw_snapshot_required_i(1'b1), .auto_reset_enable_i, .snapshot_valid_i(snapshot_valid_o),
    .snapshot_R_i(snapshot_R), .snapshot_Y_i(snapshot_Y), .snapshot_B_i(snapshot_B),
    .reset_done_i(reset_done_o), .rearm_ready_i(snapshot_rearm_ready_o),
    .tdc_start_seen_i(mptdc_start_seen_i), .tdc_packet_pending_i(mptdc_packet_pending_i),
    .tdc_pkt_valid_i(mptdc_pkt_valid_i), .tdc_pkt_ready_o(mptdc_pkt_ready_o),
    .tdc_pkt_data_flat_i(mptdc_pkt_data_flat_i), .tdc_pkt_sop_i(mptdc_pkt_sop_i),
    .tdc_pkt_eop_i(mptdc_pkt_eop_i), .position_mode_i, .gap_threshold_i,
    .min_cluster_span_i, .rst_sys_n_o(rst_sys_n), .event_open_o, .event_id_o,
    .event_id_valid_o, .required_packet_mask_o, .required_tdc_mask_o,
    .required_reset_ack_mask_o(required_reset_ack_mask),
    .observed_reset_ack_mask_o(observed_reset_ack_mask), .reset_start_o(reset_start),
    .event_accept_enable_o(event_accept_enable), .event_rejected_not_ready_o,
    .event_busy_o, .event_idle_o, .position_packet_pending_o, .position_busy_o,
    .position_drop_o, .completed_packet_mask_o, .bundle_done_o, .bundle_busy_o,
    .bundle_idle_o, .bundle_missing_source_error_o, .output_fifo_level_o,
    .output_fifo_free_words_o, .output_fifo_empty_o, .output_fifo_full_o,
    .output_fifo_almost_full_o, .output_fifo_overflow_o, .ddr_pair_valid_o,
    .ddr_padded_o, .ddr_busy_o, .ddr_empty_o, .ddrs2_data_l_o,
    .ddrs2_data_h_o, .ddrs2_clk_160m_o
  );

  // clk_ref_40m is retained as a related p04 boundary clock. No p04 logic is
  // instantiated in this phase.
  logic unused_clk_ref_40m;
  assign unused_clk_ref_40m = clk_ref_40m;
endmodule

`default_nettype wire
