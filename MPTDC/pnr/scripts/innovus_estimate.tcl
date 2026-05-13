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
# signal routing on MET1-MET3 by default, and reserves METTP for VDD/VSS/top-level
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

proc mptdc_pnr_capture_report {report_file title body} {
    if {[catch {uplevel 1 "$body > \"$report_file\""} err]} {
        set fh [open $report_file w]
        puts $fh "$title"
        puts $fh [string repeat "=" [string length $title]]
        puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
        puts $fh ""
        puts $fh "FAILED:"
        puts $fh $err
        close $fh
        puts "MPTDC_PNR_WARN: $title failed: $err"
    }
}

proc mptdc_pnr_generate_extra_reports {} {
    global pnr design

    set extra_dir "$pnr(reports_dir)/prects"
    file mkdir $extra_dir

    mptdc_pnr_capture_report "$extra_dir/extra_check_place.rpt" \
        "MPTDC extra checkPlace" {checkPlace}
    mptdc_pnr_capture_report "$extra_dir/extra_check_design_all.rpt" \
        "MPTDC extra checkDesign -all" {checkDesign -all}
    mptdc_pnr_capture_report "$extra_dir/extra_report_timing_100.rpt" \
        "MPTDC extra report_timing max_paths 100" {report_timing -max_paths 100}
    mptdc_pnr_capture_report "$extra_dir/extra_report_timing_full_clock.rpt" \
        "MPTDC extra report_timing full_clock" {report_timing -max_paths 50 -path_type full_clock}
    mptdc_pnr_capture_report "$extra_dir/extra_report_constraint.rpt" \
        "MPTDC extra report_constraint all violators" {report_constraint -all_violators}
    mptdc_pnr_capture_report "$extra_dir/extra_report_congestion.rpt" \
        "MPTDC extra reportCongestion" {reportCongestion}
    mptdc_pnr_capture_report "$extra_dir/extra_report_density.rpt" \
        "MPTDC extra reportDensity" {reportDensity}
    mptdc_pnr_capture_report "$extra_dir/extra_report_netlist_stats.rpt" \
        "MPTDC extra reportGateCount" {reportGateCount -level 20}
    mptdc_pnr_capture_report "$extra_dir/extra_report_power_hier.rpt" \
        "MPTDC extra report_power hierarchy" {report_power -hierarchy all}

    set audit_file "$extra_dir/extra_pd_reset_audit.rpt"
    set fh [open $audit_file w]
    puts $fh "MPTDC extra PD/reset audit"
    puts $fh "=========================="
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    set patterns $pnr(pd_instance_patterns)
    foreach pattern $patterns {
        set cells [mptdc_pnr_collect_cells [list $pattern]]
        puts $fh "Pattern $pattern matched [llength $cells] cells"
        foreach cell $cells {
            puts $fh "  $cell"
        }
        puts $fh ""
    }
    set rst_cells [mptdc_pnr_collect_cells [list "*u_rst*sync*"]]
    puts $fh "Reset sync cells matched [llength $rst_cells]"
    foreach cell $rst_cells {
        puts $fh "  $cell"
    }
    close $fh
}

proc mptdc_pnr_object_names {objects} {
    set names [list]

    if {[llength $objects] == 0} {
        return $names
    }

    if {![catch {get_object_name $objects} obj_names]} {
        foreach name $obj_names {
            lappend names $name
        }
        return $names
    }

    if {![catch {get_db $objects .name} obj_names]} {
        foreach name $obj_names {
            lappend names $name
        }
        return $names
    }

    foreach obj $objects {
        lappend names $obj
    }
    return $names
}

proc mptdc_pnr_collect_cells {patterns} {
    set matches [list]
    foreach pattern $patterns {
        set cells [list]
        if {[catch {get_cells -hierarchical -quiet $pattern} cells]} {
            if {[catch {get_cells -hier $pattern} cells]} {
                set cells [list]
            }
        }
        foreach cell [mptdc_pnr_object_names $cells] {
            if {[lsearch -exact $matches $cell] < 0} {
                lappend matches $cell
            }
        }
    }
    return $matches
}

