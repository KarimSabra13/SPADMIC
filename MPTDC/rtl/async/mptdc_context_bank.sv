`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.5
// File     : mptdc_context_bank.sv
// Purpose  : System-clock context store for completed Vernier measurements.
// =============================================================================
module mptdc_context_bank
  import mptdc_pkg::*;
(
  input  wire                           clk_sys,
  input  wire                           rst_n,

  input  wire  ctx_id_t                 capture_ctx_i,
  input  wire                           capture_en_i,
  input  mptdc_ctx_snapshot_t           capture_snapshot_i,
  input  wire  [MAX_HITS_W-1:0]         hit_count_i,
  input  wire  tdc_conv_flags_t         flags_i,

  input  wire  ctx_id_t                 read_ctx_i,
  output mptdc_ctx_snapshot_t           snapshot_o
);

  mptdc_ctx_snapshot_t ctx_snapshot [N_CTX];
  mptdc_ctx_snapshot_t capture_snapshot_with_meta;

  always_comb begin
    capture_snapshot_with_meta           = capture_snapshot_i;
    capture_snapshot_with_meta.hit_count = hit_count_i;
    capture_snapshot_with_meta.flags     = flags_i;
  end

  always_ff @(posedge clk_sys) begin
    if (!rst_n) begin
      for (int i = 0; i < N_CTX; i++)
        ctx_snapshot[i] <= '0;
    end else if (capture_en_i) begin
      ctx_snapshot[capture_ctx_i] <= capture_snapshot_with_meta;
    end
  end

  assign snapshot_o = ctx_snapshot[read_ctx_i];

endmodule : mptdc_context_bank

`default_nettype wire
