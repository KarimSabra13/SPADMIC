set script_dir [file dirname [file normalize [info script]]]
set helper [file join [file dirname $script_dir] innovus_mptdc_pg_dangling_checkpoint_tools.tcl]
set fixture_dir [file join $script_dir .pg_dangling_fixture]
file delete -force $fixture_dir
file mkdir $fixture_dir
set ::env(MPTDC_PG_DANGLING_AUTORUN) 0
set ::env(MPTDC_SIGNOFF_RESULT_DIR) $fixture_dir
set ::env(MPTDC_PG_DANGLING_REQUIRE_ALL_ELIGIBLE) 1
set ::env(MPTDC_PG_DANGLING_ALLOW_LONG_DELETE) 0
source $helper

set ::pg_test_scenario blocked
set ::pg_test_capture_count 0
set ::pg_test_delete_count 0

proc pg_test_write_markers {path} {
    set fh [open $path w]
    puts $fh {Net VDD: dangling Wire at (1.000, 1.000) (1.000, 1.000) on layer: MET3}
    puts $fh {Net VSS: dangling Wire at (2.000, 2.000) (2.000, 2.000) on layer: MET3}
    close $fh
}

proc mptdc_pg_dangling_capture_verify_special {path} {
    incr ::pg_test_capture_count
    file mkdir [file dirname $path]
    if {$::pg_test_scenario eq "pass" && ($::pg_test_capture_count % 2) == 0} {
        set fh [open $path w]
        puts $fh {Verification Complete : 0 Viols. 0 Wrngs.}
        close $fh
    } else {
        pg_test_write_markers $path
    }
    return $path
}

proc pg_test_record {marker handle length} {
    set net [dict get $marker net]
    set layer [dict get $marker layer]
    set x [dict get $marker x]
    set y [dict get $marker y]
    return [dict create \
        handle $handle net $net layer $layer shape stripe status routed \
        width 1.0 geomType path box [list $x $y $x $y] \
        rect [list $x $y $x $y] pts [list [list $x $y] [list $x $y]] \
        length_um $length distance_um 0.0 endpoint_match 1 box_match 1]
}

proc mptdc_pg_dangling_marker_candidates {marker eps near_radius} {
    set idx [dict get $marker idx]
    if {$::pg_test_scenario eq "blocked" && $idx == 2} {
        set rec [pg_test_record $marker swire_2 20.0]
    } elseif {$::pg_test_scenario eq "duplicate"} {
        set rec [pg_test_record $marker swire_shared 1.0]
    } else {
        set rec [pg_test_record $marker swire_$idx 1.0]
    }
    return [dict create exact [list $rec] nearby {} net_handle net_$idx]
}

proc mptdc_pg_dangling_delete_swire {rec fh prefix} {
    incr ::pg_test_delete_count
    puts $fh "${prefix}_DELETE_STATUS=PASS"
    return 1
}

proc mptdc_pg_dangling_snapshot_after_delete {fh tag} {
    return [dict create total_violations 0 shorts 0 regular_bad 0]
}

proc pg_test_report_text {scenario} {
    set ::pg_test_scenario $scenario
    set ::pg_test_capture_count 0
    set ::pg_test_delete_count 0
    set report [mptdc_pg_dangling_run delete_short]
    set fh [open $report r]
    set text [read $fh]
    close $fh
    return $text
}

set blocked [pg_test_report_text blocked]
foreach expected {
    {PG_DANGLING_ELIGIBLE_COUNT=1}
    {PG_DANGLING_UNSAFE_LENGTH_COUNT=1}
    {PG_DANGLING_ALL_ELIGIBLE_STATUS=FAIL}
    {PG_DANGLING_MUTATION_ALLOWED=0}
    {PG_DANGLING_DELETE_ATTEMPTS=0}
    {PG_DANGLING_STATUS=REVIEW_REQUIRED_PREFLIGHT_BLOCKED}
} {
    if {[string first $expected $blocked] < 0} {
        error "blocked preflight report is missing $expected"
    }
}
if {$::pg_test_delete_count != 0} {
    error "blocked preflight performed a deletion"
}

set duplicate [pg_test_report_text duplicate]
foreach expected {
    {PG_DANGLING_DUPLICATE_HANDLE_COUNT=1}
    {PG_DANGLING_ALL_ELIGIBLE_STATUS=FAIL}
    {PG_DANGLING_MUTATION_ALLOWED=0}
    {PG_DANGLING_DELETE_ATTEMPTS=0}
} {
    if {[string first $expected $duplicate] < 0} {
        error "duplicate-handle preflight report is missing $expected"
    }
}
if {$::pg_test_delete_count != 0} {
    error "duplicate-handle preflight performed a deletion"
}

set pass [pg_test_report_text pass]
foreach expected {
    {PG_DANGLING_ELIGIBLE_COUNT=2}
    {PG_DANGLING_UNSAFE_LENGTH_COUNT=0}
    {PG_DANGLING_DUPLICATE_HANDLE_COUNT=0}
    {PG_DANGLING_ALL_ELIGIBLE_STATUS=PASS}
    {PG_DANGLING_MUTATION_ALLOWED=1}
    {PG_DANGLING_DELETE_ATTEMPTS=2}
    {PG_DANGLING_DELETE_SUCCESSES=2}
    {FINAL_DANGLING_MARKER_COUNT=0}
    {PG_DANGLING_STATUS=PASS_DANGLING_CLEARED}
} {
    if {[string first $expected $pass] < 0} {
        error "passing preflight report is missing $expected"
    }
}
if {$::pg_test_delete_count != 2} {
    error "passing preflight expected two deletions, found $::pg_test_delete_count"
}

file delete -force $fixture_dir
puts "MPTDC_PG_DANGLING_CHECKPOINT_TOOLS_TEST=PASS"
