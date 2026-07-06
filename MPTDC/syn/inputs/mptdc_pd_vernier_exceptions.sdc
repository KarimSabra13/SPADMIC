# Purpose: Stable synthesis alias for the intentional PD Vernier exception.
# Source mode: R750_delta5 typical-only with count-checked slow-to-fast sampler exception.
# Signoff: not MMMC signoff, not final tapeout signoff.
# Read-SDC scope: clock/CDC only.  The exact ABS5 slow-phase to q1 sampler
# exception is applied after mapping by procedures.tcl, where q1 endpoints are
# real pin objects and can be counted exactly.
# Related legacy file: mptdc_osc_typical_r750_delta5_o13_abs5.sdc.
# Author: Karim Sabra

if {[info exists design(inputs_dir)] && [file isdirectory $design(inputs_dir)]} {
    set mptdc_stable_sdc_dir [file normalize $design(inputs_dir)]
} elseif {[info exists ::env(MPTDC_SYN_INPUTS_DIR)] && [file isdirectory $::env(MPTDC_SYN_INPUTS_DIR)]} {
    set mptdc_stable_sdc_dir [file normalize $::env(MPTDC_SYN_INPUTS_DIR)]
} else {
    set mptdc_stable_sdc_self [file normalize [info script]]
    set mptdc_stable_sdc_dir [file dirname $mptdc_stable_sdc_self]
}
set mptdc_stable_sdc_read_overlay [file join $mptdc_stable_sdc_dir mptdc_osc_typical_r750_delta5_o13_abs3.sdc]
if {![file exists $mptdc_stable_sdc_read_overlay]} {
    error "MPTDC_STABLE_SDC_FATAL: missing read-SDC overlay: $mptdc_stable_sdc_read_overlay"
}
source $mptdc_stable_sdc_read_overlay
puts "MPTDC_STABLE_SDC_INFO: ABS5 exact PD Vernier exception deferred to mapped post-synthesis Tcl hook"
