# Restore-only local PG stitching for an already routed OOC block.

proc pg_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_PG_PATCH_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc pg_capture {path body} {
    if {[catch {redirect -file $path $body} err]} {
        set fh [open $path w]
        puts $fh "STATUS=FAIL"
        puts $fh "ERROR=$err"
        close $fh
        return 0
    }
    return 1
}

proc pg_text {path} {
    if {![file exists $path]} { return "" }
    set fh [open $path r]
    set value [read $fh]
    close $fh
    return $value
}

proc pg_drc_count {path} {
    set value [pg_text $path]
    if {[regexp -nocase {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viol} $value -> count]} {
        return $count
    }
    return UNKNOWN
}

proc pg_connectivity_count {path} {
    set value [pg_text $path]
    if {[regexp -nocase {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viol} $value -> count]} {
        return $count
    }
    return UNKNOWN
}

proc pg_term_center_x {name fallback} {
    set term ""
    if {[catch {set term [dbGet top.pgTerms.name $name -p]}] || $term eq "" || $term eq "0x0"} {
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
        set numbers [regexp -all -inline {[-+]?[0-9]*[.]?[0-9]+} $raw]
        if {[llength $numbers] >= 4} {
            set llx [lindex $numbers 0]
            set urx [lindex $numbers 2]
            return [list [expr {(double($llx) + double($urx)) / 2.0}] DB_PG_TERM]
        }
    }
    return [list $fallback ENV_FALLBACK]
}

set checkpoint [pg_env SPADMIC_PG_PATCH_SOURCE_CHECKPOINT]
set run_root [pg_env SPADMIC_PG_PATCH_RUN_ROOT]
set block [pg_env SPADMIC_PG_PATCH_BLOCK]
set top [pg_env SPADMIC_PG_PATCH_TOP]
set vdd_x_fallback [expr {double([pg_env SPADMIC_PG_PATCH_VDD_X_UM])}]
set vss_x_fallback [expr {double([pg_env SPADMIC_PG_PATCH_VSS_X_UM])}]
set width [expr {double([pg_env SPADMIC_PG_PATCH_STRAP_WIDTH_UM])}]
set stream_map [pg_env SPADMIC_STREAMOUT_MAP_FILE]
set stdcell_gds [pg_env SPADMIC_PG_PATCH_STDCELL_GDS]
set reports [file join $run_root reports]
set outputs [file join $run_root outputs]
set checkpoints [file join $run_root checkpoints]
file mkdir $reports $outputs $checkpoints
array set status {
    LABEL SPADMIC_OOC_PG_ONLY_PATCH
    SIGNAL_ROUTE_ACTION PRESERVED_NO_ROUTE_DESIGN
    PLACE_ACTION NOT_RUN
    CTS_ACTION NOT_RUN
    TIMING_STATUS DEFERRED
    SIGNOFF_READY NO
}

restoreDesign $checkpoint $top
set status(RESTORE_DESIGN) PASS
lassign [pg_term_center_x VDD $vdd_x_fallback] vdd_x vdd_x_source
lassign [pg_term_center_x VSS $vss_x_fallback] vss_x vss_x_source
set status(VDD_STRIPE_CENTER_X_UM) [format %.3f $vdd_x]
set status(VSS_STRIPE_CENTER_X_UM) [format %.3f $vss_x]
set status(VDD_STRIPE_CENTER_SOURCE) $vdd_x_source
set status(VSS_STRIPE_CENTER_SOURCE) $vss_x_source
pg_capture [file join $reports report_route_before_pg.rpt] {reportRoute}
catch {saveDesign [file join $checkpoints 00_restored_signal_route.enc]}

