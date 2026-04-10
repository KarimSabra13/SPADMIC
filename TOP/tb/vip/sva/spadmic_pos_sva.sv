// =============================================================================
// SPADMIC SVA — Position Path Framing Assertions
// Checks fixed-length packet structure and EOC correctness.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_pos_sva
  import spadmic_pkg::*;
  import mptdc_pkg::*;
(
  input wire        clk_sys,
  input wire        rst_n,

  // Position block output
  input wire        pos_tx_valid,
  input wire [15:0] pos_tx_data,
  input wire        pos_tx_ready,

  // Position FSM state
  input wire [2:0]  pos_fsm_state,
  input wire [3:0]  word_idx,
  input wire        pos_busy
);

  // P13: position packets are always exactly 12 words
  // (word_idx counts from 0 to 11; overflow must not occur)
  property p_word_idx_bounded;
    @(posedge clk_sys) disable iff (!rst_n)
    pos_busy |-> (word_idx < SPADMIC_POS_PKT_WORDS);
  endproperty
  a_word_idx_bound: assert property (p_word_idx_bounded)
    else $error("[POS_SVA] word_idx exceeded POS_PKT_WORDS during packet");

  // P14: EOC marker is only at word position 11 (the last word)
  property p_eoc_at_end;
    @(posedge clk_sys) disable iff (!rst_n)
    (pos_tx_valid && pos_tx_ready && is_tdc_eoc(pos_tx_data))
      |-> (word_idx == SPADMIC_POS_PKT_WORDS - 1);
  endproperty
  a_eoc_at_end: assert property (p_eoc_at_end)
    else $error("[POS_SVA] EOC marker at wrong word position %0d", word_idx);

  // P15: header marker only at word position 0
  property p_header_at_start;
    @(posedge clk_sys) disable iff (!rst_n)
    (pos_tx_valid && pos_tx_ready && is_tdc_header(pos_tx_data))
      |-> (word_idx == 0);
  endproperty
  a_header_at_start: assert property (p_header_at_start)
    else $error("[POS_SVA] Header marker at wrong word position %0d", word_idx);

endmodule

`default_nettype wire
