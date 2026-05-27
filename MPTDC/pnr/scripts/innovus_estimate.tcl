# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : innovus_estimate.tcl
# Purpose  : First-pass Innovus floorplan/place estimate for area/timing/power
# =============================================================================
#
# Usage:
#   cd MPTDC/pnr/scripts
#   innovus -nowin -init innovus_estimate.tcl -log ../logs/innovus_estimate.log
#
# This is an estimation flow, not a signoff PnR recipe. It starts from the
# Genus post-synthesis netlist/SDC, uses the same XH018 1P4M collateral, keeps
# signal routing on MET1-MET3 globally, and reserves METTP for VDD/VSS/top-level
# power except for the localized PD-matrix phase-mesh exception.
# =============================================================================

proc mptdc_pnr_msg {msg} {
    puts "MPTDC_PNR: $msg"
}

proc mptdc_pnr_required {label body} {
    mptdc_pnr_msg $label
    if {[catch {uplevel 1 $body} err]} {
        puts "MPTDC_PNR_ERROR: $label failed"
        puts $err
        exit 1
    }
}

proc mptdc_pnr_optional {label body} {
    mptdc_pnr_msg $label
    if {[catch {uplevel 1 $body} err]} {
        puts "MPTDC_PNR_WARN: $label skipped: $err"
    }
}

proc mptdc_pnr_capture_report {report_file title body} {
    if {[catch {uplevel 1 "$body > \"$report_file\""} err]} {
        set fh [open $report_file w]
        puts $fh "$title"
        puts $fh [string repeat "=" [string length $title]]
        puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
        puts $fh ""
        puts $fh "FAILED:"
        puts $fh $err
        close $fh
        puts "MPTDC_PNR_WARN: $title failed: $err"
    }
}

proc mptdc_pnr_capture_report_candidates {report_file title bodies} {
    set errors [list]
    foreach body $bodies {
        if {![catch {uplevel 1 "$body > \"$report_file\""} err]} {
            return
        }
        lappend errors "$body: $err"
    }

    set fh [open $report_file w]
    puts $fh "$title"
    puts $fh [string repeat "=" [string length $title]]
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    puts $fh "FAILED:"
    puts $fh [join $errors "\n\n"]
    close $fh
    puts "MPTDC_PNR_WARN: $title failed for all command variants"
}

proc mptdc_pnr_generate_extra_reports {} {
    global pnr design

    set extra_dir "$pnr(reports_dir)/prects"
    file mkdir $extra_dir

    mptdc_pnr_capture_report "$extra_dir/extra_check_place.rpt" \
        "MPTDC extra checkPlace" {checkPlace}
    mptdc_pnr_capture_report "$extra_dir/extra_check_design_all.rpt" \
        "MPTDC extra checkDesign -all" {checkDesign -all}
    mptdc_pnr_capture_report "$extra_dir/extra_report_timing_100.rpt" \
        "MPTDC extra report_timing max_paths 100" {report_timing -max_paths 100}
    mptdc_pnr_capture_report "$extra_dir/extra_report_timing_full_clock.rpt" \
        "MPTDC extra report_timing full_clock" {report_timing -max_paths 50 -path_type full_clock}
    mptdc_pnr_capture_report "$extra_dir/extra_report_constraint.rpt" \
        "MPTDC extra report_constraint all violators" {report_constraint -all_violators}
    mptdc_pnr_capture_report_candidates "$extra_dir/extra_report_congestion.rpt" \
        "MPTDC extra reportCongestion" [list \
            {reportCongestion -hotSpot -num_hotspot 100 -overflow} \
            {reportCongestion -hotSpot -num_hotspot 100} \
            {reportCongestion -overflow} \
            {reportCongestion} \
        ]
    mptdc_pnr_capture_report_candidates "$extra_dir/extra_report_congestion_full.rpt" \
        "MPTDC extra congestion with blockage" [list \
            {reportCongestion -includeBlockage -overflow} \
            {reportCongestion -3d -overflow} \
            {reportCongestion -overflow} \
            {reportCongestion} \
        ]
    mptdc_pnr_capture_report "$extra_dir/extra_report_density.rpt" \
        "MPTDC extra reportDensity" {reportDensity}
    mptdc_pnr_capture_report "$extra_dir/extra_report_netlist_stats.rpt" \
        "MPTDC extra reportGateCount" {reportGateCount -level 20}
    mptdc_pnr_capture_report "$extra_dir/extra_report_power_hier.rpt" \
        "MPTDC extra report_power hierarchy" {report_power -hierarchy all}
    mptdc_pnr_capture_report_candidates "$extra_dir/extra_report_power_verbose.rpt" \
        "MPTDC extra power summary" [list \
            {report_power -hierarchy all} \
            {report_power} \
        ]
    mptdc_pnr_capture_report_candidates "$extra_dir/extra_report_clocks.rpt" \
        "MPTDC extra clock report" [list \
            {reportClockTree -summary} \
            {report_clock_tree -summary} \
            {report_clocks} \
        ]
    mptdc_pnr_capture_report_candidates "$extra_dir/extra_report_net_fanout.rpt" \
        "MPTDC extra high fanout report" [list \
            {reportNetStat -fanout 50} \
            {reportHighFanoutNet -threshold 50} \
            {reportFanoutViolation} \
        ]

    set audit_file "$extra_dir/extra_pd_reset_audit.rpt"
    set fh [open $audit_file w]
    puts $fh "MPTDC extra PD/reset audit"
    puts $fh "=========================="
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    set patterns $pnr(pd_instance_patterns)
    foreach pattern $patterns {
        set cells [mptdc_pnr_collect_cells [list $pattern]]
        puts $fh "Pattern $pattern matched [llength $cells] cells"
        foreach cell $cells {
            puts $fh "  $cell"
        }
        puts $fh ""
    }
    set rst_cells [mptdc_pnr_collect_cells [list "*u_rst*sync*"]]
    puts $fh "Reset sync cells matched [llength $rst_cells]"
    foreach cell $rst_cells {
        puts $fh "  $cell"
    }
    close $fh

    mptdc_pnr_write_phase_mesh_audit "$extra_dir/extra_phase_mesh_audit.rpt"
    mptdc_pnr_write_cdc_floorplan_audit "$extra_dir/extra_cdc_floorplan_audit.rpt"
}

