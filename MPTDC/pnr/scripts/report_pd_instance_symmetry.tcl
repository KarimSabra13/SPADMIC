# =============================================================================
# O0 PD instance placement report
# =============================================================================

proc mptdc_osc_pd_inst_ptr {inst} {
    set ptrs [list]
    catch {set ptrs [dbGet top.insts.name $inst -p]}
    foreach ptr $ptrs {
        if {$ptr ne "" && $ptr ne "0x0"} {
            return $ptr
        }
    }
    return ""
}

proc mptdc_osc_pd_db_attr_from_ptr {ptr attr} {
    if {$ptr eq ""} { return "" }
    set db_attrs [list $attr]
    switch -- $attr {
        .location { set db_attrs [list .pt .loc .box] }
        .bbox     { set db_attrs [list .box .bbox] }
        .base_cell.name { set db_attrs [list .cell.name .baseCell.name .master.name] }
        .place_status   { set db_attrs [list .pStatus .place_status .status] }
    }
    foreach db_attr $db_attrs {
        set val ""
        if {![catch {set val [dbGet ${ptr}${db_attr}]}] && $val ne ""} {
            return $val
        }
    }
    return ""
}

proc mptdc_osc_pd_db_attrs_for {attr} {
    switch -- $attr {
        .location { return [list .pt .loc .location .origin .box] }
        .bbox     { return [list .box .bbox .rect .bounds .place_box] }
        .base_cell.name { return [list .cell.name .baseCell.name .base_cell.name .lib_cell.name .master.name .ref_name] }
        .place_status   { return [list .pStatus .place_status .status] }
        default { return [list $attr] }
    }
}

proc mptdc_osc_pd_db_attr_from_obj {obj attr} {
    if {$obj eq ""} { return "" }
    if {[string match {hinst:*} "$obj"]} {
        return ""
    }
    foreach db_attr [mptdc_osc_pd_db_attrs_for $attr] {
        set val ""
        if {![catch {set val [get_db $obj $db_attr]}] && $val ne ""} {
            return $val
        }
    }
    return ""
}

proc mptdc_osc_pd_inst_attr {inst attrs} {
    set ptr [mptdc_osc_pd_inst_ptr $inst]
    foreach attr $attrs {
        set val [mptdc_osc_pd_db_attr_from_ptr $ptr $attr]
        if {$val ne ""} {
            return $val
        }
    }

    set obj [get_cells -quiet $inst]
    if {[llength $obj] == 0} {
        catch {set obj [get_cells -quiet -hierarchical $inst]}
    }
    set first_obj [lindex $obj 0]
    foreach attr $attrs {
        set val [mptdc_osc_pd_db_attr_from_obj $first_obj $attr]
        if {$val ne ""} {
            return $val
        }
    }
    foreach attr $attrs {
        if {[llength $obj] > 0 && ![catch {set val [get_object_name $obj]}] && $val ne "" && $attr eq ".name"} {
            return $val
        }
    }
    return ""
}

proc mptdc_osc_pd_box_from_attr {value} {
    if {[llength $value] == 1} {
        set value [lindex $value 0]
    }
    if {[llength $value] >= 4} {
        return [lrange $value 0 3]
    }
    return [list]
}

proc mptdc_osc_pd_norm_name {name} {
    set text "$name"
    regsub -all {\\([\[\]])} $text {\1} text
    return $text
}

proc mptdc_osc_pd_all_cell_objects {} {
    if {[info exists ::mptdc_osc_pd_all_cell_objects_cache]} {
        return $::mptdc_osc_pd_all_cell_objects_cache
    }
    set cells [list]
    catch {set cells [get_cells -quiet -hierarchical *]}
    set ::mptdc_osc_pd_all_cell_objects_cache $cells
    return $cells
}

