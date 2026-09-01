# =============================================================================
# Project  : SPAD_MPTDC
# File     : innovus_mptdc_pg_ro_ring_checkpoint_tools.tcl
# Purpose  : Repair the accepted V13 VDD/VSS dangling topology with an
#            attributable RO block-ring stitch or an explicit long-prune
#            fallback.
#
# Source this file only after restoreDesign, through mptdc_ckpt_source_tcl.
# Every mode is intended to run in a fresh Innovus process.
# =============================================================================

# Reuse the report parser and exact endpoint-to-sWire mapper without triggering
# its legacy short-delete autorun path.
if {[llength [info commands mptdc_pg_dangling_parse_report]] == 0} {
    set mptdc_pg_ro_helper [file join [file dirname [info script]] \
        innovus_mptdc_pg_dangling_checkpoint_tools.tcl]
    set mptdc_pg_ro_had_autorun [info exists ::env(MPTDC_PG_DANGLING_AUTORUN)]
    if {$mptdc_pg_ro_had_autorun} {
        set mptdc_pg_ro_saved_autorun $::env(MPTDC_PG_DANGLING_AUTORUN)
    }
    set ::env(MPTDC_PG_DANGLING_AUTORUN) 0
    source $mptdc_pg_ro_helper
    if {$mptdc_pg_ro_had_autorun} {
        set ::env(MPTDC_PG_DANGLING_AUTORUN) $mptdc_pg_ro_saved_autorun
    } else {
        unset ::env(MPTDC_PG_DANGLING_AUTORUN)
    }
    unset mptdc_pg_ro_helper mptdc_pg_ro_had_autorun
    catch {unset mptdc_pg_ro_saved_autorun}
}

proc mptdc_pg_ro_env {name default_value} {
    return [mptdc_pg_dangling_env $name $default_value]
}

proc mptdc_pg_ro_env_truthy {name default_value} {
    return [mptdc_pg_dangling_env_truthy $name $default_value]
}

proc mptdc_pg_ro_env_double {name default_value} {
    return [mptdc_pg_dangling_env_double $name $default_value]
}

proc mptdc_pg_ro_report_value {value} {
    return [mptdc_pg_dangling_report_value $value]
}

proc mptdc_pg_ro_valid_handles {value} {
    set out {}
    foreach handle $value {
        # Restored databases can return an object list wrapped in one Tcl list
        # element.  Flatten that representation before issuing per-object dbGet
        # queries.
        if {[llength $handle] > 1} {
            foreach nested [mptdc_pg_ro_valid_handles $handle] {
                if {[lsearch -exact $out $nested] < 0} {
                    lappend out $nested
                }
            }
            continue
        }
        if {$handle eq "" || $handle eq "0x0" || $handle eq "NULL" ||
            $handle eq "UNKNOWN"} {
            continue
        }
        if {[lsearch -exact $out $handle] < 0} {
            lappend out $handle
        }
    }
    return $out
}

proc mptdc_pg_ro_two_points {raw} {
    if {[llength $raw] == 2 && [llength [lindex $raw 0]] == 2 &&
        [llength [lindex $raw 1]] == 2} {
        set points $raw
    } elseif {[llength $raw] == 4} {
        set points [list [lrange $raw 0 1] [lrange $raw 2 3]]
    } elseif {[llength $raw] == 1} {
        set inner [lindex $raw 0]
        if {$inner eq $raw} {
            return {}
        }
        return [mptdc_pg_ro_two_points $inner]
    } else {
        return {}
    }
    foreach point $points {
        foreach value $point {
            if {![string is double -strict $value]} {
                return {}
            }
        }
    }
    return $points
}

proc mptdc_pg_ro_close {lhs rhs {eps 0.002}} {
    if {![string is double -strict $lhs] || ![string is double -strict $rhs]} {
        return 0
    }
    return [expr {abs(double($lhs) - double($rhs)) <= $eps}]
}

proc mptdc_pg_ro_same_point {lhs rhs {eps 0.002}} {
    return [expr {[llength $lhs] == 2 && [llength $rhs] == 2 &&
        [mptdc_pg_ro_close [lindex $lhs 0] [lindex $rhs 0] $eps] &&
        [mptdc_pg_ro_close [lindex $lhs 1] [lindex $rhs 1] $eps]}]
}

proc mptdc_pg_ro_orientation {points {eps 0.002}} {
    set points [mptdc_pg_ro_two_points $points]
    if {[llength $points] != 2} {
        return INVALID
    }
    lassign [lindex $points 0] x0 y0
    lassign [lindex $points 1] x1 y1
    if {[mptdc_pg_ro_close $y0 $y1 $eps] && ![mptdc_pg_ro_close $x0 $x1 $eps]} {
        return HORIZONTAL
    }
    if {[mptdc_pg_ro_close $x0 $x1 $eps] && ![mptdc_pg_ro_close $y0 $y1 $eps]} {
        return VERTICAL
    }
    return INVALID
}

proc mptdc_pg_ro_point_encoding {raw} {
    if {[llength $raw] == 2 && [llength [lindex $raw 0]] == 2 &&
        [llength [lindex $raw 1]] == 2} {
        return NESTED_TWO_POINT
    }
    if {[llength $raw] == 4} {
        return FLAT_FOUR_COORD
    }
    if {[llength $raw] == 1} {
        set inner [lindex $raw 0]
        if {$inner eq $raw} {
            return INVALID
        }
        return "WRAPPED_[mptdc_pg_ro_point_encoding $inner]"
    }
    return INVALID
}

proc mptdc_pg_ro_net_handle_set {net} {
    return [mptdc_pg_ro_valid_handles \
        [mptdc_pg_dangling_dbget "top.nets.name $net -p" ""]]
}

proc mptdc_pg_ro_handle_set {net} {
    set out {}
    foreach nh [mptdc_pg_ro_net_handle_set $net] {
        foreach handle [mptdc_pg_ro_valid_handles \
            [mptdc_pg_dangling_dbget "$nh.sWires" ""]] {
            if {[lsearch -exact $out $handle] < 0} {
                lappend out $handle
            }
        }
    }
    return $out
}

proc mptdc_pg_ro_swire_records {net} {
    set out {}
    foreach handle [mptdc_pg_ro_handle_set $net] {
        lappend out [mptdc_pg_dangling_swire_record $handle $net]
    }
    return $out
}

