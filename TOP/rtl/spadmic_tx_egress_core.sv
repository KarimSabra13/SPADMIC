// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_tx_egress_core.sv
// Purpose  : Physical TX egress island interface for DDRs2-facing hardening.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_tx_egress_core #(
  parameter bit FORWARDED_CLK_INVERT = 1'b0
) (
  input  wire logic                                      clk_sys,
  input  wire logic                                      clk_160m_i,
  input  wire logic                                      rst_n,
  input  wire logic                                      ddrs2_enable_i,

  input  wire logic                                      bundle_start_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] required_packet_mask_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] source_pending_mask_i,
  input  wire logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_i,

  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_valid_i,
  output logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_ready_o,
  input  wire logic [mptdc_pkg::NARROW_W-1:0]            src_data_i [spadmic_pkg::SPADMIC_SRC_COUNT],
  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_sop_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_eop_i,

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
  logic [spadmic_pkg::SPADMIC_DDR16_PHY_W-1:0] ddr_data_l_unused;
  logic [spadmic_pkg::SPADMIC_DDR16_PHY_W-1:0] ddr_data_h_unused;
  logic ddr_clk_unused;

  spadmic_tx_egress_cluster #(
    .FORWARDED_CLK_INVERT(FORWARDED_CLK_INVERT)
  ) u_cluster (
    .clk_sys                       (clk_sys),
    .clk_160m_i                    (clk_160m_i),
    .rst_n                         (rst_n),
    .ddrs2_enable_i                (ddrs2_enable_i),
    .bundle_start_i                (bundle_start_i),
    .required_packet_mask_i        (required_packet_mask_i),
    .source_pending_mask_i         (source_pending_mask_i),
    .event_id_i                    (event_id_i),
    .src_valid_i                   (src_valid_i),
    .src_ready_o                   (src_ready_o),
    .src_data_i                    (src_data_i),
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
    .ddr_data_l_o                  (ddr_data_l_unused),
    .ddr_data_h_o                  (ddr_data_h_unused),
    .ddr_pair_valid_o              (ddr_pair_valid_o),
    .ddr_padded_o                  (ddr_padded_o),
    .ddr_clk_o                     (ddr_clk_unused),
    .ddr_busy_o                    (ddr_busy_o),
    .ddr_empty_o                   (ddr_empty_o),
    .ddrs2_data_l_o                (ddrs2_data_l_o),
    .ddrs2_data_h_o                (ddrs2_data_h_o),
    .ddrs2_clk_160m_o              (ddrs2_clk_160m_o)
  );

endmodule

`default_nettype wire
