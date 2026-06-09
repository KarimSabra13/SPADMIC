# =============================================================================
# O13 phase-distribution reports
#
# Report-only helpers for the two-stage O13 topology:
#
#   RO_tune4/S[n] -> BUHDX4 u_iso -> BUHDX12 u_drv -> phase fabric
#
# These reports keep raw analog load evidence separate from final digital phase
# driver evidence.  They reuse the O12B report_property parsers because those
# are the portable Innovus path that worked on the lab server.
# =============================================================================

set ::env(MPTDC_O12B_SOURCE_ONLY) 1
source [file join [file dirname [file normalize [info script]]] innovus_o12b_phase_buffer_reports.tcl]

proc mptdc_o13_source_xlibd_config {} {
    set script_dir [file dirname [file normalize [info script]]]
    set cfg [file normalize [file join $script_dir .. config xlibd_spadmic_typical_cell_values.tcl]]
    if {[file readable $cfg]} {
        source $cfg
        return $cfg
    }
    puts "MPTDC_O13_WARN: XLIBD config not readable: $cfg"
    return ""
}

mptdc_o13_source_xlibd_config

proc mptdc_o13_reports_dir {} {
    if {[info exists ::o13(reports_dir)]} {
        return $::o13(reports_dir)
    }
    if {[info exists ::o12b(reports_dir)]} {
        return $::o12b(reports_dir)
    }
    return "reports"
}

proc mptdc_o13_source_run_id {} {
    if {[info exists ::o13(source_run_id)]} {
        return $::o13(source_run_id)
    }
    if {[info exists ::o12b(source_run_id)]} {
        return $::o12b(source_run_id)
    }
    return "unknown"
}

proc mptdc_o13_pin_candidates {family tap role} {
    if {$role eq "raw"} {
        return [mptdc_o11_pin_candidates $family $tap]
    }

    array set role_map {
        iso_A {u_iso A}
        iso_Q {u_iso Q}
        drv_A {u_drv A}
        drv_Q {u_drv Q}
    }
    if {![info exists role_map($role)]} {
        return [list]
    }
    set inst [lindex $role_map($role) 0]
    set pin  [lindex $role_map($role) 1]
    return [list \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d]/%s/%s} $family $tap $inst $pin] \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d].%s/%s} $family $tap $inst $pin] \
        [format {u_core_u_phase_buf_%s/gen_phase_buf[%d].%s/%s} $family $tap $inst $pin] \
        [format {u_core_u_phase_buf_%s_gen_phase_buf_%d__%s/%s} $family $tap $inst $pin] \
        [format {*u_phase_buf_%s*gen_phase_buf*%d*%s/%s} $family $tap $inst $pin]]
}

proc mptdc_o13_get_pins {candidates} {
    return [mptdc_o12_get_pins $candidates]
}

proc mptdc_o13_expected_cell_type_for_inst {cell_name} {
    if {[regexp {(^|[/.])u_iso$} $cell_name]} { return "BUHDX4" }
    if {[regexp {(^|[/.])u_drv$} $cell_name]} { return "BUHDX12" }
    return ""
}

proc mptdc_o13_cell_type_from_property {path} {
    return [mptdc_o12b_cell_type_from_property $path]
}

proc mptdc_o13_resolve_cell_type {cell_name property_path} {
    set cell_type [mptdc_o12b_cell_type $cell_name]
    if {$cell_type ne ""} {
        return [list $cell_type "db_attr"]
    }
    set prop_data [mptdc_o13_cell_type_from_property $property_path]
    set prop_type [lindex $prop_data 0]
    if {$prop_type ne ""} {
        return [list $prop_type [lindex $prop_data 1]]
    }
    set expected [mptdc_o13_expected_cell_type_for_inst $cell_name]
    if {$expected ne ""} {
        return [list $expected "rtl_instance_fallback"]
    }
    return [list "" "CELL_TYPE_UNRESOLVED_BY_DB"]
}

proc mptdc_o13_row_objects {family tap} {
    set raw_pins [mptdc_o13_get_pins [mptdc_o13_pin_candidates $family $tap raw]]
    set iso_a_pins [mptdc_o13_get_pins [mptdc_o13_pin_candidates $family $tap iso_A]]
    set iso_q_pins [mptdc_o13_get_pins [mptdc_o13_pin_candidates $family $tap iso_Q]]
    set drv_a_pins [mptdc_o13_get_pins [mptdc_o13_pin_candidates $family $tap drv_A]]
    set drv_q_pins [mptdc_o13_get_pins [mptdc_o13_pin_candidates $family $tap drv_Q]]

    set raw_pin [lindex $raw_pins 0]
    set iso_a_pin [lindex $iso_a_pins 0]
    set iso_q_pin [lindex $iso_q_pins 0]
    set drv_a_pin [lindex $drv_a_pins 0]
    set drv_q_pin [lindex $drv_q_pins 0]

    set raw_net [mptdc_o11_net_from_pin $raw_pin]
    set iso_net [mptdc_o11_net_from_pin $iso_q_pin]
    set out_net [mptdc_o11_net_from_pin $drv_q_pin]

    set iso_inst [mptdc_o12b_cell_from_pin $iso_q_pin]
    if {$iso_inst eq ""} { set iso_inst [mptdc_o12b_cell_from_pin $iso_a_pin] }
    set drv_inst [mptdc_o12b_cell_from_pin $drv_q_pin]
    if {$drv_inst eq ""} { set drv_inst [mptdc_o12b_cell_from_pin $drv_a_pin] }

    return [list \
        $raw_pins $iso_a_pins $iso_q_pins $drv_a_pins $drv_q_pins \
        $raw_pin $iso_a_pin $iso_q_pin $drv_a_pin $drv_q_pin \
        $raw_net $iso_net $out_net $iso_inst $drv_inst]
}

proc mptdc_o13_clock_for {family tap} {
    return [format {clk_osc_%s_buf_tap%d} $family $tap]
}

proc mptdc_o13_delay_ps {a_pin q_pin} {
    return [mptdc_o12b_delay_ps $a_pin $q_pin]
}

proc mptdc_o13_xlibd_get {key default_value} {
    if {[llength [info commands mptdc_xlibd_get]] > 0} {
        return [mptdc_xlibd_get $key $default_value]
    }
    return $default_value
}

proc mptdc_o13_xlibd_cell {cell field default_value} {
    if {[llength [info commands mptdc_xlibd_cell]] > 0} {
        return [mptdc_xlibd_cell $cell $field $default_value]
    }
    return $default_value
}

proc mptdc_o13_xlibd_budget_ff {kind} {
    if {[llength [info commands mptdc_xlibd_analog_budget_ff]] > 0} {
        return [mptdc_xlibd_analog_budget_ff $kind]
    }
    if {$kind eq "strict"} { return 58.72 }
    if {$kind eq "cn"} { return 75.59 }
    return ""
}

proc mptdc_o13_xlibd_ratio_or_bound {cap_ff bound_ff kind} {
    set budget [mptdc_o13_xlibd_budget_ff $kind]
    if {[llength [info commands mptdc_xlibd_ratio]] > 0} {
        set ratio [mptdc_xlibd_ratio $cap_ff $budget]
    } else {
        set ratio [mptdc_o11_ratio $cap_ff $budget]
    }
    if {$ratio ne ""} { return $ratio }
    if {[string is double -strict $bound_ff] && [string is double -strict $budget] && $budget > 0.0} {
        return [format "<=%.2f" [expr {$bound_ff / $budget}]]
    }
    return ""
}

