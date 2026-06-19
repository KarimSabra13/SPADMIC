# =============================================================================
# O0 oscillator/PD provisional regions
# =============================================================================

proc mptdc_osc_pd_result_dir {} {
    global pnr
    if {[info exists pnr(osc_pd_result_dir)] && $pnr(osc_pd_result_dir) ne ""} {
        file mkdir $pnr(osc_pd_result_dir)
        return $pnr(osc_pd_result_dir)
    }
    file mkdir "$pnr(reports_dir)/osc_pd"
    return "$pnr(reports_dir)/osc_pd"
}

proc mptdc_osc_pd_timestamp {} {
    return [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]
}

proc mptdc_osc_pd_object_names {objects} {
    set names [list]
    if {[llength $objects] == 0} {
        return $names
    }
    if {![catch {get_object_name $objects} obj_names] && $obj_names ne ""} {
        foreach name $obj_names {
            if {$name ne "" && [lsearch -exact $names $name] < 0} {
                lappend names $name
            }
        }
        if {[llength $names] > 0} { return $names }
    }
    if {![catch {get_db $objects .name} obj_names] && $obj_names ne ""} {
        foreach name $obj_names {
            if {$name ne "" && [lsearch -exact $names $name] < 0} {
                lappend names $name
            }
        }
        if {[llength $names] > 0} { return $names }
    }
    foreach obj $objects {
        set name ""
        catch {set name [get_object_name $obj]}
        if {$name eq ""} { catch {set name [get_db $obj .name]} }
        if {$name eq ""} { set name "$obj" }
        if {[lsearch -exact $names $name] < 0} {
            lappend names $name
        }
    }
    return $names
}

proc mptdc_osc_pd_cells {patterns} {
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
        foreach cell [mptdc_osc_pd_object_names $cells] {
            if {[lsearch -exact $out $cell] < 0} {
                lappend out $cell
            }
        }
    }
    return $out
}

proc mptdc_osc_pd_create_blockage {name box fh} {
    if {![mptdc_pnr_box_valid $box]} {
        puts $fh "BLOCKAGE $name: skipped invalid box $box"
        return
    }
    set llx [lindex $box 0]
    set lly [lindex $box 1]
    set urx [lindex $box 2]
    set ury [lindex $box 3]
    foreach cmd [list \
        [list createPlaceBlockage -name $name -type hard -box $llx $lly $urx $ury] \
        [list createPlaceBlockage -type hard -box [list $llx $lly $urx $ury]] \
    ] {
        if {![catch {uplevel 1 $cmd} err]} {
            puts $fh "BLOCKAGE $name: applied $cmd"
            return
        }
        puts $fh "BLOCKAGE $name: skipped $cmd"
        puts $fh "  $err"
    }
}

