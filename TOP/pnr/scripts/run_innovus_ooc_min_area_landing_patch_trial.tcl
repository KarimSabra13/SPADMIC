# Isolated six-net MET1 landing-extension trial. No design is persisted.

proc lp_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_MIN_AREA_LANDING_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc lp_value {value} {
    if {$value eq ""} { return NONE }
    return [string map [list "\n" " " "\r" " " "\t" " "] $value]
}

proc lp_read_kv {path} {
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

proc lp_capture {path body} {
    if {[catch {redirect -file $path $body} err]} {
        set fh [open $path w]
        puts $fh "CAPTURE_STATUS=FAIL"
        puts $fh "ERROR=[lp_value $err]"
        close $fh
        return 0
    }
    return 1
}

proc lp_violation_count {path} {
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

proc lp_flat_values {raw} {
    set values [list]
    foreach item $raw {
        if {[llength $item] > 1} {
            foreach nested [lp_flat_values $item] {
                lappend values $nested
            }
        } else {
            lappend values $item
        }
    }
    return $values
}

proc lp_flat_box {raw} {
    set values [lp_flat_values $raw]
    if {[llength $values] < 4} {
        return [list UNKNOWN UNKNOWN UNKNOWN UNKNOWN]
    }
    return [lrange $values 0 3]
}

proc lp_numeric_box {box} {
    if {[llength $box] != 4} { return 0 }
    foreach value $box {
        if {![string is double -strict $value]} { return 0 }
    }
    return 1
}

proc lp_close {actual expected {tolerance 0.001}} {
    if {![string is double -strict $actual] || ![string is double -strict $expected]} {
        return 0
    }
    return [expr {abs($actual - $expected) <= $tolerance}]
}

proc lp_box_matches {actual expected} {
    if {![lp_numeric_box $actual] || ![lp_numeric_box $expected]} { return 0 }
    foreach lhs $actual rhs $expected {
        if {![lp_close $lhs $rhs]} { return 0 }
    }
    return 1
}

proc lp_point_matches {raw expected_x expected_y} {
    set values [lp_flat_values $raw]
    if {[llength $values] < 2} { return 0 }
    return [expr {
        [lp_close [lindex $values 0] $expected_x] &&
        [lp_close [lindex $values 1] $expected_y]
    }]
}

proc lp_has_endpoint {raw expected_x expected_y} {
    set values [lp_flat_values $raw]
    for {set index 0} {$index + 1 < [llength $values]} {incr index 2} {
        if {[lp_close [lindex $values $index] $expected_x] &&
            [lp_close [lindex $values [expr {$index + 1}]] $expected_y]} {
            return 1
        }
    }
    return 0
}

proc lp_point_in_box {x y box} {
    if {![lp_numeric_box $box]} { return 0 }
    lassign $box llx lly urx ury
    return [expr {$x >= $llx - 0.001 && $x <= $urx + 0.001 &&
                  $y >= $lly - 0.001 && $y <= $ury + 0.001}]
}

proc lp_valid_handles {raw} {
    set handles [list]
    foreach handle $raw {
        if {$handle eq "" || $handle eq "0x0" || $handle eq "NULL"} { continue }
        if {[lsearch -exact $handles $handle] < 0} { lappend handles $handle }
    }
    return $handles
}

proc lp_is_antenna {type subtype message} {
    return [expr {
        [string equal -nocase $type "Antenna"] ||
        [regexp -nocase {Antenna|Ant.*Area|ProcessAntenna} $subtype] ||
        [regexp -nocase {Antenna|S[.]PAR|Antenna[[:space:]]+Side[[:space:]]+Area} $message]
    }]
}

proc lp_is_min_area {layer type subtype message} {
    return [expr {
        [string equal -nocase $layer "MET1"] &&
        [string equal -nocase $type "Geometry"] &&
        ([regexp -nocase {Minimal_Area|Minimum[[:space:]]+Area|Mar} $subtype] ||
         [regexp -nocase {Minimum[[:space:]]+Area|Minimal_Area} $message])
    }]
}

proc lp_write_marker_dump {path} {
    set markers [list]
    catch {set markers [dbGet top.markers]}
    set fh [open $path w]
    puts $fh "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\tlayer\ttype\tsubType\tmessage"
    set idx 0
    set raw_count 0
    set antenna_count 0
    set connectivity_count 0
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
        if {[lp_is_antenna $type $subtype $message]} {
            incr antenna_count
            continue
        }
        if {[string equal -nocase $type "Connectivity"]} {
            incr connectivity_count
            continue
        }
        incr idx
        lassign [lp_flat_box $box] llx lly urx ury
        set cx UNKNOWN
        set cy UNKNOWN
        if {[string is double -strict $llx] && [string is double -strict $urx]} {
            set cx [format %.6f [expr {($llx + $urx) / 2.0}]]
        }
        if {[string is double -strict $lly] && [string is double -strict $ury]} {
            set cy [format %.6f [expr {($lly + $ury) / 2.0}]]
        }
        puts $fh "$idx\t[lp_value $marker]\t[lp_value $box]\t$llx\t$lly\t$urx\t$ury\t$cx\t$cy\t[lp_value $layer]\t[lp_value $type]\t[lp_value $subtype]\t[lp_value $message]"
    }
    close $fh
    return [list $idx $raw_count $antenna_count $connectivity_count]
}

proc lp_min_area_rows {} {
    set rows [list]
    set markers [list]
    catch {set markers [dbGet top.markers]}
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} { continue }
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
        if {![lp_is_min_area $layer $type $subtype $message]} { continue }
        if {![regexp -nocase {Regular[[:space:]]+Wire[[:space:]]+of[[:space:]]+Net[[:space:]]+([^[:space:]]+)} $message -> net]} {
            continue
        }
        lappend rows [list $net $marker [lp_flat_box $box] [lp_value $message]]
    }
    return $rows
}

