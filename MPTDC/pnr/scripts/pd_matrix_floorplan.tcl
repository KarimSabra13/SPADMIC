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
    foreach cell [lsort $cells] {
        set ns ""
        set nf ""
        if {![mptdc_osc_pd_parse_ns_nf $cell ns nf]} {
            puts $fh "SKIP unparsable cell: $cell"
            continue
        }
        set x [mptdc_pnr_snap [expr {$llx + ($ns + 0.5) * $pitch_x}]]
        set y [mptdc_pnr_snap [expr {$lly + ($nf + 0.5) * $pitch_y}]]
        puts $fh "CELL $cell ns=$ns nf=$nf target=($x,$y)"
        foreach cmd [list \
            [list placeInstance $cell $x $y R0] \
            [list setObjFPlanBox Instance $cell $x $y [expr {$x + 1.0}] [expr {$y + 1.0}]] \
        ] {
            if {![catch {uplevel 1 $cmd} err]} {
                puts $fh "  applied: $cmd"
                incr placed
                break
            } else {
                puts $fh "  skipped: $cmd"
                puts $fh "    $err"
            }
        }
    }

    puts $fh ""
    puts $fh "Place/fence attempts accepted: $placed"
    puts $fh "If accepted count is 0, the synthesized PD hierarchy is not a hard placeable master yet; use the generated symmetry CSV and regions as the enforceable provisional check."
    close $fh
}
