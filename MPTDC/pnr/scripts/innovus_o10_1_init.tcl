# =============================================================================
# O10.1 Innovus typical feasibility entrypoint
# =============================================================================

proc mptdc_o10_msg {msg} {
    puts "MPTDC_O10_1: $msg"
}

proc mptdc_o10_fail {msg} {
    puts "MPTDC_O10_1_ERROR: $msg"
    exit 1
}

proc mptdc_o10_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_o10_required_file {label path} {
    if {![file exists $path]} {
        mptdc_o10_fail "missing $label: $path"
    }
    return $path
}

proc mptdc_o10_mkdirs {} {
    global o10
    foreach key {result_dir logs_dir reports_dir screenshots_dir checkpoints_dir def_dir manager_dir manifests_dir work_dir} {
        file mkdir $o10($key)
    }
}

proc mptdc_o10_capture {path title body} {
    set dir [file dirname $path]
    file mkdir $dir
    if {[catch {uplevel 1 "$body > \"$path\""} err]} {
        set fh [open $path w]
        puts $fh "$title"
        puts $fh [string repeat "=" [string length $title]]
        puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
        puts $fh ""
        puts $fh "FAILED:"
        puts $fh $err
        close $fh
        mptdc_o10_msg "report failed: $title: $err"
    }
}

proc mptdc_o10_capture_candidates {path title bodies} {
    set dir [file dirname $path]
    file mkdir $dir
    set errors [list]
    foreach body $bodies {
        if {![catch {uplevel 1 "$body > \"$path\""} err]} {
            return 1
        }
        lappend errors "$body: $err"
    }
    set fh [open $path w]
    puts $fh "$title"
    puts $fh [string repeat "=" [string length $title]]
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    puts $fh "FAILED:"
    puts $fh [join $errors "\n\n"]
    close $fh
    mptdc_o10_msg "all report variants failed: $title"
    return 0
}

proc mptdc_o10_object_names {objects} {
    set names [list]
    if {[llength $objects] == 0} {
        return $names
    }
    if {![catch {get_object_name $objects} obj_names]} {
        foreach name $obj_names { lappend names $name }
        return $names
    }
    if {![catch {get_db $objects .name} obj_names]} {
        foreach name $obj_names { lappend names $name }
        return $names
    }
    foreach obj $objects { lappend names $obj }
    return $names
}

proc mptdc_o10_collect_cells {patterns} {
    set matches [list]
    foreach pattern $patterns {
        set cells [list]
        if {[catch {get_cells -hierarchical -quiet $pattern} cells]} {
            catch {set cells [get_cells -hier $pattern]}
        }
        foreach cell [mptdc_o10_object_names $cells] {
            if {[lsearch -exact $matches $cell] < 0} {
                lappend matches $cell
            }
        }
    }
    return $matches
}

proc mptdc_o10_collect_nets {patterns} {
    set matches [list]
    foreach pattern $patterns {
        set nets [list]
        if {[catch {get_nets -hierarchical -quiet $pattern} nets]} {
            catch {set nets [get_nets -hier $pattern]}
        }
        foreach net [mptdc_o10_object_names $nets] {
            if {[lsearch -exact $matches $net] < 0} {
                lappend matches $net
            }
        }
    }
    return $matches
}

proc mptdc_pnr_object_names {objects} {
    return [mptdc_o10_object_names $objects]
}

proc mptdc_pnr_collect_cells {patterns} {
    return [mptdc_o10_collect_cells $patterns]
}

proc mptdc_pnr_collect_nets {patterns} {
    return [mptdc_o10_collect_nets $patterns]
}

proc mptdc_pnr_box_valid {box} {
    if {[llength $box] < 4} { return 0 }
    return [expr {([lindex $box 2] > [lindex $box 0]) && ([lindex $box 3] > [lindex $box 1])}]
}

proc mptdc_pnr_snap {value} {
    global pnr
    set snap $pnr(floorplan_snap_um)
    if {$snap <= 0.0} { return $value }
    return [expr {round($value / $snap) * $snap}]
}