proc mptdc_pnr_object_names {objects} {
    set names [list]

    if {[llength $objects] == 0} {
        return $names
    }

    if {![catch {get_object_name $objects} obj_names]} {
        foreach name $obj_names {
            lappend names $name
        }
        return $names
    }

    if {![catch {get_db $objects .name} obj_names]} {
        foreach name $obj_names {
            lappend names $name
        }
        return $names
    }

    foreach obj $objects {
        lappend names $obj
    }
    return $names
}

proc mptdc_pnr_collect_cells {patterns} {
    set matches [list]
    foreach pattern $patterns {
        set cells [list]
        if {[catch {get_cells -hierarchical -quiet $pattern} cells]} {
            if {[catch {get_cells -hier $pattern} cells]} {
                set cells [list]
            }
        }
        foreach cell [mptdc_pnr_object_names $cells] {
            if {[lsearch -exact $matches $cell] < 0} {
                lappend matches $cell
            }
        }
    }
    return $matches
}

proc mptdc_pnr_core_box {} {
    set core_box [list]
    if {[catch {dbGet top.fPlan.coreBox} core_box]} {
        if {[catch {dbGet top.fPlan.box} core_box]} {
            return [list]
        }
    }
    if {[llength $core_box] == 1} {
        set core_box [lindex $core_box 0]
    }
    return $core_box
}

proc mptdc_pnr_snap {value} {
    global pnr
    set snap $pnr(floorplan_snap_um)
    if {$snap <= 0.0} {
        return $value
    }
    return [expr {round($value / $snap) * $snap}]
}

proc mptdc_pnr_centered_box {core_box width height y_center} {
    set llx [expr {([lindex $core_box 0] + [lindex $core_box 2] - $width) / 2.0}]
    set lly [expr {$y_center - ($height / 2.0)}]
    set urx [expr {$llx + $width}]
    set ury [expr {$lly + $height}]

    return [list \
        [mptdc_pnr_snap $llx] \
        [mptdc_pnr_snap $lly] \
        [mptdc_pnr_snap $urx] \
        [mptdc_pnr_snap $ury]]
}

proc mptdc_pnr_box_valid {box} {
    if {[llength $box] < 4} {
        return 0
    }
    return [expr {([lindex $box 2] > [lindex $box 0]) && ([lindex $box 3] > [lindex $box 1])}]
}

proc mptdc_pnr_sandwich_boxes {} {
    global pnr

    set core_box [mptdc_pnr_core_box]
    if {![mptdc_pnr_box_valid $core_box]} {
        return [dict create]
    }

    set core_lly [lindex $core_box 1]
    set core_ury [lindex $core_box 3]
    set core_h   [expr {$core_ury - $core_lly}]
    set center_y [expr {($core_lly + $core_ury) / 2.0}]

    set osc_halo_h [expr {$pnr(osc_macro_height_um) + (2.0 * $pnr(osc_macro_halo_um))}]
    set stack_h [expr {$osc_halo_h + $pnr(pd_region_gap_um) + $pnr(pd_region_height_um) + $pnr(pd_region_gap_um) + $osc_halo_h}]
    if {$stack_h > $core_h} {
        set scale [expr {$core_h / $stack_h}]
        set pd_h [expr {max(10.0, $pnr(pd_region_height_um) * $scale)}]
        set gap  [expr {max(2.0, $pnr(pd_region_gap_um) * $scale)}]
        set osc_halo_h [expr {max($pnr(osc_macro_height_um), $osc_halo_h * $scale)}]
    } else {
        set pd_h $pnr(pd_region_height_um)
        set gap  $pnr(pd_region_gap_um)
    }

    set pd_box [mptdc_pnr_centered_box \
        $core_box $pnr(pd_region_width_um) $pd_h $center_y]
    set slow_center_y [expr {[lindex $pd_box 3] + $gap + ($osc_halo_h / 2.0)}]
    set fast_center_y [expr {[lindex $pd_box 1] - $gap - ($osc_halo_h / 2.0)}]
    set osc_w [expr {$pnr(osc_macro_width_um) + (2.0 * $pnr(osc_macro_halo_um))}]
    set slow_box [mptdc_pnr_centered_box $core_box $osc_w $osc_halo_h $slow_center_y]
    set fast_box [mptdc_pnr_centered_box $core_box $osc_w $osc_halo_h $fast_center_y]

    return [dict create core $core_box pd $pd_box slow $slow_box fast $fast_box]
}

