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

`ifdef SPADMIC_ENABLE_FUNC_COV
  spadmic_pkt_cov pkt_cov;
`endif

  bit done;

  function new(
    mailbox #(spadmic_base_txn) stim_mb,
    mailbox #(spadmic_base_txn) mon_mb,
    spadmic_env_cfg             cfg
`ifdef SPADMIC_ENABLE_FUNC_COV
    ,
    spadmic_pkt_cov             pkt_cov
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
`ifdef SPADMIC_ENABLE_FUNC_COV
    this.pkt_cov           = pkt_cov;
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

        default: ;
      endcase
    end
  endtask

  task automatic monitor_run();
    spadmic_base_txn  btxn;
    spadmic_mon_pkt_txn mtxn;
    bit ref_ok;

    forever begin
      if (!mon_mb.try_get(btxn)) begin
        #1;
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
        ref_ok = pos_ref.validate_pos_packet(
          mtxn.words, '0, '0, '0, 0, 0);
        if (!ref_ok) check_fail++;
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

  function void update_config(spadmic_ctrl_txn ct);
    if (!ct.is_read) begin
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
    pos_pkts_received++;
    note_packet_common(source_id, event_id);
    hdr = (words.size() > 0) ? words[0] : '0;
    eoc = (words.size() > 0) ? words[words.size()-1] : '0;
`ifdef SPADMIC_ENABLE_FUNC_COV
    if (words.size() > 0)
      pkt_cov.sample_pos(hdr[12], hdr[11:9], hdr[8:6], eoc[13:0]);
`endif
    if (word_count != SPADMIC_POS_PKT_WORDS) begin
      check_fail++;
      $display("[SB] FAIL: POS pkt has %0d words (expected %0d)",
                word_count, SPADMIC_POS_PKT_WORDS);
    end else if (source_id != SPADMIC_SRC_POSITION) begin
      check_fail++;
      $display("[SB] FAIL: POS pkt source=%0d != POSITION(%0d)",
               source_id, SPADMIC_SRC_POSITION);
    end else begin
      check_pass++;
    end
    $display("[SB] POS pkt received: words=%0d (received=%0d/%0d)",
             word_count, pos_pkts_received, pos_pkts_expected);
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
    $display("╠═══════════════════════════════════════════════════╣");
    if (check_fail == 0 &&
        tdc_pkts_received == tdc_pkts_expected &&
        pos_pkts_received == pos_pkts_expected)
      $display("║              *** PASS ***                        ║");
    else
      $display("║              *** FAIL ***                        ║");
    $display("╚═══════════════════════════════════════════════════╝");
    $display("");
  endfunction

endclass
