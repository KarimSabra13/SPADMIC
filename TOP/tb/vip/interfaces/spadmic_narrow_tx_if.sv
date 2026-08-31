// =============================================================================
// SPADMIC VIP - Final DDR16 pair observation interface.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface spadmic_narrow_tx_if (
  input wire clk_sys,
  input wire rst_n
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic                    ddr_clk;
  logic                    pair_valid;
  logic                    pair_padded;
  logic [NARROW_W-1:0]     data_l;
  logic [NARROW_W-1:0]     data_h;

  // Compatibility aliases for backpressure-only VIP components. The final
  // chip boundary has no ready input and always consumes the internal stream.
  logic                    valid;
  logic [NARROW_W-1:0]     data;

  // Legacy field retained so older backpressure collateral still compiles.
  // The physical TX boundary no longer consumes it.
  logic                  ready;
  assign valid = pair_valid;
  assign data  = data_l;

  // ── Clocking blocks ───────────────────────────────────────────
  clocking mon_cb @(posedge clk_sys);
    input pair_valid, pair_padded, data_l, data_h;
    input valid, data;
    input ready;
  endclocking

  clocking bp_cb @(posedge clk_sys);
    input  valid, data;
    output ready;
  endclocking

  // ── Initial state ─────────────────────────────────────────────
  initial begin
    ready = 1'b1;
  end

endinterface

`default_nettype wire
