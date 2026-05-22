# =============================================================================
# Project  : SPADMIC ARB
# File     : arb.sdc
# Purpose  : Out-of-context timing constraints for spadmic_correlated_tx.
# =============================================================================

set ARB_CLK_PERIOD_NS       6.250
set ARB_CLK_UNCERTAINTY_NS  0.300
set ARB_IO_DELAY_NS         1.500
set ARB_INPUT_TRANSITION_NS 0.150
set ARB_OUTPUT_LOAD_PF      0.050

create_clock -name clk_sys -period $ARB_CLK_PERIOD_NS [get_ports clk_sys]
set_clock_uncertainty $ARB_CLK_UNCERTAINTY_NS [get_clocks clk_sys]
set_clock_transition  $ARB_INPUT_TRANSITION_NS [get_clocks clk_sys]

set ARB_RESET_PORTS [get_ports -quiet rst_n]
set ARB_INPUT_PORTS [remove_from_collection [all_inputs] [get_ports -quiet {clk_sys rst_n}]]
set ARB_OUTPUT_PORTS [all_outputs]

if {[sizeof_collection $ARB_INPUT_PORTS] > 0} {
    set_input_delay -clock [get_clocks clk_sys] -max $ARB_IO_DELAY_NS $ARB_INPUT_PORTS
    set_input_delay -clock [get_clocks clk_sys] -min 0.000 $ARB_INPUT_PORTS
    set_input_transition $ARB_INPUT_TRANSITION_NS $ARB_INPUT_PORTS
}

if {[sizeof_collection $ARB_OUTPUT_PORTS] > 0} {
    set_output_delay -clock [get_clocks clk_sys] -max $ARB_IO_DELAY_NS $ARB_OUTPUT_PORTS
    set_output_delay -clock [get_clocks clk_sys] -min 0.000 $ARB_OUTPUT_PORTS
    set_load $ARB_OUTPUT_LOAD_PF $ARB_OUTPUT_PORTS
}

if {[sizeof_collection $ARB_RESET_PORTS] > 0} {
    set_input_delay -clock [get_clocks clk_sys] -max 0.000 $ARB_RESET_PORTS
    set_input_delay -clock [get_clocks clk_sys] -min 0.000 $ARB_RESET_PORTS
    set_input_transition $ARB_INPUT_TRANSITION_NS $ARB_RESET_PORTS
    set_false_path -from $ARB_RESET_PORTS
}

set_max_fanout 16 [current_design]
set_max_transition 0.500 [current_design]
