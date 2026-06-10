`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_pd_cell.sv
// Purpose  : Phase-detector cell — detects slow-to-fast phase crossing
// Author   : Karim Sabra
// =============================================================================
// A single phase-detector cell in the NE x NE PD matrix.  It samples the
// slow oscillator phase (slow_phase) on the rising edge of the fast
// oscillator phase (fast_phase) and detects the falling edge of the slow
// signal, which indicates the moment when the slow phase crosses the fast
// phase boundary.
//
// Edge detection:
//   - Default (SAMPLE_DEPTH = 2): two-stage pipeline.  A falling edge is
//     detected when q2 = 1 (was high 2 cycles ago) and q1 = 0 (went low
//     last cycle).
//   - Optional (SAMPLE_DEPTH >= 3): three-stage pipeline.  Requires
//     slow_phase to be high for 2 consecutive fast cycles before the
//     falling edge is confirmed, filtering brief glitches.
//
// On detection:
//   - hit_latched is set to 1 and stays high until clear_window or reset.
//   - nfast_hit_latched is a shadow timestamp register: before a hit, it tracks
//     the current local fast-column raw tag; once a hit is detected it freezes.
//     The timestamp flops intentionally have no hardware reset/clear:
//     nfast_hit is only meaningful when hit_latched=1, and no-hit cells are
//     ignored by the snapshot/drain path.  Software decodes this packet-visible
//     raw-tag field with the run metadata.
//
// Clock domain: fast_phase (fast oscillator tap, ~1 GHz).
// clear_window is an asynchronous clear from the system domain — it is
// safe because it is only asserted when the oscillators are being reset
// (no active edges on fast_phase).
//
// Physical-design note: this cell is replicated in a regular 8x8 island.  Keep
// hierarchy and pin structure reviewable so backend can match slow/fast tap
// loading, routing RC, and PVT-sensitive skew across the full matrix.
// =============================================================================
(* keep_hierarchy = "yes" *)
module mptdc_pd_cell #(
  parameter int unsigned SAMPLE_DEPTH = 2  // Edge detection pipeline depth (2 or 3)
)(
  input  wire      rst_n,           // Global reset, active low
  input  wire      clear_window,    // Conversion reset (async, safe during osc idle)

  input  wire      slow_phase,      // Slow oscillator tap (sampled signal)
  input  wire      fast_phase,      // Fast oscillator tap (sampling clock)
  input  wire      detect_en_i,     // Detection enable; holds sampler when low
  input  wire [mptdc_pkg::NFAST_W-1:0] nfast_tag_i, // Local fast-column tag

  output wire      hit_level,       // Latched hit indicator
  output wire [mptdc_pkg::NFAST_W-1:0] nfast_hit // Captured local tag at hit
);
  localparam int unsigned NFAST_W = mptdc_pkg::NFAST_W;

  logic q1, q2;
  logic hit_latched;
  logic [NFAST_W-1:0] nfast_hit_latched;

  generate
    if (SAMPLE_DEPTH >= 3) begin : gen_triple_sample
      // Three-stage pipeline: requires slow_phase high for 2 consecutive
      // fast cycles before the falling edge is confirmed.  Filters glitches.
      logic q3;
      always @(posedge fast_phase or negedge rst_n or posedge clear_window) begin
        if (!rst_n || clear_window) begin
          q1          <= 1'b0;
          q2          <= 1'b0;
          q3          <= 1'b0;
          hit_latched <= 1'b0;
        end else if (detect_en_i) begin
          q1 <= slow_phase;
          q2 <= q1;
          q3 <= q2;
          // Confirmed falling edge: q3=1, q2=1 (was high), q1=0 (went low)
          if (!hit_latched && !q1 && q2 && q3) begin
            hit_latched <= 1'b1;
          end
        end
      end
    end else begin : gen_double_sample
      // Default two-stage pipeline.
      always @(posedge fast_phase or negedge rst_n or posedge clear_window) begin
        if (!rst_n || clear_window) begin
          q1          <= 1'b0;
          q2          <= 1'b0;
          hit_latched <= 1'b0;
        end else if (detect_en_i) begin
          q1 <= slow_phase;
          q2 <= q1;
          // Falling edge: q2=1 (was high), q1=0 (went low)
          if (!hit_latched && !q1 && q2) begin
            hit_latched <= 1'b1;
          end
        end
      end
    end
	  endgenerate

  // Timestamp shadow flops are deliberately separate from q1/q2/hit_latched.
  // They track the local tag until hit_latched is set on the same fast edge,
  // then freeze for snapshot/readout.
  always_ff @(posedge fast_phase) begin
    if (!hit_latched)
      nfast_hit_latched <= nfast_tag_i;
  end

  assign hit_level = hit_latched;
  assign nfast_hit = nfast_hit_latched;

  // synthesis translate_off
  logic hit_seen_q;

  always @(posedge fast_phase or negedge rst_n or posedge clear_window) begin
    if (!rst_n || clear_window) begin
      hit_seen_q <= 1'b0;
    end else begin
      if (hit_seen_q) begin
        assert (hit_level)
          else $error("mptdc_pd_cell: hit_level deasserted before clear_window");
      end
      if (hit_level) hit_seen_q <= 1'b1;
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
