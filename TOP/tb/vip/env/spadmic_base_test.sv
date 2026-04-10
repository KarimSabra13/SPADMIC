// =============================================================================
// SPADMIC VIP — Base Test
// Provides standard test lifecycle: build → configure → run → report.
// =============================================================================

class spadmic_base_test;

  spadmic_env     env;
  spadmic_env_cfg cfg;
  string          test_name;

  function new(string name);
    this.test_name = name;
    cfg = new();
    cfg.parse_plusargs();
  endfunction

  // Override in derived tests to customize config
  virtual function void configure();
  endfunction

  // Override in derived tests to define the stimulus sequence
  virtual task body();
    // Default: initial config + TDC conversions + EOT
    env.gen.gen_initial_config();
    env.gen.gen_tdc_conversions(0, cfg.num_conversions, 10000);
    env.gen.gen_eot();
  endtask

  // Main entry point called by harness
  task automatic run_test(
    virtual spadmic_csr_req_if        csr_if,
    virtual spadmic_i2c_if            i2c_if,
    virtual spadmic_async_event_if    x_ev_if,
    virtual spadmic_async_event_if    y_ev_if,
    virtual spadmic_async_event_if    z_ev_if,
    virtual spadmic_position_line_if  pos_line_if,
    virtual spadmic_narrow_tx_if      tx_if
  );
    $display("══════════════════════════════════════════════════════");
    $display("  TEST: %s", test_name);
    $display("══════════════════════════════════════════════════════");

    // Configure
    configure();
    cfg.display();

    // Build environment
    env = new(cfg);
    env.build(csr_if, i2c_if, x_ev_if, y_ev_if, z_ev_if, pos_line_if, tx_if);

    // Generate stimulus
    body();

    // Run with timeout
    fork
      env.run();
      begin
        #(cfg.timeout_ns * 1000);
        $display("[TEST] TIMEOUT after %0d ns", cfg.timeout_ns);
      end
    join_any

    // Report
    env.report();

    // Pass/fail verdict — check both explicit failures AND expected vs received
    if (env.sb.check_fail == 0 &&
        env.sb.tdc_pkts_received >= env.sb.tdc_pkts_expected &&
        env.sb.pos_pkts_received >= env.sb.pos_pkts_expected)
      $display("═══ TEST %s: PASS ═══", test_name);
    else
      $display("═══ TEST %s: FAIL (fail=%0d, tdc=%0d/%0d, pos=%0d/%0d) ═══",
               test_name, env.sb.check_fail,
               env.sb.tdc_pkts_received, env.sb.tdc_pkts_expected,
               env.sb.pos_pkts_received, env.sb.pos_pkts_expected);
  endtask

endclass

