# =============================================================================
# O10 placement stage
# =============================================================================

proc mptdc_o10_place {} {
    global o10
    mptdc_o10_msg "Running placement"
    placeDesign
    catch {optDesign -preCTS}
    mptdc_o10_report_stage post_place
    catch {defOut "$o10(def_dir)/02_place.def"}
    catch {saveDesign "$o10(checkpoints_dir)/02_place.enc"}
    mptdc_o10_restore_script 02_place
    mptdc_o10_screenshot "03_placed_design.png" "placed design"
    mptdc_o10_write_manifest place
}
