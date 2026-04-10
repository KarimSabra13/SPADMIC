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
  int unsigned check_pass;
  int unsigned check_fail;
  int unsigned resets_seen;

  // Active configuration (updated on CTRL txns)
  logic        active_global_enable;
  spadmic_tx_sel_e active_tx_sel;
  out_mode_e   active_out_mode;
  logic [MAX_HITS_W-1:0] active_max_hits;

  bit done;

  function new(
    mailbox #(spadmic_base_txn) stim_mb,
    mailbox #(spadmic_base_txn) mon_mb,
    spadmic_env_cfg             cfg
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
    this.active_out_mode   = OUT_MODE_RAW_FEATURES;
    this.active_max_hits   = 4'd15;
  endfunction

  task automatic run();
    fork
      stim_run();
      monitor_run();
    join_any
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
          // Track expected packets
          if (active_global_enable && active_tx_sel == SPADMIC_TX_TDC)
            tdc_pkts_expected += et.num_conversions;
          $display("[SB] TDC event: axis=%0d convs=%0d (total expected=%0d)",
                   et.axis, et.num_conversions, tdc_pkts_expected);
        end

        TXN_POS_EVENT: begin
          if (active_global_enable && active_tx_sel == SPADMIC_TX_POSITION)
            pos_pkts_expected++;
          $display("[SB] POS event (total expected=%0d)", pos_pkts_expected);
        end

        TXN_RESET: begin
          resets_seen++;
          // Reset clears in-flight state — adjust expectations
          $display("[SB] Reset #%0d — clearing in-flight expectations", resets_seen);
          tdc_pkts_expected = tdc_pkts_received;
          pos_pkts_expected = pos_pkts_received;
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
      mon_mb.get(btxn);
      if (!$cast(mtxn, btxn)) continue;

      if (mtxn.is_tdc) begin
        ref_ok = tdc_ref.validate_tdc_packet(
          mtxn.words, mtxn.source_id,
          active_out_mode, active_max_hits);
        if (!ref_ok) check_fail++;
        notify_tdc_packet(mtxn.source_id, mtxn.word_count);
      end else begin
        ref_ok = pos_ref.validate_pos_packet(
          mtxn.words, '0, '0, '0, 0, 0);
        if (!ref_ok) check_fail++;
        notify_pos_packet(mtxn.word_count);
      end
    end
  endtask

  function void update_config(spadmic_ctrl_txn ct);
    if (!ct.is_read) begin
      active_global_enable = ct.global_enable;
      active_tx_sel        = ct.shared_tx_sel;
      active_out_mode      = ct.tdc_out_mode;
      active_max_hits      = ct.max_hits;
      $display("[SB] Config update: en=%0b sel=%s mode=%s hits=%0d",
               active_global_enable, active_tx_sel.name(),
               active_out_mode.name(), active_max_hits);
    end
  endfunction

  // Called by harness when TX monitor captures a complete packet
  function void notify_tdc_packet(int unsigned source_id, int unsigned word_count);
    tdc_pkts_received++;
    check_pass++;
    $display("[SB] TDC pkt received: src=%0d words=%0d (received=%0d/%0d)",
             source_id, word_count, tdc_pkts_received, tdc_pkts_expected);
  endfunction

  function void notify_pos_packet(int unsigned word_count);
    pos_pkts_received++;
    if (word_count != SPADMIC_POS_PKT_WORDS) begin
      check_fail++;
      $display("[SB] FAIL: POS pkt has %0d words (expected %0d)",
               word_count, SPADMIC_POS_PKT_WORDS);
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
        tdc_pkts_received >= tdc_pkts_expected &&
        pos_pkts_received >= pos_pkts_expected)
      $display("║              *** PASS ***                        ║");
    else
      $display("║              *** FAIL ***                        ║");
    $display("╚═══════════════════════════════════════════════════╝");
    $display("");
  endfunction

endclass

