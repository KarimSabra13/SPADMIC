// =============================================================================
// Project  : SPAD_MPTDC -- product-axis Vernier TDC
// File     : filelist_axis_core_typical_closed.f
// Purpose  : Canonical Genus filelist for the typical-closed handoff baseline.
// Top      : mptdc_axis_core
// =============================================================================
// The MPTDC_O13_* defines below are retained RTL implementation guards for the
// validated BUJIHDX4 -> BUJIHDX12 phase distribution. O13 is not the public flow
// name; the canonical entrypoint is run_genus_axis_core_typical_closed.sh.
//
// This filelist excludes the behavioral oscillator model and binds the real
// RO_tune6 macro interface through the synthesis environment.
// =============================================================================

+define+SYNTHESIS
+define+MPTDC_USE_RO_TUNE6_MACRO
+define+MPTDC_FREQ_R750_DELTA5
+define+MPTDC_O13_PHASE_DISTRIBUTION
+define+MPTDC_PHASE_BUFFER_TOPO_BUJIHDX4_BUJIHDX12
+define+MPTDC_SAFE_TEARDOWN
+define+MPTDC_DRAIN_ROW_SKIP
+define+MPTDC_DRAIN_SCAN_STRIDE2

../rtl/pkg/mptdc_pkg.sv

../rtl/cdc/mptdc_reset_sync.sv
../rtl/cdc/mptdc_sync_fifo.sv

../rtl/osc/mptdc_osc_wrapper.sv
../rtl/osc/mptdc_phase_buffer_bank.sv

../rtl/pd/mptdc_fast_epoch_tag.sv
../rtl/pd/mptdc_slow_epoch_johnson.sv
../rtl/pd/mptdc_pd_cell.sv

../rtl/async/mptdc_stop_capture_async.sv
../rtl/async/mptdc_stop_epoch_capture_async.sv
../rtl/async/mptdc_async_frontend_v2.sv
../rtl/async/mptdc_hit_capture_bridge.sv
../rtl/async/mptdc_context_bank.sv

../rtl/ctrl/mptdc_input_mux.sv
../rtl/ctrl/mptdc_meas_ctrl.sv
../rtl/ctrl/mptdc_drain_ctrl.sv
../rtl/ctrl/mptdc_watchdog.sv

../rtl/readout/mptdc_packet16_tx.sv

../rtl/top/mptdc_core.sv
../rtl/top/mptdc_axis_core.sv
