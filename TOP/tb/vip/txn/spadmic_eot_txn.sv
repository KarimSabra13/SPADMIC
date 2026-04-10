// =============================================================================
// SPADMIC VIP — End-of-Test Sentinel Transaction
// =============================================================================

class spadmic_eot_txn extends spadmic_base_txn;

  int unsigned drain_timeout_ns;  // max time to wait for outstanding packets

  function new();
    super.new(TXN_EOT);
    this.drain_timeout_ns = 50000;
  endfunction

  function string to_string();
    return $sformatf("[EOT_TXN #%0d] drain_timeout=%0dns", txn_id, drain_timeout_ns);
  endfunction
endclass

