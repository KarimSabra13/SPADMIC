// =============================================================================
// SPADMIC VIP — Base Transaction
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_base_txn;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  spadmic_txn_kind_e kind;
  int unsigned       timestamp;
  int unsigned       txn_id;
  static int unsigned next_id = 0;

  function new(spadmic_txn_kind_e kind);
    this.kind      = kind;
    this.txn_id    = next_id++;
    this.timestamp = 0;
  endfunction

  virtual function string to_string();
    return $sformatf("[TXN #%0d] kind=%s", txn_id, kind.name());
  endfunction

  virtual function spadmic_base_txn clone();
    spadmic_base_txn c = new(this.kind);
    c.timestamp = this.timestamp;
    c.txn_id    = this.txn_id;
    return c;
  endfunction
endclass

`default_nettype wire
