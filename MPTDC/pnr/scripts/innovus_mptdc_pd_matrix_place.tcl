# =============================================================================
# Stable MPTDC PD matrix 8x8 placement/audit hook
# =============================================================================

set mptdc_pd_script_dir [file dirname [file normalize [info script]]]
source [file join $mptdc_pd_script_dir innovus_mptdc_floorplan.tcl]
source [file join $mptdc_pd_script_dir osc_pd_regions.tcl]
source [file join $mptdc_pd_script_dir pd_matrix_floorplan.tcl]
unset mptdc_pd_script_dir

if {[llength [info commands mptdc_pnr_env]] == 0} {
    proc mptdc_pnr_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_pnr_pd_grid_enabled {} {
    return [mptdc_pnr_env MPTDC_PNR_PLACE_PD_GRID 0]
}

proc mptdc_pnr_fast_tags_by_column_enabled {} {
    return [mptdc_pnr_env MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN 0]
}

proc mptdc_pnr_env_truthy {name {default_value 0}} {
    set value [string tolower [mptdc_pnr_env $name $default_value]]
    return [expr {$value in {1 yes true on}}]
}

proc mptdc_pnr_exact_fast_tag_bits {} {
    return [split [mptdc_pnr_env MPTDC_FAST_TAG_REPAIR_EXACT_BITS "0 5 6"]]
}

proc mptdc_pnr_exact_fast_tag_taps {} {
    return [split [mptdc_pnr_env MPTDC_FAST_TAG_REPAIR_EXACT_TAPS "0 1 2 3 4 5 6 7"]]
}

proc mptdc_pnr_pd_grid_shape {} {
    return [list rows 8 cols 8 cells 64]
}

proc mptdc_pnr_pd_instance_patterns {} {
    if {[info exists ::env(MPTDC_PNR_PD_INSTANCE_PATTERNS)] && $::env(MPTDC_PNR_PD_INSTANCE_PATTERNS) ne ""} {
        return [split $::env(MPTDC_PNR_PD_INSTANCE_PATTERNS)]
    }
    return [list "*gen_pd_row*gen_pd_col*u_pd*" "*mptdc_pd_cell*" "*u_pd*"]
}

proc mptdc_pnr_write_pd_grid_intent {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_PD_GRID_REPORT mptdc_pd_grid_intent.rpt]
    }
    set fh [open $path w]
    puts $fh "# MPTDC PD Grid Intent"
    puts $fh "enabled=[mptdc_pnr_pd_grid_enabled]"
    puts $fh "fast_tags_by_column=[mptdc_pnr_fast_tags_by_column_enabled]"
    puts $fh "exact_fast_tag_taps=[mptdc_pnr_exact_fast_tag_taps]"
    puts $fh "exact_fast_tag_bits=[mptdc_pnr_exact_fast_tag_bits]"
    puts $fh "fast_tag_to_pd_timing_path=TIMED_DO_NOT_FALSE_PATH_DO_NOT_MULTICYCLE"
    puts $fh "shape=[mptdc_pnr_pd_grid_shape]"
    puts $fh "patterns=[mptdc_pnr_pd_instance_patterns]"
    close $fh
    return $path
}

proc mptdc_pnr_write_fast_tag_column_intent {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_FAST_TAG_COLUMN_REPORT mptdc_fast_tag_column_intent.rpt]
    }
    set fh [open $path w]
    puts $fh "# MPTDC Fast-Tag Column Placement Intent"
    puts $fh "enabled=[mptdc_pnr_fast_tags_by_column_enabled]"
    puts $fh "path_family=FAST_TAG_TO_PD_TS"
    puts $fh "route_length_report=reports/fast_tag_to_pd_route_lengths.csv"
    puts $fh "timing_report=reports/fast_tag_to_pd_timing_post_route.rpt"
    puts $fh "decision_field=FAST_TAG_TO_PD_TS_POSTROUTE_CLEAN"
    puts $fh "exact_taps=[mptdc_pnr_exact_fast_tag_taps]"
    puts $fh "exact_bits=[mptdc_pnr_exact_fast_tag_bits]"
    puts $fh "rule=place_each_fast_tag_generator_near_matching_pd_column_or_center_spine"
    puts $fh "rule=keep_bits_0_5_6_routes_short_and_local"
    close $fh
    return $path
}

proc mptdc_pnr_unique_append {var_name value} {
    upvar 1 $var_name values
    if {$value eq ""} { return }
    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}

