// =============================================================================
// SPADMIC VIP — Compile Order File
// Usage: xrun -f TOP/tb/vip/filelist.f
// =============================================================================

// ── VIP package (forward declarations, enums) ────────────────────
pkg/spadmic_vip_pkg.sv

// ── Interfaces ───────────────────────────────────────────────────
interfaces/spadmic_i2c_if.sv
interfaces/spadmic_csr_req_if.sv
interfaces/spadmic_async_event_if.sv
interfaces/spadmic_position_line_if.sv
interfaces/spadmic_narrow_tx_if.sv

// ── Transaction classes ──────────────────────────────────────────
txn/spadmic_base_txn.sv
txn/spadmic_ctrl_txn.sv
txn/spadmic_tdc_event_txn.sv
txn/spadmic_pos_event_txn.sv
txn/spadmic_reset_txn.sv
txn/spadmic_bp_txn.sv
txn/spadmic_eot_txn.sv
txn/spadmic_mon_pkt_txn.sv

// ── Agent / Driver classes ───────────────────────────────────────
agent/spadmic_generator.sv
agent/spadmic_csr_driver.sv
agent/spadmic_i2c_driver.sv
agent/spadmic_event_driver.sv
agent/spadmic_pos_driver.sv
agent/spadmic_bp_driver.sv
agent/spadmic_driver.sv

// ── Monitor classes ──────────────────────────────────────────────
monitor/spadmic_tx_monitor.sv
monitor/spadmic_csr_monitor.sv
monitor/spadmic_ctrl_monitor.sv

// ── Scoreboard + Reference Models ────────────────────────────────
scoreboard/spadmic_scoreboard.sv
scoreboard/spadmic_tdc_ref_model.sv
scoreboard/spadmic_pos_ref_model.sv

// ── Functional Coverage ──────────────────────────────────────────
coverage/spadmic_stim_cov.sv
coverage/spadmic_pkt_cov.sv
coverage/spadmic_ctrl_cov.sv
coverage/spadmic_fault_cov.sv

// ── SVA Assertion Modules ────────────────────────────────────────
sva/spadmic_ctrl_sva.sv
sva/spadmic_readout_sva.sv
sva/spadmic_mux_sva.sv
sva/spadmic_pos_sva.sv
sva/spadmic_sva_bind.sv

// ── Environment + Test Infrastructure ────────────────────────────
env/spadmic_env_cfg.sv
env/spadmic_env.sv
env/spadmic_base_test.sv
env/spadmic_test_factory.sv

// ── Test Library ─────────────────────────────────────────────────
tests/spadmic_smoke_tdc.sv
tests/spadmic_smoke_position.sv
tests/spadmic_smoke_switching.sv
tests/spadmic_tdc_modes.sv
tests/spadmic_pos_clusters.sv
tests/spadmic_ctrl_reject.sv
tests/spadmic_reset_recovery.sv
tests/spadmic_bp_stress.sv
tests/spadmic_i2c_end_to_end.sv
tests/spadmic_long_random.sv
tests/spadmic_coverage_walk.sv
tests/spadmic_stress_random.sv

// ── Top-Level Harness ────────────────────────────────────────────
tb/spadmic_vip_tb.sv
