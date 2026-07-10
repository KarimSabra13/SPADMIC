# P02-R2: deterministic PG geometry on a clean routed tx_ddr_strip checkpoint.

proc pgf_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_PG_FIX_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc pgf_value {value} {
    if {$value eq ""} { return NONE }
    return [string map [list "\n" " " "\r" " " "\t" " "] $value]
}

proc pgf_text {path} {
    if {![file exists $path]} { return "" }
    set fh [open $path r]
    set value [read $fh]
    close $fh
    return $value
}

proc pgf_violation_count {path} {
    set value [pgf_text $path]
    if {[regexp -nocase {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viol} $value -> count]} {
        return $count
    }
    return UNKNOWN
}

proc pgf_capture {path command} {
    if {[catch {redirect -file $path $command} err]} {
        set fh [open $path w]
        puts $fh "STATUS=FAIL"
        puts $fh "ERROR=[pgf_value $err]"
        close $fh
        return 0
    }
    return 1
}

proc pgf_object_count {objects} {
    if {$objects eq "" || $objects eq "0x0" || $objects eq "NULL"} { return 0 }
    return [llength $objects]
}

proc pgf_flat_numbers {value} {
    return [regexp -all -inline {[-+]?[0-9]*[.]?[0-9]+} $value]
}

proc pgf_box_matches {actual expected tolerance} {
    set a [pgf_flat_numbers $actual]
    set e [pgf_flat_numbers $expected]
    if {[llength $a] < 4 || [llength $e] < 4} { return 0 }
    for {set index 0} {$index < 4} {incr index} {
        if {abs(double([lindex $a $index]) - double([lindex $e $index])) > $tolerance} {
            return 0
        }
    }
    return 1
}

proc pgf_term_center_x {name fallback} {
    set term ""
    if {[catch {set term [dbGet top.pgTerms.name $name -p]}] ||
        $term eq "" || $term eq "0x0"} {
        return [list $fallback ENV_FALLBACK]
    }
    foreach expression [list \
        "${term}.pins.allShapes.shapes.box" \
        "${term}.pins.allShapes.box" \
        "${term}.pins.allShapes.shapes.rect" \
        "${term}.pins.allShapes.rect"] {
        if {[catch {set raw [dbGet $expression]}] || $raw eq "" || $raw eq "0x0"} {
            continue
        }
        set numbers [pgf_flat_numbers $raw]
        if {[llength $numbers] >= 4} {
            return [list [expr {(double([lindex $numbers 0]) + double([lindex $numbers 2])) / 2.0}] DB_PG_TERM]
        }
    }
    return [list $fallback ENV_FALLBACK]
}

proc pgf_write_status {path} {
    upvar #0 status status
    set fh [open $path w]
    foreach key [lsort [array names status]] { puts $fh "$key=$status($key)" }
    close $fh
}

proc pgf_dump_markers {path} {
    set fh [open $path w]
    puts $fh "idx\tmarker_handle\tbox\tlayer\ttype\tsubType\tmessage"
    set count 0
    if {![catch {set markers [dbGet top.markers]}]} {
        foreach marker $markers {
            if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} { continue }
            incr count
            set box UNKNOWN
            set layer UNKNOWN
            set type UNKNOWN
            set subtype UNKNOWN
            set message UNKNOWN
            catch {set box [dbGet $marker.box]}
            catch {set layer [dbGet $marker.layer.name]}
            catch {set type [dbGet $marker.type]}
            catch {set subtype [dbGet $marker.subType]}
            catch {set message [dbGet $marker.message]}
            puts $fh "$count\t[pgf_value $marker]\t[pgf_value $box]\t[pgf_value $layer]\t[pgf_value $type]\t[pgf_value $subtype]\t[pgf_value $message]"
        }
    }
    close $fh
    return $count
}

