// =============================================================================
// SPADMIC VIP — SPAD Matrix Reset Coverage
// =============================================================================

`ifdef SPADMIC_ENABLE_FUNC_COV

class spadmic_reset_cov;

  logic        auto_reset_enable;
  int unsigned configured_width_cycles;
  int unsigned pulse_width_cycles;
  logic        traffic_active;

  covergroup cg_reset;
    cp_auto_reset: coverpoint auto_reset_enable;
    cp_configured_width: coverpoint configured_width_cycles {
      illegal_bins disabled = {0};
      bins short_width = {[1:4]};
      bins medium_width = {[5:16]};
      bins long_width = {[17:$]};
    }

    cp_pulse_width: coverpoint pulse_width_cycles {
      illegal_bins zero = {0};
      bins short_width = {[1:4]};
      bins medium_width = {[5:16]};
      bins long_width = {[17:$]};
    }

    cp_traffic_active: coverpoint traffic_active;

    cx_enable_x_width: cross cp_auto_reset, cp_configured_width;
    cx_enable_x_traffic: cross cp_auto_reset, cp_traffic_active;
  endgroup

  function new();
    cg_reset = new();
  endfunction

  function void sample(
    logic auto_reset_enable_v,
    int unsigned configured_width_cycles_v,
    int unsigned pulse_width_cycles_v,
    logic traffic_active_v
  );
    auto_reset_enable       = auto_reset_enable_v;
    configured_width_cycles = configured_width_cycles_v;
    pulse_width_cycles  = pulse_width_cycles_v;
    traffic_active      = traffic_active_v;
    cg_reset.sample();
  endfunction

  function void report();
    $display("[RESET_COV] Coverage: %.1f%%", cg_reset.get_coverage());
  endfunction

endclass

`endif
