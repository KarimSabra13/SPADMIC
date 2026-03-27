`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_gray_cnt_sync.sv
// Purpose  : Gray-code counter with CDC synchronisation to a second domain
// Author   : Karim Sabra
// =============================================================================
// Implements a binary counter in the source (oscillator) clock domain that
// is safely transferred to the destination domain via Gray-code encoding and
// a 2-FF synchroniser chain.  Two independent channels are provided:
//   - Continuous: the free-running counter value, updated every source cycle.
//   - Latched: a snapshot captured either synchronously on src_latch_p or,
//     when USE_ASYNC_SNAPSHOT=1, asynchronously on src_async_latch_p.  The
//     async path is intended for STOP-edge capture of the slow Gray counter.
//
// Counter behaviour (source domain):
//   - Counts up every cycle when src_en is asserted.
//   - Cleared by src_clr (conv_arm) or on the rising edge of src_en (the
//     first cycle after the oscillator starts), eliminating any fixed offset
//     from CDC latency in the conv_arm pulse path.
//   - src_async_clr provides a hard asynchronous reset for conv_clr when
//     the source clock may be stopped.
//
// CRITICAL invariant: src_clr must NOT clear the snapshot register
// (bin_snap_q).  Reason: conv_arm (src_clr) and stop_seen (src_latch_p)
// traverse independent pulse_sync paths from clk_sys.  If START and STOP
// arrive quasi-simultaneously, both pulses reach the oscillator domain at
// nearly the same time.  If src_clr cleared bin_snap_q, the snapshot would
// be destroyed before the Gray CDC had time to propagate it to clk_sys,
// resulting in dst_count_latched stuck at zero.
// Solution: bin_snap_q is only reset by rst_n or src_async_clr.
//
// CDC path:
//   - Gray-encoded versions of the continuous and snapshot counters are
//     registered in the source domain.
//   - Two independent 2-FF chains (annotated ASYNC_REG for placement)
//     synchronise these Gray codes to the destination clock.
//   - Gray-to-binary decoding converts the synchronised values back for
//     use by the system-clock logic.
// =============================================================================
module mptdc_gray_cnt_sync #(
  parameter int unsigned W = 16,
  parameter bit          USE_ASYNC_SNAPSHOT = 1'b0
)(
  input  wire             src_clk,
  input  wire             src_rst_n,
  // Asynchronous clear for conv_clr — must be able to reset even if
  // src_clk is stopped.
  input  wire             src_async_clr,
  input  wire             src_en,
  input  wire             src_clr,
  input  wire             src_latch_p,
  input  wire             src_async_latch_p,
  output logic [W-1:0]    src_count,

  input  wire             dst_clk,
  input  wire             dst_rst_n,
  input  wire             dst_latch_p,
  output logic [W-1:0]    dst_count_continuous,
  output logic [W-1:0]    dst_count_latched
);

  logic [W-1:0] bin_q;
  logic [W-1:0] bin_snap_q;
  logic [W-1:0] gray_src_cont_q;
  logic [W-1:0] gray_src_snap_sync_q;
  logic [W-1:0] gray_src_snap_async_q;
  logic [W-1:0] gray_src_snap_sel;
  logic         src_en_q;

  logic [W-1:0] gray_cont_ff1, gray_cont_ff2;
  logic [W-1:0] gray_snap_ff1, gray_snap_ff2;

  logic [W-1:0] bin_dec_cont;
  logic [W-1:0] bin_dec_snap;

  assign src_count = bin_q;

  // -----------------------------------------------------------------------
  // Source-domain counter and snapshot
  // -----------------------------------------------------------------------
  // bin_q: free-running counter, cleared by src_clr (conv_arm) or on the
  //        rising edge of src_en (aligns counter start with oscillator enable).
  // bin_snap_q: snapshot captured by src_latch_p (stop_seen).
  //             NEVER cleared by src_clr — see module header for rationale.
  always_ff @(posedge src_clk or negedge src_rst_n or posedge src_async_clr) begin
    if (!src_rst_n || src_async_clr) begin
      bin_q      <= '0;
      bin_snap_q <= '0;
      src_en_q   <= 1'b0;
    end else begin
      // Local rising-edge detect on src_en
      src_en_q <= src_en;

      // Counter: clear on conv_arm or at the first enable cycle (start/stop).
      // This avoids a fixed offset if conv_arm arrives late via clk_sys CDC.
      if (src_clr || (src_en && !src_en_q))
        bin_q <= '0;
      else if (src_en)
        bin_q <= bin_q + 1'b1;

      // Snapshot: independent capture, NEVER cleared by src_clr
      if (src_latch_p)
        bin_snap_q <= bin_q;
    end
  end

  // -----------------------------------------------------------------------
  // Gray encoding (source domain)
  // -----------------------------------------------------------------------
  always_ff @(posedge src_clk or negedge src_rst_n or posedge src_async_clr) begin
    if (!src_rst_n || src_async_clr) begin
      gray_src_cont_q <= '0;
      gray_src_snap_sync_q <= '0;
    end else begin
      gray_src_cont_q      <= bin_q ^ (bin_q >> 1);
      gray_src_snap_sync_q <= bin_snap_q ^ (bin_snap_q >> 1);
    end
  end

  // -----------------------------------------------------------------------
  // Async STOP-edge snapshot (optional)
  // -----------------------------------------------------------------------
  // The slow counter uses this path so the exported coarse count represents
  // the true STOP boundary instead of a later CAPTURE-time observation.
  // Capturing the Gray code keeps the ambiguity bounded to at most one count
  // when STOP lands close to a source-clock edge.
  always_ff @(posedge src_async_latch_p or negedge src_rst_n or posedge src_async_clr) begin
    if (!src_rst_n || src_async_clr)
      gray_src_snap_async_q <= '0;
    else
      gray_src_snap_async_q <= gray_src_cont_q;
  end

  assign gray_src_snap_sel = USE_ASYNC_SNAPSHOT ? gray_src_snap_async_q
                                                : gray_src_snap_sync_q;

  // -----------------------------------------------------------------------
  // 2-FF synchroniser chains (destination domain), annotated for placement
  // -----------------------------------------------------------------------
  (* ASYNC_REG = "TRUE" *) logic [W-1:0] gray_cont_ff1_async;
  (* ASYNC_REG = "TRUE" *) logic [W-1:0] gray_cont_ff2_async;
  (* ASYNC_REG = "TRUE" *) logic [W-1:0] gray_snap_ff1_async;
  (* ASYNC_REG = "TRUE" *) logic [W-1:0] gray_snap_ff2_async;

  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      gray_cont_ff1_async <= '0;
      gray_cont_ff2_async <= '0;
      gray_snap_ff1_async <= '0;
      gray_snap_ff2_async <= '0;
    end else begin
      gray_cont_ff1_async <= gray_src_cont_q;
      gray_cont_ff2_async <= gray_cont_ff1_async;
      gray_snap_ff1_async <= gray_src_snap_sel;
      gray_snap_ff2_async <= gray_snap_ff1_async;
    end
  end

  assign gray_cont_ff1 = gray_cont_ff1_async;
  assign gray_cont_ff2 = gray_cont_ff2_async;
  assign gray_snap_ff1 = gray_snap_ff1_async;
  assign gray_snap_ff2 = gray_snap_ff2_async;

  // -----------------------------------------------------------------------
  // Gray-to-binary decoding (combinational)
  // -----------------------------------------------------------------------
  always_comb begin
    bin_dec_cont[W-1] = gray_cont_ff2[W-1];
    bin_dec_snap[W-1] = gray_snap_ff2[W-1];
    for (int i = W-2; i >= 0; i--) begin
      bin_dec_cont[i] = bin_dec_cont[i+1] ^ gray_cont_ff2[i];
      bin_dec_snap[i] = bin_dec_snap[i+1] ^ gray_snap_ff2[i];
    end
  end

  // -----------------------------------------------------------------------
  // Destination-domain output registers
  // -----------------------------------------------------------------------
  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      dst_count_continuous <= '0;
      dst_count_latched    <= '0;
    end else begin
      dst_count_continuous <= bin_dec_cont;
      if (USE_ASYNC_SNAPSHOT)
        dst_count_latched <= bin_dec_snap;
      else if (dst_latch_p) begin
        dst_count_latched <= bin_dec_snap;
      end
    end
  end

endmodule

`default_nettype wire
