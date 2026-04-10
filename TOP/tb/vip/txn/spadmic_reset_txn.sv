// =============================================================================
// SPADMIC VIP — Reset Transaction
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_reset_txn extends spadmic_base_txn;
  import spadmic_vip_pkg::*;

  rand int unsigned reset_duration_ns;  // how long to hold reset
  logic        during_traffic;     // inject while traffic is in flight

  constraint c_reasonable_duration {
    reset_duration_ns inside {[10 : 500]};
  }

  function new();
    super.new(TXN_RESET);
    this.reset_duration_ns = 100;
    this.during_traffic    = 1'b0;
  endfunction

  function string to_string();
    return $sformatf("[RESET_TXN #%0d] dur=%0dns during_traffic=%0b",
                      txn_id, reset_duration_ns, during_traffic);
  endfunction
endclass

`default_nettype wire
