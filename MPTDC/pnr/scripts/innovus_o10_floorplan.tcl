# =============================================================================
# O10 floorplan stage
# =============================================================================

proc mptdc_o10_floorplan {} {
    global o10 pnr tech
    mptdc_o10_msg "Creating O10 floorplan"
    floorPlan -site $tech(STANDARD_CELL_SITE) -r \
        $pnr(aspect_ratio) $pnr(core_utilization) \
        $pnr(core_margin_um) $pnr(core_margin_um) $pnr(core_margin_um) $pnr(core_margin_um)

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
