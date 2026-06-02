# ####################################################################

#  Created by Genus(TM) Synthesis Solution 22.13-s093_1 on Tue Jun 02 13:36:59 CEST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design mptdc_top_asic

set_case_analysis 0 [get_ports narrow_ready_i]
set_case_analysis 1 [get_ports shared_readout_en_i]
create_clock -name "clk_sys" -period 6.25 -waveform {0.0 3.125} [get_ports clk_sys]
create_clock -name "clk_osc_slow" -period 1.0 -waveform {0.0 0.5} [get_pins {u_core_u_osc_slow/u_ro_tune4/S[0]}]
create_clock -name "clk_osc_slow_tap1" -period 1.0 -waveform {0.055 0.555} [get_pins {u_core_u_osc_slow/u_ro_tune4/S[1]}]
create_clock -name "clk_osc_slow_tap2" -period 1.0 -waveform {0.11 0.61} [get_pins {u_core_u_osc_slow/u_ro_tune4/S[2]}]
create_clock -name "clk_osc_slow_tap3" -period 1.0 -waveform {0.165 0.665} [get_pins {u_core_u_osc_slow/u_ro_tune4/S[3]}]
create_clock -name "clk_osc_slow_tap4" -period 1.0 -waveform {0.22 0.72} [get_pins {u_core_u_osc_slow/u_ro_tune4/S[4]}]
create_clock -name "clk_osc_slow_tap5" -period 1.0 -waveform {0.275 0.775} [get_pins {u_core_u_osc_slow/u_ro_tune4/S[5]}]
create_clock -name "clk_osc_slow_tap6" -period 1.0 -waveform {0.33 0.83} [get_pins {u_core_u_osc_slow/u_ro_tune4/S[6]}]
create_clock -name "clk_osc_slow_tap7" -period 1.0 -waveform {0.385 0.885} [get_pins {u_core_u_osc_slow/u_ro_tune4/S[7]}]
create_clock -name "clk_osc_fast" -period 0.9 -waveform {0.0 0.45} [get_pins {u_core_u_osc_fast/u_ro_tune4/S[0]}]
create_clock -name "clk_osc_fast_tap1" -period 0.9 -waveform {0.05 0.5} [get_pins {u_core_u_osc_fast/u_ro_tune4/S[1]}]
create_clock -name "clk_osc_fast_tap2" -period 0.9 -waveform {0.1 0.55} [get_pins {u_core_u_osc_fast/u_ro_tune4/S[2]}]
create_clock -name "clk_osc_fast_tap3" -period 0.9 -waveform {0.15 0.6} [get_pins {u_core_u_osc_fast/u_ro_tune4/S[3]}]
create_clock -name "clk_osc_fast_tap4" -period 0.9 -waveform {0.2 0.65} [get_pins {u_core_u_osc_fast/u_ro_tune4/S[4]}]
create_clock -name "clk_osc_fast_tap5" -period 0.9 -waveform {0.25 0.7} [get_pins {u_core_u_osc_fast/u_ro_tune4/S[5]}]
create_clock -name "clk_osc_fast_tap6" -period 0.9 -waveform {0.3 0.75} [get_pins {u_core_u_osc_fast/u_ro_tune4/S[6]}]
create_clock -name "clk_osc_fast_tap7" -period 0.9 -waveform {0.35 0.8} [get_pins {u_core_u_osc_fast/u_ro_tune4/S[7]}]
set_clock_transition 0.15 [get_clocks clk_sys]
set_clock_transition 0.15 [get_clocks clk_osc_slow]
set_clock_transition 0.15 [get_clocks clk_osc_slow_tap1]
set_clock_transition 0.15 [get_clocks clk_osc_slow_tap2]
set_clock_transition 0.15 [get_clocks clk_osc_slow_tap3]
set_clock_transition 0.15 [get_clocks clk_osc_slow_tap4]
set_clock_transition 0.15 [get_clocks clk_osc_slow_tap5]
set_clock_transition 0.15 [get_clocks clk_osc_slow_tap6]
set_clock_transition 0.15 [get_clocks clk_osc_slow_tap7]
set_clock_transition 0.15 [get_clocks clk_osc_fast]
set_clock_transition 0.15 [get_clocks clk_osc_fast_tap1]
set_clock_transition 0.15 [get_clocks clk_osc_fast_tap2]
set_clock_transition 0.15 [get_clocks clk_osc_fast_tap3]
set_clock_transition 0.15 [get_clocks clk_osc_fast_tap4]
set_clock_transition 0.15 [get_clocks clk_osc_fast_tap5]
set_clock_transition 0.15 [get_clocks clk_osc_fast_tap6]
set_clock_transition 0.15 [get_clocks clk_osc_fast_tap7]
set_load -pin_load 0.01 [get_ports csr_ready_o]
set_load -pin_load 0.01 [get_ports csr_rvalid_o]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[31]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[30]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[29]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[28]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[27]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[26]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[25]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[24]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[23]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[22]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[21]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[20]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[19]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[18]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[17]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[16]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[15]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[14]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[13]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[12]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[11]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[10]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[9]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[8]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[7]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[6]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[5]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[4]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[3]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[2]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[1]}]
set_load -pin_load 0.01 [get_ports {csr_rdata_o[0]}]
set_load -pin_load 0.01 [get_ports narrow_valid_o]
set_load -pin_load 0.01 [get_ports {narrow_data_o[15]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[14]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[13]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[12]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[11]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[10]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[9]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[8]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[7]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[6]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[5]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[4]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[3]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[2]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[1]}]
set_load -pin_load 0.01 [get_ports {narrow_data_o[0]}]
set_load -pin_load 0.01 [get_ports acq_valid_o]
set_load -pin_load 0.01 [get_ports {acq_data_o[52]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[51]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[50]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[49]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[48]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[47]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[46]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[45]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[44]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[43]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[42]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[41]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[40]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[39]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[38]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[37]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[36]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[35]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[34]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[33]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[32]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[31]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[30]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[29]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[28]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[27]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[26]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[25]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[24]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[23]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[22]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[21]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[20]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[19]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[18]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[17]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[16]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[15]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[14]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[13]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[12]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[11]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[10]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[9]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[8]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[7]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[6]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[5]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[4]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[3]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[2]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[1]}]
set_load -pin_load 0.01 [get_ports {acq_data_o[0]}]
set_load -pin_load 0.01 [get_ports fifo_full_o]
set_false_path -from [list \
  [get_ports start_spad_async_i]  \
  [get_ports stop_spad_async_i]  \
  [get_ports cal_start_async_i]  \
  [get_ports cal_stop_async_i]  \
  [get_ports async_rst_n] ]
