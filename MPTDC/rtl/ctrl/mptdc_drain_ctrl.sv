`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.2 — Design Review Enhanced Vernier TDC
// File     : mptdc_drain_ctrl.sv
// Purpose  : System-clock drain/readout controller — reads static context bank
//            data, generates acquisition records, and manages context release.
//            Replaces both ctrl_fsm_v2 and writer_scan from v2.0.
// Author   : Karim Sabra
// =============================================================================
// State machine (sys_clk domain):
//   ST_D_IDLE — monitor ctx_drain_sync for ready contexts
//   ST_D_META — push META record (nslow, hit_count, flags, phase0, ctx_id)
//   ST_D_SCAN — iterate PD cells, push HIT record per active cell
//   ST_D_EOC  — assert ctx_release + conv_done, return to IDLE
//
// The context bank is read via combinational read port.  Data is guaranteed
// stable because ctx_drain_sync only goes high ~12 ns after the context bank
// was written (2-FF CDC latency).  No data synchronisers needed.
//
// A "released" mask prevents re-selecting a just-released context before the
// async latch clear propagates back through the 2-FF sync chain.
// =============================================================================
module mptdc_drain_ctrl
  import mptdc_pkg::*;
(
  input  wire                     clk_sys,
  input  wire                     rst_n,

  // Context drain status (2-FF synced from async domain)
  input  wire [N_CTX-1:0]         ctx_drain_sync_i,

  // Context bank read port
  output mptdc_pkg::ctx_id_t                 read_ctx_o,
  input  mptdc_pkg::mptdc_ctx_snapshot_t     snapshot_i,

  // Sync FIFO write port
  output logic                    fifo_wr_en_o,
  output mptdc_pkg::mptdc_acq_rec_t          fifo_wr_data_o,
  input  wire                     fifo_wr_full_i,

  // Context release (directly to frontend async latches)
  output logic [N_CTX-1:0]        ctx_release_o,

  // Conversion done pulse (for watchdog reset + status counters)
  output logic                    conv_done_o,

  // Debug / status
  output mptdc_pkg::drain_state_e            state_o
);

  // =========================================================================
  // State register
  // =========================================================================
  drain_state_e state_q, state_d;

  // Context being drained
  ctx_id_t drain_ctx_q;

  // =========================================================================
  // Released-context mask
  // =========================================================================
  // After releasing context g, the async latch clears but the 2-FF sync in
  // sys_clk still shows ctx_drain = 1 for ~2 cycles.  The mask prevents
  // re-selecting this context until the sync bit actually goes low.
  logic [N_CTX-1:0] released_mask;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      released_mask <= '0;
    end else begin
      for (int i = 0; i < N_CTX; i++) begin
        if (state_q == ST_D_EOC && drain_ctx_q == ctx_id_t'(i))
          released_mask[i] <= 1'b1;
        else if (!ctx_drain_sync_i[i])
          released_mask[i] <= 1'b0;
      end
    end
  end

  // =========================================================================
  // Context selection (priority — lowest index first)
  // =========================================================================
  logic [N_CTX-1:0] ctx_selectable;
  logic             any_selectable;
  ctx_id_t          selected_ctx;

  assign ctx_selectable = ctx_drain_sync_i & ~released_mask;

  always_comb begin
    any_selectable = |ctx_selectable;
    selected_ctx = '0;
    for (int i = N_CTX - 1; i >= 0; i--)
      if (ctx_selectable[i]) selected_ctx = ctx_id_t'(i);
  end

  // =========================================================================
  // Scan counters
  // =========================================================================
  localparam int unsigned PD_SCAN_W = PD_W + 1;  // must represent sentinel PD_N=64

  logic [PD_SCAN_W-1:0]     pd_scan_q;
  ph_idx_t                  ns_cnt_q, nf_cnt_q;
  logic [EVENT_SEQ_W-1:0]   event_seq_q;
  pd_idx_t                  pd_scan_idx;

  // Scan helpers
  logic scan_done, all_hits_found, cell_has_hit;
  assign pd_scan_idx    = pd_idx_t'(pd_scan_q[PD_W-1:0]);
  assign scan_done      = (pd_scan_q >= PD_SCAN_W'(PD_N));
  assign all_hits_found = (event_seq_q >= snapshot_i.hit_count);
  assign cell_has_hit   = ~scan_done & snapshot_i.hit_level[pd_scan_idx];

  // Next scan position
  logic [PD_SCAN_W-1:0] pd_scan_nxt;
  ph_idx_t              ns_cnt_nxt, nf_cnt_nxt;

  always_comb begin
    pd_scan_nxt = pd_scan_q + PD_SCAN_W'(1);
    if (nf_cnt_q == ph_idx_t'(NE - 1)) begin
      nf_cnt_nxt = '0;
      ns_cnt_nxt = ns_cnt_q + ph_idx_t'(1);
    end else begin
      nf_cnt_nxt = nf_cnt_q + ph_idx_t'(1);
      ns_cnt_nxt = ns_cnt_q;
    end
  end

  // =========================================================================
  // Record construction
  // =========================================================================
  mptdc_acq_rec_t meta_rec, hit_rec;

  always_comb begin
    meta_rec                    = '0;
    meta_rec.kind               = ACQ_REC_META;
    meta_rec.meta.nslow         = snapshot_i.nslow_snap;
    meta_rec.meta.nfast         = snapshot_i.nfast_snap;
    meta_rec.meta.nfast_stop    = snapshot_i.nfast_stop;    // v2.3
    meta_rec.meta.hit_count     = snapshot_i.hit_count;
    meta_rec.meta.flags         = snapshot_i.flags;
    meta_rec.meta.phase0_snap   = snapshot_i.phase0_snap;
    meta_rec.meta.slow_boundary_inc = snapshot_i.slow_boundary_inc; // v2.2
    meta_rec.meta.ctx_id        = drain_ctx_q;
  end

  always_comb begin
    hit_rec                     = '0;
    hit_rec.kind                = ACQ_REC_HIT;
    hit_rec.hit.ns              = ns_cnt_q;
    hit_rec.hit.nf              = nf_cnt_q;
    hit_rec.hit.nfast           = snapshot_i.nfast_hit_packed[pd_scan_idx*NFAST_W +: NFAST_W];
    hit_rec.hit.event_seq       = event_seq_q;
  end

  // =========================================================================
  // FSM — combinational next-state + output decode
  // =========================================================================
  logic advance_scan;

  always_comb begin
    state_d        = state_q;
    fifo_wr_en_o   = 1'b0;
    fifo_wr_data_o = '0;
    conv_done_o    = 1'b0;
    ctx_release_o  = '0;
    advance_scan   = 1'b0;

    case (state_q)
      // ─────────────────────────────────────────────────────────────
      ST_D_IDLE: begin
        if (any_selectable)
          state_d = ST_D_META;
      end

      // ─────────────────────────────────────────────────────────────
      ST_D_META: begin
        if (!fifo_wr_full_i) begin
          fifo_wr_en_o   = 1'b1;
          fifo_wr_data_o = meta_rec;
          state_d        = ST_D_SCAN;
        end
      end

      // ─────────────────────────────────────────────────────────────
      ST_D_SCAN: begin
        if (scan_done || all_hits_found) begin
          state_d = ST_D_EOC;
        end else if (cell_has_hit) begin
          if (!fifo_wr_full_i) begin
            fifo_wr_en_o   = 1'b1;
            fifo_wr_data_o = hit_rec;
            advance_scan   = 1'b1;
          end
          // FIFO full: stall — hold scan position
        end else begin
          advance_scan = 1'b1;   // skip empty cell
        end
      end

      // ─────────────────────────────────────────────────────────────
      ST_D_EOC: begin
        ctx_release_o[drain_ctx_q] = 1'b1;
        conv_done_o = 1'b1;
        state_d     = ST_D_IDLE;
      end

      default: state_d = ST_D_IDLE;
    endcase
  end

  // =========================================================================
  // Sequential — state + scan counters
  // =========================================================================
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q     <= ST_D_IDLE;
      drain_ctx_q <= '0;
      pd_scan_q   <= '0;
      ns_cnt_q    <= '0;
      nf_cnt_q    <= '0;
      event_seq_q <= '0;
    end else begin
      state_q <= state_d;

      case (state_q)
        ST_D_IDLE: begin
          if (any_selectable) begin
            drain_ctx_q <= selected_ctx;
            pd_scan_q   <= '0;
            ns_cnt_q    <= '0;
            nf_cnt_q    <= '0;
            event_seq_q <= '0;
          end
        end

        ST_D_SCAN: begin
          if (advance_scan) begin
            pd_scan_q <= pd_scan_nxt;
            ns_cnt_q  <= ns_cnt_nxt;
            nf_cnt_q  <= nf_cnt_nxt;
            if (cell_has_hit)
              event_seq_q <= event_seq_q + EVENT_SEQ_W'(1);
          end
        end

        default: ;
      endcase
    end
  end

  // =========================================================================
  // Context bank read port — pre-point mux during IDLE
  // =========================================================================
  assign read_ctx_o = (state_q == ST_D_IDLE) ? selected_ctx : drain_ctx_q;
  assign state_o    = state_q;

endmodule

`default_nettype wire
