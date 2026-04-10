// =============================================================================
// SPADMIC VIP — Fault/Corner Coverage
// Tracks error injection, fault observation, and corner-case scenarios.
// =============================================================================

`ifdef SPADMIC_ENABLE_FUNC_COV

class spadmic_fault_cov;

  logic       pos_drop_sticky;
  logic       pos_glitch_sticky;
  logic       mode_reject_sticky;
  logic [2:0] tdc_pkt_full;
  logic       reset_during_traffic;
  logic       csr_read_timeout_hit;

  covergroup cg_fault;
    cp_pos_drop:     coverpoint pos_drop_sticky;
    cp_pos_glitch:   coverpoint pos_glitch_sticky;
    cp_mode_reject:  coverpoint mode_reject_sticky;
    cp_fifo_full:    coverpoint tdc_pkt_full {
      bins none  = {0};
      bins x_f   = {1};
      bins y_f   = {2};
      bins z_f   = {4};
      bins xy_f  = {3};
      bins all_f = {7};
      bins other = default;
    }
    cp_reset_during: coverpoint reset_during_traffic;
    cp_csr_timeout:  coverpoint csr_read_timeout_hit;

    cx_fault_combo: cross cp_pos_drop, cp_pos_glitch, cp_mode_reject;
  endgroup

  function new();
    cg_fault = new();
  endfunction

  function void sample(
    logic drop, logic glitch, logic reject,
    logic [2:0] fifo_full, logic rst_traffic, logic csr_to
  );
    pos_drop_sticky       = drop;
    pos_glitch_sticky     = glitch;
    mode_reject_sticky    = reject;
    tdc_pkt_full          = fifo_full;
    reset_during_traffic  = rst_traffic;
    csr_read_timeout_hit  = csr_to;
    cg_fault.sample();
  endfunction

  function void report();
    $display("[FAULT_COV] Coverage: %.1f%%", cg_fault.get_coverage());
  endfunction

endclass

`endif

