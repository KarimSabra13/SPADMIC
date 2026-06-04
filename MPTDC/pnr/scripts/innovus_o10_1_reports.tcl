# =============================================================================
# O10.1 reports
# =============================================================================

proc mptdc_o10_report_stage {stage} {
    global o10
    mptdc_o10_capture_candidates "$o10(reports_dir)/timing_${stage}.rpt" \
        "O10.1 timing $stage" [list \
            {report_timing -max_paths 100} \
            {report_timing -max_paths 100 -path_type full_clock} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/high_fanout_summary_${stage}.rpt" \
        "O10.1 high fanout $stage" [list \
            {reportFanoutViolation} \
            {reportHighFanoutNet -threshold 50} \
            {reportNetStat} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_${stage}.rpt" \
        "O10.1 DRV $stage" [list \
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

proc mptdc_o10_write_checkpoint_status_report {} {
    global o10
    set fh [open "$o10(reports_dir)/checkpoint_status.rpt" w]
    puts $fh "O10.1 checkpoint status"
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
        if {[file exists "$o10(result_dir)/$rel"]} {
            puts $fh "present: $rel"
        } else {
            puts $fh "missing: $rel"
        }
    }
    close $fh
}

proc mptdc_o10_final_reports {} {
    global o10
    mptdc_o10_capture "$o10(reports_dir)/report_clocks.rpt" "O10.1 clocks" {report_clocks}
    mptdc_o10_capture_candidates "$o10(reports_dir)/clock_tree_summary.rpt" \
        "O10.1 clock tree summary" [list \
            {reportClockTree -summary} \
            {report_clock_tree -summary} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/congestion.rpt" \
        "O10.1 congestion" [list \
            {reportCongestion -hotSpot -num_hotspot 100 -overflow} \
            {reportCongestion -overflow} \
            {reportCongestion} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/route_summary.rpt" \
        "O10.1 route summary" [list \
            {reportRoute} \
            {report_route} \
            {verifyConnectivity} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_max_transition.rpt" \
        "O10.1 max transition" [list {report_constraint -max_transition -all_violators} {report_constraint -all_violators}]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_max_cap.rpt" \
        "O10.1 max capacitance" [list {report_constraint -max_capacitance -all_violators} {report_constraint -all_violators}]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_max_fanout.rpt" \
        "O10.1 max fanout" [list {report_constraint -max_fanout -all_violators} {report_constraint -all_violators}]
    mptdc_o10_capture_candidates "$o10(reports_dir)/high_fanout_summary.rpt" \
        "O10.1 high fanout final" [list {reportFanoutViolation} {reportHighFanoutNet -threshold 50} {reportNetStat}]
    mptdc_o10_capture "$o10(reports_dir)/area.rpt" "O10.1 area" {report_area}
    mptdc_o10_capture_candidates "$o10(reports_dir)/power_summary.rpt" \
        "O10.1 power" [list {report_power} {report_power -hierarchy all}]
    mptdc_o10_capture_candidates "$o10(reports_dir)/timing_post_route_core_only.rpt" \
        "O10.1 post-route core-only timing candidates" [list \
            {report_timing -from [all_registers] -to [all_registers] -max_paths 100} \
            {report_timing -max_paths 100} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/timing_post_route_io_paths.rpt" \
        "O10.1 post-route IO timing candidates" [list \
            {report_timing -to [get_ports acq_data_o*] -max_paths 100} \
            {report_timing -max_paths 100} \
        ]
    mptdc_o10_write_checkpoint_status_report

    set fh [open "$o10(reports_dir)/SUMMARY.md" w]
    puts $fh "# O10.1 Innovus Flow Repair Summary"
    puts $fh ""
    puts $fh "- Run ID: `$o10(run_id)`"
    puts $fh "- Labels: `O10_1_INNOVUS_FLOW_REPAIR`, `O10_INNOVUS_TYPICAL_FEASIBILITY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SIGNOFF`, `NOT_TAPEOUT_READY`"
    puts $fh "- Purpose: repaired first physical feasibility and visualization flow."
    puts $fh "- SDC: Innovus-safe R750_delta5 overlay; no Genus-only `design(...)` variables."
    puts $fh "- CTS status: `$o10(cts_status)`"
    puts $fh "- RO CTS attempted: `$o10(ro_cts_attempted)`"
    puts $fh "- Genus starting point: WNS -1.6 ps, TNS -11.2 ps, 7 residual `FAST_TAG_TO_PD_TS` paths."
    puts $fh "- Timing review must separate core paths from IO-output artifacts."
    puts $fh "- This is not MMMC signoff and not final layout signoff."
    close $fh
}

proc mptdc_o10_manager_summary {} {
    global o10
    set fh [open "$o10(manager_dir)/MANAGER_SUMMARY.md" w]
    puts $fh "# O10.1 Innovus Typical Feasibility"
    puts $fh ""
    puts $fh "- Run ID: `$o10(run_id)`"
    puts $fh "- Purpose: first repaired Innovus typical feasibility / visualization flow."
    puts $fh "- Caveat: `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SIGNOFF`, `NOT_TAPEOUT_READY`."
    puts $fh "- Starting Genus status: near-clean, WNS -1.6 ps, 7 residual fast-tag-to-PD paths."
    puts $fh "- CTS status: `$o10(cts_status)`"
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
    puts $fh "These images or restore instructions show the first typical-feasibility placement/routing view, not final signoff layout."
    puts $fh ""
    puts $fh "## Required Reviews"
    puts $fh ""
    puts $fh "- Timing: review core, IO, and RO-domain reports separately."
    puts $fh "- DRV: review max transition/cap/fanout reports."
    puts $fh "- Phase nets: review phase-net and fast-tag load CSVs."
    puts $fh "- PD matrix: review 64-cell placement/symmetry summary."
    close $fh
}
