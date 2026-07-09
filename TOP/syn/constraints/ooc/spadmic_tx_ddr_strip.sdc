# OOC constraints for spadmic_tx_ddr_strip.

set TX_DDR_STRIP_CLK_PERIOD_NS 6.25
set TX_DDR_STRIP_CLK_SYS_PORTS [get_ports clk_sys -quiet]
set TX_DDR_STRIP_CLK_160M_PORTS [get_ports clk_160m_i -quiet]

if {[llength $TX_DDR_STRIP_CLK_SYS_PORTS] > 0} {
  create_clock -name clk_sys -period $TX_DDR_STRIP_CLK_PERIOD_NS $TX_DDR_STRIP_CLK_SYS_PORTS
}

if {[llength $TX_DDR_STRIP_CLK_160M_PORTS] > 0} {
  create_clock -name clk_160m_i -period $TX_DDR_STRIP_CLK_PERIOD_NS $TX_DDR_STRIP_CLK_160M_PORTS
}

set TX_DDR_STRIP_CLK_SYS [get_clocks clk_sys -quiet]
set TX_DDR_STRIP_CLK_160M [get_clocks clk_160m_i -quiet]

foreach port_pat {rst_n ddrs2_enable_i tx_valid_i tx_data_i* tx_flush_i} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    if {[llength $TX_DDR_STRIP_CLK_SYS] > 0} {
      set_input_delay 0.0 -clock $TX_DDR_STRIP_CLK_SYS $ports
    } else {
      set_input_delay 0.0 $ports
    }
  }
}

foreach port_pat {tx_ready_o ddr_pair_valid_o ddr_padded_o ddr_busy_o ddr_empty_o} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    if {[llength $TX_DDR_STRIP_CLK_SYS] > 0} {
      set_output_delay 0.0 -clock $TX_DDR_STRIP_CLK_SYS $ports
    } else {
      set_output_delay 0.0 $ports
    }
  }
}

foreach port_pat {ddrs2_data_l_o* ddrs2_data_h_o* ddrs2_clk_160m_o} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    if {[llength $TX_DDR_STRIP_CLK_160M] > 0} {
      set_output_delay 0.0 -clock $TX_DDR_STRIP_CLK_160M $ports
    } elseif {[llength $TX_DDR_STRIP_CLK_SYS] > 0} {
      set_output_delay 0.0 -clock $TX_DDR_STRIP_CLK_SYS $ports
    } else {
      set_output_delay 0.0 $ports
    }
  }
}

set_max_transition 1.5 [current_design]
set_max_fanout 32 [current_design]
