# =============================================================================
# MPTDC physical optimization effort policy
# =============================================================================

if {[llength [info commands mptdc_o10_env]] == 0} {
    proc mptdc_o10_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_pnr_physical_effort_enabled {} {
    return [mptdc_o10_env MPTDC_PNR_PHYSICAL_EFFORT_ENABLE 1]
}

proc mptdc_pnr_physical_effort_mode {} {
    return [mptdc_o10_env MPTDC_PNR_PHYSICAL_EFFORT_MODE closure]
}

proc mptdc_pnr_effort_try {fh label cmd} {
    puts $fh ""
    puts $fh "## $label"
    puts $fh "command=$cmd"
    if {![catch {{*}$cmd} err]} {
        puts $fh "status=OK"
        return 1
    }
    puts $fh "status=SKIPPED_OR_FAILED"
    puts $fh "reason=$err"
    return 0
}

proc mptdc_pnr_apply_physical_effort {stage} {
    global o10 pnr
    file mkdir $o10(reports_dir)

    set report "$o10(reports_dir)/physical_effort_${stage}.rpt"
    set fh [open $report w]
    puts $fh "# MPTDC Physical Effort Policy"
    puts $fh "stage=$stage"
    puts $fh "enabled=[mptdc_pnr_physical_effort_enabled]"
    puts $fh "mode=[mptdc_pnr_physical_effort_mode]"
    if {[info exists pnr(core_utilization)]} {
        puts $fh "core_utilization=$pnr(core_utilization)"
    }
    if {[info exists pnr(place_global_max_density)]} {
        puts $fh "place_global_max_density=$pnr(place_global_max_density)"
    }
    puts $fh "intent=high_effort_area_power_setup_hold_cts_route"
    puts $fh "note=unsupported Innovus switches are reported here and are not fatal"

    if {![mptdc_pnr_physical_effort_enabled]} {
        close $fh
        return $report
    }

    set density 0.70
    if {[info exists pnr(place_global_max_density)]} {
        set density $pnr(place_global_max_density)
    }
    set bottom_layer_idx 1
    set top_layer_idx 3
    set bottom_layer MET1
    set top_layer MET3
    if {[info exists pnr(signal_bottom_layer_idx)]} { set bottom_layer_idx $pnr(signal_bottom_layer_idx) }
    if {[info exists pnr(signal_top_layer_idx)]} { set top_layer_idx $pnr(signal_top_layer_idx) }
    if {[info exists pnr(signal_bottom_layer)]} { set bottom_layer $pnr(signal_bottom_layer) }
    if {[info exists pnr(signal_top_layer)]} { set top_layer $pnr(signal_top_layer) }

    set place_cmds [list \
        [list setPlaceMode -place_global_max_density $density] \
        [list setPlaceMode -place_global_effort high] \
        [list setPlaceMode -place_global_cong_effort high] \
        [list setPlaceMode -place_global_timing_effort high] \
        [list setPlaceMode -place_detail_eco_max_distance 20] \
    ]
    foreach cmd $place_cmds {
        mptdc_pnr_effort_try $fh place_mode $cmd
    }

    set opt_cmds [list \
        [list setOptMode -effort high] \
        [list setOptMode -setupTargetSlack 0.0] \
        [list setOptMode -holdTargetSlack 0.0] \
        [list setOptMode -fixFanoutLoad true] \
        [list setOptMode -fixDrc true] \
        [list setOptMode -powerEffort high] \
        [list setOptMode -leakageToDynamicRatio 0.5] \
    ]
    foreach cmd $opt_cmds {
        mptdc_pnr_effort_try $fh opt_mode $cmd
    }

    set route_cmds [list \
        [list setNanoRouteMode -routeBottomRoutingLayer $bottom_layer_idx] \
        [list setNanoRouteMode -routeTopRoutingLayer $top_layer_idx] \
        [list setNanoRouteMode -routeWithTimingDriven true] \
        [list setNanoRouteMode -routeWithSiDriven true] \
        [list setNanoRouteMode -drouteUseMultiCutViaEffort high] \
        [list setNanoRouteMode -routeWithViaInPin true] \
        [list setNanoRouteMode -drouteFixAntenna true] \
    ]
    foreach cmd $route_cmds {
        mptdc_pnr_effort_try $fh route_mode $cmd
    }

    set cts_cmds [list \
        [list set_ccopt_property target_skew 0.12] \
        [list set_ccopt_property target_max_trans 0.35] \
        [list set_ccopt_property route_top_layer $top_layer] \
        [list set_ccopt_property route_bottom_layer $bottom_layer] \
        [list setCTSMode -engine ccopt] \
        [list setCTSMode -effort high] \
    ]
    foreach cmd $cts_cmds {
        mptdc_pnr_effort_try $fh cts_mode $cmd
    }

    close $fh
    return $report
}
