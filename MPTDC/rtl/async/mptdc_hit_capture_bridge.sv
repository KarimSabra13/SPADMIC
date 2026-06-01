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
  input  wire [SLOW_EPOCH_STAGES-1:0] slow_epoch_johnson_stop_i,
  input  wire [NFAST_W-1:0]           nfast_snap_i,
  input  wire [NFAST_W-1:0]           nfast_stop_i,
  input  wire                         phase0_snap_i,
  input  stop_phase_disc_t            stop_slow_phase_disc_i,
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
      snapshot_q.nslow_snap        <= slow_johnson_to_count(slow_epoch_johnson_stop_i);
      snapshot_q.nfast_snap        <= nfast_snap_i;
      snapshot_q.nfast_stop        <= nfast_stop_i;
      snapshot_q.phase0_snap       <= phase0_snap_i;
      snapshot_q.stop_slow_phase_disc <= stop_slow_phase_disc_i;
      snapshot_q.slow_boundary_inc <= slow_boundary_inc_i;
      snapshot_q.hit_count         <= '0;
      snapshot_q.flags             <= '0;
    end
  end

  assign snapshot_o = snapshot_q;

  // synthesis translate_off
  mptdc_ctx_snapshot_t snapshot_prev_q;
  logic                snapshot_prev_valid_q;
  logic                sample_en_prev_q;

  always_ff @(posedge clk_sys) begin
    if (!rst_n) begin
      snapshot_prev_q       <= '0;
      snapshot_prev_valid_q <= 1'b0;
      sample_en_prev_q      <= 1'b0;
    end else begin
      if (snapshot_prev_valid_q && !sample_en_i && !sample_en_prev_q) begin
        assert (snapshot_q == snapshot_prev_q)
          else $error("mptdc_hit_capture_bridge: snapshot changed without sample_en_i");
      end
      snapshot_prev_q       <= snapshot_q;
      snapshot_prev_valid_q <= 1'b1;
      sample_en_prev_q      <= sample_en_i;
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
