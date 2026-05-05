// =============================================================================
// SPADMIC VIP — Stress Random Test
// Massive multi-seed random: 5000+ conversions per seed, all profiles.
// =============================================================================

class spadmic_stress_random extends spadmic_base_test;

  function new();
    super.new("stress_random");
  endfunction

  function void configure();
    cfg.drv_mode       = DRV_MODE_I2C;
    cfg.profile        = PROFILE_STRESS;
    cfg.num_phases     = 200;
    cfg.timeout_ns     = 50_000_000;
    cfg.enable_reset_test = 1'b1;
  endfunction

  task body();
    env.gen.gen_initial_config();

    // Mix of all phase types. Multi-seed I2C stress can finish with several
    // long TDC packets still draining, so use a longer EOT drain than smoke tests.
    env.gen.gen_random_sequence(cfg.num_phases, 1_000_000);
  endtask
endclass
