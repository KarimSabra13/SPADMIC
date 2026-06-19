# =============================================================================
# O0 PD matrix regular-grid placement intent
# =============================================================================

proc mptdc_osc_pd_parse_ns_nf {inst ns_var nf_var} {
    upvar 1 $ns_var ns
    upvar 1 $nf_var nf
    set ns ""
    set nf ""
    if {[regexp {gen_pd_row\[([0-9]+)\].*gen_pd_col\[([0-9]+)\]} $inst -> ns nf]} {
        return 1
    }
    if {[regexp {gen_pd_row_([0-9]+).*gen_pd_col_([0-9]+)} $inst -> ns nf]} {
        return 1
    }
    return 0
}

proc mptdc_osc_pd_norm_name {name} {
    set text "$name"
    regsub -all {\\([\[\]])} $text {\1} text
    return $text
}

proc mptdc_osc_pd_object_name {obj} {
    if {![regexp {^(inst|hinst|pin|net|term):|^0x[0-9a-fA-F]+$} "$obj"]} {
        return "$obj"
    }
    set name ""
    catch {set name [get_object_name $obj]}
    if {$name eq ""} { catch {set name [get_db $obj .name]} }
    return $name
}

proc mptdc_osc_pd_box_from_obj {obj} {
    if {$obj eq ""} { return [list] }
    set attrs [list .bbox .rect .bounds .place_box]
    foreach attr $attrs {
        set value ""
        if {![catch {set value [get_db $obj $attr]}] && $value ne ""} {
            while {[llength $value] == 1} { set value [lindex $value 0] }
            if {[llength $value] < 4} { continue }
            set box [lrange $value 0 3]
            set ok 1
            foreach v $box {
                if {![string is double -strict $v]} { set ok 0 }
            }
            if {$ok && [lindex $box 2] > [lindex $box 0] && [lindex $box 3] > [lindex $box 1]} {
                return $box
            }
        }
    }
    return [list]
}

proc mptdc_osc_pd_leaf_objects_under {inst} {
    set prefix "[mptdc_osc_pd_norm_name $inst]/"
    set out [list]
    set db_names [list]
    catch {set db_names [dbGet top.insts.name]}
    foreach name $db_names {
        if {$name eq ""} { continue }
        set norm [mptdc_osc_pd_norm_name $name]
        if {$norm eq [mptdc_osc_pd_norm_name $inst]} { continue }
        if {[string first $prefix $norm] == 0 && [lsearch -exact $out $name] < 0} {
            lappend out $name
        }
    }
    set all_cells [list]
    catch {set all_cells [get_cells -quiet -hierarchical *]}
    foreach obj $all_cells {
        set name [mptdc_osc_pd_object_name $obj]
        if {$name eq ""} { continue }
        if {[string match {hinst:*} "$obj"] || [string match {hinst:*} "$name"]} {
            continue
        }
        set norm [mptdc_osc_pd_norm_name $name]
        if {$norm eq [mptdc_osc_pd_norm_name $inst]} { continue }
        if {[string first $prefix $norm] == 0 && [lsearch -exact $out $name] < 0} {
            lappend out $name
        }
    }
    return $out
}

proc mptdc_osc_pd_tile_group_name {ns nf} {
    return "mptdc_pd_tile_${ns}_${nf}"
}

proc mptdc_osc_pd_group_member_name {item} {
    if {![regexp {^(inst|hinst|pin|net|term):|^0x[0-9a-fA-F]+$} "$item"]} {
        return "$item"
    }
    set name [mptdc_osc_pd_object_name $item]
    if {$name eq ""} {
        set name "$item"
    }
    return $name
}

proc mptdc_osc_pd_create_tile_region {group box members fh} {
    set llx [lindex $box 0]
    set lly [lindex $box 1]
    set urx [lindex $box 2]
    set ury [lindex $box 3]
    set added 0
    if {[catch {createInstGroup $group} err]} {
        puts $fh "  group_create_warning $group: $err"
    } else {
        puts $fh "  group_created $group"
    }
    foreach obj $members {
        set member_name [mptdc_osc_pd_group_member_name $obj]
        if {$member_name eq ""} { continue }
        if {![catch {addInstToInstGroup $group $member_name} err]} {
            incr added
        } else {
            puts $fh "  group_add_warning $group $member_name: $err"
        }
    }
    set region_status FAIL
    set constraint_type NONE
    if {$added > 0} {
        set use_fence [mptdc_pnr_env MPTDC_PNR_PD_TILE_USE_FENCE 1]
        if {$use_fence && ![info exists ::mptdc_osc_pd_create_fence_usable]} {
            set ::mptdc_osc_pd_create_fence_usable [expr {[llength [info commands createFence]] > 0}]
        }
        if {$use_fence && $::mptdc_osc_pd_create_fence_usable} {
            if {![catch {createFence $group $llx $lly $urx $ury} err]} {
                set region_status PASS
                set constraint_type FENCE
            } else {
                puts $fh "  fence_create_warning $group $box: $err"
                set ::mptdc_osc_pd_create_fence_usable 0
            }
        }
        if {$region_status ne "PASS" && ![catch {createRegion $group $llx $lly $urx $ury} err]} {
            set region_status PASS
            set constraint_type REGION
        } else {
            if {$region_status ne "PASS"} {
                puts $fh "  region_create_warning $group $box: $err"
            }
        }
    }
    puts $fh "  tile_region group=$group member_count=$added box=$box constraint=$constraint_type status=$region_status"
    return [list $added $region_status $constraint_type]
}

