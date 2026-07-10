// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_digital_assembly_v1.sv
// Purpose  : Progressive top-coordinate digital assembly, Phase A contract.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_digital_assembly_v1 (
  inout  wire                                            VDD,
  inout  wire                                            VSS,
  input  wire logic                                      clk_sys,
  input  wire logic                                      clk_160m_i,
  input  wire logic                                      rst_n,
  input  wire logic                                      ddrs2_enable_i,

  input  wire logic                                      bundle_start_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] required_packet_mask_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] source_pending_mask_i,
  input  wire logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_valid_i,
  output      logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_ready_o,
  input  wire logic [mptdc_pkg::NARROW_W-1:0]            src_data_i [spadmic_pkg::SPADMIC_SRC_COUNT],
  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_sop_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_eop_i,

  output      logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] completed_packet_mask_o,
  output      logic                                      bundle_done_o,
  output      logic                                      bundle_busy_o,
  output      logic                                      bundle_idle_o,
  output      logic                                      bundle_missing_source_error_o,
  output      logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level_o,
  output      logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words_o,
  output      logic                                      output_fifo_empty_o,
  output      logic                                      output_fifo_full_o,
  output      logic                                      output_fifo_almost_full_o,
  output      logic                                      output_fifo_overflow_o,

  output      logic                                      ddr_pair_valid_o,
  output      logic                                      ddr_padded_o,
  output      logic                                      ddr_busy_o,
  output      logic                                      ddr_empty_o,
  output      logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_l_o,
  output      logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_h_o,
  output      logic                                      ddrs2_clk_160m_o
);
  logic                         tx_valid;
  logic                         tx_ready;
  logic [mptdc_pkg::NARROW_W-1:0] tx_data;
  logic                         tx_flush;

  spadmic_tx_packet_core u_tx_packet_core (
    .VDD                           (VDD),
    .VSS                           (VSS),
    .clk_sys                       (clk_sys),
    .rst_n                         (rst_n),
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
    .tx_valid_o                    (tx_valid),
    .tx_ready_i                    (tx_ready),
    .tx_data_o                     (tx_data),
    .tx_flush_o                    (tx_flush)
  );

  spadmic_tx_ddr_strip u_tx_ddr_strip (
    .VDD                 (VDD),
    .VSS                 (VSS),
    .clk_sys             (clk_sys),
    .clk_160m_i          (clk_160m_i),
    .rst_n               (rst_n),
    .ddrs2_enable_i      (ddrs2_enable_i),
    .tx_valid_i          (tx_valid),
    .tx_ready_o          (tx_ready),
    .tx_data_i           (tx_data),
    .tx_flush_i          (tx_flush),
    .ddr_pair_valid_o    (ddr_pair_valid_o),
    .ddr_padded_o        (ddr_padded_o),
    .ddr_busy_o          (ddr_busy_o),
    .ddr_empty_o         (ddr_empty_o),
    .ddrs2_data_l_o      (ddrs2_data_l_o),
    .ddrs2_data_h_o      (ddrs2_data_h_o),
    .ddrs2_clk_160m_o    (ddrs2_clk_160m_o)
  );

  // VDD/VSS are physical assembly ports. The hard-macro PG pins are connected
  // by the physical flow and the phase-specific OA PG overlay. They are
  // intentionally absent from the logical macro instances.

endmodule

`default_nettype wire