proc mptdc_pnr_core_box {} {
    set core_box [list]
    if {[catch {dbGet top.fPlan.coreBox} core_box]} {
        if {[catch {dbGet top.fPlan.box} core_box]} {
            return [list]
        }
    }
    if {[llength $core_box] == 1} {
        set core_box [lindex $core_box 0]
    }
    return $core_box
}

proc mptdc_pnr_prepare_pd_symmetry {} {
    global pnr

    set report_file "$pnr(reports_dir)/pd_matrix_symmetry.rpt"
    set cells [mptdc_pnr_collect_cells $pnr(pd_instance_patterns)]
    set fh [open $report_file w]
    puts $fh "MPTDC phase-detector matrix symmetry prep"
    puts $fh "========================================"
    puts $fh "Rows x cols target: $pnr(pd_rows) x $pnr(pd_cols)"
    puts $fh "Instance patterns: $pnr(pd_instance_patterns)"
    puts $fh "Matched instances found: [llength $cells]"
    foreach cell $cells {
        puts $fh "  $cell"
    }

    if {[llength $cells] == 0} {
        puts $fh "Status: no PD instances matched after synthesis; no group/region created."
        close $fh
        return
    }

    if {$pnr(pd_symmetry_create_group)} {
        if {[catch {createInstGroup $pnr(pd_symmetry_group)} err]} {
            puts $fh "Group create warning: $err"
        } else {
            puts $fh "Group created: $pnr(pd_symmetry_group)"
        }
        foreach cell $cells {
            if {[catch {addInstToInstGroup $pnr(pd_symmetry_group) $cell} err]} {
                puts $fh "Group add warning for $cell: $err"
            }
        }
    }

    if {$pnr(pd_symmetry_create_region)} {
        set core_box [mptdc_pnr_core_box]
        puts $fh "Core box: $core_box"
        if {[llength $core_box] >= 4} {
            set margin $pnr(pd_region_margin_um)
            set llx [expr {[lindex $core_box 0] + $margin}]
            set lly [expr {[lindex $core_box 1] + $margin}]
            set urx [expr {[lindex $core_box 2] - $margin}]
            set ury [expr {[lindex $core_box 3] - $margin}]
            if {($urx > $llx) && ($ury > $lly)} {
                if {[catch {createRegion $pnr(pd_symmetry_group) $llx $lly $urx $ury} err]} {
                    puts $fh "Region create warning: $err"
                } else {
                    puts $fh "Region created for $pnr(pd_symmetry_group): $llx $lly $urx $ury"
                }
            } else {
                puts $fh "Region skipped: core box too small for margin $margin"
            }
        } else {
            puts $fh "Region skipped: unable to read Innovus core box"
        }
    }

    puts $fh "Note: final symmetry and matched-RC constraints still require oscillator/PD macro LEFs and extracted routing rules."
    close $fh
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

foreach stale_path [list \
    "$pnr(reports_dir)/prects" \
    "$pnr(reports_dir)/postroute" \
    "$pnr(reports_dir)/run_manifest.rpt" \
    "$pnr(reports_dir)/run_status.rpt" \
    "$pnr(reports_dir)/pd_matrix_symmetry.rpt" \
    "$pnr(reports_dir)/report_area_place.rpt" \
    "$pnr(reports_dir)/report_gate_count_place.rpt" \
    "$pnr(reports_dir)/report_power_place.rpt" \
    "$pnr(outputs_dir)/$design(TOPLEVEL).place.enc"] {
    file delete -force $stale_path
}

set status_fh [open "$pnr(reports_dir)/run_status.rpt" w]
puts $status_fh "MPTDC Innovus estimate status"
puts $status_fh "============================"
puts $status_fh "Status: INCOMPLETE"
puts $status_fh "Started: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
puts $status_fh "Script: [file normalize [info script]]"
close $status_fh

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
    foreach pg_pin $tech(STANDARD_CELL_VDD_PINS) {
        mptdc_pnr_optional "Connecting $tech(STANDARD_CELL_VDD) to PG pin $pg_pin" {
            globalNetConnect $tech(STANDARD_CELL_VDD) -type pgpin -pin $pg_pin -inst *
        }
    }
    foreach pg_pin $tech(STANDARD_CELL_GND_PINS) {
        mptdc_pnr_optional "Connecting $tech(STANDARD_CELL_GND) to PG pin $pg_pin" {
            globalNetConnect $tech(STANDARD_CELL_GND) -type pgpin -pin $pg_pin -inst *
        }
    }
} else {
    mptdc_pnr_msg "Skipping explicit globalNetConnect because MPTDC_PNR_CONNECT_PG_PINS=0"
}

