// =============================================================================
// SPADMIC SVA — Control-Plane Protocol Assertions
// Checks ABI 1.0 configuration and CSR request/response contracts.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_ctrl_sva
  import spadmic_pkg::*;
  import mptdc_pkg::*;
(
  input wire        clk_sys,
  input wire        rst_n,

  input wire        cfg_accept,
  input wire        safe_idle,
  input wire        global_enable,
  input wire [2:0]  active_mode,
  input wire [2:0]  active_axis_mask,

  // CSR decoder signals
  input wire        csr_req_valid,
  input wire        csr_req_write,
  input wire [15:0] csr_req_addr,
  input wire        csr_req_ready,
  input wire        csr_rsp_valid,
  input wire        csr_rsp_err
);

  property p_cfg_accept_gate;
    @(posedge clk_sys) disable iff (!rst_n)
    cfg_accept |-> safe_idle;
  endproperty
  a_cfg_accept_gate: assert property (p_cfg_accept_gate)
    else $error("[CTRL_SVA] cfg_accept asserted while global resources were busy");

  property p_normal_mode_axis_policy;
    @(posedge clk_sys) disable iff (!rst_n)
    global_enable && (active_mode inside {SPADMIC_MODE_TDC_ONLY, SPADMIC_MODE_BOTH})
      |-> (active_axis_mask == 3'b111);
  endproperty
  a_normal_mode_axis_policy: assert property (p_normal_mode_axis_policy)
    else $error("[CTRL_SVA] normal matrix TDC mode used a partial axis mask");

  property p_response_follows_request;
    @(posedge clk_sys) disable iff (!rst_n)
    csr_req_valid && csr_req_ready |=> csr_rsp_valid;
  endproperty
  a_response_follows_request: assert property (p_response_follows_request)
    else $error("[CTRL_SVA] accepted CSR request did not receive a response");

  property p_no_spurious_response;
    @(posedge clk_sys) disable iff (!rst_n)
    csr_rsp_valid |-> $past(csr_req_valid && csr_req_ready);
  endproperty
  a_no_spurious_response: assert property (p_no_spurious_response)
    else $error("[CTRL_SVA] CSR response appeared without an accepted request");

  property p_control_change_was_safe;
    @(posedge clk_sys) disable iff (!rst_n)
    $past(rst_n) && $changed({global_enable, active_mode, active_axis_mask})
      |-> $past(safe_idle);
  endproperty
  a_control_change_was_safe: assert property (p_control_change_was_safe)
    else $error("[CTRL_SVA] active global control changed without prior safe-idle");

  property p_cfg_accept_is_write_response;
    @(posedge clk_sys) disable iff (!rst_n)
    cfg_accept |-> $past(csr_req_valid && csr_req_ready && csr_req_write);
  endproperty
  a_cfg_accept_is_write_response: assert property (p_cfg_accept_is_write_response)
    else $error("[CTRL_SVA] cfg_accept was not caused by an accepted CSR write");

endmodule

`default_nettype wire
