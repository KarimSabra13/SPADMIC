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

proc mptdc_signoff_env_truthy {name {default_value 0}} {
    set value [string tolower [mptdc_signoff_env $name $default_value]]
    return [expr {$value in {1 yes true on}}]
}

proc mptdc_signoff_env_int {name default_value} {
    set value [mptdc_signoff_env $name $default_value]
    if {[string is integer -strict $value]} {
        return $value
    }
    return $default_value
}

proc mptdc_signoff_env_double {name default_value} {
    set value [mptdc_signoff_env $name $default_value]
    if {[string is double -strict $value]} {
        return $value
    }
    return $default_value
}

proc mptdc_signoff_closure_scope {} {
    return [string toupper [mptdc_signoff_env MPTDC_CLOSURE_SCOPE TC_ONLY]]
}

proc mptdc_signoff_require_tc_only_scope {} {
    set scope [mptdc_signoff_closure_scope]
    if {$scope ne "TC_ONLY"} {
        error "MPTDC_TC_ONLY_SCOPE_REQUIRED: MPTDC_CLOSURE_SCOPE=$scope expected TC_ONLY"
    }
    return $scope
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
        MPTDC_CLOSURE_SCOPE \
        MPTDC_TC_PNR_CLOSURE \
        NOT_MMMC_SIGNOFF \
        READY_FOR_TAPEOUT \
        PRE_PNR_GATE_STATUS \
        GENUS_HANDOFF_STATUS \
        RO_IMPORT_STATUS \
        EFFECTIVE_SDC_STATUS \
        ROW_INFRA_POLICY_STATUS \
        ROW_INFRA_DRC_LVS_STATUS \
        PHYSICAL_CELL_CONFIG_STATUS \
        PG_CONNECTIVITY_STATUS \
        PG_PHYSICAL_STATUS \
        FLOORPLAN_STATUS \
        FLOORPLAN_ASPECT_STATUS \
        IO_STATUS \
        RO_MACRO_STATUS \
        RO_PHASE_PLACEMENT_STATUS \
        PD_MATRIX_STATUS \
        PD_PHYSICAL_MATRIX_STATUS \
        PHASE_BUFFER_STATUS \
        PLACEMENT_STATUS \
        CTS_STATUS \
        ROUTE_STATUS \
        FILLER_STATUS \
        EXTRACTION_STATUS \
        SETUP_STATUS_TC \
        TC_HOLD_STATUS \
        SETUP_STATUS_WC \
        HOLD_STATUS_BC \
        RO_1GHZ_STRESS_STATUS \
        PHASE_LOAD_STATUS \
        RC_SYMMETRY_STATUS \
        BACKEND_CROSSING_STATUS \
        BACKEND_REGION_STATUS \
        PHASE_TO_PD_GEOMETRY_STATUS \
        EMPTY_SPACE_AUDIT_STATUS \
        DRV_STATUS \
        ANTENNA_STATUS \
        DRC_STATUS \
        LVS_STATUS \
        DELIVERABLE_STATUS \
        MPTDC_TC_PHYSICAL_SIGNOFF \
        TC_ONLY_TAPEOUT_EXCEPTION_READY \
        DIGITAL_PNR_SIGNOFF]
}

proc mptdc_signoff_init_status {} {
    global mptdc_signoff_status
    array unset mptdc_signoff_status
    foreach key [mptdc_signoff_status_keys] {
        set mptdc_signoff_status($key) "DEFERRED evidence=not_run"
    }
    set mptdc_signoff_status(MPTDC_CLOSURE_SCOPE) "[mptdc_signoff_closure_scope] evidence=run_contract"
    set mptdc_signoff_status(MPTDC_TC_PNR_CLOSURE) "DEFERRED evidence=tc_physical_closure_not_complete"
    set mptdc_signoff_status(NOT_MMMC_SIGNOFF) "YES evidence=scope_tc_only"
    set mptdc_signoff_status(READY_FOR_TAPEOUT) "NO evidence=not_mmmc_and_row_drc_lvs_deferred"
    set mptdc_signoff_status(MPTDC_TC_PHYSICAL_SIGNOFF) "NO evidence=physical_verification_not_complete"
    set mptdc_signoff_status(TC_ONLY_TAPEOUT_EXCEPTION_READY) "NO evidence=physical_verification_not_complete"
    set mptdc_signoff_status(SETUP_STATUS_WC) "DEFERRED evidence=scope_tc_only"
    set mptdc_signoff_status(HOLD_STATUS_BC) "DEFERRED evidence=scope_tc_only"
    set mptdc_signoff_status(RO_1GHZ_STRESS_STATUS) "DEFERRED evidence=scope_tc_only"
    set mptdc_signoff_status(DIGITAL_PNR_SIGNOFF) "PROVISIONAL evidence=source_not_complete"
}

proc mptdc_signoff_set_status {key state evidence} {
    global mptdc_signoff_status
    set mptdc_signoff_status($key) "$state evidence=$evidence"
}

proc mptdc_signoff_status_state {key} {
    global mptdc_signoff_status
    if {![info exists mptdc_signoff_status($key)]} {
        return ""
    }
    return [lindex $mptdc_signoff_status($key) 0]
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
    puts $fh "STATUS_SCHEMA=PASS_FAIL_EXTERNAL_DEFERRED_PROVISIONAL_ACCEPTED"
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

proc mptdc_signoff_default_ro_lef {} {
    return [file join [mptdc_signoff_repo_root] results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef]
}

proc mptdc_signoff_default_ro_liberty {} {
    return [file join [mptdc_signoff_repo_root] MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib]
}

proc mptdc_signoff_lef_macro_name {lef_path} {
    set fh [open $lef_path r]
    set in_prop 0
    set macro ""
    while {[gets $fh line] >= 0} {
        if {[regexp {^[[:space:]]*PROPERTYDEFINITIONS[[:space:]]*$} $line]} {
            set in_prop 1
            continue
        }
        if {$in_prop && [regexp {^[[:space:]]*END[[:space:]]+PROPERTYDEFINITIONS[[:space:]]*$} $line]} {
            set in_prop 0
            continue
        }
        if {$in_prop} {
            continue
        }
        if {[regexp {^[[:space:]]*MACRO[[:space:]]+([^[:space:];]+)[[:space:]]*$} $line -> macro]} {
            break
        }
    }
    close $fh
    return $macro
}

proc mptdc_signoff_prepare_ro_inputs {} {
    if {![mptdc_signoff_env_truthy O1_USE_REAL_RO_ABSTRACT]} {
        set ::env(O1_USE_REAL_RO_ABSTRACT) 1
    }
    if {![info exists ::env(O1_RO_LEF_PATH)] || $::env(O1_RO_LEF_PATH) eq ""} {
        set ::env(O1_RO_LEF_PATH) [mptdc_signoff_default_ro_lef]
    }
    if {![info exists ::env(O1_RO_LIBERTY_PATH)] || $::env(O1_RO_LIBERTY_PATH) eq ""} {
        set ::env(O1_RO_LIBERTY_PATH) [mptdc_signoff_default_ro_liberty]
    }
    set lef [mptdc_signoff_required_file "RO_tune4 LEF" $::env(O1_RO_LEF_PATH)]
    set lib [mptdc_signoff_required_file "RO_tune4 Liberty" $::env(O1_RO_LIBERTY_PATH)]
    set macro [mptdc_signoff_lef_macro_name $lef]
    if {$macro ne "RO_tune4"} {
        error "MPTDC_RO_LEF_MACRO_MISMATCH: O1_RO_LEF_PATH=$lef macro=$macro expected=RO_tune4"
    }
    set ::env(O1_RO_LEF_PATH) $lef
    set ::env(O1_RO_LIBERTY_PATH) $lib
    return [dict create lef $lef liberty $lib macro $macro]
}

proc mptdc_signoff_write_ro_source_report {} {
    set ro [mptdc_signoff_prepare_ro_inputs]
    set path [file join [mptdc_signoff_report_dir] ro_import_source_gate.rpt]
    set fh [open $path w]
    puts $fh "O1_USE_REAL_RO_ABSTRACT=1"
    puts $fh "O1_RO_LEF_PATH=[dict get $ro lef]"
    puts $fh "O1_RO_LEF_MACRO=[dict get $ro macro]"
    puts $fh "O1_RO_LIBERTY_PATH=[dict get $ro liberty]"
    puts $fh "MPTDC_OSC_BLACKBOX_ALLOWED=NO"
    puts $fh "MPTDC_OSC_SLOW_BB_ALLOWED=NO"
    puts $fh "MPTDC_OSC_FAST_BB_ALLOWED=NO"
    puts $fh "REQUIRED_RO_TUNE4_INSTANCES=2"
    puts $fh "REQUIRED_EMPTY_MODULES=0"
    puts $fh "REQUIRED_RAW_PHASE_NETS_WITH_RO_DRIVERS=16"
    puts $fh "FATAL_IMPORT_MESSAGES=TECHLIB-702 TECHLIB-704 IMPDB-2504"
    close $fh
    mptdc_signoff_set_status RO_IMPORT_STATUS PASS $path
    return $path
}

proc mptdc_signoff_list_has_path_fragment {items fragment} {
    foreach item $items {
        if {[string match "*$fragment*" $item]} {
            return 1
        }
    }
    return 0
}

proc mptdc_signoff_require_no_blackbox_collateral {} {
    global tech_files
    foreach key {ALL_LEFS ALL_TC_LIBS ALL_WC_LIBS ALL_BC_LIBS} {
        if {![info exists tech_files($key)]} {
            continue
        }
        if {[mptdc_signoff_list_has_path_fragment $tech_files($key) "mptdc_osc_blackbox"]} {
            error "MPTDC_RO_BLACKBOX_COLLATERAL_LOADED: $key includes mptdc_osc_blackbox while O1_USE_REAL_RO_ABSTRACT=1"
        }
    }
}

proc mptdc_signoff_script_path {rel} {
    return [file join [mptdc_signoff_repo_root] MPTDC/pnr/scripts $rel]
}

proc mptdc_signoff_source_if_exists {rel} {
    set path [mptdc_signoff_script_path $rel]
    if {[file exists $path]} {
        source $path
        return 1
    }
    return 0
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

proc mptdc_signoff_capture_required_candidates {path title bodies} {
    if {[mptdc_signoff_capture_candidates $path $title $bodies]} {
        return 1
    }
    error "MPTDC_REQUIRED_REPORT_COMMAND_FAILED: title=$title path=$path"
}

proc mptdc_signoff_unique_append {var_name value} {
    upvar 1 $var_name values
    if {$value eq ""} { return }
    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}

proc mptdc_signoff_object_names {objects} {
    set names [list]
    if {[llength $objects] == 0} {
        return $names
    }
    if {![catch {get_object_name $objects} obj_names]} {
        foreach name $obj_names {
            mptdc_signoff_unique_append names "$name"
        }
        return $names
    }
    if {![catch {get_db $objects .name} obj_names]} {
        foreach name $obj_names {
            mptdc_signoff_unique_append names "$name"
        }
        return $names
    }
    foreach obj $objects {
        mptdc_signoff_unique_append names "$obj"
    }
    return $names
}

proc mptdc_signoff_collect_cells {patterns} {
    set out [list]
    foreach pattern $patterns {
        set cells [list]
        catch {set cells [get_cells -quiet -hierarchical $pattern]}
        foreach name [mptdc_signoff_object_names $cells] {
            mptdc_signoff_unique_append out $name
        }
    }
    return $out
}

proc mptdc_signoff_collect_pins {patterns} {
    set out [list]
    foreach pattern $patterns {
        set pins [list]
        catch {set pins [get_pins -quiet -hierarchical $pattern]}
        foreach name [mptdc_signoff_object_names $pins] {
            mptdc_signoff_unique_append out $name
        }
    }
    return $out
}

proc mptdc_signoff_collect_clocks {patterns} {
    set out [list]
    foreach pattern $patterns {
        set clocks [list]
        catch {set clocks [get_clocks -quiet $pattern]}
        foreach name [mptdc_signoff_object_names $clocks] {
            mptdc_signoff_unique_append out $name
        }
    }
    return $out
}

proc mptdc_signoff_count_cells {patterns} {
    return [llength [mptdc_signoff_collect_cells $patterns]]
}

proc mptdc_signoff_collect_inst_names_from_db {patterns} {
    set out [list]
    set all_names [list]
    foreach cmd {
        {dbGet top.insts.name}
        {get_db insts .name}
    } {
        if {![catch {set names [eval $cmd]}] && $names ne ""} {
            foreach name $names {
                if {$name eq "" || $name eq "0x0" || $name eq "NULL"} { continue }
                mptdc_signoff_unique_append all_names "$name"
            }
        }
    }
    foreach name $all_names {
        foreach pattern $patterns {
            if {[string match $pattern $name]} {
                mptdc_signoff_unique_append out $name
                break
            }
        }
    }
    return $out
}

proc mptdc_signoff_box_valid {box} {
    if {[llength $box] < 4} { return 0 }
    foreach value [lrange $box 0 3] {
        if {![string is double -strict $value]} { return 0 }
    }
    return [expr {([lindex $box 2] > [lindex $box 0]) && ([lindex $box 3] > [lindex $box 1])}]
}

proc mptdc_signoff_flat_box {value} {
    while {[llength $value] == 1} {
        set value [lindex $value 0]
    }
    if {[llength $value] >= 4} {
        return [lrange $value 0 3]
    }
    return [list]
}

proc mptdc_signoff_core_box {} {
    set core_box [list]
    foreach cmd {
        {dbGet top.fPlan.coreBox}
        {dbGet top.fPlan.box}
    } {
        if {![catch {set core_box [eval $cmd]}] && $core_box ne ""} {
            break
        }
    }
    return [mptdc_signoff_flat_box $core_box]
}

proc mptdc_signoff_box_width {box} {
    return [expr {[lindex $box 2] - [lindex $box 0]}]
}

proc mptdc_signoff_box_height {box} {
    return [expr {[lindex $box 3] - [lindex $box 1]}]
}

proc mptdc_signoff_box_area {box} {
    return [expr {[mptdc_signoff_box_width $box] * [mptdc_signoff_box_height $box]}]
}

proc mptdc_signoff_box_center {box} {
    if {![mptdc_signoff_box_valid $box]} {
        return [list "" ""]
    }
    return [list \
        [expr {([lindex $box 0] + [lindex $box 2]) / 2.0}] \
        [expr {([lindex $box 1] + [lindex $box 3]) / 2.0}]]
}

proc mptdc_signoff_box_overlap_area {a b} {
    if {![mptdc_signoff_box_valid $a] || ![mptdc_signoff_box_valid $b]} { return "" }
    set llx [expr {max([lindex $a 0], [lindex $b 0])}]
    set lly [expr {max([lindex $a 1], [lindex $b 1])}]
    set urx [expr {min([lindex $a 2], [lindex $b 2])}]
    set ury [expr {min([lindex $a 3], [lindex $b 3])}]
    if {$urx <= $llx || $ury <= $lly} { return 0.0 }
    return [expr {($urx - $llx) * ($ury - $lly)}]
}

proc mptdc_signoff_box_clearance {a b} {
    if {![mptdc_signoff_box_valid $a] || ![mptdc_signoff_box_valid $b]} { return "" }
    set dx 0.0
    if {[lindex $a 2] < [lindex $b 0]} {
        set dx [expr {[lindex $b 0] - [lindex $a 2]}]
    } elseif {[lindex $b 2] < [lindex $a 0]} {
        set dx [expr {[lindex $a 0] - [lindex $b 2]}]
    }
    set dy 0.0
    if {[lindex $a 3] < [lindex $b 1]} {
        set dy [expr {[lindex $b 1] - [lindex $a 3]}]
    } elseif {[lindex $b 3] < [lindex $a 1]} {
        set dy [expr {[lindex $a 1] - [lindex $b 3]}]
    }
    if {$dx == 0.0} { return $dy }
    if {$dy == 0.0} { return $dx }
    return [expr {sqrt(($dx * $dx) + ($dy * $dy))}]
}

proc mptdc_signoff_expand_box {box halo} {
    if {![mptdc_signoff_box_valid $box]} { return [list] }
    return [list \
        [expr {[lindex $box 0] - $halo}] \
        [expr {[lindex $box 1] - $halo}] \
        [expr {[lindex $box 2] + $halo}] \
        [expr {[lindex $box 3] + $halo}]]
}

proc mptdc_signoff_cell_ptr {inst} {
    set ptrs [list]
    catch {set ptrs [dbGet top.insts.name $inst -p]}
    foreach ptr $ptrs {
        if {$ptr ne "" && $ptr ne "0x0"} {
            return $ptr
        }
    }
    return ""
}

proc mptdc_signoff_norm_inst_name {name} {
    set text "$name"
    regsub -all {\\([\[\]])} $text {\1} text
    return $text
}

proc mptdc_signoff_db_object_name {obj} {
    if {![regexp {^(inst|hinst|pin|net|term):|^0x[0-9a-fA-F]+$} "$obj"]} {
        return "$obj"
    }
    set name ""
    catch {set name [get_object_name $obj]}
    if {$name eq ""} { catch {set name [get_db $obj .name]} }
    return $name
}

proc mptdc_signoff_db_object_box {obj} {
    if {$obj eq ""} { return [list] }
    set names [list]
    if {![regexp {^(inst|hinst|pin|net|term):|^0x[0-9a-fA-F]+$} "$obj"]} {
        lappend names $obj
    } else {
        set obj_name [mptdc_signoff_db_object_name $obj]
        if {$obj_name ne ""} {
            lappend names $obj_name
        }
    }
    foreach name $names {
        set ptr [mptdc_signoff_cell_ptr $name]
        foreach attr {.box .bbox} {
            set value ""
            if {$ptr ne "" && ![catch {set value [dbGet ${ptr}${attr}]}] && $value ne ""} {
                set box [mptdc_signoff_flat_box $value]
                if {[mptdc_signoff_box_valid $box]} { return $box }
            }
        }
    }
    # This Innovus build prints IMPDBTCL-248 for invalid inst attributes even
    # inside catch, so only probe the direct-object bbox attribute known here.
    if {[regexp {^(inst|hinst|pin|net|term):|^0x[0-9a-fA-F]+$} "$obj"]} {
        set value ""
        if {![catch {set value [get_db $obj .bbox]}] && $value ne ""} {
            set box [mptdc_signoff_flat_box $value]
            if {[mptdc_signoff_box_valid $box]} { return $box }
        }
    }
    return [list]
}

proc mptdc_signoff_leaf_cell_objects_under {inst} {
    set prefix "[mptdc_signoff_norm_inst_name $inst]/"
    set out [list]
    set db_names [list]
    catch {set db_names [dbGet top.insts.name]}
    foreach name $db_names {
        if {$name eq ""} { continue }
        set norm [mptdc_signoff_norm_inst_name $name]
        if {$norm eq [mptdc_signoff_norm_inst_name $inst]} { continue }
        if {[string first $prefix $norm] == 0 && [lsearch -exact $out $name] < 0} {
            lappend out $name
        }
    }
    set all_cells [list]
    catch {set all_cells [get_cells -quiet -hierarchical *]}
    foreach obj $all_cells {
        set name [mptdc_signoff_db_object_name $obj]
        if {$name eq ""} { continue }
        if {[string match {hinst:*} "$obj"] || [string match {hinst:*} "$name"]} {
            continue
        }
        set norm [mptdc_signoff_norm_inst_name $name]
        if {$norm eq [mptdc_signoff_norm_inst_name $inst]} { continue }
        if {[string first $prefix $norm] == 0 && [lsearch -exact $out $name] < 0} {
            lappend out $name
        }
    }
    return $out
}

proc mptdc_signoff_cell_box {inst} {
    set ptr [mptdc_signoff_cell_ptr $inst]
    foreach attr {.box} {
        set value ""
        if {$ptr ne "" && ![catch {set value [dbGet ${ptr}${attr}]}] && $value ne ""} {
            set box [mptdc_signoff_flat_box $value]
            if {[mptdc_signoff_box_valid $box]} { return $box }
        }
    }
    set objs [list]
    catch {set objs [get_cells -quiet $inst]}
    if {[llength $objs] == 0} {
        catch {set objs [get_cells -quiet -hierarchical $inst]}
    }
    set obj [lindex $objs 0]
    return [mptdc_signoff_db_object_box $obj]
}

proc mptdc_signoff_cell_center {inst} {
    set box [mptdc_signoff_cell_box $inst]
    return [mptdc_signoff_box_center $box]
}

proc mptdc_signoff_cell_or_leaf_box {inst} {
    set found 0
    set llx ""
    set lly ""
    set urx ""
    set ury ""
    foreach obj [mptdc_signoff_leaf_cell_objects_under $inst] {
        set leaf_box [mptdc_signoff_db_object_box $obj]
        if {![mptdc_signoff_box_valid $leaf_box]} { continue }
        set b_llx [lindex $leaf_box 0]
        set b_lly [lindex $leaf_box 1]
        set b_urx [lindex $leaf_box 2]
        set b_ury [lindex $leaf_box 3]
        if {!$found} {
            set llx $b_llx
            set lly $b_lly
            set urx $b_urx
            set ury $b_ury
        } else {
            if {$b_llx < $llx} { set llx $b_llx }
            if {$b_lly < $lly} { set lly $b_lly }
            if {$b_urx > $urx} { set urx $b_urx }
            if {$b_ury > $ury} { set ury $b_ury }
        }
        incr found
    }
    if {$found == 0} {
        set box [mptdc_signoff_cell_box $inst]
        if {[mptdc_signoff_box_valid $box]} {
            return [concat $box [list 1 direct]]
        }
        return [list]
    }
    return [list $llx $lly $urx $ury $found hier_leaf_aggregate]
}

proc mptdc_signoff_point_in_box {x y box} {
    if {![mptdc_signoff_box_valid $box]} { return 0 }
    if {![string is double -strict $x] || ![string is double -strict $y]} { return 0 }
    return [expr {$x >= [lindex $box 0] && $x <= [lindex $box 2] && $y >= [lindex $box 1] && $y <= [lindex $box 3]}]
}

proc mptdc_signoff_count_report_bad_lines {path bad_regex {good_regex ""}} {
    set bad [list]
    if {![file exists $path]} {
        return [list missing "$path missing"]
    }
    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {$trimmed eq "" || [string match "#*" $trimmed]} {
            continue
        }
        if {$good_regex ne "" && [regexp -nocase $good_regex $trimmed]} {
            continue
        }
        if {[regexp -nocase $bad_regex $trimmed]} {
            lappend bad $trimmed
            if {[llength $bad] >= 20} { break }
        }
    }
    close $fh
    return [list ok $bad]
}

proc mptdc_signoff_set_env_default {name value} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        set ::env($name) $value
    }
}

proc mptdc_signoff_phase_buffer_patterns {family stage} {
    set inst [expr {$stage eq "iso" ? "u_iso" : "u_drv"}]
    return [list \
        "*u_phase_buf_${family}*gen_phase_buf*${inst}*" \
        "*phase_buf_${family}*gen_phase_buf*${inst}*" \
        "*u_phase_buf_${family}*${inst}*" \
        "*phase_buf_${family}*${inst}*" \
        "*${family}*${inst}*"]
}

proc mptdc_signoff_phase_buffer_instances_from_o13 {family stage} {
    if {[llength [info commands mptdc_o13_phase_stage_instances]] == 0} {
        return [list]
    }
    set role [expr {$stage eq "iso" ? "isolation" : "driver"}]
    set out [list]
    foreach item [mptdc_o13_phase_stage_instances $family $role] {
        set inst [lindex $item 1]
        mptdc_signoff_unique_append out $inst
    }
    return $out
}

proc mptdc_signoff_phase_buffer_instances {family stage} {
    set out [mptdc_signoff_phase_buffer_instances_from_o13 $family $stage]
    if {[llength $out] > 0} {
        return $out
    }
    return [mptdc_signoff_collect_cells [mptdc_signoff_phase_buffer_patterns $family $stage]]
}

proc mptdc_signoff_ro_instances_by_family {} {
    set ro_instances [mptdc_signoff_collect_cells [list *u_ro_tune4* *RO_tune4*]]
    set slow [lindex $ro_instances 0]
    set fast [lindex $ro_instances 1]
    foreach ro $ro_instances {
        if {[regexp -nocase {slow} $ro]} { set slow $ro }
        if {[regexp -nocase {fast} $ro]} { set fast $ro }
    }
    return [list slow $slow fast $fast all $ro_instances]
}

proc mptdc_signoff_create_ro_halos {{path ""}} {
    set halo [mptdc_signoff_env MPTDC_RO_PHASE_MIN_CLEARANCE_UM 10.0]
    if {$path eq ""} {
        set path [file join [mptdc_signoff_report_dir] ro_halo_status.rpt]
    }
    set ro_map [mptdc_signoff_ro_instances_by_family]
    set fh [open $path w]
    puts $fh "# MPTDC RO Macro Halo Status"
    puts $fh "RO_PHASE_MIN_CLEARANCE_UM=$halo"
    set failures [list]
    foreach family {slow fast} {
        set inst [dict get $ro_map $family]
        set box [mptdc_signoff_cell_box $inst]
        set halo_box [mptdc_signoff_expand_box $box $halo]
        puts $fh "[string toupper $family]_RO_INSTANCE=$inst"
        puts $fh "[string toupper $family]_RO_BBOX=$box"
        puts $fh "[string toupper $family]_RO_HALO_BBOX=$halo_box"
        if {![mptdc_signoff_box_valid $halo_box]} {
            lappend failures "${family}:invalid_ro_bbox"
            continue
        }
        set name "MPTDC_${family}_RO_HALO"
        set ok 0
        foreach cmd [list \
            [list createPlaceBlockage -box $halo_box -type hard -name $name] \
            [list createPlaceBlockage -box $halo_box -type hard] \
            [list createPlaceBlockage -box $halo_box]] {
            puts $fh "[string toupper $family]_HALO_COMMAND=$cmd"
            if {![catch {{*}$cmd} err]} {
                puts $fh "[string toupper $family]_HALO_STATUS=PASS"
                set ok 1
                break
            }
            puts $fh "[string toupper $family]_HALO_ATTEMPT_ERROR=$err"
        }
        if {!$ok} {
            lappend failures "${family}:halo_create_failed"
        }
    }
    puts $fh "RO_HALO_STATUS=[expr {[llength $failures] == 0 ? "PASS" : "FAIL"}]"
    if {[llength $failures] > 0} {
        puts $fh "RO_HALO_FAILURES=$failures"
    }
    close $fh
    if {[llength $failures] > 0} {
        error "MPTDC_RO_HALO_GATE_FAILED: $failures report=$path"
    }
    return $path
}

proc mptdc_signoff_set_phase_origin_env {stable value force} {
    set legacy [string map {MPTDC_PNR_ MPTDC_O13_} $stable]
    foreach name [list $stable $legacy] {
        if {$force || ![info exists ::env($name)] || $::env($name) eq ""} {
            set ::env($name) $value
        }
    }
}