proc mptdc_pnr_core_box {} {
    set core_box [list]
    if {[catch {dbGet top.fPlan.coreBox} core_box]} {
        catch {set core_box [dbGet top.fPlan.box]}
    }
    if {[llength $core_box] == 1} {
        set core_box [lindex $core_box 0]
    }
    return $core_box
}

proc mptdc_osc_pd_result_dir {} {
    global o10
    return $o10(reports_dir)
}

proc mptdc_osc_pd_timestamp {} {
    return [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]
}

proc mptdc_osc_pd_cells {patterns} {
    return [mptdc_o10_collect_cells $patterns]
}

proc mptdc_osc_pd_parse_ns_nf {inst ns_var nf_var} {
    upvar 1 $ns_var ns
    upvar 1 $nf_var nf
    set ns ""
    set nf ""
    if {[regexp {gen_pd_row\[([0-9]+)\].*gen_pd_col\[([0-9]+)\]} $inst -> ns nf]} {
        return 1
    }
    if {[regexp {gen_pd_row_([0-9]+).*gen_pd_col_([0-9]+)} $inst -> ns nf]} {
        return 1
    }
    return 0
}

proc mptdc_osc_pd_net_objects {pattern} {
    set nets [list]
    catch {set nets [get_nets -quiet -hierarchical $pattern]}
    return $nets
}

proc mptdc_osc_pd_net_attr {net attr} {
    if {[llength $net] == 0} { return "" }
    if {![catch {set val [get_db $net $attr]}]} { return $val }
    return ""
}

