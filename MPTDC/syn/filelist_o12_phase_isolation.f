// =============================================================================
// Project  : SPAD_MPTDC -- Vernier Time-to-Digital Converter
// File     : filelist_o12_phase_isolation.f
// Purpose  : Genus file list for O12 phase-isolation buffer experiment
// =============================================================================
// O12 preserves packet layout, raw_lfsr_tag decode, R750_delta5 frequency mode,
// and PD RTL behavior.  The only architecture change is a matched phase buffer
// bank between RO_tune4/S[0:7] and the existing phase fabric.
// =============================================================================

+define+SYNTHESIS
+define+MPTDC_USE_RO_TUNE4_MACRO
+define+MPTDC_FREQ_R750_DELTA5
+define+MPTDC_O12_PHASE_ISOLATION
+define+MPTDC_PHASE_BUFFER_USE_BUHDX4

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
