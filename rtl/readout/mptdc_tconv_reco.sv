`timescale 1ns/1ps
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
// Equation (same contract as testbench and calibration scripts):
//   coef = (nslow - 1) * K_VERNIER * NE
//        + (nfast - 1) * NE
//        + ns * K_VERNIER
//        - nf * (K_VERNIER - 1)
//   tconv_ps = coef * DELTA_LSB
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
  output logic signed [31:0] tconv_ps_o
);
  localparam int unsigned K_VERNIER = mptdc_pkg::K_VERNIER;
  localparam int unsigned NE        = mptdc_pkg::NE;
  localparam int unsigned DELTA_LSB = mptdc_pkg::DELTA_LSB;

  always_comb begin
    int signed coef_v;
    int signed nslow_v;
    int signed nfast_v;
    int signed ns_v;
    int signed nf_v;

    nslow_v = nslow_i;
    nfast_v = nfast_i;
    ns_v    = ns_i;
    nf_v    = nf_i;

    coef_v = ((nslow_v - 1) * K_VERNIER * NE)
           + ((nfast_v - 1) * NE)
           + (ns_v * K_VERNIER)
           - (nf_v * (K_VERNIER - 1));

    tconv_ps_o = coef_v * DELTA_LSB;
  end

endmodule

`default_nettype wire
