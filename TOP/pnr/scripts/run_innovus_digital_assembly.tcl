# Fresh cumulative soft digital-assembly implementation for p00 through p03.

proc da_env_required {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_DA_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc da_value {value} {
    return [string map [list "\n" " " "\r" " " "\t" " "] "$value"]
}

proc da_status {key value} {
    set ::da_status($key) [da_value $value]
}

proc da_write_status {} {
    set path [file join $::da_reports digital_assembly_innovus_status.rpt]
    set fh [open $path w]
    foreach key [lsort [array names ::da_status]] {
        puts $fh "$key=$::da_status($key)"
    }
    close $fh
}

proc da_try_first {label commands {required 1}} {
    set path [file join $::da_reports "${label}.rpt"]
    set fh [open $path w]
    puts $fh "LABEL=$label"
    set last_error ""
    foreach command $commands {
        puts $fh "TRY=[da_value $command]"
        if {![catch {uplevel #0 $command} result]} {
            puts $fh "STATUS=PASS"
            puts $fh "COMMAND=[da_value $command]"
            close $fh
            da_status $label PASS
            return 1
        }
        puts $fh "ERROR=[da_value $result]"
        set last_error $result
    }
    puts $fh "STATUS=FAIL"
    close $fh
    da_status $label FAIL
    if {$required} {
        error "SPADMIC_DA_COMMAND_FAILED: label=$label error=$last_error"
    }
    return 0
}

proc da_capture_first {path label commands {required 1}} {
    set fh [open $path w]
    puts $fh "LABEL=$label"
    close $fh
    set last_error ""
    foreach command $commands {
        set fh [open $path a]
        puts $fh "TRY=[da_value $command]"
        close $fh
        if {![catch {redirect -append -file $path $command} result]} {
            set fh [open $path a]
            puts $fh "STATUS=PASS"
            puts $fh "COMMAND=[da_value $command]"
            close $fh
            da_status $label PASS
            return 1
        }
        set fh [open $path a]
        puts $fh "ERROR=[da_value $result]"
        close $fh
        set last_error $result
    }
    set fh [open $path a]
    puts $fh "STATUS=FAIL"
    close $fh
    da_status $label FAIL
    if {$required} {
        error "SPADMIC_DA_REPORT_FAILED: label=$label error=$last_error"
    }
    return 0
}

proc da_normalize_box {box} {
    while {[llength $box] == 1 && [llength [lindex $box 0]] > 1} {
        set box [lindex $box 0]
    }
    return $box
}

proc da_box_equal {actual expected {tolerance 0.002}} {
    set actual [da_normalize_box $actual]
    set expected [da_normalize_box $expected]
    if {[llength $actual] != 4 || [llength $expected] != 4} {
        return 0
    }
    for {set index 0} {$index < 4} {incr index} {
        set lhs [lindex $actual $index]
        set rhs [lindex $expected $index]
        if {![string is double -strict $lhs] || ![string is double -strict $rhs]} {
            return 0
        }
        if {abs(double($lhs) - double($rhs)) > $tolerance} {
            return 0
        }
    }
    return 1
}

proc da_find_box {value expected} {
    if {[da_box_equal $value $expected]} {
        return 1
    }
    foreach item $value {
        if {[llength $item] > 1 && [da_find_box $item $expected]} {
            return 1
        }
    }
    return 0
}

proc da_verification_count {path} {
    if {![file exists $path]} {
        return UNKNOWN
    }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    if {[regexp -nocase {Verification[[:space:]]+Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viols?} $text -> count]} {
        return $count
    }
    if {[regexp -nocase {No[[:space:]]+(DRC[[:space:]]+)?violations?[[:space:]]+found} $text]} {
        return 0
    }
    return UNKNOWN
}

proc da_require_zero_verification {label path} {
    set count [da_verification_count $path]
    da_status "${label}_VIOLATION_COUNT" $count
    if {$count eq "UNKNOWN" || $count != 0} {
        da_status "${label}_STATUS" FAIL
        error "SPADMIC_DA_${label}_NOT_CLEAN: count=$count report=$path"
    }
    da_status "${label}_STATUS" PASS
}

proc da_write_mmmc {} {
    global tech_files
    set path [file join $::da_generated assembly_tc_only.mmmc]
    set fh [open $path w]
    puts $fh "create_constraint_mode -name da_mode -sdc_files \[list $::da_sdc\]"
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
    return $path
}

proc da_init_design {} {
    global design tech tech_files mptdc_xh018_cells
    set design(project_root) [file join $::da_repo MPTDC]
    set design(TOPLEVEL) $::da_top
    source [file join $::da_repo MPTDC syn libraries libraries.xh018.tcl]
    source [file join $::da_repo MPTDC syn libraries libraries.xh018-stdcells.tcl]
    source [file join $::da_repo MPTDC pnr config xh018_cells.tcl]
    mptdc_xh018_validate_policy implementation
    da_status LIBRARY_SOURCE_STATUS PASS

    set mmmc [da_write_mmmc]
    global init_top_cell init_verilog init_lef_file init_mmmc_file
    global init_pwr_net init_gnd_net init_design_uniquify
    set init_top_cell $::da_top
    set init_verilog $::da_netlist
    set init_lef_file $tech_files(ALL_LEFS)
    set init_mmmc_file $mmmc
    set init_pwr_net VDD
    set init_gnd_net VSS
    set init_design_uniquify 0
    init_design

    foreach pin $tech(STANDARD_CELL_VDD_PINS) {
        catch {globalNetConnect VDD -type pgpin -pin $pin -inst *}
    }
    foreach pin $tech(STANDARD_CELL_GND_PINS) {
        catch {globalNetConnect VSS -type pgpin -pin $pin -inst *}
    }
    catch {globalNetConnect VDD -type net -net VDD}
    catch {globalNetConnect VSS -type net -net VSS}
    set actual_top [dbGet top.name]
    if {$actual_top ne $::da_top} {
        error "SPADMIC_DA_TOP_MISMATCH: actual=$actual_top expected=$::da_top"
    }
    da_status INIT_DESIGN_STATUS PASS

    set hard_macros [list]
    catch {set hard_macros [dbGet [dbGet -p2 top.insts.cell.baseClass block].name]}
    if {$hard_macros eq "0x0"} {
        set hard_macros [list]
    }
    da_status HARD_MACRO_COUNT [llength $hard_macros]
    if {[llength $hard_macros] != 0} {
        error "SPADMIC_DA_HARD_MACRO_GATE_FAILED: $hard_macros"
    }
    da_status HARD_MACRO_STATUS PASS
    catch {saveDesign [file join $::da_checkpoints 00_import.enc]}
}

proc da_apply_floorplan {} {
    global tech
    set expected $::spadmic_da_phase::die_bbox
    lassign $expected llx lly urx ury
    if {abs(double($llx)) > 0.002 || abs(double($lly)) > 0.002} {
        error "SPADMIC_DA_UNSUPPORTED_NONZERO_DIE_ORIGIN: $expected"
    }
    set width [expr {double($urx) - double($llx)}]
    set height [expr {double($ury) - double($lly)}]
    da_try_first FLOORPLAN [list \
        [list floorPlan -site $tech(STANDARD_CELL_SITE) -d $width $height 0 0 0 0] \
        [list floorPlan -site $tech(STANDARD_CELL_SITE) -s $width $height 0 0 0 0]] 1
    set actual [da_normalize_box [dbGet top.fPlan.box]]
    set fh [open [file join $::da_reports floorplan_geometry.rpt] w]
    puts $fh "LABEL=SPADMIC_DIGITAL_ASSEMBLY_FLOORPLAN_GEOMETRY"
    puts $fh "EXPECTED_DIE_BBOX_UM=[join $expected { }]"
    puts $fh "ACTUAL_DIE_BBOX_UM=[join $actual { }]"
    puts $fh "STATUS=[expr {[da_box_equal $actual $expected] ? {PASS} : {FAIL}}]"
    close $fh
    if {![da_box_equal $actual $expected]} {
        da_status FLOORPLAN_GEOMETRY_STATUS FAIL
        error "SPADMIC_DA_DIE_BBOX_MISMATCH: actual=$actual expected=$expected"
    }
    da_status EXPECTED_DIE_BBOX_UM [join $expected { }]
    da_status ACTUAL_DIE_BBOX_UM [join $actual { }]
    da_status FLOORPLAN_GEOMETRY_STATUS PASS
}

proc da_apply_obstacles {} {
    set fh [open [file join $::da_reports fixed_obstacle_application.rpt] w]
    puts $fh "LABEL=SPADMIC_DIGITAL_ASSEMBLY_FIXED_OBSTACLES"
    set count 0
    foreach index [lsort -integer [array names ::spadmic_da_phase::obstacles]] {
        set box $::spadmic_da_phase::obstacles($index)
        lassign $box llx lly urx ury
        set place_name "da_fixed_${index}"
        set route_name "da_fixed_route_${index}"
        if {[catch {createPlaceBlockage -name $place_name -type hard -box $llx $lly $urx $ury} error]} {
            puts $fh "STATUS=FAIL"
            puts $fh "ERROR=[da_value $error]"
            close $fh
            error "SPADMIC_DA_PLACE_OBSTACLE_FAILED: $index $error"
        }
        if {[catch {createRouteBlk -name $route_name -box [list $llx $lly $urx $ury] -layer {MET1 MET2 MET3}} error]} {
            puts $fh "STATUS=FAIL"
            puts $fh "ERROR=[da_value $error]"
            close $fh
            error "SPADMIC_DA_ROUTE_OBSTACLE_FAILED: $index $error"
        }
        puts $fh "OBSTACLE=$index|$box|PLACEMENT_HARD|ROUTE_MET1_MET2_MET3"
        incr count
    }
    puts $fh "OBSTACLE_COUNT=$count"
    puts $fh "STATUS=PASS"
    close $fh
    da_status FIXED_OBSTACLE_COUNT $count
    da_status FIXED_OBSTACLE_STATUS PASS
}

proc da_group_members {patterns} {
    set all_names [dbGet top.insts.name]
    set members [list]
    foreach name $all_names {
        foreach pattern $patterns {
            if {[string match $pattern $name] && [lsearch -exact $members $name] < 0} {
                lappend members $name
            }
        }
    }
    return $members
}

proc da_apply_soft_guides {} {
    set fh [open [file join $::da_reports soft_group_guide_application.rpt] w]
    puts $fh "LABEL=SPADMIC_DIGITAL_ASSEMBLY_SOFT_GROUP_GUIDES"
    set count 0
    foreach group $::spadmic_da_phase::groups {
        if {![info exists ::spadmic_da_phase::guides($group)]} {
            puts $fh "STATUS=FAIL"
            puts $fh "ERROR=missing_guide_for_$group"
            close $fh
            error "SPADMIC_DA_GUIDE_MISSING: $group"
        }
        set patterns $::spadmic_da_phase::group_patterns($group)
        set members [da_group_members $patterns]
        if {[llength $members] == 0} {
            puts $fh "STATUS=FAIL"
            puts $fh "ERROR=no_physical_members_for_$group patterns=$patterns"
            close $fh
            error "SPADMIC_DA_GUIDE_MEMBER_GATE_FAILED: $group"
        }
        set group_name "da_$group"
        catch {deleteInstGroup $group_name}
        if {[catch {createInstGroup $group_name} error]} {
            puts $fh "STATUS=FAIL"
            puts $fh "ERROR=[da_value $error]"
            close $fh
            error "SPADMIC_DA_GROUP_CREATE_FAILED: $group"
        }
        set added 0
        foreach member $members {
            if {![catch {addInstToInstGroup $group_name $member} error]} {
                incr added
            }
        }
        if {$added != [llength $members]} {
            puts $fh "STATUS=FAIL"
            puts $fh "ERROR=group_member_add_count_$added_expected_[llength $members]"
            close $fh
            error "SPADMIC_DA_GROUP_MEMBER_ADD_FAILED: $group"
        }
        lassign $::spadmic_da_phase::guides($group) llx lly urx ury
        if {[catch {createRegion $group_name $llx $lly $urx $ury} error]} {
            puts $fh "STATUS=FAIL"
            puts $fh "ERROR=[da_value $error]"
            close $fh
            error "SPADMIC_DA_GUIDE_REGION_FAILED: $group"
        }
        set group_ptr [dbGet -p top.fPlan.groups.name $group_name]
        if {$group_ptr eq "" || $group_ptr eq "0x0"} {
            error "SPADMIC_DA_GROUP_DB_OBJECT_MISSING: $group"
        }
        dbSet ${group_ptr}.conType guide
        set actual_type [string tolower [dbGet ${group_ptr}.conType]]
        if {$actual_type ne "guide"} {
            error "SPADMIC_DA_SOFT_GUIDE_TYPE_FAILED: $group actual=$actual_type"
        }
        puts $fh "GUIDE=$group|$group_name|$added|$llx $lly $urx $ury|$actual_type"
        incr count
    }
    puts $fh "GUIDE_COUNT=$count"
    puts $fh "STATUS=PASS"
    close $fh
    da_status SOFT_GUIDE_COUNT $count
    da_status SOFT_GUIDE_STATUS PASS
}

proc da_place_exact_proxy_pins {} {
    if {$::da_phase ne "p03_matrix_interface"} {
        da_status EXACT_PROXY_PIN_STATUS NOT_APPLICABLE
        da_status EXACT_PROXY_PIN_COUNT 0
        return
    }
    set plan [file join $::da_contract_root matrix_proxy_pin_plan.tsv]
    set fh [open $plan r]
    set lines [split [string trim [read $fh]] "\n"]
    close $fh
    if {[llength $lines] < 2} {
        error "SPADMIC_DA_PROXY_PLAN_EMPTY: $plan"
    }
    set report [open [file join $::da_reports matrix_proxy_pin_placement.rpt] w]
    puts $report "LABEL=SPADMIC_DIGITAL_ASSEMBLY_MATRIX_PROXY_PIN_PLACEMENT"
    set count 0
    foreach line [lrange $lines 1 end] {
        if {[string trim $line] eq ""} { continue }
        lassign [split $line "\t"] port terminal family index direction layer purpose llx lly urx ury policy
        set term_ptr [dbGet -p top.terms.name $port]
        if {$term_ptr eq "" || $term_ptr eq "0x0"} {
            puts $report "PIN=$port|STATUS=FAIL|ERROR=top_terminal_missing"
            close $report
            error "SPADMIC_DA_PROXY_TOP_TERM_MISSING: $port"
        }
        set width [expr {double($urx) - double($llx)}]
        set depth [expr {double($ury) - double($lly)}]
        set cx [expr {(double($llx) + double($urx)) / 2.0}]
        set cy [expr {(double($lly) + double($ury)) / 2.0}]
        set command [list editPin -pin $port -assign [list $cx $cy] -layer $layer -pinWidth $width -pinDepth $depth -fixedPin 1]
        if {[catch {uplevel #0 $command} error]} {
            puts $report "PIN=$port|STATUS=FAIL|ERROR=[da_value $error]"
            close $report
            error "SPADMIC_DA_PROXY_EDITPIN_FAILED: $port $error"
        }
        set expected [list $llx $lly $urx $ury]
        set boxes ""
        set layers ""
        foreach suffix {pins.allShapes.shapes.box pins.allShapes.box pins.allShapes.shapes.rect pins.allShapes.rect} {
            if {![catch {set candidate [dbGet ${term_ptr}.${suffix}]}] && $candidate ne "" && $candidate ne "0x0"} {
                set boxes $candidate
                break
            }
        }
        foreach suffix {pins.allShapes.shapes.layer.name pins.allShapes.layer.name} {
            if {![catch {set candidate [dbGet ${term_ptr}.${suffix}]}] && $candidate ne "" && $candidate ne "0x0"} {
                set layers $candidate
                break
            }
        }
        set box_ok [da_find_box $boxes $expected]
        set layer_ok [expr {[string first [string toupper $layer] [string toupper "$layers"]] >= 0}]
        puts $report "PIN=$port|MATRIX_TERMINAL=$terminal|FAMILY=$family|INDEX=$index|EXPECTED_BOX=$expected|ACTUAL_BOXES=[da_value $boxes]|EXPECTED_LAYER=$layer|ACTUAL_LAYERS=[da_value $layers]|BOX_STATUS=[expr {$box_ok ? {PASS} : {FAIL}}]|LAYER_STATUS=[expr {$layer_ok ? {PASS} : {FAIL}}]"
        if {!$box_ok || !$layer_ok} {
            close $report
            error "SPADMIC_DA_PROXY_GEOMETRY_MISMATCH: $port"
        }
        incr count
    }
    puts $report "PIN_COUNT=$count"
    puts $report "STATUS=PASS"
    close $report
    da_status EXACT_PROXY_PIN_COUNT $count
    da_status EXACT_PROXY_PIN_STATUS PASS
}

proc da_place_remaining_signal_pins {} {
    set reserved [list VDD VSS]
    if {$::da_phase eq "p03_matrix_interface"} {
        set plan [file join $::da_contract_root matrix_proxy_pin_plan.tsv]
        set fh [open $plan r]
        set lines [split [string trim [read $fh]] "\n"]
        close $fh
        foreach line [lrange $lines 1 end] {
            if {[string trim $line] ne ""} {
                lappend reserved [lindex [split $line "\t"] 0]
            }
        }
    }
    set remaining [list]
    foreach pin [dbGet top.terms.name] {
        if {[lsearch -exact $reserved $pin] < 0} {
            lappend remaining $pin
        }
    }
    set left [list]
    set right [list]
    set index 0
    foreach pin [lsort $remaining] {
        if {$index % 2 == 0} { lappend left $pin } else { lappend right $pin }
        incr index
    }
    if {[llength $left] > 0} {
        da_try_first PLACE_SIGNAL_PINS_LEFT [list \
            [list editPin -pin $left -side LEFT -layer MET3 -spreadType SIDE -spacing 1.0 -pinWidth 0.56 -pinDepth 0.56 -fixedPin 1] \
            [list editPin -pin $left -side left -layer MET3 -spreadType SIDE -spacing 1.0]] 1
    }
    if {[llength $right] > 0} {
        da_try_first PLACE_SIGNAL_PINS_RIGHT [list \
            [list editPin -pin $right -side RIGHT -layer MET3 -spreadType SIDE -spacing 1.0 -pinWidth 0.56 -pinDepth 0.56 -fixedPin 1] \
            [list editPin -pin $right -side right -layer MET3 -spreadType SIDE -spacing 1.0]] 1
    }
    da_status REMAINING_SIGNAL_PIN_COUNT [llength $remaining]
    da_status SIGNAL_PIN_PLACEMENT_STATUS PASS
}

proc da_create_pg {} {
    set expected_die $::spadmic_da_phase::die_bbox
    lassign $expected_die die_llx die_lly die_urx die_ury
    set fh [open [file join $::da_reports pg_anchor_application.rpt] w]
    puts $fh "LABEL=SPADMIC_DIGITAL_ASSEMBLY_PG_ANCHORS"
    foreach net {VDD VSS} {
        set anchors $::spadmic_da_phase::pg_anchors($net)
        if {[llength $anchors] == 0} {
            close $fh
            error "SPADMIC_DA_METTP_PG_ANCHOR_MISSING: $net"
        }
        set anchor [lindex $anchors 0]
        lassign $anchor llx lly urx ury
        set width [expr {double($urx) - double($llx)}]
        set cx [expr {(double($llx) + double($urx)) / 2.0}]
        da_try_first "CREATE_PG_PIN_$net" [list \
            [list createPGPin $net -net $net -geom METTP $llx $lly $urx $ury -dir bidi] \
            [list createPGPin $net -net $net -geom METTP $llx $lly $urx $ury]] 1
        da_try_first "CREATE_PG_STRAP_$net" [list \
            [list add_shape -net $net -layer METTP -shape STRIPE -status ROUTED -pathSeg [list $cx $die_lly $cx $die_ury] -width $width]] 1
        puts $fh "ANCHOR=$net|METTP|$anchor|STRAP_CENTER_X=$cx|STRAP_WIDTH=$width"
    }
    puts $fh "STATUS=PASS"
    close $fh
    da_try_first SROUTE_PG [list \
        [list sroute -connect {corePin} -nets {VDD VSS} -corePinTarget {stripe} -corePinCheckStdcellGeoms -allowJogging 1 -allowLayerChange 1 -layerChangeRange {MET1 METTP}] \
        [list sroute -connect {corePin} -nets {VDD VSS} -corePinTarget {stripe} -allowJogging 1 -allowLayerChange 1 -layerChangeRange {MET1 METTP}]] 1
    da_status PG_ANCHOR_STATUS PASS
    da_status PG_LOCAL_ROUTE_MODE EXPLICIT_EXACT_METTP_ANCHOR
}

proc da_place_cts_route {} {
    global mptdc_xh018_cells
    setPlaceMode -place_global_max_density $::spadmic_da_phase::max_local_density
    catch {setPlaceMode -place_global_effort high}
    catch {setPlaceMode -place_global_cong_effort high}
    catch {setPlaceMode -place_global_timing_effort high}
    da_status TARGET_UTILIZATION $::spadmic_da_phase::target_utilization
    da_status MAX_LOCAL_DENSITY $::spadmic_da_phase::max_local_density
    da_try_first PLACE_DESIGN [list {place_design} {placeDesign}] 1
    da_capture_first [file join $::da_reports check_place_post_place.rpt] CHECK_PLACE_POST_PLACE [list {checkPlace}] 1
    catch {saveDesign [file join $::da_checkpoints 01_place.enc]}

    if {[info exists mptdc_xh018_cells(cts_buffers)]} {
        catch {set_ccopt_property buffer_cells $mptdc_xh018_cells(cts_buffers)}
    }
    if {[info exists mptdc_xh018_cells(cts_inverters)]} {
        catch {set_ccopt_property inverter_cells $mptdc_xh018_cells(cts_inverters)}
    }
    da_try_first CTS_DESIGN [list {ccopt_design} {clockDesign}] 1
    catch {saveDesign [file join $::da_checkpoints 02_cts.enc]}

    if {![info exists mptdc_xh018_cells(filler)] || [llength $mptdc_xh018_cells(filler)] == 0} {
        error "SPADMIC_DA_FILLER_CELL_POLICY_MISSING"
    }
    catch {setFillerMode -addFillersWithDrc false}
    da_try_first ADD_FILLER [list \
        [list addFiller -cell $mptdc_xh018_cells(filler) -prefix DA_FILL] \
        [list addFiller -cell $mptdc_xh018_cells(filler)]] 1
    da_try_first SROUTE_PG_POST_FILLER [list \
        [list sroute -connect {corePin} -nets {VDD VSS} -corePinTarget {stripe} -corePinCheckStdcellGeoms -allowJogging 1 -allowLayerChange 1 -layerChangeRange {MET1 METTP}] \
        [list sroute -connect {corePin} -nets {VDD VSS} -corePinTarget {stripe} -allowJogging 1 -allowLayerChange 1 -layerChangeRange {MET1 METTP}]] 1

    setDesignMode -bottomRoutingLayer MET1 -topRoutingLayer MET3
    setNanoRouteMode -routeBottomRoutingLayer 1
    setNanoRouteMode -routeTopRoutingLayer 3
    catch {setNanoRouteMode -routeWithTimingDriven true}
    catch {setNanoRouteMode -routeWithSiDriven true}
    catch {setNanoRouteMode -drouteUseMultiCutViaEffort high}
    catch {setNanoRouteMode -drouteFixAntenna true}
    da_try_first ROUTE_DESIGN [list {routeDesign} {globalDetailRoute}] 1
    catch {optDesign -postRoute -setup}
    catch {optDesign -postRoute -hold}
    catch {setExtractRCMode -engine postRoute}
    catch {extractRC}
    da_status SIGNAL_ROUTE_LAYERS MET1-MET3
    da_status METTP_POLICY PG_AND_BOUNDED_PIN_ACCESS_ONLY
    da_status STANDARD_CELL_FILL_STATUS PASS
    catch {saveDesign [file join $::da_checkpoints 03_route.enc]}
}

proc da_capture_timing {} {
    set setup_dir [file join $::da_reports timing_post_route_setup]
    set hold_dir [file join $::da_reports timing_post_route_hold]
    file mkdir $setup_dir $hold_dir
    da_try_first POSTROUTE_SETUP_TIMING [list \
        [list timeDesign -postRoute -outDir $setup_dir] \
        [list timeDesign -postRoute]] 1
    da_try_first POSTROUTE_HOLD_TIMING [list \
        [list timeDesign -postRoute -hold -outDir $hold_dir] \
        [list timeDesign -postRoute -hold]] 1
    da_capture_first [file join $::da_reports report_timing_post_route_setup.rpt] REPORT_TIMING_SETUP [list \
        {report_timing -late -max_paths 100} \
        {report_timing -check_type setup -max_paths 100} \
        {report_timing -max_paths 100}] 1
    da_capture_first [file join $::da_reports report_timing_post_route_hold.rpt] REPORT_TIMING_HOLD [list \
        {report_timing -early -max_paths 100} \
        {report_timing -check_type hold -max_paths 100}] 1
    da_capture_first [file join $::da_reports report_constraint_post_route.rpt] REPORT_CONSTRAINT [list \
        {report_constraint -all_violators} \
        {report_constraints -all_violators}] 1
    da_capture_first [file join $::da_reports report_clocks_post_route.rpt] REPORT_CLOCKS [list \
        {report_clocks} \
        {reportClockTree}] 1
    da_status TC_TIMING_CAPTURE_STATUS PASS
    da_status MMMC_STATUS NOT_RUN_TC_ONLY
}

proc da_verify {} {
    set drc [file join $::da_reports verify_drc_post_route.rpt]
    set regular [file join $::da_reports verify_connectivity_regular.rpt]
    set pg [file join $::da_reports verify_connectivity_pg.rpt]
    da_capture_first $drc VERIFY_DRC_POST_ROUTE [list {verify_drc} {verifyGeometry}] 1
    da_capture_first $regular VERIFY_CONNECTIVITY_REGULAR [list \
        {verifyConnectivity -type regular} \
        {verifyConnectivity}] 1
    da_capture_first $pg VERIFY_CONNECTIVITY_PG [list \
        {verifyConnectivity -type special -nets {VDD VSS}} \
        {verifyConnectivity -nets {VDD VSS} -type special}] 1
    da_require_zero_verification INNOVUS_DRC $drc
    da_require_zero_verification REGULAR_CONNECTIVITY $regular
    da_require_zero_verification PG_CONNECTIVITY $pg
}

proc da_export {} {
    set base [file join $::da_outputs $::da_top]
    set def "${base}.def"
    set lef "${base}.lef"
    set gds "${base}.gds"
    set netlist "${base}.v"
    set pg_netlist "${base}.pg.v"
    da_try_first EXPORT_DEF [list [list defOut $def]] 1
    da_try_first EXPORT_NETLIST [list [list saveNetlist $netlist]] 1
    da_try_first EXPORT_NETLIST_PG [list [list saveNetlist -includePowerGround $pg_netlist]] 1
    da_try_first EXPORT_LEF [list \
        [list write_lef_abstract $lef] \
        [list lefOut $lef] \
        [list write_lef $lef]] 1
    set stream_command [list streamOut $gds -libName DesignLib -units 1000 -mode ALL \
        -mapFile $::da_stream_map -merge $::da_stdcell_gds]
    da_try_first EXPORT_GDS [list $stream_command] 1
    foreach path [list $def $lef $gds $netlist $pg_netlist] {
        if {![file exists $path] || [file size $path] == 0} {
            error "SPADMIC_DA_EXPORT_MISSING_OR_EMPTY: $path"
        }
    }
    da_status EXPORT_DEF_STATUS PASS
    da_status EXPORT_LEF_STATUS PASS
    da_status EXPORT_GDS_STATUS PASS
    da_status EXPORT_NETLIST_STATUS PASS
    da_status EXPORT_PG_NETLIST_STATUS PASS
    da_status CHILD_GDS_MERGE_COUNT 0
    da_status STDCELL_GDS_MERGE_COUNT 1
    catch {saveDesign [file join $::da_checkpoints 04_export.enc]}
}

proc da_main {} {
    da_init_design
    da_apply_floorplan
    da_apply_obstacles
    da_apply_soft_guides
    da_place_exact_proxy_pins
    da_place_remaining_signal_pins
    da_create_pg
    da_place_cts_route
    da_capture_timing
    da_verify
    da_export
    da_status STATUS PASS
    da_status RESULT PHASE_IMPLEMENTATION_COMPLETED_PENDING_EXTERNAL_REPORT_VALIDATION
    da_status INNOVUS_EXECUTED YES
    da_status PVS_EXECUTED NO
    da_status SIGNOFF_READY NO
    da_status NEXT_GATE RUN_STRICT_INNOVUS_REPORT_VALIDATOR
}

set ::da_repo [da_env_required SPADMIC_REPO_ROOT]
set ::da_phase [da_env_required SPADMIC_DA_PHASE]
set ::da_top [da_env_required SPADMIC_DA_TOP_MODULE]
set ::da_run_root [da_env_required SPADMIC_DA_RUN_ROOT]
set ::da_contract_root [da_env_required SPADMIC_DA_PHASE_CONTRACT_ROOT]
set ::da_config [da_env_required SPADMIC_DA_CONFIG_TCL]
set ::da_netlist [da_env_required SPADMIC_DA_NETLIST]
set ::da_sdc [da_env_required SPADMIC_DA_SDC]
set ::da_stream_map [da_env_required SPADMIC_STREAMOUT_MAP_FILE]
set ::da_stdcell_gds [da_env_required SPADMIC_STDCELL_GDS]
set ::da_reports [file join $::da_run_root reports]
set ::da_outputs [file join $::da_run_root outputs]
set ::da_checkpoints [file join $::da_run_root checkpoints]
set ::da_generated [file join $::da_run_root generated]
file mkdir $::da_reports $::da_outputs $::da_checkpoints $::da_generated

source $::da_config
array set ::da_status {}
da_status LABEL SPADMIC_DIGITAL_ASSEMBLY_INNOVUS_IMPLEMENTATION
da_status PHASE $::da_phase
da_status TOP_MODULE $::da_top
da_status SOURCE_TOP $::da_top
da_status LAYOUT_TOP $::da_top
da_status IMPLEMENTATION CUMULATIVE_SOFT_LOGIC
da_status HARD_MACRO_COUNT UNKNOWN
da_status CHILD_GDS_MERGE_COUNT 0
da_status TARGET_UTILIZATION $::spadmic_da_phase::target_utilization
da_status MAX_LOCAL_DENSITY $::spadmic_da_phase::max_local_density
da_status SIGNAL_ROUTE_LAYERS MET1-MET3
da_status METTP_POLICY PG_AND_BOUNDED_PIN_ACCESS_ONLY
da_status METAL_FILL_STATUS DEFERRED_TO_FINAL_CHIP_INTEGRATION
da_status INNOVUS_EXECUTED YES
da_status PVS_EXECUTED NO
da_status SIGNOFF_READY NO

set main_rc [catch {da_main} main_error main_options]
if {$main_rc != 0} {
    da_status STATUS FAIL
    da_status RESULT PHASE_IMPLEMENTATION_FAILED
    da_status ERROR $main_error
    da_status NEXT_GATE STOP_AND_REVIEW_INNOVUS_FAILURE
}
da_write_status
if {$main_rc == 0} {
    exit 0
}
exit 8
