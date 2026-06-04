# =============================================================================
# O9 R750/R700 delta-preserving typical oscillator/PD overlay
# =============================================================================
# Source: O9 practical frequency target derived from O8 typical closure need.
# Analog status: candidate only.  The underlying RO data is still provisional
# screenshot-derived typical information, not CSV/Ocean signoff data.
#
# This file must be used only in TC-only feasibility/characterization-candidate
# synthesis.  It is not an MMMC, PVT, tapeout, or final oscillator signoff view.
# =============================================================================

puts "MPTDC_O9_R750_SDC_INFO: loading O9_R750_DELTA5 typical candidate overlay"
puts "MPTDC_O9_R750_SDC_INFO: signoff status = PROVISIONAL_TYPICAL_NOT_FOR_SIGNOFF"
puts "MPTDC_O9_R750_SDC_INFO: expected RTL define = +define+MPTDC_FREQ_R750_DELTA5"

proc mptdc_o9_try_get_pins {patterns} {
    set pins [list]
    foreach pattern $patterns {
        set found [get_pins -quiet -hierarchical $pattern]
        if {[llength $found] > 0} {
            set pins [concat $pins $found]
        }
    }
    return $pins
}

set mptdc_o9_fast_period_typ_ns 1.333
set mptdc_o9_slow_period_typ_ns 1.430
set mptdc_o9_fast_tap_step_typ_ns 0.074
set mptdc_o9_slow_tap_step_typ_ns 0.079
set mptdc_o9_delta_step_typ_ns 0.005
set mptdc_o9_jitter_rms_ps 0.614
set mptdc_o9_setup_uncertainty_ns 0.010
set mptdc_o9_hold_uncertainty_ns 0.005
set mptdc_o9_startup_rstb_to_s5_ps 367.907

puts "MPTDC_O9_R750_SDC_INFO: design slow period ns = $design(OSC_SLOW_PERIOD)"
puts "MPTDC_O9_R750_SDC_INFO: design fast period ns = $design(OSC_FAST_PERIOD)"
puts "MPTDC_O9_R750_SDC_INFO: design slow tap step ns = $design(OSC_SLOW_TAP_STEP)"
puts "MPTDC_O9_R750_SDC_INFO: design fast tap step ns = $design(OSC_FAST_TAP_STEP)"
puts "MPTDC_O9_R750_SDC_INFO: target slow period ns = $mptdc_o9_slow_period_typ_ns"
puts "MPTDC_O9_R750_SDC_INFO: target fast period ns = $mptdc_o9_fast_period_typ_ns"
puts "MPTDC_O9_R750_SDC_INFO: target slow tap step ns = $mptdc_o9_slow_tap_step_typ_ns"
puts "MPTDC_O9_R750_SDC_INFO: target fast tap step ns = $mptdc_o9_fast_tap_step_typ_ns"
puts "MPTDC_O9_R750_SDC_INFO: target tap delta ns = $mptdc_o9_delta_step_typ_ns"
puts "MPTDC_O9_R750_SDC_INFO: observed S<5> jitter RMS = $mptdc_o9_jitter_rms_ps ps"
puts "MPTDC_O9_R750_SDC_INFO: guarded setup uncertainty = [expr {$mptdc_o9_setup_uncertainty_ns * 1000.0}] ps"
puts "MPTDC_O9_R750_SDC_INFO: guarded hold uncertainty = [expr {$mptdc_o9_hold_uncertainty_ns * 1000.0}] ps"
puts "MPTDC_O9_R750_SDC_INFO: observed rstb-to-S<5> startup marker = $mptdc_o9_startup_rstb_to_s5_ps ps"

foreach {actual expected label} [list \
    $design(OSC_SLOW_PERIOD) $mptdc_o9_slow_period_typ_ns slow_period \
    $design(OSC_FAST_PERIOD) $mptdc_o9_fast_period_typ_ns fast_period \
    $design(OSC_SLOW_TAP_STEP) $mptdc_o9_slow_tap_step_typ_ns slow_tap_step \
    $design(OSC_FAST_TAP_STEP) $mptdc_o9_fast_tap_step_typ_ns fast_tap_step \
] {
    if {[expr {abs($actual - $expected)}] > 0.0005} {
        puts "MPTDC_O9_R750_SDC_WARN: $label actual=$actual expected=$expected"
    }
}

foreach osc_clk $design(OSC_ALL_CLOCKS) {
    set_clock_uncertainty -setup $mptdc_o9_setup_uncertainty_ns [get_clocks $osc_clk]
    set_clock_uncertainty -hold  $mptdc_o9_hold_uncertainty_ns  [get_clocks $osc_clk]
}

set mptdc_o9_slow_pins [mptdc_o9_try_get_pins [list \
    {u_core/u_osc_slow/u_ro_tune4/S[0]} \
    {u_core/u_osc_slow/u_ro_tune4/S[1]} \
    {u_core/u_osc_slow/u_ro_tune4/S[2]} \
    {u_core/u_osc_slow/u_ro_tune4/S[3]} \
    {u_core/u_osc_slow/u_ro_tune4/S[4]} \
    {u_core/u_osc_slow/u_ro_tune4/S[5]} \
    {u_core/u_osc_slow/u_ro_tune4/S[6]} \
    {u_core/u_osc_slow/u_ro_tune4/S[7]} \
]]

set mptdc_o9_fast_pins [mptdc_o9_try_get_pins [list \
    {u_core/u_osc_fast/u_ro_tune4/S[0]} \
    {u_core/u_osc_fast/u_ro_tune4/S[1]} \
    {u_core/u_osc_fast/u_ro_tune4/S[2]} \
    {u_core/u_osc_fast/u_ro_tune4/S[3]} \
    {u_core/u_osc_fast/u_ro_tune4/S[4]} \
    {u_core/u_osc_fast/u_ro_tune4/S[5]} \
    {u_core/u_osc_fast/u_ro_tune4/S[6]} \
    {u_core/u_osc_fast/u_ro_tune4/S[7]} \
]]

puts "MPTDC_O9_R750_SDC_INFO: matched slow RO_tune4 S pins = [llength $mptdc_o9_slow_pins]"
puts "MPTDC_O9_R750_SDC_INFO: matched fast RO_tune4 S pins = [llength $mptdc_o9_fast_pins]"
if {[llength $mptdc_o9_slow_pins] != 8 || [llength $mptdc_o9_fast_pins] != 8} {
    puts "MPTDC_O9_R750_SDC_WARN: expected 8 slow and 8 fast RO_tune4 S pins"
}

puts "MPTDC_O9_R750_SDC_INFO: no precise clock transition is set from screenshot cursor slopes"
puts "MPTDC_O9_R750_SDC_INFO: no broad oscillator-domain false paths added"
