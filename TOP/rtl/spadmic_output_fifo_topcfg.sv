// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_output_fifo_topcfg.sv
// Purpose  : Matrix-top configured output FIFO wrapper for OOC handoff.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_output_fifo_topcfg (
  input  logic                                      clk_sys,
  input  logic                                      rst_n,

  input  logic                                      push_valid_i,
  output logic                                      push_ready_o,
  input  logic [mptdc_pkg::NARROW_W:0]              push_data_i,

  output logic                                      pop_valid_o,
  input  logic                                      pop_ready_i,
  output logic [mptdc_pkg::NARROW_W:0]              pop_data_o,

  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] level_o,
  output logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] free_words_o,
  output logic                                      empty_o,
  output logic                                      full_o,
  output logic                                      almost_full_o,
  output logic                                      overflow_o
);
  spadmic_output_fifo #(
    .DATA_W        (mptdc_pkg::NARROW_W + 1),
    .DEPTH         (spadmic_pkg::SPADMIC_OUTPUT_FIFO_DEPTH),
    .RESERVE_WORDS (spadmic_pkg::SPADMIC_OUTPUT_FIFO_RESERVE_ENTRIES),
    .LEVEL_W       (spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W)
  ) u_output_fifo (
    .clk_sys       (clk_sys),
    .rst_n         (rst_n),
    .push_valid_i  (push_valid_i),
    .push_ready_o  (push_ready_o),
    .push_data_i   (push_data_i),
    .pop_valid_o   (pop_valid_o),
    .pop_ready_i   (pop_ready_i),
    .pop_data_o    (pop_data_o),
    .level_o       (level_o),
    .free_words_o  (free_words_o),
    .empty_o       (empty_o),
    .full_o        (full_o),
    .almost_full_o (almost_full_o),
    .overflow_o    (overflow_o)
  );

endmodule

`default_nettype wire
