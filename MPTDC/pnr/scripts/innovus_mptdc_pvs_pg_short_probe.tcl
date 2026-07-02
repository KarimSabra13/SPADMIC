# =============================================================================
# Project  : SPAD_MPTDC
# File     : innovus_mptdc_pvs_pg_short_probe.tcl
# Purpose  : Map PVS VDD/VSS short polygons to Innovus special-net objects and
#            optionally run a bounded safe-copy surgical proof.
# =============================================================================

proc mptdc_pvs_pg_short_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_pvs_pg_short_env_truthy {name default_value} {
    set value [string tolower [mptdc_pvs_pg_short_env $name $default_value]]
    return [expr {$value in {1 true yes on y}}]
}

proc mptdc_pvs_pg_short_env_double {name default_value} {
    set value [mptdc_pvs_pg_short_env $name $default_value]
    if {![string is double -strict $value]} {
        error "environment variable $name must be numeric, got: $value"
    }
    return $value
}

proc mptdc_pvs_pg_short_report_dir {} {
    if {[llength [info commands mptdc_signoff_report_dir]] > 0} {
        return [mptdc_signoff_report_dir]
    }
    set result_dir [mptdc_pvs_pg_short_env MPTDC_SIGNOFF_RESULT_DIR "."]
    return [file join $result_dir reports]
}

proc mptdc_pvs_pg_short_report_value {value} {
    if {[llength [info commands mptdc_signoff_report_value]] > 0} {
        return [mptdc_signoff_report_value $value]
    }
    regsub -all {\s+} $value { } compact
    return [string trim $compact]
}

