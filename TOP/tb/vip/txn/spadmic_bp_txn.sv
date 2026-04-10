// =============================================================================
// SPADMIC VIP — Backpressure Transaction
// =============================================================================

class spadmic_bp_txn extends spadmic_base_txn;

  spadmic_bp_mode_e mode;
  int unsigned      duration_cycles;  // how many cycles to hold this BP mode

  function new();
    super.new(TXN_BP);
    this.mode            = BP_ALWAYS_READY;
    this.duration_cycles = 1000;
  endfunction

  function string to_string();
    return $sformatf("[BP_TXN #%0d] mode=%s dur=%0d cyc",
                      txn_id, mode.name(), duration_cycles);
  endfunction
endclass

