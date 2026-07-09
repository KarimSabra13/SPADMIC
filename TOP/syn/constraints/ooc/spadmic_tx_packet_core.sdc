# OOC constraints for spadmic_tx_packet_core.

set TX_PACKET_CLK_PERIOD_NS 6.25
set TX_PACKET_CLK_SYS_PORTS [get_ports clk_sys -quiet]

if {[llength $TX_PACKET_CLK_SYS_PORTS] > 0} {
  create_clock -name clk_sys -period $TX_PACKET_CLK_PERIOD_NS $TX_PACKET_CLK_SYS_PORTS
}

set TX_PACKET_CLK_SYS [get_clocks clk_sys -quiet]

foreach port_pat {rst_n bundle_start_i required_packet_mask_i* source_pending_mask_i* event_id_i* src_valid_i* src_data_i* src_sop_i* src_eop_i* tx_ready_i} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    if {[llength $TX_PACKET_CLK_SYS] > 0} {
      set_input_delay 0.0 -clock $TX_PACKET_CLK_SYS $ports
    } else {
      set_input_delay 0.0 $ports
    }
  }
}

foreach port_pat {src_ready_o* completed_packet_mask_o* bundle_done_o bundle_busy_o bundle_idle_o bundle_missing_source_error_o output_fifo_* tx_valid_o tx_data_o* tx_flush_o} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    if {[llength $TX_PACKET_CLK_SYS] > 0} {
      set_output_delay 0.0 -clock $TX_PACKET_CLK_SYS $ports
    } else {
      set_output_delay 0.0 $ports
    }
  }
}

set_max_transition 1.5 [current_design]
set_max_fanout 32 [current_design]