proc mptdc_pvs_pg_short_csv {value} {
    set value [mptdc_pvs_pg_short_report_value $value]
    regsub -all {"} $value {""} escaped
    return "\"$escaped\""
}

proc mptdc_pvs_pg_short_dbget {expr {default UNKNOWN}} {
    if {[catch {set value [uplevel #0 "dbGet $expr"]}]} {
        return $default
    }
    if {$value eq "" || $value eq "0x0" || $value eq "NULL"} {
        return $default
    }
    return $value
}

proc mptdc_pvs_pg_short_rect {raw} {
    set raw [string trim $raw]
    if {$raw eq "" || $raw eq "UNKNOWN" || $raw eq "0x0" || $raw eq "NULL"} {
        return {}
    }
    if {[llength $raw] != 4} {
        return {}
    }
    foreach value $raw {
        if {![string is double -strict $value]} {
            return {}
        }
    }
    return $raw
}

proc mptdc_pvs_pg_short_parse_rect_env {name default_value} {
    set raw [mptdc_pvs_pg_short_env $name $default_value]
    set rect [mptdc_pvs_pg_short_rect $raw]
    if {[llength $rect] != 4} {
        error "environment variable $name must be a four-number box, got: $raw"
    }
    return $rect
}

proc mptdc_pvs_pg_short_format_rect {rect} {
    if {[llength $rect] != 4} {
        return UNKNOWN
    }
    lassign $rect x1 y1 x2 y2
    return [format "%.3f %.3f %.3f %.3f" $x1 $y1 $x2 $y2]
}

proc mptdc_pvs_pg_short_bbox_from_points {points} {
    set first 1
    foreach pt $points {
        if {[llength $pt] != 2} {
            continue
        }
        set x [lindex $pt 0]
        set y [lindex $pt 1]
        if {$first} {
            set x1 $x
            set x2 $x
            set y1 $y
            set y2 $y
            set first 0
        } else {
            if {$x < $x1} { set x1 $x }
            if {$x > $x2} { set x2 $x }
            if {$y < $y1} { set y1 $y }
            if {$y > $y2} { set y2 $y }
        }
    }
    if {$first} {
        return {}
    }
    return [list $x1 $y1 $x2 $y2]
}

proc mptdc_pvs_pg_short_rect_overlap_area {a b} {
    if {[llength $a] != 4 || [llength $b] != 4} {
        return 0.0
    }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    set ox1 [expr {$ax1 > $bx1 ? $ax1 : $bx1}]
    set oy1 [expr {$ay1 > $by1 ? $ay1 : $by1}]
    set ox2 [expr {$ax2 < $bx2 ? $ax2 : $bx2}]
    set oy2 [expr {$ay2 < $by2 ? $ay2 : $by2}]
    if {$ox2 <= $ox1 || $oy2 <= $oy1} {
        return 0.0
    }
    return [expr {($ox2 - $ox1) * ($oy2 - $oy1)}]
}

proc mptdc_pvs_pg_short_rect_center {rect} {
    if {[llength $rect] != 4} {
        return {}
    }
    lassign $rect x1 y1 x2 y2
    return [list [expr {($x1 + $x2) / 2.0}] [expr {($y1 + $y2) / 2.0}]]
}

proc mptdc_pvs_pg_short_point_in_rect {pt rect {eps 0.0}} {
    if {[llength $pt] != 2 || [llength $rect] != 4} {
        return 0
    }
    lassign $pt x y
    lassign $rect x1 y1 x2 y2
    return [expr {$x >= ($x1 - $eps) && $x <= ($x2 + $eps) &&
                  $y >= ($y1 - $eps) && $y <= ($y2 + $eps)}]
}

proc mptdc_pvs_pg_short_expand_rect {rect margin} {
    if {[llength $rect] != 4} {
        return {}
    }
    lassign $rect x1 y1 x2 y2
    return [list [expr {$x1 - $margin}] [expr {$y1 - $margin}] \
                 [expr {$x2 + $margin}] [expr {$y2 + $margin}]]
}

proc mptdc_pvs_pg_short_rect_span {rect} {
    if {[llength $rect] != 4} {
        return UNKNOWN
    }
    lassign $rect x1 y1 x2 y2
    set dx [expr {abs($x2 - $x1)}]
    set dy [expr {abs($y2 - $y1)}]
    return [expr {$dx > $dy ? $dx : $dy}]
}

proc mptdc_pvs_pg_short_layer_to_innovus {layer} {
    switch -nocase -- [string trim $layer] {
        m1trm { return MET1 }
        m2trm { return MET2 }
        m3trm { return MET3 }
        mttrm { return METTP }
        via1 - via1con { return VIA1 }
        via2con { return VIA2 }
        vtpcon { return VIATP }
        default { return UNKNOWN }
    }
}

proc mptdc_pvs_pg_short_parse_file {path} {
    if {$path eq "" || ![file exists $path]} {
        error "PVS shorts report is missing: $path"
    }
    set shorts {}
    set current {}
    set active {}
    set point_count 0
    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {[regexp {^SHORT[[:space:]]+([0-9]+)\.[[:space:]]+([^[:space:]]+)[[:space:]]+-[[:space:]]+([^[:space:]]+)[[:space:]]+in[[:space:]]+(.+)$} $trimmed -> sid net_a net_b cell]} {
            if {[llength $current] > 0} {
                lappend shorts $current
            }
            set current [dict create id $sid net_a $net_a net_b $net_b cell [string trim $cell] labels {} polygons {}]
            set active {}
            set point_count 0
            continue
        }
        if {[llength $current] == 0} {
            continue
        }
        if {[regexp {^"([^"]+)"[[:space:]]+at[[:space:]]+\(([0-9.+-]+),[[:space:]]*([0-9.+-]+)\)[[:space:]]+on[[:space:]]+layer[[:space:]]+"([^"]+)"} $trimmed -> label x y layer]} {
            dict lappend current labels [dict create label $label x $x y $y layer $layer]
            continue
        }
        if {[regexp {^p[[:space:]]+([0-9]+)[[:space:]]+([0-9]+)$} $trimmed -> pid npts]} {
            set active [dict create poly_id $pid point_count $npts sn UNKNOWN pvs_layer UNKNOWN innovus_layer UNKNOWN points {} bbox {}]
            set point_count $npts
            continue
        }
        if {[llength $active] > 0 && [regexp {^SN[[:space:]]+([0-9]+)[[:space:]]+([^[:space:]]+)$} $trimmed -> sn layer]} {
            dict set active sn $sn
            dict set active pvs_layer $layer
            dict set active innovus_layer [mptdc_pvs_pg_short_layer_to_innovus $layer]
            continue
        }
        if {[llength $active] > 0 && [regexp {^([-0-9]+)[[:space:]]+([-0-9]+)$} $trimmed -> raw_x raw_y]} {
            set x [expr {$raw_x / 1000.0}]
            set y [expr {$raw_y / 1000.0}]
            dict lappend active points [list $x $y]
            if {[llength [dict get $active points]] >= $point_count} {
                dict set active bbox [mptdc_pvs_pg_short_bbox_from_points [dict get $active points]]
                dict lappend current polygons $active
                set active {}
                set point_count 0
            }
        }
    }
    close $fh
    if {[llength $current] > 0} {
        lappend shorts $current
    }
    return $shorts
}

proc mptdc_pvs_pg_short_is_target {short} {
    set tokens [list [dict get $short net_a] [dict get $short net_b]]
    foreach label [dict get $short labels] {
        lappend tokens [dict get $label label]
    }
    set has_vdd 0
    set has_vss 0
    foreach token $tokens {
        if {[string match -nocase "VDD*" $token]} {
            set has_vdd 1
        }
        if {[string match -nocase "VSS*" $token]} {
            set has_vss 1
        }
    }
    return [expr {$has_vdd && $has_vss}]
}

proc mptdc_pvs_pg_short_swire_record {sw net} {
    set layer [mptdc_pvs_pg_short_dbget "$sw.layer.name"]
    set shape [mptdc_pvs_pg_short_dbget "$sw.shape"]
    set status [mptdc_pvs_pg_short_dbget "$sw.status"]
    set width [mptdc_pvs_pg_short_dbget "$sw.width"]
    set geom [mptdc_pvs_pg_short_dbget "$sw.geomType"]
    set box_raw [mptdc_pvs_pg_short_dbget "$sw.box" ""]
    set pts_raw [mptdc_pvs_pg_short_dbget "$sw.pts" ""]
    set rect [mptdc_pvs_pg_short_rect $box_raw]
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
        pts $pts_raw]
}

proc mptdc_pvs_pg_short_collect_swires {{nets {VDD VSS}}} {
    set records {}
    foreach net $nets {
        set nh [mptdc_pvs_pg_short_dbget "top.nets.name $net -p" ""]
        if {$nh eq "" || $nh eq "UNKNOWN"} {
            continue
        }
        set swires [mptdc_pvs_pg_short_dbget "$nh.sWires" ""]
        foreach sw $swires {
            if {$sw eq "" || $sw eq "0x0" || $sw eq "NULL"} {
                continue
            }
            lappend records [mptdc_pvs_pg_short_swire_record $sw $net]
        }
    }
    return $records
}

proc mptdc_pvs_pg_short_match_polygon {poly swires} {
    set matches {}
    set layer [dict get $poly innovus_layer]
    set bbox [dict get $poly bbox]
    set center [mptdc_pvs_pg_short_rect_center $bbox]
    foreach rec $swires {
        set sw_layer [dict get $rec layer]
        set rect [dict get $rec rect]
        if {$layer eq "UNKNOWN" || $sw_layer ne $layer || [llength $rect] != 4} {
            continue
        }
        set overlap [mptdc_pvs_pg_short_rect_overlap_area $bbox $rect]
        set center_match [mptdc_pvs_pg_short_point_in_rect $center $rect 0.001]
        if {$overlap > 0.0 || $center_match} {
            dict set rec overlap_area_um2 $overlap
            dict set rec center_match $center_match
            lappend matches $rec
        }
    }
    return $matches
}

proc mptdc_pvs_pg_short_write_swire_match {fh prefix rec} {
    puts $fh "${prefix}_MATCH_NET=[dict get $rec net]"
    puts $fh "${prefix}_MATCH_LAYER=[mptdc_pvs_pg_short_report_value [dict get $rec layer]]"
    puts $fh "${prefix}_MATCH_SHAPE=[mptdc_pvs_pg_short_report_value [dict get $rec shape]]"
    puts $fh "${prefix}_MATCH_STATUS=[mptdc_pvs_pg_short_report_value [dict get $rec status]]"
    puts $fh "${prefix}_MATCH_WIDTH=[mptdc_pvs_pg_short_report_value [dict get $rec width]]"
    puts $fh "${prefix}_MATCH_GEOMTYPE=[mptdc_pvs_pg_short_report_value [dict get $rec geomType]]"
    puts $fh "${prefix}_MATCH_BOX=[mptdc_pvs_pg_short_format_rect [dict get $rec rect]]"
    puts $fh "${prefix}_MATCH_OVERLAP_UM2=[format %.6f [dict get $rec overlap_area_um2]]"
    puts $fh "${prefix}_MATCH_CENTER=[dict get $rec center_match]"
    puts $fh "${prefix}_MATCH_HANDLE=[mptdc_pvs_pg_short_report_value [dict get $rec handle]]"
}

proc mptdc_pvs_pg_short_collect_delete_candidates {swires bridge_window max_span} {
    set candidates {}
    foreach rec $swires {
        set net [dict get $rec net]
        set layer [dict get $rec layer]
        set shape [string toupper [dict get $rec shape]]
        set rect [dict get $rec rect]
        if {$net ni {VDD VSS}} {
            continue
        }
        if {$layer ni {MET1 MET2 MET3 METTP}} {
            continue
        }
        if {$shape ne "BLOCKWIRE"} {
            continue
        }
        if {[mptdc_pvs_pg_short_rect_overlap_area $rect $bridge_window] <= 0.0} {
            continue
        }
        set span [mptdc_pvs_pg_short_rect_span $rect]
        if {$span eq "UNKNOWN" || $span > $max_span} {
            continue
        }
        dict set rec candidate_span_um $span
        lappend candidates $rec
    }
    return $candidates
}

proc mptdc_pvs_pg_short_delete_candidate {rec fh idx margin} {
    set net [dict get $rec net]
    set layer [dict get $rec layer]
    set shape [dict get $rec shape]
    set rect [dict get $rec rect]
    set area [mptdc_pvs_pg_short_expand_rect $rect $margin]
    puts $fh "DELETE_${idx}_NET=$net"
    puts $fh "DELETE_${idx}_LAYER=$layer"
    puts $fh "DELETE_${idx}_SHAPE=[mptdc_pvs_pg_short_report_value $shape]"
    puts $fh "DELETE_${idx}_BOX=[mptdc_pvs_pg_short_format_rect $rect]"
    puts $fh "DELETE_${idx}_AREA=[mptdc_pvs_pg_short_format_rect $area]"
    puts $fh "DELETE_${idx}_SPAN_UM=[format %.3f [dict get $rec candidate_span_um]]"
    flush $fh
    if {[catch {uplevel #0 [list editDelete -net $net -layer $layer -area $area -type Special]} err]} {
        puts $fh "DELETE_${idx}_STATUS=FAIL"
        puts $fh "DELETE_${idx}_ERROR=[mptdc_pvs_pg_short_report_value $err]"
        return 0
    }
    puts $fh "DELETE_${idx}_STATUS=PASS"
    return 1
}

proc mptdc_pvs_pg_short_write_snapshot {fh prefix snapshot} {
    if {[llength [info commands mptdc_ckpt_write_snapshot_status]] > 0} {
        mptdc_ckpt_write_snapshot_status $fh $prefix $snapshot
        return
    }
    puts $fh "${prefix}_SNAPSHOT=[mptdc_pvs_pg_short_report_value $snapshot]"
}

proc mptdc_pvs_pg_short_run {{mode ""}} {
    if {$mode eq ""} {
        set mode [string tolower [mptdc_pvs_pg_short_env MPTDC_PVS_PG_SHORT_MODE analyze]]
    } else {
        set mode [string tolower $mode]
    }
    if {$mode ni {analyze analysis surgical_proof}} {
        error "unsupported MPTDC_PVS_PG_SHORT_MODE: $mode"
    }
    set pvs_shorts [mptdc_pvs_pg_short_env MPTDC_PVS_PG_SHORTS_FILE ""]
    set source_def [mptdc_pvs_pg_short_env MPTDC_PVS_PG_SHORT_SOURCE_DEF ""]
    set bridge_window [mptdc_pvs_pg_short_parse_rect_env MPTDC_PVS_PG_SHORT_BRIDGE_WINDOW_UM {48.0 598.0 113.0 688.5}]
    set margin [mptdc_pvs_pg_short_env_double MPTDC_PVS_PG_SHORT_DELETE_MARGIN_UM 0.05]
    set max_span [mptdc_pvs_pg_short_env_double MPTDC_PVS_PG_SHORT_MAX_DELETE_SPAN_UM 90.0]
    set report_dir [mptdc_pvs_pg_short_report_dir]
    file mkdir $report_dir

    set shorts [mptdc_pvs_pg_short_parse_file $pvs_shorts]
    set swires [mptdc_pvs_pg_short_collect_swires {VDD VSS}]
    set map_rpt [file join $report_dir pvs_pg_short_polygon_map.rpt]
    set csv_rpt [file join $report_dir pvs_pg_short_specialnet_map.csv]
    set status_rpt [file join $report_dir pvs_pg_short_root_cause_status.rpt]

    set map_fh [open $map_rpt w]
    set csv_fh [open $csv_rpt w]
    puts $map_fh "# MPTDC PVS PG Short Polygon Map"
    puts $map_fh "MODE=$mode"
    puts $map_fh "PVS_SHORTS_FILE=$pvs_shorts"
    puts $map_fh "SOURCE_DEF=[expr {$source_def eq "" ? "unset" : $source_def}]"
    puts $map_fh "BRIDGE_WINDOW_UM=[mptdc_pvs_pg_short_format_rect $bridge_window]"
    puts $map_fh "SWIRE_RECORDS_SCANNED=[llength $swires]"
    puts $csv_fh "short_id,net_a,net_b,poly_id,pvs_sn,pvs_layer,innovus_layer,pvs_box_um,bridge_window_overlap_um2,match_count,match_net,match_layer,match_shape,match_box_um,match_overlap_um2,classification"

    set target_count 0
    set target_polygon_count 0
    set matched_polygon_count 0
    set bridge_polygon_count 0
    set vdd_match_count 0
    set vss_match_count 0
    foreach short $shorts {
        if {![mptdc_pvs_pg_short_is_target $short]} {
            continue
        }
        incr target_count
        set sid [dict get $short id]
        set net_a [dict get $short net_a]
        set net_b [dict get $short net_b]
        puts $map_fh ""
        puts $map_fh "SHORT_${sid}_NET_A=$net_a"
        puts $map_fh "SHORT_${sid}_NET_B=$net_b"
        puts $map_fh "SHORT_${sid}_CELL=[mptdc_pvs_pg_short_report_value [dict get $short cell]]"
        puts $map_fh "SHORT_${sid}_LABEL_COUNT=[llength [dict get $short labels]]"
        set label_idx 0
        foreach label [dict get $short labels] {
            incr label_idx
            puts $map_fh "SHORT_${sid}_LABEL_${label_idx}=[dict get $label label] @([dict get $label x],[dict get $label y]) [dict get $label layer]"
        }
        foreach poly [dict get $short polygons] {
            incr target_polygon_count
            set pid [dict get $poly poly_id]
            set pvs_layer [dict get $poly pvs_layer]
            set innovus_layer [dict get $poly innovus_layer]
            set bbox [dict get $poly bbox]
            set bridge_overlap [mptdc_pvs_pg_short_rect_overlap_area $bbox $bridge_window]
            if {$bridge_overlap > 0.0} {
                incr bridge_polygon_count
            }
            set matches [mptdc_pvs_pg_short_match_polygon $poly $swires]
            set match_count [llength $matches]
            if {$match_count > 0} {
                incr matched_polygon_count
            }
            set classification [expr {$match_count > 0 ? "SPECIAL_SWIRE_MATCH" : "NO_TOP_SWIRE_MATCH"}]
            puts $map_fh "SHORT_${sid}_POLY_${pid}_SN=[dict get $poly sn]"
            puts $map_fh "SHORT_${sid}_POLY_${pid}_PVS_LAYER=$pvs_layer"
            puts $map_fh "SHORT_${sid}_POLY_${pid}_INNOVUS_LAYER=$innovus_layer"
            puts $map_fh "SHORT_${sid}_POLY_${pid}_BOX_UM=[mptdc_pvs_pg_short_format_rect $bbox]"
            puts $map_fh "SHORT_${sid}_POLY_${pid}_BRIDGE_WINDOW_OVERLAP_UM2=[format %.6f $bridge_overlap]"
            puts $map_fh "SHORT_${sid}_POLY_${pid}_MATCH_COUNT=$match_count"
            puts $map_fh "SHORT_${sid}_POLY_${pid}_CLASSIFICATION=$classification"
            set mi 0
            foreach rec $matches {
                incr mi
                set match_net [dict get $rec net]
                if {$match_net eq "VDD"} { incr vdd_match_count }
                if {$match_net eq "VSS"} { incr vss_match_count }
                if {$mi <= 8} {
                    mptdc_pvs_pg_short_write_swire_match $map_fh "SHORT_${sid}_POLY_${pid}_MATCH_${mi}" $rec
                }
                if {$mi == 1} {
                    puts $csv_fh "[mptdc_pvs_pg_short_csv $sid],[mptdc_pvs_pg_short_csv $net_a],[mptdc_pvs_pg_short_csv $net_b],[mptdc_pvs_pg_short_csv $pid],[mptdc_pvs_pg_short_csv [dict get $poly sn]],[mptdc_pvs_pg_short_csv $pvs_layer],[mptdc_pvs_pg_short_csv $innovus_layer],[mptdc_pvs_pg_short_csv [mptdc_pvs_pg_short_format_rect $bbox]],[format %.6f $bridge_overlap],$match_count,[mptdc_pvs_pg_short_csv $match_net],[mptdc_pvs_pg_short_csv [dict get $rec layer]],[mptdc_pvs_pg_short_csv [dict get $rec shape]],[mptdc_pvs_pg_short_csv [mptdc_pvs_pg_short_format_rect [dict get $rec rect]]],[format %.6f [dict get $rec overlap_area_um2]],[mptdc_pvs_pg_short_csv $classification]"
                }
            }
            if {$match_count == 0} {
                puts $csv_fh "[mptdc_pvs_pg_short_csv $sid],[mptdc_pvs_pg_short_csv $net_a],[mptdc_pvs_pg_short_csv $net_b],[mptdc_pvs_pg_short_csv $pid],[mptdc_pvs_pg_short_csv [dict get $poly sn]],[mptdc_pvs_pg_short_csv $pvs_layer],[mptdc_pvs_pg_short_csv $innovus_layer],[mptdc_pvs_pg_short_csv [mptdc_pvs_pg_short_format_rect $bbox]],[format %.6f $bridge_overlap],0,,,,,,[mptdc_pvs_pg_short_csv $classification]"
            }
        }
    }
    close $map_fh
    close $csv_fh

    set candidates [mptdc_pvs_pg_short_collect_delete_candidates $swires $bridge_window $max_span]
    set status_fh [open $status_rpt w]
    puts $status_fh "# MPTDC PVS PG Short Root Cause Status"
    puts $status_fh "MODE=$mode"
    puts $status_fh "PVS_SHORTS_FILE=$pvs_shorts"
    puts $status_fh "SOURCE_DEF=[expr {$source_def eq "" ? "unset" : $source_def}]"
    puts $status_fh "POLYGON_MAP_REPORT=$map_rpt"
    puts $status_fh "SPECIALNET_MAP_CSV=$csv_rpt"
    puts $status_fh "TARGET_VDD_VSS_SHORT_COUNT=$target_count"
    puts $status_fh "TARGET_POLYGON_COUNT=$target_polygon_count"
    puts $status_fh "MATCHED_POLYGON_COUNT=$matched_polygon_count"
    puts $status_fh "BRIDGE_WINDOW_POLYGON_COUNT=$bridge_polygon_count"
    puts $status_fh "VDD_MATCH_COUNT=$vdd_match_count"
    puts $status_fh "VSS_MATCH_COUNT=$vss_match_count"
    puts $status_fh "BRIDGE_WINDOW_UM=[mptdc_pvs_pg_short_format_rect $bridge_window]"
    puts $status_fh "DELETE_CANDIDATE_COUNT=[llength $candidates]"
    puts $status_fh "STREAMOUT_ONLY_SUSPECT=[expr {$matched_polygon_count == 0 ? "YES" : "NO"}]"
    puts $status_fh "ROOT_CAUSE_CLASS=[expr {$matched_polygon_count > 0 ? "EXPORTED_SPECIALNET_GEOMETRY" : "UNMAPPED_STREAMOUT_OR_MERGE"}]"

    set ci 0
    foreach rec $candidates {
        incr ci
        puts $status_fh "CANDIDATE_${ci}_NET=[dict get $rec net]"
        puts $status_fh "CANDIDATE_${ci}_LAYER=[dict get $rec layer]"
        puts $status_fh "CANDIDATE_${ci}_SHAPE=[mptdc_pvs_pg_short_report_value [dict get $rec shape]]"
        puts $status_fh "CANDIDATE_${ci}_BOX=[mptdc_pvs_pg_short_format_rect [dict get $rec rect]]"
        puts $status_fh "CANDIDATE_${ci}_SPAN_UM=[format %.3f [dict get $rec candidate_span_um]]"
    }

    set delete_attempts 0
    set delete_successes 0
    set dirty_abort 0
    if {$mode eq "surgical_proof"} {
        puts $status_fh ""
        puts $status_fh "SURGICAL_PROOF_POLICY=delete_only_short_BLOCKWIRE_special_candidates_inside_bridge_window"
        foreach rec $candidates {
            incr delete_attempts
            if {[mptdc_pvs_pg_short_delete_candidate $rec $status_fh $delete_attempts $margin]} {
                incr delete_successes
            }
            if {[llength [info commands mptdc_ckpt_verify_snapshot]] > 0} {
                set snapshot [mptdc_ckpt_verify_snapshot [format "pvs_pg_short_after_delete_%02d" $delete_attempts]]
                mptdc_pvs_pg_short_write_snapshot $status_fh [format "DELETE_%02d_VERIFY" $delete_attempts] $snapshot
                set drc [dict get $snapshot total_violations]
                set shorts_count [dict get $snapshot shorts]
                set regular_bad [dict get $snapshot regular_bad]
                if {$drc eq "UNKNOWN" || $shorts_count eq "UNKNOWN" || $regular_bad eq "UNKNOWN" ||
                    $drc != 0 || $shorts_count != 0 || $regular_bad != 0} {
                    puts $status_fh "DELETE_${delete_attempts}_ABORT_REASON=geometry_or_regular_connectivity_dirty"
                    set dirty_abort 1
                    break
                }
            }
            flush $status_fh
        }
    }

    puts $status_fh ""
    puts $status_fh "DELETE_ATTEMPTS=$delete_attempts"
    puts $status_fh "DELETE_SUCCESSES=$delete_successes"
    puts $status_fh "DIRTY_ABORT=$dirty_abort"
    if {$target_count == 0} {
        puts $status_fh "PVS_PG_SHORT_STATUS=NO_TARGET_VDD_VSS_SHORTS_FOUND"
    } elseif {$mode in {analyze analysis}} {
        puts $status_fh "PVS_PG_SHORT_STATUS=ANALYSIS_ONLY"
    } elseif {$dirty_abort} {
        puts $status_fh "PVS_PG_SHORT_STATUS=FAIL_GEOMETRY_OR_REGULAR_DIRTY"
    } elseif {$delete_successes > 0} {
        puts $status_fh "PVS_PG_SHORT_STATUS=SURGICAL_PROOF_EDITED_SAFE_COPY_NEEDS_DRYGDS_PVS"
    } else {
        puts $status_fh "PVS_PG_SHORT_STATUS=REVIEW_REQUIRED_NO_DELETES"
    }
    puts $status_fh "FINAL_SIGNOFF_READY=NO"
    puts $status_fh "READY_FOR_TAPEOUT=NO"
    close $status_fh

    puts "MPTDC_PVS_PG_SHORT_POLYGON_MAP=$map_rpt"
    puts "MPTDC_PVS_PG_SHORT_SPECIALNET_CSV=$csv_rpt"
    puts "MPTDC_PVS_PG_SHORT_STATUS_REPORT=$status_rpt"
    return $status_rpt
}

if {[mptdc_pvs_pg_short_env_truthy MPTDC_PVS_PG_SHORT_AUTORUN 0]} {
    mptdc_pvs_pg_short_run
}
