# Isolated in-memory VDD via-stack trial. The source checkpoint is never saved.

proc trial_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_PG_VIA_TRIAL_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc trial_value {value} {
    if {$value eq ""} { return NONE }
    return [string map [list "\n" " " "\r" " " "\t" " "] $value]
}

proc trial_read_kv {path} {
    array set values {}
    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        set at [string first = $line]
        if {$at <= 0} { continue }
        set key [string range $line 0 [expr {$at - 1}]]
        set values($key) [string range $line [expr {$at + 1}] end]
    }
    close $fh
    return [array get values]
}

proc trial_capture {path body} {
    if {[catch {redirect -file $path $body} err]} {
        set fh [open $path w]
        puts $fh "CAPTURE_STATUS=FAIL"
        puts $fh "ERROR=[trial_value $err]"
        close $fh
        return 0
    }
    return 1
}

proc trial_violation_count {path} {
    if {![file exists $path]} { return UNKNOWN }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    set counts [list]
    if {[regexp -nocase {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viol} $text -> count]} {
        lappend counts $count
    }
    if {[regexp -nocase {([0-9]+)[[:space:]]+Problem\(s\)[[:space:]]+\(IMPVFC-200\):[[:space:]]+Special Wires:} $text -> count]} {
        lappend counts $count
    }
    if {[llength $counts] == 0} { return UNKNOWN }
    set unique [lsort -unique $counts]
    if {[llength $unique] != 1} { return CONFLICT }
    return [lindex $unique 0]
}

proc trial_box_is_bounded {box} {
    set numbers [regexp -all -inline {[-+]?[0-9]*[.]?[0-9]+} $box]
    if {[llength $numbers] != 4} { return 0 }
    lassign $numbers llx lly urx ury
    if {$urx <= $llx || $ury <= $lly} { return 0 }
    if {($urx - $llx) > 10.0 || ($ury - $lly) > 10.0} { return 0 }
    return 1
}

proc trial_normalize_box {box} {
    return [regexp -all -inline {[-+]?[0-9]*[.]?[0-9]+} $box]
}

proc trial_flat_box {raw} {
    set values [list]
    foreach item $raw {
        foreach value $item {
            lappend values $value
        }
    }
    if {[llength $values] < 4} {
        return [list UNKNOWN UNKNOWN UNKNOWN UNKNOWN]
    }
    return [lrange $values 0 3]
}

proc trial_numeric_or_unknown {value} {
    if {[string is double -strict $value]} {
        return $value
    }
    return UNKNOWN
}

proc trial_write_marker_dump {path} {
    set markers [dbGet top.markers]
    set fh [open $path w]
    puts $fh "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\tlayer\ttype\tsubType\tmessage"
    set idx 0
    set raw_count 0
    set excluded_antenna_count 0
    set excluded_connectivity_count 0
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} {
            continue
        }
        incr raw_count
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

        if {[string equal -nocase $type "Antenna"]} {
            incr excluded_antenna_count
            continue
        }
        if {[string equal -nocase $type "Connectivity"]} {
            incr excluded_connectivity_count
            continue
        }
        incr idx

        lassign [trial_flat_box $box] llx lly urx ury
        set llx [trial_numeric_or_unknown $llx]
        set lly [trial_numeric_or_unknown $lly]
        set urx [trial_numeric_or_unknown $urx]
        set ury [trial_numeric_or_unknown $ury]
        set cx UNKNOWN
        set cy UNKNOWN
        if {$llx ne "UNKNOWN" && $urx ne "UNKNOWN"} {
            set cx [format %.6f [expr {($llx + $urx) / 2.0}]]
        }
        if {$lly ne "UNKNOWN" && $ury ne "UNKNOWN"} {
            set cy [format %.6f [expr {($lly + $ury) / 2.0}]]
        }

        puts $fh "$idx\t[trial_value $marker]\t[trial_value $box]\t$llx\t$lly\t$urx\t$ury\t$cx\t$cy\t[trial_value $layer]\t[trial_value $type]\t[trial_value $subtype]\t[trial_value $message]"
    }
    close $fh
    return [list $idx $raw_count $excluded_antenna_count $excluded_connectivity_count]
}

