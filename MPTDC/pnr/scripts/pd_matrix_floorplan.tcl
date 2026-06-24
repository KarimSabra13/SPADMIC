# =============================================================================
# O0 PD matrix regular-grid placement intent
# =============================================================================

set mptdc_pd_matrix_script_dir [file dirname [file normalize [info script]]]
set mptdc_pd_matrix_place_utils [file join $mptdc_pd_matrix_script_dir innovus_mptdc_place_utils.tcl]
if {[file exists $mptdc_pd_matrix_place_utils]} {
    source $mptdc_pd_matrix_place_utils
}
unset mptdc_pd_matrix_script_dir
unset mptdc_pd_matrix_place_utils

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

proc mptdc_osc_pd_flat_value {value} {
    while {[llength $value] == 1} {
        set value [lindex $value 0]
    }
    return $value
}

proc mptdc_osc_pd_size_from_value {value} {
    set value [mptdc_osc_pd_flat_value $value]
    if {[llength $value] < 2} { return [list] }
    foreach v [lrange $value 0 1] {
        if {![string is double -strict $v]} { return [list] }
    }
    if {[llength $value] >= 4} {
        foreach v [lrange $value 0 3] {
            if {![string is double -strict $v]} { return [list] }
        }
        set width [expr {[lindex $value 2] - [lindex $value 0]}]
        set height [expr {[lindex $value 3] - [lindex $value 1]}]
    } else {
        set width [lindex $value 0]
        set height [lindex $value 1]
    }
    if {$width <= 0.0 || $height <= 0.0} { return [list] }
    return [list $width $height]
}

