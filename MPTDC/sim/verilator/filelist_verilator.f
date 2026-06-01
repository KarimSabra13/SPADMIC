// MPTDC Verilator lint filelist.
// Paths are relative to the repository root.

+define+MPTDC_USE_OSC_MODEL

MPTDC/rtl/pkg/mptdc_pkg.sv

MPTDC/rtl/cdc/mptdc_reset_sync.sv
MPTDC/rtl/cdc/mptdc_pulse_sync.sv
MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv
MPTDC/rtl/cdc/mptdc_sync_fifo.sv

MPTDC/rtl/osc/mptdc_osc_model.sv
MPTDC/rtl/osc/mptdc_osc_stub.sv
MPTDC/rtl/osc/mptdc_osc_wrapper.sv

MPTDC/rtl/pd/mptdc_fast_epoch_tag.sv
MPTDC/rtl/pd/mptdc_pd_cell.sv

MPTDC/rtl/async/mptdc_stop_capture_async.sv
MPTDC/rtl/async/mptdc_async_frontend_v2.sv
MPTDC/rtl/async/mptdc_hit_capture_bridge.sv
MPTDC/rtl/async/mptdc_context_bank.sv

MPTDC/rtl/ctrl/mptdc_input_mux.sv
MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv
MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv
MPTDC/rtl/ctrl/mptdc_watchdog.sv

MPTDC/rtl/readout/mptdc_tconv_reco.sv
MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv
MPTDC/rtl/readout/mptdc_csr_minimal.sv

MPTDC/rtl/top/mptdc_core.sv
MPTDC/rtl/top/mptdc_top_asic.sv
