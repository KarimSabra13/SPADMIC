// =============================================================================
// SPADMIC VIP — Scoreboard + End-to-End Packet Checker
// =============================================================================

class spadmic_scoreboard;

  mailbox #(spadmic_base_txn)  stim_mb;   // from driver
  mailbox #(spadmic_base_txn)  mon_mb;    // from TX monitor
  spadmic_env_cfg              cfg;

  // Reference models
  spadmic_tdc_ref_model  tdc_ref;
  spadmic_pos_ref_model  pos_ref;

  // Counters
  int unsigned tdc_pkts_expected;
  int unsigned tdc_pkts_received;
  int unsigned pos_pkts_expected;
  int unsigned pos_pkts_received;
  int unsigned pkts_expected_by_source [SPADMIC_SRC_COUNT];
  int unsigned pkts_received_by_source [SPADMIC_SRC_COUNT];
  int unsigned next_event_id_by_source [SPADMIC_SRC_COUNT];
  int unsigned check_pass;
  int unsigned check_fail;
  int unsigned resets_seen;

  // Active configuration (updated on CTRL txns)
  logic        active_global_enable;
  spadmic_tx_sel_e active_tx_sel;
  logic [2:0]  active_axis_enable;
  logic        active_position_enable;
  out_mode_e   active_out_mode;
  logic [MAX_HITS_W-1:0] active_max_hits;
  input_sel_e  active_input_sel;
  spadmic_pos_mode_e active_pos_mode;
  spadmic_spad_reset_mode_e active_spad_reset_mode;
  logic [31:0] active_spad_reset_period;
  logic [SPADMIC_LINE_COUNT_W-1:0] active_pos_gap_threshold;
  logic [SPADMIC_LINE_COUNT_W-1:0] active_pos_min_cluster_span;
  logic [3:0]  active_pos_settle_cycles;

  typedef struct {
    spadmic_pos_mode_e         mode;
    logic [SPADMIC_LINE_W-1:0] x_pattern;
    logic [SPADMIC_LINE_W-1:0] y_pattern;
    logic [SPADMIC_LINE_W-1:0] z_pattern;
    logic [SPADMIC_LINE_COUNT_W-1:0] gap_threshold;
    logic [SPADMIC_LINE_COUNT_W-1:0] min_cluster_span;
  } expected_pos_packet_t;

  expected_pos_packet_t expected_pos_q[$];
  int unsigned spad_reset_pulses_expected_min;
  int unsigned spad_reset_pulses_received;
  int unsigned spad_reset_width_errors;

`ifdef SPADMIC_ENABLE_FUNC_COV
  spadmic_pkt_cov pkt_cov;
  spadmic_reset_cov reset_cov;
`endif

  bit done;

  function new(
    mailbox #(spadmic_base_txn) stim_mb,
    mailbox #(spadmic_base_txn) mon_mb,
    spadmic_env_cfg             cfg
`ifdef SPADMIC_ENABLE_FUNC_COV
    ,
    spadmic_pkt_cov             pkt_cov,
    spadmic_reset_cov           reset_cov
`endif
  );
    this.stim_mb           = stim_mb;
    this.mon_mb            = mon_mb;
    this.cfg               = cfg;
    this.tdc_ref           = new();
    this.pos_ref           = new();
    this.tdc_pkts_expected = 0;
    this.tdc_pkts_received = 0;
    this.pos_pkts_expected = 0;
    this.pos_pkts_received = 0;
    this.check_pass        = 0;
    this.check_fail        = 0;
    this.resets_seen       = 0;
    this.done              = 1'b0;
    this.active_global_enable = 1'b0;
    this.active_tx_sel     = SPADMIC_TX_TDC;
    this.active_axis_enable = 3'b111;
    this.active_position_enable = 1'b0;
    this.active_out_mode   = OUT_MODE_RAW_FEATURES;
    this.active_max_hits   = 4'd15;
    this.active_input_sel  = INPUT_CAL;
    this.active_pos_mode   = SPADMIC_POS_MODE_CLUSTER;
    this.active_spad_reset_mode = SPADMIC_SPAD_RST_MANUAL_ONLY;
    this.active_spad_reset_period = 32'd0;
    this.active_pos_gap_threshold = 7'd2;
    this.active_pos_min_cluster_span = 7'd2;
    this.active_pos_settle_cycles = 4'd1;
    this.spad_reset_pulses_expected_min = 0;
    this.spad_reset_pulses_received = 0;
    this.spad_reset_width_errors = 0;
