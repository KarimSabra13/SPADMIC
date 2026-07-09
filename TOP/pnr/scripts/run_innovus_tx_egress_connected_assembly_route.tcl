# =============================================================================
# SPADMIC TOP -- TX egress connected fixed-leaf assembly route/DRC
# =============================================================================

proc txasm_env_required {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "TXASM_ROUTE_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc txasm_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc txasm_status_set {key value} {
    set ::txasm_status($key) $value
}

proc txasm_read_status_key {path key default_value} {
    if {![file exists $path]} {
        return $default_value
    }
    set fh [open $path r]
    set value $default_value
    while {[gets $fh line] >= 0} {
        if {[regexp "^${key}=(.*)$" $line -> found]} {
            set value $found
        }
    }
    close $fh
    return $value
}

proc txasm_capture {path body} {
    if {[catch {redirect -file $path $body} err]} {
        set fh [open $path w]
        puts $fh "CAPTURE_STATUS=FAIL"
        puts $fh "ERROR=$err"
        close $fh
        return 0
    }
    return 1
}

proc txasm_file_text {path} {
    if {![file exists $path]} {
        return ""
    }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    return $text
}

proc txasm_drc_marker_count {path} {
    set text [txasm_file_text $path]
    if {$text eq ""} {
        return UNKNOWN
    }
    if {[regexp -nocase {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viols} $text -> count]} {
        return $count
    }
    if {[regexp -nocase {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viol} $text -> count]} {
        return $count
    }
    return UNKNOWN
}

proc txasm_checkplace_count {path pattern} {
    set text [txasm_file_text $path]
    if {$text eq ""} {
        return UNKNOWN
    }
    if {[regexp -nocase $pattern $text -> count]} {
        return $count
    }
    if {[regexp -nocase {Finished[[:space:]]+checkPlace|Finished[[:space:]]+checking[[:space:]]+placement} $text]} {
        return 0
    }
    return UNKNOWN
}

proc txasm_all_terms {} {
    set terms [list]
    if {![catch {dbGet top.terms.name} found]} {
        foreach term $found {
            if {$term ne "0x0" && $term ne ""} {
                lappend terms $term
            }
        }
    }
    return [lsort -unique $terms]
}

proc txasm_terms_matching {patterns} {
    set out [list]
    set all [txasm_all_terms]
    foreach term $all {
        foreach pat $patterns {
            if {[string match $pat $term]} {
                lappend out $term
                break
            }
        }
    }
    return [lsort -unique $out]
}

