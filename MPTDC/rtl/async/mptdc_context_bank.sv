`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.2 — Design Review Enhanced Vernier TDC
// File     : mptdc_context_bank.sv
// Purpose  : Multi-context snapshot store — freezes one completed measurement
//            image per context for later sys-domain draining.
// Author   : Karim Sabra
// =============================================================================
// Stored fields per context:
//   - full PD hit bitmap and packed per-cell nfast_hit values
//   - STOP-side nslow, CAPTURE-side nfast_snap, and boundary metadata
//   - hit_count and close flags
//
// CDC contract:
//   - write side runs on clk_fast. snapshot_en_i freezes one completed image
//     into holding registers, then capture_en_i commits that frozen image to
//     the selected drainable context.
//   - read side is a combinational mux consumed from clk_sys only after the
//     corresponding ctx_drain bit has crossed into clk_sys and the snapshot is
//     guaranteed static
//
// Storage stays fully packed for clean synthesis and Verilator compatibility.
// =============================================================================

module mptdc_context_bank
  import mptdc_pkg::*;
(
  // ── clock ────────────────────────────────────────────────────────
  input  wire                           clk_fast,

  // ── write (capture) port ─────────────────────────────────────────
  input  wire  ctx_id_t                 capture_ctx_i,
  input  wire                           snapshot_en_i,
  input  wire                           capture_en_i,

  input  wire  [PD_N-1:0]              pd_hit_level_i,
  input  wire  [PD_N*NFAST_W-1:0]      pd_nfast_hit_packed_i,
  input  wire  [NSLOW_W-1:0]           nslow_snap_i,
  input  wire  [NFAST_W-1:0]           nfast_snap_i,
  input  wire  [NFAST_W-1:0]           nfast_stop_i,          // v2.3: fast counter at STOP
  input  wire                           phase0_snap_i,
  input  wire                           slow_boundary_inc_i, // v2.2: boundary carry
  input  wire  [MAX_HITS_W-1:0]        hit_count_i,
  input  wire  tdc_conv_flags_t        flags_i,

  // ── read port ────────────────────────────────────────────────────
  input  wire  ctx_id_t                 read_ctx_i,
  output mptdc_ctx_snapshot_t           snapshot_o
);

  // ================================================================
  // Context storage — N_CTX entries, fully packed arrays so the whole
  // snapshot remains easy to infer and easy to move through tools.
  // ================================================================
  logic [PD_N-1:0]            ctx_hit_level    [N_CTX];
  logic [PD_N*NFAST_W-1:0]   ctx_nfast_packed  [N_CTX];
  logic [NSLOW_W-1:0]        ctx_nslow_snap   [N_CTX];
  logic [NFAST_W-1:0]        ctx_nfast_snap   [N_CTX];
  logic [NFAST_W-1:0]        ctx_nfast_stop   [N_CTX];  // v2.3
  logic                      ctx_phase0       [N_CTX];
  logic                      ctx_boundary_inc [N_CTX]; // v2.2
  logic [MAX_HITS_W-1:0]     ctx_hit_count    [N_CTX];
  tdc_conv_flags_t           ctx_flags        [N_CTX];

  ctx_id_t                    hold_ctx;
  logic [PD_N-1:0]            hold_hit_level;
  logic [PD_N*NFAST_W-1:0]   hold_nfast_packed;
  logic [NSLOW_W-1:0]        hold_nslow_snap;
  logic [NFAST_W-1:0]        hold_nfast_snap;
  logic [NFAST_W-1:0]        hold_nfast_stop;
  logic                      hold_phase0;
  logic                      hold_boundary_inc;
  logic [MAX_HITS_W-1:0]     hold_hit_count;
  tdc_conv_flags_t           hold_flags;

  // ================================================================
  // Write port — freeze wide data first, then commit the frozen image. This
  // keeps the high-fanout context-bank write mux off the raw PD/counter path.
  // ================================================================
  always_ff @(posedge clk_fast) begin
    if (snapshot_en_i) begin
      hold_ctx          <= capture_ctx_i;
      hold_hit_level    <= pd_hit_level_i;
      hold_nfast_packed <= pd_nfast_hit_packed_i;
      hold_nslow_snap   <= nslow_snap_i;
      hold_nfast_snap   <= nfast_snap_i;
      hold_nfast_stop   <= nfast_stop_i;
      hold_phase0       <= phase0_snap_i;
      hold_boundary_inc <= slow_boundary_inc_i;
      hold_hit_count    <= hit_count_i;
      hold_flags        <= flags_i;
    end

    if (capture_en_i) begin
      ctx_hit_level   [hold_ctx] <= hold_hit_level;
      ctx_nfast_packed[hold_ctx] <= hold_nfast_packed;
      ctx_nslow_snap  [hold_ctx] <= hold_nslow_snap;
      ctx_nfast_snap  [hold_ctx] <= hold_nfast_snap;
      ctx_nfast_stop  [hold_ctx] <= hold_nfast_stop;   // v2.3
      ctx_phase0      [hold_ctx] <= hold_phase0;
      ctx_boundary_inc[hold_ctx] <= hold_boundary_inc;
      ctx_hit_count   [hold_ctx] <= hold_hit_count;
      ctx_flags       [hold_ctx] <= hold_flags;
    end
  end

  // ================================================================
  // Read port — combinational mux from selected context.
  // drain_ctrl only consumes this bus after ctx_drain has completed
  // the 2-FF handoff into clk_sys, so the selected snapshot is static.
  // ================================================================
  assign snapshot_o.hit_level        = ctx_hit_level    [read_ctx_i];
  assign snapshot_o.nfast_hit_packed = ctx_nfast_packed [read_ctx_i];
  assign snapshot_o.nslow_snap       = ctx_nslow_snap   [read_ctx_i];
  assign snapshot_o.nfast_snap       = ctx_nfast_snap   [read_ctx_i];
  assign snapshot_o.nfast_stop       = ctx_nfast_stop   [read_ctx_i];  // v2.3
  assign snapshot_o.phase0_snap       = ctx_phase0        [read_ctx_i];
  assign snapshot_o.slow_boundary_inc = ctx_boundary_inc  [read_ctx_i];
  assign snapshot_o.hit_count         = ctx_hit_count     [read_ctx_i];
  assign snapshot_o.flags             = ctx_flags         [read_ctx_i];

endmodule : mptdc_context_bank

`default_nettype wire
