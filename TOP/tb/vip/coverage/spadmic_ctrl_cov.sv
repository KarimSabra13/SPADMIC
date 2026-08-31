// =============================================================================
// SPADMIC VIP — Control-Plane State Coverage
// Tracks control-plane states and transitions exercised during simulation.
// =============================================================================

`ifdef SPADMIC_ENABLE_FUNC_COV

class spadmic_ctrl_cov;

  logic       safe_idle;
  logic       global_enable;
  logic [2:0] active_mode;
  logic [2:0] active_axis_mask;
  logic       access_fault_present;
  logic       page_fault_present;

  covergroup cg_ctrl;
    cp_safe_idle: coverpoint safe_idle;
    cp_global_enable: coverpoint global_enable;
    cp_active_mode: coverpoint active_mode {
      bins disabled = {SPADMIC_MODE_DISABLED};
      bins tdc = {SPADMIC_MODE_TDC_ONLY};
      bins position = {SPADMIC_MODE_POSITION_ONLY};
      bins both = {SPADMIC_MODE_BOTH};
      bins calibration = {SPADMIC_MODE_CALIBRATION};
      illegal_bins reserved = {[3'd5:3'd7]};
    }
    cp_axis_mask: coverpoint active_axis_mask {
      bins none = {3'b000};
      bins partial[] = {[3'b001:3'b110]};
      bins normal_full = {3'b111};
    }
    cp_access_fault: coverpoint access_fault_present;
    cp_page_fault: coverpoint page_fault_present;

    cx_mode_x_enable: cross cp_active_mode, cp_global_enable;
    cx_mode_x_axis: cross cp_active_mode, cp_axis_mask;
    cx_idle_x_enable: cross cp_safe_idle, cp_global_enable;
  endgroup

  function new();
    cg_ctrl = new();
  endfunction

  function void sample(
    logic idle,
    logic enable,
    logic [2:0] mode,
    logic [2:0] axis_mask,
    logic access_fault,
    logic page_fault
  );
    safe_idle = idle;
    global_enable = enable;
    active_mode = mode;
    active_axis_mask = axis_mask;
    access_fault_present = access_fault;
    page_fault_present = page_fault;
    cg_ctrl.sample();
  endfunction

  function void report();
    $display("[CTRL_COV] Coverage: %.1f%%", cg_ctrl.get_coverage());
  endfunction

endclass

`endif
