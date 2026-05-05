// =============================================================================
// SPADMIC VIP — Position Clusters Test
// Walks gap_threshold × min_span × diverse patterns.
// =============================================================================

class spadmic_pos_clusters extends spadmic_base_test;

  function new();
    super.new("pos_clusters");
  endfunction

  function void configure();
    cfg.drv_mode  = DRV_MODE_DIRECT_CSR;
    cfg.profile   = PROFILE_POSITION;
    cfg.timeout_ns = 1_000_000;
  endfunction

  task body();
    logic [SPADMIC_LINE_W-1:0] pat;
    int gap_vals[3] = '{5, 10, 15};
    int span_vals[3] = '{5, 10, 20};

    env.gen.gen_initial_config();

    for (int g = 0; g < 3; g++) begin
      for (int s = 0; s < 3; s++) begin
        // Reconfigure position cluster scan thresholds for this sweep point.
        env.gen.gen_csr_write(SPADMIC_CSR_POS_GAP_CFG, gap_vals[g]);
        env.gen.gen_csr_write(SPADMIC_CSR_POS_FILTER_CFG, span_vals[s]);

        // Single cluster pattern
        pat = '0;
        for (int i = 10; i < 10 + span_vals[s]; i++) pat[i] = 1'b1;
        env.gen.gen_position_event(pat, pat, pat, 200);

        // Dual cluster pattern (two clusters separated by gap)
        pat = '0;
        for (int i = 5; i < 5 + span_vals[s]; i++) pat[i] = 1'b1;
        for (int i = 5 + span_vals[s] + gap_vals[g]; 
             i < 5 + 2*span_vals[s] + gap_vals[g] && i < SPADMIC_LINE_W; i++)
          pat[i] = 1'b1;
        env.gen.gen_position_event(pat, '0, '0, 200);
      end
    end

    env.gen.gen_eot();
  endtask
endclass
