# =============================================================================
# Project  : SPAD_MPTDC
# File     : innovus_mptdc_ro6_vss_via_checkpoint_tools.tcl
# Purpose  : Add exactly two VSS MET1-to-METTP via stacks at the immutable
#            RO_tune6 boundary overlaps in the accepted V13 checkpoint.
#
# Source only after restoreDesign through mptdc_ckpt_source_tcl. The helper
# never restores, routes, deletes geometry, or saves a checkpoint itself.
# =============================================================================

proc mptdc_ro6_vss_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_ro6_vss_env_truthy {name default_value} {
    set value [string tolower [mptdc_ro6_vss_env $name $default_value]]
    return [expr {$value in {1 true yes on y}}]
}

proc mptdc_ro6_vss_report_value {value} {
    set text "$value"
    regsub -all {[\t\r\n]+} $text { } text
    return [string trim $text]
}

proc mptdc_ro6_vss_valid_handles {values} {
    set out {}
    foreach value $values {
        if {[llength $value] > 1} {
            foreach nested [mptdc_ro6_vss_valid_handles $value] {
                if {[lsearch -exact $out $nested] < 0} {
                    lappend out $nested
                }
            }
            continue
        }
        if {$value in {"" 0x0 NULL null nil UNKNOWN}} {
            continue
        }
        if {[lsearch -exact $out $value] < 0} {
            lappend out $value
        }
    }
    return [lsort -dictionary $out]
}

proc mptdc_ro6_vss_close {lhs rhs {eps 0.002}} {
    if {![string is double -strict $lhs] || ![string is double -strict $rhs]} {
        return 0
    }
    return [expr {abs(double($lhs) - double($rhs)) <= $eps}]
}

proc mptdc_ro6_vss_rect {raw {depth 0}} {
    if {$depth > 8 || [catch {set count [llength $raw]}]} {
        return {}
    }
    if {$count == 1} {
        set inner [lindex $raw 0]
        if {$inner eq $raw} { return {} }
        return [mptdc_ro6_vss_rect $inner [expr {$depth + 1}]]
    }
    if {$count != 4} { return {} }
    foreach value $raw {
        if {![string is double -strict $value]} { return {} }
    }
    lassign $raw x1 y1 x2 y2
    return [list \
        [expr {min(double($x1), double($x2))}] \
        [expr {min(double($y1), double($y2))}] \
        [expr {max(double($x1), double($x2))}] \
        [expr {max(double($y1), double($y2))}]]
}

proc mptdc_ro6_vss_points {raw {depth 0}} {
    if {$depth > 8 || [catch {set count [llength $raw]}]} { return {} }
    if {$count == 1} {
        set inner [lindex $raw 0]
        if {$inner eq $raw} { return {} }
        return [mptdc_ro6_vss_points $inner [expr {$depth + 1}]]
    }
    if {$count == 2 && [llength [lindex $raw 0]] == 2 &&
        [llength [lindex $raw 1]] == 2} {
        set points $raw
    } elseif {$count == 4} {
        set points [list [lrange $raw 0 1] [lrange $raw 2 3]]
    } else {
        return {}
    }
    foreach point $points {
        foreach value $point {
            if {![string is double -strict $value]} { return {} }
        }
    }
    return $points
}

proc mptdc_ro6_vss_point {raw {depth 0}} {
    if {$depth > 8 || [catch {set count [llength $raw]}]} { return {} }
    if {$count == 1} {
        set inner [lindex $raw 0]
        if {$inner eq $raw} { return {} }
        return [mptdc_ro6_vss_point $inner [expr {$depth + 1}]]
    }
    if {$count != 2} { return {} }
    foreach value $raw {
        if {![string is double -strict $value]} { return {} }
    }
    return $raw
}

