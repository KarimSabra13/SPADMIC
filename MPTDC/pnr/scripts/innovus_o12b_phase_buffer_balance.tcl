# =============================================================================
# O12B phase-buffer balance report-only entrypoint
#
# Restores an O12 routed checkpoint and generates DB-backed phase-buffer
# topology/load/placement reports.  No route, CTS, RTL, SDC, or Liberty changes
# are made by this script.
# =============================================================================

proc mptdc_o12b_msg {msg} {
    puts "MPTDC_O12B: $msg"
}

proc mptdc_o12b_fail {msg} {
    puts "MPTDC_O12B_ERROR: $msg"
    exit 1
}

proc mptdc_o12b_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_o12b_mkdirs {} {
    global o12b
    foreach key {result_dir logs_dir reports_dir manifests_dir work_dir} {
        file mkdir $o12b($key)
    }
}

proc mptdc_o12b_csv_safe {value} {
    set text "$value"
    regsub -all {"} $text {""} text
    if {[regexp {[,"
]} $text]} {
        return "\"$text\""
    }
    return $text
}

proc mptdc_o12b_stage_mark {stage status} {
    global o12b
    if {![info exists o12b(manifests_dir)]} { return }
    file mkdir $o12b(manifests_dir)
    set trace "$o12b(manifests_dir)/stage_trace.csv"
    set new_file [expr {![file exists $trace]}]
    set timestamp [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]
    set fh [open $trace a]
    if {$new_file} {
        puts $fh "timestamp,stage,status"
    }
    puts $fh "[mptdc_o12b_csv_safe $timestamp],[mptdc_o12b_csv_safe $stage],[mptdc_o12b_csv_safe $status]"
    close $fh

    set cfh [open "$o12b(manifests_dir)/current_stage.txt" w]
    puts $cfh "stage=$stage"
    puts $cfh "status=$status"
    puts $cfh "timestamp=$timestamp"
    close $cfh
}

proc mptdc_o12b_capture_candidates {path title bodies} {
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
    mptdc_o12b_msg "all report variants failed: $title"
    return 0
}

proc mptdc_o12b_setup_globals {} {
    global o12b

    set script_dir [file dirname [file normalize [info script]]]
    set pnr_root   [file dirname $script_dir]
    set mptdc_root [file dirname $pnr_root]
    set repo_root  [file dirname $mptdc_root]

    set o12b(script_dir) $script_dir
    set o12b(pnr_root) $pnr_root
    set o12b(mptdc_root) $mptdc_root
    set o12b(repo_root) $repo_root
    set o12b(run_id) [mptdc_o12b_env MPTDC_O12B_RUN_ID 20260608_o12b_phase_buffer_balance]
    set o12b(source_run_id) [mptdc_o12b_env MPTDC_O12B_SOURCE_RUN_ID 20260608_o12_phase_buffer_pnr_abs1]
    set o12b(result_dir) [mptdc_o12b_env MPTDC_O12B_RESULT_DIR "$repo_root/results/innovus/$o12b(run_id)"]
    set o12b(logs_dir) "$o12b(result_dir)/logs"
    set o12b(reports_dir) "$o12b(result_dir)/reports"
    set o12b(manifests_dir) "$o12b(result_dir)/manifests"
    set o12b(work_dir) "$o12b(result_dir)/work"
    set o12b(source_result_dir) "$repo_root/results/innovus/$o12b(source_run_id)"
    set o12b(source_checkpoint_dat) [mptdc_o12b_env MPTDC_O12B_SOURCE_CHECKPOINT_DAT "$o12b(source_result_dir)/checkpoints/04_route.enc.dat"]
    set o12b(source_restore_tcl) [mptdc_o12b_env MPTDC_O12B_SOURCE_RESTORE_TCL "$o12b(source_result_dir)/checkpoints/restore_latest.tcl"]

    mptdc_o12b_mkdirs
}

proc mptdc_o12b_write_manifest {} {
    global o12b
    set fh [open "$o12b(manifests_dir)/run_manifest.txt" w]
    puts $fh "# O12B Phase Buffer Balance"
    puts $fh "date: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh "run_id: $o12b(run_id)"
    puts $fh "result_dir: $o12b(result_dir)"
    puts $fh "source_run_id: $o12b(source_run_id)"
    puts $fh "source_result_dir: $o12b(source_result_dir)"
    puts $fh "source_checkpoint_dat: $o12b(source_checkpoint_dat)"
    puts $fh "source_restore_tcl: $o12b(source_restore_tcl)"
    puts $fh "labels: O12B_PHASE_BUFFER_BALANCE REPORT_ONLY NOT_FINAL_SIGNOFF"
    close $fh
}

proc mptdc_o12b_restore_source_checkpoint {} {
    global o12b
    if {[file exists $o12b(source_checkpoint_dat)]} {
        mptdc_o12b_msg "Restoring checkpoint from current checkout: $o12b(source_checkpoint_dat)"
        restoreDesign $o12b(source_checkpoint_dat) mptdc_top_asic
        return
    }
    if {[file exists $o12b(source_restore_tcl)]} {
        mptdc_o12b_msg "Restoring checkpoint from restore script: $o12b(source_restore_tcl)"
        source $o12b(source_restore_tcl)
        return
    }
    mptdc_o12b_fail "missing O12 route checkpoint. Tried $o12b(source_checkpoint_dat) and $o12b(source_restore_tcl)"
}

proc mptdc_o12b_write_timing_summary {} {
    global o12b
    set fh [open "$o12b(reports_dir)/timing_post_route_summary_by_class.md" w]
    puts $fh "# O12B Post-Route Timing Summary By Class"
    puts $fh ""
    puts $fh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $fh ""
    puts $fh "| Class | Report | Notes |"
    puts $fh "|---|---|---|"
    puts $fh "| RO_OSC_DOMAIN | `timing_post_route_ro_osc_domain.rpt` | Review buffered oscillator-domain timing; not signoff. |"
    puts $fh "| CLK_SYS_INTERNAL | `timing_post_route_clk_sys_internal.rpt` | Keep separate from RO phase decision. |"
    puts $fh "| IO_OUTPUT | `timing_post_route_io_output.rpt` | Provisional IO timing only. |"
    puts $fh "| ASYNC_RESET_RECOVERY | `timing_post_route_reset_recovery.rpt` | Recovery/removal reported separately. |"
    puts $fh ""
    puts $fh "Do not let IO or reset/recovery dominate the O12B phase-buffer decision."
    close $fh
}

proc mptdc_o12b_write_summary {} {
    global o12b
    set fh [open "$o12b(reports_dir)/SUMMARY.md" w]
    puts $fh "# O12B Phase Buffer Balance Analysis Summary"
    puts $fh ""
    puts $fh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $fh ""
    puts $fh "- Run ID: `$o12b(run_id)`"
    puts $fh "- Source run: `$o12b(source_run_id)`"
    puts $fh "- Mode: report-only restore of an O12 routed checkpoint."
    puts $fh "- No routing, CTS, RTL, SDC, Liberty, packet, or calibration behavior is modified."
    puts $fh "- Labels: `O12B_PHASE_BUFFER_BALANCE`, `REPORT_ONLY`, `NOT_FINAL_SIGNOFF`."
    puts $fh "- Main decision report: `phase_buffer_balance_summary.md`."
    close $fh
}

proc mptdc_o12b_main {} {
    global o12b
    mptdc_o12b_setup_globals
    mptdc_o12b_stage_mark setup start
    mptdc_o12b_write_manifest
    source "$o12b(script_dir)/innovus_o12b_phase_buffer_reports.tcl"
    mptdc_o12b_stage_mark setup done

    mptdc_o12b_stage_mark restore_checkpoint start
    mptdc_o12b_restore_source_checkpoint
    mptdc_o12b_stage_mark restore_checkpoint done
    mptdc_o12b_stage_mark report_clocks start
    mptdc_o12b_capture_candidates "$o12b(reports_dir)/report_clocks.rpt" \
        "O12B restored checkpoint clocks" [list {report_clocks}]
    mptdc_o12b_stage_mark report_clocks done
    mptdc_o12b_stage_mark drv_max_cap start
    mptdc_o12b_capture_candidates "$o12b(reports_dir)/drv_max_cap.rpt" \
        "O12B restored checkpoint max capacitance" [list \
            {report_constraint -max_capacitance -all_violators} \
            {report_constraint -all_violators}]
    mptdc_o12b_stage_mark drv_max_cap done
    mptdc_o12b_stage_mark drv_max_transition start
    mptdc_o12b_capture_candidates "$o12b(reports_dir)/drv_max_transition.rpt" \
        "O12B restored checkpoint max transition" [list \
            {report_constraint -max_transition -all_violators} \
            {report_constraint -all_violators}]
    mptdc_o12b_stage_mark drv_max_transition done
    mptdc_o12b_stage_mark drv_max_fanout start
    mptdc_o12b_capture_candidates "$o12b(reports_dir)/drv_max_fanout.rpt" \
        "O12B restored checkpoint max fanout" [list \
            {report_constraint -max_fanout -all_violators} \
            {report_constraint -all_violators}]
    mptdc_o12b_stage_mark drv_max_fanout done
    mptdc_o12b_stage_mark timing_ro_osc_domain start
    mptdc_o12b_capture_candidates "$o12b(reports_dir)/timing_post_route_ro_osc_domain.rpt" \
        "O12B RO oscillator-domain timing" [list \
            {report_timing -path_group clk_osc_fast_buf_tap0 -max_paths 100} \
            {report_timing -path_group clk_osc_fast -max_paths 100} \
            {report_timing -max_paths 100}]
    mptdc_o12b_stage_mark timing_ro_osc_domain done
    mptdc_o12b_stage_mark timing_clk_sys start
    mptdc_o12b_capture_candidates "$o12b(reports_dir)/timing_post_route_clk_sys_internal.rpt" \
        "O12B clk_sys internal timing" [list \
            {report_timing -path_group clk_sys -max_paths 100} \
            {report_timing -from [get_clocks clk_sys] -to [get_clocks clk_sys] -max_paths 100} \
            {report_timing -max_paths 100}]
    mptdc_o12b_stage_mark timing_clk_sys done
    mptdc_o12b_stage_mark timing_io_output start
    mptdc_o12b_capture_candidates "$o12b(reports_dir)/timing_post_route_io_output.rpt" \
        "O12B IO output timing" [list \
            {report_timing -to [all_outputs] -max_paths 100} \
            {report_timing -max_paths 100}]
    mptdc_o12b_stage_mark timing_io_output done
    mptdc_o12b_stage_mark timing_reset_recovery start
    mptdc_o12b_capture_candidates "$o12b(reports_dir)/timing_post_route_reset_recovery.rpt" \
        "O12B reset/recovery timing" [list \
            {report_timing -check_type recovery -max_paths 100} \
            {report_timing -check_type removal -max_paths 100} \
            {report_timing -max_paths 100}]
    mptdc_o12b_stage_mark timing_reset_recovery done

    mptdc_o12b_stage_mark phase_buffer_reports start
    if {[catch {mptdc_o12b_write_reports} err]} {
        mptdc_o12b_stage_mark phase_buffer_reports failed
        set efh [open "$o12b(manifests_dir)/phase_buffer_reports_error.txt" w]
        puts $efh "error: $err"
        if {[info exists ::errorInfo]} {
            puts $efh ""
            puts $efh "errorInfo:"
            puts $efh $::errorInfo
        }
        close $efh
        mptdc_o11_write_error_csv "$o12b(reports_dir)/phase_buffer_output_loads.csv" \
            "status,message" $err
        mptdc_o11_write_error_csv "$o12b(reports_dir)/phase_buffer_topology.csv" \
            "status,message" $err
        mptdc_o12b_fail "phase-buffer balance report generation failed: $err"
    }
    mptdc_o12b_stage_mark phase_buffer_reports done
    mptdc_o12b_stage_mark summary start
    mptdc_o12b_write_timing_summary
    mptdc_o12b_write_summary
    mptdc_o12b_stage_mark summary done
    mptdc_o12b_msg "O12B phase-buffer balance analysis complete"
}

if {![info exists ::env(MPTDC_O12B_SOURCE_ONLY)] || !$::env(MPTDC_O12B_SOURCE_ONLY)} {
    mptdc_o12b_main
}
