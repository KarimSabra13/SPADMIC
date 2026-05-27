`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.5 — system-domain measurement controller
// File     : mptdc_meas_ctrl.sv
// Purpose  : Measurement teardown/context sequencing after the Vernier fabric
//            has latched STOP-side PD/counter state.
// =============================================================================
module mptdc_meas_ctrl
  import mptdc_pkg::*;
(
  input  wire                   clk_sys,
  input  wire                   rst_n,

  // Synchronized frontend status: START and STOP are both latched.
  input  wire                   meas_active_i,
  input  wire                   timeout_active_i,

  // Held static PD hit levels. The measurement fabric remains stable until
  // pd_clear_o, so row reductions can be sampled in parallel with SNAPSHOT.
  input  wire [PD_N-1:0]        hit_level_i,

  // Configuration from CSR, stable in clk_sys.
  input  wire [MAX_HITS_W-1:0]  max_hits_cfg_i,
  input  wire [15:0]            wdt_timeout_i,   // retained for status compatibility

  // Static-bus capture / context-bank commit controls.
  output logic                  snapshot_en_o,   // pulse: sample PD/counter fabric into bridge
  output logic                  capture_en_o,    // pulse: commit raw bridge image / reserve context
  output logic                  meta_en_o,       // pulse: update hit-count/flag metadata

  // Frontend / PD control.
  output logic                  fe_clear_o,      // pulse: clear START/STOP latches
  output logic                  pd_clear_o,      // pulse: clear PD/counter fabric
  output logic                  pd_gate_o,       // 0 freezes additional PD hit accumulation

  // Fast oscillator keep-alive after STOP latch is cleared.
  output logic                  osc_keep_alive_o,

  // Metadata committed with the context image.
  output tdc_conv_flags_t       close_flags_o,
  output logic [MAX_HITS_W-1:0] hit_count_o,

  // Debug / status.
  output meas_state_e           state_o
);

  meas_state_e state_q, state_d;

  localparam int unsigned ROW_PAIR_N = NE / 2;
  localparam int unsigned ROW_QUAD_N = NE / 4;
  localparam int unsigned PAIR_GROUP_N = NE / 2;

  // Balanced 64-bit hit count in the relaxed clk_sys domain.  Keep registered
  // boundaries between row reduction, final total, and context publication so
  // no clk_sys cycle contains the full 64-bit count plus flag/write logic.
  logic [1:0] row_pair_cnt_comb [0:NE-1][0:ROW_PAIR_N-1];
  logic [2:0] row_quad_cnt_comb [0:NE-1][0:ROW_QUAD_N-1];
  logic [3:0] row_cnt_comb      [0:NE-1];
  logic [3:0] row_cnt_q         [0:NE-1];
  logic [4:0] pair_cnt_comb     [0:PAIR_GROUP_N-1];
  logic [5:0] half_cnt_comb     [0:1];
  logic [6:0] total_cnt_comb;

  logic [6:0] total_hits_q;
  logic [MAX_HITS_W-1:0] hit_count_q;
  tdc_conv_flags_t flags_q;
  logic [MAX_HITS_W-1:0] eval_hit_count_comb;
  tdc_conv_flags_t eval_flags_comb;

  wire [MAX_HITS_W-1:0] effective_max_hits = max_hits_cfg_i;
  wire [6:0] effective_max_hits_ext = 7'(effective_max_hits);
  wire       any_hit_q = (total_hits_q != 7'd0);

  always_comb begin
    for (int r = 0; r < NE; r++) begin
      row_pair_cnt_comb[r][0] = {1'b0, hit_level_i[r * NE + 0]} + {1'b0, hit_level_i[r * NE + 1]};
      row_pair_cnt_comb[r][1] = {1'b0, hit_level_i[r * NE + 2]} + {1'b0, hit_level_i[r * NE + 3]};
      row_pair_cnt_comb[r][2] = {1'b0, hit_level_i[r * NE + 4]} + {1'b0, hit_level_i[r * NE + 5]};
      row_pair_cnt_comb[r][3] = {1'b0, hit_level_i[r * NE + 6]} + {1'b0, hit_level_i[r * NE + 7]};

      row_quad_cnt_comb[r][0] = {1'b0, row_pair_cnt_comb[r][0]} + {1'b0, row_pair_cnt_comb[r][1]};
      row_quad_cnt_comb[r][1] = {1'b0, row_pair_cnt_comb[r][2]} + {1'b0, row_pair_cnt_comb[r][3]};

      row_cnt_comb[r] = {1'b0, row_quad_cnt_comb[r][0]} + {1'b0, row_quad_cnt_comb[r][1]};
    end

    pair_cnt_comb[0] = {1'b0, row_cnt_q[0]} + {1'b0, row_cnt_q[1]};
    pair_cnt_comb[1] = {1'b0, row_cnt_q[2]} + {1'b0, row_cnt_q[3]};
    pair_cnt_comb[2] = {1'b0, row_cnt_q[4]} + {1'b0, row_cnt_q[5]};
    pair_cnt_comb[3] = {1'b0, row_cnt_q[6]} + {1'b0, row_cnt_q[7]};

    half_cnt_comb[0] = {1'b0, pair_cnt_comb[0]} + {1'b0, pair_cnt_comb[1]};
    half_cnt_comb[1] = {1'b0, pair_cnt_comb[2]} + {1'b0, pair_cnt_comb[3]};
    total_cnt_comb   = {1'b0, half_cnt_comb[0]} + {1'b0, half_cnt_comb[1]};
  end

  always_comb begin
    eval_hit_count_comb = hit_count_q;
    eval_flags_comb     = flags_q;

    if (effective_max_hits == '0) begin
      eval_hit_count_comb = '0;
    end else if (total_hits_q > effective_max_hits_ext) begin
      eval_hit_count_comb = effective_max_hits;
    end else begin
      eval_hit_count_comb = total_hits_q[MAX_HITS_W-1:0];
    end

    eval_flags_comb.reserved              = 1'b0;
    eval_flags_comb.closed_by_fast_maxhit = (effective_max_hits == MAX_HITS_W'(1)) && any_hit_q;
    eval_flags_comb.closed_by_maxhits     = (effective_max_hits > MAX_HITS_W'(1))
                                          && (total_hits_q >= effective_max_hits_ext);
    eval_flags_comb.closed_by_watchdog    = timeout_active_i
                                          || ((wdt_timeout_i != 16'd0) && !any_hit_q);
  end

  always_comb begin
    state_d = state_q;
    unique case (state_q)
      ST_M_IDLE: begin
        if (meas_active_i)
          state_d = ST_M_MEASURE;
      end
      ST_M_MEASURE:  state_d = ST_M_SNAPSHOT;
      ST_M_SNAPSHOT: state_d = ST_M_COUNT;
      ST_M_COUNT:    state_d = ST_M_EVAL;
      ST_M_EVAL:     state_d = ST_M_CAPTURE;
      ST_M_CAPTURE:  state_d = ST_M_CLEAR;
      ST_M_CLEAR:    state_d = ST_M_IDLE;
      default:       state_d = ST_M_IDLE;
    endcase
  end

  always_ff @(posedge clk_sys) begin
    if (!rst_n) begin
      state_q      <= ST_M_IDLE;
      total_hits_q <= '0;
      hit_count_q  <= '0;
      flags_q      <= '0;
      for (int r = 0; r < NE; r++)
        row_cnt_q[r] <= '0;
    end else begin
      state_q <= state_d;

      if (state_q == ST_M_IDLE) begin
        total_hits_q <= '0;
        hit_count_q  <= '0;
        flags_q      <= '0;
        for (int r = 0; r < NE; r++)
          row_cnt_q[r] <= '0;
      end else if (state_q == ST_M_SNAPSHOT) begin
        for (int r = 0; r < NE; r++)
          row_cnt_q[r] <= row_cnt_comb[r];
      end else if (state_q == ST_M_COUNT) begin
        total_hits_q <= total_cnt_comb;
      end else if (state_q == ST_M_EVAL) begin
        hit_count_q  <= eval_hit_count_comb;
        flags_q      <= eval_flags_comb;
      end
    end
  end

  assign snapshot_en_o    = (state_q == ST_M_SNAPSHOT);
  assign capture_en_o     = (state_q == ST_M_CAPTURE);
  assign meta_en_o        = 1'b0;
  assign fe_clear_o       = (state_q == ST_M_CAPTURE);
  assign pd_clear_o       = (state_q == ST_M_CLEAR);
  assign osc_keep_alive_o = (state_q == ST_M_MEASURE)
                           || (state_q == ST_M_SNAPSHOT);
  // Keep the PD fabric open while the sys-domain controller is still waiting
  // for the synchronized STOP indication. fe_pd_enable still gates real
  // measurement activity; this control only freezes additional accumulation
  // once the static-bus snapshot phase begins.
  assign pd_gate_o        = (state_q == ST_M_IDLE) || (state_q == ST_M_MEASURE);
  assign close_flags_o    = flags_q;
  assign hit_count_o      = hit_count_q;
  assign state_o          = state_q;

  // synthesis translate_off
  meas_state_e prev_state_q;
  always_ff @(posedge clk_sys) begin
    if (!rst_n) begin
      prev_state_q <= ST_M_IDLE;
    end else begin
      if (snapshot_en_o) assert (state_q == ST_M_SNAPSHOT);
      if (capture_en_o)  assert (state_q == ST_M_CAPTURE);
      assert (!meta_en_o)
        else $error("mptdc_meas_ctrl: meta_en_o is retired by fast-clear capture");
      if (pd_clear_o)    assert (state_q == ST_M_CLEAR);
      if (state_q == ST_M_CLEAR) assert (prev_state_q == ST_M_CAPTURE);
      prev_state_q <= state_q;
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