proc mptdc_pnr_create_place_blockage {name box} {
    if {![mptdc_pnr_box_valid $box]} {
        return
    }

    set llx [lindex $box 0]
    set lly [lindex $box 1]
    set urx [lindex $box 2]
    set ury [lindex $box 3]

    if {[catch {createPlaceBlockage -name $name -type hard -box $llx $lly $urx $ury} err]} {
        if {[catch {createPlaceBlockage -type hard -box [list $llx $lly $urx $ury]} err2]} {
            error "$err; fallback failed: $err2"
        }
    }
}

proc mptdc_pnr_phase_net_patterns {} {
    set patterns [list]
    for {set i 0} {$i < 8} {incr i} {
        lappend patterns "*slow_phase\\[$i\\]*"
        lappend patterns "*fast_phase\\[$i\\]*"
        lappend patterns "*u_osc_slow*phase\\[$i\\]*"
        lappend patterns "*u_osc_fast*phase\\[$i\\]*"
    }
    return $patterns
}

proc mptdc_pnr_collect_nets {patterns} {
    set matches [list]
    foreach pattern $patterns {
        set nets [list]
        if {[catch {get_nets -hierarchical -quiet $pattern} nets]} {
            if {[catch {get_nets -hier $pattern} nets]} {
                set nets [list]
            }
        }
        foreach net [mptdc_pnr_object_names $nets] {
            if {[lsearch -exact $matches $net] < 0} {
                lappend matches $net
            }
        }
    }
    return $matches
}

proc mptdc_pnr_write_phase_mesh_audit {report_file} {
    global pnr

    set fh [open $report_file w]
    puts $fh "MPTDC phase mesh audit"
    puts $fh "======================"
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    puts $fh "Policy"
    puts $fh "------"
    puts $fh "Global signal routing remains $pnr(signal_bottom_layer)-$pnr(signal_top_layer)."
    puts $fh "Localized PD-matrix exception enabled: $pnr(phase_exception_enable)"
    puts $fh "Exception top layer: $pnr(phase_route_top_layer) (index $pnr(phase_route_top_layer_idx))"
    puts $fh "Exception scope: 8 slow + 8 fast phase nets inside/over $pnr(pd_symmetry_group)."
    puts $fh ""

    set patterns [mptdc_pnr_phase_net_patterns]
    set nets [mptdc_pnr_collect_nets $patterns]
    puts $fh "Matched phase-like nets: [llength $nets]"
    foreach net [lsort $nets] {
        puts $fh "  $net"
    }
    puts $fh ""
    puts $fh "Reviewer checklist"
    puts $fh "------------------"
    puts $fh "  [ ] Exactly the intended slow/fast phase nets use the METTP exception."
    puts $fh "  [ ] PDN straps avoid consuming all METTP resources over the matrix center."
    puts $fh "  [ ] Extracted per-phase RC deltas are reviewed after detail route/QRC."
    close $fh
}

proc mptdc_pnr_apply_phase_mesh_route_intent {} {
    global pnr

    set report_file "$pnr(reports_dir)/phase_mesh_route_intent.rpt"
    set fh [open $report_file w]
    puts $fh "MPTDC phase mesh route intent"
    puts $fh "============================"
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    puts $fh "Intent: keep global routing on $pnr(signal_bottom_layer)-$pnr(signal_top_layer),"
    puts $fh "but mark phase-like nets as candidates for localized $pnr(phase_route_top_layer)"
    puts $fh "routing/shielding over $pnr(pd_symmetry_group)."
    puts $fh ""

    if {!$pnr(phase_exception_enable)} {
        puts $fh "Phase exception disabled; no route intent applied."
        close $fh
        return
    }

    set nets [mptdc_pnr_collect_nets [mptdc_pnr_phase_net_patterns]]
    puts $fh "Matched phase-like nets: [llength $nets]"
    foreach net [lsort $nets] {
        puts $fh "Net: $net"
        set objs [list]
        catch {set objs [get_nets -quiet $net]}
        if {[llength $objs] == 0} {
            puts $fh "  No Innovus net object found for this name."
            continue
        }
        set applied 0
        foreach cmd [list \
            [list set_db $objs .top_preferred_routing_layer $pnr(phase_route_top_layer)] \
            [list set_db $objs .route_top_layer $pnr(phase_route_top_layer)] \
            [list setAttribute -net $net -top_preferred_routing_layer $pnr(phase_route_top_layer)] \
        ] {
            if {![catch {{*}$cmd} err]} {
                puts $fh "  Applied: $cmd"
                set applied 1
            } else {
                puts $fh "  Skipped: $cmd"
                puts $fh "    $err"
            }
        }
        if {!$applied} {
            puts $fh "  No route-attribute variant accepted; enforce/review manually before detail route."
        }
    }

    puts $fh ""
    puts $fh "PDN accommodation note"
    puts $fh "----------------------"
    puts $fh "Do not consume the entire METTP resource over the center matrix with PDN straps."
    puts $fh "If a later script adds sroute/ring/stripe generation, reserve channels for these"
    puts $fh "phase-like nets before final detail routing and extracted-RC matching."
    close $fh
}

