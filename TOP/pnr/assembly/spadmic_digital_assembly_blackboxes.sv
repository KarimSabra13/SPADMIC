// Logical black-box declarations for Phase A assembly elaboration.
// The server-side Innovus netlist is generated from the approved LEFs so its
// scalar terminal names exactly match the physical macro terminals.
`timescale 1ps/1ps
`default_nettype none

(* black_box, syn_black_box, keep_hierarchy = "yes" *)
module spadmic_tx_packet_core (
  inout  wire VDD,
  inout  wire VSS,
  input  wire logic clk_sys,
  input  wire logic rst_n,
  input  wire logic bundle_start_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] required_packet_mask_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] source_pending_mask_i,
  input  wire logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_valid_i,
  output      logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_ready_o,
  input  wire logic [mptdc_pkg::NARROW_W-1:0] src_data_i [spadmic_pkg::SPADMIC_SRC_COUNT],
  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_sop_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_eop_i,
  output      logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] completed_packet_mask_o,
  output      logic bundle_done_o,
  output      logic bundle_busy_o,
  output      logic bundle_idle_o,
  output      logic bundle_missing_source_error_o,
  output      logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level_o,
  output      logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words_o,
  output      logic output_fifo_empty_o,
  output      logic output_fifo_full_o,
  output      logic output_fifo_almost_full_o,
  output      logic output_fifo_overflow_o,
  output      logic tx_valid_o,
  input  wire logic tx_ready_i,
  output      logic [mptdc_pkg::NARROW_W-1:0] tx_data_o,
  output      logic tx_flush_o
);
endmodule

(* black_box, syn_black_box, keep_hierarchy = "yes" *)
module spadmic_tx_ddr_strip (
  inout  wire VDD,
  inout  wire VSS,
  input  wire logic clk_sys,
  input  wire logic clk_160m_i,
  input  wire logic rst_n,
  input  wire logic ddrs2_enable_i,
  input  wire logic tx_valid_i,
  output      logic tx_ready_o,
  input  wire logic [mptdc_pkg::NARROW_W-1:0] tx_data_i,
  input  wire logic tx_flush_i,
  output      logic ddr_pair_valid_o,
  output      logic ddr_padded_o,
  output      logic ddr_busy_o,
  output      logic ddr_empty_o,
  output      logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_l_o,
  output      logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_h_o,
  output      logic ddrs2_clk_160m_o
);
endmodule

`default_nettype wire