proc mptdc_pg_ro_classify_source_record {marker rec eps near_radius} {
    set x [dict get $marker x]
    set y [dict get $marker y]
    set marker_layer [string toupper [dict get $marker layer]]
    set rec_layer [string toupper [dict get $rec layer]]
    set raw_points [dict get $rec pts]
    set points [mptdc_pg_ro_two_points $raw_points]
    set rect [dict get $rec rect]
    set distance [mptdc_pg_dangling_point_distance_to_rect $x $y $rect]
    set endpoint_match [expr {$rec_layer eq $marker_layer &&
        [llength $points] == 2 &&
        [mptdc_pg_dangling_endpoint_match $points $x $y $eps]}]
    set box_match [expr {$rec_layer eq $marker_layer &&
        [mptdc_pg_dangling_point_in_rect $x $y $rect $eps]}]
    dict set rec layer $rec_layer
    dict set rec points $points
    dict set rec point_encoding [mptdc_pg_ro_point_encoding $raw_points]
    dict set rec length_um [mptdc_pg_dangling_path_length $points $rect]
    dict set rec distance_um $distance
    dict set rec endpoint_match $endpoint_match
    dict set rec box_match $box_match
    dict set rec near_match [expr {!$endpoint_match && $distance <= $near_radius}]
    return $rec
}

proc mptdc_pg_ro_marker_candidates {marker eps near_radius \
    {records __MPTDC_QUERY__} {net_handle_count __MPTDC_QUERY__}} {
    set exact {}
    set nearby {}
    set net [dict get $marker net]
    if {$records eq "__MPTDC_QUERY__"} {
        set records [mptdc_pg_ro_swire_records $net]
    }
    if {$net_handle_count eq "__MPTDC_QUERY__"} {
        set net_handle_count [llength [mptdc_pg_ro_net_handle_set $net]]
    }
    foreach raw_rec $records {
        set rec [mptdc_pg_ro_classify_source_record \
            $marker $raw_rec $eps $near_radius]
        if {[dict get $rec endpoint_match]} {
            lappend exact $rec
        } elseif {[dict get $rec near_match]} {
            lappend nearby $rec
        }
    }
    return [dict create exact $exact nearby $nearby \
        source_count [llength $records] \
        net_handle_count $net_handle_count]
}

proc mptdc_pg_ro_sorted_unique_records {preflight} {
    set keyed {}
    dict for {handle rec} [dict get $preflight records] {
        set key [join [list [dict get $rec net] [dict get $rec layer] \
            [dict get $rec pts] $handle] |]
        lappend keyed [list $key $rec]
    }
    set out {}
    foreach item [lsort -dictionary -index 0 $keyed] {
        lappend out [lindex $item 1]
    }
    return $out
}

proc mptdc_pg_ro_expected_marker_fingerprint {} {
    return [lsort -dictionary [list \
        VDD|MET3|221.750|681.160 \
        VDD|MET3|221.750|201.160 \
        VDD|MET3|48.000|681.160 \
        VDD|MET3|48.000|201.160 \
        VDD|METTP|121.160|233.620 \
        VDD|METTP|121.160|648.320 \
        VSS|MET3|221.750|685.160 \
        VSS|MET3|221.750|205.160 \
        VSS|MET3|48.000|685.160 \
        VSS|MET3|48.000|205.160 \
        VSS|METTP|125.160|233.620 \
        VSS|METTP|125.160|648.320 \
        VSS|METTP|125.160|721.750 \
        VSS|METTP|205.160|158.320 \
        VSS|METTP|125.160|158.320]]
}

proc mptdc_pg_ro_marker_fingerprint {markers} {
    set out {}
    foreach marker $markers {
        lappend out [format "%s|%s|%.3f|%.3f" \
            [dict get $marker net] [string toupper [dict get $marker layer]] \
            [dict get $marker x] [dict get $marker y]]
    }
    return [lsort -dictionary $out]
}

proc mptdc_pg_ro_expected_instance_set {} {
    return [lsort -dictionary [list \
        u_core_u_osc_fast_u_ro_tune4 \
        u_core_u_osc_slow_u_ro_tune4]]
}

