// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_tx_packet_core.sv
// Purpose  : Packet/FIFO half of the split TX egress physical implementation.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_tx_packet_core (
  input  wire logic                                      clk_sys,
  input  wire logic                                      rst_n,

  input  wire logic                                      bundle_start_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] required_packet_mask_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] source_pending_mask_i,
  input  wire logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_i,

  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_valid_i,
  output logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_ready_o,
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

  output logic                                      tx_valid_o,
  input  wire logic                                tx_ready_i,
  output logic [mptdc_pkg::NARROW_W-1:0]           tx_data_o,
  output logic                                      tx_flush_o
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
  logic [NARROW_W:0] output_fifo_pop_data;

  assign bundle_word_ready = !bundle_flush_pending_q && output_fifo_push_ready;
  assign output_fifo_push_valid = bundle_flush_pending_q || bundle_word_valid;
  assign output_fifo_push_data =
      bundle_flush_pending_q ? {1'b1, {NARROW_W{1'b0}}} :
                               {1'b0, bundle_word_data};

  assign tx_flush_o = output_fifo_pop_data[NARROW_W];
  assign tx_data_o  = output_fifo_pop_data[NARROW_W-1:0];

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

  spadmic_event_bundle_tx u_event_bundle_tx (
    .clk_sys                 (clk_sys),
    .rst_n                   (rst_n),
    .bundle_start_i          (bundle_start_i),
    .required_packet_mask_i  (required_packet_mask_i),
    .source_pending_mask_i   (source_pending_mask_i),
    .event_id_i              (event_id_i),
    .src_valid_i             (src_valid_i),
    .src_ready_o             (src_ready_o),
    // SPADMIC_TX_SRC_DATA_GENERATED_BEGIN PASS_CONNECTIONS
    .src_data_i_s0_b0      (src_data_i_s0_b0),
    .src_data_i_s0_b1      (src_data_i_s0_b1),
    .src_data_i_s0_b2      (src_data_i_s0_b2),
    .src_data_i_s0_b3      (src_data_i_s0_b3),
    .src_data_i_s0_b4      (src_data_i_s0_b4),
    .src_data_i_s0_b5      (src_data_i_s0_b5),
    .src_data_i_s0_b6      (src_data_i_s0_b6),
    .src_data_i_s0_b7      (src_data_i_s0_b7),
    .src_data_i_s0_b8      (src_data_i_s0_b8),
    .src_data_i_s0_b9      (src_data_i_s0_b9),
    .src_data_i_s0_b10     (src_data_i_s0_b10),
    .src_data_i_s0_b11     (src_data_i_s0_b11),
    .src_data_i_s0_b12     (src_data_i_s0_b12),
    .src_data_i_s0_b13     (src_data_i_s0_b13),
    .src_data_i_s0_b14     (src_data_i_s0_b14),
    .src_data_i_s0_b15     (src_data_i_s0_b15),
    .src_data_i_s1_b0      (src_data_i_s1_b0),
    .src_data_i_s1_b1      (src_data_i_s1_b1),
    .src_data_i_s1_b2      (src_data_i_s1_b2),
    .src_data_i_s1_b3      (src_data_i_s1_b3),
    .src_data_i_s1_b4      (src_data_i_s1_b4),
    .src_data_i_s1_b5      (src_data_i_s1_b5),
    .src_data_i_s1_b6      (src_data_i_s1_b6),
    .src_data_i_s1_b7      (src_data_i_s1_b7),
    .src_data_i_s1_b8      (src_data_i_s1_b8),
    .src_data_i_s1_b9      (src_data_i_s1_b9),
    .src_data_i_s1_b10     (src_data_i_s1_b10),
    .src_data_i_s1_b11     (src_data_i_s1_b11),
    .src_data_i_s1_b12     (src_data_i_s1_b12),
    .src_data_i_s1_b13     (src_data_i_s1_b13),
    .src_data_i_s1_b14     (src_data_i_s1_b14),
    .src_data_i_s1_b15     (src_data_i_s1_b15),
    .src_data_i_s2_b0      (src_data_i_s2_b0),
    .src_data_i_s2_b1      (src_data_i_s2_b1),
    .src_data_i_s2_b2      (src_data_i_s2_b2),
    .src_data_i_s2_b3      (src_data_i_s2_b3),
    .src_data_i_s2_b4      (src_data_i_s2_b4),
    .src_data_i_s2_b5      (src_data_i_s2_b5),
    .src_data_i_s2_b6      (src_data_i_s2_b6),
    .src_data_i_s2_b7      (src_data_i_s2_b7),
    .src_data_i_s2_b8      (src_data_i_s2_b8),
    .src_data_i_s2_b9      (src_data_i_s2_b9),
    .src_data_i_s2_b10     (src_data_i_s2_b10),
    .src_data_i_s2_b11     (src_data_i_s2_b11),
    .src_data_i_s2_b12     (src_data_i_s2_b12),
    .src_data_i_s2_b13     (src_data_i_s2_b13),
    .src_data_i_s2_b14     (src_data_i_s2_b14),
    .src_data_i_s2_b15     (src_data_i_s2_b15),
    .src_data_i_s3_b0      (src_data_i_s3_b0),
    .src_data_i_s3_b1      (src_data_i_s3_b1),
    .src_data_i_s3_b2      (src_data_i_s3_b2),
    .src_data_i_s3_b3      (src_data_i_s3_b3),
    .src_data_i_s3_b4      (src_data_i_s3_b4),
    .src_data_i_s3_b5      (src_data_i_s3_b5),
    .src_data_i_s3_b6      (src_data_i_s3_b6),
    .src_data_i_s3_b7      (src_data_i_s3_b7),
    .src_data_i_s3_b8      (src_data_i_s3_b8),
    .src_data_i_s3_b9      (src_data_i_s3_b9),
    .src_data_i_s3_b10     (src_data_i_s3_b10),
    .src_data_i_s3_b11     (src_data_i_s3_b11),
    .src_data_i_s3_b12     (src_data_i_s3_b12),
    .src_data_i_s3_b13     (src_data_i_s3_b13),
    .src_data_i_s3_b14     (src_data_i_s3_b14),
    .src_data_i_s3_b15     (src_data_i_s3_b15),
    // SPADMIC_TX_SRC_DATA_GENERATED_END PASS_CONNECTIONS
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
    .pop_valid_o   (tx_valid_o),
    .pop_ready_i   (tx_ready_i),
    .pop_data_o    (output_fifo_pop_data),
    .level_o       (output_fifo_level_o),
    .free_words_o  (output_fifo_free_words_o),
    .empty_o       (output_fifo_empty_o),
    .full_o        (output_fifo_full_o),
    .almost_full_o (output_fifo_almost_full_o),
    .overflow_o    (output_fifo_overflow_o)
  );

endmodule

`default_nettype wire