set_false_path -to [list \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[0]/D}]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[1]/D}]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[2]/D}] ]
set_false_path -through [list \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[0]/D}]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[1]/D}]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[2]/D}] ]
set_max_delay 6.25 -from [list \
  [get_clocks clk_osc_slow_tap7]  \
  [get_clocks clk_osc_slow_tap6]  \
  [get_clocks clk_osc_slow_tap5]  \
  [get_clocks clk_osc_slow_tap4]  \
  [get_clocks clk_osc_slow_tap3]  \
  [get_clocks clk_osc_slow_tap2]  \
  [get_clocks clk_osc_slow_tap1]  \
  [get_clocks clk_osc_slow]  \
  [get_clocks clk_osc_fast_tap7]  \
  [get_clocks clk_osc_fast_tap6]  \
  [get_clocks clk_osc_fast_tap5]  \
  [get_clocks clk_osc_fast_tap4]  \
  [get_clocks clk_osc_fast_tap3]  \
  [get_clocks clk_osc_fast_tap2]  \
  [get_clocks clk_osc_fast_tap1]  \
  [get_clocks clk_osc_fast] ] -to [get_clocks clk_sys]
set_max_delay 0.9 -from [get_clocks clk_sys] -to [list \
  [get_clocks clk_osc_fast]  \
  [get_clocks clk_osc_fast_tap1]  \
  [get_clocks clk_osc_fast_tap2]  \
  [get_clocks clk_osc_fast_tap3]  \
  [get_clocks clk_osc_fast_tap4]  \
  [get_clocks clk_osc_fast_tap5]  \
  [get_clocks clk_osc_fast_tap6]  \
  [get_clocks clk_osc_fast_tap7] ]
