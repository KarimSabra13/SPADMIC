set test_dir [file dirname [file normalize [info script]]]
set scripts_dir [file dirname $test_dir]
set ::env(MPTDC_RO6_VSS_VIA_AUTORUN) 0
source [file join $scripts_dir innovus_mptdc_ro6_vss_via_checkpoint_tools.tcl]

proc assert_true {condition message} {
    if {![uplevel 1 [list expr $condition]]} {
        error "ASSERTION FAILED: $message"
    }
}

proc fixture_record {handle site role} {
    return [dict create handle $handle net [dict get $site net] \
        layer [dict get $site ${role}_layer] \
        shape [dict get $site ${role}_shape] \
        status [dict get $site ${role}_status] \
        geom [dict get $site ${role}_geom] \
        width [dict get $site ${role}_width] \
        points [dict get $site ${role}_points] \
        box [dict get $site ${role}_box]]
}

set records {}
set idx 0
foreach site [mptdc_ro6_vss_expected_sites] {
    incr idx
    lappend records [fixture_record core_$idx $site core]
    lappend records [fixture_record stripe_$idx $site stripe]
}

set resolved [mptdc_ro6_vss_resolve_sites $records]
assert_true {[dict get $resolved status] eq "PASS"} "exact two-site geometry must pass"
assert_true {[llength [dict get $resolved resolved]] == 2} "two sites must resolve"
assert_true {[dict get [lindex [dict get $resolved resolved] 0] id] eq "NORTH"} "north site order"
assert_true {[dict get [lindex [dict get $resolved resolved] 1] id] eq "SOUTH"} "south site order"

set reversed $records
set first [lindex $reversed 0]
dict set first points [lreverse [dict get $first points]]
set reversed [lreplace $reversed 0 0 $first]
assert_true {[dict get [mptdc_ro6_vss_resolve_sites $reversed] status] eq "PASS"} \
    "reversed path point order must preserve the exact contract"

set duplicate $records
lappend duplicate [dict replace [lindex $records 0] handle duplicate_core]
set duplicate_result [mptdc_ro6_vss_resolve_sites $duplicate]
assert_true {[dict get $duplicate_result status] eq "FAIL"} "ambiguous core wire must fail"
assert_true {[dict get [lindex [dict get $duplicate_result details] 0] core_count] == 2} \
    "ambiguous count must be reported"

set shifted $records
set shifted_stripe [lindex $shifted 1]
dict set shifted_stripe box {124.17 721.75 126.17 869.4}
set shifted [lreplace $shifted 1 1 $shifted_stripe]
assert_true {[dict get [mptdc_ro6_vss_resolve_sites $shifted] status] eq "FAIL"} \
    "shifted stripe must not pass exact geometry"

set north_box [dict get [lindex [mptdc_ro6_vss_expected_sites] 0] overlap_box]
set south_box [dict get [lindex [mptdc_ro6_vss_expected_sites] 1] overlap_box]
set vias [list \
    [dict create handle via_n point {125.16 723.52} box {}] \
    [dict create handle via_s point {} box {205.05 149.90 205.27 150.12}] \
    [dict create handle via_far point {10.0 10.0} box {}]]
assert_true {[llength [mptdc_ro6_vss_vias_in_box $vias $north_box]] == 1} \
    "north via must localize by point"
assert_true {[llength [mptdc_ro6_vss_vias_in_box $vias $south_box]] == 1} \
    "south via must localize by box"

set commands [mptdc_ro6_vss_via_commands $north_box]
assert_true {[llength $commands] == 4} "only layer-bounded editPowerVia variants are allowed"
foreach command $commands {
    assert_true {[lsearch -exact $command -add_vias] >= 0} "via command must add vias"
    assert_true {[lsearch -exact $command MET1] >= 0} "via command must name MET1"
    assert_true {[lsearch -exact $command METTP] >= 0} "via command must name METTP"
    assert_true {[lsearch -exact $command -area] >= 0} "via command must use exact area"
}

puts "MPTDC_RO6_VSS_VIA_CHECKPOINT_TOOLS_TEST=PASS"
