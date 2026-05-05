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
    // I2C-driven stress sequences spend substantial simulated time in control
    // traffic and cfg_accept polling; keep this shorter than stress_random but
    // large enough that a healthy run reaches EOT instead of tripping the watchdog.
    cfg.timeout_ns     = 20_000_000;
  endfunction

  task body();
    env.gen.gen_initial_config();
    env.gen.gen_random_sequence(cfg.num_phases);
  endtask
endclass
