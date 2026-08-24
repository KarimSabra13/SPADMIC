set script_dir [file dirname [file normalize [info script]]]
set signoff_script [file normalize [file join $script_dir .. innovus_mptdc_digital_signoff.tcl]]
set test_root [file normalize [file join $script_dir .tmp_signal_top_route_blockage_lifecycle]]

file delete -force $test_root
file mkdir $test_root
set ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY) 1
set ::env(MPTDC_SIGNOFF_RESULT_DIR) $test_root
set ::env(MPTDC_ENABLE_SIGNAL_TOP_ROUTE_BLOCKAGE) 1
set ::env(MPTDC_SIGNAL_TOP_ROUTE_BLOCKAGE_TEMPORARY) 1
set ::env(MPTDC_SIGNAL_TOP_ROUTE_BLOCKAGE_LAYER) METTP
source $signoff_script

rename mptdc_signoff_core_box mptdc_signoff_core_box_original
proc mptdc_signoff_core_box {} {
    return {0.0 0.0 100.0 80.0}
}

set ::mock_route_blockages [list]
proc createRouteBlk {args} {
    set name_index [lsearch -exact $args -name]
    if {$name_index < 0} {
        error "temporary blockage must be named"
    }
    set ::mock_route_blockages [list 0xabc]
    return 0xabc
}
proc dbGet {args} {
    return $::mock_route_blockages
}
proc deleteRouteBlk {args} {
    if {[llength $args] != 2 || [lindex $args 0] ne "-name"} {
        error "unsupported deleteRouteBlk form"
    }
    set ::mock_route_blockages [list]
    return 1
}

proc require_report_value {path key expected} {
    set fh [open $path r]
    set text [read $fh]
    close $fh
    set actual ""
    foreach line [split $text "\n"] {
        if {[string match "${key}=*" $line]} {
            set actual [string range $line [expr {[string length $key] + 1}] end]
        }
    }
    if {$actual ne $expected} {
        error "$key expected=$expected actual=$actual"
    }
}

set report [file join $test_root reports signal_top_route_blockage_status.rpt]
file mkdir [file dirname $report]
mptdc_signoff_apply_signal_top_route_blockage $report
require_report_value $report SIGNAL_TOP_ROUTE_BLOCKAGE_CREATE_STATUS PASS
require_report_value $report SIGNAL_TOP_ROUTE_BLOCKAGE_STATUS ACTIVE_FOR_ROUTE
mptdc_signoff_remove_signal_top_route_blockage $report
require_report_value $report SIGNAL_TOP_ROUTE_BLOCKAGE_REMOVE_STATUS PASS
require_report_value $report SIGNAL_TOP_ROUTE_BLOCKAGE_STATUS REMOVED
if {[llength $::mock_route_blockages] != 0} {
    error "temporary route blockage remains after removal"
}

rename deleteRouteBlk deleteRouteBlk_pass
proc deleteRouteBlk {args} {
    error "forced deleteRouteBlk failure"
}
proc dbDeleteObj {handle} {
    error "forced dbDeleteObj failure"
}
set failure_report [file join $test_root reports signal_top_route_blockage_remove_failure.rpt]
mptdc_signoff_apply_signal_top_route_blockage $failure_report
if {![catch {mptdc_signoff_remove_signal_top_route_blockage $failure_report}]} {
    error "unremoved temporary blockage was accepted"
}
require_report_value $failure_report SIGNAL_TOP_ROUTE_BLOCKAGE_REMOVE_STATUS FAIL
require_report_value $failure_report SIGNAL_TOP_ROUTE_BLOCKAGE_STATUS FAIL

file delete -force $test_root
puts "MPTDC_SIGNAL_TOP_ROUTE_BLOCKAGE_LIFECYCLE_TEST=PASS"
