// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : filelist_o2_raw_tag.f
// Purpose  : Genus file list for O2 raw local fast-tag experiment
// =============================================================================
// O2 keeps the O1C real RO_tune4 macro binding mode and replaces the live
// global binary nfast counter in the PD capture path with one local LFSR tag
// generator per fast column.  The raw tag is exported in the existing nfast
// packet field and decoded by software/calibration.
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
../rtl/pd/mptdc_pd_cell.sv

../rtl/async/mptdc_stop_capture_async.sv
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