`ifdef SPADMIC_ENABLE_FUNC_COV
    this.pkt_cov           = pkt_cov;
    this.reset_cov         = reset_cov;
`endif
    for (int src = 0; src < SPADMIC_SRC_COUNT; src++) begin
      this.pkts_expected_by_source[src] = 0;
      this.pkts_received_by_source[src] = 0;
      this.next_event_id_by_source[src] = 0;
    end
  endfunction

  function automatic void apply_reset_defaults();
    active_global_enable   = 1'b0;
    active_tx_sel          = SPADMIC_TX_TDC;
    active_axis_enable     = 3'b111;
    active_position_enable = 1'b1;
    active_out_mode        = OUT_MODE_RAW_FEATURES;
    active_max_hits        = 4'd15;
    active_input_sel       = INPUT_SPAD;
    active_pos_mode        = SPADMIC_POS_MODE_CLUSTER;
    active_spad_reset_mode = SPADMIC_SPAD_RST_MANUAL_ONLY;
    active_spad_reset_period = 32'd0;
    active_pos_gap_threshold = 7'd2;
    active_pos_min_cluster_span = 7'd2;
    active_pos_settle_cycles = 4'd1;
    expected_pos_q.delete();
  endfunction

  task automatic run();
    fork
      stim_run();
      monitor_run();
    join_none

    while (!done || (mon_mb.num() != 0))
      #1;

    disable fork;
  endtask

  task automatic stim_run();
    spadmic_base_txn txn;
    done = 1'b0;

    forever begin
      stim_mb.get(txn);

      case (txn.kind)
        TXN_CTRL: begin
          spadmic_ctrl_txn ct;
          $cast(ct, txn);
          update_config(ct);
        end

        TXN_TDC_EVENT: begin
          spadmic_tdc_event_txn et;
          $cast(et, txn);
          if (active_global_enable
              && (spadmic_export_mode_from_ctrl(active_tx_sel, active_position_enable)
                  != SPADMIC_EXPORT_POSITION_ONLY)
              && axis_expected_for_input(et.use_spad)
              && active_axis_enabled(et.axis)) begin
            tdc_pkts_expected += et.num_conversions;
            pkts_expected_by_source[et.axis] += et.num_conversions;
          end
          $display("[SB] TDC event: axis=%0d convs=%0d (total expected=%0d)",
                   et.axis, et.num_conversions, tdc_pkts_expected);
        end

        TXN_POS_EVENT: begin
          if (active_global_enable
              && (spadmic_export_mode_from_ctrl(active_tx_sel, active_position_enable)
                  != SPADMIC_EXPORT_TDC_ONLY)
              && active_position_enable) begin
            spadmic_pos_event_txn pet;
            if ($cast(pet, txn) &&
                (pet.x_pattern != '0 || pet.y_pattern != '0 || pet.z_pattern != '0)) begin
              pos_pkts_expected++;
              pkts_expected_by_source[SPADMIC_SRC_POSITION]++;
              push_expected_pos(pet.x_pattern, pet.y_pattern, pet.z_pattern);
            end else
              $display("[SB] POS event skipped (empty axis pattern — no packet expected)");
          end
          $display("[SB] POS event (total expected=%0d)", pos_pkts_expected);
        end

        TXN_CORRELATED_EVENT: begin
          spadmic_correlated_event_txn ct;
          $cast(ct, txn);
          if (active_global_enable) begin
            if ((spadmic_export_mode_from_ctrl(active_tx_sel, active_position_enable)
                 != SPADMIC_EXPORT_POSITION_ONLY)
                && axis_expected_for_input(ct.use_spad)) begin
              for (int ax = 0; ax < 3; ax++) begin
                if (ct.axis_mask[ax] && active_axis_enabled(ax)) begin
                  tdc_pkts_expected++;
                  pkts_expected_by_source[ax]++;
                end
              end
            end

            if ((spadmic_export_mode_from_ctrl(active_tx_sel, active_position_enable)
                 != SPADMIC_EXPORT_TDC_ONLY)
                && active_position_enable
                && ct.position_present
                && ((ct.x_pattern != '0) || (ct.y_pattern != '0) || (ct.z_pattern != '0))) begin
              pos_pkts_expected++;
              pkts_expected_by_source[SPADMIC_SRC_POSITION]++;
              push_expected_pos(ct.x_pattern, ct.y_pattern, ct.z_pattern);
            end
          end
          $display("[SB] CORR event: mask=%03b pos=%0b (tdc_exp=%0d pos_exp=%0d)",
                   ct.axis_mask, ct.position_present, tdc_pkts_expected, pos_pkts_expected);
        end

        TXN_RESET: begin
          resets_seen++;
          // Reset clears in-flight state — adjust expectations
          $display("[SB] Reset #%0d — clearing in-flight expectations", resets_seen);
          tdc_pkts_expected = tdc_pkts_received;
          pos_pkts_expected = pos_pkts_received;
          apply_reset_defaults();
          for (int src = 0; src < SPADMIC_SRC_COUNT; src++) begin
            pkts_expected_by_source[src] = pkts_received_by_source[src];
            next_event_id_by_source[src] = 0;
          end
        end

        TXN_EOT: begin
          done = 1'b1;
          return;
        end

        TXN_SPAD_RESET: begin
          spadmic_spad_reset_txn rt;
          if ($cast(rt, txn))
            notify_spad_reset(rt);
        end

        default: ;
      endcase
    end
  endtask

  task automatic monitor_run();
    spadmic_base_txn  btxn;
    spadmic_mon_pkt_txn mtxn;
    spadmic_spad_reset_txn rtxn;
    bit ref_ok;

    forever begin
      if (stim_mb.num() != 0) begin
        #1;
        continue;
      end

      if (!mon_mb.try_get(btxn)) begin
        #1;
        continue;
      end
      if ($cast(rtxn, btxn)) begin
        notify_spad_reset(rtxn);
        continue;
      end
      if (!$cast(mtxn, btxn)) continue;

      if (mtxn.is_tdc) begin
        if (spadmic_export_mode_from_ctrl(active_tx_sel, active_position_enable)
            == SPADMIC_EXPORT_POSITION_ONLY) begin
          check_fail++;
          $display("[SB] FAIL: observed TDC packet while export mode is POSITION_ONLY");
        end
        ref_ok = tdc_ref.validate_tdc_packet(
          mtxn.words, mtxn.source_id,
          active_out_mode, active_max_hits);
        if (!ref_ok) check_fail++;
        notify_tdc_packet(mtxn.source_id, mtxn.word_count, mtxn.event_id, mtxn.words);
      end else begin
        if (spadmic_export_mode_from_ctrl(active_tx_sel, active_position_enable)
            == SPADMIC_EXPORT_TDC_ONLY) begin
          check_fail++;
          $display("[SB] FAIL: observed position packet while export mode is TDC_ONLY");
        end
        notify_pos_packet(mtxn.source_id, mtxn.word_count, mtxn.event_id, mtxn.words);
      end
    end
  endtask

  function automatic logic active_axis_enabled(input int unsigned axis);
    case (axis)
      0: return active_axis_enable[0];
      1: return active_axis_enable[1];
      2: return active_axis_enable[2];
      default: return 1'b0;
    endcase
  endfunction

  function automatic logic axis_expected_for_input(input logic use_spad);
    return use_spad ? (active_input_sel == INPUT_SPAD)
                    : (active_input_sel == INPUT_CAL);
  endfunction

  function automatic int reset_period_class();
    if (active_spad_reset_period == 32'd0)
      return 0;
    if (active_spad_reset_period <= 32'd16)
      return 1;
    return 2;
  endfunction

  function automatic void push_expected_pos(
    logic [SPADMIC_LINE_W-1:0] x_pattern,
    logic [SPADMIC_LINE_W-1:0] y_pattern,
    logic [SPADMIC_LINE_W-1:0] z_pattern
  );
    expected_pos_packet_t exp;
    exp.mode = active_pos_mode;
    exp.x_pattern = x_pattern;
    exp.y_pattern = y_pattern;
    exp.z_pattern = z_pattern;
    exp.gap_threshold = active_pos_gap_threshold;
    exp.min_cluster_span = active_pos_min_cluster_span;
    expected_pos_q.push_back(exp);
  endfunction

  function void update_config(spadmic_ctrl_txn ct);
    if (!ct.is_read && ct.raw_csr_write) begin
      case (ct.addr)
        SPADMIC_CSR_POS_CTRL: begin
          active_pos_mode = spadmic_pos_mode_e'(ct.wdata[1]);
          active_spad_reset_mode = spadmic_spad_reset_mode_e'(ct.wdata[3:2]);
          if (ct.wdata[4]) begin
            spad_reset_pulses_expected_min++;
          end else if ((spadmic_spad_reset_mode_e'(ct.wdata[3:2]) != SPADMIC_SPAD_RST_MANUAL_ONLY)
                       && (active_spad_reset_period != 32'd0)) begin
            spad_reset_pulses_expected_min++;
          end
        end

        SPADMIC_CSR_POS_GAP_CFG: begin
          active_pos_gap_threshold = ct.wdata[SPADMIC_LINE_COUNT_W-1:0];
        end

        SPADMIC_CSR_POS_FILTER_CFG: begin
          active_pos_min_cluster_span = ct.wdata[SPADMIC_LINE_COUNT_W-1:0];
          active_pos_settle_cycles = ct.wdata[11:8];
        end

        SPADMIC_CSR_POS_RESET_CFG: begin
          active_spad_reset_period = ct.wdata;
        end

        default: ;
      endcase
      $display("[SB] Raw CSR write model: addr=0x%03h data=0x%08h pos_mode=%s rst_mode=%s period=%0d",
               ct.addr, ct.wdata, active_pos_mode.name(),
               active_spad_reset_mode.name(), active_spad_reset_period);
    end else if (!ct.is_read) begin
      active_global_enable = ct.global_enable;
      active_tx_sel        = ct.shared_tx_sel;
      active_axis_enable   = ct.axis_enable;
      active_position_enable = ct.position_enable;
      active_out_mode      = ct.tdc_out_mode;
      active_max_hits      = ct.max_hits;
      active_input_sel     = ct.tdc_input_sel;
      $display("[SB] Config update: en=%0b sel=%s pos=%0b mode=%s hits=%0d in=%s",
               active_global_enable, active_tx_sel.name(), active_position_enable,
               active_out_mode.name(), active_max_hits,
               active_input_sel.name());
    end
  endfunction

  function automatic void note_packet_common(
    input int unsigned source_id,
    input int unsigned event_id
  );
    if (source_id >= SPADMIC_SRC_COUNT) begin
      check_fail++;
      $display("[SB] FAIL: source_id %0d outside expected range", source_id);
      return;
    end

    if (pkts_received_by_source[source_id] >= pkts_expected_by_source[source_id]) begin
      check_fail++;
      $display("[SB] FAIL: unexpected extra packet for source %0d", source_id);
    end

    if (event_id != next_event_id_by_source[source_id]) begin
      check_fail++;
      $display("[SB] FAIL: source %0d event_id %0d != expected %0d",
               source_id, event_id, next_event_id_by_source[source_id]);
      next_event_id_by_source[source_id] = event_id + 1;
    end else begin
      next_event_id_by_source[source_id]++;
    end

    pkts_received_by_source[source_id]++;
  endfunction

  // Called by harness when TX monitor captures a complete packet
  function void notify_tdc_packet(
    int unsigned source_id,
    int unsigned word_count,
    int unsigned event_id,
    logic [NARROW_W-1:0] words[$]
  );
    logic [NARROW_W-1:0] hdr;
    tdc_pkts_received++;
    note_packet_common(source_id, event_id);
    hdr = (words.size() > 0) ? words[0] : '0;
`ifdef SPADMIC_ENABLE_FUNC_COV
    if (words.size() > 0)
      pkt_cov.sample_tdc(source_id[1:0], hdr[10:7], hdr[2:1], hdr[6:3], hdr[0]);
`endif
    if (source_id == SPADMIC_SRC_POSITION) begin
      check_fail++;
      $display("[SB] FAIL: TDC packet reported POSITION source");
    end else begin
      check_pass++;
    end
    $display("[SB] TDC pkt received: src=%0d words=%0d (received=%0d/%0d)",
              source_id, word_count, tdc_pkts_received, tdc_pkts_expected);
  endfunction

  function void notify_pos_packet(
    int unsigned source_id,
    int unsigned word_count,
    int unsigned event_id,
    logic [NARROW_W-1:0] words[$]
  );
    logic [NARROW_W-1:0] hdr;
    logic [NARROW_W-1:0] eoc;
    expected_pos_packet_t exp;
    bit have_expected;
    bit ref_ok;
    pos_pkts_received++;
    note_packet_common(source_id, event_id);
    hdr = (words.size() > 0) ? words[0] : '0;
    eoc = (words.size() > 0) ? words[words.size()-1] : '0;
    have_expected = (expected_pos_q.size() != 0);
    if (have_expected)
      exp = expected_pos_q.pop_front();
`ifdef SPADMIC_ENABLE_FUNC_COV
    if (words.size() > 0)
      pkt_cov.sample_pos(pos_kind_from_words(words), hdr[12], hdr[11:9], hdr[8:6],
                         eoc[13:0], word_count, words);
`endif
    if ((have_expected && (exp.mode == SPADMIC_POS_MODE_RAW))
        || ((words.size() > 0) && is_spadmic_pos_raw_header(words[0]))) begin
      ref_ok = pos_ref.validate_raw_pos_packet(
        words,
        have_expected ? exp.x_pattern : '0,
        have_expected ? exp.y_pattern : '0,
        have_expected ? exp.z_pattern : '0,
        have_expected
      );
      if (!ref_ok) begin
        check_fail++;
      end else if (source_id != SPADMIC_SRC_POSITION) begin
        check_fail++;
        $display("[SB] FAIL: raw POS pkt source=%0d != POSITION(%0d)",
                 source_id, SPADMIC_SRC_POSITION);
      end else begin
        check_pass++;
      end
    end else if (word_count != SPADMIC_POS_PKT_WORDS) begin
      check_fail++;
      $display("[SB] FAIL: POS cluster pkt has %0d words (expected %0d)",
                word_count, SPADMIC_POS_PKT_WORDS);
    end else if (source_id != SPADMIC_SRC_POSITION) begin
      check_fail++;
      $display("[SB] FAIL: POS pkt source=%0d != POSITION(%0d)",
               source_id, SPADMIC_SRC_POSITION);
    end else begin
      if (have_expected) begin
        ref_ok = pos_ref.validate_pos_packet(
          words,
          exp.x_pattern,
          exp.y_pattern,
          exp.z_pattern,
          exp.gap_threshold,
          exp.min_cluster_span
        );
      end else begin
        ref_ok = 1'b1;
      end

      if (!ref_ok)
        check_fail++;
      else
        check_pass++;
    end
    $display("[SB] POS pkt received: words=%0d (received=%0d/%0d)",
              word_count, pos_pkts_received, pos_pkts_expected);
  endfunction

  function automatic spadmic_mon_pkt_kind_e pos_kind_from_words(logic [NARROW_W-1:0] words[$]);
    if ((words.size() > 0) && is_spadmic_pos_raw_header(words[0]))
      return MON_PKT_POS_RAW;
    return MON_PKT_POS_CLUSTER;
  endfunction

  function void notify_spad_reset(spadmic_spad_reset_txn rt);
    spad_reset_pulses_received++;
    if (rt.pulse_width_cycles != 1) begin
      spad_reset_width_errors++;
      check_fail++;
      $display("[SB] FAIL: SPAD reset pulse width=%0d cycles", rt.pulse_width_cycles);
    end else begin
      check_pass++;
    end
`ifdef SPADMIC_ENABLE_FUNC_COV
    reset_cov.sample(active_spad_reset_mode, reset_period_class(), rt.pulse_width_cycles,
                     !((tdc_pkts_received == tdc_pkts_expected)
                       && (pos_pkts_received == pos_pkts_expected)));
`endif
  endfunction

  function void report();
    $display("");
    $display("╔═══════════════════════════════════════════════════╗");
    $display("║            SCOREBOARD SUMMARY                    ║");
    $display("╠═══════════════════════════════════════════════════╣");
    $display("║  TDC packets:  expected=%4d  received=%4d       ║",
             tdc_pkts_expected, tdc_pkts_received);
    $display("║  POS packets:  expected=%4d  received=%4d       ║",
             pos_pkts_expected, pos_pkts_received);
    $display("║  Checks:       pass=%4d  fail=%4d               ║",
             check_pass, check_fail);
    $display("║  Resets:       %4d                               ║", resets_seen);
    $display("║  SPAD resets:  exp>=%4d seen=%4d width_err=%4d ║",
             spad_reset_pulses_expected_min, spad_reset_pulses_received,
             spad_reset_width_errors);
    $display("╠═══════════════════════════════════════════════════╣");
    if (check_fail == 0 &&
        tdc_pkts_received == tdc_pkts_expected &&
        pos_pkts_received == pos_pkts_expected &&
        spad_reset_pulses_received >= spad_reset_pulses_expected_min)
      $display("║              *** PASS ***                        ║");
    else
      $display("║              *** FAIL ***                        ║");
    $display("╚═══════════════════════════════════════════════════╝");
    $display("");
  endfunction

endclass
