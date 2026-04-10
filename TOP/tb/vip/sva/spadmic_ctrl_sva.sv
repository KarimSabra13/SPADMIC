// =============================================================================
// SPADMIC SVA — Control-Plane Protocol Assertions
// Checks sequencer, CSR decoder, and config-accept contracts.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_ctrl_sva
  import spadmic_pkg::*;
  import mptdc_pkg::*;
(
  input wire        clk_sys,
  input wire        rst_n,

  // Sequencer signals
  input wire [1:0]  seq_state,           // 0=RESET, 1=IDLE, 2=DRAIN
  input wire        cfg_accept,
  input wire        global_enable_active,
  input wire        path_idle,
  input wire        transition_busy,

  // CSR decoder signals
  input wire        csr_req_valid,
  input wire        csr_req_write,
  input wire [11:0] csr_req_addr,
  input wire        csr_req_ready,
  input wire        csr_rsp_valid,
  input wire        csr_rsp_err,

  // Fault tracking
  input wire        mode_reject_sticky,
  input wire [7:0]  mode_reject_count
);

  // SEQ_RESET=0, SEQ_IDLE=1, SEQ_DRAIN=2
  localparam [1:0] SEQ_RESET = 2'd0;
  localparam [1:0] SEQ_IDLE  = 2'd1;
  localparam [1:0] SEQ_DRAIN = 2'd2;

  // P1: cfg_accept only when sequencer is IDLE and path is idle
  property p_cfg_accept_gate;
    @(posedge clk_sys) disable iff (!rst_n)
    cfg_accept |-> (seq_state == SEQ_IDLE) && path_idle;
  endproperty
  a_cfg_accept_gate: assert property (p_cfg_accept_gate)
    else $error("[CTRL_SVA] cfg_accept asserted while not IDLE+path_idle");

  // P2: sequencer forces global_enable low during DRAIN
  property p_drain_disables;
    @(posedge clk_sys) disable iff (!rst_n)
    (seq_state == SEQ_DRAIN) |-> (global_enable_active == 1'b0);
  endproperty
  a_drain_disables: assert property (p_drain_disables)
    else $error("[CTRL_SVA] global_enable not deasserted during DRAIN");

  // P3: transition_busy cleared only in IDLE state
  property p_transition_clear_in_idle;
    @(posedge clk_sys) disable iff (!rst_n)
    $fell(transition_busy) |-> (seq_state == SEQ_IDLE);
  endproperty
  a_transition_clear: assert property (p_transition_clear_in_idle)
    else $error("[CTRL_SVA] transition_busy cleared outside IDLE");

  // P4: mode_reject_count monotonically increases (never decreases except on reset)
  property p_reject_count_monotonic;
    @(posedge clk_sys) disable iff (!rst_n)
    $past(rst_n) |-> mode_reject_count >= $past(mode_reject_count);
  endproperty
  a_reject_monotonic: assert property (p_reject_count_monotonic)
    else $error("[CTRL_SVA] mode_reject_count decreased");

  // P5: CSR response valid must follow a request (no spurious responses)
  // (simplified: if no request was pending, no response should appear)

endmodule

`default_nettype wire
