// =============================================================================
// SPADMIC VIP — TX Packet Monitor
// Captures chip_tx words, assembles packets, and dispatches to scoreboard.
// =============================================================================

class spadmic_tx_monitor;

  virtual spadmic_narrow_tx_if tx_if;
  mailbox #(spadmic_base_txn)  sb_mb;     // to scoreboard
  mailbox #(int)               cov_mb;    // to coverage (packet events)
  spadmic_runtime_state        state;

  // Packet assembly state
  typedef struct {
    logic [NARROW_W-1:0] words[$];
      logic                is_tdc;     // 1=TDC, 0=Position
      int unsigned         source_id;  // TDC axis or POSITION
      int unsigned         event_id;   // shared correlated-event ID from EOC
      longint unsigned     timestamp;
  } captured_packet_t;

  int unsigned total_packets;
  int unsigned total_words;
  bit          running;

  function new(
    virtual spadmic_narrow_tx_if tx_if,
    mailbox #(spadmic_base_txn)  sb_mb,
    mailbox #(int)               cov_mb,
    spadmic_runtime_state        state
  );
    this.tx_if         = tx_if;
    this.sb_mb         = sb_mb;
    this.cov_mb        = cov_mb;
    this.state         = state;
    this.total_packets = 0;
    this.total_words   = 0;
    this.running       = 1'b0;
  endfunction

  task automatic run();
    logic [NARROW_W-1:0] word;
    captured_packet_t    pkt;
    bit                  in_packet;

    running   = 1'b1;
    in_packet = 1'b0;
    pkt.words = {};

    forever begin
      @(posedge tx_if.clk_sys);
      if (!tx_if.rst_n) begin
        in_packet = 1'b0;
        pkt.words = {};
        continue;
      end

      if (tx_if.valid) begin
        word = tx_if.data;
        total_words++;

        if (!in_packet && (is_tdc_header(word) || is_spadmic_pos_cluster_header(word))) begin
          // New packet starts (TDC, cluster-position, and raw-position headers
          // use header markers; cluster-position uses 2'b01.
          pkt.words = {};
          pkt.words.push_back(word);
          if (is_spadmic_pos_cluster_header(word)) begin
            pkt.is_tdc    = 1'b0;
            pkt.source_id = SPADMIC_SRC_POSITION;
          end else if (state.raw_pos_allowed() && is_spadmic_pos_raw_header(word)) begin
            pkt.is_tdc    = 1'b0;
            pkt.source_id = SPADMIC_SRC_POSITION;
          end else begin
            pkt.is_tdc    = 1'b1;
            pkt.source_id = tdc_header_source_id(word);
          end
          pkt.event_id  = 0;
          pkt.timestamp = $time;
          in_packet     = 1'b1;
        end else if (in_packet) begin
          pkt.words.push_back(word);

          if (!pkt.is_tdc && is_spadmic_pos_raw_header(pkt.words[0])) begin
            if (pkt.words.size() == SPADMIC_POS_RAW_PKT_WORDS) begin
              pkt.event_id = word[13:0];
              dispatch_packet(pkt);
              pkt.words = {};
              in_packet = 1'b0;
            end
          end else if (is_tdc_eoc(word)) begin
            pkt.event_id = word[13:0];
            dispatch_packet(pkt);
            pkt.words = {};
            in_packet = 1'b0;
          end else begin
            if (is_spadmic_subheader(word)) begin
              pkt.source_id = word[5:4];
              if (word[5:4] == SPADMIC_SRC_POSITION)
                pkt.is_tdc = 1'b0;
            end
          end
        end else if (is_tdc_header(word)) begin
          $display("[TX_MON] WARN: unreachable header decode for word 0x%04h", word);
        end
      end
    end
  endtask

  task automatic dispatch_packet(captured_packet_t pkt);
    spadmic_mon_pkt_txn mtxn;
    total_packets++;
    $display("[TX_MON] Packet #%0d: %s src=%0d event=%0d words=%0d @%0t",
             total_packets,
             pkt.is_tdc ? "TDC" : "POS",
             pkt.source_id,
             pkt.event_id,
             pkt.words.size(),
             pkt.timestamp);

    // Send to scoreboard
    mtxn = new();
    mtxn.is_tdc     = pkt.is_tdc;
    if (pkt.is_tdc)
      mtxn.pkt_kind = MON_PKT_TDC;
    else if ((pkt.words.size() > 0) && is_spadmic_pos_raw_header(pkt.words[0]))
      mtxn.pkt_kind = MON_PKT_POS_RAW;
    else
      mtxn.pkt_kind = MON_PKT_POS_CLUSTER;
    mtxn.source_id  = pkt.source_id;
    mtxn.word_count = pkt.words.size();
    mtxn.event_id   = pkt.event_id;
    mtxn.words      = pkt.words;
    mtxn.timestamp  = $time;
    sb_mb.put(mtxn);

    // Signal coverage sampler
    cov_mb.put(int'(total_packets));
  endtask

endclass
