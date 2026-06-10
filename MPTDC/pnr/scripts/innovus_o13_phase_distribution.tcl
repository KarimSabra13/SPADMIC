# =============================================================================
# O13 phase-distribution report-only entrypoint
#
# Restores a routed O13 checkpoint and generates DB-backed reports for:
#
#   RO_tune4/S[n] -> BUHDX4 u_iso -> BUHDX12 u_drv -> phase fabric
#
# No route, CTS, RTL, Liberty, packet, or calibration behavior is modified by
# this script.  It may apply a documented in-memory provisional IO set_load for
# block-level timing reports.
# =============================================================================

set ::env(MPTDC_O12B_SOURCE_ONLY) 1
source [file join [file dirname [file normalize [info script]]] innovus_o12b_phase_buffer_balance.tcl]

proc mptdc_o13_msg {msg} {
    puts "MPTDC_O13: $msg"
}

proc mptdc_o13_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_o13_setup_globals {} {
    global o13 o12b

    set script_dir [file dirname [file normalize [info script]]]
    set pnr_root   [file dirname $script_dir]
    set mptdc_root [file dirname $pnr_root]
    set repo_root  [file dirname $mptdc_root]
    set work_root [mptdc_o13_env MPTDC_WORK_ROOT "$repo_root/work"]
    if {[file pathtype $work_root] ne "absolute"} {
        set work_root [file normalize [file join $repo_root $work_root]]
    }
    set innovus_work [mptdc_o13_env MPTDC_INNOVUS_WORK [file join $work_root innovus]]

    set o13(script_dir) $script_dir
    set o13(pnr_root) $pnr_root
    set o13(mptdc_root) $mptdc_root
    set o13(repo_root) $repo_root
    set o13(run_id) [mptdc_o13_env MPTDC_O13_RUN_ID 20260608_o13_phase_distribution]
    set o13(source_run_id) [mptdc_o13_env MPTDC_O13_SOURCE_RUN_ID 20260608_o13_phase_distribution_innovus]
    set o13(result_dir) [mptdc_o13_env MPTDC_O13_RESULT_DIR "$innovus_work/$o13(run_id)"]
    set o13(logs_dir) "$o13(result_dir)/logs"
    set o13(reports_dir) "$o13(result_dir)/reports"
    set o13(manifests_dir) "$o13(result_dir)/manifests"
    set o13(work_dir) "$o13(result_dir)/work"
    set o13(source_result_dir) [mptdc_o13_env MPTDC_O13_SOURCE_RESULT_DIR "$innovus_work/$o13(source_run_id)"]
    set o13(source_checkpoint_dat) [mptdc_o13_env MPTDC_O13_SOURCE_CHECKPOINT_DAT "$o13(source_result_dir)/checkpoints/04_route.enc.dat"]
    set o13(source_restore_tcl) [mptdc_o13_env MPTDC_O13_SOURCE_RESTORE_TCL "$o13(source_result_dir)/checkpoints/restore_latest.tcl"]

    foreach key {result_dir logs_dir reports_dir manifests_dir work_dir} {
        file mkdir $o13($key)
    }

    foreach key {script_dir pnr_root mptdc_root repo_root run_id source_run_id result_dir logs_dir reports_dir manifests_dir work_dir source_result_dir source_checkpoint_dat source_restore_tcl} {
        set o12b($key) $o13($key)
    }
}

proc mptdc_o13_write_manifest {} {
    global o13
    set fh [open "$o13(manifests_dir)/run_manifest.txt" w]
    puts $fh "# O13 Phase Distribution"
    puts $fh "date: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh "run_id: $o13(run_id)"
    puts $fh "result_dir: $o13(result_dir)"
    puts $fh "source_run_id: $o13(source_run_id)"
    puts $fh "source_result_dir: $o13(source_result_dir)"
    puts $fh "source_checkpoint_dat: $o13(source_checkpoint_dat)"
    puts $fh "source_restore_tcl: $o13(source_restore_tcl)"
    puts $fh "io_load_class: [mptdc_o13_env MPTDC_PNR_IO_LOAD_CLASS medium]"
    puts $fh "labels: O13_PHASE_DISTRIBUTION_TREE_CLEANUP REPORT_ONLY NOT_FINAL_SIGNOFF"
    close $fh
}

