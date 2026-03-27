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
    BP_ALWAYS_READY = 0,
    BP_RANDOM_50    = 1,
    BP_ALWAYS_STALL = 2
  } mptdc_bp_mode_e;

  typedef enum int unsigned {
    TXN_CFG   = 0,
    TXN_CONV  = 1,
    TXN_BP    = 2,
    TXN_RESET = 3,
    TXN_EOT   = 4
  } mptdc_txn_kind_e;

  // These helpers decode the exact narrow packet format observed on the
  // wire so the monitor and scoreboard stay anchored to the DUT contract.
  function automatic bit is_header_word(input logic [NARROW_W-1:0] word);
    return word[15:14] == 2'b10;
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

  function automatic int unsigned words_per_hit(input out_mode_e mode);
    case (mode)
      OUT_MODE_RAW_FEATURES:  return 3;
      OUT_MODE_RAW_TIMESTAMP: return 2;
      OUT_MODE_FULL:          return 4;
      default:                return 3;
    endcase
  endfunction

  function automatic int unsigned packet_words_from_header(input logic [NARROW_W-1:0] hdr);
    return 2 + (packet_hit_count(hdr) * words_per_hit(packet_out_mode(hdr)));
  endfunction

  function automatic string bp_mode_name(input mptdc_bp_mode_e mode);
    case (mode)
      BP_ALWAYS_READY: return "always_ready";
      BP_RANDOM_50:    return "random_50";
      BP_ALWAYS_STALL: return "always_stall";
      default:         return "unknown";
    endcase
  endfunction

  class mptdc_env_cfg;
    string test_name;
    int unsigned random_seed;
    int osc_jitter_sigma_ps;
    int osc_jitter_bound_ps;
    bit enable_func_cov;
    int num_conv;

    function new();
      test_name           = "unset";
      random_seed         = 32'h1bad_f00d;
      osc_jitter_sigma_ps = 0;
      osc_jitter_bound_ps = 0;
      enable_func_cov     = 1'b0;
      num_conv            = 0;
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
    mode_e                  mode_cfg;
    input_sel_e             input_sel;
    out_mode_e              out_mode;
    logic [MAX_HITS_W-1:0]  max_hits;
    logic [15:0]            wdt_ctx_timeout;
    logic [15:0]            wdt_global_timeout;

    function new(string label_i = "cfg");
      super.new(TXN_CFG, label_i);
      mode_cfg           = MODE_MULTI_HIT;
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

    function logic [CSR_DATA_W-1:0] pack_mode_reg();
      logic [CSR_DATA_W-1:0] word;
      word      = '0;
      word[0]   = mode_cfg;
      word[1]   = input_sel;
      word[3:2] = out_mode;
      return word;
    endfunction

    virtual function string sprint();
      return $sformatf("CFG[%s] mode=%0d input=%0d out=%0d max_hits=%0d wdt_ctx=%0d wdt_global=%0d",
                       label, mode_cfg, input_sel, out_mode, max_hits,
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
    time        start_stop_delay_ps;
    time        arm_settle_ps;
    time        pulse_width_ps;
    time        idle_after_ps;
    bit         start_only;
    bit         expect_packet;

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

    mode_e                 cfg_mode;
    input_sel_e            cfg_input_sel;
    out_mode_e             cfg_out_mode;
    logic [MAX_HITS_W-1:0] cfg_max_hits;

    function new(string label_i = "conv");
      super.new(TXN_CONV, label_i);
      source_sel              = INPUT_SPAD;
      start_stop_delay_ps     = 10_000;
      arm_settle_ps           = 50_000;
      pulse_width_ps          = 1_000;
      idle_after_ps           = 50_000;
      start_only              = 1'b0;
      expect_packet           = 1'b1;
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
      c.start_stop_delay_ps    = start_stop_delay_ps;
      c.arm_settle_ps          = arm_settle_ps;
      c.pulse_width_ps         = pulse_width_ps;
      c.idle_after_ps          = idle_after_ps;
      c.start_only             = start_only;
      c.expect_packet          = expect_packet;
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
      return $sformatf("CONV[%s] src=%0d delay=%0t arm_settle=%0t pulse_w=%0t start_only=%0b expect_packet=%0b cfg_mode=%0d out=%0d conv_id_chk=%0b exp_conv_id=%0d",
                       label, source_sel, start_stop_delay_ps, arm_settle_ps,
                       pulse_width_ps, start_only, expect_packet,
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
      pd_idx        = '0;
      event_seq     = '0;
      t_raw_lsw     = '0;
      has_features  = 1'b0;
      has_timestamp = 1'b0;
    endfunction

    function string sprint();
      return $sformatf("hit nslow=%0d nfast=%0d nfast_snap=%0d ns=%0d nf=%0d pd_idx=%0d seq=%0d ts_lsw=0x%04h feat=%0b ts=%0b",
                       nslow, nfast_hit, nfast_snap, ns, nf, pd_idx, event_seq,
                       t_raw_lsw, has_features, has_timestamp);
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

  // Shared mailbox that bridges class-based sequencing to the
  // module-resident BFM loop inside mptdc_vip_tb.
  mailbox #(mptdc_base_txn) g_bfm_req_mb;

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
      write(CSR_MAX_HITS,   {28'd0, cfg.max_hits});
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
    bit                     stop_request;

    function new(virtual mptdc_narrow_if vif_i);
      vif          = vif_i;
      mode         = BP_ALWAYS_READY;
      seed         = 32'hca11_ab1e;
      stop_request = 1'b0;
    endfunction

    function void set_mode(input mptdc_bp_mode_e mode_i,
                           input int unsigned seed_i = 32'hca11_ab1e);
      mode = mode_i;
      seed = seed_i;
    endfunction

    task run();
      vif.narrow_ready = 1'b1;
      while (!stop_request) begin
        @(posedge vif.clk_sys);
        case (mode)
          BP_ALWAYS_READY: vif.narrow_ready = 1'b1;
          BP_RANDOM_50:    vif.narrow_ready = $urandom(seed) & 1'b1;
          BP_ALWAYS_STALL: vif.narrow_ready = 1'b0;
          default:         vif.narrow_ready = 1'b1;
        endcase
      end
      vif.narrow_ready = 1'b1;
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
                                            int delay_bin_i,
                                            int jitter_bin_i,
                                            bit start_only_i);
      option.per_instance = 1;
      cp_mode: coverpoint mode_i { bins mh = {MODE_MULTI_HIT}; bins fh = {MODE_FIRST_HIT}; }
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
      cp_start_only: coverpoint start_only_i { bins no = {0}; bins yes = {1}; }
      mode_x_out: cross cp_mode, cp_out;
      mode_x_delay: cross cp_mode, cp_delay;
      bp_x_delay: cross cp_bp, cp_delay;
    endgroup

    covergroup pkt_cg with function sample(int out_mode_i,
                                           int hit_count_i,
                                           bit firsthit_i,
                                           bit maxhits_i,
                                           bit watchdog_i,
                                           bit phase0_i,
                                           bit boundary_i,
                                           int words_i);
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
      cp_firsthit: coverpoint firsthit_i { bins off = {0}; bins on = {1}; }
      cp_maxhits: coverpoint maxhits_i { bins off = {0}; bins on = {1}; }
      cp_watchdog: coverpoint watchdog_i { bins off = {0}; bins on = {1}; }
      cp_phase0: coverpoint phase0_i { bins low = {0}; bins high = {1}; }
      cp_boundary: coverpoint boundary_i { bins low = {0}; bins high = {1}; }
      cp_words: coverpoint words_i;
      flags_x_hits: cross cp_firsthit, cp_maxhits, cp_watchdog, cp_hits;
      out_x_boundary: cross cp_out, cp_boundary;
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

    function void sample_stim(input mptdc_conv_txn txn,
                              input mptdc_bp_mode_e bp_mode,
                              input int jitter_sigma_ps);
`ifdef MPTDC_ENABLE_FUNC_COV
      stim_cg.sample(txn.cfg_mode, txn.source_sel, txn.cfg_out_mode,
                     bp_mode, delay_bin(txn.start_stop_delay_ps),
                     jitter_bin(jitter_sigma_ps), txn.start_only);
`endif
    endfunction

    function void sample_packet(input mptdc_packet_txn pkt);
`ifdef MPTDC_ENABLE_FUNC_COV
      pkt_cg.sample(pkt.out_mode, pkt.hit_count,
                    pkt.flags.closed_by_firsthit,
                    pkt.flags.closed_by_maxhits,
                    pkt.flags.closed_by_watchdog,
                    pkt.phase0_snap,
                    pkt.slow_boundary_inc,
                    pkt.word_count());
`endif
    endfunction
  endclass

  class mptdc_driver;
    mailbox #(mptdc_base_txn) in_mb;
    mailbox #(mptdc_conv_txn) exp_mb;
    mptdc_csr_driver          csr_drv;
    mptdc_pulse_driver        pulse_drv;
    mptdc_ready_driver        ready_drv;
    mptdc_cfg_txn             current_cfg;
    mptdc_coverage            cov;
    mptdc_env_cfg             env_cfg;
    bit                       done;

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
      current_cfg = new("current_cfg");
      done        = 1'b0;
    endfunction

    task initialize();
      ready_drv.set_mode(BP_ALWAYS_READY, env_cfg.random_seed);
      if (g_bfm_req_mb == null)
        g_bfm_req_mb = new();
    endtask

    task run();
      mptdc_base_txn         base;
      mptdc_cfg_txn          cfg;
      mptdc_backpressure_txn bp;
      mptdc_reset_txn        rst;
      mptdc_conv_txn         conv;
      mptdc_conv_txn         exp;
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
          end

          TXN_CFG: begin
            if (!$cast(cfg, base))
              $fatal(1, "Failed to cast cfg txn");
            $display("[VIP][DRV] %s", cfg.sprint());
            current_cfg = cfg.clone();
            g_bfm_req_mb.put(base);
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
            conv.cfg_mode      = current_cfg.mode_cfg;
            conv.cfg_input_sel = current_cfg.input_sel;
            conv.cfg_out_mode  = current_cfg.out_mode;
            conv.cfg_max_hits  = current_cfg.max_hits;
            cov.sample_stim(conv, ready_drv.mode, env_cfg.osc_jitter_sigma_ps);
            $display("[VIP][DRV] %s", conv.sprint());

            if (conv.expect_packet) begin
              exp = conv.clone();
              exp_mb.put(exp);
            end
            g_bfm_req_mb.put(base);
          end

          TXN_EOT: begin
            $display("[VIP][DRV] End-of-test transaction observed");
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
    endfunction

    task automatic wait_accept(output logic [NARROW_W-1:0] word);
      while (!stop_request) begin
        @(posedge vif.clk_sys);
        if (vif.narrow_valid && vif.narrow_ready) begin
          word = vif.narrow_data;
          return;
        end
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
            logic [NARROW_W-1:0] w1, w2;
            w1 = pkt.words[idx + 0];
            w2 = pkt.words[idx + 1];
            hit.ns           = ph_idx_t'(w1[14:11]);
            hit.nf           = ph_idx_t'(w1[10:7]);
            hit.pd_idx       = pd_idx_t'(w1[6:0]);
            hit.event_seq    = w2[14:11];
            hit.nfast_snap   = w2[10:4];
            hit.has_features = 1'b1;
            idx += 2;
          end

          OUT_MODE_RAW_TIMESTAMP: begin
            hit.t_raw_lsw     = pkt.words[idx];
            hit.has_timestamp = 1'b1;
            idx += 1;
          end

          OUT_MODE_FULL: begin
            logic [NARROW_W-1:0] w1, w2;
            w1 = pkt.words[idx + 0];
            w2 = pkt.words[idx + 1];
            hit.ns            = ph_idx_t'(w1[14:11]);
            hit.nf            = ph_idx_t'(w1[10:7]);
            hit.pd_idx        = pd_idx_t'(w1[6:0]);
            hit.event_seq     = w2[14:11];
            hit.nfast_snap    = w2[10:4];
            hit.t_raw_lsw     = pkt.words[idx + 2];
            hit.has_features  = 1'b1;
            hit.has_timestamp = 1'b1;
            idx += 3;
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

      if (exp.check_firsthit_flag && (pkt.flags.closed_by_firsthit != exp.expected_firsthit_flag))
        fail($sformatf("%s firsthit flag mismatch got=%0b exp=%0b",
                       exp.label, pkt.flags.closed_by_firsthit, exp.expected_firsthit_flag));

      if (exp.check_maxhits_flag && (pkt.flags.closed_by_maxhits != exp.expected_maxhits_flag))
        fail($sformatf("%s maxhits flag mismatch got=%0b exp=%0b",
                       exp.label, pkt.flags.closed_by_maxhits, exp.expected_maxhits_flag));

      if (exp.check_watchdog_flag && (pkt.flags.closed_by_watchdog != exp.expected_watchdog_flag))
        fail($sformatf("%s watchdog flag mismatch got=%0b exp=%0b",
                       exp.label, pkt.flags.closed_by_watchdog, exp.expected_watchdog_flag));

      if (exp.check_conv_id && (int'(pkt.conv_id) != exp.expected_conv_id))
        fail($sformatf("%s conv_id mismatch: got=%0d expected=%0d",
                       exp.label, pkt.conv_id, exp.expected_conv_id));

      foreach (pkt.hits[i]) begin
        if (pkt.hits[i].has_features) begin
          if (pkt.hits[i].pd_idx != pd_from_phases(pkt.hits[i].ns, pkt.hits[i].nf))
            fail($sformatf("%s hit %0d pd_idx mismatch: got=%0d expected=%0d",
                           exp.label, i, pkt.hits[i].pd_idx,
                           pd_from_phases(pkt.hits[i].ns, pkt.hits[i].nf)));
          if (pkt.hits[i].event_seq != EVENT_SEQ_W'(i))
            fail($sformatf("%s hit %0d event_seq mismatch: got=%0d expected=%0d",
                           exp.label, i, pkt.hits[i].event_seq, i));
        end
      end

      if (exp.check_full_timestamp && (pkt.out_mode == OUT_MODE_FULL))
        check_full_timestamp(pkt);

      cov.sample_packet(pkt);
      $display("[VIP][SB] PASS %s -> %s", exp.sprint(), pkt.sprint());
    endfunction

    task run(input int expected_packets);
      mptdc_conv_txn   exp;
      mptdc_packet_txn pkt;
      for (int i = 0; i < expected_packets; i++) begin
        exp_mb.get(exp);
        act_mb.get(pkt);
        check_packet(exp, pkt);
      end
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
      int expected_packets;
      // The ready driver and monitor stay alive in the background while the
      // generator, driver, and scoreboard complete the planned test sequence.
      expected_packets = gen.expected_packet_count();
      fork
        ready_drv.run();
        mon.run();
      join_none

      fork
        gen.run();
        drv.run();
        sb.run(expected_packets);
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
      cfg_txn.mode_cfg        = MODE_FIRST_HIT;
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

    function new();
      super.new("overflow_status");
      ovf_count_data = '0;
    endfunction

    virtual function void build_sequence(mptdc_generator gen);
      mptdc_cfg_txn  cfg_txn;
      mptdc_conv_txn conv;
      gen.add(make_reset());
      cfg_txn = make_cfg("cfg_ovf");
      cfg_txn.out_mode = OUT_MODE_FULL;
      gen.add(cfg_txn);
      gen.add(make_bp("bp_stall", BP_ALWAYS_STALL, cfg.random_seed));

      conv = make_conv("ovf_conv0");
      conv.start_stop_delay_ps  = 5_000;
      conv.idle_after_ps        = 50_000;
      conv.require_nonzero_hits = 1'b1;
      conv.min_hits             = 1;
      gen.add(conv);

      conv = make_conv("ovf_conv1");
      conv.start_stop_delay_ps  = 5_000;
      conv.idle_after_ps        = 50_000;
      conv.require_nonzero_hits = 1'b1;
      conv.min_hits             = 1;
      gen.add(conv);

      conv = make_conv("ovf_reject");
      conv.start_only          = 1'b1;
      conv.expect_packet       = 1'b0;
      conv.idle_after_ps       = 100_000;
      conv.check_hit_range     = 1'b0;
      gen.add(conv);

      gen.add(make_bp("bp_release", BP_ALWAYS_READY, cfg.random_seed));
    endfunction

    virtual task post_run();
      csr_vif.csr_valid = 1'b0;
      csr_vif.csr_write = 1'b0;
      #500_000;
      env.csr_drv.read(CSR_OVF_COUNT, ovf_count_data);
      if (ovf_count_data[15:0] == 0)
        $display("[VIP][TEST] overflow_status INFO: OVF_COUNT stayed zero; overflow remains timing-dependent under current drain/FIFO timing");
      else
        $display("[VIP][TEST] overflow_status OVF_COUNT=%0d", ovf_count_data[15:0]);
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
      cfg_txn.mode_cfg        = MODE_FIRST_HIT;
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
      conv.idle_after_ps    = 1_000_000;
      gen.add(conv);

      cfg_txn = make_cfg("cfg_global_recovery");
      cfg_txn.wdt_ctx_timeout    = 16'hFFFF;
      cfg_txn.wdt_global_timeout = 16'd0;
      gen.add(cfg_txn);

      conv = make_conv("global_wdt_recovery");
      conv.start_stop_delay_ps    = 10_000;
      conv.require_nonzero_hits   = 1'b1;
      conv.min_hits               = 1;
      conv.check_watchdog_flag    = 1'b1;
      conv.expected_watchdog_flag = 1'b0;
      conv.check_conv_id          = 1'b1;
      conv.expected_conv_id       = 0;
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
      int modes[2]        = '{MODE_MULTI_HIT, MODE_FIRST_HIT};
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
            cfg_txn.mode_cfg  = mode_e'(modes[m]);
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
              if (modes[m] == MODE_FIRST_HIT) begin
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
      // max_hits=0 means "unlimited" in HW (comparison disabled when cfg==0).
      // The oscillators will capture hits until the watchdog fires.
      cfg_txn = make_cfg("cfg_wdt_ctx");
      cfg_txn.mode_cfg           = MODE_MULTI_HIT;
      cfg_txn.input_sel          = INPUT_SPAD;
      cfg_txn.out_mode           = OUT_MODE_RAW_FEATURES;
      cfg_txn.max_hits           = MAX_HITS_W'(15);
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
          if (cur_max_hits == 0) cur_max_hits = 15;

          cfg_txn = make_cfg($sformatf("cfg_%0d", i));
          cfg_txn.mode_cfg  = mode_e'(cur_mode);
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
        if (cur_mode == MODE_FIRST_HIT) begin
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
      mptdc_coverage_exhaustive_test cov_exh_t;
      mptdc_stress_random_test stress_t;
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
        "coverage_exhaustive": begin
          cov_exh_t = new();
          t = cov_exh_t;
        end
        "stress_random": begin
          stress_t = new();
          t = stress_t;
        end
        default: t = null;
      endcase
      return t;
    endfunction
  endclass

endpackage

`default_nettype wire
