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
        length_um [mptdc_pg_dangling_path_length $points {}] \
        distance_um 0.0 endpoint_match 1 box_match 1]
    dict set ::pg_ro_fixture_records $idx $rec
    dict incr ::pg_ro_fixture_handle_refs $handle
    if {[lsearch -exact [dict get $::pg_ro_fixture_handles $net] $handle] < 0} {
        dict lappend ::pg_ro_fixture_handles $net $handle
    }
}

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
rename mptdc_pg_dangling_marker_candidates mptdc_pg_dangling_marker_candidates_real
proc mptdc_pg_dangling_marker_candidates {marker eps near} {
    set rec [dict get $::pg_ro_fixture_records [dict get $marker idx]]
    return [dict create exact [list $rec] nearby {} net_handle fixture_net]
}

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

rename mptdc_pg_ro_handle_set mptdc_pg_ro_handle_set_real
proc mptdc_pg_ro_handle_set {net} {
    return [dict get $::pg_ro_fixture_handles $net]
}
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

set ::env(MPTDC_PG_LONG_PRUNE_AUTHORIZATION) \
    EXACT_V13_PG15_13_HANDLE_LONG_PRUNE
set prune_report [file join $fixture_dir reports authorized.rpt]
set prune_fh [open $prune_report w]
set prune [mptdc_pg_ro_long_prune $prune_fh $preflight \
    [file join $fixture_dir reports]]
close $prune_fh
assert_equal prune_status [dict get $prune status] PASS
assert_equal prune_attempts [dict get $prune attempts] 13
assert_equal prune_successes [dict get $prune successes] 13
assert_equal prune_final_marker_count [llength $::pg_ro_fixture_markers] 0

file delete -force $fixture_dir
puts "MPTDC_PG_RO_RING_CHECKPOINT_TOOLS_TEST=PASS"
