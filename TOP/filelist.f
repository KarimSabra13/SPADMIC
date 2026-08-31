// =============================================================================
// SPADMIC top-level integration — file list
// Compile order: packages first, then modules in dependency order
// =============================================================================

// ── MPTDC baseline (pull from MPTDC/rtl/) ────────────────────────
// The MPTDC filelist must be compiled before this one:
//   -f ../MPTDC/rtl/filelist.f

// ── SPADMIC package ──────────────────────────────────────────────
rtl/spadmic_csr_map_pkg.sv
rtl/spadmic_pkg.sv

// ── Matrix-top standalone Phase 1 blocks ────────────────────────
rtl/spadmic_matrix_or_tree.sv
rtl/spadmic_matrix_snapshot_frontend.sv
rtl/spadmic_matrix_reset_ctrl.sv
rtl/spadmic_event_coordinator.sv
rtl/spadmic_ddr16_tx_pairer.sv
rtl/spadmic_ddrs2_adapter.sv
rtl/spadmic_output_fifo.sv
rtl/spadmic_output_fifo_topcfg.sv
rtl/spadmic_matrix_cfg_ctrl.sv
rtl/spadmic_csr_router.sv
rtl/spadmic_csr_banks.sv
rtl/spadmic_matrix_top_csr.sv
rtl/spadmic_position_snapshot_packetizer.sv
rtl/spadmic_position_core.sv
rtl/spadmic_event_bundle_tx.sv
rtl/spadmic_tx_packet_core.sv
rtl/spadmic_tx_ddr_strip.sv
rtl/spadmic_tx_egress_cluster.sv
rtl/spadmic_tx_egress_core.sv
pnr/assembly/spadmic_digital_assembly_v1.sv

// ── I2C control plane (from I2C/) ────────────────────────────────
../I2C/rtl/spadmic_i2c_slave.sv
../I2C/rtl/spadmic_i2c_csr_bridge.sv

// ── Reverse START/STOP adapter ───────────────────────────────────
rtl/spadmic_ref_stop_qualifier.sv

// ── Retained independent control/datapath support ────────────────
rtl/spadmic_top_sequencer.sv

// ── Packet arbiter path ──────────────────────────────────────────
../arb/rtl/spadmic_position_packet_adapter.sv
../arb/rtl/spadmic_packet_arbiter4.sv
../arb/rtl/spadmic_stream_skid_buffer.sv
../arb/rtl/spadmic_correlated_tx.sv
rtl/spadmic_ddr_tx.sv

// ── Position scanner ─────────────────────────────────────────────
../position/rtl/spadmic_axis_cluster_scan.sv
../position/rtl/spadmic_position_block.sv

// ── Per-axis TDC wrapper & top shell ─────────────────────────────
rtl/spadmic_tdc_axis_wrapper.sv
rtl/spadmic_tdc3_frontend.sv
rtl/spadmic_top_matrix_v1.sv
