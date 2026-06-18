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

proc mptdc_pnr_ro_load_shell_limit_ff {} {
    return [mptdc_pnr_env MPTDC_PNR_RO_LOAD_SHELL_LIMIT_FF 50.0]
}

proc mptdc_pnr_ro_load_resolved_limit_ff {} {
    set shell [mptdc_pnr_ro_load_shell_limit_ff]
    set preferred [mptdc_pnr_ro_load_preferred_ff]
    set warning [mptdc_pnr_ro_load_warning_ff]
    return [expr {min($shell, $preferred, $warning)}]
}

proc mptdc_pnr_required_reports {} {
    return [list \
        run_manifest.txt \
        SUMMARY.md \
        reports/SUMMARY.md \
        floorplan_intent.rpt \
        pd_grid_intent.rpt \
        fast_tag_column_intent.rpt \
        phase_buffer_placement.csv \
        phase_buffer_intent.rpt \
        power_connectivity.rpt \
        power_intent.rpt \
        unconnected_pg_pins.rpt \
        io_load_model.rpt \
        timing_io_output.rpt \
        cts_policy.rpt \
        cts_status.rpt \
        cts_clock_inclusion_audit.rpt \
        clock_tree_summary.rpt \
        report_clocks.rpt \
        timing_by_class.md \
        timing_post_route.rpt \
        timing_clk_sys.rpt \
        timing_ro_domain.rpt \
        timing_reset_recovery.rpt \
        reset_recovery_summary.md \
        fast_tag_to_pd_timing_post_route.rpt \
        fast_tag_to_pd_route_lengths.csv \
        drv_max_transition.rpt \
        drv_max_cap.rpt \
        drv_max_fanout.rpt \
        raw_ro_pin_loads.csv \
        ro_load_limit_sources.rpt \
        ro_phase_raw_pin_loads_xlibd.csv \
        phase_buffer_output_loads.csv \
        phase_buffer_output_loads_xlibd.csv \
        phase_buffer_balance_summary.md \
        pd_matrix_symmetry.md \
        phase_route_mismatch.csv \
        postroute_opt_status.rpt \
        timing_post_route_summary_by_class.md \
        route_summary.rpt \
        route_drc.rpt \
        congestion.rpt \
        antenna.rpt \
        antenna_repair_status.rpt \
        density.rpt \
        physical_verification_status.md \
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
    puts $fh "ro_load_shell_limit_ff=[mptdc_pnr_ro_load_shell_limit_ff]"
    puts $fh "ro_load_resolved_limit_ff=[mptdc_pnr_ro_load_resolved_limit_ff]"
    puts $fh "ro_load_policy=use_most_restrictive_validated_limit_until_analog_approval"
    puts $fh "FAST_TAG_TO_PD_TS_POSTROUTE_CLEAN=REVIEW_AFTER_ROUTE"
    puts $fh "RESET_RECOVERY_STATUS=RESET_RECOVERY_REVIEW_REQUIRED_UNTIL_PROVEN"
    puts $fh "ANTENNA_STATUS=REVIEW_AFTER_ROUTE"
    puts $fh ""
    foreach rpt [mptdc_pnr_required_reports] {
        puts $fh $rpt
    }
    close $fh
    return $path
}
