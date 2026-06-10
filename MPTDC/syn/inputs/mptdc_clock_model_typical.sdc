# Purpose: Stable synthesis alias for the typical clock and CDC timing model.
# Source mode: R750_delta5 typical-only clock/CDC repair.
# Signoff: not MMMC signoff, not final tapeout signoff.
# Related legacy file: mptdc_osc_typical_r750_delta5_o13_abs3.sdc.
# Author: Karim Sabra

if {[info exists design(inputs_dir)] && [file isdirectory $design(inputs_dir)]} {
    set mptdc_stable_sdc_dir [file normalize $design(inputs_dir)]
} elseif {[info exists ::env(MPTDC_SYN_INPUTS_DIR)] && [file isdirectory $::env(MPTDC_SYN_INPUTS_DIR)]} {
    set mptdc_stable_sdc_dir [file normalize $::env(MPTDC_SYN_INPUTS_DIR)]
} else {
    set mptdc_stable_sdc_self [file normalize [info script]]
    set mptdc_stable_sdc_dir [file dirname $mptdc_stable_sdc_self]
}
set mptdc_stable_sdc_legacy [file join $mptdc_stable_sdc_dir mptdc_osc_typical_r750_delta5_o13_abs3.sdc]
if {![file exists $mptdc_stable_sdc_legacy]} {
    error "MPTDC_STABLE_SDC_FATAL: missing related legacy file: $mptdc_stable_sdc_legacy"
}
source $mptdc_stable_sdc_legacy