proc mptdc_o10_setup_globals {} {
    global o10 pnr design tech tech_files paths

    set script_dir [file dirname [file normalize [info script]]]
    set pnr_root   [file dirname $script_dir]
    set mptdc_root [file dirname $pnr_root]
    set repo_root  [file dirname $mptdc_root]

    set o10(script_dir) $script_dir
    set o10(pnr_root) $pnr_root
    set o10(mptdc_root) $mptdc_root
    set o10(repo_root) $repo_root
    set o10(run_id) [mptdc_o10_env MPTDC_O10_RUN_ID 20260604_o10_1_innovus_repair]
    set o10(result_dir) [mptdc_o10_env MPTDC_O10_RESULT_DIR "$repo_root/results/innovus/$o10(run_id)"]
    set o10(logs_dir) "$o10(result_dir)/logs"
    set o10(reports_dir) "$o10(result_dir)/reports"
    set o10(screenshots_dir) "$o10(result_dir)/screenshots"
    set o10(checkpoints_dir) "$o10(result_dir)/checkpoints"
    set o10(def_dir) "$o10(result_dir)/def"
    set o10(manager_dir) "$o10(result_dir)/manager"
    set o10(manifests_dir) "$o10(result_dir)/manifests"
    set o10(work_dir) "$o10(result_dir)/work"
    set o10(screenshot_mode) [mptdc_o10_env MPTDC_O10_SCREENSHOT_MODE batch]
    set o10(cts_status) "NOT_RUN"
    set o10(ro_cts_attempted) "no"
    mptdc_o10_mkdirs

    set design(TOPLEVEL) "mptdc_axis_core"
    set design(project_root) $mptdc_root
    set design(syn_root) "$mptdc_root/syn"
    set design(postsyn_netlist) [mptdc_o10_env MPTDC_O10_NETLIST "$repo_root/results/genus_osc_pd/20260604_o9_final_typical_r750_delta5/mptdc_axis_core.postsyn.v"]
    set design(postsyn_sdc) [mptdc_o10_env MPTDC_O10_POSTSYN_SDC "$repo_root/results/genus_osc_pd/20260604_o9_final_typical_r750_delta5/mptdc_axis_core.postsyn.sdc"]
    set o10(sdc_overlay) [mptdc_o10_env MPTDC_O10_SDC_OVERLAY "$mptdc_root/pnr/constraints/mptdc_osc_typical_r750_delta5_innovus.sdc"]
    set o10(ro_lef) [mptdc_o10_env O1_RO_LEF_PATH "$repo_root/results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef"]
    set o10(ro_lib) [mptdc_o10_env O1_RO_LIBERTY_PATH "$mptdc_root/syn/macros/RO_tune4_real_abstract_shell.lib"]

    set paths(PDK_ROOT) [mptdc_o10_env PDK_ROOT /data/pdk/xfab/xh018]
    set paths(SC_ROOT) [mptdc_o10_env SC_ROOT "$paths(PDK_ROOT)/diglibs/D_CELLS_HD/v6_0"]
    set tech_files(TECHNOLOGY_LEF) [mptdc_o10_env TECHNOLOGY_LEF "$paths(PDK_ROOT)/cadence/v9_0/techLEF/v9_0_1/xh018_xx41_HD_MET4_METMID.lef"]
    set tech_files(STDCELLS_LEF) "$paths(SC_ROOT)/LEF/v6_0_0/xh018_D_CELLS_HD.lef"
    set tech_files(STDCELLS_TC_LIB) "$paths(SC_ROOT)/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib"
    set tech_files(ALL_LEFS) [list $tech_files(TECHNOLOGY_LEF) $tech_files(STDCELLS_LEF) $o10(ro_lef)]
    set tech_files(ALL_TC_LIBS) [list $tech_files(STDCELLS_TC_LIB) $o10(ro_lib)]

    set paths(CAPTABLE_DIR) [mptdc_o10_env CAPTABLE_DIR "$paths(PDK_ROOT)/cadence/v9_0/capTbl/v9_0_1"]
    set tech_files(CAPTABLE_TC) "$paths(CAPTABLE_DIR)/xh018_xx41_MET4_METMID_typ.capTbl"

    set tech(STANDARD_CELL_SITE) "core_hd"
    set tech(STANDARD_CELL_VDD) "VDD"
    set tech(STANDARD_CELL_GND) "VSS"
    set tech(STANDARD_CELL_VDD_PINS) [list vdd]
    set tech(STANDARD_CELL_GND_PINS) [list gnd]
    set tech(OSC_VDD) "VDD"
    set tech(OSC_GND) "VSS"
    set tech(OSC_VDD_PINS) [list VDD]
    set tech(OSC_GND_PINS) [list VSS]
    set tech(FILLERS) "FEED2HD FEED1HD"

    set pnr(core_utilization) [mptdc_o10_env MPTDC_PNR_CORE_UTIL 0.60]
    set pnr(place_global_max_density) [mptdc_o10_env MPTDC_PNR_MAX_DENSITY 0.70]
    set pnr(aspect_ratio) [mptdc_o10_env MPTDC_PNR_ASPECT_RATIO 1.15]
    set pnr(core_margin_um) [mptdc_o10_env MPTDC_PNR_CORE_MARGIN_UM 35.0]
    set pnr(floorplan_snap_um) [mptdc_o10_env MPTDC_PNR_FLOORPLAN_SNAP_UM 0.56]
    set pnr(signal_bottom_layer_idx) [mptdc_o10_env MPTDC_PNR_SIGNAL_BOTTOM_LAYER_IDX 1]
    set pnr(signal_top_layer_idx) [mptdc_o10_env MPTDC_PNR_SIGNAL_TOP_LAYER_IDX 3]
    set pnr(signal_bottom_layer) [mptdc_o10_env MPTDC_PNR_SIGNAL_BOTTOM_LAYER MET1]
    set pnr(signal_top_layer) [mptdc_o10_env MPTDC_PNR_SIGNAL_TOP_LAYER MET3]
    set pnr(phase_route_top_layer) [mptdc_o10_env MPTDC_PNR_PHASE_TOP_LAYER METTP]
    set pnr(phase_exception_enable) [mptdc_o10_env MPTDC_PNR_PHASE_METTP_EXCEPTION 1]
    set pnr(pd_rows) 8
    set pnr(pd_cols) 8
    set pnr(pd_region_width_um) [mptdc_o10_env MPTDC_PNR_PD_REGION_WIDTH_UM 300.0]
    set pnr(pd_region_height_um) [mptdc_o10_env MPTDC_PNR_PD_REGION_HEIGHT_UM 300.0]
    set pnr(osc_macro_width_um) [mptdc_o10_env MPTDC_PNR_OSC_WIDTH_UM 176.675]
    set pnr(osc_macro_height_um) [mptdc_o10_env MPTDC_PNR_OSC_HEIGHT_UM 67.17]
    set pnr(osc_macro_halo_um) [mptdc_o10_env MPTDC_PNR_OSC_HALO_UM 10.0]
    set pnr(pd_region_gap_um) [mptdc_o10_env MPTDC_PNR_PD_OSC_GAP_UM 20.0]
}