proc trial_run_command {fh label command} {
    puts $fh "TRY_${label}=[trial_value $command]"
    if {[catch {uplevel #0 $command} err]} {
        puts $fh "${label}_STATUS=FAIL"
        puts $fh "${label}_ERROR=[trial_value $err]"
        return 0
    }
    puts $fh "${label}_STATUS=PASS"
    return 1
}

proc trial_write_status {} {
    global status reports
    set status_report [file join $reports pg_via_trial_status.rpt]
    set fh [open $status_report w]
    foreach key [lsort [array names status]] {
        puts $fh "$key=$status($key)"
    }
    close $fh
}

proc trial_abort {reason {detail ""}} {
    global status
    set status(STATUS) FAIL
    set status(RESULT) $reason
    if {$detail ne ""} {
        set status(ERROR) [trial_value $detail]
    }
    trial_write_status
    puts stderr "SPADMIC_PG_VIA_TRIAL_ABORT: $reason: [trial_value $detail]"
    exit 8
}

set checkpoint [trial_env SPADMIC_PG_VIA_TRIAL_CHECKPOINT]
set root [trial_env SPADMIC_PG_VIA_TRIAL_ROOT]
set top [trial_env SPADMIC_PG_VIA_TRIAL_TOP]
set analysis [trial_env SPADMIC_PG_VIA_TRIAL_ANALYSIS]
set help_report [trial_env SPADMIC_PG_VIA_TRIAL_HELP_REPORT]
set mode [string tolower [trial_env SPADMIC_PG_VIA_TRIAL_MODE]]
set reports [file join $root reports]
file mkdir $reports
array set status {
    LABEL SPADMIC_OOC_PG_VIA_TRIAL
    POLICY ONE_FRESH_PROCESS_ONE_RESTORE_IN_MEMORY_TRIAL
    DESIGN_MODIFICATION IN_MEMORY_ONLY
    SOURCE_CHECKPOINT_WRITE NOT_RUN
    SAVE_DESIGN NOT_RUN
    EXPORT NOT_RUN
    STATUS FAIL
    RESULT TRIAL_INCOMPLETE
}
set status(MODE) $mode
set status(SOURCE_CHECKPOINT) $checkpoint
set status(ANALYSIS_REPORT) $analysis
set status(HELP_REPORT) $help_report

array set analysis_values [trial_read_kv $analysis]
if {![info exists analysis_values(STATUS)] || $analysis_values(STATUS) ne "PASS" ||
    ![info exists analysis_values(EDIT_POWER_VIA_TRIAL_DECISION)] ||
    $analysis_values(EDIT_POWER_VIA_TRIAL_DECISION) ne "READY_FOR_ONE_ISOLATED_TRIAL"} {
    trial_abort ANALYSIS_NOT_READY
}
if {$mode ni {via-only via-1x1 patch-stack}} {
    trial_abort BAD_MODE $mode
}
if {![info exists analysis_values(VDD_HORIZONTAL_ROW_COMPONENT_COUNT)]} {
    trial_abort MISSING_ROW_COUNT
}
set row_count $analysis_values(VDD_HORIZONTAL_ROW_COMPONENT_COUNT)
if {![string is integer -strict $row_count] || $row_count <= 0} {
    trial_abort BAD_ROW_COUNT $row_count
}
set areas [list]
for {set row 1} {$row <= $row_count} {incr row} {
    set key VDD_ROW_${row}_VIA_SEARCH_AREA
    if {![info exists analysis_values($key)] || ![trial_box_is_bounded $analysis_values($key)]} {
        trial_abort BAD_VIA_SEARCH_AREA $key
    }
    lappend areas [trial_normalize_box $analysis_values($key)]
}
set status(TARGET_ROW_COUNT) $row_count

if {[catch {restoreDesign $checkpoint $top} restore_error]} {
    trial_abort RESTORE_FAILED $restore_error
}
set status(RESTORE_DESIGN) PASS

set pre_drc [file join $reports verify_drc_pre_trial.rpt]
set pre_drc_markers [file join $reports drc_markers_pre_trial.tsv]
set pre_regular [file join $reports verify_connectivity_regular_pre_trial.rpt]
set pre_special [file join $reports verify_connectivity_special_pre_trial.rpt]
trial_capture $pre_drc {verify_drc}
set pre_marker_count UNKNOWN
set pre_marker_database_total UNKNOWN
set pre_excluded_antenna_count UNKNOWN
set pre_excluded_connectivity_count UNKNOWN
if {[catch {
    lassign [trial_write_marker_dump $pre_drc_markers] \
        pre_marker_count \
        pre_marker_database_total \
        pre_excluded_antenna_count \
        pre_excluded_connectivity_count
} marker_error]} {
    set status(PRE_DRC_MARKER_DUMP_STATUS) FAIL
    set status(PRE_DRC_MARKER_DUMP_ERROR) [trial_value $marker_error]
} else {
    set status(PRE_DRC_MARKER_DUMP_STATUS) PASS
}
set status(PRE_DRC_MARKER_COUNT) $pre_marker_count
set status(PRE_MARKER_DATABASE_TOTAL) $pre_marker_database_total
set status(PRE_EXCLUDED_ANTENNA_MARKER_COUNT) $pre_excluded_antenna_count
set status(PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $pre_excluded_connectivity_count
trial_capture $pre_regular {verifyConnectivity -type regular}
trial_capture $pre_special {verifyConnectivity -type special -nets {VDD VSS}}
set pre_drc_count [trial_violation_count $pre_drc]
set pre_regular_count [trial_violation_count $pre_regular]
set pre_special_count [trial_violation_count $pre_special]
set status(PRE_DRC_VIOLATION_COUNT) $pre_drc_count
set status(PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $pre_regular_count
set status(PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $pre_special_count
if {![string is integer -strict $pre_regular_count] || $pre_regular_count != 0 ||
    ![string is integer -strict $pre_special_count] || $pre_special_count <= 0 ||
    ![string is integer -strict $pre_drc_count] ||
    $status(PRE_DRC_MARKER_DUMP_STATUS) ne "PASS" ||
    ![string is integer -strict $pre_marker_count] ||
    $pre_marker_count != $pre_drc_count} {
    trial_abort BASELINE_PRECONDITION_FAILED \
        "drc=$pre_drc_count markers=$pre_marker_count regular=$pre_regular_count special=$pre_special_count"
}

set command_report [file join $reports pg_via_trial_commands.rpt]
set fh [open $command_report w]
puts $fh "LABEL=SPADMIC_OOC_PG_VIA_TRIAL_COMMANDS"
puts $fh "MODE=$mode"
puts $fh "TARGET_ROW_COUNT=$row_count"
set command_pass_count 0
set command_fail_count 0
set area_only_command [list setViaGenMode -area_only 1]
if {[trial_run_command $fh VIA_GEN_AREA_ONLY $area_only_command]} {
    incr command_pass_count
    set status(VIA_GEN_AREA_ONLY_STATUS) PASS
} else {
    incr command_fail_count
    set status(VIA_GEN_AREA_ONLY_STATUS) FAIL
    puts $fh "COMMAND_PASS_COUNT=$command_pass_count"
    puts $fh "COMMAND_FAIL_COUNT=$command_fail_count"
    close $fh
    set status(COMMAND_PASS_COUNT) $command_pass_count
    set status(COMMAND_FAIL_COUNT) $command_fail_count
    trial_abort AREA_ONLY_MODE_FAILED
}
set row 0
foreach area $areas {
    incr row
    puts $fh "ROW_${row}_AREA=$area"
    if {$mode in {via-only via-1x1}} {
        set label ROW_${row}_MET1_TO_METTP_STACK
        set command [list editPowerVia -add_vias 1 -nets {VDD} \
            -bottom_layer MET1 -top_layer METTP -exclude_stack_vias 0 -area $area]
        if {$mode eq "via-1x1"} {
            lappend command -via_rows 1 -via_columns 1
        }
        if {[trial_run_command $fh $label $command]} {
            incr command_pass_count
        } else {
            incr command_fail_count
        }
    } else {
        foreach layer {MET2 MET3} {
            set label ROW_${row}_${layer}_PATCH
            set command [list add_shape -net VDD -layer $layer -shape STRIPE -status ROUTED -rect $area]
            if {[trial_run_command $fh $label $command]} {
                incr command_pass_count
            } else {
                incr command_fail_count
            }
        }
        foreach pair {{MET1 MET2} {MET2 MET3} {MET3 METTP}} {
            lassign $pair bottom top_layer
            set label ROW_${row}_${bottom}_TO_${top_layer}_VIA
            set command [list editPowerVia -add_vias 1 -nets {VDD} \
                -bottom_layer $bottom -top_layer $top_layer -area $area]
            if {[trial_run_command $fh $label $command]} {
                incr command_pass_count
            } else {
                incr command_fail_count
            }
        }
    }
}
puts $fh "COMMAND_PASS_COUNT=$command_pass_count"
puts $fh "COMMAND_FAIL_COUNT=$command_fail_count"
close $fh
set status(COMMAND_PASS_COUNT) $command_pass_count
set status(COMMAND_FAIL_COUNT) $command_fail_count

set post_special [file join $reports verify_connectivity_special_post_trial.rpt]
set post_regular [file join $reports verify_connectivity_regular_post_trial.rpt]
set post_drc [file join $reports verify_drc_post_trial.rpt]
set post_drc_markers [file join $reports drc_markers_post_trial.tsv]
trial_capture $post_special {verifyConnectivity -type special -nets {VDD VSS}}
trial_capture $post_regular {verifyConnectivity -type regular}
trial_capture $post_drc {verify_drc}
set post_marker_count UNKNOWN
set post_marker_database_total UNKNOWN
set post_excluded_antenna_count UNKNOWN
set post_excluded_connectivity_count UNKNOWN
if {[catch {
    lassign [trial_write_marker_dump $post_drc_markers] \
        post_marker_count \
        post_marker_database_total \
        post_excluded_antenna_count \
        post_excluded_connectivity_count
} marker_error]} {
    set status(POST_DRC_MARKER_DUMP_STATUS) FAIL
    set status(POST_DRC_MARKER_DUMP_ERROR) [trial_value $marker_error]
} else {
    set status(POST_DRC_MARKER_DUMP_STATUS) PASS
}
set status(POST_DRC_MARKER_COUNT) $post_marker_count
set status(POST_MARKER_DATABASE_TOTAL) $post_marker_database_total
set status(POST_EXCLUDED_ANTENNA_MARKER_COUNT) $post_excluded_antenna_count
set status(POST_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $post_excluded_connectivity_count
set post_special_count [trial_violation_count $post_special]
set post_regular_count [trial_violation_count $post_regular]
set post_drc_count [trial_violation_count $post_drc]
set status(POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $post_special_count
set status(POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $post_regular_count
set status(POST_DRC_VIOLATION_COUNT) $post_drc_count

if {$command_fail_count == 0 &&
    [string is integer -strict $post_special_count] && $post_special_count == 0 &&
    [string is integer -strict $post_regular_count] && $post_regular_count == 0 &&
    [string is integer -strict $post_drc_count] && $post_drc_count <= $pre_drc_count &&
    $status(POST_DRC_MARKER_DUMP_STATUS) eq "PASS" &&
    [string is integer -strict $post_marker_count] &&
    $post_marker_count == $post_drc_count} {
    set status(STATUS) PASS
    set status(RESULT) PG_VIA_METHOD_VALIDATED_NOT_CANONICAL
} else {
    set status(RESULT) PG_VIA_METHOD_REJECTED
}

trial_write_status

if {$status(STATUS) eq "PASS"} { exit 0 }
exit 8
