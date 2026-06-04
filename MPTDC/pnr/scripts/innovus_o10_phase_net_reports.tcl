# =============================================================================
# O10 phase-net and PD reports
# =============================================================================

proc mptdc_o10_phase_patterns {} {
    set patterns [list]
    foreach family {slow fast} {
        for {set i 0} {$i < 8} {incr i} {
            lappend patterns "*${family}_phase\\[$i\\]*"
            lappend patterns "*u_osc_${family}*S\\[$i\\]*"
        }
    }
    return $patterns
}

proc mptdc_o10_write_phase_net_loads {} {
    global o10
    set fh [open "$o10(reports_dir)/phase_net_loads.csv" w]
    puts $fh "family,tap,net,fanout,total_cap,wire_cap,pin_cap,transition,route_length,notes"
    foreach family {slow fast} {
        for {set i 0} {$i < 8} {incr i} {
            set nets [mptdc_o10_collect_nets [list "*${family}_phase\\[$i\\]*" "*u_osc_${family}*S\\[$i\\]*"]]
            if {[llength $nets] == 0} {
                puts $fh "$family,$i,,0,,,,,,NO_NET_MATCH"
                continue
            }
            foreach net $nets {
                set obj [get_nets -quiet $net]
                set fanout ""; catch {set fanout [get_db $obj .num_loads]}
                set total_cap ""; catch {set total_cap [get_db $obj .total_capacitance]}
                set wire_cap ""; catch {set wire_cap [get_db $obj .wire_capacitance]}
                set pin_cap ""; catch {set pin_cap [get_db $obj .pin_capacitance]}
                set trans ""; catch {set trans [get_db $obj .transition]}
                set length ""; catch {set length [get_db $obj .route_length]}
                puts $fh "$family,$i,$net,$fanout,$total_cap,$wire_cap,$pin_cap,$trans,$length,"
            }
        }
    }
    close $fh
}

proc mptdc_o10_write_fast_tag_loads {} {
    global o10
    set fh [open "$o10(reports_dir)/fast_tag_loads.csv" w]
    puts $fh "column,bit,net,fanout,total_cap,wire_cap,pin_cap,transition,notes"
    for {set col 0} {$col < 8} {incr col} {
        for {set bit 0} {$bit < 7} {incr bit} {
            set nets [mptdc_o10_collect_nets [list "*gen_fast_tag_col\\[$col\\]*tag_o\\[$bit\\]*" "*fast_tag_col\\[$col\\]*\\[$bit\\]*"]]
            if {[llength $nets] == 0} {
                puts $fh "$col,$bit,,0,,,,,NO_NET_MATCH"
                continue
            }
            foreach net $nets {
                set obj [get_nets -quiet $net]
                set fanout ""; catch {set fanout [get_db $obj .num_loads]}
                set total_cap ""; catch {set total_cap [get_db $obj .total_capacitance]}
                set wire_cap ""; catch {set wire_cap [get_db $obj .wire_capacitance]}
                set pin_cap ""; catch {set pin_cap [get_db $obj .pin_capacitance]}
                set trans ""; catch {set trans [get_db $obj .transition]}
                puts $fh "$col,$bit,$net,$fanout,$total_cap,$wire_cap,$pin_cap,$trans,"
            }
        }
    }
    close $fh
}

proc mptdc_o10_phase_net_reports {} {
    global o10
    mptdc_o10_write_phase_net_loads
    mptdc_o10_write_fast_tag_loads

    if {[file exists "$o10(script_dir)/report_pd_instance_symmetry.tcl"]} {
        source "$o10(script_dir)/report_pd_instance_symmetry.tcl"
        catch {mptdc_osc_pd_report_instance_symmetry}
        catch {file copy -force "$o10(reports_dir)/pd_instance_symmetry_summary.md" "$o10(reports_dir)/pd_symmetry_summary.md"}
    }
    if {[file exists "$o10(script_dir)/report_pd_phase_routes.tcl"]} {
        source "$o10(script_dir)/report_pd_phase_routes.tcl"
        catch {mptdc_osc_pd_report_phase_routes}
    }
    if {[file exists "$o10(script_dir)/report_osc_tap_loads.tcl"]} {
        source "$o10(script_dir)/report_osc_tap_loads.tcl"
        catch {mptdc_osc_pd_report_tap_loads}
    }

    set fh [open "$o10(reports_dir)/phase_net_balance_summary.md" a]
    puts $fh ""
    puts $fh "## O10 Review"
    puts $fh ""
    puts $fh "- RO phase nets were not CTS trees in the intended flow."
    puts $fh "- Review `phase_net_loads.csv`, route length, fanout, cap, and phase0 extra load."
    puts $fh "- Do not add dummy load or buffering without analog/timing review."
    close $fh
    mptdc_o10_screenshot "07_phase_nets_highlight.png" "phase nets highlighted"
}
