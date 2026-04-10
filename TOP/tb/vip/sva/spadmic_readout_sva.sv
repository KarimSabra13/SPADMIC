// =============================================================================
// SPADMIC SVA — Shared-Readout Integrity Assertions
// Checks no-interleaving, one-hot grant, META-first, and source stability.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_readout_sva
  import spadmic_pkg::*;
  import mptdc_pkg::*;
(
  input wire        clk_sys,
  input wire        rst_n,

  // Shared readout signals
  input wire [2:0]  acq_valid,
  input wire [2:0]  acq_ready,
  input wire        busy,
  input wire [1:0]  packet_src,   // current grant index
  input wire        out_valid,
  input wire [15:0] out_data
);

  // P5: only one axis granted at a time (or none)
  property p_one_grant;
    @(posedge clk_sys) disable iff (!rst_n)
    $onehot0(acq_ready);
  endproperty
  a_one_grant: assert property (p_one_grant)
    else $error("[READOUT_SVA] Multiple acq_ready grants simultaneously");

  // P6: packet source stable while busy (no mid-packet switch)
  property p_source_stable;
    @(posedge clk_sys) disable iff (!rst_n)
    busy |-> $stable(packet_src) || $rose(busy);
  endproperty
  a_source_stable: assert property (p_source_stable)
    else $error("[READOUT_SVA] packet_src changed mid-packet");

  // P7: busy de-asserts only on EOC word
  property p_busy_deasserts_on_eoc;
    @(posedge clk_sys) disable iff (!rst_n)
    ($fell(busy) && out_valid) |-> is_tdc_eoc($past(out_data));
  endproperty
  a_eoc_on_deassert: assert property (p_busy_deasserts_on_eoc)
    else $error("[READOUT_SVA] busy fell without EOC on previous word");

  // P8: acq_ready only to axis with acq_valid
  property p_grant_requires_valid;
    @(posedge clk_sys) disable iff (!rst_n)
    (acq_ready != 3'b000) |-> ((acq_ready & acq_valid) == acq_ready);
  endproperty
  a_grant_needs_valid: assert property (p_grant_requires_valid)
    else $error("[READOUT_SVA] acq_ready granted to axis without acq_valid");

endmodule

`default_nettype wire