proc mptdc_pnr_collect_cells_local {patterns} {
    if {[llength [info commands mptdc_signoff_collect_cells]] > 0} {
        return [mptdc_signoff_collect_cells $patterns]
    }
    if {[llength [info commands mptdc_pnr_collect_cells]] > 0} {
        return [mptdc_pnr_collect_cells $patterns]
    }
    set out [list]
    foreach pattern $patterns {
        set cells [list]
        catch {set cells [get_cells -quiet -hierarchical $pattern]}
        foreach cell $cells {
            set name "$cell"
            catch {set name [get_object_name $cell]}
            if {$name eq ""} { catch {set name [get_db $cell .name]} }
            mptdc_pnr_unique_append out $name
        }
    }
    return $out
}

proc mptdc_pnr_fast_tag_bit_allowed {bit} {
    set raw [string trim [mptdc_pnr_env MPTDC_PNR_FAST_TAG_COLUMN_BITS ALL]]
    if {$raw eq ""} { return 1 }
    set lower [string tolower $raw]
    if {$lower in {all "*"}} { return 1 }
    set raw [string map [list "," " "] $raw]
    foreach item [split $raw] {
        set item [string trim $item]
        if {$item ne "" && $item eq "$bit"} {
            return 1
        }
    }
    return 0
}

proc mptdc_pnr_fast_tag_cell_info {inst} {
    set name [mptdc_osc_pd_norm_name "$inst"]
    if {[regexp {gen_fast_tag_col\[([0-9]+)\].*tag_o_reg\[([0-9]+)\]} $name -> col bit]} {
        return [dict create col $col bit $bit name "$inst"]
    }
    if {[regexp {gen_fast_tag_col_?([0-9]+)([^0-9].*)?tag_o_reg_?([0-9]+)([^0-9]|$)} $name -> col _ bit _]} {
        return [dict create col $col bit $bit name "$inst"]
    }
    return ""
}

proc mptdc_pnr_collect_fast_tag_column_cells {} {
    set patterns [list \
        *gen_fast_tag_col*u_fast_tag*tag_o_reg* \
        *gen_fast_tag_col*tag_o_reg* \
        *u_fast_tag_tag_o_reg*]
    set records [list]
    array set seen {}
    foreach inst [mptdc_pnr_collect_cells_local $patterns] {
        set info [mptdc_pnr_fast_tag_cell_info $inst]
        if {$info eq ""} { continue }
        set bit [dict get $info bit]
        if {![mptdc_pnr_fast_tag_bit_allowed $bit]} { continue }
        set name [dict get $info name]
        if {[info exists seen($name)]} { continue }
        set seen($name) 1
        lappend records $info
    }
    return $records
}

proc mptdc_pnr_fast_tag_column_side_box {pd_box boxes side width gap} {
    set pd_llx [lindex $pd_box 0]
    set pd_urx [lindex $pd_box 2]
    set pd_lly [lindex $pd_box 1]
    set pd_ury [lindex $pd_box 3]
    set core_llx ""
    set core_urx ""
    if {[dict exists $boxes core]} {
        set core_box [dict get $boxes core]
        set core_llx [lindex $core_box 0]
        set core_urx [lindex $core_box 2]
    }
    set backend_llx ""
    if {[dict exists $boxes backend]} {
        set backend_llx [lindex [dict get $boxes backend] 0]
    }

    if {$side eq "center"} {
        set inner_llx [expr {$pd_llx + $gap}]
        set inner_urx [expr {$pd_urx - $gap}]
        set available [expr {$inner_urx - $inner_llx}]
        if {$available <= 0.0} {
            return [list [mptdc_pnr_snap $pd_llx] $pd_lly [mptdc_pnr_snap $pd_urx] $pd_ury]
        }
        if {$width > $available} {
            set width $available
        }
        set center [expr {($pd_llx + $pd_urx) / 2.0}]
        set llx [expr {$center - ($width / 2.0)}]
        set urx [expr {$center + ($width / 2.0)}]
        if {$llx < $inner_llx} {
            set llx $inner_llx
            set urx [expr {$llx + $width}]
        }
        if {$urx > $inner_urx} {
            set urx $inner_urx
            set llx [expr {$urx - $width}]
        }
        return [list [format %.3f [mptdc_pnr_snap $llx]] $pd_lly [format %.3f [mptdc_pnr_snap $urx]] $pd_ury]
    }

    if {$side eq "west"} {
        set urx [expr {$pd_llx - $gap}]
        set llx [expr {$urx - $width}]
        if {$core_llx ne "" && $llx < $core_llx} {
            set llx [expr {$core_llx + $gap}]
        }
        return [list [mptdc_pnr_snap $llx] $pd_lly [mptdc_pnr_snap $urx] $pd_ury]
    }

    set llx [expr {$pd_urx + $gap}]
    set urx [expr {$llx + $width}]
    if {$backend_llx ne "" && $urx > ($backend_llx - $gap)} {
        set urx [expr {$backend_llx - $gap}]
    }
    if {$core_urx ne "" && $urx > $core_urx} {
        set urx [expr {$core_urx - $gap}]
    }
    return [list [mptdc_pnr_snap $llx] $pd_lly [mptdc_pnr_snap $urx] $pd_ury]
}

