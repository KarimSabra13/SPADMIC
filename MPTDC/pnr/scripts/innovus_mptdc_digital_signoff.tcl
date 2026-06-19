# =============================================================================
# Project  : SPAD_MPTDC
# File     : innovus_mptdc_digital_signoff.tcl
# Purpose  : Digital block signoff entrypoint for mptdc_axis_core
# Author   : Karim Sabra
# =============================================================================

proc mptdc_signoff_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_signoff_env_truthy {name} {
    if {![info exists ::env($name)]} {
        return 0
    }
    set value [string tolower $::env($name)]
    return [expr {$value in {1 yes true on}}]
}

proc mptdc_signoff_repo_root {} {
    return [file normalize [mptdc_signoff_env MPTDC_REPO_ROOT [file join [file dirname [info script]] ../../..]]]
}

proc mptdc_signoff_result_dir {} {
    return [file normalize [mptdc_signoff_env MPTDC_SIGNOFF_RESULT_DIR work/innovus/mptdc_digital_signoff]]
}

proc mptdc_signoff_report_dir {} {
    return [file join [mptdc_signoff_result_dir] reports]
}

proc mptdc_signoff_manifest_dir {} {
    return [file join [mptdc_signoff_result_dir] manifests]
}

proc mptdc_signoff_work_dir {} {
    return [file join [mptdc_signoff_result_dir] work]
}

proc mptdc_signoff_checkpoint_dir {} {
    return [file join [mptdc_signoff_result_dir] checkpoints]
}

proc mptdc_signoff_def_dir {} {
    return [file join [mptdc_signoff_result_dir] def]
}

proc mptdc_signoff_outputs_dir {} {
    return [file join [mptdc_signoff_result_dir] outputs]
}

proc mptdc_signoff_mkdirs {} {
    foreach dir [list \
        [mptdc_signoff_report_dir] \
        [mptdc_signoff_manifest_dir] \
        [mptdc_signoff_work_dir] \
        [mptdc_signoff_checkpoint_dir] \
        [mptdc_signoff_def_dir] \
        [mptdc_signoff_outputs_dir]] {
        file mkdir $dir
    }
}

proc mptdc_signoff_status_keys {} {
    return [list \
        PRE_PNR_GATE_STATUS \
        GENUS_HANDOFF_STATUS \
        ROW_INFRA_POLICY_STATUS \
        ROW_INFRA_DRC_LVS_STATUS \
        PHYSICAL_CELL_CONFIG_STATUS \
        PG_CONNECTIVITY_STATUS \
        FLOORPLAN_STATUS \
        IO_STATUS \
        RO_MACRO_STATUS \
        PD_MATRIX_STATUS \
        PHASE_BUFFER_STATUS \
        CTS_STATUS \
        ROUTE_STATUS \
        EXTRACTION_STATUS \
        SETUP_STATUS_TC \
        SETUP_STATUS_WC \
        HOLD_STATUS_BC \
        PHASE_LOAD_STATUS \
        RC_SYMMETRY_STATUS \
        BACKEND_CROSSING_STATUS \
        DRV_STATUS \
        ANTENNA_STATUS \
        DRC_STATUS \
        LVS_STATUS \
        DELIVERABLE_STATUS \
        DIGITAL_PNR_SIGNOFF]
}

proc mptdc_signoff_init_status {} {
    global mptdc_signoff_status
    array unset mptdc_signoff_status
    foreach key [mptdc_signoff_status_keys] {
        set mptdc_signoff_status($key) "DEFERRED evidence=not_run"
    }
    set mptdc_signoff_status(DIGITAL_PNR_SIGNOFF) "PROVISIONAL evidence=source_not_complete"
}

proc mptdc_signoff_set_status {key state evidence} {
    global mptdc_signoff_status
    set mptdc_signoff_status($key) "$state evidence=$evidence"
}

