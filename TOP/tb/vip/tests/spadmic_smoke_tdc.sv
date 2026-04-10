// =============================================================================
// SPADMIC VIP — Smoke TDC Test
// Sanity: enable all axes + CAL, inject 1 event per axis, collect 3 packets.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_smoke_tdc extends spadmic_base_test;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  function new();
    super.new("smoke_tdc");
  endfunction

  function void configure();
    cfg.drv_mode          = DRV_MODE_DIRECT_CSR;
    cfg.profile           = PROFILE_TDC_CHAR;
    cfg.default_input_sel = INPUT_CAL;
    cfg.default_out_mode  = OUT_MODE_RAW_FEATURES;
    cfg.default_max_hits  = 4'd15;
    cfg.num_conversions   = 1;
    cfg.timeout_ns        = 200_000;
  endfunction

  task body();
    env.gen.gen_initial_config();
    // One conversion per axis
    env.gen.gen_tdc_conversions(0, 1, 10000);  // X
    env.gen.gen_tdc_conversions(1, 1, 10000);  // Y
    env.gen.gen_tdc_conversions(2, 1, 10000);  // Z
    env.gen.gen_eot();
  endtask
endclass

`default_nettype wire
