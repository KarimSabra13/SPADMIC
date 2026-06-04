# =============================================================================
# O10 reports
# =============================================================================

proc mptdc_o10_report_stage {stage} {
    global o10
    mptdc_o10_capture_candidates "$o10(reports_dir)/timing_${stage}.rpt" \
        "O10 timing $stage" [list \
            {report_timing -max_paths 100} \
            {report_timing -max_paths 100 -path_type full_clock} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/high_fanout_summary_${stage}.rpt" \
        "O10 high fanout $stage" [list \
            {reportNetStat -fanout 50} \
            {reportHighFanoutNet -threshold 50} \
            {reportFanoutViolation} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_${stage}.rpt" \
        "O10 DRV $stage" [list \
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

proc mptdc_o10_final_reports {} {
    global o10
    mptdc_o10_capture "$o10(reports_dir)/report_clocks.rpt" "O10 clocks" {report_clocks}
    mptdc_o10_capture_candidates "$o10(reports_dir)/clock_tree_summary.rpt" \
        "O10 clock tree summary" [list \
            {reportClockTree -summary} \
            {report_clock_tree -summary} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/congestion.rpt" \
        "O10 congestion" [list \
            {reportCongestion -hotSpot -num_hotspot 100 -overflow} \
            {reportCongestion -overflow} \
            {reportCongestion} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/route_summary.rpt" \
        "O10 route summary" [list \
            {reportRoute} \
            {report_route} \
            {verifyConnectivity} \
        ]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_max_transition.rpt" \
        "O10 max transition" [list {report_constraint -max_transition -all_violators} {report_constraint -all_violators}]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_max_cap.rpt" \
        "O10 max capacitance" [list {report_constraint -max_capacitance -all_violators} {report_constraint -all_violators}]
    mptdc_o10_capture_candidates "$o10(reports_dir)/drv_max_fanout.rpt" \
        "O10 max fanout" [list {report_constraint -max_fanout -all_violators} {report_constraint -all_violators}]
    mptdc_o10_capture_candidates "$o10(reports_dir)/high_fanout_summary.rpt" \
        "O10 high fanout final" [list {reportNetStat -fanout 50} {reportHighFanoutNet -threshold 50}]
    mptdc_o10_capture "$o10(reports_dir)/area.rpt" "O10 area" {report_area}
    mptdc_o10_capture_candidates "$o10(reports_dir)/power_summary.rpt" \
        "O10 power" [list {report_power} {report_power -hierarchy all}]

    set fh [open "$o10(reports_dir)/SUMMARY.md" w]
    puts $fh "# O10 Innovus Typical Feasibility Summary"
    puts $fh ""
    puts $fh "- Run ID: `$o10(run_id)`"
    puts $fh "- Labels: `O10_INNOVUS_TYPICAL_FEASIBILITY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SIGNOFF`, `NOT_TAPEOUT_READY`"
    puts $fh "- Purpose: first physical feasibility and visualization run."
    puts $fh "- Genus starting point: WNS -1.6 ps, TNS -11.2 ps, 7 residual `FAST_TAG_TO_PD_TS` paths."
    puts $fh "- Review timing, DRV, congestion, phase-net, and PD symmetry reports before any Innovus-readiness claim."
    close $fh
}

proc mptdc_o10_manager_summary {} {
    global o10
    set fh [open "$o10(manager_dir)/MANAGER_SUMMARY.md" w]
    puts $fh "# O10 Innovus Typical Feasibility"
    puts $fh ""
    puts $fh "- Run ID: `$o10(run_id)`"
    puts $fh "- Purpose: first Innovus typical feasibility / visualization."
    puts $fh "- Caveat: not final signoff, not MMMC signoff, not tapeout ready."
    puts $fh "- Starting Genus status: near-clean, WNS -1.6 ps, 7 residual fast-tag-to-PD paths."
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
        puts $fh "- `../screenshots/$img`"
    }
    puts $fh ""
    puts $fh "These images show the first typical-feasibility placement/routing view, not final signoff layout."
    close $fh
}
