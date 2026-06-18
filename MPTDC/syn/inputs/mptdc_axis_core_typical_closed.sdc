# =============================================================================
# MPTDC axis-core typical-closed SDC entrypoint
# =============================================================================
# Public purpose : canonical constraint name for the closed Genus baseline.
# Timing model   : R750_delta5, buffered phase clocks, exact PD Vernier q1 cut.
# Signoff        : typical-only Genus closure; not MMMC or final signoff.
#
# The sourced alias preserves the validated count-checked exception and the
# historical implementation files. New wrappers should reference this file,
# not an O13/ABS experiment filename.
# =============================================================================

if {[info exists design(inputs_dir)] && [file isdirectory $design(inputs_dir)]} {
    set mptdc_axis_core_closed_sdc_dir [file normalize $design(inputs_dir)]
} elseif {[info exists ::env(MPTDC_SYN_INPUTS_DIR)] &&
          [file isdirectory $::env(MPTDC_SYN_INPUTS_DIR)]} {
    set mptdc_axis_core_closed_sdc_dir [file normalize $::env(MPTDC_SYN_INPUTS_DIR)]
} else {
    set mptdc_axis_core_closed_sdc_dir [file dirname [file normalize [info script]]]
}

set mptdc_axis_core_closed_delegate \
    [file join $mptdc_axis_core_closed_sdc_dir mptdc_pd_vernier_exceptions.sdc]
if {![file exists $mptdc_axis_core_closed_delegate]} {
    error "MPTDC_AXIS_CORE_TYPICAL_CLOSED_SDC_FATAL: missing $mptdc_axis_core_closed_delegate"
}

puts "MPTDC_AXIS_CORE_TYPICAL_CLOSED_SDC_INFO: sourcing canonical PD Vernier constraint stack"
source $mptdc_axis_core_closed_delegate
