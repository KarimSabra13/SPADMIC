# OOC constraints for spadmic_tx_egress_cluster.
source [file normalize [file join [file dirname [info script]] .. matrix_top_ooc_common.sdc]]

if {[llength [get_ports clk_160m_i -quiet]] > 0} {
  create_clock -name clk_160m_i -period 6.25 [get_ports clk_160m_i]
}

foreach port_pat {rst_n ddrs2_enable_i bundle_start_i required_packet_mask_i* source_pending_mask_i* event_id_i* src_valid_i* src_data_i* src_sop_i* src_eop_i*} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    set_input_delay 0.0 $ports
  }
}

foreach port_pat {src_ready_o* completed_packet_mask_o* bundle_done_o bundle_busy_o bundle_idle_o bundle_missing_source_error_o output_fifo_* ddr_data_l_o* ddr_data_h_o* ddr_pair_valid_o ddr_padded_o ddr_clk_o ddr_busy_o ddr_empty_o ddrs2_data_l_o* ddrs2_data_h_o* ddrs2_clk_160m_o} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    set_output_delay 0.0 $ports
  }
}