proc mptdc_pnr_write_cdc_floorplan_audit {report_file} {
    set fh [open $report_file w]
    puts $fh "MPTDC CDC/floorplan audit"
    puts $fh "========================="
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""

    foreach item {
        {"Reset synchronizers" "*u_rst*sync*"}
        {"Gray counter synchronizers" "*gray*ff* *u_slow_cnt* *u_fast_cnt*"}
        {"Context drain synchronizers" "*ctx_drain_sync_ff*"}
        {"Rejected START event latch" "*start_rejected_pending* *rejected_sync_pipe*"}
        {"Measurement controller" "*u_meas_ctrl*"}
        {"Hit capture bridge" "*u_hit_capture_bridge*"}
        {"Context bank" "*u_ctx_bank*"}
        {"PD matrix cells" "*gen_pd_row*gen_pd_col*u_pd*"}
    } {
        set title [lindex $item 0]
        set patterns [lrange $item 1 end]
        puts $fh $title
        puts $fh [string repeat "-" [string length $title]]
        foreach pattern $patterns {
            set cells [mptdc_pnr_collect_cells [split $pattern]]
            puts $fh "Pattern $pattern matched [llength $cells] cells"
            foreach cell [lsort $cells] {
                puts $fh "  $cell"
            }
        }
        puts $fh ""
    }

    puts $fh "Reviewer checklist"
    puts $fh "------------------"
    puts $fh "  [ ] u_meas_ctrl and u_ctx_bank are clk_sys logic and are not timed as oscillator-domain logic."
    puts $fh "  [ ] u_hit_capture_bridge sits between PD/counter fabric and sys-domain context bank."
    puts $fh "  [ ] rejected START pending latch and synchronizer remain recognizable for exact overflow accounting."
    puts $fh "  [ ] context-bank capture registers are sys-domain and not scattered across the full macro."
    puts $fh "  [ ] synchronizer cells remain recognizable and were not merged/retimed."
    close $fh
}

proc mptdc_pnr_configure_vectorless_activity {} {
    global pnr

    if {!$pnr(vectorless_activity_enable)} {
        mptdc_pnr_msg "Vectorless activity setup disabled"
        return
    }

    mptdc_pnr_msg "Configuring vectorless activity: toggle=$pnr(vectorless_toggle_rate), static_probability=$pnr(vectorless_static_probability)"

    set activity_cmds [list \
        "set_default_switching_activity -input_activity $pnr(vectorless_toggle_rate) -seq_activity $pnr(vectorless_toggle_rate) -duty $pnr(vectorless_static_probability)" \
        "set_default_switching_activity -input_activity $pnr(vectorless_toggle_rate) -seq_activity $pnr(vectorless_toggle_rate)" \
        "set_default_switching_activity -global_activity $pnr(vectorless_toggle_rate) -duty $pnr(vectorless_static_probability)" \
        "set_default_switching_activity -global_activity $pnr(vectorless_toggle_rate)" \
    ]
    set applied 0
    foreach cmd $activity_cmds {
        if {![catch {eval $cmd} err]} {
            set applied 1
            break
        }
    }
    if {!$applied} {
        mptdc_pnr_msg "No set_default_switching_activity variant was accepted"
    }

    if {[catch {propagate_activity} err]} {
        mptdc_pnr_msg "propagate_activity skipped: $err"
    }
}

