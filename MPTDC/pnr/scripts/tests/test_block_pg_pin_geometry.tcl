set script_dir [file dirname [file normalize [info script]]]
set signoff_tcl [file join $script_dir .. innovus_mptdc_digital_signoff.tcl]

set ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY) 1
source $signoff_tcl

proc assert_equal {label actual expected} {
    if {$actual ne $expected} {
        error "$label: expected '$expected', got '$actual'"
    }
}

proc rects_overlap_area {a b} {
    return [expr {
        [lindex $a 0] < [lindex $b 2] &&
        [lindex $a 2] > [lindex $b 0] &&
        [lindex $a 1] < [lindex $b 3] &&
        [lindex $a 3] > [lindex $b 1]
    }]
}

set ::env(MPTDC_BLOCK_PG_PIN_STYLE) ring_aligned_vdd_vss_pair
set ::env(MPTDC_PG_RING_WIDTH_UM) 2.0
set ::env(MPTDC_PG_RING_SPACING_UM) 1.0
set ::env(MPTDC_PG_RING_OFFSET_UM) 2.0
set ::env(MPTDC_PG_STRIPE_WIDTH_UM) 2.0
set ::env(MPTDC_PG_STRIPE_SPACING_UM) 2.0
set ::env(MPTDC_PG_STRIPE_PITCH_UM) 80.0
set ::env(MPTDC_PG_STRIPE_START_OFFSET_UM) 20.0

set specs [mptdc_signoff_block_pg_pin_specs]
assert_equal pin_count [llength $specs] 2
assert_equal vdd_spec [lindex $specs 0] {VDD LEFT 0.50 VDD}
assert_equal vss_spec [lindex $specs 1] {VSS RIGHT 0.50 VSS}

set core_box {20.16 20.16 1148.56 862.4}
set vdd_rect [mptdc_signoff_block_pg_pin_rect LEFT $core_box 4.0 28.0 0.50 VDD]
set vss_rect [mptdc_signoff_block_pg_pin_rect RIGHT $core_box 4.0 28.0 0.50 VSS]
assert_equal vdd_rect $vdd_rect {16.160 439.160 18.160 443.160}
assert_equal vss_rect $vss_rect {1153.560 443.160 1155.560 447.160}

set opposite_vss_left [mptdc_signoff_pg_mesh_pin_rect VSS LEFT $core_box 4.0 0.50]
set opposite_vdd_right [mptdc_signoff_pg_mesh_pin_rect VDD RIGHT $core_box 4.0 0.50]
assert_equal vdd_opposite_overlap [rects_overlap_area $vdd_rect $opposite_vss_left] 0
assert_equal vss_opposite_overlap [rects_overlap_area $vss_rect $opposite_vdd_right] 0

set marker_path [file join /tmp "mptdc_pg_cross_net_short_[pid].tsv"]
set fh [open $marker_path w]
puts $fh "idx\tmarker_handle\tbox\tlayer\ttype\tsubType\tmessage"
puts $fh "1\t0x1\t{1 1 2 2}\tMETTP\tGeometry\tMetal_Short\tSpecial Wire of Net VSS & Special Wire of Net VDD Type: Metal Short"
puts $fh "2\t0x2\t{3 3 4 4}\tMETTP\tGeometry\tMetal_Short\tSpecial Wire of Net VDD & Special Wire of Net VSS Type: Metal Short"
puts $fh "3\t0x3\t{5 5 6 6}\tMETTP\tGeometry\tMetal_Short\tRegular Wire of Net signal & Special Wire of Net VSS Type: Metal Short"
close $fh
set parsed [mptdc_signoff_pg_cross_net_short_status $marker_path]
assert_equal marker_parse_status [dict get $parsed status] PASS
assert_equal marker_short_count [dict get $parsed count] 2

set fh [open $marker_path w]
puts $fh "idx\tmarker_handle\tbox\tlayer\ttype\tsubType\tmessage"
close $fh
set clean [mptdc_signoff_pg_cross_net_short_status $marker_path]
assert_equal clean_marker_status [dict get $clean status] PASS
assert_equal clean_marker_short_count [dict get $clean count] 0
file delete -force $marker_path

puts "MPTDC_BLOCK_PG_PIN_GEOMETRY_TEST=PASS"
