# =============================================================================
# O10 RO/PD floorplan helpers
# =============================================================================

proc mptdc_o10_centered_box {core_box width height y_center} {
    set llx [expr {([lindex $core_box 0] + [lindex $core_box 2] - $width) / 2.0}]
    set lly [expr {$y_center - ($height / 2.0)}]
    set urx [expr {$llx + $width}]
    set ury [expr {$lly + $height}]
    return [list [mptdc_pnr_snap $llx] [mptdc_pnr_snap $lly] [mptdc_pnr_snap $urx] [mptdc_pnr_snap $ury]]
}

proc mptdc_o10_boxes {} {
    global pnr
    set core_box [mptdc_pnr_core_box]
    if {![mptdc_pnr_box_valid $core_box]} {
        return [dict create]
    }
    set core_lly [lindex $core_box 1]
    set core_ury [lindex $core_box 3]
    set center_y [expr {($core_lly + $core_ury) / 2.0}]
    set pd_box [mptdc_o10_centered_box $core_box $pnr(pd_region_width_um) $pnr(pd_region_height_um) $center_y]
    set slow_y [expr {[lindex $pd_box 3] + $pnr(pd_region_gap_um) + ($pnr(osc_macro_height_um) / 2.0)}]
    set fast_y [expr {[lindex $pd_box 1] - $pnr(pd_region_gap_um) - ($pnr(osc_macro_height_um) / 2.0)}]
    set slow_box [mptdc_o10_centered_box $core_box $pnr(osc_macro_width_um) $pnr(osc_macro_height_um) $slow_y]
    set fast_box [mptdc_o10_centered_box $core_box $pnr(osc_macro_width_um) $pnr(osc_macro_height_um) $fast_y]
    set backend_box [list [expr {[lindex $pd_box 2] + 20.0}] [lindex $core_box 1] [lindex $core_box 2] [lindex $core_box 3]]
    return [dict create core $core_box slow $slow_box pd $pd_box fast $fast_box backend $backend_box]
}

proc mptdc_o10_place_macro {inst box orient fh} {
    set x [lindex $box 0]
    set y [lindex $box 1]
    foreach cmd [list \
        [list placeInstance $inst $x $y $orient -fixed] \
        [list placeInstance $inst $x $y $orient] \
        [list setObjFPlanBox Instance $inst [lindex $box 0] [lindex $box 1] [lindex $box 2] [lindex $box 3]] \
    ] {
        if {![catch {uplevel 1 $cmd} err]} {
            puts $fh "Placed macro $inst with $cmd"
            return 1
        }
        puts $fh "Macro place skipped for $inst: $cmd"
        puts $fh "  $err"
    }
    return 0
}

proc mptdc_o10_place_ro_macro {inst box orient fh} {
    global pnr
    set llx [lindex $box 0]
    set lly [lindex $box 1]
    set urx [lindex $box 2]
    set ury [lindex $box 3]
    set ox $pnr(osc_macro_origin_x_um)
    set oy $pnr(osc_macro_origin_y_um)
    set w $pnr(osc_macro_width_um)
    set h $pnr(osc_macro_height_um)

    switch -- $orient {
        R0 {
            set x [expr {$llx + $ox}]
            set y [expr {$lly + $oy}]
        }
        MX {
            set x [expr {$llx + $ox}]
            set y [expr {$lly + $h - $oy}]
        }
        MY {
            set x [expr {$llx + $w - $ox}]
            set y [expr {$lly + $oy}]
        }
        R180 {
            set x [expr {$llx + $w - $ox}]
            set y [expr {$lly + $h - $oy}]
        }
        default {
            set x $llx
            set y $lly
        }
    }

    foreach cmd [list \
        [list placeInstance $inst $x $y $orient -fixed] \
        [list placeInstance $inst $x $y $orient] \
        [list setObjFPlanBox Instance $inst $llx $lly $urx $ury] \
    ] {
        if {![catch {uplevel 1 $cmd} err]} {
            puts $fh "Placed RO macro $inst with $cmd"
            puts $fh "  desired box: $box"
            puts $fh "  LEF origin: $ox $oy"
            return 1
        }
        puts $fh "RO macro place skipped for $inst: $cmd"
        puts $fh "  $err"
    }
    return 0
}

proc mptdc_o10_apply_pd_ro_floorplan {} {
    global o10
    set rpt "$o10(reports_dir)/floorplan_summary.rpt"
    set fh [open $rpt w]
    puts $fh "O10 RO/PD sandwich floorplan"
    puts $fh "============================"
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh "Labels: O10_INNOVUS_TYPICAL_FEASIBILITY NOT_FINAL_SIGNOFF"
    puts $fh ""

    set boxes [mptdc_o10_boxes]
    foreach key {core slow pd fast backend} {
        if {[dict exists $boxes $key]} {
            puts $fh "$key box: [dict get $boxes $key]"
        }
    }
    puts $fh ""

    set slow_cells [mptdc_o10_collect_cells [list *u_osc_slow*u_ro_tune4* *u_osc_slow*RO_tune4*]]
    set fast_cells [mptdc_o10_collect_cells [list *u_osc_fast*u_ro_tune4* *u_osc_fast*RO_tune4*]]
    set pd_cells [mptdc_o10_collect_cells [list *gen_pd_row*gen_pd_col*u_pd*]]
    puts $fh "slow RO matches: [llength $slow_cells]"
    foreach c $slow_cells { puts $fh "  $c" }
    puts $fh "fast RO matches: [llength $fast_cells]"
    foreach c $fast_cells { puts $fh "  $c" }
    puts $fh "PD cells: [llength $pd_cells] expected 64"

    if {[dict exists $boxes slow]} {
        foreach c $slow_cells { mptdc_o10_place_ro_macro $c [dict get $boxes slow] R0 $fh }
    }
    if {[dict exists $boxes fast]} {
        foreach c $fast_cells { mptdc_o10_place_ro_macro $c [dict get $boxes fast] MX $fh }
    }

    if {[dict exists $boxes pd]} {
        set pd_box [dict get $boxes pd]
        set llx [lindex $pd_box 0]
        set lly [lindex $pd_box 1]
        set urx [lindex $pd_box 2]
        set ury [lindex $pd_box 3]
        catch {createInstGroup mptdc_o10_pd_matrix}
        foreach cell $pd_cells { catch {addInstToInstGroup mptdc_o10_pd_matrix $cell} }
        catch {createRegion mptdc_o10_pd_matrix $llx $lly $urx $ury}
    }
    close $fh
}
