// =============================================================================
// Project  : SPADMIC ARB
// File     : spadmic_position_packet_adapter.sv
// Purpose  : Adds packet sidebands to the position block's 16-bit word stream.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_position_packet_adapter (
  input  wire                            clk_sys,
  input  wire                            rst_n,
  input  wire                            enable_i,

  input  wire                            pos_valid_i,
  input  wire [mptdc_pkg::NARROW_W-1:0]  pos_data_i,
  output logic                           pos_ready_o,

  output logic                           pkt_valid_o,
  input  wire                            pkt_ready_i,
  output logic [mptdc_pkg::NARROW_W-1:0] pkt_data_o,
  output logic                           pkt_sop_o,
  output logic                           pkt_eop_o,
  output spadmic_pkg::spadmic_source_id_e pkt_source_o,
  output wire                            packet_active_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic [4:0] word_idx_q;
  logic       raw_packet_q;
  logic       compact_packet_q;
  logic [4:0] compact_last_word_q;
  logic       packet_active_q;
  logic       input_allowed;
  logic       accept_word;
  logic       eop_now;

  assign input_allowed = enable_i | packet_active_q;
  assign eop_now = raw_packet_q
                 ? (word_idx_q == 5'(SPADMIC_POS_RAW_PKT_WORDS - 1))
                 : compact_packet_q
                   ? (word_idx_q == compact_last_word_q)
                   : (word_idx_q == 5'(SPADMIC_POS_PKT_WORDS - 1));

  assign pkt_source_o = SPADMIC_SRC_POSITION;
  assign packet_active_o = packet_active_q;
  assign accept_word = pkt_valid_o & pkt_ready_i;

  always_comb begin
    pkt_valid_o = pos_valid_i & input_allowed;
    pkt_data_o  = pos_data_i;
    pkt_sop_o   = (word_idx_q == '0);
    pkt_eop_o   = eop_now;
    pos_ready_o = pkt_ready_i & input_allowed;
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      word_idx_q      <= '0;
      raw_packet_q    <= 1'b0;
      compact_packet_q <= 1'b0;
      compact_last_word_q <= 5'(SPADMIC_POS_PKT_WORDS - 1);
      packet_active_q <= 1'b0;
    end else if (accept_word) begin
      if (word_idx_q == '0) begin
        raw_packet_q     <= is_spadmic_pos_raw_header(pos_data_i);
        compact_packet_q <= is_spadmic_pos_compact_header(pos_data_i);
        compact_last_word_q <= is_spadmic_pos_compact_header(pos_data_i)
                             ? 5'(3'd1 + spadmic_pos_compact_payload_words(pos_data_i))
                             : 5'(SPADMIC_POS_PKT_WORDS - 1);
        packet_active_q <= !eop_now;
      end

      if (eop_now) begin
        word_idx_q          <= '0;
        raw_packet_q        <= 1'b0;
        compact_packet_q    <= 1'b0;
        compact_last_word_q <= 5'(SPADMIC_POS_PKT_WORDS - 1);
        packet_active_q     <= 1'b0;
      end else begin
        word_idx_q      <= word_idx_q + 5'd1;
        packet_active_q <= 1'b1;
      end
    end
  end

endmodule

`default_nettype wire
