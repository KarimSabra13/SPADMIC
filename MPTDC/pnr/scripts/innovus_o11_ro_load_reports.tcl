# =============================================================================
# O11 RO_tune4 source-pin load reports
#
# This report starts from the RO_tune4 S output pins and then asks Innovus for
# the connected nets and loads.  It intentionally does not discover the phase
# nets by net-name globs; O10.2 proved that path can create valid-looking CSVs
# with only NO_NET_MATCH rows.
# =============================================================================

proc mptdc_o11_csv {value} {
    set text "$value"
    regsub -all {"} $text {""} text
    if {[regexp {[,"
]} $text]} {
        return "\"$text\""
    }
    return $text
}

proc mptdc_o11_unique_append {var_name value} {
    upvar 1 $var_name values
    if {$value eq ""} { return }
    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}

proc mptdc_o11_object_names {objects} {
    set names [list]
    if {[llength $objects] == 0} {
        return $names
    }
    if {![catch {get_object_name $objects} obj_names]} {
        foreach name $obj_names { mptdc_o11_unique_append names $name }
        return $names
    }
    if {![catch {get_db $objects .name} obj_names]} {
        foreach name $obj_names { mptdc_o11_unique_append names $name }
        return $names
    }
    foreach obj $objects { mptdc_o11_unique_append names $obj }
    return $names
}

proc mptdc_o11_db_attr {object attr} {
    if {$object eq ""} { return "" }
    if {![catch {set val [get_db $object $attr]}]} { return $val }
    return ""
}

proc mptdc_o11_obj_name {object} {
    set name [mptdc_o11_db_attr $object .name]
    if {$name ne ""} { return $name }
    if {![catch {set name [get_object_name $object]}]} { return $name }
    return "$object"
}

proc mptdc_o11_pin_candidates {family tap} {
    return [list \
        [format {u_core/u_osc_%s/u_ro_tune4/S[%d]} $family $tap] \
        [format {u_core_u_osc_%s_u_ro_tune4/S[%d]} $family $tap]]
}

proc mptdc_o11_get_exact_pins {candidates} {
    set pins [list]
    foreach candidate $candidates {
        set matches [list]
        catch {set matches [get_pins -quiet $candidate]}
        foreach pin [mptdc_o11_object_names $matches] {
            mptdc_o11_unique_append pins $pin
        }
        set matches [list]
        catch {set matches [get_pins -quiet -hierarchical $candidate]}
        foreach pin [mptdc_o11_object_names $matches] {
            mptdc_o11_unique_append pins $pin
        }
    }
    return $pins
}

proc mptdc_o11_net_from_pin {pin} {
    set nets [list]
    catch {set nets [get_nets -quiet -of_objects $pin]}
    set names [mptdc_o11_object_names $nets]
    if {[llength $names] > 0} { return [lindex $names 0] }

    set net [mptdc_o11_db_attr $pin .net]
    if {$net ne ""} { return [mptdc_o11_obj_name $net] }

    set net [mptdc_o11_db_attr [format {pin:%s} $pin] .net]
    if {$net ne ""} { return [mptdc_o11_obj_name $net] }

    return ""
}

proc mptdc_o11_net_object {net_name} {
    if {$net_name eq ""} { return "" }
    set nets [list]
    catch {set nets [get_nets -quiet $net_name]}
    if {[llength $nets] > 0} { return [lindex $nets 0] }
    catch {set nets [get_nets -quiet -hierarchical $net_name]}
    if {[llength $nets] > 0} { return [lindex $nets 0] }
    return $net_name
}

proc mptdc_o11_pin_object {pin_name} {
    if {$pin_name eq ""} { return "" }
    set pins [list]
    catch {set pins [get_pins -quiet $pin_name]}
    if {[llength $pins] > 0} { return [lindex $pins 0] }
    catch {set pins [get_pins -quiet -hierarchical $pin_name]}
    if {[llength $pins] > 0} { return [lindex $pins 0] }
    return $pin_name
}

proc mptdc_o11_num_or_blank {value} {
    if {[string is double -strict $value]} { return $value }
    return ""
}

proc mptdc_o11_pf_to_ff {value} {
    if {![string is double -strict $value]} { return "" }
    return [format "%.2f" [expr {$value * 1000.0}]]
}

proc mptdc_o11_ratio {cap_ff budget_ff} {
    if {![string is double -strict $cap_ff] || $budget_ff <= 0.0} { return "" }
    return [format "%.2f" [expr {$cap_ff / $budget_ff}]]
}

proc mptdc_o11_budget_label {cap_ff} {
    if {![string is double -strict $cap_ff]} { return "UNKNOWN" }
    if {$cap_ff <= 58.72} { return "OK_STRICT" }
    if {$cap_ff <= 75.59} { return "OK_CN" }
    if {$cap_ff <= 150.0} { return "WARN_OVER_CN" }
    if {$cap_ff <= 300.0} { return "FAIL_HIGH_LOAD" }
    return "CRITICAL"
}

proc mptdc_o11_sink_class {family sink_name} {
    if {[regexp {u_pd/(slow_phase|\.slow_phase|slow_phase$)} $sink_name] || [string match *u_pd*slow_phase* $sink_name]} {
        return "PD_SLOW_DATA"
    }
    if {[regexp {u_pd/(fast_phase|\.fast_phase|fast_phase$)} $sink_name] || [string match *u_pd*fast_phase* $sink_name]} {
        return "PD_FAST_CLOCK"
    }
    if {[string match *u_fast_tag*clk_fast* $sink_name] || [string match *mptdc_fast_epoch_tag*clk_fast* $sink_name]} {
        return "FAST_TAG_CLOCK"
    }
    if {[string match *u_slow_epoch*clk_slow* $sink_name] || [string match *mptdc_slow_epoch_johnson*clk_slow* $sink_name]} {
        return "SLOW_EPOCH_CLOCK"
    }
    if {[string match *u_stop_capture* $sink_name] || [string match *u_stop_epoch_capture* $sink_name] || [string match *phase0* $sink_name] || [string match *phase7d* $sink_name] || [string match *stop_slow_phase_disc* $sink_name]} {
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

proc mptdc_o11_load_pin_cap {sink_name} {
    set pin [mptdc_o11_pin_object $sink_name]
    foreach attr {.capacitance .pin_capacitance .input_capacitance} {
        set val [mptdc_o11_db_attr $pin $attr]
        if {[string is double -strict $val]} { return $val }
    }
    return ""
}

proc mptdc_o11_net_load_names {net_obj source_pin} {
    set names [list]
    set loads [mptdc_o11_db_attr $net_obj .loads]
    foreach load $loads {
        set lname [mptdc_o11_obj_name $load]
        if {$lname eq "" || $lname eq $source_pin} { continue }
        mptdc_o11_unique_append names $lname
    }
    return $names
}

proc mptdc_o11_count_classes {class_list} {
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

proc mptdc_o11_write_error_csv {path header msg} {
    set fh [open $path w]
    puts $fh $header
    puts $fh "ERROR,[mptdc_o11_csv $msg]"
    close $fh
}

proc mptdc_o11_write_ro_load_reports {} {
    global o11

    set phase_path "$o11(reports_dir)/phase_net_loads.csv"
    set fast_path "$o11(reports_dir)/fast_tag_loads.csv"
    set sink_path "$o11(reports_dir)/ro_phase_sink_classification.csv"
    set summary_path "$o11(reports_dir)/phase_net_load_budget_summary.md"

    set phase_fh [open $phase_path w]
    puts $phase_fh "family,tap,source_pin,matched_source_pin_count,net,fanout,total_cap_pf,total_cap_ff,wire_cap_pf,wire_cap_ff,pin_cap_pf,pin_cap_ff,transition,route_length,pd_slow_data_load_count,pd_fast_clock_load_count,fast_tag_clock_load_count,slow_epoch_clock_load_count,boundary_metadata_load_count,fast_tag_data_load_count,other_clock_like_load_count,other_load_count,budget_label,strict_ratio,cn_ratio,sinks,notes"

    set fast_fh [open $fast_path w]
    puts $fast_fh "tap,source_pin,net,fanout,total_cap_pf,total_cap_ff,fast_tag_clock_load_count,pd_fast_clock_load_count,other_clock_like_load_count,budget_label,strict_ratio,cn_ratio,fast_tag_clock_sinks,notes"

    set sink_fh [open $sink_path w]
    puts $sink_fh "family,tap,source_pin,net,sink_pin,sink_class,sink_pin_cap_pf,sink_pin_cap_ff"

    set total_rows 0
    set matched_rows 0
    set no_source_rows 0
    set no_net_rows 0
    set max_cap_ff ""
    set max_desc ""
    array set label_counts {}

    foreach family {slow fast} {
        for {set tap 0} {$tap < 8} {incr tap} {
            incr total_rows
            set candidates [mptdc_o11_pin_candidates $family $tap]
            set pins [mptdc_o11_get_exact_pins $candidates]
            if {[llength $pins] == 0} {
                incr no_source_rows
                set note "NO_SOURCE_PIN_MATCH candidates=[join $candidates {|}]"
                puts $phase_fh [join [list $family $tap "" 0 "" 0 "" "" "" "" "" "" "" "" 0 0 0 0 0 0 0 0 UNKNOWN "" "" "" [mptdc_o11_csv $note]] ","]
                if {$family eq "fast"} {
                    puts $fast_fh [join [list $tap "" "" 0 "" "" 0 0 0 UNKNOWN "" "" "" [mptdc_o11_csv $note]] ","]
                }
                continue
            }

            incr matched_rows
            set source_pin [lindex $pins 0]
            set net_name [mptdc_o11_net_from_pin $source_pin]
            if {$net_name eq ""} {
                incr no_net_rows
                set note "NO_NET_FROM_PIN matched_pins=[join $pins {|}]"
                puts $phase_fh [join [list $family $tap [mptdc_o11_csv $source_pin] [llength $pins] "" 0 "" "" "" "" "" "" "" "" 0 0 0 0 0 0 0 0 UNKNOWN "" "" "" [mptdc_o11_csv $note]] ","]
                if {$family eq "fast"} {
                    puts $fast_fh [join [list $tap [mptdc_o11_csv $source_pin] "" 0 "" "" 0 0 0 UNKNOWN "" "" "" [mptdc_o11_csv $note]] ","]
                }
                continue
            }

            set net_obj [mptdc_o11_net_object $net_name]
            set fanout [mptdc_o11_db_attr $net_obj .num_loads]
            if {$fanout eq ""} { set fanout [mptdc_o11_db_attr $net_obj .fanout] }
            set total_cap [mptdc_o11_num_or_blank [mptdc_o11_db_attr $net_obj .total_capacitance]]
            set wire_cap [mptdc_o11_num_or_blank [mptdc_o11_db_attr $net_obj .wire_capacitance]]
            set pin_cap [mptdc_o11_num_or_blank [mptdc_o11_db_attr $net_obj .pin_capacitance]]
            set trans [mptdc_o11_db_attr $net_obj .transition]
            set length [mptdc_o11_db_attr $net_obj .route_length]
            set total_cap_ff [mptdc_o11_pf_to_ff $total_cap]
            set wire_cap_ff [mptdc_o11_pf_to_ff $wire_cap]
            set pin_cap_ff [mptdc_o11_pf_to_ff $pin_cap]
            set label [mptdc_o11_budget_label $total_cap_ff]
            set strict_ratio [mptdc_o11_ratio $total_cap_ff 58.72]
            set cn_ratio [mptdc_o11_ratio $total_cap_ff 75.59]

            if {![info exists label_counts($label)]} { set label_counts($label) 0 }
            incr label_counts($label)
            if {[string is double -strict $total_cap_ff] && ($max_cap_ff eq "" || $total_cap_ff > $max_cap_ff)} {
                set max_cap_ff $total_cap_ff
                set max_desc [format {%s S[%d] %s} $family $tap $source_pin]
            }

            set sink_names [mptdc_o11_net_load_names $net_obj $source_pin]
            set classes [list]
            set fast_tag_sinks [list]
            foreach sink $sink_names {
                set class [mptdc_o11_sink_class $family $sink]
                lappend classes $class
                if {$class eq "FAST_TAG_CLOCK"} { lappend fast_tag_sinks $sink }
                set sink_cap [mptdc_o11_load_pin_cap $sink]
                puts $sink_fh [join [list \
                    $family $tap [mptdc_o11_csv $source_pin] [mptdc_o11_csv $net_name] \
                    [mptdc_o11_csv $sink] $class $sink_cap [mptdc_o11_pf_to_ff $sink_cap]] ","]
            }

            array set counts [mptdc_o11_count_classes $classes]
            set other_count [expr {$counts(OTHER) + $counts(OTHER_CLOCK_OR_METADATA)}]
            set other_clock_like_count $counts(OTHER_CLOCK_LIKE)
            set sinks_text [join [lrange $sink_names 0 63] ";"]

            puts $phase_fh [join [list \
                $family $tap [mptdc_o11_csv $source_pin] [llength $pins] [mptdc_o11_csv $net_name] \
                $fanout $total_cap $total_cap_ff $wire_cap $wire_cap_ff $pin_cap $pin_cap_ff $trans $length \
                $counts(PD_SLOW_DATA) $counts(PD_FAST_CLOCK) $counts(FAST_TAG_CLOCK) $counts(SLOW_EPOCH_CLOCK) \
                $counts(BOUNDARY_METADATA) $counts(FAST_TAG_DATA) $other_clock_like_count $other_count \
                $label $strict_ratio $cn_ratio [mptdc_o11_csv $sinks_text] ""] ","]

            if {$family eq "fast"} {
                puts $fast_fh [join [list \
                    $tap [mptdc_o11_csv $source_pin] [mptdc_o11_csv $net_name] $fanout \
                    $total_cap $total_cap_ff $counts(FAST_TAG_CLOCK) $counts(PD_FAST_CLOCK) \
                    $other_clock_like_count $label $strict_ratio $cn_ratio \
                    [mptdc_o11_csv [join $fast_tag_sinks ";"]] ""] ","]
            }
        }
    }

    close $phase_fh
    close $fast_fh
    close $sink_fh

    set sfh [open $summary_path w]
    puts $sfh "# O11 RO Phase Load Budget Summary"
    puts $sfh ""
    puts $sfh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $sfh ""
    puts $sfh "- Source run: `$o11(source_run_id)`"
    puts $sfh {- Source pins: exact `u_core/u_osc_*/u_ro_tune4/S[n]` and `u_core_u_osc_*_u_ro_tune4/S[n]` aliases; nets are derived from matched pins.}
    puts $sfh "- Strict analog D-load budget: `58.72 fF` (`0.05872 pF`)."
    puts $sfh "- CN/clock-like estimate: `75.59 fF` (`0.07559 pF`)."
    puts $sfh "- Budget labels: `OK_STRICT <= 58.72 fF`, `OK_CN <= 75.59 fF`, `WARN_OVER_CN <= 150 fF`, `FAIL_HIGH_LOAD > 150 fF and <= 300 fF`, `CRITICAL > 300 fF`."
    puts $sfh "- Total RO phase rows: $total_rows."
    puts $sfh "- Matched source-pin rows: $matched_rows."
    puts $sfh "- Rows without source-pin match: $no_source_rows."
    puts $sfh "- Rows without net from source pin: $no_net_rows."
    if {$max_cap_ff ne ""} {
        puts $sfh "- Max measured source-pin net load: `$max_cap_ff fF` at `$max_desc`."
    } else {
        puts $sfh "- Max measured source-pin net load: `UNKNOWN`."
    }
    puts $sfh ""
    puts $sfh "| Label | Row count |"
    puts $sfh "|---|---:|"
    foreach label {OK_STRICT OK_CN WARN_OVER_CN FAIL_HIGH_LOAD CRITICAL UNKNOWN} {
        set count 0
        if {[info exists label_counts($label)]} { set count $label_counts($label) }
        puts $sfh "| $label | $count |"
    }
    puts $sfh ""
    puts $sfh "Required CSVs:"
    puts $sfh ""
    puts $sfh "- `phase_net_loads.csv`"
    puts $sfh "- `fast_tag_loads.csv`"
    puts $sfh "- `ro_phase_sink_classification.csv`"
    puts $sfh ""
    puts $sfh "This report does not waive RO_tune4 output loading.  It classifies the physical load so the next backend or analog decision can be made from the real sinks."
    close $sfh
}
