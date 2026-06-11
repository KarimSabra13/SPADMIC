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

proc mptdc_o10_unique_append {var_name value} {
    upvar 1 $var_name values
    if {$value eq ""} { return }
    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}

proc mptdc_o10_sdc_object_names {objects} {
    set names [list]
    if {[llength $objects] == 0} {
        return $names
    }
    if {![catch {get_object_name $objects} obj_names]} {
        foreach name $obj_names {
            mptdc_o10_unique_append names $name
        }
        return $names
    }
    foreach obj $objects {
        mptdc_o10_unique_append names "$obj"
    }
    return $names
}

proc mptdc_o10_exact_pin_names {candidates} {
    set pins [list]
    foreach candidate $candidates {
        set matches [list]
        catch {set matches [get_pins -quiet $candidate]}
        foreach pin [mptdc_o10_sdc_object_names $matches] {
            mptdc_o10_unique_append pins $pin
        }
        set matches [list]
        catch {set matches [get_pins -quiet -hierarchical $candidate]}
        foreach pin [mptdc_o10_sdc_object_names $matches] {
            mptdc_o10_unique_append pins $pin
        }
    }
    return $pins
}

proc mptdc_o10_ro_source_pin_candidates {family tap} {
    return [list \
        [format {u_core/u_osc_%s/u_ro_tune4/S[%d]} $family $tap] \
        [format {u_core_u_osc_%s_u_ro_tune4/S[%d]} $family $tap]]
}

proc mptdc_o10_net_names_from_pin {pin_name} {
    set pins [list]
    catch {set pins [get_pins -quiet $pin_name]}
    if {[llength $pins] == 0} {
        catch {set pins [get_pins -quiet -hierarchical $pin_name]}
    }
    if {[llength $pins] == 0} {
        set pins [list $pin_name]
    }

    set net_names [list]
    foreach pin_obj $pins {
        set nets [list]
        catch {set nets [get_nets -quiet -of_objects $pin_obj]}
        foreach net [mptdc_o10_sdc_object_names $nets] {
            mptdc_o10_unique_append net_names $net
        }
    }
    return $net_names
}

proc mptdc_o10_pin_names_from_net {net_name source_pin} {
    set nets [list]
    catch {set nets [get_nets -quiet $net_name]}
    if {[llength $nets] == 0} {
        catch {set nets [get_nets -quiet -hierarchical $net_name]}
    }
    if {[llength $nets] == 0} {
        set nets [list $net_name]
    }

    set pins [list]
    foreach net_obj $nets {
        set matches [list]
        catch {set matches [get_pins -quiet -of_objects $net_obj]}
        foreach pin [mptdc_o10_sdc_object_names $matches] {
            if {$pin ne $source_pin} {
                mptdc_o10_unique_append pins $pin
            }
        }
        set ports [list]
        catch {set ports [get_ports -quiet -of_objects $net_obj]}
        foreach port [mptdc_o10_sdc_object_names $ports] {
            mptdc_o10_unique_append pins $port
        }
    }
    return $pins
}

proc mptdc_o10_pf_to_ff {value} {
    if {![string is double -strict $value]} { return "" }
    return [format "%.2f" [expr {$value * 1000.0}]]
}

proc mptdc_o10_ratio {value denom} {
    if {![string is double -strict $value] || $denom <= 0.0} { return "" }
    return [format "%.2f" [expr {$value / $denom}]]
}

proc mptdc_o10_budget_label {cap_ff} {
    if {![string is double -strict $cap_ff]} { return "UNKNOWN" }
    if {$cap_ff <= 58.72} { return "OK_STRICT" }
    if {$cap_ff <= 75.59} { return "OK_CN" }
    if {$cap_ff <= 150.0} { return "WARN_OVER_CN" }
    if {$cap_ff <= 300.0} { return "FAIL_HIGH_LOAD" }
    return "CRITICAL"
}

proc mptdc_o10_sink_class {family sink_name} {
    if {$family eq "fast" && [regexp {gen_pd_row(\[[0-9]+\]|_[0-9]+).*gen_pd_col(\[[0-9]+\]|_[0-9]+).*u_pd.*/(C|CK|CLK)$} $sink_name]} {
        return "PD_FAST_CLOCK"
    }
    if {$family eq "fast" && [regexp {gen_fast_tag_col(\[[0-9]+\]|_[0-9]+).*u_fast_tag.*_reg(\[[0-9]+\])?/(C|CK|CLK)$} $sink_name]} {
        return "FAST_TAG_CLOCK"
    }
    if {$family eq "slow" && [regexp {slow_epoch.*_reg(\[[0-9]+\])?/(C|CK|CLK)$} $sink_name]} {
        return "SLOW_EPOCH_CLOCK"
    }
    if {[string match *u_pd*slow_phase* $sink_name]} {
        return "PD_SLOW_DATA"
    }
    if {[string match *u_pd*fast_phase* $sink_name]} {
        return "PD_FAST_CLOCK"
    }
    if {[string match *u_fast_tag*clk_fast* $sink_name] || [string match *fast_tag*clk* $sink_name]} {
        return "FAST_TAG_CLOCK"
    }
    if {[string match *u_slow_epoch*clk_slow* $sink_name]} {
        return "SLOW_EPOCH_CLOCK"
    }
    if {[string match *u_stop_capture* $sink_name] || [string match *phase0* $sink_name] || [string match *phase7d* $sink_name]} {
        return "BOUNDARY_METADATA"
    }
    if {[string match *fast_tag* $sink_name] || [string match *nfast_tag* $sink_name]} {
        return "FAST_TAG_DATA"
    }
    if {[regexp {/(C|CK|CLK)$} $sink_name] || [string match *clk* $sink_name] || [string match *clock* $sink_name]} {
        if {$family eq "fast"} { return "OTHER_CLOCK_LIKE" }
        return "OTHER_CLOCK_OR_METADATA"
    }
    return "OTHER"
}

