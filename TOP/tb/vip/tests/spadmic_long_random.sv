// =============================================================================
// SPADMIC VIP — Long Random Test
// Single-seed constrained-random session: ~200 conversions, mixed traffic.
// =============================================================================

class spadmic_long_random extends spadmic_base_test;

  function new();
    super.new("long_random");
  endfunction

  function void configure();
    cfg.drv_mode       = DRV_MODE_I2C;
    cfg.profile        = PROFILE_STRESS;
    cfg.num_phases     = 50;
    cfg.timeout_ns     = 10_000_000;
  endfunction

  task body();
    env.gen.gen_initial_config();
    env.gen.gen_random_sequence(cfg.num_phases);
  endtask
endclass
