# =============================================================================
# Stable MPTDC final-typical floorplan intent
# =============================================================================

proc mptdc_pnr_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_pnr_core_util_default {} {
    return [mptdc_pnr_env MPTDC_PNR_CORE_UTIL 0.60]
}

proc mptdc_pnr_core_util_allowed_range {} {
    return [list min 0.58 default [mptdc_pnr_core_util_default] max 0.62]
}

proc mptdc_pnr_core_util_max_first_run {} {
    return 0.65
}

proc mptdc_pnr_target_aspect_ratio {} {
    return [mptdc_pnr_env MPTDC_PNR_ASPECT_RATIO 1.333333]
}

proc mptdc_pnr_allowed_aspect_ratio_range {} {
    return [list min 1.20 target [mptdc_pnr_target_aspect_ratio] max 1.47]
}

proc mptdc_pnr_box_valid {box} {
    if {[llength $box] < 4} { return 0 }
    foreach value [lrange $box 0 3] {
        if {![string is double -strict $value]} { return 0 }
    }
    return [expr {([lindex $box 2] > [lindex $box 0]) && ([lindex $box 3] > [lindex $box 1])}]
}

proc mptdc_pnr_core_box {} {
    set core_box [list]
    foreach cmd {
        {dbGet top.fPlan.coreBox}
        {dbGet top.fPlan.box}
    } {
        if {![catch {set core_box [eval $cmd]}] && $core_box ne ""} {
            break
        }
    }
    while {[llength $core_box] == 1} {
        set core_box [lindex $core_box 0]
    }
    if {[llength $core_box] >= 4} {
        return [lrange $core_box 0 3]
    }
    return [list]
}

proc mptdc_pnr_snap {value} {
    set snap [mptdc_pnr_env MPTDC_PNR_FLOORPLAN_SNAP_UM 0.56]
    if {$snap <= 0.0} { return $value }
    return [expr {round($value / $snap) * $snap}]
}

proc mptdc_pnr_floorplan_labels {} {
    return [list TYPICAL_ONLY NOT_MMMC_SIGNOFF NOT_FINAL_SILICON_SIGNOFF]
}

proc mptdc_pnr_floorplan_order {} {
    return [list \
        slow_ro_north \
        slow_buhdx4_isolation_row \
        slow_buhdx12_final_driver_row \
        pd_8x8_island \
        fast_buhdx12_final_driver_row \
        fast_buhdx4_isolation_row \
        fast_ro_south \
        clk_sys_control_fifo_readout_east \
    ]
}

proc mptdc_pnr_floorplan_timing_protection_rules {} {
    return [list \
        {keep_fast_tag_generators_near_corresponding_pd_columns} \
        {keep_nfast_tag_data_routes_short} \
        {keep_pd_matrix_compact_regular_8x8} \
        {keep_phase_buffer_drivers_close_to_pd_island} \
        {keep_backend_east_of_phase_pd_island} \
        {avoid_wide_clk_sys_buses_over_pd_island} \
        {do_not_buffer_raw_ro_nets} \
        {do_not_resize_buhdx4_buhdx12_phase_root_drivers_without_review} \
        {do_not_cts_raw_ro_or_buffered_phase_clocks} \
    ]
}

