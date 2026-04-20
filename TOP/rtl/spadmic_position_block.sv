// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_position_block.sv
// Purpose  : Async-qualified position detector, cluster scanner, queued packetizer,
//            and position-side CSR/status block for the shared chip TX path.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_position_block (
  input  wire                                clk_sys,
  input  wire                                rst_n,
  input  wire                                global_enable_i,
  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] x_lines_i,
  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] y_lines_i,
  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] z_lines_i,

  input  wire                                csr_valid_i,
  input  wire                                csr_write_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] csr_addr_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_wdata_i,
  output wire                                csr_ready_o,
  output logic                               csr_rvalid_o,
  output logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_rdata_o,

  input  wire                                pos_ready_i,
  output logic                               pos_valid_o,
  output logic [mptdc_pkg::NARROW_W-1:0]     pos_data_o,

  output wire                                busy_o,
  output wire                                packet_pending_o,
  output wire                                drop_sticky_o,
  output wire                                glitch_reject_sticky_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int unsigned POS_FRAME_W = $bits(spadmic_pos_frame_t);

  typedef enum logic [1:0] {
    DET_IDLE       = 2'd0,
    DET_SETTLE     = 2'd1,
    DET_EVAL       = 2'd2,
    DET_WAIT_CLEAR = 2'd3
  } pos_det_state_e;

  logic local_enable_q;
  logic [6:0] gap_threshold_q;
  logic [6:0] min_cluster_span_q;
  logic [3:0] settle_cycles_q;

  logic [13:0] event_count_q;
  logic [15:0] drop_count_q;
  logic [15:0] reject_count_q;
  logic        drop_sticky_q;
  logic        glitch_reject_sticky_q;

  (* ASYNC_REG = "TRUE" *) logic [SPADMIC_LINE_W-1:0] x_sync_ff1_q;
  (* ASYNC_REG = "TRUE" *) logic [SPADMIC_LINE_W-1:0] y_sync_ff1_q;
  (* ASYNC_REG = "TRUE" *) logic [SPADMIC_LINE_W-1:0] z_sync_ff1_q;
  (* ASYNC_REG = "TRUE" *) logic [SPADMIC_LINE_W-1:0] x_sync_ff2_q;
  (* ASYNC_REG = "TRUE" *) logic [SPADMIC_LINE_W-1:0] y_sync_ff2_q;
  (* ASYNC_REG = "TRUE" *) logic [SPADMIC_LINE_W-1:0] z_sync_ff2_q;
  logic [SPADMIC_LINE_W-1:0] x_sync_ff3_q;
  logic [SPADMIC_LINE_W-1:0] y_sync_ff3_q;
  logic [SPADMIC_LINE_W-1:0] z_sync_ff3_q;

  logic [SPADMIC_LINE_W-1:0] x_snapshot_q;
  logic [SPADMIC_LINE_W-1:0] y_snapshot_q;
  logic [SPADMIC_LINE_W-1:0] z_snapshot_q;

  pos_det_state_e det_state_q;
  logic [3:0]     settle_count_q;
  logic           packet_active_q;
  logic [3:0]     word_idx_q;

  spadmic_axis_clusters_t x_clusters_raw;
  spadmic_axis_clusters_t y_clusters_raw;
  spadmic_axis_clusters_t z_clusters_raw;
  spadmic_axis_clusters_t x_clusters_pkt;
  spadmic_axis_clusters_t y_clusters_pkt;
  spadmic_axis_clusters_t z_clusters_pkt;

  spadmic_pos_frame_t     frame_push_data;
  spadmic_pos_frame_t     frame_active_q;
  spadmic_pos_frame_t     frame_fifo_rd_data;
  logic                   frame_fifo_wr_en;
  logic                   frame_fifo_rd_en;
  logic                   frame_fifo_rd_valid;
  logic                   frame_fifo_full;

  logic                   x_has_activity_sync;
  logic                   y_has_activity_sync;
  logic                   z_has_activity_sync;
  logic                   lines_nonzero_sync;
  logic                   lines_stable_sync;
  logic                   overflow_any;
  logic [2:0]             non_empty_mask;
  logic [2:0]             multi_cluster_mask;
  logic                   meaningful_event;
  logic                   pos_enable;
  logic                   detector_busy;
  logic [SPADMIC_CSR_DATA_W-1:0] rd_data_next;
  logic                   status_overflow_any;
  logic [2:0]             status_non_empty_mask;
  logic [2:0]             status_multi_cluster_mask;
  logic                   load_next_frame;

  function automatic spadmic_cluster_t filter_cluster(
    input spadmic_cluster_t cluster,
    input logic [SPADMIC_LINE_IDX_W-1:0] min_span
  );
    spadmic_cluster_t filtered;
    filtered = cluster;
    if (!cluster.valid || (spadmic_cluster_span(cluster) < {1'b0, min_span})) begin
      filtered.valid = 1'b0;
      filtered.lo    = '0;
      filtered.hi    = '0;
    end
    return filtered;
  endfunction

  assign csr_ready_o            = 1'b1;
  assign pos_enable             = global_enable_i & local_enable_q;
  assign x_has_activity_sync    = |x_sync_ff2_q;
  assign y_has_activity_sync    = |y_sync_ff2_q;
  assign z_has_activity_sync    = |z_sync_ff2_q;
  assign lines_nonzero_sync     = x_has_activity_sync | y_has_activity_sync | z_has_activity_sync;
  assign lines_stable_sync      = (x_sync_ff2_q == x_sync_ff3_q)
                               && (y_sync_ff2_q == y_sync_ff3_q)
                               && (z_sync_ff2_q == z_sync_ff3_q);
  assign detector_busy          = (det_state_q != DET_IDLE);
  assign load_next_frame        = ~packet_active_q & frame_fifo_rd_valid;
  assign busy_o                 = detector_busy | packet_active_q | frame_fifo_rd_valid;
  assign packet_pending_o       = packet_active_q | frame_fifo_rd_valid;
  assign drop_sticky_o          = drop_sticky_q;
  assign glitch_reject_sticky_o = glitch_reject_sticky_q;

  spadmic_axis_cluster_scan #(.LINE_W(SPADMIC_LINE_W)) u_scan_x (
    .lines_i         (x_snapshot_q),
    .gap_threshold_i (gap_threshold_q),
    .clusters_o      (x_clusters_raw)
  );

  spadmic_axis_cluster_scan #(.LINE_W(SPADMIC_LINE_W)) u_scan_y (
    .lines_i         (y_snapshot_q),
    .gap_threshold_i (gap_threshold_q),
    .clusters_o      (y_clusters_raw)
  );

  spadmic_axis_cluster_scan #(.LINE_W(SPADMIC_LINE_W)) u_scan_z (
    .lines_i         (z_snapshot_q),
    .gap_threshold_i (gap_threshold_q),
    .clusters_o      (z_clusters_raw)
  );

  always_comb begin
    x_clusters_pkt = '0;
    y_clusters_pkt = '0;
    z_clusters_pkt = '0;

    x_clusters_pkt.cluster0 = filter_cluster(x_clusters_raw.cluster0, min_cluster_span_q);
    x_clusters_pkt.cluster1 = filter_cluster(x_clusters_raw.cluster1, min_cluster_span_q);
    x_clusters_pkt.overflow = x_clusters_raw.overflow;
    x_clusters_pkt.empty    = ~(x_clusters_pkt.cluster0.valid | x_clusters_pkt.cluster1.valid);
    x_clusters_pkt.cluster_count = {1'b0, x_clusters_pkt.cluster0.valid}
                                 + {1'b0, x_clusters_pkt.cluster1.valid};

    y_clusters_pkt.cluster0 = filter_cluster(y_clusters_raw.cluster0, min_cluster_span_q);
    y_clusters_pkt.cluster1 = filter_cluster(y_clusters_raw.cluster1, min_cluster_span_q);
    y_clusters_pkt.overflow = y_clusters_raw.overflow;
    y_clusters_pkt.empty    = ~(y_clusters_pkt.cluster0.valid | y_clusters_pkt.cluster1.valid);
    y_clusters_pkt.cluster_count = {1'b0, y_clusters_pkt.cluster0.valid}
                                 + {1'b0, y_clusters_pkt.cluster1.valid};

    z_clusters_pkt.cluster0 = filter_cluster(z_clusters_raw.cluster0, min_cluster_span_q);
    z_clusters_pkt.cluster1 = filter_cluster(z_clusters_raw.cluster1, min_cluster_span_q);
    z_clusters_pkt.overflow = z_clusters_raw.overflow;
    z_clusters_pkt.empty    = ~(z_clusters_pkt.cluster0.valid | z_clusters_pkt.cluster1.valid);
    z_clusters_pkt.cluster_count = {1'b0, z_clusters_pkt.cluster0.valid}
                                 + {1'b0, z_clusters_pkt.cluster1.valid};
  end

  assign overflow_any = x_clusters_pkt.overflow | y_clusters_pkt.overflow | z_clusters_pkt.overflow;
  assign non_empty_mask = {
    ~z_clusters_pkt.empty,
    ~y_clusters_pkt.empty,
    ~x_clusters_pkt.empty
  };
  assign multi_cluster_mask = {
    (z_clusters_pkt.cluster_count > 2'd1),
    (y_clusters_pkt.cluster_count > 2'd1),
    (x_clusters_pkt.cluster_count > 2'd1)
  };
  assign meaningful_event = |non_empty_mask;

  always_comb begin
    frame_push_data = '0;
    frame_push_data.non_empty_mask     = non_empty_mask;
    frame_push_data.multi_cluster_mask = multi_cluster_mask;
    frame_push_data.overflow_any       = overflow_any;
    frame_push_data.x_clusters         = x_clusters_pkt;
    frame_push_data.y_clusters         = y_clusters_pkt;
    frame_push_data.z_clusters         = z_clusters_pkt;
  end

  mptdc_sync_fifo #(
    .WIDTH (POS_FRAME_W),
    .DEPTH (SPADMIC_POS_QUEUE_DEPTH)
  ) u_frame_fifo (
    .clk        (clk_sys),
    .rst_n      (rst_n),
    .clr_i      (1'b0),
    .wr_en_i    (frame_fifo_wr_en),
    .wr_data_i  (frame_push_data),
    .wr_full_o  (frame_fifo_full),
    .rd_en_i    (frame_fifo_rd_en),
    .rd_data_o  (frame_fifo_rd_data),
    .rd_valid_o (frame_fifo_rd_valid),
    .level_o    (/* unused */)
  );

  assign frame_fifo_wr_en = pos_enable && (det_state_q == DET_EVAL) && meaningful_event && ~frame_fifo_full;
  assign frame_fifo_rd_en = load_next_frame;

  // The front half is still a synchronizer plus detect/settle/evaluate FSM, but
  // accepted snapshots are now queued so overlapping events are preserved until
  // the packetizer drains them.
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      local_enable_q         <= 1'b1;
      gap_threshold_q        <= 7'd2;
      min_cluster_span_q     <= 7'd2;
      settle_cycles_q        <= 4'd1;
      event_count_q          <= '0;
      drop_count_q           <= '0;
      reject_count_q         <= '0;
      drop_sticky_q          <= 1'b0;
      glitch_reject_sticky_q <= 1'b0;
      x_sync_ff1_q           <= '0;
      y_sync_ff1_q           <= '0;
      z_sync_ff1_q           <= '0;
      x_sync_ff2_q           <= '0;
      y_sync_ff2_q           <= '0;
      z_sync_ff2_q           <= '0;
      x_sync_ff3_q           <= '0;
      y_sync_ff3_q           <= '0;
      z_sync_ff3_q           <= '0;
      x_snapshot_q           <= '0;
      y_snapshot_q           <= '0;
      z_snapshot_q           <= '0;
      det_state_q            <= DET_IDLE;
      settle_count_q         <= '0;
      packet_active_q        <= 1'b0;
      word_idx_q             <= '0;
      frame_active_q         <= '0;
    end else begin
      x_sync_ff1_q <= x_lines_i;
      y_sync_ff1_q <= y_lines_i;
      z_sync_ff1_q <= z_lines_i;
      x_sync_ff2_q <= x_sync_ff1_q;
      y_sync_ff2_q <= y_sync_ff1_q;
      z_sync_ff2_q <= z_sync_ff1_q;
      x_sync_ff3_q <= x_sync_ff2_q;
      y_sync_ff3_q <= y_sync_ff2_q;
      z_sync_ff3_q <= z_sync_ff2_q;

      if (csr_valid_i & csr_write_i) begin
        case (csr_addr_i)
          SPADMIC_CSR_POS_CTRL: begin
            local_enable_q <= csr_wdata_i[0];
          end

          SPADMIC_CSR_POS_GAP_CFG: begin
            gap_threshold_q <= csr_wdata_i[6:0];
          end

          SPADMIC_CSR_POS_FILTER_CFG: begin
            min_cluster_span_q <= csr_wdata_i[6:0];
            settle_cycles_q    <= csr_wdata_i[11:8];
          end

          SPADMIC_CSR_POS_FAULT_STATUS: begin
            if (csr_wdata_i[0])
              drop_sticky_q <= 1'b0;
            if (csr_wdata_i[1])
              glitch_reject_sticky_q <= 1'b0;
          end

          default: ;
        endcase
      end

      if (!pos_enable) begin
        det_state_q    <= DET_IDLE;
        settle_count_q <= '0;
      end else begin
        case (det_state_q)
          DET_IDLE: begin
            settle_count_q <= '0;
            if (lines_nonzero_sync)
              det_state_q <= DET_SETTLE;
          end

          DET_SETTLE: begin
            if (!lines_nonzero_sync) begin
              reject_count_q         <= reject_count_q + 16'd1;
              glitch_reject_sticky_q <= 1'b1;
              settle_count_q         <= '0;
              det_state_q            <= DET_IDLE;
            end else if (!lines_stable_sync) begin
              settle_count_q <= '0;
            end else if (settle_count_q >= settle_cycles_q) begin
              x_snapshot_q   <= x_sync_ff2_q;
              y_snapshot_q   <= y_sync_ff2_q;
              z_snapshot_q   <= z_sync_ff2_q;
              settle_count_q <= '0;
              det_state_q    <= DET_EVAL;
            end else begin
              settle_count_q <= settle_count_q + 4'd1;
            end
          end

          DET_EVAL: begin
            if (meaningful_event) begin
              if (frame_fifo_full) begin
                drop_count_q  <= drop_count_q + 16'd1;
                drop_sticky_q <= 1'b1;
              end else begin
                event_count_q <= event_count_q + 14'd1;
              end
            end else begin
              reject_count_q         <= reject_count_q + 16'd1;
              glitch_reject_sticky_q <= 1'b1;
            end
            det_state_q <= DET_WAIT_CLEAR;
          end

          default: begin
            if (!lines_nonzero_sync)
              det_state_q <= DET_IDLE;
          end
        endcase
      end

      if (load_next_frame) begin
        frame_active_q  <= frame_fifo_rd_data;
        packet_active_q <= 1'b1;
        word_idx_q      <= '0;
      end else if (packet_active_q && pos_valid_o && pos_ready_i) begin
        if (word_idx_q == 4'd11) begin
          packet_active_q <= 1'b0;
          word_idx_q      <= '0;
        end else begin
          word_idx_q <= word_idx_q + 4'd1;
        end
      end
    end
  end

  assign status_overflow_any       = packet_active_q ? frame_active_q.overflow_any       : overflow_any;
  assign status_non_empty_mask     = packet_active_q ? frame_active_q.non_empty_mask     : non_empty_mask;
  assign status_multi_cluster_mask = packet_active_q ? frame_active_q.multi_cluster_mask : multi_cluster_mask;

  always_comb begin
    pos_valid_o = packet_active_q;
    pos_data_o  = '0;

    case (word_idx_q)
      4'd0: pos_data_o = spadmic_pos_header_word(
        frame_active_q.overflow_any,
        frame_active_q.non_empty_mask,
        frame_active_q.multi_cluster_mask
      );
      4'd1: pos_data_o = spadmic_pos_subheader_word(frame_active_q.non_empty_mask);
      4'd2: pos_data_o = spadmic_pos_axis_summary_word(TDC_ID_X, frame_active_q.x_clusters);
      4'd3: pos_data_o = spadmic_pos_cluster_word(frame_active_q.x_clusters.cluster0);
      4'd4: pos_data_o = spadmic_pos_cluster_word(frame_active_q.x_clusters.cluster1);
      4'd5: pos_data_o = spadmic_pos_axis_summary_word(TDC_ID_Y, frame_active_q.y_clusters);
      4'd6: pos_data_o = spadmic_pos_cluster_word(frame_active_q.y_clusters.cluster0);
      4'd7: pos_data_o = spadmic_pos_cluster_word(frame_active_q.y_clusters.cluster1);
      4'd8: pos_data_o = spadmic_pos_axis_summary_word(TDC_ID_Z, frame_active_q.z_clusters);
      4'd9: pos_data_o = spadmic_pos_cluster_word(frame_active_q.z_clusters.cluster0);
      4'd10: pos_data_o = spadmic_pos_cluster_word(frame_active_q.z_clusters.cluster1);
      4'd11: pos_data_o = spadmic_pos_eoc_word(event_count_q);
      default: ;
    endcase
  end

  always_comb begin
    rd_data_next = '0;
    case (csr_addr_i)
      SPADMIC_CSR_POS_CTRL: begin
        rd_data_next[0] = local_enable_q;
      end

      SPADMIC_CSR_POS_GAP_CFG: begin
        rd_data_next[6:0] = gap_threshold_q;
      end

      SPADMIC_CSR_POS_FILTER_CFG: begin
        rd_data_next[6:0]  = min_cluster_span_q;
        rd_data_next[11:8] = settle_cycles_q;
      end

      SPADMIC_CSR_POS_STATUS: begin
        rd_data_next[0]     = packet_active_q;
        rd_data_next[1]     = status_overflow_any;
        rd_data_next[4:2]   = status_non_empty_mask;
        rd_data_next[7:5]   = status_multi_cluster_mask;
        rd_data_next[8]     = busy_o;
        rd_data_next[9]     = packet_pending_o;
        rd_data_next[11:10] = det_state_q;
      end

      SPADMIC_CSR_POS_EVENT_COUNT: begin
        rd_data_next[13:0] = event_count_q;
      end

      SPADMIC_CSR_POS_FAULT_STATUS: begin
        rd_data_next[0]    = drop_sticky_q;
        rd_data_next[1]    = glitch_reject_sticky_q;
        rd_data_next[3:2]  = det_state_q;
      end

      SPADMIC_CSR_POS_DROP_COUNT: begin
        rd_data_next[15:0] = drop_count_q;
      end

      SPADMIC_CSR_POS_REJECT_COUNT: begin
        rd_data_next[15:0] = reject_count_q;
      end

      default: ;
    endcase
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      csr_rvalid_o <= 1'b0;
      csr_rdata_o  <= '0;
    end else begin
      csr_rvalid_o <= csr_valid_i & ~csr_write_i;
      csr_rdata_o  <= (csr_valid_i & ~csr_write_i) ? rd_data_next : '0;
    end
  end

endmodule

`default_nettype wire
