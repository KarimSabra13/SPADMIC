# =============================================================================
# Project  : SPAD_MPTDC
# File     : innovus_mptdc_route_checkpoint_repair.tcl
# Purpose  : Restore an Innovus route checkpoint, run targeted repair commands,
#            and capture DRC/connectivity evidence without a full rerun.
# =============================================================================

proc mptdc_ckpt_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_ckpt_required_env {name} {
    set value [mptdc_ckpt_env $name ""]
    if {$value eq ""} {
        error "missing required environment variable $name"
    }
    return $value
}

proc mptdc_ckpt_write_text {path text} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts -nonewline $fh $text
    close $fh
}

proc mptdc_ckpt_sanitize {value} {
    regsub -all {[^[:alnum:]_./:+-]+} $value {_} safe
    set safe [string trim $safe _]
    if {$safe eq ""} {
        set safe command
    }
    return $safe
}

proc mptdc_ckpt_command_is_helper {command} {
    if {[catch {set head [lindex $command 0]}]} {
        return 0
    }
    return [string match "mptdc_ckpt_*" $head]
}

proc mptdc_ckpt_capture {label command path} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "# $label"
    puts $fh "COMMAND=$command"
    close $fh
    set is_helper [mptdc_ckpt_command_is_helper $command]
    if {$is_helper} {
        set invoke $command
    } else {
        set invoke "$command >> \"$path\""
    }
    if {[catch {uplevel #0 $invoke} result opts]} {
        set fh [open $path a]
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh "ERROR=$result"
        if {[dict exists $opts -errorcode]} {
            puts $fh "ERRORCODE=[dict get $opts -errorcode]"
        }
        if {[dict exists $opts -errorinfo]} {
            puts $fh "ERRORINFO_BEGIN"
            puts $fh [dict get $opts -errorinfo]
            puts $fh "ERRORINFO_END"
        }
        close $fh
        return [list 0 $result]
    }
    set fh [open $path a]
    if {$is_helper} {
        puts $fh "HELPER_RESULT=$result"
    }
    puts $fh "REPORT_STATUS=PASS"
    close $fh
    return [list 1 ""]
}

proc mptdc_ckpt_command_file_commands {path} {
    if {$path eq ""} {
        return {}
    }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    set commands {}
    foreach line [split $text "\n"] {
        set trimmed [string trim $line]
        if {$trimmed eq ""} {
            continue
        }
        if {[string index $trimmed 0] eq "#"} {
            continue
        }
        lappend commands $trimmed
    }
    return $commands
}

proc mptdc_ckpt_env_commands {} {
    set raw [mptdc_ckpt_env MPTDC_CHECKPOINT_REPAIR_COMMANDS ""]
    if {$raw eq ""} {
        return {}
    }
    if {![catch {llength $raw}]} {
        return $raw
    }
    return [list $raw]
}

proc mptdc_ckpt_continue_after_command_fail {} {
    return [mptdc_ckpt_env MPTDC_CHECKPOINT_REPAIR_KEEP_GOING 0]
}

proc mptdc_ckpt_select_nets {nets} {
    if {[llength $nets] == 0} {
        error "mptdc_ckpt_select_nets requires at least one net"
    }
    catch {deselectAll}
    set selected {}
    set failures {}
    foreach net $nets {
        set net [string trim $net]
        if {$net eq ""} {
            continue
        }
        if {[catch {selectNet $net} err]} {
            lappend failures "$net:$err"
        } else {
            lappend selected $net
        }
    }
    puts "MPTDC_CKPT_SELECTED_NETS=[join $selected { }]"
    if {[llength $failures] > 0} {
        error "mptdc_ckpt_select_nets failed: [join $failures {; }]"
    }
    if {[llength $selected] == 0} {
        error "mptdc_ckpt_select_nets selected zero nets"
    }
    return $selected
}

proc mptdc_ckpt_route_selected_nets_with_commands {nets route_commands route_label} {
    set selected [mptdc_ckpt_select_nets $nets]
    puts "MPTDC_CKPT_ROUTE_SELECTED_NET_COUNT=[llength $selected]"
    puts "MPTDC_CKPT_ROUTE_SELECTED_STRATEGY=$route_label"

    # The via-in-pin route modes exposed by Innovus make this checkpoint report
    # thousands of Via_In_Pin DRCs on already-routed std-cell nets. Keep this
    # surgical repair on the selected-net path only.
    catch {setNanoRouteMode -route_with_via_in_pin false}
    catch {setNanoRouteMode -route_with_via_only_for_block_cell_pin false}

    if {[catch {setNanoRouteMode -route_selected_net_only true} err]} {
        error "failed to enable selected-net routing: $err"
    }

    set route_err ""
    set route_status [catch {
        foreach route_command $route_commands {
            puts ""
            puts $route_command
            uplevel #0 $route_command
        }
    } route_err]

    catch {setNanoRouteMode -route_selected_net_only false}
    if {$route_status} {
        error "selected-net route failed: $route_err"
    }
    catch {deselectAll}
    return $selected
}

proc mptdc_ckpt_route_selected_nets {nets} {
    return [mptdc_ckpt_route_selected_nets_with_commands \
        $nets \
        [list {globalDetailRoute -select} {detailRoute -select}] \
        global_detail_plus_detail]
}

proc mptdc_ckpt_route_selected_nets_route_design {nets} {
    return [mptdc_ckpt_route_selected_nets_with_commands \
        $nets \
        [list {routeDesign -selected}] \
        route_design_selected]
}

proc mptdc_ckpt_route_selected_nets_detail_only {nets} {
    return [mptdc_ckpt_route_selected_nets_with_commands \
        $nets \
        [list {detailRoute -select}] \
        detail_only_selected]
}

proc mptdc_ckpt_route_selected_nets_legacy {nets} {
    return [mptdc_ckpt_route_selected_nets_with_commands \
        $nets \
        [list {routeSelectedNet}] \
        route_selected_net_legacy]
}

proc mptdc_ckpt_delete_regular_net_area {net layer box} {
    if {[string trim $net] eq ""} {
        error "mptdc_ckpt_delete_regular_net_area requires a net"
    }
    if {[string trim $layer] eq ""} {
        error "mptdc_ckpt_delete_regular_net_area requires a layer"
    }
    if {[llength $box] != 4} {
        error "mptdc_ckpt_delete_regular_net_area requires box {x1 y1 x2 y2}"
    }
    puts "MPTDC_CKPT_DELETE_REGULAR_NET_AREA_NET=$net"
    puts "MPTDC_CKPT_DELETE_REGULAR_NET_AREA_LAYER=$layer"
    puts "MPTDC_CKPT_DELETE_REGULAR_NET_AREA_BOX=$box"
    editDelete -net $net -layer $layer -area $box -type Regular
    return $box
}

proc mptdc_ckpt_delete_regular_drc_wires {net} {
    if {[string trim $net] eq ""} {
        error "mptdc_ckpt_delete_regular_drc_wires requires a net"
    }
    puts "MPTDC_CKPT_DELETE_REGULAR_DRC_WIRES_NET=$net"
    editDelete -net $net -regular_wire_with_drc -type Regular
    return $net
}

proc mptdc_ckpt_assert_geometry_clean {} {
    global mptdc_ckpt_inline_assert_idx
    if {![info exists mptdc_ckpt_inline_assert_idx]} {
        set mptdc_ckpt_inline_assert_idx 0
    }
    incr mptdc_ckpt_inline_assert_idx
    set tag [format "inline_%02d_assert_geometry" $mptdc_ckpt_inline_assert_idx]
    set snapshot [mptdc_ckpt_verify_snapshot $tag]
    set total [dict get $snapshot total_violations]
    set shorts [dict get $snapshot shorts]
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_DRC=$total"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_SHORTS=$shorts"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REPORT=[dict get $snapshot drc_rpt]"
    if {$total eq "UNKNOWN" || $shorts eq "UNKNOWN" || $total != 0 || $shorts != 0} {
        error "geometry is not clean after checkpoint repair command: DRC=$total SHORTS=$shorts report=[dict get $snapshot drc_rpt]"
    }
    return $snapshot
}

proc mptdc_ckpt_assert_geometry_regular_clean {} {
    global mptdc_ckpt_inline_assert_idx
    if {![info exists mptdc_ckpt_inline_assert_idx]} {
        set mptdc_ckpt_inline_assert_idx 0
    }
    incr mptdc_ckpt_inline_assert_idx
    set tag [format "inline_%02d_assert_geometry_regular" $mptdc_ckpt_inline_assert_idx]
    set snapshot [mptdc_ckpt_verify_snapshot $tag]
    set total [dict get $snapshot total_violations]
    set shorts [dict get $snapshot shorts]
    set regular_bad [dict get $snapshot regular_bad]
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_DRC=$total"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_SHORTS=$shorts"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_BAD=$regular_bad"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_BAD_LINES=[dict get $snapshot regular_bad_lines]"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_SPECIAL_BAD=[dict get $snapshot special_bad]"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_REPORT=[dict get $snapshot drc_rpt]"
    if {$total eq "UNKNOWN" || $shorts eq "UNKNOWN" || $regular_bad eq "UNKNOWN" || $total != 0 || $shorts != 0 || $regular_bad != 0} {
        error "geometry/regular connectivity is not clean after checkpoint repair command: DRC=$total SHORTS=$shorts REGULAR_BAD=$regular_bad report=[dict get $snapshot drc_rpt]"
    }
    return $snapshot
}

proc mptdc_ckpt_verify_snapshot {tag} {
    set report_dir [mptdc_signoff_report_dir]
    set drc_rpt [file join $report_dir ${tag}_verify_drc.rpt]
    set regular_rpt [file join $report_dir ${tag}_verify_connectivity_regular.rpt]
    set special_rpt [file join $report_dir ${tag}_verify_connectivity_special.rpt]
    set report_route_rpt [file join $report_dir ${tag}_report_route.rpt]
    mptdc_signoff_capture_route_gate_reports $drc_rpt $regular_rpt $special_rpt $report_route_rpt
    lassign [mptdc_signoff_read_route_gate_reports \
        $drc_rpt $regular_rpt $special_rpt $report_route_rpt] drc_data regular_bad special_bad unrouted
    set marker_rpt [file rootname $drc_rpt]_markers.tsv
    if {[dict exists $drc_data marker_report]} {
        set marker_rpt [dict get $drc_data marker_report]
    }
    set unrouted_source UNKNOWN
    if {[dict exists $drc_data unrouted_source]} {
        set unrouted_source [dict get $drc_data unrouted_source]
    }
    set route_gate_pass [mptdc_signoff_route_gate_is_pass \
        $drc_data $regular_bad $special_bad $unrouted]
    return [dict create \
        drc_rpt $drc_rpt \
        regular_rpt $regular_rpt \
        special_rpt $special_rpt \
        report_route_rpt $report_route_rpt \
        marker_rpt $marker_rpt \
        total_violations [dict get $drc_data total_violations] \
        shorts [dict get $drc_data shorts] \
        drc_status [dict get $drc_data status] \
        regular_bad [lindex $regular_bad 0] \
        regular_bad_lines [lindex $regular_bad 1] \
        special_bad [lindex $special_bad 0] \
        special_bad_lines [lindex $special_bad 1] \
        special_raw_bad [lindex $special_bad 2] \
        special_filter_status [lindex $special_bad 3] \
        special_filtered_ro_terminals [lindex $special_bad 4] \
        special_non_ro_failures [lindex $special_bad 5] \
        special_filter_report [lindex $special_bad 6] \
        unrouted $unrouted \
        unrouted_source $unrouted_source \
        route_gate_pass $route_gate_pass]
}

proc mptdc_ckpt_write_snapshot_status {fh prefix snapshot} {
    puts $fh "${prefix}_DRC=[dict get $snapshot total_violations]"
    puts $fh "${prefix}_SHORTS=[dict get $snapshot shorts]"
    puts $fh "${prefix}_DRC_STATUS=[dict get $snapshot drc_status]"
    puts $fh "${prefix}_REGULAR_CONNECTIVITY_BAD=[dict get $snapshot regular_bad]"
    puts $fh "${prefix}_REGULAR_CONNECTIVITY_BAD_LINES=[dict get $snapshot regular_bad_lines]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_BAD=[dict get $snapshot special_bad]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_BAD_LINES=[dict get $snapshot special_bad_lines]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_RAW_BAD=[dict get $snapshot special_raw_bad]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_FILTER_STATUS=[dict get $snapshot special_filter_status]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_FILTERED_RO_TERMINALS=[dict get $snapshot special_filtered_ro_terminals]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=[dict get $snapshot special_non_ro_failures]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_FILTER_REPORT=[dict get $snapshot special_filter_report]"
    puts $fh "${prefix}_UNROUTED_NETS=[dict get $snapshot unrouted]"
    puts $fh "${prefix}_UNROUTED_NETS_SOURCE=[dict get $snapshot unrouted_source]"
    puts $fh "${prefix}_ROUTE_GATE_PASS=[dict get $snapshot route_gate_pass]"
    puts $fh "${prefix}_DRC_REPORT=[dict get $snapshot drc_rpt]"
    puts $fh "${prefix}_REGULAR_CONNECTIVITY_REPORT=[dict get $snapshot regular_rpt]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_REPORT=[dict get $snapshot special_rpt]"
    puts $fh "${prefix}_REPORT_ROUTE=[dict get $snapshot report_route_rpt]"
    puts $fh "${prefix}_MARKER_REPORT=[dict get $snapshot marker_rpt]"
}

if {[mptdc_ckpt_env MPTDC_CHECKPOINT_REPAIR_SOURCE_ONLY 0]} {
    return
}

set source_checkpoint [mptdc_ckpt_required_env MPTDC_CHECKPOINT_REPAIR_SOURCE_CHECKPOINT]
set result_dir [mptdc_ckpt_required_env MPTDC_SIGNOFF_RESULT_DIR]
set top_cell [mptdc_ckpt_env MPTDC_CHECKPOINT_REPAIR_TOP mptdc_axis_core]
set commands_file [mptdc_ckpt_env MPTDC_CHECKPOINT_REPAIR_COMMANDS_FILE ""]
set repo_root [file normalize [mptdc_ckpt_env MPTDC_REPO_ROOT [file join [file dirname [info script]] ../../..]]]

file mkdir $result_dir
set ::env(MPTDC_REPO_ROOT) $repo_root
set ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY) 1
source [file join [file dirname [info script]] innovus_mptdc_digital_signoff.tcl]
mptdc_signoff_mkdirs