set source_checkpoint [pgf_env SPADMIC_PG_FIX_SOURCE_CHECKPOINT]
set run_root [pgf_env SPADMIC_PG_FIX_RUN_ROOT]
set top [pgf_env SPADMIC_PG_FIX_TOP]
set block [pgf_env SPADMIC_PG_FIX_BLOCK]
set width [expr {double([pgf_env SPADMIC_PG_FIX_STRIPE_WIDTH_UM])}]
set vdd_fallback [expr {double([pgf_env SPADMIC_PG_FIX_VDD_X_FALLBACK_UM])}]
set vss_fallback [expr {double([pgf_env SPADMIC_PG_FIX_VSS_X_FALLBACK_UM])}]
set vdd_y0 [expr {double([pgf_env SPADMIC_PG_FIX_VDD_Y0_UM])}]
set vss_y0 [expr {double([pgf_env SPADMIC_PG_FIX_VSS_Y0_UM])}]
set y1 [expr {double([pgf_env SPADMIC_PG_FIX_Y1_UM])}]
set expected_core [pgf_env SPADMIC_PG_FIX_EXPECTED_CORE_BOX]
set expected_die [pgf_env SPADMIC_PG_FIX_EXPECTED_DIE_BOX]
set helper_candidates [pgf_env SPADMIC_PG_FIX_VDD_HELPER_CANDIDATES_UM]
set helper_y0 [expr {double([pgf_env SPADMIC_PG_FIX_VDD_HELPER_Y0_UM])}]
set helper_y1 [expr {double([pgf_env SPADMIC_PG_FIX_VDD_HELPER_Y1_UM])}]
set helper_area_half_width [expr {double([pgf_env SPADMIC_PG_FIX_VDD_HELPER_AREA_HALF_WIDTH_UM])}]
set stream_map [pgf_env SPADMIC_STREAMOUT_MAP_FILE]
set stdcell_gds [pgf_env SPADMIC_PG_FIX_STDCELL_GDS]
set reports [file join $run_root reports]
set outputs [file join $run_root outputs]
set checkpoints [file join $run_root checkpoints]
file mkdir $reports $outputs $checkpoints

array set status {
    LABEL SPADMIC_OOC_PG_GEOMETRY_FIX
    PHASE P02_R3
    POLICY RESTORE_P01_EXPLICIT_PG_GEOMETRY_LOCAL_VDD_HELPER_NO_SIGNAL_ROUTE
    PLACE_ACTION NOT_RUN
    CTS_ACTION NOT_RUN
    SIGNAL_ROUTE_ACTION PRESERVED_NO_ROUTE_DESIGN
    TIMING_STATUS DEFERRED
    SIGNOFF_READY NO
    STATUS FAIL
    RESULT REVIEW_REQUIRED
}
set status_path [file join $reports pg_geometry_fix_status.rpt]

if {[catch {restoreDesign $source_checkpoint $top} err]} {
    set status(RESTORE_DESIGN) FAIL
    set status(ERROR) [pgf_value $err]
    pgf_write_status $status_path
    exit 8
}
set status(RESTORE_DESIGN) PASS

set core_box [dbGet top.fPlan.coreBox]
set die_box [dbGet top.fPlan.box]
set status(CORE_BOX) [pgf_value $core_box]
set status(DIE_BOX) [pgf_value $die_box]
if {![pgf_box_matches $core_box $expected_core 0.002] ||
    ![pgf_box_matches $die_box $expected_die 0.002]} {
    set status(GEOMETRY_GUARD) FAIL
    set status(ERROR) UNEXPECTED_SOURCE_GEOMETRY
    pgf_write_status $status_path
    exit 8
}
set status(GEOMETRY_GUARD) PASS

foreach net {VDD VSS} {
    set net_handle [dbGet top.nets.name $net -p]
    set count [pgf_object_count [dbGet $net_handle.sWires]]
    set status(PREEXISTING_${net}_SWIRE_COUNT) $count
    if {$count != 0} {
        set status(SOURCE_PG_CLEAN_GUARD) FAIL
        set status(ERROR) SOURCE_CHECKPOINT_ALREADY_HAS_SPECIAL_PG
        pgf_write_status $status_path
        exit 8
    }
}
set status(SOURCE_PG_CLEAN_GUARD) PASS

