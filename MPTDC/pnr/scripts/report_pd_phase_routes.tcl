# =============================================================================
# O0 phase route RC/load report
# =============================================================================

proc mptdc_osc_pd_net_objects {pattern} {
    set nets [list]
    catch {set nets [get_nets -quiet -hierarchical $pattern]}
    return $nets
}

proc mptdc_osc_pd_net_attr {net attr} {
    if {[llength $net] == 0} {
        return ""
    }
    if {![catch {set val [get_db $net $attr]}]} {
        return $val
    }
    return ""
}

proc mptdc_osc_pd_emit_phase_row {fh family tap pattern} {
    set nets [mptdc_osc_pd_net_objects $pattern]
    if {[llength $nets] == 0} {
        puts $fh "$family,,${tap},,,,,,,,,,,,,,,,NO_NET_MATCH"
        return
    }
    foreach net $nets {
        set name [mptdc_osc_pd_net_attr $net .name]
        if {$name eq ""} { set name $net }
        set fanout [mptdc_osc_pd_net_attr $net .num_loads]
        if {$fanout eq ""} { set fanout [mptdc_osc_pd_net_attr $net .fanout] }
        set total_cap [mptdc_osc_pd_net_attr $net .total_capacitance]
        set wire_cap [mptdc_osc_pd_net_attr $net .wire_capacitance]
        set pin_cap [mptdc_osc_pd_net_attr $net .pin_capacitance]
        set res [mptdc_osc_pd_net_attr $net .resistance]
        set delay [mptdc_osc_pd_net_attr $net .delay]
        set trans [mptdc_osc_pd_net_attr $net .transition]
        set length [mptdc_osc_pd_net_attr $net .route_length]
        set vias [mptdc_osc_pd_net_attr $net .num_vias]
        set pd_loads ""
        set extra_loads ""
        set loads [mptdc_osc_pd_net_attr $net .loads]
        if {[llength $loads] > 0} {
            set pd_count 0
            foreach load $loads {
                set lname ""
                catch {set lname [get_db $load .name]}
                if {[string match *u_pd* $lname]} { incr pd_count }
            }
            set pd_loads $pd_count
            set extra_loads [expr {[llength $loads] - $pd_count}]
        }
        puts $fh "$family,$name,$tap,$total_cap,$wire_cap,$pin_cap,$res,$delay,$trans,$fanout,$pd_loads,$extra_loads,$length,,,,${vias},unknown,"
    }
}

proc mptdc_osc_pd_report_phase_routes {} {
    set out_dir [mptdc_osc_pd_result_dir]
    set csv "$out_dir/phase_net_rc.csv"
    set cell_csv "$out_dir/pd_cell_phase_rc.csv"
    set summary "$out_dir/phase_net_balance_summary.md"
    set fh [open $csv w]
    puts $fh "family,net,tap_index,total_cap_fF,wire_cap_fF,pin_cap_fF,total_res_ohm,estimated_delay_ps,transition_ps,fanout,pd_load_count,extra_load_count,wire_length_um,met1_um,met2_um,met3_um,mettp_um,via_count,shielded,violations"
    for {set i 0} {$i < 8} {incr i} {
        mptdc_osc_pd_emit_phase_row $fh slow $i "*slow_phase\\[$i\\]*"
    }
    for {set i 0} {$i < 8} {incr i} {
        mptdc_osc_pd_emit_phase_row $fh fast $i "*fast_phase\\[$i\\]*"
    }
    close $fh

    set cfh [open $cell_csv w]
    puts $cfh "pd_cell,ns,nf,slow_net,slow_delay_ps,slow_cap_fF,fast_net,fast_delay_ps,fast_cap_fF"
    foreach cell [lsort [mptdc_osc_pd_cells [list *gen_pd_row*gen_pd_col*u_pd*]]] {
        set ns ""
        set nf ""
        mptdc_osc_pd_parse_ns_nf $cell ns nf
        puts $cfh "$cell,$ns,$nf,slow_phase\\[$ns\\],,,fast_phase\\[$nf\\],,"
    }
    close $cfh

    set sfh [open $summary w]
    puts $sfh "# Phase Net Balance Summary"
    puts $sfh ""
    puts $sfh "- Status: PROVISIONAL_REVIEW_REQUIRED"
    puts $sfh "- CSV: phase_net_rc.csv"
    puts $sfh "- Per-cell CSV: pd_cell_phase_rc.csv"
    puts $sfh ""
    puts $sfh "Run tools/timing/analyze_pd_phase_routes.py after the snapshot is committed."
    close $sfh
}
