// =============================================================================
// SPADMIC VIP — Chip TX (Narrow Bus) Interface
// Carries the shared 16-bit chip output: valid/data/ready handshake.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface spadmic_narrow_tx_if (
  input wire clk_sys,
  input wire rst_n
);
  import mptdc_pkg::*;

  logic                  valid;
  logic [NARROW_W-1:0]   data;
  logic                  ready;

  // ── Clocking blocks ───────────────────────────────────────────
  clocking mon_cb @(posedge clk_sys);
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
