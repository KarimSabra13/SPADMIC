// =============================================================================
// SPADMIC SVA — TX Mux Safety Assertions
// Checks source selection stability and ready routing correctness.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_mux_sva
  import spadmic_pkg::*;
  import mptdc_pkg::*;
(
  input wire        clk_sys,
  input wire        rst_n,

  // Mux control
  input wire        tx_sel,          // 0=TDC, 1=POSITION
  input wire        tdc_tx_valid,
  input wire        tdc_tx_ready,
  input wire        pos_tx_valid,
  input wire        pos_tx_ready,
  input wire        chip_tx_valid,
  input wire        chip_tx_ready
);

  // P9: tx_sel changes only when both paths are idle (no valid asserted)
  property p_sel_change_idle;
    @(posedge clk_sys) disable iff (!rst_n)
    $changed(tx_sel) |-> (!$past(tdc_tx_valid) && !$past(pos_tx_valid));
  endproperty
  a_sel_change_idle: assert property (p_sel_change_idle)
    else $error("[MUX_SVA] tx_sel changed while traffic was active");

  // P10: when TDC selected, position ready must be 0
  property p_pos_ready_gated_during_tdc;
    @(posedge clk_sys) disable iff (!rst_n)
    (tx_sel == 1'b0) |-> (pos_tx_ready == 1'b0);
  endproperty
  a_pos_ready_gated: assert property (p_pos_ready_gated_during_tdc)
    else $error("[MUX_SVA] pos_tx_ready asserted while TDC is selected");

  // P11: when POSITION selected, TDC ready must be 0
  property p_tdc_ready_gated_during_pos;
    @(posedge clk_sys) disable iff (!rst_n)
    (tx_sel == 1'b1) |-> (tdc_tx_ready == 1'b0);
  endproperty
  a_tdc_ready_gated: assert property (p_tdc_ready_gated_during_pos)
    else $error("[MUX_SVA] tdc_tx_ready asserted while POSITION is selected");

  // P12: chip_tx_valid reflects only the selected source
  property p_valid_routing;
    @(posedge clk_sys) disable iff (!rst_n)
    chip_tx_valid |-> ((tx_sel == 1'b0 && tdc_tx_valid) ||
                       (tx_sel == 1'b1 && pos_tx_valid));
  endproperty
  a_valid_routing: assert property (p_valid_routing)
    else $error("[MUX_SVA] chip_tx_valid from wrong source");

endmodule

`default_nettype wire
