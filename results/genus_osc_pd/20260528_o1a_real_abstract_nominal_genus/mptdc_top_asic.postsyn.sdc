# ####################################################################

#  Created by Genus(TM) Synthesis Solution 22.13-s093_1 on Thu May 28 15:15:24 CEST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design mptdc_top_asic

set_case_analysis 0 [get_ports narrow_ready_i]
set_case_analysis 1 [get_ports shared_readout_en_i]
create_clock -name "clk_sys" -period 6.25 -waveform {0.0 3.125} [get_ports clk_sys]
create_clock -name "clk_osc_slow" -period 1.0 -waveform {0.0 0.5} [get_pins {u_core_u_osc_slow_u_stub/phase[0]}]
create_clock -name "clk_osc_slow_tap1" -period 1.0 -waveform {0.055 0.555} [get_pins {u_core_u_osc_slow_u_stub/phase[1]}]
create_clock -name "clk_osc_slow_tap2" -period 1.0 -waveform {0.11 0.61} [get_pins {u_core_u_osc_slow_u_stub/phase[2]}]
create_clock -name "clk_osc_slow_tap3" -period 1.0 -waveform {0.165 0.665} [get_pins {u_core_u_osc_slow_u_stub/phase[3]}]
create_clock -name "clk_osc_slow_tap4" -period 1.0 -waveform {0.22 0.72} [get_pins {u_core_u_osc_slow_u_stub/phase[4]}]
create_clock -name "clk_osc_slow_tap5" -period 1.0 -waveform {0.275 0.775} [get_pins {u_core_u_osc_slow_u_stub/phase[5]}]
create_clock -name "clk_osc_slow_tap6" -period 1.0 -waveform {0.33 0.83} [get_pins {u_core_u_osc_slow_u_stub/phase[6]}]
create_clock -name "clk_osc_slow_tap7" -period 1.0 -waveform {0.385 0.885} [get_pins {u_core_u_osc_slow_u_stub/phase[7]}]
create_clock -name "clk_osc_fast" -period 0.9 -waveform {0.0 0.45} [get_pins {u_core_u_osc_fast_u_stub/phase[0]}]
create_clock -name "clk_osc_fast_tap1" -period 0.9 -waveform {0.05 0.5} [get_pins {u_core_u_osc_fast_u_stub/phase[1]}]
create_clock -name "clk_osc_fast_tap2" -period 0.9 -waveform {0.1 0.55} [get_pins {u_core_u_osc_fast_u_stub/phase[2]}]
create_clock -name "clk_osc_fast_tap3" -period 0.9 -waveform {0.15 0.6} [get_pins {u_core_u_osc_fast_u_stub/phase[3]}]
create_clock -name "clk_osc_fast_tap4" -period 0.9 -waveform {0.2 0.65} [get_pins {u_core_u_osc_fast_u_stub/phase[4]}]
create_clock -name "clk_osc_fast_tap5" -period 0.9 -waveform {0.25 0.7} [get_pins {u_core_u_osc_fast_u_stub/phase[5]}]
create_clock -name "clk_osc_fast_tap6" -period 0.9 -waveform {0.3 0.75} [get_pins {u_core_u_osc_fast_u_stub/phase[6]}]
create_clock -name "clk_osc_fast_tap7" -period 0.9 -waveform {0.35 0.8} [get_pins {u_core_u_osc_fast_u_stub/phase[7]}]
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
group_path -name OPD_PD_CAPTURE -to [list \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/nfast_hit[0]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/hit_level}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/nfast_hit[6]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/nfast_hit[5]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/nfast_hit[4]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/nfast_hit[3]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/nfast_hit[2]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/nfast_hit[1]}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/nfast_hit[0]}] ]
group_path -name OPD_REAL_FAST -to [list \
  [get_pins {u_core_u_fast_cnt/src_count[6]}]  \
  [get_pins {u_core_u_fast_cnt/src_count[5]}]  \
  [get_pins {u_core_u_fast_cnt/src_count[4]}]  \
  [get_pins {u_core_u_fast_cnt/src_count[3]}]  \
  [get_pins {u_core_u_fast_cnt/src_count[2]}]  \
  [get_pins {u_core_u_fast_cnt/src_count[1]}]  \
  [get_pins {u_core_u_fast_cnt/src_count[0]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_continuous[6]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_continuous[5]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_continuous[4]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_continuous[3]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_continuous[2]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_continuous[1]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_continuous[0]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_latched[6]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_latched[5]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_latched[4]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_latched[3]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_latched[2]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_latched[1]}]  \
  [get_pins {u_core_u_fast_cnt/dst_count_latched[0]}] ]
