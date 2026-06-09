# ####################################################################

#  Created by Genus(TM) Synthesis Solution 22.13-s093_1 on Tue Jun 09 12:55:40 CEST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design mptdc_top_asic

set_case_analysis 0 [get_ports narrow_ready_i]
set_case_analysis 1 [get_ports shared_readout_en_i]
create_clock -name "clk_sys" -period 6.25 -waveform {0.0 3.125} [get_ports clk_sys]
create_clock -name "clk_osc_slow" -period 1.43 -waveform {0.0 0.715} [get_pins {u_core_u_osc_slow_u_ro_tune4/S[0]}]
create_clock -name "clk_osc_slow_tap1" -period 1.43 -waveform {0.079 0.794} [get_pins {u_core_u_osc_slow_u_ro_tune4/S[1]}]
create_clock -name "clk_osc_slow_tap2" -period 1.43 -waveform {0.158 0.873} [get_pins {u_core_u_osc_slow_u_ro_tune4/S[2]}]
create_clock -name "clk_osc_slow_tap3" -period 1.43 -waveform {0.237 0.952} [get_pins {u_core_u_osc_slow_u_ro_tune4/S[3]}]
create_clock -name "clk_osc_slow_tap4" -period 1.43 -waveform {0.316 1.031} [get_pins {u_core_u_osc_slow_u_ro_tune4/S[4]}]
create_clock -name "clk_osc_slow_tap5" -period 1.43 -waveform {0.395 1.11} [get_pins {u_core_u_osc_slow_u_ro_tune4/S[5]}]
create_clock -name "clk_osc_slow_tap6" -period 1.43 -waveform {0.474 1.189} [get_pins {u_core_u_osc_slow_u_ro_tune4/S[6]}]
create_clock -name "clk_osc_slow_tap7" -period 1.43 -waveform {0.553 1.268} [get_pins {u_core_u_osc_slow_u_ro_tune4/S[7]}]
create_clock -name "clk_osc_fast" -period 1.333 -waveform {0.0 0.6665} [get_pins {u_core_u_osc_fast_u_ro_tune4/S[0]}]
create_clock -name "clk_osc_fast_tap1" -period 1.333 -waveform {0.074 0.7405} [get_pins {u_core_u_osc_fast_u_ro_tune4/S[1]}]
create_clock -name "clk_osc_fast_tap2" -period 1.333 -waveform {0.148 0.8145} [get_pins {u_core_u_osc_fast_u_ro_tune4/S[2]}]
create_clock -name "clk_osc_fast_tap3" -period 1.333 -waveform {0.222 0.8885} [get_pins {u_core_u_osc_fast_u_ro_tune4/S[3]}]
create_clock -name "clk_osc_fast_tap4" -period 1.333 -waveform {0.296 0.9625} [get_pins {u_core_u_osc_fast_u_ro_tune4/S[4]}]
create_clock -name "clk_osc_fast_tap5" -period 1.333 -waveform {0.37 1.0365} [get_pins {u_core_u_osc_fast_u_ro_tune4/S[5]}]
create_clock -name "clk_osc_fast_tap6" -period 1.333 -waveform {0.444 1.1105} [get_pins {u_core_u_osc_fast_u_ro_tune4/S[6]}]
create_clock -name "clk_osc_fast_tap7" -period 1.333 -waveform {0.518 1.1845} [get_pins {u_core_u_osc_fast_u_ro_tune4/S[7]}]
create_generated_clock -name "clk_osc_slow_buf_tap0" -divide_by 1     -source [get_pins {u_core_u_osc_slow_u_ro_tune4/S[0]}]   [get_pins {u_core_u_phase_buf_slow/gen_phase_buf[0].u_drv/Q}] 
create_generated_clock -name "clk_osc_slow_buf_tap1" -divide_by 1     -source [get_pins {u_core_u_osc_slow_u_ro_tune4/S[1]}]   [get_pins {u_core_u_phase_buf_slow/gen_phase_buf[1].u_drv/Q}] 
create_generated_clock -name "clk_osc_slow_buf_tap2" -divide_by 1     -source [get_pins {u_core_u_osc_slow_u_ro_tune4/S[2]}]   [get_pins {u_core_u_phase_buf_slow/gen_phase_buf[2].u_drv/Q}] 
create_generated_clock -name "clk_osc_slow_buf_tap3" -divide_by 1     -source [get_pins {u_core_u_osc_slow_u_ro_tune4/S[3]}]   [get_pins {u_core_u_phase_buf_slow/gen_phase_buf[3].u_drv/Q}] 
create_generated_clock -name "clk_osc_slow_buf_tap4" -divide_by 1     -source [get_pins {u_core_u_osc_slow_u_ro_tune4/S[4]}]   [get_pins {u_core_u_phase_buf_slow/gen_phase_buf[4].u_drv/Q}] 
create_generated_clock -name "clk_osc_slow_buf_tap5" -divide_by 1     -source [get_pins {u_core_u_osc_slow_u_ro_tune4/S[5]}]   [get_pins {u_core_u_phase_buf_slow/gen_phase_buf[5].u_drv/Q}] 
create_generated_clock -name "clk_osc_slow_buf_tap6" -divide_by 1     -source [get_pins {u_core_u_osc_slow_u_ro_tune4/S[6]}]   [get_pins {u_core_u_phase_buf_slow/gen_phase_buf[6].u_drv/Q}] 
create_generated_clock -name "clk_osc_slow_buf_tap7" -divide_by 1     -source [get_pins {u_core_u_osc_slow_u_ro_tune4/S[7]}]   [get_pins {u_core_u_phase_buf_slow/gen_phase_buf[7].u_drv/Q}] 
create_generated_clock -name "clk_osc_fast_buf_tap0" -divide_by 1     -source [get_pins {u_core_u_osc_fast_u_ro_tune4/S[0]}]   [get_pins {u_core_u_phase_buf_fast/gen_phase_buf[0].u_drv/Q}] 
create_generated_clock -name "clk_osc_fast_buf_tap1" -divide_by 1     -source [get_pins {u_core_u_osc_fast_u_ro_tune4/S[1]}]   [get_pins {u_core_u_phase_buf_fast/gen_phase_buf[1].u_drv/Q}] 
create_generated_clock -name "clk_osc_fast_buf_tap2" -divide_by 1     -source [get_pins {u_core_u_osc_fast_u_ro_tune4/S[2]}]   [get_pins {u_core_u_phase_buf_fast/gen_phase_buf[2].u_drv/Q}] 
create_generated_clock -name "clk_osc_fast_buf_tap3" -divide_by 1     -source [get_pins {u_core_u_osc_fast_u_ro_tune4/S[3]}]   [get_pins {u_core_u_phase_buf_fast/gen_phase_buf[3].u_drv/Q}] 
create_generated_clock -name "clk_osc_fast_buf_tap4" -divide_by 1     -source [get_pins {u_core_u_osc_fast_u_ro_tune4/S[4]}]   [get_pins {u_core_u_phase_buf_fast/gen_phase_buf[4].u_drv/Q}] 
create_generated_clock -name "clk_osc_fast_buf_tap5" -divide_by 1     -source [get_pins {u_core_u_osc_fast_u_ro_tune4/S[5]}]   [get_pins {u_core_u_phase_buf_fast/gen_phase_buf[5].u_drv/Q}] 
create_generated_clock -name "clk_osc_fast_buf_tap6" -divide_by 1     -source [get_pins {u_core_u_osc_fast_u_ro_tune4/S[6]}]   [get_pins {u_core_u_phase_buf_fast/gen_phase_buf[6].u_drv/Q}] 
create_generated_clock -name "clk_osc_fast_buf_tap7" -divide_by 1     -source [get_pins {u_core_u_osc_fast_u_ro_tune4/S[7]}]   [get_pins {u_core_u_phase_buf_fast/gen_phase_buf[7].u_drv/Q}] 
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
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_start_wdt_cnt_reg[1]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[3]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[5]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[8]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[9]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[10]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[11]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[12]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[13]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[14]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[15]/RN}]  \
  [get_pins u_core_u_stop_capture_phase0_snap_o_reg/D]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[0]/D}]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[1]/D}]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[2]/D}]  \
  [get_pins u_core_start_timeout_latched_reg/RN]  \
  [get_pins {u_core_start_wdt_cnt_reg[0]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[2]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[4]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[6]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[7]/RN}] ]
