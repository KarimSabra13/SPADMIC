# =============================================================================
# O12C phase-buffer placement constraints
#
# This file is intended to be sourced before placement/legalization in an O12C
# P&R experiment.  It does not alter RTL, packet format, oscillator frequency,
# or calibration semantics.
# =============================================================================

set ::env(MPTDC_O12B_SOURCE_ONLY) 1
source [file join [file dirname [file normalize [info script]]] innovus_o12b_phase_buffer_reports.tcl]

proc mptdc_o12c_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_o12c_reports_dir {} {
    if {[info exists ::o12b(reports_dir)]} {
        return $::o12b(reports_dir)
    }
    if {[info exists ::env(MPTDC_O12C_RESULT_DIR)]} {
        return "$::env(MPTDC_O12C_RESULT_DIR)/reports"
    }
    return "reports"
}

proc mptdc_o12c_phase_buffer_instances {family} {
    set insts [list]
    for {set tap 0} {$tap < 8} {incr tap} {
        set row [mptdc_o12b_get_row_objects $family $tap]
        set inst [lindex $row 8]
        if {$inst ne ""} {
            lappend insts [list $tap $inst]
        }
    }
    return $insts
}

proc mptdc_o12c_place_one {inst x y orient fh} {
    foreach cmd [list \
        [list placeInstance $inst $x $y $orient] \
        [list placeInstance $inst $x $y $orient -fixed]] {
        if {![catch {uplevel 1 $cmd} err]} {
            puts $fh "placed,$inst,$x,$y,$orient,[mptdc_o12b_csv $cmd]"
            return 1
        }
        puts $fh "place_attempt_failed,$inst,$x,$y,$orient,[mptdc_o12b_csv $cmd],[mptdc_o12b_csv $err]"
    }
    return 0
}

proc mptdc_o12c_apply_phase_buffer_placement {mode} {
    set reports_dir [mptdc_o12c_reports_dir]
    file mkdir $reports_dir
    set path "$reports_dir/phase_buffer_placement_constraints.rpt"
    set fh [open $path w]
    puts $fh "# O12C Phase Buffer Placement Constraints"
    puts $fh "mode=$mode"
    puts $fh "status=REVIEW_REQUIRED"
    puts $fh "generated=[clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""

    set pitch [mptdc_o12c_env MPTDC_O12C_PHASE_BUF_PITCH_UM 4.0]
    set slow_x [mptdc_o12c_env MPTDC_O12C_SLOW_BUF_X ""]
    set slow_y [mptdc_o12c_env MPTDC_O12C_SLOW_BUF_Y ""]
    set fast_x [mptdc_o12c_env MPTDC_O12C_FAST_BUF_X ""]
    set fast_y [mptdc_o12c_env MPTDC_O12C_FAST_BUF_Y ""]
    set orient [mptdc_o12c_env MPTDC_O12C_PHASE_BUF_ORIENT R0]

    puts $fh "pitch_um=$pitch"
    puts $fh "orient=$orient"
    puts $fh "slow_origin=$slow_x,$slow_y"
    puts $fh "fast_origin=$fast_x,$fast_y"
    puts $fh ""

    if {$slow_x eq "" || $slow_y eq "" || $fast_x eq "" || $fast_y eq ""} {
        puts $fh "PLACEMENT_CONSTRAINTS_SKIPPED=YES"
        puts $fh "reason=explicit buffer row origins are required"
        puts $fh "required_env=MPTDC_O12C_SLOW_BUF_X MPTDC_O12C_SLOW_BUF_Y MPTDC_O12C_FAST_BUF_X MPTDC_O12C_FAST_BUF_Y"
        close $fh
        return 0
    }

    puts $fh "action,instance,x,y,orient,command,error"
    foreach family {slow fast} {
        set base_x [expr {$family eq "slow" ? $slow_x : $fast_x}]
        set base_y [expr {$family eq "slow" ? $slow_y : $fast_y}]
        foreach item [mptdc_o12c_phase_buffer_instances $family] {
            set tap [lindex $item 0]
            set inst [lindex $item 1]
            set x [expr {$base_x + ($tap * $pitch)}]
            set y $base_y
            mptdc_o12c_place_one $inst $x $y $orient $fh
        }
    }
    close $fh
    return 1
}
