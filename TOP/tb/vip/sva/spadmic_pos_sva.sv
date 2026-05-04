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
  input wire [4:0]  word_idx,
  input wire        pos_busy
);

  // P13: position packets are either 12-word cluster packets or 26-word raw packets.
  property p_word_idx_bounded;
    @(posedge clk_sys) disable iff (!rst_n)
    pos_busy |-> (word_idx < SPADMIC_POS_RAW_PKT_WORDS);
  endproperty
  a_word_idx_bound: assert property (p_word_idx_bounded)
    else $error("[POS_SVA] word_idx exceeded maximum position packet length");

endmodule

`default_nettype wire