proc mptdc_o10_count_classes {class_list} {
    array set counts {
        PD_SLOW_DATA 0
        PD_FAST_CLOCK 0
        FAST_TAG_CLOCK 0
        SLOW_EPOCH_CLOCK 0
        BOUNDARY_METADATA 0
        FAST_TAG_DATA 0
        OTHER_CLOCK_LIKE 0
        OTHER_CLOCK_OR_METADATA 0
        OTHER 0
    }
    foreach class $class_list {
        if {![info exists counts($class)]} {
            set counts($class) 0
        }
        incr counts($class)
    }
    return [array get counts]
}

proc mptdc_o10_read_drv_max_cap {path} {
    set caps [dict create]
    if {![file exists $path]} { return $caps }
    set fh [open $path r]
    set text [read $fh]
    close $fh

    foreach line [split $text "\n"] {
        if {[string first "|" $line] < 0} { continue }
        set fields [split $line "|"]
        if {[llength $fields] < 4} { continue }
        set pin [string trim [lindex $fields 1]]
        set required [string trim [lindex $fields 2]]
        set actual [string trim [lindex $fields 3]]
        if {$pin eq "" || ![string is double -strict $required] || ![string is double -strict $actual]} {
            continue
        }
        dict set caps $pin [list $required $actual]
    }
    return $caps
}

