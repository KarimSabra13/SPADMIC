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
  output wire                                packet_pending_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic local_enable_q;
  logic [6:0] gap_threshold_q;
  logic [13:0] event_count_q;
  logic [SPADMIC_LINE_W-1:0] x_snapshot_q;
  logic [SPADMIC_LINE_W-1:0] y_snapshot_q;
  logic [SPADMIC_LINE_W-1:0] z_snapshot_q;
  logic any_lines_q;
  logic packet_active_q;
  logic [3:0] word_idx_q;

  logic capture_event;
  logic pos_enable;

  spadmic_axis_clusters_t x_clusters;
  spadmic_axis_clusters_t y_clusters;
  spadmic_axis_clusters_t z_clusters;

  logic overflow_any;
  logic [2:0] non_empty_mask;
  logic [2:0] multi_cluster_mask;
  logic [SPADMIC_CSR_DATA_W-1:0] rd_data_next;

  assign csr_ready_o       = 1'b1;
  assign pos_enable        = global_enable_i & local_enable_q;
  assign packet_pending_o  = packet_active_q;
  assign busy_o            = packet_active_q;
  assign capture_event     = pos_enable
                           & (|x_lines_i | |y_lines_i | |z_lines_i)
                           & ~any_lines_q
                           & ~packet_active_q;

  spadmic_axis_cluster_scan #(.LINE_W(SPADMIC_LINE_W)) u_scan_x (
    .lines_i         (x_snapshot_q),
    .gap_threshold_i (gap_threshold_q),
    .clusters_o      (x_clusters)
  );

  spadmic_axis_cluster_scan #(.LINE_W(SPADMIC_LINE_W)) u_scan_y (
    .lines_i         (y_snapshot_q),
    .gap_threshold_i (gap_threshold_q),
    .clusters_o      (y_clusters)
  );

  spadmic_axis_cluster_scan #(.LINE_W(SPADMIC_LINE_W)) u_scan_z (
    .lines_i         (z_snapshot_q),
    .gap_threshold_i (gap_threshold_q),
    .clusters_o      (z_clusters)
  );

  assign overflow_any     = x_clusters.overflow | y_clusters.overflow | z_clusters.overflow;
  assign non_empty_mask   = {
    ~z_clusters.empty,
    ~y_clusters.empty,
    ~x_clusters.empty
  };
  assign multi_cluster_mask = {
    (z_clusters.cluster_count > 2'd1),
    (y_clusters.cluster_count > 2'd1),
    (x_clusters.cluster_count > 2'd1)
  };

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      local_enable_q <= 1'b1;
      gap_threshold_q <= 7'd2;
      event_count_q   <= '0;
      x_snapshot_q    <= '0;
      y_snapshot_q    <= '0;
      z_snapshot_q    <= '0;
      any_lines_q     <= 1'b0;
      packet_active_q <= 1'b0;
      word_idx_q      <= '0;
    end else begin
      any_lines_q <= (|x_lines_i | |y_lines_i | |z_lines_i);

      if (csr_valid_i & csr_write_i) begin
        case (csr_addr_i)
          SPADMIC_CSR_POS_CTRL: begin
            local_enable_q <= csr_wdata_i[0];
          end
          SPADMIC_CSR_POS_GAP_CFG: begin
            gap_threshold_q <= csr_wdata_i[6:0];
          end
          default: ;
        endcase
      end

      if (capture_event) begin
        x_snapshot_q    <= x_lines_i;
        y_snapshot_q    <= y_lines_i;
        z_snapshot_q    <= z_lines_i;
        packet_active_q <= 1'b1;
        word_idx_q      <= 4'd0;
        event_count_q   <= event_count_q + 14'd1;
      end else if (packet_active_q && pos_valid_o && pos_ready_i) begin
        if (word_idx_q == 4'd10) begin
          packet_active_q <= 1'b0;
          word_idx_q      <= '0;
        end else begin
          word_idx_q <= word_idx_q + 4'd1;
        end
      end
    end
  end

  always_comb begin
    pos_valid_o = packet_active_q;
    pos_data_o  = '0;

    case (word_idx_q)
      4'd0: pos_data_o = spadmic_pos_header_word(
        overflow_any,
        non_empty_mask,
        multi_cluster_mask
      );
      4'd1: pos_data_o = spadmic_pos_axis_summary_word(TDC_ID_X, x_clusters);
      4'd2: pos_data_o = spadmic_pos_cluster_word(x_clusters.cluster0);
      4'd3: pos_data_o = spadmic_pos_cluster_word(x_clusters.cluster1);
      4'd4: pos_data_o = spadmic_pos_axis_summary_word(TDC_ID_Y, y_clusters);
      4'd5: pos_data_o = spadmic_pos_cluster_word(y_clusters.cluster0);
      4'd6: pos_data_o = spadmic_pos_cluster_word(y_clusters.cluster1);
      4'd7: pos_data_o = spadmic_pos_axis_summary_word(TDC_ID_Z, z_clusters);
      4'd8: pos_data_o = spadmic_pos_cluster_word(z_clusters.cluster0);
      4'd9: pos_data_o = spadmic_pos_cluster_word(z_clusters.cluster1);
      4'd10: pos_data_o = spadmic_pos_eoc_word(event_count_q);
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
      SPADMIC_CSR_POS_STATUS: begin
        rd_data_next[0]   = packet_active_q;
        rd_data_next[1]   = overflow_any;
        rd_data_next[4:2] = non_empty_mask;
        rd_data_next[7:5] = multi_cluster_mask;
      end
      SPADMIC_CSR_POS_EVENT_COUNT: begin
        rd_data_next[13:0] = event_count_q;
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