set_clock_groups -name "clock_groups_clk_sys_to_clk_osc_slow_clk_osc_slow_tap1_clk_osc_slow_tap2_clk_osc_slow_tap3_clk_osc_slow_tap4_clk_osc_slow_tap5_clk_osc_slow_tap6_clk_osc_slow_tap7_to_clk_osc_fast_clk_osc_fast_tap1_clk_osc_fast_tap2_clk_osc_fast_tap3_clk_osc_fast_tap4_clk_osc_fast_tap5_clk_osc_fast_tap6_clk_osc_fast_tap7" -asynchronous -group [get_clocks clk_sys] -group [list \
  [get_clocks clk_osc_slow]  \
  [get_clocks clk_osc_slow_tap1]  \
  [get_clocks clk_osc_slow_tap2]  \
  [get_clocks clk_osc_slow_tap3]  \
  [get_clocks clk_osc_slow_tap4]  \
  [get_clocks clk_osc_slow_tap5]  \
  [get_clocks clk_osc_slow_tap6]  \
  [get_clocks clk_osc_slow_tap7] ] -group [list \
  [get_clocks clk_osc_fast]  \
  [get_clocks clk_osc_fast_tap1]  \
  [get_clocks clk_osc_fast_tap2]  \
  [get_clocks clk_osc_fast_tap3]  \
  [get_clocks clk_osc_fast_tap4]  \
  [get_clocks clk_osc_fast_tap5]  \
  [get_clocks clk_osc_fast_tap6]  \
  [get_clocks clk_osc_fast_tap7] ]
group_path -name cg_enable_group_clk_osc_fast -through [list \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST/RC_CGIC_INST/E]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST/enable]  \
  [get_pins RC_CG_DECLONE_HIER_INST/RC_CGIC_INST/E] ]
group_path -name cg_enable_group_clk_osc_fast_tap1 -through [list \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23840/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23840/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23840/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23840/RC_CGIC_INST/E]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23840/enable]  \
  [get_pins RC_CG_DECLONE_HIER_INST23840/RC_CGIC_INST/E] ]
group_path -name cg_enable_group_clk_osc_fast_tap2 -through [list \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23841/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23841/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23841/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23841/RC_CGIC_INST/E]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23841/enable]  \
  [get_pins RC_CG_DECLONE_HIER_INST23841/RC_CGIC_INST/E] ]
group_path -name cg_enable_group_clk_osc_fast_tap3 -through [list \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23842/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23842/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23842/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23842/RC_CGIC_INST/E]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23842/enable]  \
  [get_pins RC_CG_DECLONE_HIER_INST23842/RC_CGIC_INST/E] ]
group_path -name cg_enable_group_clk_osc_fast_tap4 -through [list \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23843/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23843/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23843/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23843/RC_CGIC_INST/E]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23843/enable]  \
  [get_pins RC_CG_DECLONE_HIER_INST23843/RC_CGIC_INST/E] ]
group_path -name cg_enable_group_clk_osc_fast_tap5 -through [list \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23844/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23844/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23844/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23844/RC_CGIC_INST/E]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23844/enable]  \
  [get_pins RC_CG_DECLONE_HIER_INST23844/RC_CGIC_INST/E] ]
group_path -name cg_enable_group_clk_osc_fast_tap6 -through [list \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23845/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23845/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23845/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23845/RC_CGIC_INST/E]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23845/enable]  \
  [get_pins RC_CG_DECLONE_HIER_INST23845/RC_CGIC_INST/E] ]
group_path -name cg_enable_group_clk_osc_fast_tap7 -through [list \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23846/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23846/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23846/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST23846/RC_CGIC_INST/E]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/enable}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST/E}]  \
  [get_pins RC_CG_DECLONE_HIER_INST23846/enable]  \
  [get_pins RC_CG_DECLONE_HIER_INST23846/RC_CGIC_INST/E] ]
