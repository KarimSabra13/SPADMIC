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

proc lp_expand_box {box delta} {
    if {![lp_numeric_box $box]} {
        return [list UNKNOWN UNKNOWN UNKNOWN UNKNOWN]
    }
    lassign $box llx lly urx ury
    return [list \
        [expr {$llx - $delta}] \
        [expr {$lly - $delta}] \
        [expr {$urx + $delta}] \
        [expr {$ury + $delta}]]
}

proc lp_boxes_intersect {lhs rhs} {
    if {![lp_numeric_box $lhs] || ![lp_numeric_box $rhs]} { return 0 }
    lassign $lhs llx1 lly1 urx1 ury1
    lassign $rhs llx2 lly2 urx2 ury2
    return [expr {$llx1 <= $urx2 && $urx1 >= $llx2 &&
                  $lly1 <= $ury2 && $ury1 >= $lly2}]
}

proc lp_wire_attr {wire attribute} {
    if {[catch {set value [dbGet "${wire}.${attribute}"]} err]} {
        return [list FAIL UNKNOWN [lp_value $err]]
    }
    return [list PASS $value NONE]
}

proc lp_find_canonical_stub_endpoint {net marker_box via_x via_y direction_sign} {
    set net_handles [list]
    catch {set net_handles [lp_valid_handles [dbGet top.nets.name $net -p]]}
    if {[llength $net_handles] != 1} {
        return [list FAIL NONE UNKNOWN UNKNOWN UNKNOWN UNKNOWN]
    }
    set wires [list]
    catch {set wires [lp_valid_handles [dbGet "[lindex $net_handles 0].wires"]]}
    set candidates [list]
    foreach wire $wires {
        lassign [lp_wire_attr $wire box] box_status box_value box_error
        lassign [lp_wire_attr $wire layer.name] layer_status layer layer_error
        lassign [lp_wire_attr $wire status] route_status_status route_status route_status_error
        lassign [lp_wire_attr $wire shape] shape_status shape shape_error
        lassign [lp_wire_attr $wire width] width_status width width_error
        lassign [lp_wire_attr $wire length] length_status length length_error
        lassign [lp_wire_attr $wire pts] pts_status pts pts_error
        if {$box_status ne "PASS" || $layer_status ne "PASS" ||
            $route_status_status ne "PASS" || $shape_status ne "PASS" ||
            $width_status ne "PASS" || $length_status ne "PASS" ||
            $pts_status ne "PASS" || $layer ne "MET1" ||
            ![string equal -nocase $route_status fixed] || $shape ne "0x0" ||
            ![lp_close $width 0.23] || ![lp_close $length 0.385]} {
            continue
        }
        set flat_box [lp_flat_box $box_value]
        if {![lp_boxes_intersect $flat_box $marker_box]} { continue }
        set values [lp_flat_values $pts]
        if {[llength $values] < 4} { continue }
        lassign [lrange $values 0 3] x1 y1 x2 y2
        if {![lp_close $y1 $y2]} { continue }
        set near1 [expr {[lp_close $x1 $via_x] && abs($y1 - $via_y) <= 0.050}]
        set near2 [expr {[lp_close $x2 $via_x] && abs($y2 - $via_y) <= 0.050}]
        if {$near1 == $near2} { continue }
        if {$near1} {
            set far_x $x2
            set far_y $y2
        } else {
            set far_x $x1
            set far_y $y1
        }
        if {($direction_sign < 0 && $far_x >= $via_x) ||
            ($direction_sign > 0 && $far_x <= $via_x)} {
            continue
        }
        lappend candidates [list $wire $flat_box $far_x $far_y [lp_value $pts]]
    }
    if {[llength $candidates] != 1} {
        return [list FAIL NONE UNKNOWN UNKNOWN UNKNOWN UNKNOWN]
    }
    return [linsert [lindex $candidates 0] 0 PASS]
}

