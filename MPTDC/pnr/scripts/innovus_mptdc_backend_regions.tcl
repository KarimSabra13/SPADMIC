# =============================================================================
# Stable MPTDC backend region and IO-side intent
# =============================================================================

if {[llength [info commands mptdc_pnr_env]] == 0} {
    proc mptdc_pnr_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_pnr_backend_region_name {} {
    return clk_sys_control_fifo_readout_east
}

proc mptdc_pnr_backend_region_rules {} {
    return [list \
        {place_context_bank_drain_readout_fifo_csr_control_acq_interface_east} \
        {avoid_wide_clk_sys_backend_buses_over_pd_island} \
        {route_clk_sys_control_away_from_phase_island_when_possible} \
        {separate_io_timing_from_internal_core_timing} \
    ]
}

proc mptdc_pnr_io_side_for_port {port_name} {
    if {[regexp {^(spad|cal|async|stop|start)} $port_name]} {
        return west
    }
    if {[regexp {^(acq_|csr_|status|fifo|rd_|read|ctrl)} $port_name]} {
        return east
    }
    if {[regexp {^narrow_} $port_name]} {
        return east_low_priority
    }
    if {[regexp {^(clk_sys|rst|reset)} $port_name]} {
        return east_control
    }
    return review
}

proc mptdc_pnr_write_backend_region_intent {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_BACKEND_REGION_REPORT mptdc_backend_regions.rpt]
    }
    set fh [open $path w]
    puts $fh "# MPTDC Backend Region Intent"
    puts $fh "region=[mptdc_pnr_backend_region_name]"
    puts $fh "east_logic=clk_sys control FIFO CSR readout acquisition status"
    puts $fh "west_logic=SPAD calibration asynchronous inputs"
    puts $fh "narrow_outputs=legacy_low_priority"
    puts $fh "chip_visible_tx=outside_mptdc_block"
    puts $fh "rules=[join [mptdc_pnr_backend_region_rules] {; }]"
    close $fh
    return $path
}
