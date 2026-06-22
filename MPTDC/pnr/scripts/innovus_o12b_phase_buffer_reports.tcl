# =============================================================================
# O12B phase-buffer balance reports
#
# Report-only helpers for an already routed O12 checkpoint.  The key difference
# from the O12 load report is that this file tries to measure the BUHDX4 output
# nets directly from the restored Innovus DB instead of relying only on
# max-capacitance violation rows.
# =============================================================================

set ::env(MPTDC_O12_SOURCE_ONLY) 1
source [file join [file dirname [file normalize [info script]]] innovus_o12_phase_buffer_reports.tcl]

proc mptdc_o12b_csv {value} {
    return [mptdc_o11_csv $value]
}

proc mptdc_o12b_scalar {value} {
    if {[catch {set len [llength $value]}]} {
        return "$value"
    }
    if {$len == 1} {
        if {![catch {set item [lindex $value 0]}]} {
            return $item
        }
    }
    return $value
}

proc mptdc_o12b_num {value} {
    set value [mptdc_o12b_scalar $value]
    if {[regexp {^0x[0-9A-Fa-f]+$} "$value"]} {
        return ""
    }
    if {[string is double -strict $value]} {
        return $value
    }
    if {[regexp {^(-?[0-9]+(\.[0-9]*)?([eE][-+]?[0-9]+)?)$} "$value" -> num]} {
        return $num
    }
    return ""
}

proc mptdc_o12b_numeric_tokens {value} {
    set nums [list]
    if {[catch {set len [llength $value]}]} {
        set items [list "$value"]
    } else {
        set items $value
        if {$len == 0} {
            set items [list "$value"]
        }
    }
    foreach item $items {
        set num [mptdc_o12b_num $item]
        if {$num ne ""} {
            lappend nums $num
            continue
        }
        if {[regexp {^0x[0-9A-Fa-f]+$} "$item"]} {
            continue
        }
        foreach match [regexp -all -inline {[-+]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][-+]?[0-9]+)?} "$item"] {
            lappend nums $match
        }
    }
    return $nums
}

proc mptdc_o12b_first_numeric_token {value} {
    set nums [mptdc_o12b_numeric_tokens $value]
    if {[llength $nums] == 0} {
        return ""
    }
    return [lindex $nums 0]
}

proc mptdc_o12b_bbox_manhattan_from_sizes {sx_value sy_value source} {
    set sx [mptdc_o12b_first_numeric_token $sx_value]
    set sy [mptdc_o12b_first_numeric_token $sy_value]
    if {$sx eq "" || $sy eq ""} {
        return [list "" ""]
    }
    return [list [format "%.6f" [expr {abs($sx) + abs($sy)}]] $source]
}

proc mptdc_o12b_bbox_manhattan_from_box {box source} {
    set nums [mptdc_o12b_numeric_tokens $box]
    if {[llength $nums] < 4} {
        return [list "" ""]
    }
    set llx [lindex $nums 0]
    set lly [lindex $nums 1]
    set urx [lindex $nums 2]
    set ury [lindex $nums 3]
    return [list [format "%.6f" [expr {abs($urx - $llx) + abs($ury - $lly)}]] $source]
}

