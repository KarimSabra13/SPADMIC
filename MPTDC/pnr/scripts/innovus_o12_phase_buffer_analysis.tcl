# =============================================================================
# O12 phase-buffer load analysis entrypoint
#
# Restores an O12 routed checkpoint and runs report-only raw/buffer phase-load
# extraction.  No routing, CTS, RTL, SDC, or Liberty relaxation is performed.
# =============================================================================

proc mptdc_o12_msg {msg} {
    puts "MPTDC_O12: $msg"
}

proc mptdc_o12_fail {msg} {
    puts "MPTDC_O12_ERROR: $msg"
    exit 1
}

proc mptdc_o12_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_o12_mkdirs {} {
    global o12
    foreach key {result_dir logs_dir reports_dir manifests_dir work_dir} {
        file mkdir $o12($key)
    }
}

proc mptdc_o12_capture_candidates {path title bodies} {
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
    mptdc_o12_msg "all report variants failed: $title"
    return 0
}

proc mptdc_o12_setup_globals {} {
    global o12

    set script_dir [file dirname [file normalize [info script]]]
    set pnr_root   [file dirname $script_dir]
    set mptdc_root [file dirname $pnr_root]
    set repo_root  [file dirname $mptdc_root]

    set o12(script_dir) $script_dir
    set o12(pnr_root) $pnr_root
    set o12(mptdc_root) $mptdc_root
    set o12(repo_root) $repo_root
    set o12(run_id) [mptdc_o12_env MPTDC_O12_RUN_ID 20260608_o12_phase_buffer_analysis]
    set o12(source_run_id) [mptdc_o12_env MPTDC_O12_SOURCE_RUN_ID 20260608_o12_phase_buffer_pnr]
    set o12(result_dir) [mptdc_o12_env MPTDC_O12_RESULT_DIR "$repo_root/results/innovus/$o12(run_id)"]
    set o12(logs_dir) "$o12(result_dir)/logs"
    set o12(reports_dir) "$o12(result_dir)/reports"
    set o12(manifests_dir) "$o12(result_dir)/manifests"
    set o12(work_dir) "$o12(result_dir)/work"
    set o12(source_result_dir) "$repo_root/results/innovus/$o12(source_run_id)"
    set o12(source_checkpoint_dat) [mptdc_o12_env MPTDC_O12_SOURCE_CHECKPOINT_DAT "$o12(source_result_dir)/checkpoints/04_route.enc.dat"]
    set o12(source_restore_tcl) [mptdc_o12_env MPTDC_O12_SOURCE_RESTORE_TCL "$o12(source_result_dir)/checkpoints/restore_latest.tcl"]

    mptdc_o12_mkdirs
}

proc mptdc_o12_write_manifest {} {
    global o12
    set fh [open "$o12(manifests_dir)/run_manifest.txt" w]
    puts $fh "# O12 Phase Buffer Load Analysis"
    puts $fh "date: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh "run_id: $o12(run_id)"
    puts $fh "result_dir: $o12(result_dir)"
    puts $fh "source_run_id: $o12(source_run_id)"
    puts $fh "source_result_dir: $o12(source_result_dir)"
    puts $fh "source_checkpoint_dat: $o12(source_checkpoint_dat)"
    puts $fh "source_restore_tcl: $o12(source_restore_tcl)"
    puts $fh "labels: O12_PHASE_ISOLATION_BUFFER_EXPERIMENT REPORT_ONLY NOT_FINAL_SIGNOFF"
    close $fh
}

proc mptdc_o12_restore_source_checkpoint {} {
    global o12
    if {[file exists $o12(source_checkpoint_dat)]} {
        mptdc_o12_msg "Restoring checkpoint from current checkout: $o12(source_checkpoint_dat)"
        restoreDesign $o12(source_checkpoint_dat) mptdc_axis_core
        return
    }
    if {[file exists $o12(source_restore_tcl)]} {
        mptdc_o12_msg "Restoring checkpoint from restore script: $o12(source_restore_tcl)"
        source $o12(source_restore_tcl)
        return
    }
    mptdc_o12_fail "missing O12 route checkpoint. Tried $o12(source_checkpoint_dat) and $o12(source_restore_tcl)"
}

proc mptdc_o12_write_summary {} {
    global o12
    set fh [open "$o12(reports_dir)/SUMMARY.md" w]
    puts $fh "# O12 Phase Buffer Load Analysis Summary"
    puts $fh ""
    puts $fh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $fh ""
    puts $fh "- Run ID: `$o12(run_id)`"
    puts $fh "- Source run: `$o12(source_run_id)`"
    puts $fh "- Mode: report-only restore of an O12 routed checkpoint."
    puts $fh "- No routing, CTS, RTL, SDC, or Liberty relaxation is performed by this run."
    puts $fh "- Main load report: `phase_buffer_balance_summary.md`."
    puts $fh "- CSVs: `ro_phase_raw_pin_loads.csv`, `phase_buffer_output_loads.csv`."
    puts $fh "- Labels: `O12_PHASE_ISOLATION_BUFFER_EXPERIMENT`, `REPORT_ONLY`, `NOT_FINAL_SIGNOFF`."
    close $fh
}

proc mptdc_o12_main {} {
    global o12
    mptdc_o12_setup_globals
    mptdc_o12_write_manifest
    source "$o12(script_dir)/innovus_o12_phase_buffer_reports.tcl"

    mptdc_o12_restore_source_checkpoint
    mptdc_o12_capture_candidates "$o12(reports_dir)/report_clocks.rpt" \
        "O12 restored checkpoint clocks" [list {report_clocks}]
    mptdc_o12_capture_candidates "$o12(reports_dir)/drv_max_cap.rpt" \
        "O12 restored checkpoint max capacitance" [list \
            {report_constraint -max_capacitance -all_violators} \
            {report_constraint -all_violators} \
        ]
    if {[catch {mptdc_o12_write_phase_buffer_reports} err]} {
        mptdc_o11_write_error_csv "$o12(reports_dir)/ro_phase_raw_pin_loads.csv" \
            "status,message" $err
        mptdc_o11_write_error_csv "$o12(reports_dir)/phase_buffer_output_loads.csv" \
            "status,message" $err
        mptdc_o12_fail "phase-buffer report generation failed: $err"
    }
    mptdc_o12_write_summary
    mptdc_o12_msg "O12 phase-buffer load analysis complete"
}

if {![info exists ::env(MPTDC_O12_SOURCE_ONLY)] || !$::env(MPTDC_O12_SOURCE_ONLY)} {
    mptdc_o12_main
}
