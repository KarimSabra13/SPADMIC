# =============================================================================
# Project  : SPADMIC Position Block
# File     : spadmic_position.sdc
# Purpose  : OOC constraints for spadmic_position_block Genus synthesis.
# =============================================================================
#
# Physical context:
#   The x/y/z position lines originate around the SPAD matrix boundaries and can
#   traverse roughly 3.5 mm before reaching the top-right position block.  Model
#   the degraded RC environment with a deliberately pessimistic async input slew,
#   but false-path the asynchronous launch relationship into the ff1 line
#   synchronizers.
# =============================================================================

proc position_collect_sync_stage1_pins {} {
    set pins [list]
    foreach pattern [list \
        *x_sync_ff1_q*/D \
        *y_sync_ff1_q*/D \
        *z_sync_ff1_q*/D \
        *x_sync_ff1_q_reg*/D \
        *y_sync_ff1_q_reg*/D \
        *z_sync_ff1_q_reg*/D \
    ] {
        set matches [get_pins -quiet -hierarchical $pattern]
        if {[llength $matches] > 0} {
            set pins [concat $pins $matches]
        }
    }
    return $pins
}

set POS_CLK_SYS_PERIOD_NS              6.250
set POS_CLK_UNCERTAINTY_NS             0.300
set POS_CLK_TRANSITION_NS              0.150

set POS_SYNC_INPUT_DELAY_NS            0.750
set POS_SYNC_INPUT_TRANSITION_NS       0.200

set POS_ASYNC_LINE_INPUT_DELAY_NS      2.000
set POS_ASYNC_LINE_INPUT_TRANSITION_NS 2.000

set POS_OUTPUT_DELAY_NS                1.000
set POS_TX_OUTPUT_LOAD_PF              0.075
set POS_STATUS_OUTPUT_LOAD_PF          0.025

create_clock -name clk_sys -period $POS_CLK_SYS_PERIOD_NS [get_ports clk_sys]
set_clock_uncertainty $POS_CLK_UNCERTAINTY_NS [get_clocks clk_sys]
set_clock_transition  $POS_CLK_TRANSITION_NS  [get_clocks clk_sys]

# Async reset is false-pathed below, but give Genus a nominal OOC slew/delay so
# timing-intent checks do not treat the port as an ideal zero-transition input.
set POS_RESET_INPUT [get_ports -quiet rst_n]
if {[llength $POS_RESET_INPUT] > 0} {
    set_input_delay -clock [get_clocks clk_sys] -max 0.000 $POS_RESET_INPUT
    set_input_delay -clock [get_clocks clk_sys] -min 0.000 $POS_RESET_INPUT
    set_input_transition $POS_SYNC_INPUT_TRANSITION_NS $POS_RESET_INPUT
}

set POS_ASYNC_LINE_INPUTS [get_ports -quiet {
    x_lines_i[*]
    y_lines_i[*]
    z_lines_i[*]
}]

set POS_SYNC_INPUTS [get_ports -quiet {
    global_enable_i
    csr_valid_i
    csr_write_i
    csr_addr_i[*]
    csr_wdata_i[*]
    pos_ready_i
}]

set POS_TX_OUTPUTS [get_ports -quiet {
    pos_valid_o
    pos_data_o[*]
}]

set POS_STATUS_OUTPUTS [get_ports -quiet {
    csr_ready_o
    csr_rvalid_o
    csr_rdata_o[*]
    busy_o
    packet_pending_o
    drop_sticky_o
    glitch_reject_sticky_o
    spad_matrix_rst_o
}]

# Synchronous OOC interface budgets for CSR, enable, ready, and status/control
# outputs that remain local to the top-level digital island.
if {[llength $POS_SYNC_INPUTS] > 0} {
    set_input_delay -clock [get_clocks clk_sys] -max $POS_SYNC_INPUT_DELAY_NS $POS_SYNC_INPUTS
    set_input_delay -clock [get_clocks clk_sys] -min 0.000 $POS_SYNC_INPUTS
    set_input_transition $POS_SYNC_INPUT_TRANSITION_NS $POS_SYNC_INPUTS
}

if {[llength $POS_TX_OUTPUTS] > 0} {
    set_output_delay -clock [get_clocks clk_sys] -max $POS_OUTPUT_DELAY_NS $POS_TX_OUTPUTS
    set_output_delay -clock [get_clocks clk_sys] -min 0.000 $POS_TX_OUTPUTS
    set_load $POS_TX_OUTPUT_LOAD_PF $POS_TX_OUTPUTS
}

if {[llength $POS_STATUS_OUTPUTS] > 0} {
    set_output_delay -clock [get_clocks clk_sys] -max $POS_OUTPUT_DELAY_NS $POS_STATUS_OUTPUTS
    set_output_delay -clock [get_clocks clk_sys] -min 0.000 $POS_STATUS_OUTPUTS
    set_load $POS_STATUS_OUTPUT_LOAD_PF $POS_STATUS_OUTPUTS
}

# Asynchronous 3.5 mm matrix-line contract.  Keep the heavy transition visible at
# the block boundary for receiver sizing/DRV analysis, then cut setup/hold timing
# because the ff1/ff2/ff3 line chain and settle filter own CDC correctness.
if {[llength $POS_ASYNC_LINE_INPUTS] > 0} {
    set_input_delay -clock [get_clocks clk_sys] -max $POS_ASYNC_LINE_INPUT_DELAY_NS $POS_ASYNC_LINE_INPUTS
    set_input_delay -clock [get_clocks clk_sys] -min 0.000 $POS_ASYNC_LINE_INPUTS
    set_input_transition $POS_ASYNC_LINE_INPUT_TRANSITION_NS $POS_ASYNC_LINE_INPUTS

    set POS_SYNC_STAGE1_PINS [position_collect_sync_stage1_pins]
    if {[llength $POS_SYNC_STAGE1_PINS] > 0} {
        set_false_path -from $POS_ASYNC_LINE_INPUTS -to $POS_SYNC_STAGE1_PINS
    } else {
        set_false_path -from $POS_ASYNC_LINE_INPUTS
    }
}

if {[llength $POS_RESET_INPUT] > 0} {
    set_false_path -from $POS_RESET_INPUT
}

# Preserve explicit line synchronizers. These best-effort SDC guards make the
# intent visible in Genus logs/reports even though ASYNC_REG-style FPGA
# attributes are intentionally not used in this ASIC flow.
foreach pattern {
    *x_sync_ff1_q* *x_sync_ff2_q*
    *y_sync_ff1_q* *y_sync_ff2_q*
    *z_sync_ff1_q* *z_sync_ff2_q*
} {
    set sync_cells [get_cells -quiet -hierarchical $pattern]
    if {[llength $sync_cells] > 0} {
        catch {set_dont_touch $sync_cells true}
        catch {set_db $sync_cells .preserve true}
    }
}

set_max_fanout 20 [current_design]
set_max_transition 2.000 [current_design]