set_false_path -through [list \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[7].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[6].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[5].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[4].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[3].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[2].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[1].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[7].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[6].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[5].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[4].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[3].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[2].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[1].u_pd/clear_window}]  \
  [get_pins {u_core_gen_pd_row[0].gen_pd_col[0].u_pd/clear_window}]  \
  [get_pins {u_core_start_wdt_cnt_reg[1]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[3]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[5]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[8]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[9]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[10]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[11]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[12]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[13]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[14]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[15]/RN}]  \
  [get_pins u_core_u_stop_capture_phase0_snap_o_reg/D]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[0]/D}]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[1]/D}]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[2]/D}]  \
  [get_pins u_core_start_timeout_latched_reg/RN]  \
  [get_pins {u_core_start_wdt_cnt_reg[0]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[2]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[4]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[6]/RN}]  \
  [get_pins {u_core_start_wdt_cnt_reg[7]/RN}] ]
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
set_max_delay 1.333 -from [get_clocks clk_sys] -to [list \
  [get_clocks clk_osc_fast]  \
  [get_clocks clk_osc_fast_tap1]  \
  [get_clocks clk_osc_fast_tap2]  \
  [get_clocks clk_osc_fast_tap3]  \
  [get_clocks clk_osc_fast_tap4]  \
  [get_clocks clk_osc_fast_tap5]  \
  [get_clocks clk_osc_fast_tap6]  \
  [get_clocks clk_osc_fast_tap7] ]
