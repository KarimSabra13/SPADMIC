set ::env(MPTDC_FREE_PLACEMENT_LIBRARY_ONLY) 1
source [file join $::env(MPTDC_REPO_ROOT) MPTDC pnr scripts innovus_mptdc_free_placement_trial.tcl]

set ::test_dir [file join /tmp "mptdc_free_macro_state_[pid]"]
file delete -force $::test_dir
file mkdir $::test_dir
array set ::test_status {slow placed fast placed}
array set ::test_box {
    slow {10.0 10.0 30.0 30.0}
    fast {60.0 60.0 80.0 80.0}
}
set ::test_concurrent_calls 0

proc mptdc_signoff_report_dir {} { return $::test_dir }
proc mptdc_signoff_checkpoint_dir {} { return $::test_dir }
proc mptdc_free_ro_instances {} { return {slow fast} }
proc mptdc_pnr_place_db_ptr {inst} { return "ptr_$inst" }
proc mptdc_pnr_place_query_attr {inst attrs} { return $::test_status($inst) }
proc mptdc_signoff_cell_box {inst} { return $::test_box($inst) }
proc mptdc_signoff_core_box {} { return {0.0 0.0 100.0 100.0} }
proc mptdc_signoff_set_status {key state evidence} {}
proc saveDesign {path} {}

proc dbSet {target value} {
    if {![regexp {^ptr_(.+)\.pStatus$} $target -> inst]} {
        error "unexpected dbSet target: $target"
    }
    set ::test_status($inst) $value
}

proc place_design {option} {
    if {$option ne "-concurrent_macros"} {
        error "unexpected place_design option: $option"
    }
    foreach inst {slow fast} {
        if {$::test_status($inst) ne "unplaced"} {
            error "$inst was not unplaced before concurrent placement"
        }
        set ::test_status($inst) placed
    }
    incr ::test_concurrent_calls
}

proc mptdc_pnr_place_mark_fixed {inst} {
    set ::test_status($inst) fixed
    return [dict create status PASS command [list mock_fix $inst] errors {}]
}

proc mptdc_free_create_soft_halo {inst name margin} {
    return [list [mptdc_signoff_expand_box $::test_box($inst) $margin] [list mock_halo $inst]]
}

mptdc_free_macro_aware_place_and_freeze
set report [file join $::test_dir free_macro_aware_placement.rpt]
set fh [open $report r]
set text [read $fh]
close $fh

foreach expected {
    {RO_UNPLACED_FOR_CONCURRENT_COUNT=2}
    {MACRO_AWARE_COMMAND=place_design -concurrent_macros}
    {MACRO_AWARE_COMMAND_STATUS=PASS}
    {RO_PAIR_NONOVERLAP_STATUS=PASS}
    {RO_FIXED_AFTER_MACRO_AWARE_PLACEMENT_COUNT=2}
    {MACRO_AWARE_PLACEMENT_STATUS=PASS}
} {
    if {[string first $expected $text] < 0} {
        error "missing report contract: $expected"
    }
}
if {$::test_concurrent_calls != 1} {
    error "expected one concurrent placement call, got $::test_concurrent_calls"
}
foreach inst {slow fast} {
    if {$::test_status($inst) ne "fixed"} {
        error "$inst was not fixed after concurrent placement"
    }
}

file delete -force $::test_dir
puts "FREE_MACRO_PLACEMENT_STATE_MACHINE_TEST=PASS"
