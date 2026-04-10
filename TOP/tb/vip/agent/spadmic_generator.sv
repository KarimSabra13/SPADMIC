// =============================================================================
// SPADMIC VIP — Transaction Generator / Sequencer
// Builds transaction sequences based on mission profile and constraints.
// =============================================================================

class spadmic_generator;

  mailbox #(spadmic_base_txn) drv_mb;
  spadmic_env_cfg             cfg;
  int unsigned                txn_count;

  function new(mailbox #(spadmic_base_txn) mb, spadmic_env_cfg cfg);
    this.drv_mb    = mb;
    this.cfg       = cfg;
    this.txn_count = 0;
  endfunction

  // ── Directed: initial chip configuration ──────────────────────
  task automatic gen_initial_config();
    spadmic_ctrl_txn t = new();
    t.is_read         = 1'b0;
    t.global_enable   = 1'b1;
    t.axis_enable     = 3'b111;
    t.position_enable = (cfg.profile == PROFILE_POSITION) ? 1'b1 : 1'b0;
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

  // ── Directed: Mode switch (drain + reconfig) ──────────────────
  task automatic gen_mode_switch(spadmic_tx_sel_e new_sel);
    spadmic_ctrl_txn t0, t1;
    // Disable global enable → drain → switch → re-enable
    t0 = new();
    t0.global_enable  = 1'b0;
    t0.drv_mode       = cfg.drv_mode;
    drv_mb.put(t0);

    t1 = new();
    t1.global_enable   = 1'b1;
    t1.shared_tx_sel   = new_sel;
    t1.position_enable = (new_sel == SPADMIC_TX_POSITION) ? 1'b1 : 1'b0;
    t1.drv_mode        = cfg.drv_mode;
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
  task automatic gen_eot();
    spadmic_eot_txn t = new();
    drv_mb.put(t);
    txn_count++;
  endtask

  // ── Constrained-random: profile-based sequence ────────────────
  task automatic gen_random_sequence(int unsigned num_phases);
    spadmic_bp_mode_e last_bp_mode = BP_ALWAYS_READY;

    for (int p = 0; p < num_phases; p++) begin
      int unsigned phase_kind;
      phase_kind = $urandom_range(0, 3);
      case (phase_kind)
        0: begin  // TDC conversions
          int unsigned ax = $urandom_range(0, 2);
          int unsigned cnt = $urandom_range(1, 20);
          int unsigned delay = $urandom_range(2000, 28000);
          gen_tdc_conversions(ax, cnt, delay);
        end
        1: begin  // Position event
          logic [SPADMIC_LINE_W-1:0] xp, yp, zp;
          xp = $urandom(); yp = $urandom(); zp = $urandom();
          gen_position_event(xp, yp, zp, $urandom_range(50, 500));
        end
        2: begin  // Mode switch
          // Release any ALWAYS_STALL first — the sequencer needs to
          // drain the old path before committing a source change, and
          // drain can't complete while the output is permanently stalled.
          if (last_bp_mode == BP_ALWAYS_STALL) begin
            gen_bp_change(BP_ALWAYS_READY, 200);
            last_bp_mode = BP_ALWAYS_READY;
          end
          begin
            spadmic_tx_sel_e sel;
            sel = ($urandom_range(0,1) == 0) ? SPADMIC_TX_TDC : SPADMIC_TX_POSITION;
            gen_mode_switch(sel);
          end
        end
        3: begin  // BP change
          spadmic_bp_mode_e bp;
          bp = spadmic_bp_mode_e'($urandom_range(0, 2));
          gen_bp_change(bp, $urandom_range(100, 2000));
          last_bp_mode = bp;
        end
      endcase
    end
    // Release stall before EOT so pipeline can drain
    if (last_bp_mode == BP_ALWAYS_STALL)
      gen_bp_change(BP_ALWAYS_READY, 200);

    gen_eot();
  endtask

endclass

