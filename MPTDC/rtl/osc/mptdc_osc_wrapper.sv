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
// Selection is controlled by defines:
//   - MPTDC_USE_OSC_MODEL       : simulation behavioural model with #delays
//   - MPTDC_USE_RO_TUNE4_MACRO  : synthesis-only real RO_tune4 macro binding
//   - otherwise                 : controllable implementation placeholder
//
// The wrapper is instantiated twice at the top level — once for the slow
// oscillator (TS_STEP_PS = 55) and once for the fast oscillator
// (TS_STEP_PS = 50).
// =============================================================================
`ifdef MPTDC_USE_RO_TUNE4_MACRO
(* black_box, keep_hierarchy = "yes", dont_touch = "true" *)
module RO_tune4 (
  input  wire       rstb,
  input  wire [7:0] code,
  output wire [7:0] S
);
endmodule
`endif

(* keep_hierarchy = "yes" *)
module mptdc_osc_wrapper #(
  parameter int unsigned NE         = 8,
  parameter int unsigned TS_STEP_PS = 1000
)(
  input  wire              en,       // Enable oscillation
  input  wire              rst_n,    // Asynchronous active-low reset
  input  wire [7:0]        trim_i,   // RO tune code; model uses bit 0 only
  output wire [NE-1:0]     phase,    // NE phase-shifted output taps
  output wire              phase0_guard_o,
  output wire              phase7d_probe_o
);

  // Debug trace at elaboration time (simulation only)
  // synthesis translate_off
  initial begin
`ifdef MPTDC_USE_OSC_MODEL
    $display("[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)");
`elsif MPTDC_USE_RO_TUNE4_MACRO
    $display("[OSC_WRAPPER] MODE = RO_tune4 macro binding (synthesis only)");
`else
    $display("[OSC_WRAPPER] MODE = STUB (implementation placeholder, no real oscillation)");
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
    .trim_i        (trim_i[0]),
    .phase         (phase),
    .phase0_guard_o(phase0_guard_o),
    .phase7d_probe_o(phase7d_probe_o)
  );
`elsif MPTDC_USE_RO_TUNE4_MACRO
  // Synthesis-only real macro binding.  For RO_tune4, rstb is the active-high
  // oscillator run/start control, so it maps directly to the architectural
  // oscillator enable.  It is intentionally not tied to the global reset.
  if (NE != 8) begin : gen_invalid_ro_tune4_ne
    initial begin
      $error("RO_tune4 macro binding requires NE=8; got NE=%0d", NE);
    end
  end

  (* keep_hierarchy = "yes", dont_touch = "true" *)
  RO_tune4 u_ro_tune4 (
    .rstb(en),
    .code(trim_i),
    .S   (phase[7:0])
  );

  assign phase0_guard_o = phase[0];
  assign phase7d_probe_o = phase[7];
`else
  // Synthesis/implementation: controllable placeholder, not a real oscillator.
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
