// =============================================================================
// SPADMIC VIP — Test Factory
// Maps test name string (from +SPADMIC_TEST=...) to test class instance.
// =============================================================================

class spadmic_test_factory;

  static function spadmic_base_test create_test(string name);
    case (name)
      "smoke_tdc":          begin spadmic_smoke_tdc t = new(); return t; end
      "smoke_position":     begin spadmic_smoke_position t = new(); return t; end
      "smoke_switching":    begin spadmic_smoke_switching t = new(); return t; end
      "tdc_modes":          begin spadmic_tdc_modes t = new(); return t; end
      "pos_clusters":       begin spadmic_pos_clusters t = new(); return t; end
      "ctrl_reject":        begin spadmic_ctrl_reject t = new(); return t; end
      "reset_recovery":     begin spadmic_reset_recovery t = new(); return t; end
      "bp_stress":          begin spadmic_bp_stress t = new(); return t; end
      "i2c_end_to_end":     begin spadmic_i2c_end_to_end t = new(); return t; end
      "long_random":        begin spadmic_long_random t = new(); return t; end
      "coverage_walk":      begin spadmic_coverage_walk t = new(); return t; end
      "stress_random":      begin spadmic_stress_random t = new(); return t; end
      "smoke_position_raw": begin spadmic_smoke_position_raw t = new(); return t; end
      "spad_reset_modes":   begin spadmic_spad_reset_modes t = new(); return t; end
      default: begin
        $display("[FACTORY] Unknown test: %s — using base test", name);
        begin spadmic_base_test t = new(name); return t; end
      end
    endcase
  endfunction

endclass