set margin $pnr(core_margin_um)
mptdc_pnr_required "Creating compact area-first floorplan" {
    floorPlan -site $tech(STANDARD_CELL_SITE) -r \
        $pnr(aspect_ratio) $pnr(core_utilization) \
        $margin $margin $margin $margin
}

mptdc_pnr_optional "Preparing phase-detector symmetry placement hooks" {
    if {$pnr(pd_symmetry_enable)} {
        mptdc_pnr_prepare_pd_symmetry
    } else {
        mptdc_pnr_msg "Skipping PD symmetry prep because MPTDC_PNR_PD_SYMMETRY_ENABLE=0"
    }
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

mptdc_pnr_optional "Running post-place pre-CTS timing/DRV optimization" {
    if {$pnr(do_prects_opt)} {
        optDesign -preCTS
    } else {
        mptdc_pnr_msg "Skipping pre-CTS optimization because MPTDC_PNR_DO_PRECTS_OPT=0"
    }
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

mptdc_pnr_optional "Generating extra closure reports" {
    mptdc_pnr_generate_extra_reports
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
if {[info exists tech(STANDARD_CELL_VDD_PINS)]} {
    puts $fh "VDD PG pin candidates: $tech(STANDARD_CELL_VDD_PINS)"
}
if {[info exists tech(STANDARD_CELL_GND_PINS)]} {
    puts $fh "VSS PG pin candidates: $tech(STANDARD_CELL_GND_PINS)"
}
puts $fh "Expected routing directions: MET1=$pnr(route_dir_MET1), MET2=$pnr(route_dir_MET2), MET3=$pnr(route_dir_MET3), METTP=$pnr(route_dir_METTP)"
puts $fh "PD symmetry prep enabled: $pnr(pd_symmetry_enable)"
puts $fh "PD target grid: $pnr(pd_rows)x$pnr(pd_cols)"
puts $fh "PD group: $pnr(pd_symmetry_group)"
puts $fh "PD instance patterns: $pnr(pd_instance_patterns)"
puts $fh "PD region margin um: $pnr(pd_region_margin_um)"
puts $fh "Pre-CTS opt enabled: $pnr(do_prects_opt)"
puts $fh "Detail route enabled: $pnr(do_detail_route)"
puts $fh "Netlist: $design(postsyn_netlist)"
puts $fh "SDC: $design(postsyn_sdc)"
puts $fh "MMMC: $init_mmmc_file"
puts $fh "LEF: $tech_files(ALL_LEFS)"
close $fh

set status_fh [open "$pnr(reports_dir)/run_status.rpt" w]
puts $status_fh "MPTDC Innovus estimate status"
puts $status_fh "============================"
puts $status_fh "Status: COMPLETE"
puts $status_fh "Completed: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
puts $status_fh "Script: [file normalize [info script]]"
puts $status_fh "Top: $design(TOPLEVEL)"
puts $status_fh "Netlist: $design(postsyn_netlist)"
puts $status_fh "MMMC: $init_mmmc_file"
puts $status_fh "Pre-CTS summary: $pnr(reports_dir)/prects/${design(TOPLEVEL)}_preCTS.summary.gz"
close $status_fh

mptdc_pnr_msg "Innovus estimate complete"
