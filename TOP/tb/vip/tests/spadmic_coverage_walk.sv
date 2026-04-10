// =============================================================================
// SPADMIC VIP — Coverage Walk Test
// Systematic hole-filler: walks through specific cross-coverage bins.
// =============================================================================

class spadmic_coverage_walk extends spadmic_base_test;

  function new();
    super.new("coverage_walk");
  endfunction

  function void configure();
    cfg.drv_mode   = DRV_MODE_DIRECT_CSR;
    cfg.profile    = PROFILE_TDC_CHAR;
    cfg.timeout_ns = 5_000_000;
  endfunction

  task body();
    out_mode_e modes[3] = '{OUT_MODE_RAW_FEATURES, OUT_MODE_RAW_TIMESTAMP, OUT_MODE_FULL};
    int hits[4] = '{1, 5, 10, 15};

    env.gen.gen_initial_config();

    // Walk: all modes × all max_hits × all axes × both BP modes
    for (int m = 0; m < 3; m++) begin
      for (int h = 0; h < 4; h++) begin
        for (int ax = 0; ax < 3; ax++) begin
          begin
            spadmic_ctrl_txn ct = new();
            ct.global_enable  = 1'b1;
            ct.axis_enable    = 3'b111;
            ct.shared_tx_sel  = SPADMIC_TX_TDC;
            ct.tdc_input_sel  = INPUT_CAL;
            ct.tdc_out_mode   = modes[m];
            ct.max_hits       = hits[h][3:0];
            ct.drv_mode       = cfg.drv_mode;
            env.gen.drv_mb.put(ct);
          end
          env.gen.gen_tdc_conversions(ax, 1, 10000);
        end
      end
    end

    // Also cover SPAD input config (for config coverage — no events
    // injected since SPAD matrix doesn't exist in behavioural sim)
    begin
      spadmic_ctrl_txn ct = new();
      ct.global_enable  = 1'b1;
      ct.axis_enable    = 3'b111;
      ct.shared_tx_sel  = SPADMIC_TX_TDC;
      ct.tdc_input_sel  = INPUT_SPAD;
      ct.tdc_out_mode   = OUT_MODE_RAW_FEATURES;
      ct.max_hits       = 4'd15;
      ct.drv_mode       = cfg.drv_mode;
      env.gen.drv_mb.put(ct);
    end
    // Switch back to CAL before injecting — SPAD events can't be
    // generated in simulation so there's nothing to collect.
    begin
      spadmic_ctrl_txn ct = new();
      ct.global_enable  = 1'b1;
      ct.axis_enable    = 3'b111;
      ct.shared_tx_sel  = SPADMIC_TX_TDC;
      ct.tdc_input_sel  = INPUT_CAL;
      ct.tdc_out_mode   = OUT_MODE_RAW_FEATURES;
      ct.max_hits       = 4'd15;
      ct.drv_mode       = cfg.drv_mode;
      env.gen.drv_mb.put(ct);
    end

    // Position coverage
    env.gen.gen_mode_switch(SPADMIC_TX_POSITION);
    begin
      logic [SPADMIC_LINE_W-1:0] pat;
      pat = '0;
      for (int i = 0; i < 50; i++) pat[i] = 1'b1;
      env.gen.gen_position_event(pat, pat, pat, 200);
    end

    env.gen.gen_eot();
  endtask
endclass