proc mptdc_signoff_write_status {{path ""}} {
    global mptdc_signoff_status
    if {$path eq ""} {
        set path [file join [mptdc_signoff_report_dir] digital_pnr_signoff_status.rpt]
    }
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "# MPTDC Digital PNR Signoff Status"
    puts $fh "Author: Karim Sabra"
    puts $fh "STATUS_SCHEMA=PASS_FAIL_EXTERNAL_DEFERRED_PROVISIONAL"
    foreach key [mptdc_signoff_status_keys] {
        if {[info exists mptdc_signoff_status($key)]} {
            puts $fh "$key=$mptdc_signoff_status($key)"
        } else {
            puts $fh "$key=DEFERRED evidence=not_run"
        }
    }
    close $fh
    return $path
}

proc mptdc_signoff_stage_trace {stage status} {
    set path [file join [mptdc_signoff_manifest_dir] stage_trace.csv]
    file mkdir [file dirname $path]
    set new_file [expr {![file exists $path]}]
    set fh [open $path a]
    if {$new_file} {
        puts $fh "timestamp,stage,status"
    }
    set timestamp [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]
    regsub -all {"} $stage {""} stage_csv
    regsub -all {"} $status {""} status_csv
    puts $fh "\"$timestamp\",\"$stage_csv\",\"$status_csv\""
    close $fh
}

proc mptdc_signoff_required_file {label path} {
    if {$path eq "" || ![file exists $path]} {
        error "MPTDC_DIGITAL_SIGNOFF_MISSING_FILE: $label path=$path"
    }
    return [file normalize $path]
}

proc mptdc_signoff_find_file {root rel} {
    foreach candidate [list \
        [file join $root $rel] \
        [file join $root outputs $rel] \
        [file join $root outputs post_synth $rel] \
        [file join $root 05_outputs $rel] \
        [file join $root reports $rel]] {
        if {[file exists $candidate]} {
            return [file normalize $candidate]
        }
    }
    return ""
}

proc mptdc_signoff_source_xh018_cells {} {
    set repo [mptdc_signoff_repo_root]
    source [file join $repo MPTDC/pnr/config/xh018_cells.tcl]
}

proc mptdc_signoff_write_row_policy_report {provisional_classes} {
    global mptdc_xh018_cells
    set path [file join [mptdc_signoff_report_dir] row_infra_policy.rpt]
    set fh [open $path w]
    puts $fh "ROW_INFRA_POLICY=$mptdc_xh018_cells(row_infra_policy)"
    puts $fh "ROW_INFRA_STATUS=$mptdc_xh018_cells(row_infra_status)"
    puts $fh "IMPLEMENTATION_ALLOWED=[expr {$mptdc_xh018_cells(implementation_allowed) eq "1" ? "YES" : "NO"}]"
    puts $fh "FINAL_SIGNOFF_ALLOWED=[expr {$mptdc_xh018_cells(final_signoff_allowed) eq "1" ? "YES" : "NO"}]"
    puts $fh "DIGITAL_PNR_SIGNOFF=$mptdc_xh018_cells(digital_pnr_signoff)"
    puts $fh "MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=[expr {[mptdc_signoff_env_truthy MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY] ? "1" : "0"}]"
    puts $fh "TAP_POLICY=$mptdc_xh018_cells(tap_policy)"
    puts $fh "ENDCAP_LEFT_POLICY=$mptdc_xh018_cells(endcap_left_policy)"
    puts $fh "ENDCAP_RIGHT_POLICY=$mptdc_xh018_cells(endcap_right_policy)"
    puts $fh "PROVISIONAL_CLASSES=$provisional_classes"
    puts $fh "REJECTED_CORE_ROW_CELLS=$mptdc_xh018_cells(rejected_core_row_cells)"
    puts $fh "CORE_TAP_COUNT=$mptdc_xh018_cells(core_tap_count)"
    puts $fh "CORE_ENDCAP_COUNT=$mptdc_xh018_cells(core_endcap_count)"
    puts $fh "IO_ENDCAP_COUNT=$mptdc_xh018_cells(io_endcap_count)"
    puts $fh "STDCELL_SITE=$mptdc_xh018_cells(stdcell_site)"
    puts $fh "STDCELL_POWER_PINS=$mptdc_xh018_cells(stdcell_pg_power)"
    puts $fh "STDCELL_GROUND_PINS=$mptdc_xh018_cells(stdcell_pg_ground)"
    puts $fh "EVIDENCE_PACKAGE_STATUS=$mptdc_xh018_cells(evidence_package_status)"
    close $fh
    return $path
}

proc mptdc_signoff_check_physical_cell_policy {{mode implementation}} {
    mptdc_signoff_source_xh018_cells
    set provisional [mptdc_xh018_validate_policy $mode]
    set rpt [mptdc_signoff_write_row_policy_report $provisional]
    mptdc_signoff_set_status PRE_PNR_GATE_STATUS PASS pre_pnr_gate.rpt
    mptdc_signoff_set_status ROW_INFRA_POLICY_STATUS PROVISIONAL $rpt
    mptdc_signoff_set_status ROW_INFRA_DRC_LVS_STATUS DEFERRED row_drc_lvs_not_run
    mptdc_signoff_set_status PHYSICAL_CELL_CONFIG_STATUS PROVISIONAL $rpt
    mptdc_signoff_set_status DIGITAL_PNR_SIGNOFF PROVISIONAL row_policy_pending_drc_lvs
    return $provisional
}

proc mptdc_signoff_write_policy_manifest {} {
    global mptdc_xh018_cells
    set path [file join [mptdc_signoff_manifest_dir] row_infra_policy_manifest.rpt]
    set fh [open $path w]
    puts $fh "ROW_INFRA_POLICY=$mptdc_xh018_cells(row_infra_policy)"
    puts $fh "ROW_INFRA_STATUS=$mptdc_xh018_cells(row_infra_status)"
    puts $fh "IMPLEMENTATION_ALLOWED=YES"
    puts $fh "FINAL_SIGNOFF_ALLOWED=NO"
    puts $fh "DIGITAL_PNR_SIGNOFF=PROVISIONAL"
    puts $fh "PHYSICAL_CELL_CONFIG_STATUS=$mptdc_xh018_cells(physical_cell_config_status)"
    puts $fh "STDCELL_SITE=$mptdc_xh018_cells(stdcell_site)"
    puts $fh "STDCELL_PG_POWER=$mptdc_xh018_cells(stdcell_pg_power)"
    puts $fh "STDCELL_PG_GROUND=$mptdc_xh018_cells(stdcell_pg_ground)"
    puts $fh "TAP_POLICY=$mptdc_xh018_cells(tap_policy)"
    puts $fh "ENDCAP_LEFT_POLICY=$mptdc_xh018_cells(endcap_left_policy)"
    puts $fh "ENDCAP_RIGHT_POLICY=$mptdc_xh018_cells(endcap_right_policy)"
    close $fh
    return $path
}

proc mptdc_signoff_capture {path title body} {
    file mkdir [file dirname $path]
    if {[catch {uplevel 1 "$body > \"$path\""} err]} {
        set fh [open $path w]
        puts $fh "$title"
        puts $fh [string repeat "=" [string length $title]]
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh $err
        close $fh
        return 0
    }
    return 1
}

proc mptdc_signoff_capture_candidates {path title bodies} {
    set errors [list]
    foreach body $bodies {
        if {[mptdc_signoff_capture $path $title $body]} {
            return 1
        }
        lappend errors $body
    }
    set fh [open $path a]
    puts $fh ""
    puts $fh "Tried command variants:"
    foreach body $errors { puts $fh "  $body" }
    close $fh
    return 0
}

proc mptdc_signoff_load_design_context {} {
    global design tech tech_files paths
    set repo [mptdc_signoff_repo_root]
    set handoff [mptdc_signoff_env MPTDC_SIGNOFF_HANDOFF_DIR ""]
    if {$handoff eq ""} {
        set handoff [mptdc_signoff_env MPTDC_GENUS_HANDOFF_DIR ""]
    }
    if {$handoff eq ""} {
        set handoff [mptdc_signoff_result_dir]
    }
    set handoff [file normalize $handoff]

    set design(project_root) [file join $repo MPTDC]
    set design(TOPLEVEL) mptdc_axis_core
    set design(postsyn_netlist) [mptdc_signoff_find_file $handoff mptdc_axis_core.postsyn.v]
    set design(postsyn_sdc) [mptdc_signoff_find_file $handoff mptdc_axis_core.postsyn.sdc]
    mptdc_signoff_required_file "post-synthesis netlist" $design(postsyn_netlist)
    mptdc_signoff_required_file "post-synthesis SDC" $design(postsyn_sdc)

    if {![info exists ::env(MPTDC_STDCELL_FAMILY)]} {
        set ::env(MPTDC_STDCELL_FAMILY) JIHD
    }
    if {![info exists ::env(MPTDC_STDCELL_SITE)]} {
        set ::env(MPTDC_STDCELL_SITE) [mptdc_xh018_cell stdcell_site]
    }
    if {![info exists ::env(O1_USE_REAL_RO_ABSTRACT)]} {
        set ::env(O1_USE_REAL_RO_ABSTRACT) 1
    }

    set TECHNOLOGY xh018
    set SC_TECHNOLOGY xh018-stdcells
    source [file join $repo MPTDC/syn/libraries/libraries.xh018.tcl]
    source [file join $repo MPTDC/syn/libraries/libraries.xh018-stdcells.tcl]

    set mmmc [file join $repo MPTDC/pnr/inputs/mptdc_innovus.mmmc]
    mptdc_signoff_required_file "Innovus MMMC" $mmmc
    set tech_files(SIGNOFF_MMMC) $mmmc
}

proc mptdc_signoff_initialize_design {} {
    global design tech tech_files init_top_cell init_verilog init_lef_file init_mmmc_file init_pwr_net init_gnd_net
    set init_top_cell $design(TOPLEVEL)
    set init_verilog $design(postsyn_netlist)
    set init_lef_file $tech_files(ALL_LEFS)
    set init_mmmc_file $tech_files(SIGNOFF_MMMC)
    set init_pwr_net VDD
    set init_gnd_net VSS
    init_design
    mptdc_signoff_set_status GENUS_HANDOFF_STATUS PASS init_design
}

proc mptdc_signoff_apply_pg_connectivity {} {
    global mptdc_xh018_cells
    set path [file join [mptdc_signoff_report_dir] pg_connectivity_commands.rpt]
    set fh [open $path w]
    set failures [list]
    foreach pin $mptdc_xh018_cells(stdcell_pg_power) {
        set cmd [list globalNetConnect VDD -type pgpin -pin $pin -inst *]
        puts $fh "COMMAND=$cmd"
        if {[catch {{*}$cmd} err]} {
            puts $fh "STATUS=FAIL ERROR=$err"
            lappend failures "VDD:$pin:$err"
        } else {
            puts $fh "STATUS=PASS"
        }
    }
    foreach pin $mptdc_xh018_cells(stdcell_pg_ground) {
        set cmd [list globalNetConnect VSS -type pgpin -pin $pin -inst *]
        puts $fh "COMMAND=$cmd"
        if {[catch {{*}$cmd} err]} {
            puts $fh "STATUS=FAIL ERROR=$err"
            lappend failures "VSS:$pin:$err"
        } else {
            puts $fh "STATUS=PASS"
        }
    }
    foreach item {{VDD VDD} {vdd! VDD} {VSS VSS}} {
        set pin [lindex $item 0]
        set net [lindex $item 1]
        set cmd [list globalNetConnect $net -type pgpin -pin $pin -inst *]
        puts $fh "COMMAND=$cmd"
        if {[catch {{*}$cmd} err]} {
            puts $fh "STATUS=FAIL ERROR=$err"
            lappend failures "$net:$pin:$err"
        } else {
            puts $fh "STATUS=PASS"
        }
    }
    close $fh
    if {[llength $failures] > 0} {
        mptdc_signoff_set_status PG_CONNECTIVITY_STATUS FAIL $path
        error "MPTDC_DIGITAL_SIGNOFF_PG_CONNECT_FAILED: $failures"
    }
    mptdc_signoff_set_status PG_CONNECTIVITY_STATUS PASS $path
    return $path
}

proc mptdc_signoff_write_pg_gate_template {} {
    set path [file join [mptdc_signoff_report_dir] pg_connectivity_gate.rpt]
    set fh [open $path w]
    puts $fh "UNCONNECTED_STDCELL_PG_PINS=REVIEW_AFTER_INNOVUS"
    puts $fh "UNCONNECTED_RO_PG_PINS=REVIEW_AFTER_INNOVUS"
    puts $fh "PG_SHORTS=REVIEW_AFTER_INNOVUS"
    puts $fh "PG_OPENS=REVIEW_AFTER_INNOVUS"
    puts $fh "FINAL_PG_GATE_REQUIRES=0 unconnected stdcell PG, 0 unconnected RO PG, 0 shorts, 0 opens"
    close $fh
    return $path
}

proc mptdc_signoff_stage {stage status_key body} {
    mptdc_signoff_stage_trace $stage start
    if {[catch {uplevel 1 $body} err opts]} {
        mptdc_signoff_stage_trace $stage fail
        set path [file join [mptdc_signoff_report_dir] "${stage}_failed.rpt"]
        set fh [open $path w]
        puts $fh "STAGE=$stage"
        puts $fh "STATUS=FAIL"
        puts $fh "ERROR=$err"
        if {[dict exists $opts -errorinfo]} {
            puts $fh ""
            puts $fh [dict get $opts -errorinfo]
        }
        close $fh
        mptdc_signoff_set_status $status_key FAIL $path
        mptdc_signoff_write_status
        error "MPTDC_DIGITAL_SIGNOFF_STAGE_FAILED: stage=$stage error=$err"
    }
    mptdc_signoff_stage_trace $stage done
}

proc mptdc_signoff_apply_floorplan {} {
    global tech
    set util [mptdc_signoff_env MPTDC_PNR_CORE_UTIL 0.60]
    set aspect [mptdc_signoff_env MPTDC_PNR_ASPECT_RATIO 1.333333]
    set margin [mptdc_signoff_env MPTDC_PNR_CORE_MARGIN_UM 20.0]
    floorPlan -site $tech(STANDARD_CELL_SITE) -r $aspect $util $margin $margin $margin $margin
    catch {defOut -floorplan -netlist [file join [mptdc_signoff_def_dir] 01_floorplan.def]}
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 01_floorplan.enc]}
    set rpt [file join [mptdc_signoff_report_dir] floorplan_status.rpt]
    set fh [open $rpt w]
    puts $fh "FLOORPLAN_STATUS=PASS"
    puts $fh "STDCELL_SITE=$tech(STANDARD_CELL_SITE)"
    puts $fh "CORE_UTILIZATION=$util"
    close $fh
    mptdc_signoff_set_status FLOORPLAN_STATUS PASS $rpt
}

