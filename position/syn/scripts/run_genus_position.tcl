# =============================================================================
# Project  : SPADMIC Position Block
# File     : run_genus_position.tcl
# Purpose  : Out-of-context Cadence Genus synthesis for spadmic_position_block.
# =============================================================================
#
# Usage:
#   cd position/syn/scripts
#   genus -files run_genus_position.tcl -log ../logs/genus_position.log
#
# Intent:
#   - XFAB XH018 D_CELLS_HD typical corner only.
#   - Physical-aware synthesis with the available digital stack restricted to
#     MET1, MET2, MET3, and METTP.
#   - OOC area/timing estimate for the async position capture, two-cycle scanner,
#     frame FIFO, CSR/status, and 8-word/14-word packetizer.
# =============================================================================

set runtype "synthesis"

set script_dir    [file dirname [file normalize [info script]]]
set syn_root      [file normalize "$script_dir/.."]
set position_root [file normalize "$syn_root/.."]
set repo_root     [file normalize "$position_root/.."]

set design(TOPLEVEL)      "spadmic_position_block"
set design(sdc_file)      "$syn_root/inputs/spadmic_position.sdc"
set design(work_dir)      "$syn_root/work"
set design(reports_dir)   "$syn_root/reports"
set design(outputs_dir)   "$syn_root/outputs"
set design(logs_dir)      "$syn_root/logs"
set design(project_root)  "$repo_root/MPTDC"

set TECHNOLOGY     "xh018"
set SC_TECHNOLOGY  "xh018-stdcells"

foreach dir [list $design(work_dir) $design(reports_dir) $design(outputs_dir) $design(logs_dir)] {
    file mkdir $dir
}
foreach dir [list \
    "$design(reports_dir)/elaboration" \
    "$design(reports_dir)/timing" \
    "$design(reports_dir)/qor" \
    "$design(outputs_dir)/post_elaboration" \
    "$design(outputs_dir)/post_synth"] {
    file mkdir $dir
}

proc position_msg {msg} {
    puts "SPADMIC_POSITION_GENUS: $msg"
}

proc position_try_set_db {attr value} {
    if {[catch {set_db $attr $value} err]} {
        puts "SPADMIC_POSITION_GENUS_WARN: set_db $attr $value failed: $err"
    }
}

proc position_layer_id {layer_name} {
    global tech

    set layer_obj [list]
    foreach query [list \
        [list get_db layers -if ".name == $layer_name"] \
        [list get_db layers -if ".base_name == $layer_name"] \
    ] {
        if {![catch {{*}$query} matches] && [llength $matches] > 0} {
            set layer_obj [lindex $matches 0]
            break
        }
    }

    if {[llength $layer_obj] > 0} {
        foreach attr [list .routing_level .level .number] {
            if {![catch {set value [get_db $layer_obj $attr]}] && [string is integer -strict $value]} {
                return $value
            }
        }
    }

    if {[info exists tech(layer_names)]} {
        set idx [lsearch -exact $tech(layer_names) $layer_name]
        if {$idx >= 0} {
            return [expr {$idx + 1}]
        }
    }

    error "Unable to resolve routing-layer ID for $layer_name"
}

proc position_apply_routing_limits {} {
    set bottom_id [position_layer_id MET1]
    set top_id    [position_layer_id METTP]

    foreach {attr value} [list \
        route_bottom_routing_layer           $bottom_id \
        route_top_routing_layer              $top_id \
        route_bottom_preferred_routing_layer $bottom_id \
        route_top_preferred_routing_layer    $top_id \
        ple_bottom_routing_layer             $bottom_id \
        ple_top_routing_layer                $top_id \
    ] {
        position_try_set_db $attr $value
    }
}

proc position_run_report {cmd path} {
    if {[catch {eval $cmd > $path} result]} {
        set fh [open $path w]
        puts $fh "Command failed: $cmd"
        puts $fh $result
        close $fh
        puts "SPADMIC_POSITION_GENUS_WARN: report command failed: $cmd"
    }
}

position_msg "Starting OOC synthesis for $design(TOPLEVEL)"
position_msg "Repository root: $repo_root"

# Technology and standard-cell library definitions are reused from the verified
# MPTDC flow so the position OOC run stays aligned with the top-level backend.
source "$repo_root/MPTDC/syn/libraries/libraries.$TECHNOLOGY.tcl"
source "$repo_root/MPTDC/syn/libraries/libraries.$SC_TECHNOLOGY.tcl"

# Genus/PLE physical context.  The selected XH018 tech LEF is the 4-metal HD
# stack; keep the estimator bounded to MET1/MET2/MET3/METTP so it does not assume
# unavailable upper routing resources.
position_try_set_db design_process_node 180

# Typical-only MMMC view.  This prototype run intentionally avoids WC/BC setup
# optimization so area is not bloated by slow-corner drive sizing.
create_library_set -name tc_libset -timing $tech_files(ALL_TC_LIBS)
if {[info exists tech(HAS_QRC_TECH)] && $tech(HAS_QRC_TECH)} {
    create_rc_corner -name tc_rc \
        -temperature $tech(TEMPERATURE_TC) \
        -qrc_tech $tech_files(QRCTECH_TC)
} else {
    create_rc_corner -name tc_rc \
        -temperature $tech(TEMPERATURE_TC)
}
create_timing_condition -name tc_cond -library_sets tc_libset
create_delay_corner -name tc_corner \
    -timing_condition tc_cond \
    -rc_corner tc_rc
