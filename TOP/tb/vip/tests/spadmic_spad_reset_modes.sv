// =============================================================================
// SPADMIC VIP — SPAD Matrix Reset Modes Test
// Covers automatic event reset pulses with two programmed widths.
// =============================================================================

class spadmic_spad_reset_modes extends spadmic_base_test;

  function new();
    super.new("spad_reset_modes");
  endfunction

  function void configure();
    cfg.drv_mode   = DRV_MODE_DIRECT_CSR;
    cfg.profile    = PROFILE_POSITION;
    cfg.timeout_ns = 500_000;
  endfunction

  task body();
    logic [SPADMIC_LINE_W-1:0] pattern;

    env.gen.gen_initial_config();
    pattern = '0;
    for (int i = 20; i < 28; i++)
      pattern[i] = 1'b1;

    // Initial high-level configuration programs the ABI default width of four.
    env.gen.gen_position_event(pattern, pattern, pattern, 120);

    // Width changes are only legal while disabled and globally idle.
    env.gen.gen_reset_width_update(16'd2);
    env.gen.gen_position_event(pattern, pattern, pattern, 120);
    env.gen.gen_eot();
  endtask

endclass
