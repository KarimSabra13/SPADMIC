# OOC constraints for spadmic_ddrs2_adapter.
source [file normalize [file join [file dirname [info script]] .. matrix_top_ooc_common.sdc]]

if {[llength [get_ports clk_160m_i -quiet]] > 0} {
  create_clock -name clk_160m_i -period 6.25 [get_ports clk_160m_i]
}

foreach port_pat {rst_n enable_i ddr_data_l_i* ddr_data_h_i* ddr_pair_valid_i} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    set_input_delay 0.0 $ports
  }
}

foreach port_pat {ddrs2_data_l_o* ddrs2_data_h_o* ddrs2_clk_160m_o} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    set_output_delay 0.0 $ports
  }
}
