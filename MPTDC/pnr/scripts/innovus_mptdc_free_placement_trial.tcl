# =============================================================================
# Isolated MPTDC free-placement trial profile
# =============================================================================
# This profile reuses the canonical import, PG, CTS, route, extraction, and
# reporting helpers. It changes only the physical exploration policy and is
# never selected by the canonical driver unless MPTDC_INNOVUS_INIT_TCL points
# here explicitly.

proc mptdc_free_default_env {name value} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        set ::env($name) $value
    }
}

proc mptdc_free_force_env {name value} {
    set ::env($name) $value
}

if {[info exists ::env(MPTDC_REPO_ROOT)] && $::env(MPTDC_REPO_ROOT) ne ""} {
    set mptdc_free_repo_root [file normalize $::env(MPTDC_REPO_ROOT)]
} else {
    set mptdc_free_repo_root [file normalize [file join [file dirname [info script]] ../../..]]
}

mptdc_free_default_env MPTDC_PNR_CORE_UTIL 0.50
mptdc_free_force_env MPTDC_PNR_ASPECT_RATIO 1.333333
mptdc_free_force_env MPTDC_PNR_FREE_ALL_INTERNAL_PLACEMENT 1
mptdc_free_force_env MPTDC_PNR_FREE_INTERNAL_PLACEMENT 1
mptdc_free_force_env MPTDC_PNR_FREE_DIGITAL_ONLY_PLACEMENT 0
mptdc_free_force_env MPTDC_PD_PHYSICAL_AUDIT_MODE free_internal
mptdc_free_force_env MPTDC_ALLOW_RELAXED_PD_MATRIX 1
mptdc_free_force_env MPTDC_PNR_PD_TILE_CONSTRAINT_MODE none
mptdc_free_force_env MPTDC_PNR_PD_TILE_APPLY_HIER_BOX 0
mptdc_free_force_env MPTDC_PNR_PD_TILE_USE_FENCE 0
mptdc_free_force_env MPTDC_PNR_PD_TILE_PREPLACE_LEAVES 0
mptdc_free_force_env MPTDC_PNR_PD_TILE_FIX_LEAVES 0
mptdc_free_force_env MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN 0
mptdc_free_force_env MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE 1
mptdc_free_force_env MPTDC_PNR_FIX_RO_MACROS 0
mptdc_free_force_env MPTDC_PNR_CREATE_RO_HALOS 0
mptdc_free_force_env MPTDC_PNR_CREATE_RO_ROUTE_BLOCKAGES 0
mptdc_free_force_env MPTDC_RO_HALO_POSTPLACE_AUDIT_FATAL 0
mptdc_free_force_env MPTDC_RO_PHASE_POSTPLACE_AUDIT_FATAL 0
mptdc_free_force_env MPTDC_POSTROUTE_SETUP_OPT_PASSES 2
mptdc_free_force_env MPTDC_POSTROUTE_SETUP_OPT_MAX_PASSES 2
mptdc_free_force_env MPTDC_POSTROUTE_HOLD_OPT_PASSES 2
mptdc_free_force_env MPTDC_POSTROUTE_HOLD_OPT_MAX_PASSES 2
mptdc_free_force_env MPTDC_PNR_FAST_TAG_TIMING_FOCUS 0
mptdc_free_force_env MPTDC_PNR_FAST_TAG_TARGETED_ECO 0
mptdc_free_force_env MPTDC_DISABLE_ANTENNA_REPAIR 1
mptdc_free_force_env MPTDC_ENABLE_FINAL_FILLER 1
mptdc_free_force_env MPTDC_FILLER_ADD_FILLERS_WITH_DRC 0
mptdc_free_force_env MPTDC_FREE_RO_SOFT_HALO_UM 8.0
mptdc_free_force_env MPTDC_ENABLE_RO_BLOCK_RINGS 1
mptdc_free_force_env MPTDC_RO_BLOCK_RING_WIDTH_UM 2.0
mptdc_free_force_env MPTDC_RO_BLOCK_RING_SPACING_UM 1.0
mptdc_free_force_env MPTDC_RO_BLOCK_RING_OFFSET_UM 2.0
mptdc_free_force_env MPTDC_BREAK_PG_STRIPES_AT_RO_BLOCK_RINGS 1
mptdc_free_force_env MPTDC_PG_STRATEGY innovus_sroute_golden_ro
mptdc_free_force_env MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE 1
mptdc_free_force_env MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN 1
mptdc_free_force_env MPTDC_ENABLE_RO_PG_PROBE 1
mptdc_free_force_env MPTDC_ENABLE_RO_PG_HOOKUP 0
mptdc_free_force_env MPTDC_REQUIRE_RO_PG_HOOKUP 0
mptdc_free_force_env MPTDC_ROUTE_GATE_SROUTE_RECOVERY 0
mptdc_free_force_env MPTDC_SROUTE_MODE_PROFILE block_pin_width
mptdc_free_default_env MPTDC_FREE_EXPECTED_TIE_HIGH_TARGETS 91
mptdc_free_default_env MPTDC_FREE_TIE_HIGH_MASTER LOGIC1DJIHD
mptdc_free_default_env MPTDC_FREE_TIE_LOW_MASTER LOGIC0DJIHD
mptdc_free_default_env MPTDC_FREE_TIE_MAX_FANOUT 8
mptdc_free_default_env MPTDC_FREE_TIE_MAX_DISTANCE_UM 20

set ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY) 1
source [file join $mptdc_free_repo_root MPTDC pnr scripts innovus_mptdc_digital_signoff.tcl]
unset ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY)

set ::env(MPTDC_TIE1_TRIAL_LIBRARY_ONLY) 1
source [file join $mptdc_free_repo_root MPTDC pnr scripts innovus_mptdc_tie1_insertion_trial.tcl]
unset ::env(MPTDC_TIE1_TRIAL_LIBRARY_ONLY)
source [file join $mptdc_free_repo_root MPTDC pnr scripts innovus_mptdc_place_utils.tcl]
source [file join $mptdc_free_repo_root MPTDC pnr scripts innovus_o10_io_pins.tcl]

proc mptdc_free_validate_contract {} {
    set util [expr {double($::env(MPTDC_PNR_CORE_UTIL))}]
    if {abs($util - 0.50) > 0.000001 && abs($util - 0.45) > 0.000001} {
        error "MPTDC_FREE_UTILIZATION_CONTRACT_FAILED: expected 0.50 or 0.45, got $util"
    }
    foreach {name expected} {
        MPTDC_PNR_FREE_ALL_INTERNAL_PLACEMENT 1
        MPTDC_PNR_PD_TILE_APPLY_HIER_BOX 0
        MPTDC_PNR_PD_TILE_USE_FENCE 0
        MPTDC_PNR_PD_TILE_PREPLACE_LEAVES 0
        MPTDC_PNR_PD_TILE_FIX_LEAVES 0
        MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN 0
        MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE 1
        MPTDC_PNR_CREATE_RO_HALOS 0
        MPTDC_PNR_CREATE_RO_ROUTE_BLOCKAGES 0
        MPTDC_DISABLE_ANTENNA_REPAIR 1
        MPTDC_POSTROUTE_SETUP_OPT_PASSES 2
        MPTDC_POSTROUTE_SETUP_OPT_MAX_PASSES 2
        MPTDC_POSTROUTE_HOLD_OPT_PASSES 2
        MPTDC_POSTROUTE_HOLD_OPT_MAX_PASSES 2
        MPTDC_PNR_FAST_TAG_TIMING_FOCUS 0
        MPTDC_PNR_FAST_TAG_TARGETED_ECO 0
        MPTDC_FILLER_ADD_FILLERS_WITH_DRC 0
        MPTDC_FREE_RO_SOFT_HALO_UM 8.0
        MPTDC_ENABLE_RO_BLOCK_RINGS 1
        MPTDC_BREAK_PG_STRIPES_AT_RO_BLOCK_RINGS 1
        MPTDC_PG_STRATEGY innovus_sroute_golden_ro
        MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE 1
        MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN 1
        MPTDC_ENABLE_RO_PG_PROBE 1
        MPTDC_ENABLE_RO_PG_HOOKUP 0
        MPTDC_REQUIRE_RO_PG_HOOKUP 0
        MPTDC_ROUTE_GATE_SROUTE_RECOVERY 0
        MPTDC_SROUTE_MODE_PROFILE block_pin_width
    } {
        if {![info exists ::env($name)] || $::env($name) ne $expected} {
            error "MPTDC_FREE_PROFILE_CONTRACT_FAILED: $name expected=$expected actual=[expr {[info exists ::env($name)] ? $::env($name) : {MISSING}}]"
        }
    }
    return PASS
}

proc mptdc_free_order_inputs {pins} {
    set first {}
    set rest {}
    foreach pin [lsort -dictionary $pins] {
        if {[regexp -nocase {(^|_)(clk|rst|reset|start|stop|spad|cal)} $pin]} {
            lappend first $pin
        } else {
            lappend rest $pin
        }
    }
    return [concat $first $rest]
}

proc mptdc_free_order_outputs {pins} {
    set first {}
    set rest {}
    foreach pin [lsort -dictionary $pins] {
        if {[regexp -nocase {^(pkt_|packet_)} $pin]} {
            lappend first $pin
        } else {
            lappend rest $pin
        }
    }
    return [concat $first $rest]
}

proc mptdc_free_split_at_capacity {pins capacity} {
    if {$capacity < 1} {
        return [list {} $pins]
    }
    return [list [lrange $pins 0 [expr {$capacity - 1}]] [lrange $pins $capacity end]]
}

