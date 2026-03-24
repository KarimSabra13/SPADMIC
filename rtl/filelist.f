// MPTDC v2.0 — RTL File List
// Compile order: package first, then leaf modules, then integration

// Package (must be first)
rtl/pkg/mptdc_pkg.sv

// CDC primitives
rtl/cdc/mptdc_reset_sync.sv
rtl/cdc/mptdc_pulse_sync.sv
rtl/cdc/mptdc_gray_cnt_sync.sv
rtl/cdc/mptdc_async_fifo.sv

// Oscillator
rtl/osc/mptdc_osc_model.sv
rtl/osc/mptdc_osc_stub.sv
rtl/osc/mptdc_osc_wrapper.sv

// Phase detector
rtl/pd/mptdc_pd_cell.sv

// Async capture
rtl/async/mptdc_stop_capture_async.sv
rtl/async/mptdc_async_frontend_v2.sv
rtl/async/mptdc_context_bank.sv
rtl/async/mptdc_writer_scan.sv

// Control
rtl/ctrl/mptdc_input_mux.sv
rtl/ctrl/mptdc_ctrl_fsm_v2.sv
rtl/ctrl/mptdc_watchdog.sv

// Readout
rtl/readout/mptdc_tconv_reco.sv
rtl/readout/mptdc_narrow16_tx_v2.sv
rtl/readout/mptdc_csr_minimal.sv

// Integration (top-down)
rtl/top/mptdc_core.sv
rtl/top/mptdc_top_asic.sv