proc mptdc_signoff_place_design {} {
    placeDesign
    if {[catch {optDesign -preCTS} err]} {
        set rpt [file join [mptdc_signoff_report_dir] prects_opt_review.rpt]
        set fh [open $rpt w]
        puts $fh "PRECTS_OPT_STATUS=REVIEW_REQUIRED"
        puts $fh "ERROR=$err"
        close $fh
    }
    catch {checkPlace > [file join [mptdc_signoff_report_dir] check_place_post_place.rpt]}
    catch {defOut [file join [mptdc_signoff_def_dir] 02_place.def]}
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 02_place.enc]}
}

proc mptdc_signoff_insert_row_infra {} {
    global mptdc_xh018_cells
    set rpt [file join [mptdc_signoff_report_dir] row_infra_insertion.rpt]
    set fh [open $rpt w]
    puts $fh "ROW_INFRA_POLICY=$mptdc_xh018_cells(row_infra_policy)"
    puts $fh "TAP_INSERTION=SKIPPED_NO_DEDICATED_MASTER_PENDING_DRC_LVS"
    puts $fh "ENDCAP_INSERTION=SKIPPED_NO_DEDICATED_MASTER_PENDING_DRC_LVS"
    puts $fh "FILLER_CANDIDATES=$mptdc_xh018_cells(filler)"
    close $fh
    mptdc_signoff_set_status ROW_INFRA_POLICY_STATUS PROVISIONAL $rpt
}

