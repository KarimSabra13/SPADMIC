# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : innovus_estimate.tcl
# Purpose  : First-pass Innovus floorplan/place estimate for area/timing/power
# =============================================================================
#
# Usage:
#   cd MPTDC/pnr/scripts
#   innovus -nowin -init innovus_estimate.tcl -log ../logs/innovus_estimate.log
#
# This is an estimation flow, not a signoff PnR recipe. It starts from the
# Genus post-synthesis netlist/SDC, uses the same XH018 1P4M collateral, keeps
# signal routing on M1-M3 by default, and reserves M4 for VDD/VSS/top-level
# power distribution as much as practical.
# =============================================================================

proc mptdc_pnr_msg {msg} {
    puts "MPTDC_PNR: $msg"
}

proc mptdc_pnr_required {label body} {
    mptdc_pnr_msg $label
    if {[catch {uplevel 1 $body} err]} {
        puts "MPTDC_PNR_ERROR: $label failed"
        puts $err
        exit 1
    }
}

proc mptdc_pnr_optional {label body} {
    mptdc_pnr_msg $label
    if {[catch {uplevel 1 $body} err]} {
        puts "MPTDC_PNR_WARN: $label skipped: $err"
    }
}

set script_dir [file dirname [file normalize [info script]]]
set pnr_root   [file dirname $script_dir]
set mptdc_root [file dirname $pnr_root]
set syn_root   "$mptdc_root/syn"
set runtype    "pnr"

source "$syn_root/inputs/mptdc.defines"
source "$syn_root/libraries/libraries.$TECHNOLOGY.tcl"
source "$syn_root/libraries/libraries.$SC_TECHNOLOGY.tcl"
source "$pnr_root/inputs/mptdc_pnr_config.tcl"

set pnr(work_dir)    "$pnr_root/work"
set pnr(outputs_dir) "$pnr_root/outputs"
set pnr(reports_dir) "$pnr_root/reports"
set pnr(logs_dir)    "$pnr_root/logs"

foreach dir [list $pnr(work_dir) $pnr(outputs_dir) $pnr(reports_dir) $pnr(logs_dir)] {
    file mkdir $dir
}

if {![file exists $design(postsyn_netlist)]} {
    puts "MPTDC_PNR_ERROR: missing Genus netlist: $design(postsyn_netlist)"
    puts "Run MPTDC/syn/scripts/genus.tcl first."
    exit 1
}

if {![file exists $design(postsyn_sdc)]} {
    puts "MPTDC_PNR_ERROR: missing Genus SDC: $design(postsyn_sdc)"
    puts "Run MPTDC/syn/scripts/genus.tcl first."
    exit 1
}

set init_top_cell  $design(TOPLEVEL)
set init_verilog   $design(postsyn_netlist)
set init_lef_file  $tech_files(ALL_LEFS)
set init_mmmc_file "$pnr_root/inputs/mptdc_innovus.mmmc"
set init_pwr_net   $tech(STANDARD_CELL_VDD)
set init_gnd_net   $tech(STANDARD_CELL_GND)

mptdc_pnr_required "Initializing Innovus design" {
    init_design
}

if {$pnr(connect_pg_pins)} {
    mptdc_pnr_optional "Connecting standard-cell power pins" {
        globalNetConnect $tech(STANDARD_CELL_VDD) -type pgpin -pin $tech(STANDARD_CELL_VDD) -inst *
        globalNetConnect $tech(STANDARD_CELL_GND) -type pgpin -pin $tech(STANDARD_CELL_GND) -inst *
    }
} else {
    mptdc_pnr_msg "Skipping explicit globalNetConnect by default; set MPTDC_PNR_CONNECT_PG_PINS=1 after confirming PG pin names"
}

set margin $pnr(core_margin_um)
mptdc_pnr_required "Creating compact area-first floorplan" {
    floorPlan -site $tech(STANDARD_CELL_SITE) -r \
        $pnr(aspect_ratio) $pnr(core_utilization) \
        $margin $margin $margin $margin
}

mptdc_pnr_optional "Limiting signal route layers to preserve top metal for power" {
    setNanoRouteMode -routeBottomRoutingLayer $pnr(signal_bottom_layer_idx)
    setNanoRouteMode -routeTopRoutingLayer    $pnr(signal_top_layer_idx)
}

mptdc_pnr_optional "Applying placement density target" {
    setPlaceMode -place_global_max_density $pnr(place_global_max_density)
}

mptdc_pnr_required "Running pre-CTS placement" {
    placeDesign
}

mptdc_pnr_optional "Generating pre-CTS timing reports" {
    timeDesign -preCTS -outDir "$pnr(reports_dir)/prects"
}

mptdc_pnr_optional "Generating placed area report" {
    report_area > "$pnr(reports_dir)/report_area_place.rpt"
}

mptdc_pnr_optional "Generating placed gate-count report" {
    reportGateCount -level 10 > "$pnr(reports_dir)/report_gate_count_place.rpt"
}

mptdc_pnr_optional "Generating vectorless power report" {
    report_power > "$pnr(reports_dir)/report_power_place.rpt"
}

if {$pnr(do_detail_route)} {
    mptdc_pnr_optional "Running detail route estimate" {
        routeDesign
    }
    mptdc_pnr_optional "Generating post-route timing reports" {
        timeDesign -postRoute -outDir "$pnr(reports_dir)/postroute"
    }
}

mptdc_pnr_required "Saving placed Innovus database" {
    saveDesign "$pnr(outputs_dir)/$design(TOPLEVEL).place.enc"
}

set fh [open "$pnr(reports_dir)/run_manifest.rpt" w]
puts $fh "MPTDC Innovus estimate manifest"
puts $fh "==============================="
puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
puts $fh "Top: $design(TOPLEVEL)"
puts $fh "Optimization goal: $pnr(optimization_goal)"
puts $fh "Metal stack: $pnr(metal_stack)"
puts $fh "Core utilization: $pnr(core_utilization)"
puts $fh "Placement max density: $pnr(place_global_max_density)"
puts $fh "Aspect ratio: $pnr(aspect_ratio)"
puts $fh "Core margin um: $pnr(core_margin_um)"
puts $fh "Signal routing layers: $pnr(signal_bottom_layer)-$pnr(signal_top_layer)"
puts $fh "Signal routing layer indexes: $pnr(signal_bottom_layer_idx)-$pnr(signal_top_layer_idx)"
puts $fh "Reserved power layer: $pnr(power_reserved_layer)"
puts $fh "Explicit PG pin connect enabled: $pnr(connect_pg_pins)"
puts $fh "Expected routing directions: M1=$pnr(route_dir_M1), M2=$pnr(route_dir_M2), M3=$pnr(route_dir_M3), M4=$pnr(route_dir_M4)"
puts $fh "Detail route enabled: $pnr(do_detail_route)"
puts $fh "Netlist: $design(postsyn_netlist)"
puts $fh "SDC: $design(postsyn_sdc)"
puts $fh "MMMC: $init_mmmc_file"
puts $fh "LEF: $tech_files(ALL_LEFS)"
close $fh

mptdc_pnr_msg "Innovus estimate complete"
