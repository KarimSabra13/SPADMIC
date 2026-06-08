# =============================================================================
# O12C phase-buffer topology/placement reports
#
# O12C starts by reusing the hardened O12B report generator.  The O12B reports
# now parse report_property output for capacitance/resistance, which is the
# portable Innovus path that worked in abs4.
# =============================================================================

set ::env(MPTDC_O12B_SOURCE_ONLY) 1
source [file join [file dirname [file normalize [info script]]] innovus_o12b_phase_buffer_reports.tcl]

proc mptdc_o12c_write_reports {} {
    return [mptdc_o12b_write_reports]
}