proc mptdc_pnr_apply_fast_tag_column_placement {{path ""}} {
    global pnr
    if {$path eq ""} {
        if {[info exists pnr(reports_dir)] && $pnr(reports_dir) ne ""} {
            set path [file join $pnr(reports_dir) fast_tag_column_placement.rpt]
        } else {
            set path [mptdc_pnr_env MPTDC_PNR_FAST_TAG_COLUMN_PLACEMENT_REPORT fast_tag_column_placement.rpt]
        }
    }
    set fh [open $path w]
    puts $fh "# MPTDC Fast-Tag Column Placement"
    puts $fh "FAST_TAG_COLUMN_PLACEMENT_ENABLED=[mptdc_pnr_fast_tags_by_column_enabled]"
    puts $fh "FAST_TAG_COLUMN_BITS=[mptdc_pnr_env MPTDC_PNR_FAST_TAG_COLUMN_BITS ALL]"
    puts $fh "FAST_TAG_COLUMN_RULE=align_gen_fast_tag_col_with_matching_pd_gen_pd_col_band"
    puts $fh "FAST_TAG_TO_PD_TS_FALSE_PATH=NO"
    puts $fh "FAST_TAG_TO_PD_TS_MULTICYCLE=NO"
    if {![mptdc_pnr_fast_tags_by_column_enabled]} {
        puts $fh "FAST_TAG_COLUMN_PLACEMENT_STATUS=SKIPPED"
        close $fh
        return [dict create status SKIPPED report $path constrained 0 preplaced 0 failures 0]
    }

    set boxes [mptdc_pnr_sandwich_boxes]
    if {![dict exists $boxes pd]} {
        puts $fh "FAST_TAG_COLUMN_PLACEMENT_STATUS=REVIEW_REQUIRED"
        puts $fh "FAST_TAG_COLUMN_PLACEMENT_ERROR=no_pd_box"
        close $fh
        return [dict create status REVIEW_REQUIRED report $path constrained 0 preplaced 0 failures 1]
    }
    set pd_box [dict get $boxes pd]
    set side [string tolower [mptdc_pnr_env MPTDC_PNR_FAST_TAG_COLUMN_SIDE east]]
    if {$side ni {east west center}} { set side east }
    set width [mptdc_pnr_env MPTDC_PNR_FAST_TAG_COLUMN_STRIP_WIDTH_UM 32.0]
    set gap [mptdc_pnr_env MPTDC_PNR_FAST_TAG_COLUMN_GAP_UM 2.0]
    set y_margin [mptdc_pnr_env MPTDC_PNR_FAST_TAG_COLUMN_Y_MARGIN_UM 1.0]
    set fix_cells [mptdc_pnr_env_truthy MPTDC_PNR_FAST_TAG_COLUMN_FIX 0]
    set preplace [mptdc_pnr_env_truthy MPTDC_PNR_FAST_TAG_COLUMN_PREPLACE 1]
    set strip_box [mptdc_pnr_fast_tag_column_side_box $pd_box $boxes $side $width $gap]
    set strip_llx [lindex $strip_box 0]
    set strip_urx [lindex $strip_box 2]
    if {$strip_urx <= $strip_llx} {
        puts $fh "FAST_TAG_COLUMN_PLACEMENT_STATUS=REVIEW_REQUIRED"
        puts $fh "FAST_TAG_COLUMN_PLACEMENT_ERROR=invalid_strip_box"
        puts $fh "FAST_TAG_COLUMN_STRIP_BOX=$strip_box"
        close $fh
        return [dict create status REVIEW_REQUIRED report $path constrained 0 preplaced 0 failures 1]
    }

    set records [mptdc_pnr_collect_fast_tag_column_cells]
    set pd_lly [lindex $pd_box 1]
    set pd_ury [lindex $pd_box 3]
    set pitch_y [expr {($pd_ury - $pd_lly) / 8.0}]
    set row_h [mptdc_pnr_env MPTDC_PNR_FAST_TAG_COLUMN_ROW_HEIGHT_UM [mptdc_pnr_env MPTDC_PNR_PD_TILE_ROW_HEIGHT_UM 4.48]]
    set spacing [mptdc_pnr_env MPTDC_PNR_FAST_TAG_COLUMN_MEMBER_SPACING_UM 0.56]
    set constrained 0
    set preplaced_count 0
    set failures 0
    puts $fh "PD_BOX=$pd_box"
    puts $fh "FAST_TAG_COLUMN_SIDE=$side"
    puts $fh "FAST_TAG_COLUMN_STRIP_BOX=$strip_box"
    puts $fh "FAST_TAG_COLUMN_RECORDS=[llength $records]"
    puts $fh "FAST_TAG_COLUMN_PREPLACE=$preplace"
    puts $fh "FAST_TAG_COLUMN_FIX=$fix_cells"

    for {set col 0} {$col < 8} {incr col} {
        set col_records [list]
        foreach info $records {
            if {[dict get $info col] == $col} {
                lappend col_records $info
            }
        }
        set band_lly [mptdc_pnr_snap [expr {$pd_lly + ($col * $pitch_y) + $y_margin}]]
        set band_ury [mptdc_pnr_snap [expr {$pd_lly + (($col + 1) * $pitch_y) - $y_margin}]]
        set band_box [list $strip_llx $band_lly $strip_urx $band_ury]
        puts $fh "COLUMN $col count=[llength $col_records] band_box=$band_box"
        set x [mptdc_pnr_snap [expr {$strip_llx + $spacing}]]
        set y [mptdc_pnr_snap [expr {$band_lly + max(0.0, (($band_ury - $band_lly) - $row_h) / 2.0)}]]
        foreach info [lsort -dictionary -index 2 $col_records] {
            set inst [dict get $info name]
            set size [mptdc_osc_pd_member_size $inst]
            set cell_w [lindex $size 0]
            if {$cell_w <= 0.0} { set cell_w 1.12 }
            if {($x + $cell_w) > ($strip_urx - $spacing)} {
                set x [mptdc_pnr_snap [expr {$strip_llx + $spacing}]]
                set y [mptdc_pnr_snap [expr {$y + $row_h}]]
            }
            if {[catch {setObjFPlanBox Instance $inst $strip_llx $band_lly $strip_urx $band_ury} err_box]} {
                incr failures
                puts $fh "  constraint_fail inst=$inst error=$err_box"
            } else {
                incr constrained
            }
            if {$preplace} {
                set cmd [list placeInstance $inst $x $y R0]
                if {$fix_cells} { lappend cmd -fixed }
                if {[catch {eval $cmd} err_place]} {
                    incr failures
                    puts $fh "  preplace_fail inst=$inst x=$x y=$y error=$err_place"
                } else {
                    incr preplaced_count
                }
            }
            puts $fh "  inst=$inst bit=[dict get $info bit] x=$x y=$y"
            set x [mptdc_pnr_snap [expr {$x + $cell_w + $spacing}]]
        }
    }

    set status PASS
    if {$failures > 0 || [llength $records] == 0} {
        set status REVIEW_REQUIRED
    }
    puts $fh "FAST_TAG_COLUMN_CONSTRAINTS=$constrained"
    puts $fh "FAST_TAG_COLUMN_PREPLACEMENTS=$preplaced_count"
    puts $fh "FAST_TAG_COLUMN_FAILURES=$failures"
    puts $fh "FAST_TAG_COLUMN_PLACEMENT_STATUS=$status"
    close $fh
    return [dict create status $status report $path constrained $constrained preplaced $preplaced_count failures $failures]
}

proc mptdc_pnr_apply_pd_grid_placement {} {
    if {![mptdc_pnr_pd_grid_enabled]} {
        return 0
    }
    if {[llength [info commands mptdc_osc_pd_apply_pd_matrix_floorplan]] == 0} {
        error "MPTDC_PNR_PD_GRID_FATAL: missing PD matrix helper"
    }
    return [mptdc_osc_pd_apply_pd_matrix_floorplan]
}
