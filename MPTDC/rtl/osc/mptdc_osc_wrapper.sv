`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_osc_wrapper.sv
// Purpose  : Oscillator selection wrapper — model vs. stub
// Author   : Karim Sabra
// =============================================================================
// Conditionally instantiates either the behavioural oscillator model
// (mptdc_osc_model, for simulation with real timing) or the synthesis
// stub (mptdc_osc_stub, for logic verification and physical implementation).
//
// Selection is controlled by the `MPTDC_USE_OSC_MODEL define:
//   - Defined   : instantiate mptdc_osc_model (simulation with #delays)
//   - Undefined : instantiate mptdc_osc_stub  (static placeholder)
//
// The wrapper is instantiated twice at the top level — once for the slow
// oscillator (TS_STEP_PS = 55) and once for the fast oscillator
// (TS_STEP_PS = 50).
// =============================================================================
module mptdc_osc_wrapper #(
  parameter int unsigned NE         = 8,
  parameter int unsigned TS_STEP_PS = 1000
)(
  input  wire              en,       // Enable oscillation
  input  wire              rst_n,    // Asynchronous active-low reset
  input  wire              trim_i,   // Trim bit (model only, ignored by stub)
  output wire [NE-1:0]     phase,    // NE phase-shifted output taps
  output wire              phase0_guard_o,
  output wire              phase7d_probe_o
);

  // Debug trace at elaboration time (simulation only)
  // synthesis translate_off
  initial begin
`ifdef MPTDC_USE_OSC_MODEL
    $display("[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)");
`else
    $display("[OSC_WRAPPER] MODE = STUB (synthesis placeholder, no oscillation)");
`endif
  end
  // synthesis translate_on

  // Conditional instantiation
`ifdef MPTDC_USE_OSC_MODEL
  // Simulation: behavioural model with real timing (#delays)
  mptdc_osc_model #(
    .NE(NE),
    .TS_STEP_PS(TS_STEP_PS)
  ) u_model (
    .en            (en),
    .rst_n         (rst_n),
    .trim_i        (trim_i),
    .phase         (phase),
    .phase0_guard_o(phase0_guard_o),
    .phase7d_probe_o(phase7d_probe_o)
  );
`else
  // Synthesis: static placeholder (phase = {0...0, 1})
  mptdc_osc_stub #(
    .NE(NE)
  ) u_stub (
    .en            (en),
    .rst_n         (rst_n),
    .phase         (phase),
    .phase0_guard_o(phase0_guard_o),
    .phase7d_probe_o(phase7d_probe_o)
  );
`endif

endmodule

`default_nettype wire
