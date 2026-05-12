# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : settings.tcl
# Purpose  : General Genus synthesis settings
# Author   : Karim Sabra
# =============================================================================
# This file contains tool-level configuration that is NOT design-specific.
# Design-specific settings belong in inputs/mptdc.defines.
# =============================================================================

#############################################
#       Genus HDL Settings
#############################################
set_db source_verbose true                ;# Report sourced files in log

# SystemVerilog support
set_db hdl_language sv                    ;# Default language: SystemVerilog

# Latch handling — allow intentional latches (async frontend)
set_db hdl_error_on_latch false

# Undriven signals default to 0 (safe for synthesis)
set_db hdl_undriven_signal_value 0

# Detailed SDC parsing messages (helps debug constraint issues)
set_db detailed_sdc_messages true

#############################################
#       Memory Inference
#############################################
# Force ALL memories to flip-flop implementation.
# No SRAM IP is available for this design — the sync FIFO
# (57-bit × 64-entry) will be implemented entirely as registers.
set ramstyle_mode "default"
if {[catch {set_db syn_ramstyle registers} ramstyle_err]} {
    set ramstyle_note \
        "Genus build does not support root attribute syn_ramstyle; continuing without it"
} else {
    set ramstyle_mode "registers"
    set ramstyle_note "syn_ramstyle=registers"
}

#############################################
#       Clock Gating
#############################################
# Disabled for initial bring-up: the checked-in XFAB HD liberty marks the
# integrated clock-gating cells as dont_use, so automatic insertion is not
# reliable yet on the current lab-server setup.
set mptdc_enable_clock_gating false
set clock_gating_note "clock gating disabled (library ICG cells are dont_use)"
set_db lp_insert_clock_gating $mptdc_enable_clock_gating

#############################################
#       Synthesis Effort
#############################################
# Signoff-oriented front-end runs: spend maximum effort on area/timing/power
# exploration before handoff to physical implementation. Override the label
# with MPTDC_OPT_GOAL if a future run intentionally trades area for timing.
if {[info exists ::env(MPTDC_OPT_GOAL)]} {
    set mptdc_optimization_goal $::env(MPTDC_OPT_GOAL)
} else {
    set mptdc_optimization_goal "area_first"
}

set_db syn_generic_effort  high           ;# low|medium|high|express
set_db syn_map_effort      high           ;# low|medium|high
set_db syn_opt_effort      extreme        ;# low|medium|high|extreme
set_db design_power_effort high           ;# none|low|high

#############################################
#       Verbosity
#############################################
set_db information_level 7                ;# 1 (quiet) to 9 (verbose)

mptdc_message "Genus settings loaded ($mptdc_optimization_goal, high/extreme effort, $ramstyle_note, $clock_gating_note)"
