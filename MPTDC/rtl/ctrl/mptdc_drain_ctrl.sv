`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC - Fixed-Packet Vernier TDC
// File     : mptdc_drain_ctrl.sv
// Purpose  : System-clock drain/readout controller — reads static context bank
//            data, generates acquisition records, and manages context release.
// Author   : Karim Sabra
// Domain   : clk_sys only.
// =============================================================================
// State machine (sys_clk domain):
//   ST_D_IDLE — monitor ctx_drain_sync for ready contexts
//   ST_D_META — push META record (nslow, hit_count, flags, phase0, ctx_id)
//   ST_D_SCAN — iterate PD cells, stage HIT record per active cell
//   ST_D_EMIT — transfer staged META/HIT record into the FIFO skid register
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
  input  wire                     rst_n,          // synchronous clk_sys reset, active-low

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

  always_ff @(posedge clk_sys) begin
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
  localparam int unsigned PD_SCAN_W = PD_W + 1;  // includes one sentinel value
  localparam logic [PD_SCAN_W-1:0] PD_SCAN_DONE = PD_SCAN_W'(PD_N);

  logic [PD_SCAN_W-1:0]     pd_scan_q;
  ph_idx_t                  ns_cnt_q, nf_cnt_q;
  logic [EVENT_SEQ_W-1:0]   event_seq_q;
  pd_idx_t                  pd_scan_idx;

  // Scan helpers
  logic scan_done, all_hits_found, cell_has_hit;
  assign pd_scan_idx    = pd_idx_t'(pd_scan_q[PD_W-1:0]);
  assign scan_done      = (pd_scan_q >= PD_SCAN_DONE);
  assign all_hits_found = (event_seq_q >= snapshot_i.hit_count);
  assign cell_has_hit   = !scan_done && snapshot_i.hit_level[pd_scan_idx];

`ifdef MPTDC_DRAIN_ROW_SKIP
  wire row_skip_candidate = !scan_done
                          && (nf_cnt_q == ph_idx_t'(0))
                          && !snapshot_i.row_nonzero[ns_cnt_q];
`else
  wire row_skip_candidate = 1'b0;
`endif

`ifdef MPTDC_DRAIN_SCAN_STRIDE2
  wire [PD_SCAN_W-1:0] pd_scan_plus1 = pd_scan_q + PD_SCAN_W'(1);
  wire                 cell1_valid = (pd_scan_plus1 < PD_SCAN_DONE)
                                   && (nf_cnt_q != ph_idx_t'(NE - 1));
  pd_idx_t             pd_scan_idx1;
  ph_idx_t             nf_cnt_plus1;
  logic                cell1_has_hit;
  logic                pair_has_hit;
  logic                pair_two_hits;
  logic                pair_second_hit_in_budget;

  assign pd_scan_idx1  = pd_idx_t'(pd_scan_plus1[PD_W-1:0]);
  assign nf_cnt_plus1  = nf_cnt_q + ph_idx_t'(1);
  assign cell1_has_hit = cell1_valid && snapshot_i.hit_level[pd_scan_idx1];
  assign pair_has_hit  = cell_has_hit || cell1_has_hit;
  assign pair_two_hits = cell_has_hit && cell1_has_hit;
  assign pair_second_hit_in_budget =
      (event_seq_q + EVENT_SEQ_W'(1)) < snapshot_i.hit_count;
`endif

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

`ifdef MPTDC_DRAIN_SCAN_STRIDE2
    pd_scan_nxt = pd_scan_q + PD_SCAN_W'(2);
    if (nf_cnt_q >= ph_idx_t'(NE - 2)) begin
      nf_cnt_nxt = '0;
      ns_cnt_nxt = ns_cnt_q + ph_idx_t'(1);
    end else begin
      nf_cnt_nxt = nf_cnt_q + ph_idx_t'(2);
      ns_cnt_nxt = ns_cnt_q;
    end
`endif

`ifdef MPTDC_DRAIN_ROW_SKIP
    if (row_skip_candidate) begin
      pd_scan_nxt = pd_scan_q + PD_SCAN_W'(NE);
      nf_cnt_nxt  = '0;
      ns_cnt_nxt  = ns_cnt_q + ph_idx_t'(1);
    end
`endif
  end

  // =========================================================================
  // Record construction
  // =========================================================================
  mptdc_acq_rec_t meta_rec, hit_rec;
`ifdef MPTDC_DRAIN_SCAN_STRIDE2
  mptdc_acq_rec_t stride_pending_rec_q, stride_pending_rec_d;
  logic           stride_pending_valid_q;
  pd_idx_t        hit_rec_idx;
  ph_idx_t        hit_rec_ns, hit_rec_nf;
  logic [EVENT_SEQ_W-1:0] hit_rec_seq;
`endif

  always_comb begin
    meta_rec                    = '0;
    meta_rec.kind               = ACQ_REC_META;
    meta_rec.meta.nslow         = snapshot_i.nslow_snap;
    meta_rec.meta.nfast         = snapshot_i.nfast_snap;
    meta_rec.meta.nfast_stop    = snapshot_i.nfast_stop;
    meta_rec.meta.hit_count     = snapshot_i.hit_count;
    meta_rec.meta.flags         = snapshot_i.flags;
    meta_rec.meta.phase0_snap   = snapshot_i.phase0_snap;
    meta_rec.meta.stop_slow_phase_disc = snapshot_i.stop_slow_phase_disc;
    meta_rec.meta.slow_boundary_inc = snapshot_i.slow_boundary_inc;
    meta_rec.meta.ctx_id        = drain_ctx_q;
  end

  always_comb begin
`ifdef MPTDC_DRAIN_SCAN_STRIDE2
    hit_rec_idx = pd_scan_idx;
    hit_rec_ns  = ns_cnt_q;
    hit_rec_nf  = nf_cnt_q;
    hit_rec_seq = event_seq_q;

    if (stride_pending_valid_q) begin
      hit_rec_idx = '0;
      hit_rec_ns  = stride_pending_rec_q.hit.ns;
      hit_rec_nf  = stride_pending_rec_q.hit.nf;
      hit_rec_seq = stride_pending_rec_q.hit.event_seq;
    end else if (!cell_has_hit && cell1_has_hit) begin
      hit_rec_idx = pd_scan_idx1;
      hit_rec_nf  = nf_cnt_plus1;
    end

    hit_rec                     = '0;
    hit_rec.kind                = ACQ_REC_HIT;
    hit_rec.hit.ns              = hit_rec_ns;
    hit_rec.hit.nf              = hit_rec_nf;
    hit_rec.hit.nfast           = stride_pending_valid_q
                                ? stride_pending_rec_q.hit.nfast
                                : snapshot_i.nfast_hit_packed[hit_rec_idx*NFAST_W +: NFAST_W];
    hit_rec.hit.event_seq       = hit_rec_seq;

    stride_pending_rec_d                    = '0;
    stride_pending_rec_d.kind               = ACQ_REC_HIT;
    stride_pending_rec_d.hit.ns             = ns_cnt_q;
    stride_pending_rec_d.hit.nf             = nf_cnt_plus1;
    stride_pending_rec_d.hit.nfast          = snapshot_i.nfast_hit_packed[pd_scan_idx1*NFAST_W +: NFAST_W];
    stride_pending_rec_d.hit.event_seq      = event_seq_q + EVENT_SEQ_W'(1);
`else
    hit_rec                     = '0;
    hit_rec.kind                = ACQ_REC_HIT;
    hit_rec.hit.ns              = ns_cnt_q;
    hit_rec.hit.nf              = nf_cnt_q;
    hit_rec.hit.nfast           = snapshot_i.nfast_hit_packed[pd_scan_idx*NFAST_W +: NFAST_W];
    hit_rec.hit.event_seq       = event_seq_q;
`endif
  end

  // =========================================================================
  // FSM — combinational next-state + output decode
  // =========================================================================
  logic advance_scan;
  logic stage_emit_wr;
  logic load_pending_wr;
`ifdef MPTDC_DRAIN_SCAN_STRIDE2
  logic load_stride_pending;
  logic clear_stride_pending;
  logic [1:0] scan_hit_advance;
`endif
  mptdc_acq_rec_t pending_wr_data_d;
  mptdc_acq_rec_t pending_wr_data_q;
  mptdc_acq_rec_t emit_wr_data_q;
  logic pending_wr_valid_q;
  wire  pending_wr_accept = pending_wr_valid_q & ~fifo_wr_full_i;
  wire  pending_wr_ready  = ~pending_wr_valid_q | pending_wr_accept;

  always_comb begin
    state_d        = state_q;
    conv_done_o    = 1'b0;
    ctx_release_o  = '0;
    advance_scan   = 1'b0;
    stage_emit_wr  = 1'b0;
    load_pending_wr = 1'b0;
`ifdef MPTDC_DRAIN_SCAN_STRIDE2
    load_stride_pending  = 1'b0;
    clear_stride_pending = 1'b0;
    scan_hit_advance     = 2'd0;
`endif
    pending_wr_data_d = '0;

    case (state_q)
      // ─────────────────────────────────────────────────────────────
      ST_D_IDLE: begin
        if (any_selectable)
          state_d = ST_D_META;
      end

      // ─────────────────────────────────────────────────────────────
      ST_D_META: begin
        stage_emit_wr = 1'b1;
        state_d       = ST_D_EMIT;
      end

      // ─────────────────────────────────────────────────────────────
      ST_D_SCAN: begin
`ifdef MPTDC_DRAIN_SCAN_STRIDE2
        if (stride_pending_valid_q) begin
          stage_emit_wr         = 1'b1;
          clear_stride_pending  = 1'b1;
          state_d               = ST_D_EMIT;
        end else if ((scan_done || all_hits_found) && pending_wr_ready) begin
          state_d = ST_D_EOC;
        end else if (row_skip_candidate && pending_wr_ready) begin
          advance_scan = 1'b1;
        end else if (pair_has_hit) begin
          stage_emit_wr     = 1'b1;
          advance_scan      = 1'b1;
          scan_hit_advance  = (pair_two_hits && pair_second_hit_in_budget)
                             ? 2'd2 : 2'd1;
          load_stride_pending = pair_two_hits && pair_second_hit_in_budget;
          state_d           = ST_D_EMIT;
        end else if (pending_wr_ready) begin
          advance_scan = 1'b1;   // skip empty cell pair or empty row
        end
`else
        if ((scan_done || all_hits_found) && pending_wr_ready) begin
          state_d = ST_D_EOC;
        end else if (row_skip_candidate && pending_wr_ready) begin
          advance_scan = 1'b1;   // skip empty row
        end else if (cell_has_hit) begin
          stage_emit_wr = 1'b1;
          advance_scan  = 1'b1;
          state_d       = ST_D_EMIT;
        end else if (pending_wr_ready) begin
          advance_scan = 1'b1;   // skip empty cell
        end
`endif
      end

      // ─────────────────────────────────────────────────────────────
      ST_D_EMIT: begin
        if (pending_wr_ready) begin
          load_pending_wr   = 1'b1;
          pending_wr_data_d = emit_wr_data_q;
          state_d          = ST_D_SCAN;
        end
        // FIFO full with a pending output record: stall with emit_wr_data_q held.
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

  assign fifo_wr_en_o   = pending_wr_accept;
  assign fifo_wr_data_o = pending_wr_data_q;

  // =========================================================================
  // Sequential — state + scan counters
  // =========================================================================
  always_ff @(posedge clk_sys) begin
    if (!rst_n) begin
      state_q     <= ST_D_IDLE;
      drain_ctx_q <= '0;
      pd_scan_q   <= '0;
      ns_cnt_q    <= '0;
      nf_cnt_q    <= '0;
      event_seq_q <= '0;
      pending_wr_valid_q <= 1'b0;
      pending_wr_data_q  <= '0;
      emit_wr_data_q     <= '0;
`ifdef MPTDC_DRAIN_SCAN_STRIDE2
      stride_pending_valid_q <= 1'b0;
      stride_pending_rec_q   <= '0;
`endif
    end else begin
      state_q <= state_d;

      if (stage_emit_wr) begin
        if (state_q == ST_D_META)
          emit_wr_data_q <= meta_rec;
        else
          emit_wr_data_q <= hit_rec;
      end

`ifdef MPTDC_DRAIN_SCAN_STRIDE2
      if (load_stride_pending) begin
        stride_pending_valid_q <= 1'b1;
        stride_pending_rec_q   <= stride_pending_rec_d;
      end else if (clear_stride_pending) begin
        stride_pending_valid_q <= 1'b0;
      end
`endif

      if (load_pending_wr) begin
        pending_wr_valid_q <= 1'b1;
        pending_wr_data_q  <= pending_wr_data_d;
      end else if (pending_wr_accept) begin
        pending_wr_valid_q <= 1'b0;
      end

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
`ifdef MPTDC_DRAIN_SCAN_STRIDE2
            event_seq_q <= event_seq_q + EVENT_SEQ_W'(scan_hit_advance);
`else
            if (cell_has_hit)
              event_seq_q <= event_seq_q + EVENT_SEQ_W'(1);
`endif
          end
        end

        default: ;
      endcase
    end
  end

  // =========================================================================
  // Context bank read port.
  //
  // The selected context is registered in drain_ctx_q on the IDLE->META edge.
  // META is emitted on the following cycle, so a combinational IDLE pre-point
  // mux is unnecessary. Keeping read_ctx_o registered prevents released_mask
  // and state decode from feeding the wide record-construction cone.
  // =========================================================================
  assign read_ctx_o = drain_ctx_q;
  assign state_o    = state_q;

  // synthesis translate_off
  logic          pending_hold_valid_q;
  mptdc_acq_rec_t pending_hold_data_q;

  always_ff @(posedge clk_sys) begin
    if (!rst_n) begin
      pending_hold_valid_q <= 1'b0;
      pending_hold_data_q  <= '0;
    end else begin
      if (state_q == ST_D_EOC) assert (!pending_wr_valid_q);

      if (pending_wr_valid_q && fifo_wr_full_i) begin
        if (pending_hold_valid_q) assert (pending_wr_data_q == pending_hold_data_q);
        pending_hold_valid_q <= 1'b1;
        pending_hold_data_q  <= pending_wr_data_q;
      end else begin
        pending_hold_valid_q <= 1'b0;
      end
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
