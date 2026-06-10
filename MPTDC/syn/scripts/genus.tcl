# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : genus.tcl
# Purpose  : Main Genus synthesis entry point — complete flow in one script
# Author   : Karim Sabra
# =============================================================================
# Usage:
#   cd syn/scripts
#   mkdir -p ../logs
#   genus -files genus.tcl -log ../logs/genus.log
#
# Or interactively:
#   genus
#   genus> source genus.tcl
#
# This script orchestrates the full synthesis flow:
#   1. Load design definitions and library configurations
#   2. Read MMMC (Multi-Mode Multi-Corner) view definitions
#   3. Read LEF physical abstracts
#   4. Read RTL and elaborate
#   5. Run design checks (lint)
#   6. Synthesize (generic → map → optimize)
#   7. Generate comprehensive reports
#   8. Export netlist, SDC, SDF, and database
# =============================================================================

set runtype "synthesis"
set script_dir [file dirname [file normalize [info script]]]
set syn_dir [file dirname $script_dir]

puts "================================================================"
puts " MPTDC — Cadence Genus Logic Synthesis"
puts " Target: XFAB XH018 (180 nm)"
puts " Design: mptdc_top_asic"
puts "================================================================"

set debug_file [file join [pwd] "debug.txt"]

#############################################
# 1. LOAD DEFINITIONS AND LIBRARIES
#############################################

# Helper procedures (must be loaded first — defines mptdc_message, etc.)
source "$script_dir/procedures.tcl"

mptdc_start_stage "init"

# Design-specific variables (ports, clocks, paths, SDC params)
mptdc_message "Loading design definitions"
source "$syn_dir/inputs/mptdc.defines"

# Technology and standard cell library paths
mptdc_message "Loading XFAB XH018 PDK definitions"
source "$syn_dir/libraries/libraries.$TECHNOLOGY.tcl"
source "$syn_dir/libraries/libraries.$SC_TECHNOLOGY.tcl"

# General Genus settings (effort, ramstyle, clock gating)
source "$script_dir/settings.tcl"

# Create output directories
foreach dir [list $design(work_dir) $design(export_dir) \
             $design(reports_dir) $design(logs_dir) \
             $design(synthesis_reports)] {
    file mkdir $dir
}
mptdc_write_helper_tcl_selftest "$design(reports_dir)/helper_tcl_selftest.rpt"
mptdc_message "Using Genus work directory $design(work_dir)"
cd $design(work_dir)

# Suppress known benign messages
if {[llength $design(SUPPRESS_MESSAGES_GENUS)] > 0} {
    mptdc_message "Suppressing known messages"
    suppress_messages $design(SUPPRESS_MESSAGES_GENUS)
}
if {[llength $tech(LIB_SUPPRESS_MESSAGES_GENUS)] > 0} {
    suppress_messages $tech(LIB_SUPPRESS_MESSAGES_GENUS)
}

#############################################
# 2. READ MMMC
#############################################
mptdc_start_stage "mmmc"

mptdc_message "Loading MMMC view definitions"
read_mmmc $design(mmmc_view_file)

#############################################
# 3. READ LEF (physical abstracts)
#############################################
# LEF gives Genus physical awareness for better optimization.
# Suppress LEF-specific messages.
if {[llength $tech(LEF_SUPPRESS_MESSAGES_GENUS)] > 0} {
    suppress_messages $tech(LEF_SUPPRESS_MESSAGES_GENUS)
}

mptdc_message "Loading LEF physical abstracts"
set available_lefs [list]
foreach lef_file $tech_files(ALL_LEFS) {
    if {[file exists $lef_file]} {
        lappend available_lefs $lef_file
    }
}
if {[llength $available_lefs] > 0} {
    read_physical -lef $available_lefs
} else {
    mptdc_message "No LEF abstracts found; continuing without physical-aware synthesis" high
}

#############################################
# 4. READ RTL
#############################################
mptdc_start_stage "read_rtl"

## read_hdl resolves filelist entries from the current working directory.
## The checked-in filelist uses paths relative to syn/, so switch there first.
mptdc_message "Switching to $design(syn_root) for HDL filelist resolution"
cd $design(syn_root)

set_db init_hdl_search_path $design(hdl_search_paths)

mptdc_message "Reading RTL from [file tail $design(read_hdl_list)]"
mptdc_message "  Filelist: $design(read_hdl_list)"
read_hdl -sv -f $design(read_hdl_list)
cd $design(work_dir)

#############################################
# 5. ELABORATE
#############################################
mptdc_start_stage "elaborate"

mptdc_message "Elaborating $design(TOPLEVEL) ..."
elaborate $design(TOPLEVEL)

# ── Post-Elaboration Checks ──────────────────────────────────────
mptdc_start_stage "post_elaboration"

mptdc_message "Running design checks"
check_design -unresolved
check_design -all > "$design(synthesis_reports)/post_elaboration/check_design.rpt"

# Init design (applies MMMC constraints)
mptdc_message "Initializing design with MMMC constraints"
init_design

# Check timing intent (SDC lint)
mptdc_message "Checking timing intent (SDC lint)"
check_timing_intent
check_timing_intent -verbose > \
    "$design(synthesis_reports)/post_elaboration/check_timing_intent.rpt"
mptdc_run_report "report_clocks" \
    "$design(synthesis_reports)/post_elaboration/report_clocks.rpt" \
    "post-init clock report"
mptdc_run_report_candidates [list \
    "check_timing -verbose" \
    "check_timing" \
    "check_timing_intent -verbose" \
    "check_timing_intent" \
] "$design(synthesis_reports)/post_elaboration/check_timing_post_init.rpt" \
    "post-init timing coverage check"

