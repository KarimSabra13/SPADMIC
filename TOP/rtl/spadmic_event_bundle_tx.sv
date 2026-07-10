// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_event_bundle_tx.sv
// Purpose  : Mode-mask bundle transmitter with one event ID per physical event.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_event_bundle_tx (
  input  wire logic                                clk_sys,
  input  wire logic                                rst_n,
  input  wire logic                                bundle_start_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] required_packet_mask_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] source_pending_mask_i,
  input  wire logic [spadmic_pkg::SPADMIC_EVENT_ID_W-1:0] event_id_i,

  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_valid_i,
  output logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_ready_o,
  // SPADMIC_TX_SRC_DATA_GENERATED_BEGIN PORT_DECLS
  input wire logic src_data_i_s0_b0,
  input wire logic src_data_i_s0_b1,
  input wire logic src_data_i_s0_b2,
  input wire logic src_data_i_s0_b3,
  input wire logic src_data_i_s0_b4,
  input wire logic src_data_i_s0_b5,
  input wire logic src_data_i_s0_b6,
  input wire logic src_data_i_s0_b7,
  input wire logic src_data_i_s0_b8,
  input wire logic src_data_i_s0_b9,
  input wire logic src_data_i_s0_b10,
  input wire logic src_data_i_s0_b11,
  input wire logic src_data_i_s0_b12,
  input wire logic src_data_i_s0_b13,
  input wire logic src_data_i_s0_b14,
  input wire logic src_data_i_s0_b15,
  input wire logic src_data_i_s1_b0,
  input wire logic src_data_i_s1_b1,
  input wire logic src_data_i_s1_b2,
  input wire logic src_data_i_s1_b3,
  input wire logic src_data_i_s1_b4,
  input wire logic src_data_i_s1_b5,
  input wire logic src_data_i_s1_b6,
  input wire logic src_data_i_s1_b7,
  input wire logic src_data_i_s1_b8,
  input wire logic src_data_i_s1_b9,
  input wire logic src_data_i_s1_b10,
  input wire logic src_data_i_s1_b11,
  input wire logic src_data_i_s1_b12,
  input wire logic src_data_i_s1_b13,
  input wire logic src_data_i_s1_b14,
  input wire logic src_data_i_s1_b15,
  input wire logic src_data_i_s2_b0,
  input wire logic src_data_i_s2_b1,
  input wire logic src_data_i_s2_b2,
  input wire logic src_data_i_s2_b3,
  input wire logic src_data_i_s2_b4,
  input wire logic src_data_i_s2_b5,
  input wire logic src_data_i_s2_b6,
  input wire logic src_data_i_s2_b7,
  input wire logic src_data_i_s2_b8,
  input wire logic src_data_i_s2_b9,
  input wire logic src_data_i_s2_b10,
  input wire logic src_data_i_s2_b11,
  input wire logic src_data_i_s2_b12,
  input wire logic src_data_i_s2_b13,
  input wire logic src_data_i_s2_b14,
  input wire logic src_data_i_s2_b15,
  input wire logic src_data_i_s3_b0,
  input wire logic src_data_i_s3_b1,
  input wire logic src_data_i_s3_b2,
  input wire logic src_data_i_s3_b3,
  input wire logic src_data_i_s3_b4,
  input wire logic src_data_i_s3_b5,
  input wire logic src_data_i_s3_b6,
  input wire logic src_data_i_s3_b7,
  input wire logic src_data_i_s3_b8,
  input wire logic src_data_i_s3_b9,
  input wire logic src_data_i_s3_b10,
  input wire logic src_data_i_s3_b11,
  input wire logic src_data_i_s3_b12,
  input wire logic src_data_i_s3_b13,
  input wire logic src_data_i_s3_b14,
  input wire logic src_data_i_s3_b15,
  // SPADMIC_TX_SRC_DATA_GENERATED_END PORT_DECLS
  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_sop_i,
  input  wire logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0] src_eop_i,

  output logic                                word_valid_o,
  input  wire logic                                word_ready_i,
  output logic [mptdc_pkg::NARROW_W-1:0]      word_data_o,
  output logic                                flush_o,

  output logic [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0] completed_packet_mask_o,
  output logic                                done_o,
  output logic                                busy_o,
  output logic                                idle_o,
  output logic                                missing_source_error_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic [NARROW_W-1:0] src_data_i [SPADMIC_SRC_COUNT];
  // SPADMIC_TX_SRC_DATA_GENERATED_BEGIN ARRAY_ASSIGNMENTS src_data_i
  assign src_data_i[0][0] = src_data_i_s0_b0;
  assign src_data_i[0][1] = src_data_i_s0_b1;
  assign src_data_i[0][2] = src_data_i_s0_b2;
  assign src_data_i[0][3] = src_data_i_s0_b3;
  assign src_data_i[0][4] = src_data_i_s0_b4;
  assign src_data_i[0][5] = src_data_i_s0_b5;
  assign src_data_i[0][6] = src_data_i_s0_b6;
  assign src_data_i[0][7] = src_data_i_s0_b7;
  assign src_data_i[0][8] = src_data_i_s0_b8;
  assign src_data_i[0][9] = src_data_i_s0_b9;
  assign src_data_i[0][10] = src_data_i_s0_b10;
  assign src_data_i[0][11] = src_data_i_s0_b11;
  assign src_data_i[0][12] = src_data_i_s0_b12;
  assign src_data_i[0][13] = src_data_i_s0_b13;
  assign src_data_i[0][14] = src_data_i_s0_b14;
  assign src_data_i[0][15] = src_data_i_s0_b15;
  assign src_data_i[1][0] = src_data_i_s1_b0;
  assign src_data_i[1][1] = src_data_i_s1_b1;
  assign src_data_i[1][2] = src_data_i_s1_b2;
  assign src_data_i[1][3] = src_data_i_s1_b3;
  assign src_data_i[1][4] = src_data_i_s1_b4;
  assign src_data_i[1][5] = src_data_i_s1_b5;
  assign src_data_i[1][6] = src_data_i_s1_b6;
  assign src_data_i[1][7] = src_data_i_s1_b7;
  assign src_data_i[1][8] = src_data_i_s1_b8;
  assign src_data_i[1][9] = src_data_i_s1_b9;
  assign src_data_i[1][10] = src_data_i_s1_b10;
  assign src_data_i[1][11] = src_data_i_s1_b11;
  assign src_data_i[1][12] = src_data_i_s1_b12;
  assign src_data_i[1][13] = src_data_i_s1_b13;
  assign src_data_i[1][14] = src_data_i_s1_b14;
  assign src_data_i[1][15] = src_data_i_s1_b15;
  assign src_data_i[2][0] = src_data_i_s2_b0;
  assign src_data_i[2][1] = src_data_i_s2_b1;
  assign src_data_i[2][2] = src_data_i_s2_b2;
  assign src_data_i[2][3] = src_data_i_s2_b3;
  assign src_data_i[2][4] = src_data_i_s2_b4;
  assign src_data_i[2][5] = src_data_i_s2_b5;
  assign src_data_i[2][6] = src_data_i_s2_b6;
  assign src_data_i[2][7] = src_data_i_s2_b7;
  assign src_data_i[2][8] = src_data_i_s2_b8;
  assign src_data_i[2][9] = src_data_i_s2_b9;
  assign src_data_i[2][10] = src_data_i_s2_b10;
  assign src_data_i[2][11] = src_data_i_s2_b11;
  assign src_data_i[2][12] = src_data_i_s2_b12;
  assign src_data_i[2][13] = src_data_i_s2_b13;
  assign src_data_i[2][14] = src_data_i_s2_b14;
  assign src_data_i[2][15] = src_data_i_s2_b15;
  assign src_data_i[3][0] = src_data_i_s3_b0;
  assign src_data_i[3][1] = src_data_i_s3_b1;
  assign src_data_i[3][2] = src_data_i_s3_b2;
  assign src_data_i[3][3] = src_data_i_s3_b3;
  assign src_data_i[3][4] = src_data_i_s3_b4;
  assign src_data_i[3][5] = src_data_i_s3_b5;
  assign src_data_i[3][6] = src_data_i_s3_b6;
  assign src_data_i[3][7] = src_data_i_s3_b7;
  assign src_data_i[3][8] = src_data_i_s3_b8;
  assign src_data_i[3][9] = src_data_i_s3_b9;
  assign src_data_i[3][10] = src_data_i_s3_b10;
  assign src_data_i[3][11] = src_data_i_s3_b11;
  assign src_data_i[3][12] = src_data_i_s3_b12;
  assign src_data_i[3][13] = src_data_i_s3_b13;
  assign src_data_i[3][14] = src_data_i_s3_b14;
  assign src_data_i[3][15] = src_data_i_s3_b15;
  // SPADMIC_TX_SRC_DATA_GENERATED_END ARRAY_ASSIGNMENTS

  typedef enum logic [1:0] {
    BUNDLE_IDLE = 2'd0,
    BUNDLE_SEND = 2'd1,
    BUNDLE_FLUSH = 2'd2
  } bundle_state_e;

  bundle_state_e state_q;
  logic [SPADMIC_SRC_MASK_W-1:0] active_mask_q;
  logic [SPADMIC_SRC_MASK_W-1:0] completed_mask_q;
  logic [SPADMIC_EVENT_ID_W-1:0] event_id_q;
  spadmic_source_id_e current_source_q;

  wire current_valid = src_valid_i[current_source_q];
  wire current_eop = src_eop_i[current_source_q];
  wire out_accepted = word_valid_o && word_ready_i;
  wire [SPADMIC_SRC_MASK_W-1:0] current_source_bit =
      spadmic_source_bit(current_source_q);
  wire [SPADMIC_SRC_MASK_W-1:0] completed_next =
      completed_mask_q | current_source_bit;
  wire packet_finishes_bundle = (completed_next == active_mask_q);

  function automatic spadmic_source_id_e first_source(
    input logic [SPADMIC_SRC_MASK_W-1:0] mask
  );
    if (mask[TDC_ID_X])
      return TDC_ID_X;
    if (mask[TDC_ID_Y])
      return TDC_ID_Y;
    if (mask[TDC_ID_Z])
      return TDC_ID_Z;
    return SPADMIC_SRC_POSITION;
  endfunction

  function automatic logic [SPADMIC_SRC_MASK_W-1:0] remaining_after_current(
    input logic [SPADMIC_SRC_MASK_W-1:0] active_mask,
    input logic [SPADMIC_SRC_MASK_W-1:0] completed_mask,
    input spadmic_source_id_e            current_source
  );
    logic [SPADMIC_SRC_MASK_W-1:0] current_bit;
    current_bit = spadmic_source_bit(current_source);
    return active_mask & ~(completed_mask | current_bit);
  endfunction

  always_comb begin
    src_ready_o  = '0;
    word_valid_o = 1'b0;
    word_data_o  = '0;
    flush_o      = 1'b0;

    if (state_q == BUNDLE_SEND) begin
      word_valid_o = current_valid;
      src_ready_o[current_source_q] = word_ready_i;

      if (current_eop) begin
        word_data_o = {2'b11, event_id_q};
      end else if ((current_source_q != SPADMIC_SRC_POSITION) &&
                   src_sop_i[current_source_q] &&
                   is_tdc_header(src_data_i[current_source_q])) begin
        word_data_o = patch_tdc_id_into_header(
            src_data_i[current_source_q],
            spadmic_tdc_id_e'(current_source_q)
        );
      end else begin
        word_data_o = src_data_i[current_source_q];
      end
    end else if (state_q == BUNDLE_FLUSH) begin
      flush_o = 1'b1;
    end
  end

  assign completed_packet_mask_o = completed_mask_q;
  assign busy_o = (state_q != BUNDLE_IDLE);
  assign idle_o = (state_q == BUNDLE_IDLE);

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q                <= BUNDLE_IDLE;
      active_mask_q          <= '0;
      completed_mask_q       <= '0;
      event_id_q             <= '0;
      current_source_q       <= TDC_ID_X;
      done_o                 <= 1'b0;
      missing_source_error_o <= 1'b0;
    end else begin
      done_o                 <= 1'b0;
      missing_source_error_o <= 1'b0;

      unique case (state_q)
        BUNDLE_IDLE: begin
          if (bundle_start_i) begin
            if ((required_packet_mask_i == '0) ||
                ((source_pending_mask_i & required_packet_mask_i) !=
                 required_packet_mask_i)) begin
              missing_source_error_o <= 1'b1;
            end else begin
              active_mask_q    <= required_packet_mask_i;
              completed_mask_q <= '0;
              event_id_q       <= event_id_i;
              current_source_q <= first_source(required_packet_mask_i);
              state_q          <= BUNDLE_SEND;
            end
          end
        end

        BUNDLE_SEND: begin
          if (out_accepted && current_eop) begin
            completed_mask_q <= completed_next;
            if (packet_finishes_bundle) begin
              state_q <= BUNDLE_FLUSH;
            end else begin
              current_source_q <= first_source(
                  remaining_after_current(active_mask_q,
                                          completed_mask_q,
                                          current_source_q)
              );
            end
          end
        end

        BUNDLE_FLUSH: begin
          state_q <= BUNDLE_IDLE;
          done_o  <= 1'b1;
        end

        default: state_q <= BUNDLE_IDLE;
      endcase
    end
  end

  // synthesis translate_off
  logic [NARROW_W-1:0] hold_word_q;
  logic hold_valid_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      hold_valid_q <= 1'b0;
      hold_word_q  <= '0;
    end else if (word_valid_o && !word_ready_i) begin
      if (hold_valid_q) begin
        assert (word_data_o == hold_word_q)
          else $error("spadmic_event_bundle_tx: output changed while stalled");
      end
      hold_valid_q <= 1'b1;
      hold_word_q  <= word_data_o;
    end else begin
      hold_valid_q <= 1'b0;
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
