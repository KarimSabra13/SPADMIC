`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_stop_capture_async.sv
// Purpose  : Async STOP metadata capture for the slow Vernier boundary
// Author   : Karim Sabra
// =============================================================================
// Captures the slow-domain STOP-side metadata directly on the asynchronous
// pd_enable edge.  The acquisition core then consumes stable level outputs
// when the Gray-counter snapshot reaches clk_sys.
//
// Captured fields:
//   - phase0_snap_o: state of slow phase 0 at STOP.
//   - phase7d_snap_o: simulation/helper probe aligned to the slow path.
//   - slow_boundary_inc_o: one-bit carry used to correct nslow when STOP
//     lands in the guarded phase-0 boundary window.
//
// The guarded window itself is provided by the oscillator wrapper/model, so
// the active acquisition core stays synthesis-clean.  In synthesis/stub mode,
// the wrapper drives deterministic placeholder values and this carry stays 0.
// =============================================================================
module mptdc_stop_capture_async (
  input  wire rst_n,
  input  wire async_clr_i,
  input  wire stop_async_i,
  input  wire slow_phase0_i,
  input  wire slow_phase0_guard_i,
  input  wire slow_phase7d_probe_i,
  output logic phase0_snap_o,
  output logic phase7d_snap_o,
  output logic slow_boundary_inc_o
);
  always_ff @(posedge stop_async_i or negedge rst_n or posedge async_clr_i) begin
    if (!rst_n || async_clr_i) begin
      phase0_snap_o        <= 1'b0;
      phase7d_snap_o       <= 1'b0;
      slow_boundary_inc_o  <= 1'b0;
    end else begin
      phase0_snap_o        <= slow_phase0_i;
      phase7d_snap_o       <= slow_phase7d_probe_i;
      slow_boundary_inc_o  <= slow_phase0_i & ~slow_phase0_guard_i;
    end
  end

endmodule

`default_nettype wire