group_path -name OPD_REAL_SLOW -to [list \
  [get_pins {u_core_u_slow_cnt/src_count[6]}]  \
  [get_pins {u_core_u_slow_cnt/src_count[5]}]  \
  [get_pins {u_core_u_slow_cnt/src_count[4]}]  \
  [get_pins {u_core_u_slow_cnt/src_count[3]}]  \
  [get_pins {u_core_u_slow_cnt/src_count[2]}]  \
  [get_pins {u_core_u_slow_cnt/src_count[1]}]  \
  [get_pins {u_core_u_slow_cnt/src_count[0]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_continuous[6]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_continuous[5]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_continuous[4]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_continuous[3]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_continuous[2]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_continuous[1]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_continuous[0]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_latched[6]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_latched[5]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_latched[4]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_latched[3]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_latched[2]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_latched[1]}]  \
  [get_pins {u_core_u_slow_cnt/dst_count_latched[0]}] ]
group_path -name OPD_HELD_BUS_CDC -to [list \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[flags][closed_by_watchdog]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[flags][closed_by_maxhits]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[flags][closed_by_fast_maxhit]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[flags][reserved]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_count][3]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_count][2]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_count][1]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_count][0]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[slow_boundary_inc]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[stop_slow_phase_disc][2]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[stop_slow_phase_disc][1]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[stop_slow_phase_disc][0]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[phase0_snap]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_stop][6]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_stop][5]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_stop][4]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_stop][3]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_stop][2]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_stop][1]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_stop][0]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_snap][6]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_snap][5]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_snap][4]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_snap][3]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_snap][2]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_snap][1]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_snap][0]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nslow_snap][6]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nslow_snap][5]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nslow_snap][4]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nslow_snap][3]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nslow_snap][2]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nslow_snap][1]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nslow_snap][0]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][447]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][446]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][445]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][444]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][443]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][442]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][441]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][440]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][439]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][438]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][437]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][436]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][435]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][434]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][433]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][432]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][431]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][430]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][429]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][428]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][427]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][426]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][425]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][424]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][423]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][422]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][421]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][420]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][419]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][418]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][417]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][416]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][415]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][414]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][413]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][412]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][411]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][410]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][409]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][408]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][407]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][406]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][405]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][404]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][403]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][402]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][401]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][400]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][399]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][398]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][397]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][396]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][395]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][394]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][393]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][392]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][391]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][390]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][389]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][388]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][387]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][386]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][385]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][384]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][383]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][382]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][381]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][380]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][379]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][378]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][377]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][376]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][375]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][374]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][373]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][372]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][371]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][370]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][369]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][368]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][367]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][366]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][365]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][364]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][363]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][362]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][361]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][360]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][359]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][358]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][357]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][356]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][355]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][354]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][353]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][352]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][351]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][350]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][349]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][348]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][347]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][346]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][345]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][344]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][343]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][342]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][341]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][340]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][339]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][338]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][337]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][336]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][335]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][334]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][333]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][332]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][331]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][330]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][329]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][328]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][327]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][326]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][325]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][324]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][323]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][322]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][321]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][320]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][319]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][318]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][317]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][316]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][315]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][314]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][313]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][312]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][311]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][310]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][309]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][308]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][307]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][306]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][305]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][304]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][303]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][302]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][301]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][300]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][299]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][298]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][297]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][296]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][295]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][294]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][293]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][292]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][291]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][290]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][289]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][288]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][287]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][286]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][285]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][284]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][283]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][282]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][281]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][280]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][279]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][278]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][277]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][276]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][275]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][274]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][273]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][272]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][271]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][270]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][269]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][268]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][267]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][266]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][265]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][264]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][263]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][262]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][261]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][260]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][259]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][258]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][257]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][256]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][255]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][254]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][253]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][252]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][251]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][250]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][249]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][248]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][247]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][246]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][245]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][244]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][243]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][242]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][241]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][240]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][239]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][238]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][237]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][236]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][235]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][234]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][233]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][232]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][231]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][230]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][229]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][228]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][227]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][226]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][225]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][224]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][223]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][222]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][221]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][220]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][219]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][218]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][217]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][216]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][215]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][214]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][213]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][212]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][211]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][210]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][209]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][208]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][207]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][206]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][205]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][204]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][203]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][202]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][201]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][200]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][199]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][198]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][197]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][196]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][195]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][194]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][193]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][192]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][191]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][190]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][189]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][188]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][187]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][186]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][185]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][184]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][183]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][182]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][181]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][180]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][179]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][178]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][177]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][176]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][175]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][174]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][173]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][172]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][171]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][170]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][169]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][168]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][167]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][166]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][165]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][164]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][163]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][162]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][161]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][160]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][159]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][158]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][157]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][156]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][155]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][154]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][153]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][152]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][151]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][150]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][149]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][148]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][147]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][146]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][145]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][144]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][143]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][142]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][141]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][140]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][139]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][138]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][137]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][136]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][135]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][134]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][133]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][132]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][131]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][130]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][129]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][128]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][127]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][126]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][125]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][124]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][123]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][122]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][121]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][120]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][119]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][118]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][117]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][116]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][115]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][114]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][113]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][112]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][111]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][110]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][109]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][108]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][107]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][106]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][105]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][104]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][103]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][102]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][101]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][100]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][99]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][98]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][97]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][96]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][95]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][94]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][93]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][92]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][91]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][90]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][89]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][88]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][87]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][86]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][85]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][84]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][83]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][82]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][81]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][80]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][79]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][78]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][77]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][76]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][75]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][74]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][73]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][72]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][71]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][70]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][69]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][68]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][67]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][66]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][65]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][64]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][63]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][62]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][61]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][60]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][59]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][58]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][57]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][56]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][55]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][54]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][53]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][52]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][51]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][50]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][49]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][48]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][47]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][46]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][45]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][44]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][43]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][42]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][41]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][40]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][39]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][38]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][37]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][36]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][35]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][34]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][33]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][32]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][31]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][30]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][29]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][28]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][27]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][26]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][25]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][24]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][23]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][22]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][21]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][20]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][19]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][18]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][17]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][16]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][15]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][14]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][13]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][12]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][11]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][10]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][9]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][8]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][7]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][6]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][5]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][4]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][3]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][2]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][1]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[nfast_hit_packed][0]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][63]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][62]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][61]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][60]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][59]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][58]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][57]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][56]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][55]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][54]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][53]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][52]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][51]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][50]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][49]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][48]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][47]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][46]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][45]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][44]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][43]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][42]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][41]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][40]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][39]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][38]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][37]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][36]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][35]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][34]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][33]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][32]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][31]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][30]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][29]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][28]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][27]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][26]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][25]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][24]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][23]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][22]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][21]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][20]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][19]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][18]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][17]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][16]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][15]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][14]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][13]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][12]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][11]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][10]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][9]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][8]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][7]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][6]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][5]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][4]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][3]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][2]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][1]}]  \
  [get_pins {u_core_u_hit_capture_bridge/snapshot_o[hit_level][0]}] ]
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