create_constraint_mode -name functional_mode \
    -sdc_files $design(sdc_file)
create_analysis_view -name tc_view \
    -constraint_mode functional_mode \
    -delay_corner tc_corner
set_analysis_view -setup tc_view -hold tc_view

set available_lefs [list]
foreach lef_file $tech_files(ALL_LEFS) {
    if {[file exists $lef_file]} {
        lappend available_lefs $lef_file
    } else {
        position_msg "LEF not found, skipping: $lef_file"
    }
}
if {[llength $available_lefs] > 0} {
    position_msg "Reading physical LEF abstracts"
    read_physical -lef $available_lefs
    position_apply_routing_limits
} else {
    position_msg "No LEF abstracts found; continuing without physical-aware synthesis"
}

set design(rtl_files) [list \
    "$repo_root/MPTDC/rtl/pkg/mptdc_pkg.sv" \
    "$repo_root/MPTDC/rtl/cdc/mptdc_sync_fifo.sv" \
    "$repo_root/TOP/rtl/spadmic_pkg.sv" \
    "$position_root/rtl/spadmic_axis_cluster_scan.sv" \
    "$position_root/rtl/spadmic_position_block.sv" \
]

set_db init_hdl_search_path [list \
    "$repo_root/MPTDC/rtl/pkg" \
    "$repo_root/MPTDC/rtl/cdc" \
    "$repo_root/TOP/rtl" \
    "$position_root/rtl" \
]

position_msg "Reading RTL"
foreach rtl_file $design(rtl_files) {
    if {![file exists $rtl_file]} {
        error "RTL file not found: $rtl_file"
    }
    read_hdl -sv $rtl_file
}

position_msg "Elaborating $design(TOPLEVEL)"
elaborate $design(TOPLEVEL)

position_msg "Checking design before init"
check_design -unresolved
position_run_report "check_design -all" \
    "$design(reports_dir)/elaboration/check_design_post_elab.rpt"
position_run_report "report_hierarchy" \
    "$design(reports_dir)/elaboration/report_hierarchy_post_elab.rpt"

position_msg "Initializing typical analysis view"
init_design

# Repeat routing-layer limits after init_design because some Genus versions only
# expose routing attributes once the design and physical views are initialized.
position_apply_routing_limits

position_msg "Linting timing intent"
position_run_report "check_timing_intent -verbose" \
    "$design(reports_dir)/timing/check_timing_intent.rpt"
position_run_report "report_clocks" \
    "$design(reports_dir)/timing/report_clocks.rpt"
position_run_report "report_timing -max_paths 25" \
    "$design(reports_dir)/timing/report_timing_pre_synth.rpt"

write_design -base_name "$design(outputs_dir)/post_elaboration/$design(TOPLEVEL)"

# Prototype block has no scan chain; avoid scan flops if the loaded library has
# scan-capable sequential cells.
if {[catch {
    foreach cell [get_db lib_cells -if {.scan_enable_pins!=""}] {
        set_db $cell .avoid true
    }
} err]} {
    position_msg "Scan-cell avoidance skipped or unsupported: $err"
}

# Keep the explicit structural synchronizer chain recognizable through mapping.
foreach pattern {
    *x_sync_ff1_q* *x_sync_ff2_q*
    *y_sync_ff1_q* *y_sync_ff2_q*
    *z_sync_ff1_q* *z_sync_ff2_q*
} {
    set sync_cells [get_cells -quiet -hierarchical $pattern]
    if {[llength $sync_cells] > 0} {
        catch {set_dont_touch $sync_cells true}
        catch {set_db $sync_cells .preserve true}
    }
}

position_msg "Running syn_generic"
syn_generic
position_run_report "report_timing -max_paths 25" \
    "$design(reports_dir)/timing/report_timing_post_generic.rpt"

position_msg "Running syn_map"
syn_map
position_run_report "report_timing -max_paths 25" \
    "$design(reports_dir)/timing/report_timing_post_map.rpt"

position_msg "Running syn_opt"
syn_opt

position_msg "Writing reports"
position_run_report "report_qor" \
    "$design(reports_dir)/qor/report_qor.rpt"
position_run_report "report_area" \
    "$design(reports_dir)/qor/report_area.rpt"
position_run_report "report_area -hierarchy" \
    "$design(reports_dir)/qor/report_area_hierarchy.rpt"
position_run_report "report_power" \
    "$design(reports_dir)/qor/report_power.rpt"
position_run_report "report_timing -max_paths 50" \
    "$design(reports_dir)/timing/report_timing_post_synth.rpt"
position_run_report "report_design_rules" \
    "$design(reports_dir)/qor/report_design_rules.rpt"

position_msg "Exporting post-synthesis collateral"
write_netlist > "$design(outputs_dir)/spadmic_position_block.postsyn.v"
write_sdc -view tc_view > "$design(outputs_dir)/spadmic_position_block.postsyn.sdc"
write_sdf > "$design(outputs_dir)/spadmic_position_block.postsyn.sdf"
write_design -base_name "$design(outputs_dir)/post_synth/$design(TOPLEVEL)" -innovus

position_msg "Done"
