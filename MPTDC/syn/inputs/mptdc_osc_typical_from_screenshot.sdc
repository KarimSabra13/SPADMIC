# =============================================================================
# O7 typical-from-screenshot oscillator/PD overlay
# =============================================================================
# Source: manual extraction from Virtuoso screenshots labeled around
# SPADMIC_RO_tune3_sim2_maestro / RO_tune3_sim2.
#
# Digital macro binding remains RO_tune4.  RO_tune3/RO_tune4 equivalence is not
# confirmed.  This overlay is only for O7 typical Genus feasibility and must not
# be used for MMMC, PVT signoff, tapeout signoff, or final oscillator signoff.
#
# Period and tap step remain nominal because the screenshots do not justify a
# new period or exact threshold crossing phase model.
# =============================================================================

puts "MPTDC_O7_SDC_INFO: loading screenshot-derived typical feasibility overlay"
puts "MPTDC_O7_SDC_INFO: source is manual screenshot extraction, not CSV/Ocean export"
puts "MPTDC_O7_SDC_INFO: signoff status = PROVISIONAL_FROM_SCREENSHOT_NOT_FOR_SIGNOFF"
puts "MPTDC_O7_SDC_INFO: RO_tune3/RO_tune4 equivalence is not confirmed"

proc mptdc_o7_try_get_pins {patterns} {
    set pins [list]
    foreach pattern $patterns {
        set found [get_pins -quiet -hierarchical $pattern]
        if {[llength $found] > 0} {
            set pins [concat $pins $found]
        }
    }
    return $pins
}

set mptdc_o7_slow_period_typ_ns 1.000
set mptdc_o7_fast_period_typ_ns 0.900
set mptdc_o7_slow_tap_step_typ_ns 0.055
set mptdc_o7_fast_tap_step_typ_ns 0.050
set mptdc_o7_jitter_rms_ps 0.614
set mptdc_o7_setup_uncertainty_ns 0.010
set mptdc_o7_hold_uncertainty_ns 0.005
set mptdc_o7_startup_rstb_to_s5_ps 367.907

puts "MPTDC_O7_SDC_INFO: slow period ns = $design(OSC_SLOW_PERIOD)"
puts "MPTDC_O7_SDC_INFO: fast period ns = $design(OSC_FAST_PERIOD)"
puts "MPTDC_O7_SDC_INFO: slow tap step ns = $design(OSC_SLOW_TAP_STEP)"
puts "MPTDC_O7_SDC_INFO: fast tap step ns = $design(OSC_FAST_TAP_STEP)"
puts "MPTDC_O7_SDC_INFO: nominal slow period retained = $mptdc_o7_slow_period_typ_ns ns"
puts "MPTDC_O7_SDC_INFO: nominal fast period retained = $mptdc_o7_fast_period_typ_ns ns"
puts "MPTDC_O7_SDC_INFO: nominal slow tap step retained = $mptdc_o7_slow_tap_step_typ_ns ns"
puts "MPTDC_O7_SDC_INFO: nominal fast tap step retained = $mptdc_o7_fast_tap_step_typ_ns ns"
puts "MPTDC_O7_SDC_INFO: observed S<5> jitter RMS = $mptdc_o7_jitter_rms_ps ps"
puts "MPTDC_O7_SDC_INFO: guarded setup uncertainty = [expr {$mptdc_o7_setup_uncertainty_ns * 1000.0}] ps"
puts "MPTDC_O7_SDC_INFO: guarded hold uncertainty = [expr {$mptdc_o7_hold_uncertainty_ns * 1000.0}] ps"
puts "MPTDC_O7_SDC_INFO: observed rstb-to-S<5> startup marker = $mptdc_o7_startup_rstb_to_s5_ps ps"

foreach osc_clk $design(OSC_ALL_CLOCKS) {
    set_clock_uncertainty -setup $mptdc_o7_setup_uncertainty_ns [get_clocks $osc_clk]
    set_clock_uncertainty -hold  $mptdc_o7_hold_uncertainty_ns  [get_clocks $osc_clk]
}

set mptdc_o7_slow_pins [mptdc_o7_try_get_pins [list \
    {u_core/u_osc_slow/u_ro_tune4/S[0]} \
    {u_core/u_osc_slow/u_ro_tune4/S[1]} \
    {u_core/u_osc_slow/u_ro_tune4/S[2]} \
    {u_core/u_osc_slow/u_ro_tune4/S[3]} \
    {u_core/u_osc_slow/u_ro_tune4/S[4]} \
    {u_core/u_osc_slow/u_ro_tune4/S[5]} \
    {u_core/u_osc_slow/u_ro_tune4/S[6]} \
    {u_core/u_osc_slow/u_ro_tune4/S[7]} \
]]

set mptdc_o7_fast_pins [mptdc_o7_try_get_pins [list \
    {u_core/u_osc_fast/u_ro_tune4/S[0]} \
    {u_core/u_osc_fast/u_ro_tune4/S[1]} \
    {u_core/u_osc_fast/u_ro_tune4/S[2]} \
    {u_core/u_osc_fast/u_ro_tune4/S[3]} \
    {u_core/u_osc_fast/u_ro_tune4/S[4]} \
    {u_core/u_osc_fast/u_ro_tune4/S[5]} \
    {u_core/u_osc_fast/u_ro_tune4/S[6]} \
    {u_core/u_osc_fast/u_ro_tune4/S[7]} \
]]

puts "MPTDC_O7_SDC_INFO: matched slow RO_tune4 S pins = [llength $mptdc_o7_slow_pins]"
puts "MPTDC_O7_SDC_INFO: matched fast RO_tune4 S pins = [llength $mptdc_o7_fast_pins]"
if {[llength $mptdc_o7_slow_pins] != 8 || [llength $mptdc_o7_fast_pins] != 8} {
    puts "MPTDC_O7_SDC_WARN: expected 8 slow and 8 fast RO_tune4 S pins"
}

puts "MPTDC_O7_SDC_INFO: no precise clock transition is set from screenshot cursor slopes"
puts "MPTDC_O7_SDC_INFO: no O7 broad oscillator-domain false paths added"