group_path -name cg_enable_group_clk_sys -through [list \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST0/enable]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST0/RC_CGIC_INST/E]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST1/enable]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST1/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST10/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST10/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST11/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST11/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST12/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST12/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST13/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST13/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST14/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST14/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST15/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST15/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST28/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST28/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST29/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST29/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST30/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST30/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST31/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST31/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST32/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST32/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST33/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST33/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST34/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST34/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST35/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST35/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST36/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST36/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST37/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST37/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST38/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST38/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST39/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST39/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST40/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST40/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST41/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST41/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST42/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST42/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST43/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST43/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST44/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST44/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST45/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST45/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST46/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST46/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST47/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST47/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST48/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST48/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST49/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST49/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST50/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST50/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST51/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST51/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST52/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST52/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST53/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST53/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST54/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST54/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST55/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST55/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST56/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST56/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST57/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST57/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST58/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST58/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST59/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST59/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST60/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST60/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST61/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST61/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST62/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST62/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST63/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST63/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST64/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST64/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST65/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST65/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST66/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST66/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST67/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST67/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST68/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST68/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST69/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST69/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST70/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST70/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST71/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST71/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST72/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST72/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST73/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST73/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST74/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST74/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST75/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST75/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST76/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST76/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST77/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST77/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST78/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST78/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST79/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST79/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST80/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST80/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST81/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST81/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST82/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST82/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST83/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST83/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST84/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST84/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST85/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST85/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST86/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST86/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST87/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST87/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST88/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST88/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST89/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST89/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST90/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST90/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST91/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST91/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST92/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST92/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST93/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST93/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST94/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST94/RC_CGIC_INST/E]  \
  [get_pins u_core_u_hit_capture_bridge/RC_CG_HIER_INST16/enable]  \
  [get_pins u_core_u_hit_capture_bridge/RC_CG_HIER_INST16/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST17/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST17/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST18/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST18/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST19/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST19/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST20/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST20/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST21/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST21/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST22/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST22/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST23/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST23/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST24/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST24/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST25/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST25/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST2/enable]  \
  [get_pins u_core_RC_CG_HIER_INST2/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST3/enable]  \
  [get_pins u_core_RC_CG_HIER_INST3/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST4/enable]  \
  [get_pins u_core_RC_CG_HIER_INST4/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST5/enable]  \
  [get_pins u_core_RC_CG_HIER_INST5/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST6/enable]  \
  [get_pins u_core_RC_CG_HIER_INST6/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST7/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST7/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST8/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST8/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST9/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST9/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST96/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST96/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST95/enable]  \
  [get_pins RC_CG_HIER_INST95/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST95/enable]  \
  [get_pins RC_CG_HIER_INST95/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST2/enable]  \
  [get_pins u_core_RC_CG_HIER_INST2/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST3/enable]  \
  [get_pins u_core_RC_CG_HIER_INST3/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST4/enable]  \
  [get_pins u_core_RC_CG_HIER_INST4/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST5/enable]  \
  [get_pins u_core_RC_CG_HIER_INST5/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST6/enable]  \
  [get_pins u_core_RC_CG_HIER_INST6/RC_CGIC_INST/E]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST0/enable]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST0/RC_CGIC_INST/E]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST1/enable]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST1/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST10/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST10/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST11/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST11/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST12/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST12/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST13/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST13/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST14/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST14/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST15/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST15/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST28/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST28/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST29/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST29/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST30/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST30/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST31/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST31/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST32/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST32/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST33/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST33/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST34/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST34/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST35/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST35/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST36/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST36/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST37/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST37/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST38/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST38/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST39/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST39/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST40/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST40/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST41/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST41/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST42/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST42/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST43/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST43/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST44/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST44/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST45/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST45/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST46/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST46/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST47/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST47/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST48/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST48/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST49/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST49/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST50/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST50/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST51/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST51/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST52/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST52/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST53/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST53/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST54/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST54/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST55/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST55/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST56/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST56/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST57/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST57/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST58/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST58/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST59/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST59/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST60/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST60/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST61/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST61/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST62/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST62/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST63/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST63/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST64/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST64/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST65/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST65/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST66/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST66/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST67/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST67/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST68/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST68/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST69/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST69/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST70/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST70/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST71/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST71/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST72/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST72/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST73/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST73/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST74/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST74/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST75/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST75/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST76/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST76/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST77/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST77/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST78/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST78/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST79/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST79/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST80/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST80/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST81/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST81/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST82/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST82/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST83/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST83/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST84/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST84/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST85/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST85/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST86/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST86/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST87/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST87/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST88/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST88/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST89/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST89/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST90/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST90/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST91/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST91/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST92/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST92/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST93/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST93/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST94/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST94/RC_CGIC_INST/E]  \
  [get_pins u_core_u_hit_capture_bridge/RC_CG_HIER_INST16/enable]  \
  [get_pins u_core_u_hit_capture_bridge/RC_CG_HIER_INST16/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST17/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST17/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST18/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST18/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST19/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST19/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST20/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST20/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST21/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST21/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST22/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST22/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST23/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST23/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST24/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST24/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST25/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST25/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST7/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST7/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST8/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST8/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST9/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST9/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST96/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST96/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST97/enable]  \
  [get_pins RC_CG_HIER_INST97/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST95/enable]  \
  [get_pins RC_CG_HIER_INST95/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST97/enable]  \
  [get_pins RC_CG_HIER_INST97/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST2/enable]  \
  [get_pins u_core_RC_CG_HIER_INST2/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST3/enable]  \
  [get_pins u_core_RC_CG_HIER_INST3/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST4/enable]  \
  [get_pins u_core_RC_CG_HIER_INST4/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST5/enable]  \
  [get_pins u_core_RC_CG_HIER_INST5/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST6/enable]  \
  [get_pins u_core_RC_CG_HIER_INST6/RC_CGIC_INST/E]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST0/enable]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST0/RC_CGIC_INST/E]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST1/enable]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST1/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST10/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST10/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST11/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST11/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST12/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST12/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST13/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST13/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST14/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST14/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST15/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST15/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST28/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST28/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST29/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST29/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST30/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST30/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST31/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST31/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST32/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST32/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST33/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST33/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST34/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST34/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST35/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST35/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST36/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST36/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST37/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST37/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST38/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST38/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST39/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST39/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST40/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST40/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST41/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST41/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST42/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST42/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST43/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST43/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST44/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST44/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST45/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST45/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST46/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST46/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST47/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST47/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST48/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST48/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST49/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST49/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST50/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST50/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST51/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST51/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST52/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST52/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST53/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST53/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST54/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST54/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST55/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST55/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST56/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST56/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST57/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST57/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST58/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST58/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST59/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST59/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST60/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST60/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST61/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST61/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST62/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST62/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST63/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST63/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST64/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST64/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST65/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST65/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST66/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST66/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST67/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST67/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST68/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST68/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST69/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST69/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST70/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST70/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST71/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST71/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST72/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST72/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST73/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST73/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST74/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST74/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST75/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST75/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST76/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST76/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST77/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST77/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST78/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST78/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST79/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST79/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST80/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST80/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST81/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST81/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST82/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST82/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST83/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST83/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST84/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST84/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST85/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST85/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST86/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST86/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST87/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST87/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST88/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST88/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST89/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST89/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST90/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST90/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST91/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST91/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST92/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST92/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST93/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST93/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST94/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST94/RC_CGIC_INST/E]  \
  [get_pins u_core_u_hit_capture_bridge/RC_CG_HIER_INST16/enable]  \
  [get_pins u_core_u_hit_capture_bridge/RC_CG_HIER_INST16/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST17/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST17/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST18/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST18/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST19/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST19/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST20/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST20/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST21/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST21/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST22/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST22/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST23/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST23/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST24/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST24/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST25/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST25/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST7/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST7/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST8/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST8/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST9/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST9/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST96/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST96/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST95/enable]  \
  [get_pins RC_CG_HIER_INST95/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST97/enable]  \
  [get_pins RC_CG_HIER_INST97/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST2/enable]  \
  [get_pins u_core_RC_CG_HIER_INST2/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST3/enable]  \
  [get_pins u_core_RC_CG_HIER_INST3/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST4/enable]  \
  [get_pins u_core_RC_CG_HIER_INST4/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST5/enable]  \
  [get_pins u_core_RC_CG_HIER_INST5/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST6/enable]  \
  [get_pins u_core_RC_CG_HIER_INST6/RC_CGIC_INST/E]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST0/enable]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST0/RC_CGIC_INST/E]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST1/enable]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST1/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST10/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST10/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST11/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST11/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST12/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST12/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST13/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST13/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST14/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST14/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST15/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST15/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST28/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST28/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST29/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST29/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST30/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST30/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST31/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST31/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST32/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST32/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST33/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST33/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST34/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST34/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST35/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST35/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST36/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST36/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST37/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST37/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST38/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST38/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST39/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST39/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST40/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST40/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST41/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST41/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST42/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST42/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST43/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST43/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST44/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST44/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST45/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST45/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST46/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST46/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST47/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST47/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST48/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST48/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST49/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST49/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST50/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST50/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST51/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST51/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST52/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST52/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST53/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST53/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST54/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST54/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST55/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST55/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST56/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST56/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST57/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST57/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST58/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST58/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST59/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST59/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST60/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST60/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST61/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST61/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST62/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST62/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST63/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST63/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST64/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST64/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST65/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST65/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST66/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST66/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST67/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST67/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST68/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST68/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST69/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST69/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST70/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST70/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST71/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST71/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST72/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST72/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST73/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST73/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST74/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST74/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST75/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST75/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST76/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST76/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST77/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST77/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST78/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST78/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST79/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST79/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST80/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST80/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST81/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST81/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST82/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST82/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST83/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST83/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST84/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST84/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST85/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST85/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST86/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST86/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST87/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST87/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST88/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST88/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST89/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST89/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST90/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST90/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST91/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST91/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST92/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST92/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST93/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST93/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST94/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST94/RC_CGIC_INST/E]  \
  [get_pins u_core_u_hit_capture_bridge/RC_CG_HIER_INST16/enable]  \
  [get_pins u_core_u_hit_capture_bridge/RC_CG_HIER_INST16/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST17/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST17/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST18/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST18/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST19/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST19/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST20/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST20/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST21/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST21/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST22/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST22/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST23/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST23/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST24/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST24/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST25/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST25/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST7/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST7/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST8/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST8/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST9/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST9/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST96/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST96/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST95/enable]  \
  [get_pins RC_CG_HIER_INST95/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST97/enable]  \
  [get_pins RC_CG_HIER_INST97/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST2/enable]  \
  [get_pins u_core_RC_CG_HIER_INST2/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST3/enable]  \
  [get_pins u_core_RC_CG_HIER_INST3/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST4/enable]  \
  [get_pins u_core_RC_CG_HIER_INST4/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST5/enable]  \
  [get_pins u_core_RC_CG_HIER_INST5/RC_CGIC_INST/E]  \
  [get_pins u_core_RC_CG_HIER_INST6/enable]  \
  [get_pins u_core_RC_CG_HIER_INST6/RC_CGIC_INST/E]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST0/enable]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST0/RC_CGIC_INST/E]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST1/enable]  \
  [get_pins u_core_u_ctx_bank_RC_CG_HIER_INST1/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST10/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST10/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST11/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST11/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST12/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST12/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST13/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST13/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST14/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST14/RC_CGIC_INST/E]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST15/enable]  \
  [get_pins u_core_u_drain_ctrl_RC_CG_HIER_INST15/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST28/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST28/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST29/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST29/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST30/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST30/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST31/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST31/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST32/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST32/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST33/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST33/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST34/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST34/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST35/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST35/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST36/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST36/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST37/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST37/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST38/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST38/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST39/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST39/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST40/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST40/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST41/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST41/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST42/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST42/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST43/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST43/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST44/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST44/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST45/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST45/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST46/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST46/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST47/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST47/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST48/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST48/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST49/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST49/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST50/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST50/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST51/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST51/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST52/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST52/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST53/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST53/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST54/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST54/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST55/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST55/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST56/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST56/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST57/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST57/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST58/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST58/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST59/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST59/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST60/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST60/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST61/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST61/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST62/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST62/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST63/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST63/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST64/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST64/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST65/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST65/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST66/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST66/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST67/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST67/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST68/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST68/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST69/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST69/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST70/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST70/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST71/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST71/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST72/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST72/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST73/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST73/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST74/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST74/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST75/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST75/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST76/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST76/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST77/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST77/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST78/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST78/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST79/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST79/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST80/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST80/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST81/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST81/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST82/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST82/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST83/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST83/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST84/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST84/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST85/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST85/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST86/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST86/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST87/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST87/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST88/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST88/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST89/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST89/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST90/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST90/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST91/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST91/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST92/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST92/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST93/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST93/RC_CGIC_INST/E]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST94/enable]  \
  [get_pins u_core_u_fifo/RC_CG_HIER_INST94/RC_CGIC_INST/E]  \
  [get_pins u_core_u_hit_capture_bridge/RC_CG_HIER_INST16/enable]  \
  [get_pins u_core_u_hit_capture_bridge/RC_CG_HIER_INST16/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST17/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST17/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST18/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST18/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST19/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST19/RC_CGIC_INST/E]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST20/enable]  \
  [get_pins u_core_u_meas_ctrl/RC_CG_HIER_INST20/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST21/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST21/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST22/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST22/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST23/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST23/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST24/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST24/RC_CGIC_INST/E]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST25/enable]  \
  [get_pins u_core_u_narrow_tx/RC_CG_HIER_INST25/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST7/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST7/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST8/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST8/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST9/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST9/RC_CGIC_INST/E]  \
  [get_pins u_csr_RC_CG_HIER_INST96/enable]  \
  [get_pins u_csr_RC_CG_HIER_INST96/RC_CGIC_INST/E] ]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports input_sel_override_en_i]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {input_sel_override_i[0]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports out_mode_override_en_i]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {out_mode_override_i[1]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {out_mode_override_i[0]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports csr_valid_i]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports csr_write_i]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_addr_i[5]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_addr_i[4]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_addr_i[3]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_addr_i[2]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_addr_i[1]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_addr_i[0]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[31]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[30]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[29]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[28]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[27]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[26]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[25]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[24]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[23]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[22]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[21]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[20]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[19]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[18]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[17]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[16]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[15]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[14]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[13]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[12]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[11]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[10]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[9]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[8]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[7]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[6]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[5]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[4]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[3]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[2]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[1]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_wdata_i[0]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports narrow_ready_i]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports shared_readout_en_i]
