set script_dir [file dirname [file normalize [info script]]]
set signoff_tcl [file normalize [file join $script_dir .. innovus_mptdc_digital_signoff.tcl]]
set test_root [file normalize [file join $script_dir .tmp_route_pg_pvs_candidate]]

file delete -force $test_root
file mkdir [file join $test_root reports]
set ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY) 1
set ::env(MPTDC_SIGNOFF_RESULT_DIR) $test_root
set ::env(MPTDC_ALLOW_EXACT_PG_WIRE_END_PVS_CANDIDATE) 1
set ::env(MPTDC_PG_WIRE_END_PROFILE) LEGACY_12
source $signoff_tcl

proc require_dict_value {data key expected} {
    set actual [dict get $data $key]
    if {$actual ne $expected} {
        error "$key expected=$expected actual=$actual"
    }
}
proc write_candidate_report {path {alter_first 0}} {
    set fh [open $path w]
    set index 0
    set fingerprints [mptdc_signoff_expected_pg_wire_end_fingerprint]
    foreach fingerprint $fingerprints {
        lassign [split $fingerprint |] net layer x y
        if {$alter_first && $index == 0} {
            set x [format %.3f [expr {$x + 0.001}]]
        }
        puts $fh "Net $net: dangling Wire at ($x, $y) ($x, $y) on layer: $layer"
        incr index
    }
    set count [llength $fingerprints]
    puts $fh "    $count Problem(s) (IMPVFC-94): The net has dangling wire(s)."
    puts $fh "    $count total info(s) created."
    close $fh
}

set drc_data [dict create status PASS]
set regular_bad [list 0 {}]
set special_bad [list 1 {} 1 FILTERED_RO_ONLY 4 0 filter.rpt]
set exact_report [file join $test_root reports exact_special.rpt]
write_candidate_report $exact_report
set exact [mptdc_signoff_route_pg_pvs_candidate \
    $exact_report $drc_data $regular_bad $special_bad UNKNOWN \
    [file join $test_root reports exact_status.rpt]]
require_dict_value $exact status PASS
require_dict_value $exact effective_unrouted 0
require_dict_value $exact fallback_applied 1
require_dict_value $exact actual_count 12

set ::env(MPTDC_PG_WIRE_END_PROFILE) HALO10_PNRLEF_15
set halo_report [file join $test_root reports halo_special.rpt]
set halo_status [file join $test_root reports halo_status.rpt]
write_candidate_report $halo_report
set halo [mptdc_signoff_route_pg_pvs_candidate \
    $halo_report $drc_data $regular_bad $special_bad UNKNOWN $halo_status]
require_dict_value $halo status PASS
require_dict_value $halo effective_unrouted 0
require_dict_value $halo actual_count 15
set fh [open $halo_status r]
set halo_status_text [read $fh]
close $fh
if {[string first "ROUTE_PG_PVS_CANDIDATE_PROFILE=HALO10_PNRLEF_15" $halo_status_text] < 0} {
    error "guarded-halo candidate report did not record its profile"
}

set altered_report [file join $test_root reports altered_special.rpt]
write_candidate_report $altered_report 1
set altered [mptdc_signoff_route_pg_pvs_candidate \
    $altered_report $drc_data $regular_bad $special_bad 0 \
    [file join $test_root reports altered_status.rpt]]
require_dict_value $altered status FAIL
require_dict_value $altered exact_match 0

file delete -force $test_root
puts "MPTDC_ROUTE_PG_PVS_CANDIDATE_TEST=PASS"
