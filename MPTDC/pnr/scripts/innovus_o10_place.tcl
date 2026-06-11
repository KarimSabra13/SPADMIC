# =============================================================================
# O10 placement stage
# =============================================================================

proc mptdc_o10_unplaced_count_from_checkplace {path} {
    if {![file exists $path]} {
        return ""
    }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    if {[regexp {Unplaced[[:space:]]*=[[:space:]]*([0-9]+)} $text -> count]} {
        return $count
    }
    return ""
}

proc mptdc_o10_out_of_core_count_from_checkplace {path} {
    if {![file exists $path]} {
        return ""
    }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    if {[regexp {Out of Core Area:[[:space:]]*([0-9]+)} $text -> count]} {
        return $count
    }
    return ""
}

proc mptdc_o10_write_place_failure {message} {
    global o10
    set fh [open "$o10(reports_dir)/PLACEMENT_FAILED.txt" w]
    puts $fh "PLACEMENT_STATUS=FAILED"
    puts $fh $message
    puts $fh "See reports/place_check_post_place.rpt and reports/floorplan_capacity.rpt."
    close $fh
}

proc mptdc_o10_place {} {
    global o10 pnr
    mptdc_o10_msg "Running placement"
    if {[catch {placeDesign} err]} {
        mptdc_o10_write_place_failure "placeDesign returned an error: $err"
        error "placeDesign failed: $err"
    }

    set place_check "$o10(reports_dir)/place_check_post_place.rpt"
    catch {checkPlace > $place_check}
    set unplaced [mptdc_o10_unplaced_count_from_checkplace $place_check]
    if {$unplaced ne "" && $unplaced > $pnr(place_max_unplaced)} {
        set msg "placement incomplete: unplaced instances=$unplaced limit=$pnr(place_max_unplaced)"
        mptdc_o10_msg $msg
        mptdc_o10_write_place_failure $msg
        error $msg
    }
    set out_of_core [mptdc_o10_out_of_core_count_from_checkplace $place_check]
    if {$out_of_core ne "" && $out_of_core > 0} {
        set fh [open "$o10(reports_dir)/PLACEMENT_REVIEW.txt" w]
        puts $fh "PLACEMENT_STATUS=REVIEW_REQUIRED"
        puts $fh "out_of_core_instances=$out_of_core"
        puts $fh "See reports/place_check_post_place.rpt before treating this as a clean physical result."
        close $fh
        mptdc_o10_msg "placement review required: out-of-core instances=$out_of_core"
    }

    if {[catch {optDesign -preCTS} err]} {
        mptdc_o10_msg "optDesign -preCTS failed after placement: $err"
    }
    mptdc_o10_report_stage post_place
    catch {defOut "$o10(def_dir)/02_place.def"}
    catch {saveDesign "$o10(checkpoints_dir)/02_place.enc"}
    mptdc_o10_restore_script 02_place
    mptdc_o10_screenshot "03_placed_design.png" "placed design"
    mptdc_o10_write_manifest place
}
