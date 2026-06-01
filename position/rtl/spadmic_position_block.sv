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
  output wire                                glitch_reject_sticky_o,
  output logic                               spad_matrix_rst_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int unsigned POS_FRAME_W = $bits(spadmic_pos_frame_t);
  localparam logic [4:0] POS_CLUSTER_LAST_WORD = 5'(SPADMIC_POS_PKT_WORDS - 1);
  localparam logic [4:0] POS_RAW_X_BASE        = 5'd1;
  localparam logic [4:0] POS_RAW_Y_BASE        = 5'(1 + SPADMIC_POS_RAW_WORDS_PER_AXIS);
  localparam logic [4:0] POS_RAW_Z_BASE        = 5'(1 + (2 * SPADMIC_POS_RAW_WORDS_PER_AXIS));
  localparam logic [4:0] POS_RAW_EOC_WORD      = 5'(SPADMIC_POS_RAW_PKT_WORDS - 1);

  typedef enum logic [1:0] {
    DET_IDLE       = 2'd0,
    DET_SETTLE     = 2'd1,
    DET_SCAN       = 2'd2,
    DET_WAIT_CLEAR = 2'd3
  } pos_det_state_e;

  logic local_enable_q;
  spadmic_pos_mode_e pos_mode_q;
  spadmic_spad_reset_mode_e reset_mode_q;
  logic reset_after_capture_q;
  logic compact_cluster_q;
  logic [SPADMIC_LINE_COUNT_W-1:0] gap_threshold_q;
  logic [SPADMIC_LINE_COUNT_W-1:0] min_cluster_span_q;
  logic [3:0] settle_cycles_q;
  logic [31:0] auto_reset_period_q;
  logic [31:0] auto_reset_count_q;
  logic        auto_reset_pending_q;

  logic [3:0]  event_count_q;
  logic [15:0] drop_count_q;
  logic [15:0] reject_count_q;
  logic        drop_sticky_q;
  logic        glitch_reject_sticky_q;

  logic [SPADMIC_LINE_W-1:0] x_sync_ff1_q;
  logic [SPADMIC_LINE_W-1:0] y_sync_ff1_q;
  logic [SPADMIC_LINE_W-1:0] z_sync_ff1_q;
  logic [SPADMIC_LINE_W-1:0] x_sync_ff2_q;
  logic [SPADMIC_LINE_W-1:0] y_sync_ff2_q;
  logic [SPADMIC_LINE_W-1:0] z_sync_ff2_q;
  logic [SPADMIC_LINE_W-1:0] x_sync_ff3_q;
  logic [SPADMIC_LINE_W-1:0] y_sync_ff3_q;
  logic [SPADMIC_LINE_W-1:0] z_sync_ff3_q;

  logic [SPADMIC_LINE_W-1:0] x_snapshot_q;
  logic [SPADMIC_LINE_W-1:0] y_snapshot_q;
  logic [SPADMIC_LINE_W-1:0] z_snapshot_q;

  pos_det_state_e det_state_q;
  logic [3:0]     settle_count_q;
  logic           packet_active_q;
  logic [4:0]     word_idx_q;

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
  spadmic_pos_cluster_slot_mask_t cluster_slot_mask;
  logic [2:0]             compact_cluster_words;
  logic                   meaningful_event;
  logic                   raw_meaningful_event;
  logic [2:0]             raw_non_empty_mask;
  logic                   pos_enable;
  logic                   detector_busy;
  logic [SPADMIC_CSR_DATA_W-1:0] rd_data_next;
  logic                   status_overflow_any;
  logic [2:0]             status_non_empty_mask;
  logic [2:0]             status_multi_cluster_mask;
  logic                   load_next_frame;
  logic [4:0]             cluster_last_word;
  logic [4:0]             compact_cluster_last_word;
  logic                   scan_start;
  logic                   scan_complete;
  logic                   x_scan_busy;
  logic                   y_scan_busy;
  logic                   z_scan_busy;
  logic                   x_scan_valid;
  logic                   y_scan_valid;
  logic                   z_scan_valid;

  function automatic spadmic_cluster_t filter_cluster(
    input spadmic_cluster_t cluster,
    input logic [SPADMIC_LINE_COUNT_W-1:0] min_span
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

  function automatic spadmic_cluster_t cluster_slot_from_frame(
    input spadmic_pos_frame_t frame,
    input logic [2:0]         slot_idx
  );
    spadmic_cluster_t cluster;

    cluster = '0;
    unique case (slot_idx)
      3'd0: cluster = frame.x_clusters.cluster0;
      3'd1: cluster = frame.x_clusters.cluster1;
      3'd2: cluster = frame.y_clusters.cluster0;
      3'd3: cluster = frame.y_clusters.cluster1;
      3'd4: cluster = frame.z_clusters.cluster0;
      3'd5: cluster = frame.z_clusters.cluster1;
      default: ;
    endcase
    return cluster;
  endfunction

  function automatic spadmic_cluster_t compact_cluster_from_frame(
    input spadmic_pos_frame_t frame,
    input logic [4:0]         packet_word_idx
  );
    spadmic_cluster_t cluster;
    logic [2:0]      target_payload_idx;
    logic [2:0]      valid_seen;

    cluster = '0;
    target_payload_idx = 3'(packet_word_idx - 5'd1);
    valid_seen = '0;

    for (int slot = 0; slot < SPADMIC_POS_CLUSTER_SLOT_COUNT; slot++) begin
      if (frame.cluster_slot_mask[slot]) begin
        if (valid_seen == target_payload_idx)
          cluster = cluster_slot_from_frame(frame, 3'(slot));
        valid_seen = valid_seen + 3'd1;
      end
    end

    return cluster;
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
  assign detector_busy          = (det_state_q != DET_IDLE)
                                | x_scan_busy
                                | y_scan_busy
                                | z_scan_busy;
  assign load_next_frame        = ~packet_active_q & frame_fifo_rd_valid;
  assign compact_cluster_last_word = 5'd1 + 5'(frame_active_q.compact_cluster_words);
  assign cluster_last_word      = frame_active_q.compact_cluster
                                ? compact_cluster_last_word
                                : POS_CLUSTER_LAST_WORD;
  assign busy_o                 = detector_busy | packet_active_q | frame_fifo_rd_valid;
  assign packet_pending_o       = packet_active_q | frame_fifo_rd_valid;
  assign drop_sticky_o          = drop_sticky_q;
  assign glitch_reject_sticky_o = glitch_reject_sticky_q;
  assign raw_non_empty_mask     = {
    |z_snapshot_q,
    |y_snapshot_q,
    |x_snapshot_q
  };
  assign raw_meaningful_event   = |raw_non_empty_mask;

  wire csr_pos_ctrl_write = csr_valid_i & csr_write_i & (csr_addr_i == SPADMIC_CSR_POS_CTRL);
  wire csr_pos_manual_reset_write = csr_pos_ctrl_write & csr_wdata_i[4];
  wire csr_pos_reset_cfg_write = csr_valid_i & csr_write_i & (csr_addr_i == SPADMIC_CSR_POS_RESET_CFG);
  wire settle_accept = (det_state_q == DET_SETTLE)
                     && lines_nonzero_sync
                     && lines_stable_sync
                     && (settle_count_q >= settle_cycles_q);

  assign scan_start    = settle_accept && (pos_mode_q == SPADMIC_POS_MODE_CLUSTER);
  assign scan_complete = (pos_mode_q == SPADMIC_POS_MODE_RAW)
                       || (x_scan_valid && y_scan_valid && z_scan_valid);

  spadmic_axis_cluster_scan #(.LINE_W(SPADMIC_LINE_W)) u_scan_x (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .start_i         (scan_start),
    .lines_i         (x_sync_ff2_q),
    .gap_threshold_i (gap_threshold_q),
    .busy_o          (x_scan_busy),
    .valid_o         (x_scan_valid),
    .clusters_o      (x_clusters_raw)
  );

  spadmic_axis_cluster_scan #(.LINE_W(SPADMIC_LINE_W)) u_scan_y (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .start_i         (scan_start),
    .lines_i         (y_sync_ff2_q),
    .gap_threshold_i (gap_threshold_q),
    .busy_o          (y_scan_busy),
    .valid_o         (y_scan_valid),
    .clusters_o      (y_clusters_raw)
  );

  spadmic_axis_cluster_scan #(.LINE_W(SPADMIC_LINE_W)) u_scan_z (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .start_i         (scan_start),
    .lines_i         (z_sync_ff2_q),
    .gap_threshold_i (gap_threshold_q),
    .busy_o          (z_scan_busy),
    .valid_o         (z_scan_valid),
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
  assign cluster_slot_mask = spadmic_pos_cluster_slot_mask(
    x_clusters_pkt,
    y_clusters_pkt,
    z_clusters_pkt
  );
  assign compact_cluster_words = spadmic_pos_cluster_slot_count(cluster_slot_mask);
  assign meaningful_event = (pos_mode_q == SPADMIC_POS_MODE_RAW)
                           ? raw_meaningful_event
                           : |non_empty_mask;

  always_comb begin
    frame_push_data = '0;
    frame_push_data.mode               = pos_mode_q;
    frame_push_data.compact_cluster    = (pos_mode_q == SPADMIC_POS_MODE_CLUSTER)
                                       && compact_cluster_q;
    frame_push_data.non_empty_mask     = (pos_mode_q == SPADMIC_POS_MODE_RAW)
                                       ? raw_non_empty_mask
                                       : non_empty_mask;
    frame_push_data.multi_cluster_mask = (pos_mode_q == SPADMIC_POS_MODE_RAW)
                                       ? '0
                                       : multi_cluster_mask;
    frame_push_data.overflow_any       = (pos_mode_q == SPADMIC_POS_MODE_RAW)
                                       ? 1'b0
                                       : overflow_any;
    frame_push_data.cluster_slot_mask  = (pos_mode_q == SPADMIC_POS_MODE_RAW)
                                       ? '0
                                       : cluster_slot_mask;
    frame_push_data.compact_cluster_words = (pos_mode_q == SPADMIC_POS_MODE_RAW)
                                          ? '0
                                          : compact_cluster_words;
    frame_push_data.x_clusters         = x_clusters_pkt;
    frame_push_data.y_clusters         = y_clusters_pkt;
    frame_push_data.z_clusters         = z_clusters_pkt;
    frame_push_data.x_raw_lines        = x_snapshot_q;
    frame_push_data.y_raw_lines        = y_snapshot_q;
    frame_push_data.z_raw_lines        = z_snapshot_q;
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

  assign frame_fifo_wr_en = pos_enable
                          && (det_state_q == DET_SCAN)
                          && scan_complete
                          && meaningful_event
                          && ~frame_fifo_full;
  assign frame_fifo_rd_en = load_next_frame;

  wire auto_reset_period_enabled = (auto_reset_period_q != 32'd0);
  wire auto_reset_period_hit = auto_reset_period_enabled
                            && (auto_reset_count_q >= (auto_reset_period_q - 32'd1));
  wire reset_safe_for_event_deferred = (det_state_q == DET_IDLE)
                                    && !packet_active_q
                                    && !frame_fifo_rd_valid
                                    && !lines_nonzero_sync;

  // The front half is still a synchronizer plus detect/settle/evaluate FSM, but
  // accepted snapshots are now queued so overlapping events are preserved until
  // the packetizer drains them.
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      local_enable_q         <= 1'b1;
      pos_mode_q             <= SPADMIC_POS_MODE_CLUSTER;
      reset_mode_q           <= SPADMIC_SPAD_RST_MANUAL_ONLY;
      reset_after_capture_q  <= 1'b0;
      compact_cluster_q      <= 1'b0;
      gap_threshold_q        <= 7'd2;
      min_cluster_span_q     <= 7'd2;
      settle_cycles_q        <= 4'd1;
      auto_reset_period_q    <= '0;
      auto_reset_count_q     <= '0;
      auto_reset_pending_q   <= 1'b0;
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
      spad_matrix_rst_o      <= 1'b0;
    end else begin
      spad_matrix_rst_o <= 1'b0;

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
            pos_mode_q     <= spadmic_pos_mode_e'(csr_wdata_i[1]);
            reset_mode_q   <= spadmic_spad_reset_mode_e'(csr_wdata_i[3:2]);
            reset_after_capture_q <= csr_wdata_i[5];
            compact_cluster_q <= csr_wdata_i[6];
            if (spadmic_spad_reset_mode_e'(csr_wdata_i[3:2]) != reset_mode_q) begin
              auto_reset_count_q   <= '0;
              auto_reset_pending_q <= 1'b0;
            end
            if (csr_wdata_i[4]) begin
              spad_matrix_rst_o    <= 1'b1;
              auto_reset_count_q   <= '0;
              auto_reset_pending_q <= 1'b0;
            end
          end

          SPADMIC_CSR_POS_GAP_CFG: begin
            gap_threshold_q <= csr_wdata_i[SPADMIC_LINE_COUNT_W-1:0];
          end

          SPADMIC_CSR_POS_FILTER_CFG: begin
            min_cluster_span_q <= csr_wdata_i[SPADMIC_LINE_COUNT_W-1:0];
            settle_cycles_q    <= csr_wdata_i[11:8];
          end

          SPADMIC_CSR_POS_RESET_CFG: begin
            auto_reset_period_q  <= csr_wdata_i;
            auto_reset_count_q   <= '0;
            auto_reset_pending_q <= 1'b0;
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

      if (!(csr_pos_manual_reset_write | csr_pos_reset_cfg_write | csr_pos_ctrl_write)) begin
        unique case (reset_mode_q)
          SPADMIC_SPAD_RST_EVENT_DEFERRED: begin
            if (!auto_reset_period_enabled) begin
              auto_reset_count_q   <= '0;
              auto_reset_pending_q <= 1'b0;
            end else if (auto_reset_pending_q) begin
              if (reset_safe_for_event_deferred) begin
                spad_matrix_rst_o    <= 1'b1;
                auto_reset_count_q   <= '0;
                auto_reset_pending_q <= 1'b0;
              end
            end else if (auto_reset_period_hit) begin
              auto_reset_count_q   <= '0;
              auto_reset_pending_q <= 1'b1;
            end else begin
              auto_reset_count_q <= auto_reset_count_q + 32'd1;
            end
          end

          SPADMIC_SPAD_RST_PERIODIC: begin
            auto_reset_pending_q <= 1'b0;
            if (!auto_reset_period_enabled) begin
              auto_reset_count_q <= '0;
            end else if (auto_reset_period_hit) begin
              spad_matrix_rst_o  <= 1'b1;
              auto_reset_count_q <= '0;
            end else begin
              auto_reset_count_q <= auto_reset_count_q + 32'd1;
            end
          end

          default: begin
            auto_reset_count_q   <= '0;
            auto_reset_pending_q <= 1'b0;
          end
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
              if (reset_after_capture_q) begin
                spad_matrix_rst_o    <= 1'b1;
                auto_reset_count_q   <= '0;
                auto_reset_pending_q <= 1'b0;
              end
              settle_count_q <= '0;
              det_state_q    <= DET_SCAN;
            end else begin
              settle_count_q <= settle_count_q + 4'd1;
            end
          end

          DET_SCAN: begin
            if (scan_complete) begin
              if (meaningful_event) begin
                if (frame_fifo_full) begin
                  drop_count_q  <= drop_count_q + 16'd1;
                  drop_sticky_q <= 1'b1;
                end else begin
                  event_count_q <= event_count_q + 4'd1;
                end
              end else begin
                reject_count_q         <= reject_count_q + 16'd1;
                glitch_reject_sticky_q <= 1'b1;
              end
              det_state_q <= DET_WAIT_CLEAR;
            end
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
        if (word_idx_q == ((frame_active_q.mode == SPADMIC_POS_MODE_RAW) ? POS_RAW_EOC_WORD : cluster_last_word)) begin
          packet_active_q <= 1'b0;
          word_idx_q      <= '0;
        end else begin
          word_idx_q <= word_idx_q + 5'd1;
        end
      end
    end
  end

  assign status_overflow_any       = packet_active_q ? frame_active_q.overflow_any       : overflow_any;
  assign status_non_empty_mask     = packet_active_q ? frame_active_q.non_empty_mask     : non_empty_mask;
  assign status_multi_cluster_mask = packet_active_q ? frame_active_q.multi_cluster_mask : multi_cluster_mask;

  always_comb begin
    logic [4:0] raw_axis_word_idx;

    pos_valid_o = packet_active_q;
    pos_data_o  = '0;
    raw_axis_word_idx = '0;

    if (frame_active_q.mode == SPADMIC_POS_MODE_RAW) begin
      if (word_idx_q == 5'd0) begin
        pos_data_o = spadmic_pos_raw_header_word(frame_active_q.non_empty_mask);
      end else if (word_idx_q == POS_RAW_EOC_WORD) begin
        pos_data_o = spadmic_pos_eoc_word(event_count_q);
      end else if (word_idx_q < POS_RAW_Y_BASE) begin
        raw_axis_word_idx = word_idx_q - POS_RAW_X_BASE;
        pos_data_o = spadmic_pos_raw_word(frame_active_q.x_raw_lines, int'(raw_axis_word_idx));
      end else if (word_idx_q < POS_RAW_Z_BASE) begin
        raw_axis_word_idx = word_idx_q - POS_RAW_Y_BASE;
        pos_data_o = spadmic_pos_raw_word(frame_active_q.y_raw_lines, int'(raw_axis_word_idx));
      end else if (word_idx_q < POS_RAW_EOC_WORD) begin
        raw_axis_word_idx = word_idx_q - POS_RAW_Z_BASE;
        pos_data_o = spadmic_pos_raw_word(frame_active_q.z_raw_lines, int'(raw_axis_word_idx));
      end
    end else begin
      unique case (word_idx_q)
        5'd0: begin
          pos_data_o = frame_active_q.compact_cluster
                     ? spadmic_pos_compact_header_word(
                         frame_active_q.overflow_any,
                         frame_active_q.non_empty_mask,
                         frame_active_q.multi_cluster_mask,
                         frame_active_q.cluster_slot_mask
                       )
                     : spadmic_pos_header_word(
                         frame_active_q.overflow_any,
                         frame_active_q.non_empty_mask,
                         frame_active_q.multi_cluster_mask
                       );
        end
        5'd1: pos_data_o = spadmic_pos_cluster_word(frame_active_q.x_clusters.cluster0);
        5'd2: pos_data_o = spadmic_pos_cluster_word(frame_active_q.x_clusters.cluster1);
        5'd3: pos_data_o = spadmic_pos_cluster_word(frame_active_q.y_clusters.cluster0);
        5'd4: pos_data_o = spadmic_pos_cluster_word(frame_active_q.y_clusters.cluster1);
        5'd5: pos_data_o = spadmic_pos_cluster_word(frame_active_q.z_clusters.cluster0);
        5'd6: pos_data_o = spadmic_pos_cluster_word(frame_active_q.z_clusters.cluster1);
        5'd7: pos_data_o = spadmic_pos_eoc_word(event_count_q);
        default: ;
      endcase

      if (frame_active_q.compact_cluster) begin
        if (word_idx_q == 5'd0) begin
          pos_data_o = spadmic_pos_compact_header_word(
            frame_active_q.overflow_any,
            frame_active_q.non_empty_mask,
            frame_active_q.multi_cluster_mask,
            frame_active_q.cluster_slot_mask
          );
        end else if (word_idx_q == cluster_last_word) begin
          pos_data_o = spadmic_pos_eoc_word(event_count_q);
        end else begin
          pos_data_o = spadmic_pos_cluster_word(
            compact_cluster_from_frame(frame_active_q, word_idx_q)
          );
        end
      end
    end
  end

  always_comb begin
    rd_data_next = '0;
    case (csr_addr_i)
      SPADMIC_CSR_POS_CTRL: begin
        rd_data_next[0] = local_enable_q;
        rd_data_next[1] = pos_mode_q;
        rd_data_next[3:2] = reset_mode_q;
        rd_data_next[5] = reset_after_capture_q;
        rd_data_next[6] = compact_cluster_q;
      end

      SPADMIC_CSR_POS_GAP_CFG: begin
        rd_data_next[SPADMIC_LINE_COUNT_W-1:0] = gap_threshold_q;
      end

      SPADMIC_CSR_POS_FILTER_CFG: begin
        rd_data_next[SPADMIC_LINE_COUNT_W-1:0] = min_cluster_span_q;
        rd_data_next[11:8] = settle_cycles_q;
      end

      SPADMIC_CSR_POS_RESET_CFG: begin
        rd_data_next = auto_reset_period_q;
      end

      SPADMIC_CSR_POS_STATUS: begin
        rd_data_next[0]     = packet_active_q;
        rd_data_next[1]     = status_overflow_any;
        rd_data_next[4:2]   = status_non_empty_mask;
        rd_data_next[7:5]   = status_multi_cluster_mask;
        rd_data_next[8]     = busy_o;
        rd_data_next[9]     = packet_pending_o;
        rd_data_next[11:10] = det_state_q;
        rd_data_next[12]    = pos_mode_q;
        rd_data_next[14:13] = reset_mode_q;
        rd_data_next[15]    = auto_reset_pending_q;
        rd_data_next[16]    = spad_matrix_rst_o;
      end

      SPADMIC_CSR_POS_EVENT_COUNT: begin
        rd_data_next[3:0] = event_count_q;
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
