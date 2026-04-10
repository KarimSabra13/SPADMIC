// =============================================================================
// SPADMIC VIP — Backpressure Driver
// Controls chip_tx_ready to simulate downstream stalls.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_bp_driver;
  import spadmic_vip_pkg::*;

  virtual spadmic_narrow_tx_if tx_if;
  spadmic_bp_mode_e current_mode;
  bit running;

  function new(virtual spadmic_narrow_tx_if tx_if);
    this.tx_if        = tx_if;
    this.current_mode = BP_ALWAYS_READY;
    this.running      = 1'b0;
  endfunction

  task automatic set_mode(spadmic_bp_mode_e mode);
    this.current_mode = mode;
  endtask

  // Run forever in background, applying current BP mode
  task automatic run();
    running = 1'b1;
    forever begin
      @(posedge tx_if.clk_sys);
      case (current_mode)
        BP_ALWAYS_READY: tx_if.ready = 1'b1;
        BP_ALWAYS_STALL: tx_if.ready = 1'b0;
        BP_RANDOM_50:    tx_if.ready = $urandom_range(0, 1);
      endcase
      #1;
    end
  endtask

  task automatic stop();
    running = 1'b0;
    tx_if.ready = 1'b1;
  endtask

endclass

`default_nettype wire