proc mptdc_free_place_directional_io {} {
    set reports [mptdc_signoff_report_dir]
    set summary [file join $reports free_io_pin_placement.rpt]
    set csv [file join $reports free_io_pin_placement.tsv]
    set ports [mptdc_o10_io_pin_port_names]
    set inputs {}
    set outputs {}
    set other {}
    foreach pin $ports {
        if {[string tolower $pin] in {vdd vss gnd gnd! vdd!}} {
            lappend other $pin
            continue
        }
        set direction [string tolower [lindex [mptdc_o10_io_pin_direction $pin] 0]]
        if {$direction in {in input}} {
            lappend inputs $pin
        } elseif {$direction in {out output}} {
            lappend outputs $pin
        } else {
            lappend other $pin
        }
    }

    set core [mptdc_signoff_core_box]
    if {![mptdc_signoff_box_valid $core]} {
        error "MPTDC_FREE_IO_CORE_BOX_MISSING"
    }
    set spacing [expr {double([mptdc_o10_io_pin_spacing_um])}]
    set vertical_capacity [expr {int(floor(([mptdc_signoff_box_height $core] - 4.0) / $spacing))}]
    set horizontal_capacity [expr {int(floor(([mptdc_signoff_box_width $core] - 4.0) / $spacing))}]
    lassign [mptdc_free_split_at_capacity [mptdc_free_order_inputs $inputs] $vertical_capacity] west south_overflow
    lassign [mptdc_free_split_at_capacity [mptdc_free_order_outputs $outputs] $vertical_capacity] east north_overflow
    set south [concat $south_overflow [lsort -dictionary $other]]
    set north $north_overflow

    set status PASS
    set command_rows {}
    foreach {side pins} [list WEST $west EAST $east NORTH $north SOUTH $south] {
        set result [mptdc_o10_io_pin_apply_side $side $pins]
        lappend command_rows [list $side [lindex $result 0] [lindex $result 1]]
        if {[lindex $result 0] eq "FAILED"} {
            set status FAIL
        }
    }

    set fh [open $csv w]
    puts $fh "pin\tdirection\tside"
    foreach {side pins} [list WEST $west EAST $east NORTH $north SOUTH $south] {
        foreach pin $pins {
            puts $fh "$pin\t[mptdc_o10_io_pin_direction $pin]\t$side"
        }
    }
    close $fh

    set fh [open $summary w]
    puts $fh "IO_POLICY=INPUTS_WEST_OUTPUTS_EAST_DETERMINISTIC_OVERFLOW"
    puts $fh "WEST_PIN_COUNT=[llength $west]"
    puts $fh "EAST_PIN_COUNT=[llength $east]"
    puts $fh "NORTH_OVERFLOW_PIN_COUNT=[llength $north]"
    puts $fh "SOUTH_OVERFLOW_AND_OTHER_PIN_COUNT=[llength $south]"
    puts $fh "VERTICAL_SIDE_CAPACITY=$vertical_capacity"
    puts $fh "HORIZONTAL_SIDE_CAPACITY=$horizontal_capacity"
    foreach row $command_rows {
        puts $fh "SIDE_[lindex $row 0]_STATUS=[lindex $row 1]"
        puts $fh "SIDE_[lindex $row 0]_COMMAND=[lindex $row 2]"
    }
    puts $fh "IO_STATUS=$status"
    puts $fh "PIN_INVENTORY=$csv"
    close $fh
    mptdc_signoff_set_status IO_STATUS $status $summary
    if {$status ne "PASS"} {
        error "MPTDC_FREE_IO_PLACEMENT_FAILED: report=$summary"
    }
}

proc mptdc_free_ro_instances {} {
    set ro_instances [mptdc_signoff_collect_cells [mptdc_signoff_ro_cell_patterns]]
    if {[llength $ro_instances] != 2} {
        error "MPTDC_FREE_RO_COUNT_FAILED: expected=2 actual=[llength $ro_instances]"
    }
    set slow [lindex $ro_instances 0]
    set fast [lindex $ro_instances 1]
    foreach ro $ro_instances {
        if {[regexp -nocase {slow} $ro]} { set slow $ro }
        if {[regexp -nocase {fast} $ro]} { set fast $ro }
    }
    return [list $slow $fast]
}