proc lp_write_wire_snapshot {path phase patch_contract} {
    set fh [open $path w]
    puts $fh "phase\tnet\tmarker_box\trequested_width_um\twire_index\twire_handle\tlocal_relation\tbox_status\tbox\tlayer_status\tlayer\troute_status_status\troute_status\tshape_status\tshape\twidth_status\twidth\tlength_status\tlength\tpts_status\tpts"
    set net_query_pass_count 0
    set wire_row_count 0
    set local_met1_row_count 0
    set attribute_fail_count 0
    foreach contract $patch_contract {
        lassign $contract net marker_box start_x start_y end_x patch_length patch_width source_q source_q_x source_q_y patch_direction
        set net_handles [list]
        catch {set net_handles [lp_valid_handles [dbGet top.nets.name $net -p]]}
        if {[llength $net_handles] != 1} {
            continue
        }
        set wires [list]
        if {[catch {set wires [lp_valid_handles [dbGet "[lindex $net_handles 0].wires"]]}]} {
            continue
        }
        incr net_query_pass_count
        set expanded_marker [lp_expand_box $marker_box 2.0]
        set wire_index 0
        foreach wire $wires {
            incr wire_index
            lassign [lp_wire_attr $wire box] box_status box_value box_error
            lassign [lp_wire_attr $wire layer.name] layer_status layer layer_error
            lassign [lp_wire_attr $wire status] route_status_status route_status route_status_error
            lassign [lp_wire_attr $wire shape] shape_status shape shape_error
            lassign [lp_wire_attr $wire width] width_status width width_error
            lassign [lp_wire_attr $wire length] length_status length length_error
            lassign [lp_wire_attr $wire pts] pts_status pts pts_error
            set flat_box [lp_flat_box $box_value]
            set relation UNKNOWN_BOX
            if {[lp_numeric_box $flat_box]} {
                if {[lp_boxes_intersect $flat_box $marker_box]} {
                    set relation INTERSECTS_MARKER
                } elseif {[lp_boxes_intersect $flat_box $expanded_marker]} {
                    set relation WITHIN_2UM_CONTEXT
                } else {
                    set relation OUTSIDE_CONTEXT
                }
            }
            if {$box_status ne "PASS" || $layer_status ne "PASS" ||
                $route_status_status ne "PASS" || $shape_status ne "PASS" ||
                $width_status ne "PASS" || $length_status ne "PASS" ||
                $pts_status ne "PASS"} {
                incr attribute_fail_count
            }
            if {$layer eq "MET1" &&
                ($relation eq "INTERSECTS_MARKER" ||
                 $relation eq "WITHIN_2UM_CONTEXT")} {
                incr local_met1_row_count
            }
            puts $fh "$phase\t$net\t[lp_value $marker_box]\t[format %.2f $patch_width]\t$wire_index\t[lp_value $wire]\t$relation\t$box_status\t[lp_value $flat_box]\t$layer_status\t[lp_value $layer]\t$route_status_status\t[lp_value $route_status]\t$shape_status\t[lp_value $shape]\t$width_status\t[lp_value $width]\t$length_status\t[lp_value $length]\t$pts_status\t[lp_value $pts]"
            incr wire_row_count
        }
    }
    close $fh
    return [list \
        $net_query_pass_count \
        $wire_row_count \
        $local_met1_row_count \
        $attribute_fail_count]
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
    set patch_direction_policy ALL_TOWARD_SOURCE
    set patch_width_policy UNIFORM_0.28
    set patch_width_um 0.28
    set validated_result SIX_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED
    set no_improvement_result SIX_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT
    set changed_result SIX_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
} elseif {$trial_revision eq "R2"} {
    set analysis_key STEP21_ANALYSIS
    set policy ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_LENGTH_MET1_LANDING_EXTENSIONS
    set command_policy EXACT_SIX_NET_MIXED_LENGTH_MET1_WIRE_EDITOR_EXTENSIONS
    set patch_length_policy FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56
    set patch_direction_policy ALL_TOWARD_SOURCE
    set patch_width_policy UNIFORM_0.28
    set patch_width_um 0.28
    set validated_result MIXED_LENGTH_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED
    set no_improvement_result MIXED_LENGTH_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT
    set changed_result MIXED_LENGTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
} elseif {$trial_revision eq "R3"} {
    set analysis_key STEP22_ANALYSIS
    set policy ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_DIRECTION_MET1_LANDING_EXTENSIONS
    set command_policy EXACT_SIX_NET_MIXED_DIRECTION_MET1_WIRE_EDITOR_EXTENSIONS
    set patch_length_policy FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56
    set patch_direction_policy FOUR_SURVIVORS_AWAY_FROM_SOURCE_TWO_CLOSED_TOWARD_SOURCE
    set patch_width_policy UNIFORM_0.28
    set patch_width_um 0.28
    set validated_result MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED
    set no_improvement_result MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT
    set changed_result MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
} elseif {$trial_revision eq "R4"} {
    set analysis_key STEP23_ANALYSIS
    set policy ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_WIDTH_MET1_LANDING_EXTENSIONS
    set command_policy EXACT_SIX_NET_MIXED_WIDTH_MET1_WIRE_EDITOR_EXTENSIONS
    set patch_length_policy UNIFORM_0.56
    set patch_direction_policy ALL_TOWARD_SOURCE
    set patch_width_policy FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28
    set patch_width_um MIXED_0.28_0.56
    set validated_result MIXED_WIDTH_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED
    set no_improvement_result MIXED_WIDTH_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT
    set changed_result MIXED_WIDTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
} elseif {$trial_revision eq "R5"} {
    set analysis_key STEP24_ANALYSIS
    set policy ONE_FRESH_PROCESS_ONE_RESTORE_R4_REPLAY_WITH_LOCAL_WIRE_MATERIALIZATION_CAPTURE
    set command_policy EXACT_SIX_NET_R4_REPLAY_FOR_WIRE_MATERIALIZATION_CAPTURE
    set patch_length_policy UNIFORM_0.56
    set patch_direction_policy ALL_TOWARD_SOURCE
    set patch_width_policy FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28
    set patch_width_um MIXED_0.28_0.56
    set validated_result WIRE_MATERIALIZATION_REPLAY_DRC_ZERO_VALIDATED
    set no_improvement_result WIRE_MATERIALIZATION_REPLAY_NO_IMPROVEMENT
    set changed_result WIRE_MATERIALIZATION_REPLAY_CHANGED_NOT_CLOSED
} elseif {$trial_revision eq "R6"} {
    set analysis_key STEP26_ANALYSIS
    set policy ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BASE_STUBS_THEN_FOUR_CHAINED_ENDPOINT_STUBS
    set command_policy EXACT_SIX_BASE_STUBS_THEN_FOUR_ACTUAL_ENDPOINT_CHAIN_STUBS
    set patch_length_policy FIRST_STAGE_SIX_0.56_SECOND_STAGE_FOUR_DYNAMIC_0.56
    set patch_direction_policy ALL_TOWARD_SOURCE
    set patch_width_policy UNIFORM_0.28
    set patch_width_um 0.28
    set validated_result CHAINED_ENDPOINT_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED
    set no_improvement_result CHAINED_ENDPOINT_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT
    set changed_result CHAINED_ENDPOINT_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
} else {
    error "SPADMIC_MIN_AREA_LANDING_UNSUPPORTED_REVISION: $trial_revision"
}
set expected_patch_count [expr {$trial_revision eq "R6" ? 10 : 6}]
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
set status(PATCH_DIRECTION_POLICY) $patch_direction_policy
set status(PATCH_WIDTH_POLICY) $patch_width_policy
set status(PATCH_WIDTH_UM) $patch_width_um
set status($analysis_key) $source_analysis
if {$trial_revision eq "R5"} {
    set status(MATERIALIZATION_CAPTURE_POLICY) PRE_AND_POST_ALL_WIRES_WITH_LOCAL_MET1_CLASSIFICATION
    set status(MATERIALIZATION_CAPTURE_STATUS) NOT_RUN
} elseif {$trial_revision eq "R6"} {
    set status(CHAIN_CAPTURE_POLICY) EXACT_FOUR_SURVIVOR_ACTUAL_ENDPOINTS_AFTER_VALIDATED_BASE_STAGE
    set status(BASE_STAGE_STATUS) NOT_RUN
    set status(CHAIN_ENDPOINT_CONTRACT_STATUS) NOT_RUN
    set status(CHAIN_STAGE_STATUS) NOT_RUN
}

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
} elseif {$trial_revision eq "R2"} {
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
} elseif {$trial_revision eq "R3"} {
    array set expected_analysis {
        LABEL SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS
        POLICY ISOLATED_IN_MEMORY_SIX_NET_MIXED_LENGTH_MET1_LANDING_PATCH_CLASSIFICATION
        STATUS PASS
        RESULT MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED
        TRIAL_REVISION R2
        TRIAL_PROCESS_STATUS FAIL
        TRIAL_PROCESS_RESULT MIXED_LENGTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
        METHOD_STATUS REJECTED_OR_INCOMPLETE
        PATCH_CONTRACT_STATUS PASS_EXACT_SIX_MIXED_LENGTH_EXTENSIONS
        PATCH_WIDTH_UM 0.28
        PATCH_LENGTH_POLICY FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56
        PATCH_LENGTH_UM MIXED_0.56_0.84
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
} elseif {$trial_revision eq "R4"} {
    array set expected_analysis {
        LABEL SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS
        POLICY ISOLATED_IN_MEMORY_SIX_NET_MIXED_DIRECTION_MET1_LANDING_PATCH_CLASSIFICATION
        STATUS PASS
        RESULT MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED
        TRIAL_REVISION R3
        TRIAL_PROCESS_STATUS FAIL
        TRIAL_PROCESS_RESULT MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
        METHOD_STATUS REJECTED_OR_INCOMPLETE
        PATCH_CONTRACT_STATUS PASS_EXACT_SIX_MIXED_DIRECTION_EXTENSIONS
        PATCH_WIDTH_UM 0.28
        PATCH_LENGTH_POLICY FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56
        PATCH_LENGTH_UM MIXED_0.56_0.84
        PATCH_DIRECTION_POLICY FOUR_SURVIVORS_AWAY_FROM_SOURCE_TWO_CLOSED_TOWARD_SOURCE
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
        REMOVED_MARKER_SIGNATURE_COUNT 2
        ADDED_MARKER_SIGNATURE_COUNT 0
        FINAL_MIN_AREA_NETS {n_9677 n_9693 n_9696 n_9697}
        SAVE_DESIGN NOT_RUN
        EXPORT NOT_RUN
        IMMUTABLE_PVS_STAGING NOT_RUN
        PVS_DECISION DO_NOT_RUN
        CANONICAL_RERUN_DECISION DO_NOT_RUN_FROM_THIS_STEP
        NEXT_METHOD_DECISION STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD
        ERROR_COUNT 0
    }
} elseif {$trial_revision eq "R5"} {
    array set expected_analysis {
        LABEL SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS
        POLICY ISOLATED_IN_MEMORY_SIX_NET_MIXED_WIDTH_MET1_LANDING_PATCH_CLASSIFICATION
        STATUS PASS
        RESULT MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED
        TRIAL_REVISION R4
        TRIAL_PROCESS_STATUS FAIL
        TRIAL_PROCESS_RESULT MIXED_WIDTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
        METHOD_STATUS REJECTED_OR_INCOMPLETE
        PATCH_CONTRACT_STATUS PASS_EXACT_SIX_MIXED_WIDTH_EXTENSIONS
        PATCH_WIDTH_POLICY FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28
        PATCH_WIDTH_UM MIXED_0.28_0.56
        PATCH_LENGTH_POLICY UNIFORM_0.56
        PATCH_LENGTH_UM 0.56
        PATCH_DIRECTION_POLICY ALL_TOWARD_SOURCE
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
} else {
    array set expected_analysis {
        LABEL SPADMIC_TX_PACKET_MIN_AREA_LANDING_MATERIALIZATION_ANALYSIS
        POLICY ISOLATED_IN_MEMORY_R4_REPLAY_WIRE_MATERIALIZATION_CLASSIFICATION
        STATUS PASS
        RESULT MIN_AREA_LANDING_MATERIALIZATION_PROBE_CLASSIFIED
        TRIAL_REVISION R5
        TRIAL_PROCESS_STATUS FAIL
        TRIAL_PROCESS_RESULT WIRE_MATERIALIZATION_REPLAY_CHANGED_NOT_CLOSED
        METHOD_STATUS DIAGNOSTIC_CAPTURE_COMPLETE
        PATCH_CONTRACT_STATUS PASS_EXACT_SIX_R4_REPLAY_EXTENSIONS
        PATCH_WIDTH_POLICY FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28
        PATCH_WIDTH_UM MIXED_0.28_0.56
        PATCH_LENGTH_POLICY UNIFORM_0.56
        PATCH_LENGTH_UM 0.56
        PATCH_DIRECTION_POLICY ALL_TOWARD_SOURCE
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
        NEXT_METHOD_DECISION COMPARE_CLOSED_CONTROL_AND_SURVIVOR_LANDING_COMPONENT_GEOMETRY
        ERROR_COUNT 0
        MATERIALIZATION_CAPTURE_STATUS COMPLETE
        MATERIALIZATION_STATUS UNIFORM_FIXED_0P23_BY_0P385_MET1_WITH_MET2_SPLIT
        PRE_WIRE_QUERY_PASS_NET_COUNT 6
        POST_WIRE_QUERY_PASS_NET_COUNT 6
        PRE_LOCAL_MET1_ROW_COUNT 0
        POST_LOCAL_MET1_ROW_COUNT 6
        WIRE_ATTRIBUTE_FAIL_COUNT 0
        ADDED_LOCAL_MET1_SIGNATURE_COUNT 6
        REMOVED_LOCAL_MET1_SIGNATURE_COUNT 0
        ADDED_LOCAL_MET2_SIGNATURE_COUNT 12
        REMOVED_LOCAL_MET2_SIGNATURE_COUNT 6
        CANONICAL_FIXED_STUB_NET_COUNT 6
        MET2_SPLIT_NET_COUNT 6
        MATERIALIZED_MET1_WIDTH_UM 0.23
        MATERIALIZED_MET1_CENTERLINE_LENGTH_UM 0.385
        WIRE_EDITOR_PARAMETER_CONTROL_STATUS REQUESTED_WIDTH_AND_ENDPOINT_NORMALIZED
        CLOSED_CONTROL_MATERIALIZATION_MATCH_STATUS PASS_SAME_CANONICAL_STUB_CLASS_AS_SURVIVORS
        PATCH_PARAMETER_SWEEP_DECISION RETIRED_LENGTH_DIRECTION_AND_WIDTH
        REQUESTED_WIDTH_MATERIALIZED_WIDE_NET_COUNT 0
        CANONICALIZED_WIDE_NET_COUNT 0
        NO_LOCAL_DELTA_WIDE_NET_COUNT 0
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

# net marker-box start-x start-y end-x length width source-Q source-Q-x source-Q-y direction
if {$trial_revision eq "R1" || $trial_revision eq "R6"} {
    set patch_contract [list \
        [list n_9696 {719.69 158.62 720.07 158.90} 719.88 158.76 719.32 0.56 0.28 g14627__2802/Q 716.61 159.02 TOWARD_SOURCE] \
        [list n_9693 {210.09 201.74 210.47 202.02} 210.28 201.88 209.72 0.56 0.28 g14630__8246/Q 207.01 201.62 TOWARD_SOURCE] \
        [list n_9697 {663.13 192.78 663.51 193.06} 663.32 192.92 662.76 0.56 0.28 g14626__1617/Q 660.05 192.66 TOWARD_SOURCE] \
        [list n_9677 {1666.09 201.74 1666.47 202.02} 1666.28 201.88 1666.84 0.56 0.28 g14646__2398/Q 1669.55 201.62 TOWARD_SOURCE] \
        [list n_9721 {1792.65 212.38 1793.03 212.66} 1792.84 212.52 1792.28 0.56 0.28 g14602__8246/Q 1789.57 212.78 TOWARD_SOURCE] \
        [list n_9706 {1826.81 212.38 1827.19 212.66} 1827.00 212.52 1827.56 0.56 0.28 g14617__5477/Q 1830.27 212.78 TOWARD_SOURCE]]
} elseif {$trial_revision eq "R2"} {
    set patch_contract [list \
        [list n_9696 {719.69 158.62 720.07 158.90} 719.88 158.76 719.04 0.84 0.28 g14627__2802/Q 716.61 159.02 TOWARD_SOURCE] \
        [list n_9693 {210.09 201.74 210.47 202.02} 210.28 201.88 209.44 0.84 0.28 g14630__8246/Q 207.01 201.62 TOWARD_SOURCE] \
        [list n_9697 {663.13 192.78 663.51 193.06} 663.32 192.92 662.48 0.84 0.28 g14626__1617/Q 660.05 192.66 TOWARD_SOURCE] \
        [list n_9677 {1666.09 201.74 1666.47 202.02} 1666.28 201.88 1667.12 0.84 0.28 g14646__2398/Q 1669.55 201.62 TOWARD_SOURCE] \
        [list n_9721 {1792.65 212.38 1793.03 212.66} 1792.84 212.52 1792.28 0.56 0.28 g14602__8246/Q 1789.57 212.78 TOWARD_SOURCE] \
        [list n_9706 {1826.81 212.38 1827.19 212.66} 1827.00 212.52 1827.56 0.56 0.28 g14617__5477/Q 1830.27 212.78 TOWARD_SOURCE]]
} elseif {$trial_revision eq "R3"} {
    set patch_contract [list \
        [list n_9696 {719.69 158.62 720.07 158.90} 719.88 158.76 720.72 0.84 0.28 g14627__2802/Q 716.61 159.02 AWAY_FROM_SOURCE] \
        [list n_9693 {210.09 201.74 210.47 202.02} 210.28 201.88 211.12 0.84 0.28 g14630__8246/Q 207.01 201.62 AWAY_FROM_SOURCE] \
        [list n_9697 {663.13 192.78 663.51 193.06} 663.32 192.92 664.16 0.84 0.28 g14626__1617/Q 660.05 192.66 AWAY_FROM_SOURCE] \
        [list n_9677 {1666.09 201.74 1666.47 202.02} 1666.28 201.88 1665.44 0.84 0.28 g14646__2398/Q 1669.55 201.62 AWAY_FROM_SOURCE] \
        [list n_9721 {1792.65 212.38 1793.03 212.66} 1792.84 212.52 1792.28 0.56 0.28 g14602__8246/Q 1789.57 212.78 TOWARD_SOURCE] \
        [list n_9706 {1826.81 212.38 1827.19 212.66} 1827.00 212.52 1827.56 0.56 0.28 g14617__5477/Q 1830.27 212.78 TOWARD_SOURCE]]
} else {
    set patch_contract [list \
        [list n_9696 {719.69 158.62 720.07 158.90} 719.88 158.76 719.32 0.56 0.56 g14627__2802/Q 716.61 159.02 TOWARD_SOURCE] \
        [list n_9693 {210.09 201.74 210.47 202.02} 210.28 201.88 209.72 0.56 0.56 g14630__8246/Q 207.01 201.62 TOWARD_SOURCE] \
        [list n_9697 {663.13 192.78 663.51 193.06} 663.32 192.92 662.76 0.56 0.56 g14626__1617/Q 660.05 192.66 TOWARD_SOURCE] \
        [list n_9677 {1666.09 201.74 1666.47 202.02} 1666.28 201.88 1666.84 0.56 0.56 g14646__2398/Q 1669.55 201.62 TOWARD_SOURCE] \
        [list n_9721 {1792.65 212.38 1793.03 212.66} 1792.84 212.52 1792.28 0.56 0.28 g14602__8246/Q 1789.57 212.78 TOWARD_SOURCE] \
        [list n_9706 {1826.81 212.38 1827.19 212.66} 1827.00 212.52 1827.56 0.56 0.28 g14617__5477/Q 1830.27 212.78 TOWARD_SOURCE]]
}

array set marker_row_by_net {}
foreach row $pre_rows { set marker_row_by_net([lindex $row 0]) $row }
set contract_path [file join $reports min_area_landing_patch_contract.tsv]
set contract_fh [open $contract_path w]
puts $contract_fh "net\tmarker_box\tstart_x\tstart_y\tend_x\tend_y\tlength_um\twidth_um\tsource_q\tsource_q_point\tdirection\tmarker_status\tvia1_status\tmet2_endpoint_status\tsource_q_status\tinside_source_inst_status\tcontract_status"
set contract_validated_count 0
set contract_failures [list]

foreach contract $patch_contract {
    lassign $contract net expected_box start_x start_y end_x patch_length patch_width source_q source_q_x source_q_y patch_direction
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
            set direction_matches [expr {
                ($patch_direction eq "TOWARD_SOURCE" &&
                 (($end_x < $start_x && $source_q_x < $start_x) ||
                  ($end_x > $start_x && $source_q_x > $start_x))) ||
                ($patch_direction eq "AWAY_FROM_SOURCE" &&
                 (($end_x < $start_x && $source_q_x > $start_x) ||
                  ($end_x > $start_x && $source_q_x < $start_x)))
            }]
            if {[lp_point_matches $source_point $source_q_x $source_q_y] &&
                $direction_matches} {
                set source_status PASS
            }
            set source_box [lp_flat_box $source_box]
            set half_width [expr {$patch_width / 2.0}]
            if {[lp_point_in_box $start_x [expr {$start_y - $half_width}] $source_box] &&
                [lp_point_in_box $start_x [expr {$start_y + $half_width}] $source_box] &&
                [lp_point_in_box $end_x [expr {$start_y - $half_width}] $source_box] &&
                [lp_point_in_box $end_x [expr {$start_y + $half_width}] $source_box]} {
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
        lappend contract_failures "$net:marker=$marker_status:via1=$via_status:met2=$met2_status:source=$source_status:direction=$patch_direction:width=$patch_width:inside=$inside_status"
    }
    puts $contract_fh "$net\t[join $expected_box { }]\t[format %.2f $start_x]\t[format %.2f $start_y]\t[format %.2f $end_x]\t[format %.2f $start_y]\t[format %.2f $patch_length]\t[format %.2f $patch_width]\t$source_q\t[format {%.2f %.2f} $source_q_x $source_q_y]\t$patch_direction\t$marker_status\t$via_status\t$met2_status\t$source_status\t$inside_status\t$contract_status"
}
close $contract_fh
set status(CONTRACT_VALIDATED_COUNT) $contract_validated_count
if {$contract_validated_count != 6 || [llength $contract_failures] != 0} {
    lp_abort PATCH_CONTRACT_PRECONDITION_FAILED [join $contract_failures {,}]
}

set materialization_capture_status NOT_APPLICABLE
set pre_wire_attribute_fail_count 0
set post_wire_attribute_fail_count 0
if {$trial_revision eq "R5"} {
    set pre_wire_snapshot [file join $reports wire_snapshot_pre_trial.tsv]
    lassign [lp_write_wire_snapshot $pre_wire_snapshot PRE_EDIT $patch_contract] \
        pre_wire_query_pass_net_count \
        pre_wire_row_count \
        pre_local_met1_row_count \
        pre_wire_attribute_fail_count
    set status(PRE_WIRE_QUERY_PASS_NET_COUNT) $pre_wire_query_pass_net_count
    set status(PRE_WIRE_ROW_COUNT) $pre_wire_row_count
    set status(PRE_LOCAL_MET1_ROW_COUNT) $pre_local_met1_row_count
    set status(PRE_WIRE_ATTRIBUTE_FAIL_COUNT) $pre_wire_attribute_fail_count
    if {$pre_wire_query_pass_net_count != 6} {
        lp_abort PRE_WIRE_MATERIALIZATION_CAPTURE_FAILED \
            "resolved=$pre_wire_query_pass_net_count expected=6"
    }
}

set command_path [file join $reports min_area_landing_patch_commands.rpt]
set command_fh [open $command_path w]
puts $command_fh "LABEL=SPADMIC_OOC_MIN_AREA_LANDING_PATCH_COMMANDS"
puts $command_fh "POLICY=$command_policy"
puts $command_fh "TRIAL_REVISION=$trial_revision"
puts $command_fh "PATCH_WIDTH_POLICY=$patch_width_policy"
puts $command_fh "PATCH_WIDTH_UM=$patch_width_um"
puts $command_fh "PATCH_LENGTH_POLICY=$patch_length_policy"
puts $command_fh "PATCH_DIRECTION_POLICY=$patch_direction_policy"
if {$trial_revision eq "R5"} {
    puts $command_fh "MATERIALIZATION_CAPTURE_POLICY=PRE_AND_POST_ALL_WIRES_WITH_LOCAL_MET1_CLASSIFICATION"
} elseif {$trial_revision eq "R6"} {
    puts $command_fh "CHAIN_CAPTURE_POLICY=EXACT_FOUR_SURVIVOR_ACTUAL_ENDPOINTS_AFTER_VALIDATED_BASE_STAGE"
}
if {$trial_revision eq "R2" || $trial_revision eq "R3"} {
    puts $command_fh "PATCH_LENGTH_UM=MIXED_0.56_0.84"
} else {
    puts $command_fh "PATCH_LENGTH_UM=0.56"
}
puts $command_fh "CONTRACT_VALIDATED_COUNT=$contract_validated_count"

set patch_attempted_count 0
set patch_applied_count 0
set command_failed 0
foreach contract $patch_contract {
    lassign $contract net expected_box start_x start_y end_x patch_length patch_width source_q source_q_x source_q_y patch_direction
    incr patch_attempted_count
    set label "PATCH_${net}"
    puts $command_fh "${label}_START=[format {%.2f %.2f} $start_x $start_y]"
    puts $command_fh "${label}_END=[format {%.2f %.2f} $end_x $start_y]"
    puts $command_fh "${label}_LENGTH_UM=[format %.2f $patch_length]"
    puts $command_fh "${label}_WIDTH_UM=[format %.2f $patch_width]"
    puts $command_fh "${label}_DIRECTION=$patch_direction"
    puts $command_fh "${label}_SOURCE_Q=$source_q"
    set setup_command [list setEditMode \
        -nets $net \
        -shape None \
        -force_regular 1 \
        -layer_horizontal MET1 \
        -layer_vertical MET1 \
        -snap_to_track_regular 0 \
        -width_horizontal $patch_width \
        -width_vertical $patch_width]
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

set base_patch_attempted_count $patch_attempted_count
set base_patch_applied_count $patch_applied_count
set chain_patch_attempted_count 0
set chain_patch_applied_count 0
if {$trial_revision eq "R6"} {
    if {$command_failed || $command_fail_count != 0 ||
        $base_patch_attempted_count != 6 || $base_patch_applied_count != 6} {
        set status(PATCH_ATTEMPTED_COUNT) $patch_attempted_count
        set status(PATCH_APPLIED_COUNT) $patch_applied_count
        set status(COMMAND_PASS_COUNT) $command_pass_count
        set status(COMMAND_FAIL_COUNT) $command_fail_count
        lp_abort BASE_STAGE_COMMAND_FAILED \
            "attempted=$base_patch_attempted_count applied=$base_patch_applied_count command_pass=$command_pass_count command_fail=$command_fail_count"
    }

    set base_drc [file join $reports verify_drc_after_base_stage.rpt]
    set base_markers [file join $reports drc_markers_after_base_stage.tsv]
    set base_regular [file join $reports verify_connectivity_regular_after_base_stage.rpt]
    set base_special [file join $reports verify_connectivity_special_after_base_stage.rpt]
    if {![lp_capture $base_drc {verify_drc}]} {
        lp_abort BASE_STAGE_DRC_CAPTURE_FAILED
    }
    if {[catch {
        lassign [lp_write_marker_dump $base_markers] \
            base_marker_count base_database_total base_antenna_count base_connectivity_count
    } marker_error]} {
        lp_abort BASE_STAGE_MARKER_DUMP_FAILED $marker_error
    }
    set base_rows [lp_min_area_rows]
    set base_nets [lp_row_nets $base_rows]
    if {![lp_capture $base_regular {verifyConnectivity -type regular}] ||
        ![lp_capture $base_special {verifyConnectivity -type special -nets {VDD VSS}}]} {
        lp_abort BASE_STAGE_CONNECTIVITY_CAPTURE_FAILED
    }
    set base_drc_count [lp_violation_count $base_drc]
    set base_regular_count [lp_violation_count $base_regular]
    set base_special_count [lp_violation_count $base_special]
    set expected_survivor_nets {n_9677 n_9693 n_9696 n_9697}
    set base_marker_value_status PASS
    foreach row $base_rows {
        set message [lindex $row 3]
        if {![regexp -nocase {Actual:[[:space:]]+0[.]17770000[[:space:]]+Required:[[:space:]]+0[.]20200000} $message]} {
            set base_marker_value_status FAIL
        }
    }
    set status(BASE_DRC_VIOLATION_COUNT) $base_drc_count
    set status(BASE_DRC_MARKER_COUNT) $base_marker_count
    set status(BASE_MARKER_DATABASE_TOTAL) $base_database_total
    set status(BASE_EXCLUDED_ANTENNA_MARKER_COUNT) $base_antenna_count
    set status(BASE_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $base_connectivity_count
    set status(BASE_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $base_regular_count
    set status(BASE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $base_special_count
    set status(BASE_MIN_AREA_NETS) [join $base_nets { }]
    set status(BASE_MARKER_VALUE_STATUS) $base_marker_value_status
    if {![string is integer -strict $base_drc_count] || $base_drc_count != 4 ||
        ![string is integer -strict $base_marker_count] || $base_marker_count != 4 ||
        [llength $base_rows] != 4 || $base_nets ne $expected_survivor_nets ||
        $base_marker_value_status ne "PASS" ||
        ![string is integer -strict $base_regular_count] || $base_regular_count != 0 ||
        ![string is integer -strict $base_special_count] || $base_special_count != 0 ||
        ![string is integer -strict $base_database_total] || $base_database_total != 25 ||
        ![string is integer -strict $base_antenna_count] || $base_antenna_count != 21 ||
        ![string is integer -strict $base_connectivity_count] || $base_connectivity_count != 0} {
        lp_abort BASE_STAGE_EXACT_STATE_NOT_REPRODUCED \
            "drc=$base_drc_count markers=$base_marker_count rows=[llength $base_rows] nets=$base_nets values=$base_marker_value_status regular=$base_regular_count special=$base_special_count database_total=$base_database_total antenna=$base_antenna_count connectivity=$base_connectivity_count"
    }
    set status(BASE_STAGE_STATUS) PASS_EXACT_FOUR_0P1777_SURVIVORS

    set base_wire_snapshot [file join $reports wire_snapshot_after_base_stage.tsv]
    lassign [lp_write_wire_snapshot $base_wire_snapshot AFTER_BASE_STAGE $patch_contract] \
        base_wire_query_pass_net_count \
        base_wire_row_count \
        base_local_met1_row_count \
        base_wire_attribute_fail_count
    set status(BASE_WIRE_QUERY_PASS_NET_COUNT) $base_wire_query_pass_net_count
    set status(BASE_WIRE_ROW_COUNT) $base_wire_row_count
    set status(BASE_LOCAL_MET1_ROW_COUNT) $base_local_met1_row_count
    set status(BASE_WIRE_ATTRIBUTE_FAIL_COUNT) $base_wire_attribute_fail_count
    if {$base_wire_query_pass_net_count != 6 || $base_local_met1_row_count != 6 ||
        $base_wire_attribute_fail_count != 0} {
        lp_abort BASE_STAGE_WIRE_CAPTURE_FAILED \
            "resolved=$base_wire_query_pass_net_count local_met1=$base_local_met1_row_count attribute_fail=$base_wire_attribute_fail_count"
    }

    # net marker-box via-x via-y expected-far-x expected-far-y direction-sign source-Q
    set chain_specs [list \
        [list n_9696 {719.69 158.62 720.07 158.90} 719.88 158.76 719.495 158.795 -1 g14627__2802/Q] \
        [list n_9693 {210.09 201.74 210.47 202.02} 210.28 201.88 209.895 201.845 -1 g14630__8246/Q] \
        [list n_9697 {663.13 192.78 663.51 193.06} 663.32 192.92 662.935 192.885 -1 g14626__1617/Q] \
        [list n_9677 {1666.09 201.74 1666.47 202.02} 1666.28 201.88 1666.665 201.845 1 g14646__2398/Q]]
    set chain_contract_path [file join $reports min_area_chained_endpoint_contract.tsv]
    set chain_contract_fh [open $chain_contract_path w]
    puts $chain_contract_fh "net\tmarker_box\tcanonical_wire\tcanonical_box\tcanonical_pts\tstart_x\tstart_y\tend_x\tend_y\tlength_um\trequested_width_um\tdirection\tsource_q\tinside_source_inst_status\tcontract_status"
    set chain_contract [list]
    set chain_contract_validated_count 0
    set chain_contract_failures [list]
    foreach spec $chain_specs {
        lassign $spec net marker_box via_x via_y expected_start_x expected_start_y direction_sign source_q
        lassign [lp_find_canonical_stub_endpoint \
            $net $marker_box $via_x $via_y $direction_sign] \
            endpoint_status canonical_wire canonical_box start_x start_y canonical_pts
        set endpoint_match_status FAIL
        set inside_status FAIL
        set end_x UNKNOWN
        set direction UNKNOWN
        if {$endpoint_status eq "PASS" &&
            [lp_close $start_x $expected_start_x] &&
            [lp_close $start_y $expected_start_y]} {
            set endpoint_match_status PASS
            set end_x [expr {$start_x + ($direction_sign * 0.56)}]
            set direction [expr {$direction_sign < 0 ? "TOWARD_SOURCE_WEST" : "TOWARD_SOURCE_EAST"}]
            set net_handles [list]
            catch {set net_handles [lp_valid_handles [dbGet top.nets.name $net -p]]}
            if {[llength $net_handles] == 1} {
                set iterms [list]
                catch {set iterms [lp_valid_handles [dbGet "[lindex $net_handles 0].instTerms"]]}
                foreach iterm $iterms {
                    set iterm_name UNKNOWN
                    catch {set iterm_name [dbGet "${iterm}.name"]}
                    if {$iterm_name ne $source_q} { continue }
                    set source_box UNKNOWN
                    catch {set source_box [dbGet "${iterm}.inst.box"]}
                    set source_box [lp_flat_box $source_box]
                    if {[lp_point_in_box $start_x [expr {$start_y - 0.14}] $source_box] &&
                        [lp_point_in_box $start_x [expr {$start_y + 0.14}] $source_box] &&
                        [lp_point_in_box $end_x [expr {$start_y - 0.14}] $source_box] &&
                        [lp_point_in_box $end_x [expr {$start_y + 0.14}] $source_box]} {
                        set inside_status PASS
                    }
                    break
                }
            }
        }
        set contract_status FAIL
        if {$endpoint_match_status eq "PASS" && $inside_status eq "PASS"} {
            set contract_status PASS
            incr chain_contract_validated_count
            lappend chain_contract [list $net $start_x $start_y $end_x 0.56 0.28 $direction $source_q]
        } else {
            lappend chain_contract_failures \
                "$net:endpoint=$endpoint_status:match=$endpoint_match_status:inside=$inside_status:start=$start_x,$start_y"
        }
        set contract_start_x [expr {$endpoint_status eq "PASS" ? [format %.3f $start_x] : "UNKNOWN"}]
        set contract_start_y [expr {$endpoint_status eq "PASS" ? [format %.3f $start_y] : "UNKNOWN"}]
        set contract_end_x [expr {$endpoint_match_status eq "PASS" ? [format %.3f $end_x] : "UNKNOWN"}]
        puts $chain_contract_fh "$net\t[join $marker_box { }]\t[lp_value $canonical_wire]\t[lp_value $canonical_box]\t[lp_value $canonical_pts]\t$contract_start_x\t$contract_start_y\t$contract_end_x\t$contract_start_y\t0.56\t0.28\t$direction\t$source_q\t$inside_status\t$contract_status"
    }
    close $chain_contract_fh
    set status(CHAIN_ENDPOINT_CONTRACT_VALIDATED_COUNT) $chain_contract_validated_count
    if {$chain_contract_validated_count != 4 || [llength $chain_contract_failures] != 0} {
        lp_abort CHAIN_ENDPOINT_CONTRACT_FAILED [join $chain_contract_failures {,}]
    }
    set status(CHAIN_ENDPOINT_CONTRACT_STATUS) PASS_EXACT_FOUR_ACTUAL_CANONICAL_ENDPOINTS
    puts $command_fh "BASE_STAGE_STATUS=$status(BASE_STAGE_STATUS)"
    puts $command_fh "CHAIN_ENDPOINT_CONTRACT_VALIDATED_COUNT=$chain_contract_validated_count"

    foreach chain $chain_contract {
        lassign $chain net start_x start_y end_x chain_length chain_width direction source_q
        incr chain_patch_attempted_count
        incr patch_attempted_count
        set label "CHAIN_${net}"
        puts $command_fh "${label}_START=[format {%.3f %.3f} $start_x $start_y]"
        puts $command_fh "${label}_END=[format {%.3f %.3f} $end_x $start_y]"
        puts $command_fh "${label}_LENGTH_UM=[format %.2f $chain_length]"
        puts $command_fh "${label}_WIDTH_UM=[format %.2f $chain_width]"
        puts $command_fh "${label}_DIRECTION=$direction"
        puts $command_fh "${label}_SOURCE_Q=$source_q"
        set setup_command [list setEditMode \
            -nets $net \
            -shape None \
            -force_regular 1 \
            -layer_horizontal MET1 \
            -layer_vertical MET1 \
            -snap_to_track_regular 0 \
            -width_horizontal $chain_width \
            -width_vertical $chain_width]
        if {![lp_run_command $command_fh "${label}_SET_EDIT_MODE" $setup_command] ||
            ![lp_run_command $command_fh "${label}_SET_TOOL" {uiSetTool addWire}] ||
            ![lp_run_command $command_fh "${label}_ADD_ROUTE" [list editAddRoute $start_x $start_y]] ||
            ![lp_run_command $command_fh "${label}_COMMIT_ROUTE" [list editCommitRoute $end_x $start_y]]} {
            set command_failed 1
            break
        }
        incr chain_patch_applied_count
        incr patch_applied_count
        puts $command_fh "${label}_APPLIED=YES"
        flush $command_fh
    }
    catch {uiSetTool select}
    catch {setEditMode -reset}
    set status(CHAIN_STAGE_STATUS) \
        [expr {$chain_patch_applied_count == 4 ? "APPLIED_EXACT_FOUR" : "INCOMPLETE"}]
    set post_chain_wire_snapshot [file join $reports wire_snapshot_post_chain_stage.tsv]
    lassign [lp_write_wire_snapshot $post_chain_wire_snapshot AFTER_CHAIN_STAGE $patch_contract] \
        post_chain_wire_query_pass_net_count \
        post_chain_wire_row_count \
        post_chain_local_met1_row_count \
        post_chain_wire_attribute_fail_count
    set status(POST_CHAIN_WIRE_QUERY_PASS_NET_COUNT) $post_chain_wire_query_pass_net_count
    set status(POST_CHAIN_WIRE_ROW_COUNT) $post_chain_wire_row_count
    set status(POST_CHAIN_LOCAL_MET1_ROW_COUNT) $post_chain_local_met1_row_count
    set status(POST_CHAIN_WIRE_ATTRIBUTE_FAIL_COUNT) $post_chain_wire_attribute_fail_count
    if {$post_chain_wire_query_pass_net_count != 6 || $post_chain_wire_attribute_fail_count != 0} {
        lp_abort POST_CHAIN_WIRE_CAPTURE_FAILED \
            "resolved=$post_chain_wire_query_pass_net_count attribute_fail=$post_chain_wire_attribute_fail_count"
    }
}

puts $command_fh "BASE_PATCH_ATTEMPTED_COUNT=$base_patch_attempted_count"
puts $command_fh "BASE_PATCH_APPLIED_COUNT=$base_patch_applied_count"
puts $command_fh "CHAIN_PATCH_ATTEMPTED_COUNT=$chain_patch_attempted_count"
puts $command_fh "CHAIN_PATCH_APPLIED_COUNT=$chain_patch_applied_count"
puts $command_fh "PATCH_ATTEMPTED_COUNT=$patch_attempted_count"
puts $command_fh "PATCH_APPLIED_COUNT=$patch_applied_count"
puts $command_fh "COMMAND_PASS_COUNT=$command_pass_count"
puts $command_fh "COMMAND_FAIL_COUNT=$command_fail_count"
close $command_fh
set command_fh ""
set status(PATCH_ATTEMPTED_COUNT) $patch_attempted_count
set status(PATCH_APPLIED_COUNT) $patch_applied_count
set status(BASE_PATCH_ATTEMPTED_COUNT) $base_patch_attempted_count
set status(BASE_PATCH_APPLIED_COUNT) $base_patch_applied_count
set status(CHAIN_PATCH_ATTEMPTED_COUNT) $chain_patch_attempted_count
set status(CHAIN_PATCH_APPLIED_COUNT) $chain_patch_applied_count
set status(COMMAND_PASS_COUNT) $command_pass_count
set status(COMMAND_FAIL_COUNT) $command_fail_count

if {$trial_revision eq "R5"} {
    set post_wire_snapshot [file join $reports wire_snapshot_post_trial.tsv]
    lassign [lp_write_wire_snapshot $post_wire_snapshot POST_EDIT $patch_contract] \
        post_wire_query_pass_net_count \
        post_wire_row_count \
        post_local_met1_row_count \
        post_wire_attribute_fail_count
    set status(POST_WIRE_QUERY_PASS_NET_COUNT) $post_wire_query_pass_net_count
    set status(POST_WIRE_ROW_COUNT) $post_wire_row_count
    set status(POST_LOCAL_MET1_ROW_COUNT) $post_local_met1_row_count
    set status(POST_WIRE_ATTRIBUTE_FAIL_COUNT) $post_wire_attribute_fail_count
    set status(WIRE_ATTRIBUTE_FAIL_COUNT) \
        [expr {$pre_wire_attribute_fail_count + $post_wire_attribute_fail_count}]
    if {$post_wire_query_pass_net_count == 6 &&
        $pre_wire_attribute_fail_count == 0 &&
        $post_wire_attribute_fail_count == 0} {
        set materialization_capture_status COMPLETE
    } elseif {$post_wire_query_pass_net_count == 6} {
        set materialization_capture_status PARTIAL_ATTRIBUTE_FAILURES
    } else {
        set materialization_capture_status FAILED_NET_QUERY
    }
    set status(MATERIALIZATION_CAPTURE_STATUS) $materialization_capture_status
}

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
} elseif {$command_failed || $command_fail_count != 0 ||
        $patch_applied_count != $expected_patch_count} {
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
if {$trial_revision eq "R5" && $materialization_capture_status ne "COMPLETE"} {
    set status(STATUS) FAIL
    set status(RESULT) WIRE_MATERIALIZATION_CAPTURE_INCOMPLETE
}

lp_write_status
if {$status(STATUS) eq "PASS"} { exit 0 }
exit 8
