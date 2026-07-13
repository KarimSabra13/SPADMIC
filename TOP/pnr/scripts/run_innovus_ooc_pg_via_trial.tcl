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
    error "$reason: $detail"
}

set checkpoint [trial_env SPADMIC_PG_VIA_TRIAL_CHECKPOINT]
set root [trial_env SPADMIC_PG_VIA_TRIAL_ROOT]
set top [trial_env SPADMIC_PG_VIA_TRIAL_TOP]
set analysis [trial_env SPADMIC_PG_VIA_TRIAL_ANALYSIS]
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

array set analysis_values [trial_read_kv $analysis]
if {![info exists analysis_values(STATUS)] || $analysis_values(STATUS) ne "PASS" ||
    ![info exists analysis_values(EDIT_POWER_VIA_TRIAL_DECISION)] ||
    $analysis_values(EDIT_POWER_VIA_TRIAL_DECISION) ne "READY_FOR_ONE_ISOLATED_TRIAL"} {
    trial_abort ANALYSIS_NOT_READY
}
if {$mode ni {via-only patch-stack}} {
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
set pre_regular [file join $reports verify_connectivity_regular_pre_trial.rpt]
set pre_special [file join $reports verify_connectivity_special_pre_trial.rpt]
trial_capture $pre_drc {verify_drc}
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
    ![string is integer -strict $pre_drc_count]} {
    trial_abort BASELINE_PRECONDITION_FAILED \
        "drc=$pre_drc_count regular=$pre_regular_count special=$pre_special_count"
}

set command_report [file join $reports pg_via_trial_commands.rpt]
set fh [open $command_report w]
puts $fh "LABEL=SPADMIC_OOC_PG_VIA_TRIAL_COMMANDS"
puts $fh "MODE=$mode"
puts $fh "TARGET_ROW_COUNT=$row_count"
set command_pass_count 0
set command_fail_count 0
set row 0
foreach area $areas {
    incr row
    puts $fh "ROW_${row}_AREA=$area"
    if {$mode eq "patch-stack"} {
        foreach layer {MET2 MET3} {
            set label ROW_${row}_${layer}_PATCH
            set command [list add_shape -net VDD -layer $layer -shape STRIPE -status ROUTED -rect $area]
            if {[trial_run_command $fh $label $command]} {
                incr command_pass_count
            } else {
                incr command_fail_count
            }
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
puts $fh "COMMAND_PASS_COUNT=$command_pass_count"
puts $fh "COMMAND_FAIL_COUNT=$command_fail_count"
close $fh
set status(COMMAND_PASS_COUNT) $command_pass_count
set status(COMMAND_FAIL_COUNT) $command_fail_count

set post_special [file join $reports verify_connectivity_special_post_trial.rpt]
set post_regular [file join $reports verify_connectivity_regular_post_trial.rpt]
set post_drc [file join $reports verify_drc_post_trial.rpt]
trial_capture $post_special {verifyConnectivity -type special -nets {VDD VSS}}
trial_capture $post_regular {verifyConnectivity -type regular}
trial_capture $post_drc {verify_drc}
set post_special_count [trial_violation_count $post_special]
set post_regular_count [trial_violation_count $post_regular]
set post_drc_count [trial_violation_count $post_drc]
set status(POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $post_special_count
set status(POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $post_regular_count
set status(POST_DRC_VIOLATION_COUNT) $post_drc_count

if {$command_fail_count == 0 &&
    [string is integer -strict $post_special_count] && $post_special_count == 0 &&
    [string is integer -strict $post_regular_count] && $post_regular_count == 0 &&
    [string is integer -strict $post_drc_count] && $post_drc_count <= $pre_drc_count} {
    set status(STATUS) PASS
    set status(RESULT) PG_VIA_METHOD_VALIDATED_NOT_CANONICAL
} else {
    set status(RESULT) PG_VIA_METHOD_REJECTED
}

trial_write_status

if {$status(STATUS) eq "PASS"} { exit 0 }
exit 8
