// =============================================================================
// SPADMIC VIP — Backpressure Stress Test
// Walks BP modes: ALWAYS_READY → RANDOM_50 → ALWAYS_STALL → recovery.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_bp_stress extends spadmic_base_test;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  function new();
    super.new("bp_stress");
  endfunction

  function void configure();
    cfg.drv_mode   = DRV_MODE_DIRECT_CSR;
    cfg.profile    = PROFILE_STRESS;
    cfg.timeout_ns = 2_000_000;
  endfunction

  task body();
    env.gen.gen_initial_config();

    // Phase 1: Normal traffic with ready
    env.gen.gen_bp_change(BP_ALWAYS_READY, 1000);
    env.gen.gen_tdc_conversions(0, 5, 10000);

    // Phase 2: Random backpressure
    env.gen.gen_bp_change(BP_RANDOM_50, 2000);
    env.gen.gen_tdc_conversions(1, 10, 8000);

    // Phase 3: Full stall (data should buffer)
    env.gen.gen_bp_change(BP_ALWAYS_STALL, 500);
    env.gen.gen_tdc_conversions(2, 3, 12000);

    // Phase 4: Release — all buffered data should flush
    env.gen.gen_bp_change(BP_ALWAYS_READY, 5000);

    env.gen.gen_eot();
  endtask
endclass

`default_nettype wire
