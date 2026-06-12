# =============================================================================
# Stable MPTDC final-typical route intent and report hooks
# =============================================================================

if {[llength [info commands mptdc_pnr_env]] == 0} {
    proc mptdc_pnr_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_pnr_route_signal_bottom_layer {} {
    return [mptdc_pnr_env MPTDC_PNR_SIGNAL_BOTTOM_LAYER MET1]
}

proc mptdc_pnr_route_signal_top_layer {} {
    return [mptdc_pnr_env MPTDC_PNR_SIGNAL_TOP_LAYER MET3]
}

proc mptdc_pnr_route_power_top_policy {} {
    return {reserve_top_metal_mainly_for_power}
}

proc mptdc_pnr_route_protection_rules {} {
    return [list \
        {do_not_false_path_fast_tag_to_pd_ts} \
        {do_not_multicycle_fast_tag_to_pd_ts} \
        {keep_fast_tag_bits_0_5_6_routes_short} \
        {avoid_wide_clk_sys_backend_routes_over_pd_island} \
        {do_not_buffer_raw_ro_nets} \
        {do_not_resize_or_replace_buhdx4_buhdx12_phase_root_drivers_without_review} \
        {use_m1_m2_m3_for_signal_routing} \
        [mptdc_pnr_route_power_top_policy] \
    ]
}

proc mptdc_pnr_write_route_intent {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_ROUTE_INTENT_REPORT mptdc_route_intent.rpt]
    }
    set fh [open $path w]
    puts $fh "# MPTDC Final Typical Route Intent"
    puts $fh "signal_bottom_layer=[mptdc_pnr_route_signal_bottom_layer]"
    puts $fh "signal_top_layer=[mptdc_pnr_route_signal_top_layer]"
    puts $fh "top_metal_policy=[mptdc_pnr_route_power_top_policy]"
    puts $fh "FAST_TAG_TO_PD_TS_TIMED=YES"
    puts $fh "FAST_TAG_TO_PD_TS_POSTROUTE_CLEAN=REVIEW_AFTER_ROUTE"
    puts $fh "route_length_report=reports/fast_tag_to_pd_route_lengths.csv"
    puts $fh "timing_report=reports/fast_tag_to_pd_timing_post_route.rpt"
    puts $fh "rules=[join [mptdc_pnr_route_protection_rules] {; }]"
    close $fh
    return $path
}

proc mptdc_pnr_apply_route_layer_limits {} {
    set bottom [mptdc_pnr_route_signal_bottom_layer]
    set top [mptdc_pnr_route_signal_top_layer]
    catch {setNanoRouteMode -routeBottomRoutingLayer $bottom}
    catch {setNanoRouteMode -routeTopRoutingLayer $top}
    return [list bottom $bottom top $top]
}

proc mptdc_pnr_write_fast_tag_route_lengths_template {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_FAST_TAG_ROUTE_LENGTHS reports/fast_tag_to_pd_route_lengths.csv]
    }
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "tap,bit,source register,endpoint PD cell,endpoint row,endpoint col,route length,cap,transition,slack,path class"
    puts $fh "NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,REPORT_AFTER_ROUTE"
    close $fh
    return $path
}

proc mptdc_pnr_write_fast_tag_timing_template {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_FAST_TAG_TIMING_REPORT reports/fast_tag_to_pd_timing_post_route.rpt]
    }
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "FAST_TAG_TO_PD_TS_POSTROUTE_CLEAN=REVIEW_AFTER_ROUTE"
    puts $fh "FAST_TAG_TO_PD_TS_FALSE_PATH=NO"
    puts $fh "FAST_TAG_TO_PD_TS_MULTICYCLE=NO"
    puts $fh {required_path=fast_tag_col[nf][bit] -> PD nfast_hit_latched[bit]}
    close $fh
    return $path
}
