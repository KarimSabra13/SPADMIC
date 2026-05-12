`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_osc_stub.sv
// Purpose  : Synthesis placeholder for the ring oscillator
// Author   : Karim Sabra
// =============================================================================
// Provides deterministic, X-free, non-constant phase pins for synthesis and
// logic-level integration simulations where no behavioural oscillator model is
// needed.  The taps do not model real oscillation; they are controllable from
// en/rst_n so downstream PD/oscillator-domain implementation structure is not
// optimized away before the real oscillator macro is available.
//
// In a real silicon implementation, this stub is replaced by the physical
// oscillator macro cell.  No actual TDC measurements can be performed with
// this stub — it is purely an implementation placeholder.
// =============================================================================
(* keep_hierarchy = "yes", dont_touch = "true", preserve *)
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

  (* keep = "true", dont_touch = "true" *) wire osc_active   = en & rst_n;
  (* keep = "true", dont_touch = "true" *) wire osc_inactive = ~en & rst_n;

  for (genvar tap = 0; tap < NE; tap++) begin : gen_impl_tap
    if ((tap % 4) == 0) begin : gen_active_tap
      assign phase[tap] = osc_active;
    end else if ((tap % 4) == 1) begin : gen_inactive_tap
      assign phase[tap] = osc_inactive;
    end else if ((tap % 4) == 2) begin : gen_active_b_tap
      assign phase[tap] = ~osc_active;
    end else begin : gen_inactive_b_tap
      assign phase[tap] = ~osc_inactive;
    end
  end

  assign phase0_guard_o = phase[0];
  assign phase7d_probe_o = phase[PHASE7_IDX];

endmodule



`default_nettype wire