proc mptdc_osc_pd_apply_tile_box {cell_name box fh} {
    set llx [lindex $box 0]
    set lly [lindex $box 1]
    set urx [lindex $box 2]
    set ury [lindex $box 3]
    if {![catch {setObjFPlanBox Instance $cell_name $llx $lly $urx $ury} err]} {
        puts $fh "  applied: setObjFPlanBox Instance {$cell_name} $llx $lly $urx $ury"
        return 1
    }
    puts $fh "  tile_box_warning $cell_name $box: $err"
    return 0
}

proc mptdc_osc_pd_apply_pd_matrix_floorplan {} {
    global pnr
    set out_dir [mptdc_osc_pd_result_dir]
    set rpt "$out_dir/pd_matrix_floorplan.rpt"
    set fh [open $rpt w]
    puts $fh "MPTDC O0 PD matrix floorplan"
    puts $fh "==========================="
    puts $fh "Generated: [mptdc_osc_pd_timestamp]"
    puts $fh "Topology A: columns=slow/ns, rows=fast/nf"
    puts $fh "Topology B remains documented and must be evaluated after real pin order arrives."
    puts $fh ""

    set cells [mptdc_osc_pd_cells [list *gen_pd_row*gen_pd_col*u_pd*]]
    set boxes [mptdc_pnr_sandwich_boxes]
    if {![dict exists $boxes pd]} {
        puts $fh "FATAL: no PD box available"
        close $fh
        error "O0 PD matrix floorplan failed: no PD box"
    }
    set pd_box [dict get $boxes pd]
    set llx [lindex $pd_box 0]
    set lly [lindex $pd_box 1]
    set urx [lindex $pd_box 2]
    set ury [lindex $pd_box 3]
    set pitch_x [expr {($urx - $llx) / 8.0}]
    set pitch_y [expr {($ury - $lly) / 8.0}]

    puts $fh "PD box: $pd_box"
    puts $fh "Pitch x/y: $pitch_x / $pitch_y"
    puts $fh ""

    set placed 0
    set tile_regions 0
    set tile_region_assignments 0
    set tile_region_failures 0
    set margin [mptdc_pnr_env MPTDC_PNR_PD_TILE_REGION_MARGIN_UM 1.0]
    foreach cell [lsort $cells] {
        set cell_name [mptdc_osc_pd_object_name $cell]
        if {$cell_name eq ""} { set cell_name "$cell" }
        set ns ""
        set nf ""
        if {![mptdc_osc_pd_parse_ns_nf $cell_name ns nf]} {
            puts $fh "SKIP unparsable cell: raw=$cell name=$cell_name"
            continue
        }
        set tile_llx [mptdc_pnr_snap [expr {$llx + ($ns * $pitch_x) + $margin}]]
        set tile_lly [mptdc_pnr_snap [expr {$lly + ($nf * $pitch_y) + $margin}]]
        set tile_urx [mptdc_pnr_snap [expr {$llx + (($ns + 1) * $pitch_x) - $margin}]]
        set tile_ury [mptdc_pnr_snap [expr {$lly + (($nf + 1) * $pitch_y) - $margin}]]
        set tile_box [list $tile_llx $tile_lly $tile_urx $tile_ury]
        set x [mptdc_pnr_snap [expr {$llx + ($ns * $pitch_x)}]]
        set y [mptdc_pnr_snap [expr {$lly + ($nf * $pitch_y)}]]
        puts $fh "CELL $cell_name ns=$ns nf=$nf origin=($x,$y) tile_box=$tile_box"
        set leaf_objs [mptdc_osc_pd_leaf_objects_under $cell_name]
        if {[llength $leaf_objs] > 0} {
            set members $leaf_objs
        } else {
            set members [list $cell_name]
        }
        puts $fh "  leaf_member_count=[llength $leaf_objs]"
        set group [mptdc_osc_pd_tile_group_name $ns $nf]
        set tile_result [mptdc_osc_pd_create_tile_region $group $tile_box $members $fh]
        incr tile_region_assignments [lindex $tile_result 0]
        if {[lindex $tile_result 1] eq "PASS"} {
            incr tile_regions
        } else {
            incr tile_region_failures
        }
        if {[mptdc_osc_pd_apply_tile_box $cell_name $tile_box $fh]} {
            incr placed
        }
    }

    puts $fh ""
    puts $fh "Tile box constraints accepted: $placed"
    puts $fh "Tile regions accepted: $tile_regions"
    puts $fh "Tile region failures: $tile_region_failures"
    puts $fh "Tile region assignments: $tile_region_assignments"
    puts $fh "If tile region count is below 64, the synthesized PD hierarchy could not be decomposed into leaf-cell groups for physical matrix enforcement."
    close $fh
    return [dict create \
        report $rpt \
        tile_regions $tile_regions \
        tile_region_failures $tile_region_failures \
        tile_region_assignments $tile_region_assignments \
        tile_box_constraints $placed]
}
