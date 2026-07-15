# Isolated iterative MET1 minimum-area repair trial. No design is persisted.

proc ma_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_MIN_AREA_TRIAL_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc ma_value {value} {
    if {$value eq ""} { return NONE }
    return [string map [list "\n" " " "\r" " " "\t" " "] $value]
}

proc ma_read_kv {path} {
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

proc ma_capture {path body} {
    if {[catch {redirect -file $path $body} err]} {
        set fh [open $path w]
        puts $fh "CAPTURE_STATUS=FAIL"
        puts $fh "ERROR=[ma_value $err]"
        close $fh
        return 0
    }
    return 1
}

proc ma_violation_count {path} {
    if {![file exists $path]} { return UNKNOWN }
    set fh [open $path r]
    set report [read $fh]
    close $fh
    set counts [list]
    if {[regexp -nocase {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viol} $report -> count]} {
        lappend counts $count
    }
    if {[regexp -nocase {([0-9]+)[[:space:]]+Problem\(s\)[[:space:]]+\(IMPVFC-200\):[[:space:]]+Special Wires:} $report -> count]} {
        lappend counts $count
    }
    if {[llength $counts] == 0} { return UNKNOWN }
    set unique [lsort -unique $counts]
    if {[llength $unique] != 1} { return CONFLICT }
    return [lindex $unique 0]
}

proc ma_flat_box {raw} {
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

proc ma_numeric_or_unknown {value} {
    if {[string is double -strict $value]} { return $value }
    return UNKNOWN
}

proc ma_box_is_numeric {box} {
    if {[llength $box] != 4} { return 0 }
    foreach value $box {
        if {![string is double -strict $value]} { return 0 }
    }
    return 1
}

proc ma_expand_box {box delta} {
    lassign $box llx lly urx ury
    return [list \
        [format %.3f [expr {$llx - $delta}]] \
        [format %.3f [expr {$lly - $delta}]] \
        [format %.3f [expr {$urx + $delta}]] \
        [format %.3f [expr {$ury + $delta}]]]
}

proc ma_unique_append {name value} {
    upvar 1 $name values
    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}

proc ma_is_antenna {type subtype message} {
    return [expr {
        [string equal -nocase $type "Antenna"] ||
        [regexp -nocase {Antenna|Ant.*Area|ProcessAntenna} $subtype] ||
        [regexp -nocase {Antenna|S[.]PAR|Antenna[[:space:]]+Side[[:space:]]+Area} $message]
    }]
}

proc ma_is_min_area {layer type subtype message} {
    return [expr {
        [string equal -nocase $layer "MET1"] &&
        [string equal -nocase $type "Geometry"] &&
        ([regexp -nocase {Minimal_Area|Minimum[[:space:]]+Area|Mar} $subtype] ||
         [regexp -nocase {Minimum[[:space:]]+Area|Minimal_Area} $message])
    }]
}

proc ma_write_marker_dump {path} {
    set markers [list]
    catch {set markers [dbGet top.markers]}
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

        if {[ma_is_antenna $type $subtype $message]} {
            incr excluded_antenna_count
            continue
        }
        if {[string equal -nocase $type "Connectivity"]} {
            incr excluded_connectivity_count
            continue
        }
        incr idx

        lassign [ma_flat_box $box] llx lly urx ury
        set llx [ma_numeric_or_unknown $llx]
        set lly [ma_numeric_or_unknown $lly]
        set urx [ma_numeric_or_unknown $urx]
        set ury [ma_numeric_or_unknown $ury]
        set cx UNKNOWN
        set cy UNKNOWN
        if {$llx ne "UNKNOWN" && $urx ne "UNKNOWN"} {
            set cx [format %.6f [expr {($llx + $urx) / 2.0}]]
        }
        if {$lly ne "UNKNOWN" && $ury ne "UNKNOWN"} {
            set cy [format %.6f [expr {($lly + $ury) / 2.0}]]
        }
        puts $fh "$idx\t[ma_value $marker]\t[ma_value $box]\t$llx\t$lly\t$urx\t$ury\t$cx\t$cy\t[ma_value $layer]\t[ma_value $type]\t[ma_value $subtype]\t[ma_value $message]"
    }
    close $fh
    return [list $idx $raw_count $excluded_antenna_count $excluded_connectivity_count]
}

proc ma_min_area_rows {} {
    set rows [list]
    set markers [list]
    catch {set markers [dbGet top.markers]}
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} {
            continue
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
        if {![ma_is_min_area $layer $type $subtype $message]} {
            continue
        }
        if {![regexp -nocase {Regular[[:space:]]+Wire[[:space:]]+of[[:space:]]+Net[[:space:]]+([^[:space:]]+)} $message -> net]} {
            continue
        }
        lappend rows [list $net $marker [ma_flat_box $box] [ma_value $message]]
    }
    return $rows
}