proc txasm_place_side_pins {label side layer patterns} {
    set pins [txasm_terms_matching $patterns]
    set rpt [file join $::txasm_reports_dir "${label}.rpt"]
    set fh [open $rpt w]
    puts $fh "LABEL=$label"
    puts $fh "SIDE=$side"
    puts $fh "LAYER=$layer"
    puts $fh "PIN_COUNT=[llength $pins]"
    puts $fh "PINS=$pins"
    if {[llength $pins] == 0} {
        puts $fh "STATUS=SKIPPED_NO_PINS"
        close $fh
        txasm_status_set $label SKIPPED_NO_PINS
        return
    }
    set commands [list \
        [list editPin -pin $pins -side $side -layer $layer -spreadType SIDE -spacing 1.0 -pinWidth 0.56 -pinDepth 0.56 -fixedPin 1] \
        [list editPin -pin $pins -side [string tolower $side] -layer $layer -spreadType SIDE -spacing 1.0 -pinWidth 0.56 -pinDepth 0.56 -fixedPin 1] \
        [list editPin -pin $pins -side $side -layer $layer -spreadType SIDE -spacing 1.0] \
        [list editPin -pin $pins -side [string tolower $side] -layer $layer -spreadType SIDE -spacing 1.0]]
    foreach cmd $commands {
        puts $fh "TRY=$cmd"
        if {![catch {uplevel #0 $cmd} err]} {
            puts $fh "STATUS=PASS"
            puts $fh "COMMAND=$cmd"
            close $fh
            txasm_status_set $label PASS
            return
        }
        puts $fh "ERROR=$err"
    }
    puts $fh "STATUS=FAIL"
    close $fh
    txasm_status_set $label FAIL
    error "TXASM_ROUTE_PIN_PLACEMENT_FAILED: $label"
}

proc txasm_try_first {label commands {required 1}} {
    set rpt [file join $::txasm_reports_dir "${label}.rpt"]
    set fh [open $rpt w]
    puts $fh "LABEL=$label"
    set last_err ""
    foreach cmd $commands {
        puts $fh "TRY=$cmd"
        if {![catch {uplevel #0 $cmd} err]} {
            puts $fh "STATUS=PASS"
            puts $fh "COMMAND=$cmd"
            close $fh
            txasm_status_set $label PASS
            return 1
        }
        puts $fh "ERROR=$err"
        set last_err $err
    }
    puts $fh "STATUS=FAIL"
    close $fh
    txasm_status_set $label FAIL
    if {$required} {
        error "TXASM_ROUTE_COMMAND_FAILED: label=$label error=$last_err"
    }
    return 0
}

proc txasm_write_status {} {
    set status_rpt [file join $::txasm_reports_dir tx_egress_connected_assembly_route_status.rpt]
    set fh [open $status_rpt w]
    foreach key [lsort [array names ::txasm_status]] {
        puts $fh "$key=$::txasm_status($key)"
    }
    close $fh
}

set ::txasm_repo_root [txasm_env_required SPADMIC_REPO_ROOT]
set ::txasm_run_root [txasm_env_required SPADMIC_TXASM_ROUTE_RUN_ROOT]
set ::txasm_connected_root [txasm_env_required SPADMIC_TXASM_CONNECTED_ROOT]
set ::txasm_genus_root [txasm_env_required SPADMIC_TXASM_GENUS_ROOT]
set ::txasm_netlist [txasm_env_required SPADMIC_TXASM_NETLIST]
set ::txasm_sdc [txasm_env_required SPADMIC_TXASM_SDC]
set ::txasm_top_module [txasm_env_required SPADMIC_TXASM_TOP_MODULE]

foreach {name value} {
    MPTDC_XH018_STACK xx31
    MPTDC_STDCELL_FAMILY JIHD
    MPTDC_PNR_ROUTE_LAYER_NAMES {MET1 MET2 MET3 METTP}
    MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY 1
} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        set ::env($name) $value
    }
}

set ::txasm_reports_dir [file join $::txasm_run_root reports]
set ::txasm_outputs_dir [file join $::txasm_run_root outputs]
set ::txasm_checkpoints_dir [file join $::txasm_run_root checkpoints]
set ::txasm_generated_dir [file join $::txasm_run_root generated]
file mkdir $::txasm_reports_dir $::txasm_outputs_dir $::txasm_checkpoints_dir $::txasm_generated_dir

array set ::txasm_status {}
txasm_status_set LABEL TX_EGRESS_CONNECTED_ASSEMBLY_ROUTE
txasm_status_set SIGNOFF_READY NO
txasm_status_set TOP_MODULE $::txasm_top_module
txasm_status_set NETLIST $::txasm_netlist
txasm_status_set SDC $::txasm_sdc
txasm_status_set CONNECTED_ROOT $::txasm_connected_root
txasm_status_set GENUS_ROOT $::txasm_genus_root
txasm_status_set MPTDC_XH018_STACK $::env(MPTDC_XH018_STACK)
txasm_status_set MPTDC_STDCELL_FAMILY $::env(MPTDC_STDCELL_FAMILY)
txasm_status_set MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY $::env(MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY)
txasm_status_set LEAF_POLICY BLACKBOX_FIXED_ABSTRACTS
txasm_status_set PG_CONNECTIVITY_STATUS DEFERRED_TOP_LEVEL_HOOKUP
txasm_status_set PVS_STATUS DEFERRED
txasm_status_set LVS_STATUS DEFERRED
txasm_status_set PEX_STATUS DEFERRED
txasm_status_set MMMC_STATUS DEFERRED

set connected_status [file join $::txasm_connected_root tx_egress_leaf_connected_assembly_status.rpt]
set placement_tcl [txasm_read_status_key $connected_status PLACEMENT_TCL ""]
set plan_root [txasm_read_status_key $connected_status PLAN_ROOT ""]
set plan_status ""
if {$placement_tcl eq "" && $plan_root ne ""} {
    set placement_tcl [file join $plan_root tx_egress_leaf_assembly_place.tcl]
    set plan_status [file join $plan_root tx_egress_leaf_assembly_status.rpt]
}
if {![file exists $placement_tcl]} {
    error "TXASM_ROUTE_MISSING_PLACEMENT_TCL: $placement_tcl"
}

source $placement_tcl
txasm_status_set PLACEMENT_TCL $placement_tcl

global design tech tech_files mptdc_xh018_cells
set design(project_root) [file join $::txasm_repo_root MPTDC]
set design(TOPLEVEL) $::txasm_top_module
source [file join $::txasm_repo_root MPTDC syn libraries libraries.xh018.tcl]
source [file join $::txasm_repo_root MPTDC syn libraries libraries.xh018-stdcells.tcl]
source [file join $::txasm_repo_root MPTDC pnr config xh018_cells.tcl]
mptdc_xh018_validate_policy implementation
txasm_status_set LIBRARY_SOURCE PASS

set leaf_lefs [txasm_read_status_key $connected_status LEAF_LEFS ""]
if {$leaf_lefs eq "" && [info exists SPADMIC_TX_LEAF_LEFS]} {
    set leaf_lefs $SPADMIC_TX_LEAF_LEFS
}
if {$leaf_lefs eq ""} {
    error "TXASM_ROUTE_MISSING_LEAF_LEFS"
}

set local_w [txasm_read_status_key $connected_status LOCAL_ASSEMBLY_WIDTH_UM ""]
set local_h [txasm_read_status_key $connected_status LOCAL_ASSEMBLY_HEIGHT_UM ""]
if {$local_w eq "" && $plan_status ne ""} {
    set local_w [txasm_read_status_key $plan_status LOCAL_ASSEMBLY_WIDTH_UM 3449.600]
}
if {$local_h eq "" && $plan_status ne ""} {
    set local_h [txasm_read_status_key $plan_status LOCAL_ASSEMBLY_HEIGHT_UM 746.560]
}
set guard_um [txasm_env SPADMIC_TXASM_ROUTE_GUARD_UM 2.0]
if {[catch {expr {double($guard_um)}} guard]} {
    set guard 2.0
}
set floor_w [format "%.3f" [expr {double($local_w) + $guard}]]
set floor_h [format "%.3f" [expr {double($local_h) + $guard}]]

global init_top_cell init_verilog init_lef_file init_mmmc_file init_pwr_net init_gnd_net init_design_uniquify
set init_top_cell $::txasm_top_module
set init_verilog $::txasm_netlist
set init_lef_file [concat $tech_files(ALL_LEFS) $leaf_lefs]
set init_pwr_net $tech(STANDARD_CELL_VDD)
set init_gnd_net $tech(STANDARD_CELL_GND)
set init_design_uniquify 0

set mmmc [file join $::txasm_generated_dir typical_only_route.mmmc]
set fh [open $mmmc w]
puts $fh "create_constraint_mode -name txasm_route_mode -sdc_files \[list $::txasm_sdc\]"
if {[info exists tech_files(CAPTABLE_TC)] && [file exists $tech_files(CAPTABLE_TC)]} {
    puts $fh "create_rc_corner -name txasm_route_rc -temperature 25 -cap_table $tech_files(CAPTABLE_TC)"
} else {
    puts $fh "create_rc_corner -name txasm_route_rc -temperature 25"
}
puts $fh "create_library_set -name txasm_route_libset -timing \[list $tech_files(ALL_TC_LIBS)\]"
puts $fh "create_delay_corner -name txasm_route_corner -library_set txasm_route_libset -rc_corner txasm_route_rc"
puts $fh "create_analysis_view -name txasm_route_view -constraint_mode txasm_route_mode -delay_corner txasm_route_corner"
puts $fh "set_analysis_view -setup txasm_route_view -hold txasm_route_view"
close $fh
set init_mmmc_file $mmmc

init_design
txasm_status_set INIT_DESIGN PASS

foreach pg_pin $tech(STANDARD_CELL_VDD_PINS) {
    catch {globalNetConnect $tech(STANDARD_CELL_VDD) -type pgpin -pin $pg_pin -inst *}
}
foreach pg_pin $tech(STANDARD_CELL_GND_PINS) {
    catch {globalNetConnect $tech(STANDARD_CELL_GND) -type pgpin -pin $pg_pin -inst *}
}

if {[catch {floorPlan -site $tech(STANDARD_CELL_SITE) -s $floor_w $floor_h 0.0 0.0 0.0 0.0} err]} {
    txasm_status_set FLOORPLAN FAIL
    txasm_write_status
    error "TXASM_ROUTE_FLOORPLAN_FAILED: $err"
}
txasm_status_set FLOORPLAN PASS
txasm_status_set LOCAL_ASSEMBLY_WIDTH_UM $local_w
txasm_status_set LOCAL_ASSEMBLY_HEIGHT_UM $local_h
txasm_status_set FLOORPLAN_WIDTH_UM $floor_w
txasm_status_set FLOORPLAN_HEIGHT_UM $floor_h
txasm_status_set FLOORPLAN_GUARD_UM [format "%.3f" $guard]

txasm_place_side_pins PLACE_PINS_WEST WEST MET2 {clk_sys rst_n ddrs2_enable_i bundle_start_i required_packet_mask_i* source_pending_mask_i* event_id_i* src_valid_i* src_data_i* src_sop_i* src_eop_i*}
txasm_place_side_pins PLACE_PINS_EAST EAST MET2 {src_ready_o* completed_packet_mask_o* bundle_done_o bundle_busy_o bundle_idle_o bundle_missing_source_error_o output_fifo_* ddr_pair_valid_o ddr_padded_o ddr_busy_o ddr_empty_o}
txasm_place_side_pins PLACE_PINS_NORTH NORTH MET3 {clk_160m_i ddrs2_data_l_o* ddrs2_data_h_o* ddrs2_clk_160m_o}

spadmic_apply_tx_leaf_assembly_placement [file join $::txasm_reports_dir tx_egress_leaf_assembly_placement.rpt]
set placement_status [txasm_read_status_key [file join $::txasm_reports_dir tx_egress_leaf_assembly_placement.rpt] STATUS REVIEW_REQUIRED]
txasm_status_set FIXED_LEAF_PLACEMENT_STATUS $placement_status

set check_place_pre [file join $::txasm_reports_dir check_place_pre_route.rpt]
set check_place_ok [txasm_capture $check_place_pre {checkPlace}]
txasm_status_set CHECK_PLACE_PRE_CAPTURE_STATUS [expr {$check_place_ok ? "PASS" : "FAIL"}]
txasm_status_set CHECK_PLACE_PRE_OUT_OF_CORE_COUNT [txasm_checkplace_count $check_place_pre {Out of Core Area:[[:space:]]*([0-9]+)}]
txasm_status_set CHECK_PLACE_PRE_UNPLACED_COUNT [txasm_checkplace_count $check_place_pre {Unplaced[[:space:]]*=[[:space:]]*([0-9]+)}]

catch {setPlaceMode -place_global_ignore_scan true}
catch {setPlaceMode -ignoreScan true}
txasm_try_first PLACE_DESIGN [list {place_design} {placeDesign}] 1

set check_place_post [file join $::txasm_reports_dir check_place_post_place.rpt]
set check_place_post_ok [txasm_capture $check_place_post {checkPlace}]
txasm_status_set CHECK_PLACE_POST_CAPTURE_STATUS [expr {$check_place_post_ok ? "PASS" : "FAIL"}]
txasm_status_set CHECK_PLACE_POST_OUT_OF_CORE_COUNT [txasm_checkplace_count $check_place_post {Out of Core Area:[[:space:]]*([0-9]+)}]
txasm_status_set CHECK_PLACE_POST_UNPLACED_COUNT [txasm_checkplace_count $check_place_post {Unplaced[[:space:]]*=[[:space:]]*([0-9]+)}]

catch {setDesignMode -bottomRoutingLayer MET1 -topRoutingLayer MET3}
catch {setNanoRouteMode -routeBottomRoutingLayer 1}
catch {setNanoRouteMode -routeTopRoutingLayer 3}
catch {setNanoRouteMode -routeWithTimingDriven true}
catch {setNanoRouteMode -routeWithSiDriven true}
txasm_status_set ROUTE_LAYER_SETUP PASS

txasm_try_first ROUTE_DESIGN [list {routeDesign} {globalDetailRoute}] 1
txasm_status_set ROUTE_STATUS PASS

set drc_rpt [file join $::txasm_reports_dir verify_drc_post_route.rpt]
set drc_ok [txasm_capture $drc_rpt {verify_drc}]
set drc_count [txasm_drc_marker_count $drc_rpt]
txasm_status_set VERIFY_DRC_CAPTURE_STATUS [expr {$drc_ok ? "PASS" : "FAIL"}]
txasm_status_set DRC_MARKER_TOTAL $drc_count
if {$drc_ok && $drc_count ne "UNKNOWN" && $drc_count == 0} {
    txasm_status_set INNOVUS_DRC_STATUS PASS
} else {
    txasm_status_set INNOVUS_DRC_STATUS FAIL
}

txasm_capture [file join $::txasm_reports_dir report_area.rpt] {report_area}
txasm_capture [file join $::txasm_reports_dir report_design.rpt] {report_design}
txasm_capture [file join $::txasm_reports_dir report_timing_post_route.rpt] {timeDesign -postRoute}

catch {defOut -floorplan -netlist -routing [file join $::txasm_outputs_dir tx_egress_connected_assembly_route.def]}
catch {saveNetlist [file join $::txasm_outputs_dir tx_egress_connected_assembly_route.v]}
catch {saveNetlist -includePowerGround [file join $::txasm_outputs_dir tx_egress_connected_assembly_route.pg.v]}
catch {saveDesign [file join $::txasm_checkpoints_dir tx_egress_connected_assembly_route.enc]}
txasm_status_set EXPORT_DEF [expr {[file exists [file join $::txasm_outputs_dir tx_egress_connected_assembly_route.def]] ? "PASS" : "FAIL"}]
txasm_status_set EXPORT_NETLIST [expr {[file exists [file join $::txasm_outputs_dir tx_egress_connected_assembly_route.v]] ? "PASS" : "FAIL"}]

set inst_csv [file join $::txasm_reports_dir instance_summary.csv]
set fh [open $inst_csv w]
puts $fh "instance,cell,place_status,orient,box"
foreach inst [dbGet top.insts.name] {
    set obj [dbGet top.insts.name $inst -p]
    set cell [dbGet $obj.cell.name]
    set status [dbGet $obj.pStatus]
    set orient [dbGet $obj.orient]
    set box [dbGet $obj.box]
    puts $fh "$inst,$cell,$status,$orient,\"$box\""
}
close $fh
txasm_status_set INSTANCE_SUMMARY_FILE $inst_csv

set result CONNECTED_ASSEMBLY_ROUTE_REVIEW_REQUIRED
set status REVIEW_REQUIRED
if {$placement_status eq "PASS" && [info exists ::txasm_status(PLACE_DESIGN)] && $::txasm_status(PLACE_DESIGN) eq "PASS" && [info exists ::txasm_status(ROUTE_DESIGN)] && $::txasm_status(ROUTE_DESIGN) eq "PASS" && [info exists ::txasm_status(INNOVUS_DRC_STATUS)] && $::txasm_status(INNOVUS_DRC_STATUS) eq "PASS"} {
    set result CONNECTED_ASSEMBLY_ROUTED_DRC_CLEAN
    set status PASS
}
txasm_status_set STATUS $status
txasm_status_set RESULT $result
txasm_status_set SIGNAL_ROUTE_LAYERS MET1-MET3

txasm_write_status

if {$status eq "PASS"} {
    exit 0
}
exit 8
