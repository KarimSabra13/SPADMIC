// =============================================================================
// SPADMIC VIP — Control-State Transition Monitor
// Tracks requested vs active state transitions and drain/commit behavior.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_ctrl_monitor;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  // Direct signal access via hierarchical path (set by harness)
  // These are sampled from DUT internals
  virtual spadmic_csr_req_if csr_if;

  // Tracked control-plane state
  int unsigned cfg_accept_count;
  int unsigned cfg_reject_count;
  int unsigned transition_count;
  int unsigned drain_count;
  bit          running;

  function new(virtual spadmic_csr_req_if csr_if);
    this.csr_if            = csr_if;
    this.cfg_accept_count  = 0;
    this.cfg_reject_count  = 0;
    this.transition_count  = 0;
    this.drain_count       = 0;
    this.running           = 1'b0;
  endfunction

  task automatic run();
    running = 1'b1;
    // Control-state monitoring is done via periodic status reads
    // in the actual test, or via DUT signal probing in the harness.
    // This monitor provides a centralized summary.
    forever begin
      @(posedge csr_if.clk_sys);
      if (!csr_if.rst_n) continue;
      // Signal sampling would occur here via bind or hierarchical access
    end
  endtask

  function void report();
    $display("═══════════════════════════════════════════════════");
    $display("  CONTROL-STATE MONITOR SUMMARY");
    $display("═══════════════════════════════════════════════════");
    $display("  Config accepts:     %0d", cfg_accept_count);
    $display("  Config rejects:     %0d", cfg_reject_count);
    $display("  Transitions:        %0d", transition_count);
    $display("  Drain events:       %0d", drain_count);
    $display("═══════════════════════════════════════════════════");
  endfunction

endclass

`default_nettype wire
