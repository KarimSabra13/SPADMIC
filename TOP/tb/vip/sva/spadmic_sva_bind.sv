// =============================================================================
// SPADMIC SVA — Bind File
// Connects SVA checkers to DUT modules via SystemVerilog bind.
// Bind targets use the active matrix-top integration.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

// ── Control-plane assertions ────────────────────────────────────
bind spadmic_top_matrix_v1 spadmic_ctrl_sva u_ctrl_sva (
  .clk_sys              (clk_sys),
  .rst_n                (rst_sys_n),
  .cfg_accept           (cfg_accept),
  .safe_idle            (safe_idle),
  .global_enable        (global_enable),
  .active_mode          (active_mode),
  .active_axis_mask     (active_axis_mask),
  .csr_req_valid        (csr_req_valid),
  .csr_req_write        (csr_req_write),
  .csr_req_addr         (csr_req_addr),
  .csr_req_ready        (csr_req_ready),
  .csr_rsp_valid        (csr_rsp_valid),
  .csr_rsp_err          (csr_rsp_err)
);

`default_nettype wire
