// =============================================================================
// SPADMIC VIP — Monitor Packet Transaction
// Carries a captured TX packet from monitor to scoreboard.
// =============================================================================

class spadmic_mon_pkt_txn extends spadmic_base_txn;

  logic [NARROW_W-1:0] words[$];
  int unsigned         source_id;
  int unsigned         word_count;
  int unsigned         event_id;
  bit                  is_tdc;

  function new();
    super.new(TXN_MON_PKT);
    this.source_id  = 0;
    this.word_count = 0;
    this.event_id   = 0;
    this.is_tdc     = 1'b1;
  endfunction

  function string to_string();
    return $sformatf("[MON_PKT #%0d] %s src=%0d event=%0d words=%0d",
                      txn_id, is_tdc ? "TDC" : "POS",
                      source_id, event_id, word_count);
  endfunction
endclass