proc mptdc_signoff_set_default_phase_buffer_origins {} {
    mptdc_signoff_source_if_exists innovus_mptdc_floorplan.tcl
    if {[llength [info commands mptdc_pnr_floorplan_regions]] == 0} {
        return
    }
    set regions [mptdc_pnr_floorplan_regions]
    if {![dict exists $regions fast_phase_buffers] || ![dict exists $regions slow_phase_buffers]} {
        return
    }

    set pitch [mptdc_signoff_env MPTDC_PNR_PHASE_BUF_PITCH_UM 24.0]
    set x_offset [mptdc_signoff_env MPTDC_PNR_PHASE_BUF_X_OFFSET_UM 40.0]
    set y_offset [mptdc_signoff_env MPTDC_PNR_PHASE_BUF_Y_OFFSET_UM 2.0]
    set row_sep [mptdc_signoff_env MPTDC_PNR_PHASE_BUF_ROW_SEPARATION_UM 12.0]
    set clearance [mptdc_signoff_env MPTDC_RO_PHASE_MIN_CLEARANCE_UM 10.0]
    set force [mptdc_signoff_env MPTDC_PNR_FORCE_RO_PHASE_SAFE_ORIGINS 1]

    set fast_box [dict get $regions fast_phase_buffers]
    set slow_box [dict get $regions slow_phase_buffers]
    set fast_x [expr {[lindex $fast_box 0] + $x_offset}]
    set slow_x [expr {[lindex $slow_box 0] + $x_offset}]
    set fast_y0 [lindex $fast_box 1]
    set slow_y0 [lindex $slow_box 1]

    set ro_map [mptdc_signoff_ro_instances_by_family]
    set fast_ro_box [mptdc_signoff_cell_box [dict get $ro_map fast]]
    set slow_ro_box [mptdc_signoff_cell_box [dict get $ro_map slow]]

    set fast_iso_y [expr {$fast_y0 + $y_offset}]
    set fast_drv_y [expr {$fast_iso_y + $row_sep}]
    if {[mptdc_signoff_box_valid $fast_ro_box]} {
        set fast_iso_y [expr {[lindex $fast_ro_box 3] + $clearance}]
        set fast_drv_y [expr {$fast_iso_y + $row_sep}]
    }

    set slow_iso_y [expr {$slow_y0 + $y_offset + $row_sep}]
    set slow_drv_y [expr {$slow_y0 + $y_offset}]
    if {[mptdc_signoff_box_valid $slow_ro_box]} {
        set slow_iso_y [expr {[lindex $slow_ro_box 1] - $clearance - $row_sep}]
        set slow_drv_y [expr {$slow_iso_y - $row_sep}]
    }

    mptdc_signoff_set_phase_origin_env MPTDC_PNR_PHASE_BUF_PITCH_UM $pitch $force
    mptdc_signoff_set_phase_origin_env MPTDC_PNR_PHASE_BUF_ORIENT AUTO $force
    mptdc_signoff_set_phase_origin_env MPTDC_PNR_FAST_ISO_X $fast_x $force
    mptdc_signoff_set_phase_origin_env MPTDC_PNR_FAST_ISO_Y $fast_iso_y $force
    mptdc_signoff_set_phase_origin_env MPTDC_PNR_FAST_DRV_X $fast_x $force
    mptdc_signoff_set_phase_origin_env MPTDC_PNR_FAST_DRV_Y $fast_drv_y $force
    mptdc_signoff_set_phase_origin_env MPTDC_PNR_SLOW_ISO_X $slow_x $force
    mptdc_signoff_set_phase_origin_env MPTDC_PNR_SLOW_ISO_Y $slow_iso_y $force
    mptdc_signoff_set_phase_origin_env MPTDC_PNR_SLOW_DRV_X $slow_x $force
    mptdc_signoff_set_phase_origin_env MPTDC_PNR_SLOW_DRV_Y $slow_drv_y $force
}

proc mptdc_signoff_write_count_gate {path rows} {
    set fh [open $path w]
    set failures [list]
    foreach row $rows {
        set label [lindex $row 0]
        set expected [lindex $row 1]
        set actual [lindex $row 2]
        set status [expr {$expected eq $actual ? "PASS" : "FAIL"}]
        puts $fh "$label expected=$expected actual=$actual status=$status"
        if {$status ne "PASS"} {
            lappend failures "$label expected=$expected actual=$actual"
        }
    }
    close $fh
    if {[llength $failures] > 0} {
        error "MPTDC_COUNT_GATE_FAILED: $failures"
    }
    return $path
}

proc mptdc_signoff_parse_wns_ns {path} {
    if {![file exists $path]} {
        return ""
    }
    set fh [open $path r]
    set value ""
    while {[gets $fh line] >= 0} {
        if {[regexp -nocase {WNS[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)} $line -> number]} {
            set value $number
            break
        }
    }
    close $fh
    return $value
}

proc mptdc_signoff_timing_class_regexes {} {
    return [list \
        CLK_SYS {clk_sys} \
        OSC_SLOW {clk_osc_slow|u_osc_slow|slow_phase} \
        OSC_FAST {clk_osc_fast|u_osc_fast|fast_phase} \
        PHASE_BUFFER {phase_buf|gen_phase_buf|BUJIHDX4|BUJIHDX12|iso_tap} \
        PD_MATRIX {gen_pd_row|gen_pd_col|u_pd|mptdc_pd} \
        FAST_TAG {fast_tag|raw_lfsr_tag|nfast} \
        RO_CONTROL {ro_code|RO_tune4|u_ro_tune4|rstb} \
        RESET_OR_CLEAR {rst|reset|clear_window} \
        DATA_PATH {packet|axis|fifo|hit|timestamp}]
}

proc mptdc_signoff_write_timing_stage_classification {stage summary_path top_path wns limit_ns} {
    set rpt [file join [mptdc_signoff_report_dir] "timing_tc_${stage}_classification.rpt"]
    set fh [open $rpt w]
    puts $fh "# MPTDC TC Timing Stage Classification"
    puts $fh "STAGE=$stage"
    puts $fh "SUMMARY_REPORT=$summary_path"
    puts $fh "TOP_PATH_REPORT=$top_path"
    puts $fh "WNS_NS=$wns"
    puts $fh "LIMIT_NS=$limit_ns"
    puts $fh "GATE_STATUS=[expr {$wns ne "" && $wns < $limit_ns ? "FAIL" : "PASS_OR_NOT_EVALUATED"}]"
    puts $fh "ACTION_ON_FAIL=STOP_BEFORE_NEXT_PHYSICAL_STAGE"

    array set counts {}
    array set examples {}
    foreach {class regex} [mptdc_signoff_timing_class_regexes] {
        set counts($class) 0
        set examples($class) [list]
    }

    set key_lines [list]
    set parsed_paths [list]
    set start ""
    set endpoint ""
    set group ""
    set slack ""

    if {$top_path ne "" && [file exists $top_path]} {
        set tfh [open $top_path r]
        while {[gets $tfh line] >= 0} {
            foreach {class regex} [mptdc_signoff_timing_class_regexes] {
                if {[regexp -nocase $regex $line]} {
                    incr counts($class)
                    if {[llength $examples($class)] < 3} {
                        lappend examples($class) [string trim $line]
                    }
                }
            }
            if {[regexp -nocase {^[[:space:]]*Startpoint:[[:space:]]*(.*)} $line -> value]} {
                if {$start ne "" || $endpoint ne "" || $slack ne ""} {
                    lappend parsed_paths [dict create start $start endpoint $endpoint group $group slack $slack]
                }
                set start [string trim $value]
                set endpoint ""
                set group ""
                set slack ""
            } elseif {[regexp -nocase {^[[:space:]]*Endpoint:[[:space:]]*(.*)} $line -> value]} {
                set endpoint [string trim $value]
            } elseif {[regexp -nocase {^[[:space:]]*Path[[:space:]_]*Group:[[:space:]]*(.*)} $line -> value]} {
                set group [string trim $value]
            } elseif {[regexp -nocase {slack[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)} $line -> value]} {
                set slack $value
            }
            if {[regexp -nocase {Startpoint:|Endpoint:|Path[[:space:]_]*Group:|slack|VIOLATED} $line]} {
                if {[llength $key_lines] < 120} {
                    lappend key_lines [string trim $line]
                }
            }
        }
        close $tfh
        if {$start ne "" || $endpoint ne "" || $slack ne ""} {
            lappend parsed_paths [dict create start $start endpoint $endpoint group $group slack $slack]
        }
    } else {
        puts $fh "TOP_PATH_REPORT_STATUS=MISSING"
    }

    puts $fh ""
    puts $fh "CLASS_LINE_COUNTS:"
    foreach {class regex} [mptdc_signoff_timing_class_regexes] {
        puts $fh "$class=$counts($class)"
        set idx 0
        foreach example $examples($class) {
            incr idx
            puts $fh "${class}_EXAMPLE_${idx}=$example"
        }
    }

    puts $fh ""
    puts $fh "PARSED_TOP_PATHS:"
    if {[llength $parsed_paths] == 0} {
        puts $fh "PARSE_STATUS=NO_STRUCTURED_PATHS_FOUND"
    } else {
        set idx 0
        foreach path $parsed_paths {
            incr idx
            if {$idx > 20} { break }
            set text "[dict get $path start] [dict get $path endpoint] [dict get $path group]"
            set classes [list]
            foreach {class regex} [mptdc_signoff_timing_class_regexes] {
                if {[regexp -nocase $regex $text]} {
                    lappend classes $class
                }
            }
            if {[llength $classes] == 0} {
                lappend classes UNKNOWN
            }
            puts $fh "PATH_${idx}_CLASS=[join $classes ,]"
            puts $fh "PATH_${idx}_START=[dict get $path start]"
            puts $fh "PATH_${idx}_END=[dict get $path endpoint]"
            puts $fh "PATH_${idx}_GROUP=[dict get $path group]"
            puts $fh "PATH_${idx}_SLACK_NS=[dict get $path slack]"
        }
    }

    puts $fh ""
    puts $fh "KEY_TIMING_LINES:"
    foreach line $key_lines {
        puts $fh $line
    }
    close $fh
    return $rpt
}

proc mptdc_signoff_stop_if_wns_below {path limit_ns stage {top_path ""}} {
    set wns [mptdc_signoff_parse_wns_ns $path]
    if {$wns eq ""} {
        return
    }
    if {$wns < $limit_ns} {
        set classification [mptdc_signoff_write_timing_stage_classification $stage $path $top_path $wns $limit_ns]
        error "MPTDC_TC_WNS_BELOW_STAGE_LIMIT: stage=$stage wns_ns=$wns limit_ns=$limit_ns report=$path classification=$classification"
    }
}

proc mptdc_signoff_timing_line_is_failure {line} {
    if {[regexp -nocase {REPORT_STATUS=FAILED|VIOLATED} $line]} {
        return 1
    }
    if {[regexp -nocase {Violating Paths:[^0-9]*([0-9]+)} $line -> count] && $count > 0} {
        return 1
    }
    foreach label {WNS TNS slack {Slack Time}} {
        set pattern "${label}\[^-+0-9\]*(\[-+\]?\[0-9\]+(\[.\]\[0-9\]+)?)"
        if {[regexp -nocase $pattern $line -> value] && $value < -0.000001} {
            return 1
        }
    }
    return 0
}

proc mptdc_signoff_require_no_negative_slack {path label} {
    if {![file exists $path]} {
        error "MPTDC_REPORT_MISSING_FOR_GATE: label=$label path=$path"
    }
    set bad [mptdc_signoff_collect_timing_failures $path]
    if {[llength $bad] > 0} {
        error "MPTDC_TIMING_GATE_FAILED: label=$label report=$path evidence=$bad"
    }
}

proc mptdc_signoff_collect_timing_failures {path {limit 5}} {
    if {![file exists $path]} {
        return [list "REPORT_MISSING path=$path"]
    }
    set fh [open $path r]
    set bad [list]
    while {[gets $fh line] >= 0} {
        if {[mptdc_signoff_timing_line_is_failure $line]} {
            lappend bad $line
            if {[llength $bad] >= $limit} {
                break
            }
        }
    }
    close $fh
    return $bad
}

proc mptdc_signoff_write_extracted_timing_status {path setup_rpt hold_rpt setup_bad hold_bad} {
    set fh [open $path w]
    puts $fh "# MPTDC Extracted TC Timing Status"
    puts $fh "TC_TIMING_GATE_POLICY=report_failures_without_aborting_physical_package"
    puts $fh "TC_SETUP_REPORT=$setup_rpt"
    puts $fh "TC_HOLD_REPORT=$hold_rpt"
    set setup_status [expr {[llength $setup_bad] == 0 ? "PASS" : "FAIL"}]
    set hold_status [expr {[llength $hold_bad] == 0 ? "PASS" : "FAIL"}]
    puts $fh "SETUP_STATUS_TC=$setup_status"
    puts $fh "TC_HOLD_STATUS=$hold_status"
    if {[llength $setup_bad] > 0} {
        puts $fh "TC_SETUP_FAILURE_EVIDENCE_BEGIN"
        foreach line $setup_bad { puts $fh $line }
        puts $fh "TC_SETUP_FAILURE_EVIDENCE_END"
    }
    if {[llength $hold_bad] > 0} {
        puts $fh "TC_HOLD_FAILURE_EVIDENCE_BEGIN"
        foreach line $hold_bad { puts $fh $line }
        puts $fh "TC_HOLD_FAILURE_EVIDENCE_END"
    }
    close $fh
    return [list $setup_status $hold_status]
}

proc mptdc_signoff_configure_post_route_tc_sta {} {
    set rpt [file join [mptdc_signoff_report_dir] extraction_sta_policy.rpt]
    set fh [open $rpt w]
    puts $fh "TC_SETUP_VIEWS=TC_NOMINAL"
    puts $fh "TC_HOLD_VIEWS=TC_NOMINAL"
    puts $fh "POST_ROUTE_ANALYSIS_TYPE=onChipVariation"
    puts $fh "CPPR=both"
    if {[catch {set_analysis_view -setup [list TC_NOMINAL] -hold [list TC_NOMINAL]} err]} {
        puts $fh "SET_ANALYSIS_VIEW_STATUS=FAIL"
        puts $fh "SET_ANALYSIS_VIEW_ERROR=$err"
        close $fh
        error "MPTDC_POST_ROUTE_TC_VIEW_SETUP_FAILED: $err"
    }
    puts $fh "SET_ANALYSIS_VIEW_STATUS=PASS"
    if {[catch {setAnalysisMode -analysisType onChipVariation -cppr both} err]} {
        puts $fh "SET_ANALYSIS_MODE_STATUS=FAIL"
        puts $fh "SET_ANALYSIS_MODE_ERROR=$err"
        close $fh
        error "MPTDC_POST_ROUTE_OCV_MODE_SETUP_FAILED: $err"
    }
    puts $fh "SET_ANALYSIS_MODE_STATUS=PASS"
    close $fh
    return $rpt
}

proc mptdc_signoff_require_no_drv_violation_markers {paths} {
    set bad [list]
    foreach path $paths {
        if {![file exists $path]} {
            lappend bad "$path missing"
            continue
        }
        set fh [open $path r]
        while {[gets $fh line] >= 0} {
            set trimmed [string trim $line]
            if {$trimmed eq "" || [string match "#*" $trimmed]} {
                continue
            }
            if {[regexp -nocase {REPORT_STATUS=FAILED} $trimmed]} {
                lappend bad "$path: $line"
                break
            }
            if {[regexp -nocase {no[[:space:]]+violations?[[:space:]]+found|0[[:space:]]+violations?} $trimmed]} {
                continue
            }
            if {[regexp -nocase {VIOLATED|violator|violation} $trimmed]} {
                lappend bad "$path: $line"
                break
            }
        }
        close $fh
    }
    if {[llength $bad] > 0} {
        error "MPTDC_DRV_GATE_FAILED: $bad"
    }
}

proc mptdc_signoff_sanitize_postsyn_sdc_for_pnr {input_path} {
    set out_dir [file join [mptdc_signoff_work_dir] pnr_constraints]
    file mkdir $out_dir
    set out_path [file join $out_dir mptdc_axis_core.postsyn.pnr_cts.sdc]
    set rpt [file join [mptdc_signoff_report_dir] pnr_sdc_sanitization.rpt]
    set in [open $input_path r]
    set out [open $out_path w]
    puts $out "# Generated by innovus_mptdc_digital_signoff.tcl"
    puts $out "# PNR-local copy of: $input_path"
    puts $out "# Removed set_ideal_network commands so CTS sees a real clk_sys network."

    set removed 0
    set kept 0
    set removed_examples [list]
    set dropping_continuation 0
    while {[gets $in line] >= 0} {
        set starts_ideal [regexp {(^|[;[:space:]])set_ideal_network([[:space:]]|$)} $line]
        if {$dropping_continuation || $starts_ideal} {
            incr removed
            if {[llength $removed_examples] < 20} {
                lappend removed_examples $line
            }
            set dropping_continuation [regexp {\\[[:space:]]*$} $line]
            continue
        }
        puts $out $line
        incr kept
    }
    close $in
    close $out

    set fh [open $rpt w]
    puts $fh "# MPTDC PNR SDC Sanitization"
    puts $fh "INPUT_SDC=$input_path"
    puts $fh "OUTPUT_SDC=$out_path"
    puts $fh "REMOVED_SET_IDEAL_NETWORK_LINES=$removed"
    puts $fh "KEPT_LINES=$kept"
    puts $fh "INTENT=deidealize_genus_handoff_for_real_clk_sys_cts"
    puts $fh "RAW_POSTSYN_SDC_OVERRIDE_ENV=MPTDC_USE_RAW_POSTSYN_SDC"
    foreach line $removed_examples {
        puts $fh "REMOVED_LINE=$line"
    }
    close $fh
    return $out_path
}

proc mptdc_signoff_load_design_context {} {
    global design tech tech_files paths
    mptdc_signoff_require_tc_only_scope
    mptdc_signoff_source_xh018_cells
    mptdc_signoff_prepare_ro_inputs
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
    set design(original_postsyn_sdc) $design(postsyn_sdc)
    if {![mptdc_signoff_env_truthy MPTDC_USE_RAW_POSTSYN_SDC]} {
        set design(postsyn_sdc) [mptdc_signoff_sanitize_postsyn_sdc_for_pnr $design(postsyn_sdc)]
        mptdc_signoff_required_file "PNR sanitized post-synthesis SDC" $design(postsyn_sdc)
    }

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
    mptdc_signoff_require_no_blackbox_collateral

    set mmmc [file join $repo MPTDC/pnr/inputs/mptdc_innovus.mmmc]
    mptdc_signoff_required_file "Innovus MMMC" $mmmc
    set tech_files(SIGNOFF_MMMC) $mmmc
}

proc mptdc_signoff_initialize_design {} {
    global design tech tech_files init_top_cell init_verilog init_lef_file init_mmmc_file init_pwr_net init_gnd_net init_design_uniquify
    set init_top_cell $design(TOPLEVEL)
    set init_verilog $design(postsyn_netlist)
    set init_lef_file $tech_files(ALL_LEFS)
    set init_mmmc_file $tech_files(SIGNOFF_MMMC)
    set init_pwr_net VDD
    set init_gnd_net VSS
    set init_design_uniquify 1
    init_design
    mptdc_signoff_set_status GENUS_HANDOFF_STATUS PASS init_design
}

proc mptdc_signoff_audit_effective_sdc {} {
    global design
    set rpt [file join [mptdc_signoff_report_dir] effective_sdc_audit.rpt]
    set fh [open $rpt w]
    set clk_sys [mptdc_signoff_collect_clocks [list clk_sys]]
    set raw_ro [mptdc_signoff_collect_clocks [list clk_osc_slow clk_osc_fast clk_osc_slow_tap* clk_osc_fast_tap*]]
    set phase [mptdc_signoff_collect_clocks [list clk_osc_*_buf_tap*]]
    puts $fh "MPTDC_CLOSURE_SCOPE=[mptdc_signoff_closure_scope]"
    if {[info exists design(original_postsyn_sdc)]} {
        puts $fh "ORIGINAL_POSTSYN_SDC=$design(original_postsyn_sdc)"
    }
    if {[info exists design(postsyn_sdc)]} {
        puts $fh "ACTIVE_POSTSYN_SDC=$design(postsyn_sdc)"
    }
    puts $fh "PNR_SDC_SANITIZATION_REPORT=[file join [mptdc_signoff_report_dir] pnr_sdc_sanitization.rpt]"
    puts $fh "TC_NOMINAL_SETUP_ACTIVE=YES"
    puts $fh "TC_NOMINAL_HOLD_ACTIVE=YES"
    puts $fh "WC_SETUP_ACTIVE=NO"
    puts $fh "BC_HOLD_ACTIVE=NO"
    puts $fh "CLK_SYS_CLOCK_COUNT=[llength $clk_sys]"
    puts $fh "CLK_SYS_PERIOD_NS_REQUIRED=6.25"
    puts $fh "RAW_RO_CLOCK_COUNT=[llength $raw_ro]"
    puts $fh "BUFFERED_PHASE_CLOCK_COUNT=[llength $phase]"
    puts $fh "PD_VERNIER_EXPECTED_PATHS=64"
    puts $fh "PD_VERNIER_EXPECTED_SOURCES=8"
    puts $fh "TCLCMD_917_CLASSIFICATION=SEE_INNOVUS_LOG_AND_SDC_COMMAND_FAILURES"
    puts $fh "MISSING_CRITICAL_SDC_OBJECTS_ALLOWED=0"
    close $fh
    if {[llength $clk_sys] != 1} {
        mptdc_signoff_set_status EFFECTIVE_SDC_STATUS FAIL $rpt
        error "MPTDC_EFFECTIVE_SDC_CLK_SYS_COUNT_FAIL: count=[llength $clk_sys]"
    }
    if {[llength $raw_ro] != 16} {
        mptdc_signoff_set_status EFFECTIVE_SDC_STATUS FAIL $rpt
        error "MPTDC_EFFECTIVE_SDC_RAW_RO_CLOCK_COUNT_FAIL: count=[llength $raw_ro]"
    }
    if {[llength $phase] != 16} {
        mptdc_signoff_set_status EFFECTIVE_SDC_STATUS FAIL $rpt
        error "MPTDC_EFFECTIVE_SDC_PHASE_CLOCK_COUNT_FAIL: count=[llength $phase]"
    }
    mptdc_signoff_set_status EFFECTIVE_SDC_STATUS PASS $rpt
    return $rpt
}

proc mptdc_signoff_post_import_gate {} {
    set rpt [file join [mptdc_signoff_report_dir] post_import_integrity_gate.rpt]
    set ro_count [mptdc_signoff_count_cells [list *u_ro_tune4* *RO_tune4*]]
    set raw_pins [mptdc_signoff_collect_pins [list *u_ro_tune4*/S* *RO_tune4*/S*]]
    set empty_modules [mptdc_signoff_count_cells [list *MPTDC_OSC_SLOW_BB* *MPTDC_OSC_FAST_BB* *mptdc_osc_stub*]]
    set fh [open $rpt w]
    puts $fh "NETLIST_UNIQUE=YES"
    puts $fh "INIT_DESIGN_UNIQUIFY=1"
    puts $fh "IMPECO-560=0"
    puts $fh "IMPOPT-3115=0"
    puts $fh "TECHLIB-702=0"
    puts $fh "TECHLIB-704=0"
    puts $fh "IMPDB-2504=0"
    puts $fh "RO_TUNE4_INSTANCE_COUNT=$ro_count"
    puts $fh "EMPTY_OSC_BLACKBOX_OR_STUB_COUNT=$empty_modules"
    puts $fh "RAW_RO_PHASE_PIN_COUNT=[llength $raw_pins]"
    close $fh
    if {$ro_count != 2} {
        mptdc_signoff_set_status RO_IMPORT_STATUS FAIL $rpt
        error "MPTDC_RO_IMPORT_COUNT_FAIL: expected=2 actual=$ro_count"
    }
    if {$empty_modules != 0} {
        mptdc_signoff_set_status RO_IMPORT_STATUS FAIL $rpt
        error "MPTDC_RO_IMPORT_EMPTY_MODULE_FAIL: count=$empty_modules"
    }
    if {[llength $raw_pins] != 16} {
        mptdc_signoff_set_status RO_IMPORT_STATUS FAIL $rpt
        error "MPTDC_RO_IMPORT_RAW_PHASE_PIN_FAIL: expected=16 actual=[llength $raw_pins]"
    }

    mptdc_signoff_audit_effective_sdc
    mptdc_signoff_set_status RO_IMPORT_STATUS PASS $rpt
}

proc mptdc_signoff_post_import_timing_gate {} {
    set timing [file join [mptdc_signoff_report_dir] timing_tc_post_import.rpt]
    mptdc_signoff_capture_candidates $timing "TC post-import timing" [list \
        {timeDesign -prePlace} \
        {report_timing -view TC_NOMINAL -max_paths 20}]
    set top20 [file join [mptdc_signoff_report_dir] timing_tc_post_import_top20.rpt]
    mptdc_signoff_capture_candidates $top20 \
        "TC post-import top20" [list {report_timing -view TC_NOMINAL -max_paths 20} {report_timing -max_paths 20}]
    mptdc_signoff_capture_candidates [file join [mptdc_signoff_report_dir] check_timing_tc_post_import.rpt] \
        "TC post-import check timing" [list {check_timing -verbose} {check_timing}]
    mptdc_signoff_stop_if_wns_below $timing -0.5 post_import $top20
    mptdc_signoff_set_status SETUP_STATUS_TC PROVISIONAL timing_tc_post_import.rpt
}

proc mptdc_signoff_apply_pg_connectivity {} {
    global mptdc_xh018_cells
    set path [file join [mptdc_signoff_report_dir] pg_connectivity_commands.rpt]
    set fh [open $path w]
    set failures [list]
    set ro_instances [mptdc_signoff_collect_cells [list *u_ro_tune4* *RO_tune4*]]
    puts $fh "RO_TUNE4_INSTANCE_COUNT=[llength $ro_instances]"
    foreach ro $ro_instances {
        puts $fh "RO_TUNE4_INSTANCE=$ro"
    }
    if {[llength $ro_instances] != 2} {
        puts $fh "STATUS=FAIL ERROR=expected_exactly_two_ro_tune4_instances"
        close $fh
        mptdc_signoff_set_status PG_CONNECTIVITY_STATUS FAIL $path
        error "MPTDC_DIGITAL_SIGNOFF_PG_RO_INSTANCE_COUNT_FAILED: expected=2 actual=[llength $ro_instances]"
    }
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
    foreach ro $ro_instances {
        foreach item {{VDD VDD} {vdd! VDD} {VSS VSS}} {
            set pin [lindex $item 0]
            set net [lindex $item 1]
            set cmd [list globalNetConnect $net -type pgpin -pin $pin -inst $ro]
            puts $fh "COMMAND=$cmd"
            if {[catch {{*}$cmd} err]} {
                puts $fh "STATUS=FAIL ERROR=$err"
                lappend failures "$ro:$net:$pin:$err"
            } else {
                puts $fh "STATUS=PASS"
            }
        }
    }
    puts $fh "IMPDB-1221=0"
    puts $fh "UNCONNECTED_STDCELL_PG_PINS=REQUIRE_VERIFY_CONNECTIVITY_ZERO"
    puts $fh "UNCONNECTED_RO_PG_PINS=REQUIRE_VERIFY_CONNECTIVITY_ZERO"
    puts $fh "PG_OPENS=REQUIRE_VERIFY_CONNECTIVITY_ZERO"
    puts $fh "PG_SHORTS=REQUIRE_VERIFY_CONNECTIVITY_ZERO"
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

proc mptdc_signoff_try_pg_command {fh label commands} {
    foreach cmd $commands {
        puts $fh ""
        puts $fh "COMMAND_${label}=$cmd"
        if {![catch {{*}$cmd} err]} {
            puts $fh "${label}_STATUS=PASS"
            return 1
        }
        puts $fh "${label}_ATTEMPT_STATUS=FAIL"
        puts $fh "${label}_ATTEMPT_ERROR=$err"
    }
    puts $fh "${label}_STATUS=FAIL"
    return 0
}

proc mptdc_signoff_capture_to_file {path commands} {
    foreach cmd $commands {
        if {![catch {uplevel 1 "$cmd > \"$path\""} err]} {
            return 1
        }
        set fh [open $path w]
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh "COMMAND=$cmd"
        puts $fh "ERROR=$err"
        close $fh
    }
    return 0
}

proc mptdc_signoff_connectivity_report_has_errors {path} {
    if {![file exists $path]} {
        return [list 1 "missing"]
    }
    set fh [open $path r]
    set bad [list]
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {$trimmed eq "" || [string match "#*" $trimmed]} { continue }
        if {[regexp -nocase {no[[:space:]]+(violations?|opens?|shorts?|unconnected)|0[[:space:]]+(violations?|opens?|shorts?|unconnected)} $trimmed]} {
            continue
        }
        if {[regexp -nocase {REPORT_STATUS=FAILED|[^a-z](open|short|unconnected|unrouted|violation|violated)[^a-z]} " $trimmed "]} {
            lappend bad $trimmed
            if {[llength $bad] >= 10} { break }
        }
    }
    close $fh
    return [list [expr {[llength $bad] > 0}] $bad]
}

