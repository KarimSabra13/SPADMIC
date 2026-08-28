# =============================================================================
# Project  : SPAD_MPTDC
# File     : innovus_mptdc_tie1_insertion_trial.tcl
# Purpose  : Disposable, bounded tie-high insertion and selected-net route trial
# =============================================================================

proc mptdc_tie1_trial_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_tie1_trial_required_env {name} {
    set value [mptdc_tie1_trial_env $name ""]
    if {$value eq ""} {
        error "missing required environment variable $name"
    }
    return $value
}

proc mptdc_tie1_trial_report_value {value} {
    set clean [string map [list "\r" " " "\n" " " "=" ":"] $value]
    regsub -all {[[:space:]]+} [string trim $clean] {_} clean
    if {$clean eq ""} {
        return NONE
    }
    return $clean
}

proc mptdc_tie1_trial_objects {value} {
    if {$value eq "" || $value eq "0x0" || $value eq "NULL"} {
        return {}
    }
    return $value
}

proc mptdc_tie1_trial_count {value} {
    set objects [mptdc_tie1_trial_objects $value]
    if {[catch {llength $objects} count]} {
        return 0
    }
    return $count
}

proc mptdc_tie1_trial_dbget {name required args} {
    set command [linsert $args 0 dbGet]
    if {[catch {uplevel #0 $command} result]} {
        set ::mptdc_tie1_trial_query_status($name) FAIL
        set ::mptdc_tie1_trial_query_error($name) \
            [mptdc_tie1_trial_report_value $result]
        incr ::mptdc_tie1_trial_query_error_count
        if {$required} {
            incr ::mptdc_tie1_trial_core_query_error_count
        }
        return ""
    }
    set ::mptdc_tie1_trial_query_status($name) PASS
    set ::mptdc_tie1_trial_query_error($name) NONE
    return $result
}

proc mptdc_tie1_trial_pointer_attr {pointer attribute {required 1}} {
    set name "pointer_[string map {. _ / _ \[ _ \] _} $attribute]"
    set value [mptdc_tie1_trial_dbget $name $required ${pointer}.${attribute}]
    if {$value eq "" || $value eq "0x0" || $value eq "NULL"} {
        return ""
    }
    return [string trim $value]
}

proc mptdc_tie1_trial_unique {items} {
    set result {}
    foreach item $items {
        if {$item eq ""} {
            continue
        }
        if {[lsearch -exact $result $item] < 0} {
            lappend result $item
        }
    }
    return $result
}

proc mptdc_tie1_trial_canonical_name {value} {
    set value [string trim $value]
    if {$value eq ""} {
        return ""
    }
    if {![catch {llength $value} count] && $count == 1} {
        return [lindex $value 0]
    }
    return $value
}

proc mptdc_tie1_trial_read_instance_pin_targets {path} {
    set targets {}
    set invalid_count 0
    if {![file exists $path] || ![file readable $path]} {
        return [dict create \
            status FAIL targets {} count 0 unique_count 0 invalid_count 1]
    }
    if {[catch {set fh [open $path r]}]} {
        return [dict create \
            status FAIL targets {} count 0 unique_count 0 invalid_count 1]
    }
    while {[gets $fh line] >= 0} {
        set target [string trim $line]
        if {$target eq "" || [regexp {[[:space:]]} $target] ||
            ![regexp {^.+/[^/]+$} $target]} {
            incr invalid_count
            continue
        }
        lappend targets $target
    }
    close $fh
    set unique_targets [lsort -unique $targets]
    set status [expr {$invalid_count == 0 ? "PASS" : "FAIL"}]
    return [dict create \
        status $status \
        targets $targets \
        count [llength $targets] \
        unique_count [llength $unique_targets] \
        invalid_count $invalid_count]
}

proc mptdc_tie1_trial_master_instances {master} {
    return [mptdc_tie1_trial_objects \
        [mptdc_tie1_trial_dbget "instances_$master" 1 \
            top.insts.cell.name $master -p2]]
}

proc mptdc_tie1_trial_master_count {master} {
    return [mptdc_tie1_trial_count [mptdc_tie1_trial_master_instances $master]]
}

proc mptdc_tie1_trial_filler_count {masters} {
    set count 0
    foreach master $masters {
        incr count [mptdc_tie1_trial_master_count $master]
    }
    return $count
}

proc mptdc_tie1_trial_filler_inventory {phase masters report_path} {
    set total 0
    set fh [open $report_path w]
    puts $fh "master\tinstance_count"
    foreach master $masters {
        set count [mptdc_tie1_trial_master_count $master]
        incr total $count
        puts $fh "$master\t$count"
    }
    close $fh
    return [dict create phase $phase total $total masters $masters]
}

proc mptdc_tie1_trial_nonfiller_fingerprint {phase excluded_masters report_path} {
    set rows {}
    set instances [mptdc_tie1_trial_objects \
        [mptdc_tie1_trial_dbget "${phase}_fingerprint_instances" 1 top.insts]]
    foreach inst $instances {
        set master [mptdc_tie1_trial_pointer_attr $inst cell.name]
        if {[lsearch -exact $excluded_masters $master] >= 0} {
            continue
        }
        set name [mptdc_tie1_trial_pointer_attr $inst name]
        set status [mptdc_tie1_trial_pointer_attr $inst pStatus]
        set orient [mptdc_tie1_trial_pointer_attr $inst orient]
        set box [mptdc_tie1_trial_pointer_attr $inst box]
        lappend rows [list $name $master $status $orient $box]
    }
    set rows [lsort $rows]
    set fh [open $report_path w]
    puts $fh "instance\tmaster\tplacement_status\torientation\tbox"
    foreach row $rows {
        puts $fh [join $row "\t"]
    }
    close $fh
    return [dict create phase $phase count [llength $rows] rows $rows]
}

proc mptdc_tie1_trial_route_signature {phase} {
    set nets [mptdc_tie1_trial_count \
        [mptdc_tie1_trial_dbget "${phase}_route_nets" 1 top.nets]]
    set wires [mptdc_tie1_trial_count \
        [mptdc_tie1_trial_dbget "${phase}_route_wires" 1 top.nets.wires]]
    set special_wires [mptdc_tie1_trial_count \
        [mptdc_tie1_trial_dbget "${phase}_route_special_wires" 1 top.nets.sWires]]
    set vias [mptdc_tie1_trial_count \
        [mptdc_tie1_trial_dbget "${phase}_route_vias" 1 top.nets.vias]]
    return [dict create \
        net_count $nets wire_count $wires \
        special_wire_count $special_wires via_count $vias]
}

proc mptdc_tie1_trial_placement_density {path} {
    set result [dict create \
        status FAIL percent UNKNOWN occupied UNKNOWN capacity UNKNOWN full 0]
    if {![file exists $path] || ![file readable $path]} {
        return $result
    }
    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        if {[regexp {^Placement Density:[[:space:]]*([0-9.]+)%\(([0-9]+)/([0-9]+)\)} \
                [string trim $line] -> percent occupied capacity]} {
            dict set result status PASS
            dict set result percent $percent
            dict set result occupied $occupied
            dict set result capacity $capacity
            dict set result full [expr {$occupied == $capacity && $percent == 100.0}]
            break
        }
    }
    close $fh
    return $result
}

proc mptdc_tie1_trial_capture_help {command path} {
    set status PASS
    set error NONE
    if {[catch {uplevel #0 "help $command > \"$path\""} result]} {
        set status FAIL
        set error [mptdc_tie1_trial_report_value $result]
        set fh [open $path w]
        puts $fh "COMMAND=$command"
        puts $fh "HELP_STATUS=$status"
        puts $fh "HELP_ERROR=$error"
        close $fh
    }
    return [list $status $error]
}

proc mptdc_tie1_trial_capture_man {command path} {
    set status PASS
    set error NONE
    if {[catch {uplevel #0 "man $command > \"$path\""} result]} {
        set status FAIL_OPTIONAL
        set error [mptdc_tie1_trial_report_value $result]
        set fh [open $path w]
        puts $fh "COMMAND=man $command"
        puts $fh "MAN_STATUS=$status"
        puts $fh "MAN_ERROR=$error"
        close $fh
    }
    return [list $status $error]
}

proc mptdc_tie1_trial_flagged_state {phase report_path} {
    set hi_terms [mptdc_tie1_trial_objects \
        [mptdc_tie1_trial_dbget "${phase}_flagged_hi_terms" 1 \
            top.insts.instTerms.isTieHi 1 -p]]
    set lo_terms [mptdc_tie1_trial_objects \
        [mptdc_tie1_trial_dbget "${phase}_flagged_lo_terms" 1 \
            top.insts.instTerms.isTieLo 1 -p]]
    set connected 0
    set disconnected 0
    set nets {}
    set hi_names {}
    set lo_names {}
    array set sink_count {}
    set fh [open $report_path w]
    puts $fh "polarity\tinst_term\tinstance\tmaster\tpin\tnet"
    foreach polarity_and_terms [list [list HIGH $hi_terms] [list LOW $lo_terms]] {
        set polarity [lindex $polarity_and_terms 0]
        set terms [lindex $polarity_and_terms 1]
        foreach term $terms {
            set term_name [mptdc_tie1_trial_pointer_attr $term name]
            set inst_name [mptdc_tie1_trial_pointer_attr $term inst.name]
            set master [mptdc_tie1_trial_pointer_attr $term inst.cell.name]
            set pin [mptdc_tie1_trial_pointer_attr $term cellTerm.name]
            set net [mptdc_tie1_trial_pointer_attr $term net.name]
            set canonical_term_name [mptdc_tie1_trial_canonical_name $term_name]
            if {$polarity eq "HIGH"} {
                lappend hi_names $canonical_term_name
            } else {
                lappend lo_names $canonical_term_name
            }
            if {$net eq ""} {
                set printable_net 0x0
                if {$polarity eq "HIGH"} {
                    incr disconnected
                }
            } else {
                set printable_net $net
                if {$polarity eq "HIGH"} {
                    incr connected
                    lappend nets $net
                    if {![info exists sink_count($net)]} {
                        set sink_count($net) 0
                    }
                    incr sink_count($net)
                }
            }
            puts $fh "$polarity\t$term_name\t$inst_name\t$master\t$pin\t$printable_net"
        }
    }
    close $fh
    set sink_pairs {}
    foreach net [lsort [array names sink_count]] {
        lappend sink_pairs $net $sink_count($net)
    }
    return [dict create \
        hi_terms $hi_terms \
        lo_terms $lo_terms \
        hi_names $hi_names \
        lo_names $lo_names \
        hi_count [llength $hi_terms] \
        lo_count [llength $lo_terms] \
        connected $connected \
        disconnected $disconnected \
        nets [lsort [mptdc_tie1_trial_unique $nets]] \
        sink_pairs $sink_pairs]
}

proc mptdc_tie1_trial_write_net_inventory {state high_master report_path} {
    array set sink_count [dict get $state sink_pairs]
    set all_contract_pass 1
    set all_routed 1
    set max_observed_fanout 0
    set fh [open $report_path w]
    puts $fh "net\tsink_count\ttie_high_source_count\tinst_term_count\twire_count\tvia_count\tcontract_status\troute_status"
    foreach net [dict get $state nets] {
        set net_ptrs [mptdc_tie1_trial_objects \
            [mptdc_tie1_trial_dbget "net_ptr_$net" 1 top.nets.name $net -p]]
        set ptr_count [llength $net_ptrs]
        set source_count 0
        set term_count 0
        set wire_count 0
        set via_count 0
        if {$ptr_count == 1} {
            set ptr [lindex $net_ptrs 0]
            set masters [mptdc_tie1_trial_objects \
                [mptdc_tie1_trial_dbget "net_masters_$net" 1 \
                    ${ptr}.instTerms.inst.cell.name]]
            foreach master $masters {
                if {$master eq $high_master} {
                    incr source_count
                }
            }
            set terms [mptdc_tie1_trial_objects \
                [mptdc_tie1_trial_dbget "net_terms_$net" 1 ${ptr}.instTerms]]
            set wires [mptdc_tie1_trial_objects \
                [mptdc_tie1_trial_dbget "net_wires_$net" 1 ${ptr}.wires]]
            set vias [mptdc_tie1_trial_objects \
                [mptdc_tie1_trial_dbget "net_vias_$net" 0 ${ptr}.vias]]
            set term_count [llength $terms]
            set wire_count [llength $wires]
            set via_count [llength $vias]
        }
        set sinks $sink_count($net)
        if {$sinks > $max_observed_fanout} {
            set max_observed_fanout $sinks
        }
        set contract_status [expr {
            $ptr_count == 1 && $source_count == 1 &&
            $term_count == ($sinks + 1) ? "PASS" : "FAIL"
        }]
        set route_status [expr {$wire_count > 0 ? "PASS" : "FAIL"}]
        if {$contract_status ne "PASS"} {
            set all_contract_pass 0
        }
        if {$route_status ne "PASS"} {
            set all_routed 0
        }
        puts $fh "$net\t$sinks\t$source_count\t$term_count\t$wire_count\t$via_count\t$contract_status\t$route_status"
    }
    close $fh
    return [dict create \
        net_count [llength [dict get $state nets]] \
        contract_status [expr {$all_contract_pass ? "PASS" : "FAIL"}] \
        route_status [expr {$all_routed ? "PASS" : "FAIL"}] \
        max_observed_fanout $max_observed_fanout]
}

proc mptdc_tie1_trial_marker_signature {path} {
    if {![file exists $path] || ![file readable $path]} {
        return {}
    }
    set fh [open $path r]
    set signatures {}
    foreach line [split [read $fh] "\n"] {
        if {$line eq "" || [string match "idx\t*" $line]} {
            continue
        }
        set fields [split $line "\t"]
        if {[llength $fields] < 7} {
            continue
        }
        if {![string equal -nocase [lindex $fields 4] Geometry]} {
            continue
        }
        lappend signatures [join [lrange $fields 2 end] "\t"]
    }
    close $fh
    return [lsort $signatures]
}

proc mptdc_tie1_trial_report_route_zero {path} {
    if {![file exists $path] || ![file readable $path]} {
        return 0
    }
    set fh [open $path r]
    set needed_restored_zero 0
    set extraction_zero 0
    set command_failed 0
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {[regexp -nocase {REPORT_STATUS=FAILED} $trimmed]} {
            set command_failed 1
        }
        if {[regexp {^#num needed restored net=0[[:space:]]*$} $trimmed]} {
            set needed_restored_zero 1
        }
        if {[regexp {^#need_extraction net=0([[:space:]]|\(|$)} $trimmed]} {
            set extraction_zero 1
        }
    }
    close $fh
    return [expr {!$command_failed && $needed_restored_zero && $extraction_zero}]
}

proc mptdc_tie1_trial_normalize_snapshot_unrouted {snapshot} {
    set route_report_zero \
        [mptdc_tie1_trial_report_route_zero [dict get $snapshot report_route_rpt]]
    dict set snapshot report_route_zero $route_report_zero
    if {[dict get $snapshot unrouted] eq "UNKNOWN" &&
        [dict get $snapshot regular_bad] eq "0" &&
        [dict get $snapshot special_bad] eq "1" &&
        [dict get $snapshot special_raw_bad] eq "1" &&
        [dict get $snapshot special_non_ro_failures] eq "0" &&
        $route_report_zero} {
        dict set snapshot unrouted 0
        dict set snapshot unrouted_source \
            tie1_trial_connectivity_exact_special_debt_report_route_fallback
    }
    return $snapshot
}

proc mptdc_tie1_trial_snapshot_equal_debt {baseline final} {
    foreach key {total_violations shorts regular_bad special_bad special_raw_bad special_non_ro_failures unrouted report_route_zero marker_signature} {
        if {[dict get $baseline $key] ne [dict get $final $key]} {
            return 0
        }
    }
    return [expr {[dict get $baseline special_bad_lines] eq \
        [dict get $final special_bad_lines]}]
}

set checkpoint [file normalize \
    [mptdc_tie1_trial_required_env MPTDC_TIE1_TRIAL_CKPT]]
set outdir [file normalize \
    [mptdc_tie1_trial_required_env MPTDC_TIE1_TRIAL_OUTDIR]]
set repo_root [file normalize \
    [mptdc_tie1_trial_required_env MPTDC_TIE1_TRIAL_REPO_ROOT]]
set top_cell [mptdc_tie1_trial_env MPTDC_TIE1_TRIAL_TOP mptdc_axis_core]
set high_master [mptdc_tie1_trial_env MPTDC_TIE1_TRIAL_HIGH_MASTER LOGIC1DJIHD]
set low_master [mptdc_tie1_trial_env MPTDC_TIE1_TRIAL_LOW_MASTER LOGIC0DJIHD]
set max_fanout [mptdc_tie1_trial_env MPTDC_TIE1_TRIAL_MAX_FANOUT 8]
set max_distance [mptdc_tie1_trial_env MPTDC_TIE1_TRIAL_MAX_DISTANCE 20]
set expected_hi [mptdc_tie1_trial_env MPTDC_TIE1_TRIAL_EXPECTED_HIGH_TERMS 91]
set expected_lo [mptdc_tie1_trial_env MPTDC_TIE1_TRIAL_EXPECTED_LOW_TERMS 0]
set expected_filler [mptdc_tie1_trial_env MPTDC_TIE1_TRIAL_EXPECTED_FILLERS 24797]
set expected_drc [mptdc_tie1_trial_env MPTDC_TIE1_TRIAL_EXPECTED_DRC 1]
set expected_sites [mptdc_tie1_trial_env MPTDC_TIE1_TRIAL_EXPECTED_PLACEMENT_SITES 907533]
set instance_pin_file [file normalize \
    [mptdc_tie1_trial_required_env MPTDC_TIE1_TRIAL_INSTANCE_PIN_FILE]]
set filler_masters [split [mptdc_tie1_trial_env MPTDC_TIE1_TRIAL_FILLER_MASTERS \
    "FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD"]]
set all_tie_masters [list LOGIC1DJIHD LOGIC1LVJIHD LOGIC0DJIHD LOGIC0LVJIHD]

file mkdir [file join $outdir reports]
file mkdir [file join $outdir checkpoints]
set status_report [file join $outdir reports tie1_insertion_trial_status.rpt]
set action_report [file join $outdir reports tie1_insertion_trial_action.rpt]
set baseline_terms_report [file join $outdir reports tie1_flagged_terms_baseline.tsv]
set final_terms_report [file join $outdir reports tie1_flagged_terms_final.tsv]
set net_inventory_report [file join $outdir reports tie1_inserted_net_inventory.tsv]
set master_inventory_report [file join $outdir reports tie1_trial_master_inventory.tsv]
set filler_report [file join $outdir reports filler_status.rpt]
set baseline_filler_inventory_report [file join $outdir reports tie1_filler_inventory_baseline.tsv]
set post_delete_filler_inventory_report [file join $outdir reports tie1_filler_inventory_post_delete.tsv]
set final_filler_inventory_report [file join $outdir reports tie1_filler_inventory_final.tsv]
set baseline_nonfiller_report [file join $outdir reports tie1_nonfiller_fingerprint_baseline.tsv]
set post_delete_nonfiller_report [file join $outdir reports tie1_nonfiller_fingerprint_post_delete.tsv]
set final_nonfiller_report [file join $outdir reports tie1_nonfiller_fingerprint_final.tsv]
set baseline_check_place_report [file join $outdir reports tie1_trial_baseline_check_place.rpt]
set final_check_place_report [file join $outdir reports tie1_trial_final_check_place.rpt]
set final_checkpoint [file join $outdir checkpoints repaired_route.enc]
set final_checkpoint_dat "${final_checkpoint}.dat"
set add_command_report [file join $outdir reports addTieHiLo_command.rpt]
set delete_command_report [file join $outdir reports deleteFiller_command.rpt]
set refill_command_report [file join $outdir reports addFiller_command.rpt]

array set ::mptdc_tie1_trial_query_status {}
array set ::mptdc_tie1_trial_query_error {}
set ::mptdc_tie1_trial_query_error_count 0
set ::mptdc_tie1_trial_core_query_error_count 0

set ::env(MPTDC_REPO_ROOT) $repo_root
set ::env(MPTDC_SIGNOFF_RESULT_DIR) $outdir
set ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY) 1
source [file join $repo_root MPTDC pnr scripts innovus_mptdc_digital_signoff.tcl]
set ::env(MPTDC_CHECKPOINT_REPAIR_SOURCE_ONLY) 1
source [file join $repo_root MPTDC pnr scripts innovus_mptdc_route_checkpoint_repair.tcl]
mptdc_signoff_mkdirs

set restore_status FAIL
set restore_error NONE
if {![file exists $checkpoint]} {
    set restore_error MISSING_CHECKPOINT
} elseif {[catch {restoreDesign $checkpoint $top_cell} restore_result]} {
    set restore_error [mptdc_tie1_trial_report_value $restore_result]
} else {
    set restore_status PASS
}

set baseline_snapshot_status FAIL
set baseline_snapshot_error NONE
set baseline_placement_status FAIL
set baseline_placement_error NONE
set baseline ""
set baseline_placement ""
set baseline_state [dict create \
    hi_terms {} lo_terms {} hi_names {} lo_names {} \
    hi_count 0 lo_count 0 connected 0 disconnected 0 nets {} sink_pairs {}]
set baseline_density [dict create \
    status FAIL percent UNKNOWN occupied UNKNOWN capacity UNKNOWN full 0]
set baseline_filler_inventory [dict create phase baseline total 0 masters $filler_masters]
set baseline_nonfiller [dict create phase baseline count 0 rows {}]
set baseline_route_signature [dict create \
    net_count 0 wire_count 0 special_wire_count 0 via_count 0]
set inst_count_before 0
set filler_count_before 0
array set tie_count_before {}
foreach master $all_tie_masters {
    set tie_count_before($master) 0
}

if {$restore_status eq "PASS"} {
    if {[catch {set baseline [mptdc_ckpt_verify_snapshot tie1_trial_baseline]} err]} {
        set baseline_snapshot_error [mptdc_tie1_trial_report_value $err]
    } else {
        set baseline [mptdc_tie1_trial_normalize_snapshot_unrouted $baseline]
        dict set baseline marker_signature \
            [mptdc_tie1_trial_marker_signature [dict get $baseline marker_rpt]]
        set baseline_snapshot_status PASS
    }
    if {[catch {
        set baseline_placement [mptdc_signoff_capture_placement_gate \
            tie1_trial_baseline \
            $baseline_check_place_report \
            [file join $outdir reports tie1_trial_baseline_placement_status.rpt] 0]
    } err]} {
        set baseline_placement_error [mptdc_tie1_trial_report_value $err]
    } else {
        set baseline_placement_status [dict get $baseline_placement status]
    }
    set baseline_state [mptdc_tie1_trial_flagged_state baseline $baseline_terms_report]
    set baseline_density \
        [mptdc_tie1_trial_placement_density $baseline_check_place_report]
    set inst_count_before [mptdc_tie1_trial_count \
        [mptdc_tie1_trial_dbget top_instances_before 1 top.insts]]
    set baseline_filler_inventory [mptdc_tie1_trial_filler_inventory \
        baseline $filler_masters $baseline_filler_inventory_report]
    set filler_count_before [dict get $baseline_filler_inventory total]
    set baseline_nonfiller [mptdc_tie1_trial_nonfiller_fingerprint \
        baseline [concat $filler_masters $all_tie_masters] \
        $baseline_nonfiller_report]
    set baseline_route_signature [mptdc_tie1_trial_route_signature baseline]
    foreach master $all_tie_masters {
        set tie_count_before($master) [mptdc_tie1_trial_master_count $master]
    }
}

set instance_pin_targets \
    [mptdc_tie1_trial_read_instance_pin_targets $instance_pin_file]
set instance_pin_target_match_status FAIL
if {[dict get $instance_pin_targets status] eq "PASS" &&
    [dict get $instance_pin_targets count] == $expected_hi &&
    [dict get $instance_pin_targets unique_count] == $expected_hi &&
    [lsort [dict get $instance_pin_targets targets]] eq
        [lsort [dict get $baseline_state hi_names]]} {
    set instance_pin_target_match_status PASS
}

set command_precheck PASS
set command_precheck_reasons {}
if {$restore_status ne "PASS"} { lappend command_precheck_reasons restore_failed }
if {$baseline_snapshot_status ne "PASS"} { lappend command_precheck_reasons baseline_snapshot_failed }
if {$baseline_placement_status ne "PASS"} { lappend command_precheck_reasons baseline_placement_not_clean }
if {[dict get $baseline_state hi_count] != $expected_hi} { lappend command_precheck_reasons high_term_count_mismatch }
if {[dict get $baseline_state lo_count] != $expected_lo} { lappend command_precheck_reasons low_term_count_mismatch }
if {[dict get $baseline_state connected] != 0 || [dict get $baseline_state disconnected] != $expected_hi} {
    lappend command_precheck_reasons baseline_tie_terms_not_all_disconnected
}
if {$filler_count_before != $expected_filler} { lappend command_precheck_reasons filler_count_mismatch }
if {[dict get $baseline_density status] ne "PASS" ||
    ![dict get $baseline_density full] ||
    [dict get $baseline_density occupied] != $expected_sites ||
    [dict get $baseline_density capacity] != $expected_sites} {
    lappend command_precheck_reasons baseline_site_occupancy_mismatch
}
if {[dict get $instance_pin_targets status] ne "PASS"} {
    lappend command_precheck_reasons instance_pin_target_file_invalid
}
if {[dict get $instance_pin_targets count] != $expected_hi ||
    [dict get $instance_pin_targets unique_count] != $expected_hi} {
    lappend command_precheck_reasons instance_pin_target_count_mismatch
}
if {$instance_pin_target_match_status ne "PASS"} {
    lappend command_precheck_reasons instance_pin_target_set_mismatch
}
foreach master $all_tie_masters {
    if {$tie_count_before($master) != 0} {
        lappend command_precheck_reasons preexisting_tie_instance_$master
    }
}
if {$baseline_snapshot_status eq "PASS"} {
    if {[dict get $baseline total_violations] ne "$expected_drc"} { lappend command_precheck_reasons baseline_drc_mismatch }
    if {[dict get $baseline shorts] ne "0"} { lappend command_precheck_reasons baseline_shorts_nonzero }
    if {[dict get $baseline regular_bad] ne "0"} { lappend command_precheck_reasons baseline_regular_connectivity_bad }
    if {[dict get $baseline unrouted] ne "0"} { lappend command_precheck_reasons baseline_unrouted_nonzero }
    if {[llength [dict get $baseline marker_signature]] != $expected_drc} {
        lappend command_precheck_reasons baseline_marker_signature_count_mismatch
    }
    if {[dict get $baseline special_bad] ne "1" || [dict get $baseline special_raw_bad] ne "1" ||
        [dict get $baseline special_non_ro_failures] ne "0"} {
        lappend command_precheck_reasons baseline_special_signature_mismatch
    }
}
if {[llength [info commands setTieHiLoMode]] != 1} { lappend command_precheck_reasons setTieHiLoMode_unavailable }
if {[llength [info commands addTieHiLo]] != 1} { lappend command_precheck_reasons addTieHiLo_unavailable }
if {[llength [info commands deleteFiller]] != 1} { lappend command_precheck_reasons deleteFiller_unavailable }
if {[llength [info commands setFillerMode]] != 1} { lappend command_precheck_reasons setFillerMode_unavailable }
if {[llength [info commands addFiller]] != 1} { lappend command_precheck_reasons addFiller_unavailable }
if {[llength $command_precheck_reasons] > 0} { set command_precheck FAIL }

lassign [mptdc_tie1_trial_capture_help setTieHiLoMode \
    [file join $outdir reports setTieHiLoMode_help.rpt]] set_mode_help_status set_mode_help_error
lassign [mptdc_tie1_trial_capture_help addTieHiLo \
    [file join $outdir reports addTieHiLo_help.rpt]] add_help_status add_help_error
lassign [mptdc_tie1_trial_capture_man addTieHiLo \
    [file join $outdir reports addTieHiLo_man.rpt]] add_man_status add_man_error
lassign [mptdc_tie1_trial_capture_help deleteFiller \
    [file join $outdir reports deleteFiller_help.rpt]] delete_help_status delete_help_error
lassign [mptdc_tie1_trial_capture_man deleteFiller \
    [file join $outdir reports deleteFiller_man.rpt]] delete_man_status delete_man_error
lassign [mptdc_tie1_trial_capture_help setFillerMode \
    [file join $outdir reports setFillerMode_help.rpt]] filler_mode_help_status filler_mode_help_error
lassign [mptdc_tie1_trial_capture_help addFiller \
    [file join $outdir reports addFiller_help.rpt]] refill_help_status refill_help_error

set delete_status NOT_RUN
set delete_error NONE
set delete_effect_status NOT_RUN
set delete_effect_reason COMMAND_NOT_RUN
set filler_count_post_delete $filler_count_before
set inst_count_post_delete $inst_count_before
set post_delete_filler_inventory [dict create \
    phase post_delete total $filler_count_before masters $filler_masters]
set post_delete_nonfiller $baseline_nonfiller
set post_delete_route_signature $baseline_route_signature
set post_delete_nonfiller_status NOT_RUN
set post_delete_route_status NOT_RUN

if {$command_precheck eq "PASS"} {
    if {[catch {
        deleteFiller > $delete_command_report
    } err]} {
        set delete_status FAIL
        set delete_error [mptdc_tie1_trial_report_value $err]
    } else {
        set delete_status PASS
    }
    set inst_count_post_delete [mptdc_tie1_trial_count \
        [mptdc_tie1_trial_dbget top_instances_post_delete 1 top.insts]]
    set post_delete_filler_inventory [mptdc_tie1_trial_filler_inventory \
        post_delete $filler_masters $post_delete_filler_inventory_report]
    set filler_count_post_delete [dict get $post_delete_filler_inventory total]
    set post_delete_nonfiller [mptdc_tie1_trial_nonfiller_fingerprint \
        post_delete [concat $filler_masters $all_tie_masters] \
        $post_delete_nonfiller_report]
    set post_delete_route_signature [mptdc_tie1_trial_route_signature post_delete]
    set post_delete_nonfiller_status [expr {
        [dict get $post_delete_nonfiller rows] eq
            [dict get $baseline_nonfiller rows] ? "PASS" : "FAIL"
    }]
    set post_delete_route_status [expr {
        $post_delete_route_signature eq $baseline_route_signature ? "PASS" : "FAIL"
    }]
    set delete_effect_status FAIL
    set delete_effect_reason POST_DELETE_CONTRACT_MISMATCH
    if {$delete_status eq "PASS" &&
        $filler_count_post_delete == 0 &&
        $inst_count_post_delete == ($inst_count_before - $expected_filler) &&
        $post_delete_nonfiller_status eq "PASS" &&
        $post_delete_route_status eq "PASS"} {
        set delete_effect_status PASS
        set delete_effect_reason NONE
    }
}

set mode_status NOT_RUN
set mode_error NONE
set add_status NOT_RUN
set add_error NONE
set add_effect_status NOT_RUN
set add_effect_reason COMMAND_NOT_RUN
set route_status NOT_RUN
set route_error NONE
if {$delete_effect_status eq "PASS"} {
    if {[catch {
        setTieHiLoMode -cell "$high_master $low_master" \
            -maxFanout $max_fanout -maxDistance $max_distance \
            -honorDontUse false -honorDontTouch false
    } err]} {
        set mode_status FAIL
        set mode_error [mptdc_tie1_trial_report_value $err]
    } else {
        set mode_status PASS
    }
}
if {$mode_status eq "PASS"} {
    if {[catch {
        addTieHiLo -cell "$high_master $low_master" \
            -instancePin $instance_pin_file \
            -prefix MPTDC_TIE1 > $add_command_report
    } add_result]} {
        set add_status FAIL
        set add_error [mptdc_tie1_trial_report_value $add_result]
    } else {
        set add_status PASS
    }
}

set add_command_fh [open $add_command_report a]
puts $add_command_fh ""
puts $add_command_fh "ADD_TIE_SELECTION_MODE=EXACT_INSTANCE_PIN_FILE"
puts $add_command_fh "INSTANCE_PIN_FILE=$instance_pin_file"
puts $add_command_fh "INSTANCE_PIN_TARGET_COUNT=[dict get $instance_pin_targets count]"
puts $add_command_fh "ADD_TIE_COMMAND_STATUS=$add_status"
puts $add_command_fh "ADD_TIE_COMMAND_ERROR=$add_error"
close $add_command_fh

set post_add_state [mptdc_tie1_trial_flagged_state post_add \
    [file join $outdir reports tie1_flagged_terms_post_add.tsv]]
if {$add_status eq "PASS"} {
    set add_effect_status FAIL
    set add_effect_reason NO_ELIGIBLE_TARGET_WAS_CONNECTED
    if {[dict get $post_add_state hi_count] == $expected_hi &&
        [dict get $post_add_state connected] == $expected_hi &&
        [dict get $post_add_state disconnected] == 0 &&
        [llength [dict get $post_add_state nets]] > 0} {
        set add_effect_status PASS
        set add_effect_reason NONE
    }
}
if {$add_effect_status eq "PASS" && [dict get $post_add_state disconnected] == 0 &&
    [llength [dict get $post_add_state nets]] > 0} {
    if {[catch {
        mptdc_ckpt_route_selected_nets_route_design [dict get $post_add_state nets]
    } err]} {
        set route_status FAIL
        set route_error [mptdc_tie1_trial_report_value $err]
    } else {
        set route_status PASS
    }
}

set filler_mode_status NOT_RUN
set filler_mode_error NONE
set refill_status NOT_RUN
set refill_error NONE
set pg_connectivity_status NOT_RUN
set pg_connectivity_error NONE
if {$route_status eq "PASS"} {
    if {[catch {
        setFillerMode -add_fillers_with_drc false
    } err]} {
        set filler_mode_status FAIL
        set filler_mode_error [mptdc_tie1_trial_report_value $err]
    } else {
        set filler_mode_status PASS
    }
}
if {$filler_mode_status eq "PASS"} {
    if {[catch {
        addFiller -cell $filler_masters -prefix MPTDC_FILL > $refill_command_report
    } err]} {
        set refill_status FAIL
        set refill_error [mptdc_tie1_trial_report_value $err]
    } else {
        set refill_status PASS
    }
}
if {$refill_status eq "PASS"} {
    if {[catch {
        mptdc_signoff_apply_pg_connectivity
    } err]} {
        set pg_connectivity_status FAIL
        set pg_connectivity_error [mptdc_tie1_trial_report_value $err]
    } else {
        set pg_connectivity_status PASS
    }
}

set final_state [mptdc_tie1_trial_flagged_state final $final_terms_report]
set net_inventory [mptdc_tie1_trial_write_net_inventory \
    $final_state $high_master $net_inventory_report]
set final_snapshot_status FAIL
set final_snapshot_error NONE
set final_placement_status FAIL
set final_placement_error NONE
set final_density [dict create \
    status FAIL percent UNKNOWN occupied UNKNOWN capacity UNKNOWN full 0]
set final ""
set final_placement ""
if {$restore_status eq "PASS"} {
    if {[catch {set final [mptdc_ckpt_verify_snapshot tie1_trial_final]} err]} {
        set final_snapshot_error [mptdc_tie1_trial_report_value $err]
    } else {
        set final [mptdc_tie1_trial_normalize_snapshot_unrouted $final]
        dict set final marker_signature \
            [mptdc_tie1_trial_marker_signature [dict get $final marker_rpt]]
        set final_snapshot_status PASS
    }
    if {[catch {
        set final_placement [mptdc_signoff_capture_placement_gate \
            tie1_trial_final \
            $final_check_place_report \
            [file join $outdir reports tie1_trial_final_placement_status.rpt] 0]
    } err]} {
        set final_placement_error [mptdc_tie1_trial_report_value $err]
    } else {
        set final_placement_status [dict get $final_placement status]
    }
    set final_density \
        [mptdc_tie1_trial_placement_density $final_check_place_report]
}

set inst_count_after [mptdc_tie1_trial_count \
    [mptdc_tie1_trial_dbget top_instances_after 1 top.insts]]
set final_filler_inventory [mptdc_tie1_trial_filler_inventory \
    final $filler_masters $final_filler_inventory_report]
set filler_count_after [dict get $final_filler_inventory total]
set final_nonfiller [mptdc_tie1_trial_nonfiller_fingerprint \
    final [concat $filler_masters $all_tie_masters] $final_nonfiller_report]
set nonfiller_fingerprint_status [expr {
    [dict get $final_nonfiller rows] eq [dict get $baseline_nonfiller rows] ?
        "PASS" : "FAIL"
}]
set final_site_occupancy_status [expr {
    [dict get $final_density status] eq "PASS" &&
    [dict get $final_density full] &&
    [dict get $final_density occupied] == $expected_sites &&
    [dict get $final_density capacity] == $expected_sites ? "PASS" : "FAIL"
}]
set final_filler_master_set_status [expr {
    $filler_count_after > 0 ? "PASS" : "FAIL"
}]
set filler_refill_status [expr {
    $filler_mode_status eq "PASS" && $refill_status eq "PASS" &&
    $pg_connectivity_status eq "PASS" &&
    $final_filler_master_set_status eq "PASS" ? "PASS" : "FAIL"
}]
array set tie_count_after {}
set master_fh [open $master_inventory_report w]
puts $master_fh "master\tpolarity\tbefore_count\tafter_count\tdelta"
set tie_high_delta 0
set tie_low_delta 0
set target_high_delta 0
set alternate_tie_master_delta 0
foreach master $all_tie_masters {
    set tie_count_after($master) [mptdc_tie1_trial_master_count $master]
    set delta [expr {$tie_count_after($master) - $tie_count_before($master)}]
    set polarity [expr {[string match LOGIC1* $master] ? "HIGH" : "LOW"}]
    if {$polarity eq "HIGH"} { incr tie_high_delta $delta } else { incr tie_low_delta $delta }
    if {$master eq $high_master} {
        set target_high_delta $delta
    } elseif {$delta != 0} {
        incr alternate_tie_master_delta $delta
    }
    puts $master_fh "$master\t$polarity\t$tie_count_before($master)\t$tie_count_after($master)\t$delta"
}
close $master_fh

set filler_delta [expr {$filler_count_after - $filler_count_before}]
set total_instance_delta [expr {$inst_count_after - $inst_count_before}]
set unexplained_instance_delta [expr {$total_instance_delta - $tie_high_delta - $tie_low_delta - $filler_delta}]
set fanout_status [expr {[dict get $net_inventory max_observed_fanout] <= $max_fanout ? "PASS" : "FAIL"}]
set debt_status FAIL
if {$baseline_snapshot_status eq "PASS" && $final_snapshot_status eq "PASS" &&
    [mptdc_tie1_trial_snapshot_equal_debt $baseline $final]} {
    set debt_status PASS
}

set trial_reasons {}
if {$command_precheck ne "PASS"} { lappend trial_reasons command_precheck_failed }
if {$delete_status ne "PASS"} { lappend trial_reasons filler_delete_failed }
if {$delete_effect_status ne "PASS"} { lappend trial_reasons filler_delete_contract_failed }
if {$post_delete_nonfiller_status ne "PASS"} { lappend trial_reasons post_delete_nonfiller_changed }
if {$post_delete_route_status ne "PASS"} { lappend trial_reasons post_delete_route_changed }
if {$mode_status ne "PASS"} { lappend trial_reasons set_tie_mode_failed }
if {$add_status ne "PASS"} { lappend trial_reasons add_tie_failed }
if {$add_effect_status ne "PASS"} { lappend trial_reasons add_tie_no_effect }
if {$route_status ne "PASS"} { lappend trial_reasons selected_net_route_failed }
if {$filler_mode_status ne "PASS"} { lappend trial_reasons filler_mode_failed }
if {$refill_status ne "PASS"} { lappend trial_reasons filler_refill_command_failed }
if {$pg_connectivity_status ne "PASS"} { lappend trial_reasons pg_connectivity_rebind_failed }
if {$filler_refill_status ne "PASS"} { lappend trial_reasons filler_refill_contract_failed }
if {[dict get $final_state hi_count] != $expected_hi} { lappend trial_reasons final_high_term_count_mismatch }
if {[dict get $final_state lo_count] != $expected_lo} { lappend trial_reasons final_low_term_count_mismatch }
if {[dict get $final_state connected] != $expected_hi || [dict get $final_state disconnected] != 0} {
    lappend trial_reasons final_high_terms_not_all_connected
}
if {$target_high_delta <= 0 || $target_high_delta > $expected_hi} { lappend trial_reasons target_high_instance_delta_invalid }
if {$tie_high_delta != $target_high_delta} { lappend trial_reasons non_target_high_instance_created }
if {$target_high_delta != [dict get $net_inventory net_count]} { lappend trial_reasons target_high_instance_net_count_mismatch }
if {$alternate_tie_master_delta != 0} { lappend trial_reasons alternate_tie_master_delta_nonzero }
if {$tie_low_delta != 0} { lappend trial_reasons unexpected_tie_low_instances }
if {[dict get $net_inventory net_count] <= 0} { lappend trial_reasons no_tie_nets_created }
if {[dict get $net_inventory contract_status] ne "PASS"} { lappend trial_reasons tie_net_source_contract_failed }
if {[dict get $net_inventory route_status] ne "PASS"} { lappend trial_reasons tie_net_route_contract_failed }
if {$fanout_status ne "PASS"} { lappend trial_reasons tie_net_fanout_exceeded }
if {$final_placement_status ne "PASS"} { lappend trial_reasons final_placement_not_clean }
if {$filler_count_after <= 0} { lappend trial_reasons filler_count_invalid }
if {$final_filler_master_set_status ne "PASS"} { lappend trial_reasons final_filler_master_set_invalid }
if {$final_site_occupancy_status ne "PASS"} { lappend trial_reasons final_site_occupancy_not_full }
if {$nonfiller_fingerprint_status ne "PASS"} { lappend trial_reasons nonfiller_fingerprint_changed }
if {$unexplained_instance_delta != 0} { lappend trial_reasons unexplained_instance_delta }
if {$debt_status ne "PASS"} { lappend trial_reasons physical_debt_changed }
if {$final_snapshot_status eq "PASS" && [llength [dict get $final marker_signature]] != $expected_drc} {
    lappend trial_reasons final_marker_signature_count_mismatch
}
if {$::mptdc_tie1_trial_core_query_error_count != 0} { lappend trial_reasons core_query_error }

set trial_status [expr {[llength $trial_reasons] == 0 ? "PASS" : "FAIL"}]
set save_status NOT_RUN
set save_error NONE
if {$trial_status eq "PASS"} {
    if {[catch {saveDesign $final_checkpoint} err]} {
        set save_status FAIL
        set save_error [mptdc_tie1_trial_report_value $err]
        set trial_status FAIL
        lappend trial_reasons checkpoint_save_failed
    } elseif {![file isdirectory $final_checkpoint_dat]} {
        set save_status FAIL
        set save_error CHECKPOINT_DAT_MISSING
        set trial_status FAIL
        lappend trial_reasons checkpoint_dat_missing
    } else {
        set save_status PASS
    }
}

set action_fh [open $action_report w]
puts $action_fh "STEP=TIE1_INSERTION_TRIAL_ACTION"
puts $action_fh "TARGET_HIGH_MASTER=$high_master"
puts $action_fh "TARGET_LOW_MASTER=$low_master"
puts $action_fh "MAX_FANOUT=$max_fanout"
puts $action_fh "MAX_DISTANCE_UM=$max_distance"
puts $action_fh "FILLER_RECYCLE_MODE=DELETE_INSERT_ROUTE_REFILL"
puts $action_fh "DELETE_FILLER_HELP_STATUS=$delete_help_status"
puts $action_fh "DELETE_FILLER_MAN_STATUS=$delete_man_status"
puts $action_fh "FILLER_DELETE_STATUS=$delete_status"
puts $action_fh "FILLER_DELETE_ERROR=$delete_error"
puts $action_fh "FILLER_DELETE_EFFECT_STATUS=$delete_effect_status"
puts $action_fh "FILLER_DELETE_EFFECT_REASON=$delete_effect_reason"
puts $action_fh "FILLER_COUNT_POST_DELETE=$filler_count_post_delete"
puts $action_fh "POST_DELETE_NONFILLER_FINGERPRINT_STATUS=$post_delete_nonfiller_status"
puts $action_fh "POST_DELETE_ROUTE_SIGNATURE_STATUS=$post_delete_route_status"
puts $action_fh "ADD_TIE_SELECTION_MODE=EXACT_INSTANCE_PIN_FILE"
puts $action_fh "INSTANCE_PIN_TARGET_FILE=$instance_pin_file"
puts $action_fh "INSTANCE_PIN_TARGET_FILE_STATUS=[dict get $instance_pin_targets status]"
puts $action_fh "INSTANCE_PIN_TARGET_COUNT=[dict get $instance_pin_targets count]"
puts $action_fh "INSTANCE_PIN_TARGET_UNIQUE_COUNT=[dict get $instance_pin_targets unique_count]"
puts $action_fh "INSTANCE_PIN_TARGET_INVALID_COUNT=[dict get $instance_pin_targets invalid_count]"
puts $action_fh "INSTANCE_PIN_TARGET_MATCH_STATUS=$instance_pin_target_match_status"
puts $action_fh "ROUTE_METHOD=SELECT_NET_SET_NANOROUTE_SELECTED_ONLY_ROUTE_DESIGN_SELECTED"
puts $action_fh "SET_TIE_MODE_HELP_STATUS=$set_mode_help_status"
puts $action_fh "ADD_TIE_HELP_STATUS=$add_help_status"
puts $action_fh "ADD_TIE_MAN_STATUS=$add_man_status"
puts $action_fh "ADD_TIE_MAN_ERROR=$add_man_error"
puts $action_fh "SET_TIE_MODE_STATUS=$mode_status"
puts $action_fh "SET_TIE_MODE_ERROR=$mode_error"
puts $action_fh "ADD_TIE_STATUS=$add_status"
puts $action_fh "ADD_TIE_ERROR=$add_error"
puts $action_fh "ADD_TIE_EFFECT_STATUS=$add_effect_status"
puts $action_fh "ADD_TIE_EFFECT_REASON=$add_effect_reason"
puts $action_fh "ADD_TIE_COMMAND_REPORT=$add_command_report"
puts $action_fh "SELECTED_ROUTE_STATUS=$route_status"
puts $action_fh "SELECTED_ROUTE_ERROR=$route_error"
puts $action_fh "FILLER_MODE_HELP_STATUS=$filler_mode_help_status"
puts $action_fh "FILLER_MODE_STATUS=$filler_mode_status"
puts $action_fh "FILLER_MODE_ERROR=$filler_mode_error"
puts $action_fh "ADD_FILLER_HELP_STATUS=$refill_help_status"
puts $action_fh "FILLER_REFILL_COMMAND_STATUS=$refill_status"
puts $action_fh "FILLER_REFILL_COMMAND_ERROR=$refill_error"
puts $action_fh "PG_CONNECTIVITY_REBIND_STATUS=$pg_connectivity_status"
puts $action_fh "PG_CONNECTIVITY_REBIND_ERROR=$pg_connectivity_error"
puts $action_fh "FILLER_REFILL_STATUS=$filler_refill_status"
puts $action_fh "BASELINE_FLAGGED_HIGH_TERM_COUNT=[dict get $baseline_state hi_count]"
puts $action_fh "FINAL_FLAGGED_HIGH_TERM_COUNT=[dict get $final_state hi_count]"
puts $action_fh "FINAL_CONNECTED_HIGH_TERM_COUNT=[dict get $final_state connected]"
puts $action_fh "FINAL_DISCONNECTED_HIGH_TERM_COUNT=[dict get $final_state disconnected]"
puts $action_fh "FINAL_TIE_NET_COUNT=[dict get $net_inventory net_count]"
puts $action_fh "MAX_OBSERVED_TIE_FANOUT=[dict get $net_inventory max_observed_fanout]"
puts $action_fh "TIE_FANOUT_STATUS=$fanout_status"
puts $action_fh "TIE_NET_SOURCE_CONTRACT_STATUS=[dict get $net_inventory contract_status]"
puts $action_fh "TIE_NET_ROUTE_STATUS=[dict get $net_inventory route_status]"
puts $action_fh "TIE_HIGH_INSTANCE_DELTA=$tie_high_delta"
puts $action_fh "TARGET_HIGH_INSTANCE_DELTA=$target_high_delta"
puts $action_fh "ALTERNATE_TIE_MASTER_DELTA=$alternate_tie_master_delta"
puts $action_fh "TIE_LOW_INSTANCE_DELTA=$tie_low_delta"
puts $action_fh "FILLER_COUNT_BEFORE=$filler_count_before"
puts $action_fh "FILLER_COUNT_AFTER=$filler_count_after"
puts $action_fh "FILLER_DELTA=$filler_delta"
puts $action_fh "FINAL_FILLER_MASTER_SET_STATUS=$final_filler_master_set_status"
puts $action_fh "NONFILLER_FINGERPRINT_STATUS=$nonfiller_fingerprint_status"
puts $action_fh "FINAL_SITE_OCCUPANCY_STATUS=$final_site_occupancy_status"
puts $action_fh "FINAL_PLACEMENT_SITE_OCCUPIED=[dict get $final_density occupied]"
puts $action_fh "FINAL_PLACEMENT_SITE_CAPACITY=[dict get $final_density capacity]"
puts $action_fh "TOTAL_INSTANCE_DELTA=$total_instance_delta"
puts $action_fh "UNEXPLAINED_INSTANCE_DELTA=$unexplained_instance_delta"
puts $action_fh "CHECKPOINT_SAVE_STATUS=$save_status"
puts $action_fh "CHECKPOINT_SAVE_ERROR=$save_error"
puts $action_fh "TIE1_INSERTION_TRIAL_STATUS=$trial_status"
close $action_fh

set filler_fh [open $filler_report w]
puts $filler_fh "# MPTDC Tie1 Trial Final Filler Status"
puts $filler_fh "FILLER_CELL_FAMILY=FEED*JIHD"
puts $filler_fh "FILLER_CANDIDATES=[join $filler_masters { }]"
puts $filler_fh "FILLER_COUNT_BEFORE=$filler_count_before"
puts $filler_fh "FILLER_COUNT_POST_DELETE=$filler_count_post_delete"
puts $filler_fh "FILLER_COUNT=$filler_count_after"
puts $filler_fh "FILLER_DELTA=$filler_delta"
puts $filler_fh "FILLER_DELETE_STATUS=$delete_status"
puts $filler_fh "FILLER_DELETE_EFFECT_STATUS=$delete_effect_status"
puts $filler_fh "FILLER_MODE_STATUS=$filler_mode_status"
puts $filler_fh "FILLER_REFILL_COMMAND_STATUS=$refill_status"
puts $filler_fh "FILLER_REFILL_STATUS=$filler_refill_status"
puts $filler_fh "FILLER_INSERTION_STATUS=[expr {$filler_refill_status eq "PASS" ? "PASS" : "FAIL"}]"
puts $filler_fh "FILLER_ADJUSTMENT_POLICY=EXACT_DELETE_INSERT_ROUTE_REFILL_PRIVATE_COPY"
puts $filler_fh "FINAL_FILLER_MASTER_SET_STATUS=$final_filler_master_set_status"
puts $filler_fh "NONFILLER_FINGERPRINT_STATUS=$nonfiller_fingerprint_status"
puts $filler_fh "FINAL_SITE_OCCUPANCY_STATUS=$final_site_occupancy_status"
puts $filler_fh "FINAL_PLACEMENT_SITE_OCCUPIED=[dict get $final_density occupied]"
puts $filler_fh "FINAL_PLACEMENT_SITE_CAPACITY=[dict get $final_density capacity]"
puts $filler_fh "FILLER_PLACEMENT_STATUS=$final_placement_status"
close $filler_fh

set status_fh [open $status_report w]
puts $status_fh "STEP=TIE1_INSERTION_TRIAL"
puts $status_fh "CHECKPOINT=$checkpoint"
puts $status_fh "TOP_CELL=$top_cell"
puts $status_fh "RESTORE_STATUS=$restore_status"
puts $status_fh "RESTORE_ERROR=$restore_error"
puts $status_fh "COMMAND_PRECHECK=$command_precheck"
puts $status_fh "COMMAND_PRECHECK_REASONS=$command_precheck_reasons"
puts $status_fh "FILLER_RECYCLE_MODE=DELETE_INSERT_ROUTE_REFILL"
puts $status_fh "FILLER_DELETE_STATUS=$delete_status"
puts $status_fh "FILLER_DELETE_ERROR=$delete_error"
puts $status_fh "FILLER_DELETE_EFFECT_STATUS=$delete_effect_status"
puts $status_fh "FILLER_DELETE_EFFECT_REASON=$delete_effect_reason"
puts $status_fh "FILLER_COUNT_POST_DELETE=$filler_count_post_delete"
puts $status_fh "POST_DELETE_NONFILLER_FINGERPRINT_STATUS=$post_delete_nonfiller_status"
puts $status_fh "POST_DELETE_ROUTE_SIGNATURE_STATUS=$post_delete_route_status"
puts $status_fh "ADD_TIE_SELECTION_MODE=EXACT_INSTANCE_PIN_FILE"
puts $status_fh "INSTANCE_PIN_TARGET_FILE=$instance_pin_file"
puts $status_fh "INSTANCE_PIN_TARGET_FILE_STATUS=[dict get $instance_pin_targets status]"
puts $status_fh "INSTANCE_PIN_TARGET_COUNT=[dict get $instance_pin_targets count]"
puts $status_fh "INSTANCE_PIN_TARGET_UNIQUE_COUNT=[dict get $instance_pin_targets unique_count]"
puts $status_fh "INSTANCE_PIN_TARGET_INVALID_COUNT=[dict get $instance_pin_targets invalid_count]"
puts $status_fh "INSTANCE_PIN_TARGET_MATCH_STATUS=$instance_pin_target_match_status"
puts $status_fh "BASELINE_SNAPSHOT_STATUS=$baseline_snapshot_status"
puts $status_fh "BASELINE_SNAPSHOT_ERROR=$baseline_snapshot_error"
puts $status_fh "BASELINE_PLACEMENT_STATUS=$baseline_placement_status"
puts $status_fh "BASELINE_PLACEMENT_ERROR=$baseline_placement_error"
puts $status_fh "FINAL_SNAPSHOT_STATUS=$final_snapshot_status"
puts $status_fh "FINAL_SNAPSHOT_ERROR=$final_snapshot_error"
puts $status_fh "FINAL_PLACEMENT_STATUS=$final_placement_status"
puts $status_fh "FINAL_PLACEMENT_ERROR=$final_placement_error"
puts $status_fh "SET_TIE_MODE_STATUS=$mode_status"
puts $status_fh "ADD_TIE_STATUS=$add_status"
puts $status_fh "ADD_TIE_EFFECT_STATUS=$add_effect_status"
puts $status_fh "ADD_TIE_EFFECT_REASON=$add_effect_reason"
puts $status_fh "SELECTED_ROUTE_STATUS=$route_status"
puts $status_fh "FILLER_MODE_STATUS=$filler_mode_status"
puts $status_fh "FILLER_MODE_ERROR=$filler_mode_error"
puts $status_fh "FILLER_REFILL_COMMAND_STATUS=$refill_status"
puts $status_fh "FILLER_REFILL_COMMAND_ERROR=$refill_error"
puts $status_fh "PG_CONNECTIVITY_REBIND_STATUS=$pg_connectivity_status"
puts $status_fh "PG_CONNECTIVITY_REBIND_ERROR=$pg_connectivity_error"
puts $status_fh "FILLER_REFILL_STATUS=$filler_refill_status"
puts $status_fh "EXPECTED_FLAGGED_HIGH_TERM_COUNT=$expected_hi"
puts $status_fh "BASELINE_FLAGGED_HIGH_TERM_COUNT=[dict get $baseline_state hi_count]"
puts $status_fh "FINAL_FLAGGED_HIGH_TERM_COUNT=[dict get $final_state hi_count]"
puts $status_fh "FINAL_CONNECTED_HIGH_TERM_COUNT=[dict get $final_state connected]"
puts $status_fh "FINAL_DISCONNECTED_HIGH_TERM_COUNT=[dict get $final_state disconnected]"
puts $status_fh "FINAL_FLAGGED_LOW_TERM_COUNT=[dict get $final_state lo_count]"
puts $status_fh "FINAL_TIE_NET_COUNT=[dict get $net_inventory net_count]"
puts $status_fh "TIE_NET_SOURCE_CONTRACT_STATUS=[dict get $net_inventory contract_status]"
puts $status_fh "TIE_NET_ROUTE_STATUS=[dict get $net_inventory route_status]"
puts $status_fh "TIE_FANOUT_STATUS=$fanout_status"
puts $status_fh "MAX_OBSERVED_TIE_FANOUT=[dict get $net_inventory max_observed_fanout]"
puts $status_fh "TIE_HIGH_INSTANCE_DELTA=$tie_high_delta"
puts $status_fh "TARGET_HIGH_INSTANCE_DELTA=$target_high_delta"
puts $status_fh "ALTERNATE_TIE_MASTER_DELTA=$alternate_tie_master_delta"
puts $status_fh "TIE_LOW_INSTANCE_DELTA=$tie_low_delta"
puts $status_fh "FILLER_COUNT_BEFORE=$filler_count_before"
puts $status_fh "FILLER_COUNT_AFTER=$filler_count_after"
puts $status_fh "FILLER_DELTA=$filler_delta"
puts $status_fh "FINAL_FILLER_MASTER_SET_STATUS=$final_filler_master_set_status"
puts $status_fh "NONFILLER_FINGERPRINT_STATUS=$nonfiller_fingerprint_status"
puts $status_fh "BASELINE_SITE_OCCUPANCY_STATUS=[expr {
    [dict get $baseline_density status] eq "PASS" && [dict get $baseline_density full] ?
        "PASS" : "FAIL"
}]"
puts $status_fh "BASELINE_PLACEMENT_SITE_OCCUPIED=[dict get $baseline_density occupied]"
puts $status_fh "BASELINE_PLACEMENT_SITE_CAPACITY=[dict get $baseline_density capacity]"
puts $status_fh "FINAL_SITE_OCCUPANCY_STATUS=$final_site_occupancy_status"
puts $status_fh "FINAL_PLACEMENT_SITE_OCCUPIED=[dict get $final_density occupied]"
puts $status_fh "FINAL_PLACEMENT_SITE_CAPACITY=[dict get $final_density capacity]"
puts $status_fh "TOTAL_INSTANCE_DELTA=$total_instance_delta"
puts $status_fh "UNEXPLAINED_INSTANCE_DELTA=$unexplained_instance_delta"
puts $status_fh "PHYSICAL_DEBT_PRESERVATION_STATUS=$debt_status"
if {$baseline_snapshot_status eq "PASS"} {
    mptdc_ckpt_write_snapshot_status $status_fh BASELINE $baseline
    puts $status_fh "BASELINE_REPORT_ROUTE_ZERO_STATUS=[expr {[dict get $baseline report_route_zero] ? "PASS" : "FAIL"}]"
    puts $status_fh "BASELINE_DRC_MARKER_SIGNATURE_COUNT=[llength [dict get $baseline marker_signature]]"
    puts $status_fh "BASELINE_DRC_MARKER_SIGNATURE=[dict get $baseline marker_signature]"
}
if {$final_snapshot_status eq "PASS"} {
    mptdc_ckpt_write_snapshot_status $status_fh FINAL $final
    puts $status_fh "FINAL_REPORT_ROUTE_ZERO_STATUS=[expr {[dict get $final report_route_zero] ? "PASS" : "FAIL"}]"
    puts $status_fh "FINAL_DRC_MARKER_SIGNATURE_COUNT=[llength [dict get $final marker_signature]]"
    puts $status_fh "FINAL_DRC_MARKER_SIGNATURE=[dict get $final marker_signature]"
}
puts $status_fh "CORE_QUERY_ERROR_COUNT=$::mptdc_tie1_trial_core_query_error_count"
puts $status_fh "QUERY_ERROR_COUNT=$::mptdc_tie1_trial_query_error_count"
puts $status_fh "TRIAL_FAILURE_REASONS=$trial_reasons"
puts $status_fh "CHECKPOINT_SAVE_STATUS=$save_status"
puts $status_fh "CANDIDATE_CHECKPOINT=$final_checkpoint_dat"
puts $status_fh "TIE1_INSERTION_TRIAL_STATUS=$trial_status"
close $status_fh

puts "MPTDC_TIE1_INSERTION_TRIAL_STATUS=$trial_status"
puts "MPTDC_TIE1_INSERTION_TRIAL_REPORT=$status_report"
puts "MPTDC_TIE1_HIGH_INSTANCE_DELTA=$tie_high_delta"
puts "MPTDC_TIE1_FINAL_CONNECTED_HIGH_TERM_COUNT=[dict get $final_state connected]"
puts "MPTDC_TIE1_FINAL_TIE_NET_COUNT=[dict get $net_inventory net_count]"
puts "MPTDC_TIE1_CHECKPOINT_SAVE_STATUS=$save_status"

if {$trial_status eq "PASS"} {
    exit 0
}
exit 1
