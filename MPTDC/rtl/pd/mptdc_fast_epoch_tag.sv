`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_fast_epoch_tag.sv
// Purpose  : Local fast-column epoch tag generator for O2 local-tag timing fix
// =============================================================================
// This leaf replaces the global live binary fast counter on the PD timestamp
// capture path.  Each fast column owns one shallow LFSR tag generator clocked by
// that column's fast phase.  PD cells capture the local raw tag; software and
// calibration decode it after readout using nf and run metadata.
//
// The default 7-bit sequence uses x^7 + x^6 + 1, reset seed 7'b0000001, and
// excludes the all-zero state.  For NFAST_W=7 the sequence length is 127 states.
// O6C can select a shift-mostly 7-bit Galois sequence with the same width and
// packet field position; software/calibration distinguish the interpretation
// through the nfast_encoding manifest field.
//
// O4 muxless-tag mode intentionally advances on every fast tap edge after
// reset/clear.  The RO_tune4 rstb/run control already stops the clock when the
// fast oscillator is off, so a synchronous enable/hold mux only adds critical
// oscillator-domain delay.  enable_i is retained as a compatibility port for
// existing wrappers/tests but is not used by this timing experiment.
// =============================================================================
module mptdc_fast_epoch_tag
  import mptdc_pkg::*;
#(
  parameter int unsigned W = NFAST_W,
  parameter logic [W-1:0] SEED = {{(W-1){1'b0}}, 1'b1},
  parameter int unsigned TAG_ENCODING_SEL = TAG_ENC_LFSR_FIBONACCI
)(
  input  wire              clk_fast,
  input  wire              rst_n,
  input  wire              clear_window,
  input  wire              enable_i,      // compatibility only; ignored in O4
  output logic [W-1:0]     tag_o
);

  wire unused_enable = enable_i;

  function automatic logic [W-1:0] fibonacci_next(input logic [W-1:0] state_i);
    fibonacci_next = {state_i[W-2:0], state_i[W-1] ^ state_i[W-2]};
  endfunction

  function automatic logic [W-1:0] galois_next(input logic [W-1:0] state_i);
    automatic logic feedback;
    automatic logic [W-1:0] next_tag;

    feedback = state_i[W-1];
    next_tag = {state_i[W-2:0], 1'b0};
    if (feedback)
      next_tag = next_tag ^ W'(FAST_TAG_GALOIS_MASK);
    galois_next = next_tag;
  endfunction

  function automatic logic [W-1:0] tag_next(input logic [W-1:0] state_i);
    case (TAG_ENCODING_SEL)
      TAG_ENC_GALOIS:         tag_next = galois_next(state_i);
      TAG_ENC_LFSR_FIBONACCI: tag_next = fibonacci_next(state_i);
      default:                tag_next = fibonacci_next(state_i);
    endcase
  endfunction

  always_ff @(posedge clk_fast or negedge rst_n or posedge clear_window) begin
    if (!rst_n || clear_window) begin
      tag_o <= SEED;
    end else begin
      tag_o <= tag_next(tag_o);
    end
  end

  // synthesis translate_off
  initial begin
    assert (W == NFAST_W)
      else $fatal(1, "mptdc_fast_epoch_tag: W=%0d must match NFAST_W=%0d", W, NFAST_W);
    assert (W == 7)
      else $fatal(1, "mptdc_fast_epoch_tag: only the verified 7-bit polynomial is supported");
    assert (SEED != '0)
      else $fatal(1, "mptdc_fast_epoch_tag: SEED must be non-zero");
    assert (TAG_ENCODING_SEL == TAG_ENC_LFSR_FIBONACCI ||
            TAG_ENCODING_SEL == TAG_ENC_GALOIS)
      else $fatal(1, "mptdc_fast_epoch_tag: unsupported TAG_ENCODING_SEL=%0d",
                  TAG_ENCODING_SEL);
  end

  always_ff @(posedge clk_fast or negedge rst_n or posedge clear_window) begin
    if (rst_n && !clear_window) begin
      assert (tag_o != '0)
        else $error("mptdc_fast_epoch_tag: LFSR entered all-zero state");
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
