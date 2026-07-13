# Isolated post-CTS/filler stage attribution. No PG restitch, save, or export.

proc pf_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_POSTFILLER_PROBE_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc pf_value {value} {
    if {$value eq ""} { return NONE }
    return [string map [list "\n" " " "\r" " " "\t" " "] $value]
}

proc pf_capture {path body} {
    if {[catch {redirect -file $path $body} err]} {
        set fh [open $path w]
        puts $fh "CAPTURE_STATUS=FAIL"
        puts $fh "ERROR=[pf_value $err]"
        close $fh
        return 0
    }
    return 1
}

proc pf_violation_count {path} {
    if {![file exists $path]} { return UNKNOWN }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    set counts [list]
    if {[regexp -nocase {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viol} $text -> count]} {
        lappend counts $count
    }
    if {[regexp -nocase {Total[[:space:]]+number[[:space:]]+of[[:space:]]+DRC[[:space:]]+violations[[:space:]]*=[[:space:]]*([0-9]+)} $text -> count]} {
        lappend counts $count
    }
    if {[llength $counts] == 0} { return UNKNOWN }
    set unique [lsort -unique $counts]
    if {[llength $unique] != 1} { return CONFLICT }
    return [lindex $unique 0]
}

proc pf_flat_box {raw} {
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

proc pf_numeric_or_unknown {value} {
    if {[string is double -strict $value]} { return $value }
    return UNKNOWN
}

proc pf_write_marker_dump {path} {
    set markers [dbGet top.markers]
    set fh [open $path w]
    puts $fh "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\tlayer\ttype\tsubType\tmessage"
    set idx 0
    set raw_count 0
    set excluded_antenna_count 0
    set excluded_connectivity_count 0
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} { continue }
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
        lassign [pf_flat_box $box] llx lly urx ury
        set llx [pf_numeric_or_unknown $llx]
        set lly [pf_numeric_or_unknown $lly]
        set urx [pf_numeric_or_unknown $urx]
        set ury [pf_numeric_or_unknown $ury]
        set cx UNKNOWN
        set cy UNKNOWN
        if {$llx ne "UNKNOWN" && $urx ne "UNKNOWN"} {
            set cx [format %.6f [expr {($llx + $urx) / 2.0}]]
        }
        if {$lly ne "UNKNOWN" && $ury ne "UNKNOWN"} {
            set cy [format %.6f [expr {($lly + $ury) / 2.0}]]
        }
        puts $fh "$idx\t[pf_value $marker]\t[pf_value $box]\t$llx\t$lly\t$urx\t$ury\t$cx\t$cy\t[pf_value $layer]\t[pf_value $type]\t[pf_value $subtype]\t[pf_value $message]"
    }
    close $fh
    return [list $idx $raw_count $excluded_antenna_count $excluded_connectivity_count]
}

proc pf_write_status {} {
    global pf_status pf_reports
    set fh [open [file join $pf_reports postfiller_stage_probe_status.rpt] w]
    foreach key [lsort [array names pf_status]] {
        puts $fh "$key=$pf_status($key)"
    }
    close $fh
}

proc pf_abort {reason {detail ""}} {
    global pf_status
    set pf_status(STATUS) FAIL
    set pf_status(RESULT) $reason
    if {$detail ne ""} { set pf_status(ERROR) [pf_value $detail] }
    pf_write_status
    puts stderr "SPADMIC_POSTFILLER_PROBE_ABORT: $reason: [pf_value $detail]"
    exit 8
}

