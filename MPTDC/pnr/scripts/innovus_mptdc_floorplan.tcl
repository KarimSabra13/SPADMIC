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
    set pd_w [mptdc_pnr_env MPTDC_PNR_PD_REGION_WIDTH_UM 300.0]
    set pd_h [mptdc_pnr_env MPTDC_PNR_PD_REGION_HEIGHT_UM 300.0]
    set ro_w [mptdc_pnr_env MPTDC_PNR_OSC_WIDTH_UM 300.0]
    set ro_h [mptdc_pnr_env MPTDC_PNR_OSC_HEIGHT_UM 100.0]
    set gap  [mptdc_pnr_env MPTDC_PNR_PD_OSC_GAP_UM 20.0]
    set buf_h [mptdc_pnr_env MPTDC_PNR_PHASE_BUFFER_ROW_HEIGHT_UM 20.0]
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
    puts $fh "order=[join [mptdc_pnr_floorplan_order] { -> }]"
    puts $fh "timing_protection_rules=[join [mptdc_pnr_floorplan_timing_protection_rules] {; }]"
    puts $fh ""
    dict for {name box} [mptdc_pnr_floorplan_regions] {
        puts $fh "$name=$box"
    }
    close $fh
    return $path
}
