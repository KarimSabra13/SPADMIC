// =============================================================================
// SPADMIC VIP — Test Factory
// Maps test name string (from +SPADMIC_TEST=...) to test class instance.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_test_factory;
  import spadmic_vip_pkg::*;

  static function spadmic_base_test create_test(string name);
    case (name)
      "smoke_tdc":          begin spadmic_base_test t = new("smoke_tdc"); return t; end
      "smoke_position":     begin spadmic_base_test t = new("smoke_position"); return t; end
      "smoke_switching":    begin spadmic_base_test t = new("smoke_switching"); return t; end
      "tdc_modes":          begin spadmic_base_test t = new("tdc_modes"); return t; end
      "pos_clusters":       begin spadmic_base_test t = new("pos_clusters"); return t; end
      "ctrl_reject":        begin spadmic_base_test t = new("ctrl_reject"); return t; end
      "reset_recovery":     begin spadmic_base_test t = new("reset_recovery"); return t; end
      "bp_stress":          begin spadmic_base_test t = new("bp_stress"); return t; end
      "i2c_end_to_end":     begin spadmic_base_test t = new("i2c_end_to_end"); return t; end
      "long_random":        begin spadmic_base_test t = new("long_random"); return t; end
      "coverage_walk":      begin spadmic_base_test t = new("coverage_walk"); return t; end
      "stress_random":      begin spadmic_base_test t = new("stress_random"); return t; end
      default: begin
        $display("[FACTORY] Unknown test: %s — using base test", name);
        begin spadmic_base_test t = new(name); return t; end
      end
    endcase
  endfunction

endclass

`default_nettype wire
