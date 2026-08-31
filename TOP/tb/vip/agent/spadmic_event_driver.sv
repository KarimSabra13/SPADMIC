// =============================================================================
// SPADMIC VIP — Per-Axis Async Event Driver
// Injects SPAD events or CAL start/stop pairs onto the async interface.
// =============================================================================

class spadmic_event_driver;

  virtual spadmic_async_event_if ev_if[3];  // X, Y, Z

  function new(
    virtual spadmic_async_event_if x_if,
    virtual spadmic_async_event_if y_if,
    virtual spadmic_async_event_if z_if
  );
    ev_if[0] = x_if;
    ev_if[1] = y_if;
    ev_if[2] = z_if;
  endfunction

  // Normal matrix TDC mode is one coordinated R/Y/B event. All three public
  // directions must be present because the ABI requires axis mask 3'b111.
  task automatic inject_tdc_events(spadmic_tdc_event_txn t);
    int unsigned pulse_width_ps;
    pulse_width_ps = (t.start_stop_delay_ps < 100_000)
                     ? 100_000 : t.start_stop_delay_ps;
    for (int c = 0; c < t.num_conversions; c++) begin
      fork
        ev_if[0].inject_spad_event(pulse_width_ps);
        ev_if[1].inject_spad_event(pulse_width_ps);
        ev_if[2].inject_spad_event(pulse_width_ps);
      join
      if (c < t.num_conversions - 1)
        #(t.inter_conv_gap_ps);
    end
  endtask

  task automatic clear_all();
    for (int ax = 0; ax < 3; ax++)
      ev_if[ax].clear_all();
  endtask

endclass
