set script_dir [file dirname [file normalize [info script]]]
set helper [file join [file dirname $script_dir] \
    innovus_mptdc_pg_ro_ring_checkpoint_tools.tcl]
set fixture_dir [file join $script_dir .pg_ro_ring_fixture]
file delete -force $fixture_dir
file mkdir $fixture_dir
set ::env(MPTDC_PG_RO_AUTORUN) 0
set ::env(MPTDC_SIGNOFF_RESULT_DIR) $fixture_dir
source $helper

proc assert_equal {label actual expected} {
    if {$actual ne $expected} {
        error "$label: expected '$expected', got '$actual'"
    }
}

proc assert_true {label value} {
    if {!$value} { error "$label: assertion failed" }
}

assert_equal expected_ro_instance_set \
    [join [mptdc_pg_ro_expected_instance_set] ,] \
    u_core_u_osc_fast_u_ro_tune4,u_core_u_osc_slow_u_ro_tune4

set flat_marker [dict create idx 99 net VDD layer MET3 \
    x 221.750 y 681.160 x2 221.750 y2 681.160]
set flat_record [dict create handle flat_source net VDD layer met3 \
    shape stripe status routed width 2.0 geomType pathSeg \
    box {221.75 680.16 1152.56 682.16} \
    rect {221.75 680.16 1152.56 682.16} \
    pts {221.75 681.16 1152.56 681.16} length_um 930.81]
set flat_classified [mptdc_pg_ro_classify_source_record \
    $flat_marker $flat_record 0.002 6.0]
assert_equal flat_point_encoding \
    [dict get $flat_classified point_encoding] FLAT_FOUR_COORD
assert_equal flat_point_canonicalization \
    [dict get $flat_classified points] {{221.75 681.16} {1152.56 681.16}}
assert_equal flat_point_length [dict get $flat_classified length_um] 930.81
assert_equal flat_endpoint_match [dict get $flat_classified endpoint_match] 1
assert_equal invalid_scalar_points [mptdc_pg_ro_two_points UNKNOWN] {}
assert_equal invalid_scalar_encoding [mptdc_pg_ro_point_encoding UNKNOWN] INVALID
assert_equal wrapped_handle_flattening \
    [mptdc_pg_ro_valid_handles [list [list 0xa 0xb] 0xa 0x0]] {0xa 0xb}

set anchor_target [dict create handle target net VDD layer MET3 \
    points {{0.0 0.0} {100.0 0.0}}]
set anchor_marker [dict create idx 1 net VDD layer MET3 x 0.0 y 0.0]
set trim_result [mptdc_pg_ro_anchor_classify_marker $anchor_marker $anchor_target \
    [list [dict create anchor 1 kind SAME_NET_VIA handle via_1 point {10.0 0.0}]] \
    PASS 0.002]
assert_equal anchor_unique_trim [dict get $trim_result status] TRIM_FEASIBLE
assert_equal anchor_unique_distance [dict get $trim_result nearest_distance_um] 10.0
set conflict_result [mptdc_pg_ro_anchor_classify_marker $anchor_marker $anchor_target \
    [list \
        [dict create anchor 1 kind SAME_NET_VIA handle via_1 point {10.0 0.0}] \
        [dict create anchor 0 kind OPPOSITE_NET_SWIRE handle vss_1 point {5.0 0.0}]] \
    PASS 0.002]
assert_equal anchor_conflict_blocks [dict get $conflict_result status] BLOCKED
assert_equal anchor_conflict_reason [dict get $conflict_result reason] OPPOSITE_NET_CONFLICT
set opposite_via_candidates [mptdc_pg_ro_anchor_candidates $anchor_marker \
    $anchor_target [dict create VDD {} VSS {}] \
    [dict create VDD {} VSS [list [dict create handle vss_via net VSS \
        point {25.0 0.0} name VIA_TEST]]] \
    [dict create VDD [dict create records {}] VSS [dict create records {}]] 0.002]
