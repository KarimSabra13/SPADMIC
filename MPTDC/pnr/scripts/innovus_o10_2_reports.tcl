# =============================================================================
# O10.2 reports
# =============================================================================

proc mptdc_o10_report_stage {stage} {
    global o10
    mptdc_o10_capture_candidates "$o10(reports_dir)/timing_${stage}.rpt" \
        "O10.2 timing $stage" [list \
            {report_timing -max_paths 100} \
            {report_timing -max_paths 100 -path_type full_clock} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/high_fanout_summary_${stage}.rpt" \
        "O10.2 high fanout $stage" [list \
            {reportFanoutViolation} \
            {reportHighFanoutNet -threshold 50} \
            {reportNetStat} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_${stage}.rpt" \
        "O10.2 DRV $stage" [list \
            {report_constraint -all_violators} \
            {report_design_rules} \
        ]
    mptdc_o10_write_residual_tracking $stage
}

proc mptdc_o10_write_residual_tracking {stage} {
    global o10
    set path "$o10(reports_dir)/residual_path_tracking.csv"
    set exists [file exists $path]
    set fh [open $path a]
    if {!$exists} {
        puts $fh "stage,startpoint,endpoint,expected_family,matched,status,slack_ps,notes"
    }
    set start {(R) u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[5]/C}
    foreach row {7 6 5 4 2 1 0} {
        set endpoint [format {(F) u_core_gen_pd_row[%d].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D} $row]
        puts $fh "$stage,\"$start\",\"$endpoint\",FAST_TAG_TO_PD_TS,REVIEW_TIMING_REPORT,unknown,,see timing_${stage}.rpt"
    }
    close $fh
}

proc mptdc_o10_timing_report_stats {path} {
    if {![file exists $path]} {
        return [list "missing" "" 0 0]
    }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    if {[regexp {FAILED:} $text]} {
        return [list "failed" "" 0 0]
    }
    set wns ""
    set paths 0
    set violations 0
    foreach line [split $text "\n"] {
        if {[regexp {^Path[[:space:]]+[0-9]+:} $line]} { incr paths }
        if {[regexp {VIOLATED} $line]} { incr violations }
        if {[regexp {Slack Time[[:space:]]+(-?[0-9.]+)} $line -> slack]} {
            if {$wns eq "" || $slack < $wns} { set wns $slack }
        }
    }
    return [list "ok" $wns $violations $paths]
}

proc mptdc_o10_write_checkpoint_status_report {} {
    global o10
    set fh [open "$o10(reports_dir)/checkpoint_status.rpt" w]
    puts $fh "O10.2 checkpoint status"
    puts $fh "======================="
    foreach rel {
        checkpoints/01_floorplan.enc
        checkpoints/02_place.enc
        checkpoints/03_cts.enc
        checkpoints/04_route.enc
        checkpoints/restore_latest.tcl
        checkpoints/restore_place.tcl
        checkpoints/restore_route.tcl
    } {
        if {[file exists "$o10(result_dir)/$rel"] || [file exists "$o10(result_dir)/$rel.dat"]} {
            puts $fh "present: $rel"
        } else {
            puts $fh "missing: $rel"
        }
    }
    close $fh
}

proc mptdc_o10_write_timing_class_reports {} {
    global o10
    mptdc_o10_capture_candidates "$o10(reports_dir)/timing_post_route_core_internal.rpt" \
        "O10.2 post-route core internal timing" [list \
            {report_timing -from [all_registers] -to [all_registers] -max_paths 100} \
            {report_timing -max_paths 100} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/timing_post_route_io_output.rpt" \
        "O10.2 post-route IO output timing" [list \
            {report_timing -to [all_outputs] -max_paths 100} \
            {report_timing -to [get_ports acq_data_o*] -max_paths 100} \
            {report_timing -max_paths 100} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/timing_post_route_reset_recovery.rpt" \
        "O10.2 post-route reset/recovery timing" [list \
            {report_timing -check_type recovery -max_paths 100} \
            {report_timing -check_type removal -max_paths 100} \
            {report_timing -max_paths 100} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/timing_post_route_ro_osc_domain.rpt" \
        "O10.2 post-route RO oscillator-domain timing" [list \
            {report_timing -path_group clk_osc_fast -max_paths 100} \
            {report_timing -path_group clk_osc_fast_tap1 -max_paths 100} \
            {report_timing -max_paths 100} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/timing_post_route_clk_sys_internal.rpt" \
        "O10.2 post-route clk_sys internal timing" [list \
            {report_timing -path_group clk_sys -max_paths 100} \
            {report_timing -from [get_clocks clk_sys] -to [get_clocks clk_sys] -max_paths 100} \
            {report_timing -max_paths 100} \
        ]

    set fh [open "$o10(reports_dir)/timing_post_route_summary_by_class.md" w]
    puts $fh "# O10.2 Post-Route Timing Summary By Class"
    puts $fh ""
    puts $fh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $fh ""
    puts $fh "| Class | Report | Status | WNS ns | Violated path markers | Path markers | Notes |"
    puts $fh "|---|---|---:|---:|---:|---:|---|"
    foreach row {
        {CORE_INTERNAL timing_post_route_core_internal.rpt "register-to-register core timing"}
        {IO_OUTPUT timing_post_route_io_output.rpt "block IO output timing; provisional IO budget, not signoff"}
        {ASYNC_RESET_RECOVERY timing_post_route_reset_recovery.rpt "recovery/removal classified separately from normal setup"}
        {RO_OSC_DOMAIN timing_post_route_ro_osc_domain.rpt "RO/local tag/PD oscillator-domain timing"}
        {CLK_SYS_INTERNAL timing_post_route_clk_sys_internal.rpt "clk_sys internal timing"}
    } {
        set class [lindex $row 0]
        set rpt [lindex $row 1]
        set note [lindex $row 2]
        set stats [mptdc_o10_timing_report_stats "$o10(reports_dir)/$rpt"]
        puts $fh "| $class | `$rpt` | [lindex $stats 0] | [lindex $stats 1] | [lindex $stats 2] | [lindex $stats 3] | $note |"
    }
    puts $fh ""
    puts $fh "Do not let IO output or reset/recovery paths dominate the core closure conclusion."
    close $fh
}

proc mptdc_o10_write_reset_recovery_summary {} {
    global o10
    set fh [open "$o10(reports_dir)/reset_recovery_summary.md" w]
    puts $fh "# O10.2 Reset/Recovery Summary"
    puts $fh ""
    puts $fh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $fh ""
    puts $fh "- Reset/recovery checks are reported separately in `timing_post_route_reset_recovery.rpt`."
    puts $fh "- Do not broadly false-path resets without a documented protocol waiver."
    puts $fh "- Review whether oscillator-domain clears release only while oscillators are idle and before restart."
    close $fh
    if {[file exists "$o10(reports_dir)/timing_post_route_reset_recovery.rpt"]} {
        file copy -force "$o10(reports_dir)/timing_post_route_reset_recovery.rpt" "$o10(reports_dir)/reset_recovery_paths.rpt"
    }
}

proc mptdc_o10_final_reports {} {
    global o10
    mptdc_o10_capture "$o10(reports_dir)/report_clocks.rpt" "O10.2 clocks" {report_clocks}
    mptdc_o10_capture_candidates "$o10(reports_dir)/clock_tree_summary.rpt" \
        "O10.2 clock tree summary" [list \
            {reportClockTree -summary} \
            {report_clock_tree -summary} \
            {report_clocks} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/congestion.rpt" \
        "O10.2 congestion" [list \
            {reportCongestion -hotSpot -num_hotspot 100 -overflow} \
            {reportCongestion -overflow} \
            {reportCongestion} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/route_summary.rpt" \
        "O10.2 route summary" [list \
            {report_route} \
            {reportRoute} \
            {verifyConnectivity} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/antenna.rpt" \
        "O10.2 antenna check" [list \
            {verifyProcessAntenna} \
            {verifyAntenna} \
            {verify_drc -type antenna} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_max_transition.rpt" \
        "O10.2 max transition" [list {report_constraint -max_transition -all_violators} {report_constraint -all_violators}]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_max_cap.rpt" \
        "O10.2 max capacitance" [list {report_constraint -max_capacitance -all_violators} {report_constraint -all_violators}]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_max_fanout.rpt" \
        "O10.2 max fanout" [list {report_constraint -max_fanout -all_violators} {report_constraint -all_violators}]
    mptdc_o10_capture_candidates "$o10(reports_dir)/high_fanout_summary.rpt" \
        "O10.2 high fanout final" [list {reportFanoutViolation} {reportHighFanoutNet -threshold 50} {reportNetStat}]
    mptdc_o10_capture "$o10(reports_dir)/area.rpt" "O10.2 area" {report_area}
    mptdc_o10_capture_candidates "$o10(reports_dir)/power_summary.rpt" \
        "O10.2 power" [list {report_power} {report_power -hierarchy all}]
    mptdc_o10_write_timing_class_reports
    mptdc_o10_write_reset_recovery_summary
    mptdc_o10_write_checkpoint_status_report

    set fh [open "$o10(reports_dir)/SUMMARY.md" w]
    puts $fh "# O10.2 Innovus PNR Constraint/Report/CTS Repair Summary"
    puts $fh ""
    puts $fh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $fh ""
    puts $fh "- Run ID: `$o10(run_id)`"
    puts $fh "- Labels: `O10_2_PNR_CONSTRAINT_REPORT_CTS_REPAIR`, `O10_INNOVUS_TYPICAL_FEASIBILITY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SIGNOFF`, `NOT_TAPEOUT_READY`"
    puts $fh "- Purpose: typical P&R feasibility with repaired constraints, reports, and CTS policy."
    puts $fh "- SDC: Innovus-safe R750_delta5 overlay; no Genus-only `design(...)` variables."
    puts $fh "- CTS status: `$o10(cts_status)`"
    puts $fh "- RO CTS attempted: `$o10(ro_cts_attempted)`"
    puts $fh "- Genus starting point: WNS -1.6 ps, TNS -11.2 ps, 7 residual `FAST_TAG_TO_PD_TS` paths."
    puts $fh "- Timing is split into core, IO, reset/recovery, RO-domain, and clk_sys classes."
    puts $fh "- Antenna review: `reports/antenna.rpt`."
    puts $fh "- This is not MMMC signoff and not final layout signoff."
    close $fh
}

proc mptdc_o10_manager_summary {} {
    global o10
    set fh [open "$o10(manager_dir)/MANAGER_SUMMARY.md" w]
    puts $fh "# O10.2 Innovus Typical Feasibility"
    puts $fh ""
    puts $fh "- Run ID: `$o10(run_id)`"
    puts $fh "- Purpose: first industry-style typical P&R feasibility / visualization flow."
    puts $fh "- Caveat: `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SIGNOFF`, `NOT_TAPEOUT_READY`."
    puts $fh "- Starting Genus status: near-clean, WNS -1.6 ps, 7 residual fast-tag-to-PD paths."
    puts $fh "- CTS status: `$o10(cts_status)`"
    puts $fh "- RO phase clocks excluded from CTS: `$o10(ro_cts_attempted)` attempted."
    puts $fh ""
    puts $fh "## Floorplan Concept"
    puts $fh ""
    puts $fh "- Slow RO_tune4 north."
    puts $fh "- PD matrix center."
    puts $fh "- Fast RO_tune4 south."
    puts $fh "- Digital backend right."
    puts $fh ""
    puts $fh "## Images"
    foreach img {
        01_floorplan_overview.png
        02_macros_pd_matrix.png
        03_placed_design.png
        04_clk_sys_cts.png
        05_routed_design.png
        06_congestion.png
        07_phase_nets_highlight.png
        08_final_manager_view.png
    } {
        if {[file exists "$o10(screenshots_dir)/$img"] && [file size "$o10(screenshots_dir)/$img"] > 0} {
            puts $fh "- `../screenshots/$img`"
        }
    }
    if {[file exists "$o10(screenshots_dir)/SCREENSHOT_EXPORT_FAILED.txt"]} {
        puts $fh "- Automatic screenshots unavailable in batch/nowin mode; see `GUI_SCREENSHOT_INSTRUCTIONS.md`."
    }
    puts $fh ""
    puts $fh "These images or restore instructions show a typical-feasibility placement/routing view, not final signoff layout."
    puts $fh ""
    puts $fh "## Required Reviews"
    puts $fh ""
    puts $fh "- Timing: `reports/timing_post_route_summary_by_class.md`."
    puts $fh "- DRV: max transition, max cap, and max fanout reports."
    puts $fh "- RO phase load: `reports/phase_net_loads.csv`; compare actual caps to analog max allowed load."
    puts $fh "- PD matrix: `reports/pd_instance_placement.csv` and `reports/pd_symmetry_summary.md`."
    puts $fh "- Screenshots: restore checkpoint using `GUI_SCREENSHOT_INSTRUCTIONS.md` if PNGs are absent."
    close $fh
}
