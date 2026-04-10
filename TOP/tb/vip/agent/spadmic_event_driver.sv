// =============================================================================
// SPADMIC VIP — Per-Axis Async Event Driver
// Injects SPAD events or CAL start/stop pairs onto the async interface.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_event_driver;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

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

  // Inject a complete TDC event sequence on the specified axis
  task automatic inject_tdc_events(spadmic_tdc_event_txn t);
    for (int c = 0; c < t.num_conversions; c++) begin
      if (t.use_spad) begin
        ev_if[t.axis].inject_spad_event(t.start_stop_delay_ps);
      end else begin
        ev_if[t.axis].inject_cal_pair(
          t.cal_start_width_ps,
          t.start_stop_delay_ps,
          t.cal_stop_width_ps
        );
      end
      if (c < t.num_conversions - 1)
        #(t.inter_conv_gap_ps);
    end
  endtask

endclass

`default_nettype wire
