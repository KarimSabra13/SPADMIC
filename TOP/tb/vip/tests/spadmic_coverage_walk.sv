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
    int hits[4] = '{1, 5, 10, 15};

    env.gen.gen_initial_config();

    for (int h = 0; h < 4; h++) begin
      spadmic_ctrl_txn ct = new();
      ct.global_enable  = 1'b1;
      ct.axis_enable    = 3'b111;
      ct.shared_tx_sel  = SPADMIC_TX_TDC;
      ct.tdc_input_sel  = INPUT_SPAD;
      ct.tdc_out_mode   = OUT_MODE_RAW_FEATURES;
      ct.max_hits       = hits[h][3:0];
      ct.drv_mode       = cfg.drv_mode;
      env.gen.drv_mb.put(ct);
      env.gen.gen_tdc_conversions(0, 1, 10000);
    end

    // Calibration alone permits a nonzero partial mask; no conversion is
    // started because normal matrix operation owns conversion triggering.
    env.gen.gen_calibration_mode_visit(3'b011);

    // Position coverage
    env.gen.gen_mode_switch(SPADMIC_TX_POSITION);
    begin
      logic [SPADMIC_LINE_W-1:0] pat;
      pat = '0;
      for (int i = 0; i < 50; i++) pat[i] = 1'b1;
      env.gen.gen_position_event(pat, pat, pat, 200);
      env.gen.gen_export_mode_switch(SPADMIC_EXPORT_BOTH_ACTIVE);
      env.gen.gen_position_event(pat, pat, pat, 200);
    end

    env.gen.gen_eot();
  endtask
endclass
