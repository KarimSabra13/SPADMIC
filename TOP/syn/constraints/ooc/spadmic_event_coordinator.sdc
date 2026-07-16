# OOC TC constraints for spadmic_event_coordinator.
# These values model a synchronous neighboring block at 160 MHz. They are a
# feasibility contract, not MMMC or interface signoff.

set EVENT_CLK_PERIOD_NS 6.25
set EVENT_INPUT_DELAY_NS 0.50
set EVENT_OUTPUT_DELAY_NS 0.50
set EVENT_INPUT_TRANSITION_NS 0.20
set EVENT_OUTPUT_LOAD_PF 0.02

set EVENT_CLK_PORTS [get_ports clk_sys -quiet]
if {[llength $EVENT_CLK_PORTS] > 0} {
  create_clock -name clk_sys -period $EVENT_CLK_PERIOD_NS $EVENT_CLK_PORTS
}
set EVENT_CLK [get_clocks clk_sys -quiet]

foreach port_pat {
  rst_n active_mode_i* global_enable_i active_axis_mask_i*
  matrix_activity_i cal_activity_i pre_event_resources_ready_i
  raw_snapshot_required_i auto_reset_enable_i snapshot_valid_i
  position_snapshot_captured_i tdc_start_seen_i* packet_pending_mask_i*
  reset_done_i bundle_done_i rearm_ready_i
} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    set_input_delay $EVENT_INPUT_DELAY_NS -clock $EVENT_CLK $ports
    set_input_transition $EVENT_INPUT_TRANSITION_NS $ports
  }
}

foreach port_pat {
  event_open_o event_id_o* event_id_valid_o required_packet_mask_o*
  required_tdc_mask_o* required_reset_ack_mask_o* observed_reset_ack_mask_o*
  reset_start_o bundle_start_o accept_enable_o rejected_not_ready_o busy_o idle_o
} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    set_output_delay $EVENT_OUTPUT_DELAY_NS -clock $EVENT_CLK $ports
    set_load $EVENT_OUTPUT_LOAD_PF $ports
  }
}

set_max_transition 1.5 [current_design]
set_max_fanout 32 [current_design]
