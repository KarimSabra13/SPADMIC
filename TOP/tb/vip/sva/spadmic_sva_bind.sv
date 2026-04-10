// =============================================================================
// SPADMIC SVA — Bind File
// Connects SVA checkers to DUT modules via SystemVerilog bind.
// Bind targets use the instance path within spadmic_top_v1.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

// NOTE: These bind statements connect SVA modules to the DUT hierarchy.
// The exact signal paths depend on the DUT internal naming.
// Some signals may need hierarchical cross-module references.

// ── Shared TX Mux assertions ────────────────────────────────────
// The mux is combinational inside spadmic_top_v1 (no separate module).
// Bind at the top-level where mux signals are visible.

// ── Shared Readout assertions ───────────────────────────────────
// bind spadmic_tdc_shared_readout spadmic_readout_sva u_readout_sva (
//   .clk_sys    (clk_sys),
//   .rst_n      (rst_n),
//   .acq_valid  (acq_valid_i),
//   .acq_ready  (acq_ready_o),
//   .busy       (busy),
//   .packet_src (grant_idx),
//   .out_valid  (out_valid_o),
//   .out_data   (out_data_o)
// );

// NOTE: Position SVA binds require access to internal FSM signals.
// These are commented out as templates — uncomment and adjust paths
// once the exact DUT signal names are verified during integration.

// ── Manual instantiation alternative ────────────────────────────
// If bind doesn't work for some signal paths, instantiate SVA modules
// directly in the harness (spadmic_vip_tb.sv) using hierarchical references:
//
//   spadmic_ctrl_sva u_ctrl_sva (
//     .clk_sys   (clk_sys),
//     .rst_n     (rst_n),
//     .seq_state (dut.u_sequencer.state_q),
//     ...
//   );

`default_nettype wire
