# SPADMIC matrix-top OOC Genus constraints
# Status: typical-only feasibility constraints, not signoff.

set CLK_SYS_PERIOD_NS 6.25
set CLK_40M_PERIOD_NS 25.0

if {[llength [get_ports clk_sys -quiet]] > 0} {
  create_clock -name clk_sys -period $CLK_SYS_PERIOD_NS [get_ports clk_sys]
}

if {[llength [get_ports clk_cfg_40m -quiet]] > 0} {
  create_clock -name clk_cfg_40m -period $CLK_40M_PERIOD_NS [get_ports clk_cfg_40m]
}

if {[llength [get_ports clk_ref_40m -quiet]] > 0} {
  create_clock -name clk_ref_40m -period $CLK_40M_PERIOD_NS [get_ports clk_ref_40m]
}

# Treat the three externally supplied clocks as separate domains for matrix-top
# OOC work. The final PLL relationship and macro timing handoff must replace
# this placeholder before signoff. Keep this as one complete declaration when
# all clocks exist so report review can prove no accidental inter-clock timing
# path is being optimized as a synchronous path.
set has_clk_sys [expr {[llength [get_clocks clk_sys -quiet]] > 0}]
set has_clk_cfg [expr {[llength [get_clocks clk_cfg_40m -quiet]] > 0}]
set has_clk_ref [expr {[llength [get_clocks clk_ref_40m -quiet]] > 0}]

if {$has_clk_sys && $has_clk_cfg && $has_clk_ref} {
  set_clock_groups -asynchronous \
    -group [get_clocks clk_sys] \
    -group [get_clocks clk_cfg_40m] \
    -group [get_clocks clk_ref_40m]
} elseif {$has_clk_sys && $has_clk_cfg} {
  set_clock_groups -asynchronous -group [get_clocks clk_sys] -group [get_clocks clk_cfg_40m]
} elseif {$has_clk_sys && $has_clk_ref} {
  set_clock_groups -asynchronous -group [get_clocks clk_sys] -group [get_clocks clk_ref_40m]
} elseif {$has_clk_cfg && $has_clk_ref} {
  set_clock_groups -asynchronous -group [get_clocks clk_cfg_40m] -group [get_clocks clk_ref_40m]
}

# Async matrix START paths are intentional physical timing paths. This SDC does
# not blanket false-path all matrix inputs; detailed START-tree datapath and
# slew/skew reporting is required in the Genus/Innovus result review.
foreach port_pat {R_i* Y_i* B_i* matrix_cout_i* matrix_dout_i* i2c_scl_i i2c_sda_i async_rst_n} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    set_input_delay 0.0 $ports
  }
}

foreach port_pat {Rz_o* Yz_o* Bz_o* matrix_din_o* matrix_cin_o* ddr_data_l_o* ddr_data_h_o* ddr_pair_valid_o ddr_clk_o i2c_sda_oe_o} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    set_output_delay 0.0 $ports
  }
}

set_max_transition 1.5 [current_design]
set_max_fanout 32 [current_design]