proc mptdc_pg_ro_preflight {} {
    set report_dir [mptdc_pg_dangling_report_dir]
    set detailed [file join $report_dir pg_ro_initial_verify_special_detailed.rpt]
    mptdc_pg_dangling_capture_verify_special $detailed
    set markers [mptdc_pg_dangling_parse_report $detailed]
    set eps [mptdc_pg_ro_env_double MPTDC_PG_RO_MATCH_EPS_UM 0.002]
    set near [mptdc_pg_ro_env_double MPTDC_PG_RO_NEAR_RADIUS_UM 6.0]
    set min_length [mptdc_pg_ro_env_double MPTDC_PG_RO_EXPECTED_MIN_LENGTH_UM 10.0]
    set entries {}
    set records [dict create]
    set handle_counts [dict create]
    set reasons {}
    set net_counts [dict create VDD 0 VSS 0]
    set layer_counts [dict create MET3 0 METTP 0]
    set source_net_handle_counts [dict create \
        VDD [llength [mptdc_pg_ro_net_handle_set VDD]] \
        VSS [llength [mptdc_pg_ro_net_handle_set VSS]]]
    set source_records_by_net [dict create \
        VDD [mptdc_pg_ro_swire_records VDD] \
        VSS [mptdc_pg_ro_swire_records VSS]]
    set source_swire_counts [dict create \
        VDD [llength [dict get $source_records_by_net VDD]] \
        VSS [llength [dict get $source_records_by_net VSS]]]
    set source_point_encoding_counts [dict create]
    foreach net {VDD VSS} {
        foreach rec [dict get $source_records_by_net $net] {
            set encoding [mptdc_pg_ro_point_encoding [dict get $rec pts]]
            dict incr source_point_encoding_counts "${net}|${encoding}"
        }
    }
    set marker_diagnostics {}

    foreach net {VDD VSS} {
        if {[dict get $source_net_handle_counts $net] == 0} {
            lappend reasons "[string tolower $net]_net_handle_count:0"
        }
        if {[dict get $source_swire_counts $net] == 0} {
            lappend reasons "[string tolower $net]_swire_inventory_count:0"
        }
    }

    if {[mptdc_pg_ro_marker_fingerprint $markers] ne \
        [mptdc_pg_ro_expected_marker_fingerprint]} {
        lappend reasons marker_fingerprint_mismatch
    }

    foreach marker $markers {
        set net [dict get $marker net]
        set layer [string toupper [dict get $marker layer]]
        if {$net ni {VDD VSS}} {
            lappend reasons "marker_[dict get $marker idx]_unexpected_net:$net"
        } else {
            dict incr net_counts $net
        }
        if {$layer ni {MET3 METTP}} {
            lappend reasons "marker_[dict get $marker idx]_unexpected_layer:$layer"
        } else {
            dict incr layer_counts $layer
        }
        if {![mptdc_pg_ro_close [dict get $marker x] [dict get $marker x2] $eps] ||
            ![mptdc_pg_ro_close [dict get $marker y] [dict get $marker y2] $eps]} {
            lappend reasons "marker_[dict get $marker idx]_not_point_endpoint"
            continue
        }
        set found [mptdc_pg_ro_marker_candidates $marker $eps $near \
            [dict get $source_records_by_net $net] \
            [dict get $source_net_handle_counts $net]]
        set exact [dict get $found exact]
        set nearby [dict get $found nearby]
        lappend marker_diagnostics [dict create idx [dict get $marker idx] \
            exact_count [llength $exact] nearby_count [llength $nearby] \
            source_count [dict get $found source_count] \
            net_handle_count [dict get $found net_handle_count]]
        if {[llength $exact] != 1} {
            lappend reasons "marker_[dict get $marker idx]_exact_count:[llength $exact]"
            continue
        }
        set rec [lindex $exact 0]
        set points [dict get $rec points]
        set orientation [mptdc_pg_ro_orientation $points $eps]
        set length [dict get $rec length_um]
        set width [dict get $rec width]
        if {$orientation eq "INVALID"} {
            lappend reasons "marker_[dict get $marker idx]_noncanonical_points"
            continue
        }
        if {![mptdc_pg_ro_close $width 2.0 $eps] ||
            [string tolower [dict get $rec shape]] ne "stripe" ||
            [string tolower [dict get $rec status]] ne "routed" ||
            [string tolower [dict get $rec geomType]] ne "pathseg"} {
            lappend reasons "marker_[dict get $marker idx]_unexpected_source_object_contract"
            continue
        }
        if {![string is double -strict $length] || $length <= $min_length} {
            lappend reasons "marker_[dict get $marker idx]_not_expected_long_handle:$length"
            continue
        }
        set handle [dict get $rec handle]
        dict set rec points $points
        dict set rec orientation $orientation
        if {[dict exists $records $handle]} {
            set prior [dict get $records $handle]
            if {[dict get $prior net] ne [dict get $rec net] ||
                [dict get $prior layer] ne [dict get $rec layer] ||
                ![mptdc_pg_ro_points_match [dict get $prior points] $points $eps] ||
                ![mptdc_pg_ro_close [dict get $prior width] $width $eps]} {
                lappend reasons "handle_[mptdc_pg_ro_report_value $handle]_inconsistent_references"
                continue
            }
        }
        dict set records $handle $rec
        dict incr handle_counts $handle
        lappend entries [dict create marker $marker rec $rec]
    }

    set shared 0
    set invalid_refs 0
    dict for {handle count} $handle_counts {
        if {$count == 2} {
            incr shared
        } elseif {$count != 1} {
            incr invalid_refs
            lappend reasons "handle_reference_count:$count"
        }
    }
    if {[llength $markers] != 15} { lappend reasons "marker_count:[llength $markers]" }
    if {[dict size $records] != 13} { lappend reasons "unique_handle_count:[dict size $records]" }
    if {$shared != 2} { lappend reasons "shared_handle_count:$shared" }
    if {$invalid_refs != 0} { lappend reasons "invalid_reference_groups:$invalid_refs" }
    if {[dict get $net_counts VDD] != 6 || [dict get $net_counts VSS] != 9} {
        lappend reasons "net_counts:VDD=[dict get $net_counts VDD],VSS=[dict get $net_counts VSS]"
    }
    if {[dict get $layer_counts MET3] != 8 || [dict get $layer_counts METTP] != 7} {
        lappend reasons "layer_counts:MET3=[dict get $layer_counts MET3],METTP=[dict get $layer_counts METTP]"
    }
    set status [expr {[llength $reasons] == 0 ? "PASS" : "FAIL"}]
    return [dict create status $status reasons $reasons report $detailed \
        markers $markers entries $entries records $records \
        handle_counts $handle_counts marker_count [llength $markers] \
        unique_handle_count [dict size $records] shared_handle_count $shared \
        net_counts $net_counts layer_counts $layer_counts \
        source_swire_counts $source_swire_counts \
        source_net_handle_counts $source_net_handle_counts \
        source_point_encoding_counts $source_point_encoding_counts \
        marker_diagnostics $marker_diagnostics]
}

proc mptdc_pg_ro_write_preflight {fh preflight} {
    puts $fh "INITIAL_VERIFY_SPECIAL_REPORT=[dict get $preflight report]"
    puts $fh "INITIAL_DANGLING_MARKER_COUNT=[dict get $preflight marker_count]"
    puts $fh "SOURCE_UNIQUE_HANDLE_COUNT=[dict get $preflight unique_handle_count]"
    puts $fh "SOURCE_SHARED_HANDLE_COUNT=[dict get $preflight shared_handle_count]"
    puts $fh "SOURCE_VDD_MARKER_COUNT=[dict get [dict get $preflight net_counts] VDD]"
    puts $fh "SOURCE_VSS_MARKER_COUNT=[dict get [dict get $preflight net_counts] VSS]"
    puts $fh "SOURCE_MET3_MARKER_COUNT=[dict get [dict get $preflight layer_counts] MET3]"
    puts $fh "SOURCE_METTP_MARKER_COUNT=[dict get [dict get $preflight layer_counts] METTP]"
    puts $fh "SOURCE_VDD_NET_HANDLE_COUNT=[dict get [dict get $preflight source_net_handle_counts] VDD]"
    puts $fh "SOURCE_VSS_NET_HANDLE_COUNT=[dict get [dict get $preflight source_net_handle_counts] VSS]"
    puts $fh "SOURCE_VDD_SWIRE_INVENTORY_COUNT=[dict get [dict get $preflight source_swire_counts] VDD]"
    puts $fh "SOURCE_VSS_SWIRE_INVENTORY_COUNT=[dict get [dict get $preflight source_swire_counts] VSS]"
    foreach key [lsort -dictionary \
        [dict keys [dict get $preflight source_point_encoding_counts]]] {
        set report_key [string map {| _} $key]
        puts $fh "SOURCE_${report_key}_COUNT=[dict get [dict get $preflight source_point_encoding_counts] $key]"
    }
    puts $fh "SOURCE_TOPOLOGY_STATUS=[dict get $preflight status]"
    puts $fh "SOURCE_TOPOLOGY_FAILURES=[mptdc_pg_ro_report_value [dict get $preflight reasons]]"
    foreach diagnostic [dict get $preflight marker_diagnostics] {
        set marker_idx [dict get $diagnostic idx]
        puts $fh "SOURCE_MARKER_${marker_idx}_EXACT_COUNT=[dict get $diagnostic exact_count]"
        puts $fh "SOURCE_MARKER_${marker_idx}_NEARBY_COUNT=[dict get $diagnostic nearby_count]"
        puts $fh "SOURCE_MARKER_${marker_idx}_SWIRE_INVENTORY_COUNT=[dict get $diagnostic source_count]"
        puts $fh "SOURCE_MARKER_${marker_idx}_NET_HANDLE_COUNT=[dict get $diagnostic net_handle_count]"
    }
    set idx 0
    foreach rec [mptdc_pg_ro_sorted_unique_records $preflight] {
        incr idx
        set handle [dict get $rec handle]
        set refs [dict get [dict get $preflight handle_counts] $handle]
        puts $fh "SOURCE_HANDLE_${idx}_HANDLE=[mptdc_pg_ro_report_value $handle]"
        puts $fh "SOURCE_HANDLE_${idx}_NET=[dict get $rec net]"
        puts $fh "SOURCE_HANDLE_${idx}_LAYER=[dict get $rec layer]"
        puts $fh "SOURCE_HANDLE_${idx}_WIDTH=[dict get $rec width]"
        puts $fh "SOURCE_HANDLE_${idx}_POINTS=[mptdc_pg_ro_report_value [dict get $rec points]]"
        puts $fh "SOURCE_HANDLE_${idx}_POINT_ENCODING=[dict get $rec point_encoding]"
        puts $fh "SOURCE_HANDLE_${idx}_LENGTH_UM=[dict get $rec length_um]"
        puts $fh "SOURCE_HANDLE_${idx}_MARKER_REFERENCE_COUNT=$refs"
    }
}