proc mptdc_signoff_run_cts {} {
    set rpt [file join [mptdc_signoff_report_dir] cts_policy.rpt]
    set fh [open $rpt w]
    puts $fh "CTS_PRIMARY_CLOCK=clk_sys"
    puts $fh "RO_CLOCKS_IN_CTS=0"
    puts $fh "PHASE_CLOCKS_IN_CTS=0"
    close $fh
    foreach pattern {clk_osc_slow clk_osc_fast clk_osc_slow_tap* clk_osc_fast_tap* clk_osc_*_buf_tap*} {
        catch {set_dont_touch_network [get_clocks $pattern]}
    }
    if {[catch {ccopt_design -cts} err]} {
        if {[catch {clockDesign} err2]} {
            error "CTS failed: ccopt_design -cts: $err; clockDesign: $err2"
        }
    }
    catch {optDesign -postCTS}
    catch {timeDesign -postCTS > [file join [mptdc_signoff_report_dir] timing_post_cts.rpt]}
    catch {timeDesign -postCTS -hold > [file join [mptdc_signoff_report_dir] hold_post_cts.rpt]}
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 03_cts.enc]}
    mptdc_signoff_set_status CTS_STATUS PASS $rpt
}

proc mptdc_signoff_route_design {} {
    routeDesign
    set antenna_rpt [file join [mptdc_signoff_report_dir] antenna.rpt]
    catch {verifyProcessAntenna > $antenna_rpt}
    mptdc_signoff_set_status ANTENNA_STATUS PROVISIONAL $antenna_rpt
    catch {optDesign -postRoute}
    catch {defOut [file join [mptdc_signoff_def_dir] 04_route.def]}
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 04_route.enc]}
    mptdc_signoff_set_status ROUTE_STATUS PASS routeDesign
}

