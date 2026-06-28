// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_position_snapshot_packetizer.sv
// Purpose  : Raw/cluster position packet producer from the protected matrix
//            snapshot. This block owns a private copy of the snapshot before
//            packet serialization so matrix reset can proceed after capture.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_position_snapshot_packetizer #(
  parameter int unsigned LINE_W = spadmic_pkg::SPADMIC_LINE_W
) (
  input  logic                         clk_sys,
  input  logic                         rst_n,
  input  logic                         start_i,
  input  spadmic_pkg::spadmic_pos_mode_e mode_i,
  input  logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_i,
  input  logic [LINE_W-1:0]            snapshot_R_i,
  input  logic [LINE_W-1:0]            snapshot_Y_i,
  input  logic [LINE_W-1:0]            snapshot_B_i,
  input  logic [$clog2(LINE_W + 1)-1:0] gap_threshold_i,
  input  logic [$clog2(LINE_W + 1)-1:0] min_cluster_span_i,

  output logic                         pkt_valid_o,
  input  logic                         pkt_ready_i,
  output logic [mptdc_pkg::NARROW_W-1:0] pkt_data_o,
  output logic                         pkt_sop_o,
  output logic                         pkt_eop_o,
  output logic                         packet_pending_o,
  output logic                         busy_o,
  output logic                         snapshot_captured_o,
  output logic                         done_o,
  output logic                         drop_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int unsigned RAW_WORDS_PER_AXIS =
      (LINE_W + NARROW_W - 1) / NARROW_W;
  localparam int unsigned RAW_PKT_WORDS = 1 + (3 * RAW_WORDS_PER_AXIS) + 1;
  localparam int unsigned MAX_PKT_WORDS =
      (RAW_PKT_WORDS > SPADMIC_POS_PKT_WORDS) ? RAW_PKT_WORDS :
                                                SPADMIC_POS_PKT_WORDS;
  localparam int unsigned WORD_IDX_W = $clog2(MAX_PKT_WORDS);
  localparam int unsigned LINE_COUNT_W = $clog2(LINE_W + 1);

  typedef enum logic [1:0] {
    POS_IDLE = 2'd0,
    POS_SCAN = 2'd1,
    POS_SEND = 2'd2
  } pos_state_e;

  logic [LINE_W-1:0] r_snapshot_q;
  logic [LINE_W-1:0] y_snapshot_q;
  logic [LINE_W-1:0] b_snapshot_q;
  logic [SPADMIC_EVENT_ID_W-1:0] event_id_q;
  logic [WORD_IDX_W-1:0] word_idx_q;
  pos_state_e state_q;
  spadmic_pos_mode_e mode_q;
  logic [LINE_COUNT_W-1:0] gap_threshold_q;
  logic [LINE_COUNT_W-1:0] min_cluster_span_q;
  logic scan_start_q;
  logic r_scan_busy;
  logic y_scan_busy;
  logic b_scan_busy;
  logic r_scan_valid;
  logic y_scan_valid;
  logic b_scan_valid;
  spadmic_axis_clusters_t r_clusters_raw;
  spadmic_axis_clusters_t y_clusters_raw;
  spadmic_axis_clusters_t b_clusters_raw;
  spadmic_axis_clusters_t r_clusters_filtered;
  spadmic_axis_clusters_t y_clusters_filtered;
  spadmic_axis_clusters_t b_clusters_filtered;
  spadmic_axis_clusters_t r_clusters_q;
  spadmic_axis_clusters_t y_clusters_q;
  spadmic_axis_clusters_t b_clusters_q;
  logic [2:0] cluster_non_empty_mask_next;
  logic [2:0] cluster_multi_cluster_mask_next;
  logic cluster_overflow_any_next;
  logic [2:0] cluster_non_empty_mask_q;
  logic [2:0] cluster_multi_cluster_mask_q;
  logic cluster_overflow_any_q;
  logic [WORD_IDX_W-1:0] last_word_idx;

  wire out_accepted = pkt_valid_o && pkt_ready_i;
  wire last_word = (word_idx_q == last_word_idx);
  wire [2:0] non_empty_mask = {
      |b_snapshot_q,
      |y_snapshot_q,
      |r_snapshot_q
  };
  wire scans_complete = r_scan_valid && y_scan_valid && b_scan_valid;

  function automatic logic [NARROW_W-1:0] raw_word_from_lines(
    input logic [LINE_W-1:0] lines,
    input int unsigned       raw_word_idx
  );
    logic [NARROW_W-1:0] word;
    int unsigned bit_base;

    word = '0;
    bit_base = raw_word_idx * NARROW_W;
    for (int bit_idx = 0; bit_idx < NARROW_W; bit_idx++) begin
      if ((bit_base + bit_idx) < LINE_W)
        word[bit_idx] = lines[bit_base + bit_idx];
    end

    return word;
  endfunction

  function automatic spadmic_cluster_t filter_cluster(
    input spadmic_cluster_t cluster,
    input logic [LINE_COUNT_W-1:0] min_span
  );
    spadmic_cluster_t filtered;

    filtered = cluster;
    if (!cluster.valid || (spadmic_cluster_span(cluster) < min_span)) begin
      filtered.valid = 1'b0;
      filtered.lo    = '0;
      filtered.hi    = '0;
    end

    return filtered;
  endfunction

  function automatic spadmic_axis_clusters_t filter_axis_clusters(
    input spadmic_axis_clusters_t clusters,
    input logic [LINE_COUNT_W-1:0] min_span
  );
    spadmic_axis_clusters_t filtered;

    filtered = clusters;
    filtered.cluster0 = filter_cluster(clusters.cluster0, min_span);
    filtered.cluster1 = filter_cluster(clusters.cluster1, min_span);
    filtered.empty = ~(filtered.cluster0.valid | filtered.cluster1.valid);
    filtered.cluster_count = {1'b0, filtered.cluster0.valid}
                           + {1'b0, filtered.cluster1.valid};

    return filtered;
  endfunction

  function automatic logic [NARROW_W-1:0] cluster_word_from_index(
    input logic [WORD_IDX_W-1:0] word_idx
  );
    spadmic_cluster_t cluster;

    cluster = '0;
    unique case (word_idx)
      WORD_IDX_W'(1): cluster = r_clusters_q.cluster0;
      WORD_IDX_W'(2): cluster = r_clusters_q.cluster1;
      WORD_IDX_W'(3): cluster = y_clusters_q.cluster0;
      WORD_IDX_W'(4): cluster = y_clusters_q.cluster1;
      WORD_IDX_W'(5): cluster = b_clusters_q.cluster0;
      WORD_IDX_W'(6): cluster = b_clusters_q.cluster1;
      default: cluster = '0;
    endcase

    return spadmic_pos_cluster_word(cluster);
  endfunction

  spadmic_axis_cluster_scan #(.LINE_W(LINE_W)) u_r_cluster_scan (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .start_i         (scan_start_q),
    .lines_i         (r_snapshot_q),
    .gap_threshold_i (gap_threshold_q),
    .busy_o          (r_scan_busy),
    .valid_o         (r_scan_valid),
    .clusters_o      (r_clusters_raw)
  );

  spadmic_axis_cluster_scan #(.LINE_W(LINE_W)) u_y_cluster_scan (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .start_i         (scan_start_q),
    .lines_i         (y_snapshot_q),
    .gap_threshold_i (gap_threshold_q),
    .busy_o          (y_scan_busy),
    .valid_o         (y_scan_valid),
    .clusters_o      (y_clusters_raw)
  );

  spadmic_axis_cluster_scan #(.LINE_W(LINE_W)) u_b_cluster_scan (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .start_i         (scan_start_q),
    .lines_i         (b_snapshot_q),
    .gap_threshold_i (gap_threshold_q),
    .busy_o          (b_scan_busy),
    .valid_o         (b_scan_valid),
    .clusters_o      (b_clusters_raw)
  );

  always_comb begin
    if (mode_q == SPADMIC_POS_MODE_RAW)
      last_word_idx = WORD_IDX_W'(RAW_PKT_WORDS - 1);
    else
      last_word_idx = WORD_IDX_W'(SPADMIC_POS_PKT_WORDS - 1);
  end

  always_comb begin
    r_clusters_filtered = filter_axis_clusters(r_clusters_raw,
                                               min_cluster_span_q);
    y_clusters_filtered = filter_axis_clusters(y_clusters_raw,
                                               min_cluster_span_q);
    b_clusters_filtered = filter_axis_clusters(b_clusters_raw,
                                               min_cluster_span_q);
    cluster_non_empty_mask_next = {
        !b_clusters_filtered.empty,
        !y_clusters_filtered.empty,
        !r_clusters_filtered.empty
    };
    cluster_multi_cluster_mask_next = {
        (b_clusters_filtered.cluster_count > 2'd1),
        (y_clusters_filtered.cluster_count > 2'd1),
        (r_clusters_filtered.cluster_count > 2'd1)
    };
    cluster_overflow_any_next =
        r_clusters_filtered.overflow ||
        y_clusters_filtered.overflow ||
        b_clusters_filtered.overflow;
  end

  always_comb begin
    pkt_valid_o = (state_q == POS_SEND);
    pkt_sop_o   = (state_q == POS_SEND) && (word_idx_q == '0);
    pkt_eop_o   = (state_q == POS_SEND) && last_word;
    pkt_data_o  = '0;

    if (state_q == POS_SEND) begin
      if (mode_q == SPADMIC_POS_MODE_RAW) begin
        if (word_idx_q == '0) begin
          pkt_data_o = spadmic_pos_raw_header_word(non_empty_mask);
        end else if (word_idx_q <= WORD_IDX_W'(RAW_WORDS_PER_AXIS)) begin
          pkt_data_o = raw_word_from_lines(
              r_snapshot_q,
              int'(word_idx_q - WORD_IDX_W'(1))
          );
        end else if (word_idx_q <= WORD_IDX_W'(2 * RAW_WORDS_PER_AXIS)) begin
          pkt_data_o = raw_word_from_lines(
              y_snapshot_q,
              int'(word_idx_q - WORD_IDX_W'(1 + RAW_WORDS_PER_AXIS))
          );
        end else if (word_idx_q <= WORD_IDX_W'(3 * RAW_WORDS_PER_AXIS)) begin
          pkt_data_o = raw_word_from_lines(
              b_snapshot_q,
              int'(word_idx_q - WORD_IDX_W'(1 + (2 * RAW_WORDS_PER_AXIS)))
          );
        end else begin
          pkt_data_o = {2'b11, event_id_q};
        end
      end else begin
        if (word_idx_q == '0) begin
          pkt_data_o = spadmic_pos_header_word(
              cluster_overflow_any_q,
              cluster_non_empty_mask_q,
              cluster_multi_cluster_mask_q
          );
        end else if (last_word) begin
          pkt_data_o = {2'b11, event_id_q};
        end else begin
          pkt_data_o = cluster_word_from_index(word_idx_q);
        end
      end
    end
  end

  assign packet_pending_o = (state_q != POS_IDLE);
  assign busy_o = (state_q != POS_IDLE) || r_scan_busy || y_scan_busy ||
                  b_scan_busy;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q                    <= POS_IDLE;
      r_snapshot_q               <= '0;
      y_snapshot_q               <= '0;
      b_snapshot_q               <= '0;
      event_id_q                 <= '0;
      mode_q                     <= SPADMIC_POS_MODE_RAW;
      gap_threshold_q            <= '0;
      min_cluster_span_q         <= LINE_COUNT_W'(1);
      word_idx_q                 <= '0;
      scan_start_q               <= 1'b0;
      r_clusters_q               <= '0;
      y_clusters_q               <= '0;
      b_clusters_q               <= '0;
      cluster_non_empty_mask_q   <= '0;
      cluster_multi_cluster_mask_q <= '0;
      cluster_overflow_any_q     <= 1'b0;
      snapshot_captured_o        <= 1'b0;
      done_o                     <= 1'b0;
      drop_o                     <= 1'b0;
    end else begin
      done_o              <= 1'b0;
      drop_o              <= 1'b0;
      snapshot_captured_o <= 1'b0;
      scan_start_q        <= 1'b0;

      unique case (state_q)
        POS_IDLE: begin
          if (start_i) begin
            r_snapshot_q        <= snapshot_R_i;
            y_snapshot_q        <= snapshot_Y_i;
            b_snapshot_q        <= snapshot_B_i;
            event_id_q          <= event_id_i;
            mode_q              <= mode_i;
            gap_threshold_q     <= gap_threshold_i;
            min_cluster_span_q  <= (min_cluster_span_i == '0) ?
                                   LINE_COUNT_W'(1) : min_cluster_span_i;
            word_idx_q          <= '0;
            snapshot_captured_o <= 1'b1;

            if (mode_i == SPADMIC_POS_MODE_RAW) begin
              state_q <= POS_SEND;
            end else begin
              scan_start_q <= 1'b1;
              state_q      <= POS_SCAN;
            end
          end
        end

        POS_SCAN: begin
          if (start_i)
            drop_o <= 1'b1;

          if (scans_complete) begin
            r_clusters_q                 <= r_clusters_filtered;
            y_clusters_q                 <= y_clusters_filtered;
            b_clusters_q                 <= b_clusters_filtered;
            cluster_non_empty_mask_q     <= cluster_non_empty_mask_next;
            cluster_multi_cluster_mask_q <= cluster_multi_cluster_mask_next;
            cluster_overflow_any_q       <= cluster_overflow_any_next;
            word_idx_q                   <= '0;
            state_q                      <= POS_SEND;
          end
        end

        POS_SEND: begin
          if (start_i)
            drop_o <= 1'b1;

          if (out_accepted) begin
            if (last_word) begin
              state_q    <= POS_IDLE;
              word_idx_q <= '0;
              done_o     <= 1'b1;
            end else begin
              word_idx_q <= word_idx_q + WORD_IDX_W'(1);
            end
          end
        end

        default: state_q <= POS_IDLE;
      endcase
    end
  end

  // synthesis translate_off
  logic [NARROW_W-1:0] hold_data_q;
  logic hold_valid_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      hold_valid_q <= 1'b0;
      hold_data_q  <= '0;
    end else if (pkt_valid_o && !pkt_ready_i) begin
      if (hold_valid_q) begin
        assert (pkt_data_o == hold_data_q)
          else $error("spadmic_position_snapshot_packetizer: data changed while stalled");
      end
      hold_valid_q <= 1'b1;
      hold_data_q  <= pkt_data_o;
    end else begin
      hold_valid_q <= 1'b0;
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