proc mptdc_pnr_insert_pd_decap {} {
    global pnr tech

    set report_file "$pnr(reports_dir)/pd_matrix_decap.rpt"
    set fh [open $report_file w]
    puts $fh "MPTDC PD matrix decap insertion"
    puts $fh "=============================="
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""

    if {![info exists tech(PD_DECAP)] || $tech(PD_DECAP) eq ""} {
        puts $fh "Status: skipped; tech(PD_DECAP) is not set."
        close $fh
        return
    }

    set boxes [mptdc_pnr_sandwich_boxes]
    if {![dict exists $boxes pd]} {
        puts $fh "Status: skipped; unable to derive PD region box."
        close $fh
        return
    }

    set pd_box [dict get $boxes pd]
    if {![mptdc_pnr_box_valid $pd_box]} {
        puts $fh "Status: skipped; invalid PD region box: $pd_box"
        close $fh
        return
    }

    set llx [lindex $pd_box 0]
    set lly [lindex $pd_box 1]
    set urx [lindex $pd_box 2]
    set ury [lindex $pd_box 3]

    puts $fh "PD region box: $pd_box"
    puts $fh "Decap cells: $tech(PD_DECAP)"
    puts $fh ""

    set applied 0
    foreach cmd [list \
        [list addFiller -cell $tech(PD_DECAP) -prefix MPTDC_PD_DECAP -area [list $llx $lly $urx $ury]] \
        [list addFiller -cell $tech(PD_DECAP) -prefix MPTDC_PD_DECAP -box  [list $llx $lly $urx $ury]] \
        [list addFiller -cell $tech(PD_DECAP) -prefix MPTDC_PD_DECAP] \
    ] {
        if {![catch {uplevel 1 $cmd} err]} {
            puts $fh "Applied: $cmd"
            set applied 1
            break
        }
        puts $fh "Skipped: $cmd"
        puts $fh "  $err"
    }

    if {!$applied} {
        puts $fh ""
        puts $fh "Status: no addFiller variant accepted; insert PD-bound decap manually before final route."
    }

    close $fh
}

proc mptdc_pnr_prepare_pd_symmetry {} {
    global pnr

    set report_file "$pnr(reports_dir)/pd_matrix_symmetry.rpt"
    set cells [mptdc_pnr_collect_cells $pnr(pd_instance_patterns)]
    set fh [open $report_file w]
    puts $fh "MPTDC phase-detector matrix symmetry prep"
    puts $fh "========================================"
    puts $fh "Rows x cols target: $pnr(pd_rows) x $pnr(pd_cols)"
    puts $fh "Instance patterns: $pnr(pd_instance_patterns)"
    puts $fh "Matched instances found: [llength $cells]"
    foreach cell $cells {
        puts $fh "  $cell"
    }

    if {[llength $cells] == 0} {
        puts $fh "Status: no PD instances matched after synthesis; no group/region created."
        close $fh
        return
    }

    if {$pnr(pd_symmetry_create_group)} {
        if {[catch {createInstGroup $pnr(pd_symmetry_group)} err]} {
            puts $fh "Group create warning: $err"
        } else {
            puts $fh "Group created: $pnr(pd_symmetry_group)"
        }
        foreach cell $cells {
            if {[catch {addInstToInstGroup $pnr(pd_symmetry_group) $cell} err]} {
                puts $fh "Group add warning for $cell: $err"
            }
        }
    }

    if {$pnr(pd_symmetry_create_region)} {
        set core_box [mptdc_pnr_core_box]
        set boxes [mptdc_pnr_sandwich_boxes]
        puts $fh "Core box: $core_box"
        puts $fh "Sandwich floorplan target"
        puts $fh "  Slow oscillator north macro estimate: $pnr(osc_macro_width_um) x $pnr(osc_macro_height_um) um"
        puts $fh "  Fast oscillator south macro estimate: $pnr(osc_macro_width_um) x $pnr(osc_macro_height_um) um"
        puts $fh "  Oscillator halo um: $pnr(osc_macro_halo_um)"
        puts $fh "  PD region target width x height: $pnr(pd_region_width_um) x $pnr(pd_region_height_um) um"
        puts $fh "  PD/oscillator gap um: $pnr(pd_region_gap_um)"
        if {[dict exists $boxes pd]} {
            set pd_box [dict get $boxes pd]
            set slow_box [dict get $boxes slow]
            set fast_box [dict get $boxes fast]
            puts $fh "  Slow reserve box: $slow_box"
            puts $fh "  PD matrix box:    $pd_box"
            puts $fh "  Fast reserve box: $fast_box"

            set llx [lindex $pd_box 0]
            set lly [lindex $pd_box 1]
            set urx [lindex $pd_box 2]
            set ury [lindex $pd_box 3]
            if {($urx > $llx) && ($ury > $lly)} {
                if {[catch {createRegion $pnr(pd_symmetry_group) $llx $lly $urx $ury} err]} {
                    puts $fh "Region create warning: $err"
                } else {
                    puts $fh "Region created for $pnr(pd_symmetry_group): $llx $lly $urx $ury"
                }
                if {[catch {mptdc_pnr_create_place_blockage mptdc_slow_osc_keepout $slow_box} err]} {
                    puts $fh "Slow oscillator keepout warning: $err"
                } else {
                    puts $fh "Slow oscillator keepout requested: $slow_box"
                }
                if {[catch {mptdc_pnr_create_place_blockage mptdc_fast_osc_keepout $fast_box} err]} {
                    puts $fh "Fast oscillator keepout warning: $err"
                } else {
                    puts $fh "Fast oscillator keepout requested: $fast_box"
                }
            } else {
                puts $fh "Region skipped: derived PD box is invalid"
            }
        } else {
            puts $fh "Region skipped: unable to derive sandwich boxes"
        }
    }

    puts $fh "METTP exception: $pnr(phase_exception_enable); phase route top layer: $pnr(phase_route_top_layer)"
    puts $fh "Note: final symmetry and matched-RC closure still requires oscillator macro LEFs/Liberty and extracted routing rules."
    close $fh
}

