// =============================================================================
// SPADMIC VIP — Per-Axis Asynchronous Event Interface
// Carries SPAD event and CAL start/stop pulses for one TDC axis.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface spadmic_async_event_if;

  logic spad_event_async;
  logic cal_start_async;
  logic cal_stop_async;

  // ── BFM tasks ─────────────────────────────────────────────────

  // Inject a SPAD event pulse of given width
  task automatic inject_spad_event(input int unsigned pulse_width_ps);
    spad_event_async = 1'b1;
    #(pulse_width_ps);
    spad_event_async = 1'b0;
  endtask

  // Inject a calibration START/STOP pair with given delay
  task automatic inject_cal_pair(
    input int unsigned start_width_ps,
    input int unsigned delay_ps,
    input int unsigned stop_width_ps
  );
    cal_start_async = 1'b1;
    #(start_width_ps);
    cal_start_async = 1'b0;
    #(delay_ps);
    cal_stop_async = 1'b1;
    #(stop_width_ps);
    cal_stop_async = 1'b0;
  endtask

  // Inject only a START pulse (for watchdog timeout testing)
  task automatic inject_cal_start_only(input int unsigned pulse_width_ps);
    cal_start_async = 1'b1;
    #(pulse_width_ps);
    cal_start_async = 1'b0;
  endtask

  task automatic clear_all();
    spad_event_async = 1'b0;
    cal_start_async  = 1'b0;
    cal_stop_async   = 1'b0;
  endtask

  // ── Initial state ─────────────────────────────────────────────
  initial begin
    clear_all();
  end

endinterface

`default_nettype wire
