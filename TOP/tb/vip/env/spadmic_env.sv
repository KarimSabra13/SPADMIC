// =============================================================================
// SPADMIC VIP — Environment Assembly
// Connects generator → driver → DUT → monitor → scoreboard pipeline.
// =============================================================================

class spadmic_env;

  // Configuration
  spadmic_env_cfg     cfg;

  // Mailboxes
  mailbox #(spadmic_base_txn) gen_to_drv_mb;
  mailbox #(spadmic_base_txn) drv_to_sb_mb;
  mailbox #(spadmic_base_txn) mon_to_sb_mb;
  mailbox #(int)              mon_to_cov_mb;

  // Components
  spadmic_generator    gen;
  spadmic_driver       drv;
  spadmic_csr_driver   csr_drv;
  spadmic_i2c_driver   i2c_drv;
  spadmic_event_driver ev_drv;
  spadmic_pos_driver   pos_drv;
  spadmic_bp_driver    bp_drv;
  spadmic_tx_monitor   tx_mon;
  spadmic_spad_reset_monitor spad_reset_mon;
  spadmic_csr_monitor  csr_mon;
  spadmic_ctrl_monitor ctrl_mon;
  spadmic_scoreboard   sb;

  // Coverage (conditionally instantiated)
`ifdef SPADMIC_ENABLE_FUNC_COV
  spadmic_stim_cov  stim_cov;
  spadmic_pkt_cov   pkt_cov;
  spadmic_ctrl_cov  ctrl_cov;
  spadmic_fault_cov fault_cov;
  spadmic_reset_cov reset_cov;
`endif

  function new(spadmic_env_cfg cfg);
    this.cfg = cfg;
  endfunction

  function void build(
    virtual spadmic_reset_if          reset_if,
    virtual spadmic_csr_req_if        csr_if,
    virtual spadmic_i2c_if            i2c_if,
    virtual spadmic_async_event_if    x_ev_if,
    virtual spadmic_async_event_if    y_ev_if,
    virtual spadmic_async_event_if    z_ev_if,
    virtual spadmic_position_line_if  pos_line_if,
    virtual spadmic_narrow_tx_if      tx_if,
    virtual spadmic_spad_reset_if     spad_reset_if
  );
    // Create mailboxes
    gen_to_drv_mb = new();
    drv_to_sb_mb  = new();
    mon_to_sb_mb  = new();
    mon_to_cov_mb = new();

    // Build sub-drivers
    csr_drv  = new(csr_if);
    i2c_drv  = new(i2c_if);
    ev_drv   = new(x_ev_if, y_ev_if, z_ev_if);
    pos_drv  = new(pos_line_if);
    bp_drv   = new(tx_if);

    // Build coverage
`ifdef SPADMIC_ENABLE_FUNC_COV
    stim_cov  = new();
    pkt_cov   = new();
    ctrl_cov  = new();
    fault_cov = new();
    reset_cov = new();
`endif

    // Build top-level driver
    drv = new(gen_to_drv_mb, drv_to_sb_mb, cfg, reset_if,
              csr_drv, i2c_drv, ev_drv, pos_drv, bp_drv
`ifdef SPADMIC_ENABLE_FUNC_COV
              , stim_cov, ctrl_cov, fault_cov
`endif
              );

    // Build generator
    gen = new(gen_to_drv_mb, cfg);

    // Build monitors
    tx_mon   = new(tx_if, mon_to_sb_mb, mon_to_cov_mb);
    spad_reset_mon = new(spad_reset_if, mon_to_sb_mb);
    csr_mon  = new(csr_if, mon_to_cov_mb);
    ctrl_mon = new(csr_if);

    // Build scoreboard
    sb = new(drv_to_sb_mb, mon_to_sb_mb, cfg
`ifdef SPADMIC_ENABLE_FUNC_COV
             , pkt_cov, reset_cov
`endif
             );

    $display("[ENV] Build complete — driver mode: %s", cfg.drv_mode.name());
  endfunction

  task automatic run();
    fork
      drv.run();
      tx_mon.run();
      spad_reset_mon.run();
      csr_mon.run();
      ctrl_mon.run();
      sb.run();
      bp_drv.run();
    join_none
    wait (sb.done);
    #1;
    disable fork;
  endtask

  function void report();
    $display("");
    $display("╔═══════════════════════════════════════════════════╗");
    $display("║          SPADMIC VIP — FINAL REPORT               ║");
    $display("╚═══════════════════════════════════════════════════╝");
    sb.report();
    ctrl_mon.report();
`ifdef SPADMIC_ENABLE_FUNC_COV
    stim_cov.report();
    pkt_cov.report();
    ctrl_cov.report();
    fault_cov.report();
    reset_cov.report();
`endif
    $display("[ENV] TX Monitor: %0d packets, %0d words total",
             tx_mon.total_packets, tx_mon.total_words);
    spad_reset_mon.report();
    $display("[ENV] CSR Monitor: %0d writes, %0d reads, %0d errors",
             csr_mon.total_writes, csr_mon.total_reads, csr_mon.total_errors);
  endfunction

endclass
