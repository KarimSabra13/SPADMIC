// =============================================================================
// Project  : SPAD_MPTDC -- Vernier Time-to-Digital Converter
// File     : filelist_o5_pd_stdcell_closure.f
// Purpose  : Genus file list for O5 standard-cell PD timing experiments
// =============================================================================
// O5 keeps the O2/O3/O4 local raw fast-tag and slow Johnson architecture,
// preserves packet layout and raw-tag software decode, and experiments with
// standard-cell PD timestamp implementation style: no-reset timestamp flops and
// optional clock-gating inference.
// =============================================================================

+define+SYNTHESIS
+define+MPTDC_USE_RO_TUNE4_MACRO

../rtl/pkg/mptdc_pkg.sv

../rtl/cdc/mptdc_reset_sync.sv
../rtl/cdc/mptdc_pulse_sync.sv
../rtl/cdc/mptdc_gray_cnt_sync.sv
../rtl/cdc/mptdc_sync_fifo.sv

../rtl/osc/mptdc_osc_wrapper.sv

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
