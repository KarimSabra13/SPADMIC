# Read-only local-geometry probe for the six residual TX MET1 minimum-area markers.

proc geo_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_MIN_AREA_GEOMETRY_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc geo_value {value} {
    if {$value eq ""} { return NONE }
    return [string map [list "\n" " " "\r" " " "\t" " "] $value]
}

proc geo_read_kv {path} {
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

proc geo_capture {path body} {
    if {[catch {redirect -file $path $body} err]} {
        set fh [open $path w]
        puts $fh "CAPTURE_STATUS=FAIL"
        puts $fh "ERROR=[geo_value $err]"
        close $fh
        return 0
    }
    return 1
}

proc geo_violation_count {path} {
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

proc geo_flat_box {raw} {
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

proc geo_box_is_numeric {box} {
    if {[llength $box] != 4} { return 0 }
    foreach value $box {
        if {![string is double -strict $value]} { return 0 }
    }
    return 1
}

proc geo_expand_box {box delta} {
    lassign $box llx lly urx ury
    return [list \
        [expr {$llx - $delta}] \
        [expr {$lly - $delta}] \
        [expr {$urx + $delta}] \
        [expr {$ury + $delta}]]
}

proc geo_boxes_intersect {lhs rhs} {
    if {![geo_box_is_numeric $lhs] || ![geo_box_is_numeric $rhs]} { return 0 }
    lassign $lhs llx1 lly1 urx1 ury1
    lassign $rhs llx2 lly2 urx2 ury2
    return [expr {$llx1 <= $urx2 && $urx1 >= $llx2 &&
                  $lly1 <= $ury2 && $ury1 >= $lly2}]
}

proc geo_unique_append {name value} {
    upvar 1 $name values
    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}

proc geo_valid_handles {raw} {
    set handles [list]
    foreach handle $raw {
        if {$handle eq "" || $handle eq "0x0" || $handle eq "NULL"} { continue }
        geo_unique_append handles $handle
    }
    return $handles
}

proc geo_is_antenna {type subtype message} {
    return [expr {
        [string equal -nocase $type "Antenna"] ||
        [regexp -nocase {Antenna|Ant.*Area|ProcessAntenna} $subtype] ||
        [regexp -nocase {Antenna|S[.]PAR|Antenna[[:space:]]+Side[[:space:]]+Area} $message]
    }]
}

proc geo_is_min_area {layer type subtype message} {
    return [expr {
        [string equal -nocase $layer "MET1"] &&
        [string equal -nocase $type "Geometry"] &&
        ([regexp -nocase {Minimal_Area|Minimum[[:space:]]+Area|Mar} $subtype] ||
         [regexp -nocase {Minimum[[:space:]]+Area|Minimal_Area} $message])
    }]
}

proc geo_write_marker_dump {path} {
    set markers [list]
    catch {set markers [dbGet top.markers]}
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
        if {[geo_is_antenna $type $subtype $message]} {
            incr excluded_antenna_count
            continue
        }
        if {[string equal -nocase $type "Connectivity"]} {
            incr excluded_connectivity_count
            continue
        }
        incr idx
        lassign [geo_flat_box $box] llx lly urx ury
        set cx UNKNOWN
        set cy UNKNOWN
        if {[string is double -strict $llx] && [string is double -strict $urx]} {
            set cx [format %.6f [expr {($llx + $urx) / 2.0}]]
        }
        if {[string is double -strict $lly] && [string is double -strict $ury]} {
            set cy [format %.6f [expr {($lly + $ury) / 2.0}]]
        }
        puts $fh "$idx\t[geo_value $marker]\t[geo_value $box]\t$llx\t$lly\t$urx\t$ury\t$cx\t$cy\t[geo_value $layer]\t[geo_value $type]\t[geo_value $subtype]\t[geo_value $message]"
    }
    close $fh
    return [list $idx $raw_count $excluded_antenna_count $excluded_connectivity_count]
}

proc geo_min_area_rows {} {
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
        if {![geo_is_min_area $layer $type $subtype $message]} { continue }
        if {![regexp -nocase {Regular[[:space:]]+Wire[[:space:]]+of[[:space:]]+Net[[:space:]]+([^[:space:]]+)} $message -> net]} {
            continue
        }
        lappend rows [list $net $marker [geo_flat_box $box] [geo_value $message]]
    }
    return $rows
}

proc geo_row_nets {rows} {
    set nets [list]
    foreach row $rows {
        geo_unique_append nets [lindex $row 0]
    }
    return [lsort $nets]
}

proc geo_row_signatures {rows} {
    set signatures [list]
    foreach row $rows {
        lappend signatures [list [lindex $row 0] [lindex $row 2] [lindex $row 3]]
    }
    return [lsort $signatures]
}

set query_pass_count 0
set query_fail_count 0

proc geo_try {command} {
    global query_pass_count query_fail_count
    if {[catch {set value [uplevel #0 $command]} err]} {
        incr query_fail_count
        return [list FAIL UNKNOWN [geo_value $err]]
    }
    incr query_pass_count
    return [list PASS $value NONE]
}

proc geo_attr {object attribute} {
    return [geo_try [list dbGet "${object}.${attribute}"]]
}

proc geo_report_query {fh key command} {
    puts $fh "${key}_COMMAND=[geo_value $command]"
    lassign [geo_try $command] query_status value error
    puts $fh "${key}_STATUS=$query_status"
    if {$query_status eq "PASS"} {
        puts $fh "${key}_VALUE=[geo_value $value]"
    } else {
        puts $fh "${key}_ERROR=$error"
    }
    return [list $query_status $value $error]
}

proc geo_capture_schema {object path} {
    if {[catch {redirect -file $path [list dbSchema $object]} err]} {
        set fh [open $path w]
        puts $fh "SCHEMA_STATUS=FAIL"
        puts $fh "ERROR=[geo_value $err]"
        close $fh
        return FAIL
    }
    return PASS
}

proc geo_capture_help {command path} {
    if {![catch {redirect -file $path [list man $command]}]} { return MAN }
    if {![catch {redirect -file $path [list help $command]}]} { return HELP }
    set fh [open $path w]
    puts $fh "HELP_STATUS=UNAVAILABLE"
    close $fh
    return UNAVAILABLE
}

proc geo_write_status {} {
    global status reports
    set fh [open [file join $reports min_area_geometry_probe_status.rpt] w]
    foreach key [lsort [array names status]] {
        puts $fh "$key=$status($key)"
    }
    close $fh
}

proc geo_abort {reason {detail ""}} {
    global status
    set status(STATUS) FAIL
    set status(RESULT) $reason
    if {$detail ne ""} { set status(ERROR) [geo_value $detail] }
    geo_write_status
    puts stderr "SPADMIC_MIN_AREA_GEOMETRY_ABORT: $reason: [geo_value $detail]"
    exit 8
}

set checkpoint [geo_env SPADMIC_MIN_AREA_GEOMETRY_CHECKPOINT]
set root [geo_env SPADMIC_MIN_AREA_GEOMETRY_ROOT]
set top [geo_env SPADMIC_MIN_AREA_GEOMETRY_TOP]
set step19_analysis [geo_env SPADMIC_MIN_AREA_GEOMETRY_STEP19_ANALYSIS]
set reports [file join $root reports]
file mkdir $reports

array set status {
    LABEL SPADMIC_OOC_MIN_AREA_GEOMETRY_PROBE
    POLICY ONE_FRESH_PROCESS_ONE_RESTORE_READ_ONLY_LOCAL_GEOMETRY_PROBE
    DESIGN_MODIFICATION NOT_RUN
    SOURCE_CHECKPOINT_WRITE NOT_RUN
    SAVE_DESIGN NOT_RUN
    EXPORT NOT_RUN
    PVS NOT_RUN
    RESTORE_DESIGN NOT_RUN
    STATUS FAIL
    RESULT PROBE_INCOMPLETE
}
set status(SOURCE_CHECKPOINT) $checkpoint
set status(STEP19_ANALYSIS) $step19_analysis

array set analysis_values [geo_read_kv $step19_analysis]
array set expected_analysis {
    STATUS PASS
    RESULT ITERATIVE_MIN_AREA_TRIAL_CLASSIFIED
    TRIAL_REVISION R2
    TRIAL_PROCESS_STATUS FAIL
    TRIAL_PROCESS_RESULT ITERATIVE_MIN_AREA_REPAIR_NO_IMPROVEMENT
    METHOD_STATUS REJECTED_OR_INCOMPLETE
    PRE_DRC_VIOLATION_COUNT 6
    FINAL_DRC_VIOLATION_COUNT 6
    DRC_COUNT_SEQUENCE {6 6}
    ITERATION_COUNT 1
    PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT 0
    FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT 0
    PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT 0
    FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT 0
    PRE_EXCLUDED_ANTENNA_MARKER_COUNT 21
    FINAL_EXCLUDED_ANTENNA_MARKER_COUNT 21
    PRE_MARKER_DATABASE_TOTAL 27
    FINAL_MARKER_DATABASE_TOTAL 27
    COMMAND_PASS_COUNT 22
    COMMAND_FAIL_COUNT 0
    PRE_MIN_AREA_NETS {n_9677 n_9693 n_9696 n_9697 n_9706 n_9721}
    FINAL_MIN_AREA_NETS {n_9677 n_9693 n_9696 n_9697 n_9706 n_9721}
    SAVE_DESIGN NOT_RUN
    EXPORT NOT_RUN
    PVS_DECISION DO_NOT_RUN
    ERROR_COUNT 0
}
foreach key [array names expected_analysis] {
    set actual MISSING
    if {[info exists analysis_values($key)]} { set actual $analysis_values($key) }
    if {$actual ne $expected_analysis($key)} {
        geo_abort STEP19_ANALYSIS_NOT_ACCEPTED "$key=$actual expected=$expected_analysis($key)"
    }
}
set expected_nets [lsort $analysis_values(FINAL_MIN_AREA_NETS)]

if {[catch {restoreDesign $checkpoint $top} restore_error]} {
    geo_abort RESTORE_FAILED $restore_error
}
set status(RESTORE_DESIGN) PASS

set pre_drc [file join $reports verify_drc_pre_probe.rpt]
set pre_markers [file join $reports drc_markers_pre_probe.tsv]
set pre_regular [file join $reports verify_connectivity_regular_pre_probe.rpt]
set pre_special [file join $reports verify_connectivity_special_pre_probe.rpt]
if {![geo_capture $pre_drc {verify_drc}]} { geo_abort BASELINE_DRC_CAPTURE_FAILED }
if {[catch {
    lassign [geo_write_marker_dump $pre_markers] \
        pre_marker_count pre_database_total pre_antenna_count pre_connectivity_count
} marker_error]} {
    geo_abort BASELINE_MARKER_DUMP_FAILED $marker_error
}
set pre_rows [geo_min_area_rows]
set pre_nets [geo_row_nets $pre_rows]
if {![geo_capture $pre_regular {verifyConnectivity -type regular}] ||
    ![geo_capture $pre_special {verifyConnectivity -type special -nets {VDD VSS}}]} {
    geo_abort BASELINE_CONNECTIVITY_CAPTURE_FAILED
}
set pre_drc_count [geo_violation_count $pre_drc]
set pre_regular_count [geo_violation_count $pre_regular]
set pre_special_count [geo_violation_count $pre_special]

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
    geo_abort BASELINE_PRECONDITION_FAILED \
        "drc=$pre_drc_count markers=$pre_marker_count database_total=$pre_database_total rows=[llength $pre_rows] nets=$pre_nets expected_nets=$expected_nets regular=$pre_regular_count special=$pre_special_count antenna=$pre_antenna_count connectivity=$pre_connectivity_count"
}

set schema_pass_count 0
set schema_fail_count 0
foreach object {net wire instTerm inst term pin pinShape marker layerShape shape viaInst} {
    set schema_status [geo_capture_schema $object [file join $reports "dbschema_${object}.rpt"]]
    set status(SCHEMA_${object}_STATUS) $schema_status
    if {$schema_status eq "PASS"} { incr schema_pass_count } else { incr schema_fail_count }
}
set status(SCHEMA_PASS_COUNT) $schema_pass_count
set status(SCHEMA_FAIL_COUNT) $schema_fail_count

set help_pass_count 0
set help_unavailable_count 0
foreach command {editAddRoute editCommitRoute setEditMode uiSetTool add_shape create_shape} {
    set help_status [geo_capture_help $command [file join $reports "man_${command}.rpt"]]
    set status(HELP_${command}_STATUS) $help_status
    if {$help_status eq "UNAVAILABLE"} {
        incr help_unavailable_count
    } else {
        incr help_pass_count
    }
}
set status(HELP_PASS_COUNT) $help_pass_count
set status(HELP_UNAVAILABLE_COUNT) $help_unavailable_count

set marker_geometry [file join $reports min_area_marker_geometry.tsv]
set net_topology [file join $reports min_area_net_topology.tsv]
set local_wires [file join $reports min_area_local_wires.tsv]
set local_vias [file join $reports min_area_local_vias.tsv]
set inst_terms [file join $reports min_area_inst_terms.tsv]
set pin_shapes [file join $reports min_area_pin_shapes.tsv]
set top_terms [file join $reports min_area_top_terms.tsv]
set raw_queries [file join $reports min_area_raw_queries.rpt]

set marker_fh [open $marker_geometry w]
set topology_fh [open $net_topology w]
set wire_fh [open $local_wires w]
set via_fh [open $local_vias w]
set iterm_fh [open $inst_terms w]
set pin_fh [open $pin_shapes w]
set term_fh [open $top_terms w]
set raw_fh [open $raw_queries w]
puts $marker_fh "net\tmarker_handle\tmarker_box\tllx\tlly\turx\tury\tactual_area_um2\trequired_area_um2\tadditional_area_um2\tmessage"
puts $topology_fh "net\tmarker_box\tnet_handle_status\tnet_handle\twire_query_status\twire_count\tlocal_wire_count\tvia_query_status\tvia_count\tlocal_via_count\tinst_term_query_status\tinst_term_count\ttop_term_query_status\ttop_term_count\tpin_shape_row_count"
puts $wire_fh "net\tmarker_box\twire_index\twire_handle\tlocal_relation\tbox_status\tbox\tlayer_status\tlayer\tstatus_status\tstatus\tshape_status\tshape\twidth_status\twidth\tlength_status\tlength\tpts_status\tpts"
puts $via_fh "net\tmarker_box\tvia_index\tvia_handle\tlocal_relation\tbox_status\tbox\tname_status\tname\tcut_layer_status\tcut_layer\tbottom_layer_status\tbottom_layer\ttop_layer_status\ttop_layer\tpoint_status\tpoint\tstatus_status\tstatus\torient_status\torient"
puts $iterm_fh "net\tinst_term_handle\tname_status\tname\tinst_status\tinst\tcell_status\tcell\tterm_status\tterm\tdirection_status\tdirection\tinst_box_status\tinst_box\tinst_pt_status\tinst_pt\torient_status\torient\tpoint_status\tpoint\tavg_point_status\tavg_point"
puts $pin_fh "net\tinst_term_handle\tinst\tcell\tterm\tpin_shape_handle\tlayer_status\tlayer\trect_status\trect\ttype_status\ttype\tname_status\tname\tcoordinate_space"
puts $term_fh "net\ttop_term_handle\tname_status\tname\tdirection_status\tdirection\tpoint_status\tpoint\tpin_shape_count"
puts $raw_fh "LABEL=SPADMIC_OOC_MIN_AREA_GEOMETRY_RAW_QUERIES"
puts $raw_fh "POLICY=CAUGHT_SCHEMA_GUIDED_DBGET_FALLBACKS"

set net_handle_pass_count 0
set wire_query_pass_net_count 0
set local_wire_net_count 0
set local_wire_row_count 0
set wire_context_row_count 0
set via_query_pass_net_count 0
set local_via_net_count 0
set local_via_row_count 0
set via_context_row_count 0
set inst_term_net_count 0
set inst_term_row_count 0
set top_term_row_count 0
set pin_shape_net_count 0
set pin_shape_row_count 0

foreach row $pre_rows {
    set net [lindex $row 0]
    set marker [lindex $row 1]
    set marker_box [lindex $row 2]
    set message [lindex $row 3]
    lassign $marker_box llx lly urx ury
    set actual_area UNKNOWN
    set required_area UNKNOWN
    set additional_area UNKNOWN
    if {[regexp -nocase {Actual:[[:space:]]*([0-9.]+)[[:space:]]+Required:[[:space:]]*([0-9.]+)} $message -> actual required]} {
        set actual_area [format %.8f $actual]
        set required_area [format %.8f $required]
        set additional_area [format %.8f [expr {$required - $actual}]]
    }
    puts $marker_fh "$net\t[geo_value $marker]\t[geo_value $marker_box]\t$llx\t$lly\t$urx\t$ury\t$actual_area\t$required_area\t$additional_area\t[geo_value $message]"

    puts $raw_fh ""
    puts $raw_fh "NET_${net}_BEGIN=YES"
    lassign [geo_report_query $raw_fh "NET_${net}_HANDLE" [list dbGet top.nets.name $net -p]] net_handle_status net_handle_raw net_handle_error
    set net_handles [geo_valid_handles $net_handle_raw]
    set net_handle NONE
    if {[llength $net_handles] == 1} {
        set net_handle [lindex $net_handles 0]
        incr net_handle_pass_count
    } else {
        set net_handle_status FAIL
    }

    set wire_query_status FAIL
    set wires [list]
    if {$net_handle ne "NONE"} {
        lassign [geo_report_query $raw_fh "NET_${net}_WIRES" [list dbGet "${net_handle}.wires"]] wire_query_status wire_raw wire_error
        if {$wire_query_status eq "PASS"} {
            set wires [geo_valid_handles $wire_raw]
            incr wire_query_pass_net_count
        }
        geo_report_query $raw_fh "NET_${net}_ALL_TERMS" [list dbGet "${net_handle}.allTerms"]
        geo_report_query $raw_fh "NET_${net}_INST_TERMS" [list dbGet "${net_handle}.instTerms"]
        geo_report_query $raw_fh "NET_${net}_TERMS" [list dbGet "${net_handle}.terms"]
    }

    set expanded_marker [geo_expand_box $marker_box 2.0]
    set local_count 0
    set wire_index 0
    foreach wire $wires {
        incr wire_index
        lassign [geo_attr $wire box] box_status box_value box_error
        set flat_wire_box [geo_flat_box $box_value]
        set relation UNKNOWN_BOX
        set include 0
        if {[geo_box_is_numeric $flat_wire_box]} {
            if {[geo_boxes_intersect $flat_wire_box $marker_box]} {
                set relation INTERSECTS_MARKER
                set include 1
            } elseif {[geo_boxes_intersect $flat_wire_box $expanded_marker]} {
                set relation WITHIN_2UM_CONTEXT
                set include 1
            }
        } else {
            set include 1
        }
        if {!$include} { continue }
        lassign [geo_attr $wire layer.name] layer_status layer layer_error
        lassign [geo_attr $wire status] route_status_status route_status route_status_error
        lassign [geo_attr $wire shape] shape_status shape shape_error
        lassign [geo_attr $wire width] width_status width width_error
        lassign [geo_attr $wire length] length_status length length_error
        lassign [geo_attr $wire pts] pts_status pts pts_error
        puts $wire_fh "$net\t[geo_value $marker_box]\t$wire_index\t[geo_value $wire]\t$relation\t$box_status\t[geo_value $flat_wire_box]\t$layer_status\t[geo_value $layer]\t$route_status_status\t[geo_value $route_status]\t$shape_status\t[geo_value $shape]\t$width_status\t[geo_value $width]\t$length_status\t[geo_value $length]\t$pts_status\t[geo_value $pts]"
        incr wire_context_row_count
        if {$relation eq "INTERSECTS_MARKER" || $relation eq "WITHIN_2UM_CONTEXT"} {
            incr local_count
            incr local_wire_row_count
        }
    }
    if {$local_count > 0} { incr local_wire_net_count }

    set via_query_status FAIL
    set via_handles [list]
    if {$net_handle ne "NONE"} {
        foreach attribute {vias viaInsts} {
            set query_key "NET_${net}_[string toupper $attribute]"
            lassign [geo_report_query $raw_fh $query_key [list dbGet "${net_handle}.${attribute}"]] candidate_status candidate_raw candidate_error
            if {$candidate_status eq "PASS"} { set via_query_status PASS }
            foreach handle [geo_valid_handles $candidate_raw] {
                geo_unique_append via_handles $handle
            }
        }
    }
    if {$via_query_status eq "PASS"} { incr via_query_pass_net_count }
    set local_via_count 0
    set via_index 0
    foreach via $via_handles {
        incr via_index
        lassign [geo_attr $via box] via_box_status via_box_value via_box_error
        set flat_via_box [geo_flat_box $via_box_value]
        set via_relation UNKNOWN_BOX
        set include_via 0
        if {[geo_box_is_numeric $flat_via_box]} {
            if {[geo_boxes_intersect $flat_via_box $marker_box]} {
                set via_relation INTERSECTS_MARKER
                set include_via 1
            } elseif {[geo_boxes_intersect $flat_via_box $expanded_marker]} {
                set via_relation WITHIN_2UM_CONTEXT
                set include_via 1
            }
        } else {
            set include_via 1
        }
        if {!$include_via} { continue }
        lassign [geo_attr $via via.name] via_name_status via_name via_name_error
        if {$via_name_status ne "PASS" || $via_name eq "" || $via_name eq "0x0"} {
            lassign [geo_attr $via name] via_name_status via_name via_name_error
        }
        lassign [geo_attr $via cutLayer.name] cut_layer_status cut_layer cut_layer_error
        lassign [geo_attr $via bottomLayer.name] bottom_layer_status bottom_layer bottom_layer_error
        lassign [geo_attr $via topLayer.name] top_layer_status top_layer top_layer_error
        lassign [geo_attr $via pt] via_point_status via_point via_point_error
        lassign [geo_attr $via status] via_status_status via_status via_status_error
        lassign [geo_attr $via orient] via_orient_status via_orient via_orient_error
        puts $via_fh "$net\t[geo_value $marker_box]\t$via_index\t[geo_value $via]\t$via_relation\t$via_box_status\t[geo_value $flat_via_box]\t$via_name_status\t[geo_value $via_name]\t$cut_layer_status\t[geo_value $cut_layer]\t$bottom_layer_status\t[geo_value $bottom_layer]\t$top_layer_status\t[geo_value $top_layer]\t$via_point_status\t[geo_value $via_point]\t$via_status_status\t[geo_value $via_status]\t$via_orient_status\t[geo_value $via_orient]"
        incr via_context_row_count
        if {$via_relation eq "INTERSECTS_MARKER" || $via_relation eq "WITHIN_2UM_CONTEXT"} {
            incr local_via_count
            incr local_via_row_count
        }
    }
    if {$local_via_count > 0} { incr local_via_net_count }

    lassign [geo_report_query $raw_fh "NET_${net}_TOP_INST_TERMS" [list dbGet top.insts.instTerms.net.name $net -p2]] iterm_query_status iterm_raw iterm_error
    set iterm_handles [geo_valid_handles $iterm_raw]
    if {$iterm_query_status ne "PASS" || [llength $iterm_handles] == 0} {
        if {$net_handle ne "NONE"} {
            lassign [geo_report_query $raw_fh "NET_${net}_FALLBACK_INST_TERMS" [list dbGet "${net_handle}.instTerms"]] fallback_status fallback_raw fallback_error
            foreach handle [geo_valid_handles $fallback_raw] { geo_unique_append iterm_handles $handle }
            if {$fallback_status eq "PASS"} { set iterm_query_status PASS }
        }
    }
    if {[llength $iterm_handles] > 0} { incr inst_term_net_count }

    set net_pin_shape_count 0
    foreach iterm $iterm_handles {
        incr inst_term_row_count
        lassign [geo_attr $iterm name] name_status name name_error
        lassign [geo_attr $iterm inst.name] inst_status inst inst_error
        lassign [geo_attr $iterm inst.cell.name] cell_status cell cell_error
        lassign [geo_attr $iterm term.name] term_name_status term_name term_name_error
        lassign [geo_attr $iterm term.direction] direction_status direction direction_error
        lassign [geo_attr $iterm inst.box] inst_box_status inst_box inst_box_error
        lassign [geo_attr $iterm inst.pt] inst_pt_status inst_pt inst_pt_error
        lassign [geo_attr $iterm inst.orient] orient_status orient orient_error
        lassign [geo_attr $iterm pt] point_status point point_error
        lassign [geo_attr $iterm avgPt] avg_point_status avg_point avg_point_error
        puts $iterm_fh "$net\t[geo_value $iterm]\t$name_status\t[geo_value $name]\t$inst_status\t[geo_value $inst]\t$cell_status\t[geo_value $cell]\t$term_name_status\t[geo_value $term_name]\t$direction_status\t[geo_value $direction]\t$inst_box_status\t[geo_value $inst_box]\t$inst_pt_status\t[geo_value $inst_pt]\t$orient_status\t[geo_value $orient]\t$point_status\t[geo_value $point]\t$avg_point_status\t[geo_value $avg_point]"

        lassign [geo_report_query $raw_fh "NET_${net}_ITERM_[geo_value $iterm]_DIRECT_PINSHAPES" [list dbGet "${iterm}.pinShapes"]] direct_pin_status direct_pin_raw direct_pin_error
        foreach pin_shape [geo_valid_handles $direct_pin_raw] {
            incr net_pin_shape_count
            incr pin_shape_row_count
            lassign [geo_attr $pin_shape layer.name] pin_layer_status pin_layer pin_layer_error
            lassign [geo_attr $pin_shape rect] rect_status rect rect_error
            lassign [geo_attr $pin_shape type] pin_type_status pin_type pin_type_error
            lassign [geo_attr $pin_shape name] pin_name_status pin_name pin_name_error
            puts $pin_fh "$net\t[geo_value $iterm]\t[geo_value $inst]\t[geo_value $cell]\t[geo_value $term_name]\t[geo_value $pin_shape]\t$pin_layer_status\t[geo_value $pin_layer]\t$rect_status\t[geo_value $rect]\t$pin_type_status\t[geo_value $pin_type]\t$pin_name_status\t[geo_value $pin_name]\tDIRECT_INST_TERM_QUERY_REVIEW_COORDINATE_SEMANTICS"
        }
        geo_report_query $raw_fh "NET_${net}_ITERM_[geo_value $iterm]_DIRECT_ALLSHAPES" [list dbGet "${iterm}.pins.allShapes"]
        geo_report_query $raw_fh "NET_${net}_ITERM_[geo_value $iterm]_DIRECT_ALLSHAPE_RECTS" [list dbGet "${iterm}.pins.allShapes.rect"]
        geo_report_query $raw_fh "NET_${net}_ITERM_[geo_value $iterm]_DIRECT_ALLSHAPE_LAYERS" [list dbGet "${iterm}.pins.allShapes.layer.name"]
        lassign [geo_attr $iterm term.pinShapes] pin_query_status pin_shape_raw pin_query_error
        foreach pin_shape [geo_valid_handles $pin_shape_raw] {
            incr net_pin_shape_count
            incr pin_shape_row_count
            lassign [geo_attr $pin_shape layer.name] pin_layer_status pin_layer pin_layer_error
            lassign [geo_attr $pin_shape rect] rect_status rect rect_error
            lassign [geo_attr $pin_shape type] pin_type_status pin_type pin_type_error
            lassign [geo_attr $pin_shape name] pin_name_status pin_name pin_name_error
            puts $pin_fh "$net\t[geo_value $iterm]\t[geo_value $inst]\t[geo_value $cell]\t[geo_value $term_name]\t[geo_value $pin_shape]\t$pin_layer_status\t[geo_value $pin_layer]\t$rect_status\t[geo_value $rect]\t$pin_type_status\t[geo_value $pin_type]\t$pin_name_status\t[geo_value $pin_name]\tMASTER_LOCAL_REQUIRES_INSTANCE_TRANSFORM"
        }
    }
    if {$net_pin_shape_count > 0} { incr pin_shape_net_count }

    lassign [geo_report_query $raw_fh "NET_${net}_TOP_TERMS" [list dbGet top.terms.net.name $net -p2]] term_query_status term_raw term_error
    set term_handles [geo_valid_handles $term_raw]
    foreach term $term_handles {
        incr top_term_row_count
        lassign [geo_attr $term name] top_name_status top_name top_name_error
        lassign [geo_attr $term direction] top_direction_status top_direction top_direction_error
        lassign [geo_attr $term pt] top_point_status top_point top_point_error
        lassign [geo_attr $term pinShapes] top_pin_status top_pin_raw top_pin_error
        puts $term_fh "$net\t[geo_value $term]\t$top_name_status\t[geo_value $top_name]\t$top_direction_status\t[geo_value $top_direction]\t$top_point_status\t[geo_value $top_point]\t[llength [geo_valid_handles $top_pin_raw]]"
    }

    puts $topology_fh "$net\t[geo_value $marker_box]\t$net_handle_status\t[geo_value $net_handle]\t$wire_query_status\t[llength $wires]\t$local_count\t$via_query_status\t[llength $via_handles]\t$local_via_count\t$iterm_query_status\t[llength $iterm_handles]\t$term_query_status\t[llength $term_handles]\t$net_pin_shape_count"
    puts $raw_fh "NET_${net}_END=YES"
}

close $marker_fh
close $topology_fh
close $wire_fh
close $via_fh
close $iterm_fh
close $pin_fh
close $term_fh
close $raw_fh

set status(NET_HANDLE_PASS_COUNT) $net_handle_pass_count
set status(WIRE_QUERY_PASS_NET_COUNT) $wire_query_pass_net_count
set status(LOCAL_WIRE_NET_COUNT) $local_wire_net_count
set status(LOCAL_WIRE_ROW_COUNT) $local_wire_row_count
set status(WIRE_CONTEXT_ROW_COUNT) $wire_context_row_count
set status(VIA_QUERY_PASS_NET_COUNT) $via_query_pass_net_count
set status(LOCAL_VIA_NET_COUNT) $local_via_net_count
set status(LOCAL_VIA_ROW_COUNT) $local_via_row_count
set status(VIA_CONTEXT_ROW_COUNT) $via_context_row_count
set status(INST_TERM_NET_COUNT) $inst_term_net_count
set status(INST_TERM_ROW_COUNT) $inst_term_row_count
set status(TOP_TERM_ROW_COUNT) $top_term_row_count
set status(PIN_SHAPE_NET_COUNT) $pin_shape_net_count
set status(PIN_SHAPE_ROW_COUNT) $pin_shape_row_count

if {$net_handle_pass_count != 6} {
    geo_abort NET_HANDLE_CAPTURE_FAILED "resolved=$net_handle_pass_count expected=6"
}

set post_drc [file join $reports verify_drc_post_probe.rpt]
set post_markers [file join $reports drc_markers_post_probe.tsv]
set post_regular [file join $reports verify_connectivity_regular_post_probe.rpt]
set post_special [file join $reports verify_connectivity_special_post_probe.rpt]
if {![geo_capture $post_drc {verify_drc}]} { geo_abort POST_PROBE_DRC_CAPTURE_FAILED }
if {[catch {
    lassign [geo_write_marker_dump $post_markers] \
        post_marker_count post_database_total post_antenna_count post_connectivity_count
} marker_error]} {
    geo_abort POST_PROBE_MARKER_DUMP_FAILED $marker_error
}
set post_rows [geo_min_area_rows]
set post_nets [geo_row_nets $post_rows]
if {![geo_capture $post_regular {verifyConnectivity -type regular}] ||
    ![geo_capture $post_special {verifyConnectivity -type special -nets {VDD VSS}}]} {
    geo_abort POST_PROBE_CONNECTIVITY_CAPTURE_FAILED
}
set post_drc_count [geo_violation_count $post_drc]
set post_regular_count [geo_violation_count $post_regular]
set post_special_count [geo_violation_count $post_special]

set status(POST_DRC_VIOLATION_COUNT) $post_drc_count
set status(POST_DRC_MARKER_COUNT) $post_marker_count
set status(POST_MARKER_DATABASE_TOTAL) $post_database_total
set status(POST_EXCLUDED_ANTENNA_MARKER_COUNT) $post_antenna_count
set status(POST_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $post_connectivity_count
set status(POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $post_regular_count
set status(POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $post_special_count
set status(POST_MIN_AREA_NETS) [join $post_nets { }]

if {![string is integer -strict $post_drc_count] || $post_drc_count != 6 ||
    ![string is integer -strict $post_marker_count] || $post_marker_count != 6 ||
    [llength $post_rows] != 6 || $post_nets ne $expected_nets ||
    ![string is integer -strict $post_regular_count] || $post_regular_count != 0 ||
    ![string is integer -strict $post_special_count] || $post_special_count != 0 ||
    ![string is integer -strict $post_database_total] || $post_database_total != 27 ||
    ![string is integer -strict $post_antenna_count] || $post_antenna_count != 21 ||
    ![string is integer -strict $post_connectivity_count] || $post_connectivity_count != 0 ||
    [geo_row_signatures $post_rows] ne [geo_row_signatures $pre_rows]} {
    geo_abort POST_PROBE_INVARIANT_FAILED \
        "drc=$post_drc_count markers=$post_marker_count database_total=$post_database_total rows=[llength $post_rows] nets=$post_nets regular=$post_regular_count special=$post_special_count antenna=$post_antenna_count connectivity=$post_connectivity_count"
}

set status(QUERY_PASS_COUNT) $query_pass_count
set status(QUERY_FAIL_COUNT) $query_fail_count
if {$wire_query_pass_net_count == 6 && $local_wire_net_count == 6 &&
    $inst_term_net_count == 6 && $pin_shape_net_count == 6} {
    set status(TOPOLOGY_CAPTURE_STATUS) COMPLETE_LOCAL_WIRES_TERMINALS_AND_MASTER_PIN_SHAPES
} elseif {$wire_query_pass_net_count == 6} {
    set status(TOPOLOGY_CAPTURE_STATUS) PARTIAL_SCHEMA_GUIDED_LOCAL_WIRE_CAPTURE
} else {
    set status(TOPOLOGY_CAPTURE_STATUS) PARTIAL_SCHEMA_GUIDED_QUERY_CAPTURE
}
set status(NEXT_METHOD_DECISION) REVIEW_LOCAL_WIRE_AND_TERMINAL_GEOMETRY_BEFORE_DIRECT_PATCH_TRIAL
set status(STATUS) PASS
set status(RESULT) MIN_AREA_LOCAL_GEOMETRY_EVIDENCE_CAPTURED
geo_write_status
exit 0