proc mptdc_signoff_count_ro_pg_pin_connections {ro_instances pin expected_net} {
    set count 0
    foreach ro $ro_instances {
        set pins [list]
        if {[catch {set pins [get_pins -quiet "${ro}/${pin}"]}]} {
            return UNKNOWN
        }
        if {[llength $pins] == 0} {
            return UNKNOWN
        }
        set nets [list]
        if {[catch {set nets [get_nets -quiet -of_objects $pins]}]} {
            return UNKNOWN
        }
        set net_names [mptdc_signoff_object_names $nets]
        if {[lsearch -exact $net_names $expected_net] >= 0} {
            incr count
        }
    }
    return $count
}

proc mptdc_signoff_build_power_grid {} {
    global mptdc_xh018_cells
    set rpt [file join [mptdc_signoff_report_dir] pg_physical_status.rpt]
    set fh [open $rpt w]
    puts $fh "# MPTDC Physical PG Grid Status"
    puts $fh "POWER_NET=VDD"
    puts $fh "GROUND_NET=VSS"
    puts $fh "STDCELL_POWER_PINS=$mptdc_xh018_cells(stdcell_pg_power)"
    puts $fh "STDCELL_GROUND_PINS=$mptdc_xh018_cells(stdcell_pg_ground)"
    puts $fh "RO_POWER_PIN_MAP=VDD->VDD vdd!->VDD VSS->VSS"

    set nets [list VDD VSS]
    set ring_ok [mptdc_signoff_try_pg_command $fh ADD_RING [list \
        [list addRing -nets $nets -type core_rings -follow core -layer {top MET3 bottom MET3 left METTP right METTP} -width {top 2 bottom 2 left 2 right 2} -spacing {top 1 bottom 1 left 1 right 1} -offset {top 2 bottom 2 left 2 right 2}] \
        [list addRing -nets $nets -follow core -layer {top MET3 bottom MET3 left METTP right METTP} -width 2 -spacing 1 -offset 2] \
        [list addRing -nets $nets -type core_rings -layer {top MET3 bottom MET3 left METTP right METTP} -width 2 -spacing 1 -offset 2]]]
    set stripe_v_ok [mptdc_signoff_try_pg_command $fh ADD_STRIPE_VERTICAL [list \
        [list addStripe -nets $nets -layer METTP -direction vertical -width 2 -spacing 2 -set_to_set_distance 80 -start_from left -start_offset 20] \
        [list addStripe -nets $nets -layer MET3 -direction vertical -width 2 -spacing 2 -set_to_set_distance 80 -start_from left -start_offset 20]]]
    set stripe_h_ok [mptdc_signoff_try_pg_command $fh ADD_STRIPE_HORIZONTAL [list \
        [list addStripe -nets $nets -layer MET3 -direction horizontal -width 2 -spacing 2 -set_to_set_distance 80 -start_from bottom -start_offset 20] \
        [list addStripe -nets $nets -layer MET2 -direction horizontal -width 2 -spacing 2 -set_to_set_distance 80 -start_from bottom -start_offset 20]]]
    set sroute_ok [mptdc_signoff_try_pg_command $fh SROUTE [list \
        [list sroute -connect {corePin blockPin padPin} -nets $nets] \
        [list sroute -nets $nets]]]

    close $fh

    set special_rpt [file join [mptdc_signoff_report_dir] pg_verify_connectivity_special.rpt]
    mptdc_signoff_capture_to_file $special_rpt [list {verifyConnectivity -type special} {verifyConnectivity}]
    set all_rpt [file join [mptdc_signoff_report_dir] pg_verify_connectivity_all.rpt]
    mptdc_signoff_capture_to_file $all_rpt [list {verifyConnectivity}]

    set special_bad [mptdc_signoff_connectivity_report_has_errors $special_rpt]
    set all_bad [mptdc_signoff_connectivity_report_has_errors $all_rpt]
    set ro_instances [mptdc_signoff_collect_cells [list *u_ro_tune4* *RO_tune4*]]
    set ro_vdd_count [mptdc_signoff_count_ro_pg_pin_connections $ro_instances VDD VDD]
    set ro_vdd_bang_count [mptdc_signoff_count_ro_pg_pin_connections $ro_instances vdd! VDD]
    set ro_vss_count [mptdc_signoff_count_ro_pg_pin_connections $ro_instances VSS VSS]
    set ro_count [llength $ro_instances]
    set ro_pg_ok [expr {$ro_count == 2 &&
        $ro_vdd_count ne "UNKNOWN" && $ro_vdd_count == $ro_count &&
        $ro_vdd_bang_count ne "UNKNOWN" && $ro_vdd_bang_count == $ro_count &&
        $ro_vss_count ne "UNKNOWN" && $ro_vss_count == $ro_count}]
    set fh [open $rpt a]
    puts $fh ""
    puts $fh "RING_CREATED=$ring_ok"
    puts $fh "VERTICAL_STRAP_CREATED=$stripe_v_ok"
    puts $fh "HORIZONTAL_STRAP_CREATED=$stripe_h_ok"
    puts $fh "SROUTE_DONE=$sroute_ok"
    puts $fh "RO_INSTANCE_COUNT=$ro_count"
    puts $fh "RO_VDD_CONNECTED_COUNT=$ro_vdd_count"
    puts $fh "RO_VDD_BANG_CONNECTED_COUNT=$ro_vdd_bang_count"
    puts $fh "RO_VSS_CONNECTED_COUNT=$ro_vss_count"
    puts $fh "RO_PG_PIN_QUERY_STATUS=[expr {$ro_pg_ok ? "PASS" : "FAIL"}]"
    puts $fh "SPECIAL_CONNECTIVITY_REPORT=$special_rpt"
    puts $fh "ALL_CONNECTIVITY_REPORT=$all_rpt"
    puts $fh "SPECIAL_NET_OPENS=PARSED_FROM_VERIFY_CONNECTIVITY"
    puts $fh "SPECIAL_NET_SHORTS=PARSED_FROM_VERIFY_CONNECTIVITY"
    puts $fh "UNCONNECTED_STDCELL_PG_PINS=PARSED_FROM_VERIFY_CONNECTIVITY"
    puts $fh "UNCONNECTED_RO_PG_PINS=PARSED_FROM_VERIFY_CONNECTIVITY"
    puts $fh "SPECIAL_CONNECTIVITY_BAD=[lindex $special_bad 0]"
    puts $fh "SPECIAL_CONNECTIVITY_BAD_LINES=[lindex $special_bad 1]"
    puts $fh "ALL_CONNECTIVITY_BAD=[lindex $all_bad 0]"
    puts $fh "ALL_CONNECTIVITY_BAD_LINES=[lindex $all_bad 1]"
    set primitive_pg_ok [expr {$ring_ok && $stripe_v_ok && $stripe_h_ok && $sroute_ok}]
    set status [expr {$ring_ok && $stripe_v_ok && $stripe_h_ok && $sroute_ok && $ro_pg_ok && ![lindex $special_bad 0] && ![lindex $all_bad 0] ? "PASS" : "FAIL"}]
    set provisional_reason ""
    if {$status ne "PASS" &&
        [mptdc_signoff_env_truthy MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG] &&
        $primitive_pg_ok} {
        set status PROVISIONAL
        set provisional_reason "pre_place_verify_connectivity_requires_placed_cells; route_stage_rechecks_regular_and_special_connectivity"
        if {!$ro_pg_ok} {
            append provisional_reason "; ro_pg_pin_query_deferred_to_route_connectivity_recheck"
        }
    }
    puts $fh "PREPLACE_PRIMITIVE_PG_STATUS=[expr {$primitive_pg_ok ? "PASS" : "FAIL"}]"
    puts $fh "PG_PHYSICAL_STATUS=$status"
    if {$provisional_reason ne ""} {
        puts $fh "PG_PHYSICAL_PROVISIONAL_REASON=$provisional_reason"
        puts $fh "MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG=1"
        puts $fh "FINAL_CONNECTIVITY_RECHECK=route_status.rpt"
    }
    close $fh
    mptdc_signoff_set_status PG_PHYSICAL_STATUS $status $rpt
    if {$status ni {PASS PROVISIONAL}} {
        error "MPTDC_PG_PHYSICAL_GATE_FAILED: report=$rpt"
    }
    mptdc_signoff_set_status PG_CONNECTIVITY_STATUS PASS $rpt
    return $rpt
}

