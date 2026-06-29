# =============================================================================
# O13 phase-buffer placement constraints
#
# Source before placement/legalization in an O13 P&R experiment.  The hook does
# not alter RTL, packet format, oscillator frequency, or calibration semantics.
# It only places the explicit O13 phase-distribution cells when origins are
# provided by the run script or interactive Innovus session.
# =============================================================================

set ::env(MPTDC_O13_SOURCE_ONLY) 1
set mptdc_o13_place_script_dir [file dirname [file normalize [info script]]]
set mptdc_o13_place_utils [file join $mptdc_o13_place_script_dir innovus_mptdc_place_utils.tcl]
if {[file exists $mptdc_o13_place_utils]} {
    source $mptdc_o13_place_utils
}
unset mptdc_o13_place_script_dir
unset mptdc_o13_place_utils
source [file join [file dirname [file normalize [info script]]] innovus_o13_phase_buffer_reports.tcl]

proc mptdc_o13_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_o13_place_reports_dir {} {
    if {[info exists ::o13(reports_dir)]} {
        return $::o13(reports_dir)
    }
    if {[info exists ::env(MPTDC_O13_RESULT_DIR)]} {
        return "$::env(MPTDC_O13_RESULT_DIR)/reports"
    }
    return "reports"
}

proc mptdc_o13_phase_stage_instances {family stage_role} {
    set role [expr {$stage_role eq "isolation" ? "iso_Q" : "drv_Q"}]
    set insts [list]
    for {set tap 0} {$tap < 8} {incr tap} {
        set pins [mptdc_o13_get_pins [mptdc_o13_pin_candidates $family $tap $role]]
        set pin [lindex $pins 0]
        set inst [mptdc_o12b_cell_from_pin $pin]
        if {$inst ne ""} {
            lappend insts [list $tap $inst]
        }
    }
    return $insts
}

proc mptdc_o13_place_one {inst x y orient fh} {
    if {[llength [info commands mptdc_pnr_place_instance_row_legal]] > 0} {
        set place_result [mptdc_pnr_place_instance_row_legal $inst $x $y $orient 0]
        if {[dict get $place_result status] eq "PASS"} {
            set actual_orient ""
            set actual_status ""
            set actual_origin ""
            set actual_box ""
            catch {set actual_orient [dict get $place_result actual_orient]}
            catch {set actual_status [dict get $place_result actual_status]}
            catch {set actual_origin [dict get $place_result actual_origin]}
            catch {set actual_box [dict get $place_result actual_box]}
            puts $fh "placed,$inst,$x,$y,$orient,[mptdc_o12b_csv [dict get $place_result command]],actual_orient=$actual_orient actual_status=$actual_status actual_origin=[mptdc_o12b_csv $actual_origin] actual_box=[mptdc_o12b_csv $actual_box]"
            return 1
        }
        puts $fh "place_attempt_failed,$inst,$x,$y,$orient,,[mptdc_o12b_csv [dict get $place_result errors]]"
        return 0
    }
    foreach cmd [list \
        [list placeInstance $inst $x $y $orient] \
        [list placeInstance $inst $x $y $orient -fixed]] {
        if {![catch {uplevel 1 $cmd} err]} {
            puts $fh "placed,$inst,$x,$y,$orient,[mptdc_o12b_csv $cmd],"
            return 1
        }
        puts $fh "place_attempt_failed,$inst,$x,$y,$orient,[mptdc_o12b_csv $cmd],[mptdc_o12b_csv $err]"
    }
    return 0
}

proc mptdc_o13_origin_for {family stage} {
    set prefix [string toupper "${family}_${stage}"]
    set x [mptdc_o13_env "MPTDC_O13_${prefix}_X" ""]
    set y [mptdc_o13_env "MPTDC_O13_${prefix}_Y" ""]
    return [list $x $y]
}

proc mptdc_o13_apply_phase_buffer_placement {mode} {
    set reports_dir [mptdc_o13_place_reports_dir]
    file mkdir $reports_dir
    set path "$reports_dir/phase_buffer_placement_constraints.rpt"
    set fh [open $path w]
    puts $fh "# O13 Phase Buffer Placement Constraints"
    puts $fh "mode=$mode"
    puts $fh "status=REVIEW_REQUIRED"
    puts $fh "generated=[clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""

    set pitch [mptdc_o13_env MPTDC_O13_PHASE_BUF_PITCH_UM 4.0]
    set orient [mptdc_o13_env MPTDC_O13_PHASE_BUF_ORIENT AUTO]
    puts $fh "pitch_um=$pitch"
    puts $fh "orient=$orient"

    set missing [list]
    foreach family {slow fast} {
        foreach stage {ISO DRV} {
            set origin [mptdc_o13_origin_for $family $stage]
            set x [lindex $origin 0]
            set y [lindex $origin 1]
            puts $fh "${family}_${stage}_origin=$x,$y"
            if {$x eq "" || $y eq ""} {
                set label [string toupper "${family}_${stage}"]
                lappend missing "MPTDC_O13_${label}_X/Y"
            }
        }
    }
    puts $fh ""

    if {[llength $missing] > 0} {
        puts $fh "PLACEMENT_CONSTRAINTS_SKIPPED=YES"
        puts $fh "reason=explicit isolation/driver row origins are required"
        puts $fh "missing_env=[join $missing { }]"
        close $fh
        return 0
    }

    puts $fh "action,instance,x,y,orient,command,error"
    foreach family {slow fast} {
        foreach stage_role {isolation driver} {
            set stage [expr {$stage_role eq "isolation" ? "ISO" : "DRV"}]
            set origin [mptdc_o13_origin_for $family $stage]
            set base_x [lindex $origin 0]
            set base_y [lindex $origin 1]
            foreach item [mptdc_o13_phase_stage_instances $family $stage_role] {
                set tap [lindex $item 0]
                set inst [lindex $item 1]
                set x [expr {$base_x + ($tap * $pitch)}]
                set y $base_y
                mptdc_o13_place_one $inst $x $y $orient $fh
            }
        }
    }
    close $fh
    return 1
}
