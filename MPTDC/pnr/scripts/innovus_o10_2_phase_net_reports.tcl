# =============================================================================
# O10.2 phase-net, fast-tag, and PD reports
# =============================================================================

proc mptdc_o10_csv {value} {
    set text "$value"
    regsub -all {"} $text {""} text
    if {[regexp {[,"
]} $text]} {
        return "\"$text\""
    }
    return $text
}

proc mptdc_o10_net_attr {net attr} {
    if {[llength $net] == 0} { return "" }
    if {![catch {set val [get_db $net $attr]}]} { return $val }
    return ""
}

proc mptdc_o10_net_name {net} {
    set name [mptdc_o10_net_attr $net .name]
    if {$name ne ""} { return $name }
    if {![catch {set name [get_object_name $net]}]} { return $name }
    return "$net"
}

proc mptdc_o10_all_net_objects {} {
    set nets [list]
    if {[catch {set nets [get_nets -quiet -hierarchical *]}]} {
        catch {set nets [get_nets *]}
    }
    return $nets
}

proc mptdc_o10_classify_phase_net_name {name} {
    if {[regexp {(^|[/_])((slow|fast)_phase)\[([0-9]+)\]} $name -> sep bus family tap]} {
        return [list $family $tap]
    }
    if {[regexp {u_osc_(slow|fast).*S\[([0-9]+)\]} $name -> family tap]} {
        return [list $family $tap]
    }
    if {[regexp {u_osc_(slow|fast).*_S_([0-9]+)(_|$)} $name -> family tap]} {
        return [list $family $tap]
    }
    return [list "" ""]
}

proc mptdc_o10_classify_fast_tag_net_name {name} {
    if {[regexp {gen_fast_tag_col\[([0-9]+)\].*tag_o\[([0-9]+)\]} $name -> col bit]} {
        return [list $col $bit]
    }
    if {[regexp {fast_tag_col\[([0-9]+)\].*\[([0-9]+)\]} $name -> col bit]} {
        return [list $col $bit]
    }
    if {[regexp {gen_fast_tag_col_([0-9]+).*tag_o(_reg)?_([0-9]+)(_|$)} $name -> col unused bit]} {
        return [list $col $bit]
    }
    if {[regexp {fast_tag_col_([0-9]+).*_([0-9]+)(_|$)} $name -> col bit unused]} {
        return [list $col $bit]
    }
    return [list "" ""]
}

proc mptdc_o10_net_load_counts {net} {
    set loads [mptdc_o10_net_attr $net .loads]
    set pd 0
    set tag 0
    set ro 0
    set other 0
    set names [list]
    foreach load $loads {
        set lname ""
        catch {set lname [get_db $load .name]}
        if {$lname eq ""} { set lname "$load" }
        lappend names $lname
        if {[string match *u_pd* $lname]} {
            incr pd
        } elseif {[string match *fast_tag* $lname] || [string match *tag_o* $lname]} {
            incr tag
        } elseif {[string match *ro_tune4* $lname] || [string match *RO_tune4* $lname]} {
            incr ro
        } else {
            incr other
        }
    }
    return [list $pd $tag $ro $other [join [lrange $names 0 31] ";"]]
}

proc mptdc_o10_write_error_csv {path header msg} {
    set fh [open $path w]
    puts $fh $header
    puts $fh "ERROR,[mptdc_o10_csv $msg]"
    close $fh
}

proc mptdc_o10_write_phase_net_loads {} {
    global o10
    set path "$o10(reports_dir)/phase_net_loads.csv"
    set fh [open $path w]
    puts $fh "family,tap,net,fanout,total_cap,wire_cap,pin_cap,transition,route_length,pd_load_count,tag_load_count,ro_load_count,other_load_count,sinks,notes"

    array set seen {}
    array set rows {}
    foreach net [mptdc_o10_all_net_objects] {
        set name [mptdc_o10_net_name $net]
        set key [mptdc_o10_classify_phase_net_name $name]
        set family [lindex $key 0]
        set tap [lindex $key 1]
        if {$family eq "" || $tap eq "" || $tap < 0 || $tap > 7} {
            continue
        }
        set fanout [mptdc_o10_net_attr $net .num_loads]
        if {$fanout eq ""} { set fanout [mptdc_o10_net_attr $net .fanout] }
        set total_cap [mptdc_o10_net_attr $net .total_capacitance]
        set wire_cap [mptdc_o10_net_attr $net .wire_capacitance]
        set pin_cap [mptdc_o10_net_attr $net .pin_capacitance]
        set trans [mptdc_o10_net_attr $net .transition]
        set length [mptdc_o10_net_attr $net .route_length]
        set counts [mptdc_o10_net_load_counts $net]
        set row [join [list \
            $family $tap [mptdc_o10_csv $name] $fanout $total_cap $wire_cap $pin_cap $trans $length \
            [lindex $counts 0] [lindex $counts 1] [lindex $counts 2] [lindex $counts 3] \
            [mptdc_o10_csv [lindex $counts 4]] ""] ","]
        lappend rows($family,$tap) $row
        set seen($family,$tap) 1
    }

    foreach family {slow fast} {
        for {set i 0} {$i < 8} {incr i} {
            if {[info exists rows($family,$i)]} {
                foreach row $rows($family,$i) { puts $fh $row }
            } else {
                puts $fh "$family,$i,,0,,,,,,,,,,NO_NET_MATCH"
            }
        }
    }
    close $fh
}

proc mptdc_o10_write_fast_tag_loads {} {
    global o10
    set path "$o10(reports_dir)/fast_tag_loads.csv"
    set fh [open $path w]
    puts $fh "column,bit,net,fanout,total_cap,wire_cap,pin_cap,transition,pd_load_count,tag_load_count,ro_load_count,other_load_count,sinks,notes"

    array set rows {}
    foreach net [mptdc_o10_all_net_objects] {
        set name [mptdc_o10_net_name $net]
        set key [mptdc_o10_classify_fast_tag_net_name $name]
        set col [lindex $key 0]
        set bit [lindex $key 1]
        if {$col eq "" || $bit eq "" || $col < 0 || $col > 7 || $bit < 0 || $bit > 6} {
            continue
        }
        set fanout [mptdc_o10_net_attr $net .num_loads]
        if {$fanout eq ""} { set fanout [mptdc_o10_net_attr $net .fanout] }
        set total_cap [mptdc_o10_net_attr $net .total_capacitance]
        set wire_cap [mptdc_o10_net_attr $net .wire_capacitance]
        set pin_cap [mptdc_o10_net_attr $net .pin_capacitance]
        set trans [mptdc_o10_net_attr $net .transition]
        set counts [mptdc_o10_net_load_counts $net]
        set row [join [list \
            $col $bit [mptdc_o10_csv $name] $fanout $total_cap $wire_cap $pin_cap $trans \
            [lindex $counts 0] [lindex $counts 1] [lindex $counts 2] [lindex $counts 3] \
            [mptdc_o10_csv [lindex $counts 4]] ""] ","]
        lappend rows($col,$bit) $row
    }

    for {set col 0} {$col < 8} {incr col} {
        for {set bit 0} {$bit < 7} {incr bit} {
            if {[info exists rows($col,$bit)]} {
                foreach row $rows($col,$bit) { puts $fh $row }
            } else {
                puts $fh "$col,$bit,,0,,,,,,,,,NO_NET_MATCH"
            }
        }
    }
    close $fh
}

proc mptdc_o10_write_load_summaries {} {
    global o10
    set phase_csv "$o10(reports_dir)/phase_net_loads.csv"
    set fast_csv "$o10(reports_dir)/fast_tag_loads.csv"

    set sfh [open "$o10(reports_dir)/phase_net_balance_summary.md" w]
    puts $sfh "# O10.2 Phase Net Balance Summary"
    puts $sfh ""
    puts $sfh "- Status: REVIEW_REQUIRED"
    puts $sfh "- CSV: `phase_net_loads.csv`"
    puts $sfh "- Required review: fanout, cap, route length, sink class, and phase0 extra load."
    puts $sfh "- RO phase max-cap violations are not waived by this report."
    if {[file exists $phase_csv]} {
        set text [read [open $phase_csv r]]
        puts $sfh "- Rows with `NO_NET_MATCH`: [regexp -all {NO_NET_MATCH} $text]"
        puts $sfh "- Rows with `ERROR`: [regexp -all {^ERROR,} $text]"
    }
    close $sfh

    set ffh [open "$o10(reports_dir)/fast_tag_load_balance_summary.md" w]
    puts $ffh "# O10.2 Fast Tag Load Balance Summary"
    puts $ffh ""
    puts $ffh "- Status: REVIEW_REQUIRED"
    puts $ffh "- CSV: `fast_tag_loads.csv`"
    puts $ffh "- Required review: residual `FAST_TAG_TO_PD_TS` column load after route."
    if {[file exists $fast_csv]} {
        set text [read [open $fast_csv r]]
        puts $ffh "- Rows with `NO_NET_MATCH`: [regexp -all {NO_NET_MATCH} $text]"
        puts $ffh "- Rows with `ERROR`: [regexp -all {^ERROR,} $text]"
    }
    close $ffh
}

proc mptdc_o10_phase_net_reports {} {
    global o10
    if {[catch {mptdc_o10_write_phase_net_loads} err]} {
        mptdc_o10_write_error_csv "$o10(reports_dir)/phase_net_loads.csv" \
            "family,tap,net,fanout,total_cap,wire_cap,pin_cap,transition,route_length,pd_load_count,tag_load_count,ro_load_count,other_load_count,sinks,notes" $err
    }
    if {[catch {mptdc_o10_write_fast_tag_loads} err]} {
        mptdc_o10_write_error_csv "$o10(reports_dir)/fast_tag_loads.csv" \
            "column,bit,net,fanout,total_cap,wire_cap,pin_cap,transition,pd_load_count,tag_load_count,ro_load_count,other_load_count,sinks,notes" $err
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
            puts $fh "instance,ns,nf,x_um,y_um,llx_um,lly_um,urx_um,ury_um,orientation,width_um,height_um,master,parent,placement_status,row,col,expected_x_um,expected_y_um,dx_um,dy_um,status"
            puts $fh "ERROR,,,,,,,,,,,,,,,,,,,,[mptdc_o10_csv $err]"
            close $fh
            set sfh [open "$o10(reports_dir)/pd_symmetry_summary.md" w]
            puts $sfh "# PD Instance Symmetry Summary"
            puts $sfh ""
            puts $sfh "REPORT_STATUS=FAILED"
            puts $sfh ""
            puts $sfh "$err"
            close $sfh
        }
    }

    mptdc_o10_write_load_summaries

    if {[file exists "$o10(script_dir)/report_pd_phase_routes.tcl"]} {
        catch {
            source "$o10(script_dir)/report_pd_phase_routes.tcl"
            mptdc_osc_pd_report_phase_routes
        } err
    }
    mptdc_o10_screenshot "07_phase_nets_highlight.png" "phase nets highlighted"
}