assert_equal anchor_opposite_via_is_conflict \
    [dict get [lindex $opposite_via_candidates 0] kind] OPPOSITE_NET_VIA
set incomplete_result [mptdc_pg_ro_anchor_classify_marker $anchor_marker $anchor_target \
    [list [dict create anchor 1 kind SAME_NET_VIA handle via_1 point {10.0 0.0}]] \
    FAIL 0.002]
assert_equal anchor_incomplete_query_blocks [dict get $incomplete_result reason] INCOMPLETE_QUERY
set midpoint_marker [dict create idx 2 net VDD layer MET3 x 50.0 y 0.0]
set ambiguous_result [mptdc_pg_ro_anchor_classify_marker $midpoint_marker $anchor_target \
    [list \
        [dict create anchor 1 kind SAME_NET_SWIRE handle left point {40.0 0.0}] \
        [dict create anchor 1 kind SAME_NET_SWIRE handle right point {60.0 0.0}]] \
    PASS 0.002]
assert_equal anchor_ambiguity_blocks [dict get $ambiguous_result reason] AMBIGUOUS_NEAREST_ANCHOR

set source_rec [dict create handle source_1 net VDD layer MET3 \
    points {{0.0 0.0} {100.0 0.0}} orientation HORIZONTAL]
set marker [dict create idx 1 net VDD layer MET3 x 0.0 y 0.0]
set entry [dict create marker $marker rec $source_rec]
set ring_inside [dict create handle ring_1 net VDD layer METTP \
    points {{5.0 -2.0} {5.0 2.0}} orientation VERTICAL]
set via_only [mptdc_pg_ro_mapping_candidate $entry $ring_inside 0.002 20.0]
assert_equal mapping_via_only_action [dict get $via_only action] VIA_ONLY
assert_equal mapping_via_only_point [dict get $via_only intersection] {5.000 0.000}

set ring_extend [dict create handle ring_2 net VDD layer METTP \
    points {{-5.0 -2.0} {-5.0 2.0}} orientation VERTICAL]
set extension [mptdc_pg_ro_mapping_candidate $entry $ring_extend 0.002 20.0]
assert_equal mapping_extension_action [dict get $extension action] EXTEND_ENDPOINT
assert_equal mapping_extension_point [dict get $extension intersection] {-5.000 0.000}

set wrong_net [dict replace $ring_inside net VSS]
assert_equal mapping_rejects_wrong_net \
    [llength [mptdc_pg_ro_mapping_candidate $entry $wrong_net 0.002 20.0]] 0

set ::pg_ro_fixture_markers {}
set ::pg_ro_fixture_records [dict create]
set ::pg_ro_fixture_handle_refs [dict create]
set ::pg_ro_fixture_handles [dict create VDD {} VSS {}]
set fixture_rows [list \
    [list 1 VDD MET3 221.750 681.160 vdd_m3_right_681 {{221.75 681.16} {1152.56 681.16}}] \
    [list 2 VDD MET3 221.750 201.160 vdd_m3_right_201 {{221.75 201.16} {1152.56 201.16}}] \
    [list 3 VDD MET3 48.000 681.160 vdd_m3_left_681 {{16.16 681.16} {48.0 681.16}}] \
    [list 4 VDD MET3 48.000 201.160 vdd_m3_left_201 {{16.16 201.16} {48.0 201.16}}] \
    [list 5 VDD METTP 121.160 233.620 shared_vdd_mettp {{121.16 233.62} {121.16 648.32}}] \
    [list 6 VDD METTP 121.160 648.320 shared_vdd_mettp {{121.16 233.62} {121.16 648.32}}] \
    [list 7 VSS MET3 221.750 685.160 vss_m3_right_685 {{221.75 685.16} {1155.56 685.16}}] \
    [list 8 VSS MET3 221.750 205.160 vss_m3_right_205 {{221.75 205.16} {1155.56 205.16}}] \
    [list 9 VSS MET3 48.000 685.160 vss_m3_left_685 {{13.16 685.16} {48.0 685.16}}] \
    [list 10 VSS MET3 48.000 205.160 vss_m3_left_205 {{13.16 205.16} {48.0 205.16}}] \
    [list 11 VSS METTP 125.160 233.620 shared_vss_mettp {{125.16 233.62} {125.16 648.32}}] \
    [list 12 VSS METTP 125.160 648.320 shared_vss_mettp {{125.16 233.62} {125.16 648.32}}] \
    [list 13 VSS METTP 125.160 721.750 vss_mettp_125_top {{125.16 721.75} {125.16 869.4}}] \
    [list 14 VSS METTP 205.160 158.320 vss_mettp_205_bottom {{205.16 13.16} {205.16 158.32}}] \
    [list 15 VSS METTP 125.160 158.320 vss_mettp_125_bottom {{125.16 13.16} {125.16 158.32}}]]