proc lp_row_nets {rows} {
    set nets [list]
    foreach row $rows {
        set net [lindex $row 0]
        if {[lsearch -exact $nets $net] < 0} { lappend nets $net }
    }
    return [lsort $nets]
}

proc lp_write_status {} {
    global status reports
    set fh [open [file join $reports min_area_landing_patch_trial_status.rpt] w]
    foreach key [lsort [array names status]] {
        puts $fh "$key=$status($key)"
    }
    close $fh
}

proc lp_abort {reason {detail ""}} {
    global status command_fh
    set status(STATUS) FAIL
    set status(RESULT) $reason
    if {$detail ne ""} { set status(ERROR) [lp_value $detail] }
    if {[info exists command_fh] && $command_fh ne ""} {
        catch {flush $command_fh}
        catch {close $command_fh}
        set command_fh ""
    }
    lp_write_status
    puts stderr "SPADMIC_MIN_AREA_LANDING_ABORT: $reason: [lp_value $detail]"
    exit 8
}

set command_pass_count 0
set command_fail_count 0

proc lp_run_command {fh label command} {
    global command_pass_count command_fail_count
    puts $fh "${label}=[lp_value $command]"
    if {[catch {uplevel #0 $command} err]} {
        incr command_fail_count
        puts $fh "${label}_STATUS=FAIL"
        puts $fh "${label}_ERROR=[lp_value $err]"
        flush $fh
        return 0
    }
    incr command_pass_count
    puts $fh "${label}_STATUS=PASS"
    flush $fh
    return 1
}

set checkpoint [lp_env SPADMIC_MIN_AREA_LANDING_CHECKPOINT]
set root [lp_env SPADMIC_MIN_AREA_LANDING_ROOT]
set top [lp_env SPADMIC_MIN_AREA_LANDING_TOP]
set source_analysis [lp_env SPADMIC_MIN_AREA_LANDING_SOURCE_ANALYSIS]
set trial_revision [lp_env SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION]
if {$trial_revision eq "R1"} {
    set analysis_key STEP20_ANALYSIS
    set policy ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MET1_LANDING_EXTENSIONS
    set command_policy EXACT_SIX_NET_ONE_GRID_MET1_WIRE_EDITOR_EXTENSIONS
    set patch_length_policy UNIFORM_0.56
    set validated_result SIX_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED
    set no_improvement_result SIX_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT
    set changed_result SIX_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
} elseif {$trial_revision eq "R2"} {
    set analysis_key STEP21_ANALYSIS
    set policy ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_LENGTH_MET1_LANDING_EXTENSIONS
    set command_policy EXACT_SIX_NET_MIXED_LENGTH_MET1_WIRE_EDITOR_EXTENSIONS
    set patch_length_policy FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56
    set validated_result MIXED_LENGTH_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED
    set no_improvement_result MIXED_LENGTH_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT
    set changed_result MIXED_LENGTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
} else {
    error "SPADMIC_MIN_AREA_LANDING_UNSUPPORTED_REVISION: $trial_revision"
}
set reports [file join $root reports]
file mkdir $reports
set command_fh ""

array set status {
    LABEL SPADMIC_OOC_MIN_AREA_LANDING_PATCH_TRIAL
    POLICY ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MET1_LANDING_EXTENSIONS
    DESIGN_MODIFICATION IN_MEMORY_ONLY
    SOURCE_CHECKPOINT_WRITE NOT_RUN
    SAVE_DESIGN NOT_RUN
    EXPORT NOT_RUN
    PVS NOT_RUN
    RESTORE_DESIGN NOT_RUN
    STATUS FAIL
    RESULT TRIAL_INCOMPLETE
    CONTRACT_VALIDATED_COUNT 0
    PATCH_ATTEMPTED_COUNT 0
    PATCH_APPLIED_COUNT 0
    COMMAND_PASS_COUNT 0
    COMMAND_FAIL_COUNT 0
}
set status(SOURCE_CHECKPOINT) $checkpoint
set status(POLICY) $policy
set status(TRIAL_REVISION) $trial_revision
set status(PATCH_LENGTH_POLICY) $patch_length_policy
set status($analysis_key) $source_analysis

array set analysis_values [lp_read_kv $source_analysis]
array set expected_analysis {}
if {$trial_revision eq "R1"} {
    array set expected_analysis {
        LABEL SPADMIC_TX_PACKET_MIN_AREA_GEOMETRY_ANALYSIS
        POLICY READ_ONLY_RESTORED_CHECKPOINT_LOCAL_TOPOLOGY_CLASSIFICATION
        STATUS PASS
        RESULT MIN_AREA_LOCAL_GEOMETRY_CLASSIFIED
        SELECTED_NET_REROUTE_METHOD_STATUS REJECTED_NO_IMPROVEMENT
        PRE_DRC_VIOLATION_COUNT 6
        POST_DRC_VIOLATION_COUNT 6
        PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT 0
        POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT 0
        PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT 0
        POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT 0
        PRE_EXCLUDED_ANTENNA_MARKER_COUNT 21
        POST_EXCLUDED_ANTENNA_MARKER_COUNT 21
        PRE_MARKER_DATABASE_TOTAL 27
        POST_MARKER_DATABASE_TOTAL 27
        MARKER_SIGNATURE_STABILITY PASS_IDENTICAL_BEFORE_AND_AFTER_QUERY_PROBE
        RESOLVED_NET_COUNT 6
        WIRE_QUERY_PASS_NET_COUNT 6
        LOCAL_WIRE_NET_COUNT 6
        INST_TERM_NET_COUNT 6
        INST_TERM_ROW_COUNT 12
        LOCAL_GEOMETRY_CAPTURE_STATUS PARTIAL_TERMINAL_OR_PIN_SHAPE_COVERAGE
        DIRECT_GEOMETRY_TRIAL_DECISION BLOCKED_PENDING_OPERATOR_REVIEW
        CANONICAL_RERUN_DECISION BLOCKED_PENDING_LOCAL_GEOMETRY_REVIEW
        SAVE_DESIGN NOT_RUN
        EXPORT NOT_RUN
        IMMUTABLE_PVS_STAGING NOT_RUN
        PVS_DECISION DO_NOT_RUN
        ERROR_COUNT 0
    }
} else {
    array set expected_analysis {
        LABEL SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS
        POLICY ISOLATED_IN_MEMORY_SIX_NET_MET1_LANDING_PATCH_CLASSIFICATION
        STATUS PASS
        RESULT MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED
        TRIAL_PROCESS_STATUS FAIL
        TRIAL_PROCESS_RESULT SIX_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
        METHOD_STATUS REJECTED_OR_INCOMPLETE
        PATCH_CONTRACT_STATUS PASS_EXACT_SIX_REVIEWED_EXTENSIONS
        PATCH_WIDTH_UM 0.28
        PATCH_LENGTH_UM 0.56
        PATCH_ATTEMPTED_COUNT 6
        PATCH_APPLIED_COUNT 6
        COMMAND_PASS_COUNT 24
        COMMAND_FAIL_COUNT 0
        PRE_DRC_VIOLATION_COUNT 6
        FINAL_DRC_VIOLATION_COUNT 4
        PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT 0
        FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT 0
        PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT 0
        FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT 0
        PRE_EXCLUDED_ANTENNA_MARKER_COUNT 21
        FINAL_EXCLUDED_ANTENNA_MARKER_COUNT 21
        PRE_MARKER_DATABASE_TOTAL 27
        FINAL_MARKER_DATABASE_TOTAL 25
        REMOVED_MARKER_SIGNATURE_COUNT 6
        ADDED_MARKER_SIGNATURE_COUNT 4
        FINAL_MIN_AREA_NETS {n_9677 n_9693 n_9696 n_9697}
        SAVE_DESIGN NOT_RUN
        EXPORT NOT_RUN
        IMMUTABLE_PVS_STAGING NOT_RUN
        PVS_DECISION DO_NOT_RUN
        CANONICAL_RERUN_DECISION DO_NOT_RUN_FROM_THIS_STEP
        NEXT_METHOD_DECISION STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD
        ERROR_COUNT 0
    }
}
foreach key [array names expected_analysis] {
    set actual MISSING
    if {[info exists analysis_values($key)]} { set actual $analysis_values($key) }
    if {$actual ne $expected_analysis($key)} {
        lp_abort SOURCE_ANALYSIS_NOT_ACCEPTED "$analysis_key:$key=$actual expected=$expected_analysis($key)"
    }
}

if {[catch {restoreDesign $checkpoint $top} restore_error]} {
    lp_abort RESTORE_FAILED $restore_error
}
set status(RESTORE_DESIGN) PASS

set pre_drc [file join $reports verify_drc_pre_trial.rpt]
set pre_markers [file join $reports drc_markers_pre_trial.tsv]
set pre_regular [file join $reports verify_connectivity_regular_pre_trial.rpt]
set pre_special [file join $reports verify_connectivity_special_pre_trial.rpt]
if {![lp_capture $pre_drc {verify_drc}]} { lp_abort BASELINE_DRC_CAPTURE_FAILED }
if {[catch {
    lassign [lp_write_marker_dump $pre_markers] \
        pre_marker_count pre_database_total pre_antenna_count pre_connectivity_count
} marker_error]} {
    lp_abort BASELINE_MARKER_DUMP_FAILED $marker_error
}
set pre_rows [lp_min_area_rows]
set pre_nets [lp_row_nets $pre_rows]
if {![lp_capture $pre_regular {verifyConnectivity -type regular}] ||
    ![lp_capture $pre_special {verifyConnectivity -type special -nets {VDD VSS}}]} {
    lp_abort BASELINE_CONNECTIVITY_CAPTURE_FAILED
}
set pre_drc_count [lp_violation_count $pre_drc]
set pre_regular_count [lp_violation_count $pre_regular]
set pre_special_count [lp_violation_count $pre_special]
set expected_nets {n_9677 n_9693 n_9696 n_9697 n_9706 n_9721}

set status(PRE_DRC_VIOLATION_COUNT) $pre_drc_count
set status(PRE_DRC_MARKER_COUNT) $pre_marker_count
set status(PRE_MARKER_DATABASE_TOTAL) $pre_database_total
set status(PRE_EXCLUDED_ANTENNA_MARKER_COUNT) $pre_antenna_count
set status(PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $pre_connectivity_count
set status(PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $pre_regular_count
set status(PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $pre_special_count
set status(PRE_MIN_AREA_NETS) [join $pre_nets { }]

if {![string is integer -strict $pre_drc_count] || $pre_drc_count != 6 ||
    ![string is integer -strict $pre_marker_count] || $pre_marker_count != 6 ||
    [llength $pre_rows] != 6 || $pre_nets ne $expected_nets ||
    ![string is integer -strict $pre_regular_count] || $pre_regular_count != 0 ||
    ![string is integer -strict $pre_special_count] || $pre_special_count != 0 ||
    ![string is integer -strict $pre_database_total] || $pre_database_total != 27 ||
    ![string is integer -strict $pre_antenna_count] || $pre_antenna_count != 21 ||
    ![string is integer -strict $pre_connectivity_count] || $pre_connectivity_count != 0} {
    lp_abort BASELINE_PRECONDITION_FAILED \
        "drc=$pre_drc_count markers=$pre_marker_count database_total=$pre_database_total rows=[llength $pre_rows] nets=$pre_nets regular=$pre_regular_count special=$pre_special_count antenna=$pre_antenna_count connectivity=$pre_connectivity_count"
}

# net marker-box start-x start-y end-x length source-Q source-Q-x source-Q-y
if {$trial_revision eq "R1"} {
    set patch_contract [list \
        [list n_9696 {719.69 158.62 720.07 158.90} 719.88 158.76 719.32 0.56 g14627__2802/Q 716.61 159.02] \
        [list n_9693 {210.09 201.74 210.47 202.02} 210.28 201.88 209.72 0.56 g14630__8246/Q 207.01 201.62] \
        [list n_9697 {663.13 192.78 663.51 193.06} 663.32 192.92 662.76 0.56 g14626__1617/Q 660.05 192.66] \
        [list n_9677 {1666.09 201.74 1666.47 202.02} 1666.28 201.88 1666.84 0.56 g14646__2398/Q 1669.55 201.62] \
        [list n_9721 {1792.65 212.38 1793.03 212.66} 1792.84 212.52 1792.28 0.56 g14602__8246/Q 1789.57 212.78] \
        [list n_9706 {1826.81 212.38 1827.19 212.66} 1827.00 212.52 1827.56 0.56 g14617__5477/Q 1830.27 212.78]]
} else {
    set patch_contract [list \
        [list n_9696 {719.69 158.62 720.07 158.90} 719.88 158.76 719.04 0.84 g14627__2802/Q 716.61 159.02] \
        [list n_9693 {210.09 201.74 210.47 202.02} 210.28 201.88 209.44 0.84 g14630__8246/Q 207.01 201.62] \
        [list n_9697 {663.13 192.78 663.51 193.06} 663.32 192.92 662.48 0.84 g14626__1617/Q 660.05 192.66] \
        [list n_9677 {1666.09 201.74 1666.47 202.02} 1666.28 201.88 1667.12 0.84 g14646__2398/Q 1669.55 201.62] \
        [list n_9721 {1792.65 212.38 1793.03 212.66} 1792.84 212.52 1792.28 0.56 g14602__8246/Q 1789.57 212.78] \
        [list n_9706 {1826.81 212.38 1827.19 212.66} 1827.00 212.52 1827.56 0.56 g14617__5477/Q 1830.27 212.78]]
}

array set marker_row_by_net {}
foreach row $pre_rows { set marker_row_by_net([lindex $row 0]) $row }
set contract_path [file join $reports min_area_landing_patch_contract.tsv]
set contract_fh [open $contract_path w]
puts $contract_fh "net\tmarker_box\tstart_x\tstart_y\tend_x\tend_y\tlength_um\twidth_um\tsource_q\tsource_q_point\tmarker_status\tvia1_status\tmet2_endpoint_status\tsource_q_status\tinside_source_inst_status\tcontract_status"
set contract_validated_count 0
set contract_failures [list]

foreach contract $patch_contract {
    lassign $contract net expected_box start_x start_y end_x patch_length source_q source_q_x source_q_y
    set marker_status FAIL
    set via_status FAIL
    set met2_status FAIL
    set source_status FAIL
    set inside_status FAIL
    set net_handles [list]
    catch {set net_handles [lp_valid_handles [dbGet top.nets.name $net -p]]}
    set net_handle ""
    if {[llength $net_handles] == 1} { set net_handle [lindex $net_handles 0] }

    if {[info exists marker_row_by_net($net)] &&
        [lp_box_matches [lindex $marker_row_by_net($net) 2] $expected_box]} {
        set marker_status PASS
    }

    if {$net_handle ne ""} {
        set vias [list]
        catch {set vias [lp_valid_handles [dbGet "${net_handle}.vias"]]}
        foreach via $vias {
            set via_name UNKNOWN
            set via_point UNKNOWN
            catch {set via_name [dbGet "${via}.via.name"]}
            if {$via_name eq "" || $via_name eq "0x0" || $via_name eq "UNKNOWN"} {
                catch {set via_name [dbGet "${via}.name"]}
            }
            catch {set via_point [dbGet "${via}.pt"]}
            if {$via_name eq "VIA1_o" && [lp_point_matches $via_point $start_x $start_y]} {
                set via_status PASS
                break
            }
        }

        set wires [list]
        catch {set wires [lp_valid_handles [dbGet "${net_handle}.wires"]]}
        foreach wire $wires {
            set layer UNKNOWN
            set width UNKNOWN
            set points UNKNOWN
            catch {set layer [dbGet "${wire}.layer.name"]}
            catch {set width [dbGet "${wire}.width"]}
            catch {set points [dbGet "${wire}.pts"]}
            if {$layer eq "MET2" && [lp_close $width 0.28] &&
                [lp_has_endpoint $points $start_x $start_y]} {
                set met2_status PASS
                break
            }
        }

        set iterms [list]
        catch {set iterms [lp_valid_handles [dbGet "${net_handle}.instTerms"]]}
        foreach iterm $iterms {
            set iterm_name UNKNOWN
            catch {set iterm_name [dbGet "${iterm}.name"]}
            if {$iterm_name ne $source_q} { continue }
            set source_point UNKNOWN
            set source_box UNKNOWN
            catch {set source_point [dbGet "${iterm}.pt"]}
            catch {set source_box [dbGet "${iterm}.inst.box"]}
            if {[lp_point_matches $source_point $source_q_x $source_q_y] &&
                (($end_x < $start_x && $source_q_x < $start_x) ||
                 ($end_x > $start_x && $source_q_x > $start_x))} {
                set source_status PASS
            }
            set source_box [lp_flat_box $source_box]
            if {[lp_point_in_box $start_x $start_y $source_box] &&
                [lp_point_in_box $end_x $start_y $source_box]} {
                set inside_status PASS
            }
            break
        }
    }

    set contract_status FAIL
    if {$marker_status eq "PASS" && $via_status eq "PASS" &&
        $met2_status eq "PASS" && $source_status eq "PASS" &&
        $inside_status eq "PASS" &&
        [lp_close [expr {abs($end_x - $start_x)}] $patch_length]} {
        set contract_status PASS
        incr contract_validated_count
    } else {
        lappend contract_failures "$net:marker=$marker_status:via1=$via_status:met2=$met2_status:source=$source_status:inside=$inside_status"
    }
    puts $contract_fh "$net\t[join $expected_box { }]\t[format %.2f $start_x]\t[format %.2f $start_y]\t[format %.2f $end_x]\t[format %.2f $start_y]\t[format %.2f $patch_length]\t0.28\t$source_q\t[format {%.2f %.2f} $source_q_x $source_q_y]\t$marker_status\t$via_status\t$met2_status\t$source_status\t$inside_status\t$contract_status"
}
close $contract_fh
set status(CONTRACT_VALIDATED_COUNT) $contract_validated_count
if {$contract_validated_count != 6 || [llength $contract_failures] != 0} {
    lp_abort PATCH_CONTRACT_PRECONDITION_FAILED [join $contract_failures {,}]
}

set command_path [file join $reports min_area_landing_patch_commands.rpt]
set command_fh [open $command_path w]
puts $command_fh "LABEL=SPADMIC_OOC_MIN_AREA_LANDING_PATCH_COMMANDS"
puts $command_fh "POLICY=$command_policy"
puts $command_fh "TRIAL_REVISION=$trial_revision"
puts $command_fh "PATCH_WIDTH_UM=0.28"
puts $command_fh "PATCH_LENGTH_POLICY=$patch_length_policy"
if {$trial_revision eq "R1"} {
    puts $command_fh "PATCH_LENGTH_UM=0.56"
} else {
    puts $command_fh "PATCH_LENGTH_UM=MIXED_0.56_0.84"
}
puts $command_fh "CONTRACT_VALIDATED_COUNT=$contract_validated_count"

set patch_attempted_count 0
set patch_applied_count 0
set command_failed 0
foreach contract $patch_contract {
    lassign $contract net expected_box start_x start_y end_x patch_length source_q source_q_x source_q_y
    incr patch_attempted_count
    set label "PATCH_${net}"
    puts $command_fh "${label}_START=[format {%.2f %.2f} $start_x $start_y]"
    puts $command_fh "${label}_END=[format {%.2f %.2f} $end_x $start_y]"
    puts $command_fh "${label}_LENGTH_UM=[format %.2f $patch_length]"
    puts $command_fh "${label}_SOURCE_Q=$source_q"
    set setup_command [list setEditMode \
        -nets $net \
        -shape None \
        -force_regular 1 \
        -layer_horizontal MET1 \
        -layer_vertical MET1 \
        -snap_to_track_regular 0 \
        -width_horizontal 0.28 \
        -width_vertical 0.28]
    if {![lp_run_command $command_fh "${label}_SET_EDIT_MODE" $setup_command] ||
        ![lp_run_command $command_fh "${label}_SET_TOOL" {uiSetTool addWire}] ||
        ![lp_run_command $command_fh "${label}_ADD_ROUTE" [list editAddRoute $start_x $start_y]] ||
        ![lp_run_command $command_fh "${label}_COMMIT_ROUTE" [list editCommitRoute $end_x $start_y]]} {
        set command_failed 1
        break
    }
    incr patch_applied_count
    puts $command_fh "${label}_APPLIED=YES"
    flush $command_fh
}
catch {uiSetTool select}
catch {setEditMode -reset}

puts $command_fh "PATCH_ATTEMPTED_COUNT=$patch_attempted_count"
puts $command_fh "PATCH_APPLIED_COUNT=$patch_applied_count"
puts $command_fh "COMMAND_PASS_COUNT=$command_pass_count"
puts $command_fh "COMMAND_FAIL_COUNT=$command_fail_count"
close $command_fh
set command_fh ""
set status(PATCH_ATTEMPTED_COUNT) $patch_attempted_count
set status(PATCH_APPLIED_COUNT) $patch_applied_count
set status(COMMAND_PASS_COUNT) $command_pass_count
set status(COMMAND_FAIL_COUNT) $command_fail_count

set post_drc [file join $reports verify_drc_post_trial.rpt]
set post_markers [file join $reports drc_markers_post_trial.tsv]
set post_regular [file join $reports verify_connectivity_regular_post_trial.rpt]
set post_special [file join $reports verify_connectivity_special_post_trial.rpt]
if {![lp_capture $post_drc {verify_drc}]} { lp_abort POST_DRC_CAPTURE_FAILED }
if {[catch {
    lassign [lp_write_marker_dump $post_markers] \
        post_marker_count post_database_total post_antenna_count post_connectivity_count
} marker_error]} {
    lp_abort POST_MARKER_DUMP_FAILED $marker_error
}
set post_rows [lp_min_area_rows]
set post_nets [lp_row_nets $post_rows]
if {![lp_capture $post_regular {verifyConnectivity -type regular}] ||
    ![lp_capture $post_special {verifyConnectivity -type special -nets {VDD VSS}}]} {
    lp_abort POST_CONNECTIVITY_CAPTURE_FAILED
}
set post_drc_count [lp_violation_count $post_drc]
set post_regular_count [lp_violation_count $post_regular]
set post_special_count [lp_violation_count $post_special]

set status(FINAL_DRC_VIOLATION_COUNT) $post_drc_count
set status(FINAL_DRC_MARKER_COUNT) $post_marker_count
set status(FINAL_MARKER_DATABASE_TOTAL) $post_database_total
set status(FINAL_EXCLUDED_ANTENNA_MARKER_COUNT) $post_antenna_count
set status(FINAL_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $post_connectivity_count
set status(FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $post_regular_count
set status(FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $post_special_count
set status(FINAL_MIN_AREA_NETS) [join $post_nets { }]

set numeric_post [expr {
    [string is integer -strict $post_drc_count] &&
    [string is integer -strict $post_marker_count] &&
    [string is integer -strict $post_database_total] &&
    [string is integer -strict $post_antenna_count] &&
    [string is integer -strict $post_connectivity_count] &&
    [string is integer -strict $post_regular_count] &&
    [string is integer -strict $post_special_count]
}]
if {!$numeric_post ||
    $post_database_total != ($post_marker_count + $post_antenna_count + $post_connectivity_count)} {
    set status(RESULT) PATCH_POSTCHECK_INCOMPLETE
} elseif {$command_failed || $command_fail_count != 0 || $patch_applied_count != 6} {
    set status(RESULT) PATCH_COMMAND_FAILED
} elseif {$post_regular_count != 0 || $post_special_count != 0 || $post_connectivity_count != 0} {
    set status(RESULT) PATCH_CONNECTIVITY_REGRESSION
} elseif {$post_antenna_count != 21} {
    set status(RESULT) PATCH_RESTORED_ANTENNA_SENTINEL_CHANGED
} elseif {$post_drc_count == 0 && $post_marker_count == 0 &&
        [llength $post_rows] == 0 && $post_database_total == 21} {
    set status(STATUS) PASS
    set status(RESULT) $validated_result
} elseif {$post_drc_count == 6 && $post_marker_count == 6 &&
        [llength $post_rows] == 6 && $post_nets eq $expected_nets &&
        $post_database_total == 27} {
    set status(RESULT) $no_improvement_result
} else {
    set status(RESULT) $changed_result
}

lp_write_status
if {$status(STATUS) eq "PASS"} { exit 0 }
exit 8