proc mptdc_osc_pd_hier_leaf_bbox {inst} {
    set prefix "[mptdc_osc_pd_norm_name $inst]/"
    set found 0
    set llx ""
    set lly ""
    set urx ""
    set ury ""
    foreach obj [mptdc_osc_pd_all_cell_objects] {
        set name ""
        catch {set name [get_object_name $obj]}
        if {$name eq ""} {
            catch {set name [get_db $obj .name]}
        }
        set norm [mptdc_osc_pd_norm_name $name]
        if {[string first $prefix $norm] != 0} {
            continue
        }
        set box [mptdc_osc_pd_box_from_attr [mptdc_osc_pd_db_attr_from_obj $obj .bbox]]
        if {[llength $box] < 4} {
            continue
        }
        set b_llx [lindex $box 0]
        set b_lly [lindex $box 1]
        set b_urx [lindex $box 2]
        set b_ury [lindex $box 3]
        if {![string is double -strict $b_llx] || ![string is double -strict $b_lly]
            || ![string is double -strict $b_urx] || ![string is double -strict $b_ury]} {
            continue
        }
        if {!$found} {
            set llx $b_llx
            set lly $b_lly
            set urx $b_urx
            set ury $b_ury
        } else {
            if {$b_llx < $llx} { set llx $b_llx }
            if {$b_lly < $lly} { set lly $b_lly }
            if {$b_urx > $urx} { set urx $b_urx }
            if {$b_ury > $ury} { set ury $b_ury }
        }
        incr found
    }
    if {!$found} {
        return [list]
    }
    return [list $llx $lly $urx $ury $found]
}

