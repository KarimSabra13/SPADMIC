# =============================================================================
# SPADMIC TOP -- TX egress fixed-leaf assembly Innovus smoke run
# =============================================================================

proc spadmic_txasm_env_required {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_TXASM_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc spadmic_txasm_status_set {key value} {
    set ::spadmic_txasm_status($key) $value
}

proc spadmic_txasm_read_status_key {path key default_value} {
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

proc spadmic_txasm_capture {path body} {
    if {[catch {redirect -file $path $body} err]} {
        set fh [open $path w]
        puts $fh "CAPTURE_STATUS=FAIL"
        puts $fh "ERROR=$err"
        close $fh
        return 0
    }
    return 1
}

set ::spadmic_txasm_repo_root [spadmic_txasm_env_required SPADMIC_REPO_ROOT]
set ::spadmic_txasm_run_root [spadmic_txasm_env_required SPADMIC_TXASM_RUN_ROOT]
set ::spadmic_txasm_plan_root [spadmic_txasm_env_required SPADMIC_TXASM_PLAN_ROOT]
set ::spadmic_txasm_netlist [spadmic_txasm_env_required SPADMIC_TXASM_NETLIST]
set ::spadmic_txasm_top_module [spadmic_txasm_env_required SPADMIC_TXASM_TOP_MODULE]

set ::spadmic_txasm_reports_dir [file join $::spadmic_txasm_run_root reports]
set ::spadmic_txasm_outputs_dir [file join $::spadmic_txasm_run_root outputs]
set ::spadmic_txasm_generated_dir [file join $::spadmic_txasm_run_root generated]
set ::spadmic_txasm_checkpoints_dir [file join $::spadmic_txasm_run_root checkpoints]
file mkdir $::spadmic_txasm_reports_dir $::spadmic_txasm_outputs_dir $::spadmic_txasm_generated_dir $::spadmic_txasm_checkpoints_dir

array set ::spadmic_txasm_status {}
spadmic_txasm_status_set PLAN_ROOT $::spadmic_txasm_plan_root
spadmic_txasm_status_set NETLIST $::spadmic_txasm_netlist
spadmic_txasm_status_set TOP_MODULE $::spadmic_txasm_top_module
spadmic_txasm_status_set SIGNOFF_READY NO
spadmic_txasm_status_set PG_CONNECTIVITY_STATUS DEFERRED_TOP_LEVEL_HOOKUP
spadmic_txasm_status_set PVS_STATUS DEFERRED
spadmic_txasm_status_set LVS_STATUS DEFERRED
spadmic_txasm_status_set PEX_STATUS DEFERRED
spadmic_txasm_status_set MMMC_STATUS DEFERRED

set placement_tcl [file join $::spadmic_txasm_plan_root tx_egress_leaf_assembly_place.tcl]
set plan_status [file join $::spadmic_txasm_plan_root tx_egress_leaf_assembly_status.rpt]
if {![file exists $placement_tcl]} {
    error "SPADMIC_TXASM_MISSING_PLACEMENT_TCL: $placement_tcl"
}
if {![file exists $plan_status]} {
    error "SPADMIC_TXASM_MISSING_PLAN_STATUS: $plan_status"
}
source $placement_tcl
spadmic_txasm_status_set PLACEMENT_TCL $placement_tcl

global design tech tech_files mptdc_xh018_cells
set design(project_root) [file join $::spadmic_txasm_repo_root MPTDC]
set design(TOPLEVEL) $::spadmic_txasm_top_module
source [file join $::spadmic_txasm_repo_root MPTDC syn libraries libraries.xh018.tcl]
source [file join $::spadmic_txasm_repo_root MPTDC syn libraries libraries.xh018-stdcells.tcl]
source [file join $::spadmic_txasm_repo_root MPTDC pnr config xh018_cells.tcl]
mptdc_xh018_validate_policy implementation
spadmic_txasm_status_set LIBRARY_SOURCE PASS

set empty_sdc [file join $::spadmic_txasm_generated_dir empty_assembly_smoke.sdc]
set fh [open $empty_sdc w]
puts $fh "# Empty by construction: macro-only TX leaf assembly smoke import."
close $fh

set mmmc [file join $::spadmic_txasm_generated_dir typical_only_assembly_smoke.mmmc]
set fh [open $mmmc w]
puts $fh "create_constraint_mode -name txasm_smoke_mode -sdc_files \[list $empty_sdc\]"
if {[info exists tech_files(CAPTABLE_TC)] && [file exists $tech_files(CAPTABLE_TC)]} {
    puts $fh "create_rc_corner -name txasm_smoke_rc -temperature 25 -cap_table $tech_files(CAPTABLE_TC)"
} else {
    puts $fh "create_rc_corner -name txasm_smoke_rc -temperature 25"
}
puts $fh "create_library_set -name txasm_smoke_libset -timing \[list $tech_files(ALL_TC_LIBS)\]"
puts $fh "create_delay_corner -name txasm_smoke_corner -library_set txasm_smoke_libset -rc_corner txasm_smoke_rc"
puts $fh "create_analysis_view -name txasm_smoke_view -constraint_mode txasm_smoke_mode -delay_corner txasm_smoke_corner"
puts $fh "set_analysis_view -setup txasm_smoke_view -hold txasm_smoke_view"
close $fh

set local_w [spadmic_txasm_read_status_key $plan_status LOCAL_ASSEMBLY_WIDTH_UM 3449.600]
set local_h [spadmic_txasm_read_status_key $plan_status LOCAL_ASSEMBLY_HEIGHT_UM 746.560]
set core_margin 0.0

global init_top_cell init_verilog init_lef_file init_mmmc_file init_pwr_net init_gnd_net init_design_uniquify
set init_top_cell $::spadmic_txasm_top_module
set init_verilog $::spadmic_txasm_netlist
set init_lef_file [concat $tech_files(ALL_LEFS) $SPADMIC_TX_LEAF_LEFS]
set init_mmmc_file $mmmc
set init_pwr_net $tech(STANDARD_CELL_VDD)
set init_gnd_net $tech(STANDARD_CELL_GND)
set init_design_uniquify 0
init_design
spadmic_txasm_status_set INIT_DESIGN PASS

foreach pg_pin $tech(STANDARD_CELL_VDD_PINS) {
    catch {globalNetConnect $tech(STANDARD_CELL_VDD) -type pgpin -pin $pg_pin -inst *}
}
foreach pg_pin $tech(STANDARD_CELL_GND_PINS) {
    catch {globalNetConnect $tech(STANDARD_CELL_GND) -type pgpin -pin $pg_pin -inst *}
}

if {[catch {floorPlan -site $tech(STANDARD_CELL_SITE) -s $local_w $local_h $core_margin $core_margin $core_margin $core_margin} err]} {
    spadmic_txasm_status_set FLOORPLAN FAIL
    error "SPADMIC_TXASM_FLOORPLAN_FAILED: $err"
}
spadmic_txasm_status_set FLOORPLAN PASS
spadmic_txasm_status_set LOCAL_ASSEMBLY_WIDTH_UM $local_w
spadmic_txasm_status_set LOCAL_ASSEMBLY_HEIGHT_UM $local_h

spadmic_apply_tx_leaf_assembly_placement [file join $::spadmic_txasm_reports_dir tx_egress_leaf_assembly_placement.rpt]
set placement_status [spadmic_txasm_read_status_key [file join $::spadmic_txasm_reports_dir tx_egress_leaf_assembly_placement.rpt] STATUS REVIEW_REQUIRED]
spadmic_txasm_status_set FIXED_LEAF_PLACEMENT_STATUS $placement_status

spadmic_txasm_capture [file join $::spadmic_txasm_reports_dir check_place.rpt] {checkPlace}
spadmic_txasm_capture [file join $::spadmic_txasm_reports_dir report_area.rpt] {report_area}
spadmic_txasm_capture [file join $::spadmic_txasm_reports_dir report_design.rpt] {report_design}
catch {defOut -floorplan -netlist -routing [file join $::spadmic_txasm_outputs_dir tx_egress_leaf_assembly_smoke.def]}
catch {saveDesign [file join $::spadmic_txasm_checkpoints_dir tx_egress_leaf_assembly_smoke.enc]}

set manifest_csv [file join $::spadmic_txasm_reports_dir instance_summary.csv]
set fh [open $manifest_csv w]
puts $fh "instance,cell,place_status,orient,box"
foreach inst [dbGet top.insts.name] {
    set cell [dbGet [dbGet top.insts.name $inst -p].cell.name]
    set status [dbGet [dbGet top.insts.name $inst -p].pStatus]
    set orient [dbGet [dbGet top.insts.name $inst -p].orient]
    set box [dbGet [dbGet top.insts.name $inst -p].box]
    puts $fh "$inst,$cell,$status,$orient,\"$box\""
}
close $fh
spadmic_txasm_status_set INSTANCE_SUMMARY_FILE $manifest_csv

set result FIXED_LEAF_ASSEMBLY_SMOKE_REVIEW_REQUIRED
if {$placement_status eq "PASS"} {
    set result FIXED_LEAF_ASSEMBLY_SMOKE_PLACED
}
spadmic_txasm_status_set RESULT $result
spadmic_txasm_status_set ROUTE_STATUS NOT_RUN
spadmic_txasm_status_set TOP_ABSOLUTE_PLACEMENT_STATUS [spadmic_txasm_read_status_key $plan_status TOP_ABSOLUTE_PLACEMENT_STATUS REVIEW_REQUIRED]

set status_rpt [file join $::spadmic_txasm_reports_dir tx_egress_leaf_assembly_smoke_status.rpt]
set fh [open $status_rpt w]
foreach key [lsort [array names ::spadmic_txasm_status]] {
    puts $fh "$key=$::spadmic_txasm_status($key)"
}
close $fh

exit 0
