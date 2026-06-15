// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : filelist_synth.f
// Purpose  : RTL file list for Cadence Genus synthesis
// Author   : Karim Sabra
// =============================================================================
// This filelist excludes simulation-only modules (mptdc_osc_model) and adds
// the SYNTHESIS define so that any `ifdef SYNTHESIS` guards are active.
//
// Usage:
//   In Genus TCL: read_hdl -f ../filelist_synth.f
//   Paths below are resolved from syn/ (genus.tcl switches there before read_hdl)
// =============================================================================

// Synthesis define
+define+SYNTHESIS

// Package (compile first — types, constants, enums)
../rtl/pkg/mptdc_pkg.sv

// CDC primitives (reset sync, pulse sync, gray-code counter sync, FIFO)
../rtl/cdc/mptdc_reset_sync.sv
../rtl/cdc/mptdc_sync_fifo.sv

// Oscillator abstraction — STUB ONLY for synthesis/implementation placeholder
// NOTE: mptdc_osc_model.sv is EXCLUDED (non-synthesizable behavioural model)
../rtl/osc/mptdc_osc_stub.sv
../rtl/osc/mptdc_osc_wrapper.sv
../rtl/osc/mptdc_phase_buffer_bank.sv

// Phase detector cell
../rtl/pd/mptdc_fast_epoch_tag.sv
../rtl/pd/mptdc_slow_epoch_johnson.sv
../rtl/pd/mptdc_pd_cell.sv

// Async frontend / capture logic
../rtl/async/mptdc_stop_capture_async.sv
../rtl/async/mptdc_stop_epoch_capture_async.sv
../rtl/async/mptdc_async_frontend_v2.sv
../rtl/async/mptdc_hit_capture_bridge.sv
../rtl/async/mptdc_context_bank.sv

// Control / orchestration FSMs
../rtl/ctrl/mptdc_input_mux.sv
../rtl/ctrl/mptdc_meas_ctrl.sv
../rtl/ctrl/mptdc_drain_ctrl.sv
../rtl/ctrl/mptdc_watchdog.sv

// Readout / output formatting / CSR
../rtl/readout/mptdc_packet16_tx.sv

// Top-level integration
../rtl/top/mptdc_core.sv
../rtl/top/mptdc_axis_core.sv
