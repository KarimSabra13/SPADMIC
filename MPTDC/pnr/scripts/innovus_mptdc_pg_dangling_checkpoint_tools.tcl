# =============================================================================
# Project  : SPAD_MPTDC
# File     : innovus_mptdc_pg_dangling_checkpoint_tools.tcl
# Purpose  : Analyze and optionally repair VDD/VSS special-wire dangling
#            endpoints from an already-restored Innovus checkpoint.
#
# This file is meant to be sourced from innovus_mptdc_route_checkpoint_repair.tcl
# through mptdc_ckpt_source_tcl, after restoreDesign has completed.
# =============================================================================

proc mptdc_pg_dangling_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_pg_dangling_env_truthy {name default_value} {
    set value [string tolower [mptdc_pg_dangling_env $name $default_value]]
    return [expr {$value in {1 true yes on y}}]
}

proc mptdc_pg_dangling_env_double {name default_value} {
    set value [mptdc_pg_dangling_env $name $default_value]
    if {![string is double -strict $value]} {
        error "environment variable $name must be numeric, got: $value"
    }
    return $value
}

proc mptdc_pg_dangling_report_dir {} {
    if {[llength [info commands mptdc_signoff_report_dir]] > 0} {
        return [mptdc_signoff_report_dir]
    }
    set result_dir [mptdc_pg_dangling_env MPTDC_SIGNOFF_RESULT_DIR "."]
    return [file join $result_dir reports]
}

proc mptdc_pg_dangling_report_value {value} {
    if {[llength [info commands mptdc_signoff_report_value]] > 0} {
        return [mptdc_signoff_report_value $value]
    }
    regsub -all {\s+} $value { } compact
    return [string trim $compact]
}

