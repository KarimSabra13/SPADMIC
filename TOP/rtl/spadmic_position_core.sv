// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_position_core.sv
// Purpose  : Stable physical boundary for the position packetizer/scanners.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_position_core #(
  parameter int unsigned LINE_W = spadmic_pkg::SPADMIC_LINE_W
) (
  input  logic                            clk_sys,
  input  logic                            rst_n,
  input  logic                            start_i,
  input  spadmic_pkg::spadmic_pos_mode_e mode_i,
  input  logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_i,
  input  logic [LINE_W-1:0]               snapshot_R_i,
  input  logic [LINE_W-1:0]               snapshot_Y_i,
  input  logic [LINE_W-1:0]               snapshot_B_i,
  input  logic [$clog2(LINE_W + 1)-1:0]   gap_threshold_i,
  input  logic [$clog2(LINE_W + 1)-1:0]   min_cluster_span_i,
  output logic                            pkt_valid_o,
  input  logic                            pkt_ready_i,
  output logic [mptdc_pkg::NARROW_W-1:0] pkt_data_o,
  output logic                            pkt_sop_o,
  output logic                            pkt_eop_o,
  output logic                            packet_pending_o,
  output logic                            busy_o,
  output logic                            snapshot_captured_o,
  output logic                            done_o,
  output logic                            drop_o
);

  spadmic_position_snapshot_packetizer #(.LINE_W(LINE_W)) u_packetizer (
    .clk_sys             (clk_sys),
    .rst_n               (rst_n),
    .start_i             (start_i),
    .mode_i              (mode_i),
    .event_id_i          (event_id_i),
    .snapshot_R_i        (snapshot_R_i),
    .snapshot_Y_i        (snapshot_Y_i),
    .snapshot_B_i        (snapshot_B_i),
    .gap_threshold_i     (gap_threshold_i),
    .min_cluster_span_i  (min_cluster_span_i),
    .pkt_valid_o         (pkt_valid_o),
    .pkt_ready_i         (pkt_ready_i),
    .pkt_data_o          (pkt_data_o),
    .pkt_sop_o           (pkt_sop_o),
    .pkt_eop_o           (pkt_eop_o),
    .packet_pending_o    (packet_pending_o),
    .busy_o              (busy_o),
    .snapshot_captured_o (snapshot_captured_o),
    .done_o              (done_o),
    .drop_o              (drop_o)
  );

endmodule

`default_nettype wire
