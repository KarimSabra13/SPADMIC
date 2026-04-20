// =============================================================================
// SPADMIC VIP — Backpressure Driver
// Legacy backpressure driver retained so older VIP flows still compile.
// The silicon-facing TX boundary is now source-synchronous and ignores ready.
// =============================================================================

class spadmic_bp_driver;

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
      tx_if.ready = 1'b1;
      #1;
    end
  endtask

  task automatic stop();
    running = 1'b0;
    tx_if.ready = 1'b1;
  endtask

endclass
