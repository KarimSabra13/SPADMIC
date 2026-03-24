// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// mptdc_context_bank.sv — Triple-buffer snapshot context bank
//
// Stores N_CTX (3) independent snapshot contexts, each holding a full
// PD-matrix capture.  One write port (capture) and one read port, both
// clocked by the fast oscillator (osc_fast_phase0).
//
// All storage is fully packed for Verilator/synthesis compatibility.

`timescale 1ns / 1ps
`default_nettype none

module mptdc_context_bank
  import mptdc_pkg::*;
(
  // ── clock ────────────────────────────────────────────────────────
  input  wire                           clk_fast,

  // ── write (capture) port ─────────────────────────────────────────
  input  wire  ctx_id_t                 capture_ctx_i,
  input  wire                           capture_en_i,

  input  wire  [PD_N-1:0]              pd_hit_level_i,
  input  wire  [PD_N*NFAST_W-1:0]      pd_nfast_hit_packed_i,
  input  wire  [NSLOW_W-1:0]           nslow_snap_i,
  input  wire  [NFAST_W-1:0]           nfast_snap_i,
  input  wire                           phase0_snap_i,
  input  wire  [MAX_HITS_W-1:0]        hit_count_i,
  input  wire  tdc_conv_flags_t        flags_i,

  // ── read port ────────────────────────────────────────────────────
  input  wire  ctx_id_t                 read_ctx_i,
  output mptdc_ctx_snapshot_t           snapshot_o
);

  // ================================================================
  // Context storage — N_CTX entries, fully packed
  // ================================================================
  logic [PD_N-1:0]            ctx_hit_level    [N_CTX];
  logic [PD_N*NFAST_W-1:0]   ctx_nfast_packed  [N_CTX];
  logic [NSLOW_W-1:0]        ctx_nslow_snap   [N_CTX];
  logic [NFAST_W-1:0]        ctx_nfast_snap   [N_CTX];
  logic                      ctx_phase0       [N_CTX];
  logic [MAX_HITS_W-1:0]     ctx_hit_count    [N_CTX];
  tdc_conv_flags_t           ctx_flags        [N_CTX];

  // ================================================================
  // Write port — latch all inputs on capture_en_i
  // ================================================================
  always_ff @(posedge clk_fast) begin
    if (capture_en_i) begin
      ctx_hit_level   [capture_ctx_i] <= pd_hit_level_i;
      ctx_nfast_packed[capture_ctx_i] <= pd_nfast_hit_packed_i;
      ctx_nslow_snap  [capture_ctx_i] <= nslow_snap_i;
      ctx_nfast_snap  [capture_ctx_i] <= nfast_snap_i;
      ctx_phase0      [capture_ctx_i] <= phase0_snap_i;
      ctx_hit_count   [capture_ctx_i] <= hit_count_i;
      ctx_flags       [capture_ctx_i] <= flags_i;
    end
  end

  // ================================================================
  // Read port — combinational mux from selected context
  // ================================================================
  assign snapshot_o.hit_level        = ctx_hit_level   [read_ctx_i];
  assign snapshot_o.nfast_hit_packed = ctx_nfast_packed [read_ctx_i];
  assign snapshot_o.nslow_snap       = ctx_nslow_snap  [read_ctx_i];
  assign snapshot_o.nfast_snap       = ctx_nfast_snap  [read_ctx_i];
  assign snapshot_o.phase0_snap      = ctx_phase0      [read_ctx_i];
  assign snapshot_o.hit_count        = ctx_hit_count   [read_ctx_i];
  assign snapshot_o.flags            = ctx_flags       [read_ctx_i];

endmodule : mptdc_context_bank

`default_nettype wire
