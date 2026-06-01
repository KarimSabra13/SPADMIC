# =============================================================================
# O1C RO_tune4 macro-binding oscillator/PD overlay
# =============================================================================
# REAL PHYSICAL LEF AVAILABLE, LIBERTY SHELL ONLY.
#
# This overlay is loaded after mptdc.sdc for the Genus O1C macro-binding run.
# The primary oscillator tap clocks should already have been created by
# mptdc.sdc using the O1C pin names from mptdc.defines:
#   u_core/u_osc_slow/u_ro_tune4/S[0:7]
#   u_core/u_osc_fast/u_ro_tune4/S[0:7]
#
# This file does not hide clk_sys timing and does not false-path the real
# fast-counter to nfast_hit paths.  It only adds O1C-specific checks/report
# grouping.  Genus 22.13 SDC mode rejects net-level set_max_transition and
# set_max_capacitance on the RO_tune4 phase nets, so phase electrical bounds are
# reported in O1C and enforced later in Innovus once the timing model is clean.
# =============================================================================

proc mptdc_o1c_try_get_pins {patterns} {
    set pins [list]
    foreach pattern $patterns {
        set found [get_pins -quiet -hierarchical $pattern]
        if {[llength $found] > 0} {
            set pins [concat $pins $found]
        }
    }
    return $pins
}

proc mptdc_o1c_try_get_nets {patterns} {
    set nets [list]
    foreach pattern $patterns {
        set found [get_nets -quiet -hierarchical $pattern]
        if {[llength $found] > 0} {
            set nets [concat $nets $found]
        }
    }
    return $nets
}

proc mptdc_o1c_get_nets_of_pins {pins} {
    set nets [list]
    foreach pin $pins {
        if {![catch {set found [get_nets -quiet -of_objects $pin]}] && [llength $found] > 0} {
            set nets [concat $nets $found]
        }
    }
    return $nets
}

proc mptdc_o1c_try {label body} {
    if {[catch {uplevel 1 $body} err]} {
        puts "MPTDC_O1C_SDC_WARN: $label failed: $err"
    } else {
        puts "MPTDC_O1C_SDC_INFO: $label"
    }
}

puts "MPTDC_O1C_SDC_INFO: loading RO_tune4 macro-binding overlay"
puts "MPTDC_O1C_SDC_INFO: slow period ns = $design(OSC_SLOW_PERIOD)"
puts "MPTDC_O1C_SDC_INFO: fast period ns = $design(OSC_FAST_PERIOD)"
puts "MPTDC_O1C_SDC_INFO: slow tap step ns = $design(OSC_SLOW_TAP_STEP)"
puts "MPTDC_O1C_SDC_INFO: fast tap step ns = $design(OSC_FAST_TAP_STEP)"

set mptdc_o1c_slow_pins [mptdc_o1c_try_get_pins [list \
    {u_core/u_osc_slow/u_ro_tune4/S[0]} \
    {u_core/u_osc_slow/u_ro_tune4/S[1]} \
    {u_core/u_osc_slow/u_ro_tune4/S[2]} \
    {u_core/u_osc_slow/u_ro_tune4/S[3]} \
    {u_core/u_osc_slow/u_ro_tune4/S[4]} \
    {u_core/u_osc_slow/u_ro_tune4/S[5]} \
    {u_core/u_osc_slow/u_ro_tune4/S[6]} \
    {u_core/u_osc_slow/u_ro_tune4/S[7]} \
]]

set mptdc_o1c_fast_pins [mptdc_o1c_try_get_pins [list \
    {u_core/u_osc_fast/u_ro_tune4/S[0]} \
    {u_core/u_osc_fast/u_ro_tune4/S[1]} \
    {u_core/u_osc_fast/u_ro_tune4/S[2]} \
    {u_core/u_osc_fast/u_ro_tune4/S[3]} \
    {u_core/u_osc_fast/u_ro_tune4/S[4]} \
    {u_core/u_osc_fast/u_ro_tune4/S[5]} \
    {u_core/u_osc_fast/u_ro_tune4/S[6]} \
    {u_core/u_osc_fast/u_ro_tune4/S[7]} \
]]

puts "MPTDC_O1C_SDC_INFO: matched slow RO_tune4 S pins = [llength $mptdc_o1c_slow_pins]"
puts "MPTDC_O1C_SDC_INFO: matched fast RO_tune4 S pins = [llength $mptdc_o1c_fast_pins]"
if {[llength $mptdc_o1c_slow_pins] != 8 || [llength $mptdc_o1c_fast_pins] != 8} {
    puts "MPTDC_O1C_SDC_WARN: expected 8 slow and 8 fast RO_tune4 S pins"
}

set mptdc_o1c_phase_net_patterns [list]
for {set i 0} {$i < 8} {incr i} {
    lappend mptdc_o1c_phase_net_patterns [format {*slow_phase[%d]*} $i]
    lappend mptdc_o1c_phase_net_patterns [format {*fast_phase[%d]*} $i]
    lappend mptdc_o1c_phase_net_patterns [format {*u_osc_slow*u_ro_tune4*S[%d]*} $i]
    lappend mptdc_o1c_phase_net_patterns [format {*u_osc_fast*u_ro_tune4*S[%d]*} $i]
}
set mptdc_o1c_phase_nets [mptdc_o1c_get_nets_of_pins [concat $mptdc_o1c_slow_pins $mptdc_o1c_fast_pins]]
if {[llength $mptdc_o1c_phase_nets] == 0} {
    set mptdc_o1c_phase_nets [mptdc_o1c_try_get_nets $mptdc_o1c_phase_net_patterns]
}
if {[llength $mptdc_o1c_phase_nets] > 0} {
    puts "MPTDC_O1C_SDC_INFO: RO_tune4 phase nets matched for report-only review = [llength $mptdc_o1c_phase_nets]"
    puts "MPTDC_O1C_SDC_INFO: phase max transition/cap are not applied in Genus SDC mode"
} else {
    puts "MPTDC_O1C_SDC_WARN: no RO_tune4 phase nets matched for physical bounds"
}

set mptdc_o1c_pd_cells [get_cells -quiet -hierarchical *gen_pd_row*gen_pd_col*u_pd*]
set mptdc_o1c_fast_cells [get_cells -quiet -hierarchical *u_fast_cnt*]
set mptdc_o1c_slow_cells [get_cells -quiet -hierarchical *u_slow_cnt*]
set mptdc_o1c_bridge_cells [get_cells -quiet -hierarchical *u_hit_capture_bridge*]

puts "MPTDC_O1C_SDC_INFO: matched PD cells for review = [llength $mptdc_o1c_pd_cells]"
puts "MPTDC_O1C_SDC_INFO: matched fast counter cells for review = [llength $mptdc_o1c_fast_cells]"
puts "MPTDC_O1C_SDC_INFO: matched slow counter cells for review = [llength $mptdc_o1c_slow_cells]"
puts "MPTDC_O1C_SDC_INFO: matched hit-capture bridge cells for review = [llength $mptdc_o1c_bridge_cells]"
puts "MPTDC_O1C_SDC_INFO: no O1C group_path commands added; report grouping is handled by Genus report scripts"

puts "MPTDC_O1C_SDC_INFO: no clk_sys backend exceptions added"
puts "MPTDC_O1C_SDC_INFO: fast counter -> nfast_hit remains visible for timing classification"