# Preserve hierarchy that has physical meaning before optimization can flatten
# it away: local reset synchronizer leaves and the future-matched PD matrix.
mptdc_preserve_physical_hierarchy

# Hierarchy and latch reports
report_hierarchy > "$design(synthesis_reports)/post_elaboration/report_hierarchy.rpt"
mptdc_write_latch_report \
    "$design(synthesis_reports)/post_elaboration/latch_pre_synth.rpt"

# Save elaborated design checkpoint
mptdc_message "Saving elaborated design checkpoint"
write_design -base_name "$design(export_dir)/post_elaboration/$design(TOPLEVEL)"

#############################################
# 6. SYNTHESIZE
#############################################
mptdc_start_stage "synthesis"

# Define cost groups for targeted optimization
mptdc_default_cost_groups
mptdc_apply_final_typical_repair_1 "pre_generic"

# Pre-synthesis timing snapshot
mptdc_run_nonfatal_report_step "pre-synthesis timing snapshot" \
    {mptdc_report_timing $design(synthesis_reports)} \
    "$design(synthesis_reports)/$this_run(stage)"

# Clock gating configuration
if {[info exists mptdc_enable_clock_gating] && $mptdc_enable_clock_gating} {
    if {[info exists mptdc_allow_icg_dont_use_override] && $mptdc_allow_icg_dont_use_override} {
        mptdc_allow_icg_lib_cells
    }
    if {[info exists mptdc_allow_discrete_clock_gating] && $mptdc_allow_discrete_clock_gating} {
        if {[catch {set_db lp_insert_discrete_clock_gating_logic true} discrete_cg_err]} {
            mptdc_message "Discrete clock-gating logic request was not accepted by this Genus build: $discrete_cg_err" high
        } else {
            mptdc_message "Discrete clock-gating logic enabled for O5 feasibility only" high
        }
    }
    if {![info exists mptdc_clock_gating_min_flops]} {
        set mptdc_clock_gating_min_flops 8
    }
    set_db [get_db design:$design(TOPLEVEL)] .lp_clock_gating_min_flops $mptdc_clock_gating_min_flops
    set_db [get_db design:$design(TOPLEVEL)] .lp_clock_gating_style latch
} else {
    mptdc_message "Clock gating insertion disabled for current synthesis bring-up"
}

# Don't use scan cells (no scan chain in this design)
mptdc_message "Excluding scan flip-flops from mapping"
foreach cell [get_db lib_cells -if {.scan_enable_pins!=""}] {
    set_db $cell .avoid true
}

# ── Phase 1: Generic Optimization ─────────────────────────────────
# Technology-independent: boolean opt, resource sharing, FSM encoding
mptdc_start_stage "syn_generic"
mptdc_message "Phase 1: Generic optimization"
syn_generic
mptdc_run_nonfatal_report_step "post-generic timing snapshot" \
    {mptdc_report_timing $design(synthesis_reports)} \
    "$design(synthesis_reports)/$this_run(stage)"

# ── Phase 2: Technology Mapping ───────────────────────────────────
# Maps to XFAB XH018 standard cells, selects drive strengths
mptdc_start_stage "syn_map"
mptdc_message "Phase 2: Technology mapping to XFAB XH018"
syn_map
mptdc_apply_final_typical_repair_1 "post_map_pre_opt"
mptdc_run_nonfatal_report_step "post-map timing snapshot" \
    {mptdc_report_timing $design(synthesis_reports)} \
    "$design(synthesis_reports)/$this_run(stage)"

# ── Phase 3: Incremental Optimization ─────────────────────────────
# Gate sizing, buffer insertion, hold fixing, power optimization
mptdc_start_stage "syn_opt"
mptdc_message "Phase 3: Incremental optimization"
syn_opt

#############################################
# 7. POST-SYNTHESIS REPORTS
#############################################
mptdc_start_stage "post_synthesis"
mptdc_reset_report_helper_failures

# Refresh cost groups (may be lost during optimization)
mptdc_default_cost_groups

# Timing reports
mptdc_run_nonfatal_report_step "post-synthesis timing reports" \
    {mptdc_report_timing $design(synthesis_reports)} \
    "$design(synthesis_reports)/$this_run(stage)"

# Full report suite (area, gates, power, hierarchy, DRV, QoR, latches)
mptdc_run_nonfatal_report_step "post-synthesis full reports" \
    {mptdc_full_reports $design(synthesis_reports)} \
    "$design(synthesis_reports)/$this_run(stage)"

#############################################
# 8. EXPORT DESIGN
#############################################
mptdc_start_stage "export"

# Gate-level netlist
mptdc_message "Writing post-synthesis netlist"
write_netlist > $design(postsyn_netlist)
mptdc_message "  Netlist: $design(postsyn_netlist)"

# Updated SDC
set export_view [lindex $design(selected_setup_analysis_views) 0]
mptdc_message "Writing post-synthesis SDC from $export_view"
write_sdc -view $export_view > $design(postsyn_sdc)
mptdc_message "  SDC: $design(postsyn_sdc)"

# SDF for gate-level simulation
mptdc_message "Writing SDF"
write_sdf > $design(postsyn_sdf)
mptdc_message "  SDF: $design(postsyn_sdf)"

# Genus database (for incremental runs or Innovus handoff)
mptdc_message "Writing design database"
write_design -base_name "$design(export_dir)/post_synth/$design(TOPLEVEL)" -innovus
mptdc_message "  DB: $design(export_dir)/post_synth/$design(TOPLEVEL)"

#############################################
# 9. SUMMARY
#############################################
mptdc_print_summary
