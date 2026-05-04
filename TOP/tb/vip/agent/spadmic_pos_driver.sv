// =============================================================================
// SPADMIC VIP — Position Stimulus Driver
// Drives position line patterns onto the position interface.
// =============================================================================

class spadmic_pos_driver;

  virtual spadmic_position_line_if pos_if;

  function new(virtual spadmic_position_line_if pos_if);
    this.pos_if = pos_if;
  endfunction

  task automatic drive_position_event(spadmic_pos_event_txn t);
    // Optional glitch injection before stable pattern
    if (t.inject_glitch) begin
      pos_if.inject_glitch(t.glitch_axis, t.glitch_bit, t.glitch_duration_ps);
      #(10000);  // small gap after glitch
    end

    // Drive the stable pattern
    pos_if.set_all(t.x_pattern, t.y_pattern, t.z_pattern);

    // Hold for specified duration
    #(64'd1000 * t.hold_time_ns);  // convert ns to ps

    // Clear lines
    pos_if.clear_all();
  endtask

  task automatic clear_all();
    pos_if.clear_all();
  endtask

endclass
