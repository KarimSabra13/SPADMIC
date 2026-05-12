// =============================================================================
// SPADMIC VIP — Environment Configuration
// All test-level knobs in one place.
// =============================================================================

class spadmic_env_cfg;

  // Driver mode
  spadmic_drv_mode_e drv_mode;

  // Mission profile
  spadmic_profile_e  profile;

  // Default TDC config
  input_sel_e        default_input_sel;
  out_mode_e         default_out_mode;
  logic [MAX_HITS_W-1:0] default_max_hits;

  // Default position config
  logic [6:0]        default_gap_threshold;
  logic [SPADMIC_LINE_COUNT_W-1:0] default_min_cluster_span;
  logic [3:0]        default_settle_cycles;

  // Test parameters
  int unsigned       num_conversions;
  int unsigned       num_phases;
  int unsigned       timeout_ns;
  int unsigned       seed;

  // Feature enables
  bit                enable_coverage;
  bit                enable_sva;
  bit                enable_reset_test;

  // Constrained-random policy. Normal random stays legal/coherent by default;
  // dedicated fault tests can override these knobs.
  bit                random_legal_only;
  int unsigned       random_weight_tdc;
  int unsigned       random_weight_position;
  int unsigned       random_weight_mode_switch;
  int unsigned       random_weight_bp;
  int unsigned       random_weight_correlated;

  function new();
    drv_mode              = DRV_MODE_DIRECT_CSR;
    profile               = PROFILE_TDC_CHAR;
    default_input_sel     = INPUT_CAL;
    default_out_mode      = OUT_MODE_RAW_FEATURES;
    default_max_hits      = 4'd15;
    default_gap_threshold    = 7'd10;
    default_min_cluster_span = 7'd5;
    default_settle_cycles    = 4'd4;
    num_conversions       = 10;
    num_phases            = 20;
    timeout_ns            = 500_000;
    seed                  = 0;
    enable_coverage       = 1'b1;
    enable_sva            = 1'b1;
    enable_reset_test     = 1'b0;
    random_legal_only     = 1'b1;
    random_weight_tdc         = 20;
    random_weight_position    = 20;
    random_weight_mode_switch = 10;
    random_weight_bp          = 10;
    random_weight_correlated  = 40;
  endfunction

  function void parse_plusargs();
    string s;
    int v;
    if ($value$plusargs("SPADMIC_DRV_MODE=%s", s))
      drv_mode = (s == "I2C") ? DRV_MODE_I2C : DRV_MODE_DIRECT_CSR;
    if ($value$plusargs("SPADMIC_PROFILE=%s", s)) begin
      case (s)
        "TDC_CHAR":    profile = PROFILE_TDC_CHAR;
        "POSITION":    profile = PROFILE_POSITION;
        "MODE_SWITCH": profile = PROFILE_MODE_SWITCH;
        "STRESS":      profile = PROFILE_STRESS;
      endcase
    end
    if ($value$plusargs("SPADMIC_NUM_CONV=%d", v))
      num_conversions = v;
    if ($value$plusargs("SPADMIC_NUM_PHASES=%d", v))
      num_phases = v;
    if ($value$plusargs("SPADMIC_TIMEOUT=%d", v))
      timeout_ns = v;
    if ($value$plusargs("SPADMIC_SEED=%d", v))
      seed = v;
    if ($value$plusargs("SPADMIC_MAX_HITS=%d", v))
      default_max_hits = v[MAX_HITS_W-1:0];
    if ($value$plusargs("SPADMIC_OUT_MODE=%d", v))
      default_out_mode = out_mode_e'(v[1:0]);
    if ($value$plusargs("SPADMIC_RANDOM_LEGAL_ONLY=%d", v))
      random_legal_only = (v != 0);
    if ($value$plusargs("SPADMIC_RAND_W_TDC=%d", v))
      random_weight_tdc = v;
    if ($value$plusargs("SPADMIC_RAND_W_POS=%d", v))
      random_weight_position = v;
    if ($value$plusargs("SPADMIC_RAND_W_SWITCH=%d", v))
      random_weight_mode_switch = v;
    if ($value$plusargs("SPADMIC_RAND_W_BP=%d", v))
      random_weight_bp = v;
    if ($value$plusargs("SPADMIC_RAND_W_CORR=%d", v))
      random_weight_correlated = v;
  endfunction

  function void display();
    $display("╔═══════════════════════════════════════════════════╗");
    $display("║          SPADMIC VIP CONFIGURATION                ║");
    $display("╠═══════════════════════════════════════════════════╣");
    $display("║  Driver mode:     %s", drv_mode.name());
    $display("║  Profile:         %s", profile.name());
    $display("║  Input select:    %s", default_input_sel.name());
    $display("║  Output mode:     %s", default_out_mode.name());
    $display("║  Max hits:        %0d", default_max_hits);
    $display("║  Num conversions: %0d", num_conversions);
    $display("║  Num phases:      %0d", num_phases);
    $display("║  Timeout:         %0d ns", timeout_ns);
    $display("║  Seed:            %0d", seed);
    $display("║  Random legal:    %0b", random_legal_only);
    $display("║  Rand weights:    TDC=%0d POS=%0d SWITCH=%0d BP=%0d CORR=%0d",
             random_weight_tdc, random_weight_position,
             random_weight_mode_switch, random_weight_bp,
             random_weight_correlated);
    $display("╚═══════════════════════════════════════════════════╝");
  endfunction

endclass
