# Purpose: Stable synthesis alias for the typical clock and CDC timing model.
# Source mode: R750_delta5 typical-only clock/CDC repair.
# Signoff: not MMMC signoff, not final tapeout signoff.
# Related legacy file: mptdc_osc_typical_r750_delta5_o13_abs3.sdc.
# Author: Karim Sabra

set mptdc_stable_sdc_self [file normalize [info script]]
set mptdc_stable_sdc_dir [file dirname $mptdc_stable_sdc_self]
set mptdc_stable_sdc_legacy [file join $mptdc_stable_sdc_dir mptdc_osc_typical_r750_delta5_o13_abs3.sdc]
if {![file exists $mptdc_stable_sdc_legacy]} {
    error "MPTDC_STABLE_SDC_FATAL: missing related legacy file: $mptdc_stable_sdc_legacy"
}
source $mptdc_stable_sdc_legacy
