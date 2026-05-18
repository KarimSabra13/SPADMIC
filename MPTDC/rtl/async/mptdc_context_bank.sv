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
//   - write side runs on clk_fast. snapshot_en_i/capture_en_i are first
//     registered into row-local enable copies. One cycle later those local
//     enables freeze/commit the completed image row-by-row.
//   - read side is a combinational mux consumed from clk_sys only after the
//     corresponding ctx_drain bit has crossed into clk_sys and the snapshot is
//     guaranteed static
//
// Wide PD payload storage is row-banked to avoid one global enable driving the
// full 64-cell timestamp matrix in a single 0.9 ns fast-clock cycle.
// =============================================================================

module mptdc_context_bank
  import mptdc_pkg::*;
(
  // ── clock ────────────────────────────────────────────────────────
  input  wire                           clk_fast,
  input  wire                           rst_n,

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
  // Context storage — row-banked PD payload plus scalar metadata.
  // ================================================================
  localparam int unsigned ROW_HIT_W   = NE;
  localparam int unsigned ROW_NFAST_W = NE * NFAST_W;

  logic [ROW_HIT_W-1:0]      ctx_hit_row       [N_CTX][NE];
  logic [ROW_NFAST_W-1:0]    ctx_nfast_row     [N_CTX][NE];
  logic [NSLOW_W-1:0]        ctx_nslow_snap   [N_CTX];
  logic [NFAST_W-1:0]        ctx_nfast_snap   [N_CTX];
  logic [NFAST_W-1:0]        ctx_nfast_stop   [N_CTX];  // v2.3
  logic                      ctx_phase0       [N_CTX];
  logic                      ctx_boundary_inc [N_CTX]; // v2.2
  logic [MAX_HITS_W-1:0]     ctx_hit_count    [N_CTX];
  tdc_conv_flags_t           ctx_flags        [N_CTX];

  ctx_id_t                    hold_ctx;
  logic [ROW_HIT_W-1:0]      hold_hit_row      [NE];
  logic [ROW_NFAST_W-1:0]    hold_nfast_row    [NE];
  logic [NSLOW_W-1:0]        hold_nslow_snap;
  logic [NFAST_W-1:0]        hold_nfast_snap;
  logic [NFAST_W-1:0]        hold_nfast_stop;
  logic                      hold_phase0;
  logic                      hold_boundary_inc;
  logic [MAX_HITS_W-1:0]     hold_hit_count;
  tdc_conv_flags_t           hold_flags;
  logic [NE-1:0]              snapshot_row_en_q;
  logic [NE-1:0]              capture_row_en_q;
  logic                       snapshot_meta_en_q;
  logic                       capture_meta_en_q;

  logic [PD_N-1:0]            snapshot_hit_level;
  logic [PD_N*NFAST_W-1:0]   snapshot_nfast_packed;
  logic [PD_N-1:0]            hold_hit_level;
  logic [PD_N*NFAST_W-1:0]   hold_nfast_packed;

  // ================================================================
  // Write port — local enable copies drive row banks one cycle after the
  // controller pulse, avoiding one global high-fanout write enable.
  // ================================================================
  always_ff @(posedge clk_fast) begin
    if (!rst_n) begin
      snapshot_row_en_q  <= '0;
      capture_row_en_q   <= '0;
      snapshot_meta_en_q <= 1'b0;
      capture_meta_en_q  <= 1'b0;
    end else begin
      snapshot_row_en_q  <= {NE{snapshot_en_i}};
      capture_row_en_q   <= {NE{capture_en_i}};
      snapshot_meta_en_q <= snapshot_en_i;
      capture_meta_en_q  <= capture_en_i;
    end

    for (int r = 0; r < NE; r++) begin
      if (snapshot_row_en_q[r]) begin
        hold_hit_row[r]   <= pd_hit_level_i[r * ROW_HIT_W +: ROW_HIT_W];
        hold_nfast_row[r] <= pd_nfast_hit_packed_i[r * ROW_NFAST_W +: ROW_NFAST_W];
      end

      if (capture_row_en_q[r]) begin
        ctx_hit_row  [hold_ctx][r] <= hold_hit_row[r];
        ctx_nfast_row[hold_ctx][r] <= hold_nfast_row[r];
      end
    end

    if (snapshot_meta_en_q) begin
      hold_ctx          <= capture_ctx_i;
      hold_nslow_snap   <= nslow_snap_i;
      hold_nfast_snap   <= nfast_snap_i;
      hold_nfast_stop   <= nfast_stop_i;
      hold_phase0       <= phase0_snap_i;
      hold_boundary_inc <= slow_boundary_inc_i;
      hold_hit_count    <= hit_count_i;
      hold_flags        <= flags_i;
    end

    if (capture_meta_en_q) begin
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
  always_comb begin
    snapshot_hit_level = '0;
    snapshot_nfast_packed = '0;
    hold_hit_level = '0;
    hold_nfast_packed = '0;
    for (int r = 0; r < NE; r++) begin
      snapshot_hit_level[r * ROW_HIT_W +: ROW_HIT_W] =
          ctx_hit_row[read_ctx_i][r];
      snapshot_nfast_packed[r * ROW_NFAST_W +: ROW_NFAST_W] =
          ctx_nfast_row[read_ctx_i][r];
      hold_hit_level[r * ROW_HIT_W +: ROW_HIT_W] = hold_hit_row[r];
      hold_nfast_packed[r * ROW_NFAST_W +: ROW_NFAST_W] = hold_nfast_row[r];
    end
  end

  assign snapshot_o.hit_level        = snapshot_hit_level;
  assign snapshot_o.nfast_hit_packed = snapshot_nfast_packed;
  assign snapshot_o.nslow_snap       = ctx_nslow_snap   [read_ctx_i];
  assign snapshot_o.nfast_snap       = ctx_nfast_snap   [read_ctx_i];
  assign snapshot_o.nfast_stop       = ctx_nfast_stop   [read_ctx_i];  // v2.3
  assign snapshot_o.phase0_snap       = ctx_phase0        [read_ctx_i];
  assign snapshot_o.slow_boundary_inc = ctx_boundary_inc  [read_ctx_i];
  assign snapshot_o.hit_count         = ctx_hit_count     [read_ctx_i];
  assign snapshot_o.flags             = ctx_flags         [read_ctx_i];

endmodule : mptdc_context_bank

`default_nettype wire