lassign [pgf_term_center_x VDD $vdd_fallback] vdd_x vdd_source
lassign [pgf_term_center_x VSS $vss_fallback] vss_x vss_source
set status(VDD_STRIPE_CENTER_X_UM) [format %.3f $vdd_x]
set status(VSS_STRIPE_CENTER_X_UM) [format %.3f $vss_x]
set status(VDD_STRIPE_CENTER_SOURCE) $vdd_source
set status(VSS_STRIPE_CENTER_SOURCE) $vss_source
set status(VDD_STRIPE_Y_RANGE_UM) "[format %.3f $vdd_y0],[format %.3f $y1]"
set status(VSS_STRIPE_Y_RANGE_UM) "[format %.3f $vss_y0],[format %.3f $y1]"
set status(STRIPE_WIDTH_UM) [format %.3f $width]
if {$vdd_source ne "DB_PG_TERM" || $vss_source ne "DB_PG_TERM"} {
    set status(PG_TERM_CENTER_GUARD) FAIL
    set status(ERROR) PG_TERM_CENTER_NOT_READ_FROM_DB
    pgf_write_status $status_path
    exit 8
}
set status(PG_TERM_CENTER_GUARD) PASS

set vdd_command [list add_shape -net VDD -layer METTP -shape STRIPE -status ROUTED \
    -pathSeg [list $vdd_x $vdd_y0 $vdd_x $y1] -width $width]
set vss_command [list add_shape -net VSS -layer METTP -shape STRIPE -status ROUTED \
    -pathSeg [list $vss_x $vss_y0 $vss_x $y1] -width $width]