proc mptdc_o13_xlibd_equiv_or_bound {cap_ff bound_ff kind} {
    set value ""
    if {[llength [info commands mptdc_xlibd_equivalent_loads]] > 0} {
        set value [mptdc_xlibd_equivalent_loads $cap_ff $kind]
    }
    if {$value ne ""} { return $value }
    if {[llength [info commands mptdc_xlibd_equivalent_loads]] > 0 && [string is double -strict $bound_ff]} {
        set bound_value [mptdc_xlibd_equivalent_loads $bound_ff $kind]
        if {$bound_value ne ""} { return "<=$bound_value" }
    }
    return ""
}

proc mptdc_o13_xlibd_ratio_to_value {cap_ff limit_ff} {
    if {![string is double -strict $cap_ff] || ![string is double -strict $limit_ff] || $limit_ff <= 0.0} {
        return ""
    }
    return [format "%.3f" [expr {$cap_ff / $limit_ff}]]
}

proc mptdc_o13_xlibd_equiv_cell_load {cap_ff cell field} {
    if {[llength [info commands mptdc_xlibd_equivalent_cell_loads]] > 0} {
        set value [mptdc_xlibd_equivalent_cell_loads $cap_ff $cell $field]
        if {$value ne ""} { return $value }
    }
    set unit_ff [mptdc_o13_xlibd_cell $cell $field ""]
    if {![string is double -strict $cap_ff] || ![string is double -strict $unit_ff] || $unit_ff <= 0.0} {
        return ""
    }
    return [format "%.1f" [expr {$cap_ff / $unit_ff}]]
}

proc mptdc_o13_ps_to_ns {value_ps} {
    if {![string is double -strict $value_ps]} { return "" }
    return [format "%.4f" [expr {$value_ps / 1000.0}]]
}

proc mptdc_o13_transition_status {transition_ps} {
    if {![string is double -strict $transition_ps]} {
        return "UNKNOWN_TRANSITION"
    }
    if {$transition_ps > 750.0} {
        return "TRANSITION_FAIL_REVIEW_DRIVER_OR_ROUTE"
    }
    if {$transition_ps > 500.0} {
        return "TRANSITION_WARNING_REVIEW_ROUTE"
    }
    return "TRANSITION_OK_REVIEW_ROUTE"
}

proc mptdc_o13_xlibd_driver_suitability {cell_type cap_ff fanout transition_ps} {
    set max_cap [mptdc_o13_xlibd_cell $cell_type output_max_cap_ff ""]
    set max_fanout [mptdc_o13_xlibd_cell $cell_type output_max_fanout ""]
    if {$cell_type eq ""} { return "DRIVER_CELL_UNKNOWN" }
    if {[string is double -strict $cap_ff] && [string is double -strict $max_cap] && $cap_ff > $max_cap} {
        return "OVER_XLIBD_OUTPUT_MAX_CAP"
    }
    if {[string is double -strict $fanout] && [string is double -strict $max_fanout] && $fanout > $max_fanout} {
        return "OVER_XLIBD_OUTPUT_MAX_FANOUT"
    }
    if {[string is double -strict $transition_ps] && $transition_ps > 750.0} {
        return "TRANSITION_FAIL_REVIEW_DRIVER_OR_ROUTE"
    }
    if {[string is double -strict $transition_ps] && $transition_ps > 500.0} {
        return "TRANSITION_WARNING_REVIEW_ROUTE"
    }
    if {$cell_type eq "BUHDX12"} {
        return "BUHDX12_SUITABLE_FOR_O13_REVIEW"
    }
    return "UNDER_XLIBD_LIMITS_REVIEW_TRANSITION"
}

proc mptdc_o13_write_xlibd_load_row {fh family tap stage source_pin net cap_pf cap_ff bound_ff driver_cell_type driver_input_cap_ff driver_output_max_cap_ff driver_output_max_fanout suitability notes} {
    set strict_ratio [mptdc_o13_xlibd_ratio_or_bound $cap_ff $bound_ff strict]
    set cn_ratio [mptdc_o13_xlibd_ratio_or_bound $cap_ff $bound_ff cn]
    set equiv_d [mptdc_o13_xlibd_equiv_or_bound $cap_ff $bound_ff d]
    set equiv_c [mptdc_o13_xlibd_equiv_or_bound $cap_ff $bound_ff c]
    set equiv_rn [mptdc_o13_xlibd_equiv_or_bound $cap_ff $bound_ff rn]
    puts $fh [join [list \
        $family $tap $stage [mptdc_o12b_csv $source_pin] [mptdc_o12b_csv $net] \
        $cap_pf $cap_ff $bound_ff $strict_ratio $cn_ratio $equiv_d $equiv_c $equiv_rn \
        [mptdc_o12b_csv $driver_cell_type] $driver_input_cap_ff $driver_output_max_cap_ff \
        $driver_output_max_fanout $suitability [mptdc_o12b_csv $notes]] ","]
}

proc mptdc_o13_sink_pin_tail {pin_name} {
    if {[regexp {/([A-Za-z0-9_]+)$} $pin_name -> tail]} {
        return [string toupper $tail]
    }
    return ""
}

proc mptdc_o13_sink_cap_field {pin_name} {
    set tail [mptdc_o13_sink_pin_tail $pin_name]
    switch -- $tail {
        C - CK - CLK { return "clk_cap_ff" }
        D { return "d_cap_ff" }
        RN { return "rn_cap_ff" }
        SN { return "sn_cap_ff" }
        A { return "a_cap_ff" }
        B { return "b_cap_ff" }
        default { return "" }
    }
}

proc mptdc_o13_sink_cell_type {sink_pin} {
    set inst [mptdc_o12b_cell_from_pin $sink_pin]
    if {$inst eq ""} { return "" }
    return [mptdc_o12b_cell_type $inst]
}

proc mptdc_o13_write_stage_placement {fh family tap stage inst cell_type ro_inst ro_x ro_y pd_x pd_y placement_numeric_var min_ro_dist_var max_ro_dist_var} {
    upvar $placement_numeric_var placement_numeric
    upvar $min_ro_dist_var min_ro_dist
    upvar $max_ro_dist_var max_ro_dist

    set box [mptdc_o12b_cell_box $inst]
    set ctr [mptdc_o12b_box_center $box]
    set bx [lindex $ctr 0]
    set by [lindex $ctr 1]
    set ro_dist [mptdc_o12b_distance $bx $by $ro_x $ro_y]
    set pd_dist [mptdc_o12b_distance $bx $by $pd_x $pd_y]
    set placement_status "PLACEMENT_REVIEW"
    set notes [list]
    if {$bx ne "" && $by ne ""} {
        incr placement_numeric
        set ro_man [lindex $ro_dist 2]
        if {$ro_man ne ""} {
            if {$min_ro_dist eq "" || $ro_man < $min_ro_dist} { set min_ro_dist $ro_man }
            if {$max_ro_dist eq "" || $ro_man > $max_ro_dist} { set max_ro_dist $ro_man }
        }
    } else {
        set placement_status "PLACEMENT_UNKNOWN"
        lappend notes "buffer_location_unavailable"
    }
    puts $fh [join [list \
        $family $tap $stage [mptdc_o12b_csv $inst] [mptdc_o12b_csv $cell_type] \
        $bx $by [lindex $box 0] [lindex $box 1] [lindex $box 2] [lindex $box 3] \
        [mptdc_o12b_csv $ro_inst] $ro_x $ro_y [lindex $ro_dist 0] [lindex $ro_dist 1] [lindex $ro_dist 2] \
        $pd_x $pd_y [lindex $pd_dist 2] $placement_status [mptdc_o12b_csv [join $notes ";"]]] ","]
}