proc mptdc_o12b_db_object_query_safe {object} {
    if {$object eq ""} { return 0 }
    if {[llength [info commands mptdc_o11_internal_net_token_name]] > 0
        && [mptdc_o11_internal_net_token_name $object] ne ""} {
        return 0
    }
    if {[llength [info commands mptdc_o11_normalized_object_token]] > 0} {
        set text [mptdc_o11_normalized_object_token $object]
    } else {
        set text [string trim "$object"]
    }
    if {[regexp {^net:.+[/.]iso_tap$} $text] || [regexp {(^|[/.])iso_tap$} $text]} {
        return 0
    }
    if {[regexp {^(0x[0-9A-Fa-f]+|[A-Za-z_][A-Za-z0-9_]*:)} $text]} {
        return 1
    }
    if {[regexp {[][{}"[:space:]]} $text]} {
        return 0
    }
    if {[string first "/" $text] >= 0} {
        return 0
    }
    return 1
}

proc mptdc_o12b_property_value {path property} {
    if {$path eq "" || ![file exists $path]} { return "" }
    set fh [open $path r]
    set value ""
    while {[gets $fh line] >= 0} {
        if {[regexp {^[[:space:]]*([^|[:space:]][^|]*?)[[:space:]]*\|[[:space:]]*(.*?)[[:space:]]*$} $line -> key raw_value]} {
            set key [string trim $key]
            if {$key eq $property} {
                set value [string trim $raw_value]
                break
            }
        }
    }
    close $fh
    return $value
}

proc mptdc_o12b_first_property_numeric {path properties} {
    foreach property $properties {
        set value [mptdc_o12b_num [mptdc_o12b_property_value $path $property]]
        if {$value ne ""} {
            return [list $value "property_file:$property"]
        }
    }
    return [list "" ""]
}

proc mptdc_o12b_first_property_text {path properties} {
    foreach property $properties {
        set value [mptdc_o12b_property_value $path $property]
        if {$value ne ""} {
            return [list $value "property_file:$property"]
        }
    }
    return [list "" ""]
}

proc mptdc_o12b_db_attrs_for {object} {
    global mptdc_o12b_attr_cache
    if {$object eq ""} { return [list] }
    set key "$object"
    if {[info exists mptdc_o12b_attr_cache($key)]} {
        return $mptdc_o12b_attr_cache($key)
    }
    if {![mptdc_o12b_db_object_query_safe $object]} {
        set mptdc_o12b_attr_cache($key) [list]
        return [list]
    }

    set attrs [list]
    if {![catch {set raw_attrs [get_db $object .?]}]} {
        if {[catch {
            foreach raw $raw_attrs {
                set token [string trim [lindex $raw 0]]
                if {$token eq ""} { continue }
                lappend attrs $token
            }
        }]} {
            foreach raw [split "$raw_attrs" "\n"] {
                set token [string trim $raw]
                if {$token eq ""} { continue }
                lappend attrs $token
            }
        }
    }
    set mptdc_o12b_attr_cache($key) $attrs
    return $attrs
}

proc mptdc_o12b_db_attr_supported {object attr} {
    set attr_name [string trimleft $attr .]
    if {$attr_name eq ""} { return 0 }
    set parent [lindex [split $attr_name "."] 0]
    foreach raw_attr [mptdc_o12b_db_attrs_for $object] {
        set norm [string trimleft $raw_attr .]
        if {$norm eq $attr_name} {
            return 1
        }
        if {[string first "." $attr_name] >= 0 && $norm eq $parent} {
            return 1
        }
    }
    return 0
}

proc mptdc_o12b_db_attr {object attr} {
    if {$object eq ""} { return "" }
    if {![mptdc_o12b_db_object_query_safe $object]} { return "" }
    set attrs [mptdc_o12b_db_attrs_for $object]
    if {[llength $attrs] == 0} {
        return ""
    }
    if {![mptdc_o12b_db_attr_supported $object $attr]} {
        return ""
    }
    set val ""
    if {![catch {set val [get_db $object $attr]}] && $val ne ""} {
        return [mptdc_o12b_scalar $val]
    }
    return ""
}

proc mptdc_o12b_first_numeric_attr {object attrs} {
    foreach attr $attrs {
        set val [mptdc_o12b_num [mptdc_o12b_db_attr $object $attr]]
        if {$val ne ""} {
            return [list $val $attr]
        }
    }
    return [list "" ""]
}

proc mptdc_o12b_first_text_attr {object attrs} {
    foreach attr $attrs {
        set val [mptdc_o12b_db_attr $object $attr]
        if {$val ne ""} {
            return [list $val $attr]
        }
    }
    return [list "" ""]
}

proc mptdc_o12b_db_attr_raw_supported {object attr} {
    if {$object eq ""} { return "" }
    if {![mptdc_o12b_db_object_query_safe $object]} { return "" }
    if {![mptdc_o12b_db_attr_supported $object $attr]} { return "" }
    set val ""
    if {![catch {set val [get_db $object $attr]}] && $val ne ""} {
        return $val
    }
    return ""
}

proc mptdc_o12b_expected_phase_cell_type {} {
    global o12b
    if {[info exists ::mptdc_o12b_expected_phase_cell_type]} {
        return $::mptdc_o12b_expected_phase_cell_type
    }
    set ::mptdc_o12b_expected_phase_cell_type ""
    set filelist "$o12b(mptdc_root)/syn/filelist_o12_phase_isolation.f"
    set rtl "$o12b(mptdc_root)/rtl/osc/mptdc_phase_buffer_bank.sv"
    if {![file readable $filelist] || ![file readable $rtl]} {
        return ""
    }
    set ffh [open $filelist r]
    set filelist_text [read $ffh]
    close $ffh
    set rfh [open $rtl r]
    set rtl_text [read $rfh]
    close $rfh
    if {[string first {+define+MPTDC_PHASE_BUFFER_USE_BUHDX4} $filelist_text] >= 0
        && [regexp {BUHDX4[[:space:]]+u_buf} $rtl_text]} {
        set ::mptdc_o12b_expected_phase_cell_type "BUHDX4"
    }
    return $::mptdc_o12b_expected_phase_cell_type
}

proc mptdc_o12b_pf_to_ff {value} {
    return [mptdc_o11_pf_to_ff $value]
}

proc mptdc_o12b_pin_to_inst {pin_name} {
    if {[regexp {^(.+)/(A|Q)$} $pin_name -> inst pin]} {
        return $inst
    }
    return ""
}

proc mptdc_o12b_get_cell {cell_name} {
    if {$cell_name eq ""} { return "" }
    set cells [list]
    catch {set cells [get_cells -quiet $cell_name]}
    if {[llength $cells] > 0} { return [lindex $cells 0] }
    catch {set cells [get_cells -quiet -hierarchical $cell_name]}
    if {[llength $cells] > 0} { return [lindex $cells 0] }
    return $cell_name
}

proc mptdc_o12b_cell_from_pin {pin_name} {
    set pin_obj [mptdc_o11_pin_object $pin_name]
    set cells [list]
    catch {set cells [get_cells -quiet -of_objects $pin_obj]}
    if {[llength $cells] > 0} {
        return [mptdc_o11_obj_name [lindex $cells 0]]
    }
    return [mptdc_o12b_pin_to_inst $pin_name]
}

proc mptdc_o12b_cell_type {cell_name} {
    set cell_obj [mptdc_o12b_get_cell $cell_name]
    foreach attr {
        .base_cell.name
        .lib_cell.name
        .master.name
        .cell.name
        .ref_name
        .base_cell
        .lib_cell
    } {
        set val [mptdc_o12b_db_attr $cell_obj $attr]
        if {$val ne ""} {
            if {[regexp {([A-Za-z0-9_]+)$} "$val" -> tail]} {
                return $tail
            }
            return $val
        }
    }
    return ""
}

proc mptdc_o12b_cell_type_from_property {path} {
    set data [mptdc_o12b_first_property_text $path {
        ref_name
        base_cell
        base_cell_name
        lib_cell
        lib_cell_name
        master
        cell
        cell_name
    }]
    set value [lindex $data 0]
    if {$value eq ""} { return [list "" ""] }
    if {[regexp {(BUHDX[0-9]+)} $value -> cell_type]} {
        return [list $cell_type [lindex $data 1]]
    }
    if {[regexp {([A-Za-z0-9_]+)$} $value -> tail]} {
        return [list $tail [lindex $data 1]]
    }
    return [list $value [lindex $data 1]]
}

proc mptdc_o12b_resolve_cell_type {cell_name property_path} {
    set cell_type [mptdc_o12b_cell_type $cell_name]
    if {$cell_type ne ""} {
        return [list $cell_type "db_attr"]
    }
    set prop_data [mptdc_o12b_cell_type_from_property $property_path]
    set prop_type [lindex $prop_data 0]
    if {$prop_type ne ""} {
        return [list $prop_type [lindex $prop_data 1]]
    }
    set expected [mptdc_o12b_expected_phase_cell_type]
    if {$expected ne "" && $cell_name ne "" && [regexp {u_phase_buf_(slow|fast).*gen_phase_buf} $cell_name]} {
        return [list $expected "rtl_define_fallback"]
    }
    return [list "" "CELL_TYPE_UNRESOLVED_BY_DB"]
}

proc mptdc_o12b_cell_box {cell_name} {
    set cell_obj [mptdc_o12b_get_cell $cell_name]
    foreach attr {.bbox .box .rect .bounds .place_box} {
        set val [mptdc_o12b_db_attr $cell_obj $attr]
        if {[llength $val] >= 4} {
            return [lrange $val 0 3]
        }
        if {[llength $val] == 1 && [llength [lindex $val 0]] >= 4} {
            return [lrange [lindex $val 0] 0 3]
        }
    }
    set loc_data [mptdc_o12b_first_text_attr $cell_obj {.location .origin .pt}]
    set loc [lindex $loc_data 0]
    if {[llength $loc] >= 2} {
        set x [lindex $loc 0]
        set y [lindex $loc 1]
        return [list $x $y $x $y]
    }
    set x [lindex [mptdc_o12b_first_numeric_attr $cell_obj {.x .origin_x .placed_x .pt_x}] 0]
    set y [lindex [mptdc_o12b_first_numeric_attr $cell_obj {.y .origin_y .placed_y .pt_y}] 0]
    if {$x ne "" && $y ne ""} {
        return [list $x $y $x $y]
    }
    return [list "" "" "" ""]
}

proc mptdc_o12b_box_center {box} {
    if {[llength $box] < 4} { return [list "" ""] }
    set llx [mptdc_o12b_num [lindex $box 0]]
    set lly [mptdc_o12b_num [lindex $box 1]]
    set urx [mptdc_o12b_num [lindex $box 2]]
    set ury [mptdc_o12b_num [lindex $box 3]]
    if {$llx eq "" || $lly eq "" || $urx eq "" || $ury eq ""} {
        return [list "" ""]
    }
    return [list [expr {($llx + $urx) / 2.0}] [expr {($lly + $ury) / 2.0}]]
}

proc mptdc_o12b_distance {x0 y0 x1 y1} {
    if {$x0 eq "" || $y0 eq "" || $x1 eq "" || $y1 eq ""} {
        return [list "" "" ""]
    }
    set dx [expr {$x0 - $x1}]
    set dy [expr {$y0 - $y1}]
    set manhattan [expr {abs($dx) + abs($dy)}]
    return [list $dx $dy $manhattan]
}

proc mptdc_o12b_ro_cell {family} {
    set cells [list]
    foreach pattern [list \
        [format {u_core/u_osc_%s/u_ro_tune4} $family] \
        [format {u_core_u_osc_%s_u_ro_tune4} $family] \
        [format {*u_osc_%s*u_ro_tune4} $family]] {
        catch {set found [get_cells -quiet -hierarchical $pattern]}
        foreach cell [mptdc_o11_object_names $found] {
            mptdc_o11_unique_append cells $cell
        }
    }
    return [lindex $cells 0]
}

proc mptdc_o12b_pd_center {} {
    set cells [list]
    foreach pattern {
        *gen_pd_row*gen_pd_col*u_pd*
        *u_pd*
    } {
        catch {set found [get_cells -quiet -hierarchical $pattern]}
        foreach cell [mptdc_o11_object_names $found] {
            mptdc_o11_unique_append cells $cell
        }
        if {[llength $cells] > 0} { break }
    }
    set count 0
    set sx 0.0
    set sy 0.0
    foreach cell $cells {
        set ctr [mptdc_o12b_box_center [mptdc_o12b_cell_box $cell]]
        set x [lindex $ctr 0]
        set y [lindex $ctr 1]
        if {$x eq "" || $y eq ""} { continue }
        set sx [expr {$sx + $x}]
        set sy [expr {$sy + $y}]
        incr count
    }
    if {$count == 0} {
        return [list "" "" 0]
    }
    return [list [expr {$sx / $count}] [expr {$sy / $count}] $count]
}

proc mptdc_o12b_net_metric {net_obj metric} {
    array set attrs {
        total_cap {.total_capacitance .total_cap .capacitance .load_capacitance .effective_capacitance .cap}
        wire_cap {.wire_capacitance .wire_cap .route_capacitance .routing_capacitance}
        pin_cap {.pin_capacitance .pin_cap .load_pin_capacitance .load_capacitance}
        resistance {.resistance .resistance_max .lumped_resistance .lumped_resistance_max}
        transition {.transition .max_transition .slew .max_slew}
        route_length {.route_length .routed_length .wire_length .total_wire_length .length}
    }
    if {![info exists attrs($metric)]} { return [list "" ""] }
    set data [mptdc_o12b_first_numeric_attr $net_obj $attrs($metric)]
    if {[lindex $data 0] ne "" || $metric ne "route_length"} {
        return $data
    }
    set sx [mptdc_o12b_db_attr $net_obj .box_sizex]
    set sy [mptdc_o12b_db_attr $net_obj .box_sizey]
    set data [mptdc_o12b_bbox_manhattan_from_sizes $sx $sy "get_db_net_bbox_manhattan_estimate"]
    if {[lindex $data 0] ne ""} {
        return $data
    }
    foreach attr {.box_size .bbox .box .rect .bounds} {
        set data [mptdc_o12b_bbox_manhattan_from_box [mptdc_o12b_db_attr $net_obj $attr] "get_db_net_bbox_manhattan_estimate:$attr"]
        if {[lindex $data 0] ne ""} {
            return $data
        }
    }
    return [list "" ""]
}

proc mptdc_o12b_net_metric_from_property {property_path metric} {
    array set props {
        total_cap {capacitance_max total_capacitance_max_fall total_capacitance_max_rise lumped_capacitance_max total_lumped_capacitance_max_fall total_lumped_capacitance_max_rise}
        wire_cap {wire_capacitance_max wire_capacitance_max_fall wire_capacitance_max_rise wire_lumped_capacitance_max wire_lumped_capacitance_max_fall wire_lumped_capacitance_max_rise}
        pin_cap {pin_capacitance_max pin_capacitance_max_fall pin_capacitance_max_rise}
        resistance {resistance_max lumped_resistance_max}
        transition {transition transition_max max_transition slew max_slew}
        route_length {route_length routed_length wire_length total_wire_length length}
        fanout {num_load_pins num_loads fanout}
    }
    if {![info exists props($metric)]} { return [list "" ""] }
    return [mptdc_o12b_first_property_numeric $property_path $props($metric)]
}

proc mptdc_o12b_net_metric_resolved {net_obj metric property_path} {
    set prop_data [mptdc_o12b_net_metric_from_property $property_path $metric]
    if {[lindex $prop_data 0] ne ""} {
        return $prop_data
    }
    return [mptdc_o12b_net_metric $net_obj $metric]
}

proc mptdc_o12b_net_metric_resolved_named {net_name net_obj metric property_path} {
    set data [mptdc_o12b_net_metric_resolved $net_obj $metric $property_path]
    if {[lindex $data 0] ne ""} {
        return $data
    }
    return [mptdc_o12b_net_metric_from_dbget_name $net_name $metric]
}

proc mptdc_o12b_net_load_names {net_obj source_pin} {
    set names [list]
    set loads [mptdc_o12b_db_attr $net_obj .loads]
    foreach load $loads {
        set lname [mptdc_o11_obj_name $load]
        if {$lname eq "" || $lname eq $source_pin} { continue }
        mptdc_o11_unique_append names $lname
    }
    return $names
}

proc mptdc_o12b_net_fanout_resolved {net_obj property_path} {
    set prop_data [mptdc_o12b_net_metric_from_property $property_path fanout]
    if {[lindex $prop_data 0] ne ""} {
        return [lindex $prop_data 0]
    }
    set fanout [lindex [mptdc_o12b_first_numeric_attr $net_obj {.num_loads .fanout}] 0]
    if {$fanout eq ""} {
        set load_names [mptdc_o12b_net_load_names $net_obj ""]
        if {[llength $load_names] > 0} {
            set fanout [llength $load_names]
        }
    }
    return $fanout
}

proc mptdc_o12b_pin_metric {pin_name metric} {
    set pin_obj [mptdc_o11_pin_object $pin_name]
    array set attrs {
        cap {.capacitance .cap .pin_capacitance .input_capacitance .load_capacitance}
        transition {.transition .max_transition .slew .max_slew}
        arrival {.arrival .arrival_max .late_arrival .max_arrival}
    }
    if {![info exists attrs($metric)]} { return [list "" ""] }
    return [mptdc_o12b_first_numeric_attr $pin_obj $attrs($metric)]
}

proc mptdc_o12b_get_row_objects {family tap} {
    set raw_pins [mptdc_o12_get_pins [mptdc_o12_pin_candidates $family $tap raw]]
    set a_pins [mptdc_o12_get_pins [mptdc_o12_pin_candidates $family $tap A]]
    set q_pins [mptdc_o12_get_pins [mptdc_o12_pin_candidates $family $tap Q]]

    set raw_pin [lindex $raw_pins 0]
    set a_pin [lindex $a_pins 0]
    set q_pin [lindex $q_pins 0]
    set raw_net [mptdc_o11_net_from_pin $raw_pin]
    set out_net [mptdc_o11_net_from_pin $q_pin]
    set buf_inst [mptdc_o12b_cell_from_pin $q_pin]
    if {$buf_inst eq ""} { set buf_inst [mptdc_o12b_cell_from_pin $a_pin] }
    set cell_type [mptdc_o12b_cell_type $buf_inst]
    return [list $raw_pins $a_pins $q_pins $raw_pin $a_pin $q_pin $raw_net $out_net $buf_inst $cell_type]
}

proc mptdc_o12b_write_net_debug_reports {family tap raw_net out_net} {
    global o12b
    set raw_path "$o12b(reports_dir)/net_debug_${family}_${tap}_raw.rpt"
    set out_path "$o12b(reports_dir)/net_debug_${family}_${tap}_buf.rpt"
    if {$raw_net ne ""} {
        mptdc_o12b_capture_candidates $raw_path "O12B raw net debug $family $tap" [list \
            [format {report_net -net {%s}} $raw_net] \
            [format {reportNet {%s}} $raw_net] \
            [format {report_property [get_nets {%s}]} $raw_net]]
    }
    if {$out_net ne ""} {
        mptdc_o12b_capture_candidates $out_path "O12B buffered net debug $family $tap" [list \
            [format {report_net -net {%s}} $out_net] \
            [format {reportNet {%s}} $out_net] \
            [format {report_property [get_nets {%s}]} $out_net]]
    }
}

proc mptdc_o12b_write_property_snapshot {path title object fields} {
    set dir [file dirname $path]
    file mkdir $dir
    set fh [open $path w]
    puts $fh "$title"
    puts $fh [string repeat "=" [string length $title]]
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    puts $fh "object | $object"
    puts $fh "object_query_safe | [mptdc_o12b_db_object_query_safe $object]"
    foreach field $fields {
        set property [lindex $field 0]
        set value ""
        set source ""
        foreach attr [lrange $field 1 end] {
            set value [mptdc_o12b_db_attr $object $attr]
            if {$value ne ""} {
                set source $attr
                break
            }
        }
        puts $fh "$property | $value"
        puts $fh "${property}_source | $source"
    }
    close $fh
    return 1
}

proc mptdc_o12b_tcl_braced_literal {value} {
    set text "$value"
    if {[string first "\}" $text] >= 0} {
        return ""
    }
    return "{$text}"
}

proc mptdc_o12b_write_native_named_property_report {path getter name} {
    if {$name eq ""} {
        return 0
    }
    set literal [mptdc_o12b_tcl_braced_literal $name]
    if {$literal eq ""} {
        return 0
    }
    set script [format {report_property [%s -quiet -hierarchical %s]} $getter $literal]
    if {![catch {uplevel 1 "$script > \"$path\""}]} {
        return 1
    }
    return 0
}

proc mptdc_o12b_skip_native_net_property_report {net_name} {
    if {$net_name eq ""} {
        return 1
    }

    # Restored hierarchical HDL-internal nets can resolve as net: pseudo-handles
    # that Innovus 22.33 rejects in report_property.  The DB snapshot fallback
    # still keeps the row contextual without adding caught TCLCMD errors.
    if {[llength [info commands mptdc_o11_internal_net_token_name]] > 0
        && [mptdc_o11_internal_net_token_name $net_name] ne ""} {
        return 1
    }
    if {[llength [info commands mptdc_o11_normalized_object_token]] > 0} {
        set net_text [mptdc_o11_normalized_object_token $net_name]
    } else {
        set net_text [string trim "$net_name"]
    }
    if {[regexp {^net:.+[/.]iso_tap$} $net_text] || [regexp {(^|[/.])iso_tap$} $net_text]} {
        return 1
    }

    return 0
}

proc mptdc_o12b_write_net_property_report {path net_name} {
    if {$net_name eq ""} { return 0 }
    set skip_native [mptdc_o12b_skip_native_net_property_report $net_name]
    if {!$skip_native} {
        if {[mptdc_o12b_write_native_named_property_report $path get_nets $net_name]} {
            return 1
        }
        set net_obj [mptdc_o11_net_object $net_name]
    } else {
        set net_obj ""
    }
    return [mptdc_o12b_write_property_snapshot $path "O12B net properties $net_name" $net_obj [list \
        {capacitance_max .total_capacitance .total_cap .capacitance .load_capacitance .effective_capacitance .cap} \
        {wire_capacitance_max .wire_capacitance .wire_cap .route_capacitance .routing_capacitance} \
        {pin_capacitance_max .pin_capacitance .pin_cap .load_pin_capacitance .load_capacitance} \
        {resistance_max .resistance .resistance_max .lumped_resistance .lumped_resistance_max} \
        {transition .transition .max_transition .slew .max_slew} \
        {route_length .route_length .routed_length .wire_length .total_wire_length .length} \
        {num_load_pins .num_loads .fanout} \
        {fanout .fanout .num_loads}]]
}

proc mptdc_o12b_write_cell_property_report {path cell_name} {
    if {$cell_name eq ""} { return 0 }
    if {[mptdc_o12b_write_native_named_property_report $path get_cells $cell_name]} {
        return 1
    }
    set cell_obj [mptdc_o12b_get_cell $cell_name]
    return [mptdc_o12b_write_property_snapshot $path "O12B cell properties $cell_name" $cell_obj [list \
        {ref_name .base_cell.name .lib_cell.name .master.name .cell.name .ref_name .base_cell .lib_cell} \
        {base_cell .base_cell.name .base_cell} \
        {lib_cell .lib_cell.name .lib_cell} \
        {master .master.name .master} \
        {cell .cell.name .cell} \
        {bbox .bbox .box .rect .bounds .place_box} \
        {location .location .origin .pt}]]
}

proc mptdc_o12b_note_metric_unavailable {notes metric object} {
    if {$object eq ""} {
        lappend notes "${metric}_OBJECT_UNAVAILABLE"
    } else {
        lappend notes "${metric}_DB_ATTR_UNAVAILABLE"
    }
    return $notes
}

proc mptdc_o12b_dbget_name_candidates {name} {
    set candidates [list]
    set text [string trim "$name"]
    if {$text eq ""} { return $candidates }
    if {[llength [info commands mptdc_o11_internal_net_token_name]] > 0} {
        set internal [mptdc_o11_internal_net_token_name $text]
        if {$internal ne ""} { set text $internal }
    }
    if {[regexp {^net:(.+)$} $text -> net_text]} {
        set text $net_text
    }
    regsub {^mptdc_axis_core/} $text {} stripped
    foreach candidate [list $text $stripped] {
        if {$candidate eq ""} { continue }
        mptdc_o11_unique_append candidates $candidate
        set escaped [string map [list "\\" "\\\\" "\[" "\\\[" "\]" "\\\]"] $candidate]
        mptdc_o11_unique_append candidates $escaped
    }
    return $candidates
}

proc mptdc_o12b_net_dbget_ptrs {net_name} {
    global mptdc_o12b_net_dbget_ptr_cache
    set key "$net_name"
    if {[info exists mptdc_o12b_net_dbget_ptr_cache($key)]} {
        return $mptdc_o12b_net_dbget_ptr_cache($key)
    }
    set ptrs [list]
    if {$net_name eq "" || [llength [info commands dbGet]] == 0} {
        set mptdc_o12b_net_dbget_ptr_cache($key) $ptrs
        return $ptrs
    }
    foreach candidate [mptdc_o12b_dbget_name_candidates $net_name] {
        set found [list]
        if {![catch {set found [dbGet top.nets.name $candidate -p]}]} {
            foreach ptr $found {
                if {$ptr ne "" && $ptr ne "0x0"} {
                    mptdc_o11_unique_append ptrs $ptr
                }
            }
        }
    }
    set mptdc_o12b_net_dbget_ptr_cache($key) $ptrs
    return $ptrs
}

proc mptdc_o12b_dbget_attrs_for_ptr {ptr} {
    global mptdc_o12b_dbget_attr_cache
    if {$ptr eq "" || $ptr eq "0x0" || [llength [info commands dbGet]] == 0} {
        return [list]
    }
    if {[info exists mptdc_o12b_dbget_attr_cache($ptr)]} {
        return $mptdc_o12b_dbget_attr_cache($ptr)
    }
    set attrs [list]
    if {![catch {set raw_attrs [dbGet ${ptr}.?]}]} {
        foreach raw [split "$raw_attrs" "\n"] {
            foreach token [split [string trim $raw]] {
                set token [string trim $token]
                if {$token eq ""} { continue }
                if {[regexp {^[A-Za-z_][A-Za-z0-9_]*:$} $token]} { continue }
                mptdc_o11_unique_append attrs $token
            }
        }
    }
    set mptdc_o12b_dbget_attr_cache($ptr) $attrs
    return $attrs
}

proc mptdc_o12b_dbget_attr_supported {ptr attr} {
    set attr_name [string trimleft $attr .]
    if {$ptr eq "" || $attr_name eq ""} { return 0 }
    set parent [lindex [split $attr_name "."] 0]
    foreach raw_attr [mptdc_o12b_dbget_attrs_for_ptr $ptr] {
        set norm [string trimleft $raw_attr .]
        if {$norm eq $attr_name} {
            return 1
        }
        if {[string first "." $attr_name] >= 0 && $norm eq $parent} {
            return 1
        }
    }
    return 0
}

proc mptdc_o12b_dbget_attr_raw_supported {ptr attr} {
    if {$ptr eq "" || [llength [info commands dbGet]] == 0} { return "" }
    if {![mptdc_o12b_dbget_attr_supported $ptr $attr]} { return "" }
    set val ""
    if {![catch {set val [dbGet ${ptr}${attr}]}] && $val ne ""} {
        return $val
    }
    return ""
}

proc mptdc_o12b_dbget_attr_raw {ptr attr} {
    if {$ptr eq "" || $ptr eq "0x0" || $attr eq "" || [llength [info commands dbGet]] == 0} { return "" }
    set val ""
    if {![catch {set val [dbGet ${ptr}${attr}]}] && $val ne ""} {
        return $val
    }
    return ""
}

proc mptdc_o12b_dbget_box_segment_length_um {box} {
    set nums [list]
    foreach token $box {
        set num [mptdc_o12b_num $token]
        if {$num ne ""} {
            lappend nums $num
        }
    }
    if {[llength $nums] < 4} {
        return ""
    }
    set llx [lindex $nums 0]
    set lly [lindex $nums 1]
    set urx [lindex $nums 2]
    set ury [lindex $nums 3]
    set dx [expr {abs($urx - $llx)}]
    set dy [expr {abs($ury - $lly)}]
    return [expr {$dx > $dy ? $dx : $dy}]
}

proc mptdc_o12b_dbget_route_shape_length_um {shape_ptr} {
    foreach attr {.box .rect .bbox} {
        set box [mptdc_o12b_dbget_attr_raw_supported $shape_ptr $attr]
        if {$box eq "" || $box eq "0x0"} {
            continue
        }
        set length [mptdc_o12b_dbget_box_segment_length_um $box]
        if {$length ne ""} {
            return $length
        }
    }
    return ""
}

proc mptdc_o12b_dbget_route_length_for_ptr {ptr} {
    set data [mptdc_o12b_bbox_manhattan_from_sizes \
        [mptdc_o12b_dbget_attr_raw $ptr .box_sizex] \
        [mptdc_o12b_dbget_attr_raw $ptr .box_sizey] \
        "dbGet_net_bbox_manhattan_estimate"]
    if {[lindex $data 0] ne ""} {
        return $data
    }

    foreach attr {.box_size .box .bbox} {
        set data [mptdc_o12b_bbox_manhattan_from_box \
            [mptdc_o12b_dbget_attr_raw $ptr $attr] \
            "dbGet_net_bbox_manhattan_estimate:$attr"]
        if {[lindex $data 0] ne ""} {
            return $data
        }
    }

    set use_shape_fallback 0
    if {[info exists ::env(MPTDC_O12B_ROUTE_SHAPE_FALLBACK)]} {
        set flag [string tolower $::env(MPTDC_O12B_ROUTE_SHAPE_FALLBACK)]
        if {$flag ni {0 false no off ""}} {
            set use_shape_fallback 1
        }
    }
    if {!$use_shape_fallback} {
        return [list "" ""]
    }
    foreach attr {.wires .pWires .sWires .vWires .whatIfWires} {
        set shapes [mptdc_o12b_dbget_attr_raw_supported $ptr $attr]
        if {$shapes eq "" || $shapes eq "0x0"} {
            continue
        }
        set total 0.0
        set count 0
        foreach shape_ptr $shapes {
            if {$shape_ptr eq "" || $shape_ptr eq "0x0"} {
                continue
            }
            set length [mptdc_o12b_dbget_route_shape_length_um $shape_ptr]
            if {$length eq ""} {
                continue
            }
            set total [expr {$total + $length}]
            incr count
        }
        if {$count > 0} {
            return [list [format "%.6f" $total] "dbGet_net${attr}_box_length_um"]
        }
    }
    return [list "" ""]
}

proc mptdc_o12b_net_metric_from_dbget_name {net_name metric} {
    if {$net_name eq ""} {
        return [list "" ""]
    }
    foreach ptr [mptdc_o12b_net_dbget_ptrs $net_name] {
        if {$metric eq "route_length"} {
            set route_data [mptdc_o12b_dbget_route_length_for_ptr $ptr]
            if {[lindex $route_data 0] ne ""} {
                return $route_data
            }
            continue
        }

        return [list "" ""]
    }
    return [list "" ""]
}

proc mptdc_o12b_probe_get_db_route_objects {fh object indent} {
    set route_attrs {.wires .wire .routes .route .routedWires .routed_wires .regularWires .regular_wires .rWires .shapes .rects .segments .sWires}
    set found_route_object 0
    foreach attr $route_attrs {
        if {![mptdc_o12b_db_attr_supported $object $attr]} {
            continue
        }
        set raw [mptdc_o12b_db_attr_raw_supported $object $attr]
        set raw_len 0
        catch {set raw_len [llength $raw]}
        set first ""
        if {$raw_len > 0} {
            set first [lindex $raw 0]
        }
        puts $fh "${indent}- $attr count=$raw_len first=[mptdc_o12b_csv [mptdc_o12b_scalar $first]]"
        if {$raw_len > 0 && $first ne "" && $first ne "0x0"} {
            set found_route_object 1
            puts $fh "${indent}  first_object=$first"
            puts $fh "${indent}  first_object_attributes:"
            set sub_attrs [mptdc_o12b_db_attrs_for $first]
            if {[llength $sub_attrs] == 0} {
                puts $fh "${indent}  - <none or unavailable>"
            } else {
                foreach sub_attr $sub_attrs {
                    puts $fh "${indent}  - $sub_attr"
                }
            }
            set sub_candidates {.length .routeLength .route_length .wireLength .wire_length .totalLength .total_length .layer.name .layer .rect .box .bbox .pt .points .width .status .shape}
            puts $fh "${indent}  first_object_candidate_values:"
            foreach sub_attr $sub_candidates {
                if {![mptdc_o12b_db_attr_supported $first $sub_attr]} {
                    continue
                }
                puts $fh "${indent}  - $sub_attr=[mptdc_o12b_csv [mptdc_o12b_scalar [mptdc_o12b_db_attr_raw_supported $first $sub_attr]]]"
            }
        }
    }
    if {!$found_route_object} {
        puts $fh "${indent}- no_supported_route_shape_object_found"
    }
}

proc mptdc_o12b_probe_dbget_net_route_objects {fh ptr indent} {
    set route_attrs {.wires .pWires .sWires .vWires .whatIfWires .vias .sVias .whatIfVias}
    set found_route_attr 0
    foreach attr $route_attrs {
        set raw [mptdc_o12b_dbget_attr_raw $ptr $attr]
        set raw_len 0
        catch {set raw_len [llength $raw]}
        set first ""
        if {$raw_len > 0} {
            set first [lindex $raw 0]
        }
        if {$raw eq "" || $raw eq "0x0"} {
            continue
        }
        set found_route_attr 1
        puts $fh "${indent}- $attr count=$raw_len first=[mptdc_o12b_csv [mptdc_o12b_scalar $first]]"
    }
    if {!$found_route_attr} {
        puts $fh "${indent}- no_supported_dbGet_net_route_attr_found"
    }
}

proc mptdc_o12b_write_attr_probe {samples} {
    global o12b
    set path "$o12b(reports_dir)/phase_buffer_db_attribute_probe.rpt"
    set fh [open $path w]
    puts $fh "# O12B Innovus DB Attribute Probe"
    puts $fh ""
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    foreach item $samples {
        set label [lindex $item 0]
        set object [lindex $item 1]
        set kind [lindex $item 2]
        set name [lindex $item 3]
        puts $fh "## $label"
        puts $fh ""
        puts $fh "object: $object"
        if {$kind ne ""} { puts $fh "kind: $kind" }
        if {$name ne ""} { puts $fh "name: $name" }
        puts $fh "attributes:"
        set attrs [list]
        if {[catch {set attrs [mptdc_o12b_db_attrs_for $object]} err]} {
            puts $fh "- ATTR_PROBE_FAILED: $err"
            puts $fh ""
            continue
        }
        if {[llength $attrs] == 0} {
            puts $fh "- <none or unavailable>"
        } else {
            if {[catch {
                foreach attr $attrs {
                    puts $fh "- $attr"
                }
            } err]} {
                puts $fh "- ATTR_LIST_PARSE_FAILED: $err"
                puts $fh "- raw_attrs: [mptdc_o12b_csv $attrs]"
            }
        }
        puts $fh "get_db_route_metric_probe:"
        mptdc_o12b_probe_get_db_route_objects $fh $object ""
        if {$kind eq "net" || [regexp {_net$} $label]} {
            set probe_name $name
            if {$probe_name eq ""} {
                set probe_name [mptdc_o11_obj_name $object]
            }
            set ptrs [mptdc_o12b_net_dbget_ptrs $probe_name]
            puts $fh "dbGet_net_probe:"
            puts $fh "- query_name=[mptdc_o12b_csv $probe_name]"
            if {[llength $ptrs] == 0} {
                puts $fh "- no_dbGet_top_net_pointer"
            }
            foreach ptr [lrange $ptrs 0 2] {
                puts $fh "- ptr=$ptr"
                set ptr_name [mptdc_o12b_dbget_attr_raw_supported $ptr .name]
                if {$ptr_name ne ""} {
                    puts $fh "  name=[mptdc_o12b_csv [mptdc_o12b_scalar $ptr_name]]"
                }
                puts $fh "  attributes:"
                puts $fh "  - skipped_full_dbGet_question_mark_probe"
                puts $fh "  candidate_net_values:"
                foreach attr {.numTerms .numInputTerms .numOutputTerms .area .box .box_sizex .box_sizey .box_size .bottomPreferredLayer .topPreferredLayer} {
                    set val [mptdc_o12b_dbget_attr_raw $ptr $attr]
                    if {$val eq "" || $val eq "0x0"} {
                        continue
                    }
                    puts $fh "  - $attr=[mptdc_o12b_csv [mptdc_o12b_scalar $val]]"
                }
                puts $fh "  route_metric_probe:"
                mptdc_o12b_probe_dbget_net_route_objects $fh $ptr "  "
            }
        }
        puts $fh ""
    }
    close $fh
}

proc mptdc_o12b_capture_candidates {path title bodies} {
    set dir [file dirname $path]
    file mkdir $dir
    set errors [list]
    foreach body $bodies {
        if {![catch {uplevel 1 "$body > \"$path\""} err]} {
            return 1
        }
        lappend errors "$body: $err"
    }
    set fh [open $path w]
    puts $fh "$title"
    puts $fh [string repeat "=" [string length $title]]
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    puts $fh "FAILED:"
    puts $fh [join $errors "\n\n"]
    close $fh
    return 0
}

proc mptdc_o12b_clock_for {family tap} {
    return [format {clk_osc_%s_buf_tap%d} $family $tap]
}

proc mptdc_o12b_delay_ps {a_pin q_pin} {
    set a_arr [lindex [mptdc_o12b_pin_metric $a_pin arrival] 0]
    set q_arr [lindex [mptdc_o12b_pin_metric $q_pin arrival] 0]
    if {$a_arr ne "" && $q_arr ne ""} {
        return [format "%.2f" [expr {($q_arr - $a_arr) * 1000.0}]]
    }
    return ""
}

proc mptdc_o12b_write_reports {} {
    global o12b

    set raw_path "$o12b(reports_dir)/ro_phase_raw_pin_loads.csv"
    set out_path "$o12b(reports_dir)/phase_buffer_output_loads.csv"
    set topo_path "$o12b(reports_dir)/phase_buffer_topology.csv"
    set place_path "$o12b(reports_dir)/phase_buffer_placement.csv"
    set delay_path "$o12b(reports_dir)/phase_buffer_delay_estimate.csv"
    set route_path "$o12b(reports_dir)/phase_buffer_route_summary.csv"
    set sink_path "$o12b(reports_dir)/ro_phase_sink_classification.csv"
    set summary_path "$o12b(reports_dir)/phase_buffer_balance_summary.md"
    set topo_summary_path "$o12b(reports_dir)/phase_buffer_topology_summary.md"
    set place_summary_path "$o12b(reports_dir)/phase_buffer_placement_summary.md"

    set raw_fh [open $raw_path w]
    puts $raw_fh "family,tap,raw_ro_pin,matched_raw_pin_count,raw_net,raw_fanout,raw_net_total_cap_pf,raw_net_total_cap_ff,raw_net_cap_bound_ff,budget_label,strict_ratio,cn_ratio,buffer_input_pin,sinks,notes"

    set out_fh [open $out_path w]
    puts $out_fh "family,tap,raw_ro_pin,raw_net,buffer_instance,buffer_cell_type,buffer_input_pin,buffer_output_pin,buffered_phase_net,buffer_output_fanout,total_cap_pf,total_cap_ff,wire_cap_pf,wire_cap_ff,pin_cap_pf,pin_cap_ff,res_ohm,transition_ps,route_length_um,status,sink_count,pd_load_count,fast_tag_load_count,slow_epoch_load_count,metadata_load_count,other_load_count,buffer_input_cap_pf,buffer_input_cap_ff,raw_net_cap_pf,raw_net_cap_ff,budget_label,strict_ratio,cn_ratio,notes"

    set topo_fh [open $topo_path w]
    puts $topo_fh "family,tap,buffer_chain_depth,cell_sequence,input_net,output_net,status,notes"

    set place_fh [open $place_path w]
    puts $place_fh "family,tap,buffer_instance,buffer_cell_type,x,y,llx,lly,urx,ury,ro_instance,ro_x,ro_y,dx_from_ro,dy_from_ro,manhattan_from_ro,pd_center_x,pd_center_y,manhattan_to_pd_center,status,notes"

    set delay_fh [open $delay_path w]
    puts $delay_fh "family,tap,buffer_instance,buffer_cell_type,input_pin,output_pin,delay_ps,input_transition,output_transition,clock_name,notes"

    set route_fh [open $route_path w]
    puts $route_fh "family,tap,raw_net,raw_route_length_um,raw_total_cap_pf,buffered_net,buffered_route_length_um,buffered_total_cap_pf,buffered_wire_cap_pf,buffered_pin_cap_pf,buffered_res_ohm,status,notes"

    set sink_fh [open $sink_path w]
    puts $sink_fh "family,tap,source_pin,net,sink_pin,sink_class,sink_pin_cap_pf,sink_pin_cap_ff"

    array set raw_labels {}
    array set out_labels {}
    array set topo_counts {}
    set raw_rows 0
    set raw_matched 0
    set raw_missing 0
    set raw_fanout1 0
    set raw_numeric 0
    set raw_bound_ok 0
    set out_rows 0
    set out_matched 0
    set out_missing 0
    set out_numeric 0
    set topo_match 0
    set topo_bad 0
    set placement_numeric 0
    set max_out_cap_ff ""
    set max_out_desc ""
    set min_route ""
    set max_route ""
    set min_ro_dist ""
    set max_ro_dist ""
    set max_raw_cap_ff ""
    set max_raw_desc ""

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
            set row [mptdc_o12b_get_row_objects $family $tap]
            set raw_pins [lindex $row 0]
            set a_pins [lindex $row 1]
            set q_pins [lindex $row 2]
            set raw_pin [lindex $row 3]
            set a_pin [lindex $row 4]
            set q_pin [lindex $row 5]
            set raw_net [lindex $row 6]
            set out_net [lindex $row 7]
            set buf_inst [lindex $row 8]
            set cell_type [lindex $row 9]

            set raw_net_obj [mptdc_o11_net_object $raw_net]
            set out_net_obj [mptdc_o11_net_object $out_net]
            set raw_prop_path "$o12b(reports_dir)/net_property_${family}_${tap}_raw.rpt"
            set out_prop_path "$o12b(reports_dir)/net_property_${family}_${tap}_buf.rpt"
            set cell_prop_path "$o12b(reports_dir)/cell_property_${family}_${tap}_buf.rpt"
            catch {mptdc_o12b_write_net_property_report $raw_prop_path $raw_net}
            catch {mptdc_o12b_write_net_property_report $out_prop_path $out_net}
            catch {mptdc_o12b_write_cell_property_report $cell_prop_path $buf_inst}

            set cell_type_data [mptdc_o12b_resolve_cell_type $buf_inst $cell_prop_path]
            set cell_type [lindex $cell_type_data 0]
            set cell_type_source [lindex $cell_type_data 1]

            set raw_fanout [mptdc_o12b_net_fanout_resolved $raw_net_obj $raw_prop_path]
            set out_fanout [mptdc_o12b_net_fanout_resolved $out_net_obj $out_prop_path]

            set raw_total_data [mptdc_o12b_net_metric_resolved_named $raw_net $raw_net_obj total_cap $raw_prop_path]
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
                incr raw_bound_ok
                lappend raw_notes "NO_DRV_MAX_CAP_VIOLATION_BOUND_50FF"
            }
            if {$raw_fanout eq "1"} { incr raw_fanout1 }
            set raw_label [mptdc_o12_budget_label_from_source $raw_total_ff $raw_bound_ff 1]
            if {![info exists raw_labels($raw_label)]} { set raw_labels($raw_label) 0 }
            incr raw_labels($raw_label)
            set raw_strict [mptdc_o11_ratio $raw_total_ff 58.72]
            set raw_cn [mptdc_o11_ratio $raw_total_ff 75.59]
            if {$raw_strict eq "" && $raw_bound_ff ne ""} {
                set raw_strict [format "<=%.2f" [expr {$raw_bound_ff / 58.72}]]
                set raw_cn [format "<=%.2f" [expr {$raw_bound_ff / 75.59}]]
            }
            if {[string is double -strict $raw_total_ff] && ($max_raw_cap_ff eq "" || $raw_total_ff > $max_raw_cap_ff)} {
                set max_raw_cap_ff $raw_total_ff
                set max_raw_desc [format {%s S[%d] %s} $family $tap $raw_pin]
            }
            set raw_sinks [join [mptdc_o11_net_load_names $raw_net_obj $raw_pin] ";"]
            puts $raw_fh [join [list \
                $family $tap [mptdc_o12b_csv $raw_pin] [llength $raw_pins] [mptdc_o12b_csv $raw_net] \
                $raw_fanout $raw_total_pf $raw_total_ff $raw_bound_ff $raw_label $raw_strict $raw_cn \
                [mptdc_o12b_csv $a_pin] [mptdc_o12b_csv $raw_sinks] [mptdc_o12b_csv [join $raw_notes ";"]]] ","]

            set total_data [mptdc_o12b_net_metric_resolved_named $out_net $out_net_obj total_cap $out_prop_path]
            set wire_data [mptdc_o12b_net_metric_resolved_named $out_net $out_net_obj wire_cap $out_prop_path]
            set pin_data [mptdc_o12b_net_metric_resolved_named $out_net $out_net_obj pin_cap $out_prop_path]
            set res_data [mptdc_o12b_net_metric_resolved_named $out_net $out_net_obj resistance $out_prop_path]
            set trans_data [mptdc_o12b_net_metric_resolved_named $out_net $out_net_obj transition $out_prop_path]
            set route_data [mptdc_o12b_net_metric_resolved_named $out_net $out_net_obj route_length $out_prop_path]
            set total_pf [lindex $total_data 0]
            set wire_pf [lindex $wire_data 0]
            set pin_pf [lindex $pin_data 0]
            set res_ohm [lindex $res_data 0]
            set out_trans [lindex $trans_data 0]
            set route_len [lindex $route_data 0]
            set total_ff [mptdc_o12b_pf_to_ff $total_pf]
            set wire_ff [mptdc_o12b_pf_to_ff $wire_pf]
            set pin_ff [mptdc_o12b_pf_to_ff $pin_pf]
            set out_notes [list]
            if {[llength $q_pins] == 0} {
                incr out_missing
                lappend out_notes "NO_BUFFER_OUTPUT_PIN_MATCH"
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
            if {$out_trans ne ""} { lappend out_notes "TRANSITION_SOURCE=[lindex $trans_data 1]" }
            if {$route_len ne ""} {
                lappend out_notes "ROUTE_LENGTH_SOURCE=[lindex $route_data 1]"
                if {$min_route eq "" || $route_len < $min_route} { set min_route $route_len }
                if {$max_route eq "" || $route_len > $max_route} { set max_route $route_len }
            }
            set sink_names [mptdc_o11_net_load_names $out_net_obj $q_pin]
            set classes [list]
            set pd_count 0
            set fast_tag_count 0
            set slow_epoch_count 0
            set metadata_count 0
            set other_count 0
            foreach sink $sink_names {
                set class [mptdc_o11_sink_class $family $sink]
                lappend classes $class
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
                    $family $tap [mptdc_o12b_csv $q_pin] [mptdc_o12b_csv $out_net] \
                    [mptdc_o12b_csv $sink] $class $sink_cap [mptdc_o12b_pf_to_ff $sink_cap]] ","]
            }
            set in_cap_pf [lindex [mptdc_o12b_pin_metric $a_pin cap] 0]
            set in_cap_ff [mptdc_o12b_pf_to_ff $in_cap_pf]
            set out_label [mptdc_o11_budget_label $total_ff]
            set out_strict [mptdc_o11_ratio $total_ff 58.72]
            set out_cn [mptdc_o11_ratio $total_ff 75.59]
            set out_status [expr {$total_pf ne "" ? "BUFFER_OUTPUT_QUANTIFIED" : "BUFFER_OUTPUT_UNQUANTIFIED"}]
            if {![info exists out_labels($out_label)]} { set out_labels($out_label) 0 }
            incr out_labels($out_label)
            if {[string is double -strict $total_ff] && ($max_out_cap_ff eq "" || $total_ff > $max_out_cap_ff)} {
                set max_out_cap_ff $total_ff
                set max_out_desc [format {%s tap[%d] %s} $family $tap $q_pin]
            }
            puts $out_fh [join [list \
                $family $tap [mptdc_o12b_csv $raw_pin] [mptdc_o12b_csv $raw_net] \
                [mptdc_o12b_csv $buf_inst] [mptdc_o12b_csv $cell_type] [mptdc_o12b_csv $a_pin] [mptdc_o12b_csv $q_pin] \
                [mptdc_o12b_csv $out_net] $out_fanout $total_pf $total_ff $wire_pf $wire_ff $pin_pf $pin_ff \
                $res_ohm $out_trans $route_len $out_status [llength $sink_names] $pd_count $fast_tag_count $slow_epoch_count \
                $metadata_count $other_count $in_cap_pf $in_cap_ff $raw_total_pf $raw_total_ff \
                $out_label $out_strict $out_cn [mptdc_o12b_csv [join $out_notes ";"]]] ","]

            set topo_status "TOPOLOGY_SHAPE_MATCHED"
            set topo_notes [list]
            set chain_depth 1
            set sequence $cell_type
            if {$a_pin eq "" || $q_pin eq "" || $buf_inst eq ""} {
                set topo_status "MISSING_BUFFER"
                set chain_depth 0
                set sequence ""
                lappend topo_notes "missing A/Q/instance"
            } elseif {$cell_type ne "BUHDX4"} {
                if {$cell_type eq ""} {
                    lappend topo_notes "CELL_TYPE_UNRESOLVED_BY_DB"
                    lappend topo_notes "shape matched through A/Q pins and raw/output nets"
                } else {
                    set topo_status "TOPOLOGY_MISMATCH"
                    lappend topo_notes "expected BUHDX4 got $cell_type"
                }
            } else {
                lappend topo_notes "CELL_TYPE=BUHDX4"
                lappend topo_notes "CELL_TYPE_SOURCE=$cell_type_source"
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
                $family $tap $chain_depth [mptdc_o12b_csv $sequence] [mptdc_o12b_csv $raw_net] \
                [mptdc_o12b_csv $out_net] $topo_status [mptdc_o12b_csv [join $topo_notes ";"]]] ","]

            set box [mptdc_o12b_cell_box $buf_inst]
            set ctr [mptdc_o12b_box_center $box]
            set bx [lindex $ctr 0]
            set by [lindex $ctr 1]
            set ro_dist [mptdc_o12b_distance $bx $by $ro_x $ro_y]
            set pd_dist [mptdc_o12b_distance $bx $by $pd_x $pd_y]
            set placement_status "PLACEMENT_REVIEW"
            set place_notes [list]
            if {$bx ne "" && $by ne ""} {
                incr placement_numeric
                set ro_man [lindex $ro_dist 2]
                if {$ro_man ne ""} {
                    if {$min_ro_dist eq "" || $ro_man < $min_ro_dist} { set min_ro_dist $ro_man }
                    if {$max_ro_dist eq "" || $ro_man > $max_ro_dist} { set max_ro_dist $ro_man }
                }
            } else {
                set placement_status "PLACEMENT_UNKNOWN"
                lappend place_notes "buffer_location_unavailable"
            }
            puts $place_fh [join [list \
                $family $tap [mptdc_o12b_csv $buf_inst] [mptdc_o12b_csv $cell_type] \
                $bx $by [lindex $box 0] [lindex $box 1] [lindex $box 2] [lindex $box 3] \
                [mptdc_o12b_csv $ro_inst] $ro_x $ro_y [lindex $ro_dist 0] [lindex $ro_dist 1] [lindex $ro_dist 2] \
                $pd_x $pd_y [lindex $pd_dist 2] $placement_status [mptdc_o12b_csv [join $place_notes ";"]]] ","]

            set in_trans [lindex [mptdc_o12b_pin_metric $a_pin transition] 0]
            set out_pin_trans [lindex [mptdc_o12b_pin_metric $q_pin transition] 0]
            set delay_ps [mptdc_o12b_delay_ps $a_pin $q_pin]
            set delay_notes [list]
            if {$delay_ps eq ""} { lappend delay_notes "DELAY_ATTR_UNAVAILABLE" }
            puts $delay_fh [join [list \
                $family $tap [mptdc_o12b_csv $buf_inst] [mptdc_o12b_csv $cell_type] \
                [mptdc_o12b_csv $a_pin] [mptdc_o12b_csv $q_pin] $delay_ps \
                $in_trans $out_pin_trans [mptdc_o12b_clock_for $family $tap] \
                [mptdc_o12b_csv [join $delay_notes ";"]]] ","]

            set raw_route_data [mptdc_o12b_net_metric_resolved_named $raw_net $raw_net_obj route_length $raw_prop_path]
            set raw_route_len [lindex $raw_route_data 0]
            set route_notes [list "raw_and_buffered_route_from_report_property_safe_snapshot_or_dbget_when_available"]
            if {[lindex $raw_route_data 1] ne ""} { lappend route_notes "RAW_ROUTE_LENGTH_SOURCE=[lindex $raw_route_data 1]" }
            if {[lindex $route_data 1] ne ""} { lappend route_notes "BUFFERED_ROUTE_LENGTH_SOURCE=[lindex $route_data 1]" }
            set route_row [list \
                $family $tap [mptdc_o12b_csv $raw_net] $raw_route_len $raw_total_pf \
                [mptdc_o12b_csv $out_net] $route_len $total_pf $wire_pf $pin_pf \
                $res_ohm $out_status \
                [mptdc_o12b_csv [join $route_notes ";"]]]
            puts $route_fh [join $route_row ","]

            if {![info exists attr_probe_samples_written]} {
                set attr_probe_samples_written 1
                set attr_probe_samples [list \
                    [list "${family}_${tap}_raw_net" $raw_net_obj net $raw_net] \
                    [list "${family}_${tap}_buffered_net" $out_net_obj net $out_net] \
                    [list "${family}_${tap}_buffer_cell" [mptdc_o12b_get_cell $buf_inst]] \
                    [list "${family}_${tap}_buffer_input_pin" [mptdc_o11_pin_object $a_pin]] \
                    [list "${family}_${tap}_buffer_output_pin" [mptdc_o11_pin_object $q_pin]]]
            }

            if {![info exists ::env(MPTDC_O12B_NET_DEBUG)] || $::env(MPTDC_O12B_NET_DEBUG) ne "0"} {
                if {[catch {mptdc_o12b_write_net_debug_reports $family $tap $raw_net $out_net} dbg_err]} {
                    set route_debug_row [list \
                        $family $tap [mptdc_o12b_csv $raw_net] "" "" \
                        [mptdc_o12b_csv $out_net] "" "" "" "" \
                        "" "NET_DEBUG_CAPTURE_FAILED" \
                        [mptdc_o12b_csv "NET_DEBUG_CAPTURE_FAILED=$dbg_err"]]
                    puts $route_fh [join $route_debug_row ","]
                }
            }
        }
    }

    close $raw_fh
    close $out_fh
    close $topo_fh
    close $place_fh
    close $delay_fh
    close $route_fh
    close $sink_fh

    if {[info exists attr_probe_samples]} {
        if {[catch {mptdc_o12b_write_attr_probe $attr_probe_samples} probe_err]} {
            set probe_path "$o12b(reports_dir)/phase_buffer_db_attribute_probe.rpt"
            set pfh [open $probe_path w]
            puts $pfh "# O12B Innovus DB Attribute Probe"
            puts $pfh ""
            puts $pfh "ATTR_PROBE_FAILED=$probe_err"
            close $pfh
        }
    }

    set raw_fixed [expr {$raw_matched == 16 && $raw_missing == 0 && $raw_fanout1 == 16 ? "YES" : "NO"}]
    set out_quantified [expr {$out_matched == 16 && $out_numeric == 16 ? "YES" : "NO"}]
    set topology_ok [expr {$topo_match == 16 && $topo_bad == 0 ? "YES" : "NO"}]
    set placement_quantified [expr {$placement_numeric == 16 ? "YES" : "NO"}]
    set timing_quality [expr {$out_quantified eq "YES" && $topology_ok eq "YES" && $placement_quantified eq "YES" ? "YES" : "NO"}]

    set sfh [open $summary_path w]
    puts $sfh "# O12B Phase Buffer Balance Summary"
    puts $sfh ""
    puts $sfh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $sfh ""
    puts $sfh "- Source run: `$o12b(source_run_id)`"
    puts $sfh "- Strict analog D-load budget: `58.72 fF` (`0.05872 pF`)."
    puts $sfh "- CN/clock-like estimate: `75.59 fF` (`0.07559 pF`)."
    puts $sfh "- RO Liberty shell max-cap bound: `50.00 fF` (`0.050 pF`)."
    puts $sfh "- RAW_RO_LOAD_FIXED=$raw_fixed"
    puts $sfh "- BUFFER_OUTPUT_LOAD_QUANTIFIED=$out_quantified"
    puts $sfh "- TOPOLOGY_MATCHED=$topology_ok"
    puts $sfh "- PLACEMENT_QUANTIFIED=$placement_quantified"
    puts $sfh "- TIMING_DECISION_QUALITY=$timing_quality"
    puts $sfh "- Raw RO rows: $raw_rows."
    puts $sfh "- Matched raw RO rows: $raw_matched."
    puts $sfh "- Missing raw RO rows: $raw_missing."
    puts $sfh "- Raw fanout-1 rows: $raw_fanout1."
    puts $sfh "- Raw rows with DB numeric cap: $raw_numeric."
    puts $sfh "- Raw rows bounded by no max-cap violation: $raw_bound_ok."
    puts $sfh "- Buffer output rows: $out_rows."
    puts $sfh "- Matched buffer output rows: $out_matched."
    puts $sfh "- Missing buffer output rows: $out_missing."
    puts $sfh "- Buffer output rows with DB numeric cap: $out_numeric."
    if {$max_raw_cap_ff ne ""} {
        puts $sfh "- Max measured raw RO source load: `$max_raw_cap_ff fF` at `$max_raw_desc`."
    } else {
        puts $sfh "- Max measured raw RO source load: no numeric raw cap found; matched raw rows remain bounded by the 50 fF RO shell if absent from `drv_max_cap.rpt`."
    }
    if {$max_out_cap_ff ne ""} {
        puts $sfh "- Max measured buffer output load: `$max_out_cap_ff fF` at `$max_out_desc`."
    } else {
        puts $sfh "- Max measured buffer output load: `UNKNOWN`; no portable DB cap attribute returned a numeric value."
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
    puts $sfh "## Buffer Output Labels"
    puts $sfh ""
    puts $sfh "| Label | Row count |"
    puts $sfh "|---|---:|"
    foreach label {OK_STRICT OK_CN WARN_OVER_CN FAIL_HIGH_LOAD CRITICAL UNKNOWN} {
        set count 0
        if {[info exists out_labels($label)]} { set count $out_labels($label) }
        puts $sfh "| $label | $count |"
    }
    puts $sfh ""
    puts $sfh "## Topology"
    puts $sfh ""
    puts $sfh "- TOPOLOGY_SHAPE_MATCHED rows: $topo_match."
    puts $sfh "- Topology problem rows: $topo_bad."
    puts $sfh ""
    puts $sfh "Required CSVs:"
    puts $sfh ""
    puts $sfh "- `ro_phase_raw_pin_loads.csv`"
    puts $sfh "- `phase_buffer_output_loads.csv`"
    puts $sfh "- `phase_buffer_topology.csv`"
    puts $sfh "- `phase_buffer_placement.csv`"
    puts $sfh "- `phase_buffer_delay_estimate.csv`"
    puts $sfh "- `phase_buffer_route_summary.csv`"
    puts $sfh ""
    puts $sfh "This is O12B feasibility/debug evidence only. It does not waive timing, phase matching, characterization, or signoff."
    close $sfh

    set tfh [open $topo_summary_path w]
    puts $tfh "# O12B Phase Buffer Topology Summary"
    puts $tfh ""
    puts $tfh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $tfh ""
    puts $tfh "- Source run: `$o12b(source_run_id)`"
    puts $tfh "- Expected physical topology: one `BUHDX4` phase-isolation buffer per tap."
    puts $tfh "- Expected RTL define: `MPTDC_PHASE_BUFFER_USE_BUHDX4`."
    puts $tfh "- Expected source file: `MPTDC/rtl/osc/mptdc_phase_buffer_bank.sv`."
    puts $tfh "- TOPOLOGY_SHAPE_MATCHED rows: $topo_match of 16."
    puts $tfh "- Topology problem rows: $topo_bad of 16."
    puts $tfh ""
    puts $tfh "## Status Counts"
    puts $tfh ""
    puts $tfh "| Status | Row count |"
    puts $tfh "|---|---:|"
    foreach status {TOPOLOGY_SHAPE_MATCHED TOPOLOGY_MATCH MISSING_BUFFER EXTRA_BUFFER TOPOLOGY_MISMATCH} {
        set count 0
        if {[info exists topo_counts($status)]} { set count $topo_counts($status) }
        puts $tfh "| $status | $count |"
    }
    puts $tfh ""
    puts $tfh "If cell type is sourced through `rtl_define_fallback`, Innovus DB cell-name lookup did not return a lib-cell name, but the O12 source/filelist topology still identifies the intended BUHDX4 single-stage buffer."
    close $tfh

    set pfh [open $place_summary_path w]
    puts $pfh "# O12B Phase Buffer Placement Summary"
    puts $pfh ""
    puts $pfh "REPORT_STATUS=REVIEW_REQUIRED"
    puts $pfh ""
    puts $pfh "- Source run: `$o12b(source_run_id)`"
    puts $pfh "- Placement rows with numeric buffer location: $placement_numeric of 16."
    if {$min_ro_dist ne "" && $max_ro_dist ne ""} {
        puts $pfh "- RO-to-buffer Manhattan distance min/max: `$min_ro_dist` / `$max_ro_dist` database units."
        puts $pfh "- RO-to-buffer Manhattan mismatch: `[expr {$max_ro_dist - $min_ro_dist}]` database units."
    } else {
        puts $pfh "- RO-to-buffer Manhattan distance: `UNKNOWN`."
    }
    if {$min_route ne "" && $max_route ne ""} {
        puts $pfh "- Buffered net route length min/max: `$min_route` / `$max_route` database units."
        puts $pfh "- Buffered net route length mismatch: `[expr {$max_route - $min_route}]` database units."
    } else {
        puts $pfh "- Buffered net route length: `UNKNOWN`."
    }
    puts $pfh ""
    puts $pfh "If mismatch is large or locations are unavailable, prepare O12C explicit phase-buffer placement constraints before closure interpretation."
    close $pfh
}
