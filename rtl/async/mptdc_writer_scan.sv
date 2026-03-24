`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Module : mptdc_writer_scan
// Project: SPAD_MPTDC v2.0 — Raw-Output Vernier TDC
// Purpose: Simplified PD scan-order writer.  Scans PD cells 0..PD_N-1 in
//          fixed index order and emits hits as found — no sorting required.
//          First emits one META record, then one HIT record per active cell.
// Author : Karim Sabra
// =============================================================================
module mptdc_writer_scan
  import mptdc_pkg::*;
(
  input  wire                   clk_fast,
  input  wire                   rst_async_n,

  // -- Drain request from context manager ------------------------------------
  input  wire                   drain_start_i,
  input  ctx_id_t               drain_ctx_i,
  input  mptdc_ctx_snapshot_t   snapshot_i,

  // -- Async FIFO write port -------------------------------------------------
  input  wire                   fifo_full_i,
  output logic                  fifo_wr_en_o,
  output mptdc_acq_rec_t        fifo_wr_data_o,

  // -- Completion / status ---------------------------------------------------
  output logic                  writer_done_o,
  output logic                  ctx_release_o,
  output logic                  scan_active_o
);

  // =========================================================================
  // Local FSM encoding
  // =========================================================================
  typedef enum logic [1:0] {
    S_IDLE = 2'd0,
    S_META = 2'd1,
    S_SCAN = 2'd2,
    S_DONE = 2'd3
  } scan_st_e;

  scan_st_e                 state_r, state_nxt;

  // =========================================================================
  // Latched snapshot and context (no reset — always written before read)
  // =========================================================================
  mptdc_ctx_snapshot_t      snap_r;
  ctx_id_t                  ctx_r;

  // =========================================================================
  // Scan counters
  // =========================================================================
  logic [PD_W-1:0]          pd_scan_r;      // flat cell index 0..PD_N
  ph_idx_t                  ns_cnt_r;       // slow-phase = pd_scan / NE
  ph_idx_t                  nf_cnt_r;       // fast-phase = pd_scan % NE
  logic [EVENT_SEQ_W-1:0]   event_seq_r;    // running hit ordinal

  // =========================================================================
  // Combinational helpers
  // =========================================================================
  logic                     scan_done;
  logic                     all_hits_found;
  logic                     cell_has_hit;
  logic                     can_write;
  logic                     advance_scan;

  assign scan_done      = (pd_scan_r >= PD_W'(PD_N));
  assign all_hits_found = (event_seq_r >= snap_r.hit_count);
  assign cell_has_hit   = ~scan_done & snap_r.hit_level[pd_scan_r];
  assign can_write      = ~fifo_full_i;

  // Next scan position — nf wraps at NE-1, ns increments on wrap
  logic [PD_W-1:0]          pd_scan_nxt;
  ph_idx_t                  ns_cnt_nxt;
  ph_idx_t                  nf_cnt_nxt;

  always_comb begin
    pd_scan_nxt = pd_scan_r + PD_W'(1);
    if (nf_cnt_r == ph_idx_t'(NE - 1)) begin
      nf_cnt_nxt = '0;
      ns_cnt_nxt = ns_cnt_r + ph_idx_t'(1);
    end else begin
      nf_cnt_nxt = nf_cnt_r + ph_idx_t'(1);
      ns_cnt_nxt = ns_cnt_r;
    end
  end

  // =========================================================================
  // Record construction
  // =========================================================================
  mptdc_acq_rec_t           meta_rec;
  mptdc_acq_rec_t           hit_rec;

  always_comb begin
    meta_rec                    = '0;
    meta_rec.kind               = ACQ_REC_META;
    meta_rec.meta.nslow         = snap_r.nslow_snap;
    meta_rec.meta.hit_count     = snap_r.hit_count;
    meta_rec.meta.flags         = snap_r.flags;
    meta_rec.meta.phase0_snap   = snap_r.phase0_snap;
    meta_rec.meta.ctx_id        = ctx_r;
  end

  always_comb begin
    hit_rec                     = '0;
    hit_rec.kind                = ACQ_REC_HIT;
    hit_rec.hit.ns              = ns_cnt_r;
    hit_rec.hit.nf              = nf_cnt_r;
    hit_rec.hit.nfast           = snap_r.nfast_hit_packed[pd_scan_r*NFAST_W +: NFAST_W];
    hit_rec.hit.event_seq       = event_seq_r;
  end

  // =========================================================================
  // FSM — next state and outputs (combinational)
  // =========================================================================
  always_comb begin
    state_nxt      = state_r;
    fifo_wr_en_o   = 1'b0;
    fifo_wr_data_o = '0;
    writer_done_o  = 1'b0;
    ctx_release_o  = 1'b0;
    advance_scan   = 1'b0;

    case (state_r)
      // -----------------------------------------------------------------
      S_IDLE: begin
        if (drain_start_i)
          state_nxt = S_META;
      end

      // -----------------------------------------------------------------
      S_META: begin
        if (can_write) begin
          fifo_wr_en_o   = 1'b1;
          fifo_wr_data_o = meta_rec;
          state_nxt      = S_SCAN;
        end
        // FIFO full: stall in S_META
      end

      // -----------------------------------------------------------------
      S_SCAN: begin
        if (scan_done || all_hits_found) begin
          state_nxt = S_DONE;
        end else if (cell_has_hit) begin
          if (can_write) begin
            fifo_wr_en_o   = 1'b1;
            fifo_wr_data_o = hit_rec;
            advance_scan   = 1'b1;
          end
          // FIFO full: hold wr_en low, stall scan counter
        end else begin
          // No hit at this cell — skip
          advance_scan = 1'b1;
        end
      end

      // -----------------------------------------------------------------
      S_DONE: begin
        writer_done_o = 1'b1;
        ctx_release_o = 1'b1;
        state_nxt     = S_IDLE;
      end

      default: state_nxt = S_IDLE;
    endcase
  end

  // =========================================================================
  // scan_active_o — high whenever the writer is not idle
  // =========================================================================
  assign scan_active_o = (state_r != S_IDLE);

  // =========================================================================
  // Sequential — control registers (async-assert / sync-deassert reset)
  // =========================================================================
  always_ff @(posedge clk_fast or negedge rst_async_n) begin
    if (!rst_async_n) begin
      state_r     <= S_IDLE;
      pd_scan_r   <= '0;
      ns_cnt_r    <= '0;
      nf_cnt_r    <= '0;
      event_seq_r <= '0;
    end else begin
      state_r <= state_nxt;

      case (state_r)
        S_META: begin
          if (can_write) begin
            pd_scan_r   <= '0;
            ns_cnt_r    <= '0;
            nf_cnt_r    <= '0;
            event_seq_r <= '0;
          end
        end

        S_SCAN: begin
          if (advance_scan) begin
            pd_scan_r <= pd_scan_nxt;
            ns_cnt_r  <= ns_cnt_nxt;
            nf_cnt_r  <= nf_cnt_nxt;
            if (cell_has_hit)
              event_seq_r <= event_seq_r + EVENT_SEQ_W'(1);
          end
        end

        default: ;
      endcase
    end
  end

  // =========================================================================
  // Sequential — data registers (no reset; latched on drain_start_i)
  // =========================================================================
  always_ff @(posedge clk_fast) begin
    if (state_r == S_IDLE && drain_start_i) begin
      snap_r <= snapshot_i;
      ctx_r  <= drain_ctx_i;
    end
  end

  // =========================================================================
  // Assertions (simulation only)
  // =========================================================================
  // synthesis translate_off
  property p_no_start_while_active;
    @(posedge clk_fast) disable iff (!rst_async_n)
      (state_r != S_IDLE) |-> !drain_start_i;
  endproperty
  a_no_start_while_active : assert property (p_no_start_while_active)
    else $error("[mptdc_writer_scan] drain_start_i while writer active");

  property p_done_one_cycle;
    @(posedge clk_fast) disable iff (!rst_async_n)
      writer_done_o |=> !writer_done_o;
  endproperty
  a_done_one_cycle : assert property (p_done_one_cycle)
    else $error("[mptdc_writer_scan] writer_done_o not single-cycle pulse");
  // synthesis translate_on

endmodule

`default_nettype wire
