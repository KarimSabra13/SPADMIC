// =============================================================================
// SPADMIC VIP — SPAD Matrix Reset Modes Test
// Covers manual, periodic, and event-deferred reset pulse observation.
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
    logic [SPADMIC_LINE_W-1:0] xp;

    env.gen.gen_initial_config();

    // Manual pulse: POS_CTRL[4] is write-one-pulse, with local enable kept high.
    env.gen.gen_csr_write(SPADMIC_CSR_POS_CTRL, 32'h0000_0011);

    // Short period so the VIP can observe automatic reset behavior quickly.
    env.gen.gen_csr_write(SPADMIC_CSR_POS_RESET_CFG, 32'd4);

    // Periodic raw-characterization reset can fire while lines are active.
    env.gen.gen_csr_write(SPADMIC_CSR_POS_CTRL, 32'h0000_000B);
    xp = '0;
    xp[0] = 1'b1;
    xp[126] = 1'b1;
    env.gen.gen_position_event(xp, '0, '0, 150);

    // Event-deferred reset waits until the position block reaches safe idle.
    env.gen.gen_csr_write(SPADMIC_CSR_POS_CTRL, 32'h0000_0005);
    xp = '0;
    for (int i = 20; i < 28; i++)
      xp[i] = 1'b1;
    env.gen.gen_position_event(xp, '0, '0, 120);

    env.gen.gen_csr_write(SPADMIC_CSR_POS_CTRL, 32'h0000_0001);
    env.gen.gen_csr_write(SPADMIC_CSR_POS_RESET_CFG, 32'd0);
    env.gen.gen_eot();
  endtask

endclass

