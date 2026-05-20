// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : mptdc_vip_pkg.sv
// Purpose : VIP package for transactions, drivers, monitor, scoreboard, and tests.
// Author  : Karim Sabra
// Notes   : Packet helpers decode the exact narrow-bus contract consumed by the
//           class-based monitor and scoreboard.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

package mptdc_vip_pkg;
  import mptdc_pkg::*;

  typedef enum int unsigned {
    BP_ALWAYS_READY       = 0,
    BP_RANDOM_50          = 1,
    BP_ALWAYS_STALL       = 2,
    BP_BOUNDED_STALL      = 3,
    BP_SATURATION_RELEASE = 4
  } mptdc_bp_mode_e;

  typedef enum int unsigned {
    STOP_DIRECT_DELAY  = 0,
    STOP_QUALIFIED_REF = 1
  } mptdc_stop_model_e;

  function automatic string stop_model_name(input mptdc_stop_model_e model);
    case (model)
      STOP_DIRECT_DELAY:  return "direct_delay";
      STOP_QUALIFIED_REF: return "qualified_ref";
      default:            return "unknown";
    endcase
  endfunction

  typedef enum int unsigned {
    TXN_CFG   = 0,
    TXN_CONV  = 1,
    TXN_BP    = 2,
    TXN_RESET = 3,
    TXN_EOT   = 4
  } mptdc_txn_kind_e;

  // Compatibility-only scenario tag used by the VIP. The active RTL has a
  // single mode bit value on CSR_MODE[0] (reserved, read-as-zero), but the VIP
  // still needs to distinguish normal multi-hit runs from fast-close runs that
  // are now selected by programming max_hits=1.
  typedef logic [0:0] vip_mode_t;
  localparam vip_mode_t VIP_MODE_FAST_CLOSE = 1'b1;

  function automatic logic [MAX_HITS_W-1:0] vip_effective_max_hits(
    input vip_mode_t                mode_cfg,
    input logic [MAX_HITS_W-1:0]    max_hits
  );
    if (mode_cfg == VIP_MODE_FAST_CLOSE)
      return MAX_HITS_W'(1);
    return max_hits;
  endfunction

  function automatic vip_mode_t vip_effective_mode_cfg(
    input logic [MAX_HITS_W-1:0] max_hits
  );
    if (max_hits == MAX_HITS_W'(1))
      return VIP_MODE_FAST_CLOSE;
    return vip_mode_t'(MODE_MULTI_HIT);
  endfunction

  // These helpers decode the exact narrow packet format observed on the
  // wire so the monitor and scoreboard stay anchored to the DUT contract.
  function automatic bit is_header_word(input logic [NARROW_W-1:0] word);
    return word[15:13] == 3'b100;  // v2.3: distinguish from sub-header
  endfunction

  function automatic bit is_subheader_word(input logic [NARROW_W-1:0] word);
    return word[15:13] == 3'b101;  // v2.3: sub-header marker
  endfunction

  function automatic logic [NFAST_W-1:0] subheader_nfast_stop_vip(
    input logic [NARROW_W-1:0] word
  );
    return word[12:6];
  endfunction

  function automatic bit is_eoc_word(input logic [NARROW_W-1:0] word);
    return word[15:14] == 2'b11;
  endfunction

  function automatic ctx_id_t packet_ctx_id(input logic [NARROW_W-1:0] word);
    return ctx_id_t'(word[13:12]);
  endfunction

  function automatic bit packet_phase0(input logic [NARROW_W-1:0] word);
    return word[11];
  endfunction

  function automatic logic [MAX_HITS_W-1:0] packet_hit_count(input logic [NARROW_W-1:0] word);
    return word[10:7];
  endfunction

  function automatic tdc_conv_flags_t packet_flags(input logic [NARROW_W-1:0] word);
    return tdc_conv_flags_t'(word[6:3]);
  endfunction

  function automatic out_mode_e packet_out_mode(input logic [NARROW_W-1:0] word);
    return out_mode_e'(word[2:1]);
  endfunction

  function automatic bit packet_boundary_inc(input logic [NARROW_W-1:0] word);
    return word[0];
  endfunction

  function automatic logic [13:0] packet_conv_id(input logic [NARROW_W-1:0] word);
    return word[13:0];
  endfunction

  function automatic stop_phase_disc_t packet_stop_phase_disc(input logic [NARROW_W-1:0] word);
    return stop_phase_disc_t'(word[2:0]);
  endfunction

  function automatic int unsigned words_per_hit(input out_mode_e mode);
    case (mode)
      OUT_MODE_RAW_FEATURES:  return 2;
      OUT_MODE_RAW_TIMESTAMP: return 2;
      OUT_MODE_FULL:          return 3;
      default:                return 2;
    endcase
  endfunction

  function automatic int unsigned packet_words_from_header(input logic [NARROW_W-1:0] hdr);
    return 2 + (packet_hit_count(hdr) * words_per_hit(packet_out_mode(hdr)));
  endfunction

  function automatic string bp_mode_name(input mptdc_bp_mode_e mode);
    case (mode)
      BP_ALWAYS_READY:       return "always_ready";
      BP_RANDOM_50:          return "random_50";
      BP_ALWAYS_STALL:       return "always_stall";
      BP_BOUNDED_STALL:      return "bounded_stall";
      BP_SATURATION_RELEASE: return "saturation_release";
      default:               return "unknown";
    endcase
  endfunction

  class mptdc_env_cfg;
    string test_name;
    int unsigned random_seed;
    int osc_jitter_sigma_ps;
    int osc_jitter_bound_ps;
    bit enable_func_cov;
    int num_conv;
    mptdc_stop_model_e stop_model;
    int unsigned ref_phase_offset_ps;
    string txn_log_csv;
    string txn_log_jsonl;
    string failure_dir;

    function new();
      test_name           = "unset";
      random_seed         = 32'h1bad_f00d;
      osc_jitter_sigma_ps = 0;
      osc_jitter_bound_ps = 0;
      enable_func_cov     = 1'b0;
      num_conv            = 0;
      stop_model          = STOP_DIRECT_DELAY;
      ref_phase_offset_ps = 0;
      txn_log_csv         = "";
      txn_log_jsonl       = "";
      failure_dir         = "";
    endfunction
  endclass

  class mptdc_base_txn;
    mptdc_txn_kind_e kind;
    string           label;

    function new(mptdc_txn_kind_e kind_i = TXN_CFG, string label_i = "txn");
      kind  = kind_i;
      label = label_i;
    endfunction

    virtual function string sprint();
      return $sformatf("kind=%0d label=%s", kind, label);
    endfunction
  endclass

  class mptdc_cfg_txn extends mptdc_base_txn;
    vip_mode_t              mode_cfg;
    input_sel_e             input_sel;
    out_mode_e              out_mode;
    logic [MAX_HITS_W-1:0]  max_hits;
    logic [15:0]            wdt_ctx_timeout;
    logic [15:0]            wdt_global_timeout;

    function new(string label_i = "cfg");
      super.new(TXN_CFG, label_i);
      mode_cfg           = vip_mode_t'(MODE_MULTI_HIT);
      input_sel          = INPUT_SPAD;
      out_mode           = OUT_MODE_RAW_FEATURES;
      max_hits           = MAX_HITS_W'(MAX_HITS);
      wdt_ctx_timeout    = 16'd0;
      wdt_global_timeout = 16'd0;
    endfunction

    function mptdc_cfg_txn clone();
      mptdc_cfg_txn c = new(label);
      c.mode_cfg           = mode_cfg;
      c.input_sel          = input_sel;
      c.out_mode           = out_mode;
      c.max_hits           = max_hits;
      c.wdt_ctx_timeout    = wdt_ctx_timeout;
      c.wdt_global_timeout = wdt_global_timeout;
      return c;
    endfunction

    function logic [MAX_HITS_W-1:0] effective_max_hits();
      return vip_effective_max_hits(mode_cfg, max_hits);
    endfunction

    function vip_mode_t effective_mode_cfg();
      return vip_effective_mode_cfg(effective_max_hits());
    endfunction

    function logic [CSR_DATA_W-1:0] pack_mode_reg();
      logic [CSR_DATA_W-1:0] word;
      word      = '0;
      word[0]   = MODE_MULTI_HIT;
      word[1]   = input_sel;
      word[3:2] = out_mode;
      return word;
    endfunction

    virtual function string sprint();
      return $sformatf("CFG[%s] mode=%0d input=%0d out=%0d max_hits=%0d eff_max_hits=%0d wdt_ctx=%0d wdt_global=%0d",
                       label, mode_cfg, input_sel, out_mode, max_hits, effective_max_hits(),
                       wdt_ctx_timeout, wdt_global_timeout);
    endfunction
  endclass

  class mptdc_backpressure_txn extends mptdc_base_txn;
    mptdc_bp_mode_e mode;
    int unsigned    random_seed;

    function new(string label_i = "bp");
      super.new(TXN_BP, label_i);
      mode        = BP_ALWAYS_READY;
      random_seed = 32'h1234_5678;
    endfunction

    virtual function string sprint();
      return $sformatf("BP[%s] mode=%s seed=%0d", label, bp_mode_name(mode), random_seed);
    endfunction
  endclass

  class mptdc_reset_txn extends mptdc_base_txn;
    time low_time_ps;
    time settle_time_ps;

    function new(string label_i = "reset");
      super.new(TXN_RESET, label_i);
      low_time_ps    = 100_000;
      settle_time_ps = 100_000;
    endfunction

    virtual function string sprint();
      return $sformatf("RESET[%s] low=%0t settle=%0t", label, low_time_ps, settle_time_ps);
    endfunction
  endclass

  class mptdc_conv_txn extends mptdc_base_txn;
    input_sel_e source_sel;
    int         attempt_id;
    int         event_id;
    time        start_stop_delay_ps;
    time        arm_settle_ps;
    time        pulse_width_ps;
    time        idle_after_ps;
    bit         start_only;
    bit         expect_packet;
    mptdc_stop_model_e stop_model;
    bit         accepted;
    bit         rejected;
    string      reject_reason;
    longint     start_time_ps;
    longint     stop_time_ps;
    longint     true_dt_ps;
    int         start_phase_sys_ps;
    int         start_phase_ref_ps;
    int         ref_phase_offset_ps;
    mptdc_bp_mode_e bp_mode_at_issue;

    bit         check_hit_range;
    int         min_hits;
    int         max_hits_allowed;
    bit         require_nonzero_hits;

    bit         check_firsthit_flag;
    bit         expected_firsthit_flag;
    bit         check_maxhits_flag;
    bit         expected_maxhits_flag;
    bit         check_watchdog_flag;
    bit         expected_watchdog_flag;
    bit         check_out_mode;
    bit         check_full_timestamp;
    bit         check_conv_id;
    int         expected_conv_id;

    vip_mode_t             cfg_mode;
    input_sel_e            cfg_input_sel;
    out_mode_e             cfg_out_mode;
    logic [MAX_HITS_W-1:0] cfg_max_hits;

    function new(string label_i = "conv");
      super.new(TXN_CONV, label_i);
      source_sel              = INPUT_SPAD;
      attempt_id              = -1;
      event_id                = -1;
      start_stop_delay_ps     = 10_000;
      arm_settle_ps           = 50_000;
      pulse_width_ps          = 1_000;
      idle_after_ps           = 50_000;
      start_only              = 1'b0;
      expect_packet           = 1'b1;
      stop_model              = STOP_DIRECT_DELAY;
      accepted                = 1'b0;
      rejected                = 1'b0;
      reject_reason           = "not_sampled";
      start_time_ps           = -1;
      stop_time_ps            = -1;
      true_dt_ps              = -1;
      start_phase_sys_ps      = 0;
      start_phase_ref_ps      = 0;
      ref_phase_offset_ps     = 0;
      bp_mode_at_issue        = BP_ALWAYS_READY;
      check_hit_range         = 1'b1;
      min_hits                = 0;
      max_hits_allowed        = MAX_HITS;
      require_nonzero_hits    = 1'b0;
      check_firsthit_flag     = 1'b0;
      expected_firsthit_flag  = 1'b0;
      check_maxhits_flag      = 1'b0;
      expected_maxhits_flag   = 1'b0;
      check_watchdog_flag     = 1'b0;
      expected_watchdog_flag  = 1'b0;
      check_out_mode          = 1'b1;
      check_full_timestamp    = 1'b0;
      check_conv_id           = 1'b0;
      expected_conv_id        = 0;
      cfg_mode                = MODE_MULTI_HIT;
      cfg_input_sel           = INPUT_SPAD;
      cfg_out_mode            = OUT_MODE_RAW_FEATURES;
      cfg_max_hits            = MAX_HITS_W'(MAX_HITS);
    endfunction

    function mptdc_conv_txn clone();
      mptdc_conv_txn c = new(label);
      c.source_sel             = source_sel;
      c.attempt_id             = attempt_id;
      c.event_id               = event_id;
      c.start_stop_delay_ps    = start_stop_delay_ps;
      c.arm_settle_ps          = arm_settle_ps;
      c.pulse_width_ps         = pulse_width_ps;
      c.idle_after_ps          = idle_after_ps;
      c.start_only             = start_only;
      c.expect_packet          = expect_packet;
      c.stop_model             = stop_model;
      c.accepted               = accepted;
      c.rejected               = rejected;
      c.reject_reason          = reject_reason;
      c.start_time_ps          = start_time_ps;
      c.stop_time_ps           = stop_time_ps;
      c.true_dt_ps             = true_dt_ps;
      c.start_phase_sys_ps     = start_phase_sys_ps;
      c.start_phase_ref_ps     = start_phase_ref_ps;
      c.ref_phase_offset_ps    = ref_phase_offset_ps;
      c.bp_mode_at_issue       = bp_mode_at_issue;
      c.check_hit_range        = check_hit_range;
      c.min_hits               = min_hits;
      c.max_hits_allowed       = max_hits_allowed;
      c.require_nonzero_hits   = require_nonzero_hits;
      c.check_firsthit_flag    = check_firsthit_flag;
      c.expected_firsthit_flag = expected_firsthit_flag;
      c.check_maxhits_flag     = check_maxhits_flag;
      c.expected_maxhits_flag  = expected_maxhits_flag;
      c.check_watchdog_flag    = check_watchdog_flag;
      c.expected_watchdog_flag = expected_watchdog_flag;
      c.check_out_mode         = check_out_mode;
      c.check_full_timestamp   = check_full_timestamp;
      c.check_conv_id          = check_conv_id;
      c.expected_conv_id       = expected_conv_id;
      c.cfg_mode               = cfg_mode;
      c.cfg_input_sel          = cfg_input_sel;
      c.cfg_out_mode           = cfg_out_mode;
      c.cfg_max_hits           = cfg_max_hits;
      return c;
    endfunction

    virtual function string sprint();
      return $sformatf("CONV[%s] attempt=%0d event=%0d src=%0d stop_model=%s delay=%0t arm_settle=%0t pulse_w=%0t start_only=%0b expect_packet=%0b accepted=%0b cfg_mode=%0d out=%0d conv_id_chk=%0b exp_conv_id=%0d",
                       label, attempt_id, event_id, source_sel, stop_model_name(stop_model),
                       start_stop_delay_ps, arm_settle_ps, pulse_width_ps, start_only, expect_packet, accepted,
                       cfg_mode, cfg_out_mode, check_conv_id, expected_conv_id);
    endfunction
  endclass

  class mptdc_eot_txn extends mptdc_base_txn;
    function new(string label_i = "eot");
      super.new(TXN_EOT, label_i);
    endfunction
  endclass

  class mptdc_hit_txn;
    logic [NSLOW_W-1:0]     nslow;
    logic [NFAST_W-1:0]     nfast_hit;
    logic [NFAST_W-1:0]     nfast_snap;
    ph_idx_t                ns;
    ph_idx_t                nf;
    stop_phase_disc_t       stop_phase_disc;
    pd_idx_t                pd_idx;
    logic [EVENT_SEQ_W-1:0] event_seq;
    logic [15:0]            t_raw_lsw;
    bit                     has_features;
    bit                     has_timestamp;

    function new();
      nslow         = '0;
      nfast_hit     = '0;
      nfast_snap    = '0;
      ns            = '0;
      nf            = '0;
      stop_phase_disc = '0;
      pd_idx        = '0;
      event_seq     = '0;
      t_raw_lsw     = '0;
      has_features  = 1'b0;
      has_timestamp = 1'b0;
    endfunction

    function string sprint();
      return $sformatf("hit nslow=%0d nfast=%0d ns=%0d nf=%0d stop_disc=%0d ts_lsw=0x%04h feat=%0b ts=%0b",
                       nslow, nfast_hit, ns, nf,
                       stop_phase_disc, t_raw_lsw, has_features, has_timestamp);
    endfunction
  endclass

  class mptdc_packet_txn extends mptdc_base_txn;
    ctx_id_t                ctx_id;
    bit                     phase0_snap;
    logic [MAX_HITS_W-1:0]  hit_count;
    tdc_conv_flags_t        flags;
    out_mode_e              out_mode;
    bit                     slow_boundary_inc;
    logic [13:0]            conv_id;
    logic [NARROW_W-1:0]    words[$];
    mptdc_hit_txn           hits[$];

    function new(string label_i = "packet");
      super.new(TXN_CONV, label_i);
      ctx_id            = '0;
      phase0_snap       = 1'b0;
      hit_count         = '0;
      flags             = '0;
      out_mode          = OUT_MODE_RAW_FEATURES;
      slow_boundary_inc = 1'b0;
      conv_id           = '0;
    endfunction

    function int unsigned word_count();
      return words.size();
    endfunction

    function string sprint();
      return $sformatf("PKT[%s] ctx=%0d hits=%0d out_mode=%0d flags=%04b conv_id=%0d words=%0d",
                       label, ctx_id, hit_count, out_mode, flags, conv_id, word_count());
    endfunction
  endclass

  // Shared mailboxes that bridge class-based sequencing to the
  // module-resident BFM loop inside mptdc_vip_tb.
  mailbox #(mptdc_base_txn) g_bfm_req_mb;
  mailbox #(bit)            g_bfm_ack_mb;   // 1=accepted, 0=rejected
  mailbox #(bit)            g_bfm_done_mb;  // 1=transaction fully completed
  mailbox #(logic [NARROW_W-1:0]) g_mon_word_mb;

  class mptdc_csr_driver;
    virtual mptdc_csr_if vif;

    function new(virtual mptdc_csr_if vif_i);
      vif = vif_i;
    endfunction

    task reset_signals();
      vif.reset_bus();
    endtask

    task write(input logic [CSR_ADDR_W-1:0] addr,
               input logic [CSR_DATA_W-1:0] data);
      vif.write_reg(addr, data);
    endtask

    task read(input logic [CSR_ADDR_W-1:0] addr,
              output logic [CSR_DATA_W-1:0] data);
      vif.read_reg(addr, data);
    endtask

    task program_cfg(input mptdc_cfg_txn cfg);
      write(CSR_MODE,       cfg.pack_mode_reg());
      write(CSR_MAX_HITS,   {28'd0, cfg.effective_max_hits()});
      write(CSR_WDT_CTX,    {16'd0, cfg.wdt_ctx_timeout});
      write(CSR_WDT_GLOBAL, {16'd0, cfg.wdt_global_timeout});
    endtask

    task arm_only();
      write(CSR_CTRL, 32'h0000_0001);
    endtask

    task fifo_clear();
      write(CSR_CTRL, 32'h0000_0002);
    endtask

    task soft_reset();
      write(CSR_CTRL, 32'h0000_0004);
    endtask

    task soft_reset_and_fifo_clear();
      write(CSR_CTRL, 32'h0000_0006);
    endtask
  endclass

  class mptdc_ready_driver;
    virtual mptdc_narrow_if vif;
    mptdc_bp_mode_e         mode;
    int unsigned            seed;
    int unsigned            rng_state;
    bit                     stop_request;

    function new(virtual mptdc_narrow_if vif_i);
      vif          = vif_i;
      mode         = BP_ALWAYS_READY;
      seed         = 32'hca11_ab1e;
      rng_state    = 32'hca11_ab1e;
      stop_request = 1'b0;
    endfunction

    function void set_mode(input mptdc_bp_mode_e mode_i,
                           input int unsigned seed_i = 32'hca11_ab1e);
      mode      = mode_i;
      seed      = seed_i;
      rng_state = seed_i;
    endfunction

    task run();
      vif.narrow_ready <= 1'b1;
      while (!stop_request) begin
        @(negedge vif.clk_sys);
        // Update READY in the NBA region so the monitor's negedge sampler
        // still observes the previous cycle's settled handshake state.
        case (mode)
          BP_ALWAYS_READY: vif.narrow_ready <= 1'b1;
          BP_RANDOM_50: begin
            rng_state = (rng_state * 32'h41C6_4E6D) + 32'h3039;
            vif.narrow_ready <= rng_state[0];
          end
          BP_ALWAYS_STALL: vif.narrow_ready <= 1'b0;
          BP_BOUNDED_STALL: begin
            rng_state = (rng_state * 32'h41C6_4E6D) + 32'h3039;
            vif.narrow_ready <= (rng_state[3:0] inside {[4'd0:4'd2]}) ? 1'b0 : 1'b1;
          end
          BP_SATURATION_RELEASE: begin
            rng_state = rng_state + 32'd1;
            vif.narrow_ready <= (rng_state[7:0] < 8'd192) ? 1'b0 : 1'b1;
          end
          default: vif.narrow_ready <= 1'b1;
        endcase
      end
      vif.narrow_ready <= 1'b1;
    endtask
  endclass

  class mptdc_pulse_driver;
    virtual mptdc_async_io_if vif;

    function new(virtual mptdc_async_io_if vif_i);
      vif = vif_i;
    endfunction

    task reset_signals();
      vif.reset_pulses();
    endtask

    task hard_reset(input time low_time_ps = 100_000,
                    input time settle_time_ps = 100_000);
      vif.hard_reset(low_time_ps, settle_time_ps);
    endtask

    task inject_pair(input input_sel_e source_sel,
                     input time delay_ps,
                     input time pulse_width_ps = 1_000);
      vif.inject_pair(source_sel, delay_ps, pulse_width_ps);
    endtask

    task inject_start_only(input input_sel_e source_sel,
                           input time pulse_width_ps = 1_000);
      vif.inject_start_only(source_sel, pulse_width_ps);
    endtask
  endclass

  class mptdc_generator;
    mailbox #(mptdc_base_txn) out_mb;
    mptdc_base_txn            txn_q[$];

    function new(mailbox #(mptdc_base_txn) out_mb_i);
      out_mb = out_mb_i;
    endfunction

    function void add(input mptdc_base_txn txn);
      txn_q.push_back(txn);
    endfunction

    function int expected_packet_count();
      int count = 0;
      mptdc_conv_txn conv;
      foreach (txn_q[i]) begin
        if ($cast(conv, txn_q[i]) && conv.expect_packet)
          count++;
      end
      return count;
    endfunction

    task run();
      mptdc_eot_txn eot;
      foreach (txn_q[i]) begin
        out_mb.put(txn_q[i]);
      end
      eot = new();
      out_mb.put(eot);
    endtask
  endclass

`ifdef MPTDC_ENABLE_FUNC_COV
  typedef int unsigned cov_hit_count_t;
  typedef int unsigned cov_delay_bin_t;
  typedef int unsigned cov_jitter_bin_t;
`endif

  class mptdc_coverage;
`ifdef MPTDC_ENABLE_FUNC_COV
    covergroup stim_cg with function sample(int mode_i,
                                             int src_i,
                                             int out_mode_i,
                                             int bp_mode_i,
                                             int stop_model_i,
                                             int max_hits_i,
                                             int delay_bin_i,
                                             int jitter_bin_i,
                                             int start_phase_sys_bin_i,
                                             int start_phase_ref_bin_i,
                                             int gap_bin_i,
                                             bit start_only_i,
                                             bit accepted_i);
      option.per_instance = 1;
      cp_mode: coverpoint mode_i { bins mh = {MODE_MULTI_HIT}; bins fast_close = {VIP_MODE_FAST_CLOSE}; }
      cp_src:  coverpoint src_i  { bins spad = {INPUT_SPAD}; bins cal = {INPUT_CAL}; }
      cp_out:  coverpoint out_mode_i {
        bins raw_features  = {OUT_MODE_RAW_FEATURES};
        bins raw_timestamp = {OUT_MODE_RAW_TIMESTAMP};
        bins full          = {OUT_MODE_FULL};
      }
      cp_bp: coverpoint bp_mode_i {
        bins rdy   = {BP_ALWAYS_READY};
        bins rnd   = {BP_RANDOM_50};
        bins stl   = {BP_ALWAYS_STALL};
        bins bnd   = {BP_BOUNDED_STALL};
        bins sat   = {BP_SATURATION_RELEASE};
      }
      cp_stop_model: coverpoint stop_model_i {
        bins direct_delay  = {STOP_DIRECT_DELAY};
        bins qualified_ref = {STOP_QUALIFIED_REF};
      }
      cp_max_hits_cfg: coverpoint max_hits_i {
        bins disabled = {0};
        bins one      = {1};
        bins two      = {2};
        bins eight    = {8};
        bins fifteen  = {15};
        bins other    = {[3:7], [9:14]};
      }
      cp_delay: coverpoint delay_bin_i {
        bins very_short = {0};
        bins short_d    = {1};
        bins medium_d   = {2};
        bins long_d     = {3};
      }
      cp_jitter: coverpoint jitter_bin_i {
        bins none  = {0};
        bins light = {1};
        bins heavy = {2};
      }
      cp_start_phase_sys: coverpoint start_phase_sys_bin_i { bins q[4] = {[0:3]}; }
      cp_start_phase_ref: coverpoint start_phase_ref_bin_i { bins q[4] = {[0:3]}; }
      cp_gap: coverpoint gap_bin_i {
        bins immediate = {0};
        bins short_gap = {1};
        bins target_10_20ns = {2};
        bins long_gap = {3};
      }
      cp_start_only: coverpoint start_only_i { bins no = {0}; bins yes = {1}; }
      cp_accepted: coverpoint accepted_i { bins rejected = {0}; bins accepted = {1}; }
      mode_x_out: cross cp_mode, cp_out;
      mode_x_delay: cross cp_mode, cp_delay;
      bp_x_delay: cross cp_bp, cp_delay;
      maxhits_x_bp: cross cp_max_hits_cfg, cp_bp;
      maxhits_x_stop_model: cross cp_max_hits_cfg, cp_stop_model;
      phase_x_stop: cross cp_start_phase_sys, cp_start_phase_ref, cp_stop_model;
      accepted_x_bp: cross cp_accepted, cp_bp;
    endgroup

    covergroup pkt_cg with function sample(int out_mode_i,
                                           int hit_count_i,
                                           bit fastclose_i,
                                           bit maxhits_i,
                                           bit watchdog_i,
                                            bit phase0_i,
                                            bit boundary_i,
                                            int stop_disc_i,
                                            int words_i,
                                            int ctx_id_i);
      option.per_instance = 1;
      cp_out: coverpoint out_mode_i {
        bins raw_features  = {OUT_MODE_RAW_FEATURES};
        bins raw_timestamp = {OUT_MODE_RAW_TIMESTAMP};
        bins full          = {OUT_MODE_FULL};
      }
      cp_hits: coverpoint hit_count_i {
        bins zero     = {0};
        bins one      = {1};
        bins few      = {[2:4]};
        bins several  = {[5:10]};
        bins many     = {[11:14]};
        bins maxed    = {15};
      }
      cp_fastclose: coverpoint fastclose_i { bins off = {0}; bins on = {1}; }
      cp_maxhits: coverpoint maxhits_i { bins off = {0}; bins on = {1}; }
      cp_watchdog: coverpoint watchdog_i { bins off = {0}; bins on = {1}; }
      cp_phase0: coverpoint phase0_i { bins low = {0}; bins high = {1}; }
      cp_boundary: coverpoint boundary_i { bins low = {0}; bins high = {1}; }
      cp_stop_disc: coverpoint stop_disc_i {
        bins all_states[] = {[0:7]};
        ignore_bins not_feature_word = {-1};
      }
      cp_words: coverpoint words_i;
      cp_ctx: coverpoint ctx_id_i { bins ctx0 = {0}; bins ctx1 = {1}; }
      flags_x_hits: cross cp_fastclose, cp_maxhits, cp_watchdog, cp_hits;
      out_x_boundary: cross cp_out, cp_boundary;
      out_x_stop_disc: cross cp_out, cp_stop_disc;
      ctx_x_out: cross cp_ctx, cp_out;
    endgroup
`endif

    function new();
`ifdef MPTDC_ENABLE_FUNC_COV
      stim_cg = new();
      pkt_cg  = new();
`endif
    endfunction

    function automatic int delay_bin(input time delay_ps);
      if (delay_ps <= 2_000)
        return 0;
      else if (delay_ps <= 10_000)
        return 1;
      else if (delay_ps <= 20_000)
        return 2;
      else
        return 3;
    endfunction

    function automatic int jitter_bin(input int sigma_ps);
      if (sigma_ps == 0)
        return 0;
      else if (sigma_ps <= 5)
        return 1;
      else
        return 2;
    endfunction

    function automatic int phase_bin(input int phase_ps, input int period_ps);
      if (period_ps <= 0)
        return 0;
      return (phase_ps * 4) / period_ps;
    endfunction

    function automatic int gap_bin(input time gap_ps);
      if (gap_ps <= 2_000)
        return 0;
      else if (gap_ps <= 10_000)
        return 1;
      else if (gap_ps <= 20_000)
        return 2;
      return 3;
    endfunction

    function void sample_stim(input mptdc_conv_txn txn,
                              input mptdc_bp_mode_e bp_mode,
                              input int jitter_sigma_ps);
`ifdef MPTDC_ENABLE_FUNC_COV
      stim_cg.sample(txn.cfg_mode, txn.source_sel, txn.cfg_out_mode,
                     bp_mode, txn.stop_model, txn.cfg_max_hits,
                     delay_bin(txn.start_stop_delay_ps),
                     jitter_bin(jitter_sigma_ps),
                     phase_bin(txn.start_phase_sys_ps, 6250),
                     phase_bin(txn.start_phase_ref_ps, 25000),
                     gap_bin(txn.idle_after_ps),
                     txn.start_only, txn.accepted);
`endif
    endfunction

    function void sample_packet(input mptdc_packet_txn pkt);
`ifdef MPTDC_ENABLE_FUNC_COV
      if (pkt.hits.size() == 0) begin
        pkt_cg.sample(pkt.out_mode, pkt.hit_count,
                      pkt.flags.closed_by_fast_maxhit,
                      pkt.flags.closed_by_maxhits,
                      pkt.flags.closed_by_watchdog,
                      pkt.phase0_snap,
                      pkt.slow_boundary_inc,
                      -1,
                      pkt.word_count(),
                      pkt.ctx_id);
      end else begin
        foreach (pkt.hits[i]) begin
          pkt_cg.sample(pkt.out_mode, pkt.hit_count,
                        pkt.flags.closed_by_fast_maxhit,
                        pkt.flags.closed_by_maxhits,
                        pkt.flags.closed_by_watchdog,
                        pkt.phase0_snap,
                        pkt.slow_boundary_inc,
                        pkt.hits[i].has_features ? int'(pkt.hits[i].stop_phase_disc) : -1,
                        pkt.word_count(),
                        pkt.ctx_id);
        end
      end
`endif
    endfunction
  endclass

  class mptdc_driver;
    mailbox #(mptdc_base_txn) in_mb;
    mailbox #(mptdc_conv_txn) exp_mb;
    mailbox #(mptdc_conv_txn) pending_conv_mb;
    mptdc_csr_driver          csr_drv;
    mptdc_pulse_driver        pulse_drv;
    mptdc_ready_driver        ready_drv;
    mptdc_cfg_txn             current_cfg;
    mptdc_coverage            cov;
    mptdc_env_cfg             env_cfg;
    bit                       done;
    bit                       routing_done;
    int                       rejected_count;
    int                       attempt_count;
    int                       accepted_event_count;
    int                       txn_csv_fd;
    int                       txn_jsonl_fd;

    function new(mailbox #(mptdc_base_txn) in_mb_i,
                 mailbox #(mptdc_conv_txn) exp_mb_i,
                 mptdc_csr_driver csr_drv_i,
                 mptdc_pulse_driver pulse_drv_i,
                 mptdc_ready_driver ready_drv_i,
                 mptdc_coverage cov_i,
                 mptdc_env_cfg env_cfg_i);
      in_mb       = in_mb_i;
      exp_mb      = exp_mb_i;
      csr_drv     = csr_drv_i;
      pulse_drv   = pulse_drv_i;
      ready_drv   = ready_drv_i;
      cov         = cov_i;
      env_cfg     = env_cfg_i;
      pending_conv_mb = new();
      current_cfg = new("current_cfg");
      done        = 1'b0;
      routing_done   = 1'b0;
      rejected_count = 0;
      attempt_count = 0;
      accepted_event_count = 0;
      txn_csv_fd = 0;
      txn_jsonl_fd = 0;
    endfunction

    task initialize();
      ready_drv.set_mode(BP_ALWAYS_READY, env_cfg.random_seed);
      if (g_bfm_req_mb == null)
        g_bfm_req_mb = new();
      if (g_bfm_ack_mb == null)
        g_bfm_ack_mb = new();
      if (g_bfm_done_mb == null)
        g_bfm_done_mb = new();
      if (env_cfg.txn_log_csv != "") begin
        txn_csv_fd = $fopen(env_cfg.txn_log_csv, "w");
        if (txn_csv_fd == 0)
          $fatal(1, "Failed to open transaction CSV log '%s'", env_cfg.txn_log_csv);
        $fwrite(txn_csv_fd,
          "schema_version,test_name,seed,attempt_id,event_id,label,source,stop_model,accepted,rejected,reject_reason,start_time_ps,stop_time_ps,true_dt_ps,start_phase_sys_ps,start_phase_ref_ps,ref_phase_offset_ps,max_hits,out_mode,bp_mode,start_only,expect_packet\n");
      end
      if (env_cfg.txn_log_jsonl != "") begin
        txn_jsonl_fd = $fopen(env_cfg.txn_log_jsonl, "w");
        if (txn_jsonl_fd == 0)
          $fatal(1, "Failed to open transaction JSONL log '%s'", env_cfg.txn_log_jsonl);
      end
    endtask

    task automatic log_conversion(input mptdc_conv_txn conv);
      if (txn_csv_fd != 0) begin
        $fwrite(txn_csv_fd,
          "1,%s,%0d,%0d,%0d,%s,%0d,%s,%0d,%0d,%s,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%s,%0d,%0d\n",
          env_cfg.test_name, env_cfg.random_seed, conv.attempt_id, conv.event_id,
          conv.label, conv.source_sel, stop_model_name(conv.stop_model),
          conv.accepted, conv.rejected, conv.reject_reason,
          conv.start_time_ps, conv.stop_time_ps, conv.true_dt_ps,
          conv.start_phase_sys_ps, conv.start_phase_ref_ps, conv.ref_phase_offset_ps,
          conv.cfg_max_hits, conv.cfg_out_mode, bp_mode_name(conv.bp_mode_at_issue),
          conv.start_only, conv.expect_packet);
      end
      if (txn_jsonl_fd != 0) begin
        $fwrite(txn_jsonl_fd,
          "{\"schema_version\":1,\"test_name\":\"%s\",\"seed\":%0d,\"attempt_id\":%0d,\"event_id\":%0d,\"label\":\"%s\",\"source\":%0d,\"stop_model\":\"%s\",\"accepted\":%0d,\"rejected\":%0d,\"reject_reason\":\"%s\",\"start_time_ps\":%0d,\"stop_time_ps\":%0d,\"true_dt_ps\":%0d,\"start_phase_sys_ps\":%0d,\"start_phase_ref_ps\":%0d,\"ref_phase_offset_ps\":%0d,\"max_hits\":%0d,\"out_mode\":%0d,\"bp_mode\":\"%s\",\"start_only\":%0d,\"expect_packet\":%0d}\n",
          env_cfg.test_name, env_cfg.random_seed, conv.attempt_id, conv.event_id,
          conv.label, conv.source_sel, stop_model_name(conv.stop_model),
          conv.accepted, conv.rejected, conv.reject_reason,
          conv.start_time_ps, conv.stop_time_ps, conv.true_dt_ps,
          conv.start_phase_sys_ps, conv.start_phase_ref_ps, conv.ref_phase_offset_ps,
          conv.cfg_max_hits, conv.cfg_out_mode, bp_mode_name(conv.bp_mode_at_issue),
          conv.start_only, conv.expect_packet);
      end
    endtask

    task route_expectations();
      mptdc_conv_txn conv;
      bit            accepted;
      forever begin
        pending_conv_mb.get(conv);
        if (conv == null)
          break;

        g_bfm_ack_mb.get(accepted);
        if (conv.expect_packet) begin
          if (accepted)
            exp_mb.put(conv.clone());
          else
            rejected_count++;
        end
      end
      exp_mb.put(null);
      routing_done = 1'b1;
    endtask

    task run();
      mptdc_base_txn         base;
      mptdc_cfg_txn          cfg;
      mptdc_backpressure_txn bp;
      mptdc_reset_txn        rst;
      mptdc_conv_txn         conv;
      bit                    accepted;
      bit                    txn_done;
      initialize();
      forever begin
        in_mb.get(base);
        if (base == null)
          continue;

        case (base.kind)
          TXN_RESET: begin
            if (!$cast(rst, base))
              $fatal(1, "Failed to cast reset txn");
            $display("[VIP][DRV] %s", rst.sprint());
            g_bfm_req_mb.put(base);
            g_bfm_done_mb.get(txn_done);
          end

          TXN_CFG: begin
            if (!$cast(cfg, base))
              $fatal(1, "Failed to cast cfg txn");
            $display("[VIP][DRV] %s", cfg.sprint());
            g_bfm_req_mb.put(base);
            g_bfm_done_mb.get(txn_done);
            current_cfg = cfg.clone();
            current_cfg.max_hits = current_cfg.effective_max_hits();
            current_cfg.mode_cfg = current_cfg.effective_mode_cfg();
          end

          TXN_BP: begin
            if (!$cast(bp, base))
              $fatal(1, "Failed to cast backpressure txn");
            $display("[VIP][DRV] %s", bp.sprint());
            ready_drv.set_mode(bp.mode, bp.random_seed);
          end

          TXN_CONV: begin
            if (!$cast(conv, base))
              $fatal(1, "Failed to cast conv txn");
            conv.attempt_id     = attempt_count;
            conv.event_id       = -1;
            conv.accepted       = 1'b0;
            conv.rejected       = 1'b0;
            conv.reject_reason  = "pending";
            conv.stop_model     = env_cfg.stop_model;
            conv.ref_phase_offset_ps = env_cfg.ref_phase_offset_ps;
            conv.bp_mode_at_issue = ready_drv.mode;
            conv.cfg_mode      = current_cfg.mode_cfg;
            conv.cfg_input_sel = current_cfg.input_sel;
            conv.cfg_out_mode  = current_cfg.out_mode;
            conv.cfg_max_hits  = current_cfg.max_hits;
            $display("[VIP][DRV] %s", conv.sprint());

            g_bfm_req_mb.put(base);
            g_bfm_ack_mb.get(accepted);
            conv.accepted = accepted;
            conv.rejected = !accepted;
            conv.reject_reason = accepted ? "none" : "not_ready_or_context_saturated";
            if (conv.expect_packet) begin
              if (accepted) begin
                conv.event_id = accepted_event_count;
                accepted_event_count++;
                exp_mb.put(conv.clone());
              end else begin
                rejected_count++;
              end
            end
            cov.sample_stim(conv, ready_drv.mode, env_cfg.osc_jitter_sigma_ps);
            log_conversion(conv);
            attempt_count++;
            g_bfm_done_mb.get(txn_done);
          end

          TXN_EOT: begin
            $display("[VIP][DRV] End-of-test transaction observed");
            exp_mb.put(null);
            if (rejected_count > 0)
              $display("[VIP][DRV] %0d conversions had START rejected (FIFO backpressure)", rejected_count);
            if (txn_csv_fd != 0)
              $fclose(txn_csv_fd);
            if (txn_jsonl_fd != 0)
              $fclose(txn_jsonl_fd);
            done = 1'b1;
            break;
          end

          default: $fatal(1, "Unknown transaction kind %0d", base.kind);
        endcase
      end
    endtask
  endclass

  class mptdc_output_monitor;
    virtual mptdc_narrow_if    vif;
    mailbox #(mptdc_packet_txn) out_mb;
    bit                        stop_request;

    function new(virtual mptdc_narrow_if vif_i,
                 mailbox #(mptdc_packet_txn) out_mb_i);
      vif          = vif_i;
      out_mb       = out_mb_i;
      stop_request = 1'b0;
      if (g_mon_word_mb == null)
        g_mon_word_mb = new();
    endfunction

    task automatic wait_accept(output logic [NARROW_W-1:0] word);
      while (!stop_request) begin
        if (g_mon_word_mb.try_get(word))
          return;
        @(posedge vif.clk_sys);
      end
      word = '0;
    endtask

    // Expand the accepted narrow words into typed hit records using the
    // header-declared out_mode and hit_count contract.
    function automatic void parse_packet(ref mptdc_packet_txn pkt);
      logic [NARROW_W-1:0] hdr;
      int unsigned         idx;
      hdr = pkt.words[0];
      pkt.ctx_id            = packet_ctx_id(hdr);
      pkt.phase0_snap       = packet_phase0(hdr);
      pkt.hit_count         = packet_hit_count(hdr);
      pkt.flags             = packet_flags(hdr);
      pkt.out_mode          = packet_out_mode(hdr);
      pkt.slow_boundary_inc = packet_boundary_inc(hdr);
      pkt.conv_id           = packet_conv_id(pkt.words[pkt.words.size()-1]);

      idx = 1;
      for (int hit_idx = 0; hit_idx < pkt.hit_count; hit_idx++) begin
        mptdc_hit_txn hit = new();
        logic [NARROW_W-1:0] w0;
        w0 = pkt.words[idx];
        hit.nslow     = w0[14:8];
        hit.nfast_hit = w0[7:1];
        idx++;

        case (pkt.out_mode)
          OUT_MODE_RAW_FEATURES: begin
            logic [NARROW_W-1:0] w1;
            w1 = pkt.words[idx + 0];
            hit.ns           = ph_idx_t'(w1[14:11]);
            hit.nf           = ph_idx_t'(w1[10:7]);
            hit.stop_phase_disc = packet_stop_phase_disc(w1);
            hit.has_features = 1'b1;
            idx += 1;
          end

          OUT_MODE_RAW_TIMESTAMP: begin
            hit.t_raw_lsw     = pkt.words[idx];
            hit.has_timestamp = 1'b1;
            idx += 1;
          end

          OUT_MODE_FULL: begin
            logic [NARROW_W-1:0] w1;
            w1 = pkt.words[idx + 0];
            hit.ns            = ph_idx_t'(w1[14:11]);
            hit.nf            = ph_idx_t'(w1[10:7]);
            hit.stop_phase_disc = packet_stop_phase_disc(w1);
            hit.t_raw_lsw     = pkt.words[idx + 1];
            hit.has_features  = 1'b1;
            hit.has_timestamp = 1'b1;
            idx += 2;
          end

          default: begin
            idx += 1;
          end
        endcase
        pkt.hits.push_back(hit);
      end
    endfunction

    task run();
      logic [NARROW_W-1:0] word;
      forever begin
        mptdc_packet_txn pkt;
        int unsigned     expected_words;
        wait_accept(word);
        if (stop_request)
          break;
        if (!is_header_word(word))
          continue;

        pkt = new("packet");
        pkt.words.push_back(word);
        expected_words = packet_words_from_header(word);
        while (pkt.words.size() < expected_words) begin
          wait_accept(word);
          if (stop_request)
            break;
          pkt.words.push_back(word);
        end

        if (pkt.words.size() != expected_words) begin
          $error("[VIP][MON] Incomplete packet captured: expected %0d got %0d",
                 expected_words, pkt.words.size());
          continue;
        end
        if (!is_eoc_word(pkt.words[pkt.words.size()-1])) begin
          $error("[VIP][MON] Final packet word is not EOC: 0x%04h",
                 pkt.words[pkt.words.size()-1]);
          continue;
        end

        parse_packet(pkt);
        out_mb.put(pkt);
      end
    endtask
  endclass

  class mptdc_scoreboard;
    mailbox #(mptdc_conv_txn)   exp_mb;
    mailbox #(mptdc_packet_txn) act_mb;
    mptdc_coverage              cov;
    int                         error_count;
    bit                         done;

    function new(mailbox #(mptdc_conv_txn) exp_mb_i,
                 mailbox #(mptdc_packet_txn) act_mb_i,
                 mptdc_coverage cov_i);
      exp_mb      = exp_mb_i;
      act_mb      = act_mb_i;
      cov         = cov_i;
      error_count = 0;
      done        = 1'b0;
    endfunction

    function void fail(input string msg);
      error_count++;
      $error("[VIP][SB] %s", msg);
    endfunction

    function automatic void check_full_timestamp(input mptdc_packet_txn pkt);
      foreach (pkt.hits[i]) begin
        logic signed [31:0] expected_ps;
        logic [15:0]        expected_lsw;
        if (pkt.hits[i].has_features && pkt.hits[i].has_timestamp) begin
          expected_ps  = vernier_tconv_ps(pkt.hits[i].nslow,
                                          pkt.hits[i].nfast_hit,
                                          pkt.hits[i].ns,
                                          pkt.hits[i].nf,
                                          pkt.slow_boundary_inc);
          expected_lsw = expected_ps[15:0];
          if (pkt.hits[i].t_raw_lsw !== expected_lsw) begin
            fail($sformatf("FULL timestamp mismatch hit %0d: expected 0x%04h got 0x%04h",
                           i, expected_lsw, pkt.hits[i].t_raw_lsw));
          end
        end
      end
    endfunction

    // Check contract-level packet semantics only; analog performance trends
    // belong in the dedicated data-collection benches, not the VIP scoreboard.
    function automatic void check_packet(input mptdc_conv_txn exp,
                                         input mptdc_packet_txn pkt);
      int unsigned expected_words;
      expected_words = 2 + (pkt.hit_count * words_per_hit(pkt.out_mode));
      if (pkt.word_count() != expected_words)
        fail($sformatf("%s word count mismatch: got %0d expected %0d",
                       exp.label, pkt.word_count(), expected_words));

      if (pkt.hits.size() != pkt.hit_count)
        fail($sformatf("%s hit decode mismatch: header=%0d decoded=%0d",
                       exp.label, pkt.hit_count, pkt.hits.size()));

      if (exp.check_out_mode && pkt.out_mode != exp.cfg_out_mode)
        fail($sformatf("%s out_mode mismatch: got %0d expected %0d",
                       exp.label, pkt.out_mode, exp.cfg_out_mode));

      if (exp.require_nonzero_hits && (pkt.hit_count == 0))
        fail($sformatf("%s expected non-zero hits", exp.label));

      if (exp.check_hit_range) begin
        if ((pkt.hit_count < exp.min_hits) || (pkt.hit_count > exp.max_hits_allowed))
          fail($sformatf("%s hit count %0d outside [%0d:%0d]",
                         exp.label, pkt.hit_count, exp.min_hits, exp.max_hits_allowed));
      end

      if (exp.check_firsthit_flag && (pkt.flags.closed_by_fast_maxhit != exp.expected_firsthit_flag))
        fail($sformatf("%s fast-close flag mismatch got=%0b exp=%0b",
                       exp.label, pkt.flags.closed_by_fast_maxhit, exp.expected_firsthit_flag));

      if (exp.check_maxhits_flag && (pkt.flags.closed_by_maxhits != exp.expected_maxhits_flag))
        fail($sformatf("%s maxhits flag mismatch got=%0b exp=%0b",
                       exp.label, pkt.flags.closed_by_maxhits, exp.expected_maxhits_flag));

      if (exp.check_watchdog_flag && (pkt.flags.closed_by_watchdog != exp.expected_watchdog_flag))
        fail($sformatf("%s watchdog flag mismatch got=%0b exp=%0b",
                       exp.label, pkt.flags.closed_by_watchdog, exp.expected_watchdog_flag));

      if (exp.check_conv_id && (int'(pkt.conv_id) != exp.expected_conv_id))
        fail($sformatf("%s conv_id mismatch: got=%0d expected=%0d",
                       exp.label, pkt.conv_id, exp.expected_conv_id));

      if (exp.check_full_timestamp && (pkt.out_mode == OUT_MODE_FULL))
        check_full_timestamp(pkt);

      cov.sample_packet(pkt);
      $display("[VIP][SB] PASS %s -> %s", exp.sprint(), pkt.sprint());
    endfunction

    task run();
      mptdc_conv_txn   exp;
      mptdc_packet_txn pkt;
      int              count;
      count = 0;
      forever begin
        exp_mb.get(exp);
        if (exp == null) break;   // sentinel from driver — all conversions processed
        act_mb.get(pkt);
        check_packet(exp, pkt);
        count++;
      end
      $display("[VIP][SB] Scoreboard done: %0d packets checked", count);
      done = 1'b1;
    endtask
  endclass

  class mptdc_env;
    mptdc_env_cfg                 cfg;
    mailbox #(mptdc_base_txn)     gen2drv_mb;
    mailbox #(mptdc_conv_txn)     exp_mb;
    mailbox #(mptdc_packet_txn)   act_mb;
    mptdc_generator               gen;
    mptdc_csr_driver              csr_drv;
    mptdc_pulse_driver            pulse_drv;
    mptdc_ready_driver            ready_drv;
    mptdc_coverage                cov;
    mptdc_driver                  drv;
    mptdc_output_monitor          mon;
    mptdc_scoreboard              sb;

    function new(virtual mptdc_csr_if csr_vif,
                 virtual mptdc_async_io_if async_vif,
                 virtual mptdc_narrow_if narrow_vif,
                 mptdc_env_cfg cfg_i);
      cfg        = cfg_i;
      gen2drv_mb = new();
      exp_mb     = new();
      act_mb     = new();
      gen        = new(gen2drv_mb);
      csr_drv    = new(csr_vif);
      pulse_drv  = new(async_vif);
      ready_drv  = new(narrow_vif);
      cov        = new();
      drv        = new(gen2drv_mb, exp_mb, csr_drv, pulse_drv, ready_drv, cov, cfg);
      mon        = new(narrow_vif, act_mb);
      sb         = new(exp_mb, act_mb, cov);
    endfunction

    task run();
      // The ready driver and monitor stay alive in the background while the
      // generator, driver, and scoreboard complete the planned test sequence.
      fork
        ready_drv.run();
        mon.run();
      join_none

      fork
        gen.run();
        drv.run();
        sb.run();
      join

      mon.stop_request      = 1'b1;
      ready_drv.stop_request = 1'b1;
      #10_000;
    endtask
  endclass

  class mptdc_base_test;
    string                   test_name;
    mptdc_env_cfg            cfg;
    mptdc_env                env;
    virtual mptdc_csr_if     csr_vif;
    virtual mptdc_async_io_if async_vif;
    virtual mptdc_narrow_if  narrow_vif;

    function new(string name_i = "mptdc_base_test");
      test_name = name_i;
      cfg       = new();
      cfg.test_name = name_i;
    endfunction

    function void set_vifs(virtual mptdc_csr_if csr_vif_i,
                           virtual mptdc_async_io_if async_vif_i,
                           virtual mptdc_narrow_if narrow_vif_i);
      csr_vif   = csr_vif_i;
      async_vif = async_vif_i;
      narrow_vif = narrow_vif_i;
    endfunction

    function mptdc_reset_txn make_reset(string label = "reset");
      mptdc_reset_txn rst = new(label);
      return rst;
    endfunction

    function mptdc_cfg_txn make_cfg(string label = "cfg");
      mptdc_cfg_txn cfg_txn = new(label);
      return cfg_txn;
    endfunction

    function mptdc_backpressure_txn make_bp(string label = "bp",
                                            mptdc_bp_mode_e mode = BP_ALWAYS_READY,
                                            int unsigned seed = 32'h1234_5678);
      mptdc_backpressure_txn bp = new(label);
      bp.mode        = mode;
      bp.random_seed = seed;
      return bp;
    endfunction

    function mptdc_conv_txn make_conv(string label = "conv");
      mptdc_conv_txn conv = new(label);
      return conv;
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
    endfunction

    virtual task post_run();
    endtask

    task run();
      if ((csr_vif == null) || (async_vif == null) || (narrow_vif == null))
        $fatal(1, "Virtual interfaces not configured for %s", test_name);
      env = new(csr_vif, async_vif, narrow_vif, cfg);
      build_sequence(env.gen);
      env.run();
      post_run();
      if (env.sb.error_count != 0)
        $fatal(1, "TEST %s FAILED with %0d scoreboard errors", test_name, env.sb.error_count);
      $display("[VIP][TEST] %s PASSED", test_name);
    endtask
  endclass

  class mptdc_smoke_single_conv_test extends mptdc_base_test;
    function new();
      super.new("smoke_single_conv");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      gen.add(make_reset());
      cfg_txn = make_cfg("cfg_smoke");
      gen.add(cfg_txn);
      gen.add(make_bp("bp_ready", BP_ALWAYS_READY, cfg.random_seed));
      conv = make_conv("conv_smoke");
      conv.source_sel           = INPUT_SPAD;
      conv.start_stop_delay_ps  = 10_000;
      conv.require_nonzero_hits = 1'b1;
      conv.min_hits             = 1;
      conv.max_hits_allowed     = MAX_HITS;
      gen.add(conv);
    endfunction
  endclass

  class mptdc_full_mode_timestamp_test extends mptdc_base_test;
    function new();
      super.new("full_mode_timestamp");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      gen.add(make_reset());
      cfg_txn = make_cfg("cfg_full");
      cfg_txn.out_mode = OUT_MODE_FULL;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_ready", BP_ALWAYS_READY, cfg.random_seed));
      conv = make_conv("conv_full");
      conv.start_stop_delay_ps  = 15_000;
      conv.require_nonzero_hits = 1'b1;
      conv.min_hits             = 1;
      conv.check_full_timestamp = 1'b1;
      gen.add(conv);
    endfunction
  endclass

  class mptdc_firsthit_contract_test extends mptdc_base_test;
    function new();
      super.new("firsthit_contract");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      int delays_ps[3] = '{5_000, 11_000, 23_000};
      gen.add(make_reset());
      cfg_txn = make_cfg("cfg_firsthit");
      cfg_txn.mode_cfg        = VIP_MODE_FAST_CLOSE;
      cfg_txn.wdt_ctx_timeout = 16'hFFFF;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_ready", BP_ALWAYS_READY, cfg.random_seed));
      foreach (delays_ps[i]) begin
        conv = make_conv($sformatf("firsthit_%0d", i));
        conv.start_stop_delay_ps   = delays_ps[i];
        conv.require_nonzero_hits  = 1'b1;
        conv.min_hits              = 1;
        conv.check_firsthit_flag   = 1'b1;
        conv.expected_firsthit_flag = 1'b1;
        gen.add(conv);
      end
    endfunction
  endclass

  class mptdc_backpressure_integrity_test extends mptdc_base_test;
    function new();
      super.new("backpressure_integrity");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      gen.add(make_reset());
      cfg_txn = make_cfg("cfg_bp");
      gen.add(cfg_txn);
      gen.add(make_bp("bp_rand", BP_RANDOM_50, 32'h55aa_1234));
      conv = make_conv("bp_rand_conv");
      conv.start_stop_delay_ps = 10_000;
      conv.min_hits            = 1;
      conv.require_nonzero_hits = 1'b1;
      gen.add(conv);
      gen.add(make_bp("bp_stall", BP_ALWAYS_STALL, cfg.random_seed));
      conv = make_conv("bp_stall_conv0");
      conv.start_stop_delay_ps  = 10_000;
      conv.idle_after_ps        = 5_000_000;
      conv.min_hits             = 1;
      conv.require_nonzero_hits = 1'b1;
      gen.add(conv);
      conv = make_conv("bp_stall_conv1");
      conv.start_stop_delay_ps  = 10_000;
      conv.idle_after_ps        = 5_000_000;
      conv.min_hits             = 1;
      conv.require_nonzero_hits = 1'b1;
      gen.add(conv);
      gen.add(make_bp("bp_release", BP_ALWAYS_READY, cfg.random_seed));
    endfunction
  endclass

  class mptdc_start_watchdog_test extends mptdc_base_test;
    function new();
      super.new("start_watchdog");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      gen.add(make_reset());
      cfg_txn = make_cfg("cfg_start_wdt");
      cfg_txn.max_hits           = '0;
      cfg_txn.wdt_ctx_timeout    = 16'd100;
      cfg_txn.wdt_global_timeout = 16'd10000;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_ready", BP_ALWAYS_READY, cfg.random_seed));
      conv = make_conv("start_only_wdt");
      conv.start_only            = 1'b1;
      conv.check_watchdog_flag   = 1'b1;
      conv.expected_watchdog_flag = 1'b1;
      conv.check_hit_range       = 1'b0;
      // Keep the recovery reconfiguration from racing the watchdog-forced
      // close of the START-only conversion.
      conv.idle_after_ps         = 5_000_000;
      gen.add(conv);

      cfg_txn = make_cfg("cfg_recovery");
      cfg_txn.max_hits        = MAX_HITS_W'(MAX_HITS);
      cfg_txn.wdt_ctx_timeout = 16'hFFFF;
      gen.add(cfg_txn);
      conv = make_conv("recovery_conv");
      conv.start_stop_delay_ps   = 10_000;
      conv.check_watchdog_flag   = 1'b1;
      conv.expected_watchdog_flag = 1'b0;
      conv.require_nonzero_hits  = 1'b1;
      conv.min_hits              = 1;
      gen.add(conv);
    endfunction
  endclass

  class mptdc_cal_inject_test extends mptdc_base_test;
    function new();
      super.new("cal_inject");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      gen.add(make_reset());
      cfg_txn = make_cfg("cfg_cal");
      cfg_txn.input_sel = INPUT_CAL;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_ready", BP_ALWAYS_READY, cfg.random_seed));
      conv = make_conv("cal_conv");
      conv.source_sel           = INPUT_CAL;
      conv.start_stop_delay_ps  = 12_000;
      conv.require_nonzero_hits = 1'b1;
      conv.min_hits             = 1;
      gen.add(conv);
    endfunction
  endclass

  class mptdc_overflow_status_test extends mptdc_base_test;
    logic [CSR_DATA_W-1:0] ovf_count_data;
    logic [CSR_DATA_W-1:0] status_data;
    logic [CSR_DATA_W-1:0] ctrl_data;

    function new();
      super.new("overflow_status");
      ovf_count_data = '0;
      status_data    = '0;
      ctrl_data      = '0;
    endfunction

    task automatic wait_for_ctx_state(input logic [1:0] ctx0_expected,
                                      input logic [1:0] ctx1_expected,
                                      input int unsigned max_polls = 32);
      logic [CSR_DATA_W-1:0] poll_status;
      for (int unsigned poll = 0; poll < max_polls; poll++) begin
        env.csr_drv.read(CSR_STATUS, poll_status);
        if ((poll_status[3:2] == ctx0_expected) && (poll_status[5:4] == ctx1_expected))
          return;
        #20_000;
      end
      env.sb.fail($sformatf("overflow_status timed out waiting for ctx states {%0d,%0d}",
                            ctx0_expected, ctx1_expected));
    endtask

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      gen.add(make_reset());
      cfg_txn = make_cfg("cfg_ovf");
      cfg_txn.mode_cfg           = MODE_MULTI_HIT;
      cfg_txn.input_sel          = INPUT_SPAD;
      cfg_txn.out_mode           = OUT_MODE_FULL;
      cfg_txn.max_hits           = MAX_HITS_W'(15);
      cfg_txn.wdt_ctx_timeout    = 16'd0;
      cfg_txn.wdt_global_timeout = 16'd0;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_ready", BP_ALWAYS_READY, cfg.random_seed));
    endfunction

    virtual task post_run();
      csr_vif.csr_valid = 1'b0;
      csr_vif.csr_write = 1'b0;
      narrow_vif.narrow_ready = 1'b1;
      #200_000;

      env.csr_drv.read(CSR_OVF_COUNT, ovf_count_data);
      if (ovf_count_data[15:0] != 16'd0)
        env.sb.fail($sformatf("overflow_status expected OVF_COUNT reset baseline 0, got %0d",
                              ovf_count_data[15:0]));

      // Keep the smoke test focused on the architectural rejected-START
      // counter.  Context-draining state can be too brief for a portable
      // polling test because FIFO_DEPTH=64 can absorb two full packets.
      env.csr_drv.arm_only();
      #20_000;
      async_vif.inject_start_only(INPUT_SPAD, 1_000);
      #50_000;
      env.csr_drv.read(CSR_STATUS, status_data);
      if (status_data[1] !== 1'b1)
        env.sb.fail($sformatf("overflow_status expected busy=1 after held START, got status=0x%08h",
                              status_data));

      // A second START while the first START owns the frontend must be safely
      // rejected and counted once without corrupting the active context.
      env.csr_drv.arm_only();
      #20_000;
      async_vif.inject_start_only(INPUT_SPAD, 1_000);
      #200_000;

      env.csr_drv.read(CSR_OVF_COUNT, ovf_count_data);
      if (ovf_count_data[15:0] != 16'd1)
        env.sb.fail($sformatf("overflow_status expected exactly one rejected START, got OVF_COUNT=%0d",
                              ovf_count_data[15:0]));

      env.csr_drv.soft_reset_and_fifo_clear();
      #200_000;

      env.csr_drv.read(CSR_CTRL, ctrl_data);
      if (ctrl_data[0] !== 1'b0)
        env.sb.fail("overflow_status recovery expected conv_arm=0 after combined reset");

      env.csr_drv.read(CSR_STATUS, status_data);
      if ((status_data[0] !== 1'b0) || (status_data[1] !== 1'b0))
        env.sb.fail($sformatf("overflow_status recovery expected ready=0,busy=0 after reset, got status=0x%08h",
                              status_data));

      env.csr_drv.read(CSR_OVF_COUNT, ovf_count_data);
      if (ovf_count_data[15:0] != 16'd0)
        env.sb.fail($sformatf("overflow_status recovery expected OVF_COUNT reset to 0, got %0d",
                              ovf_count_data[15:0]));
    endtask
  endclass

  class mptdc_long_random_test extends mptdc_base_test;
    function new();
      super.new("long_random");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      gen.add(make_reset());
      cfg_txn = make_cfg("cfg_random");
      cfg_txn.out_mode = OUT_MODE_FULL;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_random", BP_RANDOM_50, cfg.random_seed));
      for (int i = 0; i < 8; i++) begin
        conv = make_conv($sformatf("rand_conv_%0d", i));
        conv.start_stop_delay_ps = 2_000 + (($urandom(cfg.random_seed) % 20) * 1_000);
        conv.idle_after_ps       = 5_000_000;
        conv.require_nonzero_hits = 1'b1;
        conv.min_hits             = 1;
        conv.check_full_timestamp = 1'b1;
        gen.add(conv);
      end
      gen.add(make_bp("bp_ready_done", BP_ALWAYS_READY, cfg.random_seed));
    endfunction
  endclass

  class mptdc_multi_conv_rearm_stress_test extends mptdc_base_test;
    function new();
      super.new("multi_conv_rearm_stress");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      int delays_ps[6] = '{5_000, 8_000, 11_000, 14_000, 18_000, 24_000};
      gen.add(make_reset());

      cfg_txn = make_cfg("cfg_multi_conv_stress");
      gen.add(cfg_txn);
      gen.add(make_bp("bp_ready", BP_ALWAYS_READY, cfg.random_seed));

      for (int i = 0; i < 8; i++) begin
        conv = make_conv($sformatf("stress_conv_%0d", i));
        conv.start_stop_delay_ps  = delays_ps[i % 6];
        conv.arm_settle_ps        = 50_000;
        conv.idle_after_ps        = (i == 7) ? 3_000_000 : 125_000;
        conv.require_nonzero_hits = 1'b1;
        conv.min_hits             = 1;
        conv.check_conv_id        = 1'b1;
        conv.expected_conv_id     = i;
        gen.add(conv);
      end

      cfg_txn = make_cfg("cfg_firsthit_rearm");
      cfg_txn.mode_cfg        = VIP_MODE_FAST_CLOSE;
      cfg_txn.out_mode        = OUT_MODE_RAW_TIMESTAMP;
      cfg_txn.wdt_ctx_timeout = 16'hFFFF;
      gen.add(cfg_txn);

      for (int i = 0; i < 4; i++) begin
        conv = make_conv($sformatf("rearm_conv_%0d", i));
        conv.start_stop_delay_ps    = delays_ps[i];
        conv.arm_settle_ps          = 0;
        conv.idle_after_ps          = 250_000;
        conv.require_nonzero_hits   = 1'b1;
        conv.min_hits               = 1;
        conv.check_firsthit_flag    = 1'b1;
        conv.expected_firsthit_flag = 1'b1;
        conv.check_conv_id          = 1'b1;
        conv.expected_conv_id       = 8 + i;
        gen.add(conv);
      end
    endfunction
  endclass

  class mptdc_global_watchdog_recovery_test extends mptdc_base_test;
    logic [CSR_DATA_W-1:0] wdt_status_data;

    function new();
      super.new("global_watchdog_recovery");
      wdt_status_data = '0;
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      gen.add(make_reset());

      cfg_txn = make_cfg("cfg_global_trip");
      cfg_txn.max_hits           = '0;
      cfg_txn.wdt_ctx_timeout    = 16'hFFFF;
      cfg_txn.wdt_global_timeout = 16'd128;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_ready", BP_ALWAYS_READY, cfg.random_seed));

      conv = make_conv("global_trip_start_only");
      conv.start_only       = 1'b1;
      conv.expect_packet    = 1'b0;
      conv.check_hit_range  = 1'b0;
      conv.arm_settle_ps    = 0;
      conv.idle_after_ps    = 5_000_000;
      gen.add(conv);

      cfg_txn = make_cfg("cfg_global_recovery");
      cfg_txn.wdt_ctx_timeout    = 16'hFFFF;
      cfg_txn.wdt_global_timeout = 16'd0;
      gen.add(cfg_txn);

      conv = make_conv("global_wdt_recovery_probe");
      conv.start_stop_delay_ps    = 10_000;
      conv.arm_settle_ps          = 200_000;
      conv.check_hit_range        = 1'b0;
      conv.check_watchdog_flag    = 1'b0;
      conv.check_conv_id          = 1'b1;
      conv.expected_conv_id       = 0;
      gen.add(conv);

      conv = make_conv("global_wdt_recovery_confirm");
      conv.start_stop_delay_ps    = 18_000;
      conv.arm_settle_ps          = 200_000;
      conv.idle_after_ps          = 2_000_000;
      conv.require_nonzero_hits   = 1'b1;
      conv.min_hits               = 1;
      conv.check_watchdog_flag    = 1'b1;
      conv.expected_watchdog_flag = 1'b0;
      conv.check_conv_id          = 1'b1;
      conv.expected_conv_id       = 1;
      gen.add(conv);
    endfunction

    virtual task post_run();
      csr_vif.csr_valid = 1'b0;
      csr_vif.csr_write = 1'b0;
      #100_000;
      env.csr_drv.read(CSR_WDT_STATUS, wdt_status_data);
      if (wdt_status_data[7:0] == 0)
        env.sb.fail("global_watchdog_recovery expected CSR_WDT_STATUS global trip count > 0");
      else
        $display("[VIP][TEST] global_watchdog_recovery WDT_STATUS global_trip_cnt=%0d",
                 wdt_status_data[7:0]);
    endtask
  endclass

  class mptdc_jitter_robustness_test extends mptdc_base_test;
    function new();
      super.new("jitter_robustness");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      int delays_ps[6] = '{4_000, 8_000, 11_000, 17_000, 24_000, 31_000};
      if (cfg.osc_jitter_sigma_ps <= 0)
        $fatal(1, "jitter_robustness requires +OSC_JITTER_SIGMA_PS > 0");

      gen.add(make_reset());
      cfg_txn = make_cfg("cfg_jitter");
      cfg_txn.out_mode = OUT_MODE_FULL;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_ready", BP_ALWAYS_READY, cfg.random_seed));
      for (int i = 0; i < 6; i++) begin
        conv = make_conv($sformatf("jitter_conv_%0d", i));
        conv.start_stop_delay_ps  = delays_ps[i];
        conv.arm_settle_ps        = 0;
        conv.idle_after_ps        = 500_000;
        conv.require_nonzero_hits = 1'b1;
        conv.min_hits             = 1;
        conv.check_full_timestamp = 1'b1;
        conv.check_conv_id        = 1'b1;
        conv.expected_conv_id     = i;
        gen.add(conv);
      end
    endfunction
  endclass

  class mptdc_csr_readback_control_test extends mptdc_base_test;
    logic [CSR_DATA_W-1:0] expected_mode_data;
    logic [CSR_DATA_W-1:0] expected_max_hits_data;
    logic [CSR_DATA_W-1:0] expected_wdt_ctx_data;
    logic [CSR_DATA_W-1:0] expected_wdt_global_data;
    int                    expected_conv_count;

    function new();
      super.new("csr_readback_control");
      expected_mode_data       = '0;
      expected_max_hits_data   = '0;
      expected_wdt_ctx_data    = '0;
      expected_wdt_global_data = '0;
      expected_conv_count      = 0;
    endfunction

    task automatic expect_reg_eq(input string label,
                                 input logic [CSR_ADDR_W-1:0] addr,
                                 input logic [CSR_DATA_W-1:0] expected,
                                 input logic [CSR_DATA_W-1:0] mask = {CSR_DATA_W{1'b1}});
      logic [CSR_DATA_W-1:0] actual;
      env.csr_drv.read(addr, actual);
      if ((actual & mask) !== (expected & mask)) begin
        env.sb.fail($sformatf("%s mismatch: got 0x%08h expected 0x%08h mask 0x%08h",
                              label, actual, expected, mask));
      end
    endtask

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      gen.add(make_reset());

      cfg_txn = make_cfg("cfg_csr_readback");
      cfg_txn.mode_cfg           = vip_mode_t'(MODE_MULTI_HIT);
      cfg_txn.input_sel          = INPUT_CAL;
      cfg_txn.out_mode           = OUT_MODE_FULL;
      cfg_txn.max_hits           = MAX_HITS_W'(3);
      cfg_txn.wdt_ctx_timeout    = 16'd400;
      cfg_txn.wdt_global_timeout = 16'd64;

      expected_mode_data         = '0;
      expected_mode_data[1]      = cfg_txn.input_sel;
      expected_mode_data[3:2]    = cfg_txn.out_mode;
      expected_max_hits_data     = '0;
      expected_max_hits_data[MAX_HITS_W-1:0] = cfg_txn.max_hits;
      expected_wdt_ctx_data      = '0;
      expected_wdt_ctx_data[15:0] = cfg_txn.wdt_ctx_timeout;
      expected_wdt_global_data   = '0;
      expected_wdt_global_data[15:0] = cfg_txn.wdt_global_timeout;
      // Keep two attempts to increase the odds of exercising queued traffic
      // under permanent backpressure, but do not require both to be accepted:
      // context ownership under a stalled egress path is timing-sensitive and
      // the control-readback goal of this test only needs at least one packet
      // resident in the FIFO.
      expected_conv_count        = 2;

      gen.add(cfg_txn);
      gen.add(make_bp("bp_stall", BP_ALWAYS_STALL, cfg.random_seed));

      for (int i = 0; i < expected_conv_count; i++) begin
        conv = make_conv($sformatf("csr_fifo_fill_%0d", i));
        conv.source_sel          = INPUT_CAL;
        conv.start_stop_delay_ps = 12_000 + (i * 2_000);
        conv.expect_packet       = 1'b0;
        conv.check_hit_range     = 1'b0;
        conv.idle_after_ps       = (i == (expected_conv_count - 1)) ? 5_000_000 : 1_000_000;
        gen.add(conv);
      end
    endfunction

    virtual task post_run();
      logic [CSR_DATA_W-1:0] ctrl_data;
      logic [CSR_DATA_W-1:0] status_data;
      logic [CSR_DATA_W-1:0] fifo_status_data;
      logic [CSR_DATA_W-1:0] conv_count_data;
      logic [CSR_DATA_W-1:0] invalid_data;
      bit                    busy_seen;

      csr_vif.csr_valid       = 1'b0;
      csr_vif.csr_write       = 1'b0;
      narrow_vif.narrow_ready = 1'b0;
      #200_000;

      expect_reg_eq("CSR_MODE", CSR_MODE, expected_mode_data, 32'h0000_000F);
      expect_reg_eq("CSR_MAX_HITS", CSR_MAX_HITS, expected_max_hits_data,
                    {{(CSR_DATA_W-MAX_HITS_W){1'b0}}, {MAX_HITS_W{1'b1}}});
      expect_reg_eq("CSR_WDT_CTX", CSR_WDT_CTX, expected_wdt_ctx_data, 32'h0000_FFFF);
      expect_reg_eq("CSR_WDT_GLOBAL", CSR_WDT_GLOBAL, expected_wdt_global_data, 32'h0000_FFFF);

      env.csr_drv.read(CSR_CTRL, ctrl_data);
      if (ctrl_data[0] !== 1'b1)
        env.sb.fail("CSR_CTRL expected conv_arm=1 after queued conversions");

      env.csr_drv.read(CSR_CONV_COUNT, conv_count_data);
      if ((conv_count_data == 0) || (conv_count_data > expected_conv_count)) begin
        env.sb.fail($sformatf("CSR_CONV_COUNT out of expected range: got %0d expected [1:%0d]",
                              conv_count_data, expected_conv_count));
      end

      env.csr_drv.read(CSR_FIFO_STATUS, fifo_status_data);
      if (fifo_status_data[FIFO_LVL_W-1:0] == '0)
        env.sb.fail("CSR_FIFO_STATUS expected fifo_level > 0 before fifo_clear");
      if (fifo_status_data[FIFO_LVL_W+1] !== 1'b0)
        env.sb.fail("CSR_FIFO_STATUS expected fifo_empty=0 before fifo_clear");

      env.csr_drv.read(CSR_STATUS, status_data);
      if (status_data[0] !== 1'b1)
        env.sb.fail("CSR_STATUS expected ready=1 before fifo_clear");

      env.csr_drv.read(6'h3C, invalid_data);
      if (invalid_data !== '0)
        env.sb.fail($sformatf("Invalid CSR address read expected zero, got 0x%08h", invalid_data));

      env.csr_drv.fifo_clear();
      #100_000;

      env.csr_drv.read(CSR_CTRL, ctrl_data);
      if (ctrl_data[0] !== 1'b0)
        env.sb.fail("fifo_clear write should leave conv_arm cleared because CSR_CTRL[0]=0");

      env.csr_drv.read(CSR_FIFO_STATUS, fifo_status_data);
      if (fifo_status_data[FIFO_LVL_W-1:0] != '0)
        env.sb.fail($sformatf("FIFO clear failed: fifo_level=%0d", fifo_status_data[FIFO_LVL_W-1:0]));
      if (fifo_status_data[FIFO_LVL_W+1] !== 1'b1)
        env.sb.fail("FIFO clear failed: fifo_empty did not assert");

      env.csr_drv.read(CSR_STATUS, status_data);
      if (status_data[0] !== 1'b0)
        env.sb.fail("CSR_STATUS expected ready=0 after fifo_clear cleared conv_arm");

      expect_reg_eq("CSR_MODE sticky after fifo_clear", CSR_MODE, expected_mode_data, 32'h0000_000F);

      env.csr_drv.arm_only();
      #50_000;
      env.csr_drv.read(CSR_STATUS, status_data);
      if ((status_data[0] !== 1'b1) || (status_data[1] !== 1'b0))
        env.sb.fail($sformatf("Expected ready=1,busy=0 after re-arm, got status=0x%08h", status_data));

      narrow_vif.narrow_ready = 1'b1;
      async_vif.inject_start_only(INPUT_CAL, 1_000);
      busy_seen = 1'b0;
      for (int unsigned poll = 0; poll < 16; poll++) begin
        #20_000;
        env.csr_drv.read(CSR_STATUS, status_data);
        if (status_data[1] === 1'b1) begin
          busy_seen = 1'b1;
          break;
        end
      end
      if (!busy_seen)
        env.sb.fail($sformatf("Expected busy=1 during start-only ownership, got status=0x%08h", status_data));

      env.csr_drv.soft_reset_and_fifo_clear();
      #200_000;

      env.csr_drv.read(CSR_CTRL, ctrl_data);
      if (ctrl_data[0] !== 1'b0)
        env.sb.fail("soft_reset_and_fifo_clear should leave conv_arm=0");

      env.csr_drv.read(CSR_FIFO_STATUS, fifo_status_data);
      if (fifo_status_data[FIFO_LVL_W-1:0] != '0)
        env.sb.fail($sformatf("Combined reset failed to clear FIFO level (%0d)",
                              fifo_status_data[FIFO_LVL_W-1:0]));
      if (fifo_status_data[FIFO_LVL_W+1] !== 1'b1)
        env.sb.fail("Combined reset expected fifo_empty=1");

      env.csr_drv.read(CSR_STATUS, status_data);
      if ((status_data[0] !== 1'b0) || (status_data[1] !== 1'b0))
        env.sb.fail($sformatf("Expected ready=0,busy=0 after combined reset, got status=0x%08h", status_data));

      expect_reg_eq("CSR_MODE reset default after soft reset", CSR_MODE, '0, 32'h0000_000F);
      expect_reg_eq("CSR_MAX_HITS reset default after soft reset", CSR_MAX_HITS,
                    CSR_DATA_W'(MAX_HITS), {{(CSR_DATA_W-MAX_HITS_W){1'b0}}, {MAX_HITS_W{1'b1}}});
      expect_reg_eq("CSR_WDT_CTX reset default after soft reset", CSR_WDT_CTX, '0, 32'h0000_FFFF);
      expect_reg_eq("CSR_WDT_GLOBAL reset default after soft reset", CSR_WDT_GLOBAL, '0,
                    32'h0000_FFFF);

      env.csr_drv.arm_only();
      #50_000;
      env.csr_drv.read(CSR_STATUS, status_data);
      if ((status_data[0] !== 1'b1) || (status_data[1] !== 1'b0))
        env.sb.fail($sformatf("Expected ready=1,busy=0 after final re-arm, got status=0x%08h", status_data));
    endtask
  endclass

  class mptdc_hard_reset_readback_test extends mptdc_base_test;
    logic [CSR_DATA_W-1:0] hit_count_data;
    logic [CSR_DATA_W-1:0] status_data;
    logic [CSR_DATA_W-1:0] ctrl_data;
    logic [CSR_DATA_W-1:0] mode_data;
    logic [CSR_DATA_W-1:0] max_hits_data;
    logic [CSR_DATA_W-1:0] wdt_ctx_data;
    logic [CSR_DATA_W-1:0] wdt_global_data;

    function new();
      super.new("hard_reset_readback");
      hit_count_data  = '0;
      status_data     = '0;
      ctrl_data       = '0;
      mode_data       = '0;
      max_hits_data   = '0;
      wdt_ctx_data    = '0;
      wdt_global_data = '0;
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;

      gen.add(make_reset());

      cfg_txn = make_cfg("cfg_hard_reset_readback");
      cfg_txn.mode_cfg           = VIP_MODE_FAST_CLOSE;
      cfg_txn.input_sel          = INPUT_CAL;
      cfg_txn.out_mode           = OUT_MODE_FULL;
      cfg_txn.max_hits           = MAX_HITS_W'(1);
      cfg_txn.wdt_ctx_timeout    = 16'd0;
      cfg_txn.wdt_global_timeout = 16'd0;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_ready", BP_ALWAYS_READY, cfg.random_seed));

      conv = make_conv("hard_reset_conv");
      conv.source_sel             = INPUT_CAL;
      conv.start_stop_delay_ps    = 11_000;
      conv.idle_after_ps          = 1_000_000;
      conv.require_nonzero_hits   = 1'b1;
      conv.min_hits               = 1;
      conv.check_firsthit_flag    = 1'b1;
      conv.expected_firsthit_flag = 1'b1;
      gen.add(conv);
    endfunction

    virtual task post_run();
      csr_vif.csr_valid       = 1'b0;
      csr_vif.csr_write       = 1'b0;
      narrow_vif.narrow_ready = 1'b1;
      #200_000;

      env.csr_drv.read(CSR_HIT_COUNT, hit_count_data);
      if (hit_count_data[MAX_HITS_W-1:0] == '0)
        env.sb.fail("hard_reset_readback expected CSR_HIT_COUNT last_hit_count > 0 after conversion");
      if (hit_count_data[MAX_HITS_W+CONV_FLAGS_W-2] !== 1'b1)
        env.sb.fail($sformatf("hard_reset_readback expected closed_by_fast_maxhit=1, got CSR_HIT_COUNT=0x%08h",
                              hit_count_data));
      if (hit_count_data[MAX_HITS_W+CONV_FLAGS_W-3] !== 1'b0)
        env.sb.fail($sformatf("hard_reset_readback expected closed_by_maxhits=0, got CSR_HIT_COUNT=0x%08h",
                              hit_count_data));
      if (hit_count_data[MAX_HITS_W+CONV_FLAGS_W-4] !== 1'b0)
        env.sb.fail($sformatf("hard_reset_readback expected closed_by_watchdog=0, got CSR_HIT_COUNT=0x%08h",
                              hit_count_data));

      env.csr_drv.arm_only();
      #50_000;
      async_vif.inject_start_only(INPUT_CAL, 1_000);
      #50_000;
      env.csr_drv.read(CSR_STATUS, status_data);
      if (status_data[1] !== 1'b1)
        env.sb.fail($sformatf("hard_reset_readback expected busy=1 before hard reset, got status=0x%08h",
                              status_data));

      async_vif.hard_reset(100_000, 100_000);
      #50_000;

      env.csr_drv.read(CSR_CTRL, ctrl_data);
      if (ctrl_data[0] !== 1'b0)
        env.sb.fail("hard_reset_readback expected conv_arm=0 after hard reset");

      env.csr_drv.read(CSR_MODE, mode_data);
      if ((mode_data & 32'h0000_000F) !== 32'h0000_0000)
        env.sb.fail($sformatf("hard_reset_readback expected CSR_MODE reset defaults, got 0x%08h", mode_data));

      env.csr_drv.read(CSR_MAX_HITS, max_hits_data);
      if ((max_hits_data & {{(CSR_DATA_W-MAX_HITS_W){1'b0}}, {MAX_HITS_W{1'b1}}}) !== CSR_DATA_W'(MAX_HITS))
        env.sb.fail($sformatf("hard_reset_readback expected CSR_MAX_HITS reset default %0d, got 0x%08h",
                              MAX_HITS, max_hits_data));

      env.csr_drv.read(CSR_WDT_CTX, wdt_ctx_data);
      if ((wdt_ctx_data & 32'h0000_FFFF) !== 32'h0000_0000)
        env.sb.fail($sformatf("hard_reset_readback expected CSR_WDT_CTX reset default 0, got 0x%08h",
                              wdt_ctx_data));

      env.csr_drv.read(CSR_WDT_GLOBAL, wdt_global_data);
      if ((wdt_global_data & 32'h0000_FFFF) !== 32'h0000_0000)
        env.sb.fail($sformatf("hard_reset_readback expected CSR_WDT_GLOBAL reset default 0, got 0x%08h",
                              wdt_global_data));

      env.csr_drv.read(CSR_STATUS, status_data);
      if ((status_data[0] !== 1'b0) || (status_data[1] !== 1'b0))
        env.sb.fail($sformatf("hard_reset_readback expected ready=0,busy=0 after hard reset, got status=0x%08h",
                              status_data));

      env.csr_drv.read(CSR_HIT_COUNT, hit_count_data);
      if ((hit_count_data & 32'h0000_00FF) !== 32'h0000_0000)
        env.sb.fail($sformatf("hard_reset_readback expected CSR_HIT_COUNT cleared after hard reset, got 0x%08h",
                              hit_count_data));
    endtask
  endclass

  // ---------------------------------------------------------------------------
  // coverage_exhaustive — systematically walks ALL config combinations
  //   2 modes × 2 sources × 3 outputs × 3 backpressures × 5 delays
  //   + watchdog tests + start-only tests = ~200 conversions
  // ---------------------------------------------------------------------------
  class mptdc_coverage_exhaustive_test extends mptdc_base_test;
    function new();
      super.new("coverage_exhaustive");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      int conv_id;
      int delays_ps[5]    = '{500, 5_000, 12_000, 20_000, 28_000};
      int modes[2]        = '{MODE_MULTI_HIT, VIP_MODE_FAST_CLOSE};
      int sources[2]      = '{INPUT_SPAD, INPUT_CAL};
      int out_modes[3]    = '{OUT_MODE_RAW_FEATURES, OUT_MODE_RAW_TIMESTAMP, OUT_MODE_FULL};
      int bp_modes[3]     = '{BP_ALWAYS_READY, BP_RANDOM_50, BP_ALWAYS_STALL};

      gen.add(make_reset());
      conv_id = 0;

      // Phase 1: walk every mode × source × output × delay (always_ready)
      // idle_after must be long enough for measurement + drain + narrow TX:
      //   ~100ns measurement + ~100ns drain + ~400ns narrow TX = ~600ns
      // Use 1µs per conv, 5µs after last conv to drain before config change.
      for (int m = 0; m < 2; m++) begin
        for (int s = 0; s < 2; s++) begin
          for (int o = 0; o < 3; o++) begin
            cfg_txn = make_cfg($sformatf("cfg_m%0d_s%0d_o%0d", m, s, o));
            cfg_txn.mode_cfg  = vip_mode_t'(modes[m]);
            cfg_txn.input_sel = input_sel_e'(sources[s]);
            cfg_txn.out_mode  = out_mode_e'(out_modes[o]);
            cfg_txn.max_hits  = MAX_HITS_W'(15);
            cfg_txn.wdt_ctx_timeout    = 16'hFFFF;
            cfg_txn.wdt_global_timeout = 16'h0;
            gen.add(cfg_txn);

            gen.add(make_bp($sformatf("bp_ready_%0d", conv_id),
                            BP_ALWAYS_READY, cfg.random_seed + conv_id));

            for (int d = 0; d < 5; d++) begin
              conv = make_conv($sformatf("conv_%0d", conv_id));
              conv.source_sel         = input_sel_e'(sources[s]);
              conv.start_stop_delay_ps = delays_ps[d];
              conv.arm_settle_ps       = 0;
              // Last conv in group: extra drain to flush narrow TX before
              // next CSR_MODE write (prevents out_mode race condition)
              conv.idle_after_ps       = (d == 4) ? 5_000_000 : 1_000_000;
              conv.require_nonzero_hits = 1'b1;
              conv.min_hits            = 1;
              if (modes[m] == VIP_MODE_FAST_CLOSE) begin
                conv.check_firsthit_flag    = 1'b1;
                conv.expected_firsthit_flag = 1'b1;
              end
              if (out_modes[o] == OUT_MODE_FULL) begin
                conv.check_full_timestamp = 1'b1;
              end
              gen.add(conv);
              conv_id++;
            end
          end
        end
      end

      // Phase 2: backpressure sweep (multi_hit, spad, raw_features)
      // FIFO_DEPTH=64, each conv produces up to 16 entries (1 META + 15 hits).
      // always_stall: narrow TX blocked → FIFO fills; cap at 3 convs (48 < 64).
      // All groups: 1µs per conv, 5µs drain on last conv before next CSR write.
      for (int b = 0; b < 3; b++) begin
        automatic int bp_num_delays;
        cfg_txn = make_cfg($sformatf("cfg_bp%0d", b));
        cfg_txn.mode_cfg  = MODE_MULTI_HIT;
        cfg_txn.input_sel = INPUT_SPAD;
        cfg_txn.out_mode  = OUT_MODE_RAW_FEATURES;
        cfg_txn.max_hits  = MAX_HITS_W'(15);
        cfg_txn.wdt_ctx_timeout    = 16'hFFFF;
        cfg_txn.wdt_global_timeout = 16'h0;
        gen.add(cfg_txn);

        gen.add(make_bp($sformatf("bp_sweep_%0d", b),
                        mptdc_bp_mode_e'(bp_modes[b]),
                        cfg.random_seed + conv_id));

        // Limit always_stall to 3 convs to avoid FIFO overflow (3×16=48 < 64)
        bp_num_delays = (bp_modes[b] == BP_ALWAYS_STALL) ? 3 : 5;

        for (int d = 0; d < bp_num_delays; d++) begin
          conv = make_conv($sformatf("conv_bp_%0d", conv_id));
          conv.start_stop_delay_ps = delays_ps[d];
          conv.arm_settle_ps       = 0;
          conv.idle_after_ps       = (d == bp_num_delays - 1) ? 5_000_000 : 1_000_000;
          conv.require_nonzero_hits = 1'b1;
          conv.min_hits            = 1;
          gen.add(conv);
          conv_id++;
        end

        // drain after stall: switch back to always_ready
        if (bp_modes[b] == BP_ALWAYS_STALL) begin
          gen.add(make_bp($sformatf("bp_drain_%0d", b),
                          BP_ALWAYS_READY, cfg.random_seed));
          // Drain conv: let all stalled packets flush through narrow TX
          conv = make_conv($sformatf("conv_drain_%0d", conv_id));
          conv.start_stop_delay_ps = 10_000;
          conv.arm_settle_ps       = 0;
          conv.idle_after_ps       = 10_000_000;
          conv.require_nonzero_hits = 1'b1;
          conv.min_hits            = 1;
          gen.add(conv);
          conv_id++;
        end
      end

      // Phase 3: watchdog tests (start-only)
      // max_hits=0 disables the maxhits comparator in HW (meas_ctrl line 142:
      // max_hits_cfg_i != '0).  This keeps the measurement open so only the
      // watchdog can close it.  PD cells still fire (both oscillators start on
      // START) producing 15 hits, but the measurement won't close by maxhits.
      cfg_txn = make_cfg("cfg_wdt_ctx");
      cfg_txn.mode_cfg           = MODE_MULTI_HIT;
      cfg_txn.input_sel          = INPUT_SPAD;
      cfg_txn.out_mode           = OUT_MODE_RAW_FEATURES;
      cfg_txn.max_hits           = MAX_HITS_W'(0);
      cfg_txn.wdt_ctx_timeout    = 16'd100;
      cfg_txn.wdt_global_timeout = 16'h0;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_wdt", BP_ALWAYS_READY, cfg.random_seed));

      conv = make_conv("conv_wdt_start_only");
      conv.start_only              = 1'b1;
      conv.idle_after_ps           = 5_000_000;
      conv.check_watchdog_flag     = 1'b1;
      conv.expected_watchdog_flag  = 1'b1;
      // Don't check hit range: with start-only, oscillators free-run
      // and capture a non-deterministic number of hits before watchdog
      conv.check_hit_range         = 1'b0;
      gen.add(conv);
      conv_id++;

      // Phase 4: recovery after watchdog — normal operation
      cfg_txn = make_cfg("cfg_recovery");
      cfg_txn.mode_cfg           = MODE_MULTI_HIT;
      cfg_txn.input_sel          = INPUT_SPAD;
      cfg_txn.out_mode           = OUT_MODE_FULL;
      cfg_txn.max_hits           = MAX_HITS_W'(15);
      cfg_txn.wdt_ctx_timeout    = 16'hFFFF;
      gen.add(cfg_txn);

      conv = make_conv("conv_recovery");
      conv.start_stop_delay_ps     = 15_000;
      conv.arm_settle_ps           = 0;
      conv.idle_after_ps           = 5_000_000;
      conv.require_nonzero_hits    = 1'b1;
      conv.min_hits                = 1;
      conv.check_watchdog_flag     = 1'b1;
      conv.expected_watchdog_flag  = 1'b0;
      conv.check_full_timestamp    = 1'b1;
      gen.add(conv);
      conv_id++;

      $display("[TEST] coverage_exhaustive: %0d conversions queued", conv_id);
    endfunction
  endclass

  // ---------------------------------------------------------------------------
  // stress_random — massive random stimulus for coverage closure
  //   Configurable conversion count via +MPTDC_NUM_CONV=N (default 5000)
  //   Random: mode, source, output, delay (20ps–30ns), backpressure, max_hits
  //   Uses cfg.random_seed for reproducibility
  // ---------------------------------------------------------------------------
  class mptdc_stress_random_test extends mptdc_base_test;
    function new();
      super.new("stress_random");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      int num;
      int unsigned rng;
      int cur_mode, cur_src, cur_out, cur_bp, cur_max_hits;
      automatic int delay_ps;
      int reconfig_interval;

      num = cfg.num_conv;
      if (num <= 0) num = 5000;

      gen.add(make_reset());
      rng = cfg.random_seed;

      // Initial config
      cur_mode     = 0;
      cur_src      = 0;
      cur_out      = 0;
      cur_bp       = 0;
      cur_max_hits = 15;
      reconfig_interval = (num < 100) ? 5 : (num / 20);

      for (int i = 0; i < num; i++) begin
        // Reconfigure periodically with random settings
        if ((i % reconfig_interval) == 0) begin
          rng = rng * 32'h41C6_4E6D + 32'h3039;
          cur_mode     = (rng >> 16) & 1;
          cur_src      = (rng >> 17) & 1;
          cur_out      = (rng >> 18) % 3;
          cur_max_hits = ((rng >> 20) % 16);
          if (cur_max_hits == 0)
            cur_max_hits = 15;
          if (cur_mode == VIP_MODE_FAST_CLOSE)
            cur_max_hits = 1;
          else if (cur_max_hits == 1)
            cur_max_hits = 2;

          cfg_txn = make_cfg($sformatf("cfg_%0d", i));
          cfg_txn.mode_cfg  = vip_mode_t'(cur_mode);
          cfg_txn.input_sel = input_sel_e'(cur_src);
          cfg_txn.out_mode  = out_mode_e'(cur_out);
          cfg_txn.max_hits  = MAX_HITS_W'(cur_max_hits);
          cfg_txn.wdt_ctx_timeout    = 16'hFFFF;
          cfg_txn.wdt_global_timeout = 16'h0;
          gen.add(cfg_txn);

          // Change backpressure every other reconfig
          if (((i / reconfig_interval) % 2) == 0) begin
            rng = rng * 32'h41C6_4E6D + 32'h3039;
            cur_bp = (rng >> 16) % 3;
            // Avoid ALWAYS_STALL for bulk random — it blocks
            if (cur_bp == BP_ALWAYS_STALL) cur_bp = BP_RANDOM_50;
            gen.add(make_bp($sformatf("bp_%0d", i),
                            mptdc_bp_mode_e'(cur_bp),
                            rng));
          end
        end

        // Random delay: 20ps to 30_000ps (30ns) — uniform
        rng = rng * 32'h41C6_4E6D + 32'h3039;
        delay_ps = 20 + ((rng >> 8) % 29_981);

        conv = make_conv($sformatf("r_%0d", i));
        conv.source_sel         = input_sel_e'(cur_src);
        conv.start_stop_delay_ps = delay_ps;
        conv.arm_settle_ps       = 0;
        // 1µs: enough for measurement + drain + narrow TX (see coverage_exhaustive)
        // Last conv before reconfig: 5µs to drain all pending packets
        conv.idle_after_ps       = (((i+1) % reconfig_interval) == 0) ? 5_000_000 : 1_000_000;
        conv.require_nonzero_hits = 1'b1;
        conv.min_hits            = 1;
        if (cur_mode == VIP_MODE_FAST_CLOSE) begin
          conv.check_firsthit_flag    = 1'b1;
          conv.expected_firsthit_flag = 1'b1;
        end
        if (cur_out == OUT_MODE_FULL) begin
          conv.check_full_timestamp = 1'b1;
        end
        gen.add(conv);
      end

      $display("[TEST] stress_random: %0d conversions, seed=%0h", num, cfg.random_seed);
    endfunction
  endclass

  class mptdc_vip_ref_stop_cdv_test extends mptdc_base_test;
    function new();
      super.new("vip_ref_stop_cdv");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      int unsigned   delays_ps[6] = '{0, 2_000, 6_000, 10_000, 16_000, 24_000};

      gen.add(make_reset());
      cfg_txn = make_cfg("cfg_vip_ref");
      cfg_txn.out_mode           = OUT_MODE_FULL;
      cfg_txn.max_hits           = MAX_HITS_W'(15);
      cfg_txn.wdt_ctx_timeout    = 16'hFFFF;
      cfg_txn.wdt_global_timeout = 16'h0;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_vip_ready", BP_ALWAYS_READY, cfg.random_seed));

      foreach (delays_ps[i]) begin
        conv = make_conv($sformatf("vip_ref_%0d", i));
        conv.start_stop_delay_ps  = delays_ps[i];
        conv.arm_settle_ps        = 0;
        conv.idle_after_ps        = 1_500_000;
        conv.require_nonzero_hits = 1'b1;
        conv.min_hits             = 1;
        conv.check_full_timestamp = 1'b1;
        conv.check_conv_id        = 1'b1;
        conv.expected_conv_id     = i;
        gen.add(conv);
      end
    endfunction
  endclass

  class mptdc_vip_maxhits_matrix_test extends mptdc_base_test;
    function new();
      super.new("vip_maxhits_matrix");
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      int unsigned   maxhits_values[4] = '{1, 2, 8, 15};
      int unsigned   bp_values[3] = '{BP_ALWAYS_READY, BP_RANDOM_50, BP_BOUNDED_STALL};
      int            conv_id;

      gen.add(make_reset());
      conv_id = 0;

      foreach (maxhits_values[m]) begin
        cfg_txn = make_cfg($sformatf("cfg_vip_mh%0d", maxhits_values[m]));
        cfg_txn.max_hits           = MAX_HITS_W'(maxhits_values[m]);
        cfg_txn.mode_cfg           = (maxhits_values[m] == 1) ? VIP_MODE_FAST_CLOSE : vip_mode_t'(MODE_MULTI_HIT);
        cfg_txn.out_mode           = OUT_MODE_FULL;
        cfg_txn.wdt_ctx_timeout    = 16'hFFFF;
        cfg_txn.wdt_global_timeout = 16'h0;
        gen.add(cfg_txn);

        foreach (bp_values[b]) begin
          gen.add(make_bp($sformatf("bp_vip_mh%0d_b%0d", maxhits_values[m], b),
                          mptdc_bp_mode_e'(bp_values[b]),
                          cfg.random_seed + conv_id));
          conv = make_conv($sformatf("vip_mh%0d_b%0d", maxhits_values[m], b));
          conv.start_stop_delay_ps   = 12_000 + (b * 2_000);
          conv.arm_settle_ps         = 0;
          conv.idle_after_ps         = (b == 2) ? 5_000_000 : 1_500_000;
          conv.require_nonzero_hits  = 1'b1;
          conv.min_hits              = 1;
          conv.max_hits_allowed      = maxhits_values[m];
          conv.check_full_timestamp  = 1'b1;
          conv.check_conv_id         = 1'b1;
          conv.expected_conv_id      = conv_id;
          if (maxhits_values[m] == 1) begin
            conv.check_firsthit_flag     = 1'b1;
            conv.expected_firsthit_flag  = 1'b1;
          end
          gen.add(conv);
          conv_id++;
        end
      end
      gen.add(make_bp("bp_vip_release", BP_ALWAYS_READY, cfg.random_seed));
    endfunction
  endclass

  class mptdc_test_factory;
    static function mptdc_base_test create(input string name);
      mptdc_base_test t;
      mptdc_smoke_single_conv_test smoke_t;
      mptdc_full_mode_timestamp_test full_ts_t;
      mptdc_firsthit_contract_test firsthit_t;
      mptdc_backpressure_integrity_test bp_t;
      mptdc_start_watchdog_test start_wdt_t;
      mptdc_cal_inject_test cal_t;
      mptdc_overflow_status_test ovf_t;
      mptdc_long_random_test rand_t;
      mptdc_multi_conv_rearm_stress_test multi_conv_t;
      mptdc_global_watchdog_recovery_test global_wdt_t;
      mptdc_jitter_robustness_test jitter_t;
      mptdc_csr_readback_control_test csr_ctrl_t;
      mptdc_hard_reset_readback_test hard_reset_t;
      mptdc_coverage_exhaustive_test cov_exh_t;
      mptdc_stress_random_test stress_t;
      mptdc_vip_ref_stop_cdv_test vip_ref_t;
      mptdc_vip_maxhits_matrix_test vip_maxhits_t;
      case (name)
        "smoke_single_conv": begin
          smoke_t = new();
          t = smoke_t;
        end
        "full_mode_timestamp": begin
          full_ts_t = new();
          t = full_ts_t;
        end
        "firsthit_contract": begin
          firsthit_t = new();
          t = firsthit_t;
        end
        "backpressure_integrity": begin
          bp_t = new();
          t = bp_t;
        end
        "start_watchdog": begin
          start_wdt_t = new();
          t = start_wdt_t;
        end
        "cal_inject": begin
          cal_t = new();
          t = cal_t;
        end
        "overflow_status": begin
          ovf_t = new();
          t = ovf_t;
        end
        "long_random": begin
          rand_t = new();
          t = rand_t;
        end
        "multi_conv_rearm_stress": begin
          multi_conv_t = new();
          t = multi_conv_t;
        end
        "global_watchdog_recovery": begin
          global_wdt_t = new();
          t = global_wdt_t;
        end
        "jitter_robustness": begin
          jitter_t = new();
          t = jitter_t;
        end
        "csr_readback_control": begin
          csr_ctrl_t = new();
          t = csr_ctrl_t;
        end
        "hard_reset_readback": begin
          hard_reset_t = new();
          t = hard_reset_t;
        end
        "coverage_exhaustive": begin
          cov_exh_t = new();
          t = cov_exh_t;
        end
        "stress_random": begin
          stress_t = new();
          t = stress_t;
        end
        "vip_ref_stop_cdv": begin
          vip_ref_t = new();
          t = vip_ref_t;
        end
        "vip_maxhits_matrix": begin
          vip_maxhits_t = new();
          t = vip_maxhits_t;
        end
        default: t = null;
      endcase
      return t;
    endfunction
  endclass

endpackage

`default_nettype wire
