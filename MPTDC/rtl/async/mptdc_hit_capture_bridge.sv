`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.5
// File     : mptdc_hit_capture_bridge.sv
// Purpose  : Static-bus CDC bridge from held Vernier measurement fabric into
//            clk_sys. The source-side PD/counter values are levels that remain
//            stable until pd_clear_o, not one-cycle pulses.
// =============================================================================
module mptdc_hit_capture_bridge
  import mptdc_pkg::*;
(
  input  wire                         clk_sys,
  input  wire                         rst_n,

  input  wire                         sample_en_i,

  input  wire [PD_N-1:0]              pd_hit_level_i,
  input  wire [PD_N*NFAST_W-1:0]      pd_nfast_hit_packed_i,
  input  wire [NSLOW_W-1:0]           nslow_snap_i,
  input  wire [NFAST_W-1:0]           nfast_snap_i,
  input  wire [NFAST_W-1:0]           nfast_stop_i,
  input  wire                         phase0_snap_i,
  input  wire                         slow_boundary_inc_i,

  output mptdc_ctx_snapshot_t         snapshot_o
);

  mptdc_ctx_snapshot_t snapshot_q;

  always_ff @(posedge clk_sys) begin
    if (!rst_n) begin
      snapshot_q <= '0;
    end else if (sample_en_i) begin
      snapshot_q.hit_level         <= pd_hit_level_i;
      snapshot_q.nfast_hit_packed  <= pd_nfast_hit_packed_i;
      snapshot_q.nslow_snap        <= nslow_snap_i;
      snapshot_q.nfast_snap        <= nfast_snap_i;
      snapshot_q.nfast_stop        <= nfast_stop_i;
      snapshot_q.phase0_snap       <= phase0_snap_i;
      snapshot_q.slow_boundary_inc <= slow_boundary_inc_i;
      snapshot_q.hit_count         <= '0;
      snapshot_q.flags             <= '0;
    end
  end

  assign snapshot_o = snapshot_q;

endmodule

`default_nettype wire
