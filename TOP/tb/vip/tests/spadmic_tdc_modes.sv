// =============================================================================
// SPADMIC VIP — TDC Modes Test
// Walks all 3 output modes × {1,5,10,15} max_hits = 12 combinations.
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
    out_mode_e modes[3] = '{OUT_MODE_RAW_FEATURES, OUT_MODE_RAW_TIMESTAMP, OUT_MODE_FULL};
    int hits[4] = '{1, 5, 10, 15};

    env.gen.gen_initial_config();

    for (int m = 0; m < 3; m++) begin
      for (int h = 0; h < 4; h++) begin
        // Reconfigure
        begin
          spadmic_ctrl_txn ct = new();
          ct.global_enable  = 1'b1;
          ct.axis_enable    = 3'b111;
          ct.shared_tx_sel  = SPADMIC_TX_TDC;
          ct.tdc_input_sel  = INPUT_CAL;
          ct.tdc_out_mode   = modes[m];
          ct.max_hits       = hits[h][3:0];
          ct.drv_mode       = cfg.drv_mode;
          env.gen.drv_mb.put(ct);
        end
        // Inject on all 3 axes
        for (int ax = 0; ax < 3; ax++)
          env.gen.gen_tdc_conversions(ax, 2, 10000);
      end
    end

    env.gen.gen_eot();
  endtask
endclass