foreach row $fixture_rows {
    lassign $row idx net layer x y handle points
    set marker [dict create idx $idx net $net layer $layer x $x y $y \
        x2 $x y2 $y line "fixture marker $idx"]
    lappend ::pg_ro_fixture_markers $marker
    set orientation [expr {$layer eq "MET3" ? "HORIZONTAL" : "VERTICAL"}]
    set rec [dict create handle $handle net $net layer $layer shape stripe \
        status routed width 2.0 geomType pathSeg box {} rect {} pts $points \
        points $points orientation $orientation \
        point_encoding NESTED_TWO_POINT \
        length_um [mptdc_pg_dangling_path_length $points {}] \
        distance_um 0.0 endpoint_match 1 box_match 1]
    dict set ::pg_ro_fixture_records $idx $rec
    dict incr ::pg_ro_fixture_handle_refs $handle
    if {[lsearch -exact [dict get $::pg_ro_fixture_handles $net] $handle] < 0} {
        dict lappend ::pg_ro_fixture_handles $net $handle
    }
}
set ::pg_ro_north_residual_marker [dict create idx 16 net VSS layer MET1 \
    x 124.160 y 723.520 x2 124.160 y2 723.520 \
    line "fixture exposed north MET1 marker"]
set ::pg_ro_south_residual_marker [dict create idx 17 net VSS layer MET1 \
    x 204.160 y 150.080 x2 204.160 y2 150.080 \
    line "fixture exposed south MET1 marker"]
set ::pg_ro_north_residual_handle vss_met1_north_exposed_corewire
set ::pg_ro_south_residual_handle vss_met1_south_exposed_corewire
set north_wrapped_box [list [list 124.16 723.12 240.8 723.92]]
set south_wrapped_box [list [list [list 204.16 149.68 240.8 150.48]]]
dict set ::pg_ro_fixture_records 16 [dict create \
    handle $::pg_ro_north_residual_handle net VSS layer MET1 shape corewire \
    status routed width 0.8 geomType pathSeg \
    box $north_wrapped_box \
    rect [mptdc_pg_dangling_rect $north_wrapped_box] \
    pts {{124.16 723.52} {240.8 723.52}} \
    points {{124.16 723.52} {240.8 723.52}} orientation HORIZONTAL \
    point_encoding NESTED_TWO_POINT length_um 116.64 \
    distance_um 0.0 endpoint_match 1 box_match 1]
dict set ::pg_ro_fixture_records 17 [dict create \
    handle $::pg_ro_south_residual_handle net VSS layer MET1 shape corewire \
    status routed width 0.8 geomType pathSeg \
    box $south_wrapped_box \
    rect [mptdc_pg_dangling_rect $south_wrapped_box] \
    pts {{204.16 150.08} {240.8 150.08}} \
    points {{204.16 150.08} {240.8 150.08}} orientation HORIZONTAL \
    point_encoding NESTED_TWO_POINT length_um 36.64 \
    distance_um 0.0 endpoint_match 1 box_match 1]
