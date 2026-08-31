// =============================================================================
// SPADMIC VIP — SPAD Matrix Reset Monitor
// Captures active-high reset pulses and checks pulse-width quality.
// =============================================================================

class spadmic_spad_reset_monitor;

  virtual spadmic_spad_reset_if reset_if;
  mailbox #(spadmic_base_txn)    sb_mb;

  int unsigned total_pulses;
  int unsigned width_errors;
  bit          running;

  function new(
    virtual spadmic_spad_reset_if reset_if,
    mailbox #(spadmic_base_txn)    sb_mb
  );
    this.reset_if     = reset_if;
    this.sb_mb        = sb_mb;
    this.total_pulses = 0;
    this.width_errors = 0;
    this.running      = 1'b0;
  endfunction

  task automatic run();
    bit last_rst;
    running  = 1'b1;
    last_rst = 1'b0;

    forever begin
      @(posedge reset_if.clk_sys);
      if (!reset_if.rst_n) begin
        last_rst = 1'b0;
        continue;
      end

      if (reset_if.spad_matrix_rst && !last_rst)
        capture_pulse();

      last_rst = reset_if.spad_matrix_rst;
    end
  endtask

  task automatic capture_pulse();
    spadmic_spad_reset_txn txn;
    int unsigned width;
    int unsigned expected_width;
    longint unsigned start_time;

    start_time = $time;
    expected_width = reset_if.expected_width_cycles;
    width = 0;
    do begin
      width++;
      @(posedge reset_if.clk_sys);
    end while (reset_if.rst_n && reset_if.spad_matrix_rst);

    total_pulses++;
    if ((expected_width == 0) || (width != expected_width)) begin
      width_errors++;
      $display("[SPAD_RST_MON] FAIL: reset pulse width=%0d expected=%0d cycles",
               width, expected_width);
    end else begin
      $display("[SPAD_RST_MON] Pulse #%0d width=%0d cycles @%0t",
               total_pulses, width, start_time);
    end

    txn = new();
    txn.pulse_width_cycles = width;
    txn.expected_width_cycles = expected_width;
    txn.start_time_ps      = start_time;
    txn.end_time_ps        = $time;
    sb_mb.put(txn);
  endtask

  function void report();
    $display("[SPAD_RST_MON] pulses=%0d width_errors=%0d", total_pulses, width_errors);
  endfunction

endclass
