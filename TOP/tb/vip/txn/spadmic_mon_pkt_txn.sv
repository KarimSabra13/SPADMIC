// =============================================================================
// SPADMIC VIP — Monitor Packet Transaction
// Carries a captured TX packet from monitor to scoreboard.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_mon_pkt_txn extends spadmic_base_txn;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  logic [NARROW_W-1:0] words[$];
  int unsigned         source_id;
  int unsigned         word_count;
  bit                  is_tdc;

  function new();
    super.new(TXN_MON_PKT);
    this.source_id  = 0;
    this.word_count = 0;
    this.is_tdc     = 1'b1;
  endfunction

  function string to_string();
    return $sformatf("[MON_PKT #%0d] %s src=%0d words=%0d",
                      txn_id, is_tdc ? "TDC" : "POS",
                      source_id, word_count);
  endfunction
endclass

`default_nettype wire
