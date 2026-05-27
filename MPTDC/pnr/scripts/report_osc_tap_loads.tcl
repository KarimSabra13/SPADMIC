# =============================================================================
# O0 oscillator tap load and nfast bus reports
# =============================================================================

proc mptdc_osc_pd_report_tap_loads {} {
    set out_dir [mptdc_osc_pd_result_dir]
    set csv "$out_dir/tap_loads.csv"
    set nfast_csv "$out_dir/nfast_count_bus_rc.csv"
    set summary "$out_dir/tap_load_balance_summary.md"

    set fh [open $csv w]
    puts $fh "family,tap_index,net,fanout,pd_load_count,counter_load_count,debug_metadata_load_count,extra_load_count,total_pin_cap_fF,total_wire_cap_fF,total_cap_fF,estimated_route_delay_ps,transition_ps,extra_load_notes"
    foreach family {slow fast} {
        for {set i 0} {$i < 8} {incr i} {
            set pattern "*${family}_phase\\[$i\\]*"
            set nets [mptdc_osc_pd_net_objects $pattern]
            if {[llength $nets] == 0} {
                puts $fh "$family,$i,,0,0,0,0,0,,,,,,NO_NET_MATCH"
                continue
            }
            foreach net $nets {
                set name [mptdc_osc_pd_net_attr $net .name]
                if {$name eq ""} { set name $net }
                set fanout [mptdc_osc_pd_net_attr $net .num_loads]
                set pin_cap [mptdc_osc_pd_net_attr $net .pin_capacitance]
                set wire_cap [mptdc_osc_pd_net_attr $net .wire_capacitance]
                set total_cap [mptdc_osc_pd_net_attr $net .total_capacitance]
                set delay [mptdc_osc_pd_net_attr $net .delay]
                set trans [mptdc_osc_pd_net_attr $net .transition]
                set loads [mptdc_osc_pd_net_attr $net .loads]
                set pd_count 0
                set counter_count 0
                set meta_count 0
                set notes [list]
                foreach load $loads {
                    set lname ""
                    catch {set lname [get_db $load .name]}
                    if {[string match *u_pd* $lname]} {
                        incr pd_count
                    } elseif {[string match *u_fast_cnt* $lname] || [string match *u_slow_cnt* $lname]} {
                        incr counter_count
                        lappend notes $lname
                    } elseif {[string match *u_stop_capture* $lname] || [string match *phase*guard* $lname] || [string match *phase7d* $lname]} {
                        incr meta_count
                        lappend notes $lname
                    }
                }
                set extra_count [expr {[llength $loads] - $pd_count}]
                puts $fh "$family,$i,$name,$fanout,$pd_count,$counter_count,$meta_count,$extra_count,$pin_cap,$wire_cap,$total_cap,$delay,$trans,[join $notes {|}]"
            }
        }
    }
    close $fh

    set nfh [open $nfast_csv w]
    puts $nfh "bit,net,fanout,total_cap_fF,wire_cap_fF,pin_cap_fF,estimated_delay_ps,transition_ps,wire_length_um,violations"
    for {set i 0} {$i < 8} {incr i} {
        set nets [mptdc_osc_pd_net_objects "*nfast_src_count\\[$i\\]*"]
        if {[llength $nets] == 0} {
            puts $nfh "$i,,0,,,,,,,NO_NET_MATCH"
            continue
        }
        foreach net $nets {
            set name [mptdc_osc_pd_net_attr $net .name]
            set fanout [mptdc_osc_pd_net_attr $net .num_loads]
            set total_cap [mptdc_osc_pd_net_attr $net .total_capacitance]
            set wire_cap [mptdc_osc_pd_net_attr $net .wire_capacitance]
            set pin_cap [mptdc_osc_pd_net_attr $net .pin_capacitance]
            set delay [mptdc_osc_pd_net_attr $net .delay]
            set trans [mptdc_osc_pd_net_attr $net .transition]
            set length [mptdc_osc_pd_net_attr $net .route_length]
            puts $nfh "$i,$name,$fanout,$total_cap,$wire_cap,$pin_cap,$delay,$trans,$length,"
        }
    }
    close $nfh

    set sfh [open $summary w]
    puts $sfh "# Oscillator Tap Load Balance Summary"
    puts $sfh ""
    puts $sfh "- Status: PROVISIONAL_REVIEW_REQUIRED"
    puts $sfh "- Tap CSV: tap_loads.csv"
    puts $sfh "- nfast bus CSV: nfast_count_bus_rc.csv"
    puts $sfh ""
    puts $sfh "Phase0 extra loads must be reviewed.  Do not add one-off digital buffers to phase0."
    close $sfh
}
