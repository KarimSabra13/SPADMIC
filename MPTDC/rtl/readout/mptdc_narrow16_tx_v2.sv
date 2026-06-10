`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC - Fixed-Packet Vernier TDC
// File     : mptdc_narrow16_tx_v2.sv
// Purpose  : 16-bit ready/valid serializer — reads from sync FIFO and emits
//            the fixed calibrated-feature packet.
// Author   : Karim Sabra
// =============================================================================
// Reads META + HIT acquisition records from the sync FIFO
// and serialises them onto a 16-bit ready/valid bus.
//
// Packet format (per conversion):
//   1 × Header    — context id, hit count, flags, reserved bits
//   N × Hit words — two words per hit
//   1 × EOC       — end-of-conversion marker with 14-bit running counter
//
// Output mode selection is not part of the packet. Header[2] carries
// slow_boundary_inc so offline reconstruction keeps the rare coarse-boundary
// correction. Hit W1[2:0] carries stop_slow_phase_disc for the calibrated LUT
// key.
// =============================================================================
module mptdc_narrow16_tx_v2
  import mptdc_pkg::*;
(
  input  wire                   clk_sys,
  input  wire                   rst_n,          // synchronous clk_sys reset, active-low

  // Legacy configuration is ignored; the output format is hardwired.
  input  mptdc_pkg::out_mode_e  out_mode_i,

  // Sync-FIFO read port (FWFT: data valid while fifo_rd_valid_i is high)
  input  wire                   fifo_rd_valid_i,
  input  mptdc_pkg::mptdc_acq_rec_t fifo_rd_data_i,
  output logic                  fifo_rd_en_o,

  // 16-bit narrow output (ready / valid)
  input  wire                   narrow_ready_i,
  output logic                  narrow_valid_o,
  output logic [NARROW_W-1:0]  narrow_data_o
);

  // ---------------------------------------------------------------------------
  // FSM encoding
  // ---------------------------------------------------------------------------
  typedef enum logic [3:0] {
    S_IDLE      = 4'd0,
    S_HEADER    = 4'd1,
    S_HIT_FETCH = 4'd2,
    S_HIT_W0    = 4'd4,
    S_HIT_W1    = 4'd5,
    S_EOC       = 4'd7
  } tx_state_e;

  tx_state_e state_q;

  // ---------------------------------------------------------------------------
  // Latched conversion context (from META record)
  // ---------------------------------------------------------------------------
  ctx_id_t                ctx_id_q;
  logic                   phase0_snap_q;
  stop_phase_disc_t       stop_slow_phase_disc_q;
  logic                   slow_boundary_inc_q;
  logic [MAX_HITS_W-1:0]  hit_count_q;
  tdc_conv_flags_t        flags_q;
  logic [NSLOW_W-1:0]     nslow_q;

  // ---------------------------------------------------------------------------
  // Latched hit data (from HIT record)
  // ---------------------------------------------------------------------------
  ph_idx_t                ns_q;
  ph_idx_t                nf_q;
  logic [NFAST_W-1:0]     nfast_q;

  // ---------------------------------------------------------------------------
  // Hit index (counts fully-emitted hits, 0-based)
  // ---------------------------------------------------------------------------
  logic [MAX_HITS_W-1:0]  hit_idx_q;

  // ---------------------------------------------------------------------------
  // 14-bit wrapping conversion counter (appears in EOC word)
  // ---------------------------------------------------------------------------
  logic [13:0] conv_count_q;

  // ---------------------------------------------------------------------------
  // Output word formation
  // ---------------------------------------------------------------------------

  logic [NARROW_W-1:0] header_word;
  // Header: [15:14]=2'b10 (header), [13:12]=ctx_id, [11]=phase0,
  // [10:7]=hit_count, [6:3]=flags, [2]=slow_boundary_inc, [1:0]=reserved
  // ctx_id_q is CTX_W bits (fixed one bit for N_CTX=2) and is padded into the
  // frozen two-bit packet field.
  assign header_word = {2'b10,
                        PACKET_CTX_W'(ctx_id_q),
                        phase0_snap_q,
                        hit_count_q,
                        flags_q,
                        slow_boundary_inc_q,
                        2'b00};

  // Hit W0: [15]=0, [14:8]=nslow[6:0], [7:1]=nfast[6:0], [0]=0
  // Bit 15 always 0 to distinguish from header/EOC markers
  logic [NARROW_W-1:0] hit_w0;
  assign hit_w0 = {1'b0, nslow_q[6:0], nfast_q[6:0], 1'b0};

  // Hit W1 — features variant:
  //   [15]=0, [14:11]=ns, [10:7]=nf, [6:3]=reserved,
  //   [2:0]=stop_slow_phase_disc.
  // The discriminator is STOP-edge metadata carried with the conversion record;
  // it repairs the packet-visible raw key without changing word count or timing
  // arithmetic.
  // The packet keeps 4-bit phase fields for protocol compatibility; the active
  // 8-tap RTL drives only values 0..7.
  logic [NARROW_W-1:0] hit_w1_feat;
  assign hit_w1_feat = {1'b0, 4'(ns_q), 4'(nf_q), 4'b0, stop_slow_phase_disc_q};

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
  always_ff @(posedge clk_sys) begin
    if (!rst_n) begin
      state_q       <= S_IDLE;
      conv_count_q  <= 14'd0;
      hit_idx_q     <= '0;
      ctx_id_q      <= '0;
      phase0_snap_q <= 1'b0;
      stop_slow_phase_disc_q <= '0;
      slow_boundary_inc_q <= 1'b0;
      hit_count_q   <= '0;
      flags_q       <= '0;
      nslow_q       <= '0;
      ns_q          <= '0;
      nf_q          <= '0;
      nfast_q       <= '0;
    end else begin
      case (state_q)
        // -----------------------------------------------------------------
        S_IDLE: begin
          if (fifo_rd_valid_i && fifo_rd_data_i.kind == ACQ_REC_META) begin
            ctx_id_q      <= fifo_rd_data_i.meta.ctx_id;
            phase0_snap_q <= fifo_rd_data_i.meta.phase0_snap;
            stop_slow_phase_disc_q <= fifo_rd_data_i.meta.stop_slow_phase_disc;
            slow_boundary_inc_q <= fifo_rd_data_i.meta.slow_boundary_inc;
            hit_count_q   <= fifo_rd_data_i.meta.hit_count;
            flags_q       <= fifo_rd_data_i.meta.flags;
            nslow_q       <= fifo_rd_data_i.meta.nslow;
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
        // Pop META when available.  The FIFO full/read-pointer path reported by
        // Innovus should be fixed with a registered FIFO output or read command
        // boundary; keep the protocol guard here so the serializer never consumes
        // a malformed HIT as a conversion header.
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
        narrow_data_o  = hit_w1_feat;
      end

      S_EOC: begin
        narrow_valid_o = 1'b1;
        narrow_data_o  = eoc_word;
      end

      default: ;
    endcase
  end

  // synthesis translate_off
  logic                  narrow_hold_valid_q;
  logic [NARROW_W-1:0]  narrow_data_hold_q;

  always_ff @(posedge clk_sys) begin
    if (!rst_n) begin
      narrow_hold_valid_q <= 1'b0;
      narrow_data_hold_q  <= '0;
    end else begin
      if (fifo_rd_en_o) assert (fifo_rd_valid_i);

      if (narrow_valid_o && !narrow_ready_i) begin
        if (narrow_hold_valid_q) begin
          assert (narrow_valid_o);
          assert (narrow_data_o == narrow_data_hold_q);
        end
        narrow_hold_valid_q <= 1'b1;
        narrow_data_hold_q  <= narrow_data_o;
      end else begin
        narrow_hold_valid_q <= 1'b0;
      end
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
