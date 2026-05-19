// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_tdc_shared_readout.sv
// Purpose  : Shared TDC acquisition-record arbiter and shared serializer for the
//            one-bus SPADMIC top-level architecture.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_tdc_shared_readout (
  input  wire                                clk_sys,
  input  wire                                rst_n,
  input  wire [2:0]                          acq_valid_i,
  input  wire [mptdc_pkg::ACQ_REC_W-1:0]     acq_data_i [3],
  output logic [2:0]                         acq_ready_o,
  input  mptdc_pkg::out_mode_e               out_mode_i,
  input  wire                                shared_ready_i,
  output wire                                shared_valid_o,
  output wire [mptdc_pkg::NARROW_W-1:0]      shared_data_o,
  output wire                                busy_o,
  output wire [1:0]                          packet_src_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic [2:0] meta_available;
  logic       choice_valid;
  logic [1:0] choice_idx;
  logic [1:0] rr_ptr_q;

  logic       record_grant_active_q;
  logic [1:0] record_grant_idx_q;
  logic [MAX_HITS_W-1:0] hits_remaining_q;

  logic                     serializer_valid;
  logic [NARROW_W-1:0]      serializer_data;
  logic                     serializer_rd_en;
  logic                     selected_valid;
  logic [ACQ_REC_W-1:0]     selected_data_vec;
  mptdc_acq_rec_t           acq_rec [3];
  mptdc_acq_rec_t           selected_rec;
  spadmic_tdc_id_e          packet_src_q;
  logic                     packet_active_q;

  wire meta_pop = ~record_grant_active_q & serializer_rd_en & choice_valid;
  wire hit_pop  = record_grant_active_q & serializer_rd_en & selected_valid;
  wire packet_done = serializer_valid & shared_ready_i & is_tdc_eoc(shared_data_o);

  assign acq_rec[0] = acq_data_i[0];
  assign acq_rec[1] = acq_data_i[1];
  assign acq_rec[2] = acq_data_i[2];

  assign meta_available[0] = acq_valid_i[0] & (acq_rec[0].kind == ACQ_REC_META);
  assign meta_available[1] = acq_valid_i[1] & (acq_rec[1].kind == ACQ_REC_META);
  assign meta_available[2] = acq_valid_i[2] & (acq_rec[2].kind == ACQ_REC_META);

  // New packet ownership is decided only on META records so the shared serializer
  // never interleaves hit payload words from different axes.
  always_comb begin
    choice_valid = 1'b0;
    choice_idx   = 2'd0;

    case (rr_ptr_q)
      2'd0: begin
        if (meta_available[0]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd0;
        end else if (meta_available[1]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd1;
        end else if (meta_available[2]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd2;
        end
      end
      2'd1: begin
        if (meta_available[1]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd1;
        end else if (meta_available[2]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd2;
        end else if (meta_available[0]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd0;
        end
      end
      default: begin
        if (meta_available[2]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd2;
        end else if (meta_available[0]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd0;
        end else if (meta_available[1]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd1;
        end
      end
    endcase
  end

  // Once a packet is granted, ready is returned only to the owning axis until
  // all advertised HIT records have drained.
  always_comb begin
    selected_valid    = 1'b0;
    selected_data_vec = '0;
    acq_ready_o       = '0;

    if (record_grant_active_q) begin
      selected_valid = acq_valid_i[record_grant_idx_q];
      selected_data_vec = acq_data_i[record_grant_idx_q];
      acq_ready_o[record_grant_idx_q] = serializer_rd_en & selected_valid;
    end else if (choice_valid) begin
      selected_valid = acq_valid_i[choice_idx];
      selected_data_vec = acq_data_i[choice_idx];
      acq_ready_o[choice_idx] = serializer_rd_en & selected_valid;
    end
  end

  assign selected_rec   = selected_data_vec;
  assign shared_valid_o = serializer_valid;
  assign shared_data_o  = patch_tdc_id_into_header(serializer_data, packet_src_q);
  assign busy_o         = packet_active_q;
  assign packet_src_o   = packet_src_q;

  // The shared serializer is still the proven MPTDC narrow formatter; this block
  // only changes how acquisition records are selected and tagged.
  mptdc_narrow16_tx_v2 u_shared_narrow_tx (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .out_mode_i      (out_mode_i),
    .fifo_rd_valid_i (selected_valid),
    .fifo_rd_data_i  (selected_rec),
    .fifo_rd_en_o    (serializer_rd_en),
    .narrow_ready_i  (shared_ready_i),
    .narrow_valid_o  (serializer_valid),
    .narrow_data_o   (serializer_data)
  );

  // packet_src_q is held until EOC so the shared header source tag remains
  // coherent even while the serializer is consuming several HIT records.
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      rr_ptr_q             <= 2'd0;
      record_grant_active_q <= 1'b0;
      record_grant_idx_q   <= 2'd0;
      hits_remaining_q     <= '0;
      packet_src_q         <= TDC_ID_X;
      packet_active_q      <= 1'b0;
    end else begin
      if (meta_pop) begin
        rr_ptr_q        <= (choice_idx == 2'd2) ? 2'd0 : (choice_idx + 2'd1);
        packet_src_q    <= spadmic_tdc_id_e'(choice_idx);
        packet_active_q <= 1'b1;

        if (selected_rec.meta.hit_count != '0) begin
          record_grant_active_q <= 1'b1;
          record_grant_idx_q    <= choice_idx;
          hits_remaining_q      <= selected_rec.meta.hit_count;
        end else begin
          record_grant_active_q <= 1'b0;
          hits_remaining_q      <= '0;
        end
      end else if (hit_pop) begin
        if (hits_remaining_q == MAX_HITS_W'(1)) begin
          record_grant_active_q <= 1'b0;
          hits_remaining_q      <= '0;
        end else begin
          hits_remaining_q <= hits_remaining_q - MAX_HITS_W'(1);
        end
      end

      if (packet_done)
        packet_active_q <= 1'b0;
    end
  end

  // synthesis translate_off
  logic                            shared_hold_valid_q;
  logic [NARROW_W-1:0]             shared_data_hold_q;
  logic                            packet_src_hold_valid_q;
  spadmic_tdc_id_e                 packet_src_hold_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      shared_hold_valid_q     <= 1'b0;
      shared_data_hold_q      <= '0;
      packet_src_hold_valid_q <= 1'b0;
      packet_src_hold_q       <= TDC_ID_X;
    end else begin
      assert ((int'(acq_ready_o[0]) + int'(acq_ready_o[1]) + int'(acq_ready_o[2])) <= 1)
        else $error("spadmic_tdc_shared_readout: more than one axis ready");

      if (shared_valid_o && !shared_ready_i) begin
        if (shared_hold_valid_q) begin
          assert (shared_data_o == shared_data_hold_q)
            else $error("spadmic_tdc_shared_readout: shared_data_o changed while stalled");
        end
        shared_hold_valid_q <= 1'b1;
        shared_data_hold_q  <= shared_data_o;
      end else begin
        shared_hold_valid_q <= 1'b0;
      end

      if (packet_active_q) begin
        if (packet_src_hold_valid_q) begin
          assert (packet_src_q == packet_src_hold_q)
            else $error("spadmic_tdc_shared_readout: packet source changed before EOC");
        end
        packet_src_hold_valid_q <= 1'b1;
        packet_src_hold_q       <= packet_src_q;
      end else begin
        packet_src_hold_valid_q <= 1'b0;
      end
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
