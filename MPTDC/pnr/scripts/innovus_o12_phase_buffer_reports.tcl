# =============================================================================
# O12 phase-isolation buffer reports
#
# Starts from exact RO_tune4 S pins and exact O12 phase-buffer pins.  The raw
# RO load check treats absence from drv_max_cap.rpt as a useful bound because
# the RO Liberty shell still limits S pins to 0.050 pF, below the 58.72 fF
# strict analog budget.
# =============================================================================

set ::env(MPTDC_O11_SOURCE_ONLY) 1
source [file join [file dirname [file normalize [info script]]] innovus_o11_ro_load_reports.tcl]

proc mptdc_o12_pin_candidates {family tap role} {
    if {$role eq "raw"} {
        return [mptdc_o11_pin_candidates $family $tap]
    }
    set pin $role
    return [list \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d]/u_buf/%s} $family $tap $pin] \
        [format {u_core_u_phase_buf_%s_gen_phase_buf_%d__u_buf/%s} $family $tap $pin] \
        [format {*u_phase_buf_%s*gen_phase_buf*%d*u_buf/%s} $family $tap $pin]]
}

proc mptdc_o12_get_pins {candidates} {
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

proc mptdc_o12_source_kind {pin drv_caps raw_source} {
    if {$pin eq ""} { return [list "" "" "" "UNKNOWN"] }
    if {[dict exists $drv_caps $pin]} {
        set cap_row [dict get $drv_caps $pin]
        set cap_pf [lindex $cap_row 1]
        set cap_ff [mptdc_o11_pf_to_ff $cap_pf]
        return [list $cap_pf $cap_ff "" "CAP_FROM_DRV_MAX_CAP_RPT"]
    }
    if {$raw_source} {
        return [list "" "" "50.00" "NO_DRV_MAX_CAP_VIOLATION_BOUND_50FF"]
    }
    return [list "" "" "" "NO_DRV_MAX_CAP_VIOLATION_STD_CELL_OUTPUT"]
}

proc mptdc_o12_budget_label_from_source {cap_ff bound_ff raw_source} {
    if {[string is double -strict $cap_ff]} {
        return [mptdc_o11_budget_label $cap_ff]
    }
    if {$raw_source && [string is double -strict $bound_ff] && $bound_ff <= 58.72} {
        return "OK_STRICT"
    }
    if {$raw_source && [string is double -strict $bound_ff] && $bound_ff <= 75.59} {
        return "OK_CN"
    }
    return "UNKNOWN"
}

proc mptdc_o12_net_row {fh family tap pin matched_count raw_source drv_caps} {
    set net_name ""
    set fanout ""
    set sinks_text ""
    set notes [list]
    if {$pin eq ""} {
        set note [expr {$raw_source ? "NO_RAW_SOURCE_PIN_MATCH" : "NO_BUFFER_OUTPUT_PIN_MATCH"}]
        puts $fh [join [list $family $tap "" 0 "" 0 "" "" "" UNKNOWN "" "" "" [mptdc_o11_csv $note]] ","]
        return [list UNKNOWN "" "" "" $note]
    }

    set net_name [mptdc_o11_net_from_pin $pin]
    if {$net_name eq ""} {
        set note "NO_NET_FROM_PIN"
        puts $fh [join [list $family $tap [mptdc_o11_csv $pin] $matched_count "" 0 "" "" "" UNKNOWN "" "" "" [mptdc_o11_csv $note]] ","]
        return [list UNKNOWN "" "" "" $note]
    }

    set net_obj [mptdc_o11_net_object $net_name]
    set fanout [mptdc_o11_db_attr $net_obj .num_loads]
    if {$fanout eq ""} { set fanout [mptdc_o11_db_attr $net_obj .fanout] }
    set sink_names [mptdc_o11_net_load_names $net_obj $pin]
    set sinks_text [join [lrange $sink_names 0 63] ";"]

    set cap_data [mptdc_o12_source_kind $pin $drv_caps $raw_source]
    set cap_pf [lindex $cap_data 0]
    set cap_ff [lindex $cap_data 1]
    set bound_ff [lindex $cap_data 2]
    set cap_source [lindex $cap_data 3]
    lappend notes $cap_source

    set label [mptdc_o12_budget_label_from_source $cap_ff $bound_ff $raw_source]
    set strict_ratio [mptdc_o11_ratio $cap_ff 58.72]
    set cn_ratio [mptdc_o11_ratio $cap_ff 75.59]
    if {$strict_ratio eq "" && [string is double -strict $bound_ff]} {
        set strict_ratio [format "<=%.2f" [expr {$bound_ff / 58.72}]]
        set cn_ratio [format "<=%.2f" [expr {$bound_ff / 75.59}]]
    }

    puts $fh [join [list \
        $family $tap [mptdc_o11_csv $pin] $matched_count [mptdc_o11_csv $net_name] $fanout \
        $cap_pf $cap_ff $bound_ff $label $strict_ratio $cn_ratio \
        [mptdc_o11_csv $sinks_text] [mptdc_o11_csv [join $notes ";"]]] ","]

    return [list $label $cap_ff $bound_ff $fanout $cap_source]
}

proc mptdc_o12_write_phase_buffer_reports {} {
    global o12

    set raw_path "$o12(reports_dir)/ro_phase_raw_pin_loads.csv"
    set out_path "$o12(reports_dir)/phase_buffer_output_loads.csv"
    set balance_path "$o12(reports_dir)/phase_buffer_balance_summary.md"
    set budget_path "$o12(reports_dir)/phase_net_load_budget_summary.md"
    set drv_caps [mptdc_o11_read_drv_max_cap "$o12(reports_dir)/drv_max_cap.rpt"]

    set raw_fh [open $raw_path w]
    puts $raw_fh "family,tap,source_pin,matched_pin_count,net,fanout,total_cap_pf,total_cap_ff,cap_bound_ff,budget_label,strict_ratio,cn_ratio,sinks,notes"

    set out_fh [open $out_path w]
    puts $out_fh "family,tap,buffer_output_pin,matched_pin_count,net,fanout,total_cap_pf,total_cap_ff,cap_bound_ff,budget_label,strict_ratio,cn_ratio,sinks,notes"

    array set raw_label_counts {}
    array set out_label_counts {}
    set raw_rows 0
    set out_rows 0
    set raw_matched 0
    set out_matched 0
    set raw_missing 0
    set out_missing 0
    set raw_bound_ok 0
    set max_raw_cap_ff ""
    set max_raw_desc ""
    set max_out_cap_ff ""
    set max_out_desc ""

    foreach family {slow fast} {
        for {set tap 0} {$tap < 8} {incr tap} {
            incr raw_rows
            incr out_rows

            set raw_pins [mptdc_o12_get_pins [mptdc_o12_pin_candidates $family $tap raw]]
            set out_pins [mptdc_o12_get_pins [mptdc_o12_pin_candidates $family $tap Q]]

            set raw_pin [lindex $raw_pins 0]
            set out_pin [lindex $out_pins 0]
            if {$raw_pin eq ""} { incr raw_missing } else { incr raw_matched }
            if {$out_pin eq ""} { incr out_missing } else { incr out_matched }

            set raw_data [mptdc_o12_net_row $raw_fh $family $tap $raw_pin [llength $raw_pins] 1 $drv_caps]
            set out_data [mptdc_o12_net_row $out_fh $family $tap $out_pin [llength $out_pins] 0 $drv_caps]

            set raw_label [lindex $raw_data 0]
            set raw_cap_ff [lindex $raw_data 1]
            set raw_bound_ff [lindex $raw_data 2]
            set raw_source [lindex $raw_data 4]
            if {![info exists raw_label_counts($raw_label)]} { set raw_label_counts($raw_label) 0 }
            incr raw_label_counts($raw_label)
            if {$raw_source eq "NO_DRV_MAX_CAP_VIOLATION_BOUND_50FF"} { incr raw_bound_ok }
            if {[string is double -strict $raw_cap_ff] && ($max_raw_cap_ff eq "" || $raw_cap_ff > $max_raw_cap_ff)} {
                set max_raw_cap_ff $raw_cap_ff
                set max_raw_desc [format {%s S[%d] %s} $family $tap $raw_pin]
            }

            set out_label [lindex $out_data 0]
            set out_cap_ff [lindex $out_data 1]
            if {![info exists out_label_counts($out_label)]} { set out_label_counts($out_label) 0 }
            incr out_label_counts($out_label)
            if {[string is double -strict $out_cap_ff] && ($max_out_cap_ff eq "" || $out_cap_ff > $max_out_cap_ff)} {
                set max_out_cap_ff $out_cap_ff
                set max_out_desc [format {%s tap[%d] %s} $family $tap $out_pin]
            }
        }
    }

    close $raw_fh
    close $out_fh

    foreach path [list $balance_path $budget_path] {
        set fh [open $path w]
        if {$path eq $balance_path} {
            puts $fh "# O12 Phase Buffer Balance Summary"
        } else {
            puts $fh "# O12 RO Raw Pin Load Budget Summary"
        }
        puts $fh ""
        puts $fh "REPORT_STATUS=REVIEW_REQUIRED"
        puts $fh ""
        puts $fh "- Source run: `$o12(source_run_id)`"
        puts $fh "- Strict analog D-load budget: `58.72 fF` (`0.05872 pF`)."
        puts $fh "- CN/clock-like estimate: `75.59 fF` (`0.07559 pF`)."
        puts $fh "- RO Liberty shell max-cap bound: `50.00 fF` (`0.050 pF`)."
        puts $fh "- Raw RO rows: $raw_rows."
        puts $fh "- Matched raw RO rows: $raw_matched."
        puts $fh "- Missing raw RO rows: $raw_missing."
        puts $fh "- Raw rows bounded by no max-cap violation: $raw_bound_ok."
        puts $fh "- Buffer output rows: $out_rows."
        puts $fh "- Matched buffer output rows: $out_matched."
        puts $fh "- Missing buffer output rows: $out_missing."
        if {$max_raw_cap_ff ne ""} {
            puts $fh "- Max measured raw RO source load: `$max_raw_cap_ff fF` at `$max_raw_desc`."
        } else {
            puts $fh "- Max measured raw RO source load: no violating raw RO pin in `drv_max_cap.rpt`; raw rows are bounded by the 50 fF RO shell max-cap where matched."
        }
        if {$max_out_cap_ff ne ""} {
            puts $fh "- Max measured buffer output load violation: `$max_out_cap_ff fF` at `$max_out_desc`."
        } else {
            puts $fh "- Max measured buffer output load violation: none found in `drv_max_cap.rpt`."
        }
        puts $fh ""
        puts $fh "## Raw RO Budget Labels"
        puts $fh ""
        puts $fh "| Label | Row count |"
        puts $fh "|---|---:|"
        foreach label {OK_STRICT OK_CN WARN_OVER_CN FAIL_HIGH_LOAD CRITICAL UNKNOWN} {
            set count 0
            if {[info exists raw_label_counts($label)]} { set count $raw_label_counts($label) }
            puts $fh "| $label | $count |"
        }
        puts $fh ""
        puts $fh "## Buffer Output Labels"
        puts $fh ""
        puts $fh "| Label | Row count |"
        puts $fh "|---|---:|"
        foreach label {OK_STRICT OK_CN WARN_OVER_CN FAIL_HIGH_LOAD CRITICAL UNKNOWN} {
            set count 0
            if {[info exists out_label_counts($label)]} { set count $out_label_counts($label) }
            puts $fh "| $label | $count |"
        }
        puts $fh ""
        puts $fh "Required CSVs:"
        puts $fh ""
        puts $fh "- `ro_phase_raw_pin_loads.csv`"
        puts $fh "- `phase_buffer_output_loads.csv`"
        puts $fh ""
        puts $fh "This is an O12 feasibility report, not signoff.  Passing raw RO rows mean the direct RO load is isolated; buffer output load still needs timing, balance, placement, and power review."
        close $fh
    }
}
