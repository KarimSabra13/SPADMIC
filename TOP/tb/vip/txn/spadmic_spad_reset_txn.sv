// =============================================================================
// SPADMIC VIP — Observed SPAD Matrix Reset Transaction
// =============================================================================

class spadmic_spad_reset_txn extends spadmic_base_txn;

  int unsigned     pulse_width_cycles;
  longint unsigned start_time_ps;
  longint unsigned end_time_ps;

  function new();
    super.new(TXN_SPAD_RESET);
    this.pulse_width_cycles = 0;
    this.start_time_ps      = 0;
    this.end_time_ps        = 0;
  endfunction

  function string to_string();
    return $sformatf("[SPAD_RESET #%0d] width=%0d cycles start=%0t end=%0t",
                     txn_id, pulse_width_cycles, start_time_ps, end_time_ps);
  endfunction

endclass

