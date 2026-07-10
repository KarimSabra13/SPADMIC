# Phase-A top-coordinate digital assembly: two fixed hard macros and 19 TX nets.

proc da_env_required {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_DA_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc da_status {key value} { set ::da_status($key) $value }

proc da_capture {path body} {
    if {[catch {redirect -file $path $body} err]} {
        set fh [open $path w]
        puts $fh "STATUS=FAIL"
        puts $fh "ERROR=$err"
        close $fh
        return 0
    }
    return 1
}

proc da_write_status {} {
    set path [file join $::spadmic_da_reports_dir digital_assembly_status.rpt]
    set fh [open $path w]
    foreach key [lsort [array names ::da_status]] {
        puts $fh "$key=$::da_status($key)"
    }
    close $fh
}

proc da_drc_count {path} {
    if {![file exists $path]} { return UNKNOWN }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    if {[regexp -nocase {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viol} $text -> count]} {
        return $count
    }
    return UNKNOWN
}

proc da_connectivity_count {path} {
    if {![file exists $path]} { return UNKNOWN }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    if {[regexp -nocase {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viol} $text -> count]} {
        return $count
    }
    return UNKNOWN
}

set ::spadmic_da_repo_root [da_env_required SPADMIC_REPO_ROOT]
set ::spadmic_da_run_root [da_env_required SPADMIC_DA_RUN_ROOT]
set ::spadmic_da_config_tcl [da_env_required SPADMIC_DA_CONFIG_TCL]
set ::spadmic_da_netlist [da_env_required SPADMIC_DA_NETLIST]
set ::spadmic_da_sdc [da_env_required SPADMIC_DA_SDC]
set ::spadmic_da_packet_lef [da_env_required SPADMIC_DA_PACKET_LEF]
set ::spadmic_da_strip_lef [da_env_required SPADMIC_DA_STRIP_LEF]
set ::spadmic_da_packet_gds [da_env_required SPADMIC_DA_PACKET_GDS]
set ::spadmic_da_strip_gds [da_env_required SPADMIC_DA_STRIP_GDS]
set ::spadmic_da_stream_map [da_env_required SPADMIC_STREAMOUT_MAP_FILE]
set ::spadmic_da_reports_dir [file join $::spadmic_da_run_root reports]
set ::spadmic_da_outputs_dir [file join $::spadmic_da_run_root outputs]
set ::spadmic_da_checkpoints_dir [file join $::spadmic_da_run_root checkpoints]
set ::spadmic_da_generated_dir [file join $::spadmic_da_run_root generated]
file mkdir $::spadmic_da_reports_dir $::spadmic_da_outputs_dir $::spadmic_da_checkpoints_dir

source $::spadmic_da_config_tcl
array set ::da_status {}
da_status LABEL SPADMIC_DIGITAL_ASSEMBLY_V1_P00_TX
da_status TOP_MODULE $::SPADMIC_DA_TOP_MODULE
da_status SIGNOFF_READY NO
da_status TIMING_STATUS DEFERRED_BY_PHASE_A_PLAN
da_status PG_STATUS DEFERRED_TO_PHASE_SPECIFIC_OA_OVERLAY
da_status SIGNAL_ROUTE_LAYERS MET2-MET3
da_status MET1_FALLBACK SELECTED_NETS_ONLY_BY_EXPLICIT_ENV

global design tech tech_files mptdc_xh018_cells
set design(project_root) [file join $::spadmic_da_repo_root MPTDC]
set design(TOPLEVEL) $::SPADMIC_DA_TOP_MODULE
source [file join $::spadmic_da_repo_root MPTDC syn libraries libraries.xh018.tcl]
source [file join $::spadmic_da_repo_root MPTDC syn libraries libraries.xh018-stdcells.tcl]
source [file join $::spadmic_da_repo_root MPTDC pnr config xh018_cells.tcl]
mptdc_xh018_validate_policy implementation
da_status LIBRARY_SOURCE PASS

set mmmc [file join $::spadmic_da_generated_dir assembly_typical_import.mmmc]
set fh [open $mmmc w]
puts $fh "create_constraint_mode -name da_mode -sdc_files \[list $::spadmic_da_sdc\]"
if {[info exists tech_files(CAPTABLE_TC)] && [file exists $tech_files(CAPTABLE_TC)]} {
    puts $fh "create_rc_corner -name da_rc -temperature 25 -cap_table $tech_files(CAPTABLE_TC)"
} else {
    puts $fh "create_rc_corner -name da_rc -temperature 25"
}
puts $fh "create_library_set -name da_libset -timing \[list $tech_files(ALL_TC_LIBS)\]"
puts $fh "create_delay_corner -name da_corner -library_set da_libset -rc_corner da_rc"
puts $fh "create_analysis_view -name da_view -constraint_mode da_mode -delay_corner da_corner"
puts $fh "set_analysis_view -setup da_view -hold da_view"
close $fh

global init_top_cell init_verilog init_lef_file init_mmmc_file init_pwr_net init_gnd_net init_design_uniquify
set init_top_cell $::SPADMIC_DA_TOP_MODULE
set init_verilog $::spadmic_da_netlist
set init_lef_file [concat $tech_files(ALL_LEFS) [list $::spadmic_da_packet_lef $::spadmic_da_strip_lef]]
set init_mmmc_file $mmmc
set init_pwr_net VDD
set init_gnd_net VSS
set init_design_uniquify 0
init_design
da_status INIT_DESIGN PASS
catch {globalNetConnect VDD -type pgpin -pin VDD -inst *}
catch {globalNetConnect VSS -type pgpin -pin VSS -inst *}
catch {globalNetConnect VDD -type net -net VDD}
catch {globalNetConnect VSS -type net -net VSS}
catch {saveDesign [file join $::spadmic_da_checkpoints_dir 00_import.enc]}

source [file join $::spadmic_da_repo_root TOP pnr assembly spadmic_digital_assembly_floorplan.tcl]
spadmic_da_apply_floorplan
da_status FIXED_MACRO_PLACEMENT_STATUS PASS
source [file join $::spadmic_da_repo_root TOP pnr assembly spadmic_digital_assembly_blockages.tcl]
spadmic_da_apply_blockages
source [file join $::spadmic_da_repo_root TOP pnr assembly spadmic_digital_assembly_pin_guides.tcl]
spadmic_da_apply_proxy_pins
da_capture [file join $::spadmic_da_reports_dir check_place.rpt] {checkPlace}
catch {saveDesign [file join $::spadmic_da_checkpoints_dir 01_tx_placed.enc]}

set route_bottom MET2
set route_bottom_idx 2
if {[info exists ::env(SPADMIC_DA_ENABLE_SELECTED_MET1_FALLBACK)] && $::env(SPADMIC_DA_ENABLE_SELECTED_MET1_FALLBACK) eq "1"} {
    set route_bottom MET1
    set route_bottom_idx 1
    da_status MET1_FALLBACK ENABLED_FOR_SELECTED_NETS
}
setDesignMode -bottomRoutingLayer $route_bottom -topRoutingLayer MET3
setNanoRouteMode -routeBottomRoutingLayer $route_bottom_idx
setNanoRouteMode -routeTopRoutingLayer 3
catch {setNanoRouteMode -routeWithTimingDriven false}
catch {setNanoRouteMode -routeWithSiDriven false}
foreach net $::SPADMIC_DA_ROUTE_NETS { catch {selectNet $net} }
set route_ok 0
foreach command [list {globalDetailRoute -select} {detailRoute -select} {ecoRoute -selectedNets}] {
    if {![catch {uplevel #0 $command} route_err]} {
        set route_ok 1
        da_status ROUTE_COMMAND $command
        break
    }
}
catch {deselectAll}
if {!$route_ok} {
    da_status ROUTE_STATUS FAIL
    da_write_status
    error "SPADMIC_DA_SELECTED_ROUTE_FAILED: $route_err"
}
da_status ROUTE_STATUS PASS
catch {saveDesign [file join $::spadmic_da_checkpoints_dir 02_tx_routed.enc]}

set drc_report [file join $::spadmic_da_reports_dir verify_drc_phase_a.rpt]
set drc_capture [da_capture $drc_report {verify_drc}]
set drc_count [da_drc_count $drc_report]
da_status DRC_MARKER_TOTAL $drc_count
da_status INNOVUS_DRC_STATUS [expr {$drc_capture && $drc_count ne "UNKNOWN" && $drc_count == 0 ? "PASS" : "FAIL"}]

set conn_report [file join $::spadmic_da_reports_dir verify_connectivity_phase_a.rpt]
set conn_capture [da_capture $conn_report [list verifyConnectivity -type regular -nets $::SPADMIC_DA_ROUTE_NETS]]
set conn_count [da_connectivity_count $conn_report]
da_status SELECTED_NET_CONNECTIVITY_VIOLATION_COUNT $conn_count
da_status SELECTED_NET_CONNECTIVITY_STATUS [expr {$conn_capture && $conn_count ne "UNKNOWN" && $conn_count == 0 ? "PASS" : "FAIL"}]

set output_base [file join $::spadmic_da_outputs_dir spadmic_digital_assembly_v1_p00_tx]
defOut "${output_base}.def"
saveNetlist "${output_base}.v"
catch {saveNetlist -includePowerGround "${output_base}.pg.v"}
if {[catch {write_lef_abstract "${output_base}.lef"}]} {
    catch {lefOut "${output_base}.lef"}
}
set stream_command [list streamOut "${output_base}.gds" -libName DesignLib -units 1000 -mode ALL \
    -mapFile $::spadmic_da_stream_map -merge [list $::spadmic_da_packet_gds $::spadmic_da_strip_gds]]
if {[catch {uplevel #0 $stream_command} stream_err]} {
    da_status EXPORT_GDS_STATUS FAIL
    da_write_status
    error "SPADMIC_DA_STREAMOUT_FAILED: $stream_err"
}
da_status EXPORT_GDS_STATUS PASS
da_status EXPORT_DEF_STATUS PASS
da_status EXPORT_NETLIST_STATUS PASS
da_status EXPORT_LEF_STATUS [expr {[file exists "${output_base}.lef"] ? "PASS" : "FAIL"}]

set result REVIEW_REQUIRED
if {$::da_status(INNOVUS_DRC_STATUS) eq "PASS" &&
    $::da_status(ROUTE_STATUS) eq "PASS" &&
    $::da_status(SELECTED_NET_CONNECTIVITY_STATUS) eq "PASS" &&
    $::da_status(EXPORT_LEF_STATUS) eq "PASS"} {
    set result PHASE_A_INNOVUS_DRC_CLEAN_PENDING_PVS_AND_PG
}
da_status RESULT $result
da_status STATUS [expr {$result eq "PHASE_A_INNOVUS_DRC_CLEAN_PENDING_PVS_AND_PG" ? "PASS" : "FAIL"}]
da_write_status
if {$::da_status(STATUS) eq "PASS"} { exit 0 }
exit 8