proc mptdc_pnr_floorplan_regions {} {
    set core_box [mptdc_pnr_core_box]
    set pd_w [mptdc_pnr_env MPTDC_PNR_PD_REGION_WIDTH_UM 300.0]
    set pd_h [mptdc_pnr_env MPTDC_PNR_PD_REGION_HEIGHT_UM 300.0]
    set ro_w [mptdc_pnr_env MPTDC_PNR_OSC_WIDTH_UM 176.675]
    set ro_h [mptdc_pnr_env MPTDC_PNR_OSC_HEIGHT_UM 67.17]
    set gap  [mptdc_pnr_env MPTDC_PNR_PD_OSC_GAP_UM 20.0]
    set buf_h [mptdc_pnr_env MPTDC_PNR_PHASE_BUFFER_ROW_HEIGHT_UM 20.0]

    if {[mptdc_pnr_box_valid $core_box]} {
        set llx [lindex $core_box 0]
        set lly [lindex $core_box 1]
        set urx [lindex $core_box 2]
        set ury [lindex $core_box 3]
        set core_w [expr {$urx - $llx}]
        set core_h [expr {$ury - $lly}]
        set edge [mptdc_pnr_env MPTDC_PNR_REGION_EDGE_MARGIN_UM 30.0]
        set backend_gap [mptdc_pnr_env MPTDC_PNR_BACKEND_GAP_UM 40.0]
        set backend_w [mptdc_pnr_env MPTDC_PNR_BACKEND_WIDTH_UM 300.0]
        set left_x [mptdc_pnr_snap [expr {$llx + $edge}]]

        set max_left_w [expr {$core_w - (2.0 * $edge) - $backend_gap - $backend_w}]
        if {$max_left_w > 120.0 && $pd_w > $max_left_w} {
            set pd_w $max_left_w
        }
        if {$pd_w < 120.0} { set pd_w 120.0 }

        set stack_h [expr {(2.0 * $ro_h) + (2.0 * $buf_h) + $pd_h + (4.0 * $gap)}]
        set max_stack_h [expr {$core_h - (2.0 * $edge)}]
        if {$stack_h > $max_stack_h} {
            set pd_h [expr {$max_stack_h - (2.0 * $ro_h) - (2.0 * $buf_h) - (4.0 * $gap)}]
            if {$pd_h < 120.0} { set pd_h 120.0 }
            set stack_h [expr {(2.0 * $ro_h) + (2.0 * $buf_h) + $pd_h + (4.0 * $gap)}]
        }

        set stack_lly [mptdc_pnr_snap [expr {$lly + (($core_h - $stack_h) / 2.0)}]]
        set fast_ro_y $stack_lly
        set fast_buf_y [mptdc_pnr_snap [expr {$fast_ro_y + $ro_h + $gap}]]
        set pd_y [mptdc_pnr_snap [expr {$fast_buf_y + $buf_h + $gap}]]
        set slow_buf_y [mptdc_pnr_snap [expr {$pd_y + $pd_h + $gap}]]
        set slow_ro_y [mptdc_pnr_snap [expr {$slow_buf_y + $buf_h + $gap}]]
        set left_w [expr {max($pd_w, $ro_w)}]
        set backend_x [mptdc_pnr_snap [expr {$left_x + $left_w + $backend_gap}]]
        set backend_urx [expr {$urx - $edge}]
        if {$backend_x + 80.0 > $backend_urx} {
            set backend_x [mptdc_pnr_snap [expr {$left_x + $left_w + 20.0}]]
        }
        return [dict create \
            fast_ro [list $left_x $fast_ro_y [expr {$left_x + $ro_w}] [expr {$fast_ro_y + $ro_h}]] \
            fast_phase_buffers [list $left_x $fast_buf_y [expr {$left_x + $left_w}] [expr {$fast_buf_y + $buf_h}]] \
            pd_island [list $left_x $pd_y [expr {$left_x + $pd_w}] [expr {$pd_y + $pd_h}]] \
            slow_phase_buffers [list $left_x $slow_buf_y [expr {$left_x + $left_w}] [expr {$slow_buf_y + $buf_h}]] \
            slow_ro [list $left_x $slow_ro_y [expr {$left_x + $ro_w}] [expr {$slow_ro_y + $ro_h}]] \
            backend_east [list $backend_x [expr {$lly + $edge}] $backend_urx [expr {$ury - $edge}]] \
        ]
    }

    set x0 0.0
    set y0 0.0
    set fast_ro_y $y0
    set fast_buf_y [expr {$fast_ro_y + $ro_h + $gap}]
    set pd_y [expr {$fast_buf_y + $buf_h + $gap}]
    set slow_buf_y [expr {$pd_y + $pd_h + $gap}]
    set slow_ro_y [expr {$slow_buf_y + $buf_h + $gap}]
    set east_x [expr {max($pd_w, $ro_w) + [mptdc_pnr_env MPTDC_PNR_BACKEND_GAP_UM 30.0]}]
    return [dict create \
        fast_ro [list $x0 $fast_ro_y [expr {$x0 + $ro_w}] [expr {$fast_ro_y + $ro_h}]] \
        fast_phase_buffers [list $x0 $fast_buf_y [expr {$x0 + $ro_w}] [expr {$fast_buf_y + $buf_h}]] \
        pd_island [list $x0 $pd_y [expr {$x0 + $pd_w}] [expr {$pd_y + $pd_h}]] \
        slow_phase_buffers [list $x0 $slow_buf_y [expr {$x0 + $ro_w}] [expr {$slow_buf_y + $buf_h}]] \
        slow_ro [list $x0 $slow_ro_y [expr {$x0 + $ro_w}] [expr {$slow_ro_y + $ro_h}]] \
        backend_east [list $east_x $fast_ro_y [expr {$east_x + [mptdc_pnr_env MPTDC_PNR_BACKEND_WIDTH_UM 220.0]}] [expr {$slow_ro_y + $ro_h}]] \
    ]
}

