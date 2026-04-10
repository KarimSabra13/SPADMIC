// =============================================================================
// SPADMIC VIP — TX Packet Monitor
// Captures chip_tx words, assembles packets, and dispatches to scoreboard.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_tx_monitor;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  virtual spadmic_narrow_tx_if tx_if;
  mailbox #(spadmic_base_txn)  sb_mb;     // to scoreboard
  mailbox #(int)               cov_mb;    // to coverage (packet events)

  // Packet assembly state
  typedef struct {
    logic [NARROW_W-1:0] words[$];
    logic                is_tdc;     // 1=TDC, 0=Position
    int unsigned         source_id;  // TDC axis or POSITION
    longint unsigned     timestamp;
  } captured_packet_t;

  int unsigned total_packets;
  int unsigned total_words;
  bit          running;

  function new(
    virtual spadmic_narrow_tx_if tx_if,
    mailbox #(spadmic_base_txn)  sb_mb,
    mailbox #(int)               cov_mb
  );
    this.tx_if         = tx_if;
    this.sb_mb         = sb_mb;
    this.cov_mb        = cov_mb;
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

      if (tx_if.valid && tx_if.ready) begin
        word = tx_if.data;
        total_words++;

        if (is_tdc_header(word)) begin
          // New packet starts (TDC and position share the 3'b100 header encoding)
          if (in_packet && pkt.words.size() > 0)
            dispatch_packet(pkt);  // flush any incomplete packet
          pkt.words = {};
          pkt.words.push_back(word);
          pkt.is_tdc    = 1'b1;  // tentatively TDC; corrected upon subheader
          pkt.source_id = 0;
          pkt.timestamp = $time;
          in_packet     = 1'b1;
        end else if (in_packet && is_tdc_eoc(word)) begin
          // End of current packet
          pkt.words.push_back(word);
          dispatch_packet(pkt);
          pkt.words = {};
          in_packet = 1'b0;
        end else if (in_packet) begin
          // Mid-packet word
          pkt.words.push_back(word);
          // Detect subheader to classify packet type and extract source
          if (is_tdc_subheader(word)) begin
            pkt.source_id = word[5:4];
            if (word[5:4] == SPADMIC_SRC_POSITION)
              pkt.is_tdc = 1'b0;
          end
        end
      end
    end
  endtask

  task automatic dispatch_packet(captured_packet_t pkt);
    spadmic_mon_pkt_txn mtxn;
    total_packets++;
    $display("[TX_MON] Packet #%0d: %s src=%0d words=%0d @%0t",
             total_packets,
             pkt.is_tdc ? "TDC" : "POS",
             pkt.source_id,
             pkt.words.size(),
             pkt.timestamp);

    // Send to scoreboard
    mtxn = new();
    mtxn.is_tdc     = pkt.is_tdc;
    mtxn.source_id  = pkt.source_id;
    mtxn.word_count = pkt.words.size();
    mtxn.words      = pkt.words;
    mtxn.timestamp  = $time;
    sb_mb.put(mtxn);

    // Signal coverage sampler
    cov_mb.put(total_packets);
  endtask

endclass

`default_nettype wire
