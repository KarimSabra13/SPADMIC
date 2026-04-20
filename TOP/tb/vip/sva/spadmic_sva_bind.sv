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

// ── Shared Readout assertions ───────────────────────────────────
bind spadmic_tdc_shared_readout spadmic_readout_sva u_readout_sva (
  .clk_sys    (clk_sys),
  .rst_n      (rst_n),
  .acq_valid  (acq_valid_i),
  .acq_ready  (acq_ready_o),
  .busy       (busy_o),
  .packet_src (packet_src_o),
  .out_valid  (shared_valid_o),
  .out_data   (shared_data_o)
);

// ── Position path framing assertions ────────────────────────────
bind spadmic_position_block spadmic_pos_sva u_pos_sva (
  .clk_sys       (clk_sys),
  .rst_n         (rst_n),
  .pos_tx_valid  (pos_valid_o),
  .pos_tx_data   (pos_data_o),
  .pos_tx_ready  (pos_ready_i),
  .pos_fsm_state ({1'b0, det_state_q}),
  .word_idx      (word_idx_q),
  .pos_busy      (busy_o)
);

`default_nettype wire