proc mptdc_o10_ensure_drv_max_cap_report {} {
    global o10
    set path "$o10(reports_dir)/drv_max_cap.rpt"
    if {[file exists $path] && [file size $path] > 0} {
        return
    }
    catch {
        mptdc_o10_capture_candidates $path \
            "O10.2 max capacitance" [list {report_constraint -max_capacitance -all_violators} {report_constraint -all_violators}]
    }
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

proc mptdc_o10_write_ro_source_pin_loads {} {
    global o10
    mptdc_o10_ensure_drv_max_cap_report
    set drv_caps [mptdc_o10_read_drv_max_cap "$o10(reports_dir)/drv_max_cap.rpt"]

    set phase_fh [open "$o10(reports_dir)/phase_net_loads.csv" w]
    puts $phase_fh "family,tap,source_pin,matched_source_pin_count,net,fanout,total_cap_pf,total_cap_ff,pd_slow_data_load_count,pd_fast_clock_load_count,fast_tag_clock_load_count,slow_epoch_clock_load_count,boundary_metadata_load_count,fast_tag_data_load_count,other_clock_like_load_count,other_load_count,budget_label,strict_ratio,cn_ratio,sinks,notes"

    set fast_fh [open "$o10(reports_dir)/fast_tag_loads.csv" w]
    puts $fast_fh "tap,source_pin,net,fanout,total_cap_pf,total_cap_ff,fast_tag_clock_load_count,pd_fast_clock_load_count,other_clock_like_load_count,budget_label,strict_ratio,cn_ratio,fast_tag_clock_sinks,notes"

    set sink_fh [open "$o10(reports_dir)/ro_phase_sink_classification.csv" w]
    puts $sink_fh "family,tap,source_pin,net,sink_pin,sink_class"

    array set label_counts {}
    foreach family {slow fast} {
        for {set tap 0} {$tap < 8} {incr tap} {
            set candidates [mptdc_o10_ro_source_pin_candidates $family $tap]
            set pins [mptdc_o10_exact_pin_names $candidates]
            if {[llength $pins] == 0} {
                set note "NO_SOURCE_PIN_MATCH candidates=[join $candidates {|}]"
                puts $phase_fh [join [list $family $tap "" 0 "" 0 "" "" 0 0 0 0 0 0 0 0 UNKNOWN "" "" "" [mptdc_o10_csv $note]] ","]
                if {$family eq "fast"} {
                    puts $fast_fh [join [list $tap "" "" 0 "" "" 0 0 0 UNKNOWN "" "" "" [mptdc_o10_csv $note]] ","]
                }
                continue
            }

            set source_pin [lindex $pins 0]
            set net_names [mptdc_o10_net_names_from_pin $source_pin]
            if {[llength $net_names] == 0} {
                set note "NO_NET_FROM_PIN matched_pins=[join $pins {|}]"
                puts $phase_fh [join [list $family $tap [mptdc_o10_csv $source_pin] [llength $pins] "" 0 "" "" 0 0 0 0 0 0 0 0 UNKNOWN "" "" "" [mptdc_o10_csv $note]] ","]
                if {$family eq "fast"} {
                    puts $fast_fh [join [list $tap [mptdc_o10_csv $source_pin] "" 0 "" "" 0 0 0 UNKNOWN "" "" "" [mptdc_o10_csv $note]] ","]
                }
                continue
            }

            set net_name [lindex $net_names 0]
            set total_cap ""
            if {[dict exists $drv_caps $source_pin]} {
                set cap_row [dict get $drv_caps $source_pin]
                set total_cap [lindex $cap_row 1]
            }
            set total_cap_ff [mptdc_o10_pf_to_ff $total_cap]
            set label [mptdc_o10_budget_label $total_cap_ff]
            if {![info exists label_counts($label)]} { set label_counts($label) 0 }
            incr label_counts($label)

            set sink_names [mptdc_o10_pin_names_from_net $net_name $source_pin]
            set classes [list]
            set fast_tag_sinks [list]
            foreach sink $sink_names {
                set class [mptdc_o10_sink_class $family $sink]
                lappend classes $class
                if {$class eq "FAST_TAG_CLOCK"} {
                    mptdc_o10_unique_append fast_tag_sinks $sink
                }
                puts $sink_fh [join [list $family $tap [mptdc_o10_csv $source_pin] [mptdc_o10_csv $net_name] [mptdc_o10_csv $sink] $class] ","]
            }
            array set counts [mptdc_o10_count_classes $classes]
            set other_count [expr {$counts(OTHER) + $counts(OTHER_CLOCK_OR_METADATA)}]
            set other_clock_like_count $counts(OTHER_CLOCK_LIKE)
            set sinks_text [join [lrange $sink_names 0 63] ";"]

            puts $phase_fh [join [list \
                $family $tap [mptdc_o10_csv $source_pin] [llength $pins] [mptdc_o10_csv $net_name] \
                [llength $sink_names] $total_cap $total_cap_ff \
                $counts(PD_SLOW_DATA) $counts(PD_FAST_CLOCK) $counts(FAST_TAG_CLOCK) $counts(SLOW_EPOCH_CLOCK) \
                $counts(BOUNDARY_METADATA) $counts(FAST_TAG_DATA) $other_clock_like_count $other_count \
                $label [mptdc_o10_ratio $total_cap_ff 58.72] [mptdc_o10_ratio $total_cap_ff 75.59] \
                [mptdc_o10_csv $sinks_text] "SOURCE_PIN_ANCHORED"] ","]

            if {$family eq "fast"} {
                puts $fast_fh [join [list \
                    $tap [mptdc_o10_csv $source_pin] [mptdc_o10_csv $net_name] [llength $sink_names] \
                    $total_cap $total_cap_ff $counts(FAST_TAG_CLOCK) $counts(PD_FAST_CLOCK) \
                    $other_clock_like_count $label [mptdc_o10_ratio $total_cap_ff 58.72] \
                    [mptdc_o10_ratio $total_cap_ff 75.59] [mptdc_o10_csv [join $fast_tag_sinks ";"]] \
                    "SOURCE_PIN_ANCHORED"] ","]
            }
        }
    }

    close $phase_fh
    close $fast_fh
    close $sink_fh
}

proc mptdc_o10_write_phase_net_loads {} {
    global o10
    mptdc_o10_write_ro_source_pin_loads
}

proc mptdc_o10_write_fast_tag_loads {} {
    global o10
    if {![file exists "$o10(reports_dir)/fast_tag_loads.csv"]} {
        mptdc_o10_write_ro_source_pin_loads
    }
}

proc mptdc_o10_write_phase_net_loads_legacy {} {
    global o10
    set path "$o10(reports_dir)/phase_net_loads.legacy_all_net_scan.csv"
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
        set fh [open $phase_csv r]
        set text [read $fh]
        close $fh
        puts $sfh "- Rows with `NO_NET_MATCH`: [regexp -all {NO_NET_MATCH} $text]"
        puts $sfh "- Rows with `NO_SOURCE_PIN_MATCH`: [regexp -all {NO_SOURCE_PIN_MATCH} $text]"
        puts $sfh "- Rows with `NO_NET_FROM_PIN`: [regexp -all {NO_NET_FROM_PIN} $text]"
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
        set fh [open $fast_csv r]
        set text [read $fh]
        close $fh
        puts $ffh "- Rows with `NO_NET_MATCH`: [regexp -all {NO_NET_MATCH} $text]"
        puts $ffh "- Rows with `NO_SOURCE_PIN_MATCH`: [regexp -all {NO_SOURCE_PIN_MATCH} $text]"
        puts $ffh "- Rows with `NO_NET_FROM_PIN`: [regexp -all {NO_NET_FROM_PIN} $text]"
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
