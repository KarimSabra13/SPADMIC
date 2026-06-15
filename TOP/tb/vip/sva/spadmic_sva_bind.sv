// =============================================================================
// SPADMIC SVA — Bind File
// Connects SVA checkers to DUT modules via SystemVerilog bind.
// Bind targets use the instance path within spadmic_top_v1.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

// ── Control-plane assertions ────────────────────────────────────
// Bound at spadmic_top_v1 because signals span u_global_csr and u_top_sequencer.
bind spadmic_top_v1 spadmic_ctrl_sva u_ctrl_sva (
  .clk_sys              (clk_sys),
  .rst_n                (rst_sys_n),
  .seq_state            (u_top_sequencer.state_q),
  .cfg_accept           (seq_cfg_accept),
  .global_enable_active (global_enable),
  .path_idle            (u_top_sequencer.path_idle),
  .transition_busy      (seq_transition_busy),
  .csr_req_valid        (csr_req_valid),
  .csr_req_write        (csr_req_write),
  .csr_req_addr         (csr_req_addr),
  .csr_req_ready        (csr_req_ready),
  .csr_rsp_valid        (csr_rsp_valid),
  .csr_rsp_err          (csr_rsp_err),
  .mode_reject_sticky   (u_global_csr.mode_reject_sticky_q),
  .mode_reject_count    (u_global_csr.mode_reject_count_q[7:0])
);

`default_nettype wire