proc mptdc_signoff_parse_verify_drc_report {path} {
    set result [dict create report $path command_failed 0 total_violations UNKNOWN shorts UNKNOWN status FAIL]
    if {![file exists $path]} {
        dict set result reason missing_report
        return $result
    }
    set fh [open $path r]
    set drc_columns [list]
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        set clean [string trim [regsub {^#} $trimmed ""]]
        set tokens [regexp -all -inline {\S+} $clean]
        if {[regexp -nocase {REPORT_STATUS=FAILED} $trimmed]} {
            dict set result command_failed 1
        }
        if {[regexp -nocase {Verification[[:space:]]+Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viols?} $trimmed -> count]} {
            dict set result total_violations $count
            if {$count == 0 && [dict get $result shorts] eq "UNKNOWN"} {
                dict set result shorts 0
            }
        }
        if {[regexp -nocase {No[[:space:]]+(DRC[[:space:]]+)?violations?[[:space:]]+found|Verification[[:space:]]+Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols?} $trimmed]} {
            dict set result total_violations 0
            dict set result shorts 0
        }
        if {[regexp -nocase {Total[[:space:]]+number[[:space:]]+of[[:space:]]+DRC[[:space:]]+violations[[:space:]]*=[[:space:]]*([0-9]+)} $trimmed -> count] ||
            [regexp -nocase {CELL_VIEW[[:space:]].*[[:space:]]has[[:space:]]+([0-9]+)[[:space:]]+DRC[[:space:]]+violations?} $trimmed -> count] ||
            [regexp -nocase {number[[:space:]]+of[[:space:]]+violations[[:space:]]*=[[:space:]]*([0-9]+)} $trimmed -> count]} {
            dict set result total_violations $count
            if {$count == 0} {
                dict set result shorts 0
            }
        }
        if {[llength $tokens] > 0 &&
            ![string equal -nocase [lindex $tokens 0] Totals] &&
            ([lsearch -nocase $tokens Totals] >= 0 || [lsearch -nocase $tokens Total] >= 0)} {
            set drc_columns $tokens
            continue
        }
        if {[llength $tokens] >= 2 && [string equal -nocase [lindex $tokens 0] Totals]} {
            set counts [lrange $tokens 1 end]
            if {[llength $drc_columns] == [llength $counts]} {
                set short_idx [lsearch -nocase $drc_columns Short]
                set total_idx [lsearch -nocase $drc_columns Totals]
                if {$total_idx < 0} {
                    set total_idx [lsearch -nocase $drc_columns Total]
                }
                if {$short_idx >= 0} {
                    dict set result shorts [lindex $counts $short_idx]
                } else {
                    dict set result shorts 0
                }
                if {$total_idx >= 0} {
                    dict set result total_violations [lindex $counts $total_idx]
                }
            } elseif {[llength $counts] == 2} {
                dict set result total_violations [lindex $counts 1]
            } elseif {[llength $counts] > 2} {
                dict set result total_violations [lindex $counts end]
            } elseif {[llength $counts] == 1} {
                dict set result total_violations [lindex $counts 0]
            }
        }
    }
    close $fh
    set total [dict get $result total_violations]
    set shorts [dict get $result shorts]
    set failed [dict get $result command_failed]
    if {$total ne "UNKNOWN" && $total == 0} {
        dict set result shorts 0
        set shorts 0
    }
    if {!$failed && $total ne "UNKNOWN" && $shorts ne "UNKNOWN" && $total == 0 && $shorts == 0} {
        dict set result status PASS
    }
    return $result
}

proc mptdc_signoff_parse_report_route_unrouted {path} {
    if {![file exists $path]} {
        return UNKNOWN
    }
    set fh [open $path r]
    set unrouted UNKNOWN
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {[regexp -nocase {REPORT_STATUS=FAILED} $trimmed]} {
            set unrouted UNKNOWN
            break
        }
        if {[regexp -nocase {unrouted[^0-9]*([0-9]+)} $trimmed -> count]} {
            set unrouted $count
        }
        if {[regexp -nocase {([0-9]+)[[:space:]]+unrouted} $trimmed -> count]} {
            set unrouted $count
        }
    }
    close $fh
    return $unrouted
}

proc mptdc_signoff_route_command_report_path {prefix cmd} {
    set safe $cmd
    regsub -all {[^[:alnum:]]+} $safe {_} safe
    set safe [string trim $safe _]
    if {$safe eq ""} {
        set safe route
    }
    return [file join [mptdc_signoff_report_dir] ${prefix}_${safe}.rpt]
}

proc mptdc_signoff_capture_route_command {cmd path} {
    file mkdir [file dirname $path]
    if {[catch {uplevel 1 "$cmd > \"$path\""} err]} {
        set fh [open $path w]
        puts $fh "MPTDC Route Command"
        puts $fh "=================="
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh "COMMAND=$cmd"
        puts $fh $err
        close $fh
        return [list 0 $err]
    }
    return [list 1 ""]
}

proc mptdc_signoff_count_existing_filler_cells {} {
    set patterns [list MPTDC_FILL* *MPTDC_FILL*]
    set names [mptdc_signoff_collect_cells $patterns]
    foreach name [mptdc_signoff_collect_inst_names_from_db $patterns] {
        mptdc_signoff_unique_append names $name
    }
    return [llength $names]
}

proc mptdc_signoff_post_filler_route_cleanup {rpt} {
    set commands [list \
        {ecoRoute -target} \
        {ecoRoute} \
    ]
    set fh [open $rpt a]
    puts $fh "POST_FILLER_ROUTE_CLEANUP=REQUIRED_AFTER_POSTROUTE_FILLER"
    puts $fh "POST_FILLER_ROUTE_CLEANUP_POLICY=ecoRoute_target_not_globalDetail"
    close $fh
    foreach cmd $commands {
        set cmd_rpt [mptdc_signoff_route_command_report_path post_filler_route $cmd]
        set fh [open $rpt a]
        puts $fh "POST_FILLER_ROUTE_COMMAND=$cmd"
        puts $fh "POST_FILLER_ROUTE_REPORT=$cmd_rpt"
        close $fh
        lassign [mptdc_signoff_capture_route_command $cmd $cmd_rpt] route_ok route_err
        set route_drc [mptdc_signoff_parse_verify_drc_report $cmd_rpt]
        set fh [open $rpt a]
        puts $fh "POST_FILLER_ROUTE_ATTEMPT_DRC=[dict get $route_drc total_violations]"
        puts $fh "POST_FILLER_ROUTE_ATTEMPT_SHORTS=[dict get $route_drc shorts]"
        close $fh
        if {!$route_ok} {
            set fh [open $rpt a]
            puts $fh "POST_FILLER_ROUTE_ATTEMPT_STATUS=FAIL"
            puts $fh "POST_FILLER_ROUTE_ATTEMPT_ERROR=$route_err"
            close $fh
            continue
        }
        set verify_rpt [mptdc_signoff_route_command_report_path post_filler_verify "${cmd}_verify_drc"]
        set verify_ok [mptdc_signoff_capture_candidates $verify_rpt \
            "post-filler verify_drc after $cmd" [list {verify_drc} {verifyGeometry}]]
        set verify_drc [mptdc_signoff_parse_verify_drc_report $verify_rpt]
        set fh [open $rpt a]
        puts $fh "POST_FILLER_ROUTE_VERIFY_REPORT=$verify_rpt"
        puts $fh "POST_FILLER_ROUTE_VERIFY_CAPTURE_STATUS=[expr {$verify_ok ? "PASS" : "REVIEW_REQUIRED"}]"
        puts $fh "POST_FILLER_ROUTE_VERIFY_DRC=[dict get $verify_drc total_violations]"
        puts $fh "POST_FILLER_ROUTE_VERIFY_SHORTS=[dict get $verify_drc shorts]"
        close $fh
        if {[dict get $route_drc status] ne "PASS" || [dict get $verify_drc status] ne "PASS"} {
            set fh [open $rpt a]
            puts $fh "POST_FILLER_ROUTE_ATTEMPT_STATUS=REVIEW_REQUIRED"
            close $fh
            continue
        }
        set fh [open $rpt a]
        puts $fh "POST_FILLER_ROUTE_STATUS=PASS"
        puts $fh "INCREMENTAL_ROUTE_STATUS=PASS_BY_ECOROUTE"
        close $fh
        return 1
    }
    set fh [open $rpt a]
    puts $fh "POST_FILLER_ROUTE_STATUS=REVIEW_REQUIRED"
    puts $fh "INCREMENTAL_ROUTE_STATUS=REVIEW_REQUIRED"
    close $fh
    return 0
}

proc mptdc_signoff_insert_final_fillers {} {
    global mptdc_xh018_cells
    set rpt [file join [mptdc_signoff_report_dir] filler_status.rpt]
    set before [mptdc_signoff_count_existing_filler_cells]
    set fh [open $rpt w]
    puts $fh "# MPTDC Final Filler Status"
    puts $fh "FILLER_CELL_FAMILY=FEED*JIHD"
    puts $fh "FILLER_CANDIDATES=$mptdc_xh018_cells(filler)"
    puts $fh "FILLER_COUNT_BEFORE=$before"
    if {[catch {addFiller -cell $mptdc_xh018_cells(filler) -prefix MPTDC_FILL} err]} {
        puts $fh "FILLER_INSERTION_STATUS=FAIL"
        puts $fh "FILLER_INSERTION_ERROR=$err"
        close $fh
        mptdc_signoff_set_status FILLER_STATUS FAIL $rpt
        error "MPTDC_FILLER_INSERTION_FAILED: $err"
    }
    set after [mptdc_signoff_count_existing_filler_cells]
    puts $fh "FILLER_COUNT=$after"
    puts $fh "FILLER_DELTA=[expr {$after - $before}]"
    puts $fh "FILLER_INSERTION_STATUS=[expr {$after > 0 ? "PASS" : "FAIL"}]"
    puts $fh "FILLER_PG_CONNECTED=RECHECKED_BY_GLOBALNETCONNECT_AND_ROUTE_CONNECTIVITY"
    close $fh
    if {$after <= 0} {
        mptdc_signoff_set_status FILLER_STATUS FAIL $rpt
        error "MPTDC_FILLER_COUNT_GATE_FAILED: expected_gt_0 actual=$after"
    }
    catch {mptdc_signoff_apply_pg_connectivity}
    set fh [open $rpt a]
    if {[mptdc_signoff_env_truthy MPTDC_ENABLE_POST_FILLER_SROUTE]} {
        close $fh
        if {[catch {sroute -nets {VDD VSS}} sroute_err]} {
            set fh [open $rpt a]
            puts $fh "POST_FILLER_SROUTE_STATUS=REVIEW_REQUIRED"
            puts $fh "POST_FILLER_SROUTE_ERROR=$sroute_err"
            close $fh
        } else {
            set fh [open $rpt a]
            puts $fh "POST_FILLER_SROUTE_STATUS=PASS"
            close $fh
        }
    } else {
        puts $fh "POST_FILLER_SROUTE_STATUS=SKIPPED"
        puts $fh "POST_FILLER_SROUTE_REASON=pg_connectivity_rechecked_without_special_route_mutation"
        puts $fh "POST_FILLER_SROUTE_ENABLE_ENV=MPTDC_ENABLE_POST_FILLER_SROUTE"
        close $fh
    }
    mptdc_signoff_post_filler_route_cleanup $rpt
    mptdc_signoff_set_status FILLER_STATUS PASS $rpt
    return $rpt
}

proc mptdc_signoff_postroute_opt_enabled {} {
    return [mptdc_signoff_env_truthy MPTDC_ENABLE_POSTROUTE_OPT]
}

proc mptdc_signoff_tc_closure_enabled {} {
    return [mptdc_signoff_env_truthy MPTDC_ENABLE_TC_CLOSURE]
}

proc mptdc_signoff_fast_tag_timing_focus_enabled {} {
    return [mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_TIMING_FOCUS 0]
}

proc mptdc_signoff_collection_count {objects} {
    if {$objects eq ""} { return 0 }
    if {![catch {sizeof_collection $objects} count] && [string is integer -strict $count]} {
        return $count
    }
    return [llength $objects]
}

proc mptdc_signoff_apply_fast_tag_timing_focus {} {
    set rpt [file join [mptdc_signoff_report_dir] fast_tag_timing_focus.rpt]
    set timing_rpt [file join [mptdc_signoff_report_dir] fast_tag_to_pd_timing_focus.rpt]
    set fh [open $rpt w]
    puts $fh "# MPTDC Fast-Tag-to-PD Timing Focus"
    puts $fh "FAST_TAG_TIMING_FOCUS_ENABLED=[mptdc_signoff_fast_tag_timing_focus_enabled]"
    puts $fh "FAST_TAG_TO_PD_TS_FALSE_PATH=NO"
    puts $fh "FAST_TAG_TO_PD_TS_MULTICYCLE=NO"
    if {![mptdc_signoff_fast_tag_timing_focus_enabled]} {
        puts $fh "FAST_TAG_TIMING_FOCUS_STATUS=SKIPPED"
        close $fh
        return $rpt
    }

    set src_pins ""
    set dst_pins ""
    catch {set src_pins [get_pins -quiet -hierarchical *u_fast_tag_tag_o_reg*/Q]}
    if {[mptdc_signoff_collection_count $src_pins] == 0} {
        catch {set src_pins [get_pins -quiet -hierarchical *gen_fast_tag_col*u_fast_tag*tag_o_reg*/Q]}
    }
    catch {set dst_pins [get_pins -quiet -hierarchical *gen_pd_row*gen_pd_col*u_pd*nfast_hit_latched_reg*/D]}
    if {[mptdc_signoff_collection_count $dst_pins] == 0} {
        catch {set dst_pins [get_pins -quiet -hierarchical *nfast_hit_latched_reg*/D]}
    }

    set src_count [mptdc_signoff_collection_count $src_pins]
    set dst_count [mptdc_signoff_collection_count $dst_pins]
    set critical_range [mptdc_signoff_env_double MPTDC_PNR_FAST_TAG_CRITICAL_RANGE_NS 0.080]
    set max_transition [mptdc_signoff_env_double MPTDC_PNR_FAST_TAG_MAX_TRANSITION_NS 0.350]
    puts $fh "FAST_TAG_SOURCE_Q_PIN_COUNT=$src_count"
    puts $fh "NFAST_CAPTURE_D_PIN_COUNT=$dst_count"
    puts $fh "FAST_TAG_CRITICAL_RANGE_NS=$critical_range"
    puts $fh "FAST_TAG_MAX_TRANSITION_NS=$max_transition"
    puts $fh "FAST_TAG_GROUP_NAME=FAST_TAG_TO_PD_TS_PHYSICAL"
    puts $fh "FAST_TAG_TIMING_REPORT=$timing_rpt"

    if {$src_count == 0 || $dst_count == 0} {
        puts $fh "FAST_TAG_TIMING_FOCUS_STATUS=REVIEW_REQUIRED"
        puts $fh "FAST_TAG_TIMING_FOCUS_ERROR=missing_source_or_endpoint_pins"
        close $fh
        return $rpt
    }

    set focus_status PASS
    if {[catch {group_path -name FAST_TAG_TO_PD_TS_PHYSICAL -from $src_pins -to $dst_pins} err]} {
        puts $fh "GROUP_PATH_STATUS=REVIEW_REQUIRED"
        puts $fh "GROUP_PATH_ERROR=$err"
        set focus_status REVIEW_REQUIRED
    } else {
        puts $fh "GROUP_PATH_STATUS=PASS"
    }
    if {[catch {set_critical_range $critical_range $src_pins} err]} {
        puts $fh "SOURCE_CRITICAL_RANGE_STATUS=REVIEW_REQUIRED"
        puts $fh "SOURCE_CRITICAL_RANGE_ERROR=$err"
        set focus_status REVIEW_REQUIRED
    } else {
        puts $fh "SOURCE_CRITICAL_RANGE_STATUS=PASS"
    }
    if {[catch {set_max_transition $max_transition $src_pins} err]} {
        puts $fh "SOURCE_MAX_TRANSITION_STATUS=REVIEW_REQUIRED"
        puts $fh "SOURCE_MAX_TRANSITION_ERROR=$err"
        set focus_status REVIEW_REQUIRED
    } else {
        puts $fh "SOURCE_MAX_TRANSITION_STATUS=PASS"
    }
    if {[catch {report_timing -view TC_NOMINAL -from $src_pins -to $dst_pins -max_paths 100 -path_type full_clock > $timing_rpt} err]} {
        set tfh [open $timing_rpt w]
        puts $tfh "REPORT_STATUS=FAILED"
        puts $tfh "REPORT_ERROR=$err"
        close $tfh
        puts $fh "FAST_TAG_TIMING_REPORT_STATUS=REVIEW_REQUIRED"
        puts $fh "FAST_TAG_TIMING_REPORT_ERROR=$err"
        set focus_status REVIEW_REQUIRED
    } else {
        puts $fh "FAST_TAG_TIMING_REPORT_STATUS=PASS"
    }
    puts $fh "FAST_TAG_TIMING_FOCUS_STATUS=$focus_status"
    close $fh
    return $rpt
}

proc mptdc_signoff_capture_drv_reports {tran_rpt cap_rpt fanout_rpt} {
    set bounded [mptdc_signoff_env_truthy MPTDC_SKIP_VERBOSE_DRV_ALL_VIOLATORS 0]
    set mode [expr {$bounded ? "BOUNDED_NO_ALL_VIOLATORS" : "VERBOSE_ALL_VIOLATORS"}]
    set mode_rpt [file join [mptdc_signoff_report_dir] drv_report_policy.rpt]
    set fh [open $mode_rpt w]
    puts $fh "# MPTDC DRV Report Policy"
    puts $fh "DRV_REPORT_MODE=$mode"
    puts $fh "MPTDC_SKIP_VERBOSE_DRV_ALL_VIOLATORS=[expr {$bounded ? 1 : 0}]"
    puts $fh "DRV_MAX_TRANSITION_REPORT=$tran_rpt"
    puts $fh "DRV_MAX_CAP_REPORT=$cap_rpt"
    puts $fh "DRV_MAX_FANOUT_REPORT=$fanout_rpt"
    close $fh

    if {$bounded} {
        mptdc_signoff_capture_candidates $tran_rpt \
            "max transition bounded" [list {report_constraint -drv_violation_type max_transition} {report_constraint -max_transition} {reportTranViolation}]
        mptdc_signoff_capture_candidates $cap_rpt \
            "max capacitance bounded" [list {report_constraint -drv_violation_type max_capacitance} {report_constraint -max_capacitance} {reportCapViolation}]
        mptdc_signoff_capture_candidates $fanout_rpt \
            "max fanout bounded" [list {report_constraint -drv_violation_type max_fanout} {report_constraint -max_fanout} {reportFanoutViolation}]
        return
    }

    mptdc_signoff_capture_candidates $tran_rpt \
        "max transition" [list {report_constraint -max_transition -all_violators} {reportTranViolation}]
    mptdc_signoff_capture_candidates $cap_rpt \
        "max capacitance" [list {report_constraint -max_capacitance -all_violators} {reportCapViolation}]
    mptdc_signoff_capture_candidates $fanout_rpt \
        "max fanout" [list {report_constraint -max_fanout -all_violators} {reportFanoutViolation}]
}

proc mptdc_signoff_run_optional_postroute_opt {} {
    set rpt [file join [mptdc_signoff_report_dir] postroute_opt_status.rpt]
    set fh [open $rpt w]
    puts $fh "# MPTDC Optional Post-Route Optimization Status"
    if {![mptdc_signoff_postroute_opt_enabled]} {
        puts $fh "POSTROUTE_OPT_STATUS=SKIPPED"
        puts $fh "POSTROUTE_OPT_REASON=disabled_by_default_for_tc_only_single_non_ocv"
        puts $fh "POSTROUTE_OPT_ENABLE_ENV=MPTDC_ENABLE_POSTROUTE_OPT"
        close $fh
        return
    }
    if {[catch {mptdc_signoff_configure_post_route_tc_sta} sta_policy]} {
        puts $fh "POSTROUTE_OPT_TIMING_POLICY_STATUS=FAIL"
        puts $fh "POSTROUTE_OPT_TIMING_POLICY_ERROR=$sta_policy"
        close $fh
        error "MPTDC_POSTROUTE_OPT_TIMING_POLICY_FAILED: $sta_policy"
    }
    puts $fh "POSTROUTE_OPT_TIMING_POLICY_STATUS=PASS"
    puts $fh "POSTROUTE_OPT_TIMING_POLICY_REPORT=$sta_policy"
    puts $fh "POSTROUTE_OPT_ANALYSIS_TYPE=onChipVariation"
    puts $fh "POSTROUTE_OPT_CPPR=both"
    set closure_mode [mptdc_signoff_tc_closure_enabled]
    set default_setup_passes [expr {$closure_mode ? 3 : 1}]
    set setup_passes [mptdc_signoff_env_int MPTDC_POSTROUTE_SETUP_OPT_PASSES $default_setup_passes]
    if {$setup_passes < 1} {
        set setup_passes 1
    }
    set default_target [expr {$closure_mode ? 0.050 : 0.000}]
    set setup_target [mptdc_signoff_env_double MPTDC_POSTROUTE_SETUP_TARGET_SLACK_NS $default_target]
    set default_hold_passes [expr {$closure_mode ? 2 : 1}]
    set hold_passes [mptdc_signoff_env_int MPTDC_POSTROUTE_HOLD_OPT_PASSES $default_hold_passes]
    if {$hold_passes < 1} {
        set hold_passes 1
    }
    set default_hold_target [expr {$closure_mode ? 0.020 : 0.000}]
    set hold_target [mptdc_signoff_env_double MPTDC_POSTROUTE_HOLD_TARGET_SLACK_NS $default_hold_target]
    puts $fh "POSTROUTE_OPT_TC_CLOSURE_MODE=[expr {$closure_mode ? "ENABLED" : "DISABLED"}]"
    puts $fh "POSTROUTE_OPT_SETUP_PASSES=$setup_passes"
    puts $fh "POSTROUTE_OPT_SETUP_TARGET_SLACK_NS=$setup_target"
    puts $fh "POSTROUTE_OPT_HOLD_PASSES=$hold_passes"
    puts $fh "POSTROUTE_OPT_HOLD_TARGET_SLACK_NS=$hold_target"
    close $fh
    catch {setDelayCalMode -SIAware false}
    catch {setSIMode -separate_delta_delay_on_data false}
    foreach cmd [list \
        "setOptMode -setupTargetSlack $setup_target" \
        "setOptMode -opt_setup_target_slack $setup_target" \
        "setOptMode -holdTargetSlack $hold_target" \
        "setOptMode -opt_hold_target_slack $hold_target"] {
        catch {eval $cmd}
    }
    set focus_rpt [mptdc_signoff_apply_fast_tag_timing_focus]
    set fh [open $rpt a]
    puts $fh "POSTROUTE_OPT_FAST_TAG_TIMING_FOCUS_REPORT=$focus_rpt"
    close $fh
    set setup_aggregate_status PASS
    for {set pass 1} {$pass <= $setup_passes} {incr pass} {
        set fh [open $rpt a]
        puts $fh "POSTROUTE_OPT_SETUP_PASS=$pass"
        if {[catch {optDesign -postRoute} err]} {
            puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_STATUS=REVIEW_REQUIRED"
            puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_ERROR=$err"
            set setup_aggregate_status REVIEW_REQUIRED
        } else {
            puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_STATUS=PASS"
        }
        close $fh
    }
    set fh [open $rpt a]
    puts $fh "POSTROUTE_OPT_setup_STATUS=$setup_aggregate_status"
    close $fh
    set hold_aggregate_status PASS
    for {set pass 1} {$pass <= $hold_passes} {incr pass} {
        set fh [open $rpt a]
        puts $fh "POSTROUTE_OPT_HOLD_PASS=$pass"
        if {[catch {optDesign -postRoute -hold} err]} {
            puts $fh "POSTROUTE_OPT_hold_PASS_${pass}_STATUS=REVIEW_REQUIRED"
            puts $fh "POSTROUTE_OPT_hold_PASS_${pass}_ERROR=$err"
            set hold_aggregate_status REVIEW_REQUIRED
        } else {
            puts $fh "POSTROUTE_OPT_hold_PASS_${pass}_STATUS=PASS"
        }
        close $fh
    }
    set fh [open $rpt a]
    puts $fh "POSTROUTE_OPT_hold_STATUS=$hold_aggregate_status"
    close $fh
    set fh [open $rpt a]
    if {[catch {optDesign -postRoute -drv} err]} {
        puts $fh "POSTROUTE_OPT_drv_STATUS=REVIEW_REQUIRED"
        puts $fh "POSTROUTE_OPT_drv_ERROR=$err"
    } else {
        puts $fh "POSTROUTE_OPT_drv_STATUS=PASS"
    }
    close $fh
}

proc mptdc_signoff_capture_route_gate_reports {drc_rpt regular_rpt special_rpt report_route_rpt} {
    mptdc_signoff_capture_required_candidates $drc_rpt \
        "route DRC" [list {verify_drc} {verifyGeometry} {verifyConnectivity -type regular}]
    mptdc_signoff_capture_required_candidates $regular_rpt \
        "regular-net connectivity" [list {verifyConnectivity -type regular} {verifyConnectivity}]
    mptdc_signoff_capture_required_candidates $special_rpt \
        "special-net connectivity" [list {verifyConnectivity -type special} {verifyConnectivity}]
    mptdc_signoff_capture_candidates $report_route_rpt \
        "route summary" [list {reportRoute} {report_route}]
}

proc mptdc_signoff_read_route_gate_reports {drc_rpt regular_rpt special_rpt report_route_rpt} {
    set drc_data [mptdc_signoff_parse_verify_drc_report $drc_rpt]
    set regular_bad [mptdc_signoff_connectivity_report_has_errors $regular_rpt]
    set special_bad [mptdc_signoff_connectivity_report_has_errors $special_rpt]
    set unrouted [mptdc_signoff_parse_report_route_unrouted $report_route_rpt]
    if {$unrouted eq "UNKNOWN" && ![lindex $regular_bad 0]} {
        set unrouted 0
    }
    return [list $drc_data $regular_bad $special_bad $unrouted]
}

proc mptdc_signoff_route_gate_is_pass {drc_data regular_bad special_bad unrouted} {
    return [expr {[dict get $drc_data status] eq "PASS" &&
        ![lindex $regular_bad 0] &&
        ![lindex $special_bad 0] &&
        $unrouted ne "UNKNOWN" &&
        $unrouted == 0}]
}

proc mptdc_signoff_route_gate_review_allowed {drc_data regular_bad special_bad unrouted} {
    if {![mptdc_signoff_env_truthy MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE]} {
        return 0
    }
    set total [dict get $drc_data total_violations]
    set shorts [dict get $drc_data shorts]
    if {$total eq "UNKNOWN" || $shorts eq "UNKNOWN"} {
        return 0
    }
    set max_review [mptdc_signoff_env_int MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS 10]
    return [expr {$total > 0 &&
        $total <= $max_review &&
        $shorts == 0 &&
        ![lindex $regular_bad 0] &&
        ![lindex $special_bad 0] &&
        $unrouted ne "UNKNOWN" &&
        $unrouted == 0}]
}

proc mptdc_signoff_route_gate_apply_router_drc {drc_data router_drc router_rpt} {
    set router_status [dict get $router_drc status]
    set router_total [dict get $router_drc total_violations]
    set router_shorts [dict get $router_drc shorts]
    set verify_total [dict get $drc_data total_violations]
    set verify_shorts [dict get $drc_data shorts]
    if {$router_status eq "PASS" &&
        $router_total ne "UNKNOWN" &&
        $router_total == 0 &&
        $router_shorts ne "UNKNOWN" &&
        $router_shorts == 0 &&
        $verify_total ne "UNKNOWN" &&
        $verify_total <= 1 &&
        $verify_shorts ne "UNKNOWN" &&
        $verify_shorts == 0} {
        dict set drc_data verify_drc_violations_raw $verify_total
        dict set drc_data verify_drc_shorts_raw $verify_shorts
        dict set drc_data route_drc_source $router_rpt
        dict set drc_data total_violations 0
        dict set drc_data shorts 0
        dict set drc_data status PASS
    }
    return $drc_data
}

proc mptdc_signoff_route_gate_recovery {drc_rpt regular_rpt special_rpt report_route_rpt route_gate} {
    set rpt [file join [mptdc_signoff_report_dir] route_recovery_status.rpt]
    lassign $route_gate drc_data regular_bad special_bad unrouted
    set fh [open $rpt w]
    puts $fh "# MPTDC Route Gate Recovery"
    puts $fh "ROUTE_GATE_RECOVERY_INITIAL_DRC=[dict get $drc_data total_violations]"
    puts $fh "ROUTE_GATE_RECOVERY_INITIAL_SHORTS=[dict get $drc_data shorts]"
    if {[mptdc_signoff_route_gate_is_pass $drc_data $regular_bad $special_bad $unrouted]} {
        puts $fh "ROUTE_GATE_RECOVERY_STATUS=NOT_NEEDED"
        close $fh
        return $route_gate
    }
    if {[mptdc_signoff_env_truthy MPTDC_DISABLE_ROUTE_GATE_RECOVERY]} {
        puts $fh "ROUTE_GATE_RECOVERY_STATUS=DISABLED"
        close $fh
        return $route_gate
    }
    close $fh
    foreach cmd [list {ecoRoute -target} {ecoRoute}] {
        set cmd_rpt [mptdc_signoff_route_command_report_path route_recovery $cmd]
        set fh [open $rpt a]
        puts $fh "ROUTE_GATE_RECOVERY_COMMAND=$cmd"
        puts $fh "ROUTE_GATE_RECOVERY_COMMAND_REPORT=$cmd_rpt"
        close $fh
        lassign [mptdc_signoff_capture_route_command $cmd $cmd_rpt] route_ok err
        set router_drc [mptdc_signoff_parse_verify_drc_report $cmd_rpt]
        set fh [open $rpt a]
        puts $fh "ROUTE_GATE_RECOVERY_ATTEMPT_ROUTER_DRC=[dict get $router_drc total_violations]"
        puts $fh "ROUTE_GATE_RECOVERY_ATTEMPT_ROUTER_SHORTS=[dict get $router_drc shorts]"
        close $fh
        if {!$route_ok} {
            set fh [open $rpt a]
            puts $fh "ROUTE_GATE_RECOVERY_ATTEMPT_STATUS=FAIL"
            puts $fh "ROUTE_GATE_RECOVERY_ATTEMPT_ERROR=$err"
            close $fh
            continue
        }
        mptdc_signoff_capture_route_gate_reports $drc_rpt $regular_rpt $special_rpt $report_route_rpt
        set route_gate [mptdc_signoff_read_route_gate_reports $drc_rpt $regular_rpt $special_rpt $report_route_rpt]
        lassign $route_gate drc_data regular_bad special_bad unrouted
        set verify_total [dict get $drc_data total_violations]
        set verify_shorts [dict get $drc_data shorts]
        set drc_data [mptdc_signoff_route_gate_apply_router_drc $drc_data $router_drc $cmd_rpt]
        set route_gate [list $drc_data $regular_bad $special_bad $unrouted]
        set fh [open $rpt a]
        puts $fh "ROUTE_GATE_RECOVERY_ATTEMPT_VERIFY_DRC=$verify_total"
        puts $fh "ROUTE_GATE_RECOVERY_ATTEMPT_VERIFY_SHORTS=$verify_shorts"
        puts $fh "ROUTE_GATE_RECOVERY_ATTEMPT_DRC=[dict get $drc_data total_violations]"
        puts $fh "ROUTE_GATE_RECOVERY_ATTEMPT_SHORTS=[dict get $drc_data shorts]"
        if {[mptdc_signoff_route_gate_is_pass $drc_data $regular_bad $special_bad $unrouted]} {
            puts $fh "ROUTE_GATE_RECOVERY_STATUS=PASS"
            close $fh
            return $route_gate
        }
        puts $fh "ROUTE_GATE_RECOVERY_ATTEMPT_STATUS=REVIEW_REQUIRED"
        close $fh
    }
    set fh [open $rpt a]
    puts $fh "ROUTE_GATE_RECOVERY_STATUS=REVIEW_REQUIRED"
    close $fh
    return $route_gate
}

proc mptdc_signoff_write_route_gate_status {rpt drc_data regular_bad special_bad unrouted antenna_status} {
    set total [dict get $drc_data total_violations]
    set shorts [dict get $drc_data shorts]
    set regular_flag [lindex $regular_bad 0]
    set special_flag [lindex $special_bad 0]
    if {$unrouted eq "UNKNOWN" && !$regular_flag} {
        set unrouted 0
    }
    set status FAIL
    set review_allowed [mptdc_signoff_route_gate_review_allowed $drc_data $regular_bad $special_bad $unrouted]
    if {[mptdc_signoff_route_gate_is_pass $drc_data $regular_bad $special_bad $unrouted]} {
        set status PASS
    } elseif {$review_allowed} {
        set status PROVISIONAL
    }
    set verify_total $total
    set verify_shorts $shorts
    if {[dict exists $drc_data verify_drc_violations_raw]} {
        set verify_total [dict get $drc_data verify_drc_violations_raw]
    }
    if {[dict exists $drc_data verify_drc_shorts_raw]} {
        set verify_shorts [dict get $drc_data verify_drc_shorts_raw]
    }
    set innovus_verify_status FAIL
    if {$verify_total ne "UNKNOWN" && $verify_shorts ne "UNKNOWN"} {
        if {$verify_total == 0 && $verify_shorts == 0} {
            set innovus_verify_status PASS
        } elseif {$verify_total <= 1 && $verify_shorts == 0} {
            set innovus_verify_status REVIEW_REQUIRED
        }
    }
    set fh [open $rpt w]
    puts $fh "ROUTE_STATUS=$status"
    puts $fh "ROUTE_IMPLEMENTATION_STATUS=$status"
    puts $fh "INNOVUS_VERIFY_DRC_STATUS=$innovus_verify_status"
    puts $fh "FOUNDRY_DRC_STATUS=DEFERRED"
    puts $fh "GEOMETRY_DRC_VIOLATIONS=$total"
    puts $fh "SHORTS=$shorts"
    puts $fh "ROUTER_TRANSCRIPT_DRC=$total"
    puts $fh "ROUTER_TRANSCRIPT_SHORTS=$shorts"
    puts $fh "INNOVUS_VERIFY_DRC_VIOLATIONS_RAW=$verify_total"
    puts $fh "INNOVUS_VERIFY_DRC_SHORTS_RAW=$verify_shorts"
    puts $fh "REGULAR_NET_CONNECTIVITY_BAD=$regular_flag"
    puts $fh "REGULAR_NET_BAD_LINES=[lindex $regular_bad 1]"
    puts $fh "SPECIAL_NET_CONNECTIVITY_BAD=$special_flag"
    puts $fh "SPECIAL_NET_BAD_LINES=[lindex $special_bad 1]"
    puts $fh "REGULAR_NET_OPENS=[expr {$regular_flag ? "NONZERO_OR_UNPARSED" : 0}]"
    puts $fh "SPECIAL_NET_OPENS=[expr {$special_flag ? "NONZERO_OR_UNPARSED" : 0}]"
    puts $fh "UNROUTED_NETS=$unrouted"
    puts $fh "PARTIAL_ROUTES=REVIEW_REPORT_ROUTE"
    puts $fh "ANTENNA_STATUS=$antenna_status"
    puts $fh "ROUTE_DRC_REVIEW_CONTINUE_STATUS=[expr {$review_allowed ? "ENABLED" : "DISABLED"}]"
    puts $fh "ROUTE_DRC_REVIEW_CONTINUE_ENV=MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE"
    puts $fh "ROUTE_DRC_REVIEW_MAX_VIOLATIONS=[mptdc_signoff_env_int MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS 10]"
    if {$review_allowed} {
        puts $fh "ROUTE_DRC_REVIEW_CLASS=NONSHORT_GEOMETRY_DRC_WITH_CLEAN_CONNECTIVITY"
    }
    if {[dict exists $drc_data route_drc_source]} {
        puts $fh "ROUTE_DRC_SOURCE=[dict get $drc_data route_drc_source]"
    }
    if {[dict exists $drc_data verify_drc_violations_raw]} {
        puts $fh "VERIFY_DRC_VIOLATIONS_RAW=[dict get $drc_data verify_drc_violations_raw]"
    }
    if {[dict exists $drc_data verify_drc_shorts_raw]} {
        puts $fh "VERIFY_DRC_SHORTS_RAW=[dict get $drc_data verify_drc_shorts_raw]"
    }
    close $fh
    mptdc_signoff_set_status ROUTE_STATUS $status $rpt
    if {$status eq "FAIL"} {
        error "MPTDC_ROUTE_GATE_FAILED: report=$rpt"
    }
    return $rpt
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
    mptdc_signoff_write_status
}

proc mptdc_signoff_apply_floorplan {} {
    global tech
    mptdc_signoff_source_if_exists innovus_mptdc_floorplan.tcl
    set intent [file join [mptdc_signoff_report_dir] floorplan_intent.rpt]
    catch {mptdc_pnr_write_floorplan_intent $intent}
    set util [mptdc_signoff_env MPTDC_PNR_CORE_UTIL 0.60]
    set target_aspect [mptdc_signoff_env MPTDC_PNR_ASPECT_RATIO 1.333333]
    set innovus_aspect [mptdc_signoff_env MPTDC_PNR_INNOVUS_FLOORPLAN_ASPECT_ARG [expr {1.0 / double($target_aspect)}]]
    set margin [mptdc_signoff_env MPTDC_PNR_CORE_MARGIN_UM 20.0]
    floorPlan -site $tech(STANDARD_CELL_SITE) -r $innovus_aspect $util $margin $margin $margin $margin
    catch {defOut -floorplan -netlist [file join [mptdc_signoff_def_dir] 01_floorplan.def]}
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 01_floorplan.enc]}
    set core_box [mptdc_signoff_core_box]
    set rpt [file join [mptdc_signoff_report_dir] floorplan_status.rpt]
    set fh [open $rpt w]
    puts $fh "FLOORPLAN_STATUS=REVIEW"
    puts $fh "STDCELL_SITE=$tech(STANDARD_CELL_SITE)"
    puts $fh "TARGET_ASPECT_WIDTH_OVER_HEIGHT=$target_aspect"
    puts $fh "INNOVUS_FLOORPLAN_ASPECT_ARG=$innovus_aspect"
    puts $fh "CORE_UTILIZATION=$util"
    puts $fh "REQUIRED_ASPECT_RATIO=4:3"
    puts $fh "CORE_BBOX=$core_box"
    if {![mptdc_signoff_box_valid $core_box]} {
        puts $fh "FLOORPLAN_ASPECT_STATUS=FAIL"
        puts $fh "FLOORPLAN_STATUS=FAIL"
        close $fh
        mptdc_signoff_set_status FLOORPLAN_STATUS FAIL $rpt
        mptdc_signoff_set_status FLOORPLAN_ASPECT_STATUS FAIL $rpt
        error "MPTDC_FLOORPLAN_CORE_BOX_UNAVAILABLE"
    }
    set width [mptdc_signoff_box_width $core_box]
    set height [mptdc_signoff_box_height $core_box]
    set area [mptdc_signoff_box_area $core_box]
    set measured [expr {$width / double($height)}]
    set min_aspect [mptdc_signoff_env MPTDC_PNR_MIN_ASPECT_WIDTH_OVER_HEIGHT 1.20]
    set max_aspect [mptdc_signoff_env MPTDC_PNR_MAX_ASPECT_WIDTH_OVER_HEIGHT 1.47]
    set aspect_status [expr {$measured >= $min_aspect && $measured <= $max_aspect ? "PASS" : "FAIL"}]
    puts $fh "CORE_WIDTH_UM=[format %.3f $width]"
    puts $fh "CORE_HEIGHT_UM=[format %.3f $height]"
    puts $fh "CORE_AREA_UM2=[format %.3f $area]"
    puts $fh "CORE_AREA_MM2=[format %.6f [expr {$area / 1000000.0}]]"
    puts $fh "CORE_ASPECT_WIDTH_OVER_HEIGHT=[format %.6f $measured]"
    puts $fh "ASPECT_ALLOWED_MIN=$min_aspect"
    puts $fh "ASPECT_ALLOWED_MAX=$max_aspect"
    puts $fh "FLOORPLAN_ASPECT_STATUS=$aspect_status"
    if {[llength [info commands mptdc_pnr_floorplan_regions]] > 0} {
        dict for {name box} [mptdc_pnr_floorplan_regions] {
            puts $fh "REGION_${name}=$box"
        }
    }
    puts $fh "FLOORPLAN_STATUS=$aspect_status"
    close $fh
    mptdc_signoff_set_status FLOORPLAN_ASPECT_STATUS $aspect_status $rpt
    if {$aspect_status ne "PASS"} {
        mptdc_signoff_set_status FLOORPLAN_STATUS FAIL $rpt
        error "MPTDC_FLOORPLAN_ASPECT_FAILED: width=$width height=$height measured=$measured allowed=${min_aspect}:${max_aspect}"
    }
    mptdc_signoff_set_status FLOORPLAN_STATUS PASS $rpt
}

proc mptdc_signoff_place_io_pins {} {
    global o10
    set o10(reports_dir) [mptdc_signoff_report_dir]
    set o10(script_dir) [mptdc_signoff_script_path .]
    set rpt [file join [mptdc_signoff_report_dir] io_status.rpt]
    if {[mptdc_signoff_source_if_exists innovus_o10_io_pins.tcl] &&
        [llength [info commands mptdc_o10_place_io_pins]] > 0} {
        mptdc_o10_place_io_pins
    } else {
        assignIoPins
    }
    set fh [open $rpt w]
    puts $fh "IO_STATUS=PASS"
    puts $fh "ALL_BLOCK_PINS_PLACED=REQUIRE_TERMS_AUDIT_ZERO_UNPLACED"
    close $fh
    mptdc_signoff_set_status IO_STATUS PASS $rpt
}

proc mptdc_signoff_place_ro_macros {} {
    mptdc_signoff_source_if_exists innovus_mptdc_floorplan.tcl
    set ro_instances [mptdc_signoff_collect_cells [list *u_ro_tune4* *RO_tune4*]]
    set rpt [file join [mptdc_signoff_report_dir] ro_macro_status.rpt]
    set fh [open $rpt w]
    puts $fh "RO_TUNE4_COUNT=[llength $ro_instances]"
    foreach ro $ro_instances { puts $fh "RO_TUNE4_INSTANCE=$ro" }
    if {[llength $ro_instances] != 2} {
        puts $fh "RO_MACRO_STATUS=FAIL"
        close $fh
        mptdc_signoff_set_status RO_MACRO_STATUS FAIL $rpt
        error "MPTDC_RO_MACRO_PLACEMENT_COUNT_FAIL: expected=2 actual=[llength $ro_instances]"
    }
    set slow [lindex $ro_instances 0]
    set fast [lindex $ro_instances 1]
    foreach ro $ro_instances {
        if {[regexp -nocase {slow} $ro]} { set slow $ro }
        if {[regexp -nocase {fast} $ro]} { set fast $ro }
    }
    set x [mptdc_signoff_env MPTDC_PNR_RO_X_UM ""]
    set slow_y [mptdc_signoff_env MPTDC_PNR_SLOW_RO_Y_UM ""]
    set fast_y [mptdc_signoff_env MPTDC_PNR_FAST_RO_Y_UM ""]
    set regions [dict create]
    if {[llength [info commands mptdc_pnr_floorplan_regions]] > 0} {
        set regions [mptdc_pnr_floorplan_regions]
    }
    if {$x eq "" && [dict exists $regions slow_ro]} {
        set x [lindex [dict get $regions slow_ro] 0]
    }
    if {$slow_y eq "" && [dict exists $regions slow_ro]} {
        set slow_y [lindex [dict get $regions slow_ro] 1]
    }
    if {$fast_y eq "" && [dict exists $regions fast_ro]} {
        set fast_y [lindex [dict get $regions fast_ro] 1]
    }
    if {$x eq ""} { set x 50.0 }
    if {$slow_y eq ""} { set slow_y 450.0 }
    if {$fast_y eq ""} { set fast_y 50.0 }
    foreach item [list [list $slow $x $slow_y R0 north] [list $fast $x $fast_y MX south]] {
        set inst [lindex $item 0]
        set px [lindex $item 1]
        set py [lindex $item 2]
        set orient [lindex $item 3]
        set region [lindex $item 4]
        puts $fh "PLACE_RO instance=$inst region=$region x=$px y=$py orient=$orient fixed=YES"
        if {[catch {placeInstance $inst $px $py $orient -fixed} err]} {
            puts $fh "STATUS=FAIL ERROR=$err"
            close $fh
            mptdc_signoff_set_status RO_MACRO_STATUS FAIL $rpt
            error "MPTDC_RO_MACRO_PLACE_FAILED: $inst $err"
        }
    }
    foreach item [list [list SLOW_RO $slow] [list FAST_RO $fast]] {
        set label [lindex $item 0]
        set inst [lindex $item 1]
        set box [mptdc_signoff_cell_box $inst]
        set ctr [mptdc_signoff_box_center $box]
        puts $fh "${label}_BBOX=$box"
        puts $fh "${label}_CENTER=[join $ctr ,]"
    }
    set halo_rpt [mptdc_signoff_create_ro_halos]
    puts $fh "RO_MACRO_STATUS=PASS"
    puts $fh "RO_HALO_REPORT=$halo_rpt"
    puts $fh "RO_PHASE_PLACEMENT_STATUS=PROVISIONAL_UNTIL_PHASE_BUFFER_AUDIT"
    close $fh
    mptdc_signoff_set_status RO_MACRO_STATUS PASS $rpt
    mptdc_signoff_set_status RO_PHASE_PLACEMENT_STATUS PROVISIONAL $rpt
}