set_input_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports acq_ready_i]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports csr_ready_o]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports csr_rvalid_o]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[31]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[30]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[29]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[28]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[27]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[26]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[25]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[24]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[23]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[22]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[21]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[20]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[19]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[18]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[17]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[16]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[15]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[14]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[13]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[12]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[11]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[10]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[9]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[8]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[7]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[6]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[5]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[4]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[3]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[2]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[1]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {csr_rdata_o[0]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports narrow_valid_o]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[15]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[14]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[13]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[12]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[11]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[10]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[9]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[8]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[7]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[6]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[5]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[4]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[3]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[2]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[1]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {narrow_data_o[0]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports acq_valid_o]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[52]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[51]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[50]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[49]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[48]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[47]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[46]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[45]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[44]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[43]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[42]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[41]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[40]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[39]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[38]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[37]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[36]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[35]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[34]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[33]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[32]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[31]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[30]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[29]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[28]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[27]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[26]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[25]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[24]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[23]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[22]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[21]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[20]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[19]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[18]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[17]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[16]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[15]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[14]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[13]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[12]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[11]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[10]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[9]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[8]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[7]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[6]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[5]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[4]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[3]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[2]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[1]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports {acq_data_o[0]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay 0.5 [get_ports fifo_full_o]
set_max_fanout 20.000 [current_design]
set_max_transition 0.5 [current_design]
set_input_transition 0.1 [get_ports async_rst_n]
set_input_transition 0.1 [get_ports start_spad_async_i]
set_input_transition 0.1 [get_ports stop_spad_async_i]
set_input_transition 0.1 [get_ports cal_start_async_i]
set_input_transition 0.1 [get_ports cal_stop_async_i]
set_input_transition 0.1 [get_ports input_sel_override_en_i]
set_input_transition 0.1 [get_ports {input_sel_override_i[0]}]
set_input_transition 0.1 [get_ports out_mode_override_en_i]
set_input_transition 0.1 [get_ports {out_mode_override_i[1]}]
set_input_transition 0.1 [get_ports {out_mode_override_i[0]}]
set_input_transition 0.1 [get_ports csr_valid_i]
set_input_transition 0.1 [get_ports csr_write_i]
set_input_transition 0.1 [get_ports {csr_addr_i[5]}]
set_input_transition 0.1 [get_ports {csr_addr_i[4]}]
set_input_transition 0.1 [get_ports {csr_addr_i[3]}]
set_input_transition 0.1 [get_ports {csr_addr_i[2]}]
set_input_transition 0.1 [get_ports {csr_addr_i[1]}]
set_input_transition 0.1 [get_ports {csr_addr_i[0]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[31]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[30]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[29]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[28]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[27]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[26]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[25]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[24]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[23]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[22]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[21]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[20]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[19]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[18]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[17]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[16]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[15]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[14]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[13]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[12]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[11]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[10]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[9]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[8]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[7]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[6]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[5]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[4]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[3]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[2]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[1]}]
set_input_transition 0.1 [get_ports {csr_wdata_i[0]}]
set_input_transition 0.1 [get_ports narrow_ready_i]
set_input_transition 0.1 [get_ports shared_readout_en_i]
set_input_transition 0.1 [get_ports acq_ready_i]
set_ideal_network [get_ports clk_sys]
set_ideal_network [get_ports async_rst_n]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LGCNHDX0]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LGCNHDX1]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LGCNHDX2]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LGCNHDX4]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LGCPHDX0]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LGCPHDX1]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LGCPHDX2]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LGCPHDX4]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSGCNHDX0]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSGCNHDX1]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSGCNHDX2]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSGCNHDX4]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSGCPHDX0]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSGCPHDX1]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSGCPHDX2]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSGCPHDX4]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSOGCNHDX0]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSOGCNHDX1]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSOGCNHDX2]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSOGCNHDX4]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSOGCPHDX0]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSOGCPHDX1]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSOGCPHDX2]
set_dont_use false [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/LSOGCPHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRSQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRSQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRSQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRSQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFR2HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFR2HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFR4HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFR4HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFR8HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFR8HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQ2HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQ2HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQ4HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQ4HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQ8HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQ8HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRR2HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRR2HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRR4HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRR4HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRR8HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRR8HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQ2HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQ2HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQ4HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQ4HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQ8HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQ8HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRSQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRSQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRSQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRSQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFQSSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFRQSSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFFSQSSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRQSSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRRQSSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_slow_1_62V_125C/SDFRSQSSHDX4]
set_clock_uncertainty -setup 0.3 [get_clocks clk_sys]
set_clock_uncertainty -hold 0.3 [get_clocks clk_sys]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_slow]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_slow]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_slow_tap1]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_slow_tap1]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_slow_tap2]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_slow_tap2]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_slow_tap3]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_slow_tap3]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_slow_tap4]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_slow_tap4]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_slow_tap5]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_slow_tap5]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_slow_tap6]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_slow_tap6]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_slow_tap7]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_slow_tap7]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_fast]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_fast]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_fast_tap1]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_fast_tap1]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_fast_tap2]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_fast_tap2]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_fast_tap3]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_fast_tap3]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_fast_tap4]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_fast_tap4]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_fast_tap5]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_fast_tap5]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_fast_tap6]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_fast_tap6]
set_clock_uncertainty -setup 0.05 [get_clocks clk_osc_fast_tap7]
set_clock_uncertainty -hold 0.02 [get_clocks clk_osc_fast_tap7]
