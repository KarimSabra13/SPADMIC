// =============================================================================
// SPADMIC VIP — TDC Modes Test
// Walks the shared TDC max-hits settings used by normal matrix operation.
// =============================================================================

class spadmic_tdc_modes extends spadmic_base_test;

  function new();
    super.new("tdc_modes");
  endfunction

  function void configure();
    cfg.drv_mode   = DRV_MODE_DIRECT_CSR;
    cfg.profile    = PROFILE_TDC_CHAR;
    cfg.timeout_ns = 2_000_000;
  endfunction

  task body();
    int hits[4] = '{1, 5, 10, 15};

    env.gen.gen_initial_config();

    for (int h = 0; h < 4; h++) begin
      spadmic_ctrl_txn ct = new();
      ct.global_enable  = 1'b1;
      ct.axis_enable    = 3'b111;
      ct.shared_tx_sel  = SPADMIC_TX_TDC;
      ct.tdc_input_sel  = INPUT_SPAD;
      ct.tdc_out_mode   = OUT_MODE_RAW_FEATURES;
      ct.max_hits       = hits[h][3:0];
      ct.drv_mode       = cfg.drv_mode;
      env.gen.drv_mb.put(ct);
      env.gen.gen_tdc_conversions(0, 2, 10000);
    end

    env.gen.gen_eot();
  endtask
endclass
