// =============================================================================
// Project  : SPAD_MPTDC -- Vernier Time-to-Digital Converter
// File     : filelist_o13_phase_distribution.f
// Purpose  : Genus file list for O13 phase-distribution tree experiment
// =============================================================================
// O13 preserves packet layout, raw_lfsr_tag decode, R750_delta5 frequency mode,
// and PD RTL behavior.  The architecture change is confined to the matched
// phase buffer bank:
//
//   RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> digital phase fabric
//
// This is feasibility/closure input, not final signoff.
// =============================================================================

+define+SYNTHESIS
+define+MPTDC_USE_RO_TUNE4_MACRO
+define+MPTDC_FREQ_R750_DELTA5
+define+MPTDC_O13_PHASE_DISTRIBUTION
+define+MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12

../rtl/pkg/mptdc_pkg.sv

../rtl/cdc/mptdc_reset_sync.sv
../rtl/cdc/mptdc_pulse_sync.sv
../rtl/cdc/mptdc_gray_cnt_sync.sv
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

../rtl/readout/mptdc_tconv_reco.sv
../rtl/readout/mptdc_narrow16_tx_v2.sv
../rtl/readout/mptdc_csr_minimal.sv

../rtl/top/mptdc_core.sv
../rtl/top/mptdc_top_asic.sv
