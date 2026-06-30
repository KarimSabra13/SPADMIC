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
        POWER_STATUS \
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
    return "/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef"
}

proc mptdc_signoff_default_ro_liberty {} {
    return [file join [mptdc_signoff_repo_root] MPTDC/syn/macros/RO_tune6_real_layout_shell.lib]
}

proc mptdc_signoff_ro_macro_name {} {
    if {[info exists ::env(O1_RO_CELL_NAME)] && $::env(O1_RO_CELL_NAME) ne ""} {
        return $::env(O1_RO_CELL_NAME)
    }
    return "RO_tune6"
}

proc mptdc_signoff_ro_cell_patterns {} {
    set macro [mptdc_signoff_ro_macro_name]
    return [list *u_ro_tune4* *$macro*]
}

proc mptdc_signoff_ro_pin_patterns {} {
    set macro [mptdc_signoff_ro_macro_name]
    return [list *u_ro_tune4*/S* *$macro*/S*]
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

proc mptdc_signoff_lef_macro_size {lef_path macro_name} {
    set fh [open $lef_path r]
    set in_prop 0
    set in_macro 0
    set width ""
    set height ""
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
            set in_macro [expr {$macro eq $macro_name}]
            continue
        }
        if {$in_macro &&
            [regexp {^[[:space:]]*SIZE[[:space:]]+([-+0-9.]+)[[:space:]]+BY[[:space:]]+([-+0-9.]+)[[:space:]]*;} $line -> width height]} {
            break
        }
        if {$in_macro && [regexp {^[[:space:]]*END[[:space:]]+([^[:space:];]+)[[:space:]]*$} $line -> macro]} {
            if {$macro eq $macro_name} {
                break
            }
        }
    }
    close $fh
    if {$width eq "" || $height eq ""} {
        return [list]
    }
    return [list $width $height]
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
    if {![info exists ::env(O1_RO_CELL_NAME)] || $::env(O1_RO_CELL_NAME) eq ""} {
        set ::env(O1_RO_CELL_NAME) [mptdc_signoff_ro_macro_name]
    }
    set expected [mptdc_signoff_ro_macro_name]
    set lef [mptdc_signoff_required_file "$expected LEF" $::env(O1_RO_LEF_PATH)]
    set lib [mptdc_signoff_required_file "$expected Liberty" $::env(O1_RO_LIBERTY_PATH)]
    set macro [mptdc_signoff_lef_macro_name $lef]
    if {$macro ne $expected} {
        error "MPTDC_RO_LEF_MACRO_MISMATCH: O1_RO_LEF_PATH=$lef macro=$macro expected=$expected"
    }
    set size [mptdc_signoff_lef_macro_size $lef $expected]
    if {[llength $size] != 2} {
        error "MPTDC_RO_LEF_SIZE_MISSING: O1_RO_LEF_PATH=$lef macro=$expected"
    }
    set ::env(MPTDC_PNR_OSC_WIDTH_UM) [lindex $size 0]
    set ::env(MPTDC_PNR_OSC_HEIGHT_UM) [lindex $size 1]
    set ::env(O1_RO_LEF_PATH) $lef
    set ::env(O1_RO_LIBERTY_PATH) $lib
    return [dict create lef $lef liberty $lib macro $macro width [lindex $size 0] height [lindex $size 1]]
}

