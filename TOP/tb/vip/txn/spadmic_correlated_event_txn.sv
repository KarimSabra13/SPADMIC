// =============================================================================
// SPADMIC VIP — Correlated Event Transaction
// Represents one physical event family that may emit multiple TDC-axis packets
// plus one position packet under the shared chip TX contract.
// =============================================================================

class spadmic_correlated_event_txn extends spadmic_base_txn;

  rand logic [2:0] axis_mask;
  rand int unsigned start_stop_delay_ps;
  rand int unsigned axis_skew_ps;
  rand int unsigned cal_start_width_ps;
  rand int unsigned cal_stop_width_ps;
  rand int unsigned position_offset_ps;
  rand int unsigned hold_time_ns;
  rand int unsigned post_family_idle_ps;

  logic                  use_spad;
  logic                  position_present;
  logic [SPADMIC_LINE_W-1:0] x_pattern;
  logic [SPADMIC_LINE_W-1:0] y_pattern;
  logic [SPADMIC_LINE_W-1:0] z_pattern;

  constraint c_has_payload {
    (axis_mask != 3'b000) || position_present;
  }

  constraint c_legal_delay {
    start_stop_delay_ps inside {[2000 : 30000]};
  }

  constraint c_skew {
    axis_skew_ps inside {[0 : 20000]};
  }

  constraint c_cal_timing {
    cal_start_width_ps inside {[500 : 5000]};
    cal_stop_width_ps  inside {[500 : 5000]};
  }

  constraint c_position_timing {
    position_offset_ps inside {[0 : 50000]};
    hold_time_ns       inside {[50 : 1000]};
    post_family_idle_ps inside {[200000 : 2000000]};
  }

  function new();
    super.new(TXN_CORRELATED_EVENT);
    this.axis_mask          = 3'b111;
    this.start_stop_delay_ps = 10000;
    this.axis_skew_ps       = 1500;
    this.cal_start_width_ps = 2000;
    this.cal_stop_width_ps  = 2000;
    this.position_offset_ps = 3000;
    this.hold_time_ns       = 250;
    this.post_family_idle_ps = 800000;
    this.use_spad           = 1'b0;
    this.position_present   = 1'b1;
    this.x_pattern          = '0;
    this.y_pattern          = '0;
    this.z_pattern          = '0;
  endfunction

  function string to_string();
    return $sformatf("[CORR_EVENT #%0d] mask=%03b delay=%0dps skew=%0dps pos=%0b src=%s",
                      txn_id, axis_mask, start_stop_delay_ps, axis_skew_ps,
                      position_present, use_spad ? "SPAD" : "CAL");
  endfunction
endclass
