`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.2 — Design Review Enhanced Vernier TDC
// File     : mptdc_narrow16_tx_v2.sv
// Purpose  : 16-bit ready/valid serializer — reads from sync FIFO, emits
//            configurable narrow packets (raw features / raw timestamp / full)
// Author   : Karim Sabra
// =============================================================================
// Reads META + HIT acquisition records from the sync FIFO
// and serialises them onto a 16-bit ready/valid bus.
//
// Packet format (per conversion):
//   1 × Header   — context id, hit count, flags, output mode, boundary_inc
//   N × Hit word  — 2/3/4 words per hit depending on out_mode
//   1 × EOC      — end-of-conversion marker with 14-bit running counter
//
// v2.2: header bit[0] carries slow_boundary_inc for offline calibration
// =============================================================================
module mptdc_narrow16_tx_v2
  import mptdc_pkg::*;
(
  input  wire                   clk_sys,
  input  wire                   rst_n,

  // Configuration
  input  out_mode_e             out_mode_i,

  // Sync-FIFO read port (FWFT: data valid while fifo_rd_valid_i is high)
  input  wire                   fifo_rd_valid_i,
  input  mptdc_acq_rec_t        fifo_rd_data_i,
  output logic                  fifo_rd_en_o,

  // 16-bit narrow output (ready / valid)
  input  wire                   narrow_ready_i,
  output logic                  narrow_valid_o,
  output logic [NARROW_W-1:0]  narrow_data_o
);

  // ---------------------------------------------------------------------------
  // FSM encoding
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    S_IDLE      = 3'd0,
    S_HEADER    = 3'd1,
    S_HIT_FETCH = 3'd2,
    S_HIT_W0    = 3'd3,
    S_HIT_W1    = 3'd4,
    S_HIT_W2    = 3'd5,
    S_HIT_W3    = 3'd6,
    S_EOC       = 3'd7
  } tx_state_e;

  tx_state_e state_q;

  // ---------------------------------------------------------------------------
  // Latched conversion context (from META record)
  // ---------------------------------------------------------------------------
  ctx_id_t                ctx_id_q;
  logic                   phase0_snap_q;
  logic                   slow_boundary_inc_q;  // v2.2
  logic [MAX_HITS_W-1:0]  hit_count_q;
  tdc_conv_flags_t        flags_q;
  out_mode_e              out_mode_q;
  logic [NSLOW_W-1:0]     nslow_q;
  logic [NFAST_W-1:0]     nfast_snap_q;       // v2.2.2: nfast at CAPTURE time

  // ---------------------------------------------------------------------------
  // Latched hit data (from HIT record)
  // ---------------------------------------------------------------------------
  ph_idx_t                ns_q;
  ph_idx_t                nf_q;
  logic [NFAST_W-1:0]     nfast_q;
  logic [EVENT_SEQ_W-1:0] event_seq_q;

  // ---------------------------------------------------------------------------
  // Hit index (counts fully-emitted hits, 0-based)
  // ---------------------------------------------------------------------------
  logic [MAX_HITS_W-1:0]  hit_idx_q;

  // ---------------------------------------------------------------------------
  // 14-bit wrapping conversion counter (appears in EOC word)
  // ---------------------------------------------------------------------------
  logic [13:0] conv_count_q;

  // ---------------------------------------------------------------------------
  // PD index — combinational from latched ns/nf
  // ---------------------------------------------------------------------------
  logic [PD_W-1:0] pd_idx;
  assign pd_idx = pd_from_phases(ns_q, nf_q);

  // ---------------------------------------------------------------------------
  // Raw Vernier time reconstruction (combinational).
  // Keeps the original Vernier topology and applies the package-level
  // geometry-origin corrections for STOP-side nslow and per-hit nfast.
  // ---------------------------------------------------------------------------
  logic signed [31:0] t_raw_ps;

  always_comb begin
    t_raw_ps = vernier_tconv_ps(nslow_q, nfast_q, ns_q, nf_q,
                                slow_boundary_inc_q);
  end

  // ---------------------------------------------------------------------------
  // Output word formation
  // ---------------------------------------------------------------------------

  // Header: [15]=1, [14:13]=ctx_id, [12]=phase0, [11:8]=hit_count,
  //         [7:4]=flags, [3:2]=out_mode, [1:0]=rsvd
  logic [NARROW_W-1:0] header_word;
  // Header: [15:14]=2'b10 (header), [13:12]=ctx_id, [11]=phase0,
  // [10:7]=hit_count, [6:3]=flags, [2:1]=out_mode, [0]=slow_boundary_inc
  // ctx_id_q is CTX_W bits (1 for N_CTX=2) — always pad to 2 bits
  assign header_word = {2'b10,
                        2'(ctx_id_q),
                        phase0_snap_q,
                        hit_count_q,
                        flags_q,
                        out_mode_q,
                        slow_boundary_inc_q};

  // Hit W0: [15]=0, [14:8]=nslow[6:0], [7:1]=nfast[6:0], [0]=0
  // Bit 15 always 0 to distinguish from header/EOC markers
  logic [NARROW_W-1:0] hit_w0;
  assign hit_w0 = {1'b0, nslow_q[6:0], nfast_q[6:0], 1'b0};

  // Hit W1 — features variant: [15]=0, [14:11]=ns, [10:7]=nf, [6:0]=pd_idx
  logic [NARROW_W-1:0] hit_w1_feat;
  assign hit_w1_feat = {1'b0, ns_q, nf_q, pd_idx};

  // Hit W1 — timestamp variant: [15:0]=t_raw_ps[15:0]
  logic [NARROW_W-1:0] hit_w1_ts;
  assign hit_w1_ts = t_raw_ps[15:0];

  // Hit W2: [15]=0, [14:11]=event_seq, [10:4]=nfast_snap, [3:0]=0
  logic [NARROW_W-1:0] hit_w2;
  assign hit_w2 = {1'b0, event_seq_q, nfast_snap_q, 4'b0};

  // Hit W3 (FULL only): [15:0]=t_raw_ps[15:0]
  logic [NARROW_W-1:0] hit_w3;
  assign hit_w3 = t_raw_ps[15:0];

  // EOC: [15:14]=11, [13:0]=conv_count
  logic [NARROW_W-1:0] eoc_word;
  assign eoc_word = {2'b11, conv_count_q};

  // ---------------------------------------------------------------------------
  // Handshake helpers
  // ---------------------------------------------------------------------------
  wire out_accepted  = narrow_valid_o & narrow_ready_i;
  wire last_hit_done = ((hit_idx_q + MAX_HITS_W'(1)) == hit_count_q);

  // ---------------------------------------------------------------------------
  // Sequential FSM + datapath
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q       <= S_IDLE;
      conv_count_q  <= 14'd0;
      hit_idx_q     <= '0;
      ctx_id_q      <= '0;
      phase0_snap_q <= 1'b0;
      slow_boundary_inc_q <= 1'b0;  // v2.2
      hit_count_q   <= '0;
      flags_q       <= '0;
      out_mode_q    <= OUT_MODE_RAW_FEATURES;
      nslow_q       <= '0;
      nfast_snap_q  <= '0;
      ns_q          <= '0;
      nf_q          <= '0;
      nfast_q       <= '0;
      event_seq_q   <= '0;
    end else begin
      case (state_q)
        // -----------------------------------------------------------------
        S_IDLE: begin
          if (fifo_rd_valid_i && fifo_rd_data_i.kind == ACQ_REC_META) begin
            ctx_id_q      <= fifo_rd_data_i.meta.ctx_id;
            phase0_snap_q <= fifo_rd_data_i.meta.phase0_snap;
            slow_boundary_inc_q <= fifo_rd_data_i.meta.slow_boundary_inc; // v2.2
            hit_count_q   <= fifo_rd_data_i.meta.hit_count;
            flags_q       <= fifo_rd_data_i.meta.flags;
            nslow_q       <= fifo_rd_data_i.meta.nslow;
            nfast_snap_q  <= fifo_rd_data_i.meta.nfast;  // v2.2.2
            out_mode_q    <= out_mode_i;
            hit_idx_q     <= '0;
            state_q       <= S_HEADER;
          end
        end

        // -----------------------------------------------------------------
        S_HEADER: begin
          if (out_accepted) begin
            state_q <= (hit_count_q == '0) ? S_EOC : S_HIT_FETCH;
          end
        end

        // -----------------------------------------------------------------
        S_HIT_FETCH: begin
          if (fifo_rd_valid_i) begin
            ns_q        <= fifo_rd_data_i.hit.ns;
            nf_q        <= fifo_rd_data_i.hit.nf;
            nfast_q     <= fifo_rd_data_i.hit.nfast;
            event_seq_q <= fifo_rd_data_i.hit.event_seq;
            state_q     <= S_HIT_W0;
          end
        end

        // -----------------------------------------------------------------
        S_HIT_W0: begin
          if (out_accepted)
            state_q <= S_HIT_W1;
        end

        // -----------------------------------------------------------------
        S_HIT_W1: begin
          if (out_accepted) begin
            if (out_mode_q == OUT_MODE_RAW_TIMESTAMP) begin
              hit_idx_q <= hit_idx_q + MAX_HITS_W'(1);
              state_q   <= last_hit_done ? S_EOC : S_HIT_FETCH;
            end else begin
              state_q <= S_HIT_W2;
            end
          end
        end

        // -----------------------------------------------------------------
        S_HIT_W2: begin
          if (out_accepted) begin
            if (out_mode_q == OUT_MODE_FULL) begin
              state_q <= S_HIT_W3;
            end else begin
              hit_idx_q <= hit_idx_q + MAX_HITS_W'(1);
              state_q   <= last_hit_done ? S_EOC : S_HIT_FETCH;
            end
          end
        end

        // -----------------------------------------------------------------
        S_HIT_W3: begin
          if (out_accepted) begin
            hit_idx_q <= hit_idx_q + MAX_HITS_W'(1);
            state_q   <= last_hit_done ? S_EOC : S_HIT_FETCH;
          end
        end

        // -----------------------------------------------------------------
        S_EOC: begin
          if (out_accepted) begin
            conv_count_q <= conv_count_q + 14'd1;
            state_q      <= S_IDLE;
          end
        end

        default: state_q <= S_IDLE;
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Combinational output mux + FIFO read enable
  // ---------------------------------------------------------------------------
  always_comb begin
    narrow_valid_o = 1'b0;
    narrow_data_o  = {NARROW_W{1'b0}};
    fifo_rd_en_o   = 1'b0;

    case (state_q)
      S_IDLE: begin
        // Pop META when available
        fifo_rd_en_o = fifo_rd_valid_i
                     & (fifo_rd_data_i.kind == ACQ_REC_META);
      end

      S_HEADER: begin
        narrow_valid_o = 1'b1;
        narrow_data_o  = header_word;
      end

      S_HIT_FETCH: begin
        // Pop HIT when available
        fifo_rd_en_o = fifo_rd_valid_i;
      end

      S_HIT_W0: begin
        narrow_valid_o = 1'b1;
        narrow_data_o  = hit_w0;
      end

      S_HIT_W1: begin
        narrow_valid_o = 1'b1;
        narrow_data_o  = (out_mode_q == OUT_MODE_RAW_TIMESTAMP)
                       ? hit_w1_ts : hit_w1_feat;
      end

      S_HIT_W2: begin
        narrow_valid_o = 1'b1;
        narrow_data_o  = hit_w2;
      end

      S_HIT_W3: begin
        narrow_valid_o = 1'b1;
        narrow_data_o  = hit_w3;
      end

      S_EOC: begin
        narrow_valid_o = 1'b1;
        narrow_data_o  = eoc_word;
      end

      default: ;
    endcase
  end

endmodule

`default_nettype wire
