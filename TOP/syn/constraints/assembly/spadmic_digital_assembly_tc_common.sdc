# SPADMIC cumulative digital assembly TC constraints.
# All clocks are related to the external 160 MHz root. This is a strict
# typical-corner implementation contract, not an MMMC signoff constraint set.

set SPADMIC_DA_ROOT_PERIOD_NS 6.25
set SPADMIC_DA_CLOCK_UNCERTAINTY_NS 0.10
set SPADMIC_DA_IO_DELAY_NS 1.00
set SPADMIC_DA_DDR_OUTPUT_MAX_NS 1.00
set SPADMIC_DA_DDR_OUTPUT_MIN_NS -0.25

proc spadmic_da_ports {patterns} {
  set result [list]
  foreach pattern $patterns {
    foreach port [get_ports $pattern -quiet] {
      if {[lsearch -exact $result $port] < 0} {
        lappend result $port
      }
    }
  }
  return $result
}

proc spadmic_da_set_input_delay {clock patterns} {
  set ports [spadmic_da_ports $patterns]
  if {[llength $ports] > 0 && [llength [get_clocks $clock -quiet]] > 0} {
    set_input_delay -clock $clock $::SPADMIC_DA_IO_DELAY_NS $ports
  }
}

proc spadmic_da_set_output_delay {clock patterns} {
  set ports [spadmic_da_ports $patterns]
  if {[llength $ports] > 0 && [llength [get_clocks $clock -quiet]] > 0} {
    set_output_delay -clock $clock $::SPADMIC_DA_IO_DELAY_NS $ports
  }
}

if {[llength [get_ports clk_160m_i -quiet]] != 1} {
  error "SPADMIC_DA_CLOCK_CONTRACT: clk_160m_i must exist exactly once"
}
create_clock -name clk_160m_root -period $SPADMIC_DA_ROOT_PERIOD_NS \
  [get_ports clk_160m_i]

if {[llength [get_ports clk_sys -quiet]] == 1} {
  create_generated_clock -name clk_sys \
    -source [get_ports clk_160m_i] -master_clock clk_160m_root \
    -divide_by 1 [get_ports clk_sys]
}
if {[llength [get_ports clk_cfg_40m -quiet]] == 1} {
  create_generated_clock -name clk_cfg_40m \
    -source [get_ports clk_160m_i] -master_clock clk_160m_root \
    -divide_by 4 [get_ports clk_cfg_40m]
}
if {[llength [get_ports clk_ref_40m -quiet]] == 1} {
  create_generated_clock -name clk_ref_40m \
    -source [get_ports clk_160m_i] -master_clock clk_160m_root \
    -divide_by 4 [get_ports clk_ref_40m]
}
if {[llength [get_ports ddrs2_clk_160m_o -quiet]] == 1} {
  create_generated_clock -name ddrs2_clk_160m_out \
    -source [get_ports clk_160m_i] -master_clock clk_160m_root \
    -divide_by 1 [get_ports ddrs2_clk_160m_o]
}

set all_da_clocks [get_clocks {clk_160m_root clk_sys clk_cfg_40m clk_ref_40m ddrs2_clk_160m_out} -quiet]
if {[llength $all_da_clocks] > 0} {
  set_clock_uncertainty $SPADMIC_DA_CLOCK_UNCERTAINTY_NS $all_da_clocks
}

# Give every non-clock boundary a deterministic external environment first.
# Domain-specific commands below replace the default clock where appropriate.
set clock_ports [spadmic_da_ports {clk_160m_i clk_sys clk_cfg_40m clk_ref_40m}]
set non_clock_inputs [remove_from_collection [all_inputs] $clock_ports]
if {[llength $non_clock_inputs] > 0} {
  set_input_delay -clock clk_sys $SPADMIC_DA_IO_DELAY_NS $non_clock_inputs
  set_input_transition 0.15 $non_clock_inputs
}
set non_clock_outputs [remove_from_collection [all_outputs] [spadmic_da_ports {ddrs2_clk_160m_o}]]
if {[llength $non_clock_outputs] > 0} {
  set_output_delay -clock clk_sys $SPADMIC_DA_IO_DELAY_NS $non_clock_outputs
  set_load 0.05 $non_clock_outputs
}

# The configuration command and driven matrix columns are synchronous to the
# related 40 MHz clock in p03.
if {[llength [get_clocks clk_cfg_40m -quiet]] > 0} {
  spadmic_da_set_input_delay clk_cfg_40m {
    matrix_cfg_cmd_start_i matrix_cfg_cmd_op_i* matrix_cfg_col_idx_i*
    matrix_cfg_wdata_i*
  }
  spadmic_da_set_output_delay clk_cfg_40m {
    matrix_din_o* matrix_cin_o* matrix_cfg_busy_o matrix_cfg_done_o
    matrix_cfg_error_o matrix_cfg_last_error_o* matrix_cfg_rdata_o*
    matrix_cfg_readback_valid_o matrix_cfg_valid_o
  }
}

# DDR data is checked against both edges of the related 160 MHz root. The
# forwarded clock itself is a generated clock and is excluded from data delay.
set ddr_outputs [spadmic_da_ports {ddrs2_data_l_o* ddrs2_data_h_o* ddr_pair_valid_o ddr_padded_o}]
if {[llength $ddr_outputs] > 0} {
  set_output_delay -clock clk_160m_root -max $SPADMIC_DA_DDR_OUTPUT_MAX_NS $ddr_outputs
  set_output_delay -clock clk_160m_root -min $SPADMIC_DA_DDR_OUTPUT_MIN_NS $ddr_outputs
  set_output_delay -clock clk_160m_root -clock_fall -add_delay -max $SPADMIC_DA_DDR_OUTPUT_MAX_NS $ddr_outputs
  set_output_delay -clock clk_160m_root -clock_fall -add_delay -min $SPADMIC_DA_DDR_OUTPUT_MIN_NS $ddr_outputs
}

# Only genuinely asynchronous boundaries are cut. No asynchronous clock groups
# are permitted because clk_sys/clk_cfg_40m/clk_ref_40m share the 160 MHz root.
set reset_ports [spadmic_da_ports {async_rst_n}]
if {[llength $reset_ports] > 0} {
  set_false_path -from $reset_ports
}
set async_matrix_inputs [spadmic_da_ports {
  R_i* Y_i* B_i* matrix_dout_i* matrix_cout_i* cal_start_async_i*
}]
if {[llength $async_matrix_inputs] > 0} {
  set_false_path -from $async_matrix_inputs
}
set async_matrix_outputs [spadmic_da_ports {Rz_o* Yz_o* Bz_o* mptdc_start_async_o*}]
if {[llength $async_matrix_outputs] > 0} {
  set_false_path -to $async_matrix_outputs
}

set_max_transition 1.0 [current_design]
set_max_fanout 24 [current_design]
set_max_capacitance 0.50 [current_design]