proc mptdc_pg_ro_new_ring_records {before_by_net} {
    set rows {}
    foreach net {VDD VSS} {
        set before [dict get $before_by_net $net]
        foreach rec [mptdc_pg_ro_swire_records $net] {
            if {[lsearch -exact $before [dict get $rec handle]] < 0} {
                dict set rec points [mptdc_pg_ro_two_points [dict get $rec pts]]
                dict set rec orientation [mptdc_pg_ro_orientation [dict get $rec points]]
                lappend rows $rec
            }
        }
    }
    return $rows
}

proc mptdc_pg_ro_instance_set {} {
    if {[llength [info commands mptdc_signoff_collect_cells]] == 0 ||
        [llength [info commands mptdc_signoff_ro_cell_patterns]] == 0} {
        return {}
    }
    return [lsort -dictionary \
        [mptdc_signoff_collect_cells [mptdc_signoff_ro_cell_patterns]]]
}

proc mptdc_pg_ro_create_rings {fh} {
    set before [dict create VDD [mptdc_pg_ro_handle_set VDD] \
        VSS [mptdc_pg_ro_handle_set VSS]]
    set ro_instances [mptdc_pg_ro_instance_set]
    puts $fh "RO_INSTANCE_COUNT=[llength $ro_instances]"
    puts $fh "RO_INSTANCE_SET=[join $ro_instances ,]"
    if {$ro_instances ne [mptdc_pg_ro_expected_instance_set] ||
        [llength [info commands mptdc_signoff_create_ro_block_rings]] == 0} {
        return [dict create status FAIL reason missing_or_invalid_ro_ring_contract \
            records {} created 0 vdd_delta 0 vss_delta 0]
    }
    lassign [mptdc_signoff_create_ro_block_rings] ok ring_report
    set records [mptdc_pg_ro_new_ring_records $before]
    set vdd_delta 0
    set vss_delta 0
    set shape_fail 0
    set point_fail 0
    foreach rec $records {
        if {[dict get $rec net] eq "VDD"} { incr vdd_delta } else { incr vss_delta }
        if {[string tolower [dict get $rec shape]] ne "blockring" ||
            ![mptdc_pg_ro_close [dict get $rec width] 2.0 0.002]} { incr shape_fail }
        if {[dict get $rec orientation] eq "INVALID" ||
            [dict get $rec layer] ni {MET3 METTP}} { incr point_fail }
    }
    puts $fh "RO_BLOCK_RING_REPORT=$ring_report"
    puts $fh "RO_RING_CREATED_COUNT=[expr {$ok ? 2 : 0}]"
    puts $fh "RO_RING_NEW_SWIRE_COUNT=[llength $records]"
    puts $fh "RO_RING_SWIRE_DELTA_VDD=$vdd_delta"
    puts $fh "RO_RING_SWIRE_DELTA_VSS=$vss_delta"
    puts $fh "RO_RING_SHAPE_FAILURE_COUNT=$shape_fail"
    puts $fh "RO_RING_GEOMETRY_FAILURE_COUNT=$point_fail"
    set pass [expr {$ok && [llength $records] == 16 && $vdd_delta == 8 &&
        $vss_delta == 8 && $shape_fail == 0 && $point_fail == 0}]
    puts $fh "RING_GEOMETRY_STATUS=[expr {$pass ? {PASS} : {FAIL}}]"
    return [dict create status [expr {$pass ? {PASS} : {FAIL}}] \
        reason [expr {$pass ? {NONE} : {unexpected_ring_geometry_or_delta}}] \
        records $records created [expr {$ok ? 2 : 0}] \
        vdd_delta $vdd_delta vss_delta $vss_delta]
}

proc mptdc_pg_ro_between {value a b eps} {
    return [expr {$value >= (min($a, $b) - $eps) &&
        $value <= (max($a, $b) + $eps)}]
}

proc mptdc_pg_ro_mapping_candidate {entry ring eps max_tail} {
    set marker [dict get $entry marker]
    set source [dict get $entry rec]
    if {[dict get $source net] ne [dict get $ring net] ||
        [dict get $source layer] eq [dict get $ring layer]} {
        return {}
    }
    set sp [dict get $source points]
    set rp [dict get $ring points]
    set so [dict get $source orientation]
    set ro [dict get $ring orientation]
    if {$so eq "HORIZONTAL" && $ro eq "VERTICAL"} {
        set ix [lindex [lindex $rp 0] 0]
        set iy [lindex [lindex $sp 0] 1]
        if {![mptdc_pg_ro_between $iy [lindex [lindex $rp 0] 1] \
            [lindex [lindex $rp 1] 1] $eps]} { return {} }
    } elseif {$so eq "VERTICAL" && $ro eq "HORIZONTAL"} {
        set ix [lindex [lindex $sp 0] 0]
        set iy [lindex [lindex $rp 0] 1]
        if {![mptdc_pg_ro_between $ix [lindex [lindex $rp 0] 0] \
            [lindex [lindex $rp 1] 0] $eps]} { return {} }
    } else {
        return {}
    }
    set mx [dict get $marker x]
    set my [dict get $marker y]
    set distance [expr {sqrt(($ix - $mx) * ($ix - $mx) + ($iy - $my) * ($iy - $my))}]
    if {$distance > ($max_tail + $eps)} { return {} }
    set marker_point [list $mx $my]
    set endpoint_index -1
    if {[mptdc_pg_ro_same_point [lindex $sp 0] $marker_point $eps]} {
        set endpoint_index 0
    } elseif {[mptdc_pg_ro_same_point [lindex $sp 1] $marker_point $eps]} {
        set endpoint_index 1
    } else {
        return {}
    }
    set intersection [list [format %.3f $ix] [format %.3f $iy]]
    if {$so eq "HORIZONTAL"} {
        set inside [mptdc_pg_ro_between $ix [lindex [lindex $sp 0] 0] \
            [lindex [lindex $sp 1] 0] $eps]
    } else {
        set inside [mptdc_pg_ro_between $iy [lindex [lindex $sp 0] 1] \
            [lindex [lindex $sp 1] 1] $eps]
    }
    if {!$inside} {
        set other [lindex $sp [expr {1 - $endpoint_index}]]
        set vx [expr {$mx - [lindex $other 0]}]
        set vy [expr {$my - [lindex $other 1]}]
        set ex [expr {$ix - $mx}]
        set ey [expr {$iy - $my}]
        if {($vx * $ex + $vy * $ey) < -$eps} { return {} }
    }
    return [dict create marker $marker source $source ring $ring \
        intersection $intersection distance_um $distance \
        endpoint_index $endpoint_index action [expr {$inside ? {VIA_ONLY} : {EXTEND_ENDPOINT}}]]
}

