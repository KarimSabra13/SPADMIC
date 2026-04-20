// =============================================================================
// SPADMIC top-level integration — file list
// Compile order: packages first, then modules in dependency order
// =============================================================================

// ── MPTDC baseline (pull from MPTDC/rtl/) ────────────────────────
// The MPTDC filelist must be compiled before this one:
//   -f ../MPTDC/rtl/filelist.f

// ── SPADMIC package ──────────────────────────────────────────────
rtl/spadmic_pkg.sv

// ── I2C control plane (from I2C/) ────────────────────────────────
../I2C/rtl/spadmic_i2c_slave.sv
../I2C/rtl/spadmic_i2c_csr_bridge.sv

// ── Reverse START/STOP adapter ───────────────────────────────────
rtl/spadmic_ref_stop_qualifier.sv

// ── CSR decode / global registers ────────────────────────────────
rtl/spadmic_global_csr.sv
rtl/spadmic_top_sequencer.sv
rtl/spadmic_csr_decoder.sv

// ── Packet arbiter path ──────────────────────────────────────────
rtl/spadmic_tdc_packet_fifo.sv
rtl/spadmic_tdc_arbiter3.sv
rtl/spadmic_tdc_shared_readout.sv
rtl/spadmic_shared_tx_mux.sv
rtl/spadmic_correlated_tx.sv
rtl/spadmic_ddr_tx.sv

// ── Position scanner ─────────────────────────────────────────────
rtl/spadmic_axis_cluster_scan.sv
rtl/spadmic_position_block.sv

// ── Per-axis TDC wrapper & top shell ─────────────────────────────
rtl/spadmic_tdc_axis_wrapper.sv
rtl/spadmic_top_v1.sv
