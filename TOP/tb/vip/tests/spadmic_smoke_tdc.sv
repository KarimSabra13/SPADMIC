// =============================================================================
// SPADMIC VIP — Smoke TDC Test
// Sanity: one coordinated R/Y/B event produces one packet per TDC source.
// =============================================================================

class spadmic_smoke_tdc extends spadmic_base_test;

  function new();
    super.new("smoke_tdc");
  endfunction

  function void configure();
    cfg.drv_mode          = DRV_MODE_DIRECT_CSR;
    cfg.profile           = PROFILE_TDC_CHAR;
    cfg.default_input_sel = INPUT_SPAD;
    cfg.default_out_mode  = OUT_MODE_RAW_FEATURES;
    cfg.default_max_hits  = 4'd15;
    cfg.num_conversions   = 1;
    cfg.timeout_ns        = 200_000;
  endfunction

  task body();
    env.gen.gen_initial_config();
    env.gen.gen_tdc_conversions(0, 1, 10000);
    env.gen.gen_eot();
  endtask
endclass
