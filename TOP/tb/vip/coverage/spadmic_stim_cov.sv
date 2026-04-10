// =============================================================================
// SPADMIC VIP — Stimulus Coverage
// Tracks configuration combinations exercised during simulation.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

`ifdef SPADMIC_ENABLE_FUNC_COV

class spadmic_stim_cov;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  // Sampled fields
  logic       tx_sel;
  logic       input_sel;
  logic [1:0] out_mode;
  logic [3:0] max_hits;
  int         bp_mode;
  int         delay_bin;   // 0=short, 1=med, 2=long, 3=max

  covergroup cg_stim;
    cp_tx_sel:    coverpoint tx_sel    { bins tdc = {0}; bins pos = {1}; }
    cp_input_sel: coverpoint input_sel { bins spad = {0}; bins cal = {1}; }
    cp_out_mode:  coverpoint out_mode  { bins raw_feat = {0}; bins raw_ts = {1};
                                          bins full = {2};
                                          illegal_bins bad_mode = {3}; }
    cp_max_hits:  coverpoint max_hits  { bins mh1 = {1}; bins mh5 = {5};
                                          bins mh10 = {10}; bins mh15 = {15}; }
    cp_bp_mode:   coverpoint bp_mode   { bins ready = {0}; bins random = {1};
                                          bins stall = {2}; }
    cp_delay_bin: coverpoint delay_bin { bins short_d = {0}; bins med_d = {1};
                                          bins long_d = {2}; bins max_d = {3}; }

    cx_mode_x_hits:  cross cp_out_mode, cp_max_hits;
    cx_sel_x_mode:   cross cp_tx_sel, cp_out_mode;
    cx_bp_x_delay:   cross cp_bp_mode, cp_delay_bin;
    cx_input_x_mode: cross cp_input_sel, cp_out_mode;
  endgroup

  function new();
    cg_stim = new();
  endfunction

  function void sample(
    logic       tx_sel_v,
    logic       input_sel_v,
    logic [1:0] out_mode_v,
    logic [3:0] max_hits_v,
    int         bp_mode_v,
    int         delay_bin_v
  );
    this.tx_sel    = tx_sel_v;
    this.input_sel = input_sel_v;
    this.out_mode  = out_mode_v;
    this.max_hits  = max_hits_v;
    this.bp_mode   = bp_mode_v;
    this.delay_bin = delay_bin_v;
    cg_stim.sample();
  endfunction

  function void report();
    $display("[STIM_COV] Coverage: %.1f%%", cg_stim.get_coverage());
  endfunction

endclass

`endif

`default_nettype wire