proc mptdc_ro6_vss_rect_match {lhs rhs {eps 0.002}} {
    set lhs [mptdc_ro6_vss_rect $lhs]
    set rhs [mptdc_ro6_vss_rect $rhs]
    if {[llength $lhs] != 4 || [llength $rhs] != 4} { return 0 }
    for {set idx 0} {$idx < 4} {incr idx} {
        if {![mptdc_ro6_vss_close [lindex $lhs $idx] [lindex $rhs $idx] $eps]} {
            return 0
        }
    }
    return 1
}

proc mptdc_ro6_vss_point_match {lhs rhs {eps 0.002}} {
    return [expr {[llength $lhs] == 2 && [llength $rhs] == 2 &&
        [mptdc_ro6_vss_close [lindex $lhs 0] [lindex $rhs 0] $eps] &&
        [mptdc_ro6_vss_close [lindex $lhs 1] [lindex $rhs 1] $eps]}]
}

proc mptdc_ro6_vss_points_match {lhs rhs {eps 0.002}} {
    set lhs [mptdc_ro6_vss_points $lhs]
    set rhs [mptdc_ro6_vss_points $rhs]
    if {[llength $lhs] != 2 || [llength $rhs] != 2} { return 0 }
    return [expr {
        ([mptdc_ro6_vss_point_match [lindex $lhs 0] [lindex $rhs 0] $eps] &&
         [mptdc_ro6_vss_point_match [lindex $lhs 1] [lindex $rhs 1] $eps]) ||
        ([mptdc_ro6_vss_point_match [lindex $lhs 0] [lindex $rhs 1] $eps] &&
         [mptdc_ro6_vss_point_match [lindex $lhs 1] [lindex $rhs 0] $eps])}]
}

proc mptdc_ro6_vss_box_intersection {lhs rhs} {
    set lhs [mptdc_ro6_vss_rect $lhs]
    set rhs [mptdc_ro6_vss_rect $rhs]
    if {[llength $lhs] != 4 || [llength $rhs] != 4} { return {} }
    set llx [expr {max([lindex $lhs 0], [lindex $rhs 0])}]
    set lly [expr {max([lindex $lhs 1], [lindex $rhs 1])}]
    set urx [expr {min([lindex $lhs 2], [lindex $rhs 2])}]
    set ury [expr {min([lindex $lhs 3], [lindex $rhs 3])}]
    if {$urx <= $llx || $ury <= $lly} { return {} }
    return [list $llx $lly $urx $ury]
}

proc mptdc_ro6_vss_point_in_box {point box {eps 0.002}} {
    set point [mptdc_ro6_vss_point $point]
    set box [mptdc_ro6_vss_rect $box]
    if {[llength $point] != 2 || [llength $box] != 4} { return 0 }
    lassign $point x y
    lassign $box x1 y1 x2 y2
    return [expr {$x >= ($x1 - $eps) && $x <= ($x2 + $eps) &&
        $y >= ($y1 - $eps) && $y <= ($y2 + $eps)}]
}

proc mptdc_ro6_vss_boxes_touch {lhs rhs {eps 0.002}} {
    set lhs [mptdc_ro6_vss_rect $lhs]
    set rhs [mptdc_ro6_vss_rect $rhs]
    if {[llength $lhs] != 4 || [llength $rhs] != 4} { return 0 }
    return [expr {[lindex $lhs 0] <= ([lindex $rhs 2] + $eps) &&
        [lindex $lhs 2] >= ([lindex $rhs 0] - $eps) &&
        [lindex $lhs 1] <= ([lindex $rhs 3] + $eps) &&
        [lindex $lhs 3] >= ([lindex $rhs 1] - $eps)}]
}

