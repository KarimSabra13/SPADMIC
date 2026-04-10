// =============================================================================
// SPADMIC VIP — Smoke Switching Test
// Sanity: TDC session → drain → switch to position → back to TDC.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_smoke_switching extends spadmic_base_test;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  function new();
    super.new("smoke_switching");
  endfunction

  function void configure();
    cfg.drv_mode  = DRV_MODE_DIRECT_CSR;
    cfg.profile   = PROFILE_MODE_SWITCH;
    cfg.timeout_ns = 500_000;
  endfunction

  task body();
    logic [spadmic_pkg::SPADMIC_LINE_W-1:0] pattern;

    // Phase 1: TDC mode
    env.gen.gen_initial_config();
    env.gen.gen_tdc_conversions(0, 3, 10000);

    // Phase 2: Switch to position
    env.gen.gen_mode_switch(SPADMIC_TX_POSITION);
    pattern = '0;
    for (int i = 10; i <= 25; i++) pattern[i] = 1'b1;
    env.gen.gen_position_event(pattern, pattern, pattern, 300);

    // Phase 3: Switch back to TDC
    env.gen.gen_mode_switch(SPADMIC_TX_TDC);
    env.gen.gen_tdc_conversions(1, 2, 15000);

    env.gen.gen_eot();
  endtask
endclass

`default_nettype wire