proc mptdc_o13_restore_source_checkpoint {} {
    global o13
    if {[file exists $o13(source_checkpoint_dat)]} {
        mptdc_o13_msg "Restoring checkpoint from current checkout: $o13(source_checkpoint_dat)"
        restoreDesign $o13(source_checkpoint_dat) mptdc_top_asic
        return
    }
    if {[file exists $o13(source_restore_tcl)]} {
        mptdc_o13_msg "Restoring checkpoint from restore script: $o13(source_restore_tcl)"
        source $o13(source_restore_tcl)
        return
    }
    mptdc_o12b_fail "missing O13 route checkpoint. Tried $o13(source_checkpoint_dat) and $o13(source_restore_tcl)"
}

proc mptdc_o13_write_timing_summary {} {
    global o13
    set fh [open "$o13(reports_dir)/timing_post_route_summary_by_class.md" w]
    puts $fh "# O13 Post-Route Timing Summary By Class"
    puts $fh ""
    puts $fh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $fh ""
    puts $fh "| Class | Report | Notes |"
    puts $fh "|---|---|---|"
    puts $fh "| RO_OSC_DOMAIN | `timing_post_route_ro_osc_domain.rpt` | Review final-driver oscillator-domain timing; not signoff. |"
    puts $fh "| CLK_SYS_INTERNAL | `timing_post_route_clk_sys_internal.rpt` | Keep separate from RO phase decision. |"
    puts $fh "| IO_OUTPUT | `timing_post_route_io_output.rpt` | Provisional IO timing only. |"
    puts $fh "| ASYNC_RESET_RECOVERY | `timing_post_route_reset_recovery.rpt` | Recovery/removal reported separately. |"
    puts $fh ""
    puts $fh "Do not let IO or reset/recovery dominate the O13 phase-distribution decision."
    close $fh
}

proc mptdc_o13_apply_io_load_model {} {
    global o13

    set class [mptdc_o13_env MPTDC_PNR_IO_LOAD_CLASS medium]
    if {[llength [info commands mptdc_xlibd_normalize_io_load_class]] > 0} {
        set class [mptdc_xlibd_normalize_io_load_class $class]
    }
    set load_pf ""
    set load_ff ""
    set d_inputs ""
    if {[llength [info commands mptdc_xlibd_io_load_class_value]] > 0} {
        set load_pf [mptdc_xlibd_io_load_class_value $class load_pf]
        set load_ff [mptdc_xlibd_io_load_class_value $class load_ff]
        set d_inputs [mptdc_xlibd_io_load_class_value $class d_inputs]
    }
    if {$load_pf eq ""} {
        set class medium
        set load_pf 0.0256
        set load_ff 25.6
        set d_inputs 8
    }

    set outputs [list]
    set output_names [list]
    set apply_status "NOT_APPLIED"
    set apply_error ""
    if {[catch {set outputs [all_outputs]} apply_error]} {
        set outputs [list]
        set apply_status "FAILED_ALL_OUTPUTS"
    } elseif {[llength $outputs] == 0} {
        set apply_status "FAILED_NO_OUTPUTS"
    } elseif {[catch {set_load $load_pf $outputs} apply_error]} {
        set apply_status "FAILED_SET_LOAD"
    } else {
        set apply_status "APPLIED_TO_ALL_OUTPUTS"
    }
    if {[llength $outputs] > 0 && [llength [info commands mptdc_o11_object_names]] > 0} {
        set output_names [mptdc_o11_object_names $outputs]
    }

    set fh [open "$o13(reports_dir)/io_load_model.rpt" w]
    puts $fh "# O13 XLIBD IO Load Model"
    puts $fh ""
    puts $fh "REPORT_STATUS=PROVISIONAL_BLOCK_IO_MODEL_NOT_PAD_SIGNOFF"
    puts $fh ""
    puts $fh "MPTDC_PNR_IO_LOAD_CLASS=$class"
    puts $fh "DFRRQHDX2_D_INPUTS_EQUIVALENT=$d_inputs"
    puts $fh "OUTPUT_LOAD_PF=$load_pf"
    puts $fh "OUTPUT_LOAD_FF=$load_ff"
    puts $fh "APPLY_STATUS=$apply_status"
    if {$apply_error ne "" && $apply_status ne "APPLIED_TO_ALL_OUTPUTS"} {
        puts $fh "APPLY_ERROR=$apply_error"
    }
    puts $fh ""
    puts $fh "Important outputs to review:"
    foreach pattern {acq_data_o narrow_data_o csr_rdata_o csr_rvalid_o acq_valid_o} {
        puts $fh "- $pattern"
    }
    puts $fh ""
    puts $fh "All outputs matched: [llength $output_names]"
    foreach name [lrange $output_names 0 127] {
        puts $fh "- $name"
    }
    puts $fh ""
    puts $fh "This load model is only for block-level feasibility. It is not pad-level signoff."
    close $fh
}