set script_dir [file dirname [file normalize [info script]]]
set pnr_root   [file dirname $script_dir]
set mptdc_root [file dirname $pnr_root]
set syn_root   "$mptdc_root/syn"
set runtype    "pnr"

source "$syn_root/inputs/mptdc.defines"
source "$syn_root/libraries/libraries.$TECHNOLOGY.tcl"
source "$syn_root/libraries/libraries.$SC_TECHNOLOGY.tcl"
source "$pnr_root/inputs/mptdc_pnr_config.tcl"

set pnr(work_dir)    "$pnr_root/work"
set pnr(outputs_dir) "$pnr_root/outputs"
set pnr(reports_dir) "$pnr_root/reports"
set pnr(logs_dir)    "$pnr_root/logs"

foreach dir [list $pnr(work_dir) $pnr(outputs_dir) $pnr(reports_dir) $pnr(logs_dir)] {
    file mkdir $dir
}

set pnr(osc_pd_enable) 0
if {[info exists ::env(MPTDC_OSC_PD_ENABLE)] && $::env(MPTDC_OSC_PD_ENABLE)} {
    set pnr(osc_pd_enable) 1
    if {[info exists ::env(MPTDC_OSC_PD_RESULT_DIR)] && $::env(MPTDC_OSC_PD_RESULT_DIR) ne ""} {
        set pnr(osc_pd_result_dir) $::env(MPTDC_OSC_PD_RESULT_DIR)
    } else {
        set pnr(osc_pd_result_dir) "$pnr(reports_dir)/osc_pd"
    }
    file mkdir $pnr(osc_pd_result_dir)
}

foreach stale_path [list \
    "$pnr(reports_dir)/prects" \
    "$pnr(reports_dir)/postroute" \
    "$pnr(reports_dir)/run_manifest.rpt" \
    "$pnr(reports_dir)/run_status.rpt" \
    "$pnr(reports_dir)/pd_matrix_symmetry.rpt" \
    "$pnr(reports_dir)/report_area_place.rpt" \
    "$pnr(reports_dir)/report_gate_count_place.rpt" \
    "$pnr(reports_dir)/report_power_place.rpt" \
    "$pnr(outputs_dir)/$design(TOPLEVEL).place.enc"] {
    file delete -force $stale_path
}

set status_fh [open "$pnr(reports_dir)/run_status.rpt" w]
puts $status_fh "MPTDC Innovus estimate status"
puts $status_fh "============================"
puts $status_fh "Status: INCOMPLETE"
puts $status_fh "Started: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
puts $status_fh "Script: [file normalize [info script]]"
close $status_fh

if {![file exists $design(postsyn_netlist)]} {
    puts "MPTDC_PNR_ERROR: missing Genus netlist: $design(postsyn_netlist)"
    puts "Run MPTDC/syn/scripts/genus.tcl first."
    exit 1
}

if {![file exists $design(postsyn_sdc)]} {
    puts "MPTDC_PNR_ERROR: missing Genus SDC: $design(postsyn_sdc)"
    puts "Run MPTDC/syn/scripts/genus.tcl first."
    exit 1
}

set init_top_cell  $design(TOPLEVEL)
set init_verilog   $design(postsyn_netlist)
set init_lef_file  $tech_files(ALL_LEFS)
set init_mmmc_file "$pnr_root/inputs/mptdc_innovus.mmmc"
set init_pwr_net   $tech(STANDARD_CELL_VDD)
set init_gnd_net   $tech(STANDARD_CELL_GND)

mptdc_pnr_required "Initializing Innovus design" {
    init_design
}

if {$pnr(connect_pg_pins)} {
    foreach pg_pin $tech(STANDARD_CELL_VDD_PINS) {
        mptdc_pnr_optional "Connecting $tech(STANDARD_CELL_VDD) to PG pin $pg_pin" {
            globalNetConnect $tech(STANDARD_CELL_VDD) -type pgpin -pin $pg_pin -inst *
        }
    }
    foreach pg_pin $tech(STANDARD_CELL_GND_PINS) {
        mptdc_pnr_optional "Connecting $tech(STANDARD_CELL_GND) to PG pin $pg_pin" {
            globalNetConnect $tech(STANDARD_CELL_GND) -type pgpin -pin $pg_pin -inst *
        }
    }
    if {[info exists tech(OSC_VDD)] && [info exists tech(OSC_VDD_PINS)]} {
        foreach pg_pin $tech(OSC_VDD_PINS) {
            mptdc_pnr_optional "Connecting $tech(OSC_VDD) to oscillator PG pin $pg_pin" {
                globalNetConnect $tech(OSC_VDD) -type pgpin -pin $pg_pin -inst *
            }
        }
    }
    if {[info exists tech(OSC_GND)] && [info exists tech(OSC_GND_PINS)]} {
        foreach pg_pin $tech(OSC_GND_PINS) {
            mptdc_pnr_optional "Connecting $tech(OSC_GND) to oscillator PG pin $pg_pin" {
                globalNetConnect $tech(OSC_GND) -type pgpin -pin $pg_pin -inst *
            }
        }
    }
} else {
    mptdc_pnr_msg "Skipping explicit globalNetConnect because MPTDC_PNR_CONNECT_PG_PINS=0"
}

