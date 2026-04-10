// =============================================================================
// SPADMIC VIP — Packet Content Coverage
// Tracks TDC and position packet diversity observed during simulation.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

`ifdef SPADMIC_ENABLE_FUNC_COV

class spadmic_pkt_cov;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

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

  covergroup cg_tdc_pkt;
    cp_source:    coverpoint pkt_source { bins x = {0}; bins y = {1}; bins z = {2}; }
    cp_hit_count: coverpoint hit_count  { bins zero = {0}; bins one = {1};
                                           bins few = {[2:4]}; bins many = {[5:10]};
                                           bins deep = {[11:14]}; bins max_h = {15}; }
    cp_out_mode:  coverpoint out_mode   { bins raw_feat = {0}; bins raw_ts = {1};
                                           bins full = {2}; }
    cp_flags:     coverpoint flags      { bins none = {0}; bins fastclose = {4};
                                           bins maxhits = {2}; bins watchdog_f = {1};
                                           bins fast_and_max = {6}; }
    cp_boundary:  coverpoint slow_boundary_inc;

    cx_source_x_hits: cross cp_source, cp_hit_count;
    cx_mode_x_flags:  cross cp_out_mode, cp_flags;
  endgroup

  covergroup cg_pos_pkt;
    cp_overflow:       coverpoint overflow_any;
    cp_non_empty_mask: coverpoint non_empty_mask { bins all_empty = {0}; bins x_only = {1};
                                                    bins xy = {3}; bins all_set = {7};
                                                    default: bins other = default; }
    cp_multi_mask:     coverpoint multi_cluster_mask;
    cp_event_count:    coverpoint event_count    { bins low = {[0:10]}; bins med = {[11:100]};
                                                    bins high = {[101:$]}; }
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

  function void sample_pos(
    logic overflow, logic [2:0] ne_mask, logic [2:0] mc_mask, int ec
  );
    overflow_any       = overflow;
    non_empty_mask     = ne_mask;
    multi_cluster_mask = mc_mask;
    event_count        = ec;
    cg_pos_pkt.sample();
  endfunction

  function void report();
    $display("[PKT_COV] TDC coverage: %.1f%%", cg_tdc_pkt.get_coverage());
    $display("[PKT_COV] POS coverage: %.1f%%", cg_pos_pkt.get_coverage());
  endfunction

endclass

`endif

`default_nettype wire
