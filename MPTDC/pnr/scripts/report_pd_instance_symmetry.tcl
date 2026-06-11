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

proc mptdc_osc_pd_report_instance_symmetry {} {
    global pnr
    set out_dir [mptdc_osc_pd_result_dir]
    set csv "$out_dir/pd_instance_placement.csv"
    set summary "$out_dir/pd_instance_symmetry_summary.md"
    set cells [mptdc_osc_pd_cells [list *gen_pd_row*gen_pd_col*u_pd*]]
    set boxes [mptdc_pnr_sandwich_boxes]
    set pd_box [dict get $boxes pd]
    set llx [lindex $pd_box 0]
    set lly [lindex $pd_box 1]
    set urx [lindex $pd_box 2]
    set ury [lindex $pd_box 3]
    set pitch_x [expr {($urx - $llx) / 8.0}]
    set pitch_y [expr {($ury - $lly) / 8.0}]

    set fh [open $csv w]
    puts $fh "instance,ns,nf,x_um,y_um,llx_um,lly_um,urx_um,ury_um,orient,place_status,expected_region,status,master,width_um,height_um,row,col,expected_x_um,expected_y_um,dx_um,dy_um"
    set coord_valid_count 0
    set missing_coord [list]
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
        set llx ""
        set lly ""
        set urx ""
        set ury ""
        set width ""
        set height ""
        if {[llength $bbox] >= 4} {
            set llx [lindex $bbox 0]
            set lly [lindex $bbox 1]
            set urx [lindex $bbox 2]
            set ury [lindex $bbox 3]
            set width [expr {$urx - $llx}]
            set height [expr {$ury - $lly}]
            if {$x eq "" || $y eq ""} {
                set x $llx
                set y $lly
            }
        }
        set exp_x ""
        set exp_y ""
        set dx ""
        set dy ""
        if {$ns ne "" && $nf ne ""} {
            set exp_x [mptdc_pnr_snap [expr {$llx + ($ns + 0.5) * $pitch_x}]]
            set exp_y [mptdc_pnr_snap [expr {$lly + ($nf + 0.5) * $pitch_y}]]
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
        if {$x eq "" || $y eq "" || $llx eq "" || $lly eq "" || $urx eq "" || $ury eq ""} {
            set row_status "COORDINATE_MISSING"
            lappend missing_coord $cell
        }
        puts $fh "$cell,$ns,$nf,$x,$y,$llx,$lly,$urx,$ury,$orient,$place_status,pd_matrix,$row_status,$master,$width,$height,$nf,$ns,$exp_x,$exp_y,$dx,$dy"
    }
    close $fh

    set report_status "PASS"
    if {[llength $cells] != 64 || [llength $missing_logic] > 0 || [llength $missing_coord] > 0} {
        set report_status "INVALID"
    } elseif {[llength $large_offsets] > 0} {
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
