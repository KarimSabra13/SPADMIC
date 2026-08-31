// =============================================================================
// SPADMIC VIP — Smoke Position Test
// Sanity: enable position, inject known line pattern, collect 1 packet.
// =============================================================================

class spadmic_smoke_position extends spadmic_base_test;

  function new();
    super.new("smoke_position");
  endfunction

  function void configure();
    cfg.drv_mode          = DRV_MODE_DIRECT_CSR;
    cfg.profile           = PROFILE_POSITION;
    cfg.default_gap_threshold    = 7'd10;
    cfg.default_min_cluster_span = 7'd5;
    cfg.default_settle_cycles    = 4'd4;
    cfg.timeout_ns        = 200_000;
  endfunction

  task body();
    logic [spadmic_pkg::SPADMIC_LINE_W-1:0] pattern;

    // Config for position mode
    env.gen.gen_initial_config();

    // One physical matrix event presents all public R/Y/B directions.
    pattern = '0;
    for (int i = 20; i <= 35; i++) pattern[i] = 1'b1;
    env.gen.gen_position_event(pattern, pattern, pattern, 300);

    env.gen.gen_eot();
  endtask
endclass
