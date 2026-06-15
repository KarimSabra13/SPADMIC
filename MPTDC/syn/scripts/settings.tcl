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
# Disabled by default: the checked-in XFAB HD liberty marks the integrated
# clock-gating cells as dont_use. O5 can enable this only as an explicit
# feasibility experiment after the server script records the ICG audit.
if {[info exists ::env(MPTDC_ENABLE_CLOCK_GATING)]} {
    set mptdc_enable_clock_gating [mptdc_bool_env MPTDC_ENABLE_CLOCK_GATING false]
} else {
    set mptdc_enable_clock_gating false
}
if {[info exists ::env(MPTDC_CLOCK_GATING_MIN_FLOPS)]} {
    set mptdc_clock_gating_min_flops $::env(MPTDC_CLOCK_GATING_MIN_FLOPS)
} else {
    set mptdc_clock_gating_min_flops 8
}
set mptdc_allow_icg_dont_use_override [mptdc_bool_env MPTDC_ALLOW_ICG_DONT_USE_OVERRIDE false]
set mptdc_allow_discrete_clock_gating [mptdc_bool_env MPTDC_ALLOW_DISCRETE_CLOCK_GATING false]
if {$mptdc_enable_clock_gating} {
    set clock_gating_note "clock gating enabled experimentally (min_flops=$mptdc_clock_gating_min_flops, icg_dont_use_override=$mptdc_allow_icg_dont_use_override, discrete=$mptdc_allow_discrete_clock_gating)"
} else {
    set clock_gating_note "clock gating disabled (library ICG cells are dont_use)"
}
set_db lp_insert_clock_gating $mptdc_enable_clock_gating

#############################################
#       Synthesis Effort
#############################################
# Signoff-oriented front-end runs: spend maximum effort on area/timing/power
# exploration before handoff to physical implementation. O4 adds an explicit
# fast-feasibility mode for architecture screening. It lowers optimization
# effort only; constraints, clocks, reports, and path classification are
# unchanged, so it must not be used as final closure evidence.
if {[info exists ::env(MPTDC_OPT_GOAL)]} {
    set mptdc_optimization_goal $::env(MPTDC_OPT_GOAL)
} else {
    set mptdc_optimization_goal "area_first"
}

if {[info exists ::env(GENUS_EFFORT)]} {
    set mptdc_genus_effort $::env(GENUS_EFFORT)
} else {
    set mptdc_genus_effort "closure"
}

switch -- $mptdc_genus_effort {
    fast {
        set mptdc_syn_generic_effort medium
        set mptdc_syn_map_effort     medium
        set mptdc_syn_opt_effort     medium
        set mptdc_design_power_effort low
        set mptdc_effort_note "FAST_FEASIBILITY effort"
    }
    closure {
        set mptdc_syn_generic_effort high
        set mptdc_syn_map_effort     high
        set mptdc_syn_opt_effort     extreme
        set mptdc_design_power_effort high
        set mptdc_effort_note "CLOSURE effort"
    }
    default {
        puts "MPTDC_SETTINGS_WARN: unsupported GENUS_EFFORT=$mptdc_genus_effort; using closure"
        set mptdc_genus_effort       "closure"
        set mptdc_syn_generic_effort high
        set mptdc_syn_map_effort     high
        set mptdc_syn_opt_effort     extreme
        set mptdc_design_power_effort high
        set mptdc_effort_note "CLOSURE effort"
    }
}

if {[info exists ::env(MPTDC_DESIGN_POWER_EFFORT)] && $::env(MPTDC_DESIGN_POWER_EFFORT) ne ""} {
    set mptdc_design_power_effort $::env(MPTDC_DESIGN_POWER_EFFORT)
    append mptdc_effort_note ", design_power_effort override=$mptdc_design_power_effort"
}

set_db syn_generic_effort  $mptdc_syn_generic_effort   ;# low|medium|high|express
set_db syn_map_effort      $mptdc_syn_map_effort       ;# low|medium|high
set_db syn_opt_effort      $mptdc_syn_opt_effort       ;# low|medium|high|extreme
set_db design_power_effort $mptdc_design_power_effort  ;# none|low|high

proc mptdc_settings_try_set_db {attr value} {
    if {[catch {set_db $attr $value} err]} {
        puts "MPTDC_SETTINGS_WARN: set_db $attr $value skipped: $err"
        return 0
    }
    puts "MPTDC_SETTINGS_INFO: set_db $attr $value"
    return 1
}

set mptdc_genus_area_recovery [mptdc_bool_env MPTDC_GENUS_AREA_RECOVERY true]
set mptdc_genus_power_opt [mptdc_bool_env MPTDC_GENUS_POWER_OPT true]
if {$mptdc_genus_area_recovery} {
    foreach attr {
        syn_map_area_recovery
        syn_opt_area_recovery
        optimize_merge_flops
        optimize_constant_0_flops
        optimize_constant_1_flops
    } {
        mptdc_settings_try_set_db $attr true
    }
}
if {$mptdc_genus_power_opt} {
    foreach pair {
        {leakage_power_effort high}
        {lp_power_analysis_effort high}
    } {
        mptdc_settings_try_set_db [lindex $pair 0] [lindex $pair 1]
    }
}

#############################################
#       Verbosity
#############################################
set_db information_level 7                ;# 1 (quiet) to 9 (verbose)

mptdc_message "Genus settings loaded ($mptdc_optimization_goal, $mptdc_effort_note, generic=$mptdc_syn_generic_effort map=$mptdc_syn_map_effort opt=$mptdc_syn_opt_effort power=$mptdc_design_power_effort, area_recovery=$mptdc_genus_area_recovery, power_opt=$mptdc_genus_power_opt, $ramstyle_note, $clock_gating_note)"
