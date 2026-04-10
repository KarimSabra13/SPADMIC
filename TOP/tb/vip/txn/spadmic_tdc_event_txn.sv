// =============================================================================
// SPADMIC VIP — TDC Event Transaction
// Represents injection of START/STOP events on one TDC axis.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_tdc_event_txn extends spadmic_base_txn;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  int unsigned axis;             // 0=X, 1=Y, 2=Z
  int unsigned num_conversions;  // how many START/STOP pairs to inject
  int unsigned start_stop_delay_ps;
  int unsigned inter_conv_gap_ps;
  logic        use_spad;         // 1=SPAD event, 0=CAL start/stop pair

  // For CAL injection timing
  int unsigned cal_start_width_ps;
  int unsigned cal_stop_width_ps;

  // Expected results (populated by reference model)
  int unsigned expected_hit_count;
  out_mode_e   expected_out_mode;

  constraint c_legal_axis {
    axis inside {[0:2]};
  }

  constraint c_legal_delay {
    start_stop_delay_ps inside {[2000 : 30000]};
  }

  constraint c_reasonable_conversions {
    num_conversions inside {[1 : 200]};
  }

  constraint c_cal_timing {
    cal_start_width_ps inside {[500 : 5000]};
    cal_stop_width_ps  inside {[500 : 5000]};
  }

  function new();
    super.new(TXN_TDC_EVENT);
    this.axis                 = 0;
    this.num_conversions      = 1;
    this.start_stop_delay_ps  = 10000;
    this.inter_conv_gap_ps    = 50000;
    this.use_spad             = 1'b0;
    this.cal_start_width_ps   = 2000;
    this.cal_stop_width_ps    = 2000;
    this.expected_hit_count   = 0;
    this.expected_out_mode    = OUT_RAW_FEATURES;
  endfunction

  function string to_string();
    return $sformatf("[TDC_EVENT #%0d] axis=%0d convs=%0d delay=%0dps src=%s",
                      txn_id, axis, num_conversions, start_stop_delay_ps,
                      use_spad ? "SPAD" : "CAL");
  endfunction
endclass

`default_nettype wire