proc mptdc_pnr_sandwich_boxes {} {
    return [mptdc_o10_boxes]
}

proc mptdc_o10_write_mmmc {} {
    global o10 design tech_files
    set mmmc "$o10(work_dir)/o10_1_typical_only.mmmc"
    set fh [open $mmmc w]
    puts $fh "create_constraint_mode -name functional_mode -sdc_files \[list $design(postsyn_sdc) $o10(sdc_overlay)\]"
    if {[file exists $tech_files(CAPTABLE_TC)]} {
        puts $fh "create_rc_corner -name tc_rc -temperature 25 -cap_table $tech_files(CAPTABLE_TC)"
    } else {
        puts $fh "create_rc_corner -name tc_rc -temperature 25"
    }
    puts $fh "create_library_set -name tc_libset -timing \[list $tech_files(ALL_TC_LIBS)\]"
    puts $fh "create_delay_corner -name tc_corner -library_set tc_libset -rc_corner tc_rc"
    puts $fh "create_analysis_view -name tc_view -constraint_mode functional_mode -delay_corner tc_corner"
    puts $fh "set_analysis_view -setup tc_view -hold tc_view"
    close $fh
    set o10(mmmc_file) $mmmc
}

proc mptdc_o10_verify_inputs {} {
    global o10 design tech_files
    mptdc_o10_required_file "O9 netlist" $design(postsyn_netlist)
    mptdc_o10_required_file "O9 post-synth SDC" $design(postsyn_sdc)
    mptdc_o10_required_file "O10.1 R750 Innovus SDC overlay" $o10(sdc_overlay)
    mptdc_o10_required_file "technology LEF" $tech_files(TECHNOLOGY_LEF)
    mptdc_o10_required_file "standard-cell LEF" $tech_files(STDCELLS_LEF)
    mptdc_o10_required_file "typical Liberty" $tech_files(STDCELLS_TC_LIB)
    mptdc_o10_required_file "RO_tune4 LEF" $o10(ro_lef)
    mptdc_o10_required_file "RO_tune4 Liberty shell" $o10(ro_lib)
}

proc mptdc_o10_write_manifest {stage} {
    global o10 design tech_files pnr
    set path "$o10(manifests_dir)/${stage}_manifest.rpt"
    set fh [open $path w]
    puts $fh "O10.1 Innovus manifest"
    puts $fh "======================"
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh "Stage: $stage"
    puts $fh "Run ID: $o10(run_id)"
    puts $fh "Top: $design(TOPLEVEL)"
    puts $fh "Netlist: $design(postsyn_netlist)"
    puts $fh "Post-synth SDC: $design(postsyn_sdc)"
    puts $fh "O10.1 overlay SDC: $o10(sdc_overlay)"
    puts $fh "MMMC: $o10(mmmc_file)"
    puts $fh "LEFs: $tech_files(ALL_LEFS)"
    puts $fh "Liberty: $tech_files(ALL_TC_LIBS)"
    puts $fh "Core util: $pnr(core_utilization)"
    puts $fh "Max density: $pnr(place_global_max_density)"
    puts $fh "Screenshot mode: $o10(screenshot_mode)"
    puts $fh "CTS status: $o10(cts_status)"
    puts $fh "Labels: O10_1_INNOVUS_FLOW_REPAIR O10_INNOVUS_TYPICAL_FEASIBILITY NOT_MMMC_SIGNOFF NOT_FINAL_SIGNOFF NOT_TAPEOUT_READY"
    close $fh
}

