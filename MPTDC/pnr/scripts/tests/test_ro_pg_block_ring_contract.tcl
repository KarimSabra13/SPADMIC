set script_dir [file dirname [file normalize [info script]]]
set signoff_tcl [file join $script_dir .. innovus_mptdc_digital_signoff.tcl]

set ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY) 1
source $signoff_tcl

proc assert_equal {label actual expected} {
    if {$actual ne $expected} {
        error "$label: expected '$expected', got '$actual'"
    }
}

proc option_value {command option} {
    set index [lsearch -exact $command $option]
    if {$index < 0 || $index == ([llength $command] - 1)} {
        error "missing option $option in command: $command"
    }
    return [lindex $command [expr {$index + 1}]]
}

set horizontal [mptdc_signoff_ro_pg_stripe_commands \
    VDD MET3 horizontal 30.0 {10.0 20.0 50.0 60.0} 0.8 2.0 5000.0]
set horizontal_exact [lindex $horizontal 0]
assert_equal horizontal_exact_tool [lindex $horizontal_exact 0] add_shape
assert_equal horizontal_exact_net [option_value $horizontal_exact -net] VDD
assert_equal horizontal_exact_path [option_value $horizontal_exact -pathSeg] \
    {10.000 30.000 50.000 30.000}
assert_equal horizontal_fallback_offset [option_value [lindex $horizontal 1] -start_offset] 10.000

set vertical [mptdc_signoff_ro_pg_stripe_commands \
    VSS METTP vertical 15.0 {10.0 20.0 50.0 60.0} 2.0 2.0 5000.0]
set vertical_exact [lindex $vertical 0]
assert_equal vertical_exact_path [option_value $vertical_exact -pathSeg] \
    {15.000 20.000 15.000 60.000}
assert_equal vertical_fallback_offset [option_value [lindex $vertical 1] -start_offset] 5.000

set ::env(MPTDC_RO_BLOCK_RING_WIDTH_UM) 2.0
set ::env(MPTDC_RO_BLOCK_RING_SPACING_UM) 1.0
set ::env(MPTDC_RO_BLOCK_RING_OFFSET_UM) 2.0
set ring [lindex [mptdc_signoff_ro_block_ring_commands {VDD VSS}] 0]
assert_equal ring_tool [lindex $ring 0] addRing
assert_equal ring_type [option_value $ring -type] block_rings
assert_equal ring_scope [option_value $ring -around] cluster
assert_equal ring_layers [option_value $ring -layer] \
    {top MET3 bottom MET3 left METTP right METTP}

set ::env(MPTDC_BREAK_PG_STRIPES_AT_RO_BLOCK_RINGS) 1
set mesh [mptdc_signoff_pg_mesh_stripe_commands {VDD VSS} METTP MET3 vertical]
assert_equal block_aware_mesh_candidate_count [llength $mesh] 1
if {[lsearch -exact [lindex $mesh 0] -break_stripes_at_block_rings] < 0} {
    error "block-aware mesh command omitted -break_stripes_at_block_rings"
}

set ::env(MPTDC_ENABLE_RO_BLOCK_RINGS) 1
set ::env(MPTDC_PG_STRATEGY) innovus_sroute_golden_ro
set ::env(MPTDC_ENABLE_SROUTE_PADPIN_FALLBACK) 0
set sroute [lindex [mptdc_signoff_postplace_sroute_commands {VDD VSS}] 0]
assert_equal block_pin_target [option_value $sroute -blockPinTarget] blockring

puts "MPTDC_RO_PG_BLOCK_RING_CONTRACT_TEST=PASS"