proc mptdc_o13_write_summary {} {
    global o13
    set fh [open "$o13(reports_dir)/SUMMARY.md" w]
    puts $fh "# O13 Phase Distribution Analysis Summary"
    puts $fh ""
    puts $fh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $fh ""
    puts $fh "- Run ID: `$o13(run_id)`"
    puts $fh "- Source run: `$o13(source_run_id)`"
    puts $fh "- Mode: report-only restore of an O13 routed checkpoint."
    puts $fh "- Expected topology: `RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric`."
    puts $fh "- Provisional IO load report: `io_load_model.rpt`."
    puts $fh "- No routing, CTS, RTL, Liberty, packet, or calibration behavior is modified."
    puts $fh "- IO timing uses the documented in-memory provisional load model from `io_load_model.rpt`."
    puts $fh "- Labels: `O13_PHASE_DISTRIBUTION_TREE_CLEANUP`, `REPORT_ONLY`, `NOT_FINAL_SIGNOFF`."
    puts $fh "- Main decision report: `phase_buffer_balance_summary.md`."
    close $fh
}

proc mptdc_o13_main {} {
    global o13
    mptdc_o13_setup_globals
    mptdc_o12b_stage_mark setup start
    mptdc_o13_write_manifest
    source "$o13(script_dir)/innovus_o13_phase_buffer_reports.tcl"
    mptdc_o12b_stage_mark setup done

    mptdc_o12b_stage_mark restore_checkpoint start
    mptdc_o13_restore_source_checkpoint
    mptdc_o12b_stage_mark restore_checkpoint done

    mptdc_o12b_stage_mark report_clocks start
    mptdc_o12b_capture_candidates "$o13(reports_dir)/report_clocks.rpt" \
        "O13 restored checkpoint clocks" [list {report_clocks}]
    mptdc_o12b_stage_mark report_clocks done

    mptdc_o12b_stage_mark io_load_model start
    mptdc_o13_apply_io_load_model
    mptdc_o12b_stage_mark io_load_model done

    mptdc_o12b_stage_mark drv_max_cap start
    mptdc_o12b_capture_candidates "$o13(reports_dir)/drv_max_cap.rpt" \
        "O13 restored checkpoint max capacitance" [list \
            {report_constraint -max_capacitance -all_violators} \
            {report_constraint -all_violators}]
    mptdc_o12b_stage_mark drv_max_cap done

    mptdc_o12b_stage_mark drv_max_transition start
    mptdc_o12b_capture_candidates "$o13(reports_dir)/drv_max_transition.rpt" \
        "O13 restored checkpoint max transition" [list \
            {report_constraint -max_transition -all_violators} \
            {report_constraint -all_violators}]
    mptdc_o12b_stage_mark drv_max_transition done

    mptdc_o12b_stage_mark drv_max_fanout start
    mptdc_o12b_capture_candidates "$o13(reports_dir)/drv_max_fanout.rpt" \
        "O13 restored checkpoint max fanout" [list \
            {report_constraint -max_fanout -all_violators} \
            {report_constraint -all_violators}]
    mptdc_o12b_stage_mark drv_max_fanout done

    mptdc_o12b_stage_mark timing_ro_osc_domain start
    mptdc_o12b_capture_candidates "$o13(reports_dir)/timing_post_route_ro_osc_domain.rpt" \
        "O13 RO oscillator-domain timing" [list \
            {report_timing -path_group clk_osc_fast_buf_tap0 -max_paths 100} \
            {report_timing -path_group clk_osc_fast -max_paths 100} \
            {report_timing -max_paths 100}]
    mptdc_o12b_stage_mark timing_ro_osc_domain done

    mptdc_o12b_stage_mark timing_clk_sys start
    mptdc_o12b_capture_candidates "$o13(reports_dir)/timing_post_route_clk_sys_internal.rpt" \
        "O13 clk_sys internal timing" [list \
            {report_timing -path_group clk_sys -max_paths 100} \
            {report_timing -from [get_clocks clk_sys] -to [get_clocks clk_sys] -max_paths 100} \
            {report_timing -max_paths 100}]
    mptdc_o12b_stage_mark timing_clk_sys done

    mptdc_o12b_stage_mark timing_io_output start
    mptdc_o12b_capture_candidates "$o13(reports_dir)/timing_post_route_io_output.rpt" \
        "O13 IO output timing" [list \
            {report_timing -to [all_outputs] -max_paths 100} \
            {report_timing -max_paths 100}]
    mptdc_o12b_stage_mark timing_io_output done

    mptdc_o12b_stage_mark timing_reset_recovery start
    mptdc_o12b_capture_candidates "$o13(reports_dir)/timing_post_route_reset_recovery.rpt" \
        "O13 reset/recovery timing" [list \
            {report_timing -check_type recovery -max_paths 100} \
            {report_timing -check_type removal -max_paths 100} \
            {report_timing -max_paths 100}]
    mptdc_o12b_stage_mark timing_reset_recovery done

    mptdc_o12b_stage_mark phase_buffer_reports start
    if {[catch {mptdc_o13_write_reports} err]} {
        mptdc_o12b_stage_mark phase_buffer_reports failed
        set efh [open "$o13(manifests_dir)/phase_buffer_reports_error.txt" w]
        puts $efh "error: $err"
        if {[info exists ::errorInfo]} {
            puts $efh ""
            puts $efh "errorInfo:"
            puts $efh $::errorInfo
        }
        close $efh
        mptdc_o11_write_error_csv "$o13(reports_dir)/phase_buffer_output_loads.csv" \
            "status,message" $err
        mptdc_o11_write_error_csv "$o13(reports_dir)/phase_buffer_topology.csv" \
            "status,message" $err
        mptdc_o12b_fail "O13 phase-distribution report generation failed: $err"
    }
    mptdc_o12b_stage_mark phase_buffer_reports done

    mptdc_o12b_stage_mark summary start
    mptdc_o13_write_timing_summary
    mptdc_o13_write_summary
    mptdc_o12b_stage_mark summary done
    mptdc_o13_msg "O13 phase-distribution analysis complete"
}

if {![info exists ::env(MPTDC_O13_SOURCE_ONLY)] || !$::env(MPTDC_O13_SOURCE_ONLY)} {
    mptdc_o13_main
}
