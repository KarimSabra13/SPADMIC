# =============================================================================
# MPTDC clk_sys-only CTS validate/debug script
#
# Default behavior is validate-only:
#   - restore or use the current Innovus design
#   - inventory clocks and phase/RO objects
#   - generate a CCOpt spec if the Innovus version supports it
#   - audit the spec text for clk_sys-only safety
#   - do not run ccopt_design unless explicitly requested and the audit is clean
#
# This script must never be used as a generic CCOpt fallback.
# =============================================================================

proc mptdc_cts_dbg_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_cts_dbg_msg {msg} {
    puts "MPTDC_CTS_CLK_SYS_ONLY_DEBUG: $msg"
}

proc mptdc_cts_dbg_setup {} {
    global ctsdbg

    set script_dir [file dirname [file normalize [info script]]]
    set pnr_root [file dirname $script_dir]
    set mptdc_root [file dirname $pnr_root]
    set repo_root [file dirname $mptdc_root]

    set default_result_dir [file normalize [file join [pwd] cts_clk_sys_only_debug]]
    set ctsdbg(script_dir) $script_dir
    set ctsdbg(repo_root) $repo_root
    set ctsdbg(result_dir) [mptdc_cts_dbg_env MPTDC_CTS_DEBUG_RESULT_DIR $default_result_dir]
    set ctsdbg(reports_dir) "$ctsdbg(result_dir)/reports"
    set ctsdbg(work_dir) "$ctsdbg(result_dir)/work"
    set ctsdbg(checkpoint_dat) [mptdc_cts_dbg_env MPTDC_CTS_DEBUG_CHECKPOINT_DAT ""]
    set ctsdbg(restore_tcl) [mptdc_cts_dbg_env MPTDC_CTS_DEBUG_RESTORE_TCL ""]
    set ctsdbg(run_ccopt) [mptdc_cts_dbg_env MPTDC_CTS_DEBUG_RUN_CCOPT 0]
    set ctsdbg(status) "CTS_SKIPPED_NO_SAFE_CLK_SYS_ONLY_COMMAND"
    set ctsdbg(primary_clock) "clk_sys"
    set ctsdbg(forbidden_regex) {(clk_osc|RO_tune4|u_ro_tune4|phase_buf|gen_phase_buf|BUHDX4|BUHDX12|u_core_u_phase_buf)}

    file mkdir $ctsdbg(reports_dir)
    file mkdir $ctsdbg(work_dir)
}

proc mptdc_cts_dbg_object_names {objects} {
    set names [list]
    if {[llength $objects] == 0} {
        return $names
    }
    if {![catch {get_object_name $objects} obj_names]} {
        foreach name $obj_names { lappend names $name }
        return $names
    }
    if {![catch {get_db $objects .name} obj_names]} {
        foreach name $obj_names { lappend names $name }
        return $names
    }
    foreach obj $objects { lappend names $obj }
    return $names
}

proc mptdc_cts_dbg_restore_design {} {
    global ctsdbg

    if {$ctsdbg(checkpoint_dat) ne "" && [file exists $ctsdbg(checkpoint_dat)]} {
        mptdc_cts_dbg_msg "Restoring checkpoint: $ctsdbg(checkpoint_dat)"
        restoreDesign $ctsdbg(checkpoint_dat) mptdc_top_asic
        return "RESTORED_CHECKPOINT_DAT"
    }
    if {$ctsdbg(restore_tcl) ne "" && [file exists $ctsdbg(restore_tcl)]} {
        mptdc_cts_dbg_msg "Restoring through Tcl: $ctsdbg(restore_tcl)"
        source $ctsdbg(restore_tcl)
        return "RESTORED_RESTORE_TCL"
    }
    mptdc_cts_dbg_msg "No restore input provided; auditing current Innovus session"
    return "USED_CURRENT_SESSION"
}

proc mptdc_cts_dbg_all_clock_names {} {
    set clocks [list]
    if {[llength [info commands all_clocks]] > 0} {
        catch {set clocks [all_clocks]}
    }
    if {[llength $clocks] == 0} {
        catch {set clocks [get_clocks *]}
    }
    return [mptdc_cts_dbg_object_names $clocks]
}

