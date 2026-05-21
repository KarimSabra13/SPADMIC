// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_axis_cluster_scan.sv
// Purpose  : Two-cycle scan of one axis bitmap, reporting up to two clusters
//            plus overflow for timing-safe standard-cell synthesis.
// Author   : Karim Sabra
//
// Timing note:
//   The original implementation scanned all 64 bits through one combinational
//   loop. This implementation registers the state after the lower half and
//   finishes the upper half in the next cycle. For the default 64-line axis, the
//   longest scan cone is bounded to 32 line updates plus small cluster-state
//   muxing, roughly half of the original worst-case FO4 depth.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_axis_cluster_scan #(
  parameter int unsigned LINE_W = spadmic_pkg::SPADMIC_LINE_W
) (
  input  wire                              clk_sys,
  input  wire                              rst_n,
  input  wire                              start_i,
  input  wire [LINE_W-1:0]                 lines_i,
  input  wire [$clog2(LINE_W + 1)-1:0]     gap_threshold_i,
  output logic                             busy_o,
  output logic                             valid_o,
  output spadmic_pkg::spadmic_axis_clusters_t clusters_o
);
  import spadmic_pkg::*;

  localparam int unsigned LINE_COUNT_W = $clog2(LINE_W + 1);
  localparam int unsigned LOWER_END    = (LINE_W + 1) / 2;

  typedef enum logic {
    SCAN_IDLE = 1'b0,
    SCAN_HIGH = 1'b1
  } scan_state_e;

  typedef struct packed {
    spadmic_axis_clusters_t             clusters;
    logic                               in_cluster;
    logic [LINE_COUNT_W-1:0]            gap_run;
    logic [1:0]                         cluster_idx;
  } scan_accum_t;

  scan_state_e                         state_q;
  scan_accum_t                         lower_accum_q;
  logic [LINE_W-1:0]                   lines_q;
  logic [LINE_COUNT_W-1:0]             gap_threshold_q;
  spadmic_axis_clusters_t              clusters_q;

  function automatic scan_accum_t scan_step(
    input scan_accum_t             state_i,
    input logic                    line_hit,
    input logic [SPADMIC_LINE_IDX_W-1:0] line_idx,
    input logic [LINE_COUNT_W-1:0] gap_threshold
  );
    scan_accum_t state;

    state = state_i;

    if (line_hit) begin
      if (!state.in_cluster) begin
        if ((state.cluster_idx == 2'd0) && !state.clusters.cluster0.valid) begin
          state.clusters.cluster0.valid = 1'b1;
          state.clusters.cluster0.lo    = line_idx;
          state.clusters.cluster0.hi    = line_idx;
        end else if ((state.cluster_idx == 2'd0) && (state.gap_run >= gap_threshold)) begin
          state.cluster_idx = 2'd1;
          if (!state.clusters.cluster1.valid) begin
            state.clusters.cluster1.valid = 1'b1;
            state.clusters.cluster1.lo    = line_idx;
            state.clusters.cluster1.hi    = line_idx;
          end
        end else if ((state.cluster_idx >= 2'd1) && (state.gap_run >= gap_threshold)) begin
          state.clusters.overflow = 1'b1;
        end else if (state.cluster_idx == 2'd0) begin
          state.clusters.cluster0.hi = line_idx;
        end else if ((state.cluster_idx == 2'd1) && !state.clusters.overflow) begin
          state.clusters.cluster1.hi = line_idx;
        end
        state.in_cluster = 1'b1;
        state.gap_run    = '0;
      end else begin
        state.gap_run = '0;
        if (state.cluster_idx == 2'd0)
          state.clusters.cluster0.hi = line_idx;
        else if ((state.cluster_idx == 2'd1) && !state.clusters.overflow)
          state.clusters.cluster1.hi = line_idx;
      end
    end else if (state.in_cluster) begin
      state.gap_run = state.gap_run + LINE_COUNT_W'(1);
      if (state.gap_run >= gap_threshold)
        state.in_cluster = 1'b0;
    end

    return state;
  endfunction

  function automatic scan_accum_t scan_lower_half(
    input logic [LINE_W-1:0]        lines,
    input logic [LINE_COUNT_W-1:0]  gap_threshold
  );
    scan_accum_t state;

    state = initial_accum();
    for (int unsigned i = 0; i < LOWER_END; i++) begin
      state = scan_step(state, lines[i], SPADMIC_LINE_IDX_W'(i), gap_threshold);
    end
    return state;
  endfunction

  function automatic scan_accum_t scan_upper_half(
    input scan_accum_t              state_i,
    input logic [LINE_W-1:0]        lines,
    input logic [LINE_COUNT_W-1:0]  gap_threshold
  );
    scan_accum_t state;

    state = state_i;
    for (int unsigned i = LOWER_END; i < LINE_W; i++) begin
      state = scan_step(state, lines[i], SPADMIC_LINE_IDX_W'(i), gap_threshold);
    end
    return state;
  endfunction

  function automatic scan_accum_t initial_accum();
    scan_accum_t state;

    state = '0;
    state.clusters.empty = 1'b1;
    return state;
  endfunction

  function automatic spadmic_axis_clusters_t finalize_clusters(
    input scan_accum_t state
  );
    spadmic_axis_clusters_t clusters;

    clusters = state.clusters;
    clusters.empty = ~clusters.cluster0.valid;
    clusters.cluster_count = {1'b0, clusters.cluster0.valid}
                           + {1'b0, clusters.cluster1.valid};
    return clusters;
  endfunction

  assign busy_o     = (state_q != SCAN_IDLE);
  assign clusters_o = clusters_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q         <= SCAN_IDLE;
      lower_accum_q   <= '0;
      lines_q         <= '0;
      gap_threshold_q <= '0;
      clusters_q      <= '0;
      valid_o         <= 1'b0;
    end else begin
      valid_o <= 1'b0;

      unique case (state_q)
        SCAN_IDLE: begin
          if (start_i) begin
            lines_q         <= lines_i;
            gap_threshold_q <= gap_threshold_i;
            lower_accum_q   <= scan_lower_half(lines_i, gap_threshold_i);
            state_q         <= SCAN_HIGH;
          end
        end

        default: begin
          clusters_q <= finalize_clusters(
            scan_upper_half(lower_accum_q, lines_q, gap_threshold_q)
          );
          valid_o <= 1'b1;
          state_q <= SCAN_IDLE;
        end
      endcase
    end
  end

endmodule

`default_nettype wire