dict lappend ::pg_ro_fixture_handles VSS $::pg_ro_north_residual_handle
dict lappend ::pg_ro_fixture_handles VSS $::pg_ro_south_residual_handle

rename mptdc_pg_dangling_capture_verify_special mptdc_pg_dangling_capture_verify_special_real
proc mptdc_pg_dangling_capture_verify_special {path} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "fixture marker count [llength $::pg_ro_fixture_markers]"
    close $fh
    return $path
}
rename mptdc_pg_dangling_parse_report mptdc_pg_dangling_parse_report_real
proc mptdc_pg_dangling_parse_report {path} {
    return $::pg_ro_fixture_markers
}
rename mptdc_pg_ro_marker_candidates mptdc_pg_ro_marker_candidates_real
proc mptdc_pg_ro_marker_candidates {marker eps near {records {}} \
    {net_handle_count 1}} {
    set rec [dict get $::pg_ro_fixture_records [dict get $marker idx]]
    return [dict create exact [list $rec] nearby {} source_count \
        [llength [dict get $::pg_ro_fixture_handles [dict get $marker net]]] \
        net_handle_count $net_handle_count]
}
rename mptdc_pg_ro_handle_set mptdc_pg_ro_handle_set_real
proc mptdc_pg_ro_handle_set {net} {
    return [dict get $::pg_ro_fixture_handles $net]
}
rename mptdc_pg_ro_net_handle_set mptdc_pg_ro_net_handle_set_real
proc mptdc_pg_ro_net_handle_set {net} {
    return [list "fixture_net_$net"]
}

set residual_contracts [mptdc_pg_ro_expected_residual_contracts]
assert_equal residual_contract_count [llength $residual_contracts] 2
assert_equal residual_fingerprint \
    [mptdc_pg_ro_fingerprint_value \
        [mptdc_pg_ro_expected_residual_fingerprint]] \
    VSS|MET1|124.160|723.520,VSS|MET1|204.160|150.080
assert_equal north_source_transition \
    [dict get [mptdc_pg_ro_source_residual_contract \
        [dict get $::pg_ro_fixture_records 13] 0.002] id] NORTH
assert_equal south_source_transition \
    [dict get [mptdc_pg_ro_source_residual_contract \
        [dict get $::pg_ro_fixture_records 14] 0.002] id] SOUTH
set north_candidates [mptdc_pg_ro_residual_contract_candidates \
    $::pg_ro_north_residual_marker [lindex $residual_contracts 0] 0.002 6.0]
assert_equal north_residual_exact_candidate \
    [llength [dict get $north_candidates candidates]] 1
assert_equal north_residual_predicates \
    [dict get [lindex [dict get $north_candidates diagnostics] 0] status] PASS
set saved_south_residual [dict get $::pg_ro_fixture_records 17]
dict set ::pg_ro_fixture_records 17 rect {204.15 149.68 240.8 150.48}
set wrong_south_candidates [mptdc_pg_ro_residual_contract_candidates \
    $::pg_ro_south_residual_marker [lindex $residual_contracts 1] 0.002 6.0]
assert_equal south_residual_rejects_wrong_box \
    [llength [dict get $wrong_south_candidates candidates]] 0
assert_true south_residual_reports_rect_failure \
    [expr {[lsearch -exact \
        [dict get [lindex [dict get $wrong_south_candidates diagnostics] 0] failures] \
        RECT] >= 0}]
dict set ::pg_ro_fixture_records 17 $saved_south_residual

set preflight [mptdc_pg_ro_preflight]
assert_equal preflight_status [dict get $preflight status] PASS
assert_equal preflight_marker_count [dict get $preflight marker_count] 15
assert_equal preflight_unique_handles [dict get $preflight unique_handle_count] 13
assert_equal preflight_shared_handles [dict get $preflight shared_handle_count] 2
assert_equal shared_vdd_net \
    [dict get [dict get $preflight records] shared_vdd_mettp net] VDD
