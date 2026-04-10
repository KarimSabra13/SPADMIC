// =============================================================================
// SPADMIC VIP — Position Event Transaction
// Represents injection of position line patterns on 3 axes.
// =============================================================================

class spadmic_pos_event_txn extends spadmic_base_txn;

  logic [SPADMIC_LINE_W-1:0] x_pattern;
  logic [SPADMIC_LINE_W-1:0] y_pattern;
  logic [SPADMIC_LINE_W-1:0] z_pattern;

  rand int unsigned hold_time_ns;       // how long to hold the pattern
  logic        inject_glitch;      // inject a short glitch before stable pattern
  int unsigned glitch_axis;        // which axis gets glitch (0,1,2)
  int unsigned glitch_bit;         // which bit glitches
  int unsigned glitch_duration_ps; // glitch width

  // Expected results (populated by reference model)
  logic [2:0]  expected_non_empty_mask;
  logic [2:0]  expected_overflow_mask;

  // Position config snapshot at injection time
  rand logic [6:0]  gap_threshold;
  rand logic [6:0]  min_cluster_span;
  rand logic [3:0]  settle_cycles;

  constraint c_legal_position_config {
    gap_threshold    inside {[7'd5 : 7'd20]};
    min_cluster_span inside {[7'd5 : 7'd30]};
    settle_cycles    inside {[4'd2 : 4'd10]};
  }

  constraint c_reasonable_hold {
    hold_time_ns inside {[50 : 1000]};
  }

  function new();
    super.new(TXN_POS_EVENT);
    this.x_pattern          = '0;
    this.y_pattern          = '0;
    this.z_pattern          = '0;
    this.hold_time_ns       = 200;
    this.inject_glitch      = 1'b0;
    this.glitch_axis        = 0;
    this.glitch_bit         = 0;
    this.glitch_duration_ps = 500;
    this.gap_threshold      = 7'd10;
    this.min_cluster_span   = 7'd5;
    this.settle_cycles      = 4'd4;
  endfunction

  function string to_string();
    return $sformatf("[POS_EVENT #%0d] x=%0h y=%0h z=%0h hold=%0dns glitch=%0b",
                      txn_id, x_pattern, y_pattern, z_pattern,
                      hold_time_ns, inject_glitch);
  endfunction
endclass

