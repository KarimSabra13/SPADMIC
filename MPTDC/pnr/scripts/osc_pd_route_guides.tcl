# =============================================================================
# O0 oscillator/PD route-guide intent
# =============================================================================

proc mptdc_osc_pd_apply_route_guides {} {
    global pnr
    set out_dir [mptdc_osc_pd_result_dir]
    set rpt "$out_dir/osc_pd_route_guides.rpt"
    set fh [open $rpt w]
    puts $fh "MPTDC O0 oscillator/PD route-guide intent"
    puts $fh "========================================"
    puts $fh "Generated: [mptdc_osc_pd_timestamp]"
    puts $fh "Status: PROVISIONAL - NOT ANALOG VERIFIED"
    puts $fh ""

    set phase_nets [mptdc_pnr_collect_nets [mptdc_pnr_phase_net_patterns]]
    puts $fh "Matched phase nets: [llength $phase_nets]"
    foreach net [lsort $phase_nets] {
        puts $fh "NET $net"
        set objs [list]
        catch {set objs [get_nets -quiet $net]}
        foreach cmd [list \
            [list set_db $objs .top_preferred_routing_layer $pnr(phase_route_top_layer)] \
            [list set_db $objs .bottom_preferred_routing_layer $pnr(signal_bottom_layer)] \
            [list setAttribute -net $net -top_preferred_routing_layer $pnr(phase_route_top_layer)] \
        ] {
            if {[llength $objs] == 0 && [lindex $cmd 0] eq "set_db"} {
                continue
            }
            if {![catch {uplevel 1 $cmd} err]} {
                puts $fh "  applied: $cmd"
            } else {
                puts $fh "  skipped: $cmd"
                puts $fh "    $err"
            }
        }
    }

    set boxes [mptdc_pnr_sandwich_boxes]
    if {[dict exists $boxes pd]} {
        set pd_box [dict get $boxes pd]
        set llx [lindex $pd_box 0]
        set lly [lindex $pd_box 1]
        set urx [lindex $pd_box 2]
        set ury [lindex $pd_box 3]
        foreach cmd [list \
            [list createRouteBlk -name mptdc_o0_pd_no_random_digital_routes -box $llx $lly $urx $ury -layer {MET1 MET2}] \
            [list createRouteBlk -box [list $llx $lly $urx $ury] -layer {MET1 MET2}] \
        ] {
            if {![catch {uplevel 1 $cmd} err]} {
                puts $fh "Applied local route blockage/guide candidate: $cmd"
                break
            } else {
                puts $fh "Route blockage candidate skipped: $cmd"
                puts $fh "  $err"
            }
        }
    }

    puts $fh ""
    puts $fh "Policy reminders:"
    puts $fh "- Do not route normal backend buses through the phase-routing area unless unavoidable."
    puts $fh "- Do not insert one-off buffers on phase0.  Use analog-approved symmetric structures only."
    puts $fh "- Detailed extracted RC reports, not this route intent alone, determine O0 physical status."
    close $fh
}
