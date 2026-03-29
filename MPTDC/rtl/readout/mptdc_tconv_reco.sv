`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_tconv_reco.sv
// Purpose  : Raw Vernier time reconstruction (combinational)
// Author   : Karim Sabra
// =============================================================================
// Computes the raw time estimate (tconv_ps) in picoseconds from the Vernier
// counter and phase values.  This is a purely combinational block — no
// clock, no state.  It is instantiated in the acquisition core readout path
// and produces a result in the same cycle as its inputs change.
//
// Equation: same original Vernier topology, with the package-level
// geometry-origin corrections and source-side slow boundary carry applied.
//
// Where:
//   K_VERNIER  = OSC_TS_SLOW_PS / DELTA_STEP  (slow steps per Vernier step)
//   DELTA_LSB  = 2 * DELTA_STEP                (LSB of the time measurement)
//   NE         = 9                              (ring oscillator element count)
//
// This formulation unfolds the Vernier delay-line model into a single
// signed multiplication, avoiding iterative counting.
// =============================================================================
module mptdc_tconv_reco (
  input  wire [mptdc_pkg::NSLOW_W-1:0] nslow_i,
  input  wire [mptdc_pkg::NFAST_W-1:0] nfast_i,
  input  wire mptdc_pkg::ph_idx_t      ns_i,
  input  wire mptdc_pkg::ph_idx_t      nf_i,
  input  wire                          slow_boundary_inc_i,
  output logic signed [31:0] tconv_ps_o
);
  always_comb begin
    tconv_ps_o = mptdc_pkg::vernier_tconv_ps(nslow_i, nfast_i, ns_i, nf_i,
                                             slow_boundary_inc_i);
  end

endmodule

`default_nettype wire
