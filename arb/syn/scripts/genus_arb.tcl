# =============================================================================
# Project  : SPADMIC ARB
# File     : genus_arb.tcl
# Purpose  : Out-of-context Cadence Genus synthesis for spadmic_correlated_tx.
# =============================================================================
#
# Usage:
#   cd arb/syn/scripts
#   genus -files genus_arb.tcl -log ../logs/genus_arb.log
# =============================================================================

set runtype "synthesis"

set script_dir [file dirname [file normalize [info script]]]
set syn_root   [file normalize "$script_dir/.."]
set arb_root   [file normalize "$syn_root/.."]
set repo_root  [file normalize "$arb_root/.."]

set design(TOPLEVEL)    "spadmic_correlated_tx"
set design(sdc_file)    "$script_dir/arb.sdc"
set design(work_dir)    "$syn_root/work"
set design(reports_dir) "$syn_root/reports"
set design(outputs_dir) "$syn_root/outputs"
set design(logs_dir)    "$syn_root/logs"

set TECHNOLOGY    "xh018"
set SC_TECHNOLOGY "xh018-stdcells"

foreach dir [list $design(work_dir) $design(reports_dir) $design(outputs_dir) $design(logs_dir)] {
    file mkdir $dir
}
foreach dir [list \
    "$design(reports_dir)/elaboration" \
    "$design(reports_dir)/timing" \
    "$design(reports_dir)/qor" \
    "$design(reports_dir)/messages" \
    "$design(outputs_dir)/post_elaboration" \
    "$design(outputs_dir)/post_synth"] {
    file mkdir $dir
}

proc arb_msg {msg} {
    puts "SPADMIC_ARB_GENUS: $msg"
}

proc arb_try_set_db {attr value} {
    if {[catch {set_db $attr $value} err]} {
        puts "SPADMIC_ARB_GENUS_WARN: set_db $attr $value failed: $err"
    }
}

proc arb_run_report {cmd path} {
    if {[catch {eval $cmd > $path} result]} {
        set fh [open $path w]
        puts $fh "Command failed: $cmd"
        puts $fh $result
        close $fh
        puts "SPADMIC_ARB_GENUS_WARN: report command failed: $cmd"
    }
}

proc arb_run_report_candidates {cmds path} {
    foreach cmd $cmds {
        if {![catch {eval $cmd > $path} result]} {
            return
        }
    }
    set fh [open $path w]
    puts $fh "All report command candidates failed:"
    foreach cmd $cmds {
        puts $fh "  $cmd"
    }
    close $fh
    puts "SPADMIC_ARB_GENUS_WARN: all report candidates failed for $path"
}

proc arb_write_checkpoint_reports {tag} {
    global design

    arb_msg "Writing $tag checkpoint reports"
    arb_run_report "report_timing -max_paths 50" \
        "$design(reports_dir)/timing/report_timing_${tag}.rpt"
    arb_run_report "report_qor" \
        "$design(reports_dir)/qor/report_qor_${tag}.rpt"
    arb_run_report_candidates [list "report_area -hierarchical" "report_area -hierarchy" "report_area"] \
        "$design(reports_dir)/qor/report_area_${tag}.rpt"
    arb_run_report "report_messages" \
        "$design(reports_dir)/messages/report_messages_${tag}.rpt"
}

arb_msg "Starting OOC synthesis for $design(TOPLEVEL)"
arb_msg "Repository root: $repo_root"

source "$repo_root/MPTDC/syn/libraries/libraries.$TECHNOLOGY.tcl"
source "$repo_root/MPTDC/syn/libraries/libraries.$SC_TECHNOLOGY.tcl"

arb_try_set_db design_process_node 180
arb_try_set_db interconnect_mode ple
arb_try_set_db syn_generic_effort high
arb_try_set_db syn_map_effort high
arb_try_set_db syn_opt_effort high

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
        arb_msg "LEF not found, skipping: $lef_file"
    }
}
if {[llength $available_lefs] > 0} {
    arb_msg "Reading physical LEF abstracts"
    read_physical -lef $available_lefs
} else {
    arb_msg "No LEF abstracts found; continuing without physical-aware synthesis"
}

