# =============================================================================
# O10 route stage
# =============================================================================

proc mptdc_o10_route {} {
    global o10 pnr
    mptdc_o10_msg "Running route feasibility"
    if {[llength [info commands mptdc_pnr_apply_physical_effort]] > 0} {
        mptdc_pnr_apply_physical_effort pre_route
    }
    mptdc_o10_stage_mark route.routeDesign start
    if {[catch {routeDesign} err]} {
        mptdc_o10_msg "routeDesign failed: $err"
        mptdc_o10_stage_mark route.routeDesign failed
        set fh [open "$o10(reports_dir)/ROUTE_FAILED.txt" w]
        puts $fh "ROUTE_STATUS=FAILED"
        puts $fh "routeDesign failed: $err"
        puts $fh "No post-route timing, congestion, or DRV report should be treated as routed evidence."
        close $fh
        error "routeDesign failed: $err"
    } else {
        mptdc_o10_stage_mark route.routeDesign done
    }
    set run_postroute_opt 1
    if {[info exists pnr(run_postroute_opt)]} {
        set run_postroute_opt $pnr(run_postroute_opt)
    }
    if {$run_postroute_opt} {
        mptdc_o10_stage_mark route.optDesign_postRoute start
        if {[llength [info commands mptdc_pnr_apply_physical_effort]] > 0} {
            mptdc_pnr_apply_physical_effort pre_postroute_opt
        }
        if {[catch {optDesign -postRoute} err]} {
            mptdc_o10_msg "optDesign -postRoute failed: $err"
            mptdc_o10_stage_mark route.optDesign_postRoute failed
            set fh [open "$o10(reports_dir)/POSTROUTE_OPT_FAILED.txt" w]
            puts $fh "POSTROUTE_OPT_STATUS=FAILED"
            puts $fh "reason=$err"
            puts $fh "This run keeps the routed checkpoint for review; do not treat post-route optimization as complete."
            close $fh
        } else {
            mptdc_o10_stage_mark route.optDesign_postRoute done
            set fh [open "$o10(reports_dir)/postroute_opt_status.rpt" w]
            puts $fh "POSTROUTE_OPT_STATUS=COMPLETE"
            close $fh
        }
    } else {
        mptdc_o10_stage_mark route.optDesign_postRoute skipped
        set fh [open "$o10(reports_dir)/POSTROUTE_OPT_SKIPPED.txt" w]
        puts $fh "POSTROUTE_OPT_STATUS=SKIPPED"
        puts $fh "reason=MPTDC_O10_RUN_POSTROUTE_OPT is not set to 1; route-feasibility flow preserves the routeDesign checkpoint and avoids SI post-route optimization in single non-OCV mode."
        close $fh
    }
    mptdc_o10_stage_mark route.reports start
    mptdc_o10_report_stage post_route
    mptdc_o10_capture_candidates "$o10(reports_dir)/hold_post_route.rpt" \
        "O10 hold post route" [list {timeDesign -postRoute -hold} {report_timing -check_type hold -max_paths 100}]
    mptdc_o10_stage_mark route.reports done
    mptdc_o10_stage_mark route.defOut start
    catch {defOut "$o10(def_dir)/04_route.def"}
    mptdc_o10_stage_mark route.defOut done
    mptdc_o10_stage_mark route.saveDesign start
    catch {saveDesign "$o10(checkpoints_dir)/04_route.enc"}
    mptdc_o10_stage_mark route.saveDesign done
    mptdc_o10_stage_mark route.restore_script start
    mptdc_o10_restore_script 04_route
    mptdc_o10_stage_mark route.restore_script done
    mptdc_o10_stage_mark route.screenshot_routed start
    mptdc_o10_screenshot "05_routed_design.png" "routed design"
    mptdc_o10_stage_mark route.screenshot_routed done
    mptdc_o10_stage_mark route.screenshot_congestion start
    mptdc_o10_screenshot "06_congestion.png" "congestion"
    mptdc_o10_stage_mark route.screenshot_congestion done
    mptdc_o10_stage_mark route.screenshot_final_manager start
    mptdc_o10_screenshot "08_final_manager_view.png" "final manager view"
    mptdc_o10_stage_mark route.screenshot_final_manager done
    mptdc_o10_stage_mark route.manifest start
    mptdc_o10_write_manifest route
    mptdc_o10_stage_mark route.manifest done
}