set_max_delay 6.25 -from [list \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[2]/Q}]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[1]/Q}]  \
  [get_pins {u_core_u_stop_capture_stop_slow_phase_disc_o_reg[0]/Q}]  \
  [get_pins u_core_u_stop_capture_phase0_snap_o_reg/Q] ] -to [list \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][0]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][1]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][2]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][3]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][4]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][5]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][6]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][7]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][8]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][9]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][10]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][11]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][12]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][13]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][14]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][15]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][16]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][17]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][18]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][19]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][20]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][21]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][22]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][23]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][24]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][25]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][26]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][27]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][28]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][29]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][30]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][31]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][32]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][33]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][34]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][35]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][36]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][37]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][38]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][39]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][40]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][41]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][42]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][43]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][44]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][45]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][46]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][47]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][48]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][49]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][50]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][51]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][52]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][53]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][54]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][55]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][56]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][57]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][58]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][59]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][60]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][61]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][62]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[hit_level][63]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][0]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][1]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][2]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][3]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][4]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][5]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][6]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][7]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][8]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][9]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][10]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][11]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][12]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][13]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][14]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][15]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][16]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][17]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][18]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][19]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][20]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][21]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][22]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][23]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][24]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][25]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][26]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][27]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][28]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][29]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][30]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][31]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][32]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][33]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][34]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][35]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][36]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][37]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][38]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][39]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][40]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][41]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][42]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][43]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][44]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][45]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][46]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][47]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][48]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][49]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][50]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][51]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][52]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][53]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][54]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][55]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][56]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][57]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][58]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][59]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][60]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][61]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][62]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][63]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][64]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][65]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][66]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][67]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][68]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][69]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][70]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][71]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][72]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][73]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][74]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][75]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][76]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][77]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][78]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][79]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][80]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][81]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][82]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][83]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][84]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][85]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][86]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][87]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][88]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][89]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][90]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][91]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][92]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][93]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][94]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][95]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][96]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][97]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][98]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][99]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][100]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][101]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][102]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][103]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][104]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][105]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][106]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][107]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][108]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][109]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][110]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][111]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][112]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][113]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][114]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][115]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][116]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][117]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][118]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][119]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][120]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][121]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][122]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][123]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][124]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][125]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][126]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][127]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][128]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][129]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][130]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][131]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][132]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][133]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][134]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][135]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][136]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][137]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][138]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][139]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][140]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][141]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][142]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][143]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][144]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][145]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][146]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][147]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][148]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][149]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][150]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][151]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][152]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][153]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][154]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][155]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][156]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][157]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][158]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][159]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][160]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][161]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][162]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][163]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][164]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][165]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][166]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][167]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][168]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][169]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][170]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][171]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][172]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][173]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][174]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][175]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][176]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][177]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][178]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][179]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][180]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][181]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][182]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][183]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][184]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][185]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][186]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][187]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][188]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][189]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][190]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][191]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][192]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][193]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][194]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][195]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][196]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][197]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][198]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][199]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][200]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][201]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][202]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][203]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][204]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][205]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][206]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][207]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][208]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][209]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][210]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][211]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][212]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][213]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][214]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][215]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][216]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][217]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][218]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][219]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][220]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][221]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][222]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][223]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][224]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][225]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][226]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][227]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][228]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][229]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][230]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][231]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][232]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][233]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][234]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][235]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][236]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][237]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][238]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][239]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][240]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][241]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][242]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][243]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][244]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][245]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][246]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][247]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][248]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][249]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][250]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][251]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][252]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][253]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][254]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][255]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][256]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][257]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][258]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][259]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][260]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][261]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][262]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][263]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][264]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][265]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][266]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][267]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][268]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][269]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][270]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][271]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][272]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][273]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][274]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][275]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][276]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][277]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][278]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][279]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][280]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][281]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][282]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][283]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][284]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][285]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][286]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][287]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][288]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][289]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][290]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][291]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][292]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][293]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][294]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][295]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][296]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][297]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][298]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][299]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][300]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][301]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][302]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][303]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][304]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][305]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][306]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][307]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][308]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][309]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][310]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][311]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][312]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][313]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][314]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][315]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][316]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][317]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][318]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][319]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][320]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][321]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][322]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][323]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][324]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][325]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][326]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][327]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][328]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][329]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][330]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][331]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][332]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][333]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][334]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][335]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][336]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][337]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][338]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][339]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][340]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][341]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][342]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][343]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][344]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][345]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][346]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][347]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][348]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][349]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][350]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][351]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][352]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][353]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][354]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][355]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][356]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][357]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][358]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][359]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][360]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][361]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][362]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][363]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][364]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][365]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][366]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][367]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][368]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][369]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][370]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][371]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][372]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][373]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][374]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][375]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][376]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][377]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][378]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][379]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][380]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][381]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][382]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][383]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][384]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][385]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][386]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][387]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][388]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][389]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][390]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][391]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][392]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][393]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][394]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][395]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][396]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][397]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][398]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][399]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][400]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][401]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][402]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][403]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][404]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][405]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][406]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][407]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][408]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][409]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][410]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][411]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][412]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][413]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][414]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][415]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][416]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][417]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][418]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][419]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][420]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][421]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][422]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][423]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][424]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][425]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][426]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][427]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][428]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][429]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][430]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][431]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][432]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][433]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][434]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][435]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][436]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][437]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][438]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][439]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][440]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][441]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][442]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][443]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][444]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][445]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][446]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_hit_packed][447]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_snap][1]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_snap][2]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_snap][3]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_snap][4]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_snap][5]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nfast_snap][6]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nslow_snap][0]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nslow_snap][1]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nslow_snap][2]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nslow_snap][3]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nslow_snap][4]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nslow_snap][5]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[nslow_snap][6]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[phase0_snap]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[stop_slow_phase_disc][0]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[stop_slow_phase_disc][1]/D}]  \
  [get_pins {u_core_u_hit_capture_bridge_snapshot_q_reg[stop_slow_phase_disc][2]/D}] ]
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
set_clock_groups -name "clock_groups_clk_sys_to_clk_osc_slow_clk_osc_slow_tap1_clk_osc_slow_tap2_clk_osc_slow_tap3_clk_osc_slow_tap4_clk_osc_slow_tap5_clk_osc_slow_tap6_clk_osc_slow_tap7_clk_osc_fast_clk_osc_fast_tap1_clk_osc_fast_tap2_clk_osc_fast_tap3_clk_osc_fast_tap4_clk_osc_fast_tap5_clk_osc_fast_tap6_clk_osc_fast_tap7_clk_osc_slow_buf_tap0_clk_osc_slow_buf_tap1_clk_osc_slow_buf_tap2_clk_osc_slow_buf_tap3_clk_osc_slow_buf_tap4_clk_osc_slow_buf_tap5_clk_osc_slow_buf_tap6_clk_osc_slow_buf_tap7_clk_osc_fast_buf_tap0_clk_osc_fast_buf_tap1_clk_osc_fast_buf_tap2_clk_osc_fast_buf_tap3_clk_osc_fast_buf_tap4_clk_osc_fast_buf_tap5_clk_osc_fast_buf_tap6_clk_osc_fast_buf_tap7" -asynchronous -group [get_clocks clk_sys] -group [list \
  [get_clocks clk_osc_slow]  \
  [get_clocks clk_osc_slow_tap1]  \
  [get_clocks clk_osc_slow_tap2]  \
  [get_clocks clk_osc_slow_tap3]  \
  [get_clocks clk_osc_slow_tap4]  \
  [get_clocks clk_osc_slow_tap5]  \
  [get_clocks clk_osc_slow_tap6]  \
  [get_clocks clk_osc_slow_tap7]  \
  [get_clocks clk_osc_fast]  \
  [get_clocks clk_osc_fast_tap1]  \
  [get_clocks clk_osc_fast_tap2]  \
  [get_clocks clk_osc_fast_tap3]  \
  [get_clocks clk_osc_fast_tap4]  \
  [get_clocks clk_osc_fast_tap5]  \
  [get_clocks clk_osc_fast_tap6]  \
  [get_clocks clk_osc_fast_tap7]  \
  [get_clocks clk_osc_slow_buf_tap0]  \
  [get_clocks clk_osc_slow_buf_tap1]  \
  [get_clocks clk_osc_slow_buf_tap2]  \
  [get_clocks clk_osc_slow_buf_tap3]  \
  [get_clocks clk_osc_slow_buf_tap4]  \
  [get_clocks clk_osc_slow_buf_tap5]  \
  [get_clocks clk_osc_slow_buf_tap6]  \
  [get_clocks clk_osc_slow_buf_tap7]  \
  [get_clocks clk_osc_fast_buf_tap0]  \
  [get_clocks clk_osc_fast_buf_tap1]  \
  [get_clocks clk_osc_fast_buf_tap2]  \
  [get_clocks clk_osc_fast_buf_tap3]  \
  [get_clocks clk_osc_fast_buf_tap4]  \
  [get_clocks clk_osc_fast_buf_tap5]  \
  [get_clocks clk_osc_fast_buf_tap6]  \
  [get_clocks clk_osc_fast_buf_tap7] ]
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
set_dont_touch [get_designs mptdc_phase_buffer_bank]
set_dont_touch [get_cells u_core_u_phase_buf_fast]
set_dont_touch [get_cells u_core_u_phase_buf_slow]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRSQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRSQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRSQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRSQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFR2HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFR2HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFR4HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFR4HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFR8HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFR8HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQ2HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQ2HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQ4HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQ4HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQ8HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQ8HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRR2HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRR2HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRR4HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRR4HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRR8HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRR8HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQ2HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQ2HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQ4HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQ4HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQ8HDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQ8HDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRSQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRSQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRSQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRSQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSQHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSQHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSQHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSQHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFQSSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFRQSSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFFSQSSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRQSSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRRQSSHDX4]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSQSSHDX0]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSQSSHDX1]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSQSSHDX2]
set_dont_use true [get_lib_cells D_CELLS_HD_LPMOS_typ_1_80V_25C/SDFRSQSSHDX4]
set_clock_uncertainty -setup 0.3 [get_clocks clk_sys]
set_clock_uncertainty -hold 0.3 [get_clocks clk_sys]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_tap1]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_tap1]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_tap2]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_tap2]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_tap3]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_tap3]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_tap4]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_tap4]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_tap5]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_tap5]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_tap6]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_tap6]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_tap7]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_tap7]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_tap1]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_tap1]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_tap2]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_tap2]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_tap3]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_tap3]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_tap4]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_tap4]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_tap5]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_tap5]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_tap6]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_tap6]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_tap7]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_tap7]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_buf_tap0]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_buf_tap0]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_buf_tap1]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_buf_tap1]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_buf_tap2]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_buf_tap2]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_buf_tap3]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_buf_tap3]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_buf_tap4]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_buf_tap4]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_buf_tap5]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_buf_tap5]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_buf_tap6]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_buf_tap6]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_slow_buf_tap7]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_slow_buf_tap7]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_buf_tap0]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_buf_tap0]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_buf_tap1]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_buf_tap1]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_buf_tap2]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_buf_tap2]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_buf_tap3]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_buf_tap3]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_buf_tap4]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_buf_tap4]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_buf_tap5]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_buf_tap5]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_buf_tap6]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_buf_tap6]
set_clock_uncertainty -setup 0.01 [get_clocks clk_osc_fast_buf_tap7]
set_clock_uncertainty -hold 0.005 [get_clocks clk_osc_fast_buf_tap7]
