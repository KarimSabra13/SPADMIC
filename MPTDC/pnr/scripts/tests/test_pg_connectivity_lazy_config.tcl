set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ../../../..]]
set signoff_tcl [file join $script_dir .. innovus_mptdc_digital_signoff.tcl]
set result_dir [file join /tmp "mptdc_pg_connectivity_lazy_[pid]"]

set ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY) 1
set ::env(MPTDC_REPO_ROOT) $repo_root
set ::env(MPTDC_SIGNOFF_RESULT_DIR) $result_dir
source $signoff_tcl

proc assert_equal {label actual expected} {
    if {$actual ne $expected} {
        error "$label: expected '$expected', got '$actual'"
    }
}

proc report_value {path key} {
    set fh [open $path r]
    set value MISSING
    while {[gets $fh line] >= 0} {
        if {[string match "${key}=*" $line]} {
            set value [string range $line [expr {[string length $key] + 1}] end]
        }
    }
    close $fh
    return $value
}

proc mptdc_signoff_collect_cells {patterns} {
    return {u_core/u_ro_fast u_core/u_ro_slow}
}

proc globalNetConnect {args} {
    lappend ::pg_commands $args
}

file delete -force $result_dir
mptdc_signoff_mkdirs
catch {unset ::mptdc_xh018_cells}

set ::pg_commands [list]
set report [mptdc_signoff_apply_pg_connectivity]
assert_equal lazy_source [report_value $report PG_CONFIG_SOURCE_STATUS] LOADED
assert_equal lazy_command_count [report_value $report PG_CONNECTIVITY_COMMAND_COUNT] 6
assert_equal lazy_failure_count [report_value $report PG_CONNECTIVITY_COMMAND_FAILURE_COUNT] 0
assert_equal lazy_command_status [report_value $report PG_CONNECTIVITY_COMMAND_STATUS] PASS
assert_equal lazy_recorded_commands [llength $::pg_commands] 6
assert_equal stdcell_vdd [lindex $::pg_commands 0] {VDD -type pgpin -pin vddi -inst *}
assert_equal stdcell_vss [lindex $::pg_commands 1] {VSS -type pgpin -pin gndi -inst *}
assert_equal ro_fast_vdd [lindex $::pg_commands 2] {VDD -type pgpin -pin VDD -inst u_core/u_ro_fast}
assert_equal ro_fast_vss [lindex $::pg_commands 3] {VSS -type pgpin -pin VSS -inst u_core/u_ro_fast}
assert_equal ro_slow_vdd [lindex $::pg_commands 4] {VDD -type pgpin -pin VDD -inst u_core/u_ro_slow}
assert_equal ro_slow_vss [lindex $::pg_commands 5] {VSS -type pgpin -pin VSS -inst u_core/u_ro_slow}

set ::pg_commands [list]
set report [mptdc_signoff_apply_pg_connectivity]
assert_equal stable_source [report_value $report PG_CONFIG_SOURCE_STATUS] ALREADY_LOADED
assert_equal stable_command_count [report_value $report PG_CONNECTIVITY_COMMAND_COUNT] 6
assert_equal stable_recorded_commands [llength $::pg_commands] 6

catch {unset ::mptdc_xh018_cells}
rename mptdc_signoff_source_xh018_cells mptdc_signoff_source_xh018_cells_real
proc mptdc_signoff_source_xh018_cells {} {
    error FORCED_CONFIG_LOAD_FAILURE
}
set failure_rc [catch {mptdc_signoff_apply_pg_connectivity} failure_error]
assert_equal forced_failure_rc $failure_rc 1
if {![string match "*MPTDC_XH018_CELL_CONFIG_LOAD_FAILED*" $failure_error]} {
    error "forced_failure_error: unexpected '$failure_error'"
}
set report [file join $result_dir reports pg_connectivity_commands.rpt]
assert_equal forced_source [report_value $report PG_CONFIG_SOURCE_STATUS] FAIL
assert_equal forced_command_count [report_value $report PG_CONNECTIVITY_COMMAND_COUNT] 0
assert_equal forced_command_status [report_value $report PG_CONNECTIVITY_COMMAND_STATUS] FAIL

file delete -force $result_dir
puts "MPTDC_PG_CONNECTIVITY_LAZY_CONFIG_TEST=PASS"