set status_rpt [file join [mptdc_signoff_report_dir] checkpoint_repair_status.rpt]
set status_fh [open $status_rpt w]
puts $status_fh "# MPTDC Route Checkpoint Repair"
puts $status_fh "SOURCE_CHECKPOINT=$source_checkpoint"
puts $status_fh "RESULT_DIR=$result_dir"
puts $status_fh "TOP_CELL=$top_cell"
puts $status_fh "COMMANDS_FILE=$commands_file"
flush $status_fh

if {![file exists $source_checkpoint]} {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=FAIL"
    puts $status_fh "CHECKPOINT_REPAIR_REASON=missing_source_checkpoint"
    close $status_fh
    error "missing source checkpoint: $source_checkpoint"
}

puts "MPTDC_CHECKPOINT_REPAIR_RESTORE=$source_checkpoint"
restoreDesign $source_checkpoint $top_cell
catch {set_db get_db_display_limit 50000}

set command_list [mptdc_ckpt_command_file_commands $commands_file]
foreach cmd [mptdc_ckpt_env_commands] {
    lappend command_list $cmd
}
if {[llength $command_list] == 0} {
    lappend command_list {ecoRoute -fix_drc}
}

set initial_snapshot [mptdc_ckpt_verify_snapshot 00_initial]
mptdc_ckpt_write_snapshot_status $status_fh INITIAL $initial_snapshot

