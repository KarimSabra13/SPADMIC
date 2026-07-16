# OOC TC constraints for spadmic_position_core.
# The snapshot buses are captured synchronously from the protected matrix
# snapshot frontend. This is a typical-corner feasibility contract.

set POSITION_CLK_PERIOD_NS 6.25
set POSITION_INPUT_DELAY_NS 0.50
set POSITION_OUTPUT_DELAY_NS 0.50
set POSITION_INPUT_TRANSITION_NS 0.20
set POSITION_OUTPUT_LOAD_PF 0.02

set POSITION_CLK_PORTS [get_ports clk_sys -quiet]
if {[llength $POSITION_CLK_PORTS] > 0} {
  create_clock -name clk_sys -period $POSITION_CLK_PERIOD_NS $POSITION_CLK_PORTS
}
set POSITION_CLK [get_clocks clk_sys -quiet]

foreach port_pat {
  rst_n start_i mode_i* event_id_i* snapshot_R_i* snapshot_Y_i* snapshot_B_i*
  gap_threshold_i* min_cluster_span_i* pkt_ready_i
} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    set_input_delay $POSITION_INPUT_DELAY_NS -clock $POSITION_CLK $ports
    set_input_transition $POSITION_INPUT_TRANSITION_NS $ports
  }
}

foreach port_pat {
  pkt_valid_o pkt_data_o* pkt_sop_o pkt_eop_o packet_pending_o busy_o
  snapshot_captured_o done_o drop_o
} {
  set ports [get_ports $port_pat -quiet]
  if {[llength $ports] > 0} {
    set_output_delay $POSITION_OUTPUT_DELAY_NS -clock $POSITION_CLK $ports
    set_load $POSITION_OUTPUT_LOAD_PF $ports
  }
}

set_max_transition 1.5 [current_design]
set_max_fanout 32 [current_design]
