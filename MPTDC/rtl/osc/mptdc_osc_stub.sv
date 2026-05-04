`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_osc_stub.sv
// Purpose  : Synthesis placeholder for the ring oscillator (static phases)
// Author   : Karim Sabra
// =============================================================================
// Provides a deterministic, X-free output for synthesis and logic-level
// integration simulations where no behavioural oscillator model is needed.
// All taps output a fixed value: phase[0] = 1, all others = 0.  This
// corresponds to the reset state of the behavioural model.
//
// In a real silicon implementation, this stub is replaced by the physical
// oscillator macro cell.  The static output means no actual TDC
// measurements can be performed — it is purely for logic verification.
// =============================================================================
module mptdc_osc_stub #(
  parameter int unsigned NE = 8
)(
  input  wire          en,        // Enable (ignored — no oscillation)
  input  wire          rst_n,     // Reset (ignored — output always stable)
  output wire [NE-1:0] phase,     // Static phases: {0...0, 1}
  output wire          phase0_guard_o,
  output wire          phase7d_probe_o
);

  localparam int unsigned PHASE7_IDX = (NE > 7) ? 7 : (NE - 1);

  // Fixed deterministic output: only tap 0 is high
  assign phase = {{(NE-1){1'b0}}, 1'b1};
  assign phase0_guard_o = phase[0];
  assign phase7d_probe_o = phase[PHASE7_IDX];

endmodule



`default_nettype wire
