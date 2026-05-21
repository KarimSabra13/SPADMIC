// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_axis_cluster_scan.sv
// Purpose  : Five-cycle scan of one axis bitmap, reporting up to two clusters
//            plus overflow for timing-safe standard-cell synthesis.
// Author   : Karim Sabra
//
// Timing note:
//   The original implementation scanned all 64 bits through one combinational
//   loop, then a two-cycle version still carried state through 32 serial line
//   updates in one stage. This implementation captures the bitmap, summarizes
//   eight 8-bit chunks in parallel, then merges summaries through registered
//   8->4->2->1 stages. No timing stage contains more than one 8-bit local scan
//   or one summary merge, replacing the old O(N) state ripple with a shallow
//   pipelined reduction tree.
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
  localparam int unsigned CHUNK_W      = 8;
  localparam int unsigned CHUNK_COUNT  = (LINE_W + CHUNK_W - 1) / CHUNK_W;
  localparam int unsigned PAIR_COUNT   = (CHUNK_COUNT + 1) / 2;
  localparam int unsigned QUAD_COUNT   = (PAIR_COUNT + 1) / 2;

  typedef enum logic [2:0] {
    SCAN_IDLE  = 3'd0,
    SCAN_CHUNK = 3'd1,
    SCAN_PAIR  = 3'd2,
    SCAN_QUAD  = 3'd3,
    SCAN_FINAL = 3'd4
  } scan_state_e;

  typedef struct packed {
    spadmic_axis_clusters_t             clusters;
    logic                               in_cluster;
    logic [LINE_COUNT_W-1:0]            gap_run;
    logic [1:0]                         cluster_idx;
  } scan_accum_t;

  typedef struct packed {
    logic                               has_hit;
    logic [SPADMIC_LINE_IDX_W-1:0]      first_hit;
    logic [SPADMIC_LINE_IDX_W-1:0]      last_hit;
    spadmic_axis_clusters_t             clusters;
  } scan_summary_t;

  scan_state_e                         state_q;
  logic [LINE_W-1:0]                   lines_q;
  logic [LINE_COUNT_W-1:0]             gap_threshold_q;
  scan_summary_t                       chunk_q [CHUNK_COUNT];
  scan_summary_t                       pair_q  [PAIR_COUNT];
  scan_summary_t                       quad_q  [QUAD_COUNT];
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

  function automatic scan_summary_t summarize_chunk(
    input logic [CHUNK_W-1:0]       chunk_lines,
    input logic [SPADMIC_LINE_IDX_W-1:0] base_idx,
    input logic [LINE_COUNT_W-1:0]  gap_threshold
  );
    scan_accum_t   state;
    scan_summary_t summary;
    logic          first_seen;
    logic [SPADMIC_LINE_IDX_W-1:0] line_idx;

    state = initial_accum();
    summary = '0;
    first_seen = 1'b0;

    for (int unsigned i = 0; i < CHUNK_W; i++) begin
      line_idx = base_idx + SPADMIC_LINE_IDX_W'(i);
      state = scan_step(state, chunk_lines[i], line_idx, gap_threshold);
      if (chunk_lines[i]) begin
        if (!first_seen) begin
          summary.first_hit = line_idx;
          first_seen = 1'b1;
        end
        summary.last_hit = line_idx;
      end
    end

    summary.has_hit  = first_seen;
    summary.clusters = finalize_clusters(state);
    return summary;
  endfunction

  function automatic logic merge_across_boundary(
    input scan_summary_t            left,
    input scan_summary_t            right,
    input logic [LINE_COUNT_W-1:0]  gap_threshold
  );
    logic [LINE_COUNT_W-1:0] boundary_gap;

    boundary_gap = LINE_COUNT_W'(right.first_hit - left.last_hit - 1'b1);
    return (boundary_gap == '0) || (boundary_gap < gap_threshold);
  endfunction

  function automatic spadmic_axis_clusters_t normalize_clusters(
    input spadmic_axis_clusters_t clusters_i
  );
    spadmic_axis_clusters_t clusters;

    clusters = clusters_i;
    clusters.empty = ~(clusters.cluster0.valid | clusters.cluster1.valid);
    clusters.cluster_count = {1'b0, clusters.cluster0.valid}
                           + {1'b0, clusters.cluster1.valid};
    return clusters;
  endfunction

  function automatic scan_summary_t merge_summaries(
    input scan_summary_t            left,
    input scan_summary_t            right,
    input logic [LINE_COUNT_W-1:0]  gap_threshold
  );
    scan_summary_t result;
    logic          join_boundary;

    if (!left.has_hit)
      return right;
    if (!right.has_hit)
      return left;

    result = '0;
    result.has_hit   = 1'b1;
    result.first_hit = left.first_hit;
    result.last_hit  = right.last_hit;

    if (left.clusters.overflow) begin
      result.clusters = normalize_clusters(left.clusters);
      result.clusters.overflow = 1'b1;
      return result;
    end

    join_boundary = merge_across_boundary(left, right, gap_threshold);

    if (left.clusters.cluster_count == 2'd0) begin
      result.clusters = normalize_clusters(right.clusters);
    end else if (right.clusters.cluster_count == 2'd0) begin
      result.clusters = normalize_clusters(left.clusters);
    end else if (join_boundary) begin
      result.clusters.cluster0 = left.clusters.cluster0;
      result.clusters.cluster1 = left.clusters.cluster1;

      if (left.clusters.cluster_count == 2'd1) begin
        result.clusters.cluster0.hi = right.clusters.cluster0.hi;
        if (right.clusters.cluster1.valid)
          result.clusters.cluster1 = right.clusters.cluster1;
        result.clusters.overflow = right.clusters.overflow;
      end else begin
        result.clusters.cluster1.hi = right.clusters.cluster0.hi;
        result.clusters.overflow = right.clusters.overflow
                                | right.clusters.cluster1.valid;
      end
      result.clusters = normalize_clusters(result.clusters);
    end else begin
      result.clusters.cluster0 = left.clusters.cluster0;
      result.clusters.cluster1 = left.clusters.cluster1;

      if (left.clusters.cluster_count == 2'd1) begin
        result.clusters.cluster1 = right.clusters.cluster0;
        result.clusters.overflow = right.clusters.overflow
                                | right.clusters.cluster1.valid;
      end else begin
        result.clusters.overflow = 1'b1;
      end
      result.clusters = normalize_clusters(result.clusters);
    end

    return result;
  endfunction

  function automatic spadmic_axis_clusters_t merge_final_clusters(
    input scan_summary_t            left,
    input scan_summary_t            right,
    input logic [LINE_COUNT_W-1:0]  gap_threshold
  );
    scan_summary_t final_summary;

    final_summary = merge_summaries(left, right, gap_threshold);
    return final_summary.clusters;
  endfunction

  assign busy_o     = (state_q != SCAN_IDLE);
  assign clusters_o = clusters_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q         <= SCAN_IDLE;
      lines_q         <= '0;
      gap_threshold_q <= '0;
      chunk_q         <= '{default: '0};
      pair_q          <= '{default: '0};
      quad_q          <= '{default: '0};
      clusters_q      <= '0;
      valid_o         <= 1'b0;
    end else begin
      valid_o <= 1'b0;

      unique case (state_q)
        SCAN_IDLE: begin
          if (start_i) begin
            lines_q         <= lines_i;
            gap_threshold_q <= gap_threshold_i;
            state_q         <= SCAN_CHUNK;
          end
        end

        SCAN_CHUNK: begin
          for (int unsigned chunk = 0; chunk < CHUNK_COUNT; chunk++) begin
            chunk_q[chunk] <= summarize_chunk(
              lines_q[(chunk * CHUNK_W) +: CHUNK_W],
              SPADMIC_LINE_IDX_W'(chunk * CHUNK_W),
              gap_threshold_q
            );
          end
          state_q <= SCAN_PAIR;
        end

        SCAN_PAIR: begin
          for (int unsigned pair_idx = 0; pair_idx < PAIR_COUNT; pair_idx++) begin
            pair_q[pair_idx] <= merge_summaries(
              chunk_q[pair_idx * 2],
              chunk_q[(pair_idx * 2) + 1],
              gap_threshold_q
            );
          end
          state_q <= SCAN_QUAD;
        end

        SCAN_QUAD: begin
          for (int unsigned quad_idx = 0; quad_idx < QUAD_COUNT; quad_idx++) begin
            quad_q[quad_idx] <= merge_summaries(
              pair_q[quad_idx * 2],
              pair_q[(quad_idx * 2) + 1],
              gap_threshold_q
            );
          end
          state_q <= SCAN_FINAL;
        end

        default: begin
          clusters_q <= merge_final_clusters(
            quad_q[0],
            quad_q[1],
            gap_threshold_q
          );
          valid_o <= 1'b1;
          state_q <= SCAN_IDLE;
        end
      endcase
    end
  end

endmodule

`default_nettype wire
