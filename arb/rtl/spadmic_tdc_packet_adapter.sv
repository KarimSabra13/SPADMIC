// =============================================================================
// Project  : SPADMIC ARB
// File     : spadmic_tdc_packet_adapter.sv
// Purpose  : Per-axis MPTDC acquisition-record to 16-bit packet stream adapter.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_tdc_packet_adapter #(
  parameter logic [spadmic_pkg::SPADMIC_AXIS_ID_W-1:0] SOURCE_ID = spadmic_pkg::TDC_ID_X
)(
  input  wire                            clk_sys,
  input  wire                            rst_n,
  input  wire                            enable_i,
  input  mptdc_pkg::out_mode_e           out_mode_i,

  input  wire                            acq_valid_i,
  input  wire [mptdc_pkg::ACQ_REC_W-1:0] acq_data_i,
  output logic                           acq_ready_o,

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

  typedef enum logic [3:0] {
    S_IDLE      = 4'd0,
    S_HEADER    = 4'd1,
    S_HIT_FETCH = 4'd2,
    S_HIT_W0    = 4'd4,
    S_HIT_W1    = 4'd5,
    S_EOC       = 4'd7
  } adapter_state_e;

  adapter_state_e        state_q;
  mptdc_acq_rec_t        acq_rec;
  ctx_id_t               ctx_id_q;
  logic                  phase0_snap_q;
  stop_phase_disc_t      stop_slow_phase_disc_q;
  logic                  slow_boundary_inc_q;
  logic [MAX_HITS_W-1:0] hit_count_q;
  tdc_conv_flags_t       flags_q;
  logic [NSLOW_W-1:0]    nslow_q;
  ph_idx_t               ns_q;
  ph_idx_t               nf_q;
  logic [NFAST_W-1:0]    nfast_q;
  logic [MAX_HITS_W-1:0] hit_idx_q;

  logic [NARROW_W-1:0]   header_word_raw;
  logic [NARROW_W-1:0]   header_word;
  logic [NARROW_W-1:0]   hit_w0;
  logic [NARROW_W-1:0]   hit_w1_feat;
  logic [NARROW_W-1:0]   eoc_word;

  wire                   out_accepted = pkt_valid_o & pkt_ready_i;
  wire                   last_hit_done = ((hit_idx_q + MAX_HITS_W'(1)) == hit_count_q);

  assign acq_rec = acq_data_i;
  assign pkt_source_o = spadmic_source_id_e'(SOURCE_ID);
  assign packet_active_o = (state_q != S_IDLE);
  wire unused_out_mode = |out_mode_i;

  assign header_word_raw = {2'b10,
                            PACKET_CTX_W'(ctx_id_q),
                            phase0_snap_q,
                            hit_count_q,
                            flags_q,
                            slow_boundary_inc_q,
                            2'b00};
  assign header_word = patch_tdc_id_into_header(header_word_raw, spadmic_tdc_id_e'(SOURCE_ID));
  assign hit_w0      = {1'b0, nslow_q[6:0], nfast_q[6:0], 1'b0};
  assign hit_w1_feat = {1'b0, 4'(ns_q), 4'(nf_q), 4'b0, stop_slow_phase_disc_q};
  assign eoc_word    = {2'b11, {SPADMIC_EVENT_ID_W{1'b0}}};

  always_comb begin
    pkt_valid_o = 1'b0;
    pkt_data_o  = '0;
    pkt_sop_o   = 1'b0;
    pkt_eop_o   = 1'b0;
    acq_ready_o = 1'b0;

    unique case (state_q)
      S_IDLE: begin
        acq_ready_o = enable_i
                    & acq_valid_i
                    & (acq_rec.kind == ACQ_REC_META);
      end

      S_HEADER: begin
        pkt_valid_o = 1'b1;
        pkt_data_o  = header_word;
        pkt_sop_o   = 1'b1;
      end

      S_HIT_FETCH: begin
        acq_ready_o = acq_valid_i & (acq_rec.kind == ACQ_REC_HIT);
      end

      S_HIT_W0: begin
        pkt_valid_o = 1'b1;
        pkt_data_o  = hit_w0;
      end

      S_HIT_W1: begin
        pkt_valid_o = 1'b1;
        pkt_data_o  = hit_w1_feat;
      end

      S_EOC: begin
        pkt_valid_o = 1'b1;
        pkt_data_o  = eoc_word;
        pkt_eop_o   = 1'b1;
      end

      default: ;
    endcase
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q                  <= S_IDLE;
      ctx_id_q                 <= '0;
      phase0_snap_q            <= 1'b0;
      stop_slow_phase_disc_q   <= '0;
      slow_boundary_inc_q      <= 1'b0;
      hit_count_q              <= '0;
      flags_q                  <= '0;
      nslow_q                  <= '0;
      ns_q                     <= '0;
      nf_q                     <= '0;
      nfast_q                  <= '0;
      hit_idx_q                <= '0;
    end else begin
      unique case (state_q)
        S_IDLE: begin
          if (acq_ready_o) begin
            ctx_id_q               <= acq_rec.meta.ctx_id;
            phase0_snap_q          <= acq_rec.meta.phase0_snap;
            stop_slow_phase_disc_q <= acq_rec.meta.stop_slow_phase_disc;
            slow_boundary_inc_q    <= acq_rec.meta.slow_boundary_inc;
            hit_count_q            <= acq_rec.meta.hit_count;
            flags_q                <= acq_rec.meta.flags;
            nslow_q                <= acq_rec.meta.nslow;
            hit_idx_q              <= '0;
            state_q                <= S_HEADER;
          end
        end

        S_HEADER: begin
          if (out_accepted)
            state_q <= (hit_count_q == '0) ? S_EOC : S_HIT_FETCH;
        end

        S_HIT_FETCH: begin
          if (acq_ready_o) begin
            ns_q     <= acq_rec.hit.ns;
            nf_q     <= acq_rec.hit.nf;
            nfast_q  <= acq_rec.hit.nfast;
            state_q  <= S_HIT_W0;
          end
        end

        S_HIT_W0: begin
          if (out_accepted)
            state_q <= S_HIT_W1;
        end

        S_HIT_W1: begin
          if (out_accepted) begin
            hit_idx_q <= hit_idx_q + MAX_HITS_W'(1);
            state_q   <= last_hit_done ? S_EOC : S_HIT_FETCH;
          end
        end

        S_EOC: begin
          if (out_accepted)
            state_q <= S_IDLE;
        end

        default: state_q <= S_IDLE;
      endcase
    end
  end

  // synthesis translate_off
  logic [NARROW_W-1:0] hold_data_q;
  logic                hold_valid_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      hold_valid_q <= 1'b0;
      hold_data_q  <= '0;
    end else begin
      if (pkt_valid_o && !pkt_ready_i) begin
        if (hold_valid_q)
          assert (pkt_data_o == hold_data_q)
            else $error("spadmic_tdc_packet_adapter: packet data changed under stall");
        hold_valid_q <= 1'b1;
        hold_data_q  <= pkt_data_o;
      end else begin
        hold_valid_q <= 1'b0;
      end
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
