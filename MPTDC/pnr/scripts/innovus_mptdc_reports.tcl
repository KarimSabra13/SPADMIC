# =============================================================================
# Stable MPTDC final-typical report manifest and limits
# =============================================================================

if {[llength [info commands mptdc_pnr_env]] == 0} {
    proc mptdc_pnr_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_pnr_ro_load_preferred_ff {} {
    return [mptdc_pnr_env MPTDC_PNR_RO_LOAD_PREFERRED_FF 58.72]
}

proc mptdc_pnr_ro_load_warning_ff {} {
    return [mptdc_pnr_env MPTDC_PNR_RO_LOAD_WARNING_FF 75.59]
}

proc mptdc_pnr_required_reports {} {
    return [list \
        run_manifest.txt \
        floorplan_intent.rpt \
        pd_grid_intent.rpt \
        phase_buffer_placement.csv \
        power_connectivity.rpt \
        io_load_model.rpt \
        cts_policy.rpt \
        cts_exclusion_audit.rpt \
        report_clocks.rpt \
        drv_max_transition.rpt \
        drv_max_cap.rpt \
        drv_max_fanout.rpt \
        raw_ro_pin_loads.csv \
        phase_buffer_output_loads.csv \
        phase_route_mismatch.csv \
        timing_post_route_summary_by_class.md \
        route_summary.rpt \
        congestion.rpt \
        drc_summary.rpt \
        lvs_setup_manifest.rpt \
        extraction_setup_manifest.rpt \
    ]
}

proc mptdc_pnr_write_report_manifest {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_REPORT_MANIFEST mptdc_required_reports.rpt]
    }
    set fh [open $path w]
    puts $fh "# MPTDC Required Report Manifest"
    puts $fh "labels=TYPICAL_ONLY NOT_MMMC_SIGNOFF NOT_FINAL_SILICON_SIGNOFF"
    puts $fh "ro_load_preferred_ff=[mptdc_pnr_ro_load_preferred_ff]"
    puts $fh "ro_load_warning_ff=[mptdc_pnr_ro_load_warning_ff]"
    puts $fh ""
    foreach rpt [mptdc_pnr_required_reports] {
        puts $fh $rpt
    }
    close $fh
    return $path
}
