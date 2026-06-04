# =============================================================================
# O10 route stage
# =============================================================================

proc mptdc_o10_route {} {
    global o10
    mptdc_o10_msg "Running route feasibility"
    if {[catch {routeDesign} err]} {
        mptdc_o10_msg "routeDesign failed: $err"
    }
    catch {optDesign -postRoute}
    mptdc_o10_report_stage post_route
    mptdc_o10_capture_candidates "$o10(reports_dir)/hold_post_route.rpt" \
        "O10 hold post route" [list {report_timing -check_type hold -max_paths 100} {timeDesign -postRoute -hold}]
    catch {defOut "$o10(def_dir)/04_route.def"}
    catch {saveDesign "$o10(checkpoints_dir)/04_route.enc"}
    mptdc_o10_restore_script 04_route
    mptdc_o10_screenshot "05_routed_design.png" "routed design"
    mptdc_o10_screenshot "06_congestion.png" "congestion"
    mptdc_o10_screenshot "08_final_manager_view.png" "final manager view"
    mptdc_o10_write_manifest route
}
