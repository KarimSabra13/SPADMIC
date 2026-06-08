`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC -- Vernier Time-to-Digital Converter
// File     : mptdc_phase_buffer_bank.sv
// Purpose  : Matched phase-isolation buffer bank for RO_tune4 output taps
// =============================================================================
// O12 experiment intent:
//   RO_tune4/S[0:7] drives only this local, symmetric buffer bank.  The buffered
//   phase bus then drives the PD matrix, tag generators, and metadata logic.
//
// Simulation keeps this as a transparent assign so packet format, raw_lfsr_tag
// semantics, R750_delta5 mode, and PD behavior remain bit-identical.
//
// For the physical experiment, define MPTDC_PHASE_BUFFER_USE_BUHDX4 in the
// synthesis filelist to instantiate one BUHDX4 per tap.  BUHDX4 is the buffer
// cell already referenced by the XH018 flow as a verified lab-server buffer.
// Every tap uses the same single-cell topology.
// =============================================================================

`ifdef MPTDC_PHASE_BUFFER_USE_BUHDX4
(* black_box, keep_hierarchy = "yes", dont_touch = "true" *)
module BUHDX4 (
  input  wire A,
  output wire Q
);
endmodule
`endif

(* keep_hierarchy = "yes", dont_touch = "true", preserve *)
module mptdc_phase_buffer_bank (
  input  wire [7:0] phase_raw_i,
  output wire [7:0] phase_buf_o
);

  for (genvar tap = 0; tap < 8; tap++) begin : gen_phase_buf
    (* keep = "true", dont_touch = "true" *) wire raw_tap = phase_raw_i[tap];

`ifdef MPTDC_PHASE_BUFFER_USE_BUHDX4
    (* keep = "true", dont_touch = "true" *) wire buf_tap;

    (* keep = "true", dont_touch = "true" *)
    BUHDX4 u_buf (
      .A (raw_tap),
      .Q (buf_tap)
    );

    assign phase_buf_o[tap] = buf_tap;
`else
    assign phase_buf_o[tap] = raw_tap;
`endif
  end

endmodule

`default_nettype wire