proc mptdc_pg_ro_build_mappings {preflight ring_records} {
    set eps [mptdc_pg_ro_env_double MPTDC_PG_RO_MATCH_EPS_UM 0.002]
    set max_tail [mptdc_pg_ro_env_double MPTDC_PG_RO_RING_MAX_TAIL_UM 20.0]
    set mappings {}
    set failures {}
    foreach entry [dict get $preflight entries] {
        set candidates {}
        foreach ring $ring_records {
            set candidate [mptdc_pg_ro_mapping_candidate $entry $ring $eps $max_tail]
            if {[llength $candidate] > 0} { lappend candidates $candidate }
        }
        set ranked {}
        foreach candidate $candidates {
            lappend ranked [list [dict get $candidate distance_um] $candidate]
        }
        set candidates [lsort -real -index 0 $ranked]
        if {[llength $candidates] == 0} {
            lappend failures "marker_[dict get [dict get $entry marker] idx]_unmapped"
            continue
        }
        set best [lindex [lindex $candidates 0] 1]
        if {[llength $candidates] > 1} {
            set first_distance [lindex [lindex $candidates 0] 0]
            set second_distance [lindex [lindex $candidates 1] 0]
            if {[mptdc_pg_ro_close $first_distance $second_distance $eps]} {
                lappend failures "marker_[dict get [dict get $entry marker] idx]_ambiguous_ring"
                continue
            }
        }
        lappend mappings $best
    }
    return [dict create status [expr {[llength $mappings] == 15 &&
        [llength $failures] == 0 ? {PASS} : {FAIL}}] mappings $mappings failures $failures]
}

proc mptdc_pg_ro_write_mappings {fh mapping_data} {
    set mappings [dict get $mapping_data mappings]
    puts $fh "MAPPED_MARKER_COUNT=[llength $mappings]"
    puts $fh "MARKER_RING_MAPPING_STATUS=[dict get $mapping_data status]"
    puts $fh "MARKER_RING_MAPPING_FAILURES=[mptdc_pg_ro_report_value [dict get $mapping_data failures]]"
    foreach mapping $mappings {
        set marker [dict get $mapping marker]
        set idx [dict get $marker idx]
        puts $fh "MAPPING_${idx}_SOURCE_HANDLE=[mptdc_pg_ro_report_value [dict get [dict get $mapping source] handle]]"
        puts $fh "MAPPING_${idx}_RING_HANDLE=[mptdc_pg_ro_report_value [dict get [dict get $mapping ring] handle]]"
        puts $fh "MAPPING_${idx}_NET=[dict get $marker net]"
        puts $fh "MAPPING_${idx}_SOURCE_LAYER=[dict get $marker layer]"
        puts $fh "MAPPING_${idx}_INTERSECTION=[dict get $mapping intersection]"
        puts $fh "MAPPING_${idx}_DISTANCE_UM=[format %.3f [dict get $mapping distance_um]]"
        puts $fh "MAPPING_${idx}_ACTION=[dict get $mapping action]"
    }
}

proc mptdc_pg_ro_snapshot {fh tag} {
    set snapshot [mptdc_pg_dangling_snapshot_after_delete $fh $tag]
    if {[llength $snapshot] == 0} {
        return [dict create total_violations UNKNOWN shorts UNKNOWN regular_bad UNKNOWN \
            special_bad UNKNOWN route_gate_pass 0]
    }
    return $snapshot
}

proc mptdc_pg_ro_geometry_regular_clean {snapshot} {
    return [mptdc_pg_dangling_snapshot_is_geometry_regular_clean $snapshot]
}

proc mptdc_pg_ro_points_match {lhs rhs eps} {
    set lhs [mptdc_pg_ro_two_points $lhs]
    set rhs [mptdc_pg_ro_two_points $rhs]
    return [expr {[llength $lhs] == 2 && [llength $rhs] == 2 &&
        (([mptdc_pg_ro_same_point [lindex $lhs 0] [lindex $rhs 0] $eps] &&
          [mptdc_pg_ro_same_point [lindex $lhs 1] [lindex $rhs 1] $eps]) ||
         ([mptdc_pg_ro_same_point [lindex $lhs 0] [lindex $rhs 1] $eps] &&
          [mptdc_pg_ro_same_point [lindex $lhs 1] [lindex $rhs 0] $eps]))}]
}

