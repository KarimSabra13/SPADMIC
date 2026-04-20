// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_correlated_tx.sv
// Purpose  : Packet-level arbiter + shared event tagger + post-arbiter FIFO for
//            TDC/position export on the shared chip TX path.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_correlated_tx (
  input  wire                                clk_sys,
  input  wire                                rst_n,
  input  wire spadmic_pkg::spadmic_tx_sel_e  tx_sel_i,
  input  wire [spadmic_pkg::SPADMIC_AXIS_COUNT-1:0] axis_enable_i,
  input  wire                                position_enable_i,

  input  wire                                tdc_valid_i,
  input  wire [mptdc_pkg::NARROW_W-1:0]      tdc_data_i,
  output logic                               tdc_ready_o,

  input  wire                                pos_valid_i,
  input  wire [mptdc_pkg::NARROW_W-1:0]      pos_data_i,
  output logic                               pos_ready_o,

  input  wire                                shared_ready_i,
  output wire                                shared_valid_o,
  output wire [mptdc_pkg::NARROW_W-1:0]      shared_data_o,

  output logic                               correlation_overflow_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  spadmic_export_mode_e               export_mode;

  logic                               grant_active_q;
  logic                               grant_is_pos_q;
  logic                               rr_prefer_pos_q;

  logic                               selected_is_pos;
  logic                               selected_valid;
  logic [NARROW_W-1:0]                selected_data;
  logic                               selected_ready;
  logic                               input_accept;

  logic [3:0]                         word_idx_q;
  spadmic_source_id_e                 packet_source_q;
  logic                               packet_source_valid_q;

  logic [NARROW_W-1:0]                fifo_wr_data;
  logic [NARROW_W-1:0]                fifo_rd_data;
  logic                               fifo_wr_en;
  logic                               fifo_rd_en;
  logic                               fifo_rd_valid;
  logic                               fifo_full;

  logic [SPADMIC_EVENT_ID_W-1:0]      source_event_id_q [SPADMIC_SRC_COUNT];
  logic [SPADMIC_EVENT_ID_W-1:0]      assigned_event_id;
  spadmic_source_id_e                 packet_source_now;

  assign export_mode    = spadmic_export_mode_from_ctrl(tx_sel_i, position_enable_i);
  assign selected_ready = ~fifo_full;
  assign input_accept   = selected_valid & selected_ready;

  assign packet_source_now = grant_is_pos_q ? SPADMIC_SRC_POSITION : packet_source_q;
  assign assigned_event_id = source_event_id_q[packet_source_now];

  assign fifo_wr_en     = input_accept;
  assign fifo_rd_en     = fifo_rd_valid & shared_ready_i;
  assign shared_valid_o = fifo_rd_valid;
  assign shared_data_o  = fifo_rd_data;

  always_comb begin
    selected_is_pos = 1'b0;
    selected_valid  = 1'b0;
    selected_data   = '0;
    tdc_ready_o     = 1'b0;
    pos_ready_o     = 1'b0;

    if (grant_active_q) begin
      if (grant_is_pos_q) begin
        selected_is_pos = 1'b1;
        selected_valid  = pos_valid_i;
        selected_data   = pos_data_i;
        pos_ready_o     = selected_ready;
      end else begin
        selected_valid  = tdc_valid_i;
        selected_data   = tdc_data_i;
        tdc_ready_o     = selected_ready;
      end
    end else begin
      unique case (export_mode)
        SPADMIC_EXPORT_POSITION_ONLY: begin
          selected_is_pos = 1'b1;
          selected_valid  = pos_valid_i;
          selected_data   = pos_data_i;
          pos_ready_o     = selected_ready;
        end

        SPADMIC_EXPORT_TDC_ONLY: begin
          selected_valid  = tdc_valid_i;
          selected_data   = tdc_data_i;
          tdc_ready_o     = selected_ready;
        end

        default: begin
          if (rr_prefer_pos_q) begin
            if (pos_valid_i) begin
              selected_is_pos = 1'b1;
              selected_valid  = 1'b1;
              selected_data   = pos_data_i;
              pos_ready_o     = selected_ready;
            end else begin
              selected_valid  = tdc_valid_i;
              selected_data   = tdc_data_i;
              tdc_ready_o     = selected_ready;
            end
          end else begin
            if (tdc_valid_i) begin
              selected_valid  = 1'b1;
              selected_data   = tdc_data_i;
              tdc_ready_o     = selected_ready;
            end else begin
              selected_is_pos = 1'b1;
              selected_valid  = pos_valid_i;
              selected_data   = pos_data_i;
              pos_ready_o     = selected_ready;
            end
          end
        end
      endcase
    end
  end

  assign fifo_wr_data = (input_accept && is_tdc_eoc(selected_data))
                      ? {2'b11, assigned_event_id}
                      : selected_data;

  mptdc_sync_fifo #(
    .WIDTH (NARROW_W),
    .DEPTH (SPADMIC_OUTPUT_FIFO_DEPTH)
  ) u_out_fifo (
    .clk        (clk_sys),
    .rst_n      (rst_n),
    .clr_i      (1'b0),
    .wr_en_i    (fifo_wr_en),
    .wr_data_i  (fifo_wr_data),
    .wr_full_o  (fifo_full),
    .rd_en_i    (fifo_rd_en),
    .rd_data_o  (fifo_rd_data),
    .rd_valid_o (fifo_rd_valid),
    .level_o    (/* unused */)
  );

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      grant_active_q         <= 1'b0;
      grant_is_pos_q         <= 1'b0;
      rr_prefer_pos_q        <= 1'b0;
      word_idx_q             <= '0;
      packet_source_q        <= TDC_ID_X;
      packet_source_valid_q  <= 1'b0;
      correlation_overflow_o <= 1'b0;

      for (int i = 0; i < SPADMIC_SRC_COUNT; i++)
        source_event_id_q[i] <= '0;
    end else begin
      if (input_accept && is_tdc_header(selected_data)) begin
        word_idx_q            <= 4'd1;
        if (selected_is_pos) begin
          packet_source_valid_q <= 1'b1;
          packet_source_q <= SPADMIC_SRC_POSITION;
        end else begin
          packet_source_valid_q <= 1'b1;
          packet_source_q       <= tdc_header_source_id(selected_data);
        end
      end else if (input_accept) begin
        if (!packet_source_valid_q && (word_idx_q == 4'd1) && is_spadmic_subheader(selected_data)) begin
          packet_source_q       <= spadmic_source_id_e'(selected_data[5:4]);
          packet_source_valid_q <= 1'b1;
        end

        if (is_tdc_eoc(selected_data)) begin
          word_idx_q            <= '0;
          packet_source_valid_q <= 1'b0;
        end else begin
          word_idx_q <= word_idx_q + 4'd1;
        end
      end

      if (input_accept && !grant_active_q && !is_tdc_eoc(selected_data)) begin
        grant_active_q <= 1'b1;
        grant_is_pos_q <= selected_is_pos;
      end else if (input_accept && is_tdc_eoc(selected_data)) begin
        grant_active_q  <= 1'b0;
        rr_prefer_pos_q <= ~grant_is_pos_q;
      end

      if (input_accept && is_tdc_eoc(selected_data) && packet_source_valid_q) begin
        source_event_id_q[packet_source_now] <= source_event_id_q[packet_source_now]
                                             + SPADMIC_EVENT_ID_W'(1);
      end
    end
  end

endmodule

`default_nettype wire