proc mptdc_o13_write_reports {} {
    set reports_dir [mptdc_o13_reports_dir]
    file mkdir $reports_dir

    set raw_path "$reports_dir/ro_phase_raw_pin_loads.csv"
    set out_path "$reports_dir/phase_buffer_output_loads.csv"
    set topo_path "$reports_dir/phase_buffer_topology.csv"
    set topo_summary_path "$reports_dir/phase_buffer_topology_summary.md"
    set place_path "$reports_dir/phase_buffer_placement.csv"
    set place_summary_path "$reports_dir/phase_buffer_placement_summary.md"
    set delay_path "$reports_dir/phase_buffer_delay_estimate.csv"
    set route_path "$reports_dir/phase_buffer_route_summary.csv"
    set sink_path "$reports_dir/ro_phase_sink_classification.csv"
    set summary_path "$reports_dir/phase_buffer_balance_summary.md"
    set xlibd_path "$reports_dir/phase_net_loads_xlibd_enhanced.csv"
    set raw_xlibd_path "$reports_dir/ro_phase_raw_pin_loads_xlibd.csv"
    set out_xlibd_path "$reports_dir/phase_buffer_output_loads_xlibd.csv"
    set fast_tag_xlibd_path "$reports_dir/fast_tag_loads_xlibd.csv"
    set xlibd_budget_path "$reports_dir/phase_net_load_budget_summary.md"
    set xlibd_interp_path "$reports_dir/phase_buffer_xlibd_interpretation.md"

    set raw_fh [open $raw_path w]
    puts $raw_fh "family,tap,raw_ro_pin,matched_raw_pin_count,raw_net,raw_fanout,raw_net_total_cap_pf,raw_net_total_cap_ff,raw_net_cap_bound_ff,budget_label,strict_ratio,cn_ratio,isolation_input_pin,sinks,notes"

    set out_fh [open $out_path w]
    puts $out_fh "family,tap,raw_ro_pin,raw_net,isolation_instance,isolation_cell_type,isolation_input_pin,isolation_output_pin,isolation_net,driver_instance,driver_cell_type,driver_input_pin,driver_output_pin,buffered_phase_net,buffer_output_fanout,total_cap_pf,total_cap_ff,wire_cap_pf,wire_cap_ff,pin_cap_pf,pin_cap_ff,res_ohm,transition_ps,route_length_um,status,sink_count,pd_load_count,fast_tag_load_count,slow_epoch_load_count,metadata_load_count,other_load_count,isolation_input_cap_pf,isolation_input_cap_ff,driver_input_cap_pf,driver_input_cap_ff,raw_net_cap_pf,raw_net_cap_ff,budget_label,strict_ratio,cn_ratio,notes"

    set topo_fh [open $topo_path w]
    puts $topo_fh "family,tap,buffer_chain_depth,cell_sequence,input_net,isolation_net,output_net,status,notes"

    set place_fh [open $place_path w]
    puts $place_fh "family,tap,stage,buffer_instance,buffer_cell_type,x,y,llx,lly,urx,ury,ro_instance,ro_x,ro_y,dx_from_ro,dy_from_ro,manhattan_from_ro,pd_center_x,pd_center_y,manhattan_to_pd_center,status,notes"

    set delay_fh [open $delay_path w]
    puts $delay_fh "family,tap,isolation_instance,isolation_cell_type,driver_instance,driver_cell_type,isolation_delay_ps,driver_delay_ps,total_chain_delay_ps,isolation_input_transition,isolation_output_transition,driver_input_transition,driver_output_transition,clock_name,notes"

    set route_fh [open $route_path w]
    puts $route_fh "family,tap,raw_net,raw_route_length_um,raw_total_cap_pf,isolation_net,isolation_route_length_um,isolation_total_cap_pf,buffered_net,buffered_route_length_um,buffered_total_cap_pf,buffered_wire_cap_pf,buffered_pin_cap_pf,buffered_res_ohm,status,notes"

    set sink_fh [open $sink_path w]
    puts $sink_fh "family,tap,source_pin,net,sink_pin,sink_class,sink_pin_cap_pf,sink_pin_cap_ff"

    set xlibd_fh [open $xlibd_path w]
    puts $xlibd_fh "family,tap,stage,source_pin,net,actual_cap_pf,actual_cap_fF,cap_bound_fF,analog_budget_ratio_strict,analog_budget_ratio_cn,equivalent_DFRRQHDX2_D_inputs,equivalent_DFRRQHDX2_C_inputs,equivalent_DFRRQHDX2_RN_inputs,driver_cell_type,driver_input_cap_fF,driver_output_max_cap_fF,driver_output_max_fanout,phase_driver_suitability,notes"

    set raw_xlibd_fh [open $raw_xlibd_path w]
    puts $raw_xlibd_fh "family,tap,raw_ro_pin,raw_net,actual_load_ff,strict_budget_ff,cn_budget_ff,strict_ratio,cn_ratio,first_cell_type,first_cell_input_cap_ff,first_cell_ratio_to_strict_budget,first_cell_ratio_to_cn_budget,budget_label,notes"

    set out_xlibd_fh [open $out_xlibd_path w]
    puts $out_xlibd_fh "family,tap,driver_pin,net,driver_cell_type,driver_output_max_cap_ff,actual_output_cap_ff,output_cap_ratio,actual_transition_ns,transition_status,equivalent_DFRRQHDX1_clk_loads,equivalent_DFRRQHDX2_clk_loads,equivalent_DFRQHDX2_clk_loads,equivalent_DFRHDX1_clk_loads,sink_classification,pd_load_count,fast_tag_load_count,slow_epoch_load_count,metadata_load_count,other_load_count,notes"

    set fast_tag_xlibd_fh [open $fast_tag_xlibd_path w]
    puts $fast_tag_xlibd_fh "family,tap,source_pin,net,sink_pin,sink_class,driver_cell_type,sink_cell_type,sink_pin_role,sink_actual_cap_ff,sink_reference_cap_ff,estimated_equivalent_load_count,notes"

    array set raw_labels {}
    array set out_labels {}
    array set topo_counts {}
    set raw_rows 0
    set raw_matched 0
    set raw_missing 0
    set raw_fanout1 0
    set raw_numeric 0
    set out_rows 0
    set out_matched 0
    set out_missing 0
    set out_numeric 0
    set topo_match 0
    set topo_bad 0
    set placement_numeric 0
    set max_raw_cap_ff ""
    set max_raw_desc ""
    set max_out_cap_ff ""
    set max_out_desc ""
    set max_transition_ps ""
    set max_transition_desc ""
    set min_ro_dist ""
    set max_ro_dist ""

    set pd_center [mptdc_o12b_pd_center]
    set pd_x [lindex $pd_center 0]
    set pd_y [lindex $pd_center 1]

    foreach family {slow fast} {
        set ro_inst [mptdc_o12b_ro_cell $family]
        set ro_center [mptdc_o12b_box_center [mptdc_o12b_cell_box $ro_inst]]
        set ro_x [lindex $ro_center 0]
        set ro_y [lindex $ro_center 1]

        for {set tap 0} {$tap < 8} {incr tap} {
            incr raw_rows
            incr out_rows

            set row [mptdc_o13_row_objects $family $tap]
            set raw_pins [lindex $row 0]
            set iso_a_pins [lindex $row 1]
            set iso_q_pins [lindex $row 2]
            set drv_a_pins [lindex $row 3]
            set drv_q_pins [lindex $row 4]
            set raw_pin [lindex $row 5]
            set iso_a_pin [lindex $row 6]
            set iso_q_pin [lindex $row 7]
            set drv_a_pin [lindex $row 8]
            set drv_q_pin [lindex $row 9]
            set raw_net [lindex $row 10]
            set iso_net [lindex $row 11]
            set out_net [lindex $row 12]
            set iso_inst [lindex $row 13]
            set drv_inst [lindex $row 14]

            set raw_net_obj [mptdc_o11_net_object $raw_net]
            set iso_net_obj [mptdc_o11_net_object $iso_net]
            set out_net_obj [mptdc_o11_net_object $out_net]

            set raw_prop_path "$reports_dir/net_property_${family}_${tap}_raw.rpt"
            set iso_prop_path "$reports_dir/net_property_${family}_${tap}_iso.rpt"
            set out_prop_path "$reports_dir/net_property_${family}_${tap}_buf.rpt"
            set iso_cell_prop_path "$reports_dir/cell_property_${family}_${tap}_iso.rpt"
            set drv_cell_prop_path "$reports_dir/cell_property_${family}_${tap}_drv.rpt"
            catch {mptdc_o12b_write_net_property_report $raw_prop_path $raw_net}
            catch {mptdc_o12b_write_net_property_report $iso_prop_path $iso_net}
            catch {mptdc_o12b_write_net_property_report $out_prop_path $out_net}
            catch {mptdc_o12b_write_cell_property_report $iso_cell_prop_path $iso_inst}
            catch {mptdc_o12b_write_cell_property_report $drv_cell_prop_path $drv_inst}

            set iso_cell_data [mptdc_o13_resolve_cell_type $iso_inst $iso_cell_prop_path]
            set drv_cell_data [mptdc_o13_resolve_cell_type $drv_inst $drv_cell_prop_path]
            set iso_cell_type [lindex $iso_cell_data 0]
            set drv_cell_type [lindex $drv_cell_data 0]
            set iso_cell_source [lindex $iso_cell_data 1]
            set drv_cell_source [lindex $drv_cell_data 1]

            set raw_fanout [mptdc_o12b_net_fanout_resolved $raw_net_obj $raw_prop_path]
            set out_fanout [mptdc_o12b_net_fanout_resolved $out_net_obj $out_prop_path]

            set raw_total_data [mptdc_o12b_net_metric_resolved $raw_net_obj total_cap $raw_prop_path]
            set raw_total_pf [lindex $raw_total_data 0]
            set raw_total_ff [mptdc_o12b_pf_to_ff $raw_total_pf]
            set raw_bound_ff ""
            set raw_notes [list]
            if {[llength $raw_pins] == 0} {
                incr raw_missing
                lappend raw_notes "NO_RAW_SOURCE_PIN_MATCH"
            } else {
                incr raw_matched
            }
            if {$raw_total_pf ne ""} {
                incr raw_numeric
                lappend raw_notes "RAW_CAP_SOURCE=[lindex $raw_total_data 1]"
            } else {
                set raw_bound_ff "50.00"
                lappend raw_notes "NO_NUMERIC_RAW_CAP_BOUND_50FF"
            }
            if {$raw_fanout eq "1"} { incr raw_fanout1 }
            set raw_label [mptdc_o12_budget_label_from_source $raw_total_ff $raw_bound_ff 1]
            if {![info exists raw_labels($raw_label)]} { set raw_labels($raw_label) 0 }
            incr raw_labels($raw_label)
            set raw_strict [mptdc_o13_xlibd_ratio_or_bound $raw_total_ff "" strict]
            set raw_cn [mptdc_o13_xlibd_ratio_or_bound $raw_total_ff "" cn]
            if {$raw_strict eq "" && $raw_bound_ff ne ""} {
                set raw_strict [mptdc_o13_xlibd_ratio_or_bound "" $raw_bound_ff strict]
                set raw_cn [mptdc_o13_xlibd_ratio_or_bound "" $raw_bound_ff cn]
            }
            if {[string is double -strict $raw_total_ff] && ($max_raw_cap_ff eq "" || $raw_total_ff > $max_raw_cap_ff)} {
                set max_raw_cap_ff $raw_total_ff
                set max_raw_desc [format {%s S[%d] %s} $family $tap $raw_pin]
            }
            set raw_sinks [join [mptdc_o11_net_load_names $raw_net_obj $raw_pin] ";"]
            puts $raw_fh [join [list \
                $family $tap [mptdc_o12b_csv $raw_pin] [llength $raw_pins] [mptdc_o12b_csv $raw_net] \
                $raw_fanout $raw_total_pf $raw_total_ff $raw_bound_ff $raw_label $raw_strict $raw_cn \
                [mptdc_o12b_csv $iso_a_pin] [mptdc_o12b_csv $raw_sinks] [mptdc_o12b_csv [join $raw_notes ";"]]] ","]

            set xlibd_iso_input_cap [mptdc_o13_xlibd_cell BUHDX4 input_cap_ff 10.56]
            set raw_xlibd_note "receiver_cell=BUHDX4;receiver_input_cap_ff=$xlibd_iso_input_cap;raw_ro_load_budget_is_analog_authoritative"
            mptdc_o13_write_xlibd_load_row $xlibd_fh $family $tap raw_ro_source $raw_pin $raw_net \
                $raw_total_pf $raw_total_ff $raw_bound_ff RO_tune4 "" "" "" $raw_label $raw_xlibd_note

            set first_cell_type $iso_cell_type
            if {$first_cell_type eq ""} { set first_cell_type "BUHDX4" }
            set first_cell_input_cap_ff [mptdc_o13_xlibd_cell $first_cell_type input_cap_ff ""]
            set raw_strict_budget [mptdc_o13_xlibd_budget_ff strict]
            set raw_cn_budget [mptdc_o13_xlibd_budget_ff cn]
            set first_strict_ratio [mptdc_o13_xlibd_ratio_to_value $first_cell_input_cap_ff $raw_strict_budget]
            set first_cn_ratio [mptdc_o13_xlibd_ratio_to_value $first_cell_input_cap_ff $raw_cn_budget]
            set raw_xlibd_row_notes $raw_notes
            if {$raw_total_ff eq ""} {
                lappend raw_xlibd_row_notes "ERROR_UNKNOWN_ACTUAL_CAP"
            }
            puts $raw_xlibd_fh [join [list \
                $family $tap [mptdc_o12b_csv $raw_pin] [mptdc_o12b_csv $raw_net] \
                $raw_total_ff $raw_strict_budget $raw_cn_budget $raw_strict $raw_cn \
                [mptdc_o12b_csv $first_cell_type] $first_cell_input_cap_ff $first_strict_ratio $first_cn_ratio \
                $raw_label [mptdc_o12b_csv [join $raw_xlibd_row_notes ";"]]] ","]

            set iso_total_data [mptdc_o12b_net_metric_resolved $iso_net_obj total_cap $iso_prop_path]
            set iso_route_data [mptdc_o12b_net_metric_resolved $iso_net_obj route_length $iso_prop_path]
            set total_data [mptdc_o12b_net_metric_resolved $out_net_obj total_cap $out_prop_path]
            set wire_data [mptdc_o12b_net_metric_resolved $out_net_obj wire_cap $out_prop_path]
            set pin_data [mptdc_o12b_net_metric_resolved $out_net_obj pin_cap $out_prop_path]
            set res_data [mptdc_o12b_net_metric_resolved $out_net_obj resistance $out_prop_path]
            set trans_data [mptdc_o12b_net_metric_resolved $out_net_obj transition $out_prop_path]
            set route_data [mptdc_o12b_net_metric_resolved $out_net_obj route_length $out_prop_path]
            set raw_route_data [mptdc_o12b_net_metric_resolved $raw_net_obj route_length $raw_prop_path]

            set iso_total_pf [lindex $iso_total_data 0]
            set iso_route_len [lindex $iso_route_data 0]
            set raw_route_len [lindex $raw_route_data 0]
            set total_pf [lindex $total_data 0]
            set wire_pf [lindex $wire_data 0]
            set pin_pf [lindex $pin_data 0]
            set res_ohm [lindex $res_data 0]
            set out_trans [lindex $trans_data 0]
            set route_len [lindex $route_data 0]
            set raw_route_len [lindex $raw_route_data 0]
            set total_ff [mptdc_o12b_pf_to_ff $total_pf]
            set wire_ff [mptdc_o12b_pf_to_ff $wire_pf]
            set pin_ff [mptdc_o12b_pf_to_ff $pin_pf]

            set out_notes [list]
            if {[llength $drv_q_pins] == 0} {
                incr out_missing
                lappend out_notes "NO_FINAL_DRIVER_OUTPUT_PIN_MATCH"
            } else {
                incr out_matched
            }
            if {$total_pf ne ""} {
                incr out_numeric
                lappend out_notes "TOTAL_CAP_SOURCE=[lindex $total_data 1]"
            } else {
                set out_notes [mptdc_o12b_note_metric_unavailable $out_notes TOTAL_CAP $out_net_obj]
            }
            if {$wire_pf ne ""} { lappend out_notes "WIRE_CAP_SOURCE=[lindex $wire_data 1]" }
            if {$pin_pf ne ""} { lappend out_notes "PIN_CAP_SOURCE=[lindex $pin_data 1]" }
            if {$res_ohm ne ""} { lappend out_notes "RESISTANCE_SOURCE=[lindex $res_data 1]" }
            if {$out_trans ne ""} {
                lappend out_notes "TRANSITION_SOURCE=[lindex $trans_data 1]"
                if {$max_transition_ps eq "" || $out_trans > $max_transition_ps} {
                    set max_transition_ps $out_trans
                    set max_transition_desc [format {%s tap[%d] %s} $family $tap $drv_q_pin]
                }
            }
            if {$route_len ne ""} { lappend out_notes "ROUTE_LENGTH_SOURCE=[lindex $route_data 1]" }

            set sink_names [mptdc_o11_net_load_names $out_net_obj $drv_q_pin]
            set pd_count 0
            set fast_tag_count 0
            set slow_epoch_count 0
            set metadata_count 0
            set other_count 0
            foreach sink $sink_names {
                set class [mptdc_o11_sink_class $family $sink]
                if {$class eq "PD_FAST_CLOCK" || $class eq "PD_SLOW_DATA"} {
                    incr pd_count
                } elseif {$class eq "FAST_TAG_CLOCK" || $class eq "FAST_TAG_DATA"} {
                    incr fast_tag_count
                } elseif {$class eq "SLOW_EPOCH_CLOCK"} {
                    incr slow_epoch_count
                } elseif {$class eq "BOUNDARY_METADATA" || $class eq "OTHER_CLOCK_OR_METADATA"} {
                    incr metadata_count
                } else {
                    incr other_count
                }
                set sink_cap [lindex [mptdc_o12b_pin_metric $sink cap] 0]
                puts $sink_fh [join [list \
                    $family $tap [mptdc_o12b_csv $drv_q_pin] [mptdc_o12b_csv $out_net] \
                    [mptdc_o12b_csv $sink] $class $sink_cap [mptdc_o12b_pf_to_ff $sink_cap]] ","]
                if {$class eq "FAST_TAG_CLOCK" || $class eq "FAST_TAG_DATA"} {
                    set sink_cell_type [mptdc_o13_sink_cell_type $sink]
                    set sink_role [mptdc_o13_sink_pin_tail $sink]
                    set sink_field [mptdc_o13_sink_cap_field $sink]
                    set sink_cap_ff [mptdc_o12b_pf_to_ff $sink_cap]
                    set sink_ref_cap_ff ""
                    set sink_equiv_count ""
                    set sink_notes [list]
                    if {$sink_cell_type eq ""} {
                        lappend sink_notes "SINK_CELL_TYPE_UNKNOWN"
                    }
                    if {$sink_field eq ""} {
                        lappend sink_notes "SINK_PIN_ROLE_UNMAPPED"
                    } else {
                        set sink_ref_cap_ff [mptdc_o13_xlibd_cell $sink_cell_type $sink_field ""]
                        if {$sink_ref_cap_ff eq ""} {
                            lappend sink_notes "REFERENCE_PIN_CAP_UNKNOWN"
                        }
                    }
                    if {$sink_cap_ff ne "" && $sink_ref_cap_ff ne ""} {
                        set sink_equiv_count [mptdc_o13_xlibd_ratio_to_value $sink_cap_ff $sink_ref_cap_ff]
                    }
                    if {$sink_cap_ff eq ""} {
                        lappend sink_notes "ACTUAL_PIN_CAP_UNKNOWN"
                    }
                    puts $fast_tag_xlibd_fh [join [list \
                        $family $tap [mptdc_o12b_csv $drv_q_pin] [mptdc_o12b_csv $out_net] \
                        [mptdc_o12b_csv $sink] $class [mptdc_o12b_csv $drv_cell_type] \
                        [mptdc_o12b_csv $sink_cell_type] $sink_role $sink_cap_ff $sink_ref_cap_ff \
                        $sink_equiv_count [mptdc_o12b_csv [join $sink_notes ";"]]] ","]
                }
            }

            set iso_in_cap_pf [lindex [mptdc_o12b_pin_metric $iso_a_pin cap] 0]
            set iso_in_cap_ff [mptdc_o12b_pf_to_ff $iso_in_cap_pf]
            set drv_in_cap_pf [lindex [mptdc_o12b_pin_metric $drv_a_pin cap] 0]
            set drv_in_cap_ff [mptdc_o12b_pf_to_ff $drv_in_cap_pf]
            set out_label [mptdc_o11_budget_label $total_ff]
            set out_strict [mptdc_o13_xlibd_ratio_or_bound $total_ff "" strict]
            set out_cn [mptdc_o13_xlibd_ratio_or_bound $total_ff "" cn]
            set out_status [expr {$total_pf ne "" ? "FINAL_DRIVER_OUTPUT_QUANTIFIED" : "FINAL_DRIVER_OUTPUT_UNQUANTIFIED"}]
            if {![info exists out_labels($out_label)]} { set out_labels($out_label) 0 }
            incr out_labels($out_label)
            if {[string is double -strict $total_ff] && ($max_out_cap_ff eq "" || $total_ff > $max_out_cap_ff)} {
                set max_out_cap_ff $total_ff
                set max_out_desc [format {%s tap[%d] %s} $family $tap $drv_q_pin]
            }

            puts $out_fh [join [list \
                $family $tap [mptdc_o12b_csv $raw_pin] [mptdc_o12b_csv $raw_net] \
                [mptdc_o12b_csv $iso_inst] [mptdc_o12b_csv $iso_cell_type] [mptdc_o12b_csv $iso_a_pin] [mptdc_o12b_csv $iso_q_pin] [mptdc_o12b_csv $iso_net] \
                [mptdc_o12b_csv $drv_inst] [mptdc_o12b_csv $drv_cell_type] [mptdc_o12b_csv $drv_a_pin] [mptdc_o12b_csv $drv_q_pin] [mptdc_o12b_csv $out_net] \
                $out_fanout $total_pf $total_ff $wire_pf $wire_ff $pin_pf $pin_ff $res_ohm $out_trans $route_len $out_status \
                [llength $sink_names] $pd_count $fast_tag_count $slow_epoch_count $metadata_count $other_count \
                $iso_in_cap_pf $iso_in_cap_ff $drv_in_cap_pf $drv_in_cap_ff $raw_total_pf $raw_total_ff \
                $out_label $out_strict $out_cn [mptdc_o12b_csv [join $out_notes ";"]]] ","]

            set xlibd_drv_in_cap [mptdc_o13_xlibd_cell $drv_cell_type input_cap_ff ""]
            set xlibd_drv_out_max_cap [mptdc_o13_xlibd_cell $drv_cell_type output_max_cap_ff ""]
            set xlibd_drv_out_max_fanout [mptdc_o13_xlibd_cell $drv_cell_type output_max_fanout ""]
            set xlibd_drv_suitability [mptdc_o13_xlibd_driver_suitability $drv_cell_type $total_ff $out_fanout $out_trans]
            set out_xlibd_note "wire_cap_ff=$wire_ff;pin_cap_ff=$pin_ff;pd_load_count=$pd_count;fast_tag_load_count=$fast_tag_count;slow_epoch_load_count=$slow_epoch_count;metadata_load_count=$metadata_count;other_load_count=$other_count"
            mptdc_o13_write_xlibd_load_row $xlibd_fh $family $tap final_phase_driver_output $drv_q_pin $out_net \
                $total_pf $total_ff "" $drv_cell_type $xlibd_drv_in_cap $xlibd_drv_out_max_cap \
                $xlibd_drv_out_max_fanout $xlibd_drv_suitability $out_xlibd_note

            set sink_classification [format {PD=%d;FAST_TAG=%d;SLOW_EPOCH=%d;METADATA=%d;OTHER=%d} \
                $pd_count $fast_tag_count $slow_epoch_count $metadata_count $other_count]
            set output_cap_ratio [mptdc_o13_xlibd_ratio_to_value $total_ff $xlibd_drv_out_max_cap]
            set out_xlibd_row_notes $out_notes
            if {$total_ff eq ""} {
                lappend out_xlibd_row_notes "ERROR_UNKNOWN_ACTUAL_OUTPUT_CAP"
            }
            puts $out_xlibd_fh [join [list \
                $family $tap [mptdc_o12b_csv $drv_q_pin] [mptdc_o12b_csv $out_net] \
                [mptdc_o12b_csv $drv_cell_type] $xlibd_drv_out_max_cap $total_ff $output_cap_ratio \
                [mptdc_o13_ps_to_ns $out_trans] [mptdc_o13_transition_status $out_trans] \
                [mptdc_o13_xlibd_equiv_cell_load $total_ff DFRRQHDX1 clk_cap_ff] \
                [mptdc_o13_xlibd_equiv_cell_load $total_ff DFRRQHDX2 clk_cap_ff] \
                [mptdc_o13_xlibd_equiv_cell_load $total_ff DFRQHDX2 clk_cap_ff] \
                [mptdc_o13_xlibd_equiv_cell_load $total_ff DFRHDX1 clk_cap_ff] \
                [mptdc_o12b_csv $sink_classification] $pd_count $fast_tag_count $slow_epoch_count \
                $metadata_count $other_count [mptdc_o12b_csv [join $out_xlibd_row_notes ";"]]] ","]

            set topo_status "TOPOLOGY_MATCH"
            set topo_notes [list]
            set sequence [join [list $iso_cell_type $drv_cell_type] ";"]
            if {$raw_pin eq "" || $iso_a_pin eq "" || $iso_q_pin eq "" || $drv_a_pin eq "" || $drv_q_pin eq "" || $iso_inst eq "" || $drv_inst eq ""} {
                set topo_status "MISSING_BUFFER"
                lappend topo_notes "missing raw/iso/driver pin or instance"
            } elseif {$iso_cell_type ne "BUHDX4" || $drv_cell_type ne "BUHDX12"} {
                if {$iso_cell_type eq "" || $drv_cell_type eq ""} {
                    set topo_status "TOPOLOGY_SHAPE_MATCHED"
                    lappend topo_notes "CELL_TYPE_UNRESOLVED_BY_DB"
                } else {
                    set topo_status "TOPOLOGY_MISMATCH"
                    lappend topo_notes "expected BUHDX4;BUHDX12 got $sequence"
                }
            } else {
                lappend topo_notes "CELL_SEQUENCE=BUHDX4;BUHDX12"
                lappend topo_notes "ISO_CELL_SOURCE=$iso_cell_source"
                lappend topo_notes "DRV_CELL_SOURCE=$drv_cell_source"
            }
            if {$raw_fanout ne "" && $raw_fanout ne "1"} {
                set topo_status "EXTRA_BUFFER"
                lappend topo_notes "raw_fanout=$raw_fanout"
            }
            if {![info exists topo_counts($topo_status)]} { set topo_counts($topo_status) 0 }
            incr topo_counts($topo_status)
            if {$topo_status eq "TOPOLOGY_MATCH" || $topo_status eq "TOPOLOGY_SHAPE_MATCHED"} {
                incr topo_match
            } else {
                incr topo_bad
            }
            puts $topo_fh [join [list \
                $family $tap 2 [mptdc_o12b_csv $sequence] [mptdc_o12b_csv $raw_net] \
                [mptdc_o12b_csv $iso_net] [mptdc_o12b_csv $out_net] $topo_status [mptdc_o12b_csv [join $topo_notes ";"]]] ","]

            mptdc_o13_write_stage_placement $place_fh $family $tap isolation $iso_inst $iso_cell_type $ro_inst $ro_x $ro_y $pd_x $pd_y placement_numeric min_ro_dist max_ro_dist
            mptdc_o13_write_stage_placement $place_fh $family $tap driver $drv_inst $drv_cell_type $ro_inst $ro_x $ro_y $pd_x $pd_y placement_numeric min_ro_dist max_ro_dist

            set iso_in_trans [lindex [mptdc_o12b_pin_metric $iso_a_pin transition] 0]
            set iso_out_trans [lindex [mptdc_o12b_pin_metric $iso_q_pin transition] 0]
            set drv_in_trans [lindex [mptdc_o12b_pin_metric $drv_a_pin transition] 0]
            set drv_out_trans [lindex [mptdc_o12b_pin_metric $drv_q_pin transition] 0]
            set iso_delay_ps [mptdc_o13_delay_ps $iso_a_pin $iso_q_pin]
            set drv_delay_ps [mptdc_o13_delay_ps $drv_a_pin $drv_q_pin]
            set total_delay_ps ""
            if {$iso_delay_ps ne "" && $drv_delay_ps ne ""} {
                set total_delay_ps [format "%.2f" [expr {$iso_delay_ps + $drv_delay_ps}]]
            }
            set delay_notes [list]
            if {$iso_delay_ps eq ""} { lappend delay_notes "ISO_DELAY_ATTR_UNAVAILABLE" }
            if {$drv_delay_ps eq ""} { lappend delay_notes "DRV_DELAY_ATTR_UNAVAILABLE" }
            puts $delay_fh [join [list \
                $family $tap [mptdc_o12b_csv $iso_inst] [mptdc_o12b_csv $iso_cell_type] \
                [mptdc_o12b_csv $drv_inst] [mptdc_o12b_csv $drv_cell_type] \
                $iso_delay_ps $drv_delay_ps $total_delay_ps \
                $iso_in_trans $iso_out_trans $drv_in_trans $drv_out_trans \
                [mptdc_o13_clock_for $family $tap] [mptdc_o12b_csv [join $delay_notes ";"]]] ","]

            puts $route_fh [join [list \
                $family $tap [mptdc_o12b_csv $raw_net] $raw_route_len $raw_total_pf \
                [mptdc_o12b_csv $iso_net] $iso_route_len $iso_total_pf \
                [mptdc_o12b_csv $out_net] $route_len $total_pf $wire_pf $pin_pf $res_ohm \
                $out_status [mptdc_o12b_csv "raw_iso_and_final_driver_route_from_report_property_when_available"]]] ","]
        }
    }

    close $raw_fh
    close $out_fh
    close $topo_fh
    close $place_fh
    close $delay_fh
    close $route_fh
    close $sink_fh
    close $xlibd_fh
    close $raw_xlibd_fh
    close $out_xlibd_fh
    close $fast_tag_xlibd_fh

    set raw_fixed [expr {$raw_matched == 16 && $raw_missing == 0 && $raw_fanout1 == 16 ? "YES" : "NO"}]
    set out_quantified [expr {$out_matched == 16 && $out_numeric == 16 ? "YES" : "NO"}]
    set topology_ok [expr {$topo_match == 16 && $topo_bad == 0 ? "YES" : "NO"}]
    set placement_quantified [expr {$placement_numeric == 32 ? "YES" : "NO"}]
    set timing_quality [expr {$out_quantified eq "YES" && $topology_ok eq "YES" && $placement_quantified eq "YES" ? "YES" : "NO"}]

    set bfh [open $xlibd_budget_path w]
    puts $bfh "# O13 Phase Net XLIBD Load Budget Summary"
    puts $bfh ""
    puts $bfh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $bfh ""
    puts $bfh "- Source run: `[mptdc_o13_source_run_id]`"
    puts $bfh "- XLIBD library: `[mptdc_o13_xlibd_get source.library D_CELLS_HD_LPMOS_typ_1.80V_25C]`"
    puts $bfh "- Strict analog RO D-load budget: `[mptdc_o13_xlibd_budget_ff strict] fF`."
    puts $bfh "- CN/clock-like analog estimate: `[mptdc_o13_xlibd_budget_ff cn] fF`."
    puts $bfh "- DFRRQHDX1 D/C/RN caps: `[mptdc_o13_xlibd_cell DFRRQHDX1 d_cap_ff 3.19]` / `[mptdc_o13_xlibd_cell DFRRQHDX1 clk_cap_ff 3.62]` / `[mptdc_o13_xlibd_cell DFRRQHDX1 rn_cap_ff 7.32]` fF."
    puts $bfh "- DFRRQHDX2 D/C/RN caps: `[mptdc_o13_xlibd_cell DFRRQHDX2 d_cap_ff 3.20]` / `[mptdc_o13_xlibd_cell DFRRQHDX2 clk_cap_ff 3.45]` / `[mptdc_o13_xlibd_cell DFRRQHDX2 rn_cap_ff 6.51]` fF."
    puts $bfh "- DFRQHDX2 D/C caps: `[mptdc_o13_xlibd_cell DFRQHDX2 d_cap_ff 2.70]` / `[mptdc_o13_xlibd_cell DFRQHDX2 clk_cap_ff 3.63]` fF."
    puts $bfh "- DFRHDX1 D/C caps: `[mptdc_o13_xlibd_cell DFRHDX1 d_cap_ff 2.71]` / `[mptdc_o13_xlibd_cell DFRHDX1 clk_cap_ff 3.63]` fF."
    puts $bfh "- BUHDX4 input cap: `[mptdc_o13_xlibd_cell BUHDX4 input_cap_ff 10.56] fF`."
    puts $bfh "- BUHDX12 input cap: `[mptdc_o13_xlibd_cell BUHDX12 input_cap_ff 32.24] fF`."
    if {$max_raw_cap_ff ne ""} {
        puts $bfh "- Max measured raw RO source load: `$max_raw_cap_ff fF` at `$max_raw_desc`."
        puts $bfh "- Max raw equivalent DFRRQHDX2 D/C/RN inputs: `[mptdc_o13_xlibd_equiv_or_bound $max_raw_cap_ff "" d]` / `[mptdc_o13_xlibd_equiv_or_bound $max_raw_cap_ff "" c]` / `[mptdc_o13_xlibd_equiv_or_bound $max_raw_cap_ff "" rn]`."
    } else {
        puts $bfh "- Max measured raw RO source load: `UNKNOWN`."
    }
    if {$max_out_cap_ff ne ""} {
        puts $bfh "- Max measured final driver output load: `$max_out_cap_ff fF` at `$max_out_desc`."
        puts $bfh "- Max final-output equivalent DFRRQHDX2 D/C/RN inputs: `[mptdc_o13_xlibd_equiv_or_bound $max_out_cap_ff "" d]` / `[mptdc_o13_xlibd_equiv_or_bound $max_out_cap_ff "" c]` / `[mptdc_o13_xlibd_equiv_or_bound $max_out_cap_ff "" rn]`."
    } else {
        puts $bfh "- Max measured final driver output load: `UNKNOWN`."
    }
    puts $bfh ""
    puts $bfh "Required companion CSVs: `ro_phase_raw_pin_loads_xlibd.csv`, `phase_buffer_output_loads_xlibd.csv`, `fast_tag_loads_xlibd.csv`, and `phase_net_loads_xlibd_enhanced.csv`."
    puts $bfh ""
    puts $bfh "This summary does not waive analog RO budgets or Liberty design-rule checks."
    close $bfh

    set ifh [open $xlibd_interp_path w]
    puts $ifh "# O13 Phase Buffer XLIBD Interpretation"
    puts $ifh ""
    puts $ifh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $ifh ""
    puts $ifh "- Preferred topology: `RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric`."
    puts $ifh "- BUHDX4 input cap: `[mptdc_o13_xlibd_cell BUHDX4 input_cap_ff 10.56] fF`, safely below the strict `[mptdc_o13_xlibd_budget_ff strict] fF` analog budget."
    puts $ifh "- BUHDX12 input cap: `[mptdc_o13_xlibd_cell BUHDX12 input_cap_ff 32.24] fF`, also under strict budget but less isolated than BUHDX4."
    puts $ifh "- INHDX12 input cap: `[mptdc_o13_xlibd_cell INHDX12 input_cap_ff 55.64] fF`, close to strict budget; do not place directly on RO without analog review."
    puts $ifh "- BUHDX2/BUHDX3 input caps: `[mptdc_o13_xlibd_cell BUHDX2 input_cap_ff 5.72]` / `[mptdc_o13_xlibd_cell BUHDX3 input_cap_ff 8.07] fF`; useful intermediate-drive choices but not final drivers for 0.5-0.7 pF phase loads."
    puts $ifh "- BUHDX4 at `0.8075 pF`: rise/fall transition `[mptdc_o13_xlibd_cell BUHDX4 timing.load_0p8075_pf.rise_transition_ns 1.1716]` / `[mptdc_o13_xlibd_cell BUHDX4 timing.load_0p8075_pf.fall_transition_ns 0.8442] ns`."
    puts $ifh "- BUHDX3 at `0.6058 pF`: rise/fall transition `[mptdc_o13_xlibd_cell BUHDX3 timing.load_0p6058_pf.rise_transition_ns 1.1723]` / `[mptdc_o13_xlibd_cell BUHDX3 timing.load_0p6058_pf.fall_transition_ns 0.8588] ns`, too weak for preferred final phase drive."
    puts $ifh "- BUHDX12 at `0.6058 pF`: rise/fall transition `[mptdc_o13_xlibd_cell BUHDX12 timing.load_0p6058_pf.rise_transition_ns 0.3080]` / `[mptdc_o13_xlibd_cell BUHDX12 timing.load_0p6058_pf.fall_transition_ns 0.2295] ns`."
    puts $ifh "- BUHDX12 at `1.2106 pF`: rise/fall transition `[mptdc_o13_xlibd_cell BUHDX12 timing.load_1p2106_pf.rise_transition_ns 0.5955]` / `[mptdc_o13_xlibd_cell BUHDX12 timing.load_1p2106_pf.fall_transition_ns 0.4391] ns`."
    puts $ifh ""
    puts $ifh "Decision: `BUHDX4 -> BUHDX12` remains the preferred O13 topology. If routed transition still fails, evaluate matched `BUHDX4 -> BUHDX12 -> BUHDX12` next."
    puts $ifh ""
    puts $ifh "This report is interpretation only. The timing engine remains the full Liberty view used by Genus/Innovus."
    close $ifh

    set sfh [open $summary_path w]
    puts $sfh "# O13 Phase Distribution Balance Summary"
    puts $sfh ""
    puts $sfh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $sfh ""
    puts $sfh "- Source run: `[mptdc_o13_source_run_id]`"
    puts $sfh "- Strict analog D-load budget: `[mptdc_o13_xlibd_budget_ff strict] fF`."
    puts $sfh "- CN/clock-like estimate: `[mptdc_o13_xlibd_budget_ff cn] fF`."
    puts $sfh "- Expected topology: `RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric`."
    puts $sfh "- XLIBD reference: `ro_phase_raw_pin_loads_xlibd.csv`, `phase_buffer_output_loads_xlibd.csv`, `fast_tag_loads_xlibd.csv`, `phase_net_loads_xlibd_enhanced.csv`, `phase_net_load_budget_summary.md`, `phase_buffer_xlibd_interpretation.md`."
    puts $sfh "- RAW_RO_LOAD_FIXED=$raw_fixed"
    puts $sfh "- FINAL_DRIVER_OUTPUT_LOAD_QUANTIFIED=$out_quantified"
    puts $sfh "- TOPOLOGY_MATCHED=$topology_ok"
    puts $sfh "- PLACEMENT_QUANTIFIED=$placement_quantified"
    puts $sfh "- TIMING_DECISION_QUALITY=$timing_quality"
    puts $sfh "- Raw RO rows: $raw_rows."
    puts $sfh "- Matched raw RO rows: $raw_matched."
    puts $sfh "- Missing raw RO rows: $raw_missing."
    puts $sfh "- Raw fanout-1 rows: $raw_fanout1."
    puts $sfh "- Raw rows with numeric DB cap: $raw_numeric."
    puts $sfh "- Final driver output rows: $out_rows."
    puts $sfh "- Matched final driver output rows: $out_matched."
    puts $sfh "- Missing final driver output rows: $out_missing."
    puts $sfh "- Final driver output rows with numeric DB cap: $out_numeric."
    if {$max_raw_cap_ff ne ""} {
        puts $sfh "- Max measured raw RO source load: `$max_raw_cap_ff fF` at `$max_raw_desc`."
    } else {
        puts $sfh "- Max measured raw RO source load: `UNKNOWN`; raw rows still require numeric/report-property evidence."
    }
    if {$max_out_cap_ff ne ""} {
        puts $sfh "- Max measured final driver output load: `$max_out_cap_ff fF` at `$max_out_desc`."
    } else {
        puts $sfh "- Max measured final driver output load: `UNKNOWN`."
    }
    if {$max_transition_ps ne ""} {
        puts $sfh "- Max measured final driver output transition: `$max_transition_ps` at `$max_transition_desc`."
    } else {
        puts $sfh "- Max measured final driver output transition: `UNKNOWN`."
    }
    puts $sfh ""
    puts $sfh "## Raw RO Budget Labels"
    puts $sfh ""
    puts $sfh "| Label | Row count |"
    puts $sfh "|---|---:|"
    foreach label {OK_STRICT OK_CN WARN_OVER_CN FAIL_HIGH_LOAD CRITICAL UNKNOWN} {
        set count 0
        if {[info exists raw_labels($label)]} { set count $raw_labels($label) }
        puts $sfh "| $label | $count |"
    }
    puts $sfh ""
    puts $sfh "## Final Driver Output Labels"
    puts $sfh ""
    puts $sfh "| Label | Row count |"
    puts $sfh "|---|---:|"
    foreach label {OK_STRICT OK_CN WARN_OVER_CN FAIL_HIGH_LOAD CRITICAL UNKNOWN} {
        set count 0
        if {[info exists out_labels($label)]} { set count $out_labels($label) }
        puts $sfh "| $label | $count |"
    }
    puts $sfh ""
    puts $sfh "This is O13 feasibility/debug evidence only. It does not waive timing, phase matching, characterization, power, or signoff."
    close $sfh

    set tfh [open $topo_summary_path w]
    puts $tfh "# O13 Phase Buffer Topology Summary"
    puts $tfh ""
    puts $tfh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $tfh ""
    puts $tfh "- Source run: `[mptdc_o13_source_run_id]`"
    puts $tfh "- Expected physical topology: `BUHDX4 -> BUHDX12` per tap."
    puts $tfh "- Expected RTL define: `MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12`."
    puts $tfh "- TOPOLOGY_MATCH/SHAPE rows: $topo_match of 16."
    puts $tfh "- Topology problem rows: $topo_bad of 16."
    puts $tfh ""
    puts $tfh "## Status Counts"
    puts $tfh ""
    puts $tfh "| Status | Row count |"
    puts $tfh "|---|---:|"
    foreach status {TOPOLOGY_MATCH TOPOLOGY_SHAPE_MATCHED MISSING_BUFFER EXTRA_BUFFER TOPOLOGY_MISMATCH} {
        set count 0
        if {[info exists topo_counts($status)]} { set count $topo_counts($status) }
        puts $tfh "| $status | $count |"
    }
    close $tfh

    set pfh [open $place_summary_path w]
    puts $pfh "# O13 Phase Buffer Placement Summary"
    puts $pfh ""
    puts $pfh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $pfh ""
    puts $pfh "- Source run: `[mptdc_o13_source_run_id]`"
    puts $pfh "- Placement rows with numeric buffer location: $placement_numeric of 32."
    if {$min_ro_dist ne "" && $max_ro_dist ne ""} {
        puts $pfh "- RO-to-buffer Manhattan distance min/max: `$min_ro_dist` / `$max_ro_dist` database units."
        puts $pfh "- RO-to-buffer Manhattan mismatch: `[expr {$max_ro_dist - $min_ro_dist}]` database units."
    } else {
        puts $pfh "- RO-to-buffer Manhattan distance: `UNKNOWN`."
    }
    puts $pfh ""
    puts $pfh "O13 placement is closure-quality only when first-stage BUHDX4 cells stay close to RO pins and second-stage BUHDX12 cells are ordered and balanced before digital distribution."
    close $pfh
}
