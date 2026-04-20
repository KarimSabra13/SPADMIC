// =============================================================================
// SPADMIC VIP — Stimulus Coverage
// Tracks configuration combinations exercised during simulation.
// =============================================================================

`ifdef SPADMIC_ENABLE_FUNC_COV

class spadmic_stim_cov;

  // Sampled fields
  logic [1:0] export_mode;
  int         drv_mode;
  logic       input_sel;
  logic [1:0] out_mode;
  logic [3:0] max_hits;
  logic [2:0] axis_mask;
  logic       pos_present;
  int         delay_bin;   // 0=short, 1=med, 2=long, 3=max
  int         stim_kind;

  covergroup cg_stim;
    cp_export_mode: coverpoint export_mode {
      bins tdc_only = {SPADMIC_EXPORT_TDC_ONLY};
      bins pos_only = {SPADMIC_EXPORT_POSITION_ONLY};
      bins both     = {SPADMIC_EXPORT_BOTH_ACTIVE};
    }
    cp_drv_mode:  coverpoint drv_mode  { bins i2c = {DRV_MODE_I2C};
                                         bins direct = {DRV_MODE_DIRECT_CSR}; }
    cp_input_sel: coverpoint input_sel { bins spad = {0}; bins cal = {1}; }
    cp_out_mode:  coverpoint out_mode  { bins raw_feat = {0}; bins raw_ts = {1};
                                          bins full = {2};
                                          illegal_bins bad_mode = {3}; }
    cp_max_hits:  coverpoint max_hits  { bins mh1 = {1}; bins mh5 = {5};
                                          bins mh10 = {10}; bins mh15 = {15}; }
    cp_axis_mask: coverpoint axis_mask { bins x = {3'b001}; bins y = {3'b010};
                                         bins z = {3'b100}; bins xy = {3'b011};
                                         bins yz = {3'b110}; bins xz = {3'b101};
                                         bins xyz = {3'b111}; bins none = {3'b000}; }
    cp_pos_present: coverpoint pos_present;
    cp_delay_bin: coverpoint delay_bin { bins short_d = {0}; bins med_d = {1};
                                           bins long_d = {2}; bins max_d = {3}; }
    cp_stim_kind: coverpoint stim_kind { bins tdc = {STIM_KIND_TDC};
                                         bins pos = {STIM_KIND_POSITION};
                                         bins corr = {STIM_KIND_CORRELATED};
                                         bins reset = {STIM_KIND_RESET}; }

    cx_mode_x_hits:  cross cp_out_mode, cp_max_hits;
    cx_export_x_kind: cross cp_export_mode, cp_stim_kind;
    cx_drv_x_export:  cross cp_drv_mode, cp_export_mode;
    cx_axis_x_kind:   cross cp_axis_mask, cp_stim_kind;
    cx_input_x_mode: cross cp_input_sel, cp_out_mode;
  endgroup

  function new();
    cg_stim = new();
  endfunction

  function void sample(
    logic [1:0] export_mode_v,
    int         drv_mode_v,
    logic       input_sel_v,
    logic [1:0] out_mode_v,
    logic [3:0] max_hits_v,
    logic [2:0] axis_mask_v,
    logic       pos_present_v,
    int         delay_bin_v,
    int         stim_kind_v
  );
    this.export_mode = export_mode_v;
    this.drv_mode    = drv_mode_v;
    this.input_sel   = input_sel_v;
    this.out_mode    = out_mode_v;
    this.max_hits    = max_hits_v;
    this.axis_mask   = axis_mask_v;
    this.pos_present = pos_present_v;
    this.delay_bin   = delay_bin_v;
    this.stim_kind   = stim_kind_v;
    cg_stim.sample();
  endfunction

  function void report();
    $display("[STIM_COV] Coverage: %.1f%%", cg_stim.get_coverage());
  endfunction

endclass

`endif
