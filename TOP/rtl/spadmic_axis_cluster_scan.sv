// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_axis_cluster_scan.sv
// Purpose  : Scan one axis bitmap and report up to two clusters plus overflow.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_axis_cluster_scan #(
  parameter int unsigned LINE_W = spadmic_pkg::SPADMIC_LINE_W
) (
  input  wire [LINE_W-1:0]               lines_i,
  input  wire [$clog2(LINE_W + 1)-1:0]   gap_threshold_i,
  output spadmic_pkg::spadmic_axis_clusters_t clusters_o
);
  import spadmic_pkg::*;

  localparam int unsigned LINE_COUNT_W = $clog2(LINE_W + 1);

  spadmic_axis_clusters_t result_r;

  // A new cluster starts only after a gap of at least gap_threshold_i zeros.
  // Additional qualifying clusters beyond cluster1 raise overflow instead.
  always_comb begin
    logic in_cluster;
    logic [LINE_COUNT_W-1:0] gap_run;
    int unsigned cluster_idx;

    result_r    = '0;
    result_r.empty = 1'b1;
    in_cluster  = 1'b0;
    gap_run     = '0;
    cluster_idx = 0;

    for (int i = 0; i < LINE_W; i++) begin
      if (lines_i[i]) begin
        if (!in_cluster) begin
          if ((cluster_idx == 0) && !result_r.cluster0.valid) begin
            result_r.cluster0.valid = 1'b1;
            result_r.cluster0.lo    = SPADMIC_LINE_IDX_W'(i);
            result_r.cluster0.hi    = SPADMIC_LINE_IDX_W'(i);
          end else if ((cluster_idx == 0) && (gap_run >= gap_threshold_i)) begin
            cluster_idx = 1;
            if (!result_r.cluster1.valid) begin
              result_r.cluster1.valid = 1'b1;
              result_r.cluster1.lo    = SPADMIC_LINE_IDX_W'(i);
              result_r.cluster1.hi    = SPADMIC_LINE_IDX_W'(i);
            end
          end else if ((cluster_idx >= 1) && (gap_run >= gap_threshold_i)) begin
            result_r.overflow = 1'b1;
          end else if (cluster_idx == 0) begin
            result_r.cluster0.hi = SPADMIC_LINE_IDX_W'(i);
          end else if ((cluster_idx == 1) && !result_r.overflow) begin
            result_r.cluster1.hi = SPADMIC_LINE_IDX_W'(i);
          end
          in_cluster = 1'b1;
          gap_run    = '0;
        end else begin
          gap_run = '0;
          if (cluster_idx == 0)
            result_r.cluster0.hi = SPADMIC_LINE_IDX_W'(i);
          else if ((cluster_idx == 1) && !result_r.overflow)
            result_r.cluster1.hi = SPADMIC_LINE_IDX_W'(i);
        end
      end else if (in_cluster) begin
        gap_run = gap_run + LINE_COUNT_W'(1);
        if (gap_run >= gap_threshold_i)
          in_cluster = 1'b0;
      end
    end

    result_r.empty = ~result_r.cluster0.valid;
    result_r.cluster_count = {
      1'b0,
      result_r.cluster0.valid
    } + {
      1'b0,
      result_r.cluster1.valid
    };
  end

  assign clusters_o = result_r;

endmodule

`default_nettype wire
