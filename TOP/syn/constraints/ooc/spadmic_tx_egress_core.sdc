# OOC constraints for the physical TX_EGRESS_CORE wrapper.
#
# Keep this file direct rather than only sourcing the logical cluster SDC:
# Genus has accepted a wrapper-only source file without materializing the
# expected clocks in report_clocks.

set TX_EGRESS_CORE_CLK_PERIOD_NS 6.25
set TX_EGRESS_CORE_CLK_SYS_PORTS [get_ports clk_sys -quiet]
set TX_EGRESS_CORE_CLK_160M_PORTS [get_ports clk_160m_i -quiet]

if {[llength $TX_EGRESS_CORE_CLK_SYS_PORTS] > 0} {
  create_clock -name clk_sys -period $TX_EGRESS_CORE_CLK_PERIOD_NS $TX_EGRESS_CORE_CLK_SYS_PORTS
}

if {[llength $TX_EGRESS_CORE_CLK_160M_PORTS] > 0} {
  create_clock -name clk_160m_i -period $TX_EGRESS_CORE_CLK_PERIOD_NS $TX_EGRESS_CORE_CLK_160M_PORTS
}

set TX_EGRESS_CORE_CLK_SYS [get_clocks clk_sys -quiet]
set TX_EGRESS_CORE_CLK_160M [get_clocks clk_160m_i -quiet]

foreach port_pat {rst_n ddrs2_enable_i bundle_start_i required_packet_mask_i* source_pending_mask_i* event_id_i* src_valid_i* src_data_i* src_sop_i* src_eop_i*} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    if {[llength $TX_EGRESS_CORE_CLK_SYS] > 0} {
      set_input_delay 0.0 -clock $TX_EGRESS_CORE_CLK_SYS $ports
    } else {
      set_input_delay 0.0 $ports
    }
  }
}

foreach port_pat {src_ready_o* completed_packet_mask_o* bundle_done_o bundle_busy_o bundle_idle_o bundle_missing_source_error_o output_fifo_* ddr_pair_valid_o ddr_padded_o ddr_busy_o ddr_empty_o} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    if {[llength $TX_EGRESS_CORE_CLK_SYS] > 0} {
      set_output_delay 0.0 -clock $TX_EGRESS_CORE_CLK_SYS $ports
    } else {
      set_output_delay 0.0 $ports
    }
  }
}

foreach port_pat {ddrs2_data_l_o* ddrs2_data_h_o* ddrs2_clk_160m_o} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    if {[llength $TX_EGRESS_CORE_CLK_160M] > 0} {
      set_output_delay 0.0 -clock $TX_EGRESS_CORE_CLK_160M $ports
    } elseif {[llength $TX_EGRESS_CORE_CLK_SYS] > 0} {
      set_output_delay 0.0 -clock $TX_EGRESS_CORE_CLK_SYS $ports
    } else {
      set_output_delay 0.0 $ports
    }
  }
}

set_max_transition 1.5 [current_design]
set_max_fanout 32 [current_design]