proc mptdc_ro6_vss_expected_sites {} {
    return [list \
        [dict create id NORTH net VSS \
            core_layer MET1 core_shape corewire core_status routed core_geom pathseg \
            core_width 0.8 core_points {{124.16 723.52} {240.8 723.52}} \
            core_box {124.16 723.12 240.8 723.92} \
            stripe_layer METTP stripe_shape stripe stripe_status routed stripe_geom pathseg \
            stripe_width 2.0 stripe_points {{125.16 721.75} {125.16 869.4}} \
            stripe_box {124.16 721.75 126.16 869.4} \
            overlap_box {124.16 723.12 126.16 723.92}] \
        [dict create id SOUTH net VSS \
            core_layer MET1 core_shape corewire core_status routed core_geom pathseg \
            core_width 0.8 core_points {{204.16 150.08} {240.8 150.08}} \
            core_box {204.16 149.68 240.8 150.48} \
            stripe_layer METTP stripe_shape stripe stripe_status routed stripe_geom pathseg \
            stripe_width 2.0 stripe_points {{205.16 13.16} {205.16 158.32}} \
            stripe_box {204.16 13.16 206.16 158.32} \
            overlap_box {204.16 149.68 206.16 150.48}]]
}

proc mptdc_ro6_vss_record_matches {record site role {eps 0.002}} {
    if {![dict exists $record net] || [dict get $record net] ne [dict get $site net]} {
        return 0
    }
    foreach key {layer shape status geom width points box} {
        set expected_key ${role}_${key}
        if {![dict exists $record $key] || ![dict exists $site $expected_key]} {
            return 0
        }
    }
    if {[string toupper [dict get $record layer]] ne
        [string toupper [dict get $site ${role}_layer]]} { return 0 }
    if {[string tolower [dict get $record shape]] ne
        [string tolower [dict get $site ${role}_shape]]} { return 0 }
    if {[string tolower [dict get $record status]] ne
        [string tolower [dict get $site ${role}_status]]} { return 0 }
    if {[string tolower [dict get $record geom]] ne
        [string tolower [dict get $site ${role}_geom]]} { return 0 }
    if {![mptdc_ro6_vss_close [dict get $record width] \
        [dict get $site ${role}_width] $eps]} { return 0 }
    if {![mptdc_ro6_vss_points_match [dict get $record points] \
        [dict get $site ${role}_points] $eps]} { return 0 }
    return [mptdc_ro6_vss_rect_match [dict get $record box] \
        [dict get $site ${role}_box] $eps]
}

proc mptdc_ro6_vss_resolve_sites {records {eps 0.002}} {
    set resolved {}
    set details {}
    set reasons {}
    set used_handles {}
    foreach site [mptdc_ro6_vss_expected_sites] {
        set id [dict get $site id]
        set core_candidates {}
        set stripe_candidates {}
        foreach record $records {
            if {[mptdc_ro6_vss_record_matches $record $site core $eps]} {
                lappend core_candidates $record
            }
            if {[mptdc_ro6_vss_record_matches $record $site stripe $eps]} {
                lappend stripe_candidates $record
            }
        }
        set detail [dict create id $id core_count [llength $core_candidates] \
            stripe_count [llength $stripe_candidates] overlap_status FAIL]
        if {[llength $core_candidates] != 1 || [llength $stripe_candidates] != 1} {
            lappend reasons "$id:core=[llength $core_candidates],stripe=[llength $stripe_candidates]"
            lappend details $detail
            continue
        }
        set core [lindex $core_candidates 0]
        set stripe [lindex $stripe_candidates 0]
        set core_handle [dict get $core handle]
        set stripe_handle [dict get $stripe handle]
        if {$core_handle eq $stripe_handle ||
            [lsearch -exact $used_handles $core_handle] >= 0 ||
            [lsearch -exact $used_handles $stripe_handle] >= 0} {
            lappend reasons "$id:handle_reuse"
            lappend details $detail
            continue
        }
        set overlap [mptdc_ro6_vss_box_intersection [dict get $core box] [dict get $stripe box]]
        if {![mptdc_ro6_vss_rect_match $overlap [dict get $site overlap_box] $eps]} {
            lappend reasons "$id:overlap=$overlap"
            lappend details $detail
            continue
        }
        dict set detail overlap_status PASS
        dict set detail overlap $overlap
        lappend details $detail
        lappend used_handles $core_handle $stripe_handle
        dict set site core_record $core
        dict set site stripe_record $stripe
        dict set site resolved_overlap $overlap
        lappend resolved $site
    }
    set status [expr {[llength $reasons] == 0 && [llength $resolved] == 2 ? {PASS} : {FAIL}}]
    return [dict create status $status resolved $resolved details $details reasons $reasons]
}