set margin $pnr(core_margin_um)
mptdc_pnr_required "Creating compact area-first floorplan" {
    floorPlan -site $tech(STANDARD_CELL_SITE) -r \
        $pnr(aspect_ratio) $pnr(core_utilization) \
        $margin $margin $margin $margin
}

mptdc_pnr_optional "Applying oscillator/PD provisional regions and floorplan hooks" {
    if {$pnr(osc_pd_enable)} {
        source "$script_dir/osc_pd_regions.tcl"
        source "$script_dir/pd_matrix_floorplan.tcl"
        source "$script_dir/osc_pd_route_guides.tcl"
        mptdc_osc_pd_apply_regions
        mptdc_osc_pd_apply_pd_matrix_floorplan
        mptdc_osc_pd_apply_route_guides
    } else {
        mptdc_pnr_msg "Skipping oscillator/PD O0 hooks because MPTDC_OSC_PD_ENABLE is not set"
    }
}

mptdc_pnr_optional "Preparing phase-detector symmetry placement hooks" {
    if {$pnr(pd_symmetry_enable)} {
        mptdc_pnr_prepare_pd_symmetry
    } else {
        mptdc_pnr_msg "Skipping PD symmetry prep because MPTDC_PNR_PD_SYMMETRY_ENABLE=0"
    }
}

mptdc_pnr_optional "Limiting signal route layers to preserve top metal for power" {
    setNanoRouteMode -routeBottomRoutingLayer $pnr(signal_bottom_layer_idx)
    setNanoRouteMode -routeTopRoutingLayer    $pnr(signal_top_layer_idx)
}

mptdc_pnr_optional "Recording localized METTP phase-mesh exception" {
    if {$pnr(phase_exception_enable)} {
        mptdc_pnr_msg "Global route top remains $pnr(signal_top_layer); localized $pnr(phase_route_top_layer) exception is reserved for PD phase mesh review"
        mptdc_pnr_apply_phase_mesh_route_intent
    }
}

mptdc_pnr_optional "Applying placement density target" {
    setPlaceMode -place_global_max_density $pnr(place_global_max_density)
}

mptdc_pnr_required "Running pre-CTS placement" {
    placeDesign
}

mptdc_pnr_optional "Running post-place pre-CTS timing/DRV optimization" {
    if {$pnr(do_prects_opt)} {
        optDesign -preCTS
    } else {
        mptdc_pnr_msg "Skipping pre-CTS optimization because MPTDC_PNR_DO_PRECTS_OPT=0"
    }
}

mptdc_pnr_optional "Packing PD matrix digital-rail decap" {
    mptdc_pnr_insert_pd_decap
}

mptdc_pnr_optional "Generating pre-CTS timing reports" {
    timeDesign -preCTS -outDir "$pnr(reports_dir)/prects"
}

mptdc_pnr_optional "Configuring vectorless activity propagation" {
    mptdc_pnr_configure_vectorless_activity
}

mptdc_pnr_optional "Generating placed area report" {
    report_area > "$pnr(reports_dir)/report_area_place.rpt"
}

mptdc_pnr_optional "Generating placed gate-count report" {
    reportGateCount -level 10 > "$pnr(reports_dir)/report_gate_count_place.rpt"
}

mptdc_pnr_optional "Generating vectorless power report" {
    report_power > "$pnr(reports_dir)/report_power_place.rpt"
}

mptdc_pnr_optional "Generating extra closure reports" {
    mptdc_pnr_generate_extra_reports
}

if {$pnr(do_detail_route)} {
    mptdc_pnr_optional "Running detail route estimate" {
        routeDesign
    }
    mptdc_pnr_optional "Generating post-route timing reports" {
        setAnalysisMode -analysisType onChipVariation -cppr both
        timeDesign -postRoute -outDir "$pnr(reports_dir)/postroute"
    }
}

mptdc_pnr_optional "Generating oscillator/PD signoff reports" {
    if {$pnr(osc_pd_enable)} {
        source "$script_dir/report_pd_instance_symmetry.tcl"
        source "$script_dir/report_pd_phase_routes.tcl"
        source "$script_dir/report_osc_tap_loads.tcl"
        mptdc_osc_pd_report_instance_symmetry
        mptdc_osc_pd_report_phase_routes
        mptdc_osc_pd_report_tap_loads
    } else {
        mptdc_pnr_msg "Skipping oscillator/PD O0 reports because MPTDC_OSC_PD_ENABLE is not set"
    }
}

mptdc_pnr_required "Saving placed Innovus database" {
    saveDesign "$pnr(outputs_dir)/$design(TOPLEVEL).place.enc"
}

