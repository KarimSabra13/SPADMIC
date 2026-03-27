// MPTDC RTL file list
// Compile order: package -> reusable leaves -> control/readout -> integration

// Package (compile first)
rtl/pkg/mptdc_pkg.sv

// CDC primitives
rtl/cdc/mptdc_reset_sync.sv
rtl/cdc/mptdc_pulse_sync.sv
rtl/cdc/mptdc_gray_cnt_sync.sv
rtl/cdc/mptdc_sync_fifo.sv

// Oscillator abstraction
rtl/osc/mptdc_osc_model.sv
rtl/osc/mptdc_osc_stub.sv
rtl/osc/mptdc_osc_wrapper.sv

// Phase detector
rtl/pd/mptdc_pd_cell.sv

// Async frontend / capture
rtl/async/mptdc_stop_capture_async.sv
rtl/async/mptdc_async_frontend_v2.sv
rtl/async/mptdc_context_bank.sv

// Control / orchestration
rtl/ctrl/mptdc_input_mux.sv
rtl/ctrl/mptdc_meas_ctrl.sv
rtl/ctrl/mptdc_drain_ctrl.sv
rtl/ctrl/mptdc_watchdog.sv

// Readout / CSR
rtl/readout/mptdc_tconv_reco.sv
rtl/readout/mptdc_narrow16_tx_v2.sv
rtl/readout/mptdc_csr_minimal.sv

// Top-level integration
rtl/top/mptdc_core.sv
rtl/top/mptdc_top_asic.sv