proc mptdc_cts_dbg_collect_cell_names {patterns} {
    set names [list]
    foreach pattern $patterns {
        set cells [list]
        catch {set cells [get_cells -hierarchical -quiet $pattern]}
        foreach name [mptdc_cts_dbg_object_names $cells] {
            if {[lsearch -exact $names $name] < 0} {
                lappend names $name
            }
        }
    }
    return $names
}

proc mptdc_cts_dbg_collect_pin_names {patterns} {
    set names [list]
    foreach pattern $patterns {
        set pins [list]
        catch {set pins [get_pins -hierarchical -quiet $pattern]}
        foreach name [mptdc_cts_dbg_object_names $pins] {
            if {[lsearch -exact $names $name] < 0} {
                lappend names $name
            }
        }
    }
    return $names
}

proc mptdc_cts_dbg_write_clock_inventory {restore_status} {
    global ctsdbg

    set clock_names [mptdc_cts_dbg_all_clock_names]
    set fh [open "$ctsdbg(reports_dir)/cts_clock_inventory.rpt" w]
    puts $fh "# MPTDC clk_sys-only CTS clock inventory"
    puts $fh "restore_status=$restore_status"
    puts $fh "primary_clock=$ctsdbg(primary_clock)"
    puts $fh "clock_count=[llength $clock_names]"
    puts $fh ""
    foreach clk $clock_names {
        set class "EXCLUDED_OR_UNKNOWN"
        if {$clk eq $ctsdbg(primary_clock)} {
            set class "INCLUDE_CTS_TARGET"
        } elseif {[regexp {clk_osc|tap|phase|RO_tune4} $clk]} {
            set class "EXCLUDE_RO_OR_PHASE"
        }
        puts $fh "$class $clk"
    }
    close $fh
    return $clock_names
}

proc mptdc_cts_dbg_write_object_guard {} {
    global ctsdbg

    set phase_cells [mptdc_cts_dbg_collect_cell_names [list *phase_buf* *gen_phase_buf* *u_core_u_phase_buf*]]
    set ro_pins [mptdc_cts_dbg_collect_pin_names [list *u_ro_tune4*/S* *RO_tune4*/S*]]

    set fh [open "$ctsdbg(reports_dir)/cts_object_guard.rpt" w]
    puts $fh "# MPTDC clk_sys-only CTS object guard"
    puts $fh "phase_buffer_cell_count=[llength $phase_cells]"
    puts $fh "ro_tune4_s_pin_count=[llength $ro_pins]"
    puts $fh ""
    puts $fh "Phase-buffer cells must not be CTS roots/sinks:"
    foreach name [lrange $phase_cells 0 255] { puts $fh "- $name" }
    puts $fh ""
    puts $fh "RO_tune4/S pins must not be CTS roots/sinks:"
    foreach name [lrange $ro_pins 0 255] { puts $fh "- $name" }
    close $fh
}