proc mptdc_osc_pd_member_size {member} {
    set ptr [mptdc_osc_pd_inst_ptr $member]
    foreach attr {
        .cell.size .baseCell.size .base_cell.size .libCell.size .master.size
        .cell.box .baseCell.box .base_cell.box .libCell.box .master.box
        .cell.bbox .baseCell.bbox .base_cell.bbox .libCell.bbox .master.bbox
        .box .bbox
    } {
        set value ""
        if {$ptr ne "" && ![catch {set value [dbGet ${ptr}${attr}]}] && $value ne ""} {
            set size [mptdc_osc_pd_size_from_value $value]
            if {[llength $size] == 2} { return $size }
        }
    }

    set objs [list]
    catch {set objs [get_cells -quiet $member]}
    if {[llength $objs] == 0} {
        catch {set objs [get_cells -quiet -hierarchical $member]}
    }
    set obj [lindex $objs 0]
    foreach attr {
        .base_cell.size .lib_cell.size .master.size .cell.size
        .base_cell.box .lib_cell.box .master.box .cell.box
        .base_cell.bbox .lib_cell.bbox .master.bbox .cell.bbox
        .bbox .box
    } {
        set value ""
        if {$obj ne "" && ![catch {set value [get_db $obj $attr]}] && $value ne ""} {
            set size [mptdc_osc_pd_size_from_value $value]
            if {[llength $size] == 2} { return $size }
        }
    }

    return [list \
        [mptdc_pnr_env MPTDC_PNR_PD_TILE_DEFAULT_CELL_WIDTH_UM 4.48] \
        [mptdc_pnr_env MPTDC_PNR_PD_TILE_ROW_HEIGHT_UM 4.48]]
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

proc mptdc_osc_pd_snap_up {value step} {
    if {$step <= 0.0} { return $value }
    return [expr {ceil($value / $step) * $step}]
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

proc mptdc_osc_pd_apply_leaf_tile_box {member box fh} {
    set llx [lindex $box 0]
    set lly [lindex $box 1]
    set urx [lindex $box 2]
    set ury [lindex $box 3]
    if {![catch {setObjFPlanBox Instance $member $llx $lly $urx $ury} err]} {
        return 1
    }
    puts $fh "  leaf_tile_box_warning $member $box: $err"
    return 0
}

proc mptdc_osc_pd_preplace_tile_members {members box fh} {
    if {![mptdc_pnr_env MPTDC_PNR_PD_TILE_PREPLACE_LEAVES 1]} {
        return [dict create enabled 0 box_constraints 0 preplaced 0 failures 0 overflow 0]
    }
    set llx [lindex $box 0]
    set lly [lindex $box 1]
    set urx [lindex $box 2]
    set ury [lindex $box 3]
    set site_w [mptdc_pnr_env MPTDC_PNR_PD_TILE_SITE_WIDTH_UM 0.56]
    set row_h [mptdc_pnr_env MPTDC_PNR_PD_TILE_ROW_HEIGHT_UM 4.48]
    set spacing [mptdc_pnr_env MPTDC_PNR_PD_TILE_MEMBER_SPACING_UM 0.0]
    set fix_leaves [mptdc_pnr_env MPTDC_PNR_PD_TILE_FIX_LEAVES 1]
    set orient [mptdc_pnr_env MPTDC_PNR_PD_TILE_ORIENT AUTO]
    set tile_w [expr {$urx - $llx}]
    set tile_h [expr {$ury - $lly}]

    set leaf_box_count 0
    set entries [list]
    foreach member $members {
        if {[mptdc_osc_pd_apply_leaf_tile_box $member $box $fh]} {
            incr leaf_box_count
        }
        set size [mptdc_osc_pd_member_size $member]
        set width [mptdc_osc_pd_snap_up [lindex $size 0] $site_w]
        set height [mptdc_osc_pd_snap_up [lindex $size 1] $row_h]
        if {$width <= 0.0} { set width $site_w }
        if {$height <= 0.0} { set height $row_h }
        if {$height > $row_h} { set row_h $height }
        lappend entries [list $width $height $member]
    }

    set rows [list]
    set row [list]
    set row_width 0.0
    foreach entry [lsort -real -decreasing -index 0 $entries] {
        set width [lindex $entry 0]
        set next_width [expr {$row_width + ($row_width > 0.0 ? $spacing : 0.0) + $width}]
        if {[llength $row] > 0 && $next_width > $tile_w} {
            lappend rows [list $row_width $row]
            set row [list]
            set row_width 0.0
            set next_width $width
        }
        lappend row $entry
        set row_width $next_width
    }
    if {[llength $row] > 0} {
        lappend rows [list $row_width $row]
    }

    set overflow 0
    set total_h [expr {[llength $rows] * $row_h}]
    if {$total_h > $tile_h} {
        set overflow 1
        puts $fh "  tile_pack_overflow rows=[llength $rows] row_h=$row_h tile_h=$tile_h"
    }
    set y [mptdc_pnr_snap [expr {$lly + max(0.0, ($tile_h - $total_h) / 2.0)}]]
    set preplaced 0
    set failures 0
    foreach row_item $rows {
        set row_width [lindex $row_item 0]
        set row_entries [lindex $row_item 1]
        set x [mptdc_pnr_snap [expr {$llx + max(0.0, ($tile_w - $row_width) / 2.0)}]]
        foreach entry $row_entries {
            set width [lindex $entry 0]
            set member [lindex $entry 2]
            if {[llength [info commands mptdc_pnr_place_instance_row_legal]] > 0} {
                set place_result [mptdc_pnr_place_instance_row_legal $member $x $y $orient $fix_leaves]
                if {[dict get $place_result status] eq "PASS"} {
                    incr preplaced
                    puts $fh "  leaf_preplaced $member x=$x y=$y orient=$orient command=[dict get $place_result command] fixed_status=[dict get $place_result fixed_status]"
                } else {
                    incr failures
                    puts $fh "  leaf_preplace_warning $member x=$x y=$y orient=$orient errors=[dict get $place_result errors]"
                }
            } else {
                set cmd [list placeInstance $member $x $y]
                if {[catch {eval $cmd} err]} {
                    incr failures
                    puts $fh "  leaf_preplace_warning $member x=$x y=$y: $err"
                } else {
                    incr preplaced
                }
            }
            set x [mptdc_pnr_snap [expr {$x + $width + $spacing}]]
        }
        set y [mptdc_pnr_snap [expr {$y + $row_h}]]
    }
    return [dict create \
        enabled 1 \
        box_constraints $leaf_box_count \
        preplaced $preplaced \
        failures $failures \
        overflow $overflow]
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
    set leaf_box_constraints 0
    set leaf_preplacements 0
    set leaf_preplacement_failures 0
    set leaf_pack_overflows 0
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
        set preplace_result [mptdc_osc_pd_preplace_tile_members $members $tile_box $fh]
        incr leaf_box_constraints [dict get $preplace_result box_constraints]
        incr leaf_preplacements [dict get $preplace_result preplaced]
        incr leaf_preplacement_failures [dict get $preplace_result failures]
        incr leaf_pack_overflows [dict get $preplace_result overflow]
        puts $fh "  leaf_tile_box_constraints=[dict get $preplace_result box_constraints]"
        puts $fh "  leaf_preplacements=[dict get $preplace_result preplaced]"
        puts $fh "  leaf_preplacement_failures=[dict get $preplace_result failures]"
        puts $fh "  leaf_pack_overflow=[dict get $preplace_result overflow]"
    }

    puts $fh ""
    puts $fh "Tile box constraints accepted: $placed"
    puts $fh "Tile regions accepted: $tile_regions"
    puts $fh "Tile region failures: $tile_region_failures"
    puts $fh "Tile region assignments: $tile_region_assignments"
    puts $fh "Leaf tile box constraints accepted: $leaf_box_constraints"
    puts $fh "Leaf preplacements accepted: $leaf_preplacements"
    puts $fh "Leaf preplacement failures: $leaf_preplacement_failures"
    puts $fh "Leaf pack overflows: $leaf_pack_overflows"
    puts $fh "If tile region count is below 64, the synthesized PD hierarchy could not be decomposed into leaf-cell groups for physical matrix enforcement."
    close $fh
    return [dict create \
        report $rpt \
        tile_regions $tile_regions \
        tile_region_failures $tile_region_failures \
        tile_region_assignments $tile_region_assignments \
        tile_box_constraints $placed \
        leaf_tile_box_constraints $leaf_box_constraints \
        leaf_preplacements $leaf_preplacements \
        leaf_preplacement_failures $leaf_preplacement_failures \
        leaf_pack_overflows $leaf_pack_overflows]
}
