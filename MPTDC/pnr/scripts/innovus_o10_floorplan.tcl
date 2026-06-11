# =============================================================================
# O10 floorplan stage
# =============================================================================

proc mptdc_o10_floorplan {} {
    global o10 pnr tech
    mptdc_o10_msg "Creating O10 floorplan"
    if {$pnr(auto_die_from_regions) || ($pnr(die_width_um) ne "" && $pnr(die_height_um) ne "")} {
        set min_core_w [expr {max($pnr(pd_region_width_um), $pnr(osc_macro_width_um)) + (2.0 * $pnr(region_pad_um))}]
        set min_core_h [expr {$pnr(pd_region_height_um) + (2.0 * $pnr(pd_region_gap_um)) + (2.0 * $pnr(osc_macro_height_um)) + (2.0 * $pnr(region_pad_um))}]
        set die_w [mptdc_pnr_snap [expr {$min_core_w + (2.0 * $pnr(core_margin_um))}]]
        set die_h [mptdc_pnr_snap [expr {$min_core_h + (2.0 * $pnr(core_margin_um))}]]
        if {$pnr(die_width_um) ne ""} {
            set die_w [mptdc_pnr_snap $pnr(die_width_um)]
        }
        if {$pnr(die_height_um) ne ""} {
            set die_h [mptdc_pnr_snap $pnr(die_height_um)]
        }
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

    catch {setNanoRouteMode -routeBottomRoutingLayer $pnr(signal_bottom_layer_idx)}
    catch {setNanoRouteMode -routeTopRoutingLayer $pnr(signal_top_layer_idx)}
    catch {setPlaceMode -place_global_max_density $pnr(place_global_max_density)}

    catch {defOut -floorplan -netlist "$o10(def_dir)/01_floorplan.def"}
    catch {saveDesign "$o10(checkpoints_dir)/01_floorplan.enc"}
    mptdc_o10_restore_script 01_floorplan
    mptdc_o10_screenshot "01_floorplan_overview.png" "floorplan overview"
    mptdc_o10_screenshot "02_macros_pd_matrix.png" "macros and PD matrix"
    mptdc_o10_write_manifest floorplan
}