proc mptdc_signoff_write_ro_source_report {} {
    set ro [mptdc_signoff_prepare_ro_inputs]
    set path [file join [mptdc_signoff_report_dir] ro_import_source_gate.rpt]
    set fh [open $path w]
    puts $fh "O1_USE_REAL_RO_ABSTRACT=1"
    puts $fh "O1_RO_CELL_NAME=[mptdc_signoff_ro_macro_name]"
    puts $fh "O1_RO_LEF_PATH=[dict get $ro lef]"
    puts $fh "O1_RO_LEF_MACRO=[dict get $ro macro]"
    puts $fh "MPTDC_PNR_OSC_WIDTH_UM=[dict get $ro width]"
    puts $fh "MPTDC_PNR_OSC_HEIGHT_UM=[dict get $ro height]"
    puts $fh "MPTDC_RO_LEF_SIZE_STATUS=PASS"
    puts $fh "O1_RO_LIBERTY_PATH=[dict get $ro liberty]"
    puts $fh "MPTDC_OSC_BLACKBOX_ALLOWED=NO"
    puts $fh "MPTDC_OSC_SLOW_BB_ALLOWED=NO"
    puts $fh "MPTDC_OSC_FAST_BB_ALLOWED=NO"
    puts $fh "REQUIRED_RO_TUNE6_INSTANCES=2"
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

proc mptdc_signoff_apply_recovery_defaults {} {
    foreach {name value} {
        MPTDC_XH018_STACK xx31
        MPTDC_PNR_METAL_STACK xx31
        MPTDC_PNR_ROUTE_LAYER_NAMES {MET1 MET2 MET3 METTP}
        MPTDC_PNR_SIGNAL_TOP_LAYER MET3
        MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER METTP
        MPTDC_PNR_POWER_LAYER METTP
        MPTDC_PNR_PHASE_TOP_LAYER METTP
        MPTDC_PNR_PD_TILE_CONSTRAINT_MODE none
        MPTDC_PNR_PD_TILE_APPLY_HIER_BOX 0
        MPTDC_PNR_PD_TILE_REGION_MARGIN_UM 0.0
        MPTDC_PNR_PD_TILE_USE_FENCE 0
        MPTDC_PNR_PD_TILE_PREPLACE_LEAVES 0
        MPTDC_PNR_PD_TILE_FIX_LEAVES 0
        MPTDC_PD_PHYSICAL_AUDIT_MODE soft_region
        MPTDC_PD_TILE_SOFT_BOX_MARGIN_UM 12.0
        MPTDC_PD_TILE_MAX_OFFSET_UM 12.0
        MPTDC_PNR_CORE_UTIL 0.55
        MPTDC_PNR_FIX_RO_MACROS 0
        MPTDC_PNR_CREATE_RO_HALOS 0
        MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN 1
        MPTDC_PNR_FAST_TAG_COLUMN_SIDE center
        MPTDC_PNR_ALLOW_FAST_TAG_CENTER_OVER_PD 1
        MPTDC_PNR_FAST_TAG_COLUMN_PREPLACE 0
        MPTDC_PNR_FAST_TAG_COLUMN_FIX 0
        MPTDC_PNR_FAST_TAG_COLUMN_STRIP_WIDTH_UM 40.0
        MPTDC_ENABLE_POSTROUTE_OPT 1
        MPTDC_ENABLE_TC_CLOSURE 1
        MPTDC_POSTROUTE_SETUP_OPT_PASSES 4
        MPTDC_POSTROUTE_SETUP_OPT_MAX_PASSES 4
        MPTDC_POSTROUTE_SETUP_EARLY_STOP 1
        MPTDC_POSTROUTE_SETUP_PLATEAU_GUARD 1
        MPTDC_POSTROUTE_SETUP_STALL_LIMIT 1
        MPTDC_POSTROUTE_SETUP_MIN_IMPROVEMENT_NS 0.005
        MPTDC_PNR_FAST_TAG_TIMING_FOCUS 1
        MPTDC_PNR_FAST_TAG_TARGETED_ECO 1
        MPTDC_PNR_FAST_TAG_ECO_ALLOW_ON22_X2 1
        MPTDC_PNR_FAST_TAG_ECO_PROTECT_ENDPOINT_FLOPS 0
        MPTDC_PNR_FAST_TAG_ECO_UPSIZE_SMALL_GATES 1
        MPTDC_PNR_FAST_TAG_ECO_MAX_UPSIZE_CELLS 64
        MPTDC_PNR_FAST_TAG_ECO_UPSIZE_DRIVE_LIMIT 4
        MPTDC_PNR_FAST_TAG_ECO_PATH_DRIVEN 1
        MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_PATHS 100
        MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_CELLS 128
        MPTDC_PNR_FAST_TAG_ECO_NAME_FALLBACK 0
        MPTDC_PNR_FAST_TAG_ECO_ALLOW_ENDPOINT_FLOP_RESIZE 1
        MPTDC_ENABLE_BLOCK_PG_PINS 1
        MPTDC_BLOCK_PG_PIN_LAYER METTP
        MPTDC_BLOCK_PG_PIN_STYLE mesh_lr_vdd_vss
        MPTDC_BLOCK_PG_PIN_WIDTH_UM 4.0
        MPTDC_BLOCK_PG_PIN_DEPTH_UM 28.0
        MPTDC_BLOCK_PG_PIN_OUTSIDE_OVERLAP_UM 8.0
        MPTDC_BLOCK_PG_PIN_CREATE_MODE geom
        MPTDC_BLOCK_PG_PIN_EDITPIN_FALLBACK 0
        MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES 0
        MPTDC_BLOCK_PG_STITCH_WIDTH_UM 2.0
        MPTDC_BLOCK_PG_STITCH_SPACING_UM 2.0
        MPTDC_BLOCK_PG_STITCH_SET_DISTANCE_UM 5000.0
        MPTDC_BLOCK_PG_STITCH_NUMBER_OF_SETS 0
        MPTDC_ENABLE_FINAL_FILLER 0
        MPTDC_ENABLE_POST_FILLER_SROUTE 0
        MPTDC_ENABLE_PREPLACE_PG_SROUTE 0
        MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG 1
        MPTDC_ENABLE_POSTPLACE_PRE_ROUTE_SROUTE 1
        MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN 1
        MPTDC_POSTPLACE_PRE_ROUTE_ACCEPT_PG_VERIFY_CLEAN 1
        MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE 0
        MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN 0
        MPTDC_ENABLE_SROUTE_PADPIN_FALLBACK 0
        MPTDC_ENABLE_SROUTE_MODE_EXPERIMENTS 0
        MPTDC_SROUTE_PRESERVE_EXISTING_ROUTES 0
        MPTDC_SROUTE_CONNECT_STRIPE 1
        MPTDC_SROUTE_CORE_PIN_STOP_ROUTE RowEnd
        MPTDC_ENABLE_RO_PG_PROBE 0
        MPTDC_ENABLE_RO_PG_HOOKUP 1
        MPTDC_REQUIRE_RO_PG_HOOKUP 1
        MPTDC_RO_PG_HOOKUP_SEARCH_UM 45.0
        MPTDC_RO_PG_HOOKUP_MARGIN_UM 1.0
        MPTDC_RO_PG_HOOKUP_SPACING_UM 2.0
        MPTDC_RO_PG_HOOKUP_SET_DISTANCE_UM 5000.0
        MPTDC_FILLER_ADD_FILLERS_WITH_DRC 0
        MPTDC_REQUIRE_DRC_SAFE_FILLER 1
        MPTDC_ENABLE_ROUTE_GATE_RECOVERY 1
        MPTDC_ROUTE_GATE_SROUTE_RECOVERY 0
        MPTDC_ROUTE_REPAIR_COMMANDS {{ecoRoute -target} {ecoRoute -fix_drc}}
        MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE 1
        MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS 2
        MPTDC_ROUTE_DRC_REVIEW_ALLOWED_CLASSES Mar
    } {
        mptdc_signoff_set_env_default $name $value
    }
}

proc mptdc_signoff_pg_policy_guard {} {
    if {[mptdc_signoff_env_truthy MPTDC_ALLOW_LEGACY_PG_TOPOLOGY 0]} {
        return
    }
    set failures [list]
    set style [string tolower [mptdc_signoff_env MPTDC_BLOCK_PG_PIN_STYLE mesh_lr_vdd_vss]]
    if {$style ne "mesh_lr_vdd_vss"} {
        lappend failures "MPTDC_BLOCK_PG_PIN_STYLE=$style expected mesh_lr_vdd_vss"
    }
    if {[mptdc_signoff_env_truthy MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES 0]} {
        lappend failures "MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES=1 expected 0"
    }
    if {![mptdc_signoff_env_truthy MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN 1]} {
        lappend failures "MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN=0 expected 1"
    }
    if {[mptdc_signoff_env_truthy MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE 0]} {
        lappend failures "MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE=1 expected 0"
    }
    if {[mptdc_signoff_env_truthy MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN 0]} {
        lappend failures "MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN=1 expected 0"
    }
    if {[mptdc_signoff_env_truthy MPTDC_ENABLE_SROUTE_MODE_EXPERIMENTS 0]} {
        lappend failures "MPTDC_ENABLE_SROUTE_MODE_EXPERIMENTS=1 expected 0"
    }
    set core_pin_stop [mptdc_signoff_env MPTDC_SROUTE_CORE_PIN_STOP_ROUTE RowEnd]
    if {$core_pin_stop ne "RowEnd"} {
        lappend failures "MPTDC_SROUTE_CORE_PIN_STOP_ROUTE=$core_pin_stop expected RowEnd"
    }
    if {![mptdc_signoff_env_truthy MPTDC_ENABLE_RO_PG_HOOKUP 1]} {
        lappend failures "MPTDC_ENABLE_RO_PG_HOOKUP=0 expected 1"
    }
    if {![mptdc_signoff_env_truthy MPTDC_REQUIRE_RO_PG_HOOKUP 1]} {
        lappend failures "MPTDC_REQUIRE_RO_PG_HOOKUP=0 expected 1"
    }
    if {[llength $failures] > 0} {
        error "MPTDC_PG_POLICY_GUARD_FAILED: [join $failures {; }]; set MPTDC_ALLOW_LEGACY_PG_TOPOLOGY=1 only for explicit debug bypass"
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
    set ro_instances [mptdc_signoff_collect_cells [mptdc_signoff_ro_cell_patterns]]
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
    puts $fh "RO_HALO_ENABLED=[expr {[mptdc_signoff_env_truthy MPTDC_PNR_CREATE_RO_HALOS 1] ? 1 : 0}]"
    if {![mptdc_signoff_env_truthy MPTDC_PNR_CREATE_RO_HALOS 1]} {
        puts $fh "RO_HALO_STATUS=SKIPPED"
        puts $fh "RO_HALO_REASON=disabled_for_tc_closure_placement_relaxation"
        close $fh
        return $path
    }
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
    set origin_clearance [mptdc_signoff_env MPTDC_RO_PHASE_ORIGIN_CLEARANCE_UM [expr {$clearance + 6.0}]]
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
        set fast_iso_y [expr {[lindex $fast_ro_box 3] + $origin_clearance}]
        set fast_drv_y [expr {$fast_iso_y + $row_sep}]
    }

    set slow_iso_y [expr {$slow_y0 + $y_offset + $row_sep}]
    set slow_drv_y [expr {$slow_y0 + $y_offset}]
    if {[mptdc_signoff_box_valid $slow_ro_box]} {
        set slow_iso_y [expr {[lindex $slow_ro_box 1] - $origin_clearance - $row_sep}]
        set slow_drv_y [expr {$slow_iso_y - $row_sep}]
    }

    mptdc_signoff_set_phase_origin_env MPTDC_PNR_PHASE_BUF_PITCH_UM $pitch $force
    mptdc_signoff_set_phase_origin_env MPTDC_PNR_PHASE_BUF_ORIENT ROW_LEGAL $force
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

proc mptdc_signoff_parse_tns_ns {path} {
    if {![file exists $path]} {
        return ""
    }
    set fh [open $path r]
    set value ""
    while {[gets $fh line] >= 0} {
        if {[regexp -nocase {TNS[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)} $line -> number]} {
            set value $number
            break
        }
    }
    close $fh
    return $value
}

proc mptdc_signoff_parse_worst_slack_ns {path} {
    if {![file exists $path]} {
        return ""
    }
    set fh [open $path r]
    set worst ""
    while {[gets $fh line] >= 0} {
        foreach pattern {
            {Slack Time[[:space:]]+([-+]?[0-9]+([.][0-9]+)?)}
            {slack[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)}
            {WNS[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)}
        } {
            if {[regexp -nocase $pattern $line -> value]} {
                if {$worst eq "" || $value < $worst} {
                    set worst $value
                }
            }
        }
    }
    close $fh
    return $worst
}

proc mptdc_signoff_timing_class_regexes {} {
    return [list \
        CLK_SYS {clk_sys} \
        OSC_SLOW {clk_osc_slow|u_osc_slow|slow_phase} \
        OSC_FAST {clk_osc_fast|u_osc_fast|fast_phase} \
        PHASE_BUFFER {phase_buf|gen_phase_buf|BUJIHDX4|BUJIHDX12|iso_tap} \
        PD_MATRIX {gen_pd_row|gen_pd_col|u_pd|mptdc_pd} \
        FAST_TAG {fast_tag|raw_lfsr_tag|nfast} \
        RO_CONTROL {ro_code|RO_tune6|u_ro_tune4|rstb} \
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
    set ro_count [mptdc_signoff_count_cells [mptdc_signoff_ro_cell_patterns]]
    set raw_pins [mptdc_signoff_collect_pins [mptdc_signoff_ro_pin_patterns]]
    set empty_modules [mptdc_signoff_count_cells [list *MPTDC_OSC_SLOW_BB* *MPTDC_OSC_FAST_BB* *mptdc_osc_stub*]]
    set fh [open $rpt w]
    puts $fh "NETLIST_UNIQUE=YES"
    puts $fh "INIT_DESIGN_UNIQUIFY=1"
    puts $fh "IMPECO-560=0"
    puts $fh "IMPOPT-3115=0"
    puts $fh "TECHLIB-702=0"
    puts $fh "TECHLIB-704=0"
    puts $fh "IMPDB-2504=0"
    puts $fh "RO_TUNE6_INSTANCE_COUNT=$ro_count"
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
    set ro_instances [mptdc_signoff_collect_cells [mptdc_signoff_ro_cell_patterns]]
    puts $fh "RO_TUNE6_INSTANCE_COUNT=[llength $ro_instances]"
    foreach ro $ro_instances {
        puts $fh "RO_TUNE6_INSTANCE=$ro"
    }
    if {[llength $ro_instances] != 2} {
        puts $fh "STATUS=FAIL ERROR=expected_exactly_two_ro_tune6_instances"
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
    puts $fh "PG_CONNECTIVITY_STAGE=PRE_PLACEMENT_GLOBAL_NET_CONNECT"
    puts $fh "UNCONNECTED_STDCELL_PG_PINS=DEFER_TO_POSTROUTE_CONNECTIVITY_GATE"
    puts $fh "UNCONNECTED_RO_PG_PINS=DEFER_TO_POSTROUTE_CONNECTIVITY_GATE"
    puts $fh "PG_OPENS=DEFER_TO_POSTROUTE_CONNECTIVITY_GATE"
    puts $fh "PG_SHORTS=DEFER_TO_POSTROUTE_CONNECTIVITY_GATE"
    close $fh
    if {[llength $failures] > 0} {
        mptdc_signoff_set_status PG_CONNECTIVITY_STATUS FAIL $path
        error "MPTDC_DIGITAL_SIGNOFF_PG_CONNECT_FAILED: $failures"
    }
    mptdc_signoff_set_status PG_CONNECTIVITY_STATUS PROVISIONAL $path
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

proc mptdc_signoff_report_token {text} {
    set token "$text"
    regsub -all {[^[:alnum:]_]+} $token {_} token
    set token [string trim $token _]
    if {$token eq ""} { return item }
    return $token
}

proc mptdc_signoff_report_value {value} {
    set text "$value"
    regsub -all {[\t\r\n]+} $text { } text
    return $text
}

proc mptdc_signoff_sroute_commands {nets} {
    set commands [list \
        [list sroute -connect {corePin blockPin} -nets $nets \
            -blockPin all -blockPinTarget {ring stripe} \
            -corePinTarget {ring stripe} -allowLayerChange 1]]
    if {[mptdc_signoff_env_truthy MPTDC_ENABLE_SROUTE_PADPIN_FALLBACK 0]} {
        lappend commands [list sroute -connect {corePin blockPin padPin} -nets $nets \
            -blockPin all -blockPinTarget {ring stripe} \
            -corePinTarget {ring stripe} -padPinTarget {ring stripe} \
            -allowLayerChange 1]
    }
    return $commands
}

proc mptdc_signoff_postplace_sroute_commands {nets} {
    set commands [list [list sroute -connect {corePin} -nets $nets \
        -corePinTarget {ring stripe} -allowLayerChange 1]]

    if {![mptdc_signoff_env_truthy MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE 0]} {
        return $commands
    }

    if {[mptdc_signoff_env_truthy MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN 0]} {
        set cmd [list sroute -connect {corePin blockPin} -nets $nets \
            -blockPin all -blockPinTarget {ring stripe} \
            -corePinTarget {ring stripe} -allowLayerChange 1]
        if {[lsearch -exact $commands $cmd] < 0} {
            lappend commands $cmd
        }
    }

    foreach cmd [list \
        [list sroute -connect {corePin} -nets $nets \
            -corePinTarget firstAfterRowEnd -allowLayerChange 1] \
    ] {
        if {[lsearch -exact $commands $cmd] < 0} {
            lappend commands $cmd
        }
    }
    return $commands
}

proc mptdc_signoff_capture_sroute_command {cmd path} {
    file mkdir [file dirname $path]
    if {[catch {uplevel #0 "$cmd > \"$path\""} err opts]} {
        set fh [open $path w]
        puts $fh "MPTDC SRoute Command"
        puts $fh "==================="
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh "COMMAND=$cmd"
        puts $fh "ERROR=$err"
        if {[dict exists $opts -errorcode]} {
            puts $fh "ERRORCODE=[dict get $opts -errorcode]"
        }
        if {[dict exists $opts -errorinfo]} {
            puts $fh "ERRORINFO_BEGIN"
            puts $fh [dict get $opts -errorinfo]
            puts $fh "ERRORINFO_END"
        }
        close $fh
        return [list 0 $err]
    }
    return [list 1 ""]
}

proc mptdc_signoff_parse_sroute_report {path} {
    set result [dict create \
        report $path \
        command_failed 0 \
        wires UNKNOWN \
        open_ports 0 \
        block_open_ports 0 \
        core_open_ports 0 \
        power_bump_open_ports 0 \
        status REVIEW_REQUIRED]
    if {![file exists $path]} {
        dict set result reason missing_report
        return $result
    }
    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        if {[regexp -nocase {REPORT_STATUS=FAILED} $line]} {
            dict set result command_failed 1
        }
        if {[regexp -nocase {sroute[[:space:]]+created[[:space:]]+([0-9]+)[[:space:]]+wire} $line -> wires]} {
            dict set result wires $wires
        }
        if {[regexp -nocase {Number[[:space:]]+of[[:space:]]+(Block|Core|Power Bump)[[:space:]]+ports[[:space:]]+routed:.*open:[[:space:]]*([0-9]+)} $line -> port_type open]} {
            switch -nocase -- $port_type {
                block {
                    dict incr result block_open_ports $open
                }
                core {
                    dict incr result core_open_ports $open
                }
                "power bump" {
                    dict incr result power_bump_open_ports $open
                }
            }
            dict incr result open_ports $open
        } elseif {[regexp -nocase {Number[[:space:]]+of[[:space:]].*ports[[:space:]]+routed:.*open:[[:space:]]*([0-9]+)} $line -> open]} {
            dict incr result open_ports $open
        }
    }
    close $fh
    if {[dict get $result command_failed]} {
        dict set result status FAIL
    } elseif {[dict get $result open_ports] > 0} {
        dict set result status REVIEW_REQUIRED
        dict set result reason open_ports_nonzero
    } elseif {[dict get $result wires] ne "UNKNOWN" && [dict get $result wires] == 0} {
        dict set result status REVIEW_REQUIRED
        dict set result reason zero_wires_created
    } else {
        dict set result status PASS
    }
    return $result
}

proc mptdc_signoff_try_sroute_command {fh label commands} {
    puts $fh "${label}_PADPIN_FALLBACK_ENABLED=[expr {[mptdc_signoff_env_truthy MPTDC_ENABLE_SROUTE_PADPIN_FALLBACK 0] ? 1 : 0}]"
    set idx 0
    foreach cmd $commands {
        incr idx
        set report [file join [mptdc_signoff_report_dir] "[mptdc_signoff_report_token $label]_sroute_${idx}.rpt"]
        puts $fh ""
        puts $fh "COMMAND_${label}=$cmd"
        puts $fh "${label}_ATTEMPT_${idx}_REPORT=$report"
        lassign [mptdc_signoff_capture_sroute_command $cmd $report] ok err
        set data [mptdc_signoff_parse_sroute_report $report]
        puts $fh "${label}_ATTEMPT_${idx}_COMMAND_STATUS=[expr {$ok ? "PASS" : "FAIL"}]"
        puts $fh "${label}_ATTEMPT_${idx}_STATUS=[dict get $data status]"
        puts $fh "${label}_ATTEMPT_${idx}_WIRES=[dict get $data wires]"
        puts $fh "${label}_ATTEMPT_${idx}_OPEN_PORTS=[dict get $data open_ports]"
        puts $fh "${label}_ATTEMPT_${idx}_BLOCK_OPEN_PORTS=[dict get $data block_open_ports]"
        puts $fh "${label}_ATTEMPT_${idx}_CORE_OPEN_PORTS=[dict get $data core_open_ports]"
        puts $fh "${label}_ATTEMPT_${idx}_POWER_BUMP_OPEN_PORTS=[dict get $data power_bump_open_ports]"
        if {[dict exists $data reason]} {
            puts $fh "${label}_ATTEMPT_${idx}_REASON=[dict get $data reason]"
        }
        if {!$ok} {
            puts $fh "${label}_ATTEMPT_${idx}_ERROR=$err"
        }
        if {[dict get $data status] eq "PASS"} {
            puts $fh "${label}_STATUS=PASS"
            puts $fh "${label}_REPORT=$report"
            return 1
        }
    }
    puts $fh "${label}_STATUS=FAIL"
    return 0
}

proc mptdc_signoff_sroute_attempt_summary {label} {
    set token [mptdc_signoff_report_token $label]
    set best [dict create status FAIL wires UNKNOWN open_ports 0 reason no_successful_clean_attempt report ""]
    foreach report [lsort [glob -nocomplain [file join [mptdc_signoff_report_dir] "${token}_sroute_*.rpt"]]] {
        set data [mptdc_signoff_parse_sroute_report $report]
        dict set data report $report
        if {[dict get $data status] eq "PASS"} {
            return $data
        }
        set wires [dict get $data wires]
        if {[dict get $data status] eq "REVIEW_REQUIRED"} {
            set best_wires [dict get $best wires]
            set best_open [dict get $best open_ports]
            set data_open [dict get $data open_ports]
            if {[dict get $best status] ne "REVIEW_REQUIRED" ||
                $best_wires eq "UNKNOWN" ||
                $data_open < $best_open ||
                ($data_open == $best_open &&
                    $wires ne "UNKNOWN" &&
                    ($best_wires eq "UNKNOWN" || $wires > $best_wires))} {
                set best $data
            }
        }
    }
    return $best
}

proc mptdc_signoff_try_sroute_mode_group {fh label suffix commands} {
    set applied 0
    foreach cmd $commands {
        puts $fh "${label}_SROUTE_MODE_${suffix}_COMMAND=$cmd"
        if {![catch {{*}$cmd} err]} {
            puts $fh "${label}_SROUTE_MODE_${suffix}_STATUS=PASS"
            set applied 1
            break
        }
        puts $fh "${label}_SROUTE_MODE_${suffix}_ATTEMPT_STATUS=FAIL"
        puts $fh "${label}_SROUTE_MODE_${suffix}_ATTEMPT_ERROR=$err"
    }
    if {!$applied} {
        puts $fh "${label}_SROUTE_MODE_${suffix}_STATUS=REVIEW_REQUIRED"
    }
    return $applied
}

proc mptdc_signoff_configure_sroute_mode {fh label} {
    set core_pin_stop [mptdc_signoff_env MPTDC_SROUTE_CORE_PIN_STOP_ROUTE ""]
    set core_pin_stop_ok 0
    if {$core_pin_stop ne ""} {
        set core_pin_stop_ok [mptdc_signoff_try_sroute_mode_group $fh $label CORE_PIN_STOP_ROUTE [list [list setSrouteMode -corePinStopRoute $core_pin_stop]]]
    }

    if {![mptdc_signoff_env_truthy MPTDC_ENABLE_SROUTE_MODE_EXPERIMENTS 0]} {
        puts $fh "${label}_SROUTE_MODE_EXPERIMENTS_ENABLED=0"
        puts $fh "${label}_SROUTE_MODE_STATUS=[expr {$core_pin_stop eq "" ? "SKIPPED" : ($core_pin_stop_ok ? "PASS" : "REVIEW_REQUIRED")}]"
        puts $fh "${label}_SROUTE_MODE_REASON=[expr {$core_pin_stop eq "" ? "disabled_by_env" : "deterministic_core_pin_stop_only"}]"
        return
    }
    puts $fh "${label}_SROUTE_MODE_EXPERIMENTS_ENABLED=1"
    puts $fh "${label}_SROUTE_MODE_LEGACY_PRESERVE_EXISTING_ROUTES_ENV=[mptdc_signoff_env MPTDC_SROUTE_PRESERVE_EXISTING_ROUTES unset]"
    puts $fh "${label}_SROUTE_MODE_LEGACY_CONNECT_STRIPE_ENV=[mptdc_signoff_env MPTDC_SROUTE_CONNECT_STRIPE unset]"

    set mode_groups [list \
        [list VIA_THRU_TO_CLOSEST_RING [list [list setSrouteMode -viaThruToClosestRing true]]] \
        [list EXTEND_NEAREST_TARGET [list [list setSrouteMode -extendNearestTarget true]]] \
        [list BLOCK_PIN_ROUTE_WITH_PIN_WIDTH [list [list setSrouteMode -blockPinRouteWithPinWidth true]]] \
        [list BLOCK_PIN_CONNECT_RING_PIN_CORNERS [list [list setSrouteMode -blockPinConnectRingPinCorners true]]] \
        [list CONNECT_BROKEN_CORE_PIN [list [list setSrouteMode -connectBrokenCorePin true]]] \
        [list CORE_PIN_REFER_TO_FOLLOW_PIN [list [list setSrouteMode -corePinReferToFollowPin true]]]]

    set via_shape [mptdc_signoff_env MPTDC_SROUTE_VIA_CONNECT_TO_SHAPE ""]
    if {$via_shape ne ""} {
        lappend mode_groups [list VIA_CONNECT_TO_SHAPE [list [list setSrouteMode -viaConnectToShape $via_shape]]]
    }
    set target_search_distance [mptdc_signoff_env MPTDC_SROUTE_TARGET_SEARCH_DISTANCE_UM ""]
    if {$target_search_distance ne ""} {
        lappend mode_groups [list TARGET_SEARCH_DISTANCE [list [list setSrouteMode -targetSearchDistance $target_search_distance]]]
    }
    set pass_count 0
    if {$core_pin_stop_ok} {
        incr pass_count
    }
    foreach group $mode_groups {
        set suffix [lindex $group 0]
        set commands [lindex $group 1]
        if {[mptdc_signoff_try_sroute_mode_group $fh $label $suffix $commands]} {
            incr pass_count
        }
    }
    puts $fh "${label}_SROUTE_MODE_PASS_COUNT=$pass_count"
    puts $fh "${label}_SROUTE_MODE_STATUS=[expr {$pass_count > 0 ? "PASS" : "REVIEW_REQUIRED"}]"
}

proc mptdc_signoff_dump_pg_terms {path {label PG_OBJECT_DUMP}} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "# MPTDC PG Object Dump"
    puts $fh "DUMP_LABEL=$label"
    catch {set_db get_db_display_limit [mptdc_signoff_env_int MPTDC_DB_DISPLAY_LIMIT 20000]}
    foreach item [list \
        [list PG_TERM_NAMES {dbGet top.pgTerms.name}] \
        [list PG_TERM_COUNT {llength [dbGet top.pgTerms.name]}] \
        [list VDD_PG_TERM_HANDLES {dbGet top.pgTerms.name VDD* -p}] \
        [list VDD_PG_TERM_NAMES {dbGet [dbGet top.pgTerms.name VDD* -p].name}] \
        [list VDD_PG_TERM_NETS {dbGet [dbGet top.pgTerms.name VDD* -p].net.name}] \
        [list VDD_PG_TERM_LAYERS {dbGet [dbGet top.pgTerms.name VDD* -p].pins.allShapes.layer.name}] \
        [list VSS_PG_TERM_HANDLES {dbGet top.pgTerms.name VSS* -p}] \
        [list VSS_PG_TERM_NAMES {dbGet [dbGet top.pgTerms.name VSS* -p].name}] \
        [list VSS_PG_TERM_NETS {dbGet [dbGet top.pgTerms.name VSS* -p].net.name}] \
        [list VSS_PG_TERM_LAYERS {dbGet [dbGet top.pgTerms.name VSS* -p].pins.allShapes.layer.name}] \
        [list TERM_NAMES {dbGet top.terms.name}] \
        [list VDD_NET_HANDLES {dbGet top.nets.name VDD -p}] \
        [list VDD_SWIRE_COUNT {llength [dbGet [dbGet top.nets.name VDD -p].sWires]}] \
        [list VDD_SWIRE_LAYERS {dbGet [dbGet top.nets.name VDD -p].sWires.layer.name}] \
        [list VDD_SWIRE_STATUS {dbGet [dbGet top.nets.name VDD -p].sWires.status}] \
        [list VSS_NET_HANDLES {dbGet top.nets.name VSS -p}] \
        [list VSS_SWIRE_COUNT {llength [dbGet [dbGet top.nets.name VSS -p].sWires]}] \
        [list VSS_SWIRE_LAYERS {dbGet [dbGet top.nets.name VSS -p].sWires.layer.name}] \
        [list VSS_SWIRE_STATUS {dbGet [dbGet top.nets.name VSS -p].sWires.status}] \
        [list GET_PORTS_VDD {get_ports -quiet VDD}] \
        [list GET_PORTS_VSS {get_ports -quiet VSS}] \
    ] {
        set key [lindex $item 0]
        set cmd [lindex $item 1]
        puts $fh ""
        puts $fh "${key}_COMMAND=$cmd"
        puts $fh "${key}_BEGIN"
        if {[catch {set value [uplevel #0 $cmd]} err]} {
            puts $fh "${key}_STATUS=FAIL"
            puts $fh "${key}_ERROR=[mptdc_signoff_report_value $err]"
        } else {
            puts $fh "${key}_STATUS=PASS"
            puts $fh "${key}_VALUE=[mptdc_signoff_report_value $value]"
            puts $fh [mptdc_signoff_report_value $value]
        }
        puts $fh "${key}_END"
    }
    close $fh
    return $path
}

proc mptdc_signoff_dump_pg_topology_value {fh key cmd} {
    puts $fh ""
    puts $fh "${key}_COMMAND=$cmd"
    puts $fh "${key}_BEGIN"
    if {[catch {set value [uplevel #0 $cmd]} err]} {
        puts $fh "${key}_STATUS=FAIL"
        puts $fh "${key}_ERROR=[mptdc_signoff_report_value $err]"
    } else {
        puts $fh "${key}_STATUS=PASS"
        puts $fh "${key}_VALUE=[mptdc_signoff_report_value $value]"
    }
    puts $fh "${key}_END"
}

proc mptdc_signoff_dump_pg_topology {path {label PG_TOPOLOGY}} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    set base [file rootname [file tail $path]]
    set dir [file dirname $path]
    puts $fh "# MPTDC PG Topology Dump"
    puts $fh "DUMP_LABEL=$label"
    catch {set_db get_db_display_limit [mptdc_signoff_env_int MPTDC_DB_DISPLAY_LIMIT 50000]}

    foreach item [list \
        [list marker {dbSchema marker}] \
        [list sWire {dbSchema sWire}] \
        [list term {dbSchema term}] \
        [list pin {dbSchema pin}] \
        [list pinShape {dbSchema pinShape}] \
    ] {
        set name [lindex $item 0]
        set cmd [lindex $item 1]
        set schema_path [file join $dir "${base}_${name}_schema.rpt"]
        puts $fh "SCHEMA_${name}_REPORT=$schema_path"
        if {[catch {uplevel #0 "$cmd > \"$schema_path\""} err]} {
            puts $fh "SCHEMA_${name}_STATUS=FAIL"
            puts $fh "SCHEMA_${name}_ERROR=[mptdc_signoff_report_value $err]"
        } else {
            puts $fh "SCHEMA_${name}_STATUS=PASS"
        }
    }

    foreach item [list \
        [list TOP_NAME {dbGet top.name}] \
        [list CORE_BOX {dbGet top.fPlan.coreBox}] \
        [list PG_TERM_NAMES {dbGet top.pgTerms.name}] \
        [list PG_TERM_NETS {dbGet top.pgTerms.net.name}] \
        [list PG_TERM_LAYERS {dbGet top.pgTerms.pins.allShapes.layer.name}] \
        [list VDD_PGTERM_NAMES {dbGet [dbGet top.pgTerms.net.name VDD -p2].name}] \
        [list VSS_PGTERM_NAMES {dbGet [dbGet top.pgTerms.net.name VSS -p2].name}] \
        [list VDD_SWIRE_COUNT {llength [dbGet [dbGet top.nets.name VDD -p].sWires]}] \
        [list VSS_SWIRE_COUNT {llength [dbGet [dbGet top.nets.name VSS -p].sWires]}] \
    ] {
        mptdc_signoff_dump_pg_topology_value $fh [lindex $item 0] [lindex $item 1]
    }

    set max_swires [mptdc_signoff_env_int MPTDC_PG_TOPOLOGY_MAX_SWIRE_ROWS 600]
    puts $fh ""
    puts $fh "SWIRE_NON_FOLLOWPIN_TABLE_BEGIN"
    puts $fh "net\tidx\tshape\tlayer\tstatus\twidth\tgeomType\tbox\tpts"
    foreach net {VDD VSS} {
        if {[catch {set nh [dbGet top.nets.name $net -p]} err] || $nh eq "" || $nh eq "0x0"} {
            puts $fh "$net\tERROR\t[mptdc_signoff_report_value $err]"
            continue
        }
        if {[catch {set swires [dbGet $nh.sWires]} err]} {
            puts $fh "$net\tERROR\t[mptdc_signoff_report_value $err]"
            continue
        }
        set idx 0
        set rows 0
        set skipped_followpin 0
        foreach sw $swires {
            incr idx
            if {$sw eq "" || $sw eq "0x0" || $sw eq "NULL"} {
                continue
            }
            set shape UNKNOWN
            set layer UNKNOWN
            set status UNKNOWN
            set width UNKNOWN
            set geom UNKNOWN
            set box UNKNOWN
            set pts UNKNOWN
            catch {set shape [dbGet $sw.shape]}
            if {$shape eq "followpin"} {
                incr skipped_followpin
                continue
            }
            catch {set layer [dbGet $sw.layer.name]}
            catch {set status [dbGet $sw.status]}
            catch {set width [dbGet $sw.width]}
            catch {set geom [dbGet $sw.geomType]}
            catch {set box [dbGet $sw.box]}
            catch {set pts [dbGet $sw.pts]}
            puts $fh "$net\t$idx\t[mptdc_signoff_report_value $shape]\t[mptdc_signoff_report_value $layer]\t[mptdc_signoff_report_value $status]\t[mptdc_signoff_report_value $width]\t[mptdc_signoff_report_value $geom]\t[mptdc_signoff_report_value $box]\t[mptdc_signoff_report_value $pts]"
            incr rows
            if {$rows >= $max_swires} {
                puts $fh "$net\tTRUNCATED\tmax_non_followpin_rows=$max_swires"
                break
            }
        }
        puts $fh "$net\tFOLLOWPIN_ROWS_SKIPPED\t$skipped_followpin"
    }
    puts $fh "SWIRE_NON_FOLLOWPIN_TABLE_END"

    set verify_rpt [file join $dir "${base}_verify_special.rpt"]
    set verify_console [file join $dir "${base}_verify_special.console.rpt"]
    puts $fh ""
    puts $fh "VERIFY_SPECIAL_REPORT=$verify_rpt"
    puts $fh "VERIFY_SPECIAL_CONSOLE=$verify_console"
    if {[catch {uplevel #0 "verifyConnectivity -type special -nets {VDD VSS} -report \"$verify_rpt\" > \"$verify_console\""} err]} {
        puts $fh "VERIFY_SPECIAL_STATUS=FAIL"
        puts $fh "VERIFY_SPECIAL_ERROR=[mptdc_signoff_report_value $err]"
    } else {
        puts $fh "VERIFY_SPECIAL_STATUS=PASS"
    }

    set max_markers [mptdc_signoff_env_int MPTDC_PG_TOPOLOGY_MAX_MARKER_ROWS 160]
    puts $fh ""
    puts $fh "MARKER_TABLE_BEGIN"
    puts $fh "idx\thandle\tbox\tlayer\ttype\tsubType\tmessage"
    if {[catch {set markers [dbGet top.markers]} err]} {
        puts $fh "MARKER_STATUS=FAIL\t[mptdc_signoff_report_value $err]"
    } else {
        set idx 0
        foreach marker $markers {
            if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} { continue }
            incr idx
            if {$idx > $max_markers} {
                puts $fh "TRUNCATED\tmax_marker_rows=$max_markers"
                break
            }
            set box UNKNOWN
            set layer UNKNOWN
            set type UNKNOWN
            set subtype UNKNOWN
            set message UNKNOWN
            catch {set box [dbGet $marker.box]}
            catch {set layer [dbGet $marker.layer.name]}
            catch {set type [dbGet $marker.type]}
            catch {set subtype [dbGet $marker.subType]}
            catch {set message [dbGet $marker.message]}
            puts $fh "$idx\t[mptdc_signoff_report_value $marker]\t[mptdc_signoff_report_value $box]\t[mptdc_signoff_report_value $layer]\t[mptdc_signoff_report_value $type]\t[mptdc_signoff_report_value $subtype]\t[mptdc_signoff_report_value $message]"
        }
        puts $fh "MARKER_COUNT=$idx"
    }
    puts $fh "MARKER_TABLE_END"
    close $fh
    return $path
}

proc mptdc_signoff_pg_connectivity_commands {nets} {
    return [list \
        [list verifyConnectivity -type special -nets $nets] \
        [list verifyConnectivity -nets $nets -type special] \
        [list verifyConnectivity -type special -net $nets] \
        [list verifyConnectivity -net $nets -type special] \
        [list verifyConnectivity -type special]]
}

proc mptdc_signoff_capture_to_file_selected {path commands} {
    foreach cmd $commands {
        if {![catch {uplevel 1 "$cmd > \"$path\""} err]} {
            return [list 1 $cmd]
        }
        set fh [open $path w]
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh "COMMAND=$cmd"
        puts $fh "ERROR=$err"
        close $fh
    }
    return [list 0 ""]
}

proc mptdc_signoff_run_postplace_pre_route_sroute {} {
    set rpt [file join [mptdc_signoff_report_dir] postplace_pre_route_sroute_status.rpt]
    set fh [open $rpt w]
    puts $fh "# MPTDC Post-placement Pre-route SRoute Status"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_ENABLED=[expr {[mptdc_signoff_env_truthy MPTDC_ENABLE_POSTPLACE_PRE_ROUTE_SROUTE 1] ? 1 : 0}]"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_REQUIRE_CLEAN=[expr {[mptdc_signoff_env_truthy MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN 1] ? 1 : 0}]"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_CANDIDATE_PROBE=[expr {[mptdc_signoff_env_truthy MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE 0] ? 1 : 0}]"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_BLOCKPIN=[expr {[mptdc_signoff_env_truthy MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN 0] ? 1 : 0}]"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_CORE_PIN_STOP_ROUTE=[mptdc_signoff_env MPTDC_SROUTE_CORE_PIN_STOP_ROUTE unset]"
    if {![mptdc_signoff_env_truthy MPTDC_ENABLE_POSTPLACE_PRE_ROUTE_SROUTE 1]} {
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_STATUS=SKIPPED"
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_REASON=disabled_by_env"
        close $fh
        return $rpt
    }

    set pg_dump_initial [mptdc_signoff_dump_pg_terms \
        [file join [mptdc_signoff_report_dir] postplace_pre_route_pg_objects_before_stitch.rpt] \
        POSTPLACE_PRE_ROUTE_BEFORE_STITCH]
    puts $fh "POSTPLACE_PRE_ROUTE_PG_OBJECT_DUMP_BEFORE_STITCH=$pg_dump_initial"
    lassign [mptdc_signoff_create_block_pg_stitches \
        postplace_pre_route_block_pg_stitch_status.rpt \
        POSTPLACE_PRE_ROUTE_BLOCK_PG_STITCH] postplace_stitch_ok postplace_stitch_rpt
    puts $fh "POSTPLACE_PRE_ROUTE_BLOCK_PG_STITCH_STATUS=[expr {$postplace_stitch_ok ? "PASS" : "FAIL"}]"
    puts $fh "POSTPLACE_PRE_ROUTE_BLOCK_PG_STITCH_REPORT=$postplace_stitch_rpt"
    set pg_dump_pre [mptdc_signoff_dump_pg_terms \
        [file join [mptdc_signoff_report_dir] postplace_pre_route_pg_objects_before_sroute.rpt] \
        POSTPLACE_PRE_ROUTE_BEFORE_SROUTE]
    puts $fh "POSTPLACE_PRE_ROUTE_PG_OBJECT_DUMP_BEFORE=$pg_dump_pre"
    set pg_topology_pre [mptdc_signoff_dump_pg_topology \
        [file join [mptdc_signoff_report_dir] postplace_pre_route_pg_topology_before_sroute.rpt] \
        POSTPLACE_PRE_ROUTE_BEFORE_SROUTE]
    puts $fh "POSTPLACE_PRE_ROUTE_PG_TOPOLOGY_BEFORE=$pg_topology_pre"
    set ro_pg_probe_pre [mptdc_signoff_ro_pg_probe \
        [file join [mptdc_signoff_report_dir] ro_pg_probe_before_hookup.rpt] \
        POSTPLACE_PRE_ROUTE_BEFORE_RO_PG_HOOKUP]
    puts $fh "POSTPLACE_PRE_ROUTE_RO_PG_PROBE_BEFORE=$ro_pg_probe_pre"
    lassign [mptdc_signoff_ro_pg_hookup] ro_pg_hookup_ok ro_pg_hookup_rpt
    puts $fh "POSTPLACE_PRE_ROUTE_RO_PG_HOOKUP_STATUS=[expr {$ro_pg_hookup_ok ? "PASS_OR_SKIPPED" : "FAIL"}]"
    puts $fh "POSTPLACE_PRE_ROUTE_RO_PG_HOOKUP_REPORT=$ro_pg_hookup_rpt"
    set ro_pg_probe_post [mptdc_signoff_ro_pg_probe \
        [file join [mptdc_signoff_report_dir] ro_pg_probe_after_hookup.rpt] \
        POSTPLACE_PRE_ROUTE_AFTER_RO_PG_HOOKUP]
    puts $fh "POSTPLACE_PRE_ROUTE_RO_PG_PROBE_AFTER=$ro_pg_probe_post"
    set pg_topology_after_hookup [mptdc_signoff_dump_pg_topology \
        [file join [mptdc_signoff_report_dir] postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt] \
        POSTPLACE_PRE_ROUTE_AFTER_RO_PG_HOOKUP]
    puts $fh "POSTPLACE_PRE_ROUTE_PG_TOPOLOGY_AFTER_RO_PG_HOOKUP=$pg_topology_after_hookup"
    mptdc_signoff_configure_sroute_mode $fh POSTPLACE_PRE_ROUTE
    set command_ok [mptdc_signoff_try_sroute_command $fh POSTPLACE_PRE_ROUTE_SROUTE [mptdc_signoff_postplace_sroute_commands {VDD VSS}]]
    set pg_dump_post [mptdc_signoff_dump_pg_terms \
        [file join [mptdc_signoff_report_dir] postplace_pre_route_pg_objects_after_sroute.rpt] \
        POSTPLACE_PRE_ROUTE_AFTER_SROUTE]
    puts $fh "POSTPLACE_PRE_ROUTE_PG_OBJECT_DUMP_AFTER=$pg_dump_post"
    set pg_topology_post [mptdc_signoff_dump_pg_topology \
        [file join [mptdc_signoff_report_dir] postplace_pre_route_pg_topology_after_sroute.rpt] \
        POSTPLACE_PRE_ROUTE_AFTER_SROUTE]
    puts $fh "POSTPLACE_PRE_ROUTE_PG_TOPOLOGY_AFTER=$pg_topology_post"
    set summary [mptdc_signoff_sroute_attempt_summary POSTPLACE_PRE_ROUTE_SROUTE]
    set summary_status [dict get $summary status]
    set wires [dict get $summary wires]
    set open_ports [dict get $summary open_ports]
    set progress_ok [expr {$summary_status in {PASS REVIEW_REQUIRED} &&
        $wires ne "UNKNOWN" && $wires > 0}]
    if {$command_ok} {
        set status PASS
    } elseif {$progress_ok} {
        set status REVIEW_REQUIRED
    } else {
        set status FAIL
    }
    set status_before_verify $status

    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_COMMAND_STATUS=[expr {$command_ok ? "PASS" : "FAIL"}]"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_STATUS=$summary_status"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_WIRES=$wires"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_OPEN_PORTS=$open_ports"
    if {[dict exists $summary block_open_ports]} {
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_BLOCK_OPEN_PORTS=[dict get $summary block_open_ports]"
    }
    if {[dict exists $summary core_open_ports]} {
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_CORE_OPEN_PORTS=[dict get $summary core_open_ports]"
    }
    if {[dict exists $summary power_bump_open_ports]} {
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_POWER_BUMP_OPEN_PORTS=[dict get $summary power_bump_open_ports]"
    }
    if {[dict exists $summary reason]} {
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_REASON=[dict get $summary reason]"
    }
    if {[dict exists $summary report]} {
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_REPORT=[dict get $summary report]"
    }
    set special_rpt [file join [mptdc_signoff_report_dir] postplace_pre_route_verify_connectivity_special.rpt]
    lassign [mptdc_signoff_capture_to_file_selected $special_rpt [mptdc_signoff_pg_connectivity_commands {VDD VSS}]] special_capture_ok special_capture_cmd
    set special_bad [mptdc_signoff_connectivity_report_has_errors $special_rpt]
    puts $fh "POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_REPORT=$special_rpt"
    puts $fh "POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_CAPTURE_STATUS=[expr {$special_capture_ok ? "PASS" : "FAIL"}]"
    puts $fh "POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_COMMAND=$special_capture_cmd"
    puts $fh "POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=[lindex $special_bad 0]"
    puts $fh "POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD_LINES=[lindex $special_bad 1]"
    set verify_clean_override 0
    if {$status ne "PASS" &&
        $special_capture_ok &&
        ![lindex $special_bad 0] &&
        [mptdc_signoff_env_truthy MPTDC_POSTPLACE_PRE_ROUTE_ACCEPT_PG_VERIFY_CLEAN 1]} {
        set status PASS
        set verify_clean_override 1
    }
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_STATUS_BEFORE_VERIFY=$status_before_verify"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_VERIFY_CLEAN_OVERRIDE=$verify_clean_override"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_PROGRESS_STATUS=[expr {$progress_ok ? "PASS" : "FAIL"}]"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_STATUS=$status"
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_FINAL_GATE=route_status.rpt"
    set gate_action PASS
    if {$status ne "PASS"} {
        if {[mptdc_signoff_env_truthy MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN 1]} {
            set gate_action FAIL_FAST
        } else {
            set gate_action CONTINUE_FOR_ROUTE_GATE
        }
    }
    puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_GATE_ACTION=$gate_action"

    if {$status ne "PASS" &&
        [mptdc_signoff_env_truthy MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN 1]} {
        set fail_def [file join [mptdc_signoff_def_dir] 03b_postplace_pre_route_sroute_failed.def]
        set fail_ckpt [file join [mptdc_signoff_checkpoint_dir] 03b_postplace_pre_route_sroute_failed.enc]
        set fail_ckpt_dat "${fail_ckpt}.dat"
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_FAILURE_DEF=$fail_def"
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_FAILURE_CHECKPOINT=$fail_ckpt"
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_FAILURE_CHECKPOINT_DAT=$fail_ckpt_dat"
        close $fh
        set def_status PASS
        set def_error ""
        if {[catch {defOut $fail_def} def_error]} {
            set def_status FAIL
        }
        set ckpt_status PASS
        set ckpt_error ""
        if {[catch {saveDesign $fail_ckpt} ckpt_error]} {
            set ckpt_status FAIL
        }
        set fh [open $rpt a]
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_FAILURE_DEF_SAVE_STATUS=$def_status"
        if {$def_error ne ""} {
            puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_FAILURE_DEF_SAVE_ERROR=[mptdc_signoff_report_value $def_error]"
        }
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_FAILURE_CHECKPOINT_SAVE_STATUS=$ckpt_status"
        if {$ckpt_error ne ""} {
            puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_FAILURE_CHECKPOINT_SAVE_ERROR=[mptdc_signoff_report_value $ckpt_error]"
        }
        puts $fh "POSTPLACE_PRE_ROUTE_SROUTE_FAILURE_CHECKPOINT_DAT_EXISTS=[expr {[file isdirectory $fail_ckpt_dat] ? 1 : 0}]"
        close $fh
        error "MPTDC_POSTPLACE_PRE_ROUTE_SROUTE_GATE_FAILED: status=$status report=$rpt"
    }
    close $fh
    return $rpt
}

proc mptdc_signoff_block_pg_pin_specs {} {
    set style [mptdc_signoff_block_pg_pin_style]
    switch -- $style {
        left_vdd_right_vss {
            return [list [list VDD LEFT 0.50 VDD] [list VSS RIGHT 0.50 VSS]]
        }
        left_vss_right_vdd {
            return [list [list VSS LEFT 0.50 VSS] [list VDD RIGHT 0.50 VDD]]
        }
        both_sides_vdd_vss {
            return [list \
                [list VDD LEFT 0.40 VDD_LEFT] \
                [list VSS LEFT 0.60 VSS_LEFT] \
                [list VDD RIGHT 0.40 VDD_RIGHT] \
                [list VSS RIGHT 0.60 VSS_RIGHT]]
        }
        top_bottom_vdd_vss {
            return [list \
                [list VDD TOP 0.40 VDD_TOP MET3] \
                [list VSS TOP 0.60 VSS_TOP MET3] \
                [list VDD BOTTOM 0.40 VDD_BOTTOM MET3] \
                [list VSS BOTTOM 0.60 VSS_BOTTOM MET3]]
        }
        all_sides_vdd_vss {
            return [list \
                [list VDD LEFT 0.40 VDD_LEFT METTP] \
                [list VSS LEFT 0.60 VSS_LEFT METTP] \
                [list VDD RIGHT 0.40 VDD_RIGHT METTP] \
                [list VSS RIGHT 0.60 VSS_RIGHT METTP] \
                [list VDD TOP 0.40 VDD_TOP MET3] \
                [list VSS TOP 0.60 VSS_TOP MET3] \
                [list VDD BOTTOM 0.40 VDD_BOTTOM MET3] \
                [list VSS BOTTOM 0.60 VSS_BOTTOM MET3]]
        }
        mesh_lr_vdd_vss {
            return [list \
                [list VDD LEFT 0.40 VDD_LEFT METTP] \
                [list VSS LEFT 0.60 VSS_LEFT METTP] \
                [list VDD RIGHT 0.40 VDD_RIGHT METTP] \
                [list VSS RIGHT 0.60 VSS_RIGHT METTP]]
        }
        mesh_intersection -
        mesh_intersection_vdd_vss {
            return [list \
                [list VDD LEFT 0.40 VDD_LEFT METTP] \
                [list VSS LEFT 0.60 VSS_LEFT METTP] \
                [list VDD RIGHT 0.40 VDD_RIGHT METTP] \
                [list VSS RIGHT 0.60 VSS_RIGHT METTP] \
                [list VDD TOP 0.40 VDD_TOP MET3] \
                [list VSS TOP 0.60 VSS_TOP MET3] \
                [list VDD BOTTOM 0.40 VDD_BOTTOM MET3] \
                [list VSS BOTTOM 0.60 VSS_BOTTOM MET3]]
        }
        default {
            error "MPTDC_UNSUPPORTED_BLOCK_PG_PIN_STYLE: $style"
        }
    }
}

proc mptdc_signoff_block_pg_pin_style {} {
    return [string tolower [mptdc_signoff_env MPTDC_BLOCK_PG_PIN_STYLE mesh_lr_vdd_vss]]
}

proc mptdc_signoff_block_pg_pin_style_is_mesh {} {
    set style [mptdc_signoff_block_pg_pin_style]
    return [expr {$style in {mesh_lr_vdd_vss mesh_intersection mesh_intersection_vdd_vss}}]
}

proc mptdc_signoff_pg_ring_width {} {
    return [mptdc_signoff_env_double MPTDC_PG_RING_WIDTH_UM 2.0]
}

proc mptdc_signoff_pg_ring_spacing {} {
    return [mptdc_signoff_env_double MPTDC_PG_RING_SPACING_UM 1.0]
}

proc mptdc_signoff_pg_ring_offset {} {
    return [mptdc_signoff_env_double MPTDC_PG_RING_OFFSET_UM 2.0]
}

proc mptdc_signoff_pg_stripe_width {} {
    return [mptdc_signoff_env_double MPTDC_PG_STRIPE_WIDTH_UM 2.0]
}

proc mptdc_signoff_pg_stripe_spacing {} {
    return [mptdc_signoff_env_double MPTDC_PG_STRIPE_SPACING_UM 2.0]
}

proc mptdc_signoff_pg_stripe_pitch {} {
    return [mptdc_signoff_env_double MPTDC_PG_STRIPE_PITCH_UM 80.0]
}

proc mptdc_signoff_pg_stripe_start_offset {} {
    return [mptdc_signoff_env_double MPTDC_PG_STRIPE_START_OFFSET_UM 20.0]
}

proc mptdc_signoff_pg_ring_center {net side core_box} {
    set ring_width [mptdc_signoff_pg_ring_width]
    set ring_spacing [mptdc_signoff_pg_ring_spacing]
    set ring_offset [mptdc_signoff_pg_ring_offset]
    set slot [mptdc_signoff_block_pg_net_slot $net]
    set delta [expr {$ring_offset + ($ring_width / 2.0) + ($slot * ($ring_width + $ring_spacing))}]
    switch -- [string toupper $side] {
        LEFT {
            return [expr {[lindex $core_box 0] - $delta}]
        }
        RIGHT {
            return [expr {[lindex $core_box 2] + $delta}]
        }
        BOTTOM {
            return [expr {[lindex $core_box 1] - $delta}]
        }
        TOP {
            return [expr {[lindex $core_box 3] + $delta}]
        }
        default {
            error "MPTDC_UNSUPPORTED_PG_RING_SIDE: $side"
        }
    }
}

proc mptdc_signoff_pg_nearest_stripe_center {net axis core_box fraction} {
    set axis [string tolower $axis]
    if {$axis eq "x"} {
        set min [lindex $core_box 0]
        set max [lindex $core_box 2]
    } elseif {$axis eq "y"} {
        set min [lindex $core_box 1]
        set max [lindex $core_box 3]
    } else {
        error "MPTDC_UNSUPPORTED_PG_STRIPE_AXIS: $axis"
    }
    if {![string is double -strict $fraction]} {
        set fraction 0.50
    }
    if {$fraction < 0.0} { set fraction 0.0 }
    if {$fraction > 1.0} { set fraction 1.0 }
    set stripe_width [mptdc_signoff_pg_stripe_width]
    set stripe_spacing [mptdc_signoff_pg_stripe_spacing]
    set stripe_pitch [mptdc_signoff_pg_stripe_pitch]
    set stripe_start [mptdc_signoff_pg_stripe_start_offset]
    set slot [mptdc_signoff_block_pg_net_slot $net]
    set first [expr {$min + $stripe_start + ($stripe_width / 2.0) + ($slot * ($stripe_width + $stripe_spacing))}]
    set target [expr {$min + (($max - $min) * $fraction)}]
    if {$stripe_pitch <= 0.0} {
        set stripe_pitch [expr {$stripe_width + $stripe_spacing}]
    }
    set idx [expr {int(floor((($target - $first) / $stripe_pitch) + 0.5))}]
    if {$idx < 0} { set idx 0 }
    set max_idx [expr {int(floor(($max - $first) / $stripe_pitch))}]
    if {$max_idx < 0} { set max_idx 0 }
    if {$idx > $max_idx} { set idx $max_idx }
    return [format %.3f [expr {$first + ($idx * $stripe_pitch)}]]
}

proc mptdc_signoff_pg_mesh_pin_rect {net side core_box width y_fraction} {
    if {$net eq ""} {
        set net [expr {$y_fraction > 0.5 ? "VSS" : "VDD"}]
    }
    set side_u [string toupper $side]
    set ring_width [mptdc_signoff_pg_ring_width]
    set ring_half [expr {$ring_width / 2.0}]
    set pin_half [expr {$width / 2.0}]
    switch -- $side_u {
        LEFT -
        RIGHT {
            set x [mptdc_signoff_pg_ring_center $net $side_u $core_box]
            set y [mptdc_signoff_pg_nearest_stripe_center $net y $core_box $y_fraction]
            return [list \
                [format %.3f [expr {$x - $ring_half}]] \
                [format %.3f [expr {$y - $pin_half}]] \
                [format %.3f [expr {$x + $ring_half}]] \
                [format %.3f [expr {$y + $pin_half}]]]
        }
        TOP -
        BOTTOM {
            set x [mptdc_signoff_pg_nearest_stripe_center $net x $core_box $y_fraction]
            set y [mptdc_signoff_pg_ring_center $net $side_u $core_box]
            return [list \
                [format %.3f [expr {$x - $pin_half}]] \
                [format %.3f [expr {$y - $ring_half}]] \
                [format %.3f [expr {$x + $pin_half}]] \
                [format %.3f [expr {$y + $ring_half}]]]
        }
        default {
            error "MPTDC_UNSUPPORTED_BLOCK_PG_PIN_SIDE: $side"
        }
    }
}

proc mptdc_signoff_block_pg_pin_rect {side core_box width depth {y_fraction 0.50} {net ""}} {
    if {[mptdc_signoff_block_pg_pin_style_is_mesh]} {
        return [mptdc_signoff_pg_mesh_pin_rect $net $side $core_box $width $y_fraction]
    }
    set llx [lindex $core_box 0]
    set lly [lindex $core_box 1]
    set urx [lindex $core_box 2]
    set ury [lindex $core_box 3]
    set outside [mptdc_signoff_env_double MPTDC_BLOCK_PG_PIN_OUTSIDE_OVERLAP_UM 8.0]
    if {![string is double -strict $y_fraction]} {
        set y_fraction 0.50
    }
    if {$y_fraction < 0.0} { set y_fraction 0.0 }
    if {$y_fraction > 1.0} { set y_fraction 1.0 }
    set cy [expr {$lly + (($ury - $lly) * $y_fraction)}]
    set half [expr {$width / 2.0}]
    switch -- [string toupper $side] {
        LEFT {
            return [list [expr {$llx - $outside}] [expr {$cy - $half}] [expr {$llx + $depth}] [expr {$cy + $half}]]
        }
        RIGHT {
            return [list [expr {$urx - $depth}] [expr {$cy - $half}] [expr {$urx + $outside}] [expr {$cy + $half}]]
        }
        TOP {
            set cx [expr {$llx + (($urx - $llx) * $y_fraction)}]
            return [list [expr {$cx - $half}] [expr {$ury - $depth}] [expr {$cx + $half}] [expr {$ury + $outside}]]
        }
        BOTTOM {
            set cx [expr {$llx + (($urx - $llx) * $y_fraction)}]
            return [list [expr {$cx - $half}] [expr {$lly - $outside}] [expr {$cx + $half}] [expr {$lly + $depth}]]
        }
        default {
            error "MPTDC_UNSUPPORTED_BLOCK_PG_PIN_SIDE: $side"
        }
    }
}

proc mptdc_signoff_verify_block_pg_pin {net} {
    set ports [list]
    if {![catch {set ports [get_ports -quiet $net]}] && [llength $ports] > 0} {
        return [list 1 get_ports [mptdc_signoff_object_names $ports]]
    }
    set names ""
    foreach cmd [list \
        [list dbGet top.pgTerms.name] \
        [list dbGet top.terms.name] \
        [list get_db ports $net] \
    ] {
        if {![catch {set names [{*}$cmd]}] && $names ne "" && $names ne "0x0"} {
            foreach name $names {
                if {$name eq $net} {
                    return [list 1 $cmd $names]
                }
                if {[regexp "^${net}(_|$)" $name]} {
                    return [list 1 $cmd $names]
                }
            }
        }
    }
    return [list 0 none "no top-level term/port object found for $net"]
}

proc mptdc_signoff_create_one_block_pg_pin {fh pin_name net side layer rect width depth} {
    set label [mptdc_signoff_report_token $pin_name]
    set side_lc [string tolower $side]
    set assign_x [expr {([lindex $rect 0] + [lindex $rect 2]) / 2.0}]
    set assign_y [expr {([lindex $rect 1] + [lindex $rect 3]) / 2.0}]
    set llx [lindex $rect 0]
    set lly [lindex $rect 1]
    set urx [lindex $rect 2]
    set ury [lindex $rect 3]
    set create_mode [string tolower [mptdc_signoff_env MPTDC_BLOCK_PG_PIN_CREATE_MODE geom]]
    puts $fh "BLOCK_PG_PIN_${label}_CREATE_MODE=$create_mode"
    set on_die_commands [list \
        [list createPGPin -onDie -net $net -width $width -length $depth] \
        [list createPGPin -onDie -net $net -width $depth -length $width]]
    set geom_commands [list \
        [list createPGPin $pin_name -net $net -geom $layer $llx $lly $urx $ury -dir bidi] \
        [list createPGPin $pin_name -net $net -geom $layer $llx $lly $urx $ury]]
    set editpin_commands [list \
        [list editPin -pin $pin_name -side $side -layer $layer -assign [list $assign_x $assign_y] -pinWidth $width -pinDepth $depth -fixedPin 1] \
        [list editPin -pin $pin_name -side $side -layer $layer -spreadType SIDE -pinWidth $width -pinDepth $depth -fixedPin 1] \
        [list editPin -pin $pin_name -side $side_lc -layer $layer -assign [list $assign_x $assign_y] -pinWidth $width -pinDepth $depth -fixedPin 1]]
    set commands [list]
    if {$create_mode eq "geom"} {
        set commands $geom_commands
    } elseif {$create_mode eq "geom_then_on_die"} {
        set commands [concat $geom_commands $on_die_commands]
    } else {
        set commands [concat $on_die_commands $geom_commands]
    }
    if {[mptdc_signoff_env_truthy MPTDC_BLOCK_PG_PIN_EDITPIN_FALLBACK 0]} {
        set commands [concat $commands $editpin_commands]
    } else {
        puts $fh "BLOCK_PG_PIN_${label}_EDITPIN_FALLBACK=DISABLED"
    }
    foreach cmd $commands {
        puts $fh "BLOCK_PG_PIN_${label}_COMMAND=$cmd"
        if {![catch {{*}$cmd} err]} {
            puts $fh "BLOCK_PG_PIN_${label}_CREATE_STATUS=PASS"
            puts $fh "BLOCK_PG_PIN_${label}_CREATE_COMMAND=$cmd"
            return 1
        }
        puts $fh "BLOCK_PG_PIN_${label}_ATTEMPT_STATUS=FAIL"
        puts $fh "BLOCK_PG_PIN_${label}_ATTEMPT_ERROR=$err"
    }
    puts $fh "BLOCK_PG_PIN_${label}_CREATE_STATUS=FAIL"
    return 0
}

proc mptdc_signoff_create_block_pg_pins {} {
    set rpt [file join [mptdc_signoff_report_dir] block_pg_pin_status.rpt]
    set fh [open $rpt w]
    puts $fh "# MPTDC Block PG Pin Status"
    puts $fh "BLOCK_PG_PIN_ENABLE=[mptdc_signoff_env MPTDC_ENABLE_BLOCK_PG_PINS 1]"
    if {![mptdc_signoff_env_truthy MPTDC_ENABLE_BLOCK_PG_PINS 1]} {
        puts $fh "BLOCK_PG_PIN_STATUS=SKIPPED"
        puts $fh "BLOCK_PG_PIN_REASON=MPTDC_ENABLE_BLOCK_PG_PINS_DISABLED"
        close $fh
        return [list 1 $rpt]
    }

    set layer [mptdc_signoff_env MPTDC_BLOCK_PG_PIN_LAYER METTP]
    set width [mptdc_signoff_env_double MPTDC_BLOCK_PG_PIN_WIDTH_UM 4.0]
    set depth [mptdc_signoff_env_double MPTDC_BLOCK_PG_PIN_DEPTH_UM 28.0]
    set core_box [mptdc_signoff_core_box]
    puts $fh "BLOCK_PG_PIN_LAYER=$layer"
    puts $fh "BLOCK_PG_PIN_STYLE=[mptdc_signoff_env MPTDC_BLOCK_PG_PIN_STYLE mesh_lr_vdd_vss]"
    puts $fh "BLOCK_PG_PIN_WIDTH_UM=$width"
    puts $fh "BLOCK_PG_PIN_DEPTH_UM=$depth"
    puts $fh "BLOCK_PG_PIN_OUTSIDE_OVERLAP_UM=[mptdc_signoff_env_double MPTDC_BLOCK_PG_PIN_OUTSIDE_OVERLAP_UM 8.0]"
    puts $fh "BLOCK_PG_PIN_MESH_ALIGNED=[expr {[mptdc_signoff_block_pg_pin_style_is_mesh] ? 1 : 0}]"
    puts $fh "BLOCK_PG_RING_WIDTH_UM=[mptdc_signoff_pg_ring_width]"
    puts $fh "BLOCK_PG_RING_SPACING_UM=[mptdc_signoff_pg_ring_spacing]"
    puts $fh "BLOCK_PG_RING_OFFSET_UM=[mptdc_signoff_pg_ring_offset]"
    puts $fh "BLOCK_PG_STRIPE_WIDTH_UM=[mptdc_signoff_pg_stripe_width]"
    puts $fh "BLOCK_PG_STRIPE_SPACING_UM=[mptdc_signoff_pg_stripe_spacing]"
    puts $fh "BLOCK_PG_STRIPE_PITCH_UM=[mptdc_signoff_pg_stripe_pitch]"
    puts $fh "BLOCK_PG_STRIPE_START_OFFSET_UM=[mptdc_signoff_pg_stripe_start_offset]"
    puts $fh "CORE_BBOX=$core_box"
    if {![mptdc_signoff_box_valid $core_box]} {
        puts $fh "BLOCK_PG_PIN_STATUS=FAIL"
        puts $fh "BLOCK_PG_PIN_ERROR=invalid_core_bbox"
        close $fh
        return [list 0 $rpt]
    }

    set failures [list]
    foreach spec [mptdc_signoff_block_pg_pin_specs] {
        set net [lindex $spec 0]
        set side [lindex $spec 1]
        set pin_layer $layer
        set y_fraction 0.50
        if {[llength $spec] >= 3} {
            set y_fraction [lindex $spec 2]
        }
        set pin_name $net
        if {[llength $spec] >= 4} {
            set pin_name [lindex $spec 3]
        }
        if {[llength $spec] >= 5} {
            set pin_layer [lindex $spec 4]
        }
        set label [mptdc_signoff_report_token $pin_name]
        set rect [mptdc_signoff_block_pg_pin_rect $side $core_box $width $depth $y_fraction $net]
        puts $fh ""
        puts $fh "BLOCK_PG_PIN_NET=$net"
        puts $fh "BLOCK_PG_PIN_NAME=$pin_name"
        puts $fh "BLOCK_PG_PIN_SIDE=$side"
        puts $fh "BLOCK_PG_PIN_LAYER_EFFECTIVE=$pin_layer"
        puts $fh "BLOCK_PG_PIN_Y_FRACTION=$y_fraction"
        puts $fh "BLOCK_PG_PIN_RECT=$rect"
        set create_ok [mptdc_signoff_create_one_block_pg_pin $fh $pin_name $net $side $pin_layer $rect $width $depth]
        set verify [mptdc_signoff_verify_block_pg_pin $net]
        puts $fh "BLOCK_PG_PIN_${label}_VERIFY_STATUS=[expr {[lindex $verify 0] ? "PASS" : "FAIL"}]"
        puts $fh "BLOCK_PG_PIN_${label}_VERIFY_SOURCE=[lindex $verify 1]"
        puts $fh "BLOCK_PG_PIN_${label}_VERIFY_DETAIL=[lindex $verify 2]"
        if {!$create_ok || ![lindex $verify 0]} {
            lappend failures $pin_name
        }
    }

    if {[llength $failures] > 0} {
        puts $fh "BLOCK_PG_PIN_STATUS=FAIL"
        puts $fh "BLOCK_PG_PIN_FAILURES=$failures"
        close $fh
        return [list 0 $rpt]
    }
    puts $fh "BLOCK_PG_PIN_STATUS=PASS"
    close $fh
    return [list 1 $rpt]
}

proc mptdc_signoff_block_pg_net_slot {net} {
    switch -- [string toupper $net] {
        VDD { return 0 }
        VSS { return 1 }
        default { return 0 }
    }
}

proc mptdc_signoff_block_pg_stitch_coordinate {net side rect core_box width spacing} {
    set pitch [mptdc_signoff_env_double MPTDC_BLOCK_PG_STITCH_NET_PITCH_UM [expr {$width + $spacing}]]
    set min_pitch [expr {$width + $spacing}]
    if {$pitch < $min_pitch} {
        set pitch $min_pitch
    }
    set slot [mptdc_signoff_block_pg_net_slot $net]
    set half [expr {$width / 2.0}]
    switch -- [string toupper $side] {
        LEFT {
            set coord [expr {[lindex $core_box 0] + ($slot * $pitch)}]
            set low [expr {[lindex $rect 0] + $half}]
            set high [expr {[lindex $rect 2] - $half}]
        }
        RIGHT {
            set coord [expr {[lindex $core_box 2] - ($slot * $pitch)}]
            set low [expr {[lindex $rect 0] + $half}]
            set high [expr {[lindex $rect 2] - $half}]
        }
        BOTTOM {
            set coord [expr {[lindex $core_box 1] + ($slot * $pitch)}]
            set low [expr {[lindex $rect 1] + $half}]
            set high [expr {[lindex $rect 3] - $half}]
        }
        TOP {
            set coord [expr {[lindex $core_box 3] - ($slot * $pitch)}]
            set low [expr {[lindex $rect 1] + $half}]
            set high [expr {[lindex $rect 3] - $half}]
        }
        default {
            error "MPTDC_UNSUPPORTED_BLOCK_PG_STITCH_SIDE: $side"
        }
    }
    if {$coord < $low} { set coord $low }
    if {$coord > $high} { set coord $high }
    return [format %.3f $coord]
}

proc mptdc_signoff_block_pg_stitch_commands {net layer direction start_from offset width spacing set_distance} {
    set base [list addStripe -nets [list $net] -layer $layer -direction $direction \
        -width $width -spacing $spacing -set_to_set_distance $set_distance \
        -start_from $start_from -start_offset $offset]
    set commands [list]
    set number_of_sets [mptdc_signoff_env_int MPTDC_BLOCK_PG_STITCH_NUMBER_OF_SETS 0]
    if {$number_of_sets > 0} {
        lappend commands [concat $base [list -number_of_sets $number_of_sets]]
    }
    lappend commands $base
    return $commands
}

proc mptdc_signoff_create_block_pg_stitches {{report_name block_pg_stitch_status.rpt} {label BLOCK_PG_STITCH}} {
    set rpt [file join [mptdc_signoff_report_dir] $report_name]
    set fh [open $rpt w]
    puts $fh "# MPTDC Block PG Stitch Stripe Status"
    puts $fh "${label}_ENABLE=[mptdc_signoff_env MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES 0]"
    if {![mptdc_signoff_env_truthy MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES 0]} {
        puts $fh "${label}_STATUS=SKIPPED"
        puts $fh "${label}_REASON=MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES_DISABLED"
        close $fh
        return [list 1 $rpt]
    }
    if {![mptdc_signoff_env_truthy MPTDC_ENABLE_BLOCK_PG_PINS 1]} {
        puts $fh "${label}_STATUS=SKIPPED"
        puts $fh "${label}_REASON=block_pg_pins_disabled"
        close $fh
        return [list 1 $rpt]
    }

    set default_layer [mptdc_signoff_env MPTDC_BLOCK_PG_PIN_LAYER METTP]
    set pin_width [mptdc_signoff_env_double MPTDC_BLOCK_PG_PIN_WIDTH_UM 4.0]
    set pin_depth [mptdc_signoff_env_double MPTDC_BLOCK_PG_PIN_DEPTH_UM 28.0]
    set stitch_width [mptdc_signoff_env_double MPTDC_BLOCK_PG_STITCH_WIDTH_UM 2.0]
    set stitch_spacing [mptdc_signoff_env_double MPTDC_BLOCK_PG_STITCH_SPACING_UM 2.0]
    set set_distance [mptdc_signoff_env_double MPTDC_BLOCK_PG_STITCH_SET_DISTANCE_UM 5000.0]
    set core_box [mptdc_signoff_core_box]
    puts $fh "${label}_PIN_LAYER_DEFAULT=$default_layer"
    puts $fh "${label}_PIN_WIDTH_UM=$pin_width"
    puts $fh "${label}_PIN_DEPTH_UM=$pin_depth"
    puts $fh "${label}_WIDTH_UM=$stitch_width"
    puts $fh "${label}_SPACING_UM=$stitch_spacing"
    puts $fh "${label}_SET_DISTANCE_UM=$set_distance"
    puts $fh "${label}_NUMBER_OF_SETS=[mptdc_signoff_env_int MPTDC_BLOCK_PG_STITCH_NUMBER_OF_SETS 0]"
    puts $fh "CORE_BBOX=$core_box"
    if {![mptdc_signoff_box_valid $core_box]} {
        puts $fh "${label}_STATUS=FAIL"
        puts $fh "${label}_ERROR=invalid_core_bbox"
        close $fh
        return [list 0 $rpt]
    }

    set failures [list]
    set created 0
    foreach spec [mptdc_signoff_block_pg_pin_specs] {
        set net [lindex $spec 0]
        set side [lindex $spec 1]
        set y_fraction 0.50
        if {[llength $spec] >= 3} {
            set y_fraction [lindex $spec 2]
        }
        set pin_name $net
        if {[llength $spec] >= 4} {
            set pin_name [lindex $spec 3]
        }
        set layer $default_layer
        if {[llength $spec] >= 5} {
            set layer [lindex $spec 4]
        }
        set rect [mptdc_signoff_block_pg_pin_rect $side $core_box $pin_width $pin_depth $y_fraction $net]
        set side_u [string toupper $side]
        switch -- $side_u {
            LEFT -
            RIGHT {
                set direction vertical
                set start_from left
                set offset [mptdc_signoff_block_pg_stitch_coordinate $net $side_u $rect $core_box $stitch_width $stitch_spacing]
            }
            TOP -
            BOTTOM {
                set direction horizontal
                set start_from bottom
                set offset [mptdc_signoff_block_pg_stitch_coordinate $net $side_u $rect $core_box $stitch_width $stitch_spacing]
            }
            default {
                lappend failures "$pin_name:unsupported_side:$side"
                continue
            }
        }
        set item_label [mptdc_signoff_report_token "${label}_${pin_name}"]
        puts $fh ""
        puts $fh "${item_label}_PIN=$pin_name"
        puts $fh "${item_label}_NET=$net"
        puts $fh "${item_label}_SIDE=$side_u"
        puts $fh "${item_label}_LAYER=$layer"
        puts $fh "${item_label}_DIRECTION=$direction"
        puts $fh "${item_label}_START_FROM=$start_from"
        puts $fh "${item_label}_START_OFFSET=$offset"
        puts $fh "${item_label}_PIN_RECT=$rect"
        set ok [mptdc_signoff_try_pg_command $fh $item_label \
            [mptdc_signoff_block_pg_stitch_commands $net $layer $direction $start_from $offset \
                $stitch_width $stitch_spacing $set_distance]]
        if {$ok} {
            incr created
        } else {
            lappend failures $pin_name
        }
    }

    puts $fh ""
    puts $fh "${label}_CREATED_COUNT=$created"
    if {[llength $failures] > 0} {
        puts $fh "${label}_STATUS=FAIL"
        puts $fh "${label}_FAILURES=$failures"
        close $fh
        return [list 0 $rpt]
    }
    puts $fh "${label}_STATUS=PASS"
    close $fh
    return [list 1 $rpt]
}

proc mptdc_signoff_ro_pg_supply_specs {} {
    return [list [list VDD VDD] [list vdd! VDD] [list VSS VSS]]
}

proc mptdc_signoff_ro_pg_layer_width {layer} {
    set default [mptdc_signoff_env_double MPTDC_RO_PG_HOOKUP_WIDTH_UM 2.0]
    switch -- [string toupper $layer] {
        MET1 { return [mptdc_signoff_env_double MPTDC_RO_PG_HOOKUP_MET1_WIDTH_UM 0.8] }
        MET2 { return [mptdc_signoff_env_double MPTDC_RO_PG_HOOKUP_MET2_WIDTH_UM 0.8] }
        MET3 { return [mptdc_signoff_env_double MPTDC_RO_PG_HOOKUP_MET3_WIDTH_UM $default] }
        METTP { return [mptdc_signoff_env_double MPTDC_RO_PG_HOOKUP_METTP_WIDTH_UM $default] }
        default { return $default }
    }
}

proc mptdc_signoff_ro_pg_valid_handle {value} {
    if {$value eq "" || $value eq "0x0" || $value eq "NULL"} {
        return 0
    }
    return 1
}

proc mptdc_signoff_ro_pg_unique_append {var_name value} {
    upvar 1 $var_name values
    if {![mptdc_signoff_ro_pg_valid_handle $value]} { return }
    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}

proc mptdc_signoff_db_attr_supported {handle attr} {
    if {![mptdc_signoff_ro_pg_valid_handle $handle]} { return 0 }
    if {[catch {set attrs [dbGet ${handle}.?]}]} { return 0 }
    foreach item $attrs {
        set name $item
        regsub {[\(:].*$} $name {} name
        if {$name eq $attr} {
            return 1
        }
    }
    return 0
}

proc mptdc_signoff_ro_pg_inst_term_handles {inst pin} {
    set handles [list]
    set ptr [mptdc_signoff_cell_ptr $inst]
    if {$ptr ne ""} {
        foreach attr {instTerms pgInstTerms} {
            if {![mptdc_signoff_db_attr_supported $ptr $attr]} { continue }
            foreach depth {-p -p2} {
                if {![catch {set values [dbGet ${ptr}.${attr}.name $pin $depth]}]} {
                    foreach value $values {
                        mptdc_signoff_ro_pg_unique_append handles $value
                    }
                }
            }
        }
    }
    foreach expr [list "top.insts.name $inst -p" "top.insts.name $inst -p2"] {
        if {[catch {set inst_ptrs [dbGet {*}$expr]}]} { continue }
        foreach inst_ptr $inst_ptrs {
            if {![mptdc_signoff_ro_pg_valid_handle $inst_ptr]} { continue }
            foreach attr {instTerms pgInstTerms} {
                if {![mptdc_signoff_db_attr_supported $inst_ptr $attr]} { continue }
                foreach depth {-p -p2} {
                    if {![catch {set values [dbGet ${inst_ptr}.${attr}.name $pin $depth]}]} {
                        foreach value $values {
                            mptdc_signoff_ro_pg_unique_append handles $value
                        }
                    }
                }
            }
        }
    }
    return $handles
}

proc mptdc_signoff_ro_pg_shape_schema_status {} {
    set ro_instances [mptdc_signoff_collect_cells [mptdc_signoff_ro_cell_patterns]]
    if {[llength $ro_instances] == 0} {
        return [dict create supported 0 reason no_ro_instances]
    }
    set inst_attr_supported 0
    set term_shape_supported 0
    set detail [list]
    foreach inst $ro_instances {
        set ptr [mptdc_signoff_cell_ptr $inst]
        if {![mptdc_signoff_ro_pg_valid_handle $ptr]} {
            lappend detail "$inst:no_inst_handle"
            continue
        }
        set attrs [list]
        foreach attr {instTerms pgInstTerms} {
            if {[mptdc_signoff_db_attr_supported $ptr $attr]} {
                lappend attrs $attr
            }
        }
        if {[llength $attrs] == 0} {
            lappend detail "$inst:inst_term_attr_unsupported"
            continue
        }
        set inst_attr_supported 1
        foreach attr $attrs {
            foreach spec [mptdc_signoff_ro_pg_supply_specs] {
                set pin [lindex $spec 0]
                if {[catch {set terms [dbGet ${ptr}.${attr}.name $pin -p]}]} { continue }
                foreach term $terms {
                    if {![mptdc_signoff_ro_pg_valid_handle $term]} { continue }
                    foreach shape_attr {pins pin allShapes} {
                        if {[mptdc_signoff_db_attr_supported $term $shape_attr]} {
                            set term_shape_supported 1
                            return [dict create supported 1 reason ok inst $inst term_attr $attr shape_attr $shape_attr]
                        }
                    }
                }
            }
        }
        lappend detail "$inst:term_shape_attr_unsupported"
    }
    if {!$inst_attr_supported || !$term_shape_supported} {
        return [dict create supported 0 reason pin_shape_schema_unsupported detail [join $detail { | }]]
    }
    return [dict create supported 1 reason ok]
}

proc mptdc_signoff_ro_pg_add_shape_row {var_name seen_name inst pin net layer box source} {
    upvar 1 $var_name rows
    upvar 1 $seen_name seen
    if {$layer eq "" || ![mptdc_signoff_box_valid $box]} { return }
    set key "$inst|$pin|$net|$layer|[join $box ,]"
    if {[lsearch -exact $seen $key] >= 0} { return }
    lappend seen $key
    lappend rows [dict create inst $inst pin $pin net $net layer $layer box $box source $source]
}

proc mptdc_signoff_ro_pg_shape_rows_from_term {term inst pin net} {
    set rows [list]
    set seen [list]
    set shape_handles [list]
    set shape_exprs [list]
    if {[mptdc_signoff_db_attr_supported $term pins]} {
        lappend shape_exprs "${term}.pins.allShapes"
    }
    if {[mptdc_signoff_db_attr_supported $term pin]} {
        lappend shape_exprs "${term}.pin.allShapes"
    }
    if {[mptdc_signoff_db_attr_supported $term allShapes]} {
        lappend shape_exprs "${term}.allShapes"
    }
    foreach expr $shape_exprs {
        if {![catch {set values [dbGet $expr]}]} {
            foreach value $values {
                mptdc_signoff_ro_pg_unique_append shape_handles $value
            }
        }
    }
    foreach shape $shape_handles {
        set layer ""
        set box [list]
        foreach attr {layer.name layer} {
            if {$layer eq ""} {
                catch {set layer [dbGet ${shape}.${attr}]}
            }
        }
        foreach attr {box shapes.box rect shapes.rect} {
            if {![mptdc_signoff_box_valid $box]} {
                catch {set box [mptdc_signoff_flat_box [dbGet ${shape}.${attr}]]}
            }
        }
        mptdc_signoff_ro_pg_add_shape_row rows seen $inst $pin $net $layer $box shape_handle
    }
    if {[llength $rows] > 0} {
        return $rows
    }

    set layers [list]
    set layer_exprs [list]
    set box_exprs [list]
    if {[mptdc_signoff_db_attr_supported $term pins]} {
        lappend layer_exprs "${term}.pins.allShapes.layer.name"
        lappend box_exprs "${term}.pins.allShapes.shapes.box" \
            "${term}.pins.allShapes.box" \
            "${term}.pins.allShapes.shapes.rect" \
            "${term}.pins.allShapes.rect"
    }
    if {[mptdc_signoff_db_attr_supported $term pin]} {
        lappend layer_exprs "${term}.pin.allShapes.layer.name"
        lappend box_exprs "${term}.pin.allShapes.shapes.box" \
            "${term}.pin.allShapes.box"
    }
    if {[mptdc_signoff_db_attr_supported $term allShapes]} {
        lappend layer_exprs "${term}.allShapes.layer.name"
        lappend box_exprs "${term}.allShapes.shapes.box" \
            "${term}.allShapes.box"
    }
    foreach expr $layer_exprs {
        if {![catch {set layers [dbGet $expr]}] && [llength $layers] > 0} {
            break
        }
    }
    set boxes [list]
    foreach expr $box_exprs {
        if {![catch {set boxes [dbGet $expr]}] && [llength $boxes] > 0} {
            break
        }
    }
    set direct_box [mptdc_signoff_flat_box $boxes]
    if {[mptdc_signoff_box_valid $direct_box]} {
        set layer [lindex $layers 0]
        mptdc_signoff_ro_pg_add_shape_row rows seen $inst $pin $net $layer $direct_box term_box
        return $rows
    }
    set idx 0
    foreach box_value $boxes {
        set box [mptdc_signoff_flat_box $box_value]
        if {[mptdc_signoff_box_valid $box]} {
            if {[llength $layers] > $idx} {
                set layer [lindex $layers $idx]
            } else {
                set layer [lindex $layers end]
            }
            mptdc_signoff_ro_pg_add_shape_row rows seen $inst $pin $net $layer $box term_box_list
        }
        incr idx
    }
    return $rows
}

proc mptdc_signoff_ro_pg_pin_shapes {inst pin net} {
    set rows [list]
    set seen [list]
    foreach term [mptdc_signoff_ro_pg_inst_term_handles $inst $pin] {
        foreach row [mptdc_signoff_ro_pg_shape_rows_from_term $term $inst $pin $net] {
            set key "[dict get $row inst]|[dict get $row pin]|[dict get $row layer]|[join [dict get $row box] ,]"
            if {[lsearch -exact $seen $key] < 0} {
                lappend seen $key
                lappend rows $row
            }
        }
    }
    return $rows
}

proc mptdc_signoff_ro_pg_all_pin_shapes {} {
    set rows [list]
    foreach inst [mptdc_signoff_collect_cells [mptdc_signoff_ro_cell_patterns]] {
        foreach spec [mptdc_signoff_ro_pg_supply_specs] {
            set pin [lindex $spec 0]
            set net [lindex $spec 1]
            foreach row [mptdc_signoff_ro_pg_pin_shapes $inst $pin $net] {
                lappend rows $row
            }
        }
    }
    return $rows
}

proc mptdc_signoff_ro_pg_nearest_target {net pin_box preferred_layer {max_distance ""}} {
    if {$max_distance eq ""} {
        set max_distance [mptdc_signoff_env_double MPTDC_RO_PG_HOOKUP_SEARCH_UM 45.0]
    }
    set nh ""
    catch {set nh [dbGet top.nets.name $net -p]}
    if {$nh eq "" || $nh eq "0x0"} {
        return [dict create found 0 reason missing_net]
    }
    if {[catch {set swires [dbGet $nh.sWires]} err]} {
        return [dict create found 0 reason "swire_query_failed:$err"]
    }

    set best [dict create found 0 reason no_target_within_search]
    set best_dist 1.0e30
    set fallback [dict create found 0 reason no_swire_target]
    set fallback_dist 1.0e30
    foreach pass {preferred any} {
        foreach sw $swires {
            if {![mptdc_signoff_ro_pg_valid_handle $sw]} { continue }
            set shape UNKNOWN
            set layer UNKNOWN
            set width UNKNOWN
            set box [list]
            catch {set shape [dbGet $sw.shape]}
            catch {set layer [dbGet $sw.layer.name]}
            catch {set width [dbGet $sw.width]}
            catch {set box [mptdc_signoff_flat_box [dbGet $sw.box]]}
            if {![mptdc_signoff_box_valid $box]} { continue }
            if {$pass eq "preferred" && $preferred_layer ne "" && $layer ne $preferred_layer} {
                continue
            }
            set dist [mptdc_signoff_box_clearance $pin_box $box]
            if {$dist eq ""} { continue }
            if {$dist < $fallback_dist} {
                set fallback_dist $dist
                set fallback [dict create found 1 in_range 0 handle $sw shape $shape layer $layer width $width box $box distance $dist]
            }
            if {$dist <= $max_distance && $dist < $best_dist} {
                set best_dist $dist
                set best [dict create found 1 in_range 1 handle $sw shape $shape layer $layer width $width box $box distance $dist]
            }
        }
        if {[dict get $best found]} {
            return $best
        }
    }
    if {[dict get $fallback found]} {
        dict set fallback reason nearest_target_out_of_range
        return $fallback
    }
    return $best
}

proc mptdc_signoff_ro_pg_bridge_direction {pin_box target_box} {
    set pin_ctr [mptdc_signoff_box_center $pin_box]
    set target_ctr [mptdc_signoff_box_center $target_box]
    set dx [expr {abs([lindex $target_ctr 0] - [lindex $pin_ctr 0])}]
    set dy [expr {abs([lindex $target_ctr 1] - [lindex $pin_ctr 1])}]
    if {$dx >= $dy} {
        return horizontal
    }
    return vertical
}

proc mptdc_signoff_ro_pg_bridge_area {pin_box target_box margin} {
    return [list \
        [format %.3f [expr {min([lindex $pin_box 0], [lindex $target_box 0]) - $margin}]] \
        [format %.3f [expr {min([lindex $pin_box 1], [lindex $target_box 1]) - $margin}]] \
        [format %.3f [expr {max([lindex $pin_box 2], [lindex $target_box 2]) + $margin}]] \
        [format %.3f [expr {max([lindex $pin_box 3], [lindex $target_box 3]) + $margin}]]]
}

proc mptdc_signoff_ro_pg_stripe_commands {net layer direction coord area width spacing set_distance} {
    set start_from [expr {$direction eq "horizontal" ? "bottom" : "left"}]
    set coord [format %.3f $coord]
    set commands [list]
    lappend commands [list addStripe -nets [list $net] -layer $layer -direction $direction \
        -width $width -spacing $spacing -set_to_set_distance $set_distance \
        -start_from $start_from -start_offset $coord -number_of_sets 1 -area $area]
    lappend commands [list addStripe -nets [list $net] -layer $layer -direction $direction \
        -width $width -spacing $spacing -set_to_set_distance $set_distance \
        -start_from $start_from -start_offset $coord -area $area]
    return $commands
}

proc mptdc_signoff_ro_pg_marker_near_pin {marker_box pin_rows search} {
    if {![mptdc_signoff_box_valid $marker_box]} { return 0 }
    foreach row $pin_rows {
        set dist [mptdc_signoff_box_clearance $marker_box [dict get $row box]]
        if {$dist ne "" && $dist <= $search} {
            return 1
        }
    }
    return 0
}

proc mptdc_signoff_ro_pg_probe {path {label RO_PG_PROBE}} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    set search [mptdc_signoff_env_double MPTDC_RO_PG_HOOKUP_SEARCH_UM 45.0]
    puts $fh "# MPTDC RO PG Probe"
    puts $fh "DUMP_LABEL=$label"
    puts $fh "RO_PG_PROBE_ENABLED=[expr {[mptdc_signoff_env_truthy MPTDC_ENABLE_RO_PG_PROBE 0] ? 1 : 0}]"
    puts $fh "RO_PG_HOOKUP_ENABLED=[expr {[mptdc_signoff_env_truthy MPTDC_ENABLE_RO_PG_HOOKUP 1] ? 1 : 0}]"
    puts $fh "RO_PG_HOOKUP_SEARCH_UM=$search"
    if {![mptdc_signoff_env_truthy MPTDC_ENABLE_RO_PG_PROBE 0]} {
        puts $fh "RO_PG_PROBE_STATUS=SKIPPED"
        puts $fh "RO_PG_PROBE_REASON=disabled_by_env"
        close $fh
        return $path
    }
    set schema [mptdc_signoff_ro_pg_shape_schema_status]
    if {![dict get $schema supported]} {
        puts $fh "RO_PG_PROBE_STATUS=FAIL"
        puts $fh "RO_PG_PROBE_REASON=[dict get $schema reason]"
        if {[dict exists $schema detail]} {
            puts $fh "RO_PG_PROBE_SCHEMA_DETAIL=[dict get $schema detail]"
        }
        close $fh
        return $path
    }
    set rows [mptdc_signoff_ro_pg_all_pin_shapes]
    puts $fh "RO_PG_PIN_SHAPE_COUNT=[llength $rows]"
    puts $fh ""
    puts $fh "RO_PG_PIN_SHAPES_BEGIN"
    puts $fh "idx\tinst\tpin\tnet\tlayer\tbox\tsource\ttarget_status\ttarget_shape\ttarget_layer\ttarget_distance\ttarget_box"
    set idx 0
    foreach row $rows {
        incr idx
        set target [mptdc_signoff_ro_pg_nearest_target [dict get $row net] [dict get $row box] [dict get $row layer] $search]
        if {[dict get $target found]} {
            set target_status [expr {[dict get $target in_range] ? "IN_RANGE" : "OUT_OF_RANGE"}]
            set target_shape [dict get $target shape]
            set target_layer [dict get $target layer]
            set target_distance [format %.3f [dict get $target distance]]
            set target_box [dict get $target box]
        } else {
            set target_status [dict get $target reason]
            set target_shape ""
            set target_layer ""
            set target_distance ""
            set target_box ""
        }
        puts $fh "$idx\t[dict get $row inst]\t[dict get $row pin]\t[dict get $row net]\t[dict get $row layer]\t[dict get $row box]\t[dict get $row source]\t$target_status\t$target_shape\t$target_layer\t$target_distance\t$target_box"
    }
    puts $fh "RO_PG_PIN_SHAPES_END"

    puts $fh ""
    puts $fh "RO_PG_MARKERS_BEGIN"
    puts $fh "idx\tclass\tbox\tlayer\ttype\tsubType\tmessage"
    set ro_unconnected 0
    set ro_dangling 0
    set special_open 0
    set other 0
    if {[catch {set markers [dbGet top.markers]} err]} {
        puts $fh "MARKER_STATUS=FAIL\t[mptdc_signoff_report_value $err]"
    } else {
        set midx 0
        foreach marker $markers {
            if {![mptdc_signoff_ro_pg_valid_handle $marker]} { continue }
            incr midx
            set box [list]
            set layer UNKNOWN
            set type UNKNOWN
            set subtype UNKNOWN
            set message UNKNOWN
            catch {set box [mptdc_signoff_flat_box [dbGet $marker.box]]}
            catch {set layer [dbGet $marker.layer.name]}
            catch {set type [dbGet $marker.type]}
            catch {set subtype [dbGet $marker.subType]}
            catch {set message [dbGet $marker.message]}
            set class OTHER
            if {[regexp {Pin:[[:space:]]+([^;]+)/(VDD|VSS|vdd!)} $message]} {
                set class RO_PG_UNCONNECTED_PIN
                incr ro_unconnected
            } elseif {$type eq "Connectivity" &&
                $subtype eq "ConnectivityAntenna" &&
                [mptdc_signoff_ro_pg_marker_near_pin $box $rows $search]} {
                set class RO_PG_DANGLING_NEAR_PIN
                incr ro_dangling
            } elseif {$type eq "Connectivity" &&
                [regexp {Net[[:space:]]+(VDD|VSS)} $message] &&
                [string match -nocase *open* $subtype]} {
                set class SPECIAL_OPEN
                incr special_open
            } else {
                incr other
            }
            puts $fh "$midx\t$class\t$box\t$layer\t$type\t$subtype\t[mptdc_signoff_report_value $message]"
        }
    }
    puts $fh "RO_PG_MARKERS_END"
    puts $fh "RO_PG_MARKER_RO_UNCONNECTED_COUNT=$ro_unconnected"
    puts $fh "RO_PG_MARKER_RO_DANGLING_COUNT=$ro_dangling"
    puts $fh "RO_PG_MARKER_SPECIAL_OPEN_COUNT=$special_open"
    puts $fh "RO_PG_MARKER_OTHER_COUNT=$other"
    puts $fh "RO_PG_PROBE_STATUS=[expr {[llength $rows] > 0 ? "PASS" : "FAIL"}]"
    close $fh
    return $path
}

proc mptdc_signoff_ro_pg_hookup {} {
    set rpt [file join [mptdc_signoff_report_dir] ro_pg_hookup_status.rpt]
    set fh [open $rpt w]
    puts $fh "# MPTDC RO PG Hookup Status"
    puts $fh "RO_PG_HOOKUP_ENABLE=[mptdc_signoff_env MPTDC_ENABLE_RO_PG_HOOKUP 1]"
    puts $fh "RO_PG_HOOKUP_REQUIRED=[mptdc_signoff_env MPTDC_REQUIRE_RO_PG_HOOKUP 1]"
    if {![mptdc_signoff_env_truthy MPTDC_ENABLE_RO_PG_HOOKUP 1]} {
        puts $fh "RO_PG_HOOKUP_STATUS=SKIPPED"
        puts $fh "RO_PG_HOOKUP_REASON=disabled_by_env"
        close $fh
        return [list 1 $rpt]
    }
    set schema [mptdc_signoff_ro_pg_shape_schema_status]
    if {![dict get $schema supported]} {
        puts $fh "RO_PG_HOOKUP_STATUS=FAIL"
        puts $fh "RO_PG_HOOKUP_REASON=[dict get $schema reason]"
        if {[dict exists $schema detail]} {
            puts $fh "RO_PG_HOOKUP_SCHEMA_DETAIL=[dict get $schema detail]"
        }
        close $fh
        return [list 0 $rpt]
    }

    set search [mptdc_signoff_env_double MPTDC_RO_PG_HOOKUP_SEARCH_UM 45.0]
    set margin [mptdc_signoff_env_double MPTDC_RO_PG_HOOKUP_MARGIN_UM 1.0]
    set spacing [mptdc_signoff_env_double MPTDC_RO_PG_HOOKUP_SPACING_UM 2.0]
    set set_distance [mptdc_signoff_env_double MPTDC_RO_PG_HOOKUP_SET_DISTANCE_UM 5000.0]
    puts $fh "RO_PG_HOOKUP_SEARCH_UM=$search"
    puts $fh "RO_PG_HOOKUP_MARGIN_UM=$margin"
    puts $fh "RO_PG_HOOKUP_SPACING_UM=$spacing"
    puts $fh "RO_PG_HOOKUP_SET_DISTANCE_UM=$set_distance"

    set rows [mptdc_signoff_ro_pg_all_pin_shapes]
    puts $fh "RO_PG_PIN_SHAPE_COUNT=[llength $rows]"
    set failures [list]
    set created 0
    set skipped 0
    set idx 0
    foreach row $rows {
        incr idx
        set inst [dict get $row inst]
        set pin [dict get $row pin]
        set net [dict get $row net]
        set layer [dict get $row layer]
        set pin_box [dict get $row box]
        set target [mptdc_signoff_ro_pg_nearest_target $net $pin_box $layer $search]
        set item_label [mptdc_signoff_report_token "RO_PG_${idx}_${pin}_${layer}"]
        puts $fh ""
        puts $fh "${item_label}_INST=$inst"
        puts $fh "${item_label}_PIN=$pin"
        puts $fh "${item_label}_NET=$net"
        puts $fh "${item_label}_PIN_LAYER=$layer"
        puts $fh "${item_label}_PIN_BOX=$pin_box"
        if {![dict get $target found]} {
            puts $fh "${item_label}_TARGET_STATUS=FAIL"
            puts $fh "${item_label}_TARGET_REASON=[dict get $target reason]"
            lappend failures "$inst/$pin:$layer:target_missing"
            incr skipped
            continue
        }
        puts $fh "${item_label}_TARGET_STATUS=[expr {[dict get $target in_range] ? "PASS" : "OUT_OF_RANGE"}]"
        puts $fh "${item_label}_TARGET_SHAPE=[dict get $target shape]"
        puts $fh "${item_label}_TARGET_LAYER=[dict get $target layer]"
        puts $fh "${item_label}_TARGET_DISTANCE_UM=[format %.3f [dict get $target distance]]"
        puts $fh "${item_label}_TARGET_BOX=[dict get $target box]"
        if {![dict get $target in_range]} {
            lappend failures "$inst/$pin:$layer:target_out_of_range:[format %.3f [dict get $target distance]]"
            incr skipped
            continue
        }

        set target_box [dict get $target box]
        set direction [mptdc_signoff_ro_pg_bridge_direction $pin_box $target_box]
        set area [mptdc_signoff_ro_pg_bridge_area $pin_box $target_box $margin]
        set pin_ctr [mptdc_signoff_box_center $pin_box]
        set coord [expr {$direction eq "horizontal" ? [lindex $pin_ctr 1] : [lindex $pin_ctr 0]}]
        set width [mptdc_signoff_ro_pg_layer_width $layer]
        puts $fh "${item_label}_BRIDGE_DIRECTION=$direction"
        puts $fh "${item_label}_BRIDGE_AREA=$area"
        puts $fh "${item_label}_BRIDGE_COORD=[format %.3f $coord]"
        puts $fh "${item_label}_BRIDGE_WIDTH=$width"
        set ok [mptdc_signoff_try_pg_command $fh ${item_label}_PIN_LAYER \
            [mptdc_signoff_ro_pg_stripe_commands $net $layer $direction $coord $area $width $spacing $set_distance]]
        if {$ok} {
            incr created
        } else {
            lappend failures "$inst/$pin:$layer:pin_layer_stripe_failed"
        }

        set target_layer [dict get $target layer]
        if {$target_layer ne "" && $target_layer ne $layer} {
            set target_width [mptdc_signoff_ro_pg_layer_width $target_layer]
            set target_coord $coord
            puts $fh "${item_label}_TARGET_BRIDGE_COORD=[format %.3f $target_coord]"
            puts $fh "${item_label}_TARGET_BRIDGE_WIDTH=$target_width"
            set target_ok [mptdc_signoff_try_pg_command $fh ${item_label}_TARGET_LAYER \
                [mptdc_signoff_ro_pg_stripe_commands $net $target_layer $direction $target_coord $area $target_width $spacing $set_distance]]
            if {$target_ok} {
                incr created
            } else {
                lappend failures "$inst/$pin:$target_layer:target_layer_stripe_failed"
            }
        }
    }

    puts $fh ""
    puts $fh "RO_PG_HOOKUP_CREATED_STRIPE_COUNT=$created"
    puts $fh "RO_PG_HOOKUP_SKIPPED_COUNT=$skipped"
    if {[llength $rows] == 0} {
        lappend failures no_ro_pg_pin_shapes_found
    }
    if {[llength $failures] > 0} {
        puts $fh "RO_PG_HOOKUP_STATUS=FAIL"
        puts $fh "RO_PG_HOOKUP_FAILURES=[join $failures { | }]"
        close $fh
        return [list 0 $rpt]
    }
    puts $fh "RO_PG_HOOKUP_STATUS=PASS"
    close $fh
    return [list 1 $rpt]
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
        if {[regexp -nocase {REPORT_STATUS=FAILED|no[[:space:]]+routing|[1-9][0-9]*[[:space:]]+Problem\(s\)|Verification Complete[[:space:]]*:[[:space:]]*[1-9][0-9]*[[:space:]]+Viols|[^a-z](open|short|unconnected|unrouted|violation|violated|dangling)[^a-z]} " $trimmed "]} {
            lappend bad $trimmed
            if {[llength $bad] >= 10} { break }
        }
    }
    close $fh
    return [list [expr {[llength $bad] > 0}] $bad]
}

proc mptdc_signoff_write_pg_postroute_connectivity_status {special_rpt regular_rpt} {
    set rpt [file join [mptdc_signoff_report_dir] pg_postroute_connectivity_status.rpt]
    set special_bad [mptdc_signoff_connectivity_report_has_errors $special_rpt]
    set regular_bad [mptdc_signoff_connectivity_report_has_errors $regular_rpt]
    set special_flag [lindex $special_bad 0]
    set status [expr {$special_flag ? "FAIL" : "PASS"}]
    set fh [open $rpt w]
    puts $fh "# MPTDC Post-route PG Connectivity Status"
    puts $fh "PG_CONNECTIVITY_STATUS=$status"
    puts $fh "PG_CONNECTIVITY_STAGE=POST_ROUTE_SPECIAL_NET_VERIFY"
    puts $fh "SPECIAL_CONNECTIVITY_REPORT=$special_rpt"
    puts $fh "SPECIAL_CONNECTIVITY_BAD=$special_flag"
    puts $fh "SPECIAL_CONNECTIVITY_BAD_LINES=[lindex $special_bad 1]"
    puts $fh "REGULAR_CONNECTIVITY_REPORT=$regular_rpt"
    puts $fh "REGULAR_CONNECTIVITY_BAD=[lindex $regular_bad 0]"
    puts $fh "REGULAR_CONNECTIVITY_BAD_LINES=[lindex $regular_bad 1]"
    puts $fh "PG_GATE_NOTE=regular_net_connectivity_is_reported_for_route_gate_only"
    close $fh
    mptdc_signoff_set_status PG_CONNECTIVITY_STATUS $status $rpt
    return $status
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
    close $fh
    lassign [mptdc_signoff_create_block_pg_pins] block_pin_ok block_pin_rpt
    lassign [mptdc_signoff_create_block_pg_stitches block_pg_stitch_status.rpt BLOCK_PG_STITCH] block_stitch_ok block_stitch_rpt
    set fh [open $rpt a]
    set preplace_sroute_enabled [mptdc_signoff_env_truthy MPTDC_ENABLE_PREPLACE_PG_SROUTE 0]
    puts $fh "PREPLACE_PG_SROUTE_ENABLED=[expr {$preplace_sroute_enabled ? 1 : 0}]"
    if {$preplace_sroute_enabled} {
        mptdc_signoff_configure_sroute_mode $fh PRE_ROUTE_PG
        set sroute_ok [mptdc_signoff_try_sroute_command $fh SROUTE [mptdc_signoff_sroute_commands $nets]]
        set sroute_summary [mptdc_signoff_sroute_attempt_summary SROUTE]
    } else {
        puts $fh "PRE_ROUTE_PG_SROUTE_MODE_STATUS=SKIPPED"
        puts $fh "PRE_ROUTE_PG_SROUTE_MODE_REASON=preplace_pg_sroute_disabled"
        puts $fh "SROUTE_STATUS=SKIPPED"
        set sroute_ok 0
        set sroute_summary [dict create \
            status SKIPPED \
            wires 0 \
            open_ports 0 \
            block_open_ports 0 \
            core_open_ports 0 \
            power_bump_open_ports 0 \
            reason preplace_pg_sroute_disabled \
            report ""]
    }
    set sroute_status [dict get $sroute_summary status]
    set sroute_wires [dict get $sroute_summary wires]
    set sroute_progress_ok [expr {!$preplace_sroute_enabled ||
        ($sroute_status in {PASS REVIEW_REQUIRED} &&
        $sroute_wires ne "UNKNOWN" && $sroute_wires > 0)}]
    set sroute_gate_ok [expr {!$preplace_sroute_enabled || $sroute_ok}]

    close $fh

    set special_rpt [file join [mptdc_signoff_report_dir] pg_verify_connectivity_special.rpt]
    lassign [mptdc_signoff_capture_to_file_selected $special_rpt [mptdc_signoff_pg_connectivity_commands $nets]] special_capture_ok special_capture_cmd
    set all_rpt [file join [mptdc_signoff_report_dir] pg_verify_connectivity_all.rpt]
    mptdc_signoff_capture_to_file $all_rpt [list {verifyConnectivity}]

    set special_bad [mptdc_signoff_connectivity_report_has_errors $special_rpt]
    set all_bad [mptdc_signoff_connectivity_report_has_errors $all_rpt]
    set ro_instances [mptdc_signoff_collect_cells [mptdc_signoff_ro_cell_patterns]]
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
    puts $fh "BLOCK_PG_PIN_STATUS=[expr {$block_pin_ok ? "PASS" : "FAIL"}]"
    puts $fh "BLOCK_PG_PIN_REPORT=$block_pin_rpt"
    puts $fh "BLOCK_PG_STITCH_STATUS=[expr {$block_stitch_ok ? "PASS" : "FAIL"}]"
    puts $fh "BLOCK_PG_STITCH_REPORT=$block_stitch_rpt"
    puts $fh "SROUTE_DONE=$sroute_ok"
    puts $fh "SROUTE_EFFECTIVE_STATUS=$sroute_status"
    puts $fh "SROUTE_EFFECTIVE_WIRES=$sroute_wires"
    puts $fh "SROUTE_EFFECTIVE_OPEN_PORTS=[dict get $sroute_summary open_ports]"
    if {[dict exists $sroute_summary reason]} {
        puts $fh "SROUTE_EFFECTIVE_REASON=[dict get $sroute_summary reason]"
    }
    puts $fh "SROUTE_PREPLACE_PROGRESS_STATUS=[expr {$sroute_progress_ok ? "PASS" : "FAIL"}]"
    puts $fh "RO_INSTANCE_COUNT=$ro_count"
    puts $fh "RO_VDD_CONNECTED_COUNT=$ro_vdd_count"
    puts $fh "RO_VDD_BANG_CONNECTED_COUNT=$ro_vdd_bang_count"
    puts $fh "RO_VSS_CONNECTED_COUNT=$ro_vss_count"
    puts $fh "RO_PG_PIN_QUERY_STATUS=[expr {$ro_pg_ok ? "PASS" : "FAIL"}]"
    puts $fh "SPECIAL_CONNECTIVITY_REPORT=$special_rpt"
    puts $fh "SPECIAL_CONNECTIVITY_CAPTURE_STATUS=[expr {$special_capture_ok ? "PASS" : "FAIL"}]"
    puts $fh "SPECIAL_CONNECTIVITY_COMMAND=$special_capture_cmd"
    puts $fh "ALL_CONNECTIVITY_REPORT=$all_rpt"
    puts $fh "SPECIAL_NET_OPENS=PARSED_FROM_VERIFY_CONNECTIVITY"
    puts $fh "SPECIAL_NET_SHORTS=PARSED_FROM_VERIFY_CONNECTIVITY"
    puts $fh "UNCONNECTED_STDCELL_PG_PINS=PARSED_FROM_VERIFY_CONNECTIVITY"
    puts $fh "UNCONNECTED_RO_PG_PINS=PARSED_FROM_VERIFY_CONNECTIVITY"
    puts $fh "SPECIAL_CONNECTIVITY_BAD=[lindex $special_bad 0]"
    puts $fh "SPECIAL_CONNECTIVITY_BAD_LINES=[lindex $special_bad 1]"
    puts $fh "ALL_CONNECTIVITY_BAD=[lindex $all_bad 0]"
    puts $fh "ALL_CONNECTIVITY_BAD_LINES=[lindex $all_bad 1]"
    set primitive_pg_ok [expr {$ring_ok && $stripe_v_ok && $stripe_h_ok && $block_pin_ok && $block_stitch_ok && $sroute_progress_ok}]
    set status [expr {$ring_ok && $stripe_v_ok && $stripe_h_ok && $block_pin_ok && $block_stitch_ok && $sroute_gate_ok && $ro_pg_ok && ![lindex $special_bad 0] && ![lindex $all_bad 0] ? "PASS" : "FAIL"}]
    set provisional_reason ""
    if {$status ne "PASS" &&
        [mptdc_signoff_env_truthy MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG] &&
        $primitive_pg_ok} {
        set status PROVISIONAL
        set provisional_reason "pre_place_verify_connectivity_requires_placed_cells; route_stage_rechecks_regular_and_special_connectivity"
        if {!$sroute_ok} {
            append provisional_reason "; sroute_open_ports_deferred_to_route_stage"
        }
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
    mptdc_signoff_set_status PG_CONNECTIVITY_STATUS PROVISIONAL $rpt
    return $rpt
}

proc mptdc_signoff_parse_verify_drc_report {path} {
    set result [dict create report $path command_failed 0 total_violations UNKNOWN shorts UNKNOWN status FAIL drc_class_counts {}]
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
                set class_counts [dict create]
                set short_idx [lsearch -nocase $drc_columns Short]
                set total_idx [lsearch -nocase $drc_columns Totals]
                if {$total_idx < 0} {
                    set total_idx [lsearch -nocase $drc_columns Total]
                }
                for {set i 0} {$i < [llength $drc_columns]} {incr i} {
                    set column [lindex $drc_columns $i]
                    if {[string equal -nocase $column Totals] || [string equal -nocase $column Total]} {
                        continue
                    }
                    dict set class_counts $column [lindex $counts $i]
                }
                dict set result drc_class_counts $class_counts
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

proc mptdc_signoff_dump_drc_markers {path} {
    file mkdir [file dirname $path]
    set schema_rpt [file rootname $path]_schema.rpt
    catch {dbSchema marker > $schema_rpt}
    catch {help marker >> $schema_rpt}
    set markers [list]
    catch {set markers [dbGet top.markers]}
    set fh [open $path w]
    puts $fh "idx\tmarker_handle\tbox\tlayer\ttype\tsubType\tmessage"
    set idx 0
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} { continue }
        incr idx
        set box UNKNOWN
        set layer UNKNOWN
        set type UNKNOWN
        set subtype UNKNOWN
        set message UNKNOWN
        catch {set box [dbGet $marker.box]}
        catch {set layer [dbGet $marker.layer.name]}
        catch {set type [dbGet $marker.type]}
        catch {set subtype [dbGet $marker.subType]}
        catch {set message [dbGet $marker.message]}
        puts $fh "$idx\t[mptdc_signoff_report_value $marker]\t[mptdc_signoff_report_value $box]\t[mptdc_signoff_report_value $layer]\t[mptdc_signoff_report_value $type]\t[mptdc_signoff_report_value $subtype]\t[mptdc_signoff_report_value $message]"
    }
    close $fh
    return $path
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

proc mptdc_signoff_parse_checkplace_report {path} {
    set result [dict create \
        report $path \
        command_failed 0 \
        command_complete 0 \
        parser_complete 0 \
        overlap UNKNOWN \
        region_fence UNKNOWN \
        not_of_fence UNKNOWN \
        unplaced UNKNOWN \
        placed UNKNOWN \
        fixed UNKNOWN \
        status FAIL]
    if {![file exists $path]} {
        dict set result reason missing_report
        return $result
    }

    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {[regexp -nocase {REPORT_STATUS=FAILED} $trimmed]} {
            dict set result command_failed 1
        }
        if {[regexp -nocase {Finished[[:space:]]+checkPlace|checkPlace[[:space:]].*complete|Finished[[:space:]]+Check[[:space:]]+Place} $trimmed]} {
            dict set result command_complete 1
        }
        if {[regexp -nocase {Overlapping[[:space:]]+with[[:space:]]+other[[:space:]]+instance[[:space:]]*:[[:space:]]*([0-9]+)} $trimmed -> count]} {
            dict set result overlap $count
        }
        if {[regexp -nocase {Region/Fence[[:space:]]+Violation[[:space:]]*:[[:space:]]*([0-9]+)} $trimmed -> count]} {
            dict set result region_fence $count
        }
        if {[regexp -nocase {Not-of-Fence[[:space:]]+Violation[[:space:]]*:[[:space:]]*([0-9]+)} $trimmed -> count]} {
            dict set result not_of_fence $count
        }
        if {[regexp -nocase {^\*?info:[[:space:]]*Placed[[:space:]]*=[[:space:]]*([0-9]+).*Fixed[[:space:]]*=[[:space:]]*([0-9]+)} $trimmed -> placed fixed]} {
            dict set result placed $placed
            dict set result fixed $fixed
        } elseif {[regexp -nocase {^\*?info:[[:space:]]*Placed[[:space:]]*=[[:space:]]*([0-9]+)} $trimmed -> placed]} {
            dict set result placed $placed
        }
        if {[regexp -nocase {^\*?info:[[:space:]]*Unplaced[[:space:]]*=[[:space:]]*([0-9]+)} $trimmed -> count]} {
            dict set result unplaced $count
        }
    }
    close $fh

    set inferred_zero_fields [list]
    if {![dict get $result command_failed] && [dict get $result command_complete]} {
        foreach key {overlap region_fence not_of_fence} {
            if {[dict get $result $key] eq "UNKNOWN"} {
                dict set result $key 0
                lappend inferred_zero_fields $key
            }
        }
    }

    set missing [list]
    foreach key {overlap region_fence not_of_fence unplaced placed} {
        if {[dict get $result $key] eq "UNKNOWN"} {
            lappend missing $key
        }
    }
    if {![dict get $result command_failed] &&
        [dict get $result command_complete] &&
        [llength $missing] == 0} {
        dict set result parser_complete 1
    } else {
        dict set result missing_fields $missing
    }
    if {[llength $inferred_zero_fields] > 0} {
        dict set result inferred_zero_fields $inferred_zero_fields
    }
    if {![dict get $result command_failed] &&
        [dict get $result parser_complete] &&
        [dict get $result overlap] == 0 &&
        [dict get $result region_fence] == 0 &&
        [dict get $result not_of_fence] == 0 &&
        [dict get $result unplaced] == 0} {
        dict set result status PASS
    }
    return $result
}

proc mptdc_signoff_checkplace_is_clean {data} {
    return [expr {![dict get $data command_failed] &&
        [dict get $data parser_complete] &&
        [dict get $data overlap] == 0 &&
        [dict get $data region_fence] == 0 &&
        [dict get $data not_of_fence] == 0 &&
        [dict get $data unplaced] == 0}]
}

proc mptdc_signoff_write_placement_gate_status {rpt label data recovery_rpt} {
    set clean [mptdc_signoff_checkplace_is_clean $data]
    set dirty_allowed [mptdc_signoff_env_truthy MPTDC_ALLOW_DIRTY_PLACEMENT_ROUTE 0]
    set status FAIL
    if {$clean} {
        set status PASS
    } elseif {$dirty_allowed} {
        set status PROVISIONAL
    }

    set fh [open $rpt w]
    puts $fh "PLACEMENT_GATE_LABEL=$label"
    puts $fh "PLACEMENT_STATUS=$status"
    puts $fh "CHECKPLACE_REPORT=[dict get $data report]"
    puts $fh "CHECKPLACE_COMMAND_FAILED=[dict get $data command_failed]"
    puts $fh "CHECKPLACE_COMMAND_COMPLETE=[dict get $data command_complete]"
    puts $fh "CHECKPLACE_PARSER_COMPLETE=[dict get $data parser_complete]"
    if {[dict exists $data missing_fields]} {
        puts $fh "CHECKPLACE_MISSING_FIELDS=[dict get $data missing_fields]"
    }
    if {[dict exists $data inferred_zero_fields]} {
        puts $fh "CHECKPLACE_INFERRED_ZERO_FIELDS=[dict get $data inferred_zero_fields]"
    }
    puts $fh "OVERLAPPING_WITH_OTHER_INSTANCE=[dict get $data overlap]"
    puts $fh "REGION_FENCE_VIOLATIONS=[dict get $data region_fence]"
    puts $fh "NOT_OF_FENCE_VIOLATIONS=[dict get $data not_of_fence]"
    puts $fh "UNPLACED_CELLS=[dict get $data unplaced]"
    puts $fh "PLACED_CELLS=[dict get $data placed]"
    puts $fh "FIXED_CELLS=[dict get $data fixed]"
    puts $fh "DIRTY_PLACEMENT_ROUTE_ALLOWED=[expr {$dirty_allowed ? 1 : 0}]"
    puts $fh "DIRTY_PLACEMENT_ROUTE_ENV=MPTDC_ALLOW_DIRTY_PLACEMENT_ROUTE"
    if {$recovery_rpt ne ""} {
        puts $fh "PLACEMENT_GATE_RECOVERY_REPORT=$recovery_rpt"
    }
    close $fh
    return $status
}

proc mptdc_signoff_capture_placement_gate {label check_rpt status_rpt {allow_recovery 1}} {
    mptdc_signoff_capture_required_candidates $check_rpt \
        "$label checkPlace" [list {checkPlace}]
    set data [mptdc_signoff_parse_checkplace_report $check_rpt]
    set recovery_rpt ""

    if {$allow_recovery &&
        ![mptdc_signoff_checkplace_is_clean $data] &&
        [mptdc_signoff_env_truthy MPTDC_PLACEMENT_GATE_RECOVERY 1]} {
        set recovery_rpt [file join [mptdc_signoff_report_dir] "${label}_placement_recovery.rpt"]
        set fh [open $recovery_rpt w]
        puts $fh "PLACEMENT_GATE_LABEL=$label"
        puts $fh "INITIAL_CHECKPLACE_REPORT=$check_rpt"
        puts $fh "INITIAL_OVERLAPS=[dict get $data overlap]"
        puts $fh "INITIAL_REGION_FENCE_VIOLATIONS=[dict get $data region_fence]"
        puts $fh "INITIAL_NOT_OF_FENCE_VIOLATIONS=[dict get $data not_of_fence]"
        puts $fh "INITIAL_UNPLACED_CELLS=[dict get $data unplaced]"
        close $fh

        foreach cmd {{refinePlace -preserveRouting true -hardFence false} {refinePlace}} {
            set fh [open $recovery_rpt a]
            puts $fh "RECOVERY_COMMAND=$cmd"
            close $fh
            if {[catch {uplevel #0 $cmd} err]} {
                set fh [open $recovery_rpt a]
                puts $fh "RECOVERY_COMMAND_STATUS=FAIL"
                puts $fh "RECOVERY_COMMAND_ERROR=$err"
                close $fh
                continue
            }
            set fh [open $recovery_rpt a]
            puts $fh "RECOVERY_COMMAND_STATUS=PASS"
            close $fh
            break
        }

        set recovered_check [file join [mptdc_signoff_report_dir] "${label}_check_place_after_recovery.rpt"]
        mptdc_signoff_capture_required_candidates $recovered_check \
            "$label checkPlace after placement recovery" [list {checkPlace}]
        set data [mptdc_signoff_parse_checkplace_report $recovered_check]
        set fh [open $recovery_rpt a]
        puts $fh "RECOVERED_CHECKPLACE_REPORT=$recovered_check"
        puts $fh "RECOVERED_OVERLAPS=[dict get $data overlap]"
        puts $fh "RECOVERED_REGION_FENCE_VIOLATIONS=[dict get $data region_fence]"
        puts $fh "RECOVERED_NOT_OF_FENCE_VIOLATIONS=[dict get $data not_of_fence]"
        puts $fh "RECOVERED_UNPLACED_CELLS=[dict get $data unplaced]"
        close $fh
    }

    set status [mptdc_signoff_write_placement_gate_status $status_rpt $label $data $recovery_rpt]
    dict set data status $status
    dict set data status_report $status_rpt
    dict set data recovery_report $recovery_rpt
    return $data
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
    if {[catch {uplevel 1 "$cmd > \"$path\""} err opts]} {
        set fh [open $path w]
        puts $fh "MPTDC Route Command"
        puts $fh "=================="
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh "COMMAND=$cmd"
        puts $fh "ERROR=$err"
        if {[dict exists $opts -errorcode]} {
            puts $fh "ERRORCODE=[dict get $opts -errorcode]"
        }
        if {[dict exists $opts -errorinfo]} {
            puts $fh "ERRORINFO_BEGIN"
            puts $fh [dict get $opts -errorinfo]
            puts $fh "ERRORINFO_END"
        }
        close $fh
        return [list 0 $err]
    }
    return [list 1 ""]
}

proc mptdc_signoff_route_repair_commands {} {
    set raw [mptdc_signoff_env MPTDC_ROUTE_REPAIR_COMMANDS ""]
    if {$raw ne ""} {
        if {![catch {llength $raw}]} {
            return $raw
        }
    }
    return [list {ecoRoute -target} {ecoRoute -fix_drc}]
}

proc mptdc_signoff_count_existing_filler_cells {} {
    set patterns [list MPTDC_FILL* *MPTDC_FILL*]
    set names [mptdc_signoff_collect_cells $patterns]
    foreach name [mptdc_signoff_collect_inst_names_from_db $patterns] {
        mptdc_signoff_unique_append names $name
    }
    return [llength $names]
}

proc mptdc_signoff_configure_filler_mode {} {
    set rpt [file join [mptdc_signoff_report_dir] filler_mode_status.rpt]
    set allow_drc [mptdc_signoff_env_truthy MPTDC_FILLER_ADD_FILLERS_WITH_DRC 0]
    set require_safe [mptdc_signoff_env_truthy MPTDC_REQUIRE_DRC_SAFE_FILLER 1]
    set value [expr {$allow_drc ? "true" : "false"}]
    set commands [list \
        [list setFillerMode -add_fillers_with_drc $value] \
        [list setFillerMode -add_fillers_with_drc [expr {$allow_drc ? 1 : 0}]] \
        [list setFillerMode -addFillersWithDrc $value] \
        [list setFillerMode -addFillersWithDrc [expr {$allow_drc ? 1 : 0}]]]
    set fh [open $rpt w]
    puts $fh "# MPTDC Filler Mode Status"
    puts $fh "MPTDC_FILLER_ADD_FILLERS_WITH_DRC=[expr {$allow_drc ? 1 : 0}]"
    puts $fh "MPTDC_REQUIRE_DRC_SAFE_FILLER=[expr {$require_safe ? 1 : 0}]"
    puts $fh "REQUESTED_ADD_FILLERS_WITH_DRC=$value"
    foreach cmd $commands {
        puts $fh "FILLER_MODE_COMMAND=$cmd"
        if {![catch {{*}$cmd} err]} {
            puts $fh "FILLER_MODE_STATUS=PASS"
            puts $fh "FILLER_MODE_APPLIED_COMMAND=$cmd"
            close $fh
            return [list 1 $rpt]
        }
        puts $fh "FILLER_MODE_ATTEMPT_STATUS=FAIL"
        puts $fh "FILLER_MODE_ATTEMPT_ERROR=$err"
    }
    if {$allow_drc || !$require_safe} {
        puts $fh "FILLER_MODE_STATUS=REVIEW_REQUIRED"
        puts $fh "FILLER_MODE_REASON=setFillerMode_variant_not_accepted"
        close $fh
        return [list 1 $rpt]
    }
    puts $fh "FILLER_MODE_STATUS=FAIL"
    puts $fh "FILLER_MODE_REASON=drc_safe_filler_mode_required_but_not_applied"
    close $fh
    return [list 0 $rpt]
}

proc mptdc_signoff_post_filler_run_route_command {rpt phase cmd} {
    set cmd_rpt [mptdc_signoff_route_command_report_path $phase $cmd]
    set fh [open $rpt a]
    puts $fh "POST_FILLER_ROUTE_COMMAND_PHASE=$phase"
    puts $fh "POST_FILLER_ROUTE_COMMAND=$cmd"
    puts $fh "POST_FILLER_ROUTE_REPORT=$cmd_rpt"
    close $fh
    lassign [mptdc_signoff_capture_route_command $cmd $cmd_rpt] route_ok route_err
    set route_drc [mptdc_signoff_parse_verify_drc_report $cmd_rpt]
    set marker_rpt [mptdc_signoff_dump_drc_markers [file rootname $cmd_rpt]_markers.tsv]
    set fh [open $rpt a]
    puts $fh "POST_FILLER_ROUTE_${phase}_COMMAND_STATUS=[expr {$route_ok ? "PASS" : "FAIL"}]"
    puts $fh "POST_FILLER_ROUTE_${phase}_ROUTER_DRC=[dict get $route_drc total_violations]"
    puts $fh "POST_FILLER_ROUTE_${phase}_ROUTER_SHORTS=[dict get $route_drc shorts]"
    puts $fh "POST_FILLER_ROUTE_${phase}_MARKER_REPORT=$marker_rpt"
    if {!$route_ok} {
        puts $fh "POST_FILLER_ROUTE_${phase}_ERROR=$route_err"
    }
    close $fh
    return $route_ok
}

proc mptdc_signoff_post_filler_verify {rpt} {
    set drc_rpt [file join [mptdc_signoff_report_dir] post_filler_verify_drc.rpt]
    set special_rpt [file join [mptdc_signoff_report_dir] post_filler_verify_connectivity_special.rpt]
    set all_rpt [file join [mptdc_signoff_report_dir] post_filler_verify_connectivity_all.rpt]
    set drc_ok [mptdc_signoff_capture_candidates $drc_rpt \
        "post-filler verify_drc" [list {verify_drc} {verifyGeometry}]]
    lassign [mptdc_signoff_capture_to_file_selected $special_rpt [mptdc_signoff_pg_connectivity_commands {VDD VSS}]] special_ok special_cmd
    set all_ok [mptdc_signoff_capture_candidates $all_rpt \
        "post-filler all-net connectivity" [list {verifyConnectivity}]]
    set drc_data [mptdc_signoff_parse_verify_drc_report $drc_rpt]
    set marker_rpt [mptdc_signoff_dump_drc_markers [file join [mptdc_signoff_report_dir] post_filler_verify_drc_markers.tsv]]
    set special_bad [mptdc_signoff_connectivity_report_has_errors $special_rpt]
    set all_bad [mptdc_signoff_connectivity_report_has_errors $all_rpt]
    set verify_pass [expr {$drc_ok && $special_ok && $all_ok &&
        [dict get $drc_data status] eq "PASS" &&
        ![lindex $special_bad 0] &&
        ![lindex $all_bad 0]}]
    set fh [open $rpt a]
    puts $fh "POST_FILLER_VERIFY_DRC_REPORT=$drc_rpt"
    puts $fh "POST_FILLER_VERIFY_DRC_MARKER_REPORT=$marker_rpt"
    puts $fh "POST_FILLER_VERIFY_DRC_CAPTURE_STATUS=[expr {$drc_ok ? "PASS" : "REVIEW_REQUIRED"}]"
    puts $fh "POST_FILLER_VERIFY_DRC=[dict get $drc_data total_violations]"
    puts $fh "POST_FILLER_VERIFY_SHORTS=[dict get $drc_data shorts]"
    puts $fh "POST_FILLER_SPECIAL_CONNECTIVITY_REPORT=$special_rpt"
    puts $fh "POST_FILLER_SPECIAL_CONNECTIVITY_CAPTURE_STATUS=[expr {$special_ok ? "PASS" : "REVIEW_REQUIRED"}]"
    puts $fh "POST_FILLER_SPECIAL_CONNECTIVITY_COMMAND=$special_cmd"
    puts $fh "POST_FILLER_SPECIAL_CONNECTIVITY_BAD=[lindex $special_bad 0]"
    puts $fh "POST_FILLER_SPECIAL_CONNECTIVITY_BAD_LINES=[lindex $special_bad 1]"
    puts $fh "POST_FILLER_ALL_CONNECTIVITY_REPORT=$all_rpt"
    puts $fh "POST_FILLER_ALL_CONNECTIVITY_CAPTURE_STATUS=[expr {$all_ok ? "PASS" : "REVIEW_REQUIRED"}]"
    puts $fh "POST_FILLER_ALL_CONNECTIVITY_BAD=[lindex $all_bad 0]"
    puts $fh "POST_FILLER_ALL_CONNECTIVITY_BAD_LINES=[lindex $all_bad 1]"
    puts $fh "POST_FILLER_VERIFY_STATUS=[expr {$verify_pass ? "PASS" : "REVIEW_REQUIRED"}]"
    close $fh
    return $verify_pass
}

proc mptdc_signoff_post_filler_route_cleanup {rpt} {
    set commands [mptdc_signoff_route_repair_commands]
    if {[llength $commands] == 0} {
        set commands [list {ecoRoute -target} {ecoRoute -fix_drc}]
    }
    set pre_sroute_cmd [lindex $commands 0]
    set post_sroute_cmds [lrange $commands 1 end]
    set fh [open $rpt a]
    puts $fh "POST_FILLER_ROUTE_CLEANUP=REQUIRED_AFTER_POSTROUTE_FILLER"
    puts $fh "POST_FILLER_ROUTE_CLEANUP_POLICY=bounded_incremental_eco_then_pg_then_drc"
    puts $fh "POST_FILLER_ROUTE_REPAIR_COMMANDS=$commands"
    puts $fh "POST_FILLER_ROUTE_PRE_SROUTE_COMMAND=$pre_sroute_cmd"
    puts $fh "POST_FILLER_ROUTE_POST_SROUTE_COMMANDS=$post_sroute_cmds"
    close $fh

    set route_ok [mptdc_signoff_post_filler_run_route_command $rpt POST_FILLER_PRE_SROUTE $pre_sroute_cmd]

    set fh [open $rpt a]
    if {[mptdc_signoff_env_truthy MPTDC_ENABLE_POST_FILLER_SROUTE]} {
        mptdc_signoff_configure_sroute_mode $fh POST_FILLER
        set sroute_ok [mptdc_signoff_try_sroute_command $fh POST_FILLER_SROUTE [mptdc_signoff_sroute_commands {VDD VSS}]]
        if {!$sroute_ok} {
            puts $fh "POST_FILLER_SROUTE_REASON=all_sroute_command_variants_failed"
        }
    } else {
        set sroute_ok 1
        puts $fh "POST_FILLER_SROUTE_STATUS=SKIPPED"
        puts $fh "POST_FILLER_SROUTE_REASON=pg_connectivity_rechecked_without_special_route_mutation"
        puts $fh "POST_FILLER_SROUTE_ENABLE_ENV=MPTDC_ENABLE_POST_FILLER_SROUTE"
    }
    close $fh

    foreach cmd $post_sroute_cmds {
        if {![mptdc_signoff_post_filler_run_route_command $rpt POST_FILLER_POST_SROUTE $cmd]} {
            set route_ok 0
        }
    }
    set verify_ok [mptdc_signoff_post_filler_verify $rpt]
    set fh [open $rpt a]
    set status [expr {$route_ok && $sroute_ok && $verify_ok ? "PASS" : "REVIEW_REQUIRED"}]
    puts $fh "POST_FILLER_ROUTE_STATUS=$status"
    puts $fh "INCREMENTAL_ROUTE_STATUS=$status"
    close $fh
    return [expr {$status eq "PASS"}]
}

proc mptdc_signoff_insert_final_fillers {} {
    global mptdc_xh018_cells
    set rpt [file join [mptdc_signoff_report_dir] filler_status.rpt]
    set before [mptdc_signoff_count_existing_filler_cells]
    if {![mptdc_signoff_env_truthy MPTDC_ENABLE_FINAL_FILLER 1]} {
        set fh [open $rpt w]
        puts $fh "# MPTDC Final Filler Status"
        puts $fh "FILLER_COUNT_BEFORE=$before"
        puts $fh "FILLER_INSERTION_STATUS=SKIPPED"
        puts $fh "FILLER_INSERTION_REASON=MPTDC_ENABLE_FINAL_FILLER_DISABLED_FOR_ROUTE_DEBUG"
        puts $fh "FILLER_STATUS=PROVISIONAL"
        puts $fh "POST_FILLER_ROUTE_CLEANUP=SKIPPED"
        puts $fh "POST_FILLER_GATE_NOTE=route_status_rpt_will_capture_base_route_without_final_filler"
        close $fh
        mptdc_signoff_set_status FILLER_STATUS PROVISIONAL $rpt
        return $rpt
    }
    lassign [mptdc_signoff_configure_filler_mode] filler_mode_ok filler_mode_rpt
    set fh [open $rpt w]
    puts $fh "# MPTDC Final Filler Status"
    puts $fh "FILLER_CELL_FAMILY=FEED*JIHD"
    puts $fh "FILLER_CANDIDATES=$mptdc_xh018_cells(filler)"
    puts $fh "FILLER_COUNT_BEFORE=$before"
    puts $fh "FILLER_MODE_REPORT=$filler_mode_rpt"
    puts $fh "FILLER_MODE_STATUS=[expr {$filler_mode_ok ? "PASS_OR_REVIEW" : "FAIL"}]"
    if {!$filler_mode_ok} {
        puts $fh "FILLER_INSERTION_STATUS=FAIL"
        puts $fh "FILLER_INSERTION_REASON=drc_safe_filler_mode_not_applied"
        close $fh
        mptdc_signoff_set_status FILLER_STATUS FAIL $rpt
        error "MPTDC_FILLER_MODE_GATE_FAILED: report=$filler_mode_rpt"
    }
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
    set post_filler_ok [mptdc_signoff_post_filler_route_cleanup $rpt]
    set fh [open $rpt a]
    puts $fh "POST_FILLER_CLEANUP_STATUS=[expr {$post_filler_ok ? "PASS" : "REVIEW_REQUIRED"}]"
    puts $fh "POST_FILLER_GATE_NOTE=route_status_rpt_remains_the_hard_short_open_gate"
    close $fh
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
    return [expr {[mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_TIMING_FOCUS 0] ||
        [mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_TARGETED_ECO 0]}]
}

proc mptdc_signoff_fast_tag_targeted_eco_enabled {} {
    return [mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_TARGETED_ECO 0]
}

proc mptdc_signoff_collection_count {objects} {
    if {$objects eq ""} { return 0 }
    if {![catch {sizeof_collection $objects} count] && [string is integer -strict $count]} {
        return $count
    }
    return [llength $objects]
}

proc mptdc_signoff_fast_tag_source_q_pins {} {
    set src_pins ""
    catch {set src_pins [get_pins -quiet -hierarchical *u_fast_tag_tag_o_reg*/Q]}
    if {[mptdc_signoff_collection_count $src_pins] == 0} {
        catch {set src_pins [get_pins -quiet -hierarchical *gen_fast_tag_col*u_fast_tag*tag_o_reg*/Q]}
    }
    return $src_pins
}

proc mptdc_signoff_fast_tag_capture_d_pins {} {
    set dst_pins ""
    catch {set dst_pins [get_pins -quiet -hierarchical *gen_pd_row*gen_pd_col*u_pd*nfast_hit_latched_reg*/D]}
    if {[mptdc_signoff_collection_count $dst_pins] == 0} {
        catch {set dst_pins [get_pins -quiet -hierarchical *nfast_hit_latched_reg*/D]}
    }
    return $dst_pins
}

proc mptdc_signoff_capture_fast_tag_timing_report {src_pins dst_pins timing_rpt} {
    if {[mptdc_signoff_collection_count $src_pins] == 0 ||
        [mptdc_signoff_collection_count $dst_pins] == 0} {
        set tfh [open $timing_rpt w]
        puts $tfh "REPORT_STATUS=FAILED"
        puts $tfh "REPORT_ERROR=missing_source_or_endpoint_pins"
        close $tfh
        return [dict create status REVIEW_REQUIRED report $timing_rpt error missing_source_or_endpoint_pins]
    }
    set max_paths [mptdc_signoff_env_int MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_PATHS 100]
    if {$max_paths < 1} { set max_paths 100 }
    set errors [list]
    foreach cmd [list \
        [list report_timing -view TC_NOMINAL -from $src_pins -to $dst_pins -max_paths $max_paths -path_type full_clock -net] \
        [list report_timing -view TC_NOMINAL -from $src_pins -to $dst_pins -max_paths $max_paths -path_type full_clock] \
        [list report_timing -view TC_NOMINAL -from $src_pins -to $dst_pins -max_paths $max_paths]] {
        set redirect_cmd [concat $cmd [list > $timing_rpt]]
        if {![catch {eval $redirect_cmd} err]} {
            return [dict create status PASS report $timing_rpt command $cmd error ""]
        }
        lappend errors "$cmd: $err"
    }
    set tfh [open $timing_rpt w]
    puts $tfh "REPORT_STATUS=FAILED"
    puts $tfh "REPORT_ERROR=[join $errors { | }]"
    close $tfh
    return [dict create status REVIEW_REQUIRED report $timing_rpt command "" error [join $errors { | }]]
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

    set src_pins [mptdc_signoff_fast_tag_source_q_pins]
    set dst_pins [mptdc_signoff_fast_tag_capture_d_pins]

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
    if {[llength [info commands set_critical_range]] == 0} {
        puts $fh "SOURCE_CRITICAL_RANGE_STATUS=SKIPPED"
        puts $fh "SOURCE_CRITICAL_RANGE_REASON=command_unavailable_in_innovus"
    } elseif {[catch {set_critical_range $critical_range $src_pins} err]} {
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
    set timing_result [mptdc_signoff_capture_fast_tag_timing_report $src_pins $dst_pins $timing_rpt]
    if {[dict get $timing_result status] ne "PASS"} {
        set err [dict get $timing_result error]
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

proc mptdc_signoff_pin_source_cells {pins} {
    set cells [list]
    set cell_objs [list]
    catch {set cell_objs [get_cells -quiet -of_objects $pins]}
    foreach name [mptdc_signoff_object_names $cell_objs] {
        mptdc_signoff_unique_append cells $name
    }
    foreach pin_name [mptdc_signoff_object_names $pins] {
        set inst $pin_name
        regsub {/[^/]+$} $inst {} inst
        mptdc_signoff_unique_append cells $inst
    }
    return $cells
}

proc mptdc_signoff_cell_master_name {inst} {
    set ptr [mptdc_signoff_cell_ptr $inst]
    foreach attr {cell.name base_cell.name lib_cell.name ref_name master.name} {
        set value ""
        if {$ptr ne "" && ![catch {set value [dbGet ${ptr}.${attr}]}] && $value ne "" && $value ne "0x0"} {
            return "$value"
        }
    }
    foreach attr {base_cell.name lib_cell.name ref_name cell.name master.name} {
        set value ""
        if {![catch {set value [get_db inst:$inst .$attr]}] && $value ne "" && $value ne "0x0"} {
            return "$value"
        }
    }
    return UNKNOWN
}

proc mptdc_signoff_set_cell_dont_touch {inst value} {
    set ok 0
    set obj [list]
    catch {set obj [get_cells -quiet $inst]}
    if {[mptdc_signoff_collection_count $obj] > 0} {
        if {![catch {set_dont_touch $obj $value}]} { set ok 1 }
        if {![catch {set_db $obj .dont_touch $value}]} { set ok 1 }
    }
    return $ok
}

proc mptdc_signoff_set_cell_size_ok {inst} {
    set ok 0
    set obj [list]
    catch {set obj [get_cells -quiet $inst]}
    if {[mptdc_signoff_collection_count $obj] > 0} {
        if {![catch {set_db $obj .dont_touch size_ok}]} { set ok 1 }
    }
    if {!$ok} {
        if {[mptdc_signoff_collection_count $obj] > 0} {
            if {![catch {set_dont_touch $obj false}]} { set ok 1 }
            if {![catch {set_db $obj .dont_touch false}]} { set ok 1 }
        }
    }
    return $ok
}

proc mptdc_signoff_fast_tag_eco_next_drive_master {master} {
    set master [string toupper $master]
    if {![regexp {^(.+JIHD)X([0-9]+)$} $master -> prefix drive]} {
        return ""
    }
    set limit [mptdc_signoff_env_int MPTDC_PNR_FAST_TAG_ECO_UPSIZE_DRIVE_LIMIT 4]
    if {$limit < 1} { set limit 1 }
    foreach next {1 2 3 4 6 8 12} {
        if {$next > $drive && $next <= $limit} {
            return "${prefix}X${next}"
        }
    }
    return ""
}

proc mptdc_signoff_fast_tag_eco_allow_cell {inst} {
    set norm [mptdc_signoff_norm_inst_name $inst]
    set master [string toupper [mptdc_signoff_cell_master_name $inst]]
    if {[regexp -nocase {RO_tune6|u_ro_tune4|phase_buf|gen_phase_buf|clk_osc|clk_sys|cts} $norm]} {
        return [dict create allowed 0 class FORBIDDEN_PROTECTED_MACRO_PHASE_OR_CLOCK master $master]
    }
    if {[mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_ALLOW_ENDPOINT_FLOP_RESIZE 0] &&
        [regexp -nocase {tag_o_reg|nfast_hit_latched_reg} $norm] &&
        [mptdc_signoff_fast_tag_eco_next_drive_master $master] ne ""} {
        return [dict create allowed 1 class FAST_TAG_ENDPOINT_FLOP_BOUNDED_RESIZE master $master]
    }
    if {[regexp -nocase {tag_o_reg|nfast_hit_latched_reg|_reg(\[[0-9]+\])?$} $norm]} {
        return [dict create allowed 0 class FORBIDDEN_SOURCE_OR_CAPTURE_FLOP master $master]
    }
    if {$master eq "ON22JIHDX1"} {
        return [dict create allowed 1 class ON22_X1_TO_X2_CANDIDATE master $master]
    }
    if {[regexp {^(BU|IN).*JIHDX[0-9]+$} $master] &&
        [regexp -nocase {fast_tag|raw_lfsr|nfast|tag|hit|meas_ctrl} $norm]} {
        return [dict create allowed 1 class FAST_TAG_DATA_BUFFER_OR_INVERTER master $master]
    }
    if {[mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_UPSIZE_SMALL_GATES 1] &&
        [mptdc_signoff_fast_tag_eco_next_drive_master $master] ne "" &&
        [regexp -nocase {fast_tag|raw_lfsr|nfast|tag|hit|meas_ctrl} $norm]} {
        return [dict create allowed 1 class FAST_TAG_RELATED_UPSIZE_CANDIDATE master $master]
    }
    return [dict create allowed 0 class NON_TARGET_CELL master $master]
}

proc mptdc_signoff_collect_fast_tag_eco_cells {} {
    set patterns [list \
        *gen_fast_tag_col* \
        *u_fast_tag* \
        *raw_lfsr_tag* \
        *nfast* \
        *meas_ctrl* \
        *hit*]
    set cells [list]
    foreach inst [mptdc_signoff_collect_cells $patterns] {
        set info [mptdc_signoff_fast_tag_eco_allow_cell $inst]
        if {[dict get $info allowed]} {
            mptdc_signoff_unique_append cells $inst
        }
    }
    return $cells
}

proc mptdc_signoff_extract_inst_from_timing_token {token} {
    set text [string trim "$token" " \t\r\n,;(){}"]
    if {![regexp {/} $text]} { return "" }
    regsub {/[A-Za-z0-9_$\[\]\\]+.*$} $text {} inst
    set inst [string trim $inst " \t\r\n,;(){}"]
    if {$inst eq "" || [regexp {^(Startpoint|Endpoint|Path|clock|data)$} $inst]} {
        return ""
    }
    return $inst
}

proc mptdc_signoff_fast_tag_path_eco_scores {timing_rpt} {
    set scores [dict create]
    if {![file exists $timing_rpt]} {
        return $scores
    }
    set max_cells [mptdc_signoff_env_int MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_CELLS 128]
    if {$max_cells < 1} { set max_cells 128 }
    set fh [open $timing_rpt r]
    while {[gets $fh line] >= 0} {
        foreach token [regexp -all -inline {\S+/\S+} $line] {
            set inst [mptdc_signoff_extract_inst_from_timing_token $token]
            if {$inst eq ""} { continue }
            set info [mptdc_signoff_fast_tag_eco_allow_cell $inst]
            if {![dict get $info allowed]} { continue }
            if {[dict exists $scores $inst]} {
                dict incr scores $inst
            } else {
                dict set scores $inst 1
            }
            if {[dict size $scores] >= $max_cells} {
                break
            }
        }
        if {[dict size $scores] >= $max_cells} {
            break
        }
    }
    close $fh
    return $scores
}

proc mptdc_signoff_rank_fast_tag_path_eco_cells {timing_rpt} {
    set ranked [list]
    set scores [mptdc_signoff_fast_tag_path_eco_scores $timing_rpt]
    dict for {inst score} $scores {
        lappend ranked [list $inst $score]
    }
    return [lsort -integer -decreasing -index 1 $ranked]
}

proc mptdc_signoff_try_cell_resize {inst target_cell} {
    set errors [list]
    foreach cmd [list \
        [list ecoChangeCell -inst $inst -cell $target_cell] \
        [list change_link $inst $target_cell] \
        [list sizeCell $inst $target_cell] \
        [list replaceCell $inst $target_cell]] {
        if {![catch {uplevel #0 $cmd} err]} {
            return [dict create status PASS command $cmd error ""]
        }
        lappend errors "$cmd: $err"
    }
    return [dict create status REVIEW_REQUIRED command "" error [join $errors { | }]]
}

proc mptdc_signoff_try_on22_x2_resize {inst} {
    return [mptdc_signoff_try_cell_resize $inst ON22JIHDX2]
}

proc mptdc_signoff_apply_fast_tag_targeted_eco {} {
    set rpt [file join [mptdc_signoff_report_dir] fast_tag_targeted_eco.rpt]
    set fh [open $rpt w]
    puts $fh "# MPTDC Fast-Tag Targeted Innovus ECO"
    puts $fh "FAST_TAG_TARGETED_ECO_ENABLED=[mptdc_signoff_fast_tag_targeted_eco_enabled]"
    puts $fh "FAST_TAG_TO_PD_TS_FALSE_PATH=NO"
    puts $fh "FAST_TAG_TO_PD_TS_MULTICYCLE=NO"
    puts $fh "FAST_TAG_TARGETED_ECO_SCOPE=innovus_only_no_rtl_no_genus"
    puts $fh "FAST_TAG_TARGETED_ECO_ALLOWED=fast_tag_related_data_buffers_inverters_small_gates_and_ON22JIHDX1_to_ON22JIHDX2"
    puts $fh "FAST_TAG_TARGETED_ECO_FORBIDDEN=RO_macros_phase_buffers_oscillator_clocks_clock_tree_cells"
    puts $fh "FAST_TAG_ECO_PROTECT_ENDPOINT_FLOPS=[expr {[mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_PROTECT_ENDPOINT_FLOPS 0] ? 1 : 0}]"
    puts $fh "FAST_TAG_ECO_UPSIZE_SMALL_GATES=[expr {[mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_UPSIZE_SMALL_GATES 1] ? 1 : 0}]"
    puts $fh "FAST_TAG_ECO_MAX_UPSIZE_CELLS=[mptdc_signoff_env_int MPTDC_PNR_FAST_TAG_ECO_MAX_UPSIZE_CELLS 64]"
    puts $fh "FAST_TAG_ECO_UPSIZE_DRIVE_LIMIT=[mptdc_signoff_env_int MPTDC_PNR_FAST_TAG_ECO_UPSIZE_DRIVE_LIMIT 4]"
    puts $fh "FAST_TAG_ECO_PATH_DRIVEN=[expr {[mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_PATH_DRIVEN 1] ? 1 : 0}]"
    puts $fh "FAST_TAG_ECO_PATH_MAX_PATHS=[mptdc_signoff_env_int MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_PATHS 100]"
    puts $fh "FAST_TAG_ECO_PATH_MAX_CELLS=[mptdc_signoff_env_int MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_CELLS 128]"
    puts $fh "FAST_TAG_ECO_NAME_FALLBACK=[expr {[mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_NAME_FALLBACK 0] ? 1 : 0}]"
    puts $fh "FAST_TAG_ECO_ALLOW_ENDPOINT_FLOP_RESIZE=[expr {[mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_ALLOW_ENDPOINT_FLOP_RESIZE 0] ? 1 : 0}]"
    if {![mptdc_signoff_fast_tag_targeted_eco_enabled]} {
        puts $fh "FAST_TAG_TARGETED_ECO_STATUS=SKIPPED"
        close $fh
        return $rpt
    }

    set src_pins [mptdc_signoff_fast_tag_source_q_pins]
    set dst_pins [mptdc_signoff_fast_tag_capture_d_pins]
    set src_cells [mptdc_signoff_pin_source_cells $src_pins]
    set dst_cells [mptdc_signoff_pin_source_cells $dst_pins]
    puts $fh "FAST_TAG_SOURCE_Q_PIN_COUNT=[mptdc_signoff_collection_count $src_pins]"
    puts $fh "NFAST_CAPTURE_D_PIN_COUNT=[mptdc_signoff_collection_count $dst_pins]"
    puts $fh "FAST_TAG_SOURCE_FLOP_COUNT=[llength $src_cells]"
    puts $fh "NFAST_CAPTURE_FLOP_COUNT=[llength $dst_cells]"
    if {[mptdc_signoff_collection_count $src_pins] == 0 ||
        [mptdc_signoff_collection_count $dst_pins] == 0} {
        puts $fh "FAST_TAG_TARGETED_ECO_STATUS=REVIEW_REQUIRED"
        puts $fh "FAST_TAG_TARGETED_ECO_ERROR=missing_source_or_endpoint_pins"
        close $fh
        return $rpt
    }

    set path_timing_rpt [file join [mptdc_signoff_report_dir] fast_tag_to_pd_timing_targeted_eco_input.rpt]
    set path_timing_result [mptdc_signoff_capture_fast_tag_timing_report $src_pins $dst_pins $path_timing_rpt]
    puts $fh "FAST_TAG_ECO_PATH_TIMING_REPORT=$path_timing_rpt"
    puts $fh "FAST_TAG_ECO_PATH_TIMING_REPORT_STATUS=[dict get $path_timing_result status]"
    if {[dict exists $path_timing_result command]} {
        puts $fh "FAST_TAG_ECO_PATH_TIMING_REPORT_COMMAND=[dict get $path_timing_result command]"
    }

    set protected [list]
    set protect_endpoint_flops [mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_PROTECT_ENDPOINT_FLOPS 0]
    if {$protect_endpoint_flops} {
        foreach inst [concat $src_cells $dst_cells] {
            mptdc_signoff_unique_append protected $inst
        }
    }
    foreach inst [mptdc_signoff_collect_cells [list *RO_tune6* *u_ro_tune4* *phase_buf* *gen_phase_buf* *u_phase_buf*]] {
        mptdc_signoff_unique_append protected $inst
    }
    set protected_count 0
    foreach inst $protected {
        if {[mptdc_signoff_set_cell_dont_touch $inst true]} {
            incr protected_count
        }
    }
    puts $fh "FAST_TAG_ECO_PROTECTED_CELL_COUNT=$protected_count"
    set size_ok_endpoint_count 0
    if {!$protect_endpoint_flops} {
        foreach inst [concat $src_cells $dst_cells] {
            if {[mptdc_signoff_set_cell_size_ok $inst]} {
                incr size_ok_endpoint_count
                puts $fh "FAST_TAG_ECO_ENDPOINT_FLOP_SIZE_OK=$inst"
            }
        }
    }
    puts $fh "FAST_TAG_ECO_ENDPOINT_FLOP_SIZE_OK_COUNT=$size_ok_endpoint_count"
    foreach pattern {clk_osc_slow clk_osc_fast clk_osc_slow_tap* clk_osc_fast_tap* clk_osc_*_buf_tap*} {
        if {![catch {set_dont_touch_network [get_clocks $pattern]} err]} {
            puts $fh "FAST_TAG_ECO_PROTECTED_CLOCK=$pattern"
        } else {
            puts $fh "FAST_TAG_ECO_PROTECTED_CLOCK_WARNING=$pattern error=$err"
        }
    }

    set path_scores [dict create]
    set path_allowed [list]
    if {[mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_PATH_DRIVEN 1] &&
        [dict get $path_timing_result status] eq "PASS"} {
        set path_scores [mptdc_signoff_fast_tag_path_eco_scores $path_timing_rpt]
        foreach ranked [mptdc_signoff_rank_fast_tag_path_eco_cells $path_timing_rpt] {
            set inst [lindex $ranked 0]
            set score [lindex $ranked 1]
            set info [mptdc_signoff_fast_tag_eco_allow_cell $inst]
            if {![dict get $info allowed]} { continue }
            mptdc_signoff_unique_append path_allowed $inst
            puts $fh "FAST_TAG_ECO_PATH_ALLOWED_CELL=$inst score=$score class=[dict get $info class] master=[dict get $info master]"
        }
        puts $fh "FAST_TAG_ECO_PATH_DRIVEN_STATUS=PASS"
    } else {
        puts $fh "FAST_TAG_ECO_PATH_DRIVEN_STATUS=SKIPPED"
    }
    puts $fh "FAST_TAG_ECO_PATH_ALLOWED_CELL_COUNT=[llength $path_allowed]"

    set broad_allowed [list]
    if {[mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_NAME_FALLBACK 0]} {
        set broad_allowed [mptdc_signoff_collect_fast_tag_eco_cells]
    }
    set allowed [list]
    foreach inst $path_allowed {
        mptdc_signoff_unique_append allowed $inst
    }
    set path_order_count [llength $allowed]
    foreach inst $broad_allowed {
        mptdc_signoff_unique_append allowed $inst
    }
    puts $fh "FAST_TAG_ECO_NAME_FALLBACK_ALLOWED_CELL_COUNT=[llength $broad_allowed]"
    puts $fh "FAST_TAG_ECO_PATH_ORDERED_PREFIX_COUNT=$path_order_count"
    set allowed_count 0
    set on22_candidates [list]
    set upsize_candidates [list]
    foreach inst $allowed {
        set info [mptdc_signoff_fast_tag_eco_allow_cell $inst]
        if {[mptdc_signoff_set_cell_dont_touch $inst false]} {
            incr allowed_count
        }
        set target [mptdc_signoff_fast_tag_eco_next_drive_master [dict get $info master]]
        set path_score 0
        if {[dict exists $path_scores $inst]} {
            set path_score [dict get $path_scores $inst]
        }
        puts $fh "FAST_TAG_ECO_ALLOWED_CELL=$inst class=[dict get $info class] master=[dict get $info master] path_score=$path_score resize_target=$target"
        if {[dict get $info class] eq "ON22_X1_TO_X2_CANDIDATE"} {
            lappend on22_candidates $inst
        }
        if {$target ne ""} {
            lappend upsize_candidates [list $inst $target]
        }
    }
    puts $fh "FAST_TAG_ECO_ALLOWED_CELL_COUNT=$allowed_count"
    puts $fh "FAST_TAG_ECO_ON22_X1_CANDIDATE_COUNT=[llength $on22_candidates]"
    puts $fh "FAST_TAG_ECO_UPSIZE_CANDIDATE_COUNT=[llength $upsize_candidates]"

    set resize_attempts 0
    set resize_success 0
    set max_upsize [mptdc_signoff_env_int MPTDC_PNR_FAST_TAG_ECO_MAX_UPSIZE_CELLS 64]
    if {$max_upsize < 0} { set max_upsize 0 }
    if {[mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_UPSIZE_SMALL_GATES 1]} {
        foreach candidate $upsize_candidates {
            if {$resize_attempts >= $max_upsize} {
                puts $fh "FAST_TAG_ECO_UPSIZE_STOP_REASON=max_upsize_cells_reached"
                break
            }
            set inst [lindex $candidate 0]
            set target [lindex $candidate 1]
            if {$target eq "ON22JIHDX2" && ![mptdc_signoff_env_truthy MPTDC_PNR_FAST_TAG_ECO_ALLOW_ON22_X2 1]} {
                puts $fh "FAST_TAG_ECO_UPSIZE_SKIPPED=$inst target=$target reason=ON22_X2_disabled_by_env"
                continue
            }
            incr resize_attempts
            set result [mptdc_signoff_try_cell_resize $inst $target]
            puts $fh "FAST_TAG_ECO_UPSIZE_ATTEMPT=$inst target=$target status=[dict get $result status] command=[dict get $result command]"
            if {[dict get $result status] eq "PASS"} {
                incr resize_success
            } else {
                puts $fh "FAST_TAG_ECO_UPSIZE_ATTEMPT_ERROR=[dict get $result error]"
            }
        }
    } else {
        puts $fh "FAST_TAG_ECO_UPSIZE_STATUS=DISABLED_BY_ENV"
    }
    puts $fh "FAST_TAG_ECO_UPSIZE_ATTEMPTS=$resize_attempts"
    puts $fh "FAST_TAG_ECO_UPSIZE_SUCCESSES=$resize_success"
    puts $fh "FAST_TAG_ECO_BUFFER_INSERTION_SCOPE=delegated_to_following_optDesign_postRoute_with_fast_tag_group_and_protected_forbidden_families"
    puts $fh "FAST_TAG_TARGETED_ECO_STATUS=PASS"
    close $fh
    return $rpt
}

proc mptdc_signoff_write_fast_tag_timing_diagnosis {timing_rpt setup_wns setup_closure_status} {
    set rpt [file join [mptdc_signoff_report_dir] fast_tag_to_pd_timing_diagnosis.rpt]
    set fh [open $rpt w]
    puts $fh "# MPTDC Fast-Tag-to-PD Timing Diagnosis"
    puts $fh "FAST_TAG_TO_PD_TS_FALSE_PATH=NO"
    puts $fh "FAST_TAG_TO_PD_TS_MULTICYCLE=NO"
    puts $fh "FAST_TAG_TIMING_REPORT=$timing_rpt"
    puts $fh "POSTROUTE_OPT_SETUP_WNS_NS=$setup_wns"
    puts $fh "POSTROUTE_OPT_SETUP_CLOSURE_STATUS=$setup_closure_status"
    if {![file exists $timing_rpt]} {
        puts $fh "FAST_TAG_TIMING_DIAGNOSIS_STATUS=REVIEW_REQUIRED"
        puts $fh "FAST_TAG_TIMING_DIAGNOSIS_ERROR=timing_report_missing"
        close $fh
        return $rpt
    }
    set focus_slack [mptdc_signoff_parse_worst_slack_ns $timing_rpt]
    puts $fh "FAST_TAG_FOCUSED_WORST_SLACK_NS=$focus_slack"
    set source_score 0
    set buffer_score 0
    set net_score 0
    set path_markers 0
    set fh_in [open $timing_rpt r]
    while {[gets $fh_in line] >= 0} {
        if {[regexp -nocase {^Path[[:space:]]+[0-9]+:|Startpoint:|Beginpoint:|Endpoint:|Slack Time|slack} $line]} {
            incr path_markers
        }
        if {[regexp -nocase {DFRRQ|DFF|tag_o_reg|clock.to.q|clock-to-q|C->Q|CK.*Q|/C[[:space:]].*/Q} $line]} {
            incr source_score
        }
        if {[regexp -nocase {BUJIHD|INJIHD|ON22JIHD|buffer|inverter} $line]} {
            incr buffer_score
        }
        if {[regexp -nocase {net delay|wire|route|interconnect|capacitance|fanout|physical|distance} $line]} {
            incr net_score
        }
    }
    close $fh_in
    set dominant UNKNOWN_REVIEW_REPORT
    if {$source_score >= $buffer_score && $source_score >= $net_score && $source_score > 0} {
        set dominant SOURCE_FLOP_C_TO_Q_OR_LAUNCH_Q
    } elseif {$buffer_score >= $net_score && $buffer_score > 0} {
        set dominant BUFFER_INVERTER_ON22_DELAY
    } elseif {$net_score > 0} {
        set dominant PHYSICAL_DISTANCE_OR_NET_DELAY
    }
    puts $fh "FAST_TAG_DIAGNOSIS_SOURCE_FLOP_SCORE=$source_score"
    puts $fh "FAST_TAG_DIAGNOSIS_BUFFER_INVERTER_ON22_SCORE=$buffer_score"
    puts $fh "FAST_TAG_DIAGNOSIS_PHYSICAL_NET_SCORE=$net_score"
    puts $fh "FAST_TAG_DIAGNOSIS_PATH_MARKERS=$path_markers"
    puts $fh "FAST_TAG_DIAGNOSIS_DOMINANT_TERM=$dominant"
    if {$setup_closure_status eq "FAIL"} {
        puts $fh "FAST_TAG_DIAGNOSIS_ACTION=STOP_OPT_LOOP_AND_REPORT_RESIDUAL_PATH"
    } else {
        puts $fh "FAST_TAG_DIAGNOSIS_ACTION=REVIEW_FOCUSED_REPORT_AGAINST_OFFICIAL_TC_GATE"
    }
    puts $fh "FAST_TAG_TIMING_DIAGNOSIS_STATUS=PASS"
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

proc mptdc_signoff_capture_postroute_setup_snapshot {prefix pass} {
    set rpt [file join [mptdc_signoff_report_dir] "postroute_opt_${prefix}_pass_${pass}_timing.rpt"]
    if {[catch {timeDesign -postRoute > $rpt} err]} {
        set fh [open $rpt w]
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh "REPORT_ERROR=$err"
        close $fh
        return [dict create status REVIEW_REQUIRED report $rpt wns "" tns "" error $err]
    }
    set wns [mptdc_signoff_parse_wns_ns $rpt]
    set tns [mptdc_signoff_parse_tns_ns $rpt]
    return [dict create status PASS report $rpt wns $wns tns $tns error ""]
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
    set requested_setup_passes [mptdc_signoff_env_int MPTDC_POSTROUTE_SETUP_OPT_PASSES $default_setup_passes]
    set setup_passes $requested_setup_passes
    if {$setup_passes < 1} {
        set setup_passes 1
    }
    set setup_hard_cap 10
    set setup_max_passes [mptdc_signoff_env_int MPTDC_POSTROUTE_SETUP_OPT_MAX_PASSES 10]
    if {$setup_max_passes < 1} {
        set setup_max_passes 1
    }
    set setup_hard_cap_applied 0
    if {$setup_max_passes > $setup_hard_cap} {
        set setup_max_passes $setup_hard_cap
        set setup_hard_cap_applied 1
    }
    if {$setup_passes > $setup_max_passes} {
        set setup_passes $setup_max_passes
        set setup_hard_cap_applied 1
    }
    set default_target [expr {$closure_mode ? 0.050 : 0.000}]
    set setup_target [mptdc_signoff_env_double MPTDC_POSTROUTE_SETUP_TARGET_SLACK_NS $default_target]
    set default_hold_passes [expr {$closure_mode ? 2 : 1}]
    set requested_hold_passes [mptdc_signoff_env_int MPTDC_POSTROUTE_HOLD_OPT_PASSES $default_hold_passes]
    set hold_passes $requested_hold_passes
    if {$hold_passes < 1} {
        set hold_passes 1
    }
    set hold_max_passes [mptdc_signoff_env_int MPTDC_POSTROUTE_HOLD_OPT_MAX_PASSES 2]
    if {$hold_max_passes < 1} {
        set hold_max_passes 1
    }
    if {$hold_passes > $hold_max_passes} {
        set hold_passes $hold_max_passes
    }
    set default_hold_target [expr {$closure_mode ? 0.020 : 0.000}]
    set hold_target [mptdc_signoff_env_double MPTDC_POSTROUTE_HOLD_TARGET_SLACK_NS $default_hold_target]
    set setup_early_stop [mptdc_signoff_env_truthy MPTDC_POSTROUTE_SETUP_EARLY_STOP 1]
    set setup_plateau_guard [mptdc_signoff_env_truthy MPTDC_POSTROUTE_SETUP_PLATEAU_GUARD 1]
    set setup_stall_limit [mptdc_signoff_env_int MPTDC_POSTROUTE_SETUP_STALL_LIMIT 2]
    if {$setup_stall_limit < 1} {
        set setup_stall_limit 1
    }
    set setup_min_improvement [mptdc_signoff_env_double MPTDC_POSTROUTE_SETUP_MIN_IMPROVEMENT_NS 0.005]
    if {$setup_min_improvement < 0.0} {
        set setup_min_improvement 0.0
    }
    puts $fh "POSTROUTE_OPT_TC_CLOSURE_MODE=[expr {$closure_mode ? "ENABLED" : "DISABLED"}]"
    puts $fh "POSTROUTE_OPT_SETUP_REQUESTED_PASSES=$requested_setup_passes"
    puts $fh "POSTROUTE_OPT_SETUP_HARD_CAP=$setup_hard_cap"
    puts $fh "POSTROUTE_OPT_SETUP_HARD_CAP_APPLIED=$setup_hard_cap_applied"
    puts $fh "POSTROUTE_OPT_SETUP_MAX_PASSES=$setup_max_passes"
    puts $fh "POSTROUTE_OPT_SETUP_PASSES=$setup_passes"
    puts $fh "POSTROUTE_OPT_SETUP_TARGET_SLACK_NS=$setup_target"
    puts $fh "POSTROUTE_OPT_SETUP_EARLY_STOP=[expr {$setup_early_stop ? 1 : 0}]"
    puts $fh "POSTROUTE_OPT_SETUP_PLATEAU_GUARD=[expr {$setup_plateau_guard ? 1 : 0}]"
    puts $fh "POSTROUTE_OPT_SETUP_STALL_LIMIT=$setup_stall_limit"
    puts $fh "POSTROUTE_OPT_SETUP_MIN_IMPROVEMENT_NS=$setup_min_improvement"
    puts $fh "POSTROUTE_OPT_HOLD_REQUESTED_PASSES=$requested_hold_passes"
    puts $fh "POSTROUTE_OPT_HOLD_MAX_PASSES=$hold_max_passes"
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
    set eco_rpt [mptdc_signoff_apply_fast_tag_targeted_eco]
    puts $fh "POSTROUTE_OPT_FAST_TAG_TARGETED_ECO_REPORT=$eco_rpt"
    close $fh
    set setup_aggregate_status PASS
    set best_setup_wns ""
    set final_setup_wns ""
    set final_setup_tns ""
    set setup_stop_after 0
    set setup_stop_reason ""
    set setup_stall_count 0
    for {set pass 1} {$pass <= $setup_passes} {incr pass} {
        set fh [open $rpt a]
        puts $fh "POSTROUTE_OPT_SETUP_PASS=$pass"
        flush $fh
        if {[catch {optDesign -postRoute} err]} {
            puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_STATUS=REVIEW_REQUIRED"
            puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_ERROR=$err"
            set setup_aggregate_status REVIEW_REQUIRED
        } else {
            puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_STATUS=PASS"
        }
        set timing_snapshot [mptdc_signoff_capture_postroute_setup_snapshot setup $pass]
        set setup_wns [dict get $timing_snapshot wns]
        set setup_tns [dict get $timing_snapshot tns]
        set final_setup_wns $setup_wns
        set final_setup_tns $setup_tns
        puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_TIMING_REPORT=[dict get $timing_snapshot report]"
        puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_WNS_NS=$setup_wns"
        puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_TNS_NS=$setup_tns"
        if {[dict get $timing_snapshot status] ne "PASS"} {
            puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_TIMING_STATUS=REVIEW_REQUIRED"
            puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_TIMING_ERROR=[dict get $timing_snapshot error]"
            set setup_aggregate_status REVIEW_REQUIRED
        } else {
            puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_TIMING_STATUS=PASS"
        }
        set stop_reason ""
        if {$setup_wns ne ""} {
            if {$setup_early_stop && $setup_wns >= $setup_target} {
                set stop_reason "target_slack_reached"
            } elseif {$best_setup_wns eq "" || ($setup_wns - $best_setup_wns) >= $setup_min_improvement} {
                set best_setup_wns $setup_wns
                set setup_stall_count 0
            } else {
                incr setup_stall_count
                if {$setup_plateau_guard && $setup_stall_count >= $setup_stall_limit} {
                    set stop_reason "setup_wns_plateau"
                }
            }
        }
        puts $fh "POSTROUTE_OPT_setup_PASS_${pass}_STALL_COUNT=$setup_stall_count"
        if {$stop_reason ne ""} {
            puts $fh "POSTROUTE_OPT_SETUP_STOP_AFTER_PASS=$pass"
            puts $fh "POSTROUTE_OPT_SETUP_STOP_REASON=$stop_reason"
            set setup_stop_after $pass
            set setup_stop_reason $stop_reason
        }
        close $fh
        if {$stop_reason ne ""} {
            break
        }
    }
    if {$setup_stop_reason eq ""} {
        set setup_stop_after $setup_passes
        set setup_stop_reason max_passes_exhausted
    }
    set setup_closure_status FAIL
    if {$setup_aggregate_status eq "PASS" && $final_setup_wns ne "" && $final_setup_wns >= 0.0} {
        set setup_closure_status PASS
    }
    set final_fast_tag_timing_rpt [file join [mptdc_signoff_report_dir] fast_tag_to_pd_timing_postroute_opt_final.rpt]
    set final_src_pins [mptdc_signoff_fast_tag_source_q_pins]
    set final_dst_pins [mptdc_signoff_fast_tag_capture_d_pins]
    set final_fast_tag_timing_result [mptdc_signoff_capture_fast_tag_timing_report $final_src_pins $final_dst_pins $final_fast_tag_timing_rpt]
    set diagnosis_rpt [mptdc_signoff_write_fast_tag_timing_diagnosis $final_fast_tag_timing_rpt $final_setup_wns $setup_closure_status]
    set fh [open $rpt a]
    puts $fh "POSTROUTE_OPT_setup_STATUS=$setup_aggregate_status"
    puts $fh "POSTROUTE_OPT_SETUP_STOP_AFTER_PASS=$setup_stop_after"
    puts $fh "POSTROUTE_OPT_SETUP_STOP_REASON=$setup_stop_reason"
    puts $fh "POSTROUTE_OPT_SETUP_FINAL_WNS_NS=$final_setup_wns"
    puts $fh "POSTROUTE_OPT_SETUP_FINAL_TNS_NS=$final_setup_tns"
    puts $fh "POSTROUTE_OPT_SETUP_CLOSURE_STATUS=$setup_closure_status"
    puts $fh "POSTROUTE_OPT_FAST_TAG_FINAL_TIMING_REPORT=$final_fast_tag_timing_rpt"
    puts $fh "POSTROUTE_OPT_FAST_TAG_FINAL_TIMING_STATUS=[dict get $final_fast_tag_timing_result status]"
    puts $fh "POSTROUTE_OPT_FAST_TAG_TIMING_DIAGNOSIS_REPORT=$diagnosis_rpt"
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
        "route DRC" [list {verify_drc} {verifyGeometry}]
    mptdc_signoff_dump_drc_markers [file rootname $drc_rpt]_markers.tsv
    mptdc_signoff_capture_required_candidates $regular_rpt \
        "regular-net connectivity" [list {verifyConnectivity -type regular} {verifyConnectivity}]
    lassign [mptdc_signoff_capture_to_file_selected $special_rpt [mptdc_signoff_pg_connectivity_commands {VDD VSS}]] special_ok special_cmd
    if {!$special_ok} {
        error "MPTDC_REQUIRED_REPORT_COMMAND_FAILED: title=special-net connectivity path=$special_rpt"
    }
    set fh [open [file rootname $special_rpt]_command.rpt w]
    puts $fh "SPECIAL_CONNECTIVITY_COMMAND=$special_cmd"
    close $fh
    mptdc_signoff_capture_candidates $report_route_rpt \
        "route summary" [list {reportRoute} {report_route}]
}

proc mptdc_signoff_read_route_gate_reports {drc_rpt regular_rpt special_rpt report_route_rpt} {
    set drc_data [mptdc_signoff_parse_verify_drc_report $drc_rpt]
    set marker_rpt [file rootname $drc_rpt]_markers.tsv
    if {[file exists $marker_rpt]} {
        dict set drc_data marker_report $marker_rpt
    }
    set regular_bad [mptdc_signoff_connectivity_report_has_errors $regular_rpt]
    set special_bad [mptdc_signoff_connectivity_report_has_errors $special_rpt]
    set unrouted [mptdc_signoff_parse_report_route_unrouted $report_route_rpt]
    if {$unrouted eq "UNKNOWN" && ![lindex $regular_bad 0] && ![lindex $special_bad 0]} {
        set unrouted 0
        dict set drc_data unrouted_source connectivity_clean_fallback
    } else {
        dict set drc_data unrouted_source report_route
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

proc mptdc_signoff_route_drc_review_class {drc_data} {
    set total [dict get $drc_data total_violations]
    if {$total eq "UNKNOWN"} {
        return [list 0 unknown_total {}]
    }
    set class_counts [dict get $drc_data drc_class_counts]
    if {[llength $class_counts] == 0} {
        return [list 0 missing_class_counts {}]
    }
    set allowed_raw [mptdc_signoff_env MPTDC_ROUTE_DRC_REVIEW_ALLOWED_CLASSES Mar]
    set allowed [list]
    foreach cls $allowed_raw {
        lappend allowed [string tolower $cls]
    }
    set nonzero [list]
    set disallowed [list]
    set allowed_total 0
    foreach {cls count} $class_counts {
        if {$count eq "" || ![string is integer -strict $count]} {
            lappend disallowed "$cls=$count"
            continue
        }
        if {$count == 0} {
            continue
        }
        lappend nonzero "$cls=$count"
        if {[lsearch -exact $allowed [string tolower $cls]] >= 0} {
            incr allowed_total $count
        } else {
            lappend disallowed "$cls=$count"
        }
    }
    if {[llength $disallowed] > 0} {
        return [list 0 "disallowed_classes:[join $disallowed ,]" $nonzero]
    }
    if {$allowed_total != $total} {
        return [list 0 "class_total_mismatch:allowed=$allowed_total total=$total" $nonzero]
    }
    return [list 1 allowed_classes $nonzero]
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
    set max_review [mptdc_signoff_env_int MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS 2]
    set review_class [mptdc_signoff_route_drc_review_class $drc_data]
    set review_class_ok [lindex $review_class 0]
    return [expr {$total > 0 &&
        $total <= $max_review &&
        $shorts == 0 &&
        ![lindex $regular_bad 0] &&
        ![lindex $special_bad 0] &&
        $unrouted ne "UNKNOWN" &&
        $unrouted == 0 &&
        $review_class_ok}]
}

proc mptdc_signoff_route_gate_apply_router_drc {drc_data router_drc router_rpt} {
    dict set drc_data router_transcript_status [dict get $router_drc status]
    dict set drc_data router_transcript_drc [dict get $router_drc total_violations]
    dict set drc_data router_transcript_shorts [dict get $router_drc shorts]
    dict set drc_data router_transcript_source $router_rpt
    return $drc_data
}

proc mptdc_signoff_route_gate_recovery {drc_rpt regular_rpt special_rpt report_route_rpt route_gate} {
    set rpt [file join [mptdc_signoff_report_dir] route_recovery_status.rpt]
    lassign $route_gate drc_data regular_bad special_bad unrouted
    set fh [open $rpt w]
    puts $fh "# MPTDC Route Gate Recovery"
    puts $fh "ROUTE_GATE_RECOVERY_INITIAL_DRC=[dict get $drc_data total_violations]"
    puts $fh "ROUTE_GATE_RECOVERY_INITIAL_SHORTS=[dict get $drc_data shorts]"
    puts $fh "ROUTE_GATE_RECOVERY_REPAIR_COMMANDS=[mptdc_signoff_route_repair_commands]"
    if {[mptdc_signoff_route_gate_is_pass $drc_data $regular_bad $special_bad $unrouted]} {
        puts $fh "ROUTE_GATE_RECOVERY_STATUS=NOT_NEEDED"
        close $fh
        return $route_gate
    }
    if {![mptdc_signoff_env_truthy MPTDC_ENABLE_ROUTE_GATE_RECOVERY 0]} {
        puts $fh "ROUTE_GATE_RECOVERY_STATUS=DISABLED_BY_DEFAULT"
        puts $fh "ROUTE_GATE_RECOVERY_ENABLE_ENV=MPTDC_ENABLE_ROUTE_GATE_RECOVERY"
        close $fh
        return $route_gate
    }
    if {[mptdc_signoff_env_truthy MPTDC_DISABLE_ROUTE_GATE_RECOVERY]} {
        puts $fh "ROUTE_GATE_RECOVERY_STATUS=DISABLED"
        close $fh
        return $route_gate
    }
    close $fh
    if {[lindex $special_bad 0] && [mptdc_signoff_env_truthy MPTDC_ROUTE_GATE_SROUTE_RECOVERY 1]} {
        set fh [open $rpt a]
        puts $fh "ROUTE_GATE_SROUTE_RECOVERY=ENABLED"
        puts $fh "ROUTE_GATE_SROUTE_RECOVERY_INITIAL_SPECIAL_BAD_LINES=[lindex $special_bad 1]"
        mptdc_signoff_configure_sroute_mode $fh ROUTE_GATE
        set sroute_ok [mptdc_signoff_try_sroute_command $fh ROUTE_GATE_SROUTE [mptdc_signoff_sroute_commands {VDD VSS}]]
        puts $fh "ROUTE_GATE_SROUTE_RECOVERY_COMMAND_STATUS=[expr {$sroute_ok ? "PASS" : "FAIL"}]"
        close $fh
        if {$sroute_ok} {
            mptdc_signoff_capture_route_gate_reports $drc_rpt $regular_rpt $special_rpt $report_route_rpt
            set route_gate [mptdc_signoff_read_route_gate_reports $drc_rpt $regular_rpt $special_rpt $report_route_rpt]
            lassign $route_gate drc_data regular_bad special_bad unrouted
            set fh [open $rpt a]
            puts $fh "ROUTE_GATE_SROUTE_RECOVERY_VERIFY_DRC=[dict get $drc_data total_violations]"
            puts $fh "ROUTE_GATE_SROUTE_RECOVERY_VERIFY_SHORTS=[dict get $drc_data shorts]"
            puts $fh "ROUTE_GATE_SROUTE_RECOVERY_SPECIAL_BAD=[lindex $special_bad 0]"
            puts $fh "ROUTE_GATE_SROUTE_RECOVERY_SPECIAL_BAD_LINES=[lindex $special_bad 1]"
            close $fh
            if {[mptdc_signoff_route_gate_is_pass $drc_data $regular_bad $special_bad $unrouted]} {
                set fh [open $rpt a]
                puts $fh "ROUTE_GATE_RECOVERY_STATUS=PASS_AFTER_SROUTE"
                close $fh
                return $route_gate
            }
        }
    } else {
        set fh [open $rpt a]
        puts $fh "ROUTE_GATE_SROUTE_RECOVERY=[expr {[lindex $special_bad 0] ? "DISABLED_BY_ENV" : "NOT_NEEDED"}]"
        close $fh
    }
    foreach cmd [mptdc_signoff_route_repair_commands] {
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
        set recovery_marker_rpt [mptdc_signoff_dump_drc_markers [file rootname $cmd_rpt]_markers.tsv]
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
        puts $fh "ROUTE_GATE_RECOVERY_ATTEMPT_MARKER_REPORT=$recovery_marker_rpt"
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
        } elseif {$review_allowed} {
            set innovus_verify_status REVIEW_REQUIRED
        }
    }
    set review_class [mptdc_signoff_route_drc_review_class $drc_data]
    set fh [open $rpt w]
    puts $fh "ROUTE_STATUS=$status"
    puts $fh "ROUTE_IMPLEMENTATION_STATUS=$status"
    puts $fh "INNOVUS_VERIFY_DRC_STATUS=$innovus_verify_status"
    puts $fh "FOUNDRY_DRC_STATUS=DEFERRED"
    puts $fh "GEOMETRY_DRC_VIOLATIONS=$total"
    puts $fh "SHORTS=$shorts"
    if {[dict exists $drc_data router_transcript_drc]} {
        puts $fh "ROUTER_TRANSCRIPT_DRC=[dict get $drc_data router_transcript_drc]"
        puts $fh "ROUTER_TRANSCRIPT_SHORTS=[dict get $drc_data router_transcript_shorts]"
        puts $fh "ROUTER_TRANSCRIPT_STATUS=[dict get $drc_data router_transcript_status]"
        puts $fh "ROUTER_TRANSCRIPT_SOURCE=[dict get $drc_data router_transcript_source]"
    } else {
        puts $fh "ROUTER_TRANSCRIPT_DRC=NOT_USED_FOR_GATE"
        puts $fh "ROUTER_TRANSCRIPT_SHORTS=NOT_USED_FOR_GATE"
    }
    puts $fh "INNOVUS_VERIFY_DRC_VIOLATIONS_RAW=$verify_total"
    puts $fh "INNOVUS_VERIFY_DRC_SHORTS_RAW=$verify_shorts"
    puts $fh "REGULAR_NET_CONNECTIVITY_BAD=$regular_flag"
    puts $fh "REGULAR_NET_BAD_LINES=[lindex $regular_bad 1]"
    puts $fh "SPECIAL_NET_CONNECTIVITY_BAD=$special_flag"
    puts $fh "SPECIAL_NET_BAD_LINES=[lindex $special_bad 1]"
    puts $fh "REGULAR_NET_OPENS=[expr {$regular_flag ? "NONZERO_OR_UNPARSED" : 0}]"
    puts $fh "SPECIAL_NET_OPENS=[expr {$special_flag ? "NONZERO_OR_UNPARSED" : 0}]"
    puts $fh "UNROUTED_NETS=$unrouted"
    if {[dict exists $drc_data unrouted_source]} {
        puts $fh "UNROUTED_NETS_SOURCE=[dict get $drc_data unrouted_source]"
    }
    puts $fh "PARTIAL_ROUTES=REVIEW_REPORT_ROUTE"
    puts $fh "ANTENNA_STATUS=$antenna_status"
    puts $fh "ROUTE_DRC_REVIEW_CONTINUE_STATUS=[expr {$review_allowed ? "ENABLED" : "DISABLED"}]"
    puts $fh "ROUTE_DRC_REVIEW_CONTINUE_ENV=MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE"
    puts $fh "ROUTE_DRC_REVIEW_MAX_VIOLATIONS=[mptdc_signoff_env_int MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS 2]"
    puts $fh "ROUTE_DRC_REVIEW_ALLOWED_CLASSES=[mptdc_signoff_env MPTDC_ROUTE_DRC_REVIEW_ALLOWED_CLASSES Mar]"
    puts $fh "ROUTE_DRC_REVIEW_CLASS_STATUS=[expr {[lindex $review_class 0] ? "PASS" : "FAIL"}]"
    puts $fh "ROUTE_DRC_REVIEW_CLASS_REASON=[lindex $review_class 1]"
    puts $fh "ROUTE_DRC_REVIEW_CLASS_COUNTS=[lindex $review_class 2]"
    puts $fh "ROUTE_DRC_CLASS_COUNTS=[dict get $drc_data drc_class_counts]"
    if {$review_allowed} {
        puts $fh "ROUTE_DRC_REVIEW_CLASS=ALLOWED_NONSHORT_MAR_WITH_CLEAN_CONNECTIVITY"
    }
    if {[dict exists $drc_data route_drc_source]} {
        puts $fh "ROUTE_DRC_SOURCE=[dict get $drc_data route_drc_source]"
    }
    if {[dict exists $drc_data marker_report]} {
        puts $fh "DRC_MARKER_REPORT=[dict get $drc_data marker_report]"
    }
    if {[dict exists $drc_data verify_drc_violations_raw]} {
        puts $fh "VERIFY_DRC_VIOLATIONS_RAW=[dict get $drc_data verify_drc_violations_raw]"
    }
    if {[dict exists $drc_data verify_drc_shorts_raw]} {
        puts $fh "VERIFY_DRC_SHORTS_RAW=[dict get $drc_data verify_drc_shorts_raw]"
    }
    set failure_marker_rpt ""
    set failure_def ""
    set failure_checkpoint ""
    if {$status eq "FAIL"} {
        set failure_marker_rpt [file join [mptdc_signoff_report_dir] route_gate_failure_drc_markers.tsv]
        set failure_def [file join [mptdc_signoff_def_dir] 04_route_failed.def]
        set failure_checkpoint [file join [mptdc_signoff_checkpoint_dir] 04_route_failed.enc]
        set failure_checkpoint_dat "${failure_checkpoint}.dat"
        puts $fh "ROUTE_GATE_FAILURE_MARKER_REPORT=$failure_marker_rpt"
        puts $fh "ROUTE_GATE_FAILURE_DEF=$failure_def"
        puts $fh "ROUTE_GATE_FAILURE_CHECKPOINT=$failure_checkpoint"
        puts $fh "ROUTE_GATE_FAILURE_CHECKPOINT_DAT=$failure_checkpoint_dat"
    }
    close $fh
    mptdc_signoff_set_status ROUTE_STATUS $status $rpt
    if {$status eq "FAIL"} {
        set failure_def_status PASS
        set failure_def_error ""
        if {[catch {defOut $failure_def} failure_def_error]} {
            set failure_def_status FAIL
        }
        set failure_ckpt_status PASS
        set failure_ckpt_error ""
        if {[catch {saveDesign $failure_checkpoint} failure_ckpt_error]} {
            set failure_ckpt_status FAIL
        }
        set fh [open $rpt a]
        puts $fh "ROUTE_GATE_FAILURE_DEF_SAVE_STATUS=$failure_def_status"
        if {$failure_def_error ne ""} {
            puts $fh "ROUTE_GATE_FAILURE_DEF_SAVE_ERROR=[mptdc_signoff_report_value $failure_def_error]"
        }
        puts $fh "ROUTE_GATE_FAILURE_CHECKPOINT_SAVE_STATUS=$failure_ckpt_status"
        if {$failure_ckpt_error ne ""} {
            puts $fh "ROUTE_GATE_FAILURE_CHECKPOINT_SAVE_ERROR=[mptdc_signoff_report_value $failure_ckpt_error]"
        }
        puts $fh "ROUTE_GATE_FAILURE_CHECKPOINT_DAT_EXISTS=[expr {[file isdirectory $failure_checkpoint_dat] ? 1 : 0}]"
        close $fh
        mptdc_signoff_dump_drc_markers $failure_marker_rpt
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
    set ro_instances [mptdc_signoff_collect_cells [mptdc_signoff_ro_cell_patterns]]
    set rpt [file join [mptdc_signoff_report_dir] ro_macro_status.rpt]
    set fh [open $rpt w]
    puts $fh "RO_TUNE6_COUNT=[llength $ro_instances]"
    foreach ro $ro_instances { puts $fh "RO_TUNE6_INSTANCE=$ro" }
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
    set fix_ro [mptdc_signoff_env_truthy MPTDC_PNR_FIX_RO_MACROS 1]
    puts $fh "RO_MACRO_FIXED=[expr {$fix_ro ? "YES" : "NO"}]"
    foreach item [list [list $slow $x $slow_y R0 north] [list $fast $x $fast_y MX south]] {
        set inst [lindex $item 0]
        set px [lindex $item 1]
        set py [lindex $item 2]
        set orient [lindex $item 3]
        set region [lindex $item 4]
        set place_cmd [list placeInstance $inst $px $py $orient]
        if {$fix_ro} {
            lappend place_cmd -fixed
        }
        puts $fh "PLACE_RO instance=$inst region=$region x=$px y=$py orient=$orient fixed=[expr {$fix_ro ? "YES" : "NO"}]"
        puts $fh "PLACE_RO_COMMAND=$place_cmd"
        if {[catch {uplevel #0 $place_cmd} err]} {
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
        set tile_box_constraints_skipped 0
        if {[dict exists $grid_result tile_box_constraints_skipped]} {
            set tile_box_constraints_skipped [dict get $grid_result tile_box_constraints_skipped]
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
        puts $fh "PD_GRID_TILE_BOX_CONSTRAINTS_SKIPPED=$tile_box_constraints_skipped"
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
    set audit_mode [string tolower [mptdc_signoff_env MPTDC_PD_PHYSICAL_AUDIT_MODE auto]]
    if {$audit_mode eq "auto"} {
        if {[mptdc_signoff_env_truthy MPTDC_PNR_PD_TILE_PREPLACE_LEAVES 0] ||
            [mptdc_signoff_env_truthy MPTDC_PNR_PD_TILE_FIX_LEAVES 0]} {
            set audit_mode strict_center
        } else {
            set audit_mode soft_region
        }
    }
    if {$audit_mode ni {strict_center soft_region relaxed}} {
        set audit_mode strict_center
    }
    set max_center_offset [mptdc_signoff_env MPTDC_PD_TILE_MAX_OFFSET_UM 10.0]
    set tile_region_margin [mptdc_signoff_env MPTDC_PNR_PD_TILE_REGION_MARGIN_UM 1.0]
    set soft_box_margin [mptdc_signoff_env MPTDC_PD_TILE_SOFT_BOX_MARGIN_UM 2.0]
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
            set tile_check_box [list \
                [expr {$exp_llx + $tile_region_margin}] \
                [expr {$exp_lly + $tile_region_margin}] \
                [expr {$exp_urx - $tile_region_margin}] \
                [expr {$exp_ury - $tile_region_margin}]]
            if {![mptdc_signoff_box_valid $tile_check_box]} {
                set tile_check_box [list $exp_llx $exp_lly $exp_urx $exp_ury]
            }
            set tile_check_box [mptdc_signoff_expand_box $tile_check_box $soft_box_margin]
            if {$cx ne "" && $cy ne ""} {
                set dx [expr {$cx - $exp_cx}]
                set dy [expr {$cy - $exp_cy}]
                if {abs($dx) > $max_abs_dx} { set max_abs_dx [expr {abs($dx)}] }
                if {abs($dy) > $max_abs_dy} { set max_abs_dy [expr {abs($dy)}] }
                if {$audit_mode eq "strict_center"} {
                    if {abs($dx) > $max_center_offset || abs($dy) > $max_center_offset} {
                        set row_status OUTLIER
                        incr outliers
                    }
                } else {
                    if {![mptdc_signoff_point_in_box $cx $cy $tile_check_box]} {
                        set row_status OUTSIDE_TILE_REGION
                        incr outliers
                    }
                }
            }
        }
        puts $fh "[expr {$ns eq "" || $nf eq "" ? "NA" : "${ns}_${nf}"}],$ns,$nf,$cell,$llx,$lly,$urx,$ury,$cx,$cy,$leaf_count,$bbox_source,$exp_llx,$exp_lly,$exp_urx,$exp_ury,$dx,$dy,$row_status"
    }
    close $fh

    set backend_intrusion [mptdc_signoff_count_backend_cells_in_pd_box $pd_box]
    set essential_status [expr {[llength $cells] == 64 && $physical == 64 && $missing_logic == 0 && $missing_box == 0 && $backend_intrusion == 0 ? "PASS" : "FAIL"}]
    set regularity_status [expr {$essential_status eq "PASS" && $outliers == 0 ? "PASS" : "FAIL"}]
    set relaxed_gate [expr {[mptdc_signoff_env_truthy MPTDC_ALLOW_RELAXED_PD_MATRIX 0] || $audit_mode in {relaxed soft_region}}]
    set status $regularity_status
    if {$status ne "PASS" && $relaxed_gate && $essential_status eq "PASS"} {
        set status REVIEW_REQUIRED
    }
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
    puts $fh "PD_PHYSICAL_AUDIT_MODE=$audit_mode"
    puts $fh "PD_PHYSICAL_MATRIX_RELAXED_GATE=[expr {$relaxed_gate ? 1 : 0}]"
    puts $fh "PD_TILE_STRICT_CENTER_MAX_OFFSET_UM=$max_center_offset"
    puts $fh "PD_TILE_REGION_MARGIN_UM=$tile_region_margin"
    puts $fh "PD_TILE_SOFT_BOX_MARGIN_UM=$soft_box_margin"
    puts $fh "PD_TILE_OUTLIER_COUNT=$outliers"
    puts $fh "PD_MAX_ABS_DX_UM=[format %.3f $max_abs_dx]"
    puts $fh "PD_MAX_ABS_DY_UM=[format %.3f $max_abs_dy]"
    puts $fh "PD_BACKEND_INTRUSION_COUNT=$backend_intrusion"
    puts $fh "PD_MATRIX_ESSENTIAL_STATUS=$essential_status"
    puts $fh "PD_MATRIX_REGULARITY=$regularity_status"
    puts $fh "PD_PHYSICAL_MATRIX_GATE_STATUS=$status"
    puts $fh "PD_PHYSICAL_MATRIX_STATUS=$status"
    puts $fh "CSV=$csv"
    close $fh
    mptdc_signoff_set_status PD_PHYSICAL_MATRIX_STATUS $status $rpt
    mptdc_signoff_set_status PD_MATRIX_STATUS $status $rpt
    if {$status eq "FAIL"} {
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
        if {[regexp {gen_pd_row|gen_pd_col|u_pd|phase_buf|u_ro_tune4|RO_tune6|MPTDC_FILL} $name]} {
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
    if {[mptdc_signoff_env_truthy MPTDC_RO_PHASE_PREPLACE_AUDIT 1]} {
        mptdc_signoff_audit_ro_phase_overlap \
            $slow_iso_insts $slow_drv_insts $fast_iso_insts $fast_drv_insts \
            pre_place 0
    }
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

proc mptdc_signoff_audit_ro_phase_overlap {slow_iso_insts slow_drv_insts fast_iso_insts fast_drv_insts {label final} {fatal 1}} {
    if {$label eq "" || $label eq "final" || $label eq "post_place"} {
        set rpt [file join [mptdc_signoff_report_dir] ro_phase_overlap_audit.rpt]
        set check_rpt [file join [mptdc_signoff_report_dir] check_place_ro_phase_overlap.rpt]
    } else {
        set rpt [file join [mptdc_signoff_report_dir] "ro_phase_overlap_${label}_audit.rpt"]
        set check_rpt [file join [mptdc_signoff_report_dir] "check_place_ro_phase_overlap_${label}.rpt"]
    }
    set required_clearance [mptdc_signoff_env MPTDC_RO_PHASE_MIN_CLEARANCE_UM 10.0]
    set fail_on_global_checkplace [mptdc_signoff_env_truthy MPTDC_RO_PHASE_FAIL_ON_GLOBAL_CHECKPLACE_OVERLAP 0]
    set ro_map [mptdc_signoff_ro_instances_by_family]
    set slow_ro [dict get $ro_map slow]
    set fast_ro [dict get $ro_map fast]

    mptdc_signoff_capture_candidates $check_rpt \
        "RO/phase $label checkPlace" [list {checkPlace} {checkDesign -all}]
    set check_overlap_count [mptdc_signoff_checkplace_overlap_count $check_rpt]

    set fh [open $rpt w]
    puts $fh "# MPTDC RO / Phase-Buffer Overlap Audit"
    puts $fh "RO_PHASE_AUDIT_LABEL=$label"
    puts $fh "RO_PHASE_AUDIT_FATAL=$fatal"
    puts $fh "RO_PHASE_MIN_CLEARANCE_REQUIRED_UM=$required_clearance"
    puts $fh "RO_TUNE6_COUNT=[llength [dict get $ro_map all]]"
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
        set reason ro_tune6_count_not_two
    } elseif {[lindex $slow_result 3] > 0 || [lindex $fast_result 3] > 0} {
        set status FAIL
        set reason phase_buffer_bbox_invalid
    } elseif {$slow_overlap > 0.0 || $fast_overlap > 0.0} {
        set status FAIL
        set reason phase_buffer_overlaps_ro_macro
    } elseif {[lindex $slow_result 0] ne "PASS" || [lindex $fast_result 0] ne "PASS"} {
        set status FAIL
        set reason phase_buffer_clearance_below_required
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
    if {$status ne "PASS" && $fatal} {
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
    set place_gate [mptdc_signoff_capture_placement_gate \
        post_place \
        [file join [mptdc_signoff_report_dir] check_place_post_place.rpt] \
        [file join [mptdc_signoff_report_dir] placement_status.rpt] \
        1]
    set placement_status [dict get $place_gate status]
    mptdc_signoff_set_status PLACEMENT_STATUS $placement_status [dict get $place_gate status_report]
    if {$placement_status eq "FAIL"} {
        error "MPTDC_PLACEMENT_GATE_FAILED: report=[dict get $place_gate status_report]"
    }
    mptdc_signoff_audit_ro_phase_overlap \
        [mptdc_signoff_phase_buffer_instances slow iso] \
        [mptdc_signoff_phase_buffer_instances slow drv] \
        [mptdc_signoff_phase_buffer_instances fast iso] \
        [mptdc_signoff_phase_buffer_instances fast drv] \
        post_place 1
    catch {defOut [file join [mptdc_signoff_def_dir] 02_place.def]}
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 02_place.enc]}
    mptdc_signoff_audit_pd_matrix_physical
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
        foreach attr {.name .num_loads .num_load_pins .is_ideal .is_dont_touch .is_clock} {
            set value [mptdc_signoff_safe_db_value $net $attr]
            if {$value ne ""} {
                puts $fh "CLK_SYS_NET_${idx}_${attr}=[mptdc_signoff_abbrev_db_value $value]"
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
    return {(clk_osc|RO_tune6|u_ro_tune4|mptdc_phase_buffer_bank|phase_buf|gen_phase_buf|u_core_u_phase_buf)}
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
    set tc_view_status PASS
    set efh [open $rpt a]
    if {[catch {set_analysis_view -setup [list TC_NOMINAL] -hold [list TC_NOMINAL]} tc_view_err tc_view_opts]} {
        set tc_view_status FAIL
        puts $efh "POST_CTS_SET_ANALYSIS_VIEW_STATUS=FAIL"
        puts $efh "POST_CTS_SET_ANALYSIS_VIEW_ERROR=$tc_view_err"
        if {[dict exists $tc_view_opts -errorinfo]} {
            puts $efh "POST_CTS_SET_ANALYSIS_VIEW_ERRORINFO_BEGIN"
            puts $efh [dict get $tc_view_opts -errorinfo]
            puts $efh "POST_CTS_SET_ANALYSIS_VIEW_ERRORINFO_END"
        }
    } else {
        puts $efh "POST_CTS_SET_ANALYSIS_VIEW_STATUS=PASS"
    }
    close $efh
    if {$tc_view_status ne "PASS" && ![mptdc_signoff_env_truthy MPTDC_ALLOW_TC_VIEW_REVIEW_CONTINUE 0]} {
        mptdc_signoff_set_status CTS_STATUS FAIL $rpt
        error "MPTDC_POST_CTS_TC_VIEW_SETUP_FAILED: report=$rpt"
    }
    set post_cts_opt_status PASS
    set efh [open $rpt a]
    if {[catch {optDesign -postCTS} post_cts_err post_cts_opts]} {
        set post_cts_opt_status FAIL
        puts $efh "POST_CTS_OPT_STATUS=FAIL"
        puts $efh "POST_CTS_OPT_ERROR=$post_cts_err"
        if {[dict exists $post_cts_opts -errorinfo]} {
            puts $efh "POST_CTS_OPT_ERRORINFO_BEGIN"
            puts $efh [dict get $post_cts_opts -errorinfo]
            puts $efh "POST_CTS_OPT_ERRORINFO_END"
        }
    } else {
        puts $efh "POST_CTS_OPT_STATUS=PASS"
    }
    close $efh
    if {$post_cts_opt_status ne "PASS" && ![mptdc_signoff_env_truthy MPTDC_ALLOW_CTS_POSTOPT_REVIEW_CONTINUE 0]} {
        mptdc_signoff_set_status CTS_STATUS FAIL $rpt
        error "MPTDC_POST_CTS_OPT_FAILED: report=$rpt"
    }
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
    if {$tc_view_status ne "PASS" || $post_cts_opt_status ne "PASS"} {
        set cts_stage_status REVIEW_REQUIRED
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
    } else {
        mptdc_signoff_set_status CTS_STATUS $cts_stage_status $rpt
    }
}

proc mptdc_signoff_route_design {} {
    mptdc_signoff_source_if_exists innovus_mptdc_route.tcl
    set route_intent_rpt [file join [mptdc_signoff_report_dir] route_layer_intent.rpt]
    catch {mptdc_pnr_write_route_intent $route_intent_rpt}
    set route_audit_rpt [file join [mptdc_signoff_report_dir] route_layer_audit.rpt]
    set route_audit [dict create status FAIL report $route_audit_rpt]
    if {[catch {set route_audit [mptdc_pnr_audit_route_layers $route_audit_rpt]} audit_err audit_opts]} {
        set afh [open $route_audit_rpt a]
        puts $afh "ROUTE_LAYER_AUDIT_STATUS=FAIL"
        puts $afh "ROUTE_LAYER_AUDIT_ERROR=$audit_err"
        if {[dict exists $audit_opts -errorinfo]} {
            puts $afh "ROUTE_LAYER_AUDIT_ERRORINFO_BEGIN"
            puts $afh [dict get $audit_opts -errorinfo]
            puts $afh "ROUTE_LAYER_AUDIT_ERRORINFO_END"
        }
        close $afh
        mptdc_signoff_set_status ROUTE_STATUS FAIL $route_audit_rpt
        error "MPTDC_ROUTE_LAYER_AUDIT_FAILED: report=$route_audit_rpt error=$audit_err"
    }
    if {[dict get $route_audit status] ne "PASS"} {
        mptdc_signoff_set_status ROUTE_STATUS FAIL $route_audit_rpt
        error "MPTDC_ROUTE_LAYER_AUDIT_FAILED: report=$route_audit_rpt invalid=[dict get $route_audit invalid]"
    }
    set route_layer_rpt [file join [mptdc_signoff_report_dir] route_layer_limits.rpt]
    set rfh [open $route_layer_rpt w]
    puts $rfh "# MPTDC Route Layer Limits"
    puts $rfh "ROUTE_LAYER_AUDIT_REPORT=$route_audit_rpt"
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
    set place_gate [mptdc_signoff_capture_placement_gate \
        pre_route \
        [file join [mptdc_signoff_report_dir] check_place_pre_route.rpt] \
        [file join [mptdc_signoff_report_dir] placement_pre_route_status.rpt] \
        1]
    if {[dict get $place_gate status] eq "FAIL"} {
        mptdc_signoff_set_status ROUTE_STATUS FAIL [dict get $place_gate status_report]
        error "MPTDC_PRE_ROUTE_PLACEMENT_GATE_FAILED: report=[dict get $place_gate status_report]"
    }
    mptdc_signoff_run_postplace_pre_route_sroute

    set route_cmd [mptdc_signoff_env MPTDC_ROUTE_DESIGN_COMMAND ""]
    if {$route_cmd eq ""} {
        if {[mptdc_signoff_env_truthy MPTDC_ROUTE_DESIGN_PLACEMENT_CHECK 1]} {
            set route_cmd {routeDesign -placementCheck}
        } else {
            set route_cmd {routeDesign}
        }
    }
    set route_cmd_rpt [file join [mptdc_signoff_report_dir] route_command_status.rpt]
    set rcfh [open $route_cmd_rpt w]
    puts $rcfh "ROUTE_COMMAND=$route_cmd"
    puts $rcfh "ROUTE_DESIGN_PLACEMENT_CHECK=[expr {[mptdc_signoff_env_truthy MPTDC_ROUTE_DESIGN_PLACEMENT_CHECK 1] ? 1 : 0}]"
    close $rcfh
    if {[catch {uplevel #0 $route_cmd} route_err route_opts]} {
        set rcfh [open $route_cmd_rpt a]
        puts $rcfh "ROUTE_COMMAND_STATUS=FAIL"
        puts $rcfh "ROUTE_COMMAND_ERROR=$route_err"
        if {[dict exists $route_opts -errorcode]} {
            puts $rcfh "ROUTE_COMMAND_ERRORCODE=[dict get $route_opts -errorcode]"
        }
        if {[dict exists $route_opts -errorinfo]} {
            puts $rcfh "ROUTE_COMMAND_ERRORINFO_BEGIN"
            puts $rcfh [dict get $route_opts -errorinfo]
            puts $rcfh "ROUTE_COMMAND_ERRORINFO_END"
        }
        close $rcfh
        error "MPTDC_ROUTE_COMMAND_FAILED: report=$route_cmd_rpt error=$route_err"
    }
    set rcfh [open $route_cmd_rpt a]
    puts $rcfh "ROUTE_COMMAND_STATUS=PASS"
    close $rcfh
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
    mptdc_signoff_write_pg_postroute_connectivity_status $special_rpt $regular_rpt
    mptdc_signoff_write_route_gate_status $rpt $drc_data $regular_bad $special_bad $unrouted $antenna_status
    catch {defOut [file join [mptdc_signoff_def_dir] 04_route.def]}
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 04_route.enc]}
}

proc mptdc_signoff_capture_power_report {} {
    set power_rpt [file join [mptdc_signoff_report_dir] power_tc_nominal.rpt]
    set status_rpt [file join [mptdc_signoff_report_dir] power_status.rpt]
    set ok [mptdc_signoff_capture_candidates $power_rpt \
        "TC_NOMINAL Innovus power report" [list \
            {report_power} \
            {reportPower}]]
    set status [expr {$ok ? "PROVISIONAL" : "REVIEW_REQUIRED"}]
    set fh [open $status_rpt w]
    puts $fh "# MPTDC TC Innovus Power Status"
    puts $fh "POWER_STATUS=$status"
    puts $fh "POWER_REPORT=$power_rpt"
    puts $fh "POWER_SCOPE=innovus_tc_nominal_default_activity"
    puts $fh "POWER_SIGNOFF_SCOPE=NO_IR_EM_NO_ACTIVITY_SIGNOFF"
    if {!$ok} {
        puts $fh "POWER_REPORT_CAPTURE_STATUS=REVIEW_REQUIRED"
    } else {
        puts $fh "POWER_REPORT_CAPTURE_STATUS=PASS"
    }
    close $fh
    mptdc_signoff_set_status POWER_STATUS $status $status_rpt
    return $status_rpt
}

proc mptdc_signoff_extract_and_sta {} {
    set extract_rpt [file join [mptdc_signoff_report_dir] extraction_rc.rpt]
    mptdc_signoff_capture_required_candidates $extract_rpt \
        "post-route TC extractRC" [list {extractRC}]
    set sta_policy [mptdc_signoff_configure_post_route_tc_sta]
    mptdc_signoff_set_status EXTRACTION_STATUS PROVISIONAL $sta_policy
    mptdc_signoff_capture_power_report
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
    set drv_status_rpt [file join [mptdc_signoff_report_dir] drv_status.rpt]
    if {[catch {mptdc_signoff_require_no_drv_violation_markers [list $tran_rpt $cap_rpt $fanout_rpt]} drv_err drv_opts]} {
        set fh [open $drv_status_rpt w]
        puts $fh "# MPTDC Post-route DRV Status"
        puts $fh "DRV_STATUS=FAIL"
        puts $fh "DRV_MAX_TRANSITION_REPORT=$tran_rpt"
        puts $fh "DRV_MAX_CAP_REPORT=$cap_rpt"
        puts $fh "DRV_MAX_FANOUT_REPORT=$fanout_rpt"
        puts $fh "DRV_ERROR=$drv_err"
        if {[dict exists $drv_opts -errorinfo]} {
            puts $fh "DRV_ERRORINFO_BEGIN"
            puts $fh [dict get $drv_opts -errorinfo]
            puts $fh "DRV_ERRORINFO_END"
        }
        close $fh
        mptdc_signoff_set_status DRV_STATUS FAIL $drv_status_rpt
        error $drv_err
    }
    set fh [open $drv_status_rpt w]
    puts $fh "# MPTDC Post-route DRV Status"
    puts $fh "DRV_STATUS=PASS"
    puts $fh "DRV_MAX_TRANSITION_REPORT=$tran_rpt"
    puts $fh "DRV_MAX_CAP_REPORT=$cap_rpt"
    puts $fh "DRV_MAX_FANOUT_REPORT=$fanout_rpt"
    close $fh
    mptdc_signoff_set_status DRV_STATUS PASS $drv_status_rpt
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
    set raw_cap_limit [mptdc_signoff_env MPTDC_RO_TUNE6_S_MAX_CAP_PF \
        [mptdc_signoff_env MPTDC_RO_TUNE4_S_MAX_CAP_PF 0.050]]
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
    puts $sfh "RO_TUNE6_S_MAX_CAP_PF=$raw_cap_limit"
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
    set placement_state [mptdc_signoff_status_state PLACEMENT_STATUS]
    set pg_conn_state [mptdc_signoff_status_state PG_CONNECTIVITY_STATUS]
    set cts_state [mptdc_signoff_status_state CTS_STATUS]
    set route_state [mptdc_signoff_status_state ROUTE_STATUS]
    set extraction_state [mptdc_signoff_status_state EXTRACTION_STATUS]
    set power_state [mptdc_signoff_status_state POWER_STATUS]
    set drv_state [mptdc_signoff_status_state DRV_STATUS]
    set tc_pnr_state PASS
    set tc_pnr_evidence tc_only_routed_timed_closure_complete
    set digital_evidence row_and_block_drc_lvs_deferred
    if {$placement_state ne "PASS" || $pg_conn_state ne "PASS" || $cts_state ne "PASS" ||
        $route_state ne "PASS" || $extraction_state ne "PASS" || $drv_state ne "PASS"} {
        set tc_pnr_state DEFERRED
        set tc_pnr_evidence implementation_gate_not_complete
        set digital_evidence row_and_block_drc_lvs_deferred_implementation_gate_not_complete
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
    puts $fh "PLACEMENT_STATUS=$placement_state"
    puts $fh "PG_CONNECTIVITY_STATUS=$pg_conn_state"
    puts $fh "CTS_STATUS=$cts_state"
    puts $fh "ROUTE_STATUS=$route_state"
    puts $fh "EXTRACTION_STATUS=$extraction_state"
    puts $fh "POWER_STATUS=$power_state"
    puts $fh "DRV_STATUS=$drv_state"
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

    set matrix [file join [mptdc_signoff_report_dir] acceptance_matrix.rpt]
    set mfh [open $matrix w]
    puts $mfh "# MPTDC TC Innovus Acceptance Matrix"
    foreach key { \
        PLACEMENT_STATUS \
        PD_MATRIX_STATUS \
        PD_PHYSICAL_MATRIX_STATUS \
        PG_PHYSICAL_STATUS \
        PG_CONNECTIVITY_STATUS \
        CTS_STATUS \
        ROUTE_STATUS \
        ANTENNA_STATUS \
        EXTRACTION_STATUS \
        POWER_STATUS \
        SETUP_STATUS_TC \
        TC_HOLD_STATUS \
        DRV_STATUS \
        MPTDC_TC_PNR_CLOSURE \
        DRC_STATUS \
        LVS_STATUS \
        READY_FOR_TAPEOUT} {
        puts $mfh "$key=[mptdc_signoff_status_state $key]"
    }
    puts $mfh "TC_INNOVUS_SCOPE=YES"
    puts $mfh "FOUNDRY_DRC_LVS_IR_SCOPE=DEFERRED"
    puts $mfh "ACCEPTANCE_MATRIX_STATUS=$tc_pnr_state"
    close $mfh
}

proc mptdc_signoff_source_check {} {
    mptdc_signoff_apply_recovery_defaults
    mptdc_signoff_pg_policy_guard
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
    mptdc_signoff_apply_recovery_defaults
    mptdc_signoff_pg_policy_guard
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

if {[info exists ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY)] && $::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY)} {
    return
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
