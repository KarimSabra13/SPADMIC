// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_position_snapshot_packetizer.sv
// Purpose  : Raw position packet producer from the protected matrix snapshot.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_position_snapshot_packetizer #(
  parameter int unsigned LINE_W = spadmic_pkg::SPADMIC_LINE_W
) (
  input  logic                         clk_sys,
  input  logic                         rst_n,
  input  logic                         start_i,
  input  logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_i,
  input  logic [LINE_W-1:0]            snapshot_R_i,
  input  logic [LINE_W-1:0]            snapshot_Y_i,
  input  logic [LINE_W-1:0]            snapshot_B_i,

  output logic                         pkt_valid_o,
  input  logic                         pkt_ready_i,
  output logic [mptdc_pkg::NARROW_W-1:0] pkt_data_o,
  output logic                         pkt_sop_o,
  output logic                         pkt_eop_o,
  output logic                         packet_pending_o,
  output logic                         busy_o,
  output logic                         done_o,
  output logic                         drop_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int unsigned RAW_WORDS_PER_AXIS =
      (LINE_W + NARROW_W - 1) / NARROW_W;
  localparam int unsigned RAW_PKT_WORDS = 1 + (3 * RAW_WORDS_PER_AXIS) + 1;
  localparam int unsigned WORD_IDX_W = $clog2(RAW_PKT_WORDS);

  logic [LINE_W-1:0] r_snapshot_q;
  logic [LINE_W-1:0] y_snapshot_q;
  logic [LINE_W-1:0] b_snapshot_q;
  logic [SPADMIC_EVENT_ID_W-1:0] event_id_q;
  logic [WORD_IDX_W-1:0] word_idx_q;
  logic active_q;

  wire out_accepted = pkt_valid_o && pkt_ready_i;
  wire last_word = (word_idx_q == WORD_IDX_W'(RAW_PKT_WORDS - 1));
  wire [2:0] non_empty_mask = {
      |b_snapshot_q,
      |y_snapshot_q,
      |r_snapshot_q
  };

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

  always_comb begin
    pkt_valid_o = active_q;
    pkt_sop_o   = active_q && (word_idx_q == '0);
    pkt_eop_o   = active_q && last_word;
    pkt_data_o  = '0;

    if (active_q) begin
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
    end
  end

  assign packet_pending_o = active_q;
  assign busy_o = active_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      active_q     <= 1'b0;
      r_snapshot_q <= '0;
      y_snapshot_q <= '0;
      b_snapshot_q <= '0;
      event_id_q   <= '0;
      word_idx_q   <= '0;
      done_o       <= 1'b0;
      drop_o       <= 1'b0;
    end else begin
      done_o <= 1'b0;
      drop_o <= 1'b0;

      if (start_i) begin
        if (active_q) begin
          drop_o <= 1'b1;
        end else begin
          active_q     <= 1'b1;
          r_snapshot_q <= snapshot_R_i;
          y_snapshot_q <= snapshot_Y_i;
          b_snapshot_q <= snapshot_B_i;
          event_id_q   <= event_id_i;
          word_idx_q   <= '0;
        end
      end else if (out_accepted) begin
        if (last_word) begin
          active_q   <= 1'b0;
          word_idx_q <= '0;
          done_o     <= 1'b1;
        end else begin
          word_idx_q <= word_idx_q + WORD_IDX_W'(1);
        end
      end
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
