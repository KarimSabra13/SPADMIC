// =============================================================================
// SPADMIC VIP — Compile Order File
// Usage: xrun -f TOP/tb/vip/filelist.f
//
// Class files are `included inside spadmic_vip_pkg.sv (Xcelium requires
// all class definitions in the same compilation unit as the package).
// Only interfaces, SVA bind modules, and the package are listed here.
// =============================================================================

// ── Interfaces (compiled first — classes reference them via virtual) ──
interfaces/spadmic_reset_if.sv
interfaces/spadmic_i2c_if.sv
interfaces/spadmic_csr_req_if.sv
interfaces/spadmic_async_event_if.sv
../../../position/vip/interfaces/spadmic_position_line_if.sv
interfaces/spadmic_narrow_tx_if.sv
interfaces/spadmic_spad_reset_if.sv

// ── VIP package (includes all class files) ───────────────────────
pkg/spadmic_vip_pkg.sv

// ── SVA Assertion Modules ────────────────────────────────────────
sva/spadmic_ctrl_sva.sv
sva/spadmic_readout_sva.sv
sva/spadmic_mux_sva.sv
../../../position/vip/sva/spadmic_pos_sva.sv
sva/spadmic_sva_bind.sv

// ── Top-Level Harness ────────────────────────────────────────────
tb/spadmic_vip_tb.sv