proc mptdc_pg_ro_replace_source_handles {fh preflight mappings} {
    set by_handle [dict create]
    foreach mapping $mappings {
        dict lappend by_handle [dict get [dict get $mapping source] handle] $mapping
    }
    set eps [mptdc_pg_ro_env_double MPTDC_PG_RO_MATCH_EPS_UM 0.002]
    set attempts 0
    set successes 0
    set failures {}
    dict for {handle handle_mappings} $by_handle {
        set rec [dict get [dict get $preflight records] $handle]
        set points [dict get $rec points]
        set target_points $points
        set changed 0
        foreach mapping $handle_mappings {
            if {[dict get $mapping action] ne "EXTEND_ENDPOINT"} { continue }
            set endpoint [dict get $mapping endpoint_index]
            lset target_points $endpoint [dict get $mapping intersection]
            set changed 1
        }
        if {!$changed} {
            puts $fh "REPLACEMENT_[expr {$attempts + 1}]_STATUS=SKIPPED_VIA_ONLY"
            continue
        }
        incr attempts
        set prefix "REPLACEMENT_$attempts"
        puts $fh "${prefix}_SOURCE_HANDLE=[mptdc_pg_ro_report_value $handle]"
        puts $fh "${prefix}_SOURCE_POINTS=[mptdc_pg_ro_report_value $points]"
        puts $fh "${prefix}_TARGET_POINTS=[mptdc_pg_ro_report_value $target_points]"
        set before [mptdc_pg_ro_handle_set [dict get $rec net]]
        if {[catch {uplevel #0 [list dbDeleteObj $handle]} err]} {
            puts $fh "${prefix}_STATUS=FAIL_DELETE"
            puts $fh "${prefix}_ERROR=[mptdc_pg_ro_report_value $err]"
            lappend failures "$handle:delete_failed"
            continue
        }
        set flat_path [concat [lindex $target_points 0] [lindex $target_points 1]]
        set command [list add_shape -net [dict get $rec net] -layer [dict get $rec layer] \
            -shape STRIPE -status ROUTED -pathSeg $flat_path -width [dict get $rec width]]
        puts $fh "${prefix}_ADD_COMMAND=[mptdc_pg_ro_report_value $command]"
        if {[catch {uplevel #0 $command} err]} {
            puts $fh "${prefix}_STATUS=FAIL_ADD"
            puts $fh "${prefix}_ERROR=[mptdc_pg_ro_report_value $err]"
            lappend failures "$handle:add_failed"
            continue
        }
        set matches {}
        foreach new_rec [mptdc_pg_ro_swire_records [dict get $rec net]] {
            set new_handle [dict get $new_rec handle]
            if {[lsearch -exact $before $new_handle] >= 0} { continue }
            if {[dict get $new_rec layer] eq [dict get $rec layer] &&
                [mptdc_pg_ro_points_match [dict get $new_rec pts] $target_points $eps] &&
                [mptdc_pg_ro_close [dict get $new_rec width] [dict get $rec width] $eps]} {
                lappend matches $new_handle
            }
        }
        if {[llength $matches] != 1 ||
            [lsearch -exact [mptdc_pg_ro_handle_set [dict get $rec net]] $handle] >= 0} {
            puts $fh "${prefix}_STATUS=FAIL_READBACK"
            puts $fh "${prefix}_MATCH_COUNT=[llength $matches]"
            lappend failures "$handle:readback_failed"
            continue
        }
        incr successes
        puts $fh "${prefix}_NEW_HANDLE=[mptdc_pg_ro_report_value [lindex $matches 0]]"
        puts $fh "${prefix}_STATUS=PASS"
    }
    puts $fh "REPLACEMENT_ATTEMPTS=$attempts"
    puts $fh "REPLACEMENT_SUCCESSES=$successes"
    puts $fh "REPLACEMENT_FAILURES=[mptdc_pg_ro_report_value $failures]"
    return [dict create status [expr {[llength $failures] == 0 ? {PASS} : {FAIL}}] \
        attempts $attempts successes $successes failures $failures]
}

proc mptdc_pg_ro_via_handles_in_area {net area} {
    set nh [mptdc_pg_dangling_dbget "top.nets.name $net -p" ""]
    if {$nh eq "" || $nh eq "UNKNOWN"} { return {} }
    set out {}
    set via_handles [mptdc_pg_ro_valid_handles \
        [mptdc_pg_dangling_dbget "$nh.vias" ""]]
    foreach via [mptdc_pg_ro_valid_handles \
        [mptdc_pg_dangling_dbget "$nh.sVias" ""]] {
        if {[lsearch -exact $via_handles $via] < 0} { lappend via_handles $via }
    }
    foreach via $via_handles {
        set point [mptdc_pg_ro_two_points [mptdc_pg_dangling_dbget "$via.pt" ""]]
        if {[llength $point] == 0} {
            set raw [mptdc_pg_dangling_dbget "$via.pt" ""]
            if {[llength $raw] == 2} { set point [list $raw] }
        }
        if {[llength $point] != 1} { continue }
        lassign [lindex $point 0] x y
        if {[mptdc_pg_dangling_point_in_rect $x $y $area 0.002]} { lappend out $via }
    }
    return $out
}

proc mptdc_pg_ro_add_power_vias {fh mappings} {
    set half [mptdc_pg_ro_env_double MPTDC_PG_RO_VIA_AREA_HALF_UM 0.400]
    set keyed [dict create]
    foreach mapping $mappings {
        set net [dict get [dict get $mapping marker] net]
        lassign [dict get $mapping intersection] x y
        dict set keyed "$net|[format %.3f $x]|[format %.3f $y]" $mapping
    }
    set attempts 0
    set successes 0
    set failures {}
    foreach key [lsort -dictionary [dict keys $keyed]] {
        incr attempts
        set mapping [dict get $keyed $key]
        set net [dict get [dict get $mapping marker] net]
        lassign [dict get $mapping intersection] x y
        set area [list [format %.3f [expr {$x - $half}]] \
            [format %.3f [expr {$y - $half}]] \
            [format %.3f [expr {$x + $half}]] \
            [format %.3f [expr {$y + $half}]]]
        set before [mptdc_pg_ro_via_handles_in_area $net $area]
        set prefix "VIA_$attempts"
        puts $fh "${prefix}_NET=$net"
        puts $fh "${prefix}_POINT=[dict get $mapping intersection]"
        puts $fh "${prefix}_AREA=$area"
        puts $fh "${prefix}_COUNT_PRE=[llength $before]"
        if {[llength [info commands mptdc_signoff_ro_pg_via_commands]] == 0 ||
            [llength [info commands mptdc_signoff_try_pg_command]] == 0} {
            puts $fh "${prefix}_STATUS=FAIL_MISSING_COMMAND_HELPER"
            lappend failures "$key:missing_helper"
            continue
        }
        set command_ok [mptdc_signoff_try_pg_command $fh $prefix \
            [mptdc_signoff_ro_pg_via_commands $net MET3 METTP $area]]
        set after [mptdc_pg_ro_via_handles_in_area $net $area]
        set delta [expr {[llength $after] - [llength $before]}]
        puts $fh "${prefix}_COUNT_POST=[llength $after]"
        puts $fh "${prefix}_COUNT_DELTA=$delta"
        if {$command_ok && $delta > 0} {
            incr successes
            puts $fh "${prefix}_STATUS=PASS"
        } else {
            puts $fh "${prefix}_STATUS=FAIL_NO_VERIFIED_VIA_EFFECT"
            lappend failures "$key:no_verified_via_effect"
        }
    }
    puts $fh "VIA_ATTEMPTS=$attempts"
    puts $fh "VIA_SUCCESSES=$successes"
    puts $fh "VIA_FAILURES=[mptdc_pg_ro_report_value $failures]"
    return [dict create status [expr {[llength $failures] == 0 &&
        $attempts == [dict size $keyed] ? {PASS} : {FAIL}}] attempts $attempts \
        successes $successes failures $failures]
}

proc mptdc_pg_ro_final_dangling {report_dir} {
    set report [file join $report_dir pg_ro_final_verify_special_detailed.rpt]
    if {[catch {mptdc_pg_dangling_capture_verify_special $report} err]} {
        return [dict create status FAIL count UNKNOWN report $report error $err]
    }
    return [dict create status PASS count \
        [llength [mptdc_pg_dangling_parse_report $report]] report $report error NONE]
}

proc mptdc_pg_ro_long_prune {fh preflight report_dir} {
    set expected_auth EXACT_V13_PG15_13_HANDLE_LONG_PRUNE
    set actual_auth [mptdc_pg_ro_env MPTDC_PG_LONG_PRUNE_AUTHORIZATION NONE]
    puts $fh "LONG_PRUNE_AUTHORIZATION=$actual_auth"
    puts $fh "LONG_PRUNE_REQUIRED_AUTHORIZATION=$expected_auth"
    if {$actual_auth ne $expected_auth} {
        puts $fh "PRUNE_ATTEMPTS=0"
        puts $fh "PRUNE_SUCCESSES=0"
        return [dict create status FAIL reason authorization_missing attempts 0 successes 0]
    }
    set remaining [dict get $preflight marker_count]
    set attempts 0
    set successes 0
    set failures {}
    foreach rec [mptdc_pg_ro_sorted_unique_records $preflight] {
        incr attempts
        set handle [dict get $rec handle]
        set refs [dict get [dict get $preflight handle_counts] $handle]
        set prefix "PRUNE_$attempts"
        puts $fh "${prefix}_HANDLE=[mptdc_pg_ro_report_value $handle]"
        puts $fh "${prefix}_NET=[dict get $rec net]"
        puts $fh "${prefix}_LAYER=[dict get $rec layer]"
        puts $fh "${prefix}_POINTS=[mptdc_pg_ro_report_value [dict get $rec points]]"
        puts $fh "${prefix}_MARKER_REFERENCE_COUNT=$refs"
        if {[catch {uplevel #0 [list dbDeleteObj $handle]} err]} {
            puts $fh "${prefix}_STATUS=FAIL_DELETE"
            puts $fh "${prefix}_ERROR=[mptdc_pg_ro_report_value $err]"
            lappend failures "$handle:delete_failed"
            break
        }
        if {[lsearch -exact [mptdc_pg_ro_handle_set [dict get $rec net]] $handle] >= 0} {
            puts $fh "${prefix}_STATUS=FAIL_HANDLE_PERSISTED"
            lappend failures "$handle:persisted"
            break
        }
        set remaining [expr {$remaining - $refs}]
        set snapshot [mptdc_pg_ro_snapshot $fh [format "pg_ro_after_prune_%02d" $attempts]]
        set detailed [file join $report_dir [format "pg_ro_after_prune_%02d_special_detailed.rpt" $attempts]]
        mptdc_pg_dangling_capture_verify_special $detailed
        set observed [llength [mptdc_pg_dangling_parse_report $detailed]]
        puts $fh "${prefix}_EXPECTED_DANGLING_COUNT=$remaining"
        puts $fh "${prefix}_OBSERVED_DANGLING_COUNT=$observed"
        if {![mptdc_pg_ro_geometry_regular_clean $snapshot] || $observed != $remaining} {
            puts $fh "${prefix}_STATUS=FAIL_INCREMENTAL_GATE"
            lappend failures "$handle:incremental_gate_failed"
            break
        }
        incr successes
        puts $fh "${prefix}_STATUS=PASS"
    }
    puts $fh "PRUNE_ATTEMPTS=$attempts"
    puts $fh "PRUNE_SUCCESSES=$successes"
    puts $fh "PRUNE_FAILURES=[mptdc_pg_ro_report_value $failures]"
    set pass [expr {[llength $failures] == 0 && $attempts == 13 &&
        $successes == 13 && $remaining == 0}]
    return [dict create status [expr {$pass ? {PASS} : {FAIL}}] \
        reason [expr {$pass ? {NONE} : {prune_gate_failed}}] \
        attempts $attempts successes $successes]
}

proc mptdc_pg_ro_run {{mode ""}} {
    if {$mode eq ""} {
        set mode [string tolower [mptdc_pg_ro_env MPTDC_PG_RO_MODE ring_probe]]
    } else {
        set mode [string tolower $mode]
    }
    set report_dir [mptdc_pg_dangling_report_dir]
    file mkdir $report_dir
    set report [file join $report_dir pg_ro_ring_repair_status.rpt]
    set fh [open $report w]
    puts $fh "# MPTDC V13 RO Ring / Long-Prune PG Repair"
    puts $fh "PG_RO_REPAIR_MODE=$mode"
    puts $fh "PROCESS_ISOLATION=ONE_INNOVUS_PROCESS_PER_CANDIDATE"
    puts $fh "SOURCE_CONTRACT=V13_DRC0_SPECIAL15_EXACT13_LONG_HANDLES"
    puts $fh "SOURCE_MARKER_FINGERPRINT_POLICY=EXACT_V13_PG15"
    puts $fh "MATCH_EPS_UM=[mptdc_pg_ro_env MPTDC_PG_RO_MATCH_EPS_UM 0.002]"
    puts $fh "EXPECTED_MIN_SOURCE_LENGTH_UM=[mptdc_pg_ro_env MPTDC_PG_RO_EXPECTED_MIN_LENGTH_UM 10.0]"
    puts $fh "RING_MAX_TAIL_UM=[mptdc_pg_ro_env MPTDC_PG_RO_RING_MAX_TAIL_UM 20.0]"
    puts $fh "VIA_AREA_HALF_UM=[mptdc_pg_ro_env MPTDC_PG_RO_VIA_AREA_HALF_UM 0.400]"
    puts $fh "RO_BLOCK_RING_WIDTH_UM=[mptdc_pg_ro_env MPTDC_RO_BLOCK_RING_WIDTH_UM 2.0]"
    puts $fh "RO_BLOCK_RING_SPACING_UM=[mptdc_pg_ro_env MPTDC_RO_BLOCK_RING_SPACING_UM 1.0]"
    puts $fh "RO_BLOCK_RING_OFFSET_UM=[mptdc_pg_ro_env MPTDC_RO_BLOCK_RING_OFFSET_UM 2.0]"
    puts $fh "ANTENNA_REPAIR_ATTEMPTED=NO"
    puts $fh "ROUTE_OPTIMIZER_POLICY=NO_ECOROUTE_NO_ROUTEDESIGN_NO_GLOBAL_OPTIMIZER"
    puts $fh "PLACEMENT_EDIT_POLICY=NO_INSTANCES_MOVED"
    puts $fh "PG_MUTATION_SCOPE=[expr {$mode eq {long_prune} ? {EXACT_13_SOURCE_SWIRE_HANDLES} : {TWO_RO_BLOCK_RINGS_EXACT_SOURCE_ENDPOINTS_BOUNDED_VIAS}}]"

    set preflight [mptdc_pg_ro_preflight]
    mptdc_pg_ro_write_preflight $fh $preflight
    set final_status FAIL_PREFLIGHT
    set ring_data [dict create status NOT_RUN records {}]
    set mapping_data [dict create status NOT_RUN mappings {} failures {}]
    set replacement_data [dict create status NOT_RUN attempts 0 successes 0]
    set via_data [dict create status NOT_RUN attempts 0 successes 0]
    set prune_data [dict create status NOT_RUN attempts 0 successes 0]
    set post_snapshot {}

    if {[dict get $preflight status] eq "PASS"} {
        if {$mode in {ring_probe ring_stitch}} {
            set ring_data [mptdc_pg_ro_create_rings $fh]
            if {[dict get $ring_data status] eq "PASS"} {
                set mapping_data [mptdc_pg_ro_build_mappings $preflight \
                    [dict get $ring_data records]]
                mptdc_pg_ro_write_mappings $fh $mapping_data
                set ring_snapshot [mptdc_pg_ro_snapshot $fh pg_ro_after_ring]
                set ring_clean [mptdc_pg_ro_geometry_regular_clean $ring_snapshot]
                puts $fh "RING_POST_GEOMETRY_REGULAR_STATUS=[expr {$ring_clean ? {PASS} : {FAIL}}]"
                if {$mode eq "ring_probe"} {
                    if {[dict get $mapping_data status] eq "PASS" && $ring_clean} {
                        set final_status PASS_PROBE_READY
                    } elseif {!$ring_clean} {
                        set final_status REVIEW_RING_GEOMETRY_DIRTY
                    } else {
                        set final_status REVIEW_RING_MAPPING_BLOCKED
                    }
                } elseif {[dict get $mapping_data status] eq "PASS" && $ring_clean} {
                    set replacement_data [mptdc_pg_ro_replace_source_handles $fh \
                        $preflight [dict get $mapping_data mappings]]
                    if {[dict get $replacement_data status] eq "PASS"} {
                        set via_data [mptdc_pg_ro_add_power_vias $fh \
                            [dict get $mapping_data mappings]]
                    }
                    set post_snapshot [mptdc_pg_ro_snapshot $fh pg_ro_after_stitch]
                    if {[dict get $replacement_data status] eq "PASS" &&
                        [dict get $via_data status] eq "PASS" &&
                        [mptdc_pg_ro_geometry_regular_clean $post_snapshot]} {
                        set final_status PENDING_SPECIAL_PROOF
                    } else {
                        set final_status FAIL_STITCH_GATE
                    }
                } else {
                    set final_status FAIL_STITCH_PREFLIGHT
                }
            } else {
                puts $fh "MAPPED_MARKER_COUNT=0"
                puts $fh "MARKER_RING_MAPPING_STATUS=NOT_RUN"
                set final_status REVIEW_RING_CREATION_BLOCKED
            }
        } elseif {$mode eq "long_prune"} {
            set ro_instances [mptdc_pg_ro_instance_set]
            puts $fh "RO_INSTANCE_COUNT=[llength $ro_instances]"
            puts $fh "RO_INSTANCE_SET=[join $ro_instances ,]"
            puts $fh "RO_RING_CREATED_COUNT=0"
            puts $fh "RO_RING_SWIRE_DELTA_VDD=0"
            puts $fh "RO_RING_SWIRE_DELTA_VSS=0"
            puts $fh "RING_GEOMETRY_STATUS=NOT_RUN_BY_LONG_PRUNE_SCOPE"
            puts $fh "MAPPED_MARKER_COUNT=0"
            puts $fh "MARKER_RING_MAPPING_STATUS=NOT_RUN_BY_LONG_PRUNE_SCOPE"
            if {$ro_instances eq [mptdc_pg_ro_expected_instance_set]} {
                set prune_data [mptdc_pg_ro_long_prune $fh $preflight $report_dir]
            } else {
                set prune_data [dict create status FAIL reason invalid_ro_instance_count \
                    attempts 0 successes 0]
                puts $fh "PRUNE_ATTEMPTS=0"
                puts $fh "PRUNE_SUCCESSES=0"
                puts $fh "PRUNE_FAILURES=invalid_ro_instance_count"
            }
            set post_snapshot [mptdc_pg_ro_snapshot $fh pg_ro_after_long_prune]
            if {[dict get $prune_data status] eq "PASS" &&
                [mptdc_pg_ro_geometry_regular_clean $post_snapshot]} {
                set final_status PENDING_SPECIAL_PROOF
            } else {
                set final_status FAIL_LONG_PRUNE_GATE
            }
        } else {
            set final_status FAIL_UNSUPPORTED_MODE
        }
    }

    if {$mode ne "ring_stitch"} {
        puts $fh "REPLACEMENT_ATTEMPTS=[dict get $replacement_data attempts]"
        puts $fh "REPLACEMENT_SUCCESSES=[dict get $replacement_data successes]"
    }
    if {$mode ne "ring_stitch"} {
        puts $fh "VIA_ATTEMPTS=[dict get $via_data attempts]"
        puts $fh "VIA_SUCCESSES=[dict get $via_data successes]"
    }
    if {$mode ne "long_prune"} {
        puts $fh "PRUNE_ATTEMPTS=[dict get $prune_data attempts]"
        puts $fh "PRUNE_SUCCESSES=[dict get $prune_data successes]"
    }
    set final [mptdc_pg_ro_final_dangling $report_dir]
    puts $fh "FINAL_VERIFY_SPECIAL_REPORT=[dict get $final report]"
    puts $fh "FINAL_DANGLING_MARKER_COUNT=[dict get $final count]"
    if {$final_status eq "PENDING_SPECIAL_PROOF"} {
        if {[dict get $final status] eq "PASS" && [dict get $final count] == 0} {
            set final_status PASS_DANGLING_CLEARED
        } else {
            set final_status FAIL_DANGLING_REMAINS
        }
    }
    puts $fh "PG_RO_REPAIR_STATUS=$final_status"
    close $fh
    puts "MPTDC_PG_RO_RING_REPAIR_REPORT=$report"
    return $report
}

if {[mptdc_pg_ro_env_truthy MPTDC_PG_RO_AUTORUN 1]} {
    mptdc_pg_ro_run
}