proc pf_capture_stage {prefix stem} {
    global pf_status pf_reports
    set drc [file join $pf_reports "verify_drc_${stem}.rpt"]
    set markers [file join $pf_reports "drc_markers_${stem}.tsv"]
    set special [file join $pf_reports "verify_connectivity_special_${stem}.rpt"]
    set regular [file join $pf_reports "verify_connectivity_regular_${stem}.rpt"]

    set drc_capture [pf_capture $drc {verify_drc}]
    set marker_count UNKNOWN
    set marker_database_total UNKNOWN
    set excluded_antenna_count UNKNOWN
    set excluded_connectivity_count UNKNOWN
    if {[catch {
        lassign [pf_write_marker_dump $markers] \
            marker_count marker_database_total \
            excluded_antenna_count excluded_connectivity_count
    } marker_error]} {
        set marker_dump_status FAIL
        set pf_status(${prefix}_DRC_MARKER_DUMP_ERROR) [pf_value $marker_error]
    } else {
        set marker_dump_status PASS
    }
    set special_capture [pf_capture $special {verifyConnectivity -type special -nets {VDD VSS}}]
    set regular_capture [pf_capture $regular {verifyConnectivity -type regular}]

    set drc_count [pf_violation_count $drc]
    set special_count [pf_violation_count $special]
    set regular_count [pf_violation_count $regular]
    set pf_status(${prefix}_DRC_CAPTURE_STATUS) [expr {$drc_capture ? "PASS" : "FAIL"}]
    set pf_status(${prefix}_SPECIAL_CONNECTIVITY_CAPTURE_STATUS) [expr {$special_capture ? "PASS" : "FAIL"}]
    set pf_status(${prefix}_REGULAR_CONNECTIVITY_CAPTURE_STATUS) [expr {$regular_capture ? "PASS" : "FAIL"}]
    set pf_status(${prefix}_DRC_MARKER_DUMP_STATUS) $marker_dump_status
    set pf_status(${prefix}_DRC_VIOLATION_COUNT) $drc_count
    set pf_status(${prefix}_DRC_MARKER_COUNT) $marker_count
    set pf_status(${prefix}_MARKER_DATABASE_TOTAL) $marker_database_total
    set pf_status(${prefix}_EXCLUDED_ANTENNA_MARKER_COUNT) $excluded_antenna_count
    set pf_status(${prefix}_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $excluded_connectivity_count
    set pf_status(${prefix}_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $special_count
    set pf_status(${prefix}_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $regular_count

    set valid [expr {
        $drc_capture && $special_capture && $regular_capture &&
        $marker_dump_status eq "PASS" &&
        [string is integer -strict $drc_count] &&
        [string is integer -strict $special_count] &&
        [string is integer -strict $regular_count] &&
        [string is integer -strict $marker_count] &&
        [string is integer -strict $marker_database_total] &&
        [string is integer -strict $excluded_antenna_count] &&
        [string is integer -strict $excluded_connectivity_count] &&
        $marker_count == $drc_count &&
        $marker_database_total == ($marker_count + $excluded_antenna_count + $excluded_connectivity_count)
    }]
    if {!$valid} {
        pf_abort ${prefix}_EVIDENCE_INCONSISTENT \
            "drc=$drc_count markers=$marker_count raw=$marker_database_total antenna=$excluded_antenna_count connectivity=$excluded_connectivity_count special=$special_count regular=$regular_count"
    }
}

set checkpoint [pf_env SPADMIC_POSTFILLER_PROBE_CHECKPOINT]
set pf_root [pf_env SPADMIC_POSTFILLER_PROBE_ROOT]
set top [pf_env SPADMIC_POSTFILLER_PROBE_TOP]
set fillers [pf_env SPADMIC_POSTFILLER_PROBE_FILLER_CELLS]
set pf_reports [file join $pf_root reports]
file mkdir $pf_reports
array set pf_status {
    LABEL SPADMIC_OOC_POSTFILLER_STAGE_PROBE
    POLICY ONE_FRESH_PROCESS_ONE_RESTORE_POST_CTS_FILLER_STAGE_ATTRIBUTION
    DESIGN_MODIFICATION IN_MEMORY_FILLER_ONLY
    POST_FILLER_SROUTE NOT_RUN
    SOURCE_CHECKPOINT_WRITE NOT_RUN
    SAVE_DESIGN NOT_RUN
    EXPORT NOT_RUN
    PVS NOT_RUN
    STATUS FAIL
    RESULT POSTFILLER_STAGE_PROBE_INCOMPLETE
}
set pf_status(SOURCE_CHECKPOINT) $checkpoint
set pf_status(TOP_MODULE) $top
set pf_status(FILLER_CELLS) $fillers

if {[catch {restoreDesign $checkpoint $top} restore_error]} {
    pf_abort RESTORE_FAILED $restore_error
}
set pf_status(RESTORE_DESIGN) PASS

pf_capture_stage POST_CTS post_cts_pre_filler

set command_report [file join $pf_reports postfiller_stage_probe_commands.rpt]
set fh [open $command_report w]
puts $fh "LABEL=SPADMIC_OOC_POSTFILLER_STAGE_PROBE_COMMANDS"
puts $fh "POLICY=CANONICAL_DRC_SAFE_FILLER_ONLY_NO_PG_RESTITCH"
set filler_mode_status FAIL
set filler_mode_command NONE
foreach command [list \
    [list setFillerMode -add_fillers_with_drc false] \
    [list setFillerMode -add_fillers_with_drc 0] \
    [list setFillerMode -addFillersWithDrc false] \
    [list setFillerMode -addFillersWithDrc 0]] {
    puts $fh "TRY_FILLER_MODE=[pf_value $command]"
    if {![catch {uplevel #0 $command} err]} {
        set filler_mode_status PASS
        set filler_mode_command $command
        puts $fh "FILLER_MODE_STATUS=PASS"
        puts $fh "FILLER_MODE_COMMAND=[pf_value $command]"
        break
    }
    puts $fh "FILLER_MODE_ERROR=[pf_value $err]"
}
set pf_status(FILLER_MODE_STATUS) $filler_mode_status
set pf_status(FILLER_MODE_COMMAND) [pf_value $filler_mode_command]
if {$filler_mode_status ne "PASS"} {
    close $fh
    pf_abort FILLER_MODE_FAILED
}

set add_filler_command [list addFiller -cell $fillers -prefix FILL]
puts $fh "TRY_ADD_FILLER=[pf_value $add_filler_command]"
if {[catch {uplevel #0 $add_filler_command} add_filler_error]} {
    puts $fh "ADD_FILLER_STATUS=FAIL"
    puts $fh "ADD_FILLER_ERROR=[pf_value $add_filler_error]"
    close $fh
    set pf_status(ADD_FILLER_STATUS) FAIL
    pf_abort ADD_FILLER_FAILED $add_filler_error
}
puts $fh "ADD_FILLER_STATUS=PASS"
puts $fh "ADD_FILLER_COMMAND=[pf_value $add_filler_command]"
puts $fh "POST_FILLER_SROUTE=NOT_RUN"
close $fh
set pf_status(ADD_FILLER_STATUS) PASS
set pf_status(ADD_FILLER_COMMAND) [pf_value $add_filler_command]

pf_capture_stage POST_FILLER_PRE_RESTITCH post_filler_pre_restitch

set pf_status(STATUS) PASS
set pf_status(RESULT) POSTFILLER_STAGE_EVIDENCE_CAPTURED
pf_write_status
exit 0