foreach item [list [list VDD $vdd_command] [list VSS $vss_command]] {
    lassign $item net command
    if {[catch {uplevel #0 $command} err]} {
        set status(ADD_SHAPE_${net}) FAIL
        set status(ERROR) [pgf_value $err]
        pgf_write_status $status_path
        exit 8
    }
    set status(ADD_SHAPE_${net}) PASS
    set status(ADD_SHAPE_${net}_COMMAND) [pgf_value $command]
}
catch {saveDesign [file join $checkpoints 01_explicit_pg_stripes.enc]}

set sroute_command [list sroute -connect {corePin} -nets {VDD VSS} \
    -corePinTarget stripe -corePinCheckStdcellGeoms -allowJogging 1 \
    -allowLayerChange 1 -layerChangeRange {MET1 METTP}]
if {[catch {uplevel #0 $sroute_command} err]} {
    set status(SROUTE_CORE_PIN) FAIL
    set status(ERROR) [pgf_value $err]
    pgf_write_status $status_path
    exit 8
}
set status(SROUTE_CORE_PIN) PASS
set status(SROUTE_COMMAND) [pgf_value $sroute_command]
catch {saveDesign [file join $checkpoints 02_core_pin_stitched.enc]}

set main_detail [file join $reports verify_connectivity_pg_main_detail.rpt]
set main_console [file join $reports verify_connectivity_pg_main.rpt]
set main_command "verifyConnectivity -type special -nets {VDD VSS} -report \"$main_detail\""
set main_capture 1
if {[catch {uplevel #0 "$main_command > \"$main_console\""} err]} {
    set main_capture 0
    set status(VERIFY_MAIN_PG_ERROR) [pgf_value $err]
}
set main_count [pgf_violation_count $main_console]
set status(MAIN_PG_CONNECTIVITY_VIOLATION_COUNT) $main_count
set status(MAIN_PG_MARKER_COUNT) [pgf_dump_markers [file join $reports pg_connectivity_main_markers.tsv]]

set helper_selected NONE
set helper_summary [file join $reports vdd_helper_candidate_summary.tsv]
set helper_fh [open $helper_summary w]
puts $helper_fh "trial\tx_um\tadd_shape\tsroute\tpg_violations\tdrc_violations\tverdict"
if {$main_capture && $main_count ne "UNKNOWN" && $main_count == 0} {
    set status(VDD_HELPER_STATUS) NOT_REQUIRED
    set helper_selected NOT_REQUIRED
} else {
    set main_text [pgf_text $main_detail]
    if {!$main_capture || $main_count ne "3" ||
        [regexp {Net VSS} $main_text] ||
        ![regexp {134[.]540} $main_text] ||
        ![regexp {143[.]245} $main_text]} {
        close $helper_fh
        set status(VDD_HELPER_STATUS) FAIL_UNEXPECTED_MAIN_MARKERS
        set status(ERROR) MAIN_PG_FAILURE_DOES_NOT_MATCH_APPROVED_VDD_RESIDUAL
        pgf_write_status $status_path
        exit 8
    }
    set status(VDD_HELPER_STATUS) SEARCHING
    set baseline [file join $checkpoints 02_core_pin_stitched.enc.dat]
    if {![file exists $baseline]} {
        set baseline [file join $checkpoints 02_core_pin_stitched.enc]
    }
    set trial 0
    foreach candidate $helper_candidates {
        incr trial
        if {[catch {restoreDesign $baseline $top} restore_err]} {
            puts $helper_fh "$trial\t$candidate\tNOT_RUN\tNOT_RUN\tUNKNOWN\tUNKNOWN\tRESTORE_FAIL"
            continue
        }
        set x [expr {double($candidate)}]
        set helper_command [list add_shape -net VDD -layer METTP -shape STRIPE \
            -status ROUTED -pathSeg [list $x $helper_y0 $x $helper_y1] -width $width]
        if {[catch {uplevel #0 $helper_command} add_err]} {
            puts $helper_fh "$trial\t[format %.3f $x]\tFAIL\tNOT_RUN\tUNKNOWN\tUNKNOWN\tADD_SHAPE_FAIL"
            continue
        }
        set area [list \
            [expr {$x - $helper_area_half_width}] \
            [expr {$helper_y0 - 1.120}] \
            [expr {$x + $helper_area_half_width}] \
            [expr {$helper_y1 + 1.120}]]
        set helper_sroute [list sroute -connect {corePin} -nets {VDD} -area $area \
            -corePinTarget stripe -corePinCheckStdcellGeoms -allowJogging 1 \
            -allowLayerChange 1 -layerChangeRange {MET1 METTP}]
        if {[catch {uplevel #0 $helper_sroute} route_err]} {
            puts $helper_fh "$trial\t[format %.3f $x]\tPASS\tFAIL\tUNKNOWN\tUNKNOWN\tSROUTE_FAIL"
            continue
        }
        set trial_detail [file join $reports "vdd_helper_trial_${trial}_pg_detail.rpt"]
        set trial_console [file join $reports "vdd_helper_trial_${trial}_pg.rpt"]
        set trial_verify "verifyConnectivity -type special -nets {VDD VSS} -report \"$trial_detail\""
        if {[catch {uplevel #0 "$trial_verify > \"$trial_console\""} verify_err]} {
            puts $helper_fh "$trial\t[format %.3f $x]\tPASS\tPASS\tUNKNOWN\tUNKNOWN\tVERIFY_FAIL"
            continue
        }
        set trial_pg_count [pgf_violation_count $trial_console]
        pgf_dump_markers [file join $reports "vdd_helper_trial_${trial}_markers.tsv"]
        set trial_drc [file join $reports "vdd_helper_trial_${trial}_drc.rpt"]
        set trial_drc_capture [pgf_capture $trial_drc {verify_drc}]
        set trial_drc_count [pgf_violation_count $trial_drc]
        set verdict REJECT
        if {$trial_pg_count ne "UNKNOWN" && $trial_pg_count == 0 &&
            $trial_drc_capture && $trial_drc_count ne "UNKNOWN" &&
            $trial_drc_count == 0} {
            set verdict ACCEPT
            set helper_selected [format %.3f $x]
        }
        puts $helper_fh "$trial\t[format %.3f $x]\tPASS\tPASS\t$trial_pg_count\t$trial_drc_count\t$verdict"
        if {$verdict eq "ACCEPT"} { break }
    }
}
close $helper_fh
set status(VDD_HELPER_SELECTED_X_UM) $helper_selected
set status(VDD_HELPER_Y_RANGE_UM) "[format %.3f $helper_y0],[format %.3f $helper_y1]"
set status(VDD_HELPER_CANDIDATE_REPORT) $helper_summary
if {$helper_selected eq "NONE"} {
    set status(VDD_HELPER_STATUS) FAIL_NO_CLEAN_CANDIDATE
    set status(INTERNAL_PG_STATUS) FAIL
    pgf_write_status $status_path
    exit 8
}
if {$helper_selected ne "NOT_REQUIRED"} {
    set status(VDD_HELPER_STATUS) PASS
    catch {saveDesign [file join $checkpoints 03_vdd_helper_selected.enc]}
}

set special_detail [file join $reports verify_connectivity_pg_detail.rpt]
set special_console [file join $reports verify_connectivity_pg.rpt]
set special_command "verifyConnectivity -type special -nets {VDD VSS} -report \"$special_detail\""
set special_capture 1
if {[catch {uplevel #0 "$special_command > \"$special_console\""} err]} {
    set special_capture 0
    set status(VERIFY_PG_ERROR) [pgf_value $err]
}
set special_count [pgf_violation_count $special_console]
set status(PG_CONNECTIVITY_VIOLATION_COUNT) $special_count
set status(PG_CONNECTIVITY_STATUS) [expr {$special_capture && $special_count ne "UNKNOWN" && $special_count == 0 ? "PASS" : "FAIL"}]
set status(PG_MARKER_COUNT) [pgf_dump_markers [file join $reports pg_connectivity_markers.tsv]]

set regular_report [file join $reports verify_connectivity_regular.rpt]
set regular_capture [pgf_capture $regular_report {verifyConnectivity -type regular}]
set regular_count [pgf_violation_count $regular_report]
set status(REGULAR_CONNECTIVITY_VIOLATION_COUNT) $regular_count
set status(REGULAR_CONNECTIVITY_STATUS) [expr {$regular_capture && $regular_count ne "UNKNOWN" && $regular_count == 0 ? "PASS" : "FAIL"}]

set drc_report [file join $reports verify_drc_post_pg.rpt]
set drc_capture [pgf_capture $drc_report {verify_drc}]
set drc_count [pgf_violation_count $drc_report]
set status(DRC_MARKER_TOTAL) $drc_count
set status(INNOVUS_DRC_STATUS) [expr {$drc_capture && $drc_count ne "UNKNOWN" && $drc_count == 0 ? "PASS" : "FAIL"}]
catch {defOut [file join $reports tx_ddr_strip.pg_postcheck.def]}

if {$status(PG_CONNECTIVITY_STATUS) ne "PASS" ||
    $status(REGULAR_CONNECTIVITY_STATUS) ne "PASS" ||
    $status(INNOVUS_DRC_STATUS) ne "PASS"} {
    catch {saveDesign [file join $checkpoints 04_pg_postcheck_failed.enc]}
    set status(INTERNAL_PG_STATUS) FAIL
    pgf_write_status $status_path
    exit 8
}

set base [file join $outputs $block]
defOut "${base}.def"
saveNetlist "${base}.routed.v"
saveNetlist -includePowerGround "${base}.routed.pg.v"
if {[catch {write_lef_abstract "${base}.lef"}]} { lefOut "${base}.lef" }
file copy -force "${base}.lef" "${base}.abstract.lef"
streamOut "${base}.gds" -libName DesignLib -units 1000 -mode ALL \
    -mapFile $stream_map -merge [list $stdcell_gds]
catch {saveDesign [file join $checkpoints 05_pg_clean_export.enc]}

set status(INTERNAL_PG_STATUS) PASS
set status(STATUS) PASS
set status(RESULT) PG_STITCHED_DRC_CLEAN_PENDING_PVS
pgf_write_status $status_path
exit 0
