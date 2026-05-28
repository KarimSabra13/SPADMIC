# =============================================================================
# O1B oscillator/PD R800 timing overlay
# =============================================================================
# WHAT-IF ONLY - NOT CALIBRATION SAFE UNTIL ANALOG CONFIRMS TUNE TABLE.
#
# This overlay assumes mptdc_freq_modes.defines has already been sourced from
# mptdc.defines before the main SDC creates oscillator clocks.  It adds log
# visibility and review grouping only; it does not add broad false paths.
# =============================================================================

puts "MPTDC_O1B_R800_SDC_INFO: loading R800 oscillator/PD what-if overlay"
puts "MPTDC_O1B_R800_SDC_INFO: freq_mode=$design(FREQ_MODE)"
puts "MPTDC_O1B_R800_SDC_INFO: status=$design(FREQ_MODE_STATUS)"
puts "MPTDC_O1B_R800_SDC_INFO: calibration_safe=$design(FREQ_MODE_CALIBRATION_SAFE)"
puts "MPTDC_O1B_R800_SDC_INFO: slow_period_ns=$design(OSC_SLOW_PERIOD)"
puts "MPTDC_O1B_R800_SDC_INFO: fast_period_ns=$design(OSC_FAST_PERIOD)"
puts "MPTDC_O1B_R800_SDC_INFO: slow_tap_step_ns=$design(OSC_SLOW_TAP_STEP)"
puts "MPTDC_O1B_R800_SDC_INFO: fast_tap_step_ns=$design(OSC_FAST_TAP_STEP)"
puts "MPTDC_O1B_R800_SDC_INFO: tap_delta_ns=$design(OSC_TAP_DELTA_NS)"

if {$design(FREQ_MODE) eq "r800_period_delta_whatif"} {
    puts "MPTDC_O1B_R800_SDC_WARN: r800_period_delta_whatif is STA/PnR only; analog tune-code and calibration safety are unproven"
}

if {[expr {abs($design(OSC_TAP_DELTA_NS) - 0.005)}] > 0.0005} {
    puts "MPTDC_O1B_R800_SDC_WARN: tap delta differs from 0.005 ns; calibration-model review required"
}

puts "MPTDC_O1B_R800_SDC_INFO: no clk_sys backend timing exceptions added"
puts "MPTDC_O1B_R800_SDC_INFO: no intentional Vernier false paths added by this overlay"