set idx 0
set final_snapshot $initial_snapshot
set command_failure 0
set command_failure_index 0
set command_failure_error ""
foreach command $command_list {
    incr idx
    set tag [format "%02d_after_command" $idx]
    set safe [mptdc_ckpt_sanitize $command]
    set cmd_rpt [file join [mptdc_signoff_report_dir] [format "%02d_command_%s.rpt" $idx $safe]]
    puts $status_fh ""
    puts $status_fh "COMMAND_${idx}=$command"
    puts $status_fh "COMMAND_${idx}_REPORT=$cmd_rpt"
    flush $status_fh
    lassign [mptdc_ckpt_capture "checkpoint repair command $idx" $command $cmd_rpt] ok err
    puts $status_fh "COMMAND_${idx}_STATUS=[expr {$ok ? "PASS" : "FAIL"}]"
    if {!$ok} {
        puts $status_fh "COMMAND_${idx}_ERROR=$err"
    }
    set final_snapshot [mptdc_ckpt_verify_snapshot $tag]
    mptdc_ckpt_write_snapshot_status $status_fh COMMAND_${idx}_VERIFY $final_snapshot
    puts $status_fh "COMMAND_${idx}_DRC_REPORT=[dict get $final_snapshot drc_rpt]"
    puts $status_fh "COMMAND_${idx}_MARKER_REPORT=[dict get $final_snapshot marker_rpt]"
    flush $status_fh
    if {!$ok && ![mptdc_ckpt_continue_after_command_fail]} {
        set command_failure 1
        set command_failure_index $idx
        set command_failure_error $err
        break
    }
}

