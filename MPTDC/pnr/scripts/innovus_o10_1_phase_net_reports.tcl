# =============================================================================
# O10.1 phase-net, fast-tag, and PD reports
# =============================================================================

proc mptdc_o10_bus_glob {prefix idx suffix} {
    return [format "%s\\[%d\\]%s" $prefix $idx $suffix]
}

proc mptdc_o10_phase_net_patterns {family idx} {
    set p1 [format "*%s_phase\\[%d\\]*" $family $idx]
    set p2 [format "*u_osc_%s*S\\[%d\\]*" $family $idx]
    return [list $p1 $p2]
}

proc mptdc_o10_fast_tag_patterns {col bit} {
    set p1 [format "*gen_fast_tag_col\\[%d\\]*tag_o\\[%d\\]*" $col $bit]
    set p2 [format "*fast_tag_col\\[%d\\]*\\[%d\\]*" $col $bit]
    return [list $p1 $p2]
}

proc mptdc_o10_write_error_csv {path header msg} {
    set fh [open $path w]
    puts $fh $header
    puts $fh "ERROR,,,,,,,,,$msg"
    close $fh
}

proc mptdc_o10_write_phase_net_loads {} {
    global o10
    set fh [open "$o10(reports_dir)/phase_net_loads.csv" w]
    puts $fh "family,tap,net,fanout,total_cap,wire_cap,pin_cap,transition,route_length,notes"
    foreach family {slow fast} {
        for {set i 0} {$i < 8} {incr i} {
            set nets [mptdc_o10_collect_nets [mptdc_o10_phase_net_patterns $family $i]]
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
            set nets [mptdc_o10_collect_nets [mptdc_o10_fast_tag_patterns $col $bit]]
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
    if {[catch {mptdc_o10_write_phase_net_loads} err]} {
        mptdc_o10_write_error_csv "$o10(reports_dir)/phase_net_loads.csv" \
            "family,tap,net,fanout,total_cap,wire_cap,pin_cap,transition,route_length,notes" $err
    }
    if {[catch {mptdc_o10_write_fast_tag_loads} err]} {
        mptdc_o10_write_error_csv "$o10(reports_dir)/fast_tag_loads.csv" \
            "column,bit,net,fanout,total_cap,wire_cap,pin_cap,transition,notes" $err
    }

    set pd_status "not_run"
    if {[file exists "$o10(script_dir)/report_pd_instance_symmetry.tcl"]} {
        if {[catch {
            source "$o10(script_dir)/report_pd_instance_symmetry.tcl"
            mptdc_osc_pd_report_instance_symmetry
            file copy -force "$o10(reports_dir)/pd_instance_symmetry_summary.md" "$o10(reports_dir)/pd_symmetry_summary.md"
        } err]} {
            set pd_status $err
            set fh [open "$o10(reports_dir)/pd_instance_placement.csv" w]
            puts $fh "instance,ns,nf,x_um,y_um,orientation,width_um,height_um,master,parent,placement_status,row,col,expected_x_um,expected_y_um,dx_um,dy_um"
            puts $fh "ERROR,,,,,,,,,,,,,,,,$err"
            close $fh
            set sfh [open "$o10(reports_dir)/pd_symmetry_summary.md" w]
            puts $sfh "# PD Instance Symmetry Summary"
            puts $sfh ""
            puts $sfh "FAILED: $err"
            close $sfh
        }
    }

    set fh [open "$o10(reports_dir)/phase_net_balance_summary.md" a]
    puts $fh "# O10.1 Phase Net Balance Summary"
    puts $fh ""
    puts $fh "- RO phase nets must not be CTS trees."
    puts $fh "- Review `phase_net_loads.csv`, route length, fanout, cap, and phase0 extra load."
    puts $fh "- Review `fast_tag_loads.csv` for residual FAST_TAG_TO_PD_TS load context."
    puts $fh "- PD report status: $pd_status"
    puts $fh "- Do not add dummy load or buffering without analog/timing review."
    close $fh

    if {[file exists "$o10(script_dir)/report_pd_phase_routes.tcl"]} {
        catch {
            source "$o10(script_dir)/report_pd_phase_routes.tcl"
            mptdc_osc_pd_report_phase_routes
        } err
    }
    mptdc_o10_screenshot "07_phase_nets_highlight.png" "phase nets highlighted"
}
