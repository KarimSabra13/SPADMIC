# =============================================================================
# O10 floorplan stage
# =============================================================================

proc mptdc_o10_sum_numeric_values {values} {
    set sum 0.0
    foreach value $values {
        if {[regexp {^-?[0-9]+([.][0-9]+)?([eE][-+]?[0-9]+)?$} $value]} {
            set sum [expr {$sum + double($value)}]
        }
    }
    return $sum
}

proc mptdc_o10_estimate_instance_area_um2 {} {
    global pnr
    if {$pnr(min_stdcell_area_um2) ne ""} {
        return [expr {double($pnr(min_stdcell_area_um2))}]
    }

    foreach query {
        {dbGet top.insts.cell.area}
        {dbGet top.insts.baseCell.area}
    } {
        set values [list]
        if {![catch {set values [eval $query]}]} {
            set area [mptdc_o10_sum_numeric_values $values]
            if {$area > 0.0} {
                return $area
            }
        }
    }
    return 0.0
}

proc mptdc_o10_fixed_die_dimensions {} {
    global o10 pnr
    set min_core_w [expr {max($pnr(pd_region_width_um), $pnr(osc_macro_width_um)) + (2.0 * $pnr(region_pad_um))}]
    set min_core_h [expr {$pnr(pd_region_height_um) + (2.0 * $pnr(pd_region_gap_um)) + (2.0 * $pnr(osc_macro_height_um)) + (2.0 * $pnr(region_pad_um))}]
    set core_w $min_core_w
    set core_h $min_core_h
    set inst_area [mptdc_o10_estimate_instance_area_um2]
    set required_core_area 0.0

    if {$inst_area > 0.0 && $pnr(core_utilization) > 0.0} {
        set required_core_area [expr {($inst_area / double($pnr(core_utilization))) * double($pnr(area_guard_band))}]
        set aspect [expr {double($pnr(fixed_die_aspect_ratio))}]
        if {$aspect <= 0.0} {
            set aspect 1.0
        }
        set area_core_w [expr {sqrt($required_core_area * $aspect)}]
        set area_core_h [expr {sqrt($required_core_area / $aspect)}]
        set core_w [expr {max($core_w, $area_core_w)}]
        set core_h [expr {max($core_h, $area_core_h)}]
        if {[expr {$core_w * $core_h}] < $required_core_area} {
            if {[expr {$core_w / $core_h}] < $aspect} {
                set core_w [expr {$required_core_area / $core_h}]
            } else {
                set core_h [expr {$required_core_area / $core_w}]
            }
        }
    }

    set die_w [mptdc_pnr_snap [expr {$core_w + (2.0 * $pnr(core_margin_um))}]]
    set die_h [mptdc_pnr_snap [expr {$core_h + (2.0 * $pnr(core_margin_um))}]]
    if {$pnr(die_width_um) ne ""} {
        set die_w [mptdc_pnr_snap $pnr(die_width_um)]
    }
    if {$pnr(die_height_um) ne ""} {
        set die_h [mptdc_pnr_snap $pnr(die_height_um)]
    }

    set path "$o10(reports_dir)/floorplan_capacity.rpt"
    set fh [open $path w]
    puts $fh "O10.2 floorplan capacity"
    puts $fh "========================"
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh "instance_area_um2=$inst_area"
    puts $fh "core_utilization_target=$pnr(core_utilization)"
    puts $fh "area_guard_band=$pnr(area_guard_band)"
    puts $fh "required_core_area_um2=$required_core_area"
    puts $fh "minimum_region_core_width_um=$min_core_w"
    puts $fh "minimum_region_core_height_um=$min_core_h"
    puts $fh "chosen_die_width_um=$die_w"
    puts $fh "chosen_die_height_um=$die_h"
    close $fh

    return [list $die_w $die_h]
}

proc mptdc_o10_floorplan {} {
    global o10 pnr tech
    mptdc_o10_msg "Creating O10 floorplan"
    if {[llength [info commands mptdc_pnr_apply_physical_effort]] > 0} {
        mptdc_pnr_apply_physical_effort floorplan
    }
    if {$pnr(auto_die_from_regions) || ($pnr(die_width_um) ne "" && $pnr(die_height_um) ne "")} {
        set dims [mptdc_o10_fixed_die_dimensions]
        set die_w [lindex $dims 0]
        set die_h [lindex $dims 1]
        mptdc_o10_msg "Using fixed die floorplan ${die_w}um x ${die_h}um for RO/PD stack"
        if {[catch {
            floorPlan -site $tech(STANDARD_CELL_SITE) -d \
                $die_w $die_h \
                $pnr(core_margin_um) $pnr(core_margin_um) $pnr(core_margin_um) $pnr(core_margin_um)
        } err]} {
            mptdc_o10_msg "fixed die floorPlan failed: $err; falling back to utilization floorplan"
            floorPlan -site $tech(STANDARD_CELL_SITE) -r \
                $pnr(aspect_ratio) $pnr(core_utilization) \
                $pnr(core_margin_um) $pnr(core_margin_um) $pnr(core_margin_um) $pnr(core_margin_um)
        }
    } else {
        floorPlan -site $tech(STANDARD_CELL_SITE) -r \
            $pnr(aspect_ratio) $pnr(core_utilization) \
            $pnr(core_margin_um) $pnr(core_margin_um) $pnr(core_margin_um) $pnr(core_margin_um)
    }

    mptdc_o10_apply_pd_ro_floorplan
    if {[llength [info commands mptdc_o10_place_io_pins]] > 0} {
        mptdc_o10_place_io_pins
    }

    catch {setNanoRouteMode -routeBottomRoutingLayer $pnr(signal_bottom_layer_idx)}
    catch {setNanoRouteMode -routeTopRoutingLayer $pnr(signal_top_layer_idx)}
    catch {setPlaceMode -place_global_max_density $pnr(place_global_max_density)}
    if {[llength [info commands mptdc_pnr_apply_physical_effort]] > 0} {
        mptdc_pnr_apply_physical_effort post_floorplan
    }

    catch {defOut -floorplan -netlist "$o10(def_dir)/01_floorplan.def"}
    catch {saveDesign "$o10(checkpoints_dir)/01_floorplan.enc"}
    mptdc_o10_restore_script 01_floorplan
    mptdc_o10_screenshot "01_floorplan_overview.png" "floorplan overview"
    mptdc_o10_screenshot "02_macros_pd_matrix.png" "macros and PD matrix"
    mptdc_o10_write_manifest floorplan
}
