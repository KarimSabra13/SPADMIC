# =============================================================================
# SPADMIC matrix-top -- single-block Innovus OOC hardening flow
# =============================================================================

proc spadmic_ooc_env_required {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_OOC_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc spadmic_ooc_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

set ::spadmic_ooc_repo_root [spadmic_ooc_env_required SPADMIC_REPO_ROOT]
set ::spadmic_ooc_run_root [spadmic_ooc_env_required SPADMIC_INNOVUS_RUN_ROOT]
set ::spadmic_ooc_block_root [spadmic_ooc_env_required SPADMIC_INNOVUS_BLOCK_ROOT]
set ::spadmic_ooc_handoff_root [spadmic_ooc_env_required SPADMIC_INNOVUS_HANDOFF_ROOT]
set ::spadmic_ooc_block [spadmic_ooc_env_required SPADMIC_INNOVUS_BLOCK]
set ::spadmic_ooc_top_module [spadmic_ooc_env_required SPADMIC_INNOVUS_TOP_MODULE]
set ::spadmic_ooc_netlist [spadmic_ooc_env_required SPADMIC_INNOVUS_NETLIST]
set ::spadmic_ooc_sdc [spadmic_ooc_env_required SPADMIC_INNOVUS_SDC]
set ::spadmic_ooc_config_tcl [spadmic_ooc_env_required SPADMIC_INNOVUS_CONFIG_TCL]
set ::spadmic_ooc_genus_summary [spadmic_ooc_env_required SPADMIC_INNOVUS_GENUS_SUMMARY]

set ::spadmic_ooc_reports_dir [file join $::spadmic_ooc_block_root reports]
set ::spadmic_ooc_outputs_dir [file join $::spadmic_ooc_block_root outputs]
set ::spadmic_ooc_checkpoints_dir [file join $::spadmic_ooc_block_root checkpoints]
set ::spadmic_ooc_logs_dir [file join $::spadmic_ooc_block_root logs]
set ::spadmic_ooc_generated_dir [file join $::spadmic_ooc_block_root generated]
file mkdir $::spadmic_ooc_reports_dir $::spadmic_ooc_outputs_dir $::spadmic_ooc_checkpoints_dir $::spadmic_ooc_logs_dir $::spadmic_ooc_generated_dir
file mkdir [file join $::spadmic_ooc_handoff_root innovus] [file join $::spadmic_ooc_handoff_root netlist] [file join $::spadmic_ooc_handoff_root reports]

source $::spadmic_ooc_config_tcl

array set ::spadmic_ooc_status {}
proc spadmic_ooc_status_set {key value} {
    set ::spadmic_ooc_status($key) $value
}

proc spadmic_ooc_cfg {name} {
    set var "::spadmic_ooc::$name"
    if {![info exists $var]} {
        error "SPADMIC_OOC_MISSING_CONFIG: $name"
    }
    return [set $var]
}

proc spadmic_ooc_cfg_default {name default_value} {
    set var "::spadmic_ooc::$name"
    if {![info exists $var]} {
        return $default_value
    }
    return [set $var]
}

proc spadmic_ooc_cfg_list {name} {
    return [spadmic_ooc_cfg $name]
}

proc spadmic_ooc_layer_index {layer fallback} {
    if {[string is integer -strict $layer]} {
        return $layer
    }
    set upper [string toupper $layer]
    if {[regexp {^MET([0-9]+)$} $upper -> idx]} {
        return $idx
    }
    if {$upper eq "METTP"} {
        return 4
    }
    return $fallback
}

proc spadmic_ooc_write_text {path lines} {
    set fh [open $path w]
    foreach line $lines {
        puts $fh $line
    }
    close $fh
}

proc spadmic_ooc_try_first {label commands {required 1}} {
    set rpt [file join $::spadmic_ooc_reports_dir "${label}.rpt"]
    set fh [open $rpt w]
    puts $fh "LABEL=$label"
    set last_err ""
    foreach cmd $commands {
        puts $fh "TRY=$cmd"
        if {![catch {uplevel #0 $cmd} err]} {
            puts $fh "STATUS=PASS"
            puts $fh "COMMAND=$cmd"
            close $fh
            spadmic_ooc_status_set $label PASS
            return 1
        }
        puts $fh "ERROR=$err"
        set last_err $err
    }
    puts $fh "STATUS=FAIL"
    close $fh
    spadmic_ooc_status_set $label FAIL
    if {$required} {
        error "SPADMIC_OOC_COMMAND_FAILED: label=$label error=$last_err"
    }
    return 0
}

proc spadmic_ooc_capture_first {path label commands {required 1}} {
    set fh [open $path w]
    puts $fh "LABEL=$label"
    close $fh
    set last_err ""
    foreach cmd $commands {
        set fh [open $path a]
        puts $fh "TRY=$cmd"
        close $fh
        if {![catch {redirect -append -file $path $cmd} err]} {
            set fh [open $path a]
            puts $fh "STATUS=PASS"
            puts $fh "COMMAND=$cmd"
            close $fh
            return 1
        }
        set fh [open $path a]
        puts $fh "ERROR=$err"
        close $fh
        set last_err $err
    }
    set fh [open $path a]
    puts $fh "STATUS=FAIL"
    close $fh
    if {$required} {
        error "SPADMIC_OOC_REPORT_COMMAND_FAILED: label=$label path=$path error=$last_err"
    }
    return 0
}

proc spadmic_ooc_parse_drc_report {path} {
    set result UNKNOWN
    if {![file exists $path]} {
        return MISSING
    }
    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {[regexp -nocase {REPORT_STATUS=FAILED|STATUS=FAIL} $trimmed]} {
            set result FAIL
        }
        if {[regexp -nocase {Verification[[:space:]]+Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viols?} $trimmed -> count]} {
            set result [expr {$count == 0 ? "PASS" : "FAIL"}]
        }
        if {[regexp -nocase {No[[:space:]]+(DRC[[:space:]]+)?violations?[[:space:]]+found} $trimmed]} {
            set result PASS
        }
        if {[regexp -nocase {Total[[:space:]]+number[[:space:]]+of[[:space:]]+DRC[[:space:]]+violations[[:space:]]*=[[:space:]]*([0-9]+)} $trimmed -> count] ||
            [regexp -nocase {number[[:space:]]+of[[:space:]]+violations[[:space:]]*=[[:space:]]*([0-9]+)} $trimmed -> count]} {
            set result [expr {$count == 0 ? "PASS" : "FAIL"}]
        }
    }
    close $fh
    return $result
}

proc spadmic_ooc_connectivity_status {path} {
    if {![file exists $path]} {
        return MISSING
    }
    set bad 0
    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {[regexp -nocase {STATUS=FAIL|REPORT_STATUS=FAILED} $trimmed]} {
            set bad 1
        }
        if {[regexp -nocase {Found[[:space:]]+no[[:space:]]+problems[[:space:]]+or[[:space:]]+warnings} $trimmed] ||
            [regexp -nocase {Verification[[:space:]]+Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols?[.][[:space:]]+0[[:space:]]+Wrngs[.]} $trimmed]} {
            continue
        }
        if {[regexp -nocase {^(Error|Warning)[[:space:]]+Limit[[:space:]]*=} $trimmed]} {
            continue
        }
        if {[regexp -nocase {problem|short|open|unconnected|not[[:space:]]+connected|violation|error} $trimmed] &&
            ![regexp -nocase {no.*(problems|short|open|error|violation)|0[[:space:]]+(problems?|short|open|error|violation|viols)} $trimmed]} {
            set bad 1
        }
    }
    close $fh
    return [expr {$bad ? "FAIL" : "PASS"}]
}

proc spadmic_ooc_require_file {label path} {
    if {![file exists $path] || [file size $path] == 0} {
        error "SPADMIC_OOC_REQUIRED_FILE_MISSING: $label path=$path"
    }
    spadmic_ooc_status_set $label PASS
}

proc spadmic_ooc_write_mmmc {path} {
    global tech_files
    set fh [open $path w]
    puts $fh "create_constraint_mode -name tc_ooc_mode -sdc_files \[list $::spadmic_ooc_sdc\]"
    if {[info exists tech_files(CAPTABLE_TC)] && [file exists $tech_files(CAPTABLE_TC)]} {
        puts $fh "create_rc_corner -name tc_rc -temperature 25 -cap_table $tech_files(CAPTABLE_TC)"
    } else {
        puts $fh "create_rc_corner -name tc_rc -temperature 25"
    }
    puts $fh "create_library_set -name tc_libset -timing \[list $tech_files(ALL_TC_LIBS)\]"
    puts $fh "create_delay_corner -name tc_corner -library_set tc_libset -rc_corner tc_rc"
    puts $fh "create_analysis_view -name tc_view -constraint_mode tc_ooc_mode -delay_corner tc_corner"
    puts $fh "set_analysis_view -setup tc_view -hold tc_view"
    close $fh
}

proc spadmic_ooc_source_libraries {} {
    global design tech tech_files mptdc_xh018_cells
    set design(project_root) [file join $::spadmic_ooc_repo_root MPTDC]
    set design(TOPLEVEL) $::spadmic_ooc_top_module
    source [file join $::spadmic_ooc_repo_root MPTDC syn libraries libraries.xh018.tcl]
    source [file join $::spadmic_ooc_repo_root MPTDC syn libraries libraries.xh018-stdcells.tcl]
    source [file join $::spadmic_ooc_repo_root MPTDC pnr config xh018_cells.tcl]
    mptdc_xh018_validate_policy implementation
    spadmic_ooc_status_set LIBRARY_SOURCE PASS
}

proc spadmic_ooc_init_design {} {
    global tech tech_files init_top_cell init_verilog init_lef_file init_mmmc_file init_pwr_net init_gnd_net init_design_uniquify
    set mmmc [file join $::spadmic_ooc_generated_dir typical_only.mmmc]
    spadmic_ooc_write_mmmc $mmmc
    set init_top_cell $::spadmic_ooc_top_module
    set init_verilog $::spadmic_ooc_netlist
    set init_lef_file $tech_files(ALL_LEFS)
    set init_mmmc_file $mmmc
    set init_pwr_net $tech(STANDARD_CELL_VDD)
    set init_gnd_net $tech(STANDARD_CELL_GND)
    set init_design_uniquify 1
    init_design
    foreach pg_pin $tech(STANDARD_CELL_VDD_PINS) {
        catch {globalNetConnect $tech(STANDARD_CELL_VDD) -type pgpin -pin $pg_pin -inst *}
    }
    foreach pg_pin $tech(STANDARD_CELL_GND_PINS) {
        catch {globalNetConnect $tech(STANDARD_CELL_GND) -type pgpin -pin $pg_pin -inst *}
    }
    spadmic_ooc_status_set INIT_DESIGN PASS
}

proc spadmic_ooc_floorplan {} {
    set core_w [spadmic_ooc_cfg core_width_um]
    set core_h [spadmic_ooc_cfg core_height_um]
    set margin [spadmic_ooc_cfg core_margin_um]
    set site [spadmic_ooc_cfg stdcell_site]
    set cmds [list \
        [list floorPlan -site $site -s $core_w $core_h $margin $margin $margin $margin] \
        [list floorPlan -site $site -d [expr {$core_w + 2.0 * $margin}] [expr {$core_h + 2.0 * $margin}] $margin $margin $margin $margin]]
    spadmic_ooc_try_first FLOORPLAN $cmds 1
}

proc spadmic_ooc_die_size {} {
    set core_w [spadmic_ooc_cfg core_width_um]
    set core_h [spadmic_ooc_cfg core_height_um]
    set margin [spadmic_ooc_cfg core_margin_um]
    return [list [expr {$core_w + 2.0 * $margin}] [expr {$core_h + 2.0 * $margin}]]
}

proc spadmic_ooc_create_pg_pins {} {
    set layer [spadmic_ooc_cfg power_layer]
    set power_net [spadmic_ooc_cfg pg_power_net]
    set ground_net [spadmic_ooc_cfg pg_ground_net]
    set power_pin [spadmic_ooc_cfg pg_power_pin]
    set ground_pin [spadmic_ooc_cfg pg_ground_pin]
    set pg_width [spadmic_ooc_cfg pg_pin_width_um]
    set pg_depth [spadmic_ooc_cfg pg_pin_depth_um]
    lassign [spadmic_ooc_die_size] die_w die_h
    set y1 [expr {$die_h - $pg_depth - 0.5}]
    set y2 [expr {$die_h - 0.5}]
    set vdd_llx [expr {$die_w * 0.25 - $pg_width / 2.0}]
    set vdd_urx [expr {$die_w * 0.25 + $pg_width / 2.0}]
    set vss_llx [expr {$die_w * 0.75 - $pg_width / 2.0}]
    set vss_urx [expr {$die_w * 0.75 + $pg_width / 2.0}]
    spadmic_ooc_try_first CREATE_PG_PIN_VDD [list \
        [list createPGPin $power_pin -net $power_net -geom $layer $vdd_llx $y1 $vdd_urx $y2 -dir bidi] \
        [list createPGPin $power_pin -net $power_net -geom $layer $vdd_llx $y1 $vdd_urx $y2]] 1
    spadmic_ooc_try_first CREATE_PG_PIN_VSS [list \
        [list createPGPin $ground_pin -net $ground_net -geom $layer $vss_llx $y1 $vss_urx $y2 -dir bidi] \
        [list createPGPin $ground_pin -net $ground_net -geom $layer $vss_llx $y1 $vss_urx $y2]] 1
}

proc spadmic_ooc_create_pg_straps {} {
    set layer [spadmic_ooc_cfg power_layer]
    set power_net [spadmic_ooc_cfg pg_power_net]
    set ground_net [spadmic_ooc_cfg pg_ground_net]
    set strap_width [spadmic_ooc_cfg_default pg_strap_width_um [spadmic_ooc_cfg pg_pin_depth_um]]
    set strap_spacing [spadmic_ooc_cfg_default pg_strap_spacing_um $strap_width]
    lassign [spadmic_ooc_die_size] die_w die_h
    set set_distance [expr {$die_w + 20.0}]
    set vdd_offset [expr {$die_w * 0.25 - $strap_width / 2.0}]
    set vss_offset [expr {$die_w * 0.75 - $strap_width / 2.0}]
    set all_ok 1

    foreach item [list \
        [list CREATE_PG_STRAP_VDD $power_net $vdd_offset] \
        [list CREATE_PG_STRAP_VSS $ground_net $vss_offset]] {
        lassign $item label net offset
        set ok [spadmic_ooc_try_first $label [list \
            [list addStripe -nets [list $net] -layer $layer -direction vertical \
                -width $strap_width -spacing $strap_spacing -set_to_set_distance $set_distance \
                -start_from left -start_offset $offset -number_of_sets 1] \
            [list addStripe -nets [list $net] -layer $layer -direction vertical \
                -width $strap_width -spacing $strap_spacing -set_to_set_distance $set_distance \
                -start_from left -start_offset $offset]] 0]
        if {!$ok} {
            set all_ok 0
        }
    }
    spadmic_ooc_status_set CREATE_PG_STRAPS [expr {$all_ok ? "PASS" : "FAIL"}]
}

proc spadmic_ooc_route_pg {} {
    set power_net [spadmic_ooc_cfg pg_power_net]
    set ground_net [spadmic_ooc_cfg pg_ground_net]
    spadmic_ooc_create_pg_straps
    set cmds [list \
        [list sroute -connect {corePin blockPin padPin} -nets [list $power_net $ground_net] -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -padPinTarget {ring stripe} -allowLayerChange 1] \
        [list sroute -connect {corePin blockPin} -nets [list $power_net $ground_net] -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -allowLayerChange 1] \
        [list sroute -connect {corePin} -nets [list $power_net $ground_net] -corePinTarget {ring stripe} -allowLayerChange 1] \
        [list sroute -connect {padPin corePin} -nets [list $power_net $ground_net] -allowJogging 1 -layerChangeRange {MET1 METTP}] \
        [list sroute -connect {padPin corePin} -nets [list $power_net $ground_net] -allowJogging 1] \
        [list sroute -connect {blockPin padPin corePin} -nets [list $power_net $ground_net] -allowJogging 1 -layerChangeRange {MET1 METTP}] \
        [list sroute -connect {blockPin padPin corePin} -nets [list $power_net $ground_net] -allowJogging 1] \
        [list sroute -connect {blockPin corePin} -nets [list $power_net $ground_net] -allowJogging 1] \
        [list sroute -connect {blockPin corePin} -nets [list $power_net $ground_net]] \
        [list sroute -nets [list $power_net $ground_net]]]
    spadmic_ooc_try_first SROUTE_PG $cmds 1
}

proc spadmic_ooc_place_side_pins {side pins} {
    if {[llength $pins] == 0} {
        return
    }
    set layer [spadmic_ooc_cfg signal_top_layer]
    set spacing [spadmic_ooc_cfg signal_pin_spacing_um]
    set width [spadmic_ooc_cfg signal_pin_width_um]
    set depth [spadmic_ooc_cfg signal_pin_depth_um]
    set side_lc [string tolower $side]
    set label "PLACE_PINS_$side"
    set cmds [list \
        [list editPin -pin $pins -side $side -layer $layer -spreadType SIDE -spacing $spacing -pinWidth $width -pinDepth $depth -fixedPin 1] \
        [list editPin -pin $pins -side $side_lc -layer $layer -spreadType SIDE -spacing $spacing -pinWidth $width -pinDepth $depth -fixedPin 1] \
        [list editPin -pin $pins -side $side -layer $layer -spreadType SIDE -spacing $spacing] \
        [list editPin -pin $pins -side $side_lc -layer $layer -spreadType SIDE -spacing $spacing]]
    spadmic_ooc_try_first $label $cmds 1
}

proc spadmic_ooc_place_pins {} {
    spadmic_ooc_place_side_pins WEST [spadmic_ooc_cfg_list pins_west]
    spadmic_ooc_place_side_pins SOUTH [spadmic_ooc_cfg_list pins_south]
    spadmic_ooc_place_side_pins NORTH [spadmic_ooc_cfg_list pins_north]
}

proc spadmic_ooc_route_layer_setup {} {
    set bottom [spadmic_ooc_cfg signal_bottom_layer]
    set top [spadmic_ooc_cfg signal_top_layer]
    set bottom_idx [spadmic_ooc_layer_index [spadmic_ooc_env SPADMIC_OOC_SIGNAL_BOTTOM_LAYER_IDX [spadmic_ooc_cfg signal_bottom_layer_idx]] 1]
    set top_idx [spadmic_ooc_layer_index [spadmic_ooc_env SPADMIC_OOC_SIGNAL_TOP_LAYER_IDX [spadmic_ooc_cfg signal_top_layer_idx]] 3]
    catch {setDesignMode -bottomRoutingLayer $bottom -topRoutingLayer $top}
    catch {setNanoRouteMode -routeBottomRoutingLayer $bottom_idx}
    catch {setNanoRouteMode -routeTopRoutingLayer $top_idx}
    spadmic_ooc_status_set ROUTE_LAYER_SETUP PASS
}

proc spadmic_ooc_place_design {} {
    set density [spadmic_ooc_cfg place_max_density]
    catch {setPlaceMode -place_global_max_density $density}
    spadmic_ooc_try_first PLACE_DESIGN [list {place_design} {placeDesign}] 1
    spadmic_ooc_capture_first [file join $::spadmic_ooc_reports_dir report_area_post_place.rpt] report_area_post_place [list {report_area} {reportArea}] 0
    catch {defOut [file join $::spadmic_ooc_outputs_dir 02_place.def]}
    catch {saveDesign [file join $::spadmic_ooc_checkpoints_dir 02_place.enc]}
}

proc spadmic_ooc_cts_design {} {
    global mptdc_xh018_cells
    if {[info exists mptdc_xh018_cells(cts_buffers)]} {
        catch {set_ccopt_property buffer_cells $mptdc_xh018_cells(cts_buffers)}
    }
    if {[info exists mptdc_xh018_cells(cts_inverters)]} {
        catch {set_ccopt_property inverter_cells $mptdc_xh018_cells(cts_inverters)}
    }
    spadmic_ooc_try_first CTS_DESIGN [list {ccopt_design} {clockDesign}] 1
    catch {timeDesign -postCTS -outDir [file join $::spadmic_ooc_reports_dir timing_post_cts]}
    catch {saveDesign [file join $::spadmic_ooc_checkpoints_dir 03_cts.enc]}
}

proc spadmic_ooc_route_design {} {
    spadmic_ooc_route_layer_setup
    spadmic_ooc_try_first ROUTE_DESIGN [list {routeDesign} {globalDetailRoute}] 1
    catch {defOut [file join $::spadmic_ooc_outputs_dir 04_route.def]}
    catch {saveDesign [file join $::spadmic_ooc_checkpoints_dir 04_route.enc]}
}

proc spadmic_ooc_add_fillers {} {
    global mptdc_xh018_cells
    if {![info exists mptdc_xh018_cells(filler)] || [llength $mptdc_xh018_cells(filler)] == 0} {
        error "SPADMIC_OOC_NO_FILLER_CELLS"
    }
    set fillers $mptdc_xh018_cells(filler)
    spadmic_ooc_try_first ADD_FILLER [list \
        [list addFiller -cell $fillers -prefix FILL] \
        [list addFiller -cell $fillers]] 1
}

proc spadmic_ooc_postroute_opt_and_timing {} {
    catch {setDelayCalMode -SIAware false}
    catch {setSIMode -separate_delta_delay_on_data false}
    spadmic_ooc_try_first POSTROUTE_OPT_DRV [list {optDesign -postRoute -drv} {optDesign -postRoute}] 0
    catch {setExtractRCMode -engine postRoute}
    catch {extractRC}
    set setup_dir [file join $::spadmic_ooc_reports_dir timing_post_route_setup]
    set hold_dir [file join $::spadmic_ooc_reports_dir timing_post_route_hold]
    catch {file mkdir $setup_dir $hold_dir}
    spadmic_ooc_try_first POSTROUTE_SETUP_TIMING [list \
        [list timeDesign -postRoute -outDir $setup_dir] \
        [list timeDesign -postRoute]] 1
    spadmic_ooc_try_first POSTROUTE_HOLD_TIMING [list \
        [list timeDesign -postRoute -hold -outDir $hold_dir] \
        [list timeDesign -postRoute -hold]] 1
    spadmic_ooc_capture_first [file join $::spadmic_ooc_reports_dir report_timing_post_route.rpt] report_timing_post_route [list {report_timing -max_paths 50} {report_timing}] 0
    spadmic_ooc_capture_first [file join $::spadmic_ooc_reports_dir report_clocks_post_route.rpt] report_clocks_post_route [list {report_clocks} {reportClockTree}] 0
    spadmic_ooc_capture_first [file join $::spadmic_ooc_reports_dir report_drv_post_route.rpt] report_drv_post_route [list {report_constraint -all_violators} {report_constraints -all_violators}] 0
}

proc spadmic_ooc_verify_reports {} {
    set drc_rpt [file join $::spadmic_ooc_reports_dir verify_drc_post_route.rpt]
    set reg_conn_rpt [file join $::spadmic_ooc_reports_dir verify_connectivity_regular.rpt]
    set pg_conn_rpt [file join $::spadmic_ooc_reports_dir verify_connectivity_pg.rpt]
    set route_rpt [file join $::spadmic_ooc_reports_dir report_route.rpt]
    spadmic_ooc_capture_first $drc_rpt verify_drc_post_route [list {verify_drc} {verifyGeometry}] 1
    spadmic_ooc_capture_first $reg_conn_rpt verify_connectivity_regular [list {verifyConnectivity -type regular} {verifyConnectivity}] 1
    spadmic_ooc_capture_first $pg_conn_rpt verify_connectivity_pg [list {verifyConnectivity -type special -nets {VDD VSS}} {verifyConnectivity -nets {VDD VSS} -type special} {verifyConnectivity -type special}] 1
    spadmic_ooc_capture_first $route_rpt report_route [list {reportRoute} {report_route}] 0
    set drc_status [spadmic_ooc_parse_drc_report $drc_rpt]
    set reg_status [spadmic_ooc_connectivity_status $reg_conn_rpt]
    set pg_status [spadmic_ooc_connectivity_status $pg_conn_rpt]
    spadmic_ooc_status_set INNOVUS_DRC_STATUS $drc_status
    spadmic_ooc_status_set REGULAR_CONNECTIVITY_STATUS $reg_status
    spadmic_ooc_status_set PG_CONNECTIVITY_STATUS $pg_status
}

proc spadmic_ooc_export_outputs {} {
    set block $::spadmic_ooc_block
    set def [file join $::spadmic_ooc_outputs_dir "${block}.def"]
    set lef [file join $::spadmic_ooc_outputs_dir "${block}.lef"]
    set abstract_lef [file join $::spadmic_ooc_outputs_dir "${block}.abstract.lef"]
    set gds [file join $::spadmic_ooc_outputs_dir "${block}.gds"]
    set routed_v [file join $::spadmic_ooc_outputs_dir "${block}.routed.v"]
    set routed_pg_v [file join $::spadmic_ooc_outputs_dir "${block}.routed.pg.v"]
    spadmic_ooc_try_first EXPORT_DEF [list [list defOut $def]] 1
    spadmic_ooc_try_first EXPORT_NETLIST [list [list saveNetlist $routed_v]] 1
    spadmic_ooc_try_first EXPORT_NETLIST_PG [list [list saveNetlist -includePowerGround $routed_pg_v]] 0
    spadmic_ooc_try_first EXPORT_LEF [list \
        [list write_lef_abstract $lef] \
        [list lefOut $lef] \
        [list write_lef $lef]] 1
    if {[file exists $lef]} {
        file copy -force $lef $abstract_lef
    }
    set stream_cmd [list streamOut $gds -libName DesignLib -units 1000 -mode ALL]
    set stream_map [spadmic_ooc_env SPADMIC_STREAMOUT_MAP_FILE ""]
    if {$stream_map ne ""} {
        lappend stream_cmd -mapFile $stream_map
    }
    spadmic_ooc_try_first EXPORT_GDS [list $stream_cmd] 1
    foreach pair [list \
        [list EXPORT_DEF_FILE $def] \
        [list EXPORT_LEF_FILE $lef] \
        [list EXPORT_ABSTRACT_LEF_FILE $abstract_lef] \
        [list EXPORT_GDS_FILE $gds] \
        [list EXPORT_NETLIST_FILE $routed_v]] {
        spadmic_ooc_require_file [lindex $pair 0] [lindex $pair 1]
    }
    catch {saveDesign [file join $::spadmic_ooc_checkpoints_dir 05_postroute_export.enc]}
}

proc spadmic_ooc_copy_handoff {} {
    set block $::spadmic_ooc_block
    set hnet [file join $::spadmic_ooc_handoff_root netlist]
    set hinv [file join $::spadmic_ooc_handoff_root innovus]
    set hrpt [file join $::spadmic_ooc_handoff_root reports]
    file mkdir $hnet $hinv $hrpt
    foreach src [list $::spadmic_ooc_netlist $::spadmic_ooc_sdc] {
        file copy -force $src [file join $hnet [file tail $src]]
    }
    foreach tail [list "${block}.def" "${block}.lef" "${block}.abstract.lef" "${block}.gds" "${block}.routed.v" "${block}.routed.pg.v"] {
        set src [file join $::spadmic_ooc_outputs_dir $tail]
        if {[file exists $src]} {
            file copy -force $src [file join $hinv $tail]
        }
    }
    foreach rpt [glob -nocomplain -directory $::spadmic_ooc_reports_dir *] {
        if {[file isfile $rpt]} {
            file copy -force $rpt [file join $hrpt [file tail $rpt]]
        }
    }
    set readme [file join $::spadmic_ooc_handoff_root README.md]
    spadmic_ooc_write_text $readme [list \
        "# SPADMIC OOC Abstract Handoff: $block" \
        "" \
        "- Block: `$block`" \
        "- Top module: `$::spadmic_ooc_top_module`" \
        "- Innovus root: `$::spadmic_ooc_block_root`" \
        "- Genus netlist: `$::spadmic_ooc_netlist`" \
        "- Genus SDC: `$::spadmic_ooc_sdc`" \
        "- Ordinary signal routing: `MET1`-`MET3`" \
        "- Power pins: one `VDD` and one `VSS` north-edge bar on `METTP`" \
        "- PVS/LVS/PEX/MMMC: deferred; this package is not `SIGNOFF_READY`." \
    ]
    spadmic_ooc_status_set HANDOFF_COPY PASS
}

proc spadmic_ooc_write_status {} {
    set path [file join $::spadmic_ooc_reports_dir ooc_harden_status.rpt]
    set result ABSTRACT_READY_FOR_TOP_REVIEW
    foreach required [list \
        LIBRARY_SOURCE INIT_DESIGN FLOORPLAN CREATE_PG_PIN_VDD CREATE_PG_PIN_VSS SROUTE_PG \
        PLACE_PINS_WEST PLACE_PINS_SOUTH PLACE_PINS_NORTH PLACE_DESIGN CTS_DESIGN ROUTE_DESIGN \
        ADD_FILLER POSTROUTE_SETUP_TIMING POSTROUTE_HOLD_TIMING EXPORT_DEF EXPORT_LEF EXPORT_GDS \
        EXPORT_DEF_FILE EXPORT_LEF_FILE EXPORT_ABSTRACT_LEF_FILE EXPORT_GDS_FILE EXPORT_NETLIST_FILE HANDOFF_COPY] {
        if {![info exists ::spadmic_ooc_status($required)] || $::spadmic_ooc_status($required) ne "PASS"} {
            set result INNOVUS_TC_OOC_REVIEW_REQUIRED
        }
    }
    foreach review_key [list INNOVUS_DRC_STATUS REGULAR_CONNECTIVITY_STATUS PG_CONNECTIVITY_STATUS] {
        if {![info exists ::spadmic_ooc_status($review_key)] || $::spadmic_ooc_status($review_key) ne "PASS"} {
            set result INNOVUS_TC_OOC_REVIEW_REQUIRED
        }
    }
    set ::spadmic_ooc_status(RESULT) $result
    set ::spadmic_ooc_status(SIGNOFF_READY) NO
    set ::spadmic_ooc_status(PVS_STATUS) DEFERRED
    set ::spadmic_ooc_status(PEX_STATUS) DEFERRED
    set ::spadmic_ooc_status(MMMC_STATUS) DEFERRED_TYPICAL_ONLY
    set ::spadmic_ooc_status(OA_IMPORT_STATUS) DEFERRED_USE_DEF_LEF_GDS_PACKAGE
    set fh [open $path w]
    foreach key [lsort [array names ::spadmic_ooc_status]] {
        puts $fh "$key=$::spadmic_ooc_status($key)"
    }
    puts $fh "BLOCK=$::spadmic_ooc_block"
    puts $fh "TOP_MODULE=$::spadmic_ooc_top_module"
    puts $fh "NETLIST=$::spadmic_ooc_netlist"
    puts $fh "SDC=$::spadmic_ooc_sdc"
    puts $fh "BLOCK_ROOT=$::spadmic_ooc_block_root"
    puts $fh "HANDOFF_ROOT=$::spadmic_ooc_handoff_root"
    puts $fh "LAYOUT_AUDIT_DIR=[spadmic_ooc_cfg layout_audit_dir]"
    puts $fh "PIN_PLAN_CSV=[spadmic_ooc_cfg pin_plan_csv]"
    close $fh
}

proc spadmic_ooc_main {} {
    spadmic_ooc_require_file GENUS_NETLIST_INPUT $::spadmic_ooc_netlist
    spadmic_ooc_require_file GENUS_SDC_INPUT $::spadmic_ooc_sdc
    spadmic_ooc_source_libraries
    spadmic_ooc_init_design
    spadmic_ooc_floorplan
    spadmic_ooc_place_pins
    spadmic_ooc_route_layer_setup
    spadmic_ooc_create_pg_pins
    spadmic_ooc_place_design
    spadmic_ooc_cts_design
    spadmic_ooc_add_fillers
    spadmic_ooc_route_design
    spadmic_ooc_route_pg
    spadmic_ooc_postroute_opt_and_timing
    spadmic_ooc_verify_reports
    spadmic_ooc_export_outputs
    spadmic_ooc_copy_handoff
    spadmic_ooc_write_status
}

if {[catch {spadmic_ooc_main} err opts]} {
    spadmic_ooc_status_set RESULT FAIL
    spadmic_ooc_status_set FIRST_ERROR $err
    set error_rpt [file join $::spadmic_ooc_reports_dir ooc_harden_error.rpt]
    set fh [open $error_rpt w]
    puts $fh "ERROR=$err"
    puts $fh "OPTIONS=$opts"
    close $fh
    spadmic_ooc_write_status
    error $err
}

exit