proc mptdc_cts_dbg_create_and_audit_spec {} {
    global ctsdbg

    set spec_path "$ctsdbg(work_dir)/clk_sys_only_debug.spec"
    set audit_path "$ctsdbg(reports_dir)/cts_clk_sys_only_spec_audit.rpt"
    set spec_created 0
    set spec_text ""
    set create_error ""
    set cmd [list create_ccopt_clock_tree_spec -file $spec_path]

    if {[catch {{*}$cmd} create_error]} {
        set spec_created 0
    } else {
        set spec_created 1
    }
    if {$spec_created && [file exists $spec_path]} {
        set sfh [open $spec_path r]
        set spec_text [read $sfh]
        close $sfh
    }

    set has_clk_sys [regexp {clk_sys} $spec_text]
    set has_forbidden [regexp $ctsdbg(forbidden_regex) $spec_text]
    set status "CTS_SKIPPED_NO_SAFE_CLK_SYS_ONLY_COMMAND"
    if {!$spec_created} {
        set status "CTS_SKIPPED_NO_SAFE_CLK_SYS_ONLY_COMMAND"
    } elseif {!$has_clk_sys} {
        set status "CTS_SKIPPED_NO_SAFE_CLK_SYS_ONLY_COMMAND"
    } elseif {$has_forbidden} {
        if {[regexp {clk_osc|RO_tune4|u_ro_tune4} $spec_text]} {
            set status "RO_CLOCKS_IN_CTS"
        } else {
            set status "PHASE_CLOCKS_IN_CTS"
        }
    } else {
        set status "SPEC_AUDIT_CLK_SYS_ONLY"
    }

    set fh [open $audit_path w]
    puts $fh "# MPTDC clk_sys-only CTS spec audit"
    puts $fh "spec_command=$cmd"
    puts $fh "spec_path=$spec_path"
    puts $fh "spec_created=$spec_created"
    if {$create_error ne "" && !$spec_created} {
        puts $fh "create_error=$create_error"
    }
    puts $fh "has_clk_sys=$has_clk_sys"
    puts $fh "has_forbidden_ro_or_phase=$has_forbidden"
    puts $fh "forbidden_regex=$ctsdbg(forbidden_regex)"
    puts $fh "audit_status=$status"
    puts $fh "run_ccopt_requested=$ctsdbg(run_ccopt)"
    puts $fh ""
    puts $fh "Rejected statuses: GENERIC_CCOPT_USED, RO_CLOCKS_IN_CTS, PHASE_CLOCKS_IN_CTS, CTS_AMBIGUOUS_BUT_RAN_ANYWAY."
    puts $fh "This audit is validate-only unless MPTDC_CTS_DEBUG_RUN_CCOPT=1 and audit_status=SPEC_AUDIT_CLK_SYS_ONLY."
    close $fh

    set ctsdbg(status) $status
    return [list $status $spec_path]
}

proc mptdc_cts_dbg_write_status {status spec_path detail} {
    global ctsdbg

    set fh [open "$ctsdbg(reports_dir)/cts_status.rpt" w]
    puts $fh "MPTDC_CLK_SYS_CTS_ONLY_DEBUG_STATUS=$status"
    puts $fh "CTS_PRIMARY_CLOCK=$ctsdbg(primary_clock)"
    puts $fh "SPEC_PATH=$spec_path"
    puts $fh "DETAIL=$detail"
    puts $fh "GENERIC_CCOPT_USED=NO"
    puts $fh "RO_CLOCKS_ALLOWED_IN_CTS=NO"
    puts $fh "PHASE_CLOCKS_ALLOWED_IN_CTS=NO"
    puts $fh "NOT_SIGNOFF=YES"
    close $fh
}

proc mptdc_cts_dbg_main {} {
    global ctsdbg
    mptdc_cts_dbg_setup
    set restore_status [mptdc_cts_dbg_restore_design]
    mptdc_cts_dbg_write_clock_inventory $restore_status
    mptdc_cts_dbg_write_object_guard
    set audit [mptdc_cts_dbg_create_and_audit_spec]
    set status [lindex $audit 0]
    set spec_path [lindex $audit 1]

    if {$status eq "SPEC_AUDIT_CLK_SYS_ONLY" && $ctsdbg(run_ccopt) == 1} {
        if {[catch {ccopt_design} err]} {
            set status "CTS_SKIPPED_NO_SAFE_CLK_SYS_ONLY_COMMAND"
            mptdc_cts_dbg_write_status $status $spec_path "ccopt_design_failed=$err"
            return 1
        }
        set status "CLK_SYS_ONLY_CTS_COMPLETE"
        mptdc_cts_dbg_write_status $status $spec_path "ccopt_design_complete"
        catch {report_clocks > "$ctsdbg(reports_dir)/report_clocks_after_cts.rpt"}
        catch {reportClockTree -summary > "$ctsdbg(reports_dir)/clock_tree_summary_after_cts.rpt"}
        return 0
    }

    if {$status eq "SPEC_AUDIT_CLK_SYS_ONLY"} {
        mptdc_cts_dbg_write_status "CTS_SKIPPED_NO_SAFE_CLK_SYS_ONLY_COMMAND" $spec_path "validate_only_spec_clean_no_ccopt_run"
        return 0
    }

    mptdc_cts_dbg_write_status $status $spec_path "unsafe_or_unavailable_spec_no_ccopt_run"
    return 2
}

if {![info exists ::env(MPTDC_CTS_DEBUG_SOURCE_ONLY)] || $::env(MPTDC_CTS_DEBUG_SOURCE_ONLY) ne "1"} {
    exit [mptdc_cts_dbg_main]
}