set spacing $width
set distance 10000.0
foreach item [list [list VDD $vdd_x] [list VSS $vss_x]] {
    lassign $item net center
    set offset [expr {$center - $width / 2.0}]
    set command [list addStripe -nets [list $net] -layer METTP -direction vertical \
        -width $width -spacing $spacing -set_to_set_distance $distance \
        -start_from left -start_offset $offset -number_of_sets 1]
    if {[catch {uplevel #0 $command} err]} {
        set status(ADD_STRIPE_$net) FAIL
        set status(ERROR) $err
        set fh [open [file join $reports pg_only_patch_status.rpt] w]
        foreach key [lsort [array names status]] { puts $fh "$key=$status($key)" }
        close $fh
        error "SPADMIC_PG_PATCH_ADD_STRIPE_FAILED: net=$net error=$err"
    }
    set status(ADD_STRIPE_$net) PASS
}

set route_ok 0
foreach command [list \
    [list sroute -connect {corePin blockPin} -nets {VDD VSS} -blockPin all \
        -blockPinTarget stripe -corePinTarget stripe -allowLayerChange 1] \
    [list sroute -connect {blockPin corePin} -nets {VDD VSS} -blockPin all \
        -allowJogging 1 -layerChangeRange {MET1 METTP}] \
    [list sroute -connect {blockPin corePin} -nets {VDD VSS} -allowJogging 1]] {
    if {![catch {uplevel #0 $command} err]} {
        set route_ok 1
        set status(SROUTE_COMMAND) $command
        break
    }
}
if {!$route_ok} {
    set status(SROUTE_PG) FAIL
    set status(ERROR) $err
    error "SPADMIC_PG_PATCH_SROUTE_FAILED: $err"
}
set status(SROUTE_PG) PASS
catch {saveDesign [file join $checkpoints 01_pg_stitched.enc]}

set drc [file join $reports verify_drc_post_pg.rpt]
set pg_conn [file join $reports verify_connectivity_pg.rpt]
set regular_conn [file join $reports verify_connectivity_regular.rpt]
set drc_ok [pg_capture $drc {verify_drc}]
set drc_count [pg_drc_count $drc]
set pg_ok [pg_capture $pg_conn {verifyConnectivity -type special -nets {VDD VSS}}]
set regular_ok [pg_capture $regular_conn {verifyConnectivity -type regular}]
set pg_count [pg_connectivity_count $pg_conn]
set regular_count [pg_connectivity_count $regular_conn]
set status(DRC_MARKER_TOTAL) $drc_count
set status(PG_CONNECTIVITY_VIOLATION_COUNT) $pg_count
set status(REGULAR_CONNECTIVITY_VIOLATION_COUNT) $regular_count
set status(PG_CONNECTIVITY_STATUS) [expr {$pg_ok && $pg_count ne "UNKNOWN" && $pg_count == 0 ? "PASS" : "FAIL"}]
set status(REGULAR_CONNECTIVITY_STATUS) [expr {$regular_ok && $regular_count ne "UNKNOWN" && $regular_count == 0 ? "PASS" : "FAIL"}]
set status(INNOVUS_DRC_STATUS) [expr {$drc_ok && $drc_count ne "UNKNOWN" && $drc_count == 0 ? "PASS" : "FAIL"}]
pg_capture [file join $reports report_route_after_pg.rpt] {reportRoute}

set base [file join $outputs $block]
defOut "${base}.def"
saveNetlist "${base}.routed.v"
saveNetlist -includePowerGround "${base}.routed.pg.v"
if {[catch {write_lef_abstract "${base}.lef"}]} { lefOut "${base}.lef" }
file copy -force "${base}.lef" "${base}.abstract.lef"
streamOut "${base}.gds" -libName DesignLib -units 1000 -mode ALL \
    -mapFile $stream_map -merge [list $stdcell_gds]
catch {saveDesign [file join $checkpoints 02_pg_verified_export.enc]}

set status(INTERNAL_PG_STATUS) $status(PG_CONNECTIVITY_STATUS)
set status(RESULT) REVIEW_REQUIRED
set status(STATUS) FAIL
if {$status(INNOVUS_DRC_STATUS) eq "PASS" && $status(PG_CONNECTIVITY_STATUS) eq "PASS" && $status(REGULAR_CONNECTIVITY_STATUS) eq "PASS"} {
    set status(RESULT) PG_STITCHED_DRC_CLEAN_PENDING_PVS
    set status(STATUS) PASS
}
set fh [open [file join $reports pg_only_patch_status.rpt] w]
foreach key [lsort [array names status]] { puts $fh "$key=$status($key)" }
close $fh
if {$status(STATUS) eq "PASS"} { exit 0 }
exit 8
