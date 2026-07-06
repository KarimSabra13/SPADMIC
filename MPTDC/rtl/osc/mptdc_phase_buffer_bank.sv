`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC -- Vernier Time-to-Digital Converter
// File     : mptdc_phase_buffer_bank.sv
// Purpose  : Matched phase-isolation buffer bank for RO_tune4 output taps
// Author   : Karim Sabra
// =============================================================================
// Active physical intent:
//   RO_tune4/S[0:7] drives only this local, symmetric buffer bank.  The
//   buffered phase bus then drives the PD matrix, tag generators, and metadata
//   logic.
//
// Simulation keeps this as a transparent assign so packet format, raw_lfsr_tag
// semantics, R750_delta5 mode, and PD behavior remain bit-identical.
//
// For the single-stage physical topology, define MPTDC_PHASE_BUFFER_USE_BUHDX4
// in the synthesis filelist to instantiate one BUHDX4 per tap.  Every tap uses
// the same single-cell topology.
//
// For the active two-stage phase-distribution topology, define
// MPTDC_PHASE_BUFFER_TOPO_BUJIHDX4_BUJIHDX12.  This keeps the first-stage
// BUJIHDX4 input load on RO_tune4/S[n], then uses a BUJIHDX12 second-stage
// digital driver for the larger phase-fabric load.  Every tap uses the same
// two-stage topology.
// =============================================================================

`ifdef MPTDC_PHASE_BUFFER_USE_BUHDX4
`ifdef MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12
`error "Select only one MPTDC phase-buffer physical topology define"
`endif
`endif
`ifdef MPTDC_PHASE_BUFFER_USE_BUHDX4
`ifdef MPTDC_PHASE_BUFFER_TOPO_BUJIHDX4_BUJIHDX12
`error "Select only one MPTDC phase-buffer physical topology define"
`endif
`endif
`ifdef MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12
`ifdef MPTDC_PHASE_BUFFER_TOPO_BUJIHDX4_BUJIHDX12
`error "Select only one MPTDC phase-buffer physical topology define"
`endif
`endif

`ifdef MPTDC_PHASE_BUFFER_USE_BUHDX4
`define MPTDC_PHASE_BUFFER_NEEDS_BUHDX4
`endif

`ifdef MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12
`define MPTDC_PHASE_BUFFER_NEEDS_BUHDX4
`define MPTDC_PHASE_BUFFER_NEEDS_BUHDX12
`endif

`ifdef MPTDC_PHASE_BUFFER_TOPO_BUJIHDX4_BUJIHDX12
`define MPTDC_PHASE_BUFFER_NEEDS_BUJIHDX4
`define MPTDC_PHASE_BUFFER_NEEDS_BUJIHDX12
`endif

`ifdef MPTDC_PHASE_BUFFER_NEEDS_BUHDX4
(* black_box, keep_hierarchy = "yes", dont_touch = "true" *)
module BUHDX4 (
  input  wire A,
  output wire Q
);
endmodule
`endif

`ifdef MPTDC_PHASE_BUFFER_NEEDS_BUHDX12
(* black_box, keep_hierarchy = "yes", dont_touch = "true" *)
module BUHDX12 (
  input  wire A,
  output wire Q
);
endmodule
`endif

`ifdef MPTDC_PHASE_BUFFER_NEEDS_BUJIHDX4
(* black_box, keep_hierarchy = "yes", dont_touch = "true" *)
module BUJIHDX4 (
  input  wire A,
  output wire Q
);
endmodule
`endif

`ifdef MPTDC_PHASE_BUFFER_NEEDS_BUJIHDX12
(* black_box, keep_hierarchy = "yes", dont_touch = "true" *)
module BUJIHDX12 (
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

`ifdef MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12
    (* keep = "true", dont_touch = "true" *) wire iso_tap;
    (* keep = "true", dont_touch = "true" *) wire drv_tap;

    (* keep = "true", dont_touch = "true" *)
    BUHDX4 u_iso (
      .A (raw_tap),
      .Q (iso_tap)
    );

    (* keep = "true", dont_touch = "true" *)
    BUHDX12 u_drv (
      .A (iso_tap),
      .Q (drv_tap)
    );

    assign phase_buf_o[tap] = drv_tap;
`elsif MPTDC_PHASE_BUFFER_TOPO_BUJIHDX4_BUJIHDX12
    (* keep = "true", dont_touch = "true" *) wire iso_tap;
    (* keep = "true", dont_touch = "true" *) wire drv_tap;

    (* keep = "true", dont_touch = "true" *)
    BUJIHDX4 u_iso (
      .A (raw_tap),
      .Q (iso_tap)
    );

    (* keep = "true", dont_touch = "true" *)
    BUJIHDX12 u_drv (
      .A (iso_tap),
      .Q (drv_tap)
    );

    assign phase_buf_o[tap] = drv_tap;
`elsif MPTDC_PHASE_BUFFER_USE_BUHDX4
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

/* verilator lint_off DECLFILENAME */
(* keep_hierarchy = "yes", dont_touch = "true", preserve *)
module mptdc_ro_probe_buffer (
  input  wire phase_tap_i,
  output wire probe_o
);

`ifdef MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12
  (* keep = "true", dont_touch = "true" *) wire probe_buf;

  (* keep = "true", dont_touch = "true" *)
  BUHDX12 u_probe_buf (
    .A (phase_tap_i),
    .Q (probe_buf)
  );

  assign probe_o = probe_buf;
`elsif MPTDC_PHASE_BUFFER_TOPO_BUJIHDX4_BUJIHDX12
  (* keep = "true", dont_touch = "true" *) wire probe_buf;

  (* keep = "true", dont_touch = "true" *)
  BUJIHDX12 u_probe_buf (
    .A (phase_tap_i),
    .Q (probe_buf)
  );

  assign probe_o = probe_buf;
`elsif MPTDC_PHASE_BUFFER_USE_BUHDX4
  (* keep = "true", dont_touch = "true" *) wire probe_buf;

  (* keep = "true", dont_touch = "true" *)
  BUHDX4 u_probe_buf (
    .A (phase_tap_i),
    .Q (probe_buf)
  );

  assign probe_o = probe_buf;
`else
  assign probe_o = phase_tap_i;
`endif

endmodule
/* verilator lint_on DECLFILENAME */

`ifdef MPTDC_PHASE_BUFFER_NEEDS_BUHDX4
`undef MPTDC_PHASE_BUFFER_NEEDS_BUHDX4
`endif

`ifdef MPTDC_PHASE_BUFFER_NEEDS_BUHDX12
`undef MPTDC_PHASE_BUFFER_NEEDS_BUHDX12
`endif
`ifdef MPTDC_PHASE_BUFFER_NEEDS_BUJIHDX4
`undef MPTDC_PHASE_BUFFER_NEEDS_BUJIHDX4
`endif
`ifdef MPTDC_PHASE_BUFFER_NEEDS_BUJIHDX12
`undef MPTDC_PHASE_BUFFER_NEEDS_BUJIHDX12
`endif

`default_nettype wire
