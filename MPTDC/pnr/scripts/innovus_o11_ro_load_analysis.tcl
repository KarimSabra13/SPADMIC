# =============================================================================
# O11 RO_tune4 load analysis entrypoint
#
# Restores the O10.2 routed checkpoint and runs report-only load extraction.
# =============================================================================

proc mptdc_o11_msg {msg} {
    puts "MPTDC_O11: $msg"
}

proc mptdc_o11_fail {msg} {
    puts "MPTDC_O11_ERROR: $msg"
    exit 1
}

proc mptdc_o11_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_o11_mkdirs {} {
    global o11
    foreach key {result_dir logs_dir reports_dir manifests_dir work_dir} {
        file mkdir $o11($key)
    }
}

proc mptdc_o11_capture_candidates {path title bodies} {
    set dir [file dirname $path]
    file mkdir $dir
    set errors [list]
    foreach body $bodies {
        if {![catch {uplevel 1 "$body > \"$path\""} err]} {
            return 1
        }
        lappend errors "$body: $err"
    }
    set fh [open $path w]
    puts $fh "$title"
    puts $fh [string repeat "=" [string length $title]]
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    puts $fh "FAILED:"
    puts $fh [join $errors "\n\n"]
    close $fh
    mptdc_o11_msg "all report variants failed: $title"
    return 0
}

proc mptdc_o11_setup_globals {} {
    global o11

    set script_dir [file dirname [file normalize [info script]]]
    set pnr_root   [file dirname $script_dir]
    set mptdc_root [file dirname $pnr_root]
    set repo_root  [file dirname $mptdc_root]

    set o11(script_dir) $script_dir
    set o11(pnr_root) $pnr_root
    set o11(mptdc_root) $mptdc_root
    set o11(repo_root) $repo_root
    set o11(run_id) [mptdc_o11_env MPTDC_O11_RUN_ID 20260608_o11_ro_load_analysis]
    set o11(source_run_id) [mptdc_o11_env MPTDC_O11_SOURCE_RUN_ID 20260604_o10_2_pnr_repair]
    set o11(result_dir) [mptdc_o11_env MPTDC_O11_RESULT_DIR "$repo_root/results/innovus/$o11(run_id)"]
    set o11(logs_dir) "$o11(result_dir)/logs"
    set o11(reports_dir) "$o11(result_dir)/reports"
    set o11(manifests_dir) "$o11(result_dir)/manifests"
    set o11(work_dir) "$o11(result_dir)/work"
    set o11(source_result_dir) "$repo_root/results/innovus/$o11(source_run_id)"
    set o11(source_checkpoint_dat) [mptdc_o11_env MPTDC_O11_SOURCE_CHECKPOINT_DAT "$o11(source_result_dir)/checkpoints/04_route.enc.dat"]
    set o11(source_restore_tcl) [mptdc_o11_env MPTDC_O11_SOURCE_RESTORE_TCL "$o11(source_result_dir)/checkpoints/restore_latest.tcl"]

    mptdc_o11_mkdirs
}

proc mptdc_o11_write_manifest {} {
    global o11
    set fh [open "$o11(manifests_dir)/run_manifest.txt" w]
    puts $fh "# O11 RO_tune4 Load Analysis"
    puts $fh "date: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh "run_id: $o11(run_id)"
    puts $fh "result_dir: $o11(result_dir)"
    puts $fh "source_run_id: $o11(source_run_id)"
    puts $fh "source_result_dir: $o11(source_result_dir)"
    puts $fh "source_checkpoint_dat: $o11(source_checkpoint_dat)"
    puts $fh "source_restore_tcl: $o11(source_restore_tcl)"
    puts $fh "labels: O11_RO_LOAD_ANALYSIS REPORT_ONLY NOT_FINAL_SIGNOFF"
    close $fh
}

proc mptdc_o11_restore_source_checkpoint {} {
    global o11
    if {[file exists $o11(source_checkpoint_dat)]} {
        mptdc_o11_msg "Restoring checkpoint from current checkout: $o11(source_checkpoint_dat)"
        restoreDesign $o11(source_checkpoint_dat) mptdc_top_asic
        return
    }
    if {[file exists $o11(source_restore_tcl)]} {
        mptdc_o11_msg "Restoring checkpoint from restore script: $o11(source_restore_tcl)"
        source $o11(source_restore_tcl)
        return
    }
    mptdc_o11_fail "missing O10.2 route checkpoint. Tried $o11(source_checkpoint_dat) and $o11(source_restore_tcl)"
}

proc mptdc_o11_write_summary {} {
    global o11
    set fh [open "$o11(reports_dir)/SUMMARY.md" w]
    puts $fh "# O11 RO_tune4 Load Analysis Summary"
    puts $fh ""
    puts $fh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $fh ""
    puts $fh "- Run ID: `$o11(run_id)`"
    puts $fh "- Source run: `$o11(source_run_id)`"
    puts $fh "- Mode: report-only restore of the O10.2 routed checkpoint."
    puts $fh "- No routing, CTS, RTL, SDC, or Liberty relaxation is performed by this run."
    puts $fh "- Main load report: `phase_net_load_budget_summary.md`."
    puts $fh "- CSVs: `phase_net_loads.csv`, `fast_tag_loads.csv`, `ro_phase_sink_classification.csv`."
    puts $fh "- Labels: `O11_RO_LOAD_ANALYSIS`, `REPORT_ONLY`, `NOT_FINAL_SIGNOFF`."
    close $fh
}

proc mptdc_o11_main {} {
    global o11
    mptdc_o11_setup_globals
    mptdc_o11_write_manifest
    source "$o11(script_dir)/innovus_o11_ro_load_reports.tcl"

    mptdc_o11_restore_source_checkpoint
    mptdc_o11_capture_candidates "$o11(reports_dir)/report_clocks.rpt" \
        "O11 restored checkpoint clocks" [list {report_clocks}]
    mptdc_o11_capture_candidates "$o11(reports_dir)/drv_max_cap.rpt" \
        "O11 restored checkpoint max capacitance" [list \
            {report_constraint -max_capacitance -all_violators} \
            {report_constraint -all_violators} \
        ]
    if {[catch {mptdc_o11_write_ro_load_reports} err]} {
        mptdc_o11_write_error_csv "$o11(reports_dir)/phase_net_loads.csv" \
            "status,message" $err
        mptdc_o11_write_error_csv "$o11(reports_dir)/fast_tag_loads.csv" \
            "status,message" $err
        mptdc_o11_write_error_csv "$o11(reports_dir)/ro_phase_sink_classification.csv" \
            "status,message" $err
        mptdc_o11_fail "RO load report generation failed: $err"
    }
    mptdc_o11_write_summary
    mptdc_o11_msg "O11 RO_tune4 load analysis complete"
}

if {![info exists ::env(MPTDC_O11_SOURCE_ONLY)] || !$::env(MPTDC_O11_SOURCE_ONLY)} {
    mptdc_o11_main
}
