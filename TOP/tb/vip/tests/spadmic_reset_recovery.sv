// =============================================================================
// SPADMIC VIP — Reset Recovery Test
// Asserts async_rst_n during active TDC traffic, checks clean recovery.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_reset_recovery extends spadmic_base_test;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  function new();
    super.new("reset_recovery");
  endfunction

  function void configure();
    cfg.drv_mode          = DRV_MODE_DIRECT_CSR;
    cfg.profile           = PROFILE_STRESS;
    cfg.enable_reset_test = 1'b1;
    cfg.timeout_ns        = 1_000_000;
  endfunction

  task body();
    // Phase 1: Start traffic
    env.gen.gen_initial_config();
    env.gen.gen_tdc_conversions(0, 5, 10000);

    // Phase 2: Reset during traffic
    env.gen.gen_reset(100, 1'b1);

    // Phase 3: Reconfigure and verify recovery
    env.gen.gen_initial_config();
    env.gen.gen_tdc_conversions(0, 3, 10000);
    env.gen.gen_tdc_conversions(1, 3, 10000);

    env.gen.gen_eot();
  endtask
endclass

`default_nettype wire