proc mptdc_pnr_sandwich_boxes {} {
    set regions [mptdc_pnr_floorplan_regions]
    set boxes [dict create]
    set core_box [mptdc_pnr_core_box]
    if {[mptdc_pnr_box_valid $core_box]} {
        dict set boxes core $core_box
    }
    foreach {legacy_key region_key} {
        fast fast_ro
        fast_buf fast_phase_buffers
        pd pd_island
        slow_buf slow_phase_buffers
        slow slow_ro
        backend backend_east
    } {
        if {[dict exists $regions $region_key]} {
            dict set boxes $legacy_key [dict get $regions $region_key]
        }
    }
    return $boxes
}

proc mptdc_pnr_auto_dimensions {} {
    set std_area [mptdc_pnr_env MPTDC_PNR_STDCELL_AREA_UM2 [mptdc_pnr_env MPTDC_PNR_MIN_STDCELL_AREA_UM2 0.0]]
    set util [mptdc_pnr_core_util_default]
    set ratio [mptdc_pnr_target_aspect_ratio]
    set guard [mptdc_pnr_env MPTDC_PNR_AREA_GUARD_BAND 1.20]
    set region_area 0.0
    dict for {name box} [mptdc_pnr_floorplan_regions] {
        set w [expr {[lindex $box 2] - [lindex $box 0]}]
        set h [expr {[lindex $box 3] - [lindex $box 1]}]
        set region_area [expr {$region_area + ($w * $h)}]
    }
    set cell_area [expr {$std_area > 0.0 ? ($std_area / $util) : 0.0}]
    set required_area [expr {max($region_area, $cell_area) * $guard}]
    if {$required_area <= 0.0} {
        set required_area 1.0
    }
    set height [expr {sqrt($required_area / $ratio)}]
    set width [expr {$height * $ratio}]
    return [dict create \
        width_um $width \
        height_um $height \
        aspect_ratio [expr {$width / $height}] \
        target_aspect_ratio $ratio \
        standard_cell_area_um2 $std_area \
        reserved_region_area_um2 $region_area \
        utilization $util \
        area_guard_band $guard]
}

proc mptdc_pnr_write_floorplan_intent {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_FLOORPLAN_REPORT mptdc_floorplan_intent.rpt]
    }
    set fh [open $path w]
    puts $fh "# MPTDC Final Typical Floorplan Intent"
    puts $fh "labels=[join [mptdc_pnr_floorplan_labels] { }]"
    puts $fh "core_utilization=[mptdc_pnr_core_util_default]"
    puts $fh "core_utilization_allowed=[mptdc_pnr_core_util_allowed_range]"
    puts $fh "core_utilization_max_first_run=[mptdc_pnr_core_util_max_first_run]"
    puts $fh "aspect_ratio_allowed=[mptdc_pnr_allowed_aspect_ratio_range]"
    puts $fh "order=[join [mptdc_pnr_floorplan_order] { -> }]"
    puts $fh "timing_protection_rules=[join [mptdc_pnr_floorplan_timing_protection_rules] {; }]"
    puts $fh ""
    dict for {name box} [mptdc_pnr_floorplan_regions] {
        puts $fh "$name=$box"
    }
    puts $fh ""
    dict for {name value} [mptdc_pnr_auto_dimensions] {
        puts $fh "auto_dimension_$name=$value"
    }
    close $fh
    return $path
}