proc mptdc_osc_pd_apply_regions {} {
    global pnr
    set out_dir [mptdc_osc_pd_result_dir]
    set rpt "$out_dir/floorplan_summary.rpt"
    set fh [open $rpt w]
    puts $fh "MPTDC O0 oscillator/PD floorplan summary"
    puts $fh "========================================"
    puts $fh "Generated: [mptdc_osc_pd_timestamp]"
    puts $fh "Status: PROVISIONAL - NOT ANALOG VERIFIED"
    puts $fh ""

    set slow_cells [mptdc_osc_pd_cells [list *u_osc_slow*]]
    set fast_cells [mptdc_osc_pd_cells [list *u_osc_fast*]]
    set pd_cells   [mptdc_osc_pd_cells [list *gen_pd_row*gen_pd_col*u_pd*]]
    set bridge     [mptdc_osc_pd_cells [list *u_hit_capture_bridge*]]
    set meas_ctrl  [mptdc_osc_pd_cells [list *u_meas_ctrl*]]
    set ctx_bank   [mptdc_osc_pd_cells [list *u_ctx_bank*]]
    set drain_ctrl [mptdc_osc_pd_cells [list *u_drain_ctrl*]]
    set fifo       [mptdc_osc_pd_cells [list *u_fifo*]]

    puts $fh "Object discovery"
    puts $fh "----------------"
    puts $fh "u_osc_slow matches: [llength $slow_cells]"
    foreach c $slow_cells { puts $fh "  $c" }
    puts $fh "u_osc_fast matches: [llength $fast_cells]"
    foreach c $fast_cells { puts $fh "  $c" }
    puts $fh "PD cells: [llength $pd_cells] (expected 64)"
    puts $fh "hit_capture_bridge matches: [llength $bridge]"
    puts $fh "meas_ctrl matches: [llength $meas_ctrl]"
    puts $fh "context_bank matches: [llength $ctx_bank]"
    puts $fh "drain_ctrl matches: [llength $drain_ctrl]"
    puts $fh "FIFO matches: [llength $fifo]"
    puts $fh ""

    set boxes [mptdc_pnr_sandwich_boxes]
    if {![dict exists $boxes pd]} {
        puts $fh "FATAL: could not derive sandwich boxes from current core floorplan"
        close $fh
        error "O0 floorplan failed: no sandwich boxes"
    }
    set core_box [dict get $boxes core]
    set slow_box [dict get $boxes slow]
    set pd_box   [dict get $boxes pd]
    set fast_box [dict get $boxes fast]

    set core_llx [lindex $core_box 0]
    set core_lly [lindex $core_box 1]
    set core_urx [lindex $core_box 2]
    set core_ury [lindex $core_box 3]
    set pd_urx [lindex $pd_box 2]
    set backend_box [list \
        [mptdc_pnr_snap [expr {$pd_urx + 20.0}]] \
        $core_lly \
        $core_urx \
        $core_ury]
    set phase_left_box [list $core_llx [lindex $fast_box 3] [lindex $pd_box 0] [lindex $slow_box 1]]

    puts $fh "Assigned boxes"
    puts $fh "--------------"
    puts $fh "core:          $core_box"
    puts $fh "slow reserve:  $slow_box"
    puts $fh "PD matrix:     $pd_box"
    puts $fh "fast reserve:  $fast_box"
    puts $fh "backend island:$backend_box"
    puts $fh "left phase channel: $phase_left_box"
    puts $fh ""

    mptdc_osc_pd_create_blockage mptdc_o0_slow_osc_macro_keepout $slow_box $fh
    mptdc_osc_pd_create_blockage mptdc_o0_fast_osc_macro_keepout $fast_box $fh
    if {[mptdc_pnr_box_valid $phase_left_box]} {
        mptdc_osc_pd_create_blockage mptdc_o0_phase_left_channel_no_stdcell $phase_left_box $fh
    }

    foreach item [list \
        [list mptdc_o0_backend_island $backend_box [concat $bridge $meas_ctrl $ctx_bank $drain_ctrl $fifo]] \
        [list mptdc_o0_pd_matrix $pd_box $pd_cells] \
    ] {
        set group [lindex $item 0]
        set box [lindex $item 1]
        set cells [lindex $item 2]
        if {[catch {createInstGroup $group} err]} {
            puts $fh "GROUP $group create warning: $err"
        }
        foreach cell $cells {
            catch {addInstToInstGroup $group $cell}
        }
        if {[mptdc_pnr_box_valid $box]} {
            set llx [lindex $box 0]
            set lly [lindex $box 1]
            set urx [lindex $box 2]
            set ury [lindex $box 3]
            if {[catch {createRegion $group $llx $lly $urx $ury} err]} {
                puts $fh "REGION $group warning: $err"
            } else {
                puts $fh "REGION $group: $box"
            }
        }
    }

    puts $fh ""
    if {[llength $pd_cells] != 64} {
        puts $fh "RED STATUS: PD cell count is not 64. Floorplan is not valid for signoff."
    } else {
        puts $fh "PD count check: PASS"
    }
    puts $fh "Note: current RTL uses mptdc_osc_stub hierarchy. The slow/fast macro boxes are reserved regions until a hard macro binding is approved."
    close $fh

    set mfh [open "$out_dir/macro_placement.rpt" w]
    puts $mfh "MPTDC O0 provisional macro placement"
    puts $mfh "===================================="
    puts $mfh "Generated: [mptdc_osc_pd_timestamp]"
    puts $mfh "Status: PROVISIONAL - RTL hard macro binding is not yet active"
    puts $mfh "slow reserve box: $slow_box"
    puts $mfh "fast reserve box: $fast_box"
    puts $mfh "slow hierarchy matches: [llength $slow_cells]"
    foreach c $slow_cells { puts $mfh "  $c" }
    puts $mfh "fast hierarchy matches: [llength $fast_cells]"
    foreach c $fast_cells { puts $mfh "  $c" }
    puts $mfh ""
    puts $mfh "Required next step: bind u_osc_slow/u_osc_fast to real hard macros or analog-approved blackbox wrappers before claiming macro placement signoff."
    close $mfh

    if {[llength $pd_cells] != 64} {
        error "O0 floorplan failed: expected 64 PD cells, found [llength $pd_cells]"
    }
}