proc mptdc_ro6_vss_dbget {expression} {
    if {[catch {set value [uplevel #0 "dbGet $expression"]} err]} {
        return [dict create status FAIL value {} error $err]
    }
    return [dict create status PASS value $value error NONE]
}

proc mptdc_ro6_vss_net_handles {net} {
    set query [mptdc_ro6_vss_dbget "top.nets.name $net -p"]
    if {[dict get $query status] ne "PASS"} {
        return [dict create status FAIL handles {} error [dict get $query error]]
    }
    set handles [mptdc_ro6_vss_valid_handles [dict get $query value]]
    return [dict create status [expr {[llength $handles] == 1 ? {PASS} : {FAIL}}] \
        handles $handles error [expr {[llength $handles] == 1 ? {NONE} : {net_handle_count}}]]
}

proc mptdc_ro6_vss_property_handles {net property} {
    set net_query [mptdc_ro6_vss_net_handles $net]
    if {[dict get $net_query status] ne "PASS"} {
        return [dict create status FAIL handles {} error [dict get $net_query error]]
    }
    set net_handle [lindex [dict get $net_query handles] 0]
    set query [mptdc_ro6_vss_dbget "$net_handle.$property"]
    if {[dict get $query status] ne "PASS"} {
        return [dict create status FAIL handles {} error [dict get $query error]]
    }
    return [dict create status PASS \
        handles [mptdc_ro6_vss_valid_handles [dict get $query value]] error NONE]
}

proc mptdc_ro6_vss_swire_records {net} {
    set query [mptdc_ro6_vss_property_handles $net sWires]
    if {[dict get $query status] ne "PASS"} {
        return [dict create status FAIL records {} error [dict get $query error]]
    }
    set records {}
    set failures {}
    foreach handle [dict get $query handles] {
        set values [dict create]
        foreach spec {
            {layer layer.name} {shape shape} {status status} {geom geomType}
            {width width} {box box} {points pts}
        } {
            lassign $spec key attribute
            set attr [mptdc_ro6_vss_dbget "$handle.$attribute"]
            if {[dict get $attr status] ne "PASS"} {
                lappend failures "$handle.$attribute"
                continue
            }
            dict set values $key [dict get $attr value]
        }
        if {[dict size $values] != 7} { continue }
        set box [mptdc_ro6_vss_rect [dict get $values box]]
        set points [mptdc_ro6_vss_points [dict get $values points]]
        if {[llength $box] != 4 || [llength $points] != 2} {
            lappend failures "$handle.geometry"
            continue
        }
        lappend records [dict create handle $handle net $net \
            layer [dict get $values layer] shape [dict get $values shape] \
            status [dict get $values status] geom [dict get $values geom] \
            width [dict get $values width] box $box points $points]
    }
    return [dict create status [expr {[llength $failures] == 0 ? {PASS} : {FAIL}}] \
        records $records error [join $failures ,]]
}

proc mptdc_ro6_vss_via_records {net} {
    set handles {}
    set failures {}
    foreach property {vias sVias} {
        set query [mptdc_ro6_vss_property_handles $net $property]
        if {[dict get $query status] ne "PASS"} {
            lappend failures "$property:[dict get $query error]"
            continue
        }
        foreach handle [dict get $query handles] {
            if {[lsearch -exact $handles $handle] < 0} { lappend handles $handle }
        }
    }
    set records {}
    foreach handle [lsort -dictionary $handles] {
        set point {}
        set box {}
        set pt_query [mptdc_ro6_vss_dbget "$handle.pt"]
        if {[dict get $pt_query status] eq "PASS"} {
            set point [mptdc_ro6_vss_point [dict get $pt_query value]]
        }
        set box_query [mptdc_ro6_vss_dbget "$handle.box"]
        if {[dict get $box_query status] eq "PASS"} {
            set box [mptdc_ro6_vss_rect [dict get $box_query value]]
        }
        if {[llength $point] != 2 && [llength $box] != 4} {
            lappend failures "$handle:unlocatable"
        }
        lappend records [dict create handle $handle point $point box $box]
    }
    return [dict create status [expr {[llength $failures] == 0 ? {PASS} : {FAIL}}] \
        records $records error [join $failures ,]]
}

proc mptdc_ro6_vss_swire_key {record} {
    set width [dict get $record width]
    if {[string is double -strict $width]} { set width [format %.3f $width] }
    set box {}
    foreach value [dict get $record box] { lappend box [format %.3f $value] }
    set points {}
    foreach point [dict get $record points] {
        lappend points [list [format %.3f [lindex $point 0]] [format %.3f [lindex $point 1]]]
    }
    return [join [list [dict get $record handle] [string toupper [dict get $record layer]] \
        [string tolower [dict get $record shape]] [string tolower [dict get $record status]] \
        [string tolower [dict get $record geom]] $width $box $points] |]
}

proc mptdc_ro6_vss_swire_fingerprint {records} {
    set keys {}
    foreach record $records { lappend keys [mptdc_ro6_vss_swire_key $record] }
    return [lsort -dictionary $keys]
}

proc mptdc_ro6_vss_via_handles {records} {
    set out {}
    foreach record $records { lappend out [dict get $record handle] }
    return [lsort -dictionary -unique $out]
}

proc mptdc_ro6_vss_list_difference {lhs rhs} {
    set out {}
    foreach item $lhs {
        if {[lsearch -exact $rhs $item] < 0} { lappend out $item }
    }
    return [lsort -dictionary -unique $out]
}

proc mptdc_ro6_vss_vias_in_box {records box} {
    set out {}
    foreach record $records {
        set local 0
        if {[dict exists $record point] &&
            [mptdc_ro6_vss_point_in_box [dict get $record point] $box]} {
            set local 1
        } elseif {[dict exists $record box] &&
            [mptdc_ro6_vss_boxes_touch [dict get $record box] $box]} {
            set local 1
        }
        if {$local} { lappend out $record }
    }
    return $out
}

proc mptdc_ro6_vss_report_dir {} {
    if {[llength [info commands mptdc_signoff_report_dir]] > 0} {
        return [mptdc_signoff_report_dir]
    }
    return [file join [mptdc_ro6_vss_env MPTDC_SIGNOFF_RESULT_DIR .] reports]
}

proc mptdc_ro6_vss_write_site_resolution {fh resolution} {
    set idx 0
    foreach detail [dict get $resolution details] {
        incr idx
        set prefix SITE_$idx
        puts $fh "${prefix}_ID=[dict get $detail id]"
        puts $fh "${prefix}_CORE_CANDIDATE_COUNT=[dict get $detail core_count]"
        puts $fh "${prefix}_STRIPE_CANDIDATE_COUNT=[dict get $detail stripe_count]"
        puts $fh "${prefix}_OVERLAP_STATUS=[dict get $detail overlap_status]"
        if {[dict exists $detail overlap]} {
            puts $fh "${prefix}_OVERLAP_BOX=[dict get $detail overlap]"
        }
    }
}

proc mptdc_ro6_vss_via_commands {area} {
    if {[llength [info commands mptdc_signoff_ro_pg_via_commands]] > 0} {
        return [lrange [mptdc_signoff_ro_pg_via_commands VSS MET1 METTP $area] 0 3]
    }
    return [list \
        [list editPowerVia -add_vias 1 -nets {VSS} -bottom_layer MET1 -top_layer METTP -area $area] \
        [list editPowerVia -add_vias 1 -net VSS -bottom_layer MET1 -top_layer METTP -area $area] \
        [list editPowerVia -add_vias 1 -nets {VSS} -bottomLayer MET1 -topLayer METTP -area $area] \
        [list editPowerVia -add_vias 1 -net VSS -bottomLayer MET1 -topLayer METTP -area $area]]
}

proc mptdc_ro6_vss_run_impl {fh} {
    set expected_auth EXACT_V13_TWO_RO6_VSS_MET1_METTP_VIA_STACKS_V1
    set actual_auth [mptdc_ro6_vss_env MPTDC_RO6_VSS_VIA_AUTHORIZATION NONE]
    puts $fh "RO6_VSS_VIA_REPAIR_MODE=EXACT_TWO_SITE_VIA_STACK"
    puts $fh "AUTHORIZATION=$actual_auth"
    puts $fh "REQUIRED_AUTHORIZATION=$expected_auth"
    puts $fh "AUTHORIZATION_STATUS=[expr {$actual_auth eq $expected_auth ? {PASS} : {FAIL}}]"
    puts $fh "TARGET_NET=VSS"
    puts $fh "BOTTOM_LAYER=MET1"
    puts $fh "TOP_LAYER=METTP"
    puts $fh "TARGET_SITE_COUNT=2"
    puts $fh "GEOMETRY_EDIT_POLICY=VIA_ONLY_NO_SWIRE_EDIT"
    puts $fh "ROUTE_OPTIMIZER_POLICY=NO_ECOROUTE_NO_ROUTEDESIGN_NO_SROUTE"
    puts $fh "SIGNOFF_ELIGIBLE=NO"
    if {$actual_auth ne $expected_auth} {
        puts $fh "PREFLIGHT_STATUS=FAIL"
        puts $fh "RO6_VSS_VIA_REPAIR_STATUS=FAIL_AUTHORIZATION"
        puts $fh "NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE"
        return FAIL_AUTHORIZATION
    }
    if {[llength [info commands mptdc_signoff_try_pg_command]] == 0} {
        puts $fh "PREFLIGHT_STATUS=FAIL"
        puts $fh "RO6_VSS_VIA_REPAIR_STATUS=FAIL_MISSING_COMMAND_HELPER"
        puts $fh "NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE"
        return FAIL_MISSING_COMMAND_HELPER
    }

    set vdd_swires_pre [mptdc_ro6_vss_swire_records VDD]
    set vss_swires_pre [mptdc_ro6_vss_swire_records VSS]
    set vdd_vias_pre [mptdc_ro6_vss_via_records VDD]
    set vss_vias_pre [mptdc_ro6_vss_via_records VSS]
    set query_status PASS
    foreach data [list $vdd_swires_pre $vss_swires_pre $vdd_vias_pre $vss_vias_pre] {
        if {[dict get $data status] ne "PASS"} { set query_status FAIL }
    }
    puts $fh "PRE_QUERY_STATUS=$query_status"
    puts $fh "VDD_SWIRE_COUNT_PRE=[llength [dict get $vdd_swires_pre records]]"
    puts $fh "VSS_SWIRE_COUNT_PRE=[llength [dict get $vss_swires_pre records]]"
    puts $fh "VDD_VIA_COUNT_PRE=[llength [dict get $vdd_vias_pre records]]"
    puts $fh "VSS_VIA_COUNT_PRE=[llength [dict get $vss_vias_pre records]]"

    set resolution [mptdc_ro6_vss_resolve_sites [dict get $vss_swires_pre records]]
    mptdc_ro6_vss_write_site_resolution $fh $resolution
    puts $fh "RESOLVED_SITE_COUNT=[llength [dict get $resolution resolved]]"
    puts $fh "GEOMETRY_CONTRACT_STATUS=[dict get $resolution status]"
    puts $fh "GEOMETRY_CONTRACT_REASONS=[mptdc_ro6_vss_report_value [dict get $resolution reasons]]"
    set preexisting_local 0
    set idx 0
    foreach site [dict get $resolution resolved] {
        incr idx
        set local [mptdc_ro6_vss_vias_in_box [dict get $vss_vias_pre records] [dict get $site overlap_box]]
        puts $fh "SITE_${idx}_PREEXISTING_LOCAL_VIA_COUNT=[llength $local]"
        incr preexisting_local [llength $local]
    }
    puts $fh "PREEXISTING_TARGET_LOCAL_VIA_COUNT=$preexisting_local"
    set preflight_status [expr {$query_status eq "PASS" &&
        [dict get $resolution status] eq "PASS" && $preexisting_local == 0 ? {PASS} : {FAIL}}]
    puts $fh "PREFLIGHT_STATUS=$preflight_status"
    if {$preflight_status ne "PASS"} {
        puts $fh "VIA_ATTEMPTS=0"
        puts $fh "VIA_SUCCESSES=0"
        puts $fh "RO6_VSS_VIA_REPAIR_STATUS=FAIL_PREFLIGHT"
        puts $fh "NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE"
        return FAIL_PREFLIGHT
    }

    set attempts 0
    set successes 0
    set command_failures {}
    foreach site [dict get $resolution resolved] {
        incr attempts
        set label "RO6_VSS_VIA_SITE_$attempts"
        set area [dict get $site overlap_box]
        puts $fh "${label}_ID=[dict get $site id]"
        puts $fh "${label}_AREA=$area"
        set ok [mptdc_signoff_try_pg_command $fh $label [mptdc_ro6_vss_via_commands $area]]
        if {$ok} {
            incr successes
        } else {
            lappend command_failures [dict get $site id]
            break
        }
    }
    puts $fh "VIA_ATTEMPTS=$attempts"
    puts $fh "VIA_SUCCESSES=$successes"
    puts $fh "VIA_COMMAND_FAILURES=[mptdc_ro6_vss_report_value $command_failures]"

    set vdd_swires_post [mptdc_ro6_vss_swire_records VDD]
    set vss_swires_post [mptdc_ro6_vss_swire_records VSS]
    set vdd_vias_post [mptdc_ro6_vss_via_records VDD]
    set vss_vias_post [mptdc_ro6_vss_via_records VSS]
    set post_query_status PASS
    foreach data [list $vdd_swires_post $vss_swires_post $vdd_vias_post $vss_vias_post] {
        if {[dict get $data status] ne "PASS"} { set post_query_status FAIL }
    }
    puts $fh "POST_QUERY_STATUS=$post_query_status"
    puts $fh "VDD_SWIRE_COUNT_POST=[llength [dict get $vdd_swires_post records]]"
    puts $fh "VSS_SWIRE_COUNT_POST=[llength [dict get $vss_swires_post records]]"
    puts $fh "VDD_VIA_COUNT_POST=[llength [dict get $vdd_vias_post records]]"
    puts $fh "VSS_VIA_COUNT_POST=[llength [dict get $vss_vias_post records]]"

    set vdd_swire_status [expr {[mptdc_ro6_vss_swire_fingerprint [dict get $vdd_swires_pre records]] eq
        [mptdc_ro6_vss_swire_fingerprint [dict get $vdd_swires_post records]] ? {UNCHANGED} : {CHANGED}}]
    set vss_swire_status [expr {[mptdc_ro6_vss_swire_fingerprint [dict get $vss_swires_pre records]] eq
        [mptdc_ro6_vss_swire_fingerprint [dict get $vss_swires_post records]] ? {UNCHANGED} : {CHANGED}}]
    set vdd_via_pre_handles [mptdc_ro6_vss_via_handles [dict get $vdd_vias_pre records]]
    set vdd_via_post_handles [mptdc_ro6_vss_via_handles [dict get $vdd_vias_post records]]
    set vss_via_pre_handles [mptdc_ro6_vss_via_handles [dict get $vss_vias_pre records]]
    set vss_via_post_handles [mptdc_ro6_vss_via_handles [dict get $vss_vias_post records]]
    set vdd_via_status [expr {$vdd_via_pre_handles eq $vdd_via_post_handles ? {UNCHANGED} : {CHANGED}}]
    set vss_added [mptdc_ro6_vss_list_difference $vss_via_post_handles $vss_via_pre_handles]
    set vss_removed [mptdc_ro6_vss_list_difference $vss_via_pre_handles $vss_via_post_handles]
    set new_records {}
    foreach record [dict get $vss_vias_post records] {
        if {[lsearch -exact $vss_added [dict get $record handle]] >= 0} { lappend new_records $record }
    }
    puts $fh "VDD_SWIRE_FINGERPRINT_STATUS=$vdd_swire_status"
    puts $fh "VSS_SWIRE_FINGERPRINT_STATUS=$vss_swire_status"
    puts $fh "VDD_VIA_FINGERPRINT_STATUS=$vdd_via_status"
    puts $fh "VSS_VIA_ADDED_COUNT=[llength $vss_added]"
    puts $fh "VSS_VIA_REMOVED_COUNT=[llength $vss_removed]"
    puts $fh "VSS_VIA_ADDED_HANDLES=[mptdc_ro6_vss_report_value $vss_added]"

    set local_status PASS
    set idx 0
    foreach site [dict get $resolution resolved] {
        incr idx
        set local [mptdc_ro6_vss_vias_in_box $new_records [dict get $site overlap_box]]
        set effect [expr {[llength $local] > 0 ? {PASS} : {FAIL}}]
        puts $fh "SITE_${idx}_NEW_LOCAL_VIA_COUNT=[llength $local]"
        puts $fh "SITE_${idx}_VIA_EFFECT_STATUS=$effect"
        if {$effect ne "PASS"} { set local_status FAIL }
    }

    set final_ok [expr {$attempts == 2 && $successes == 2 &&
        $post_query_status eq "PASS" && $vdd_swire_status eq "UNCHANGED" &&
        $vss_swire_status eq "UNCHANGED" && $vdd_via_status eq "UNCHANGED" &&
        [llength $vss_added] >= 2 && [llength $vss_removed] == 0 &&
        $local_status eq "PASS"}]
    if {$final_ok} {
        puts $fh "RO6_VSS_VIA_REPAIR_STATUS=PASS_PVS_CANDIDATE"
        puts $fh "NEXT_STAGE=PVS_RO6_VSS_VIA_CANDIDATE"
        return PASS_PVS_CANDIDATE
    }
    puts $fh "RO6_VSS_VIA_REPAIR_STATUS=FAIL_POSTCHECK"
    puts $fh "NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE"
    return FAIL_POSTCHECK
}

proc mptdc_ro6_vss_run {} {
    set report_dir [mptdc_ro6_vss_report_dir]
    file mkdir $report_dir
    set report [file join $report_dir ro6_vss_via_repair_status.rpt]
    set fh [open $report w]
    puts $fh "# MPTDC RO6 VSS Via Repair"
    set code [catch {mptdc_ro6_vss_run_impl $fh} status opts]
    if {$code} {
        puts $fh "RO6_VSS_VIA_REPAIR_STATUS=FAIL_RUNTIME"
        puts $fh "RUNTIME_ERROR=[mptdc_ro6_vss_report_value $status]"
        puts $fh "SIGNOFF_ELIGIBLE=NO"
        puts $fh "NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE"
        close $fh
        return -options $opts $status
    }
    close $fh
    puts "MPTDC_RO6_VSS_VIA_REPAIR_REPORT=$report"
    if {$status ne "PASS_PVS_CANDIDATE"} {
        error "RO6 VSS via repair rejected: $status; report=$report"
    }
    return $report
}

if {[mptdc_ro6_vss_env_truthy MPTDC_RO6_VSS_VIA_AUTORUN 1]} {
    mptdc_ro6_vss_run
}
