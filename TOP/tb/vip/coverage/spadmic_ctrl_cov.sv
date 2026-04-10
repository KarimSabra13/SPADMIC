// =============================================================================
// SPADMIC VIP — Control-Plane State Coverage
// Tracks control-plane states and transitions exercised during simulation.
// =============================================================================

`ifdef SPADMIC_ENABLE_FUNC_COV

class spadmic_ctrl_cov;

  logic       cfg_accept;
  logic       transition_busy;
  logic       ctrl_apply_pending;
  logic       mode_reject_sticky;
  logic       path_idle;
  logic [1:0] seq_state;  // 0=reset, 1=idle, 2=drain

  covergroup cg_ctrl;
    cp_cfg_accept:      coverpoint cfg_accept;
    cp_transition_busy: coverpoint transition_busy;
    cp_ctrl_pending:    coverpoint ctrl_apply_pending;
    cp_reject_sticky:   coverpoint mode_reject_sticky;
    cp_path_idle:       coverpoint path_idle;
    cp_seq_state:       coverpoint seq_state { bins reset_st = {0};
                                                bins idle_st = {1};
                                                bins drain_st = {2}; }

    cx_accept_x_idle:  cross cp_cfg_accept, cp_path_idle;
    cx_reject_x_state: cross cp_reject_sticky, cp_seq_state;
  endgroup

  function new();
    cg_ctrl = new();
  endfunction

  function void sample(
    logic accept, logic busy, logic pending,
    logic reject, logic idle, logic [1:0] state
  );
    cfg_accept          = accept;
    transition_busy     = busy;
    ctrl_apply_pending  = pending;
    mode_reject_sticky  = reject;
    path_idle           = idle;
    seq_state           = state;
    cg_ctrl.sample();
  endfunction

  function void report();
    $display("[CTRL_COV] Coverage: %.1f%%", cg_ctrl.get_coverage());
  endfunction

endclass

`endif

