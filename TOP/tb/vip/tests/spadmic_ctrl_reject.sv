// =============================================================================
// SPADMIC VIP — Control Reject Test
// Writes GLOBAL_CTRL while NOT idle → expects reject sticky + count.
// =============================================================================

class spadmic_ctrl_reject extends spadmic_base_test;

  function new();
    super.new("ctrl_reject");
  endfunction

  function void configure();
    cfg.drv_mode   = DRV_MODE_DIRECT_CSR;
    cfg.profile    = PROFILE_TDC_CHAR;
    cfg.timeout_ns = 500_000;
    cfg.enable_reset_test = 1'b1;
  endfunction

  task body();
    // Start TDC traffic
    env.gen.gen_initial_config();
    env.gen.gen_tdc_conversions(0, 10, 10000);

    // While traffic is in-flight, attempt to change mode (should be rejected)
    begin
      spadmic_ctrl_txn ct = new();
      ct.raw_csr_write = 1'b1;
      ct.addr          = SPADMIC_CSR_GLOBAL_CTRL;
      ct.wdata         = 32'h0000_00F5;  // valid POSITION_ONLY control value
      ct.drv_mode      = cfg.drv_mode;
      env.gen.drv_mb.put(ct);
    end

    // Read fault register to check reject
    begin
      spadmic_ctrl_txn rd = new();
      rd.is_read = 1'b1;
      rd.addr    = CSR_ACCESS_LAST_INFO;
      rd.drv_mode = cfg.drv_mode;
      env.gen.drv_mb.put(rd);
    end

    env.gen.gen_eot();
  endtask
endclass