set design(rtl_files) [list \
    "$repo_root/MPTDC/rtl/pkg/mptdc_pkg.sv" \
    "$repo_root/MPTDC/rtl/cdc/mptdc_sync_fifo.sv" \
    "$repo_root/TOP/rtl/spadmic_pkg.sv" \
    "$arb_root/rtl/spadmic_tdc_packet_adapter.sv" \
    "$arb_root/rtl/spadmic_position_packet_adapter.sv" \
    "$arb_root/rtl/spadmic_packet_arbiter4.sv" \
    "$arb_root/rtl/spadmic_stream_skid_buffer.sv" \
    "$arb_root/rtl/spadmic_correlated_tx.sv" \
]

set_db init_hdl_search_path [list \
    "$repo_root/MPTDC/rtl/pkg" \
    "$repo_root/MPTDC/rtl/cdc" \
    "$repo_root/TOP/rtl" \
    "$arb_root/rtl" \
]

arb_msg "Reading RTL"
foreach rtl_file $design(rtl_files) {
    if {![file exists $rtl_file]} {
        error "RTL file not found: $rtl_file"
    }
    read_hdl -sv $rtl_file
}

arb_msg "Elaborating $design(TOPLEVEL)"
elaborate $design(TOPLEVEL)

arb_msg "Checking design before init"
check_design -unresolved
arb_run_report "check_design -all" \
    "$design(reports_dir)/elaboration/check_design_post_elab.rpt"
arb_run_report "report_hierarchy" \
    "$design(reports_dir)/elaboration/report_hierarchy_post_elab.rpt"

arb_msg "Initializing timing analysis view"
init_design

arb_msg "Checking timing intent"
check_timing_intent
arb_run_report "check_timing_intent -verbose" \
    "$design(reports_dir)/timing/check_timing_intent.rpt"
arb_run_report "report_clocks" \
    "$design(reports_dir)/timing/report_clocks.rpt"
arb_run_report "report_timing -max_paths 25" \
    "$design(reports_dir)/timing/report_timing_pre_synth.rpt"
arb_write_checkpoint_reports "pre_synth"

write_design -base_name "$design(outputs_dir)/post_elaboration/$design(TOPLEVEL)"

if {[catch {
    foreach cell [get_db lib_cells -if {.scan_enable_pins!=""}] {
        set_db $cell .avoid true
    }
} err]} {
    arb_msg "Scan-cell avoidance skipped or unsupported: $err"
}

arb_msg "Running syn_generic"
syn_generic
arb_write_checkpoint_reports "post_generic"

arb_msg "Running syn_map"
syn_map
arb_write_checkpoint_reports "post_map"

arb_msg "Running syn_opt"
syn_opt

arb_msg "Writing final reports"
arb_write_checkpoint_reports "post_opt"
arb_run_report "report_timing -max_paths 50" \
    "$design(reports_dir)/report_timing.rpt"
arb_run_report_candidates [list "report_area -hierarchical" "report_area -hierarchy" "report_area"] \
    "$design(reports_dir)/report_area.rpt"
arb_run_report "report_qor" \
    "$design(reports_dir)/report_qor.rpt"
arb_run_report "report_design_rules" \
    "$design(reports_dir)/report_design_rules.rpt"
arb_run_report "report_power" \
    "$design(reports_dir)/report_power.rpt"

arb_msg "Exporting post-synthesis collateral"
write_netlist > "$design(outputs_dir)/spadmic_correlated_tx.postsyn.v"
write_sdc -view tc_view > "$design(outputs_dir)/spadmic_correlated_tx.postsyn.sdc"
write_sdf > "$design(outputs_dir)/spadmic_correlated_tx.postsyn.sdf"
write_design -base_name "$design(outputs_dir)/post_synth/$design(TOPLEVEL)" -innovus

arb_msg "Done"
