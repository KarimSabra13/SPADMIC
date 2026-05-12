// =============================================================================
// SPADMIC VIP — Transaction Generator / Sequencer
// Builds transaction sequences based on mission profile and constraints.
// =============================================================================

class spadmic_random_scenario;

  rand spadmic_random_phase_e phase_kind;
  rand int unsigned           axis;
  rand logic [2:0]            axis_mask;
  rand int unsigned           num_conversions;
  rand int unsigned           start_stop_delay_ps;
  rand int unsigned           hold_time_ns;
  rand int unsigned           axis_skew_ps;
  rand int unsigned           position_offset_ps;
  rand int unsigned           post_family_idle_ps;
  rand int unsigned           x_base;
  rand int unsigned           y_base;
  rand int unsigned           z_base;
  rand int unsigned           x_span;
  rand int unsigned           y_span;
  rand int unsigned           z_span;
  rand spadmic_bp_mode_e      bp_mode;
  rand int unsigned           bp_duration_cycles;
  rand spadmic_export_mode_e  export_mode;

  bit                         legal_only;

  constraint c_axis {
    axis inside {[0:2]};
    axis_mask inside {[3'b001:3'b111]};
  }

  constraint c_tdc {
    num_conversions inside {[1:20]};
    start_stop_delay_ps inside {[2_000:30_000]};
  }

  constraint c_position {
    x_span inside {[5:24]};
    y_span inside {[5:24]};
    z_span inside {[5:24]};
    x_base inside {[0:SPADMIC_LINE_W-1]};
    y_base inside {[0:SPADMIC_LINE_W-1]};
    z_base inside {[0:SPADMIC_LINE_W-1]};
    x_base + x_span <= SPADMIC_LINE_W;
    y_base + y_span <= SPADMIC_LINE_W;
    z_base + z_span <= SPADMIC_LINE_W;
    hold_time_ns inside {[80:600]};
  }

  constraint c_correlated {
    axis_skew_ps inside {[0:4_000]};
    position_offset_ps inside {[0:12_000]};
    post_family_idle_ps inside {[400_000:1_200_000]};
  }

  constraint c_backpressure {
    bp_duration_cycles inside {[100:2_000]};
    if (legal_only) {
      bp_mode inside {BP_ALWAYS_READY, BP_RANDOM_50};
    } else {
      bp_mode inside {BP_ALWAYS_READY, BP_RANDOM_50, BP_ALWAYS_STALL};
    }
  }

  constraint c_export_mode {
    export_mode inside {SPADMIC_EXPORT_TDC_ONLY,
                        SPADMIC_EXPORT_POSITION_ONLY,
                        SPADMIC_EXPORT_BOTH_ACTIVE};
  }

  function new(bit legal_only = 1'b1);
    this.legal_only = legal_only;
  endfunction

endclass

class spadmic_generator;

  mailbox #(spadmic_base_txn) drv_mb;
  spadmic_env_cfg             cfg;
  int unsigned                txn_count;

  function new(mailbox #(spadmic_base_txn) mb, spadmic_env_cfg cfg);
    this.drv_mb    = mb;
    this.cfg       = cfg;
    this.txn_count = 0;
  endfunction

  function automatic int unsigned random_total_weight();
    return cfg.random_weight_tdc
         + cfg.random_weight_position
         + cfg.random_weight_mode_switch
         + cfg.random_weight_bp
         + cfg.random_weight_correlated;
  endfunction

  function automatic spadmic_random_phase_e choose_random_phase();
    int unsigned total;
    int unsigned choice;
    int unsigned accum;

    total = random_total_weight();
    if (total == 0)
      return RANDOM_PHASE_CORRELATED;

    choice = $urandom_range(0, total - 1);
    accum = cfg.random_weight_tdc;
    if (choice < accum)
      return RANDOM_PHASE_TDC;

    accum += cfg.random_weight_position;
    if (choice < accum)
      return RANDOM_PHASE_POSITION;

    accum += cfg.random_weight_mode_switch;
    if (choice < accum)
      return RANDOM_PHASE_MODE_SWITCH;

    accum += cfg.random_weight_bp;
    if (choice < accum)
      return RANDOM_PHASE_BP;

    return RANDOM_PHASE_CORRELATED;
  endfunction

  function automatic logic [SPADMIC_LINE_W-1:0] make_cluster_pattern(
    int unsigned base_idx,
    int unsigned span
  );
    logic [SPADMIC_LINE_W-1:0] pat;
    pat = '0;
    for (int i = 0; i < span; i++)
      pat[base_idx + i] = 1'b1;
    return pat;
  endfunction

  // ── Directed: initial chip configuration ──────────────────────
  task automatic gen_initial_config();
    spadmic_ctrl_txn t = new();
    t.is_read         = 1'b0;
    t.global_enable   = 1'b1;
    t.axis_enable     = 3'b111;
    t.position_enable = (cfg.profile == PROFILE_POSITION || cfg.profile == PROFILE_STRESS) ? 1'b1 : 1'b0;
    t.shared_tx_sel   = (cfg.profile == PROFILE_POSITION) ? SPADMIC_TX_POSITION : SPADMIC_TX_TDC;
    t.tdc_input_sel   = cfg.default_input_sel;
    t.tdc_out_mode    = cfg.default_out_mode;
    t.max_hits        = cfg.default_max_hits;
    t.drv_mode        = cfg.drv_mode;
    drv_mb.put(t);
    txn_count++;
  endtask

  // ── Directed: TDC conversions ─────────────────────────────────
  task automatic gen_tdc_conversions(
    int unsigned axis,
    int unsigned count,
    int unsigned delay_ps,
    int unsigned gap_ps = 0   // 0 = use txn default (400 ns)
  );
    spadmic_tdc_event_txn t = new();
    t.axis                 = axis;
    t.num_conversions      = count;
    t.start_stop_delay_ps  = delay_ps;
    if (gap_ps != 0) t.inter_conv_gap_ps = gap_ps;
    t.use_spad             = (cfg.default_input_sel == INPUT_SPAD);
    drv_mb.put(t);
    txn_count++;
  endtask

  // ── Directed: Position event ──────────────────────────────────
  task automatic gen_position_event(
    logic [SPADMIC_LINE_W-1:0] x, y, z,
    int unsigned hold_ns
  );
    spadmic_pos_event_txn t = new();
    t.x_pattern    = x;
    t.y_pattern    = y;
    t.z_pattern    = z;
    t.hold_time_ns = hold_ns;
    drv_mb.put(t);
    txn_count++;
  endtask

  task automatic gen_csr_write(
    logic [SPADMIC_CSR_ADDR_W-1:0]  addr,
    logic [SPADMIC_CSR_DATA_W-1:0]  data
  );
    spadmic_ctrl_txn t = new();
    t.raw_csr_write = 1'b1;
    t.addr          = addr;
    t.wdata         = data;
    t.drv_mode      = cfg.drv_mode;
    drv_mb.put(t);
    txn_count++;
  endtask

  task automatic gen_correlated_event(
    logic [2:0]               axis_mask,
    int unsigned              delay_ps,
    logic [SPADMIC_LINE_W-1:0] x,
    logic [SPADMIC_LINE_W-1:0] y,
    logic [SPADMIC_LINE_W-1:0] z,
    int unsigned              hold_ns,
    bit                       use_spad = 1'b0,
    int unsigned              axis_skew_ps = 1500,
    int unsigned              pos_offset_ps = 3000
  );
    spadmic_correlated_event_txn t = new();
    t.axis_mask           = axis_mask;
    t.start_stop_delay_ps = delay_ps;
    t.axis_skew_ps        = axis_skew_ps;
    t.position_offset_ps  = pos_offset_ps;
    t.position_present    = (x != '0) || (y != '0) || (z != '0);
    t.x_pattern           = x;
    t.y_pattern           = y;
    t.z_pattern           = z;
    t.hold_time_ns        = hold_ns;
    t.use_spad            = use_spad;
    drv_mb.put(t);
    txn_count++;
  endtask

  // ── Directed: Mode switch (drain + reconfig) ──────────────────
  task automatic gen_mode_switch(spadmic_tx_sel_e new_sel);
    gen_export_mode_switch((new_sel == SPADMIC_TX_POSITION)
                           ? SPADMIC_EXPORT_POSITION_ONLY
                           : SPADMIC_EXPORT_TDC_ONLY);
  endtask

  task automatic gen_export_mode_switch(spadmic_export_mode_e new_mode);
    spadmic_ctrl_txn t0, t1;
    // Disable global enable → drain → switch → re-enable
    t0 = new();
    t0.global_enable = 1'b0;
    t0.axis_enable   = 3'b111;
    t0.tdc_input_sel = cfg.default_input_sel;
    t0.tdc_out_mode  = cfg.default_out_mode;
    t0.max_hits      = cfg.default_max_hits;
    t0.drv_mode      = cfg.drv_mode;
    drv_mb.put(t0);

    t1 = new();
    t1.global_enable = 1'b1;
    t1.axis_enable   = 3'b111;
    t1.tdc_input_sel = cfg.default_input_sel;
    t1.tdc_out_mode  = cfg.default_out_mode;
    t1.max_hits      = cfg.default_max_hits;
    case (new_mode)
      SPADMIC_EXPORT_POSITION_ONLY: begin
        t1.shared_tx_sel   = SPADMIC_TX_POSITION;
        t1.position_enable = 1'b1;
      end
      SPADMIC_EXPORT_BOTH_ACTIVE: begin
        t1.shared_tx_sel   = SPADMIC_TX_TDC;
        t1.position_enable = 1'b1;
      end
      default: begin
        t1.shared_tx_sel   = SPADMIC_TX_TDC;
        t1.position_enable = 1'b0;
      end
    endcase
    t1.drv_mode = cfg.drv_mode;
    drv_mb.put(t1);
    txn_count += 2;
  endtask

  // ── Directed: Backpressure change ─────────────────────────────
  task automatic gen_bp_change(spadmic_bp_mode_e mode, int unsigned dur);
    spadmic_bp_txn t = new();
    t.mode            = mode;
    t.duration_cycles = dur;
    drv_mb.put(t);
    txn_count++;
  endtask

  // ── Directed: Reset during traffic ────────────────────────────
  task automatic gen_reset(int unsigned dur_ns, logic during_traffic);
    spadmic_reset_txn t = new();
    t.reset_duration_ns = dur_ns;
    t.during_traffic    = during_traffic;
    drv_mb.put(t);
    txn_count++;
  endtask

  // ── End of test ───────────────────────────────────────────────
  task automatic gen_eot(int unsigned drain_timeout_ns = 50000);
    spadmic_eot_txn t = new();
    t.drain_timeout_ns = drain_timeout_ns;
    drv_mb.put(t);
    txn_count++;
  endtask

  // ── Constrained-random: profile-based sequence ────────────────
  task automatic gen_random_sequence(
    int unsigned num_phases,
    int unsigned eot_drain_timeout_ns = 50000
  );
    spadmic_bp_mode_e last_bp_mode = BP_ALWAYS_READY;
    spadmic_export_mode_e planned_export_mode;
    spadmic_random_scenario sc;

    planned_export_mode = (cfg.profile == PROFILE_POSITION)
                          ? SPADMIC_EXPORT_POSITION_ONLY
                          : ((cfg.profile == PROFILE_STRESS)
                             ? SPADMIC_EXPORT_BOTH_ACTIVE
                             : SPADMIC_EXPORT_TDC_ONLY);
    sc = new(cfg.random_legal_only);

    for (int p = 0; p < num_phases; p++) begin
      spadmic_random_phase_e phase;
      phase = choose_random_phase();
      sc.legal_only = cfg.random_legal_only;
      if (!sc.randomize() with { phase_kind == phase; }) begin
        $fatal(1, "[GEN] Failed to randomize legal scenario for phase %0d", phase);
      end

      case (sc.phase_kind)
        RANDOM_PHASE_TDC: begin
          if (planned_export_mode == SPADMIC_EXPORT_POSITION_ONLY) begin
            gen_export_mode_switch(SPADMIC_EXPORT_TDC_ONLY);
            planned_export_mode = SPADMIC_EXPORT_TDC_ONLY;
          end
          gen_tdc_conversions(sc.axis, sc.num_conversions, sc.start_stop_delay_ps);
        end

        RANDOM_PHASE_POSITION: begin
          logic [SPADMIC_LINE_W-1:0] xp, yp, zp;
          if (planned_export_mode == SPADMIC_EXPORT_TDC_ONLY) begin
            gen_export_mode_switch(SPADMIC_EXPORT_POSITION_ONLY);
            planned_export_mode = SPADMIC_EXPORT_POSITION_ONLY;
          end
          xp = make_cluster_pattern(sc.x_base, sc.x_span);
          yp = make_cluster_pattern(sc.y_base, sc.y_span);
          zp = make_cluster_pattern(sc.z_base, sc.z_span);
          gen_position_event(xp, yp, zp, sc.hold_time_ns);
        end

        RANDOM_PHASE_MODE_SWITCH: begin
          // Release any ALWAYS_STALL first — the sequencer needs to
          // drain the old path before committing a source change, and
          // drain can't complete while the output is permanently stalled.
          if (last_bp_mode == BP_ALWAYS_STALL) begin
            gen_bp_change(BP_ALWAYS_READY, 200);
            last_bp_mode = BP_ALWAYS_READY;
          end
          gen_export_mode_switch(sc.export_mode);
          planned_export_mode = sc.export_mode;
        end

        RANDOM_PHASE_BP: begin
          gen_bp_change(sc.bp_mode, sc.bp_duration_cycles);
          last_bp_mode = sc.bp_mode;
        end

        default: begin
          logic [SPADMIC_LINE_W-1:0] xp, yp, zp;
          if (planned_export_mode != SPADMIC_EXPORT_BOTH_ACTIVE) begin
            gen_export_mode_switch(SPADMIC_EXPORT_BOTH_ACTIVE);
            planned_export_mode = SPADMIC_EXPORT_BOTH_ACTIVE;
          end
          xp = make_cluster_pattern(sc.x_base, sc.x_span);
          yp = make_cluster_pattern(sc.y_base, sc.y_span);
          zp = make_cluster_pattern(sc.z_base, sc.z_span);

          gen_correlated_event(
            sc.axis_mask,
            sc.start_stop_delay_ps,
            xp, yp, zp,
            sc.hold_time_ns,
            (cfg.default_input_sel == INPUT_SPAD),
            sc.axis_skew_ps,
            sc.position_offset_ps
          );
        end
      endcase
    end
    // Release stall before EOT so pipeline can drain
    if (last_bp_mode == BP_ALWAYS_STALL)
      gen_bp_change(BP_ALWAYS_READY, 200);

    gen_eot(eot_drain_timeout_ns);
  endtask

endclass