set fh [open "$pnr(reports_dir)/run_manifest.rpt" w]
puts $fh "MPTDC Innovus estimate manifest"
puts $fh "==============================="
puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
puts $fh "Top: $design(TOPLEVEL)"
puts $fh "Optimization goal: $pnr(optimization_goal)"
puts $fh "Metal stack: $pnr(metal_stack)"
puts $fh "Core utilization: $pnr(core_utilization)"
puts $fh "Placement max density: $pnr(place_global_max_density)"
puts $fh "Aspect ratio: $pnr(aspect_ratio)"
puts $fh "Core margin um: $pnr(core_margin_um)"
puts $fh "Signal routing layers: $pnr(signal_bottom_layer)-$pnr(signal_top_layer)"
puts $fh "Signal routing layer indexes: $pnr(signal_bottom_layer_idx)-$pnr(signal_top_layer_idx)"
puts $fh "Reserved power layer: $pnr(power_reserved_layer)"
puts $fh "Phase METTP exception enabled: $pnr(phase_exception_enable)"
puts $fh "Phase exception top layer: $pnr(phase_route_top_layer)"
puts $fh "Phase exception top layer index: $pnr(phase_route_top_layer_idx)"
puts $fh "Explicit PG pin connect enabled: $pnr(connect_pg_pins)"
if {[info exists tech(STANDARD_CELL_VDD_PINS)]} {
    puts $fh "VDD PG pin candidates: $tech(STANDARD_CELL_VDD_PINS)"
}
if {[info exists tech(STANDARD_CELL_GND_PINS)]} {
    puts $fh "VSS PG pin candidates: $tech(STANDARD_CELL_GND_PINS)"
}
puts $fh "Expected routing directions: MET1=$pnr(route_dir_MET1), MET2=$pnr(route_dir_MET2), MET3=$pnr(route_dir_MET3), METTP=$pnr(route_dir_METTP)"
puts $fh "PD symmetry prep enabled: $pnr(pd_symmetry_enable)"
puts $fh "PD target grid: $pnr(pd_rows)x$pnr(pd_cols)"
puts $fh "PD group: $pnr(pd_symmetry_group)"
puts $fh "PD instance patterns: $pnr(pd_instance_patterns)"
puts $fh "PD region margin um: $pnr(pd_region_margin_um)"
puts $fh "PD region target width/height um: $pnr(pd_region_width_um) / $pnr(pd_region_height_um)"
puts $fh "Oscillator macro estimate width/height um: $pnr(osc_macro_width_um) / $pnr(osc_macro_height_um)"
puts $fh "Oscillator macro halo/gap um: $pnr(osc_macro_halo_um) / $pnr(pd_region_gap_um)"
if {[info exists tech(PD_DECAP)]} {
    puts $fh "PD decap cells: $tech(PD_DECAP)"
}
puts $fh "Vectorless activity enabled: $pnr(vectorless_activity_enable)"
puts $fh "Vectorless toggle/static probability: $pnr(vectorless_toggle_rate) / $pnr(vectorless_static_probability)"
puts $fh "Pre-CTS opt enabled: $pnr(do_prects_opt)"
puts $fh "Detail route enabled: $pnr(do_detail_route)"
puts $fh "Netlist: $design(postsyn_netlist)"
puts $fh "SDC: $design(postsyn_sdc)"
puts $fh "MMMC: $init_mmmc_file"
puts $fh "LEF: $tech_files(ALL_LEFS)"
puts $fh ""
puts $fh "Review checklist"
puts $fh "----------------"
puts $fh "  [ ] extra_report_congestion*.rpt contain valid hotspot/overflow data or command failures to fix."
puts $fh "  [ ] pd_matrix_symmetry.rpt shows a grid-snapped sandwich region and oscillator keepouts."
puts $fh "  [ ] pd_matrix_decap.rpt shows DECAP25HD/DECAP15HD insertion inside or around the PD region."
puts $fh "  [ ] phase_mesh_route_intent.rpt shows whether Innovus accepted phase-net route attributes."
puts $fh "  [ ] extra_phase_mesh_audit.rpt lists only intended phase-like nets for the METTP exception."
puts $fh "  [ ] extra_cdc_floorplan_audit.rpt keeps synchronizers, u_meas_ctrl, and u_ctx_bank recognizable."
puts $fh "  [ ] timing reports separate u_meas_ctrl/context logic-depth blockers from placement/wire blockers."
close $fh

set status_fh [open "$pnr(reports_dir)/run_status.rpt" w]
puts $status_fh "MPTDC Innovus estimate status"
puts $status_fh "============================"
puts $status_fh "Status: COMPLETE"
puts $status_fh "Completed: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
puts $status_fh "Script: [file normalize [info script]]"
puts $status_fh "Top: $design(TOPLEVEL)"
puts $status_fh "Netlist: $design(postsyn_netlist)"
puts $status_fh "MMMC: $init_mmmc_file"
puts $status_fh "Pre-CTS summary: $pnr(reports_dir)/prects/${design(TOPLEVEL)}_preCTS.summary.gz"
close $status_fh

mptdc_pnr_msg "Innovus estimate complete"
