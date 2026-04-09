// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_tdc_packet_fifo.sv
// Purpose  : Legacy packet FIFO retained for standalone collateral around the
//            older per-axis narrow packet path.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_tdc_packet_fifo #(
  parameter int unsigned DEPTH = 64,
  parameter spadmic_pkg::spadmic_tdc_id_e TDC_ID = spadmic_pkg::TDC_ID_X
) (
  input  wire                 clk_sys,
  input  wire                 rst_n,

  input  wire                 narrow_valid_i,
  input  wire [15:0]          narrow_data_i,
  output wire                 narrow_ready_o,

  output wire                 pkt_valid_o,
  output wire [15:0]          pkt_data_o,
  output wire                 pkt_sop_o,
  output wire                 pkt_eop_o,
  input  wire                 pkt_ready_i,

  output wire                 pkt_available_o,
  output wire                 fifo_full_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int unsigned FIFO_W = NARROW_W + 2;
  localparam int unsigned PKT_CNT_W = $clog2(DEPTH + 1);

  logic [FIFO_W-1:0] fifo_wr_data;
  logic [FIFO_W-1:0] fifo_rd_data;
  logic              fifo_wr_en;
  logic              fifo_rd_en;
  logic              fifo_rd_valid;
  logic [PKT_CNT_W-1:0] packet_count_q;

  wire sop_word = is_tdc_header(narrow_data_i);
  wire eop_word = is_tdc_eoc(narrow_data_i);
  wire [NARROW_W-1:0] patched_word = patch_tdc_id_into_subheader(
    narrow_data_i,
    TDC_ID
  );

  assign fifo_wr_data   = {sop_word, eop_word, patched_word};
  assign narrow_ready_o = ~fifo_full_o;
  assign fifo_wr_en     = narrow_valid_i & narrow_ready_o;
  assign pkt_available_o = (packet_count_q != '0);
  assign pkt_valid_o     = fifo_rd_valid & pkt_available_o;
  assign {pkt_sop_o, pkt_eop_o, pkt_data_o} = fifo_rd_data;
  assign fifo_rd_en      = pkt_valid_o & pkt_ready_i;

  // The FIFO stores SOP/EOP sideband bits with each word so the downstream
  // legacy arbiter can preserve packet boundaries without reparsing payloads.
  mptdc_sync_fifo #(
    .WIDTH (FIFO_W),
    .DEPTH (DEPTH)
  ) u_fifo (
    .clk        (clk_sys),
    .rst_n      (rst_n),
    .clr_i      (1'b0),
    .wr_en_i    (fifo_wr_en),
    .wr_data_i  (fifo_wr_data),
    .wr_full_o  (fifo_full_o),
    .rd_en_i    (fifo_rd_en),
    .rd_data_o  (fifo_rd_data),
    .rd_valid_o (fifo_rd_valid),
    .level_o    (/* unused */)
  );

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      packet_count_q <= '0;
    end else begin
      case ({fifo_wr_en & eop_word, fifo_rd_en & pkt_eop_o})
        2'b10: packet_count_q <= packet_count_q + PKT_CNT_W'(1);
        2'b01: packet_count_q <= packet_count_q - PKT_CNT_W'(1);
        default: ;
      endcase
    end
  end

endmodule

`default_nettype wire