proc mptdc_osc_pd_report_instance_symmetry {} {
    global pnr
    set out_dir [mptdc_osc_pd_result_dir]
    set csv "$out_dir/pd_instance_placement.csv"
    set summary "$out_dir/pd_instance_symmetry_summary.md"
    set cells [mptdc_osc_pd_cells [list *gen_pd_row*gen_pd_col*u_pd*]]
    set boxes [mptdc_pnr_sandwich_boxes]
    set pd_box [dict get $boxes pd]
    set pd_llx [lindex $pd_box 0]
    set pd_lly [lindex $pd_box 1]
    set pd_urx [lindex $pd_box 2]
    set pd_ury [lindex $pd_box 3]
    set pitch_x [expr {($pd_urx - $pd_llx) / 8.0}]
    set pitch_y [expr {($pd_ury - $pd_lly) / 8.0}]

    set fh [open $csv w]
    puts $fh "instance,ns,nf,x_um,y_um,llx_um,lly_um,urx_um,ury_um,orient,place_status,expected_region,status,master,width_um,height_um,row,col,expected_x_um,expected_y_um,dx_um,dy_um"
    set coord_valid_count 0
    set missing_coord [list]
    set missing_bbox [list]
    set missing_logic [list]
    set large_offsets [list]
    foreach cell [lsort $cells] {
        set ns ""
        set nf ""
        if {![mptdc_osc_pd_parse_ns_nf $cell ns nf]} {
            lappend missing_logic $cell
        }
        set loc [mptdc_osc_pd_inst_attr $cell [list .location .pt]]
        set x ""
        set y ""
        if {[llength $loc] >= 2} {
            set x [lindex $loc 0]
            set y [lindex $loc 1]
        }
        set orient [mptdc_osc_pd_inst_attr $cell [list .orient]]
        set master [mptdc_osc_pd_inst_attr $cell [list .base_cell.name .cell.name .master.name]]
        set place_status [mptdc_osc_pd_inst_attr $cell [list .place_status .pStatus .status]]
        set bbox [mptdc_osc_pd_box_from_attr [mptdc_osc_pd_inst_attr $cell [list .bbox .box]]]
        set bbox_source "direct"
        set leaf_count ""
        if {[llength $bbox] < 4} {
            set hier_bbox [mptdc_osc_pd_hier_leaf_bbox $cell]
            if {[llength $hier_bbox] >= 4} {
                set bbox [lrange $hier_bbox 0 3]
                set bbox_source "hier_leaf_aggregate"
                set leaf_count [lindex $hier_bbox 4]
            }
        }
        set inst_llx ""
        set inst_lly ""
        set inst_urx ""
        set inst_ury ""
        set width ""
        set height ""
        if {[llength $bbox] >= 4} {
            set inst_llx [lindex $bbox 0]
            set inst_lly [lindex $bbox 1]
            set inst_urx [lindex $bbox 2]
            set inst_ury [lindex $bbox 3]
            set width [expr {$inst_urx - $inst_llx}]
            set height [expr {$inst_ury - $inst_lly}]
            if {$x eq "" || $y eq ""} {
                if {$bbox_source eq "hier_leaf_aggregate"} {
                    set x [expr {($inst_llx + $inst_urx) / 2.0}]
                    set y [expr {($inst_lly + $inst_ury) / 2.0}]
                } else {
                    set x $inst_llx
                    set y $inst_lly
                }
            }
        }
        if {$bbox_source eq "hier_leaf_aggregate"} {
            if {$master eq ""} { set master "HIER_LEAF_AGGREGATE_${leaf_count}_LEAVES" }
            if {$place_status eq ""} { set place_status "AGGREGATED_FROM_PLACED_LEAVES" }
        }
        set exp_x ""
        set exp_y ""
        set dx ""
        set dy ""
        if {$ns ne "" && $nf ne ""} {
            set exp_x [mptdc_pnr_snap [expr {$pd_llx + ($ns + 0.5) * $pitch_x}]]
            set exp_y [mptdc_pnr_snap [expr {$pd_lly + ($nf + 0.5) * $pitch_y}]]
            if {$x ne "" && $y ne ""} {
                set dx [expr {$x - $exp_x}]
                set dy [expr {$y - $exp_y}]
                incr coord_valid_count
                if {abs($dx) > 5.0 || abs($dy) > 5.0} {
                    lappend large_offsets $cell
                }
            }
        }
        set row_status "OK"
        if {$x eq "" || $y eq ""} {
            set row_status "COORDINATE_MISSING"
            lappend missing_coord $cell
        } elseif {$inst_llx eq "" || $inst_lly eq "" || $inst_urx eq "" || $inst_ury eq ""} {
            set row_status "BBOX_MISSING"
            lappend missing_bbox $cell
        }
        puts $fh "$cell,$ns,$nf,$x,$y,$inst_llx,$inst_lly,$inst_urx,$inst_ury,$orient,$place_status,pd_matrix,$row_status,$master,$width,$height,$nf,$ns,$exp_x,$exp_y,$dx,$dy"
    }
    close $fh

    set report_status "PASS"
    if {[llength $cells] != 64 || [llength $missing_logic] > 0 || [llength $missing_coord] > 0} {
        set report_status "INVALID"
    } elseif {[llength $missing_bbox] > 0 || [llength $large_offsets] > 0} {
        set report_status "REVIEW_REQUIRED"
    }

    set sfh [open $summary w]
    puts $sfh "# PD Instance Symmetry Summary"
    puts $sfh ""
    puts $sfh "REPORT_STATUS=$report_status"
    puts $sfh ""
    puts $sfh "- Cells found: [llength $cells]"
    puts $sfh "- Expected cells: 64"
    puts $sfh "- Coordinate-valid cells: $coord_valid_count"
    puts $sfh "- Missing logical index cells: [llength $missing_logic]"
    puts $sfh "- Missing coordinate cells: [llength $missing_coord]"
    puts $sfh "- Missing bbox cells: [llength $missing_bbox]"
    puts $sfh "- Large offset cells over 5 um: [llength $large_offsets]"
    puts $sfh "- CSV: pd_instance_placement.csv"
    puts $sfh ""
    if {[llength $cells] != 64} {
        puts $sfh "RED STATUS: expected 64 PD cells."
    } else {
        puts $sfh "Count check: PASS"
    }
    if {[llength $missing_coord] > 0} {
        puts $sfh ""
        puts $sfh "## Missing Coordinates"
        foreach cell $missing_coord {
            puts $sfh "- `$cell`"
        }
    }
    puts $sfh ""
    puts $sfh "Run tools/timing/analyze_pd_instance_symmetry.py for duplicate/missing/offset details."
    close $sfh
}