proc mptdc_pg_dangling_capture_verify_special {path} {
    file mkdir [file dirname $path]
    set console "[file rootname $path].console.rpt"
    if {[catch {uplevel #0 "verifyConnectivity -type special -nets {VDD VSS} -report \"$path\" > \"$console\""} err]} {
        set fh [open $path a]
        puts $fh "VERIFY_SPECIAL_STATUS=FAIL"
        puts $fh "VERIFY_SPECIAL_ERROR=[mptdc_pg_dangling_report_value $err]"
        close $fh
        error "verifyConnectivity special failed: $err"
    }
    return $path
}

proc mptdc_pg_dangling_parse_report {path} {
    set markers {}
    set fh [open $path r]
    set idx 0
    while {[gets $fh line] >= 0} {
        set re {^Net[[:space:]]+([^:]+):[[:space:]]+dangling Wire at \(([0-9.+-]+),[[:space:]]*([0-9.+-]+)\)[[:space:]]+\(([0-9.+-]+),[[:space:]]*([0-9.+-]+)\)[[:space:]]+on layer:[[:space:]]+([^[:space:]]+)}
        if {[regexp $re $line -> net x1 y1 x2 y2 layer]} {
            incr idx
            lappend markers [dict create \
                idx $idx \
                net $net \
                layer $layer \
                x $x1 \
                y $y1 \
                x2 $x2 \
                y2 $y2 \
                line [string trim $line]]
        }
    }
    close $fh
    return $markers
}

proc mptdc_pg_dangling_dbget {expr {default UNKNOWN}} {
    if {[catch {set value [uplevel #0 "dbGet $expr"]}]} {
        return $default
    }
    if {$value eq "" || $value eq "0x0" || $value eq "NULL"} {
        return $default
    }
    return $value
}

proc mptdc_pg_dangling_rect {raw {depth 0}} {
    set raw [string trim $raw]
    if {$raw eq "" || $raw eq "UNKNOWN" || $raw eq "0x0" || $raw eq "NULL"} {
        return {}
    }
    if {$depth > 8 || [catch {set count [llength $raw]}]} {
        return {}
    }
    if {$count == 1} {
        set inner [lindex $raw 0]
        if {$inner eq $raw} {
            return {}
        }
        return [mptdc_pg_dangling_rect $inner [expr {$depth + 1}]]
    }
    if {$count != 4} {
        return {}
    }
    foreach value $raw {
        if {![string is double -strict $value]} {
            return {}
        }
    }
    lassign $raw x1 y1 x2 y2
    return [list \
        [expr {min(double($x1), double($x2))}] \
        [expr {min(double($y1), double($y2))}] \
        [expr {max(double($x1), double($x2))}] \
        [expr {max(double($y1), double($y2))}]]
}

proc mptdc_pg_dangling_point_distance_to_rect {x y rect} {
    if {[llength $rect] != 4} {
        return 1.0e30
    }
    lassign $rect x1 y1 x2 y2
    set dx 0.0
    if {$x < $x1} {
        set dx [expr {$x1 - $x}]
    } elseif {$x > $x2} {
        set dx [expr {$x - $x2}]
    }
    set dy 0.0
    if {$y < $y1} {
        set dy [expr {$y1 - $y}]
    } elseif {$y > $y2} {
        set dy [expr {$y - $y2}]
    }
    return [expr {sqrt($dx * $dx + $dy * $dy)}]
}

proc mptdc_pg_dangling_point_in_rect {x y rect eps} {
    if {[llength $rect] != 4} {
        return 0
    }
    lassign $rect x1 y1 x2 y2
    return [expr {$x >= ($x1 - $eps) && $x <= ($x2 + $eps) &&
                  $y >= ($y1 - $eps) && $y <= ($y2 + $eps)}]
}

proc mptdc_pg_dangling_point_match {pt x y eps} {
    if {[llength $pt] != 2} {
        return 0
    }
    set px [lindex $pt 0]
    set py [lindex $pt 1]
    if {![string is double -strict $px] || ![string is double -strict $py]} {
        return 0
    }
    return [expr {abs($px - $x) <= $eps && abs($py - $y) <= $eps}]
}

proc mptdc_pg_dangling_endpoint_match {pts x y eps} {
    if {[llength $pts] < 1} {
        return 0
    }
    set first [lindex $pts 0]
    set last [lindex $pts end]
    return [expr {[mptdc_pg_dangling_point_match $first $x $y $eps] ||
                  [mptdc_pg_dangling_point_match $last $x $y $eps]}]
}

proc mptdc_pg_dangling_path_length {pts rect} {
    if {[llength $pts] >= 2} {
        set total 0.0
        set prev [lindex $pts 0]
        for {set i 1} {$i < [llength $pts]} {incr i} {
            set cur [lindex $pts $i]
            if {[llength $prev] == 2 && [llength $cur] == 2} {
                set x0 [lindex $prev 0]
                set y0 [lindex $prev 1]
                set x1 [lindex $cur 0]
                set y1 [lindex $cur 1]
                if {[string is double -strict $x0] && [string is double -strict $y0] &&
                    [string is double -strict $x1] && [string is double -strict $y1]} {
                    set total [expr {$total + sqrt(($x1 - $x0) * ($x1 - $x0) + ($y1 - $y0) * ($y1 - $y0))}]
                }
            }
            set prev $cur
        }
        return $total
    }
    if {[llength $rect] == 4} {
        lassign $rect x1 y1 x2 y2
        return [expr {sqrt(($x2 - $x1) * ($x2 - $x1) + ($y2 - $y1) * ($y2 - $y1))}]
    }
    return UNKNOWN
}

proc mptdc_pg_dangling_swire_record {sw net} {
    set layer [mptdc_pg_dangling_dbget "$sw.layer.name"]
    set shape [mptdc_pg_dangling_dbget "$sw.shape"]
    set status [mptdc_pg_dangling_dbget "$sw.status"]
    set width [mptdc_pg_dangling_dbget "$sw.width"]
    set geom [mptdc_pg_dangling_dbget "$sw.geomType"]
    set box_raw [mptdc_pg_dangling_dbget "$sw.box" ""]
    set pts_raw [mptdc_pg_dangling_dbget "$sw.pts" ""]
    set rect [mptdc_pg_dangling_rect $box_raw]
    set length [mptdc_pg_dangling_path_length $pts_raw $rect]
    return [dict create \
        handle $sw \
        net $net \
        layer $layer \
        shape $shape \
        status $status \
        width $width \
        geomType $geom \
        box $box_raw \
        rect $rect \
        pts $pts_raw \
        length_um $length]
}

proc mptdc_pg_dangling_marker_candidates {marker eps near_radius} {
    set net [dict get $marker net]
    set layer [dict get $marker layer]
    set x [dict get $marker x]
    set y [dict get $marker y]
    set exact {}
    set nearby {}
    set nh [mptdc_pg_dangling_dbget "top.nets.name $net -p" ""]
    if {$nh eq "" || $nh eq "UNKNOWN"} {
        return [dict create exact $exact nearby $nearby net_handle $nh]
    }
    set swires [mptdc_pg_dangling_dbget "$nh.sWires" ""]
    foreach sw $swires {
        if {$sw eq "" || $sw eq "0x0" || $sw eq "NULL"} {
            continue
        }
        set rec [mptdc_pg_dangling_swire_record $sw $net]
        set sw_layer [dict get $rec layer]
        set rect [dict get $rec rect]
        set pts [dict get $rec pts]
        set distance [mptdc_pg_dangling_point_distance_to_rect $x $y $rect]
        set endpoint_match [expr {$sw_layer eq $layer && [mptdc_pg_dangling_endpoint_match $pts $x $y $eps]}]
        set box_match [expr {$sw_layer eq $layer && [mptdc_pg_dangling_point_in_rect $x $y $rect $eps]}]
        dict set rec distance_um $distance
        dict set rec endpoint_match $endpoint_match
        dict set rec box_match $box_match
        if {$endpoint_match} {
            lappend exact $rec
        } elseif {$distance <= $near_radius} {
            lappend nearby $rec
        }
    }
    return [dict create exact $exact nearby $nearby net_handle $nh]
}

proc mptdc_pg_dangling_write_swire {fh prefix rec} {
    puts $fh "${prefix}_HANDLE=[mptdc_pg_dangling_report_value [dict get $rec handle]]"
    puts $fh "${prefix}_NET=[dict get $rec net]"
    puts $fh "${prefix}_LAYER=[mptdc_pg_dangling_report_value [dict get $rec layer]]"
    puts $fh "${prefix}_SHAPE=[mptdc_pg_dangling_report_value [dict get $rec shape]]"
    puts $fh "${prefix}_STATUS=[mptdc_pg_dangling_report_value [dict get $rec status]]"
    puts $fh "${prefix}_WIDTH=[mptdc_pg_dangling_report_value [dict get $rec width]]"
    puts $fh "${prefix}_GEOMTYPE=[mptdc_pg_dangling_report_value [dict get $rec geomType]]"
    puts $fh "${prefix}_BOX=[mptdc_pg_dangling_report_value [dict get $rec box]]"
    puts $fh "${prefix}_PTS=[mptdc_pg_dangling_report_value [dict get $rec pts]]"
    puts $fh "${prefix}_LENGTH_UM=[mptdc_pg_dangling_report_value [dict get $rec length_um]]"
    puts $fh "${prefix}_DISTANCE_UM=[mptdc_pg_dangling_report_value [dict get $rec distance_um]]"
    puts $fh "${prefix}_ENDPOINT_MATCH=[dict get $rec endpoint_match]"
    puts $fh "${prefix}_BOX_MATCH=[dict get $rec box_match]"
}

proc mptdc_pg_dangling_delete_swire {rec fh prefix} {
    set sw [dict get $rec handle]
    set net [dict get $rec net]
    set layer [dict get $rec layer]
    set box [dict get $rec box]
    set method [string tolower [mptdc_pg_dangling_env MPTDC_PG_DANGLING_DELETE_METHOD dbdeleteobj_then_editdelete]]
    puts $fh "${prefix}_DELETE_METHOD=$method"
    puts $fh "${prefix}_DELETE_TARGET_HANDLE=[mptdc_pg_dangling_report_value $sw]"
    puts $fh "${prefix}_DELETE_TARGET_NET=$net"
    puts $fh "${prefix}_DELETE_TARGET_LAYER=$layer"
    puts $fh "${prefix}_DELETE_TARGET_BOX=[mptdc_pg_dangling_report_value $box]"
    flush $fh

    if {$method in {dbdeleteobj dbdeleteobj_then_editdelete}} {
        if {![catch {uplevel #0 [list dbDeleteObj $sw]} err]} {
            puts $fh "${prefix}_DELETE_STATUS=PASS"
            puts $fh "${prefix}_DELETE_USED=dbDeleteObj"
            return 1
        }
        puts $fh "${prefix}_DBDELETEOBJ_STATUS=FAIL"
        puts $fh "${prefix}_DBDELETEOBJ_ERROR=[mptdc_pg_dangling_report_value $err]"
        if {$method eq "dbdeleteobj"} {
            puts $fh "${prefix}_DELETE_STATUS=FAIL"
            return 0
        }
    }

    if {[llength [mptdc_pg_dangling_rect $box]] != 4} {
        puts $fh "${prefix}_EDITDELETE_STATUS=SKIPPED_NO_BOX"
        puts $fh "${prefix}_DELETE_STATUS=FAIL"
        return 0
    }
    if {![catch {uplevel #0 [list editDelete -net $net -layer $layer -area $box -type Special]} err]} {
        puts $fh "${prefix}_DELETE_STATUS=PASS"
        puts $fh "${prefix}_DELETE_USED=editDelete_full_swire_box"
        return 1
    }
    puts $fh "${prefix}_EDITDELETE_STATUS=FAIL"
    puts $fh "${prefix}_EDITDELETE_ERROR=[mptdc_pg_dangling_report_value $err]"
    puts $fh "${prefix}_DELETE_STATUS=FAIL"
    return 0
}

proc mptdc_pg_dangling_snapshot_after_delete {fh tag} {
    if {[llength [info commands mptdc_ckpt_verify_snapshot]] == 0} {
        puts $fh "${tag}_VERIFY_STATUS=SKIPPED_NO_CHECKPOINT_HELPER"
        return {}
    }
    set snapshot [mptdc_ckpt_verify_snapshot $tag]
    puts $fh "${tag}_DRC=[dict get $snapshot total_violations]"
    puts $fh "${tag}_SHORTS=[dict get $snapshot shorts]"
    puts $fh "${tag}_REGULAR_CONNECTIVITY_BAD=[dict get $snapshot regular_bad]"
    puts $fh "${tag}_SPECIAL_CONNECTIVITY_BAD=[dict get $snapshot special_bad]"
    puts $fh "${tag}_SPECIAL_CONNECTIVITY_BAD_LINES=[dict get $snapshot special_bad_lines]"
    puts $fh "${tag}_ROUTE_GATE_PASS=[dict get $snapshot route_gate_pass]"
    puts $fh "${tag}_DRC_REPORT=[dict get $snapshot drc_rpt]"
    puts $fh "${tag}_REGULAR_CONNECTIVITY_REPORT=[dict get $snapshot regular_rpt]"
    puts $fh "${tag}_SPECIAL_CONNECTIVITY_REPORT=[dict get $snapshot special_rpt]"
    return $snapshot
}

proc mptdc_pg_dangling_snapshot_is_geometry_regular_clean {snapshot} {
    if {[llength $snapshot] == 0} {
        return 1
    }
    return [expr {[dict get $snapshot total_violations] ne "UNKNOWN" &&
                  [dict get $snapshot shorts] ne "UNKNOWN" &&
                  [dict get $snapshot regular_bad] ne "UNKNOWN" &&
                  [dict get $snapshot total_violations] == 0 &&
                  [dict get $snapshot shorts] == 0 &&
                  [dict get $snapshot regular_bad] == 0}]
}

proc mptdc_pg_dangling_run {{mode ""}} {
    if {$mode eq ""} {
        set mode [string tolower [mptdc_pg_dangling_env MPTDC_PG_DANGLING_MODE analyze]]
    } else {
        set mode [string tolower $mode]
    }
    set eps [mptdc_pg_dangling_env_double MPTDC_PG_DANGLING_MATCH_EPS_UM 0.002]
    set near_radius [mptdc_pg_dangling_env_double MPTDC_PG_DANGLING_NEAR_RADIUS_UM 6.0]
    set max_delete_length [mptdc_pg_dangling_env_double MPTDC_PG_DANGLING_MAX_DELETE_LENGTH_UM 10.0]
    set allow_long_delete [mptdc_pg_dangling_env_truthy MPTDC_PG_DANGLING_ALLOW_LONG_DELETE 0]
    set require_all_eligible [mptdc_pg_dangling_env_truthy MPTDC_PG_DANGLING_REQUIRE_ALL_ELIGIBLE 1]
    set delete_mode [expr {$mode in {delete_short delete_all delete_all_candidates repair}}]
    set report_dir [mptdc_pg_dangling_report_dir]
    file mkdir $report_dir

    set verify_rpt [file join $report_dir pg_dangling_initial_verify_special_detailed.rpt]
    mptdc_pg_dangling_capture_verify_special $verify_rpt
    set markers [mptdc_pg_dangling_parse_report $verify_rpt]

    set rpt [file join $report_dir pg_dangling_analysis_status.rpt]
    set fh [open $rpt w]
    puts $fh "# MPTDC PG Dangling Endpoint Analysis"
    puts $fh "PG_DANGLING_MODE=$mode"
    puts $fh "VERIFY_SPECIAL_REPORT=$verify_rpt"
    puts $fh "MATCH_EPS_UM=$eps"
    puts $fh "NEAR_RADIUS_UM=$near_radius"
    puts $fh "MAX_DELETE_LENGTH_UM=$max_delete_length"
    puts $fh "ALLOW_LONG_DELETE=[expr {$allow_long_delete ? 1 : 0}]"
    puts $fh "REQUIRE_ALL_ELIGIBLE=[expr {$require_all_eligible ? 1 : 0}]"
    puts $fh "MARKER_COUNT=[llength $markers]"

    set delete_plan {}
    set candidate_handle_counts {}
    set blocked_count 0
    set ambiguous_count 0
    set missing_count 0
    set unsafe_length_count 0

    foreach marker $markers {
        set idx [dict get $marker idx]
        set net [dict get $marker net]
        set layer [dict get $marker layer]
        set x [dict get $marker x]
        set y [dict get $marker y]
        puts $fh ""
        puts $fh "MARKER_${idx}_LINE=[mptdc_pg_dangling_report_value [dict get $marker line]]"
        puts $fh "MARKER_${idx}_NET=$net"
        puts $fh "MARKER_${idx}_LAYER=$layer"
        puts $fh "MARKER_${idx}_POINT=($x,$y)"

        set found [mptdc_pg_dangling_marker_candidates $marker $eps $near_radius]
        set exact [dict get $found exact]
        set nearby [dict get $found nearby]
        puts $fh "MARKER_${idx}_EXACT_ENDPOINT_SWIRE_COUNT=[llength $exact]"
        puts $fh "MARKER_${idx}_NEARBY_SWIRE_COUNT=[llength $nearby]"

        set ci 0
        foreach rec $exact {
            incr ci
            mptdc_pg_dangling_write_swire $fh "MARKER_${idx}_EXACT_${ci}" $rec
        }
        set ni 0
        foreach rec $nearby {
            incr ni
            if {$ni > 12} {
                puts $fh "MARKER_${idx}_NEARBY_TRUNCATED=1"
                break
            }
            mptdc_pg_dangling_write_swire $fh "MARKER_${idx}_NEARBY_${ni}" $rec
        }

        if {[llength $exact] == 0} {
            incr missing_count
            puts $fh "MARKER_${idx}_ACTION=NO_EXACT_SWIRE_FOUND"
            continue
        }
        if {[llength $exact] > 1} {
            incr ambiguous_count
            puts $fh "MARKER_${idx}_ACTION=BLOCKED_AMBIGUOUS_EXACT_SWIRE"
            continue
        }

        set rec [lindex $exact 0]
        set length [dict get $rec length_um]
        set length_ok 0
        if {$length ne "UNKNOWN" && [string is double -strict $length] && $length <= $max_delete_length} {
            set length_ok 1
        }
        if {!$length_ok && !$allow_long_delete} {
            incr blocked_count
            incr unsafe_length_count
            puts $fh "MARKER_${idx}_ACTION=BLOCKED_UNSAFE_LENGTH"
            puts $fh "MARKER_${idx}_DELETE_BLOCKED_REASON=segment_length_requires_explicit_ALLOW_LONG_DELETE"
            continue
        }
        set handle [dict get $rec handle]
        dict incr candidate_handle_counts $handle
        lappend delete_plan [dict create idx $idx rec $rec]
        puts $fh "MARKER_${idx}_ACTION=ELIGIBLE_EXACT_SWIRE"
    }

    set duplicate_handle_count 0
    dict for {handle count} $candidate_handle_counts {
        if {$count > 1} {
            incr duplicate_handle_count
            puts $fh "DUPLICATE_HANDLE_[mptdc_pg_dangling_report_value $handle]_REFERENCE_COUNT=$count"
        }
    }
    set eligible_count [llength $delete_plan]
    set all_eligible [expr {[llength $markers] > 0 &&
                            $eligible_count == [llength $markers] &&
                            $missing_count == 0 && $ambiguous_count == 0 &&
                            $unsafe_length_count == 0 && $duplicate_handle_count == 0}]
    puts $fh ""
    puts $fh "PG_DANGLING_ELIGIBLE_COUNT=$eligible_count"
    puts $fh "PG_DANGLING_UNSAFE_LENGTH_COUNT=$unsafe_length_count"
    puts $fh "PG_DANGLING_DUPLICATE_HANDLE_COUNT=$duplicate_handle_count"
    puts $fh "PG_DANGLING_ALL_ELIGIBLE_STATUS=[expr {$all_eligible ? "PASS" : "FAIL"}]"

    set mutation_allowed [expr {$delete_mode && (!$require_all_eligible || $all_eligible)}]
    puts $fh "PG_DANGLING_MUTATION_ALLOWED=[expr {$mutation_allowed ? 1 : 0}]"
    set delete_attempts 0
    set delete_successes 0
    set dirty_abort 0
    if {$mutation_allowed} {
        foreach plan $delete_plan {
            set idx [dict get $plan idx]
            set rec [dict get $plan rec]
            set handle [dict get $rec handle]
            if {[dict get $candidate_handle_counts $handle] != 1} {
                puts $fh "MARKER_${idx}_DELETE_STATUS=SKIPPED_DUPLICATE_HANDLE"
                continue
            }
            incr delete_attempts
            puts $fh "MARKER_${idx}_ACTION=DELETE_PREFLIGHTED_EXACT_SWIRE"
            if {[mptdc_pg_dangling_delete_swire $rec $fh "MARKER_${idx}"]} {
                incr delete_successes
            }
            set snapshot [mptdc_pg_dangling_snapshot_after_delete $fh [format "pg_dangling_after_delete_%02d" $idx]]
            flush $fh
            if {![mptdc_pg_dangling_snapshot_is_geometry_regular_clean $snapshot]} {
                puts $fh "MARKER_${idx}_ABORT_REASON=geometry_or_regular_connectivity_became_dirty"
                set dirty_abort 1
                break
            }
        }
    } elseif {$delete_mode} {
        puts $fh "PG_DANGLING_MUTATION_BLOCKED_REASON=not_all_candidates_are_unique_short_exact_endpoints"
    }

    puts $fh ""
    puts $fh "PG_DANGLING_DELETE_ATTEMPTS=$delete_attempts"
    puts $fh "PG_DANGLING_DELETE_SUCCESSES=$delete_successes"
    puts $fh "PG_DANGLING_BLOCKED_COUNT=$blocked_count"
    puts $fh "PG_DANGLING_AMBIGUOUS_COUNT=$ambiguous_count"
    puts $fh "PG_DANGLING_MISSING_EXACT_COUNT=$missing_count"
    puts $fh "PG_DANGLING_DIRTY_ABORT=$dirty_abort"
    set final_verify [file join $report_dir pg_dangling_final_verify_special_detailed.rpt]
    catch {mptdc_pg_dangling_capture_verify_special $final_verify}
    set final_markers {}
    if {[file exists $final_verify]} {
        set final_markers [mptdc_pg_dangling_parse_report $final_verify]
    }
    puts $fh "FINAL_VERIFY_SPECIAL_REPORT=$final_verify"
    puts $fh "FINAL_DANGLING_MARKER_COUNT=[llength $final_markers]"
    if {$dirty_abort} {
        puts $fh "PG_DANGLING_STATUS=FAIL_GEOMETRY_OR_REGULAR_DIRTY"
    } elseif {!$delete_mode} {
        puts $fh "PG_DANGLING_STATUS=ANALYSIS_ONLY"
    } elseif {!$mutation_allowed} {
        puts $fh "PG_DANGLING_STATUS=REVIEW_REQUIRED_PREFLIGHT_BLOCKED"
    } elseif {[llength $final_markers] == 0} {
        puts $fh "PG_DANGLING_STATUS=PASS_DANGLING_CLEARED"
    } else {
        puts $fh "PG_DANGLING_STATUS=REVIEW_REQUIRED_DANGLING_REMAINS"
    }
    close $fh
    puts "MPTDC_PG_DANGLING_ANALYSIS_REPORT=$rpt"
    return $rpt
}

if {[mptdc_pg_dangling_env_truthy MPTDC_PG_DANGLING_AUTORUN 1]} {
    mptdc_pg_dangling_run
}
