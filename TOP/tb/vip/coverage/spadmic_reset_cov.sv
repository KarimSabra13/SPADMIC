// =============================================================================
// SPADMIC VIP — SPAD Matrix Reset Coverage
// =============================================================================

`ifdef SPADMIC_ENABLE_FUNC_COV

class spadmic_reset_cov;

  logic [1:0]  reset_mode;
  int unsigned reset_period_class;
  int unsigned pulse_width_cycles;
  logic        traffic_active;

  covergroup cg_reset;
    cp_reset_mode: coverpoint reset_mode {
      bins manual_only    = {SPADMIC_SPAD_RST_MANUAL_ONLY};
      bins event_deferred = {SPADMIC_SPAD_RST_EVENT_DEFERRED};
      bins periodic       = {SPADMIC_SPAD_RST_PERIODIC};
      illegal_bins bad    = {2'd3};
    }

    cp_period_class: coverpoint reset_period_class {
      bins disabled = {0};
      bins short_p  = {1};
      bins long_p   = {2};
    }

    cp_pulse_width: coverpoint pulse_width_cycles {
      bins one_cycle = {1};
      illegal_bins wide = {[2:$]};
      illegal_bins zero = {0};
    }

    cp_traffic_active: coverpoint traffic_active;

    cx_mode_x_period: cross cp_reset_mode, cp_period_class;
    cx_mode_x_traffic: cross cp_reset_mode, cp_traffic_active;
  endgroup

  function new();
    cg_reset = new();
  endfunction

  function void sample(
    logic [1:0] reset_mode_v,
    int unsigned reset_period_class_v,
    int unsigned pulse_width_cycles_v,
    logic traffic_active_v
  );
    reset_mode          = reset_mode_v;
    reset_period_class  = reset_period_class_v;
    pulse_width_cycles  = pulse_width_cycles_v;
    traffic_active      = traffic_active_v;
    cg_reset.sample();
  endfunction

  function void report();
    $display("[RESET_COV] Coverage: %.1f%%", cg_reset.get_coverage());
  endfunction

endclass

`endif

