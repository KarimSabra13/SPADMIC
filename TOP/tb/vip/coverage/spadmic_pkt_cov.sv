// =============================================================================
// SPADMIC VIP — Packet Content Coverage
// Tracks TDC and position packet diversity observed during simulation.
// =============================================================================

`ifdef SPADMIC_ENABLE_FUNC_COV

class spadmic_pkt_cov;

  // TDC packet fields
  logic [1:0] pkt_source;
  logic [3:0] hit_count;
  logic [1:0] out_mode;
  logic [3:0] flags;
  logic       slow_boundary_inc;

  // Position packet fields
  logic       overflow_any;
  logic [2:0] non_empty_mask;
  logic [2:0] multi_cluster_mask;
  int         event_count;
  int         pkt_kind;
  int         packet_words;
  int         raw_pattern_class;
  int         event_id_class;
  logic [2:0] raw_axis_mask;

  covergroup cg_tdc_pkt;
    cp_source:    coverpoint pkt_source { bins x = {0}; bins y = {1}; bins z = {2}; }
    cp_hit_count: coverpoint hit_count  { bins zero = {0}; bins one = {1};
                                           bins few = {[2:4]}; bins many = {[5:10]};
                                           bins deep = {[11:14]}; bins max_h = {15}; }
    cp_out_mode:  coverpoint out_mode   { bins raw_feat = {0}; bins raw_ts = {1};
                                           bins full = {2};
                                           illegal_bins bad_mode = {3}; }
    cp_flags:     coverpoint flags      { bins none = {0}; bins fastclose = {4};
                                           bins maxhits = {2}; bins watchdog_f = {1};
                                           bins fast_and_max = {6}; }
    cp_boundary:  coverpoint slow_boundary_inc;

    cx_source_x_hits: cross cp_source, cp_hit_count;
    cx_mode_x_flags:  cross cp_out_mode, cp_flags;
  endgroup

  covergroup cg_pos_pkt;
    cp_pkt_kind:       coverpoint pkt_kind {
      bins cluster = {MON_PKT_POS_CLUSTER};
      bins raw     = {MON_PKT_POS_RAW};
    }
    cp_overflow:       coverpoint overflow_any;
    cp_non_empty_mask: coverpoint non_empty_mask { bins all_empty = {0}; bins x_only = {1};
                                                     bins xy = {3}; bins all_set = {7};
                                                     bins other = default; }
    cp_multi_mask:     coverpoint multi_cluster_mask;
    cp_event_count:    coverpoint event_count    { bins low = {[0:10]}; bins med = {[11:100]};
                                                      bins high = {[101:16382]};
                                                      bins wrap_edge = {16383}; }
    cp_event_id_class: coverpoint event_id_class {
      bins zero     = {0};
      bins adjacent = {1};
      bins mid      = {2};
      bins wrap     = {3};
    }
    cp_packet_words:   coverpoint packet_words {
      bins compact_len = {[SPADMIC_POS_COMPACT_MIN_PKT_WORDS:SPADMIC_POS_PKT_WORDS-1]};
      bins cluster_len = {SPADMIC_POS_PKT_WORDS};
      bins raw_len     = {SPADMIC_POS_RAW_PKT_WORDS};
      illegal_bins short_or_other = default;
    }
    cp_raw_pattern:    coverpoint raw_pattern_class {
      bins not_raw       = {0};
      bins sparse        = {1};
      bins edge_bits     = {2};
      bins marker_like   = {3};
      bins dense         = {4};
    }
    cp_raw_axis_mask:  coverpoint raw_axis_mask {
      bins not_raw = {0};
      bins x_only  = {3'b001};
      bins y_only  = {3'b010};
      bins z_only  = {3'b100};
      bins xy      = {3'b011};
      bins xz      = {3'b101};
      bins yz      = {3'b110};
      bins xyz     = {3'b111};
    }

    cx_kind_x_mask: cross cp_pkt_kind, cp_non_empty_mask;
    cx_kind_x_len:  cross cp_pkt_kind, cp_packet_words;
    cx_kind_x_event: cross cp_pkt_kind, cp_event_id_class;
    cx_raw_pattern_x_axis: cross cp_raw_pattern, cp_raw_axis_mask;
  endgroup

  function new();
    cg_tdc_pkt = new();
    cg_pos_pkt = new();
  endfunction

  function void sample_tdc(
    logic [1:0] source, logic [3:0] hc, logic [1:0] mode,
    logic [3:0] flg, logic boundary
  );
    pkt_source        = source;
    hit_count         = hc;
    out_mode          = mode;
    flags             = flg;
    slow_boundary_inc = boundary;
    cg_tdc_pkt.sample();
  endfunction

  function automatic int classify_raw_pattern(logic [15:0] words[$]);
    bit marker_like;
    int ones_total;

    if ((words.size() == 0) || !is_spadmic_pos_raw_header(words[0]))
      return 0;

    marker_like = 1'b0;
    ones_total = 0;
    for (int idx = 1; idx < words.size()-1; idx++) begin
      if (is_tdc_header(words[idx]) || is_tdc_eoc(words[idx]))
        marker_like = 1'b1;
      ones_total += $countones(words[idx]);
    end

    if (marker_like)
      return 3;
    if (words[1][0]
        || words[SPADMIC_POS_RAW_WORDS_PER_AXIS][NARROW_W-1]
        || words[1 + SPADMIC_POS_RAW_WORDS_PER_AXIS][0]
        || words[2 * SPADMIC_POS_RAW_WORDS_PER_AXIS][NARROW_W-1]
        || words[1 + (2 * SPADMIC_POS_RAW_WORDS_PER_AXIS)][0]
        || words[3 * SPADMIC_POS_RAW_WORDS_PER_AXIS][NARROW_W-1])
      return 2;
    if (ones_total > 64)
      return 4;
    return 1;
  endfunction

  function automatic logic [2:0] classify_raw_axis_mask(logic [15:0] words[$]);
    logic [2:0] mask;
    mask = 3'b000;

    if ((words.size() == 0) || !is_spadmic_pos_raw_header(words[0]))
      return mask;

    for (int axis = 0; axis < 3; axis++) begin
      for (int idx = 0; idx < SPADMIC_POS_RAW_WORDS_PER_AXIS; idx++) begin
        int word_idx;
        word_idx = 1 + (axis * SPADMIC_POS_RAW_WORDS_PER_AXIS) + idx;
        if ((word_idx < words.size()) && (words[word_idx] != '0))
          mask[axis] = 1'b1;
      end
    end

    return mask;
  endfunction

  function automatic int classify_event_id(int ec);
    if (ec == 0)
      return 0;
    if (ec <= 10)
      return 1;
    if (ec >= 16380)
      return 3;
    return 2;
  endfunction

  function void sample_pos(
    spadmic_mon_pkt_kind_e kind,
    logic overflow, logic [2:0] ne_mask, logic [2:0] mc_mask, int ec,
    int unsigned words_count,
    logic [15:0] words[$]
  );
    pkt_kind           = kind;
    overflow_any       = overflow;
    non_empty_mask     = ne_mask;
    multi_cluster_mask = mc_mask;
    event_count        = ec;
    packet_words       = words_count;
    raw_pattern_class  = classify_raw_pattern(words);
    raw_axis_mask      = classify_raw_axis_mask(words);
    event_id_class     = classify_event_id(ec);
    cg_pos_pkt.sample();
  endfunction

  function void report();
    $display("[PKT_COV] TDC coverage: %.1f%%", cg_tdc_pkt.get_coverage());
    $display("[PKT_COV] POS coverage: %.1f%%", cg_pos_pkt.get_coverage());
  endfunction

endclass

`endif