assert_equal shared_vdd_layer \
    [dict get [dict get $preflight records] shared_vdd_mettp layer] METTP
assert_equal shared_vss_net \
    [dict get [dict get $preflight records] shared_vss_mettp net] VSS
assert_equal shared_vss_layer \
    [dict get [dict get $preflight records] shared_vss_mettp layer] METTP

set saved_markers $::pg_ro_fixture_markers
set wrong_marker [lindex $::pg_ro_fixture_markers 0]
dict set wrong_marker x 221.740
lset ::pg_ro_fixture_markers 0 $wrong_marker
set wrong_fingerprint [mptdc_pg_ro_preflight]
assert_equal preflight_rejects_wrong_fingerprint \
    [dict get $wrong_fingerprint status] FAIL
assert_true preflight_fingerprint_reason \
    [expr {[lsearch -exact [dict get $wrong_fingerprint reasons] \
        marker_fingerprint_mismatch] >= 0}]
set ::pg_ro_fixture_markers $saved_markers

set saved_record [dict get $::pg_ro_fixture_records 1]
dict set ::pg_ro_fixture_records 1 width 1.8
set wrong_width [mptdc_pg_ro_preflight]
assert_equal preflight_rejects_wrong_width [dict get $wrong_width status] FAIL
dict set ::pg_ro_fixture_records 1 $saved_record

proc dbDeleteObj {handle} {
    set rec {}
    dict for {idx candidate} $::pg_ro_fixture_records {
        if {[dict get $candidate handle] eq $handle} {
            set rec $candidate
            break
        }
    }
    if {[llength $rec] == 0} { error "unknown fixture handle $handle" }
    set net [dict get $rec net]
    set kept {}
    foreach candidate [dict get $::pg_ro_fixture_handles $net] {
        if {$candidate ne $handle} { lappend kept $candidate }
    }
    dict set ::pg_ro_fixture_handles $net $kept
    set kept_markers {}
    foreach marker $::pg_ro_fixture_markers {
        set idx [dict get $marker idx]
        if {[dict get [dict get $::pg_ro_fixture_records $idx] handle] ne $handle} {
            lappend kept_markers $marker
        }
    }
    set ::pg_ro_fixture_markers $kept_markers
    if {$handle eq "vss_mettp_125_top"} {
        lappend ::pg_ro_fixture_markers $::pg_ro_north_residual_marker
    } elseif {$handle eq "vss_mettp_205_bottom"} {
        lappend ::pg_ro_fixture_markers $::pg_ro_south_residual_marker
    }
}
rename mptdc_pg_ro_snapshot mptdc_pg_ro_snapshot_real
proc mptdc_pg_ro_snapshot {fh tag} {
    return [dict create total_violations 0 shorts 0 regular_bad 0 \
        special_bad [expr {[llength $::pg_ro_fixture_markers] == 0 ? 0 : 1}] \
        route_gate_pass [expr {[llength $::pg_ro_fixture_markers] == 0 ? 1 : 0}]]
}

set auth_report [file join $fixture_dir reports missing_auth.rpt]
set auth_fh [open $auth_report w]
set missing_auth [mptdc_pg_ro_long_prune $auth_fh $preflight \
    [file join $fixture_dir reports]]
close $auth_fh
assert_equal prune_requires_authorization [dict get $missing_auth status] FAIL
assert_equal prune_missing_auth_attempts [dict get $missing_auth attempts] 0

assert_equal retired_prune_did_not_mutate_fixture \
    [llength $::pg_ro_fixture_markers] 15

file delete -force $fixture_dir
puts "MPTDC_PG_RO_RING_CHECKPOINT_TOOLS_TEST=PASS"