proc mptdc_free_seed_ro_macros {} {
    lassign [mptdc_free_ro_instances] slow fast
    set core [mptdc_signoff_core_box]
    set width [expr {double([mptdc_signoff_env MPTDC_PNR_OSC_WIDTH_UM 10.0])}]
    set height [expr {double([mptdc_signoff_env MPTDC_PNR_OSC_HEIGHT_UM 10.0])}]
    set x_span [expr {[mptdc_signoff_box_width $core] - $width}]
    set y_span [expr {[mptdc_signoff_box_height $core] - $height}]
    if {$x_span <= 0.0 || $y_span <= 0.0} {
        error "MPTDC_FREE_RO_DOES_NOT_FIT_CORE"
    }
    set slow_x [expr {[lindex $core 0] + 0.18 * $x_span}]
    set slow_y [expr {[lindex $core 1] + 0.63 * $y_span}]
    set fast_x [expr {[lindex $core 0] + 0.63 * $x_span}]
    set fast_y [expr {[lindex $core 1] + 0.18 * $y_span}]
    set rpt [file join [mptdc_signoff_report_dir] free_ro_seed_status.rpt]
    set fh [open $rpt w]
    puts $fh "RO_SEED_POLICY=BROAD_DIAGONAL_MOVABLE_R0_MX"
    foreach row [list [list SLOW $slow $slow_x $slow_y R0] [list FAST $fast $fast_x $fast_y MX]] {
        lassign $row family inst x y orient
        set command [list placeInstance $inst $x $y $orient]
        puts $fh "${family}_INSTANCE=$inst"
        puts $fh "${family}_SEED=[format %.3f $x],[format %.3f $y],$orient"
        puts $fh "${family}_FIXED_AT_SEED=NO"
        if {[catch {uplevel #0 $command} err]} {
            puts $fh "RO_SEED_STATUS=FAIL"
            puts $fh "ERROR=$err"
            close $fh
            error "MPTDC_FREE_RO_SEED_FAILED: $err"
        }
    }
    puts $fh "RO_SEED_STATUS=PASS"
    close $fh
    mptdc_signoff_set_status RO_MACRO_STATUS PROVISIONAL $rpt
}

proc mptdc_free_create_soft_halo {inst name margin} {
    set box [mptdc_signoff_expand_box [mptdc_signoff_cell_box $inst] $margin]
    if {![mptdc_signoff_box_valid $box]} {
        error "MPTDC_FREE_SOFT_HALO_BOX_INVALID: instance=$inst"
    }
    foreach command [list \
        [list createPlaceBlockage -name $name -type soft -box $box] \
        [list createPlaceBlockage -type soft -box $box]] {
        if {![catch {uplevel #0 $command} err]} {
            return [list $box $command]
        }
    }
    error "MPTDC_FREE_SOFT_HALO_CREATE_FAILED: instance=$inst error=$err"
}

proc mptdc_free_mark_unplaced {inst} {
    set errors {}
    set commands {}
    set ptr [mptdc_pnr_place_db_ptr $inst]
    if {$ptr ne ""} {
        lappend commands [list dbSet ${ptr}.pStatus unplaced]
    }
    lappend commands \
        [list setInstancePlacementStatus -status unplaced -name $inst] \
        [list set_db inst:$inst .place_status unplaced]

    foreach command $commands {
        if {[catch {uplevel #0 $command} err]} {
            lappend errors "$command: $err"
            continue
        }
        set actual [string tolower [mptdc_pnr_place_query_attr $inst {pStatus place_status status}]]
        if {$actual eq "unplaced"} {
            return [dict create status PASS command $command actual_status $actual errors $errors]
        }
        lappend errors "$command: post_status=$actual"
    }
    return [dict create status FAIL command "" actual_status \
        [mptdc_pnr_place_query_attr $inst {pStatus place_status status}] errors $errors]
}

proc mptdc_free_box_inside {inner outer} {
    if {![mptdc_signoff_box_valid $inner] || ![mptdc_signoff_box_valid $outer]} {
        return 0
    }
    set epsilon 0.001
    return [expr {
        [lindex $inner 0] >= [lindex $outer 0] - $epsilon &&
        [lindex $inner 1] >= [lindex $outer 1] - $epsilon &&
        [lindex $inner 2] <= [lindex $outer 2] + $epsilon &&
        [lindex $inner 3] <= [lindex $outer 3] + $epsilon
    }]
}

proc mptdc_free_macro_aware_place_and_freeze {} {
    set rpt [file join [mptdc_signoff_report_dir] free_macro_aware_placement.rpt]
    set fh [open $rpt w]
    set ro_instances [mptdc_free_ro_instances]
    set unplaced_count 0
    set index 0
    foreach inst $ro_instances {
        set before [mptdc_pnr_place_query_attr $inst {pStatus place_status status}]
        set transition [mptdc_free_mark_unplaced $inst]
        puts $fh "RO_${index}_INSTANCE=$inst"
        puts $fh "RO_${index}_PRE_CONCURRENT_STATUS=$before"
        puts $fh "RO_${index}_UNPLACE_COMMAND=[dict get $transition command]"
        puts $fh "RO_${index}_UNPLACE_STATUS=[dict get $transition status]"
        puts $fh "RO_${index}_POST_UNPLACE_STATUS=[dict get $transition actual_status]"
        puts $fh "RO_${index}_UNPLACE_ERRORS=[dict get $transition errors]"
        if {[dict get $transition status] ne "PASS"} {
            puts $fh "MACRO_AWARE_PLACEMENT_STATUS=FAIL"
            close $fh
            error "MPTDC_FREE_RO_UNPLACE_FAILED: instance=$inst errors=[dict get $transition errors]"
        }
        incr unplaced_count
        incr index
    }
    puts $fh "RO_UNPLACED_FOR_CONCURRENT_COUNT=$unplaced_count"

    set command [list place_design -concurrent_macros]
    puts $fh "MACRO_AWARE_COMMAND=$command"
    if {[catch {uplevel #0 $command} command_error]} {
        puts $fh "MACRO_AWARE_COMMAND_STATUS=FAIL"
        puts $fh "MACRO_AWARE_COMMAND_ERROR=$command_error"
        puts $fh "MACRO_AWARE_PLACEMENT_STATUS=FAIL"
        close $fh
        error "MPTDC_FREE_MACRO_AWARE_PLACEMENT_FAILED: $command_error"
    }
    puts $fh "MACRO_AWARE_COMMAND_STATUS=PASS"
    puts $fh "MACRO_AWARE_COMMAND_ERROR=NONE"

    set halo_margin [expr {double([mptdc_signoff_env MPTDC_FREE_RO_SOFT_HALO_UM 8.0])}]
    set core [mptdc_signoff_core_box]
    set final_boxes {}
    set index 0
    foreach inst $ro_instances {
        set final_status [mptdc_pnr_place_query_attr $inst {pStatus place_status status}]
        set final_box [mptdc_signoff_cell_box $inst]
        set in_core [mptdc_free_box_inside $final_box $core]
        puts $fh "RO_${index}_POST_CONCURRENT_STATUS=$final_status"
        puts $fh "RO_${index}_FINAL_BBOX=$final_box"
        puts $fh "RO_${index}_IN_CORE_STATUS=[expr {$in_core ? {PASS} : {FAIL}}]"
        if {![mptdc_pnr_place_status_is_placed $final_status] || !$in_core} {
            puts $fh "MACRO_AWARE_PLACEMENT_STATUS=FAIL"
            close $fh
            error "MPTDC_FREE_RO_CONCURRENT_READBACK_FAILED: instance=$inst status=$final_status box=$final_box"
        }
        lappend final_boxes $final_box
        incr index
    }
    set ro_overlap [mptdc_signoff_box_overlap_area [lindex $final_boxes 0] [lindex $final_boxes 1]]
    puts $fh "RO_PAIR_OVERLAP_AREA_UM2=[format %.6f $ro_overlap]"
    puts $fh "RO_PAIR_NONOVERLAP_STATUS=[expr {$ro_overlap <= 0.0 ? {PASS} : {FAIL}}]"
    if {$ro_overlap > 0.0} {
        puts $fh "MACRO_AWARE_PLACEMENT_STATUS=FAIL"
        close $fh
        error "MPTDC_FREE_RO_CONCURRENT_OVERLAP_FAILED: overlap=$ro_overlap"
    }

    set fixed_count 0
    set halo_count 0
    set index 0
    foreach inst $ro_instances {
        set fixed [mptdc_pnr_place_mark_fixed $inst]
        puts $fh "RO_${index}_FIX_COMMAND=[dict get $fixed command]"
        puts $fh "RO_${index}_FIX_STATUS=[dict get $fixed status]"
        if {[dict get $fixed status] ne "PASS"} {
            puts $fh "MACRO_AWARE_PLACEMENT_STATUS=FAIL"
            close $fh
            error "MPTDC_FREE_RO_FREEZE_FAILED: instance=$inst"
        }
        incr fixed_count
        set halo [mptdc_free_create_soft_halo $inst "MPTDC_FREE_RO_SOFT_HALO_$index" $halo_margin]
        puts $fh "RO_${index}_SOFT_HALO_BOX=[lindex $halo 0]"
        puts $fh "RO_${index}_SOFT_HALO_COMMAND=[lindex $halo 1]"
        incr halo_count
        incr index
    }
    puts $fh "RO_FIXED_AFTER_MACRO_AWARE_PLACEMENT_COUNT=$fixed_count"
    puts $fh "RO_SOFT_HALO_COUNT=$halo_count"
    puts $fh "RO_SOFT_HALO_MARGIN_UM=$halo_margin"
    puts $fh "RO_HARD_HALO_COUNT=0"
    puts $fh "RO_ROUTE_BLOCKAGE_COUNT=0"
    puts $fh "MACRO_AWARE_PLACEMENT_STATUS=PASS"
    close $fh
    mptdc_signoff_set_status RO_MACRO_STATUS PASS $rpt
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 01_macro_place.enc]}
}

proc mptdc_free_capture_manager_image {name} {
    set manager [file join [mptdc_signoff_result_dir] manager]
    file mkdir $manager
    set path [file join $manager "${name}.gif"]
    set status MISSING_OPTIONAL
    set selected NONE
    catch {fit}
    catch {gui_fit}
    foreach command [list [list dumpToGIF $path] [list saveImage $path] [list save_image $path]] {
        catch {file delete -force $path}
        if {![catch {uplevel #0 $command} err] && [file exists $path] && [file size $path] > 0} {
            set status PASS
            set selected $command
            break
        }
    }
    set rpt [file join [mptdc_signoff_report_dir] "manager_${name}_image_status.rpt"]
    set fh [open $rpt w]
    puts $fh "MANAGER_IMAGE=$path"
    puts $fh "MANAGER_IMAGE_STATUS=$status"
    puts $fh "MANAGER_IMAGE_COMMAND=$selected"
    puts $fh "MANUAL_GUI_FALLBACK_REQUIRED=[expr {$status eq {PASS} ? {NO} : {YES}}]"
    close $fh
    return $status
}

proc mptdc_free_initialize_tie_queries {} {
    catch {unset ::mptdc_tie1_trial_query_error}
    array set ::mptdc_tie1_trial_query_error {}
    set ::mptdc_tie1_trial_query_error_count 0
    set ::mptdc_tie1_trial_core_query_error_count 0
}

proc mptdc_free_insert_ties {} {
    mptdc_free_initialize_tie_queries
    set reports [mptdc_signoff_report_dir]
    set expected_count [expr {int($::env(MPTDC_FREE_EXPECTED_TIE_HIGH_TARGETS))}]
    set high_master $::env(MPTDC_FREE_TIE_HIGH_MASTER)
    set low_master $::env(MPTDC_FREE_TIE_LOW_MASTER)
    set max_fanout [expr {int($::env(MPTDC_FREE_TIE_MAX_FANOUT))}]
    set max_distance [expr {double($::env(MPTDC_FREE_TIE_MAX_DISTANCE_UM))}]
    set baseline [mptdc_tie1_trial_flagged_state baseline \
        [file join $reports tie1_flagged_terms_baseline.tsv]]
    if {[dict get $baseline hi_count] != $expected_count ||
        [dict get $baseline lo_count] != 0 ||
        [dict get $baseline disconnected] != $expected_count} {
        error "MPTDC_FREE_TIE_BASELINE_FAILED: hi=[dict get $baseline hi_count] lo=[dict get $baseline lo_count] disconnected=[dict get $baseline disconnected] expected=$expected_count"
    }

    set targets [file join [mptdc_signoff_result_dir] manifests tie1_instance_pin_targets.txt]
    set fh [open $targets w]
    foreach name [lsort -dictionary [dict get $baseline hi_names]] {
        puts $fh $name
    }
    close $fh

    set mode_cmd [list setTieHiLoMode -cell "$high_master $low_master" \
        -maxFanout $max_fanout -maxDistance $max_distance \
        -honorDontUse false -honorDontTouch false]
    if {[catch {uplevel #0 $mode_cmd} mode_error]} {
        error "MPTDC_FREE_SET_TIE_MODE_FAILED: $mode_error"
    }
    set add_cmd [list addTieHiLo -cell "$high_master $low_master" \
        -instancePin $targets -prefix MPTDC_FREE_TIE1]
    set command_report [file join $reports addTieHiLo_free_trial.rpt]
    if {[catch {uplevel #0 [concat $add_cmd [list > $command_report]]} add_error]} {
        error "MPTDC_FREE_ADD_TIE_FAILED: $add_error"
    }

    set post [mptdc_tie1_trial_target_state post_add \
        [dict get $baseline hi_pointer_name_pairs] [dict get $baseline hi_names] \
        [file join $reports tie1_target_readback_post_add.tsv]]
    if {[dict get $post target_set_status] ne "PASS" ||
        [dict get $post connected] != $expected_count ||
        [dict get $post disconnected] != 0} {
        error "MPTDC_FREE_TIE_EFFECT_FAILED: set=[dict get $post target_set_status] connected=[dict get $post connected] disconnected=[dict get $post disconnected]"
    }

    set legalize_status PASS
    if {[catch {refinePlace} legalize_error]} {
        if {[catch {placeDesign -incremental} legalize_error]} {
            set legalize_status FAIL
        }
    }
    if {$legalize_status ne "PASS"} {
        error "MPTDC_FREE_TIE_LEGALIZE_FAILED: $legalize_error"
    }
    set place_gate [mptdc_signoff_capture_placement_gate \
        post_tie \
        [file join $reports check_place_post_tie.rpt] \
        [file join $reports placement_post_tie_status.rpt] 1]
    if {[dict get $place_gate status] ne "PASS"} {
        error "MPTDC_FREE_TIE_POST_PLACE_FAILED: [dict get $place_gate status_report]"
    }

    set ::mptdc_free_tie_pointer_pairs [dict get $baseline hi_pointer_name_pairs]
    set ::mptdc_free_tie_expected_names [dict get $baseline hi_names]
    set ::mptdc_free_tie_expected_count $expected_count
    set ::mptdc_free_tie_high_master $high_master
    set ::mptdc_free_tie_max_fanout $max_fanout
    set rpt [file join $reports tie1_insertion_status.rpt]
    set fh [open $rpt w]
    puts $fh "TIE1_INSERTION_STAGE=PRE_CTS_PRE_FILLER"
    puts $fh "TIE1_TARGET_COUNT=$expected_count"
    puts $fh "TIE1_CONNECTED_TARGET_COUNT=[dict get $post connected]"
    puts $fh "TIE1_DISCONNECTED_TARGET_COUNT=[dict get $post disconnected]"
    puts $fh "TIE1_TARGET_SET_STATUS=[dict get $post target_set_status]"
    puts $fh "TIE1_LOGICAL_DONT_TOUCH_OVERRIDE_SCOPE=ADD_TIE_COMMAND_ONLY"
    puts $fh "TIE1_INSERTION_STATUS=PASS"
    puts $fh "TARGET_FILE=$targets"
    close $fh
    mptdc_signoff_set_status TIE1_INSERTION_STATUS PASS $rpt
    catch {saveDesign [file join [mptdc_signoff_checkpoint_dir] 02_tie_inserted.enc]}
}

proc mptdc_free_gate_routed_ties {} {
    set reports [mptdc_signoff_report_dir]
    set final [mptdc_tie1_trial_target_state final \
        $::mptdc_free_tie_pointer_pairs $::mptdc_free_tie_expected_names \
        [file join $reports tie1_target_readback_final.tsv]]
    set inventory [mptdc_tie1_trial_write_net_inventory $final \
        $::mptdc_free_tie_high_master [file join $reports tie1_inserted_net_inventory.tsv]]
    set status PASS
    if {[dict get $final target_set_status] ne "PASS" ||
        [dict get $final connected] != $::mptdc_free_tie_expected_count ||
        [dict get $final disconnected] != 0 ||
        [dict get $inventory net_count] < 1 ||
        [dict get $inventory contract_status] ne "PASS" ||
        [dict get $inventory route_status] ne "PASS" ||
        [dict get $inventory max_observed_fanout] > $::mptdc_free_tie_max_fanout} {
        set status FAIL
    }
    set rpt [file join $reports tie1_routed_status.rpt]
    set fh [open $rpt w]
    puts $fh "TIE1_FINAL_TARGET_SET_STATUS=[dict get $final target_set_status]"
    puts $fh "TIE1_FINAL_CONNECTED_TARGET_COUNT=[dict get $final connected]"
    puts $fh "TIE1_FINAL_DISCONNECTED_TARGET_COUNT=[dict get $final disconnected]"
    puts $fh "TIE1_FINAL_NET_COUNT=[dict get $inventory net_count]"
    puts $fh "TIE1_NET_CONTRACT_STATUS=[dict get $inventory contract_status]"
    puts $fh "TIE1_NET_ROUTE_STATUS=[dict get $inventory route_status]"
    puts $fh "TIE1_MAX_OBSERVED_FANOUT=[dict get $inventory max_observed_fanout]"
    puts $fh "TIE1_ROUTED_STATUS=$status"
    close $fh
    mptdc_signoff_set_status TIE1_INSERTION_STATUS $status $rpt
    if {$status ne "PASS"} {
        error "MPTDC_FREE_TIE_ROUTE_GATE_FAILED: report=$rpt"
    }
}

proc mptdc_free_write_profile_report {} {
    set reports [mptdc_signoff_report_dir]
    set status [expr {
        [mptdc_signoff_status_state MPTDC_TC_PNR_CLOSURE] eq "PASS" &&
        [mptdc_signoff_status_state TIE1_INSERTION_STATUS] eq "PASS" ? "PASS" : "FAIL"
    }]
    set rpt [file join $reports operator_gate_mptdc_free_placement_trial.rpt]
    set fh [open $rpt w]
    puts $fh "STEP=MPTDC_FREE_PLACEMENT_TRIAL"
    puts $fh "PNR_PROFILE=ISOLATED_FREE_PLACEMENT_TRIAL"
    puts $fh "CANONICAL_PROFILE_DEFAULT_CHANGED=NO"
    puts $fh "GENUS_HANDOFF_REUSED=YES"
    puts $fh "CLOSURE_SCOPE=TC_ONLY"
    puts $fh "CORE_ASPECT_TARGET=4:3"
    puts $fh "CORE_UTILIZATION=$::env(MPTDC_PNR_CORE_UTIL)"
    puts $fh "PD_MATRIX_PHYSICAL_CONSTRAINTS=NONE"
    puts $fh "IO_POLICY=INPUTS_WEST_OUTPUTS_EAST_DETERMINISTIC_OVERFLOW"
    puts $fh "RO_POLICY=BROAD_MOVABLE_SEEDS_THEN_MACRO_AWARE_PLACE_AND_FREEZE"
    puts $fh "RO_SOFT_HALO_UM=$::env(MPTDC_FREE_RO_SOFT_HALO_UM)"
    puts $fh "RO_BLOCK_RING_POLICY=ONE_SELECTED_CLUSTER_RING_PER_RO_WITH_SWIRE_GROWTH_PROOF"
    puts $fh "RO_BLOCK_RING_ENABLE=$::env(MPTDC_ENABLE_RO_BLOCK_RINGS)"
    puts $fh "PG_STRIPE_BLOCK_RING_BREAK=$::env(MPTDC_BREAK_PG_STRIPES_AT_RO_BLOCK_RINGS)"
    puts $fh "PG_STRATEGY=$::env(MPTDC_PG_STRATEGY)"
    puts $fh "SROUTE_MODE_PROFILE=$::env(MPTDC_SROUTE_MODE_PROFILE)"
    puts $fh "LOGICAL_DONT_TOUCH_CHANGE_COUNT=0"
    puts $fh "ANTENNA_REPAIR_ATTEMPTED=NO"
    puts $fh "ANTENNA_EXCEPTION_POLICY=MANAGER_EXCEPTION_REPORT_ONLY"
    puts $fh "POSTROUTE_SETUP_OPT_PASSES=2"
    puts $fh "POSTROUTE_HOLD_OPT_PASSES=2"
    puts $fh "FAST_TAG_TARGETED_ECO=DISABLED_FOR_FREE_PLACEMENT_PROFILE"
    puts $fh "PLACEMENT_STATUS=[mptdc_signoff_status_state PLACEMENT_STATUS]"
    puts $fh "PG_CONNECTIVITY_STATUS=[mptdc_signoff_status_state PG_CONNECTIVITY_STATUS]"
    puts $fh "CTS_STATUS=[mptdc_signoff_status_state CTS_STATUS]"
    puts $fh "ROUTE_STATUS=[mptdc_signoff_status_state ROUTE_STATUS]"
    puts $fh "SETUP_STATUS_TC=[mptdc_signoff_status_state SETUP_STATUS_TC]"
    puts $fh "TC_HOLD_STATUS=[mptdc_signoff_status_state TC_HOLD_STATUS]"
    puts $fh "DRV_STATUS=[mptdc_signoff_status_state DRV_STATUS]"
    puts $fh "TIE1_INSERTION_STATUS=[mptdc_signoff_status_state TIE1_INSERTION_STATUS]"
    puts $fh "MPTDC_TC_PNR_CLOSURE=[mptdc_signoff_status_state MPTDC_TC_PNR_CLOSURE]"
    puts $fh "FOUNDRY_DRC_STATUS=NOT_RUN"
    puts $fh "LVS_STATUS=NOT_RUN"
    puts $fh "SIGNOFF_ELIGIBLE=NO"
    puts $fh "MPTDC_FREE_PLACEMENT_TRIAL_STATUS=$status"
    puts $fh "DECISION=[expr {$status eq {PASS} ? {PASS_READY_FOR_BASE_DRC_AND_LVS} : {FAIL_STOP}}]"
    puts $fh "NEXT_STAGE=[expr {$status eq {PASS} ? {PVS_BASE_DRC_THEN_FULL_LVS} : {STOP_AND_REVIEW}}]"
    close $fh
    return $status
}

proc mptdc_free_main {} {
    mptdc_free_validate_contract
    mptdc_signoff_apply_recovery_defaults
    mptdc_signoff_pg_policy_guard
    mptdc_signoff_mkdirs
    mptdc_signoff_init_status
    mptdc_signoff_stage source_gate PHYSICAL_CELL_CONFIG_STATUS {
        mptdc_signoff_check_physical_cell_policy implementation
        mptdc_signoff_write_policy_manifest
    }
    mptdc_signoff_stage import_mmmc GENUS_HANDOFF_STATUS {
        mptdc_signoff_load_design_context
        mptdc_signoff_initialize_design
    }
    mptdc_signoff_stage post_import_gate RO_IMPORT_STATUS { mptdc_signoff_post_import_gate }
    mptdc_signoff_stage post_import_tc_timing SETUP_STATUS_TC { mptdc_signoff_post_import_timing_gate }
    mptdc_signoff_stage floorplan FLOORPLAN_STATUS { mptdc_signoff_apply_floorplan }
    mptdc_signoff_stage io_placement IO_STATUS { mptdc_free_place_directional_io }
    mptdc_signoff_stage ro_seed RO_MACRO_STATUS { mptdc_free_seed_ro_macros }
    mptdc_signoff_stage macro_aware_placement RO_MACRO_STATUS {
        mptdc_free_macro_aware_place_and_freeze
        mptdc_free_capture_manager_image floorplan
    }
    mptdc_signoff_stage pg_connectivity PG_PHYSICAL_STATUS {
        mptdc_signoff_apply_pg_connectivity
        mptdc_signoff_write_pg_gate_template
        mptdc_signoff_build_power_grid
    }
    mptdc_signoff_stage pd_matrix_inventory PD_MATRIX_STATUS { mptdc_signoff_place_pd_matrix }
    mptdc_signoff_stage phase_buffer_inventory PHASE_BUFFER_STATUS { mptdc_signoff_place_phase_buffers }
    mptdc_signoff_stage row_infrastructure ROW_INFRA_POLICY_STATUS { mptdc_signoff_insert_row_infra }
    mptdc_signoff_stage placement PLACEMENT_STATUS { mptdc_signoff_place_design }
    mptdc_signoff_stage pre_cts_tie_insertion TIE1_INSERTION_STATUS { mptdc_free_insert_ties }
    mptdc_signoff_stage cts CTS_STATUS { mptdc_signoff_run_cts }
    mptdc_signoff_stage route ROUTE_STATUS { mptdc_signoff_route_design }
    mptdc_signoff_stage routed_tie_gate TIE1_INSERTION_STATUS { mptdc_free_gate_routed_ties }
    mptdc_signoff_stage extraction_sta EXTRACTION_STATUS { mptdc_signoff_extract_and_sta }
    mptdc_signoff_stage phase_and_backend_reports PHASE_LOAD_STATUS { mptdc_signoff_write_phase_and_backend_reports }
    mptdc_signoff_stage physical_verification_package DRC_STATUS { mptdc_signoff_write_final_package }
    catch {mptdc_signoff_capture_candidates \
        [file join [mptdc_signoff_report_dir] manager_route_congestion.rpt] \
        "Manager route congestion" [list {reportCongestion -hotSpot -num_hotspot 100 -overflow} {reportCongestion -overflow} {reportCongestion}]}
    mptdc_free_capture_manager_image route_congestion
    set status_path [mptdc_signoff_write_status]
    set profile_status [mptdc_free_write_profile_report]
    puts "MPTDC_FREE_PLACEMENT_TRIAL_STATUS=$profile_status"
    puts "MPTDC_DIGITAL_SIGNOFF_STATUS=$status_path"
    if {$profile_status ne "PASS"} {
        error "MPTDC_FREE_PLACEMENT_TRIAL_GATE_FAILED"
    }
}

if {[info exists ::env(MPTDC_FREE_PLACEMENT_LIBRARY_ONLY)] &&
    $::env(MPTDC_FREE_PLACEMENT_LIBRARY_ONLY)} {
    return
}

if {[info exists ::env(MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY)] && $::env(MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY)} {
    mptdc_free_validate_contract
    mptdc_signoff_source_check
    puts "MPTDC_FREE_PLACEMENT_SOURCE_CHECK=PASS"
    return
}

if {[catch {mptdc_free_main} err opts]} {
    puts "MPTDC_FREE_PLACEMENT_ERROR: $err"
    if {[dict exists $opts -errorinfo]} {
        puts [dict get $opts -errorinfo]
    }
    exit 1
}
