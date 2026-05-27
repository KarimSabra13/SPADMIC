# =============================================================================
# O0 PD instance placement report
# =============================================================================

proc mptdc_osc_pd_inst_attr {inst attr} {
    set obj [get_cells -quiet $inst]
    if {[llength $obj] == 0} {
        catch {set obj [get_cells -quiet -hierarchical $inst]}
    }
    if {[llength $obj] == 0} {
        return ""
    }
    if {![catch {set val [get_db $obj $attr]}]} {
        return $val
    }
    return ""
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
    puts $fh "instance,ns,nf,x_um,y_um,orientation,width_um,height_um,master,parent,placement_status,row,col,expected_x_um,expected_y_um,dx_um,dy_um"
    foreach cell [lsort $cells] {
        set ns ""
        set nf ""
        mptdc_osc_pd_parse_ns_nf $cell ns nf
        set loc [mptdc_osc_pd_inst_attr $cell .location]
        set x ""
        set y ""
        if {[llength $loc] >= 2} {
            set x [lindex $loc 0]
            set y [lindex $loc 1]
        }
        set orient [mptdc_osc_pd_inst_attr $cell .orient]
        set master [mptdc_osc_pd_inst_attr $cell .base_cell.name]
        set status [mptdc_osc_pd_inst_attr $cell .place_status]
        set bbox [mptdc_osc_pd_inst_attr $cell .bbox]
        set width ""
        set height ""
        if {[llength $bbox] >= 4} {
            set width [expr {[lindex $bbox 2] - [lindex $bbox 0]}]
            set height [expr {[lindex $bbox 3] - [lindex $bbox 1]}]
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
            }
        }
        puts $fh "$cell,$ns,$nf,$x,$y,$orient,$width,$height,$master,u_core,$status,$nf,$ns,$exp_x,$exp_y,$dx,$dy"
    }
    close $fh

    set sfh [open $summary w]
    puts $sfh "# PD Instance Symmetry Summary"
    puts $sfh ""
    puts $sfh "- Status: PROVISIONAL_REVIEW_REQUIRED"
    puts $sfh "- Cells found: [llength $cells]"
    puts $sfh "- Expected cells: 64"
    puts $sfh "- CSV: pd_instance_placement.csv"
    puts $sfh ""
    if {[llength $cells] != 64} {
        puts $sfh "RED STATUS: expected 64 PD cells."
    } else {
        puts $sfh "Count check: PASS"
    }
    puts $sfh ""
    puts $sfh "Run tools/timing/analyze_pd_instance_symmetry.py for duplicate/missing/offset details."
    close $sfh
}