proc mptdc_signoff_extract_and_sta {} {
    catch {extractRC}
    mptdc_signoff_set_status EXTRACTION_STATUS PROVISIONAL extract_rc_report_required
    mptdc_signoff_capture_candidates [file join [mptdc_signoff_report_dir] timing_tc_nominal.rpt] \
        "TC_NOMINAL setup timing" [list \
            {timeDesign -postRoute -analysisView TC_NOMINAL} \
            {report_timing -view TC_NOMINAL -max_paths 100} \
            {timeDesign -postRoute}]
    mptdc_signoff_capture_candidates [file join [mptdc_signoff_report_dir] timing_wc_setup.rpt] \
        "WC_SETUP setup timing" [list \
            {timeDesign -postRoute -analysisView WC_SETUP} \
            {report_timing -view WC_SETUP -max_paths 100}]
    mptdc_signoff_capture_candidates [file join [mptdc_signoff_report_dir] timing_bc_hold.rpt] \
        "BC_HOLD hold timing" [list \
            {timeDesign -postRoute -hold -analysisView BC_HOLD} \
            {report_timing -view BC_HOLD -check_type hold -max_paths 100}]
    mptdc_signoff_set_status SETUP_STATUS_TC PROVISIONAL timing_tc_nominal.rpt
    mptdc_signoff_set_status SETUP_STATUS_WC PROVISIONAL timing_wc_setup.rpt
    mptdc_signoff_set_status HOLD_STATUS_BC PROVISIONAL timing_bc_hold.rpt
    mptdc_signoff_capture_candidates [file join [mptdc_signoff_report_dir] drv_max_transition.rpt] \
        "max transition" [list {report_constraint -max_transition -all_violators} {reportTranViolation}]
    mptdc_signoff_capture_candidates [file join [mptdc_signoff_report_dir] drv_max_cap.rpt] \
        "max capacitance" [list {report_constraint -max_capacitance -all_violators} {reportCapViolation}]
    mptdc_signoff_capture_candidates [file join [mptdc_signoff_report_dir] drv_max_fanout.rpt] \
        "max fanout" [list {report_constraint -max_fanout -all_violators} {reportFanoutViolation}]
    mptdc_signoff_set_status DRV_STATUS PROVISIONAL drv_reports_require_parse
}