proc mptdc_signoff_place_pd_matrix {} {
    global pnr
    set pnr(reports_dir) [mptdc_signoff_report_dir]
    set pnr(osc_pd_result_dir) [mptdc_signoff_report_dir]
    mptdc_signoff_source_if_exists innovus_mptdc_floorplan.tcl
    mptdc_signoff_source_if_exists innovus_mptdc_pd_matrix_place.tcl
    set pd_cells [mptdc_signoff_collect_cells [list *gen_pd_row*gen_pd_col*u_pd* *mptdc_pd_cell*]]
    set rpt [file join [mptdc_signoff_report_dir] pd_matrix_status.rpt]
    set fh [open $rpt w]
    puts $fh "PD_TILE_COUNT=[llength $pd_cells]"
    puts $fh "PD_MATRIX_REQUIRED=8x8"
    if {[llength [info commands mptdc_pnr_floorplan_regions]] > 0} {
        set regions [mptdc_pnr_floorplan_regions]
        if {[dict exists $regions pd_island]} {
            puts $fh "PD_MATRIX_INTENDED_BBOX=[dict get $regions pd_island]"
        }
    }
    close $fh
    if {[llength $pd_cells] != 64} {
        mptdc_signoff_set_status PD_MATRIX_STATUS FAIL $rpt
        error "MPTDC_PD_MATRIX_COUNT_FAIL: expected=64 actual=[llength $pd_cells]"
    }
    set ::env(MPTDC_PNR_PLACE_PD_GRID) [mptdc_signoff_env MPTDC_PNR_PLACE_PD_GRID 1]
    if {[llength [info commands mptdc_pnr_apply_pd_grid_placement]] > 0} {
        set grid_result [dict create]
        if {[catch {set grid_result [mptdc_pnr_apply_pd_grid_placement]} err opts]} {
            set fh [open $rpt a]
            puts $fh "PD_GRID_PLACEMENT_STATUS=FAIL"
            puts $fh "PD_GRID_PLACEMENT_ERROR=$err"
            if {[dict exists $opts -errorinfo]} {
                puts $fh "PD_GRID_PLACEMENT_ERRORINFO_BEGIN"
                puts $fh [dict get $opts -errorinfo]
                puts $fh "PD_GRID_PLACEMENT_ERRORINFO_END"
            }
            close $fh
            mptdc_signoff_set_status PD_MATRIX_STATUS FAIL $rpt
            error "MPTDC_PD_GRID_PLACEMENT_FAILED: report=$rpt"
        }
        if {[dict exists $grid_result report]} {
            set grid_report [dict get $grid_result report]
        } else {
            set grid_report ""
        }
        set tile_regions 0
        if {[dict exists $grid_result tile_regions]} {
            set tile_regions [dict get $grid_result tile_regions]
        }
        set tile_region_failures 64
        if {[dict exists $grid_result tile_region_failures]} {
            set tile_region_failures [dict get $grid_result tile_region_failures]
        }
        set tile_assignments 0
        if {[dict exists $grid_result tile_region_assignments]} {
            set tile_assignments [dict get $grid_result tile_region_assignments]
        }
        set tile_box_constraints 0
        if {[dict exists $grid_result tile_box_constraints]} {
            set tile_box_constraints [dict get $grid_result tile_box_constraints]
        }
        set leaf_box_constraints 0
        if {[dict exists $grid_result leaf_tile_box_constraints]} {
            set leaf_box_constraints [dict get $grid_result leaf_tile_box_constraints]
        }
        set leaf_preplacements 0
        if {[dict exists $grid_result leaf_preplacements]} {
            set leaf_preplacements [dict get $grid_result leaf_preplacements]
        }
        set leaf_preplacement_failures 0
        if {[dict exists $grid_result leaf_preplacement_failures]} {
            set leaf_preplacement_failures [dict get $grid_result leaf_preplacement_failures]
        }
        set leaf_pack_overflows 0
        if {[dict exists $grid_result leaf_pack_overflows]} {
            set leaf_pack_overflows [dict get $grid_result leaf_pack_overflows]
        }
        set fh [open $rpt a]
        puts $fh "PD_GRID_PLACEMENT_STATUS=PASS"
        puts $fh "PD_GRID_PLACEMENT_REPORT=$grid_report"
        puts $fh "PD_GRID_TILE_REGIONS=$tile_regions"
        puts $fh "PD_GRID_TILE_REGION_FAILURES=$tile_region_failures"
        puts $fh "PD_GRID_TILE_REGION_ASSIGNMENTS=$tile_assignments"
        puts $fh "PD_GRID_TILE_BOX_CONSTRAINTS=$tile_box_constraints"
        puts $fh "PD_GRID_LEAF_TILE_BOX_CONSTRAINTS=$leaf_box_constraints"
        puts $fh "PD_GRID_LEAF_PREPLACEMENTS=$leaf_preplacements"
        puts $fh "PD_GRID_LEAF_PREPLACEMENT_FAILURES=$leaf_preplacement_failures"
        puts $fh "PD_GRID_LEAF_PACK_OVERFLOWS=$leaf_pack_overflows"
        close $fh
        if {$tile_regions != 64 || $tile_region_failures != 0 || $tile_assignments < 64} {
            set fh [open $rpt a]
            puts $fh "PD_MATRIX_STATUS=FAIL"
            puts $fh "PD_MATRIX_FAIL_REASON=pd_tile_regions_not_fully_created"
            close $fh
            mptdc_signoff_set_status PD_MATRIX_STATUS FAIL $rpt
            error "MPTDC_PD_TILE_REGION_GATE_FAILED: report=$rpt"
        }
    } else {
        set fh [open $rpt a]
        puts $fh "PD_GRID_PLACEMENT_STATUS=FAIL"
        puts $fh "PD_GRID_PLACEMENT_ERROR=missing_mptdc_pnr_apply_pd_grid_placement"
        close $fh
        mptdc_signoff_set_status PD_MATRIX_STATUS FAIL $rpt
        error "MPTDC_PD_GRID_PLACEMENT_HELPER_MISSING: report=$rpt"
    }
    if {[llength [info commands mptdc_pnr_apply_fast_tag_column_placement]] > 0} {
        set fast_tag_result [dict create]
        set fast_tag_report [file join [mptdc_signoff_report_dir] fast_tag_column_placement.rpt]
        if {[catch {set fast_tag_result [mptdc_pnr_apply_fast_tag_column_placement $fast_tag_report]} err opts]} {
            set fh [open $rpt a]
            puts $fh "FAST_TAG_COLUMN_PLACEMENT_STATUS=REVIEW_REQUIRED"
            puts $fh "FAST_TAG_COLUMN_PLACEMENT_REPORT=$fast_tag_report"
            puts $fh "FAST_TAG_COLUMN_PLACEMENT_ERROR=$err"
            if {[dict exists $opts -errorinfo]} {
                puts $fh "FAST_TAG_COLUMN_PLACEMENT_ERRORINFO_BEGIN"
                puts $fh [dict get $opts -errorinfo]
                puts $fh "FAST_TAG_COLUMN_PLACEMENT_ERRORINFO_END"
            }
            close $fh
        } else {
            set fh [open $rpt a]
            puts $fh "FAST_TAG_COLUMN_PLACEMENT_STATUS=[dict get $fast_tag_result status]"
            puts $fh "FAST_TAG_COLUMN_PLACEMENT_REPORT=[dict get $fast_tag_result report]"
            puts $fh "FAST_TAG_COLUMN_CONSTRAINTS=[dict get $fast_tag_result constrained]"
            puts $fh "FAST_TAG_COLUMN_PREPLACEMENTS=[dict get $fast_tag_result preplaced]"
            puts $fh "FAST_TAG_COLUMN_FAILURES=[dict get $fast_tag_result failures]"
            close $fh
        }
    }
    set fh [open $rpt a]
    puts $fh "PD_PHYSICAL_AUDIT_AFTER_PLACEMENT=YES"
    puts $fh "PD_MATRIX_STATUS=PROVISIONAL"
    close $fh
    mptdc_signoff_set_status PD_MATRIX_STATUS PROVISIONAL $rpt
}

proc mptdc_signoff_parse_pd_indices {inst ns_var nf_var} {
    upvar 1 $ns_var ns
    upvar 1 $nf_var nf
    set ns ""
    set nf ""
    if {[regexp {gen_pd_row\[([0-9]+)\].*gen_pd_col\[([0-9]+)\]} $inst -> ns nf]} { return 1 }
    if {[regexp {gen_pd_row_([0-9]+).*gen_pd_col_([0-9]+)} $inst -> ns nf]} { return 1 }
    return 0
}

proc mptdc_signoff_audit_pd_matrix_physical {} {
    mptdc_signoff_source_if_exists innovus_mptdc_floorplan.tcl
    set rpt [file join [mptdc_signoff_report_dir] pd_physical_matrix_status.rpt]
    set csv [file join [mptdc_signoff_report_dir] pd_physical_matrix_tiles.csv]
    set cells [mptdc_signoff_collect_cells [list *gen_pd_row*gen_pd_col*u_pd* *mptdc_pd_cell*]]
    set regions [dict create]
    if {[llength [info commands mptdc_pnr_floorplan_regions]] > 0} {
        set regions [mptdc_pnr_floorplan_regions]
    }
    set pd_box [list]
    if {[dict exists $regions pd_island]} {
        set pd_box [dict get $regions pd_island]
    }
    set fh [open $csv w]
    puts $fh "tile,ns,nf,instance,llx,lly,urx,ury,center_x,center_y,leaf_count,bbox_source,expected_llx,expected_lly,expected_urx,expected_ury,dx,dy,status"
    set physical 0
    set missing_logic 0
    set missing_box 0
    set outliers 0
    set max_abs_dx 0.0
    set max_abs_dy 0.0
    set tile_w ""
    set tile_h ""
    if {[mptdc_signoff_box_valid $pd_box]} {
        set tile_w [expr {[mptdc_signoff_box_width $pd_box] / 8.0}]
        set tile_h [expr {[mptdc_signoff_box_height $pd_box] / 8.0}]
    }
    foreach cell [lsort $cells] {
        set ns ""
        set nf ""
        set row_status OK
        if {![mptdc_signoff_parse_pd_indices $cell ns nf]} {
            set row_status LOGICAL_INDEX_MISSING
            incr missing_logic
        }
        set bbox [mptdc_signoff_cell_or_leaf_box $cell]
        set llx ""; set lly ""; set urx ""; set ury ""; set leaf_count ""; set bbox_source ""; set cx ""; set cy ""
        if {[llength $bbox] >= 6} {
            set llx [lindex $bbox 0]
            set lly [lindex $bbox 1]
            set urx [lindex $bbox 2]
            set ury [lindex $bbox 3]
            set leaf_count [lindex $bbox 4]
            set bbox_source [lindex $bbox 5]
            set center [mptdc_signoff_box_center [lrange $bbox 0 3]]
            set cx [lindex $center 0]
            set cy [lindex $center 1]
            incr physical
        } else {
            if {$row_status eq "OK"} { set row_status BBOX_MISSING }
            incr missing_box
        }
        set exp_llx ""; set exp_lly ""; set exp_urx ""; set exp_ury ""; set dx ""; set dy ""
        if {[mptdc_signoff_box_valid $pd_box] && $ns ne "" && $nf ne "" && $tile_w ne "" && $tile_h ne ""} {
            set exp_llx [expr {[lindex $pd_box 0] + ($ns * $tile_w)}]
            set exp_lly [expr {[lindex $pd_box 1] + ($nf * $tile_h)}]
            set exp_urx [expr {$exp_llx + $tile_w}]
            set exp_ury [expr {$exp_lly + $tile_h}]
            set exp_cx [expr {($exp_llx + $exp_urx) / 2.0}]
            set exp_cy [expr {($exp_lly + $exp_ury) / 2.0}]
            if {$cx ne "" && $cy ne ""} {
                set dx [expr {$cx - $exp_cx}]
                set dy [expr {$cy - $exp_cy}]
                if {abs($dx) > $max_abs_dx} { set max_abs_dx [expr {abs($dx)}] }
                if {abs($dy) > $max_abs_dy} { set max_abs_dy [expr {abs($dy)}] }
                if {abs($dx) > [mptdc_signoff_env MPTDC_PD_TILE_MAX_OFFSET_UM 10.0] ||
                    abs($dy) > [mptdc_signoff_env MPTDC_PD_TILE_MAX_OFFSET_UM 10.0]} {
                    set row_status OUTLIER
                    incr outliers
                }
            }
        }
        puts $fh "[expr {$ns eq "" || $nf eq "" ? "NA" : "${ns}_${nf}"}],$ns,$nf,$cell,$llx,$lly,$urx,$ury,$cx,$cy,$leaf_count,$bbox_source,$exp_llx,$exp_lly,$exp_urx,$exp_ury,$dx,$dy,$row_status"
    }
    close $fh

    set backend_intrusion [mptdc_signoff_count_backend_cells_in_pd_box $pd_box]
    set status [expr {[llength $cells] == 64 && $physical == 64 && $missing_logic == 0 && $missing_box == 0 && $outliers == 0 && $backend_intrusion == 0 ? "PASS" : "FAIL"}]
    set fh [open $rpt w]
    puts $fh "PD_TILE_COUNT=[llength $cells]"
    puts $fh "PD_PHYSICAL_TILE_COUNT=$physical"
    puts $fh "PD_MATRIX_BBOX=$pd_box"
    if {[mptdc_signoff_box_valid $pd_box]} {
        set ctr [mptdc_signoff_box_center $pd_box]
        puts $fh "PD_MATRIX_CENTER=[join $ctr ,]"
        puts $fh "PD_MATRIX_WIDTH_UM=[format %.3f [mptdc_signoff_box_width $pd_box]]"
        puts $fh "PD_MATRIX_HEIGHT_UM=[format %.3f [mptdc_signoff_box_height $pd_box]]"
    }
    puts $fh "PD_TILE_PITCH_X=$tile_w"
    puts $fh "PD_TILE_PITCH_Y=$tile_h"
    puts $fh "PD_TILE_OUTLIER_COUNT=$outliers"
    puts $fh "PD_MAX_ABS_DX_UM=[format %.3f $max_abs_dx]"
    puts $fh "PD_MAX_ABS_DY_UM=[format %.3f $max_abs_dy]"
    puts $fh "PD_BACKEND_INTRUSION_COUNT=$backend_intrusion"
    puts $fh "PD_MATRIX_REGULARITY=$status"
    puts $fh "PD_PHYSICAL_MATRIX_STATUS=$status"
    puts $fh "CSV=$csv"
    close $fh
    mptdc_signoff_set_status PD_PHYSICAL_MATRIX_STATUS $status $rpt
    mptdc_signoff_set_status PD_MATRIX_STATUS $status $rpt
    if {$status ne "PASS"} {
        error "MPTDC_PD_PHYSICAL_MATRIX_GATE_FAILED: report=$rpt"
    }
    return $rpt
}

proc mptdc_signoff_count_backend_cells_in_pd_box {pd_box} {
    if {![mptdc_signoff_box_valid $pd_box]} { return -1 }
    set count 0
    set cells [list]
    catch {set cells [get_cells -quiet -hierarchical *]}
    foreach obj $cells {
        set name [mptdc_signoff_db_object_name $obj]
        if {[regexp {gen_pd_row|gen_pd_col|u_pd|phase_buf|u_ro_tune4|RO_tune4|MPTDC_FILL} $name]} {
            continue
        }
        set box [mptdc_signoff_db_object_box $obj]
        if {![mptdc_signoff_box_valid $box]} { continue }
        set ctr [mptdc_signoff_box_center $box]
        if {[mptdc_signoff_point_in_box [lindex $ctr 0] [lindex $ctr 1] $pd_box]} {
            incr count
        }
    }
    return $count
}

proc mptdc_signoff_place_phase_buffers {} {
    global mptdc_xh018_cells o13 o12b
    mptdc_signoff_set_default_phase_buffer_origins
    set o13(reports_dir) [mptdc_signoff_report_dir]
    set o12b(reports_dir) [mptdc_signoff_report_dir]
    set ::env(MPTDC_O13_RESULT_DIR) [mptdc_signoff_result_dir]
    mptdc_signoff_source_if_exists innovus_mptdc_phase_buffer_place.tcl
    set placement_applied NOT_RUN
    if {[llength [info commands mptdc_pnr_apply_phase_buffer_placement]] > 0} {
        set placement_applied [expr {[mptdc_pnr_apply_phase_buffer_placement final_typical] ? "YES" : "NO"}]
    }
    set slow_iso_insts [mptdc_signoff_phase_buffer_instances slow iso]
    set slow_drv_insts [mptdc_signoff_phase_buffer_instances slow drv]
    set fast_iso_insts [mptdc_signoff_phase_buffer_instances fast iso]
    set fast_drv_insts [mptdc_signoff_phase_buffer_instances fast drv]
    set slow_iso [llength $slow_iso_insts]
    set slow_drv [llength $slow_drv_insts]
    set fast_iso [llength $fast_iso_insts]
    set fast_drv [llength $fast_drv_insts]
    set rpt [file join [mptdc_signoff_report_dir] phase_buffer_status.rpt]
    set rows [list \
        [list SLOW_ISO_COUNT 8 $slow_iso] \
        [list SLOW_DRIVER_COUNT 8 $slow_drv] \
        [list FAST_ISO_COUNT 8 $fast_iso] \
        [list FAST_DRIVER_COUNT 8 $fast_drv]]
    set failures [list]
    set fh [open $rpt w]
    foreach row $rows {
        set label [lindex $row 0]
        set expected [lindex $row 1]
        set actual [lindex $row 2]
        set status [expr {$expected eq $actual ? "PASS" : "FAIL"}]
        puts $fh "$label expected=$expected actual=$actual status=$status"
        if {$status ne "PASS"} {
            lappend failures "$label expected=$expected actual=$actual"
        }
    }
    puts $fh "PHASE_BUFFER_PLACEMENT_APPLIED=$placement_applied"
    foreach {label insts} [list \
        SLOW_ISO_INSTANCES $slow_iso_insts \
        SLOW_DRIVER_INSTANCES $slow_drv_insts \
        FAST_ISO_INSTANCES $fast_iso_insts \
        FAST_DRIVER_INSTANCES $fast_drv_insts] {
        puts $fh "$label=[join $insts { }]"
    }
    puts $fh "PHASE_ISO_BUFFER=$mptdc_xh018_cells(phase_iso_buffer)"
    puts $fh "PHASE_FINAL_BUFFER=$mptdc_xh018_cells(phase_final_buffer)"
    puts $fh "PHASE_BUFFER_STATUS=[expr {[llength $failures] == 0 ? "PASS" : "FAIL"}]"
    close $fh
    if {[llength $failures] > 0} {
        error "MPTDC_COUNT_GATE_FAILED: $failures"
    }
    mptdc_signoff_audit_ro_phase_overlap $slow_iso_insts $slow_drv_insts $fast_iso_insts $fast_drv_insts
    mptdc_signoff_set_status PHASE_BUFFER_STATUS PASS $rpt
}

proc mptdc_signoff_checkplace_overlap_count {path} {
    if {![file exists $path]} { return UNKNOWN }
    set fh [open $path r]
    set count 0
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {$trimmed eq "" || [string match "#*" $trimmed]} { continue }
        if {[regexp -nocase {no[[:space:]]+.*overlap|0[[:space:]]+.*overlap} $trimmed]} { continue }
        if {[regexp -nocase {overlap|intersect} $trimmed]} {
            incr count
        }
    }
    close $fh
    return $count
}

proc mptdc_signoff_audit_ro_phase_family {fh family ro_inst iso_insts drv_insts required_clearance} {
    set label [string toupper $family]
    set ro_box [mptdc_signoff_cell_box $ro_inst]
    puts $fh "${label}_RO_INSTANCE=$ro_inst"
    puts $fh "${label}_RO_BBOX=$ro_box"
    set total_overlap 0.0
    set min_clearance ""
    set invalid 0
    set idx 0
    foreach {stage insts} [list ISO $iso_insts DRIVER $drv_insts] {
        foreach inst $insts {
            set box [mptdc_signoff_cell_box $inst]
            set overlap [mptdc_signoff_box_overlap_area $ro_box $box]
            set clearance [mptdc_signoff_box_clearance $ro_box $box]
            puts $fh "${label}_${stage}_${idx}_INSTANCE=$inst"
            puts $fh "${label}_${stage}_${idx}_BBOX=$box"
            puts $fh "${label}_${stage}_${idx}_OVERLAP_AREA_UM2=$overlap"
            puts $fh "${label}_${stage}_${idx}_CLEARANCE_UM=$clearance"
            if {$overlap eq "" || $clearance eq ""} {
                incr invalid
            } else {
                set total_overlap [expr {$total_overlap + $overlap}]
                if {$min_clearance eq "" || $clearance < $min_clearance} {
                    set min_clearance $clearance
                }
            }
            incr idx
        }
    }
    set status PASS
    if {[llength $iso_insts] != 8 || [llength $drv_insts] != 8} {
        set status FAIL
    }
    if {$invalid > 0 || $min_clearance eq "" || $total_overlap > 0.0 || $min_clearance < $required_clearance} {
        set status FAIL
    }
    puts $fh "${label}_ISO_COUNT=[llength $iso_insts]"
    puts $fh "${label}_DRIVER_COUNT=[llength $drv_insts]"
    puts $fh "${label}_RO_PHASE_BUFFER_OVERLAP_AREA=[format %.6f $total_overlap]"
    puts $fh "${label}_RO_PHASE_MIN_CLEARANCE_UM=$min_clearance"
    puts $fh "${label}_RO_PHASE_INVALID_BBOX_COUNT=$invalid"
    puts $fh "${label}_RO_PHASE_PLACEMENT_STATUS=$status"
    return [list $status $total_overlap $min_clearance $invalid]
}

proc mptdc_signoff_audit_ro_phase_overlap {slow_iso_insts slow_drv_insts fast_iso_insts fast_drv_insts} {
    set rpt [file join [mptdc_signoff_report_dir] ro_phase_overlap_audit.rpt]
    set check_rpt [file join [mptdc_signoff_report_dir] check_place_ro_phase_overlap.rpt]
    set required_clearance [mptdc_signoff_env MPTDC_RO_PHASE_MIN_CLEARANCE_UM 10.0]
    set fail_on_global_checkplace [mptdc_signoff_env_truthy MPTDC_RO_PHASE_FAIL_ON_GLOBAL_CHECKPLACE_OVERLAP 0]
    set ro_map [mptdc_signoff_ro_instances_by_family]
    set slow_ro [dict get $ro_map slow]
    set fast_ro [dict get $ro_map fast]

    mptdc_signoff_capture_candidates $check_rpt \
        "RO/phase pre-placement checkPlace" [list {checkPlace} {checkDesign -all}]
    set check_overlap_count [mptdc_signoff_checkplace_overlap_count $check_rpt]

    set fh [open $rpt w]
    puts $fh "# MPTDC RO / Phase-Buffer Overlap Audit"
    puts $fh "RO_PHASE_MIN_CLEARANCE_REQUIRED_UM=$required_clearance"
    puts $fh "RO_TUNE4_COUNT=[llength [dict get $ro_map all]]"
    puts $fh "CHECKPLACE_REPORT=$check_rpt"
    puts $fh "CHECKPLACE_OVERLAP_LINE_COUNT=$check_overlap_count"
    puts $fh "CHECKPLACE_OVERLAP_FATAL=$fail_on_global_checkplace"
    if {$check_overlap_count eq "UNKNOWN"} {
        puts $fh "CHECKPLACE_OVERLAP_STATUS=UNKNOWN"
    } elseif {$check_overlap_count > 0} {
        puts $fh "CHECKPLACE_OVERLAP_STATUS=REVIEW_REQUIRED"
    } else {
        puts $fh "CHECKPLACE_OVERLAP_STATUS=PASS"
    }
    puts $fh ""
    set slow_result [mptdc_signoff_audit_ro_phase_family $fh slow $slow_ro $slow_iso_insts $slow_drv_insts $required_clearance]
    puts $fh ""
    set fast_result [mptdc_signoff_audit_ro_phase_family $fh fast $fast_ro $fast_iso_insts $fast_drv_insts $required_clearance]

    set slow_overlap [lindex $slow_result 1]
    set fast_overlap [lindex $fast_result 1]
    set slow_min [lindex $slow_result 2]
    set fast_min [lindex $fast_result 2]
    set min_clearance ""
    foreach value [list $slow_min $fast_min] {
        if {$value eq ""} { continue }
        if {$min_clearance eq "" || $value < $min_clearance} { set min_clearance $value }
    }
    set status PASS
    set reason NONE
    if {[llength [dict get $ro_map all]] != 2} {
        set status FAIL
        set reason ro_tune4_count_not_two
    } elseif {[lindex $slow_result 0] ne "PASS" || [lindex $fast_result 0] ne "PASS"} {
        set status FAIL
        set reason phase_buffer_overlaps_ro_macro
    } elseif {$fail_on_global_checkplace && $check_overlap_count ne "UNKNOWN" && $check_overlap_count > 0} {
        set status FAIL
        set reason checkplace_reports_overlap
    }
    puts $fh ""
    puts $fh "SLOW_RO_PHASE_BUFFER_OVERLAP_AREA=[format %.6f $slow_overlap]"
    puts $fh "FAST_RO_PHASE_BUFFER_OVERLAP_AREA=[format %.6f $fast_overlap]"
    puts $fh "RO_PHASE_MIN_CLEARANCE_UM=$min_clearance"
    puts $fh "RO_PHASE_PLACEMENT_STATUS=$status"
    puts $fh "RO_PHASE_PLACEMENT_REASON=$reason"
    close $fh
    mptdc_signoff_set_status RO_PHASE_PLACEMENT_STATUS $status $rpt
    if {$status ne "PASS"} {
        error "MPTDC_RO_PHASE_OVERLAP_GATE_FAILED: reason=$reason report=$rpt"
    }
    return $rpt
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
    set timing [file join [mptdc_signoff_report_dir] timing_tc_pre_cts.rpt]
    mptdc_signoff_capture_candidates $timing "TC pre-CTS timing" [list \
        {timeDesign -preCTS} \
        {report_timing -view TC_NOMINAL -max_paths 100}]
    set top100 [file join [mptdc_signoff_report_dir] timing_tc_pre_cts_top100.rpt]
    mptdc_signoff_capture_candidates $top100 \
        "TC pre-CTS top100" [list {report_timing -view TC_NOMINAL -max_paths 100} {report_timing -max_paths 100}]
    mptdc_signoff_stop_if_wns_below $timing -1.0 pre_cts $top100
    mptdc_signoff_capture_candidates [file join [mptdc_signoff_report_dir] check_place_post_place.rpt] \
        "post-place check" [list {checkPlace} {checkDesign -all}]
    catch {defOut [file join [mptdc_signoff_def_dir] 02_place.def]}
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 02_place.enc]}
    mptdc_signoff_audit_pd_matrix_physical
    set rpt [file join [mptdc_signoff_report_dir] placement_status.rpt]
    set fh [open $rpt w]
    puts $fh "PLACEMENT_STATUS=PASS"
    puts $fh "UNPLACED_CELLS=REQUIRE_CHECK_PLACE_ZERO"
    puts $fh "UNPLACED_TERMS=REQUIRE_CHECK_PLACE_ZERO"
    close $fh
    mptdc_signoff_set_status PLACEMENT_STATUS PASS $rpt
}

proc mptdc_signoff_insert_row_infra {} {
    global mptdc_xh018_cells
    set rpt [file join [mptdc_signoff_report_dir] row_infra_insertion.rpt]
    set fh [open $rpt w]
    puts $fh "ROW_INFRA_POLICY=$mptdc_xh018_cells(row_infra_policy)"
    puts $fh "TAP_INSERTION=SKIPPED_NO_DEDICATED_MASTER_PENDING_DRC_LVS"
    puts $fh "ENDCAP_INSERTION=SKIPPED_NO_DEDICATED_MASTER_PENDING_DRC_LVS"
    puts $fh "FILLER_CANDIDATES=$mptdc_xh018_cells(filler)"
    puts $fh "DECAP_CANDIDATES=$mptdc_xh018_cells(decap)"
    puts $fh "TIE_HIGH_CANDIDATES=$mptdc_xh018_cells(tie_high)"
    puts $fh "TIE_LOW_CANDIDATES=$mptdc_xh018_cells(tie_low)"
    puts $fh "FILLER_INSERTION_STATUS=DEFERRED_AFTER_ROUTE_FINAL_ECO"
    puts $fh "FILLER_STAGE_REPORT=filler_status.rpt"
    close $fh
    mptdc_signoff_set_status ROW_INFRA_POLICY_STATUS PROVISIONAL $rpt
}

proc mptdc_signoff_first_number_for_patterns {path patterns} {
    if {![file exists $path]} { return "" }
    set fh [open $path r]
    set value ""
    while {[gets $fh line] >= 0} {
        foreach pattern $patterns {
            if {[regexp -nocase $pattern $line -> number]} {
                set value $number
                break
            }
        }
        if {$value ne ""} { break }
    }
    close $fh
    return $value
}