set final_def [file join [mptdc_signoff_def_dir] repaired_route.def]
set final_ckpt [file join [mptdc_signoff_checkpoint_dir] repaired_route.enc]
set final_ckpt_dat "${final_ckpt}.dat"
catch {defOut $final_def}
catch {saveDesign $final_ckpt}

puts $status_fh ""
set final_drc [dict get $final_snapshot total_violations]
set final_shorts [dict get $final_snapshot shorts]
puts $status_fh "FINAL_DRC=$final_drc"
puts $status_fh "FINAL_SHORTS=$final_shorts"
puts $status_fh "FINAL_DRC_STATUS=[dict get $final_snapshot drc_status]"
puts $status_fh "FINAL_REGULAR_CONNECTIVITY_BAD=[dict get $final_snapshot regular_bad]"
puts $status_fh "FINAL_SPECIAL_CONNECTIVITY_BAD=[dict get $final_snapshot special_bad]"
puts $status_fh "FINAL_UNROUTED_NETS=[dict get $final_snapshot unrouted]"
puts $status_fh "FINAL_ROUTE_GATE_PASS=[dict get $final_snapshot route_gate_pass]"
puts $status_fh "FINAL_DEF=$final_def"
puts $status_fh "FINAL_CHECKPOINT=$final_ckpt"
puts $status_fh "FINAL_CHECKPOINT_DAT=$final_ckpt_dat"
puts $status_fh "FINAL_CHECKPOINT_DAT_EXISTS=[expr {[file isdirectory $final_ckpt_dat] ? 1 : 0}]"
if {$command_failure} {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=FAIL_COMMAND"
    puts $status_fh "CHECKPOINT_REPAIR_FAILED_COMMAND_INDEX=$command_failure_index"
    puts $status_fh "CHECKPOINT_REPAIR_FAILED_COMMAND_ERROR=$command_failure_error"
    puts $status_fh "CHECKPOINT_REPAIR_KEEP_GOING_ENV=MPTDC_CHECKPOINT_REPAIR_KEEP_GOING"
} elseif {[dict get $final_snapshot route_gate_pass]} {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=PASS_ROUTE_GATE"
} elseif {$final_drc ne "UNKNOWN" && $final_shorts ne "UNKNOWN" && $final_drc == 0 && $final_shorts == 0} {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY_REVIEW_CONNECTIVITY"
} else {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=REVIEW_REQUIRED"
}
close $status_fh

puts "MPTDC_CHECKPOINT_REPAIR_STATUS_REPORT=$status_rpt"