proc ma_row_nets {rows} {
    set nets [list]
    foreach row $rows {
        ma_unique_append nets [lindex $row 0]
    }
    return [lsort $nets]
}

proc ma_write_status {} {
    global status reports
    set path [file join $reports min_area_second_pass_trial_status.rpt]
    set fh [open $path w]
    foreach key [lsort [array names status]] {
        puts $fh "$key=$status($key)"
    }
    close $fh
}

proc ma_abort {reason {detail ""}} {
    global status commands_fh
    set status(STATUS) FAIL
    set status(RESULT) $reason
    if {$detail ne ""} {
        set status(ERROR) [ma_value $detail]
    }
    if {[info exists commands_fh] && $commands_fh ne ""} {
        catch {flush $commands_fh}
        catch {close $commands_fh}
        set commands_fh ""
    }
    ma_write_status
    puts stderr "SPADMIC_MIN_AREA_SECOND_PASS_ABORT: $reason: [ma_value $detail]"
    exit 8
}

proc ma_run_command {fh iteration label command} {
    puts $fh "ITERATION_${iteration}_${label}=[ma_value $command]"
    if {[catch {uplevel #0 $command} err]} {
        puts $fh "ITERATION_${iteration}_${label}_STATUS=FAIL"
        puts $fh "ITERATION_${iteration}_${label}_ERROR=[ma_value $err]"
        return 0
    }
    puts $fh "ITERATION_${iteration}_${label}_STATUS=PASS"
    return 1
}

set checkpoint [ma_env SPADMIC_MIN_AREA_TRIAL_CHECKPOINT]
set root [ma_env SPADMIC_MIN_AREA_TRIAL_ROOT]
set top [ma_env SPADMIC_MIN_AREA_TRIAL_TOP]
set analysis [ma_env SPADMIC_MIN_AREA_TRIAL_ANALYSIS]
set iteration_limit [ma_env SPADMIC_MIN_AREA_TRIAL_ITERATION_LIMIT]
set trial_revision [ma_env SPADMIC_MIN_AREA_TRIAL_REVISION]
set reports [file join $root reports]
file mkdir $reports
set commands_fh ""

if {![string is integer -strict $iteration_limit] || $iteration_limit < 1 || $iteration_limit > 3} {
    error "SPADMIC_MIN_AREA_TRIAL_BAD_ITERATION_LIMIT: $iteration_limit"
}
if {$trial_revision ne "R2"} {
    error "SPADMIC_MIN_AREA_TRIAL_BAD_REVISION: $trial_revision expected=R2"
}

array set status {
    LABEL SPADMIC_OOC_MIN_AREA_SECOND_PASS_TRIAL
    POLICY ONE_FRESH_PROCESS_ONE_RESTORE_IN_MEMORY_TRIAL
    DESIGN_MODIFICATION IN_MEMORY_ONLY
    SOURCE_CHECKPOINT_WRITE NOT_RUN
    SAVE_DESIGN NOT_RUN
    EXPORT NOT_RUN
    STATUS FAIL
    RESULT TRIAL_INCOMPLETE
    RESTORE_DESIGN NOT_RUN
    ITERATION_COUNT 0
    DRC_COUNT_SEQUENCE UNKNOWN
}
set status(SOURCE_CHECKPOINT) $checkpoint
set status(STEP17_ANALYSIS) $analysis
set status(ITERATION_LIMIT) $iteration_limit
set status(TRIAL_REVISION) $trial_revision

array set analysis_values [ma_read_kv $analysis]
array set expected_analysis {
    STATUS PASS
    RESULT BLOCKERS_CLASSIFIED
    PHYSICAL_CANDIDATE_STATUS PG_AND_REGULAR_CLOSED_FINAL_REPAIR_REQUIRED
    FINAL_DRC_STATUS FAIL
    REGULAR_CONNECTIVITY_STATUS PASS
    PG_CONNECTIVITY_STATUS PASS
    PG_PROBLEM_COUNT 0
    MIN_AREA_REPAIR_EFFECT REDUCED_10_TO_6
    MIN_AREA_PRE_MARKER_COUNT 10
    MIN_AREA_POST_MARKER_COUNT 6
    MIN_AREA_FINAL_MARKER_COUNT 6
    ANTENNA_FINAL_MARKER_COUNT 177
    STREAM_PIN_TARGET_STATUS CANONICAL_TARGETS_PRESERVED
    STREAM_PIN_COMMAND_MAPPING_DECISION REMOVE_NEGATIVE_COMPENSATION_KEEP_CANONICAL_CENTERS
    PVS_DECISION DO_NOT_RUN
}
foreach key [array names expected_analysis] {
    set actual MISSING
    if {[info exists analysis_values($key)]} {
        set actual $analysis_values($key)
    }
    if {$actual ne $expected_analysis($key)} {
        ma_abort STEP17_ANALYSIS_NOT_ACCEPTED \
            "$key=$actual expected=$expected_analysis($key)"
    }
}
if {![info exists analysis_values(MIN_AREA_FINAL_NETS)]} {
    ma_abort STEP17_ANALYSIS_NOT_ACCEPTED MIN_AREA_FINAL_NETS_MISSING
}
set expected_nets [lsort -unique $analysis_values(MIN_AREA_FINAL_NETS)]
set source_run_antenna_count $analysis_values(ANTENNA_FINAL_MARKER_COUNT)
set antenna_comparability RESTORED_MARKER_DB_REPRESENTATION_NOT_DIRECTLY_COMPARABLE_TO_SOURCE_RUN
set restored_antenna_policy REQUIRE_EXACT_BASELINE_21_AND_UNCHANGED_ACROSS_ITERATIONS
set status(SOURCE_RUN_ANTENNA_MARKER_COUNT) $source_run_antenna_count
set status(ANTENNA_COUNT_COMPARABILITY) $antenna_comparability
set status(RESTORED_ANTENNA_MARKER_COUNT_POLICY) $restored_antenna_policy

if {[catch {restoreDesign $checkpoint $top} restore_error]} {
    ma_abort RESTORE_FAILED $restore_error
}
set status(RESTORE_DESIGN) PASS

set pre_drc [file join $reports verify_drc_pre_trial.rpt]
set pre_markers [file join $reports drc_markers_pre_trial.tsv]
set pre_regular [file join $reports verify_connectivity_regular_pre_trial.rpt]
set pre_special [file join $reports verify_connectivity_special_pre_trial.rpt]
if {![ma_capture $pre_drc {verify_drc}]} {
    ma_abort BASELINE_DRC_CAPTURE_FAILED
}
if {[catch {
    lassign [ma_write_marker_dump $pre_markers] \
        pre_marker_count pre_database_total pre_antenna_count pre_connectivity_count
} marker_error]} {
    ma_abort BASELINE_MARKER_DUMP_FAILED $marker_error
}
set current_rows [ma_min_area_rows]
set current_nets [ma_row_nets $current_rows]
if {![ma_capture $pre_regular {verifyConnectivity -type regular}] ||
    ![ma_capture $pre_special {verifyConnectivity -type special -nets {VDD VSS}}]} {
    ma_abort BASELINE_CONNECTIVITY_CAPTURE_FAILED
}
set pre_drc_count [ma_violation_count $pre_drc]
set pre_regular_count [ma_violation_count $pre_regular]
set pre_special_count [ma_violation_count $pre_special]

set status(PRE_DRC_REPORT) $pre_drc
set status(PRE_DRC_MARKER_REPORT) $pre_markers
set status(PRE_REGULAR_CONNECTIVITY_REPORT) $pre_regular
set status(PRE_SPECIAL_CONNECTIVITY_REPORT) $pre_special
set status(PRE_DRC_VIOLATION_COUNT) $pre_drc_count
set status(PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $pre_regular_count
set status(PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $pre_special_count
set status(PRE_DRC_MARKER_COUNT) $pre_marker_count
set status(PRE_MARKER_DATABASE_TOTAL) $pre_database_total
set status(PRE_EXCLUDED_ANTENNA_MARKER_COUNT) $pre_antenna_count
set status(PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $pre_connectivity_count
set status(PRE_MIN_AREA_NETS) [join $current_nets { }]
set status(FINAL_DRC_REPORT) $pre_drc
set status(FINAL_DRC_MARKER_REPORT) $pre_markers
set status(FINAL_REGULAR_CONNECTIVITY_REPORT) $pre_regular
set status(FINAL_SPECIAL_CONNECTIVITY_REPORT) $pre_special
set status(FINAL_DRC_VIOLATION_COUNT) $pre_drc_count
set status(FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $pre_regular_count
set status(FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $pre_special_count
set status(FINAL_DRC_MARKER_COUNT) $pre_marker_count
set status(FINAL_MARKER_DATABASE_TOTAL) $pre_database_total
set status(FINAL_EXCLUDED_ANTENNA_MARKER_COUNT) $pre_antenna_count
set status(FINAL_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $pre_connectivity_count
set status(FINAL_MIN_AREA_NETS) [join $current_nets { }]
set status(RESTORED_BASELINE_ANTENNA_MARKER_COUNT) $pre_antenna_count
set status(RESTORED_BASELINE_MARKER_DATABASE_TOTAL) $pre_database_total
set status(COMMAND_PASS_COUNT) 0
set status(COMMAND_FAIL_COUNT) 0

set command_report [file join $reports min_area_second_pass_trial_commands.rpt]
set commands_fh [open $command_report w]
puts $commands_fh "LABEL=SPADMIC_OOC_MIN_AREA_SECOND_PASS_TRIAL_COMMANDS"
puts $commands_fh "POLICY=BOUNDED_SELECTED_NET_EXISTING_REPAIR_SEQUENCE"
puts $commands_fh "TRIAL_REVISION=$trial_revision"
puts $commands_fh "ITERATION_LIMIT=$iteration_limit"
puts $commands_fh "SOURCE_RUN_ANTENNA_MARKER_COUNT=$source_run_antenna_count"
puts $commands_fh "ANTENNA_COUNT_COMPARABILITY=$antenna_comparability"
puts $commands_fh "RESTORED_ANTENNA_MARKER_COUNT_POLICY=$restored_antenna_policy"
puts $commands_fh "BASELINE_DRC_VIOLATION_COUNT=$pre_drc_count"
puts $commands_fh "BASELINE_DRC_MARKER_COUNT=$pre_marker_count"
puts $commands_fh "BASELINE_MARKER_DATABASE_TOTAL=$pre_database_total"
puts $commands_fh "BASELINE_ANTENNA_MARKER_COUNT=$pre_antenna_count"
puts $commands_fh "BASELINE_CONNECTIVITY_MARKER_COUNT=$pre_connectivity_count"
puts $commands_fh "BASELINE_MIN_AREA_NETS=[join $current_nets { }]"
flush $commands_fh

if {![string is integer -strict $pre_drc_count] || $pre_drc_count != 6 ||
    ![string is integer -strict $pre_marker_count] || $pre_marker_count != 6 ||
    [llength $current_rows] != 6 ||
    $current_nets ne $expected_nets ||
    ![string is integer -strict $pre_regular_count] || $pre_regular_count != 0 ||
    ![string is integer -strict $pre_special_count] || $pre_special_count != 0 ||
    ![string is integer -strict $pre_database_total] || $pre_database_total != 27 ||
    ![string is integer -strict $pre_antenna_count] || $pre_antenna_count != 21 ||
    ![string is integer -strict $pre_connectivity_count] || $pre_connectivity_count != 0} {
    ma_abort BASELINE_PRECONDITION_FAILED \
        "drc=$pre_drc_count markers=$pre_marker_count database_total=$pre_database_total rows=[llength $current_rows] nets=$current_nets expected_nets=$expected_nets regular=$pre_regular_count special=$pre_special_count restored_antenna=$pre_antenna_count source_run_antenna=$source_run_antenna_count connectivity=$pre_connectivity_count"
}

set previous_count $pre_drc_count
set drc_sequence [list $pre_drc_count]
set total_command_pass_count 0
set total_command_fail_count 0

for {set iteration 1} {$iteration <= $iteration_limit} {incr iteration} {
    puts $commands_fh "ITERATION_${iteration}_BEGIN=YES"
    puts $commands_fh "ITERATION_${iteration}_PRE_DRC_VIOLATION_COUNT=$previous_count"
    puts $commands_fh "ITERATION_${iteration}_MIN_AREA_NETS=[join $current_nets { }]"

    catch {setNanoRouteMode -route_with_via_in_pin false}
    catch {setNanoRouteMode -route_with_via_only_for_block_cell_pin false}
    if {[ma_run_command $commands_fh $iteration SELECTED_NET_MODE \
        {setNanoRouteMode -route_selected_net_only true}]} {
        incr total_command_pass_count
    } else {
        incr total_command_fail_count
        ma_abort SELECTED_NET_MODE_FAILED "iteration=$iteration"
    }
    catch {deselectAll}

    set selected [list]
    foreach net $current_nets {
        set label "SELECT_NET_[string map {[ _ ] _} $net]"
        if {[ma_run_command $commands_fh $iteration $label [list selectNet $net]]} {
            incr total_command_pass_count
            lappend selected $net
        } else {
            incr total_command_fail_count
        }
    }
    if {[llength $selected] != [llength $current_nets]} {
        catch {setNanoRouteMode -route_selected_net_only false}
        catch {deselectAll}
        ma_abort NET_SELECTION_FAILED "iteration=$iteration selected=$selected expected=$current_nets"
    }

    set row_index 0
    foreach row $current_rows {
        incr row_index
        set net [lindex $row 0]
        set box [lindex $row 2]
        if {![ma_box_is_numeric $box]} {
            ma_abort NON_NUMERIC_MIN_AREA_BOX "iteration=$iteration net=$net box=$box"
        }
        set expanded [ma_expand_box $box 0.010]
        if {[ma_run_command $commands_fh $iteration \
            "AREA_DELETE_${row_index}_${net}" \
            [list editDelete -net $net -layer MET1 -area $expanded -type Regular]]} {
            incr total_command_pass_count
        } else {
            incr total_command_fail_count
        }
    }

    foreach net $selected {
        if {[ma_run_command $commands_fh $iteration \
            "DRC_WIRE_DELETE_${net}" \
            [list editDelete -net $net -regular_wire_with_drc]]} {
            incr total_command_pass_count
        } else {
            incr total_command_fail_count
        }
    }

    set route_index 0
    foreach command {{globalDetailRoute -select} {detailRoute -select} {ecoRoute -fix_drc}} {
        incr route_index
        if {[ma_run_command $commands_fh $iteration "ROUTE_${route_index}" $command]} {
            incr total_command_pass_count
        } else {
            incr total_command_fail_count
        }
    }
    catch {setNanoRouteMode -route_selected_net_only false}
    catch {deselectAll}

    if {$total_command_fail_count != 0} {
        ma_abort REPAIR_COMMAND_FAILED \
            "iteration=$iteration command_fail_count=$total_command_fail_count"
    }

    set iter_drc [file join $reports verify_drc_iteration_${iteration}.rpt]
    set iter_markers [file join $reports drc_markers_iteration_${iteration}.tsv]
    set iter_regular [file join $reports verify_connectivity_regular_iteration_${iteration}.rpt]
    set iter_special [file join $reports verify_connectivity_special_iteration_${iteration}.rpt]
    if {![ma_capture $iter_drc {verify_drc}]} {
        ma_abort ITERATION_DRC_CAPTURE_FAILED "iteration=$iteration"
    }
    if {[catch {
        lassign [ma_write_marker_dump $iter_markers] \
            iter_marker_count iter_database_total iter_antenna_count iter_connectivity_count
    } marker_error]} {
        ma_abort ITERATION_MARKER_DUMP_FAILED "iteration=$iteration error=$marker_error"
    }
    set next_rows [ma_min_area_rows]
    set next_nets [ma_row_nets $next_rows]
    if {![ma_capture $iter_regular {verifyConnectivity -type regular}] ||
        ![ma_capture $iter_special {verifyConnectivity -type special -nets {VDD VSS}}]} {
        ma_abort ITERATION_CONNECTIVITY_CAPTURE_FAILED "iteration=$iteration"
    }
    set iter_drc_count [ma_violation_count $iter_drc]
    set iter_regular_count [ma_violation_count $iter_regular]
    set iter_special_count [ma_violation_count $iter_special]
    lappend drc_sequence $iter_drc_count

    set status(ITERATION_COUNT) $iteration
    set status(DRC_COUNT_SEQUENCE) [join $drc_sequence { }]
    set status(FINAL_DRC_REPORT) $iter_drc
    set status(FINAL_DRC_MARKER_REPORT) $iter_markers
    set status(FINAL_REGULAR_CONNECTIVITY_REPORT) $iter_regular
    set status(FINAL_SPECIAL_CONNECTIVITY_REPORT) $iter_special
    set status(FINAL_DRC_VIOLATION_COUNT) $iter_drc_count
    set status(FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $iter_regular_count
    set status(FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $iter_special_count
    set status(FINAL_DRC_MARKER_COUNT) $iter_marker_count
    set status(FINAL_MARKER_DATABASE_TOTAL) $iter_database_total
    set status(FINAL_EXCLUDED_ANTENNA_MARKER_COUNT) $iter_antenna_count
    set status(FINAL_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $iter_connectivity_count
    set status(FINAL_MIN_AREA_NETS) [join $next_nets { }]
    set status(COMMAND_PASS_COUNT) $total_command_pass_count
    set status(COMMAND_FAIL_COUNT) $total_command_fail_count

    puts $commands_fh "ITERATION_${iteration}_POST_DRC_VIOLATION_COUNT=$iter_drc_count"
    puts $commands_fh "ITERATION_${iteration}_POST_DRC_MARKER_COUNT=$iter_marker_count"
    puts $commands_fh "ITERATION_${iteration}_POST_MARKER_DATABASE_TOTAL=$iter_database_total"
    puts $commands_fh "ITERATION_${iteration}_POST_ANTENNA_MARKER_COUNT=$iter_antenna_count"
    puts $commands_fh "ITERATION_${iteration}_POST_CONNECTIVITY_MARKER_COUNT=$iter_connectivity_count"
    puts $commands_fh "ITERATION_${iteration}_POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT=$iter_regular_count"
    puts $commands_fh "ITERATION_${iteration}_POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=$iter_special_count"
    puts $commands_fh "ITERATION_${iteration}_POST_MIN_AREA_NETS=[join $next_nets { }]"
    puts $commands_fh "ITERATION_${iteration}_END=YES"
    flush $commands_fh
    ma_write_status

    if {![string is integer -strict $iter_drc_count] ||
        ![string is integer -strict $iter_marker_count] ||
        $iter_marker_count != $iter_drc_count ||
        [llength $next_rows] != $iter_marker_count ||
        ![string is integer -strict $iter_regular_count] || $iter_regular_count != 0 ||
        ![string is integer -strict $iter_special_count] || $iter_special_count != 0 ||
        ![string is integer -strict $iter_antenna_count] || $iter_antenna_count != $pre_antenna_count ||
        ![string is integer -strict $iter_connectivity_count] || $iter_connectivity_count != 0 ||
        ![string is integer -strict $iter_database_total] ||
        $iter_database_total != ($iter_marker_count + $iter_antenna_count + $iter_connectivity_count)} {
        ma_abort ITERATION_GATE_FAILED \
            "iteration=$iteration drc=$iter_drc_count markers=$iter_marker_count database_total=$iter_database_total min_area_rows=[llength $next_rows] regular=$iter_regular_count special=$iter_special_count restored_antenna=$iter_antenna_count baseline_restored_antenna=$pre_antenna_count source_run_antenna=$source_run_antenna_count connectivity=$iter_connectivity_count"
    }

    if {$iter_drc_count == 0} {
        set status(STATUS) PASS
        set status(RESULT) ITERATIVE_MIN_AREA_REPAIR_VALIDATED
        break
    }
    if {$iter_drc_count >= $previous_count} {
        set status(RESULT) ITERATIVE_MIN_AREA_REPAIR_NO_IMPROVEMENT
        break
    }
    if {$iteration == $iteration_limit} {
        set status(RESULT) ITERATIVE_MIN_AREA_REPAIR_REDUCED_NOT_CLOSED
        break
    }

    set previous_count $iter_drc_count
    set current_rows $next_rows
    set current_nets $next_nets
}

puts $commands_fh "COMMAND_PASS_COUNT=$total_command_pass_count"
puts $commands_fh "COMMAND_FAIL_COUNT=$total_command_fail_count"
puts $commands_fh "DRC_COUNT_SEQUENCE=[join $drc_sequence { }]"
close $commands_fh
set commands_fh ""
ma_write_status

if {$status(STATUS) eq "PASS"} { exit 0 }
exit 8