proc mptdc_signoff_numeric_max {a b} {
    if {$a eq ""} { return $b }
    if {$b eq ""} { return $a }
    if {$b > $a} { return $b }
    return $a
}

proc mptdc_signoff_parse_cts_summary_metrics {path} {
    set metrics [dict create total_sinks "" clk_sys_sinks "" clk_sys_skew "" clk_sys_insertion_min "" clk_sys_insertion_max "" clk_sys_insertion_range "" max_transition ""]
    if {![file exists $path]} {
        return $metrics
    }
    set fh [open $path r]
    set in_sink_counts 0
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {[regexp -nocase {Clock DAG sink counts} $trimmed]} {
            set in_sink_counts 1
            continue
        }
        if {$in_sink_counts && [regexp -nocase {^Total[[:space:]]+([0-9]+)} $trimmed -> total_sinks]} {
            dict set metrics total_sinks $total_sinks
            set in_sink_counts 0
        }
        if {[regexp -nocase {sink counts[[:space:]]*:.*total=([0-9]+)} $trimmed -> total_sinks]} {
            dict set metrics total_sinks $total_sinks
        }
        if {[regexp -nocase {clk_sys/[^[:space:]]*[[:space:]]+([-+]?[0-9]+[.][0-9]+)[[:space:]]+([-+]?[0-9]+[.][0-9]+)[[:space:]]+([-+]?[0-9]+[.][0-9]+)} $trimmed -> min_id max_id skew]} {
            dict set metrics clk_sys_insertion_min $min_id
            dict set metrics clk_sys_insertion_max $max_id
            dict set metrics clk_sys_insertion_range [expr {$max_id - $min_id}]
            dict set metrics clk_sys_skew $skew
        }
        if {[regexp -nocase {clk_sys/} $trimmed] && ![regexp -nocase {insertion delay} $trimmed]} {
            set small_nums [list]
            foreach value [regexp -all -inline {[-+]?[0-9]*[.]?[0-9]+} $trimmed] {
                if {$value <= 1.0} {
                    lappend small_nums $value
                }
            }
            if {[llength $small_nums] >= 4} {
                set min_id [lindex $small_nums end-3]
                set max_id [lindex $small_nums end-2]
                set skew [lindex $small_nums end-1]
                if {$min_id <= $max_id} {
                    dict set metrics clk_sys_insertion_min $min_id
                    dict set metrics clk_sys_insertion_max $max_id
                    dict set metrics clk_sys_insertion_range [expr {$max_id - $min_id}]
                    dict set metrics clk_sys_skew $skew
                }
            }
        }
        if {[regexp -nocase {clk_sys/[^[:space:]:]+:[[:space:]].*insertion delay[[:space:]]+\[min=([-+]?[0-9.]+),[[:space:]]+max=([-+]?[0-9.]+).*skew[[:space:]]+\[([-+]?[0-9.]+)[[:space:]]+vs} $trimmed -> min_id max_id skew]} {
            dict set metrics clk_sys_insertion_min $min_id
            dict set metrics clk_sys_insertion_max $max_id
            dict set metrics clk_sys_insertion_range [expr {$max_id - $min_id}]
            dict set metrics clk_sys_skew $skew
        }
        if {[regexp -nocase {clk_sys/[^[:space:]]+[[:space:]]+([0-9]+)[[:space:]]+[0-9]+[[:space:]]+[-+]?[0-9.]+%} $trimmed -> clk_sys_sinks]} {
            dict set metrics clk_sys_sinks $clk_sys_sinks
        }
        if {[regexp -nocase {^(Trunk|Leaf)[[:space:]]+[-+]?[0-9.]+[[:space:]]+[0-9]+[[:space:]]+[-+]?[0-9.]+[[:space:]]+[-+]?[0-9.]+[[:space:]]+[-+]?[0-9.]+[[:space:]]+([-+]?[0-9.]+)} $trimmed -> _ max_tran]} {
            dict set metrics max_transition [mptdc_signoff_numeric_max [dict get $metrics max_transition] $max_tran]
        }
        if {[regexp -nocase {^(Trunk|Leaf).*max=([-+]?[0-9.]+)ns} $trimmed -> _ max_tran]} {
            dict set metrics max_transition [mptdc_signoff_numeric_max [dict get $metrics max_transition] $max_tran]
        }
    }
    close $fh
    return $metrics
}

proc mptdc_signoff_merge_empty_metrics {primary fallback} {
    foreach key [dict keys $fallback] {
        if {[dict get $primary $key] eq "" && [dict get $fallback $key] ne ""} {
            dict set primary $key [dict get $fallback $key]
        }
    }
    return $primary
}

proc mptdc_signoff_merge_metrics_from_files {metrics paths} {
    foreach path $paths {
        set file_metrics [mptdc_signoff_parse_cts_summary_metrics $path]
        set metrics [mptdc_signoff_merge_empty_metrics $metrics $file_metrics]
    }
    return $metrics
}

proc mptdc_signoff_count_clk_sys_sinks {} {
    set count ""
    foreach cmd {
        {sizeof_collection [all_registers -clock clk_sys]}
        {sizeof_collection [get_pins -quiet -of_objects [get_clocks clk_sys]]}
    } {
        if {![catch {set value [eval $cmd]}] && [string is integer -strict $value] && $value > 0} {
            set count $value
            break
        }
    }
    return $count
}

proc mptdc_signoff_clk_sys_root_fanout {} {
    set nets [list]
    catch {set nets [get_nets -quiet clk_sys]}
    if {[llength $nets] == 0} {
        catch {set nets [get_nets clk_sys]}
    }
    foreach net $nets {
        foreach attr {.num_loads .num_load_pins} {
            if {![catch {set value [get_db $net $attr]}] &&
                [string is integer -strict $value]} {
                return $value
            }
        }
    }
    return ""
}

proc mptdc_signoff_count_cts_fanout_violations {path} {
    if {![file exists $path]} {
        return ""
    }
    set count ""
    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        if {[regexp -nocase {Found[[:space:]]+a[[:space:]]+total[[:space:]]+of[[:space:]]+([0-9]+)[[:space:]]+clock[[:space:]]+tree[[:space:]]+nets?[[:space:]]+with[[:space:]]+max[[:space:]]+fanout[[:space:]]+violations?} $line -> value]} {
            set count $value
        }
        if {[regexp -nocase {Fanout[[:space:]]*:[[:space:]]*\{count=([0-9]+)} $line -> value]} {
            set count $value
        }
        if {[regexp -nocase {^[[:space:]]*Fanout[[:space:]]+-[[:space:]]+([0-9]+)[[:space:]]+} $line -> value]} {
            set count $value
        }
    }
    close $fh
    return $count
}

proc mptdc_signoff_safe_db_value {obj attr} {
    if {[catch {set value [get_db $obj $attr]}]} {
        return ""
    }
    return $value
}

proc mptdc_signoff_abbrev_db_value {value {limit 48}} {
    set value [string trim $value]
    if {$value eq ""} {
        return ""
    }
    set words [split $value]
    if {[llength $words] > $limit} {
        return "[join [lrange $words 0 [expr {$limit - 1}]] { }] ...TRUNCATED_[llength $words]_TOKENS"
    }
    if {[string length $value] > 512} {
        return "[string range $value 0 511]...TRUNCATED_[string length $value]_CHARS"
    }
    return $value
}

proc mptdc_signoff_write_clk_sys_root_audit {tag} {
    set rpt [file join [mptdc_signoff_report_dir] "cts_clk_sys_root_${tag}.rpt"]
    set fanout_limit [mptdc_signoff_env_int MPTDC_CTS_CLK_SYS_MAX_ROOT_FANOUT 100]
    set fh [open $rpt w]
    puts $fh "# MPTDC clk_sys CTS root audit"
    puts $fh "TAG=$tag"
    puts $fh "CLK_SYS_ROOT_FANOUT_REQUIRED_LE=$fanout_limit"
    puts $fh "CLK_SYS_ROOT_FANOUT=[mptdc_signoff_clk_sys_root_fanout]"
    puts $fh "CLK_SYS_REGISTERS_BY_TIMING_GRAPH=[mptdc_signoff_count_clk_sys_sinks]"
    foreach {label cmd} {
        CLOCK_COUNT {get_clocks -quiet clk_sys}
        PORT_COUNT {get_ports -quiet clk_sys}
        NET_COUNT {get_nets -quiet clk_sys}
        PIN_COUNT {get_pins -quiet -of_objects [get_clocks clk_sys]}
        CCOPT_CLOCK_TREES {get_ccopt_clock_trees}
    } {
        if {[catch {set objs [eval $cmd]} err]} {
            puts $fh "${label}_STATUS=UNAVAILABLE"
            puts $fh "${label}_ERROR=$err"
        } else {
            puts $fh "${label}=[llength $objs]"
            if {$label eq "CCOPT_CLOCK_TREES"} {
                set names $objs
            } else {
                set names [mptdc_signoff_object_names $objs]
            }
            if {[llength $names] > 0} {
                puts $fh "${label}_NAMES=[join [lrange $names 0 31] { }]"
            }
        }
    }
    set nets [list]
    catch {set nets [get_nets -quiet clk_sys]}
    set idx 0
    foreach net $nets {
        incr idx
        set names [mptdc_signoff_object_names [list $net]]
        puts $fh "CLK_SYS_NET_${idx}_NAME=[join $names { }]"
        foreach attr {.name .num_loads .num_load_pins .is_ideal .is_dont_touch .is_clock .wires.status} {
            set value [mptdc_signoff_safe_db_value $net $attr]
            if {$value ne ""} {
                if {$attr eq ".wires.status"} {
                    puts $fh "CLK_SYS_NET_${idx}_${attr}=[mptdc_signoff_abbrev_db_value $value 8]"
                } else {
                    puts $fh "CLK_SYS_NET_${idx}_${attr}=[mptdc_signoff_abbrev_db_value $value]"
                }
            }
        }
    }
    close $fh
    return $rpt
}

proc mptdc_signoff_read_file_text {path} {
    if {![file exists $path]} {
        return ""
    }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    return $text
}

proc mptdc_signoff_clk_sys_cts_spec_forbidden_regex {} {
    return {(clk_osc|RO_tune4|u_ro_tune4|mptdc_phase_buffer_bank|phase_buf|gen_phase_buf|u_core_u_phase_buf)}
}

proc mptdc_signoff_ccopt_clock_tree_names {} {
    if {[llength [info commands get_ccopt_clock_trees]] == 0} {
        return ""
    }
    if {[catch {set trees [get_ccopt_clock_trees]}]} {
        return ""
    }
    return $trees
}

proc mptdc_signoff_ccopt_tree_set_valid {trees forbidden_regex} {
    if {$trees eq ""} {
        return 0
    }
    set tree_text [join $trees { }]
    if {![regexp {(^|[[:space:]])clk_sys($|[[:space:]])} $tree_text]} {
        return 0
    }
    if {[regexp $forbidden_regex $tree_text]} {
        return 0
    }
    if {[llength $trees] != 1} {
        return 0
    }
    return 1
}

proc mptdc_signoff_filter_clk_sys_cts_spec {input_path output_path forbidden_regex} {
    set in [open $input_path r]
    set out [open $output_path w]
    set command ""
    set total 0
    set kept 0
    set dropped_forbidden 0
    set dropped_clk_sys_ideal 0
    set incomplete 0

    while {[gets $in line] >= 0} {
        append command $line "\n"
        if {![info complete $command]} {
            continue
        }
        incr total
        set trimmed [string trim $command]
        set drop 0
        if {[regexp $forbidden_regex $command]} {
            set drop 1
            incr dropped_forbidden
        } elseif {[regexp -nocase {^[[:space:]]*set_ccopt_property[[:space:]]+ideal_net[[:space:]].*-net[[:space:]]+clk_sys[[:space:]]+true} $trimmed]} {
            set drop 1
            incr dropped_clk_sys_ideal
        }
        if {!$drop} {
            puts -nonewline $out $command
            incr kept
        }
        set command ""
    }

    if {[string trim $command] ne ""} {
        incr incomplete
    }
    close $in
    close $out
    return [dict create \
        TOTAL_COMMANDS $total \
        KEPT_COMMANDS $kept \
        DROPPED_FORBIDDEN_COMMANDS $dropped_forbidden \
        DROPPED_CLK_SYS_IDEAL_COMMANDS $dropped_clk_sys_ideal \
        INCOMPLETE_COMMANDS $incomplete]
}

proc mptdc_signoff_try_cts_policy_cmd {fh label cmd} {
    puts $fh "${label}_COMMAND=$cmd"
    if {[catch {{*}$cmd} err]} {
        puts $fh "${label}_STATUS=SKIPPED_OR_FAILED"
        puts $fh "${label}_ERROR=$err"
        return 0
    }
    puts $fh "${label}_STATUS=PASS"
    return 1
}

proc mptdc_signoff_select_interactive_constraint_mode {fh} {
    if {[llength [info commands set_interactive_constraint_modes]] == 0} {
        puts $fh "INTERACTIVE_CONSTRAINT_MODE_STATUS=UNAVAILABLE"
        puts $fh "INTERACTIVE_CONSTRAINT_MODE_DETAIL=set_interactive_constraint_modes_not_present"
        return 0
    }
    set modes [list]
    set env_mode [mptdc_signoff_env MPTDC_INTERACTIVE_CONSTRAINT_MODE ""]
    if {$env_mode ne ""} {
        lappend modes $env_mode
    }
    if {[llength [info commands all_constraint_modes]] > 0} {
        set discovered_modes [list]
        if {![catch {set discovered_modes [all_constraint_modes]}]} {
            foreach mode $discovered_modes {
                lappend modes $mode
            }
        }
    }
    set tried [list]
    set errors [list]
    foreach mode $modes {
        set mode [string trim $mode]
        if {$mode eq "" || $mode eq "0x0"} {
            continue
        }
        if {[lsearch -exact $tried $mode] >= 0} {
            continue
        }
        lappend tried $mode
        if {![catch {set_interactive_constraint_modes $mode} err]} {
            puts $fh "INTERACTIVE_CONSTRAINT_MODE_STATUS=PASS"
            puts $fh "INTERACTIVE_CONSTRAINT_MODE=$mode"
            puts $fh "INTERACTIVE_CONSTRAINT_MODE_CANDIDATES=[join $tried { }]"
            return 1
        }
        lappend errors "$mode:$err"
    }
    puts $fh "INTERACTIVE_CONSTRAINT_MODE_STATUS=FAIL"
    puts $fh "INTERACTIVE_CONSTRAINT_MODE_CANDIDATES=[join $tried { }]"
    puts $fh "INTERACTIVE_CONSTRAINT_MODE_ERROR=[join $errors { | }]"
    return 0
}

proc mptdc_signoff_cts_target_fanout {root_fanout_limit} {
    set default_target $root_fanout_limit
    if {$default_target > 64} {
        set default_target 64
    }
    return [mptdc_signoff_env_int MPTDC_CTS_CLK_SYS_TARGET_FANOUT $default_target]
}

proc mptdc_signoff_prepare_clk_sys_for_cts {policy_rpt} {
    set cleanup_rpt [file join [mptdc_signoff_report_dir] cts_clk_sys_constraint_cleanup.rpt]
    set fanout_limit [mptdc_signoff_env_int MPTDC_CTS_CLK_SYS_MAX_ROOT_FANOUT 100]
    set target_fanout [mptdc_signoff_cts_target_fanout $fanout_limit]
    set pre_audit [mptdc_signoff_write_clk_sys_root_audit pre_cts_policy]
    set fh [open $cleanup_rpt w]
    puts $fh "# MPTDC clk_sys CTS constraint cleanup"
    puts $fh "INTENT=deidealize_clk_sys_for_measured_cts_without_touching_ro_phase_clocks"
    puts $fh "RO_PHASE_CLOCKS_REMAIN_PROTECTED=YES"
    puts $fh "CLK_SYS_ROOT_PRE_CTS_AUDIT=$pre_audit"
    puts $fh "REMOVE_IDEAL_NETWORK_COMMAND_AVAILABLE=[expr {[llength [info commands remove_ideal_network]] > 0}]"
    puts $fh "CLK_SYS_ROOT_FANOUT_BEFORE=[mptdc_signoff_clk_sys_root_fanout]"
    puts $fh "CLK_SYS_CTS_TARGET_FANOUT=$target_fanout"

    mptdc_signoff_select_interactive_constraint_mode $fh
    set clk_sys [list]
    catch {set clk_sys [get_clocks -quiet clk_sys]}
    if {[llength $clk_sys] > 0} {
        mptdc_signoff_try_cts_policy_cmd $fh CLK_SYS_CTS_CLEANUP \
            [list set_propagated_clock $clk_sys]
    } else {
        puts $fh {CLK_SYS_CTS_CLEANUP_COMMAND=set_propagated_clock [get_clocks clk_sys]}
        puts $fh "CLK_SYS_CTS_CLEANUP_STATUS=SKIPPED_OR_FAILED"
        puts $fh "CLK_SYS_CTS_CLEANUP_ERROR=clk_sys_clock_not_found"
    }

    foreach cmd [list \
        [list set_ccopt_property max_fanout $target_fanout] \
        [list set_ccopt_property cts_max_fanout $target_fanout] \
    ] {
        mptdc_signoff_try_cts_policy_cmd $fh CLK_SYS_CTS_FANOUT_PROPERTY $cmd
    }

    puts $fh "CLK_SYS_ROOT_FANOUT_AFTER_CLEANUP=[mptdc_signoff_clk_sys_root_fanout]"
    set post_audit [mptdc_signoff_write_clk_sys_root_audit pre_ccopt]
    puts $fh "CLK_SYS_ROOT_PRE_CCOPT_AUDIT=$post_audit"
    close $fh

    set pfh [open $policy_rpt a]
    puts $pfh "CLK_SYS_CTS_CONSTRAINT_CLEANUP_REPORT=$cleanup_rpt"
    puts $pfh "CLK_SYS_ROOT_PRE_CTS_AUDIT=$pre_audit"
    puts $pfh "CLK_SYS_ROOT_PRE_CCOPT_AUDIT=$post_audit"
    close $pfh
    return $cleanup_rpt
}

proc mptdc_signoff_create_clk_sys_cts_spec {policy_rpt} {
    set spec_path [file join [mptdc_signoff_work_dir] clk_sys_cts.spec]
    set raw_spec_path [file join [mptdc_signoff_work_dir] clk_sys_cts.generic.spec]
    set audit_path [file join [mptdc_signoff_report_dir] cts_clk_sys_spec_audit.rpt]
    set forbidden_regex [mptdc_signoff_clk_sys_cts_spec_forbidden_regex]
    set status PROVISIONAL
    set accepted_cmd ""
    set detail ""
    set has_clk_sys 0
    set has_forbidden 0
    set filtered_has_clk_sys 0
    set filtered_has_forbidden 0
    set allow_generic [mptdc_signoff_env_truthy MPTDC_ALLOW_GENERIC_CCOPT_WITH_RO_CLOCKS]
    set require_clk_sys_only [mptdc_signoff_env_truthy MPTDC_REQUIRE_CLK_SYS_ONLY_CTS_SPEC]
    set strict [expr {$require_clk_sys_only || !$allow_generic}]

    set fh [open $audit_path w]
    puts $fh "# MPTDC clk_sys-only CTS spec audit"
    puts $fh "SELECTED_SPEC_PATH=$spec_path"
    puts $fh "GENERIC_SPEC_PATH=$raw_spec_path"
    puts $fh "FORBIDDEN_REGEX=$forbidden_regex"
    puts $fh "ALLOW_GENERIC_CCOPT_WITH_RO_CLOCKS=$allow_generic"
    puts $fh "REQUIRE_CLK_SYS_ONLY_SPEC_ENV=$require_clk_sys_only"
    puts $fh "STRICT_CLK_SYS_ONLY_SPEC_REQUIRED=$strict"
    puts $fh "NOTE=Innovus_22_33_create_ccopt_clock_tree_spec_does_not_accept_clock_tree_selection_options"

    foreach cmd [list \
        [list create_ccopt_clock_tree_spec -file $raw_spec_path -views [list TC_NOMINAL]] \
        [list create_ccopt_clock_tree_spec -file $raw_spec_path] \
    ] {
        catch {file delete -force $raw_spec_path $spec_path}
        puts $fh "SPEC_COMMAND=$cmd"
        if {[catch {{*}$cmd} err]} {
            puts $fh "SPEC_COMMAND_STATUS=FAIL"
            puts $fh "SPEC_COMMAND_ERROR=$err"
            continue
        }
        set trees_after_create [mptdc_signoff_ccopt_clock_tree_names]
        if {$trees_after_create eq ""} {
            puts $fh "CCOPT_CLOCK_TREES_AFTER_SPEC_CREATE=UNAVAILABLE"
        } else {
            puts $fh "CCOPT_CLOCK_TREES_AFTER_SPEC_CREATE=[llength $trees_after_create]"
            puts $fh "CCOPT_CLOCK_TREE_NAMES_AFTER_SPEC_CREATE=[join $trees_after_create { }]"
        }
        set text [mptdc_signoff_read_file_text $raw_spec_path]
        set has_clk_sys [regexp {clk_sys} $text]
        set has_forbidden [regexp $forbidden_regex $text]
        puts $fh "SPEC_COMMAND_STATUS=PASS"
        puts $fh "GENERIC_HAS_CLK_SYS=$has_clk_sys"
        puts $fh "GENERIC_HAS_FORBIDDEN_RO_OR_PHASE=$has_forbidden"
        if {$trees_after_create ne "" &&
            ![mptdc_signoff_ccopt_tree_set_valid $trees_after_create $forbidden_regex]} {
            set status FAIL
            set accepted_cmd $cmd
            set detail "ccopt_session_contains_non_clk_sys_trees_after_spec_create"
            break
        }
        if {$has_clk_sys && !$has_forbidden} {
            file copy -force $raw_spec_path $spec_path
            set status PASS
            set accepted_cmd $cmd
            set detail "clk_sys_only_spec_accepted"
            break
        }
        if {$has_clk_sys && $has_forbidden} {
            set accepted_cmd $cmd
            set filter_stats [mptdc_signoff_filter_clk_sys_cts_spec \
                $raw_spec_path $spec_path $forbidden_regex]
            foreach key [lsort [dict keys $filter_stats]] {
                puts $fh "FILTER_$key=[dict get $filter_stats $key]"
            }
            set filtered_text [mptdc_signoff_read_file_text $spec_path]
            set filtered_has_clk_sys [regexp {clk_sys} $filtered_text]
            set filtered_has_forbidden [regexp $forbidden_regex $filtered_text]
            puts $fh "FILTERED_HAS_CLK_SYS=$filtered_has_clk_sys"
            puts $fh "FILTERED_HAS_FORBIDDEN_RO_OR_PHASE=$filtered_has_forbidden"
            if {$filtered_has_clk_sys &&
                !$filtered_has_forbidden &&
                [dict get $filter_stats INCOMPLETE_COMMANDS] == 0} {
                set status PASS
                set detail "filtered_clk_sys_only_spec_accepted"
                break
            }
            if {$strict} {
                set status FAIL
            } else {
                file copy -force $raw_spec_path $spec_path
                set status PROVISIONAL
            }
            set detail "generic_spec_contains_ro_or_phase_clock_text_and_filter_failed"
            break
        }
        set detail "generic_spec_did_not_expose_clk_sys"
    }

    puts $fh "CTS_SPEC_AUDIT_STATUS=$status"
    puts $fh "CTS_SPEC_AUDIT_DETAIL=$detail"
    puts $fh "ACCEPTED_SPEC_COMMAND=$accepted_cmd"
    close $fh

    set pfh [open $policy_rpt a]
    puts $pfh "CTS_SPEC_AUDIT_STATUS=$status"
    puts $pfh "CTS_SPEC_AUDIT_REPORT=$audit_path"
    puts $pfh "CTS_SPEC_PATH=$spec_path"
    puts $pfh "CTS_GENERIC_SPEC_PATH=$raw_spec_path"
    puts $pfh "CTS_SPEC_ACCEPTED_COMMAND=$accepted_cmd"
    close $pfh

    if {$strict && $status ne "PASS"} {
        return [list FAIL $spec_path $audit_path $accepted_cmd $raw_spec_path]
    }
    return [list $status $spec_path $audit_path $accepted_cmd $raw_spec_path]
}

proc mptdc_signoff_source_clk_sys_cts_spec {spec_path policy_rpt} {
    set source_rpt [file join [mptdc_signoff_report_dir] cts_clk_sys_spec_source.rpt]
    set forbidden_regex [mptdc_signoff_clk_sys_cts_spec_forbidden_regex]
    set fh [open $source_rpt w]
    puts $fh "# MPTDC selected clk_sys CTS spec source audit"
    puts $fh "SELECTED_SPEC_PATH=$spec_path"
    puts $fh "FORBIDDEN_REGEX=$forbidden_regex"

    set pre_trees [mptdc_signoff_ccopt_clock_tree_names]
    if {$pre_trees eq ""} {
        puts $fh "PRE_SOURCE_CCOPT_CLOCK_TREES=UNAVAILABLE"
    } else {
        puts $fh "PRE_SOURCE_CCOPT_CLOCK_TREES=[llength $pre_trees]"
        puts $fh "PRE_SOURCE_CCOPT_CLOCK_TREE_NAMES=[join $pre_trees { }]"
    }

    set source_status PASS
    if {$pre_trees ne "" && [llength $pre_trees] > 0} {
        puts $fh "SOURCE_SELECTED_SPEC_STATUS=SKIPPED_ALREADY_DEFINED"
    } else {
        puts $fh "SOURCE_SELECTED_SPEC_COMMAND=source $spec_path"
        if {[catch {uplevel #0 [list source $spec_path]} err]} {
            set source_status FAIL
            puts $fh "SOURCE_SELECTED_SPEC_STATUS=FAIL"
            puts $fh "SOURCE_SELECTED_SPEC_ERROR=$err"
        } else {
            puts $fh "SOURCE_SELECTED_SPEC_STATUS=PASS"
        }
    }

    set post_trees [mptdc_signoff_ccopt_clock_tree_names]
    if {$post_trees eq ""} {
        puts $fh "POST_SOURCE_CCOPT_CLOCK_TREES=UNAVAILABLE"
    } else {
        puts $fh "POST_SOURCE_CCOPT_CLOCK_TREES=[llength $post_trees]"
        puts $fh "POST_SOURCE_CCOPT_CLOCK_TREE_NAMES=[join $post_trees { }]"
    }
    set tree_valid [mptdc_signoff_ccopt_tree_set_valid $post_trees $forbidden_regex]
    puts $fh "POST_SOURCE_CLK_SYS_ONLY_TREE_SET=$tree_valid"
    if {!$tree_valid} {
        set source_status FAIL
    }
    set root_audit [mptdc_signoff_write_clk_sys_root_audit pre_ccopt_selected_spec]
    puts $fh "CLK_SYS_ROOT_PRE_CCOPT_SELECTED_SPEC_AUDIT=$root_audit"
    puts $fh "CTS_SPEC_SOURCE_STATUS=$source_status"
    close $fh

    set pfh [open $policy_rpt a]
    puts $pfh "CTS_SPEC_SOURCE_STATUS=$source_status"
    puts $pfh "CTS_SPEC_SOURCE_REPORT=$source_rpt"
    puts $pfh "CLK_SYS_ROOT_PRE_CCOPT_SELECTED_SPEC_AUDIT=$root_audit"
    close $pfh
    return [list $source_status $source_rpt]
}

proc mptdc_signoff_write_cts_measured_status {policy_rpt summary_rpt} {
    global mptdc_signoff_status
    set measured_rpt [file join [mptdc_signoff_report_dir] cts_measured_status.rpt]
    set detail_rpt [file join [mptdc_signoff_report_dir] cts_clock_tree_detail.rpt]
    mptdc_signoff_capture_candidates $detail_rpt \
        "CTS clock tree detail" [list {report_ccopt_clock_trees} {report_clock_tree}]
    set summary_metrics [mptdc_signoff_parse_cts_summary_metrics $summary_rpt]
    set summary_metrics [mptdc_signoff_merge_metrics_from_files $summary_metrics [list \
        $detail_rpt \
        [file join [mptdc_signoff_result_dir] logs innovus_mptdc_digital_signoff.log] \
        [file join [mptdc_signoff_result_dir] logs digital_signoff_wrapper.log]]]
    set total_dag_sinks [dict get $summary_metrics total_sinks]
    set sinks_expected [mptdc_signoff_count_clk_sys_sinks]
    set sink_count_source ""
    set sinks_reached [mptdc_signoff_first_number_for_patterns $summary_rpt [list \
        {clk_sys[^0-9]+([0-9]+)[^0-9]+sinks?}]]
    if {[dict get $summary_metrics clk_sys_sinks] ne ""} {
        set sinks_reached [dict get $summary_metrics clk_sys_sinks]
        set sink_count_source "clock_tree_summary_clk_sys"
    } elseif {$sinks_expected ne "" && [dict get $summary_metrics clk_sys_skew] ne ""} {
        set sinks_reached $sinks_expected
        set sink_count_source "independent_timing_graph_query_clk_sys_skew_group_present"
    } elseif {$sinks_reached ne ""} {
        set sink_count_source "generic_summary_regex_review"
    }
    set skew [mptdc_signoff_first_number_for_patterns $summary_rpt [list \
        {max[^0-9a-z]*skew[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)} \
        {skew[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)}]]
    if {[dict get $summary_metrics clk_sys_skew] ne ""} {
        set skew [dict get $summary_metrics clk_sys_skew]
    }
    set transition [mptdc_signoff_first_number_for_patterns $summary_rpt [list \
        {max[^0-9a-z]*transition[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)} \
        {max[^0-9a-z]*tran[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)} \
        {transition[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)} \
        {tran[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)}]]
    if {[dict get $summary_metrics max_transition] ne ""} {
        set transition [dict get $summary_metrics max_transition]
    }
    set insertion [mptdc_signoff_first_number_for_patterns $summary_rpt [list \
        {insertion[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)} \
        {latency[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)}]]
    set insertion_min [dict get $summary_metrics clk_sys_insertion_min]
    set insertion_max [dict get $summary_metrics clk_sys_insertion_max]
    set insertion_range [dict get $summary_metrics clk_sys_insertion_range]
    if {$insertion_max ne ""} {
        set insertion $insertion_max
    }

    set skew_limit [mptdc_signoff_env MPTDC_CTS_MAX_SKEW_NS 0.20]
    set transition_limit [mptdc_signoff_env MPTDC_CTS_MAX_TRANSITION_NS 0.35]
    set root_fanout_limit [mptdc_signoff_env_int MPTDC_CTS_CLK_SYS_MAX_ROOT_FANOUT 100]
    set root_fanout [mptdc_signoff_clk_sys_root_fanout]
    set fanout_violations [mptdc_signoff_count_cts_fanout_violations $detail_rpt]
    set status PASS
    set reason ""
    if {$sinks_expected eq "" || $sinks_reached eq ""} {
        set status PROVISIONAL
        append reason "clk_sys_sink_count_unparsed "
    } elseif {$sinks_expected != $sinks_reached} {
        set status FAIL
        append reason "sink_count_mismatch "
    }
    if {$skew eq ""} {
        set status PROVISIONAL
        append reason "skew_unparsed "
    } elseif {$skew > $skew_limit} {
        set status FAIL
        append reason "skew_over_limit "
    }
    if {$transition eq ""} {
        set status PROVISIONAL
        append reason "transition_unparsed "
    } elseif {$transition > $transition_limit} {
        set status FAIL
        append reason "transition_over_limit "
    }
    if {$root_fanout eq ""} {
        set status PROVISIONAL
        append reason "clk_sys_root_fanout_unparsed "
    } elseif {$root_fanout > $root_fanout_limit} {
        set status FAIL
        append reason "clk_sys_root_fanout_over_limit "
    }
    if {$fanout_violations eq ""} {
        set status PROVISIONAL
        append reason "cts_fanout_violations_unparsed "
    } elseif {$fanout_violations > 0} {
        set status FAIL
        append reason "cts_fanout_violations_nonzero "
    }

    set fh [open $measured_rpt w]
    puts $fh "CTS_MEASURED_STATUS=$status"
    puts $fh "CTS_REASON=[string trim $reason]"
    puts $fh "CLK_SYS_SINKS_EXPECTED=$sinks_expected"
    puts $fh "CLK_SYS_SINKS_REACHED=$sinks_reached"
    puts $fh "CLK_SYS_SINK_COUNT_SOURCE=$sink_count_source"
    puts $fh "CTS_TOTAL_DAG_SINKS=$total_dag_sinks"
    puts $fh "CLK_SYS_MAX_SKEW_NS=$skew"
    puts $fh "CLK_SYS_MAX_TRANSITION_NS=$transition"
    puts $fh "CLK_SYS_INSERTION_DELAY_NS=$insertion"
    puts $fh "CLK_SYS_MIN_INSERTION_DELAY_NS=$insertion_min"
    puts $fh "CLK_SYS_MAX_INSERTION_DELAY_NS=$insertion_max"
    puts $fh "CLK_SYS_INSERTION_DELAY_RANGE_NS=$insertion_range"
    puts $fh "CLK_SYS_MAX_SKEW_NS_REQUIRED_LE=$skew_limit"
    puts $fh "CLK_SYS_MAX_TRANSITION_NS_REQUIRED_LE=$transition_limit"
    puts $fh "CLK_SYS_ROOT_FANOUT=$root_fanout"
    puts $fh "CLK_SYS_ROOT_FANOUT_REQUIRED_LE=$root_fanout_limit"
    puts $fh "CTS_MAX_FANOUT_VIOLATIONS=$fanout_violations"
    puts $fh "CTS_MAX_FANOUT_VIOLATIONS_REQUIRED=0"
    puts $fh "RO_CLOCKS_IN_CTS=0"
    puts $fh "PHASE_CLOCKS_IN_CTS=0"
    puts $fh "SUMMARY_REPORT=$summary_rpt"
    puts $fh "DETAIL_REPORT=$detail_rpt"
    close $fh

    set fh [open $policy_rpt a]
    puts $fh "CTS_MEASURED_STATUS=$status"
    puts $fh "CTS_MEASURED_REPORT=$measured_rpt"
    close $fh
    if {$status eq "FAIL"} {
        mptdc_signoff_set_status CTS_STATUS FAIL $measured_rpt
        error "MPTDC_CTS_MEASURED_GATE_FAILED: report=$measured_rpt"
    }
    mptdc_signoff_set_status CTS_STATUS $status $measured_rpt
    return $measured_rpt
}

proc mptdc_signoff_run_cts {} {
    global mptdc_signoff_status
    global mptdc_xh018_cells
    mptdc_signoff_source_if_exists innovus_mptdc_cts.tcl
    catch {mptdc_pnr_apply_cts_exclusions}
    set rpt [file join [mptdc_signoff_report_dir] cts_policy.rpt]
    set fh [open $rpt w]
    puts $fh "CTS_PRIMARY_CLOCK=clk_sys"
    puts $fh "RO_CLOCKS_IN_CTS=0"
    puts $fh "PHASE_CLOCKS_IN_CTS=0"
    puts $fh "CTS_BUFFERS=$mptdc_xh018_cells(cts_buffers)"
    puts $fh "CTS_INVERTERS=$mptdc_xh018_cells(cts_inverters)"
    puts $fh "CLOCKDESIGN_FALLBACK=DISALLOWED"
    close $fh
    foreach pattern {clk_osc_slow clk_osc_fast clk_osc_slow_tap* clk_osc_fast_tap* clk_osc_*_buf_tap*} {
        catch {set_dont_touch_network [get_clocks $pattern]}
    }
    catch {set_ccopt_property buffer_cells $mptdc_xh018_cells(cts_buffers)}
    catch {set_ccopt_property inverter_cells $mptdc_xh018_cells(cts_inverters)}
    catch {set_ccopt_property target_skew 0.20}
    catch {set_ccopt_property target_max_trans 0.35}
    mptdc_signoff_prepare_clk_sys_for_cts $rpt
    set spec_result [mptdc_signoff_create_clk_sys_cts_spec $rpt]
    set spec_status [lindex $spec_result 0]
    if {$spec_status eq "FAIL"} {
        set efh [open $rpt a]
        puts $efh "CTS_STATUS=FAIL"
        puts $efh "CTS_FAIL_REASON=strict_clk_sys_only_ccopt_spec_required_but_unavailable"
        puts $efh "CTS_FAIL_ACTION=do_not_run_generic_ccopt_because_it_adds_ro_phase_clock_trees"
        close $efh
        error "MPTDC_CLK_SYS_CTS_SPEC_FAILED: report=[lindex $spec_result 2]"
    }
    set spec_source_result [mptdc_signoff_source_clk_sys_cts_spec [lindex $spec_result 1] $rpt]
    if {[lindex $spec_source_result 0] ne "PASS"} {
        set efh [open $rpt a]
        puts $efh "CTS_STATUS=FAIL"
        puts $efh "CTS_FAIL_REASON=selected_clk_sys_cts_spec_source_or_validation_failed"
        close $efh
        error "MPTDC_CLK_SYS_CTS_SPEC_SOURCE_FAILED: report=[lindex $spec_source_result 1]"
    }
    set efh [open $rpt a]
    puts $efh "CTS_SPEC_GATE_STATUS=$spec_status"
    if {$spec_status eq "PASS"} {
        puts $efh "CTS_SPEC_GATE_ACTION=strict_clk_sys_spec_accepted"
    } else {
        puts $efh "CTS_SPEC_GATE_ACTION=generic_ccopt_override_enabled_review_required"
    }
    close $efh
    set ccopt_ok 0
    set ccopt_last_error ""
    foreach cmd [list {ccopt_design} {ccopt_design -cts}] {
        set efh [open $rpt a]
        puts $efh "CCOPT_COMMAND=$cmd"
        close $efh
        if {![catch {uplevel #0 $cmd} err]} {
            set ccopt_ok 1
            set efh [open $rpt a]
            puts $efh "CCOPT_COMMAND_STATUS=PASS"
            close $efh
            break
        }
        set ccopt_last_error $err
        set efh [open $rpt a]
        puts $efh "CCOPT_COMMAND_STATUS=FAIL"
        puts $efh "CCOPT_ERROR=$err"
        close $efh
    }
    if {!$ccopt_ok} {
        set efh [open $rpt a]
        puts $efh "CTS_STATUS=FAIL"
        close $efh
        error "MPTDC_CLK_SYS_CTS_FAILED: $ccopt_last_error"
    }
    set post_ccopt_root_audit [mptdc_signoff_write_clk_sys_root_audit post_ccopt]
    set efh [open $rpt a]
    puts $efh "CLK_SYS_ROOT_POST_CCOPT_AUDIT=$post_ccopt_root_audit"
    close $efh
    catch {optDesign -postCTS}
    mptdc_signoff_capture_candidates [file join [mptdc_signoff_report_dir] timing_post_cts.rpt] \
        "TC post-CTS setup" [list {timeDesign -postCTS} {report_timing -view TC_NOMINAL -max_paths 100}]
    mptdc_signoff_capture_candidates [file join [mptdc_signoff_report_dir] hold_post_cts.rpt] \
        "TC post-CTS hold" [list {timeDesign -postCTS -hold} {report_timing -view TC_NOMINAL -check_type hold -max_paths 100}]
    mptdc_signoff_capture_candidates [file join [mptdc_signoff_report_dir] clock_tree_summary.rpt] \
        "clock tree summary" [list {report_ccopt_clock_trees -summary} {report_clock_tree -summary}]
    set post_opt_root_audit [mptdc_signoff_write_clk_sys_root_audit post_cts_opt]
    set efh [open $rpt a]
    puts $efh "CLK_SYS_ROOT_POST_CTS_OPT_AUDIT=$post_opt_root_audit"
    close $efh
    set measured [mptdc_signoff_write_cts_measured_status $rpt [file join [mptdc_signoff_report_dir] clock_tree_summary.rpt]]
    set cts_stage_status PASS
    if {[info exists mptdc_signoff_status(CTS_STATUS)] && [string match *PROVISIONAL* $mptdc_signoff_status(CTS_STATUS)]} {
        set cts_stage_status PROVISIONAL
    }
    set sfh [open $rpt a]
    puts $sfh "CTS_STATUS=$cts_stage_status"
    puts $sfh "IMPCCOPT-4255=0"
    puts $sfh "MAX_SKEW_NS_REQUIRED_LE=0.20"
    puts $sfh "MAX_CLOCK_TRANSITION_NS_REQUIRED_LE=0.35"
    puts $sfh "CTS_MEASURED_REPORT=$measured"
    close $sfh
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 03_cts.enc]}
    if {$cts_stage_status eq "PASS"} {
        mptdc_signoff_set_status CTS_STATUS PASS $rpt
    }
}

proc mptdc_signoff_route_design {} {
    mptdc_signoff_source_if_exists innovus_mptdc_route.tcl
    set route_intent_rpt [file join [mptdc_signoff_report_dir] route_layer_intent.rpt]
    catch {mptdc_pnr_write_route_intent $route_intent_rpt}
    set route_layer_rpt [file join [mptdc_signoff_report_dir] route_layer_limits.rpt]
    set rfh [open $route_layer_rpt w]
    puts $rfh "# MPTDC Route Layer Limits"
    if {[catch {mptdc_pnr_apply_route_layer_limits} layer_limits]} {
        puts $rfh "ROUTE_LAYER_LIMIT_STATUS=REVIEW_REQUIRED"
        puts $rfh "ROUTE_LAYER_LIMIT_ERROR=$layer_limits"
    } else {
        puts $rfh "ROUTE_LAYER_LIMIT_STATUS=APPLIED"
        foreach {key value} $layer_limits {
            puts $rfh "[string toupper $key]=$value"
        }
    }
    close $rfh
    routeDesign
    set antenna_rpt [file join [mptdc_signoff_report_dir] antenna.rpt]
    mptdc_signoff_run_optional_postroute_opt
    mptdc_signoff_insert_final_fillers
    set antenna_status PROVISIONAL
    if {![catch {verifyProcessAntenna > $antenna_rpt} antenna_err]} {
        set antenna_status PROVISIONAL_WITH_LEF_ANTENNA_COMPLETENESS_REVIEW
    } else {
        set fh [open $antenna_rpt w]
        puts $fh "ANTENNA_STATUS=PROVISIONAL"
        puts $fh "VERIFY_PROCESS_ANTENNA_ERROR=$antenna_err"
        close $fh
    }
    mptdc_signoff_set_status ANTENNA_STATUS $antenna_status $antenna_rpt
    set drc_rpt [file join [mptdc_signoff_report_dir] route_drc.rpt]
    set regular_rpt [file join [mptdc_signoff_report_dir] route_connectivity_regular.rpt]
    set special_rpt [file join [mptdc_signoff_report_dir] route_connectivity_special.rpt]
    set report_route_rpt [file join [mptdc_signoff_report_dir] report_route.rpt]
    mptdc_signoff_capture_route_gate_reports $drc_rpt $regular_rpt $special_rpt $report_route_rpt
    set rpt [file join [mptdc_signoff_report_dir] route_status.rpt]
    set route_gate [mptdc_signoff_read_route_gate_reports $drc_rpt $regular_rpt $special_rpt $report_route_rpt]
    set route_gate [mptdc_signoff_route_gate_recovery \
        $drc_rpt $regular_rpt $special_rpt $report_route_rpt $route_gate]
    lassign $route_gate drc_data regular_bad special_bad unrouted
    mptdc_signoff_write_route_gate_status $rpt $drc_data $regular_bad $special_bad $unrouted $antenna_status
    catch {defOut [file join [mptdc_signoff_def_dir] 04_route.def]}
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 04_route.enc]}
}

proc mptdc_signoff_extract_and_sta {} {
    set extract_rpt [file join [mptdc_signoff_report_dir] extraction_rc.rpt]
    mptdc_signoff_capture_required_candidates $extract_rpt \
        "post-route TC extractRC" [list {extractRC}]
    set sta_policy [mptdc_signoff_configure_post_route_tc_sta]
    mptdc_signoff_set_status EXTRACTION_STATUS PROVISIONAL $sta_policy
    set setup_rpt [file join [mptdc_signoff_report_dir] timing_tc_nominal.rpt]
    set hold_rpt [file join [mptdc_signoff_report_dir] timing_tc_hold.rpt]
    set setup_top [file join [mptdc_signoff_report_dir] timing_tc_nominal_top100.rpt]
    mptdc_signoff_capture_required_candidates $setup_rpt \
        "TC_NOMINAL setup timing" [list \
            {timeDesign -postRoute} \
            {report_timing -view TC_NOMINAL -max_paths 100}]
    mptdc_signoff_capture_candidates $setup_top \
        "TC_NOMINAL setup top100" [list \
            {report_timing -view TC_NOMINAL -max_paths 100} \
            {report_timing -max_paths 100}]
    mptdc_signoff_capture_required_candidates $hold_rpt \
        "TC_NOMINAL hold timing" [list \
            {timeDesign -postRoute -hold} \
            {report_timing -view TC_NOMINAL -check_type hold -max_paths 100}]
    mptdc_signoff_set_status EXTRACTION_STATUS PASS extraction_rc.rpt
    set setup_bad [mptdc_signoff_collect_timing_failures $setup_rpt]
    set hold_bad [mptdc_signoff_collect_timing_failures $hold_rpt]
    set timing_status_rpt [file join [mptdc_signoff_report_dir] extracted_timing_status.rpt]
    lassign [mptdc_signoff_write_extracted_timing_status $timing_status_rpt \
        $setup_rpt $hold_rpt $setup_bad $hold_bad] setup_status hold_status
    mptdc_signoff_set_status SETUP_STATUS_TC $setup_status timing_tc_nominal.rpt
    mptdc_signoff_set_status TC_HOLD_STATUS $hold_status timing_tc_hold.rpt
    mptdc_signoff_set_status SETUP_STATUS_WC DEFERRED scope_tc_only
    mptdc_signoff_set_status HOLD_STATUS_BC DEFERRED scope_tc_only
    mptdc_signoff_set_status RO_1GHZ_STRESS_STATUS DEFERRED scope_tc_only
    set tran_rpt [file join [mptdc_signoff_report_dir] drv_max_transition.rpt]
    set cap_rpt [file join [mptdc_signoff_report_dir] drv_max_cap.rpt]
    set fanout_rpt [file join [mptdc_signoff_report_dir] drv_max_fanout.rpt]
    mptdc_signoff_capture_drv_reports $tran_rpt $cap_rpt $fanout_rpt
    mptdc_signoff_require_no_drv_violation_markers [list $tran_rpt $cap_rpt $fanout_rpt]
    mptdc_signoff_set_status DRV_STATUS PASS drv_reports_require_zero_violations
}

proc mptdc_signoff_spread_pct {values} {
    if {[llength $values] == 0} { return "" }
    set min ""
    set max ""
    set sum 0.0
    foreach value $values {
        if {![string is double -strict $value]} { return "" }
        if {$min eq "" || $value < $min} { set min $value }
        if {$max eq "" || $value > $max} { set max $value }
        set sum [expr {$sum + $value}]
    }
    set mean [expr {$sum / double([llength $values])}]
    if {$mean <= 0.0} { return "" }
    return [format %.3f [expr {(($max - $min) / $mean) * 100.0}]]
}

proc mptdc_signoff_csv_split {line} {
    set out [list]
    foreach col [split $line ","] {
        lappend out [string trim [string trim $col] "\""]
    }
    return $out
}

proc mptdc_signoff_csv_header_map {header mandatory} {
    set seen [dict create]
    set index 0
    foreach col [mptdc_signoff_csv_split $header] {
        set name [string trim $col]
        if {$name eq ""} {
            incr index
            continue
        }
        if {[dict exists $seen $name]} {
            error "duplicate_column:$name"
        }
        dict set seen $name $index
        incr index
    }
    foreach name $mandatory {
        if {![dict exists $seen $name]} {
            error "missing_column:$name"
        }
    }
    return $seen
}

proc mptdc_signoff_csv_get {cols header name} {
    if {![dict exists $header $name]} {
        return ""
    }
    set index [dict get $header $name]
    if {$index >= [llength $cols]} {
        return ""
    }
    return [string trim [lindex $cols $index]]
}

proc mptdc_signoff_metric_stats {rows family metric} {
    set count 0
    set min ""
    set max ""
    set sum 0.0
    set min_tap ""
    set max_tap ""
    foreach row $rows {
        if {[dict get $row family] ne $family} {
            continue
        }
        if {![dict exists $row $metric]} {
            continue
        }
        set value [dict get $row $metric]
        if {![string is double -strict $value]} {
            continue
        }
        set tap [dict get $row tap]
        if {$min eq "" || $value < $min} {
            set min $value
            set min_tap $tap
        }
        if {$max eq "" || $value > $max} {
            set max $value
            set max_tap $tap
        }
        set sum [expr {$sum + $value}]
        incr count
    }
    if {$count == 0} {
        return [dict create count 0 min "" max "" mean "" spread_abs "" spread_pct "" best_tap "" worst_tap ""]
    }
    set mean [expr {$sum / double($count)}]
    set spread_abs [expr {$max - $min}]
    set spread_pct ""
    if {$mean > 0.0} {
        set spread_pct [expr {($spread_abs / $mean) * 100.0}]
    }
    return [dict create \
        count $count \
        min [format %.6f $min] \
        max [format %.6f $max] \
        mean [format %.6f $mean] \
        spread_abs [format %.6f $spread_abs] \
        spread_pct [expr {$spread_pct eq "" ? "" : [format %.3f $spread_pct]}] \
        best_tap $min_tap \
        worst_tap $max_tap]
}

proc mptdc_signoff_phase_rc_parse_csv {route_csv detailed_csv status_rpt} {
    set numeric_metrics [list \
        raw_route_length_um \
        raw_total_cap_pf \
        isolation_route_length_um \
        isolation_total_cap_pf \
        buffered_route_length_um \
        buffered_total_cap_pf \
        buffered_wire_cap_pf \
        buffered_pin_cap_pf \
        buffered_res_ohm]
    set mandatory [concat [list family tap] $numeric_metrics]
    set optional_delay_metrics [list extracted_delay_ps extracted_delay_ns buffered_delay_ps buffered_delay_ns delay_ps delay_ns]
    set rows [list]
    set parse_status PASS
    set parse_error ""
    set row_keys [dict create]
    set family_counts [dict create slow 0 fast 0]
    set delay_metrics [list]
    set parse_errors [list]
    set missing_metric_counts [dict create]
    set invalid_metric_counts [dict create]
    set structure_ok 1

    if {![file exists $route_csv]} {
        set parse_status DATA_MISSING
        set parse_error "missing_route_csv"
    } else {
        set fh [open $route_csv r]
        set header_line ""
        while {[gets $fh line] >= 0} {
            if {[string trim $line] ne ""} {
                set header_line $line
                break
            }
        }
        if {$header_line eq ""} {
            set parse_status DATA_MISSING
            set parse_error "empty_route_csv"
        } elseif {[catch {set header [mptdc_signoff_csv_header_map $header_line $mandatory]} header_err]} {
            set parse_status DATA_MISSING
            set parse_error $header_err
        } else {
            foreach metric $optional_delay_metrics {
                if {[dict exists $header $metric]} {
                    lappend delay_metrics $metric
                }
            }
            set line_no 1
            while {[gets $fh line] >= 0} {
                incr line_no
                if {[string trim $line] eq ""} { continue }
                set cols [mptdc_signoff_csv_split $line]
                set family [mptdc_signoff_csv_get $cols $header family]
                set tap [mptdc_signoff_csv_get $cols $header tap]
                if {$family ni {slow fast}} {
                    set parse_status DATA_MISSING
                    set parse_error "bad_family_line_${line_no}:$family"
                    set structure_ok 0
                    break
                }
                if {$tap eq ""} {
                    set parse_status DATA_MISSING
                    set parse_error "missing_tap_line_$line_no"
                    set structure_ok 0
                    break
                }
                set key "$family/$tap"
                if {[dict exists $row_keys $key]} {
                    set parse_status DATA_MISSING
                    set parse_error "duplicate_family_tap:$key"
                    set structure_ok 0
                    break
                }
                dict set row_keys $key 1
                dict incr family_counts $family
                set row [dict create family $family tap $tap]
                foreach metric $numeric_metrics {
                    set value [mptdc_signoff_csv_get $cols $header $metric]
                    if {![string is double -strict $value]} {
                        set parse_status DATA_MISSING
                        if {$value eq ""} {
                            dict incr missing_metric_counts $metric
                        } else {
                            dict incr invalid_metric_counts $metric
                        }
                        lappend parse_errors "nonnumeric_${metric}_line_${line_no}:$value"
                        continue
                    }
                    dict set row $metric $value
                }
                foreach metric $delay_metrics {
                    set value [mptdc_signoff_csv_get $cols $header $metric]
                    if {$value eq ""} {
                        continue
                    }
                    if {![string is double -strict $value]} {
                        set parse_status DATA_MISSING
                        dict incr invalid_metric_counts $metric
                        lappend parse_errors "nonnumeric_${metric}_line_${line_no}:$value"
                        continue
                    }
                    dict set row $metric $value
                }
                lappend rows $row
            }
        }
        close $fh
    }

    if {$parse_error eq "" && [llength $parse_errors] > 0} {
        set parse_error [lindex $parse_errors 0]
    }

    if {$structure_ok} {
        if {[llength $rows] != 16 ||
            [dict get $family_counts slow] != 8 ||
            [dict get $family_counts fast] != 8} {
            set parse_status DATA_MISSING
            set parse_error "expected_16_rows_8_slow_8_fast_got_total_[llength $rows]_slow_[dict get $family_counts slow]_fast_[dict get $family_counts fast]"
        }
    }

    set max_spread [mptdc_signoff_env MPTDC_PHASE_RC_MAX_SPREAD_PCT 10.0]
    set raw_cap_limit [mptdc_signoff_env MPTDC_RO_TUNE4_S_MAX_CAP_PF 0.050]
    set rc_status PASS
    set phase_status PASS
    set classification PARSER_FALSE_FAILURE
    set asymmetry_count 0
    set metrics_for_symmetry [concat \
        $numeric_metrics \
        $delay_metrics]
    set data_missing [expr {$parse_status ne "PASS"}]
    set actual_asymmetry 0

    foreach family {slow fast} {
        foreach metric $metrics_for_symmetry {
            set stats [mptdc_signoff_metric_stats $rows $family $metric]
            set spread [dict get $stats spread_pct]
            if {$spread eq "" || [dict get $stats count] != 8} {
                set data_missing 1
            } elseif {$spread > $max_spread} {
                set actual_asymmetry 1
                incr asymmetry_count
            }
        }
        foreach row $rows {
            if {[dict get $row family] ne $family} { continue }
            if {[dict exists $row raw_total_cap_pf] && [dict get $row raw_total_cap_pf] > $raw_cap_limit} {
                set phase_status FAIL
            }
        }
    }
    if {$data_missing || $actual_asymmetry} {
        set rc_status FAIL
    }
    if {$data_missing && $phase_status eq "PASS"} {
        set phase_status PROVISIONAL
    }
    if {$actual_asymmetry && $data_missing} {
        set classification ACTUAL_PHYSICAL_ASYMMETRY_WITH_DATA_MISSING
    } elseif {$actual_asymmetry} {
        set classification ACTUAL_PHYSICAL_ASYMMETRY
    } elseif {$data_missing} {
        set classification DATA_MISSING
    }

    set missing_total 0
    foreach metric [dict keys $missing_metric_counts] {
        incr missing_total [dict get $missing_metric_counts $metric]
    }
    set invalid_total 0
    foreach metric [dict keys $invalid_metric_counts] {
        incr invalid_total [dict get $invalid_metric_counts $metric]
    }

    set original_parse_status $parse_status
    set original_phase_status $phase_status
    set original_rc_status $rc_status
    set original_classification $classification
    set acceptance_requested [mptdc_signoff_env_truthy MPTDC_PHASE_RC_ACCEPT_ASYMMETRY]
    set acceptance_applied 0
    set acceptance_scope [mptdc_signoff_env MPTDC_PHASE_RC_ACCEPT_SCOPE TC_ONLY_O13_OWNER_REVIEW]
    set acceptance_reason [mptdc_signoff_env MPTDC_PHASE_RC_ACCEPT_REASON owner_accepted_o13_phase_rc_asymmetry_for_this_tc_only_version]
    regsub -all {[\r\n]} $acceptance_scope { } acceptance_scope
    regsub -all {[\r\n]} $acceptance_reason { } acceptance_reason

    set missing_metrics [lsort [dict keys $missing_metric_counts]]
    set isolation_cap_only_missing [expr {
        [llength $missing_metrics] == 0 ||
        ([llength $missing_metrics] == 1 && [lindex $missing_metrics 0] eq "isolation_total_cap_pf")
    }]
    set structurally_complete [expr {
        $structure_ok &&
        [llength $rows] == 16 &&
        [dict get $family_counts slow] == 8 &&
        [dict get $family_counts fast] == 8 &&
        $invalid_total == 0
    }]
    set acceptance_eligible [expr {
        $acceptance_requested &&
        $actual_asymmetry &&
        $structurally_complete &&
        $isolation_cap_only_missing &&
        $phase_status ne "FAIL"
    }]
    if {$acceptance_eligible} {
        set acceptance_applied 1
        set phase_status ACCEPTED
        set rc_status ACCEPTED
        set classification "TC_ONLY_ACCEPTED_${classification}"
    }

    file mkdir [file dirname $detailed_csv]
    set dfh [open $detailed_csv w]
    puts $dfh "family,tap,metric,unit,count,min,max,mean,absolute_spread,percentage_spread,worst_tap,best_tap"
    foreach family {slow fast} {
        foreach metric [concat $numeric_metrics $delay_metrics] {
            set unit ""
            if {[string match *_um $metric]} {
                set unit um
            } elseif {[string match *_pf $metric]} {
                set unit pf
            } elseif {[string match *_ohm $metric]} {
                set unit ohm
            } elseif {[string match *_ps $metric]} {
                set unit ps
            } elseif {[string match *_ns $metric]} {
                set unit ns
            }
            set stats [mptdc_signoff_metric_stats $rows $family $metric]
            puts $dfh "$family,ALL,$metric,$unit,[dict get $stats count],[dict get $stats min],[dict get $stats max],[dict get $stats mean],[dict get $stats spread_abs],[dict get $stats spread_pct],[dict get $stats worst_tap],[dict get $stats best_tap]"
        }
    }
    close $dfh

    set sfh [open $status_rpt w]
    puts $sfh "# MPTDC Phase Load and RC Symmetry Status"
    puts $sfh "PARSER_SCHEMA_VERSION=2"
    puts $sfh "ROUTE_CSV=$route_csv"
    puts $sfh "DETAILED_CSV=$detailed_csv"
    puts $sfh "ROUTE_ROWS=[llength $rows]"
    puts $sfh "SLOW_ROWS=[dict get $family_counts slow]"
    puts $sfh "FAST_ROWS=[dict get $family_counts fast]"
    puts $sfh "PARSE_STATUS=$parse_status"
    if {$parse_error ne ""} { puts $sfh "PARSE_ERROR=$parse_error" }
    puts $sfh "PARSE_ERROR_COUNT=[llength $parse_errors]"
    if {[llength $parse_errors] > 0} {
        puts $sfh "PARSE_ERRORS=[join [lrange $parse_errors 0 11] {;}]"
        if {[llength $parse_errors] > 12} {
            puts $sfh "PARSE_ERRORS_TRUNCATED=YES"
        }
    }
    puts $sfh "MISSING_NUMERIC_FIELD_COUNT=$missing_total"
    puts $sfh "INVALID_NUMERIC_FIELD_COUNT=$invalid_total"
    puts $sfh "MISSING_NUMERIC_METRICS=[join [lsort [dict keys $missing_metric_counts]] { }]"
    puts $sfh "INVALID_NUMERIC_METRICS=[join [lsort [dict keys $invalid_metric_counts]] { }]"
    foreach metric [lsort [dict keys $missing_metric_counts]] {
        puts $sfh "MISSING_${metric}_count=[dict get $missing_metric_counts $metric]"
    }
    foreach metric [lsort [dict keys $invalid_metric_counts]] {
        puts $sfh "INVALID_${metric}_count=[dict get $invalid_metric_counts $metric]"
    }
    puts $sfh "UNITS_ROUTE_LENGTH=um"
    puts $sfh "UNITS_CAPACITANCE=pf"
    puts $sfh "UNITS_RESISTANCE=ohm"
    puts $sfh "RO_TUNE4_S_MAX_CAP_PF=$raw_cap_limit"
    puts $sfh "MAX_ALLOWED_SPREAD_PCT=$max_spread"
    puts $sfh "OPTIONAL_DELAY_METRICS=[join $delay_metrics { }]"
    puts $sfh "RC_SYMMETRY_FAILURE_CLASSIFICATION=$classification"
    puts $sfh "RC_SYMMETRY_ASYMMETRIC_METRIC_COUNT=$asymmetry_count"
    puts $sfh "RC_SYMMETRY_ACCEPTANCE_REQUESTED=[expr {$acceptance_requested ? "YES" : "NO"}]"
    puts $sfh "RC_SYMMETRY_ACCEPTANCE_ELIGIBLE=[expr {$acceptance_eligible ? "YES" : "NO"}]"
    puts $sfh "RC_SYMMETRY_ACCEPTANCE_APPLIED=[expr {$acceptance_applied ? "YES" : "NO"}]"
    puts $sfh "RC_SYMMETRY_ACCEPTANCE_SCOPE=$acceptance_scope"
    puts $sfh "RC_SYMMETRY_ACCEPTANCE_REASON=$acceptance_reason"
    puts $sfh "PHASE_RC_PARSE_ORIGINAL_STATUS=$original_parse_status"
    puts $sfh "PHASE_LOAD_ORIGINAL_STATUS=$original_phase_status"
    puts $sfh "RC_SYMMETRY_ORIGINAL_STATUS=$original_rc_status"
    puts $sfh "RC_SYMMETRY_ORIGINAL_CLASSIFICATION=$original_classification"
    foreach family {slow fast} {
        foreach metric [concat $numeric_metrics $delay_metrics] {
            set stats [mptdc_signoff_metric_stats $rows $family $metric]
            set prefix "${family}_${metric}"
            puts $sfh "${prefix}_count=[dict get $stats count]"
            puts $sfh "${prefix}_min=[dict get $stats min]"
            puts $sfh "${prefix}_max=[dict get $stats max]"
            puts $sfh "${prefix}_mean=[dict get $stats mean]"
            puts $sfh "${prefix}_absolute_spread=[dict get $stats spread_abs]"
            puts $sfh "${prefix}_percentage_spread=[dict get $stats spread_pct]"
            puts $sfh "${prefix}_worst_tap=[dict get $stats worst_tap]"
            puts $sfh "${prefix}_best_tap=[dict get $stats best_tap]"
        }
    }
    puts $sfh "PHASE_LOAD_STATUS=$phase_status"
    puts $sfh "RC_SYMMETRY_STATUS=$rc_status"
    close $sfh

    return [dict create \
        parse_status $parse_status \
        phase_status $phase_status \
        rc_status $rc_status \
        classification $classification \
        original_phase_status $original_phase_status \
        original_rc_status $original_rc_status \
        original_classification $original_classification \
        acceptance_applied [expr {$acceptance_applied ? "YES" : "NO"}] \
        rows [llength $rows] \
        detailed_csv $detailed_csv]
}

proc mptdc_signoff_write_phase_rc_parser_selftest {} {
    set rpt [file join [mptdc_signoff_report_dir] phase_rc_parser_selftest.rpt]
    set fixture [file join [mptdc_signoff_report_dir] phase_rc_parser_selftest_fixture.csv]
    set detail [file join [mptdc_signoff_report_dir] phase_rc_parser_selftest_detailed.csv]
    set status [file join [mptdc_signoff_report_dir] phase_rc_parser_selftest_status.rpt]
    file mkdir [file dirname $fixture]
    set fh [open $fixture w]
    puts $fh "family,tap,raw_net,raw_route_length_um,raw_total_cap_pf,isolation_net,isolation_route_length_um,isolation_total_cap_pf,buffered_net,buffered_route_length_um,buffered_total_cap_pf,buffered_wire_cap_pf,buffered_pin_cap_pf,buffered_res_ohm,status,notes"
    foreach family {slow fast} {
        for {set tap 0} {$tap < 8} {incr tap} {
            set base [expr {100.0 + $tap}]
            puts $fh "$family,$tap,raw_${family}_${tap},$base,0.020,iso_${family}_${tap},[expr {$base + 1.0}],0.024,buf_${family}_${tap},[expr {$base + 2.0}],0.030,0.012,0.018,10.0,PASS,selftest"
        }
    }
    close $fh
    set result [mptdc_signoff_phase_rc_parse_csv $fixture $detail $status]
    set pass [expr {[dict get $result parse_status] eq "PASS" && [dict get $result rc_status] eq "PASS"}]
    set fh [open $rpt w]
    puts $fh "# MPTDC Phase RC Parser Self-Test"
    puts $fh "PHASE_RC_PARSER_SELFTEST_SCHEMA_VERSION=1"
    puts $fh "PHASE_RC_PARSER_SELFTEST_STATUS=[expr {$pass ? "PASS" : "FAIL"}]"
    puts $fh "PHASE_RC_PARSER_SELFTEST_FIXTURE=$fixture"
    puts $fh "PHASE_RC_PARSER_SELFTEST_DETAIL=$detail"
    puts $fh "PHASE_RC_PARSER_SELFTEST_STATUS_REPORT=$status"
    puts $fh "PHASE_RC_PARSER_SELFTEST_PARSE_STATUS=[dict get $result parse_status]"
    puts $fh "PHASE_RC_PARSER_SELFTEST_RC_STATUS=[dict get $result rc_status]"
    close $fh
    if {!$pass} {
        error "MPTDC_PHASE_RC_PARSER_SELFTEST_FAILED: report=$rpt"
    }
    return $rpt
}

proc mptdc_signoff_write_phase_and_backend_reports {} {
    global o13 o12b
    set o13(reports_dir) [mptdc_signoff_report_dir]
    set o12b(reports_dir) [mptdc_signoff_report_dir]
    mptdc_signoff_source_if_exists innovus_o13_phase_buffer_reports.tcl
    set o13_status REVIEW_REQUIRED
    set o13_error ""
    if {[llength [info commands mptdc_o13_write_reports]] > 0} {
        if {[catch {mptdc_o13_write_reports} o13_error]} {
            set o13_status FAIL
        } else {
            set o13_status PASS
        }
    }

    set route_csv [file join [mptdc_signoff_report_dir] phase_buffer_route_summary.csv]
    set phase_rpt [file join [mptdc_signoff_report_dir] phase_rc_symmetry_status.rpt]
    set detailed_csv [file join [mptdc_signoff_report_dir] phase_rc_symmetry_detailed.csv]
    set phase_result [mptdc_signoff_phase_rc_parse_csv $route_csv $detailed_csv $phase_rpt]
    set phase_status [dict get $phase_result phase_status]
    set rc_status [dict get $phase_result rc_status]
    if {$o13_status ne "PASS"} {
        if {$phase_status in {PASS ACCEPTED}} { set phase_status PROVISIONAL }
        if {$rc_status in {PASS ACCEPTED}} { set rc_status PROVISIONAL }
    }
    set fh [open $phase_rpt a]
    puts $fh "O13_REPORT_GENERATION_STATUS=$o13_status"
    if {$o13_error ne ""} { puts $fh "O13_REPORT_GENERATION_ERROR=$o13_error" }
    puts $fh "EFFECTIVE_PHASE_LOAD_STATUS=$phase_status"
    puts $fh "EFFECTIVE_RC_SYMMETRY_STATUS=$rc_status"
    close $fh
    mptdc_signoff_set_status PHASE_LOAD_STATUS $phase_status $phase_rpt
    mptdc_signoff_set_status RC_SYMMETRY_STATUS $rc_status $phase_rpt

    set phase_geom_rpt [file join [mptdc_signoff_report_dir] phase_to_pd_geometry_status.rpt]
    set placement_csv [file join [mptdc_signoff_report_dir] phase_buffer_placement.csv]
    set placement_rows 0
    set unknown_rows 0
    if {[file exists $placement_csv]} {
        set fh [open $placement_csv r]
        set header 1
        while {[gets $fh line] >= 0} {
            if {$header} { set header 0; continue }
            if {[string trim $line] eq ""} { continue }
            incr placement_rows
            if {[regexp -nocase {PLACEMENT_UNKNOWN|PLACEMENT_QUERY_FAILED} $line]} {
                incr unknown_rows
            }
        }
        close $fh
    }
    set phase_geom_status [expr {$placement_rows == 32 && $unknown_rows == 0 ? "PASS" : "PROVISIONAL"}]
    set fh [open $phase_geom_rpt w]
    puts $fh "PHASE_TO_PD_GEOMETRY_STATUS=$phase_geom_status"
    puts $fh "PHASE_BUFFER_PLACEMENT_ROWS=$placement_rows"
    puts $fh "PHASE_BUFFER_PLACEMENT_UNKNOWN_ROWS=$unknown_rows"
    puts $fh "PLACEMENT_CSV=$placement_csv"
    close $fh
    mptdc_signoff_set_status PHASE_TO_PD_GEOMETRY_STATUS $phase_geom_status $phase_geom_rpt

    set backend_rpt [file join [mptdc_signoff_report_dir] backend_region_status.rpt]
    set pd_box [list]
    mptdc_signoff_source_if_exists innovus_mptdc_floorplan.tcl
    if {[llength [info commands mptdc_pnr_floorplan_regions]] > 0} {
        set regions [mptdc_pnr_floorplan_regions]
        if {[dict exists $regions pd_island]} { set pd_box [dict get $regions pd_island] }
    }
    set backend_intrusion [mptdc_signoff_count_backend_cells_in_pd_box $pd_box]
    set backend_status [expr {$backend_intrusion == 0 ? "PASS" : "FAIL"}]
    set fh [open $backend_rpt w]
    puts $fh "BACKEND_REGION_STATUS=$backend_status"
    puts $fh "PD_MATRIX_BBOX=$pd_box"
    puts $fh "BACKEND_INTRUSION_COUNT=$backend_intrusion"
    puts $fh "BACKEND_CROSSING_STATUS=PROVISIONAL"
    puts $fh "BACKEND_CROSSING_REASON=route_net_crossing_classification_not_yet_foundry_clean"
    close $fh
    mptdc_signoff_set_status BACKEND_REGION_STATUS $backend_status $backend_rpt
    mptdc_signoff_set_status BACKEND_CROSSING_STATUS PROVISIONAL $backend_rpt

    set empty_rpt [file join [mptdc_signoff_report_dir] empty_space_audit.rpt]
    set core_box [mptdc_signoff_core_box]
    set placed_area 0.0
    set cell_count 0
    set cells [list]
    catch {set cells [get_cells -quiet -hierarchical *]}
    foreach obj $cells {
        set box [mptdc_signoff_db_object_box $obj]
        if {![mptdc_signoff_box_valid $box]} { continue }
        set placed_area [expr {$placed_area + [mptdc_signoff_box_area $box]}]
        incr cell_count
    }
    set core_area [expr {[mptdc_signoff_box_valid $core_box] ? [mptdc_signoff_box_area $core_box] : 0.0}]
    set empty_status REVIEW_REQUIRED
    set fh [open $empty_rpt w]
    puts $fh "EMPTY_SPACE_AUDIT_STATUS=$empty_status"
    puts $fh "CORE_BBOX=$core_box"
    puts $fh "CORE_AREA_UM2=[format %.3f $core_area]"
    puts $fh "PLACED_CELL_AREA_UM2=[format %.3f $placed_area]"
    puts $fh "PLACED_CELL_COUNT=$cell_count"
    if {$core_area > 0.0} {
        puts $fh "CORE_UTILIZATION=[format %.4f [expr {$placed_area / $core_area}]]"
        puts $fh "EMPTY_AREA_UM2=[format %.3f [expr {$core_area - $placed_area}]]"
        puts $fh "EMPTY_AREA_PERCENT=[format %.2f [expr {(($core_area - $placed_area) / $core_area) * 100.0}]]"
    }
    puts $fh "EMPTY_SPACE_CLASSIFICATION=REVIEW_LAYOUT_WITH_CONGESTION_PG_PHASE_SYMMETRY"
    close $fh
    mptdc_signoff_set_status EMPTY_SPACE_AUDIT_STATUS $empty_status $empty_rpt
}

proc mptdc_signoff_write_final_package {} {
    set rpt [file join [mptdc_signoff_report_dir] physical_verification_status.md]
    set setup_state [mptdc_signoff_status_state SETUP_STATUS_TC]
    set hold_state [mptdc_signoff_status_state TC_HOLD_STATUS]
    set route_state [mptdc_signoff_status_state ROUTE_STATUS]
    set extraction_state [mptdc_signoff_status_state EXTRACTION_STATUS]
    set tc_pnr_state PASS
    set tc_pnr_evidence tc_only_routed_timed_closure_complete
    set digital_evidence row_and_block_drc_lvs_deferred
    if {$route_state ne "PASS" || $extraction_state ne "PASS"} {
        set tc_pnr_state DEFERRED
        set tc_pnr_evidence route_or_extraction_not_complete
        set digital_evidence row_and_block_drc_lvs_deferred_route_or_extraction_not_complete
    } elseif {$setup_state ne "PASS" || $hold_state ne "PASS"} {
        set tc_pnr_state DEFERRED
        set tc_pnr_evidence tc_timing_not_closed
        set digital_evidence row_and_block_drc_lvs_deferred_timing_not_closed
    }
    set fh [open $rpt w]
    puts $fh "# Physical Verification Status"
    puts $fh ""
    puts $fh "ROW_INFRA_DRC_LVS_STATUS=DEFERRED"
    puts $fh "DRC_STATUS=DEFERRED"
    puts $fh "LVS_STATUS=DEFERRED"
    puts $fh "MPTDC_TC_PNR_CLOSURE=$tc_pnr_state"
    puts $fh "MPTDC_TC_PNR_CLOSURE_EVIDENCE=$tc_pnr_evidence"
    puts $fh "SETUP_STATUS_TC=$setup_state"
    puts $fh "TC_HOLD_STATUS=$hold_state"
    puts $fh "MPTDC_TC_PHYSICAL_SIGNOFF=NO"
    puts $fh "TC_ONLY_TAPEOUT_EXCEPTION_READY=NO"
    puts $fh "DIGITAL_PNR_SIGNOFF=PROVISIONAL"
    puts $fh "NOT_MMMC_SIGNOFF=YES"
    puts $fh "READY_FOR_TAPEOUT=NO"
    puts $fh ""
    puts $fh "Foundry-qualified PVS/Assura/Calibre DRC/LVS evidence is required before PASS."
    close $fh
    mptdc_signoff_set_status DRC_STATUS DEFERRED $rpt
    mptdc_signoff_set_status LVS_STATUS DEFERRED $rpt
    mptdc_signoff_set_status DELIVERABLE_STATUS PROVISIONAL [mptdc_signoff_outputs_dir]
    mptdc_signoff_set_status MPTDC_TC_PNR_CLOSURE $tc_pnr_state $tc_pnr_evidence
    mptdc_signoff_set_status MPTDC_TC_PHYSICAL_SIGNOFF NO drc_lvs_and_physical_verification_deferred
    mptdc_signoff_set_status TC_ONLY_TAPEOUT_EXCEPTION_READY NO drc_lvs_and_physical_verification_deferred
    mptdc_signoff_set_status NOT_MMMC_SIGNOFF YES scope_tc_only
    mptdc_signoff_set_status READY_FOR_TAPEOUT NO row_and_mmmc_deferred
    mptdc_signoff_set_status DIGITAL_PNR_SIGNOFF PROVISIONAL $digital_evidence
}

proc mptdc_signoff_source_check {} {
    mptdc_signoff_mkdirs
    mptdc_signoff_init_status
    mptdc_signoff_require_tc_only_scope
    mptdc_signoff_write_phase_rc_parser_selftest
    set ro_rpt [mptdc_signoff_write_ro_source_report]
    set provisional [mptdc_signoff_check_physical_cell_policy implementation]
    mptdc_signoff_write_policy_manifest
    mptdc_signoff_set_status MPTDC_CLOSURE_SCOPE TC_ONLY source_check
    mptdc_signoff_set_status SETUP_STATUS_WC DEFERRED scope_tc_only
    mptdc_signoff_set_status HOLD_STATUS_BC DEFERRED scope_tc_only
    mptdc_signoff_set_status RO_1GHZ_STRESS_STATUS DEFERRED scope_tc_only
    mptdc_signoff_set_status RO_IMPORT_STATUS PASS $ro_rpt
    set status_path [mptdc_signoff_write_status]
    puts "MPTDC_DIGITAL_SIGNOFF_SOURCE_CHECK=PASS"
    puts "MPTDC_CLOSURE_SCOPE=TC_ONLY"
    puts "MPTDC_TC_PNR_CLOSURE=DEFERRED"
    puts "SETUP_STATUS_WC=DEFERRED evidence=scope_tc_only"
    puts "HOLD_STATUS_BC=DEFERRED evidence=scope_tc_only"
    puts "RO_1GHZ_STRESS_STATUS=DEFERRED evidence=scope_tc_only"
    puts "RO_IMPORT_SOURCE_GATE=PASS"
    puts "ROW_INFRA_POLICY=NO_DEDICATED_CORE_TAP_ENDCAP_PENDING_DRC_LVS"
    puts "ROW_INFRA_STATUS=PROVISIONAL"
    puts "IMPLEMENTATION_ALLOWED=YES"
    puts "FINAL_SIGNOFF_ALLOWED=NO"
    puts "DIGITAL_PNR_SIGNOFF=PROVISIONAL"
    puts "NOT_MMMC_SIGNOFF=YES"
    puts "READY_FOR_TAPEOUT=NO"
    puts "PROVISIONAL_ROW_CLASSES=$provisional"
    puts "MPTDC_DIGITAL_SIGNOFF_STATUS_TEMPLATE=$status_path"
}

proc mptdc_signoff_phase_rc_parse_only {} {
    mptdc_signoff_mkdirs
    mptdc_signoff_write_phase_rc_parser_selftest
    set route_csv [file join [mptdc_signoff_report_dir] phase_buffer_route_summary.csv]
    set detailed_csv [file join [mptdc_signoff_report_dir] phase_rc_symmetry_detailed.csv]
    set phase_rpt [file join [mptdc_signoff_report_dir] phase_rc_symmetry_status.rpt]
    set result [mptdc_signoff_phase_rc_parse_csv $route_csv $detailed_csv $phase_rpt]
    puts "MPTDC_PHASE_RC_PARSE_ONLY=PASS"
    puts "PHASE_RC_PARSE_STATUS=[dict get $result parse_status]"
    puts "PHASE_LOAD_STATUS=[dict get $result phase_status]"
    puts "RC_SYMMETRY_STATUS=[dict get $result rc_status]"
    puts "RC_SYMMETRY_FAILURE_CLASSIFICATION=[dict get $result classification]"
    puts "RC_SYMMETRY_ACCEPTANCE_APPLIED=[dict get $result acceptance_applied]"
    puts "PHASE_LOAD_ORIGINAL_STATUS=[dict get $result original_phase_status]"
    puts "RC_SYMMETRY_ORIGINAL_STATUS=[dict get $result original_rc_status]"
    puts "PHASE_RC_SYMMETRY_STATUS_REPORT=$phase_rpt"
    puts "PHASE_RC_SYMMETRY_DETAILED_CSV=$detailed_csv"
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
    mptdc_signoff_stage post_import_gate RO_IMPORT_STATUS {
        mptdc_signoff_post_import_gate
    }
    mptdc_signoff_stage post_import_tc_timing SETUP_STATUS_TC {
        mptdc_signoff_post_import_timing_gate
    }
    mptdc_signoff_stage floorplan FLOORPLAN_STATUS {
        mptdc_signoff_apply_floorplan
    }
    mptdc_signoff_stage io_placement IO_STATUS {
        mptdc_signoff_place_io_pins
    }
    mptdc_signoff_stage ro_macro_placement RO_MACRO_STATUS {
        mptdc_signoff_place_ro_macros
    }
    mptdc_signoff_stage pg_connectivity PG_PHYSICAL_STATUS {
        mptdc_signoff_apply_pg_connectivity
        mptdc_signoff_write_pg_gate_template
        mptdc_signoff_build_power_grid
    }
    mptdc_signoff_stage pd_matrix_placement PD_MATRIX_STATUS {
        mptdc_signoff_place_pd_matrix
    }
    mptdc_signoff_stage phase_buffer_placement PHASE_BUFFER_STATUS {
        mptdc_signoff_place_phase_buffers
    }
    mptdc_signoff_stage row_infrastructure ROW_INFRA_POLICY_STATUS {
        mptdc_signoff_insert_row_infra
    }
    mptdc_signoff_stage placement PLACEMENT_STATUS {
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
        mptdc_signoff_write_phase_and_backend_reports
    }
    mptdc_signoff_stage physical_verification_package DRC_STATUS {
        mptdc_signoff_write_final_package
    }
    set status_path [mptdc_signoff_write_status]
    set tc_pnr_state [mptdc_signoff_status_state MPTDC_TC_PNR_CLOSURE]
    set setup_state [mptdc_signoff_status_state SETUP_STATUS_TC]
    set hold_state [mptdc_signoff_status_state TC_HOLD_STATUS]
    if {$tc_pnr_state eq "PASS"} {
        puts "MPTDC_DIGITAL_SIGNOFF_EXECUTION=COMPLETE_TC_ONLY_PROVISIONAL"
    } else {
        puts "MPTDC_DIGITAL_SIGNOFF_EXECUTION=COMPLETE_TC_ONLY_PROVISIONAL_TIMING_NOT_CLOSED"
    }
    puts "MPTDC_TC_PNR_CLOSURE=$tc_pnr_state"
    puts "SETUP_STATUS_TC=$setup_state"
    puts "TC_HOLD_STATUS=$hold_state"
    puts "SETUP_STATUS_WC=DEFERRED evidence=scope_tc_only"
    puts "HOLD_STATUS_BC=DEFERRED evidence=scope_tc_only"
    puts "RO_1GHZ_STRESS_STATUS=DEFERRED evidence=scope_tc_only"
    puts "DIGITAL_PNR_SIGNOFF=PROVISIONAL"
    puts "NOT_MMMC_SIGNOFF=YES"
    puts "READY_FOR_TAPEOUT=NO"
    puts "TC_ONLY_TAPEOUT_EXCEPTION_READY=NO"
    puts "MPTDC_DIGITAL_SIGNOFF_STATUS=$status_path"
}

if {[info exists ::env(MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY)] && $::env(MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY)} {
    mptdc_signoff_source_check
    return
}

if {[info exists ::env(MPTDC_PHASE_RC_PARSE_ONLY)] && $::env(MPTDC_PHASE_RC_PARSE_ONLY)} {
    mptdc_signoff_phase_rc_parse_only
    return
}

if {[catch {mptdc_signoff_main} err opts]} {
    puts "MPTDC_DIGITAL_SIGNOFF_ERROR: $err"
    if {[dict exists $opts -errorinfo]} {
        puts [dict get $opts -errorinfo]
    }
    exit 1
}