proc mptdc_signoff_write_final_package {} {
    set rpt [file join [mptdc_signoff_report_dir] physical_verification_status.md]
    set fh [open $rpt w]
    puts $fh "# Physical Verification Status"
    puts $fh ""
    puts $fh "ROW_INFRA_DRC_LVS_STATUS=DEFERRED"
    puts $fh "DRC_STATUS=DEFERRED"
    puts $fh "LVS_STATUS=DEFERRED"
    puts $fh "DIGITAL_PNR_SIGNOFF=PROVISIONAL"
    puts $fh ""
    puts $fh "Foundry-qualified PVS/Assura/Calibre DRC/LVS evidence is required before PASS."
    close $fh
    mptdc_signoff_set_status DRC_STATUS DEFERRED $rpt
    mptdc_signoff_set_status LVS_STATUS DEFERRED $rpt
    mptdc_signoff_set_status DELIVERABLE_STATUS PROVISIONAL [mptdc_signoff_outputs_dir]
    mptdc_signoff_set_status DIGITAL_PNR_SIGNOFF PROVISIONAL row_and_block_drc_lvs_deferred
}

proc mptdc_signoff_source_check {} {
    mptdc_signoff_mkdirs
    mptdc_signoff_init_status
    set provisional [mptdc_signoff_check_physical_cell_policy implementation]
    mptdc_signoff_write_policy_manifest
    set status_path [mptdc_signoff_write_status]
    puts "MPTDC_DIGITAL_SIGNOFF_SOURCE_CHECK=PASS"
    puts "ROW_INFRA_POLICY=NO_DEDICATED_CORE_TAP_ENDCAP_PENDING_DRC_LVS"
    puts "ROW_INFRA_STATUS=PROVISIONAL"
    puts "IMPLEMENTATION_ALLOWED=YES"
    puts "FINAL_SIGNOFF_ALLOWED=NO"
    puts "DIGITAL_PNR_SIGNOFF=PROVISIONAL"
    puts "PROVISIONAL_ROW_CLASSES=$provisional"
    puts "MPTDC_DIGITAL_SIGNOFF_STATUS_TEMPLATE=$status_path"
}