proc mptdc_o10_init_design {} {
    global o10 design tech tech_files
    global init_top_cell init_verilog init_lef_file init_mmmc_file init_pwr_net init_gnd_net
    set init_top_cell $design(TOPLEVEL)
    set init_verilog $design(postsyn_netlist)
    set init_lef_file $tech_files(ALL_LEFS)
    set init_mmmc_file $o10(mmmc_file)
    set init_pwr_net $tech(STANDARD_CELL_VDD)
    set init_gnd_net $tech(STANDARD_CELL_GND)

    mptdc_o10_msg "Initializing design with O10.1 typical-only repaired view"
    init_design

    foreach pg_pin $tech(STANDARD_CELL_VDD_PINS) {
        catch {globalNetConnect $tech(STANDARD_CELL_VDD) -type pgpin -pin $pg_pin -inst *}
    }
    foreach pg_pin $tech(STANDARD_CELL_GND_PINS) {
        catch {globalNetConnect $tech(STANDARD_CELL_GND) -type pgpin -pin $pg_pin -inst *}
    }
    foreach pg_pin $tech(OSC_VDD_PINS) {
        catch {globalNetConnect $tech(OSC_VDD) -type pgpin -pin $pg_pin -inst *}
    }
    foreach pg_pin $tech(OSC_GND_PINS) {
        catch {globalNetConnect $tech(OSC_GND) -type pgpin -pin $pg_pin -inst *}
    }
}

proc mptdc_o10_checkpoint_status {} {
    global o10
    set fh [open "$o10(reports_dir)/checkpoint_status.rpt" w]
    puts $fh "O10.1 checkpoint status"
    puts $fh "======================="
    foreach rel {
        checkpoints/01_floorplan.enc
        checkpoints/02_place.enc
        checkpoints/03_cts.enc
        checkpoints/04_route.enc
        checkpoints/restore_latest.tcl
        checkpoints/restore_place.tcl
        checkpoints/restore_route.tcl
    } {
        set path "$o10(result_dir)/$rel"
        if {[file exists $path]} {
            puts $fh "present: $rel"
        } else {
            puts $fh "missing: $rel"
        }
    }
    close $fh
}

proc mptdc_o10_main {} {
    global o10
    mptdc_o10_setup_globals
    mptdc_o10_verify_inputs
    mptdc_o10_write_mmmc
    mptdc_o10_write_manifest init

    source "$o10(script_dir)/innovus_o10_1_screenshots.tcl"
    source "$o10(script_dir)/innovus_o10_1_reports.tcl"
    source "$o10(script_dir)/innovus_o10_pd_ro_floorplan.tcl"
    source "$o10(script_dir)/innovus_o10_floorplan.tcl"
    source "$o10(script_dir)/innovus_o10_place.tcl"
    source "$o10(script_dir)/innovus_o10_1_cts.tcl"
    source "$o10(script_dir)/innovus_o10_route.tcl"
    source "$o10(script_dir)/innovus_o10_1_phase_net_reports.tcl"

    mptdc_o10_init_design
    mptdc_o10_report_stage pre_place
    mptdc_o10_floorplan
    if {[mptdc_o10_env MPTDC_O10_STOP_AFTER ""] eq "floorplan"} {
        mptdc_o10_final_reports
        mptdc_o10_manager_summary
        return
    }
    mptdc_o10_place
    if {[mptdc_o10_env MPTDC_O10_STOP_AFTER ""] eq "place"} {
        mptdc_o10_final_reports
        mptdc_o10_manager_summary
        return
    }
    mptdc_o10_cts
    mptdc_o10_route
    mptdc_o10_phase_net_reports
    mptdc_o10_final_reports
    mptdc_o10_manager_summary
    mptdc_o10_checkpoint_status
    mptdc_o10_msg "O10.1 Innovus flow repair complete"
}

if {![info exists ::env(MPTDC_O10_SOURCE_ONLY)] || !$::env(MPTDC_O10_SOURCE_ONLY)} {
    mptdc_o10_main
}
