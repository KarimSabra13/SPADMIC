// =============================================================================
// Project  : SPADMIC ARB
// File     : spadmic_correlated_tx.sv
// Purpose  : Uniform TDC/position packet funnel with unified event tagging.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_correlated_tx (
  input  wire                                clk_sys,
  input  wire                                rst_n,
  input  wire spadmic_pkg::spadmic_tx_sel_e  tx_sel_i,
  input  wire [spadmic_pkg::SPADMIC_AXIS_COUNT-1:0] axis_enable_i,
  input  wire                                position_enable_i,
  input  mptdc_pkg::out_mode_e               tdc_out_mode_i,

  input  wire [spadmic_pkg::SPADMIC_AXIS_COUNT-1:0] acq_valid_i,
  input  wire [mptdc_pkg::ACQ_REC_W-1:0]     acq_data_i [spadmic_pkg::SPADMIC_AXIS_COUNT],
  output logic [spadmic_pkg::SPADMIC_AXIS_COUNT-1:0] acq_ready_o,

  input  wire                                pos_valid_i,
  input  wire [mptdc_pkg::NARROW_W-1:0]      pos_data_i,
  output logic                               pos_ready_o,

  input  wire                                shared_ready_i,
  output wire                                shared_valid_o,
  output wire [mptdc_pkg::NARROW_W-1:0]      shared_data_o,

  output wire                                tdc_busy_o,
  output wire                                arb_busy_o,
  output logic                               correlation_overflow_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  spadmic_export_mode_e export_mode;
  logic                 tdc_mode_supported;

  logic [SPADMIC_SRC_COUNT-1:0] source_enable_d;
  logic [SPADMIC_SRC_COUNT-1:0] source_enable_q;
  logic [SPADMIC_SRC_COUNT-1:0] source_mask_q;
  logic [SPADMIC_SRC_COUNT-1:0] source_active;

  logic [SPADMIC_SRC_COUNT-1:0] src_valid;
  logic [SPADMIC_SRC_COUNT-1:0] src_ready;
  logic [NARROW_W-1:0]          src_data [SPADMIC_SRC_COUNT];
  logic [SPADMIC_SRC_COUNT-1:0] src_sop;
  logic [SPADMIC_SRC_COUNT-1:0] src_eop;
  spadmic_source_id_e           src_source [SPADMIC_SRC_COUNT];

  logic                         arb_pkt_valid;
  logic                         arb_pkt_ready;
  logic [NARROW_W-1:0]          arb_pkt_data;
  logic                         arb_pkt_sop;
  logic                         arb_pkt_eop;
  spadmic_source_id_e           arb_pkt_source;
  logic [SPADMIC_SRC_COUNT-1:0] arb_source_pending;
  logic                         arb_core_busy;

  logic                         arb_fifo_valid;
  logic                         arb_fifo_ready;
  logic [NARROW_W-1:0]          arb_fifo_data;
  logic                         arb_fifo_sop;
  logic                         arb_fifo_eop;
  spadmic_source_id_e           arb_fifo_source;

  logic [NARROW_W-1:0]          fifo_wr_data;
  logic [NARROW_W-1:0]          fifo_rd_data;
  logic                         fifo_wr_en;
  logic                         fifo_rd_en;
  logic                         fifo_rd_valid;
  logic                         fifo_full;

  logic [SPADMIC_EVENT_ID_W-1:0] unified_event_id_q;

  assign export_mode = spadmic_export_mode_from_ctrl(tx_sel_i, position_enable_i);
  assign tdc_mode_supported = (tdc_out_mode_i == OUT_MODE_RAW_FEATURES)
                            || (tdc_out_mode_i == OUT_MODE_FULL);

  always_comb begin
    source_enable_d = '0;

    if ((export_mode != SPADMIC_EXPORT_POSITION_ONLY) && tdc_mode_supported) begin
      source_enable_d[TDC_ID_X] = axis_enable_i[0];
      source_enable_d[TDC_ID_Y] = axis_enable_i[1];
      source_enable_d[TDC_ID_Z] = axis_enable_i[2];
    end

    if ((export_mode != SPADMIC_EXPORT_TDC_ONLY) && position_enable_i)
      source_enable_d[SPADMIC_SRC_POSITION] = 1'b1;
  end

  spadmic_tdc_packet_adapter #(.SOURCE_ID(TDC_ID_X)) u_tdc_x_adapter (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .enable_i        (source_enable_q[TDC_ID_X]),
    .out_mode_i      (tdc_out_mode_i),
    .acq_valid_i     (acq_valid_i[0]),
    .acq_data_i      (acq_data_i[0]),
    .acq_ready_o     (acq_ready_o[0]),
    .pkt_valid_o     (src_valid[TDC_ID_X]),
    .pkt_ready_i     (src_ready[TDC_ID_X]),
    .pkt_data_o      (src_data[TDC_ID_X]),
    .pkt_sop_o       (src_sop[TDC_ID_X]),
    .pkt_eop_o       (src_eop[TDC_ID_X]),
    .pkt_source_o    (src_source[TDC_ID_X]),
    .packet_active_o (source_active[TDC_ID_X])
  );

  spadmic_tdc_packet_adapter #(.SOURCE_ID(TDC_ID_Y)) u_tdc_y_adapter (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .enable_i        (source_enable_q[TDC_ID_Y]),
    .out_mode_i      (tdc_out_mode_i),
    .acq_valid_i     (acq_valid_i[1]),
    .acq_data_i      (acq_data_i[1]),
    .acq_ready_o     (acq_ready_o[1]),
    .pkt_valid_o     (src_valid[TDC_ID_Y]),
    .pkt_ready_i     (src_ready[TDC_ID_Y]),
    .pkt_data_o      (src_data[TDC_ID_Y]),
    .pkt_sop_o       (src_sop[TDC_ID_Y]),
    .pkt_eop_o       (src_eop[TDC_ID_Y]),
    .pkt_source_o    (src_source[TDC_ID_Y]),
    .packet_active_o (source_active[TDC_ID_Y])
  );

  spadmic_tdc_packet_adapter #(.SOURCE_ID(TDC_ID_Z)) u_tdc_z_adapter (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .enable_i        (source_enable_q[TDC_ID_Z]),
    .out_mode_i      (tdc_out_mode_i),
    .acq_valid_i     (acq_valid_i[2]),
    .acq_data_i      (acq_data_i[2]),
    .acq_ready_o     (acq_ready_o[2]),
    .pkt_valid_o     (src_valid[TDC_ID_Z]),
    .pkt_ready_i     (src_ready[TDC_ID_Z]),
    .pkt_data_o      (src_data[TDC_ID_Z]),
    .pkt_sop_o       (src_sop[TDC_ID_Z]),
    .pkt_eop_o       (src_eop[TDC_ID_Z]),
    .pkt_source_o    (src_source[TDC_ID_Z]),
    .packet_active_o (source_active[TDC_ID_Z])
  );

  spadmic_position_packet_adapter u_pos_adapter (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .enable_i        (source_enable_q[SPADMIC_SRC_POSITION]),
    .pos_valid_i     (pos_valid_i),
    .pos_data_i      (pos_data_i),
    .pos_ready_o     (pos_ready_o),
    .pkt_valid_o     (src_valid[SPADMIC_SRC_POSITION]),
    .pkt_ready_i     (src_ready[SPADMIC_SRC_POSITION]),
    .pkt_data_o      (src_data[SPADMIC_SRC_POSITION]),
    .pkt_sop_o       (src_sop[SPADMIC_SRC_POSITION]),
    .pkt_eop_o       (src_eop[SPADMIC_SRC_POSITION]),
    .pkt_source_o    (src_source[SPADMIC_SRC_POSITION]),
    .packet_active_o (source_active[SPADMIC_SRC_POSITION])
  );

  spadmic_packet_arbiter4 u_packet_arbiter (
    .clk_sys          (clk_sys),
    .rst_n            (rst_n),
    .source_mask_i    (source_mask_q),
    .src_valid_i      (src_valid),
    .src_ready_o      (src_ready),
    .src_data_i       (src_data),
    .src_sop_i        (src_sop),
    .src_eop_i        (src_eop),
    .src_source_i     (src_source),
    .arb_valid_o      (arb_pkt_valid),
    .arb_ready_i      (arb_pkt_ready),
    .arb_data_o       (arb_pkt_data),
    .arb_sop_o        (arb_pkt_sop),
    .arb_eop_o        (arb_pkt_eop),
    .arb_source_o     (arb_pkt_source),
    .source_pending_o (arb_source_pending),
    .arb_busy_o       (arb_core_busy)
  );

  spadmic_stream_skid_buffer u_arb_out_skid (
    .clk_sys      (clk_sys),
    .rst_n        (rst_n),
    .in_valid_i   (arb_pkt_valid),
    .in_ready_o   (arb_pkt_ready),
    .in_data_i    (arb_pkt_data),
    .in_sop_i     (arb_pkt_sop),
    .in_eop_i     (arb_pkt_eop),
    .in_source_i  (arb_pkt_source),
    .out_valid_o  (arb_fifo_valid),
    .out_ready_i  (arb_fifo_ready),
    .out_data_o   (arb_fifo_data),
    .out_sop_o    (arb_fifo_sop),
    .out_eop_o    (arb_fifo_eop),
    .out_source_o (arb_fifo_source)
  );

  assign arb_fifo_ready = !fifo_full;
  assign fifo_wr_en     = arb_fifo_valid & arb_fifo_ready;
  assign fifo_wr_data   = arb_fifo_eop ? {2'b11, unified_event_id_q} : arb_fifo_data;
  assign fifo_rd_en     = fifo_rd_valid & shared_ready_i;
  assign shared_valid_o = fifo_rd_valid;
  assign shared_data_o  = fifo_rd_data;
  assign tdc_busy_o     = (|source_active[2:0]) | (|arb_source_pending[2:0]);
  assign arb_busy_o     = arb_core_busy | arb_fifo_valid | fifo_rd_valid;

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
      source_enable_q         <= '0;
      source_mask_q           <= '0;
      unified_event_id_q      <= '0;
      correlation_overflow_o  <= 1'b0;
    end else begin
      source_enable_q <= source_enable_d;
      source_mask_q   <= source_enable_d | source_active | arb_source_pending;

      if (fifo_wr_en && arb_fifo_eop) begin
        if (&unified_event_id_q)
          correlation_overflow_o <= 1'b1;
        unified_event_id_q <= unified_event_id_q + SPADMIC_EVENT_ID_W'(1);
      end
    end
  end

  // synthesis translate_off
  logic packet_open_q;
  spadmic_source_id_e packet_source_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      packet_open_q   <= 1'b0;
      packet_source_q <= TDC_ID_X;
    end else if (fifo_wr_en) begin
      if (arb_fifo_sop) begin
        assert (!packet_open_q)
          else $error("spadmic_correlated_tx: SOP observed before previous EOP");
        packet_source_q <= arb_fifo_source;
        packet_open_q   <= !arb_fifo_eop;
      end else begin
        assert (packet_open_q)
          else $error("spadmic_correlated_tx: payload/EOP without open packet");
        assert (arb_fifo_source == packet_source_q)
          else $error("spadmic_correlated_tx: source changed mid-packet");
        if (arb_fifo_eop)
          packet_open_q <= 1'b0;
      end
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
