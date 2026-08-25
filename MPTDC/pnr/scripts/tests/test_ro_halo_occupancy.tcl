set script_dir [file dirname [file normalize [info script]]]
set signoff_tcl [file normalize [file join $script_dir .. innovus_mptdc_digital_signoff.tcl]]
set test_root [file normalize [file join $script_dir .tmp_ro_halo_occupancy]]

file delete -force $test_root
file mkdir [file join $test_root reports]
set ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY) 1
set ::env(MPTDC_SIGNOFF_RESULT_DIR) $test_root
set ::env(MPTDC_PNR_CREATE_RO_HALOS) 1
set ::env(MPTDC_RO_PHASE_MIN_CLEARANCE_UM) 10.0
set ::env(MPTDC_RO_HALO_PLACER_GUARD_X_UM) 11.2
set ::env(MPTDC_RO_HALO_PLACER_GUARD_Y_UM) 4.48
source $signoff_tcl

rename mptdc_signoff_ro_instances_by_family mptdc_signoff_ro_instances_by_family_original
rename mptdc_signoff_collect_inst_names_from_db mptdc_signoff_collect_inst_names_from_db_original
rename mptdc_signoff_cell_box mptdc_signoff_cell_box_original

proc mptdc_signoff_ro_instances_by_family {} {
    return [list slow ro_slow fast ro_fast all {ro_slow ro_fast}]
}
proc mptdc_signoff_collect_inst_names_from_db {patterns} {
    return [dict keys $::mock_boxes]
}
proc mptdc_signoff_cell_box {inst} {
    if {[dict exists $::mock_boxes $inst]} {
        return [dict get $::mock_boxes $inst]
    }
    return [list]
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

proc createPlaceBlockage {args} {
    lappend ::mock_place_blockages $args
}

set ::mock_boxes [dict create \
    ro_slow {10.0 10.0 20.0 20.0} \
    ro_fast {50.0 50.0 60.0 60.0} \
    cell_slow_outside {30.0 12.0 31.0 13.0} \
    cell_fast_outside {70.0 52.0 71.0 53.0}]
set ::mock_place_blockages [list]
set create_report [file join $test_root reports ro_halo_create.rpt]
mptdc_signoff_create_ro_halos $create_report
require_report_value $create_report RO_HALO_AUDIT_CLEARANCE_UM 10.0
require_report_value $create_report RO_HALO_PLACER_GUARD_X_UM 11.2
require_report_value $create_report RO_HALO_PLACER_GUARD_Y_UM 4.48
require_report_value $create_report RO_HALO_PLACEMENT_CLEARANCE_X_UM 21.2
require_report_value $create_report RO_HALO_PLACEMENT_CLEARANCE_Y_UM 14.48
require_report_value $create_report SLOW_RO_HALO_BBOX {0.0 0.0 30.0 30.0}
require_report_value $create_report SLOW_RO_PLACEMENT_BLOCKAGE_BBOX {-11.200000 -4.480000 41.200000 34.480000}
require_report_value $create_report FAST_RO_PLACEMENT_BLOCKAGE_BBOX {28.800000 35.520000 81.200000 74.480000}
require_report_value $create_report RO_HALO_COUNT 2
require_report_value $create_report RO_HALO_STATUS PASS
if {[llength $::mock_place_blockages] != 2} {
    error "expected two guarded placement blockages, got [llength $::mock_place_blockages]"
}

set pass_report [file join $test_root reports ro_halo_occupancy_pass.rpt]
mptdc_signoff_audit_ro_halo_occupancy 1 $pass_report
require_report_value $pass_report RO_HALO_OCCUPANCY_STATUS PASS
require_report_value $pass_report RO_HALO_TOTAL_INTRUSION_COUNT 0
require_report_value $pass_report RO_HALO_INVALID_INSTANCE_BBOX_COUNT 0
require_report_value $pass_report RO_TUNE6_COUNT 2

dict set ::mock_boxes cell_inside_slow {25.0 12.0 26.0 13.0}
set fail_report [file join $test_root reports ro_halo_occupancy_fail.rpt]
if {![catch {mptdc_signoff_audit_ro_halo_occupancy 1 $fail_report}]} {
    error "instance inside the 10 um RO halo was accepted"
}
require_report_value $fail_report RO_HALO_OCCUPANCY_STATUS FAIL
require_report_value $fail_report RO_HALO_TOTAL_INTRUSION_COUNT 1
require_report_value $fail_report SLOW_RO_HALO_INTRUSION_0_INSTANCE cell_inside_slow
require_report_value $fail_report SLOW_RO_HALO_INTRUSION_0_BBOX {25.0 12.0 26.0 13.0}
require_report_value $fail_report SLOW_RO_HALO_INTRUSION_0_RO_CLEARANCE_UM 5.0

file delete -force $test_root
puts "MPTDC_RO_HALO_OCCUPANCY_TEST=PASS"
