// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_tx_egress_cluster.sv
// Purpose  : Hardenable TX egress island: event bundle, output FIFO, DDR16
//            pairer, and DDRs2 adapter.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_tx_egress_cluster #(
  parameter bit FORWARDED_CLK_INVERT = 1'b0
) (
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
  input  logic [mptdc_pkg::NARROW_W-1:0]            src_data_i [spadmic_pkg::SPADMIC_SRC_COUNT],
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

  output logic [spadmic_pkg::SPADMIC_DDR16_PHY_W-1:0] ddr_data_l_o,
  output logic [spadmic_pkg::SPADMIC_DDR16_PHY_W-1:0] ddr_data_h_o,
  output logic                                      ddr_pair_valid_o,
  output logic                                      ddr_padded_o,
  output logic                                      ddr_clk_o,
  output logic                                      ddr_busy_o,
  output logic                                      ddr_empty_o,

  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_l_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_h_o,
  output logic                                      ddrs2_clk_160m_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic bundle_word_valid;
  logic bundle_word_ready;
  logic [NARROW_W-1:0] bundle_word_data;
  logic bundle_flush;
  logic bundle_flush_pending_q;

  logic output_fifo_push_valid;
  logic output_fifo_push_ready;
  logic [NARROW_W:0] output_fifo_push_data;
  logic output_fifo_pop_valid;
  logic output_fifo_pop_ready;
  logic output_fifo_pop_fire;
  logic [NARROW_W:0] output_fifo_pop_data;
  logic output_fifo_pop_is_flush;

  logic ddr_word_valid;
  logic ddr_word_ready;
  logic [NARROW_W-1:0] ddr_word_data;
  logic ddr_flush;

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

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      bundle_flush_pending_q <= 1'b0;
    end else begin
      if (bundle_flush)
        bundle_flush_pending_q <= 1'b1;
      else if (bundle_flush_pending_q && output_fifo_push_ready)
        bundle_flush_pending_q <= 1'b0;
    end
  end

  spadmic_event_bundle_tx u_bundle_tx (
    .clk_sys                 (clk_sys),
    .rst_n                   (rst_n),
    .bundle_start_i          (bundle_start_i),
    .required_packet_mask_i  (required_packet_mask_i),
    .source_pending_mask_i   (source_pending_mask_i),
    .event_id_i              (event_id_i),
    .src_valid_i             (src_valid_i),
    .src_ready_o             (src_ready_o),
    .src_data_i              (src_data_i),
    .src_sop_i               (src_sop_i),
    .src_eop_i               (src_eop_i),
    .word_valid_o            (bundle_word_valid),
    .word_ready_i            (bundle_word_ready),
    .word_data_o             (bundle_word_data),
    .flush_o                 (bundle_flush),
    .completed_packet_mask_o (completed_packet_mask_o),
    .done_o                  (bundle_done_o),
    .busy_o                  (bundle_busy_o),
    .idle_o                  (bundle_idle_o),
    .missing_source_error_o  (bundle_missing_source_error_o)
  );

  spadmic_output_fifo_topcfg u_output_fifo (
    .clk_sys       (clk_sys),
    .rst_n         (rst_n),
    .push_valid_i  (output_fifo_push_valid),
    .push_ready_o  (output_fifo_push_ready),
    .push_data_i   (output_fifo_push_data),
    .pop_valid_o   (output_fifo_pop_valid),
    .pop_ready_i   (output_fifo_pop_ready),
    .pop_data_o    (output_fifo_pop_data),
    .level_o       (output_fifo_level_o),
    .free_words_o  (output_fifo_free_words_o),
    .empty_o       (output_fifo_empty_o),
    .full_o        (output_fifo_full_o),
    .almost_full_o (output_fifo_almost_full_o),
    .overflow_o    (output_fifo_overflow_o)
  );

  spadmic_ddr16_tx_pairer u_ddr16_pairer (
    .clk_sys          (clk_sys),
    .rst_n            (rst_n),
    .word_valid_i     (ddr_word_valid),
    .word_data_i      (ddr_word_data),
    .flush_i          (ddr_flush),
    .word_ready_o     (ddr_word_ready),
    .ddr_data_l_o     (ddr_data_l_o),
    .ddr_data_h_o     (ddr_data_h_o),
    .ddr_pair_valid_o (ddr_pair_valid_o),
    .ddr_padded_o     (ddr_padded_o),
    .ddr_clk_o        (ddr_clk_o),
    .busy_o           (ddr_busy_o),
    .empty_o          (ddr_empty_o)
  );

  spadmic_ddrs2_adapter #(
    .FORWARDED_CLK_INVERT (FORWARDED_CLK_INVERT)
  ) u_ddrs2_adapter (
    .clk_160m_i       (clk_160m_i),
    .rst_n            (rst_n),
    .enable_i         (ddrs2_enable_i),
    .ddr_data_l_i     (ddr_data_l_o),
    .ddr_data_h_i     (ddr_data_h_o),
    .ddr_pair_valid_i (ddr_pair_valid_o),
    .ddrs2_data_l_o   (ddrs2_data_l_o),
    .ddrs2_data_h_o   (ddrs2_data_h_o),
    .ddrs2_clk_160m_o (ddrs2_clk_160m_o)
  );

endmodule

`default_nettype wire
