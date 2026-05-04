// =============================================================================
// SPADMIC VIP — Chip TX Interface Adapter
// Adapts the physical DDR byte bus back into a logical 16-bit word stream for
// the existing packet-oriented VIP components.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface spadmic_narrow_tx_if (
  input wire clk_sys,
  input wire rst_n
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  // Physical DUT pins
  logic                        phy_clk;
  logic                        phy_valid;
  logic [SPADMIC_TX_PHY_W-1:0] phy_data;

  // Reconstructed logical-word view used by the existing VIP
  logic                  valid;
  logic [NARROW_W-1:0]   data;

  // Legacy field retained so older backpressure collateral still compiles.
  // The physical TX boundary no longer consumes it.
  logic                  ready;
  logic [SPADMIC_TX_PHY_W-1:0] low_byte_q;

  always @(posedge phy_clk or negedge rst_n) begin
    if (!rst_n) begin
      low_byte_q <= '0;
    end else begin
      #1;
      if (phy_valid)
        low_byte_q <= phy_data;
    end
  end

  always @(negedge phy_clk or negedge rst_n) begin
    if (!rst_n) begin
      valid <= 1'b0;
      data  <= '0;
    end else begin
      #1;
      valid <= phy_valid;
      if (phy_valid)
        data <= {phy_data, low_byte_q};
    end
  end

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