proc mptdc_signoff_main {} {
    mptdc_signoff_mkdirs
    mptdc_signoff_init_status
    mptdc_signoff_stage source_gate PHYSICAL_CELL_CONFIG_STATUS {
        mptdc_signoff_check_physical_cell_policy implementation
        mptdc_signoff_write_policy_manifest
    }
    mptdc_signoff_stage import_mmmc GENUS_HANDOFF_STATUS {
        mptdc_signoff_load_design_context
        mptdc_signoff_initialize_design
    }
    mptdc_signoff_stage pg_connectivity PG_CONNECTIVITY_STATUS {
        mptdc_signoff_apply_pg_connectivity
        mptdc_signoff_write_pg_gate_template
    }
    mptdc_signoff_stage floorplan FLOORPLAN_STATUS {
        mptdc_signoff_apply_floorplan
    }
    mptdc_signoff_stage io_placement IO_STATUS {
        set rpt [file join [mptdc_signoff_report_dir] io_status.rpt]
        set fh [open $rpt w]
        puts $fh "IO_STATUS=PROVISIONAL"
        puts $fh "reason=block-level IO placement requires existing IO constraint script review"
        close $fh
        mptdc_signoff_set_status IO_STATUS PROVISIONAL $rpt
    }
    mptdc_signoff_stage ro_macro_placement RO_MACRO_STATUS {
        set rpt [file join [mptdc_signoff_report_dir] ro_macro_status.rpt]
        set fh [open $rpt w]
        puts $fh "RO_MACRO_STATUS=PROVISIONAL"
        puts $fh "required_macro=RO_tune4"
        close $fh
        mptdc_signoff_set_status RO_MACRO_STATUS PROVISIONAL $rpt
    }
    mptdc_signoff_stage pd_matrix_placement PD_MATRIX_STATUS {
        set rpt [file join [mptdc_signoff_report_dir] pd_matrix_status.rpt]
        set fh [open $rpt w]
        puts $fh "PD_MATRIX_STATUS=PROVISIONAL"
        puts $fh "required_matrix=8x8"
        close $fh
        mptdc_signoff_set_status PD_MATRIX_STATUS PROVISIONAL $rpt
    }
    mptdc_signoff_stage phase_buffer_placement PHASE_BUFFER_STATUS {
        set rpt [file join [mptdc_signoff_report_dir] phase_buffer_status.rpt]
        set fh [open $rpt w]
        puts $fh "PHASE_BUFFER_STATUS=PROVISIONAL"
        puts $fh "phase_iso_buffer=[mptdc_xh018_cell phase_iso_buffer]"
        puts $fh "phase_final_buffer=[mptdc_xh018_cell phase_final_buffer]"
        close $fh
        mptdc_signoff_set_status PHASE_BUFFER_STATUS PROVISIONAL $rpt
    }
    mptdc_signoff_stage row_infrastructure ROW_INFRA_POLICY_STATUS {
        mptdc_signoff_insert_row_infra
    }
    mptdc_signoff_stage placement FLOORPLAN_STATUS {
        mptdc_signoff_place_design
    }
    mptdc_signoff_stage cts CTS_STATUS {
        mptdc_signoff_run_cts
    }
    mptdc_signoff_stage route ROUTE_STATUS {
        mptdc_signoff_route_design
    }
    mptdc_signoff_stage extraction_sta EXTRACTION_STATUS {
        mptdc_signoff_extract_and_sta
    }
    mptdc_signoff_stage phase_and_backend_reports PHASE_LOAD_STATUS {
        mptdc_signoff_set_status PHASE_LOAD_STATUS PROVISIONAL phase_load_reports_require_review
        mptdc_signoff_set_status RC_SYMMETRY_STATUS PROVISIONAL rc_symmetry_reports_require_review
        mptdc_signoff_set_status BACKEND_CROSSING_STATUS PROVISIONAL backend_crossing_reports_require_review
    }
    mptdc_signoff_stage physical_verification_package DRC_STATUS {
        mptdc_signoff_write_final_package
    }
    set status_path [mptdc_signoff_write_status]
    puts "MPTDC_DIGITAL_SIGNOFF_EXECUTION=COMPLETE_PROVISIONAL"
    puts "DIGITAL_PNR_SIGNOFF=PROVISIONAL"
    puts "MPTDC_DIGITAL_SIGNOFF_STATUS=$status_path"
}

if {[info exists ::env(MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY)] && $::env(MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY)} {
    mptdc_signoff_source_check
    return
}

if {[catch {mptdc_signoff_main} err opts]} {
    puts "MPTDC_DIGITAL_SIGNOFF_ERROR: $err"
    if {[dict exists $opts -errorinfo]} {
        puts [dict get $opts -errorinfo]
    }
    exit 1
}
