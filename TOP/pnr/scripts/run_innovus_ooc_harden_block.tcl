# =============================================================================
# SPADMIC matrix-top -- single-block Innovus OOC hardening flow
# =============================================================================

proc spadmic_ooc_env_required {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_OOC_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc spadmic_ooc_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc spadmic_ooc_truthy {value} {
    set normalized [string tolower [string trim $value]]
    return [expr {$normalized eq "1" || $normalized eq "yes" || $normalized eq "true" || $normalized eq "on"}]
}

set ::spadmic_ooc_repo_root [spadmic_ooc_env_required SPADMIC_REPO_ROOT]
set ::spadmic_ooc_run_root [spadmic_ooc_env_required SPADMIC_INNOVUS_RUN_ROOT]
set ::spadmic_ooc_block_root [spadmic_ooc_env_required SPADMIC_INNOVUS_BLOCK_ROOT]
set ::spadmic_ooc_handoff_root [spadmic_ooc_env_required SPADMIC_INNOVUS_HANDOFF_ROOT]
set ::spadmic_ooc_block [spadmic_ooc_env_required SPADMIC_INNOVUS_BLOCK]
set ::spadmic_ooc_top_module [spadmic_ooc_env_required SPADMIC_INNOVUS_TOP_MODULE]
set ::spadmic_ooc_netlist [spadmic_ooc_env_required SPADMIC_INNOVUS_NETLIST]
set ::spadmic_ooc_sdc [spadmic_ooc_env_required SPADMIC_INNOVUS_SDC]
set ::spadmic_ooc_config_tcl [spadmic_ooc_env_required SPADMIC_INNOVUS_CONFIG_TCL]
set ::spadmic_ooc_genus_summary [spadmic_ooc_env_required SPADMIC_INNOVUS_GENUS_SUMMARY]

set ::spadmic_ooc_reports_dir [file join $::spadmic_ooc_block_root reports]
set ::spadmic_ooc_outputs_dir [file join $::spadmic_ooc_block_root outputs]
set ::spadmic_ooc_checkpoints_dir [file join $::spadmic_ooc_block_root checkpoints]
set ::spadmic_ooc_logs_dir [file join $::spadmic_ooc_block_root logs]
set ::spadmic_ooc_generated_dir [file join $::spadmic_ooc_block_root generated]
file mkdir $::spadmic_ooc_reports_dir $::spadmic_ooc_outputs_dir $::spadmic_ooc_checkpoints_dir $::spadmic_ooc_logs_dir $::spadmic_ooc_generated_dir
file mkdir [file join $::spadmic_ooc_handoff_root innovus] [file join $::spadmic_ooc_handoff_root netlist] [file join $::spadmic_ooc_handoff_root reports]

source $::spadmic_ooc_config_tcl

array set ::spadmic_ooc_status {}
proc spadmic_ooc_status_set {key value} {
    set ::spadmic_ooc_status($key) $value
}

proc spadmic_ooc_cfg {name} {
    set var "::spadmic_ooc::$name"
    if {![info exists $var]} {
        error "SPADMIC_OOC_MISSING_CONFIG: $name"
    }
    return [set $var]
}

proc spadmic_ooc_cfg_default {name default_value} {
    set var "::spadmic_ooc::$name"
    if {![info exists $var]} {
        return $default_value
    }
    return [set $var]
}

proc spadmic_ooc_cfg_list {name} {
    return [spadmic_ooc_cfg $name]
}

proc spadmic_ooc_pg_sroute_enabled {} {
    set default_value [spadmic_ooc_cfg_default enable_pg_sroute 0]
    return [spadmic_ooc_truthy [spadmic_ooc_env SPADMIC_OOC_ENABLE_PG_SROUTE $default_value]]
}

proc spadmic_ooc_route_profile {} {
    set default_profile [spadmic_ooc_cfg_default route_profile default]
    return [string tolower [string trim [spadmic_ooc_env SPADMIC_OOC_ROUTE_PROFILE $default_profile]]]
}

proc spadmic_ooc_route_profile_met2_first {} {
    set profile [spadmic_ooc_route_profile]
    return [expr {[lsearch -exact [list met2_first met2_first_antenna] $profile] >= 0}]
}

proc spadmic_ooc_route_profile_effort_enabled {} {
    set profile [spadmic_ooc_route_profile]
    if {[lsearch -exact [list met2_first met2_first_antenna met1_effort met1_effort_antenna] $profile] >= 0} {
        return 1
    }
    return [spadmic_ooc_truthy [spadmic_ooc_env SPADMIC_OOC_ENABLE_ROUTE_EFFORT 0]]
}

proc spadmic_ooc_antenna_repair_enabled {} {
    set profile [spadmic_ooc_route_profile]
    set default_value [expr {[regexp -nocase {antenna} $profile] ? 1 : 0}]
    return [spadmic_ooc_truthy [spadmic_ooc_env SPADMIC_OOC_ENABLE_ANTENNA_REPAIR $default_value]]
}

proc spadmic_ooc_require_antenna_clean {} {
    set default_value [expr {[spadmic_ooc_antenna_repair_enabled] ? 1 : 0}]
    return [spadmic_ooc_truthy [spadmic_ooc_env SPADMIC_OOC_REQUIRE_ANTENNA_CLEAN $default_value]]
}

proc spadmic_ooc_core_width_um {} {
    return [spadmic_ooc_env SPADMIC_OOC_CORE_WIDTH_UM [spadmic_ooc_cfg core_width_um]]
}

proc spadmic_ooc_core_height_um {} {
    return [spadmic_ooc_env SPADMIC_OOC_CORE_HEIGHT_UM [spadmic_ooc_cfg core_height_um]]
}

proc spadmic_ooc_place_max_density {} {
    return [spadmic_ooc_env SPADMIC_OOC_PLACE_MAX_DENSITY [spadmic_ooc_cfg place_max_density]]
}

proc spadmic_ooc_configure_scan_placement {} {
    set rpt [file join $::spadmic_ooc_reports_dir SCAN_PLACEMENT_MODE.rpt]
    set enabled [spadmic_ooc_truthy [spadmic_ooc_env SPADMIC_OOC_IGNORE_UNDEFINED_SCAN 1]]
    set allow_reorder [spadmic_ooc_truthy [spadmic_ooc_env SPADMIC_OOC_ALLOW_SCAN_REORDER 0]]
    set fh [open $rpt w]
    puts $fh "LABEL=SCAN_PLACEMENT_MODE"
    puts $fh "SPADMIC_OOC_IGNORE_UNDEFINED_SCAN=[expr {$enabled ? 1 : 0}]"
    puts $fh "SPADMIC_OOC_ALLOW_SCAN_REORDER=[expr {$allow_reorder ? 1 : 0}]"
    if {!$enabled} {
        puts $fh "STATUS=DISABLED_BY_ENV"
        puts $fh "REASON=Undefined scan-chain handling left to default Innovus placement policy."
        close $fh
        spadmic_ooc_status_set SCAN_PLACEMENT_MODE DISABLED_BY_ENV
        return
    }

    set required_cmds [list \
        {setPlaceMode -place_global_ignore_scan true} \
        {setPlaceMode -ignoreScan true}]
    set optional_cmds [list]
    if {!$allow_reorder} {
        set optional_cmds [list \
            {setPlaceMode -place_global_reorder_scan false} \
            {setPlaceMode -place_detail_reorder_scan false}]
    }

    set required_pass 0
    set required_fail 0
    set optional_pass 0
    set optional_fail 0
    foreach cmd $required_cmds {
        puts $fh "TRY_REQUIRED=$cmd"
        if {![catch {uplevel #0 $cmd} err]} {
            incr required_pass
            puts $fh "TRY_STATUS=PASS"
            puts $fh "COMMAND=$cmd"
        } else {
            incr required_fail
            puts $fh "TRY_STATUS=FAIL"
            puts $fh "ERROR=[spadmic_ooc_report_value $err]"
        }
    }
    foreach cmd $optional_cmds {
        puts $fh "TRY_OPTIONAL=$cmd"
        if {![catch {uplevel #0 $cmd} err]} {
            incr optional_pass
            puts $fh "TRY_STATUS=PASS"
            puts $fh "COMMAND=$cmd"
        } else {
            incr optional_fail
            puts $fh "TRY_STATUS=FAIL"
            puts $fh "ERROR=[spadmic_ooc_report_value $err]"
        }
    }

    puts $fh "REQUIRED_PASS_COUNT=$required_pass"
    puts $fh "REQUIRED_FAIL_COUNT=$required_fail"
    puts $fh "OPTIONAL_PASS_COUNT=$optional_pass"
    puts $fh "OPTIONAL_FAIL_COUNT=$optional_fail"
    if {$required_pass > 0} {
        puts $fh "STATUS=PASS"
        spadmic_ooc_status_set SCAN_PLACEMENT_MODE PASS
    } else {
        puts $fh "STATUS=REVIEW_REQUIRED"
        spadmic_ooc_status_set SCAN_PLACEMENT_MODE REVIEW_REQUIRED
    }
    close $fh
}

proc spadmic_ooc_layer_index {layer fallback} {
    if {[string is integer -strict $layer]} {
        return $layer
    }
    set upper [string toupper $layer]
    if {[regexp {^MET([0-9]+)$} $upper -> idx]} {
        return $idx
    }
    if {$upper eq "METTP"} {
        return 4
    }
    return $fallback
}

proc spadmic_ooc_snap_to_grid {value {grid 0.56}} {
    if {$grid <= 0.0} {
        return $value
    }
    return [format %.3f [expr {round(double($value) / double($grid)) * double($grid)}]]
}

proc spadmic_ooc_write_text {path lines} {
    set fh [open $path w]
    foreach line $lines {
        puts $fh $line
    }
    close $fh
}

proc spadmic_ooc_try_first {label commands {required 1}} {
    set rpt [file join $::spadmic_ooc_reports_dir "${label}.rpt"]
    set fh [open $rpt w]
    puts $fh "LABEL=$label"
    set last_err ""
    foreach cmd $commands {
        puts $fh "TRY=$cmd"
        if {![catch {uplevel #0 $cmd} err]} {
            puts $fh "STATUS=PASS"
            puts $fh "COMMAND=$cmd"
            close $fh
            spadmic_ooc_status_set $label PASS
            return 1
        }
        puts $fh "ERROR=$err"
        set last_err $err
    }
    puts $fh "STATUS=FAIL"
    close $fh
    spadmic_ooc_status_set $label FAIL
    if {$required} {
        error "SPADMIC_OOC_COMMAND_FAILED: label=$label error=$last_err"
    }
    return 0
}

proc spadmic_ooc_try_all {label commands {required_any 1}} {
    set rpt [file join $::spadmic_ooc_reports_dir "${label}.rpt"]
    set fh [open $rpt w]
    puts $fh "LABEL=$label"
    set pass_count 0
    set fail_count 0
    set last_err ""
    foreach cmd $commands {
        puts $fh "TRY=$cmd"
        if {![catch {uplevel #0 $cmd} err]} {
            incr pass_count
            puts $fh "TRY_STATUS=PASS"
            puts $fh "COMMAND=$cmd"
        } else {
            incr fail_count
            puts $fh "TRY_STATUS=FAIL"
            puts $fh "ERROR=$err"
            set last_err $err
        }
    }
    puts $fh "PASS_COUNT=$pass_count"
    puts $fh "FAIL_COUNT=$fail_count"
    if {$pass_count > 0} {
        puts $fh "STATUS=PASS"
        close $fh
        spadmic_ooc_status_set $label PASS
        return 1
    }
    puts $fh "STATUS=FAIL"
    close $fh
    spadmic_ooc_status_set $label FAIL
    if {$required_any} {
        error "SPADMIC_OOC_COMMAND_FAILED: label=$label error=$last_err"
    }
    return 0
}

proc spadmic_ooc_capture_first {path label commands {required 1}} {
    set fh [open $path w]
    puts $fh "LABEL=$label"
    close $fh
    set last_err ""
    foreach cmd $commands {
        set fh [open $path a]
        puts $fh "TRY=$cmd"
        close $fh
        if {![catch {redirect -append -file $path $cmd} err]} {
            set fh [open $path a]
            puts $fh "STATUS=PASS"
            puts $fh "COMMAND=$cmd"
            close $fh
            return 1
        }
        set fh [open $path a]
        puts $fh "ERROR=$err"
        close $fh
        set last_err $err
    }
    set fh [open $path a]
    puts $fh "STATUS=FAIL"
    close $fh
    if {$required} {
        error "SPADMIC_OOC_REPORT_COMMAND_FAILED: label=$label path=$path error=$last_err"
    }
    return 0
}

proc spadmic_ooc_parse_drc_report {path} {
    set result UNKNOWN
    if {![file exists $path]} {
        return MISSING
    }
    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {[regexp -nocase {REPORT_STATUS=FAILED|STATUS=FAIL} $trimmed]} {
            set result FAIL
        }
        if {[regexp -nocase {Verification[[:space:]]+Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viols?} $trimmed -> count]} {
            set result [expr {$count == 0 ? "PASS" : "FAIL"}]
        }
        if {[regexp -nocase {No[[:space:]]+(DRC[[:space:]]+)?violations?[[:space:]]+found} $trimmed]} {
            set result PASS
        }
        if {[regexp -nocase {Total[[:space:]]+number[[:space:]]+of[[:space:]]+DRC[[:space:]]+violations[[:space:]]*=[[:space:]]*([0-9]+)} $trimmed -> count] ||
            [regexp -nocase {number[[:space:]]+of[[:space:]]+violations[[:space:]]*=[[:space:]]*([0-9]+)} $trimmed -> count]} {
            set result [expr {$count == 0 ? "PASS" : "FAIL"}]
        }
    }
    close $fh
    return $result
}

proc spadmic_ooc_report_value {value} {
    regsub -all {\s+} $value { } compact
    return [string trim $compact]
}

proc spadmic_ooc_flat_box {raw} {
    set values [list]
    foreach item $raw {
        foreach value $item {
            lappend values $value
        }
    }
    if {[llength $values] < 4} {
        return [list UNKNOWN UNKNOWN UNKNOWN UNKNOWN]
    }
    return [lrange $values 0 3]
}

proc spadmic_ooc_numeric_or_unknown {value} {
    if {[string is double -strict $value]} {
        return $value
    }
    return UNKNOWN
}

proc spadmic_ooc_unique_append {var_name value} {
    upvar 1 $var_name values
    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}

proc spadmic_ooc_write_marker_dump {path} {
    file mkdir [file dirname $path]
    set schema_rpt [file rootname $path]_schema.rpt
    catch {dbSchema marker > $schema_rpt}
    catch {help marker >> $schema_rpt}

    set markers [list]
    catch {set markers [dbGet top.markers]}

    set fh [open $path w]
    puts $fh "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\tlayer\ttype\tsubType\tmessage"
    set idx 0
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} {
            continue
        }
        incr idx
        set box UNKNOWN
        set layer UNKNOWN
        set type UNKNOWN
        set subtype UNKNOWN
        set message UNKNOWN
        catch {set box [dbGet $marker.box]}
        catch {set layer [dbGet $marker.layer.name]}
        catch {set type [dbGet $marker.type]}
        catch {set subtype [dbGet $marker.subType]}
        catch {set message [dbGet $marker.message]}

        lassign [spadmic_ooc_flat_box $box] llx lly urx ury
        set llx [spadmic_ooc_numeric_or_unknown $llx]
        set lly [spadmic_ooc_numeric_or_unknown $lly]
        set urx [spadmic_ooc_numeric_or_unknown $urx]
        set ury [spadmic_ooc_numeric_or_unknown $ury]
        set cx UNKNOWN
        set cy UNKNOWN
        if {$llx ne "UNKNOWN" && $urx ne "UNKNOWN"} {
            set cx [format %.6f [expr {($llx + $urx) / 2.0}]]
        }
        if {$lly ne "UNKNOWN" && $ury ne "UNKNOWN"} {
            set cy [format %.6f [expr {($lly + $ury) / 2.0}]]
        }

        puts $fh "$idx\t[spadmic_ooc_report_value $marker]\t[spadmic_ooc_report_value $box]\t$llx\t$lly\t$urx\t$ury\t$cx\t$cy\t[spadmic_ooc_report_value $layer]\t[spadmic_ooc_report_value $type]\t[spadmic_ooc_report_value $subtype]\t[spadmic_ooc_report_value $message]"
    }
    close $fh
    return $idx
}

proc spadmic_ooc_marker_min_area_nets {} {
    set nets [list]
    set rows [list]
    set markers [list]
    catch {set markers [dbGet top.markers]}
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} {
            continue
        }
        set layer ""
        set type ""
        set subtype ""
        set message ""
        set box UNKNOWN
        catch {set box [dbGet $marker.box]}
        catch {set layer [dbGet $marker.layer.name]}
        catch {set type [dbGet $marker.type]}
        catch {set subtype [dbGet $marker.subType]}
        catch {set message [dbGet $marker.message]}
        if {![string equal -nocase $layer "MET1"]} {
            continue
        }
        if {![string equal -nocase $type "Geometry"]} {
            continue
        }
        if {![regexp -nocase {Minimal_Area|Minimum[[:space:]]+Area|Mar} $subtype] &&
            ![regexp -nocase {Minimum[[:space:]]+Area|Minimal_Area} $message]} {
            continue
        }
        if {![regexp -nocase {Regular[[:space:]]+Wire[[:space:]]+of[[:space:]]+Net[[:space:]]+([^[:space:]]+)} $message -> net]} {
            continue
        }
        spadmic_ooc_unique_append nets $net
        lappend rows [list $net $marker [spadmic_ooc_flat_box $box] [spadmic_ooc_report_value $message]]
    }
    return [list $nets $rows]
}

proc spadmic_ooc_marker_classification {} {
    array set counts {
        total 0
        met1_min_area 0
        antenna 0
        expected_pg_connectivity 0
        other 0
    }
    set min_area_nets [list]
    set antenna_nets [list]
    set other_rows [list]
    set markers [list]
    catch {set markers [dbGet top.markers]}
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} {
            continue
        }
        incr counts(total)
        set layer ""
        set type ""
        set subtype ""
        set message ""
        catch {set layer [dbGet $marker.layer.name]}
        catch {set type [dbGet $marker.type]}
        catch {set subtype [dbGet $marker.subType]}
        catch {set message [dbGet $marker.message]}

        set report_msg [spadmic_ooc_report_value $message]
        set is_min_area 0
        if {[string equal -nocase $layer "MET1"] &&
            [string equal -nocase $type "Geometry"] &&
            ([regexp -nocase {Minimal_Area|Minimum[[:space:]]+Area|Mar} $subtype] ||
             [regexp -nocase {Minimum[[:space:]]+Area|Minimal_Area} $message])} {
            set is_min_area 1
        }
        if {$is_min_area} {
            incr counts(met1_min_area)
            if {[regexp -nocase {Regular[[:space:]]+Wire[[:space:]]+of[[:space:]]+Net[[:space:]]+([^[:space:]]+)} $message -> net]} {
                spadmic_ooc_unique_append min_area_nets $net
            }
            continue
        }

        set is_expected_pg 0
        if {![spadmic_ooc_pg_sroute_enabled] &&
            [string equal -nocase $type "Connectivity"] &&
            [regexp -nocase {Net[[:space:]]+(VDD|VSS)} $message]} {
            set is_expected_pg 1
        }
        if {$is_expected_pg} {
            incr counts(expected_pg_connectivity)
            continue
        }

        set is_antenna 0
        if {[string equal -nocase $type "Antenna"] ||
            [regexp -nocase {Antenna|Ant.*Area|ProcessAntenna} $subtype] ||
            [regexp -nocase {Antenna|S[.]PAR|Antenna[[:space:]]+Side[[:space:]]+Area} $message]} {
            set is_antenna 1
        }
        if {$is_antenna} {
            incr counts(antenna)
            if {[regexp -nocase {Regular[[:space:]]+Wire[[:space:]]+of[[:space:]]+Net[[:space:]]+([^[:space:]]+)} $message -> net]} {
                spadmic_ooc_unique_append antenna_nets $net
            }
            continue
        }

        incr counts(other)
        lappend other_rows "$marker:$layer:$type:$subtype:$report_msg"
    }
    return [list \
        total $counts(total) \
        met1_min_area $counts(met1_min_area) \
        antenna $counts(antenna) \
        expected_pg_connectivity $counts(expected_pg_connectivity) \
        other $counts(other) \
        min_area_nets $min_area_nets \
        antenna_nets $antenna_nets \
        other_rows $other_rows]
}

proc spadmic_ooc_write_marker_classification {path} {
    array set cls [spadmic_ooc_marker_classification]
    set require_antenna [spadmic_ooc_require_antenna_clean]
    set min_area_status [expr {$cls(met1_min_area) == 0 ? "PASS" : "FAIL"}]
    set antenna_status [expr {$cls(antenna) == 0 ? "PASS" : ($require_antenna ? "FAIL" : "REVIEW_REQUIRED")}]
    set other_status [expr {$cls(other) == 0 ? "PASS" : "FAIL"}]
    set overall [expr {$min_area_status eq "PASS" && $antenna_status eq "PASS" && $other_status eq "PASS" ? "PASS" : "FAIL"}]

    spadmic_ooc_write_text $path [list \
        "LABEL=DRC_MARKER_CLASSIFICATION" \
        "STATUS=$overall" \
        "MARKER_TOTAL=$cls(total)" \
        "MET1_MIN_AREA_MARKER_COUNT=$cls(met1_min_area)" \
        "MET1_MIN_AREA_NETS=[join $cls(min_area_nets) { }]" \
        "ANTENNA_MARKER_COUNT=$cls(antenna)" \
        "ANTENNA_NETS=[join $cls(antenna_nets) { }]" \
        "EXPECTED_PG_CONNECTIVITY_MARKER_COUNT=$cls(expected_pg_connectivity)" \
        "OTHER_MARKER_COUNT=$cls(other)" \
        "OTHER_MARKERS=[join $cls(other_rows) {; }]" \
        "REQUIRE_ANTENNA_CLEAN=[expr {$require_antenna ? 1 : 0}]" \
        "MIN_AREA_MARKER_STATUS=$min_area_status" \
        "ANTENNA_MARKER_STATUS=$antenna_status" \
        "OTHER_MARKER_STATUS=$other_status" \
    ]

    spadmic_ooc_status_set DRC_MARKER_CLASSIFICATION $overall
    spadmic_ooc_status_set DRC_MARKER_TOTAL $cls(total)
    spadmic_ooc_status_set MET1_MIN_AREA_MARKER_COUNT $cls(met1_min_area)
    spadmic_ooc_status_set MET1_MIN_AREA_MARKER_STATUS $min_area_status
    spadmic_ooc_status_set ANTENNA_MARKER_COUNT $cls(antenna)
    spadmic_ooc_status_set ANTENNA_MARKER_STATUS $antenna_status
    spadmic_ooc_status_set EXPECTED_PG_CONNECTIVITY_MARKER_COUNT $cls(expected_pg_connectivity)
    spadmic_ooc_status_set OTHER_MARKER_COUNT $cls(other)
    spadmic_ooc_status_set OTHER_MARKER_STATUS $other_status
    return $overall
}

proc spadmic_ooc_box_is_numeric {box} {
    if {[llength $box] != 4} {
        return 0
    }
    foreach value $box {
        if {![string is double -strict $value]} {
            return 0
        }
    }
    return 1
}

proc spadmic_ooc_expand_box {box delta} {
    lassign $box llx lly urx ury
    return [list \
        [format %.3f [expr {$llx - $delta}]] \
        [format %.3f [expr {$lly - $delta}]] \
        [format %.3f [expr {$urx + $delta}]] \
        [format %.3f [expr {$ury + $delta}]]]
}

proc spadmic_ooc_selected_net_min_area_repair {} {
    if {![spadmic_ooc_truthy [spadmic_ooc_env SPADMIC_OOC_ENABLE_MIN_AREA_REPAIR 1]]} {
        spadmic_ooc_status_set POSTROUTE_MIN_AREA_REPAIR DISABLED
        spadmic_ooc_write_text [file join $::spadmic_ooc_reports_dir POSTROUTE_MIN_AREA_REPAIR.rpt] [list \
            "LABEL=POSTROUTE_MIN_AREA_REPAIR" \
            "STATUS=DISABLED" \
            "OVERRIDE=Set SPADMIC_OOC_ENABLE_MIN_AREA_REPAIR=1 to run selected-net MET1 min-area repair." \
        ]
        return 0
    }

    set rpt [file join $::spadmic_ooc_reports_dir POSTROUTE_MIN_AREA_REPAIR.rpt]
    set pre_drc [file join $::spadmic_ooc_reports_dir postroute_min_area_repair_pre_verify_drc.rpt]
    set pre_markers [file join $::spadmic_ooc_reports_dir postroute_min_area_repair_pre_markers.tsv]
    set post_drc [file join $::spadmic_ooc_reports_dir postroute_min_area_repair_post_verify_drc.rpt]
    set post_markers [file join $::spadmic_ooc_reports_dir postroute_min_area_repair_post_markers.tsv]

    set fh [open $rpt w]
    puts $fh "LABEL=POSTROUTE_MIN_AREA_REPAIR"
    puts $fh "PRE_DRC_REPORT=$pre_drc"
    puts $fh "PRE_MARKER_REPORT=$pre_markers"
    close $fh

    if {[catch {redirect -file $pre_drc {verify_drc}} err]} {
        set fh [open $rpt a]
        puts $fh "STATUS=FAIL"
        puts $fh "REASON=pre_verify_failed"
        puts $fh "ERROR=[spadmic_ooc_report_value $err]"
        close $fh
        spadmic_ooc_status_set POSTROUTE_MIN_AREA_REPAIR FAIL
        return 0
    }
    set pre_marker_count [spadmic_ooc_write_marker_dump $pre_markers]
    lassign [spadmic_ooc_marker_min_area_nets] nets rows
    set fh [open $rpt a]
    puts $fh "PRE_MARKER_COUNT=$pre_marker_count"
    puts $fh "MIN_AREA_MARKER_COUNT=[llength $rows]"
    puts $fh "MIN_AREA_NET_COUNT=[llength $nets]"
    puts $fh "MIN_AREA_NETS=[join $nets { }]"
    foreach row $rows {
        puts $fh "MIN_AREA_MARKER=[spadmic_ooc_report_value $row]"
    }
    close $fh

    if {[llength $nets] == 0} {
        set pre_status [spadmic_ooc_parse_drc_report $pre_drc]
        set fh [open $rpt a]
        puts $fh "STATUS=SKIPPED_NO_MET1_MIN_AREA_MARKERS"
        puts $fh "PRE_DRC_STATUS=$pre_status"
        close $fh
        spadmic_ooc_status_set POSTROUTE_MIN_AREA_REPAIR SKIPPED_NO_MARKERS
        return 0
    }

    catch {setNanoRouteMode -route_with_via_in_pin false}
    catch {setNanoRouteMode -route_with_via_only_for_block_cell_pin false}
    set selected_mode_ok 1
    set selected_mode_error ""
    if {[catch {setNanoRouteMode -route_selected_net_only true} selected_mode_error]} {
        set selected_mode_ok 0
    }
    catch {deselectAll}

    set selected [list]
    set selection_failures [list]
    foreach net $nets {
        if {![catch {selectNet $net} err]} {
            lappend selected $net
        } else {
            lappend selection_failures "$net:$err"
        }
    }

    if {!$selected_mode_ok || [llength $selected] == 0} {
        catch {setNanoRouteMode -route_selected_net_only false}
        catch {deselectAll}
        set fh [open $rpt a]
        puts $fh "SELECTED_NET_MODE_STATUS=[expr {$selected_mode_ok ? "PASS" : "FAIL"}]"
        puts $fh "SELECTED_NET_MODE_ERROR=[spadmic_ooc_report_value $selected_mode_error]"
        puts $fh "SELECTED_NET_COUNT=[llength $selected]"
        puts $fh "SELECTION_FAILURES=[join $selection_failures {; }]"
        puts $fh "STATUS=FAIL"
        close $fh
        spadmic_ooc_status_set POSTROUTE_MIN_AREA_REPAIR FAIL
        return 0
    }

    set area_delete_count 0
    set area_delete_failures [list]
    foreach row $rows {
        set net [lindex $row 0]
        set box [lindex $row 2]
        if {[lsearch -exact $selected $net] < 0} {
            continue
        }
        if {![spadmic_ooc_box_is_numeric $box]} {
            lappend area_delete_failures "$net:non_numeric_box=$box"
            continue
        }
        set expanded_box [spadmic_ooc_expand_box $box 0.010]
        if {[catch {editDelete -net $net -layer MET1 -area $expanded_box -type Regular} err]} {
            lappend area_delete_failures "$net:$expanded_box:$err"
        } else {
            incr area_delete_count
        }
    }

    set drc_wire_delete_failures [list]
    foreach net $selected {
        if {[catch {editDelete -net $net -regular_wire_with_drc} err]} {
            lappend drc_wire_delete_failures "$net:$err"
        }
    }

    set route_commands [list {globalDetailRoute -select} {detailRoute -select} {ecoRoute -fix_drc}]
    set route_failures [list]
    foreach cmd $route_commands {
        if {[catch {uplevel #0 $cmd} err]} {
            lappend route_failures "$cmd:$err"
        }
    }
    catch {setNanoRouteMode -route_selected_net_only false}
    catch {deselectAll}

    if {[catch {redirect -file $post_drc {verify_drc}} err]} {
        set fh [open $rpt a]
        puts $fh "POST_DRC_REPORT=$post_drc"
        puts $fh "POST_DRC_STATUS=FAIL"
        puts $fh "POST_DRC_ERROR=[spadmic_ooc_report_value $err]"
        close $fh
        spadmic_ooc_status_set POSTROUTE_MIN_AREA_REPAIR FAIL
        return 1
    }
    set post_marker_count [spadmic_ooc_write_marker_dump $post_markers]
    set post_status [spadmic_ooc_parse_drc_report $post_drc]

    set fh [open $rpt a]
    puts $fh "SELECTED_NET_MODE_STATUS=PASS"
    puts $fh "SELECTED_NET_COUNT=[llength $selected]"
    puts $fh "SELECTED_NETS=[join $selected { }]"
    puts $fh "SELECTION_FAILURES=[join $selection_failures {; }]"
    puts $fh "AREA_DELETE_COUNT=$area_delete_count"
    puts $fh "AREA_DELETE_FAILURES=[join $area_delete_failures {; }]"
    puts $fh "DRC_WIRE_DELETE_FAILURES=[join $drc_wire_delete_failures {; }]"
    puts $fh "ROUTE_COMMANDS=$route_commands"
    puts $fh "ROUTE_FAILURES=[join $route_failures {; }]"
    puts $fh "POST_DRC_REPORT=$post_drc"
    puts $fh "POST_MARKER_REPORT=$post_markers"
    puts $fh "POST_MARKER_COUNT=$post_marker_count"
    puts $fh "POST_DRC_STATUS=$post_status"
    set status [expr {$post_status eq "PASS" ? "PASS" : "REVIEW_REQUIRED"}]
    puts $fh "STATUS=$status"
    close $fh
    spadmic_ooc_status_set POSTROUTE_MIN_AREA_REPAIR $status
    return 1
}

proc spadmic_ooc_connectivity_status {path} {
    if {![file exists $path]} {
        return MISSING
    }
    set bad 0
    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {[regexp -nocase {STATUS=FAIL|REPORT_STATUS=FAILED} $trimmed]} {
            set bad 1
        }
        if {[regexp -nocase {Found[[:space:]]+no[[:space:]]+problems[[:space:]]+or[[:space:]]+warnings} $trimmed] ||
            [regexp -nocase {Verification[[:space:]]+Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols?[.][[:space:]]+0[[:space:]]+Wrngs[.]} $trimmed]} {
            continue
        }
        if {[regexp -nocase {^(Error|Warning)[[:space:]]+Limit[[:space:]]*=} $trimmed]} {
            continue
        }
        if {[regexp -nocase {problem|short|open|unconnected|not[[:space:]]+connected|violation|error} $trimmed] &&
            ![regexp -nocase {no.*(problems|short|open|error|violation)|0[[:space:]]+(problems?|short|open|error|violation|viols)} $trimmed]} {
            set bad 1
        }
    }
    close $fh
    return [expr {$bad ? "FAIL" : "PASS"}]
}

proc spadmic_ooc_regular_connectivity_status {path} {
    if {![spadmic_ooc_pg_sroute_enabled]} {
        if {![file exists $path]} {
            return MISSING
        }
        set bad 0
        set ignored_pg_no_route 0
        set fh [open $path r]
        while {[gets $fh line] >= 0} {
            set trimmed [string trim $line]
            if {$trimmed eq ""} {
                continue
            }
            if {[regexp -nocase {STATUS=FAIL|REPORT_STATUS=FAILED} $trimmed]} {
                set bad 1
                continue
            }
            if {[regexp -nocase {^Net[[:space:]]+(VDD|VSS):[[:space:]]+no[[:space:]]+routing[.]?$} $trimmed]} {
                set ignored_pg_no_route 1
                continue
            }
            if {[regexp -nocase {^[0-9]+[[:space:]]+Problem\(s\)[[:space:]]+\(IMPVFC-98\):[[:space:]]+Net[[:space:]]+has[[:space:]]+no[[:space:]]+global[[:space:]]+routing[[:space:]]+and[[:space:]]+no[[:space:]]+special[[:space:]]+routing[.]?$} $trimmed]} {
                set ignored_pg_no_route 1
                continue
            }
            if {[regexp -nocase {^[0-9]+[[:space:]]+total[[:space:]]+info\(s\)[[:space:]]+created[.]?$} $trimmed]} {
                continue
            }
            if {$ignored_pg_no_route &&
                [regexp -nocase {^Verification[[:space:]]+Complete[[:space:]]*:[[:space:]]*[0-9]+[[:space:]]+Viols?[.][[:space:]]+0[[:space:]]+Wrngs[.]?$} $trimmed]} {
                continue
            }
            if {[regexp -nocase {Found[[:space:]]+no[[:space:]]+problems[[:space:]]+or[[:space:]]+warnings} $trimmed] ||
                [regexp -nocase {Verification[[:space:]]+Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols?[.][[:space:]]+0[[:space:]]+Wrngs[.]} $trimmed]} {
                continue
            }
            if {[regexp -nocase {^(Error|Warning)[[:space:]]+Limit[[:space:]]*=} $trimmed]} {
                continue
            }
            if {[regexp -nocase {problem|short|open|unconnected|not[[:space:]]+connected|violation|error} $trimmed] &&
                ![regexp -nocase {no.*(problems|short|open|error|violation)|0[[:space:]]+(problems?|short|open|error|violation|viols)} $trimmed]} {
                set bad 1
            }
        }
        close $fh
        if {$ignored_pg_no_route && !$bad} {
            spadmic_ooc_status_set REGULAR_CONNECTIVITY_NOTE PG_VDD_VSS_NO_ROUTE_IGNORED_BY_DEFER_POLICY
        }
        return [expr {$bad ? "FAIL" : "PASS"}]
    }
    return [spadmic_ooc_connectivity_status $path]
}

proc spadmic_ooc_require_file {label path} {
    if {![file exists $path] || [file size $path] == 0} {
        error "SPADMIC_OOC_REQUIRED_FILE_MISSING: $label path=$path"
    }
    spadmic_ooc_status_set $label PASS
}

proc spadmic_ooc_write_mmmc {path} {
    global tech_files
    set fh [open $path w]
    puts $fh "create_constraint_mode -name tc_ooc_mode -sdc_files \[list $::spadmic_ooc_sdc\]"
    if {[info exists tech_files(CAPTABLE_TC)] && [file exists $tech_files(CAPTABLE_TC)]} {
        puts $fh "create_rc_corner -name tc_rc -temperature 25 -cap_table $tech_files(CAPTABLE_TC)"
    } else {
        puts $fh "create_rc_corner -name tc_rc -temperature 25"
    }
    puts $fh "create_library_set -name tc_libset -timing \[list $tech_files(ALL_TC_LIBS)\]"
    puts $fh "create_delay_corner -name tc_corner -library_set tc_libset -rc_corner tc_rc"
    puts $fh "create_analysis_view -name tc_view -constraint_mode tc_ooc_mode -delay_corner tc_corner"
    puts $fh "set_analysis_view -setup tc_view -hold tc_view"
    close $fh
}

proc spadmic_ooc_source_libraries {} {
    global design tech tech_files mptdc_xh018_cells
    set design(project_root) [file join $::spadmic_ooc_repo_root MPTDC]
    set design(TOPLEVEL) $::spadmic_ooc_top_module
    source [file join $::spadmic_ooc_repo_root MPTDC syn libraries libraries.xh018.tcl]
    source [file join $::spadmic_ooc_repo_root MPTDC syn libraries libraries.xh018-stdcells.tcl]
    source [file join $::spadmic_ooc_repo_root MPTDC pnr config xh018_cells.tcl]
    mptdc_xh018_validate_policy implementation
    spadmic_ooc_status_set LIBRARY_SOURCE PASS
}

proc spadmic_ooc_init_design {} {
    global tech tech_files init_top_cell init_verilog init_lef_file init_mmmc_file init_pwr_net init_gnd_net init_design_uniquify
    set mmmc [file join $::spadmic_ooc_generated_dir typical_only.mmmc]
    spadmic_ooc_write_mmmc $mmmc
    set init_top_cell $::spadmic_ooc_top_module
    set init_verilog $::spadmic_ooc_netlist
    set init_lef_file $tech_files(ALL_LEFS)
    set init_mmmc_file $mmmc
    set init_pwr_net $tech(STANDARD_CELL_VDD)
    set init_gnd_net $tech(STANDARD_CELL_GND)
    set init_design_uniquify 1
    init_design
    foreach pg_pin $tech(STANDARD_CELL_VDD_PINS) {
        catch {globalNetConnect $tech(STANDARD_CELL_VDD) -type pgpin -pin $pg_pin -inst *}
    }
    foreach pg_pin $tech(STANDARD_CELL_GND_PINS) {
        catch {globalNetConnect $tech(STANDARD_CELL_GND) -type pgpin -pin $pg_pin -inst *}
    }
    spadmic_ooc_status_set INIT_DESIGN PASS
}

proc spadmic_ooc_floorplan {} {
    set core_w [spadmic_ooc_core_width_um]
    set core_h [spadmic_ooc_core_height_um]
    set margin [spadmic_ooc_cfg core_margin_um]
    set site [spadmic_ooc_cfg stdcell_site]
    spadmic_ooc_status_set CORE_WIDTH_UM $core_w
    spadmic_ooc_status_set CORE_HEIGHT_UM $core_h
    spadmic_ooc_status_set CORE_MARGIN_UM $margin
    set cmds [list \
        [list floorPlan -site $site -s $core_w $core_h $margin $margin $margin $margin] \
        [list floorPlan -site $site -d [expr {$core_w + 2.0 * $margin}] [expr {$core_h + 2.0 * $margin}] $margin $margin $margin $margin]]
    spadmic_ooc_try_first FLOORPLAN $cmds 1
}

proc spadmic_ooc_die_size {} {
    set core_w [spadmic_ooc_core_width_um]
    set core_h [spadmic_ooc_core_height_um]
    set margin [spadmic_ooc_cfg core_margin_um]
    return [list [expr {$core_w + 2.0 * $margin}] [expr {$core_h + 2.0 * $margin}]]
}

proc spadmic_ooc_pg_pin_centers {} {
    set pg_grid [spadmic_ooc_cfg_default pg_grid_um 0.56]
    lassign [spadmic_ooc_die_size] die_w die_h
    set vdd_cx [spadmic_ooc_snap_to_grid [expr {$die_w * 0.25}] $pg_grid]
    set vss_cx [spadmic_ooc_snap_to_grid [expr {$die_w * 0.75}] $pg_grid]
    return [list $vdd_cx $vss_cx]
}

proc spadmic_ooc_create_pg_pins {} {
    set layer [spadmic_ooc_cfg power_layer]
    set power_net [spadmic_ooc_cfg pg_power_net]
    set ground_net [spadmic_ooc_cfg pg_ground_net]
    set power_pin [spadmic_ooc_cfg pg_power_pin]
    set ground_pin [spadmic_ooc_cfg pg_ground_pin]
    set pg_width [spadmic_ooc_cfg pg_pin_width_um]
    set pg_depth [spadmic_ooc_cfg pg_pin_depth_um]
    set pg_grid [spadmic_ooc_cfg_default pg_grid_um 0.56]
    lassign [spadmic_ooc_die_size] die_w die_h
    set y2 [spadmic_ooc_snap_to_grid $die_h $pg_grid]
    set y1 [spadmic_ooc_snap_to_grid [expr {$y2 - $pg_depth}] $pg_grid]
    lassign [spadmic_ooc_pg_pin_centers] vdd_cx vss_cx
    set half_width [expr {$pg_width / 2.0}]
    set vdd_llx [spadmic_ooc_snap_to_grid [expr {$vdd_cx - $half_width}] $pg_grid]
    set vdd_urx [spadmic_ooc_snap_to_grid [expr {$vdd_cx + $half_width}] $pg_grid]
    set vss_llx [spadmic_ooc_snap_to_grid [expr {$vss_cx - $half_width}] $pg_grid]
    set vss_urx [spadmic_ooc_snap_to_grid [expr {$vss_cx + $half_width}] $pg_grid]
    spadmic_ooc_try_first CREATE_PG_PIN_VDD [list \
        [list createPGPin $power_pin -net $power_net -geom $layer $vdd_llx $y1 $vdd_urx $y2 -dir bidi] \
        [list createPGPin $power_pin -net $power_net -geom $layer $vdd_llx $y1 $vdd_urx $y2]] 1
    spadmic_ooc_try_first CREATE_PG_PIN_VSS [list \
        [list createPGPin $ground_pin -net $ground_net -geom $layer $vss_llx $y1 $vss_urx $y2 -dir bidi] \
        [list createPGPin $ground_pin -net $ground_net -geom $layer $vss_llx $y1 $vss_urx $y2]] 1
    spadmic_ooc_status_set PG_PIN_VDD_CENTER_X_UM $vdd_cx
    spadmic_ooc_status_set PG_PIN_VSS_CENTER_X_UM $vss_cx
    spadmic_ooc_status_set PG_PIN_TOP_Y_UM $y2
}

proc spadmic_ooc_create_pg_straps {} {
    set layer [spadmic_ooc_cfg power_layer]
    set power_net [spadmic_ooc_cfg pg_power_net]
    set ground_net [spadmic_ooc_cfg pg_ground_net]
    set strap_width [spadmic_ooc_cfg_default pg_strap_width_um [spadmic_ooc_cfg pg_pin_depth_um]]
    set strap_spacing [spadmic_ooc_cfg_default pg_strap_spacing_um $strap_width]
    set pg_grid [spadmic_ooc_cfg_default pg_grid_um 0.56]
    set strategy [string tolower [spadmic_ooc_cfg_default pg_route_strategy legacy_addstripe]]
    set core_margin [spadmic_ooc_cfg core_margin_um]
    set ground_rail_offset [spadmic_ooc_cfg_default pg_ground_first_rail_offset_um 4.48]
    lassign [spadmic_ooc_die_size] die_w die_h
    lassign [spadmic_ooc_pg_pin_centers] vdd_cx vss_cx
    set y_top [spadmic_ooc_snap_to_grid $die_h $pg_grid]
    set vdd_y0 [spadmic_ooc_snap_to_grid $core_margin $pg_grid]
    set vss_y0 [spadmic_ooc_snap_to_grid [expr {$core_margin + $ground_rail_offset}] $pg_grid]
    set set_distance [spadmic_ooc_snap_to_grid [expr {$die_w + 20.0}] $pg_grid]
    # addStripe -start_offset is measured from the core edge, not the die edge.
    # Subtracting core_margin prevents the exact 10.08um pin/stripe displacement
    # observed in P02 R1. explicit_exact avoids that ambiguity entirely.
    set vdd_offset [spadmic_ooc_snap_to_grid [expr {$vdd_cx - $core_margin - $strap_width / 2.0}] $pg_grid]
    set vss_offset [spadmic_ooc_snap_to_grid [expr {$vss_cx - $core_margin - $strap_width / 2.0}] $pg_grid]
    set all_ok 1

    foreach item [list \
        [list CREATE_PG_STRAP_VDD $power_net $vdd_cx $vdd_y0 $vdd_offset] \
        [list CREATE_PG_STRAP_VSS $ground_net $vss_cx $vss_y0 $vss_offset]] {
        lassign $item label net center_x y0 offset
        if {$strategy eq "explicit_exact"} {
            set commands [list \
                [list add_shape -net $net -layer $layer -shape STRIPE -status ROUTED \
                    -pathSeg [list $center_x $y0 $center_x $y_top] -width $strap_width]]
        } else {
            set commands [list \
                [list addStripe -nets [list $net] -layer $layer -direction vertical \
                    -width $strap_width -spacing $strap_spacing -set_to_set_distance $set_distance \
                    -start_from left -start_offset $offset -number_of_sets 1] \
                [list addStripe -nets [list $net] -layer $layer -direction vertical \
                    -width $strap_width -spacing $strap_spacing -set_to_set_distance $set_distance \
                    -start_from left -start_offset $offset]]
        }
        set ok [spadmic_ooc_try_first $label $commands 0]
        if {!$ok} {
            set all_ok 0
        }
    }
    spadmic_ooc_status_set PG_ROUTE_STRATEGY [string toupper $strategy]
    spadmic_ooc_status_set PG_STRAP_VDD_CENTER_X_UM $vdd_cx
    spadmic_ooc_status_set PG_STRAP_VSS_CENTER_X_UM $vss_cx
    spadmic_ooc_status_set PG_STRAP_VDD_Y_RANGE_UM "$vdd_y0,$y_top"
    spadmic_ooc_status_set PG_STRAP_VSS_Y_RANGE_UM "$vss_y0,$y_top"
    spadmic_ooc_status_set CREATE_PG_STRAPS [expr {$all_ok ? "PASS" : "FAIL"}]
}

proc spadmic_ooc_route_pg {} {
    set power_net [spadmic_ooc_cfg pg_power_net]
    set ground_net [spadmic_ooc_cfg pg_ground_net]
    if {![spadmic_ooc_pg_sroute_enabled]} {
        spadmic_ooc_status_set CREATE_PG_STRAPS DEFERRED_TOP_LEVEL_HOOKUP
        spadmic_ooc_status_set CREATE_PG_STRAP_VDD SKIPPED_DEFERRED_TOP
        spadmic_ooc_status_set CREATE_PG_STRAP_VSS SKIPPED_DEFERRED_TOP
        spadmic_ooc_status_set SROUTE_PG DEFERRED_TOP_LEVEL_HOOKUP
        spadmic_ooc_status_set PG_LOCAL_ROUTE_MODE DEFERRED_TOP_LEVEL_HOOKUP
        spadmic_ooc_write_text [file join $::spadmic_ooc_reports_dir SROUTE_PG.rpt] [list \
            "LABEL=SROUTE_PG" \
            "STATUS=DEFERRED_TOP_LEVEL_HOOKUP" \
            "POWER_NET=$power_net" \
            "GROUND_NET=$ground_net" \
            "REASON=Local OOC hardening exports METTP VDD/VSS access pins only. Top-level assembly must hook these pins to the final PG network." \
            "OVERRIDE=Set SPADMIC_OOC_ENABLE_PG_SROUTE=1 to run experimental local PG special routing." \
        ]
        return
    }
    set strategy [string tolower [spadmic_ooc_cfg_default pg_route_strategy legacy_addstripe]]
    spadmic_ooc_status_set PG_LOCAL_ROUTE_MODE [string toupper $strategy]
    spadmic_ooc_create_pg_straps
    if {$strategy eq "explicit_exact"} {
        set cmds [list \
            [list sroute -connect {corePin} -nets [list $power_net $ground_net] \
                -corePinTarget {stripe} -corePinCheckStdcellGeoms -allowJogging 1 \
                -allowLayerChange 1 -layerChangeRange {MET1 METTP}] \
            [list sroute -connect {corePin} -nets [list $power_net $ground_net] \
                -corePinTarget {stripe} -allowJogging 1 -allowLayerChange 1 \
                -layerChangeRange {MET1 METTP}]]
    } else {
        set cmds [list \
            [list sroute -connect {corePin blockPin padPin} -nets [list $power_net $ground_net] -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -padPinTarget {ring stripe} -allowLayerChange 1] \
            [list sroute -connect {corePin blockPin} -nets [list $power_net $ground_net] -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -allowLayerChange 1] \
            [list sroute -connect {corePin} -nets [list $power_net $ground_net] -corePinTarget {ring stripe} -allowLayerChange 1] \
            [list sroute -nets [list $power_net $ground_net]]]
    }
    spadmic_ooc_try_first SROUTE_PG $cmds 1
}

proc spadmic_ooc_place_side_pins {side pins} {
    if {[llength $pins] == 0} {
        return
    }
    set layer [spadmic_ooc_cfg signal_top_layer]
    set spacing [spadmic_ooc_cfg signal_pin_spacing_um]
    set width [spadmic_ooc_cfg signal_pin_width_um]
    set depth [spadmic_ooc_cfg signal_pin_depth_um]
    set side_lc [string tolower $side]
    set label "PLACE_PINS_$side"
    set cmds [list \
        [list editPin -pin $pins -side $side -layer $layer -spreadType SIDE -spacing $spacing -pinWidth $width -pinDepth $depth -fixedPin 1] \
        [list editPin -pin $pins -side $side_lc -layer $layer -spreadType SIDE -spacing $spacing -pinWidth $width -pinDepth $depth -fixedPin 1] \
        [list editPin -pin $pins -side $side -layer $layer -spreadType SIDE -spacing $spacing] \
        [list editPin -pin $pins -side $side_lc -layer $layer -spreadType SIDE -spacing $spacing]]
    spadmic_ooc_try_first $label $cmds 1
}

proc spadmic_ooc_place_pins {} {
    spadmic_ooc_place_side_pins WEST [spadmic_ooc_cfg_list pins_west]
    spadmic_ooc_place_side_pins SOUTH [spadmic_ooc_cfg_list pins_south]
    spadmic_ooc_place_side_pins NORTH [spadmic_ooc_cfg_list pins_north]
    set pin_assignment_tcl [spadmic_ooc_cfg_default pin_assignment_tcl ""]
    if {$pin_assignment_tcl ne "" && [file exists $pin_assignment_tcl]} {
        spadmic_ooc_try_first PLACE_PINS_GUIDED [list [list source $pin_assignment_tcl]] 1
    }
}

proc spadmic_ooc_route_layer_setup {} {
    set profile [spadmic_ooc_route_profile]
    set bottom_default [spadmic_ooc_cfg signal_bottom_layer]
    set bottom_idx_default [spadmic_ooc_cfg signal_bottom_layer_idx]
    if {[spadmic_ooc_route_profile_met2_first]} {
        set bottom_default MET2
        set bottom_idx_default 2
    }
    set bottom [string toupper [spadmic_ooc_env SPADMIC_OOC_SIGNAL_BOTTOM_LAYER $bottom_default]]
    set top [string toupper [spadmic_ooc_env SPADMIC_OOC_SIGNAL_TOP_LAYER [spadmic_ooc_cfg signal_top_layer]]]
    set bottom_idx [spadmic_ooc_layer_index [spadmic_ooc_env SPADMIC_OOC_SIGNAL_BOTTOM_LAYER_IDX $bottom_idx_default] [spadmic_ooc_layer_index $bottom 1]]
    set top_idx [spadmic_ooc_layer_index [spadmic_ooc_env SPADMIC_OOC_SIGNAL_TOP_LAYER_IDX [spadmic_ooc_cfg signal_top_layer_idx]] [spadmic_ooc_layer_index $top 3]]
    set effort_enabled [spadmic_ooc_route_profile_effort_enabled]
    set antenna_repair [spadmic_ooc_antenna_repair_enabled]

    set rpt [file join $::spadmic_ooc_reports_dir ROUTE_LAYER_SETUP.rpt]
    set fh [open $rpt w]
    puts $fh "LABEL=ROUTE_LAYER_SETUP"
    puts $fh "ROUTE_PROFILE=$profile"
    puts $fh "SIGNAL_BOTTOM_LAYER=$bottom"
    puts $fh "SIGNAL_TOP_LAYER=$top"
    puts $fh "SIGNAL_BOTTOM_LAYER_IDX=$bottom_idx"
    puts $fh "SIGNAL_TOP_LAYER_IDX=$top_idx"
    puts $fh "ROUTE_EFFORT_ENABLED=[expr {$effort_enabled ? 1 : 0}]"
    puts $fh "ANTENNA_REPAIR_ENABLED=[expr {$antenna_repair ? 1 : 0}]"

    set commands [list \
        [list setDesignMode -bottomRoutingLayer $bottom -topRoutingLayer $top] \
        [list setNanoRouteMode -routeBottomRoutingLayer $bottom_idx] \
        [list setNanoRouteMode -routeTopRoutingLayer $top_idx]]
    if {$effort_enabled} {
        foreach cmd [list \
            [list setNanoRouteMode -routeWithTimingDriven true] \
            [list setNanoRouteMode -routeWithSiDriven true] \
            [list setNanoRouteMode -drouteUseMultiCutViaEffort high]] {
            lappend commands $cmd
        }
    }
    if {$antenna_repair} {
        lappend commands [list setNanoRouteMode -drouteFixAntenna true]
    }

    set required_failures [list]
    set optional_failures [list]
    set cmd_idx 0
    foreach cmd $commands {
        incr cmd_idx
        puts $fh "TRY=$cmd"
        if {[catch {uplevel #0 $cmd} err]} {
            puts $fh "TRY_STATUS=FAIL"
            puts $fh "ERROR=[spadmic_ooc_report_value $err]"
            if {$cmd_idx <= 3} {
                lappend required_failures "$cmd:$err"
            } else {
                lappend optional_failures "$cmd:$err"
            }
        } else {
            puts $fh "TRY_STATUS=PASS"
            puts $fh "COMMAND=$cmd"
        }
    }
    set status [expr {[llength $required_failures] == 0 ? "PASS" : "FAIL"}]
    puts $fh "STATUS=$status"
    puts $fh "REQUIRED_FAILURES=[join $required_failures {; }]"
    puts $fh "OPTIONAL_FAILURES=[join $optional_failures {; }]"
    close $fh

    spadmic_ooc_status_set ROUTE_LAYER_SETUP $status
    spadmic_ooc_status_set ROUTE_PROFILE $profile
    spadmic_ooc_status_set SIGNAL_ROUTE_LAYERS "${bottom}-${top}"
    spadmic_ooc_status_set SIGNAL_ROUTE_LAYER_INDEXES "${bottom_idx}-${top_idx}"
    spadmic_ooc_status_set ROUTE_EFFORT_ENABLED [expr {$effort_enabled ? 1 : 0}]
    spadmic_ooc_status_set ANTENNA_REPAIR_ENABLED [expr {$antenna_repair ? 1 : 0}]
}

proc spadmic_ooc_place_design {} {
    set density [spadmic_ooc_place_max_density]
    spadmic_ooc_status_set PLACE_MAX_DENSITY $density
    spadmic_ooc_configure_scan_placement
    catch {setPlaceMode -place_global_max_density $density}
    spadmic_ooc_try_first PLACE_DESIGN [list {place_design} {placeDesign}] 1
    spadmic_ooc_capture_first [file join $::spadmic_ooc_reports_dir report_area_post_place.rpt] report_area_post_place [list {report_area} {reportArea}] 0
    catch {defOut [file join $::spadmic_ooc_outputs_dir 02_place.def]}
    catch {saveDesign [file join $::spadmic_ooc_checkpoints_dir 02_place.enc]}
}

proc spadmic_ooc_cts_design {} {
    if {[spadmic_ooc_truthy [spadmic_ooc_cfg_default allow_cts_skip 0]]} {
        spadmic_ooc_status_set CTS_DESIGN PASS
        spadmic_ooc_status_set CTS_STATUS SKIPPED_BY_BLOCK_CONFIG
        spadmic_ooc_write_text [file join $::spadmic_ooc_reports_dir CTS_DESIGN.rpt] [list \
            "LABEL=CTS_DESIGN" \
            "STATUS=PASS" \
            "CTS_STATUS=SKIPPED_BY_BLOCK_CONFIG" \
            "REASON=Block has no local sequential clock tree to synthesize; timing is still reported after route." \
            "COMMAND=not_run"]
        catch {timeDesign -postCTS -outDir [file join $::spadmic_ooc_reports_dir timing_post_cts]}
        catch {saveDesign [file join $::spadmic_ooc_checkpoints_dir 03_cts.enc]}
        return
    }
    global mptdc_xh018_cells
    if {[info exists mptdc_xh018_cells(cts_buffers)]} {
        catch {set_ccopt_property buffer_cells $mptdc_xh018_cells(cts_buffers)}
    }
    if {[info exists mptdc_xh018_cells(cts_inverters)]} {
        catch {set_ccopt_property inverter_cells $mptdc_xh018_cells(cts_inverters)}
    }
    spadmic_ooc_try_first CTS_DESIGN [list {ccopt_design} {clockDesign}] 1
    catch {timeDesign -postCTS -outDir [file join $::spadmic_ooc_reports_dir timing_post_cts]}
    catch {saveDesign [file join $::spadmic_ooc_checkpoints_dir 03_cts.enc]}
}

proc spadmic_ooc_route_design {} {
    spadmic_ooc_route_layer_setup
    spadmic_ooc_try_first ROUTE_DESIGN [list {routeDesign} {globalDetailRoute}] 1
    catch {defOut [file join $::spadmic_ooc_outputs_dir 04_route.def]}
    catch {saveDesign [file join $::spadmic_ooc_checkpoints_dir 04_route.enc]}
}

proc spadmic_ooc_configure_filler_mode {} {
    set rpt [file join $::spadmic_ooc_reports_dir FILLER_MODE.rpt]
    set allow_drc [spadmic_ooc_truthy [spadmic_ooc_env SPADMIC_OOC_FILLER_ADD_FILLERS_WITH_DRC 0]]
    set require_safe [spadmic_ooc_truthy [spadmic_ooc_env SPADMIC_OOC_REQUIRE_DRC_SAFE_FILLER 1]]
    set value [expr {$allow_drc ? "true" : "false"}]
    set commands [list \
        [list setFillerMode -add_fillers_with_drc $value] \
        [list setFillerMode -add_fillers_with_drc [expr {$allow_drc ? 1 : 0}]] \
        [list setFillerMode -addFillersWithDrc $value] \
        [list setFillerMode -addFillersWithDrc [expr {$allow_drc ? 1 : 0}]]]
    set fh [open $rpt w]
    puts $fh "LABEL=FILLER_MODE"
    puts $fh "SPADMIC_OOC_FILLER_ADD_FILLERS_WITH_DRC=[expr {$allow_drc ? 1 : 0}]"
    puts $fh "SPADMIC_OOC_REQUIRE_DRC_SAFE_FILLER=[expr {$require_safe ? 1 : 0}]"
    puts $fh "REQUESTED_ADD_FILLERS_WITH_DRC=$value"
    foreach cmd $commands {
        puts $fh "TRY=$cmd"
        if {![catch {uplevel #0 $cmd} err]} {
            puts $fh "STATUS=PASS"
            puts $fh "COMMAND=$cmd"
            close $fh
            spadmic_ooc_status_set FILLER_MODE PASS
            spadmic_ooc_status_set FILLER_ADD_FILLERS_WITH_DRC [expr {$allow_drc ? "ALLOW" : "DISABLE"}]
            return 1
        }
        puts $fh "ERROR=$err"
    }
    if {$allow_drc || !$require_safe} {
        puts $fh "STATUS=REVIEW_REQUIRED"
        puts $fh "REASON=setFillerMode_variant_not_accepted"
        close $fh
        spadmic_ooc_status_set FILLER_MODE REVIEW_REQUIRED
        return 1
    }
    puts $fh "STATUS=FAIL"
    puts $fh "REASON=drc_safe_filler_mode_not_applied"
    close $fh
    spadmic_ooc_status_set FILLER_MODE FAIL
    return 0
}

proc spadmic_ooc_add_fillers {} {
    global mptdc_xh018_cells
    if {![info exists mptdc_xh018_cells(filler)] || [llength $mptdc_xh018_cells(filler)] == 0} {
        error "SPADMIC_OOC_NO_FILLER_CELLS"
    }
    if {![spadmic_ooc_configure_filler_mode]} {
        error "SPADMIC_OOC_FILLER_MODE_GATE_FAILED"
    }
    set fillers $mptdc_xh018_cells(filler)
    spadmic_ooc_try_first ADD_FILLER [list \
        [list addFiller -cell $fillers -prefix FILL] \
        [list addFiller -cell $fillers]] 1
}

proc spadmic_ooc_postroute_cleanup {} {
    set commands [list {ecoRoute -target} {ecoRoute -fix_drc} {ecoRoute}]
    spadmic_ooc_try_all POSTROUTE_DRC_CLEANUP $commands 0
}

proc spadmic_ooc_postroute_opt_and_timing {} {
    catch {setDelayCalMode -SIAware false}
    catch {setSIMode -separate_delta_delay_on_data false}
    spadmic_ooc_try_first POSTROUTE_OPT_DRV [list {optDesign -postRoute -drv} {optDesign -postRoute}] 0
    catch {setExtractRCMode -engine postRoute}
    catch {extractRC}
    set setup_dir [file join $::spadmic_ooc_reports_dir timing_post_route_setup]
    set hold_dir [file join $::spadmic_ooc_reports_dir timing_post_route_hold]
    catch {file mkdir $setup_dir $hold_dir}
    spadmic_ooc_try_first POSTROUTE_SETUP_TIMING [list \
        [list timeDesign -postRoute -outDir $setup_dir] \
        [list timeDesign -postRoute]] 1
    spadmic_ooc_try_first POSTROUTE_HOLD_TIMING [list \
        [list timeDesign -postRoute -hold -outDir $hold_dir] \
        [list timeDesign -postRoute -hold]] 1
    spadmic_ooc_capture_first [file join $::spadmic_ooc_reports_dir report_timing_post_route.rpt] report_timing_post_route [list {report_timing -max_paths 50} {report_timing}] 0
    spadmic_ooc_capture_first [file join $::spadmic_ooc_reports_dir report_clocks_post_route.rpt] report_clocks_post_route [list {report_clocks} {reportClockTree}] 0
    spadmic_ooc_capture_first [file join $::spadmic_ooc_reports_dir report_drv_post_route.rpt] report_drv_post_route [list {report_constraint -all_violators} {report_constraints -all_violators}] 0
}

proc spadmic_ooc_postroute_antenna_repair {} {
    set rpt [file join $::spadmic_ooc_reports_dir POSTROUTE_ANTENNA_REPAIR.rpt]
    if {![spadmic_ooc_antenna_repair_enabled]} {
        spadmic_ooc_write_text $rpt [list \
            "LABEL=POSTROUTE_ANTENNA_REPAIR" \
            "STATUS=DISABLED" \
            "OVERRIDE=Set SPADMIC_OOC_ENABLE_ANTENNA_REPAIR=1 or use SPADMIC_OOC_ROUTE_PROFILE=met2_first_antenna." \
        ]
        spadmic_ooc_status_set POSTROUTE_ANTENNA_REPAIR DISABLED
        return 0
    }

    set pre_markers [file join $::spadmic_ooc_reports_dir postroute_antenna_repair_pre_markers.tsv]
    set post_markers [file join $::spadmic_ooc_reports_dir postroute_antenna_repair_post_markers.tsv]
    spadmic_ooc_write_marker_dump $pre_markers
    array set pre_cls [spadmic_ooc_marker_classification]

    set fh [open $rpt w]
    puts $fh "LABEL=POSTROUTE_ANTENNA_REPAIR"
    puts $fh "PRE_MARKER_REPORT=$pre_markers"
    puts $fh "PRE_ANTENNA_MARKER_COUNT=$pre_cls(antenna)"
    puts $fh "PRE_ANTENNA_NETS=[join $pre_cls(antenna_nets) { }]"
    if {$pre_cls(antenna) == 0} {
        puts $fh "STATUS=SKIPPED_NO_ANTENNA_MARKERS"
        close $fh
        spadmic_ooc_status_set POSTROUTE_ANTENNA_REPAIR SKIPPED_NO_MARKERS
        return 0
    }

    set commands [list \
        [list setNanoRouteMode -drouteFixAntenna true] \
        [list ecoRoute -fix_antenna] \
        [list ecoRoute -fix_drc] \
        [list globalDetailRoute] \
        [list detailRoute] \
        [list ecoRoute]]
    set pass_count 0
    set fail_count 0
    set failures [list]
    foreach cmd $commands {
        puts $fh "TRY=$cmd"
        if {[catch {uplevel #0 $cmd} err]} {
            incr fail_count
            puts $fh "TRY_STATUS=FAIL"
            puts $fh "ERROR=[spadmic_ooc_report_value $err]"
            lappend failures "$cmd:$err"
        } else {
            incr pass_count
            puts $fh "TRY_STATUS=PASS"
            puts $fh "COMMAND=$cmd"
        }
    }
    spadmic_ooc_write_marker_dump $post_markers
    array set post_cls [spadmic_ooc_marker_classification]
    set status [expr {$post_cls(antenna) == 0 ? "PASS" : "REVIEW_REQUIRED"}]
    puts $fh "PASS_COUNT=$pass_count"
    puts $fh "FAIL_COUNT=$fail_count"
    puts $fh "FAILURES=[join $failures {; }]"
    puts $fh "POST_MARKER_REPORT=$post_markers"
    puts $fh "POST_ANTENNA_MARKER_COUNT=$post_cls(antenna)"
    puts $fh "POST_ANTENNA_NETS=[join $post_cls(antenna_nets) { }]"
    puts $fh "STATUS=$status"
    close $fh
    spadmic_ooc_status_set POSTROUTE_ANTENNA_REPAIR $status
    return 1
}

proc spadmic_ooc_post_min_area_repair_timing {} {
    catch {setExtractRCMode -engine postRoute}
    catch {extractRC}
    set setup_dir [file join $::spadmic_ooc_reports_dir timing_post_route_setup_after_min_area_repair]
    set hold_dir [file join $::spadmic_ooc_reports_dir timing_post_route_hold_after_min_area_repair]
    catch {file mkdir $setup_dir $hold_dir}
    spadmic_ooc_try_first POSTROUTE_MIN_AREA_REPAIR_SETUP_TIMING [list \
        [list timeDesign -postRoute -outDir $setup_dir] \
        [list timeDesign -postRoute]] 0
    spadmic_ooc_try_first POSTROUTE_MIN_AREA_REPAIR_HOLD_TIMING [list \
        [list timeDesign -postRoute -hold -outDir $hold_dir] \
        [list timeDesign -postRoute -hold]] 0
}

proc spadmic_ooc_verify_reports {} {
    set drc_rpt [file join $::spadmic_ooc_reports_dir verify_drc_post_route.rpt]
    set drc_marker_tsv [file join $::spadmic_ooc_reports_dir verify_drc_post_route_markers.tsv]
    set reg_conn_rpt [file join $::spadmic_ooc_reports_dir verify_connectivity_regular.rpt]
    set pg_conn_rpt [file join $::spadmic_ooc_reports_dir verify_connectivity_pg.rpt]
    set route_rpt [file join $::spadmic_ooc_reports_dir report_route.rpt]
    set marker_class_rpt [file join $::spadmic_ooc_reports_dir DRC_MARKER_CLASSIFICATION.rpt]
    spadmic_ooc_capture_first $drc_rpt verify_drc_post_route [list {verify_drc} {verifyGeometry}] 1
    set marker_count [spadmic_ooc_write_marker_dump $drc_marker_tsv]
    set marker_class_status [spadmic_ooc_write_marker_classification $marker_class_rpt]
    spadmic_ooc_write_text [file join $::spadmic_ooc_reports_dir DRC_MARKER_DUMP.rpt] [list \
        "LABEL=DRC_MARKER_DUMP" \
        "STATUS=PASS" \
        "MARKER_REPORT=$drc_marker_tsv" \
        "MARKER_COUNT=$marker_count" \
        "CLASSIFICATION_REPORT=$marker_class_rpt" \
        "CLASSIFICATION_STATUS=$marker_class_status" \
    ]
    spadmic_ooc_status_set DRC_MARKER_DUMP PASS
    spadmic_ooc_capture_first $reg_conn_rpt verify_connectivity_regular [list {verifyConnectivity -type regular} {verifyConnectivity}] 1
    if {[spadmic_ooc_pg_sroute_enabled]} {
        spadmic_ooc_capture_first $pg_conn_rpt verify_connectivity_pg [list {verifyConnectivity -type special -nets {VDD VSS}} {verifyConnectivity -nets {VDD VSS} -type special} {verifyConnectivity -type special}] 1
    } else {
        spadmic_ooc_write_text $pg_conn_rpt [list \
            "LABEL=verify_connectivity_pg" \
            "STATUS=DEFERRED_TOP_LEVEL_HOOKUP" \
            "REASON=No local special PG route was created. The exported abstract provides METTP VDD/VSS access pins for top-level hookup." \
            "COMMAND=not_run" \
        ]
    }
    spadmic_ooc_capture_first $route_rpt report_route [list {reportRoute} {report_route}] 0
    set drc_status [spadmic_ooc_parse_drc_report $drc_rpt]
    set reg_status [spadmic_ooc_regular_connectivity_status $reg_conn_rpt]
    if {[spadmic_ooc_pg_sroute_enabled]} {
        set pg_status [spadmic_ooc_connectivity_status $pg_conn_rpt]
    } else {
        set pg_status DEFERRED_TOP_LEVEL_HOOKUP
    }
    spadmic_ooc_status_set INNOVUS_DRC_STATUS $drc_status
    spadmic_ooc_status_set REGULAR_CONNECTIVITY_STATUS $reg_status
    spadmic_ooc_status_set PG_CONNECTIVITY_STATUS $pg_status
}

proc spadmic_ooc_export_outputs {} {
    set block $::spadmic_ooc_block
    set def [file join $::spadmic_ooc_outputs_dir "${block}.def"]
    set lef [file join $::spadmic_ooc_outputs_dir "${block}.lef"]
    set abstract_lef [file join $::spadmic_ooc_outputs_dir "${block}.abstract.lef"]
    set gds [file join $::spadmic_ooc_outputs_dir "${block}.gds"]
    set routed_v [file join $::spadmic_ooc_outputs_dir "${block}.routed.v"]
    set routed_pg_v [file join $::spadmic_ooc_outputs_dir "${block}.routed.pg.v"]
    spadmic_ooc_try_first EXPORT_DEF [list [list defOut $def]] 1
    spadmic_ooc_try_first EXPORT_NETLIST [list [list saveNetlist $routed_v]] 1
    spadmic_ooc_try_first EXPORT_NETLIST_PG [list [list saveNetlist -includePowerGround $routed_pg_v]] 0
    spadmic_ooc_try_first EXPORT_LEF [list \
        [list write_lef_abstract $lef] \
        [list lefOut $lef] \
        [list write_lef $lef]] 1
    if {[file exists $lef]} {
        file copy -force $lef $abstract_lef
    }
    set stream_cmd [list streamOut $gds -libName DesignLib -units 1000 -mode ALL]
    set stream_map [spadmic_ooc_env SPADMIC_STREAMOUT_MAP_FILE ""]
    if {$stream_map ne ""} {
        lappend stream_cmd -mapFile $stream_map
    }
    set stdcell_gds [spadmic_ooc_env SPADMIC_STDCELL_GDS ""]
    if {$stdcell_gds ne ""} {
        lappend stream_cmd -merge $stdcell_gds
    }
    spadmic_ooc_try_first EXPORT_GDS [list $stream_cmd] 1
    foreach pair [list \
        [list EXPORT_DEF_FILE $def] \
        [list EXPORT_LEF_FILE $lef] \
        [list EXPORT_ABSTRACT_LEF_FILE $abstract_lef] \
        [list EXPORT_GDS_FILE $gds] \
        [list EXPORT_NETLIST_FILE $routed_v]] {
        spadmic_ooc_require_file [lindex $pair 0] [lindex $pair 1]
    }
    catch {saveDesign [file join $::spadmic_ooc_checkpoints_dir 05_postroute_export.enc]}
}

proc spadmic_ooc_copy_handoff {} {
    set block $::spadmic_ooc_block
    set hnet [file join $::spadmic_ooc_handoff_root netlist]
    set hinv [file join $::spadmic_ooc_handoff_root innovus]
    set hrpt [file join $::spadmic_ooc_handoff_root reports]
    file mkdir $hnet $hinv $hrpt
    foreach src [list $::spadmic_ooc_netlist $::spadmic_ooc_sdc] {
        file copy -force $src [file join $hnet [file tail $src]]
    }
    foreach tail [list "${block}.def" "${block}.lef" "${block}.abstract.lef" "${block}.gds" "${block}.routed.v" "${block}.routed.pg.v"] {
        set src [file join $::spadmic_ooc_outputs_dir $tail]
        if {[file exists $src]} {
            file copy -force $src [file join $hinv $tail]
        }
    }
    foreach rpt [glob -nocomplain -directory $::spadmic_ooc_reports_dir *] {
        if {[file isfile $rpt]} {
            file copy -force $rpt [file join $hrpt [file tail $rpt]]
        }
    }
    set readme [file join $::spadmic_ooc_handoff_root README.md]
    if {[spadmic_ooc_pg_sroute_enabled]} {
        set pg_route_note "- PG special-route stitching: experimental local `sroute` enabled for this run; review `verify_connectivity_pg.rpt` before top use."
    } else {
        set pg_route_note "- PG special-route stitching: deferred to top-level hookup; this package exports only `METTP` access pins for `VDD`/`VSS`."
    }
    set route_profile [spadmic_ooc_route_profile]
    set route_layers "MET1-MET3"
    if {[info exists ::spadmic_ooc_status(SIGNAL_ROUTE_LAYERS)]} {
        set route_layers $::spadmic_ooc_status(SIGNAL_ROUTE_LAYERS)
    }
    spadmic_ooc_write_text $readme [list \
        "# SPADMIC OOC Abstract Handoff: $block" \
        "" \
        "- Block: `$block`" \
        "- Top module: `$::spadmic_ooc_top_module`" \
        "- Innovus root: `$::spadmic_ooc_block_root`" \
        "- Genus netlist: `$::spadmic_ooc_netlist`" \
        "- Genus SDC: `$::spadmic_ooc_sdc`" \
        "- OOC route profile: `$route_profile`" \
        "- Ordinary signal routing: `$route_layers`" \
        "- Power pins: one `VDD` and one `VSS` north-edge bar on `METTP`" \
        $pg_route_note \
        "- PVS/LVS/PEX/MMMC: deferred; this package is not `SIGNOFF_READY`." \
    ]
    spadmic_ooc_status_set HANDOFF_COPY PASS
}

proc spadmic_ooc_write_status {} {
    set path [file join $::spadmic_ooc_reports_dir ooc_harden_status.rpt]
    set result ABSTRACT_READY_FOR_TOP_REVIEW
    set required_statuses [list \
        LIBRARY_SOURCE INIT_DESIGN FLOORPLAN CREATE_PG_PIN_VDD CREATE_PG_PIN_VSS FILLER_MODE \
        PLACE_PINS_WEST PLACE_PINS_SOUTH PLACE_PINS_NORTH ROUTE_LAYER_SETUP PLACE_DESIGN CTS_DESIGN ROUTE_DESIGN \
        ADD_FILLER POSTROUTE_SETUP_TIMING POSTROUTE_HOLD_TIMING EXPORT_DEF EXPORT_LEF EXPORT_GDS \
        EXPORT_DEF_FILE EXPORT_LEF_FILE EXPORT_ABSTRACT_LEF_FILE EXPORT_GDS_FILE EXPORT_NETLIST_FILE HANDOFF_COPY]
    if {[spadmic_ooc_pg_sroute_enabled]} {
        lappend required_statuses SROUTE_PG
    }
    foreach required $required_statuses {
        if {![info exists ::spadmic_ooc_status($required)] || $::spadmic_ooc_status($required) ne "PASS"} {
            set result INNOVUS_TC_OOC_REVIEW_REQUIRED
        }
    }
    foreach review_key [list INNOVUS_DRC_STATUS REGULAR_CONNECTIVITY_STATUS DRC_MARKER_CLASSIFICATION] {
        if {![info exists ::spadmic_ooc_status($review_key)] || $::spadmic_ooc_status($review_key) ne "PASS"} {
            set result INNOVUS_TC_OOC_REVIEW_REQUIRED
        }
    }
    set pg_ok 0
    if {[info exists ::spadmic_ooc_status(PG_CONNECTIVITY_STATUS)]} {
        if {$::spadmic_ooc_status(PG_CONNECTIVITY_STATUS) eq "PASS"} {
            set pg_ok 1
        } elseif {![spadmic_ooc_pg_sroute_enabled] && $::spadmic_ooc_status(PG_CONNECTIVITY_STATUS) eq "DEFERRED_TOP_LEVEL_HOOKUP"} {
            set pg_ok 1
        }
    }
    if {!$pg_ok} {
        set result INNOVUS_TC_OOC_REVIEW_REQUIRED
    }
    set ::spadmic_ooc_status(RESULT) $result
    set ::spadmic_ooc_status(SIGNOFF_READY) NO
    set ::spadmic_ooc_status(PVS_STATUS) DEFERRED
    set ::spadmic_ooc_status(PEX_STATUS) DEFERRED
    set ::spadmic_ooc_status(MMMC_STATUS) DEFERRED_TYPICAL_ONLY
    set ::spadmic_ooc_status(OA_IMPORT_STATUS) DEFERRED_USE_DEF_LEF_GDS_PACKAGE
    set fh [open $path w]
    foreach key [lsort [array names ::spadmic_ooc_status]] {
        puts $fh "$key=$::spadmic_ooc_status($key)"
    }
    puts $fh "BLOCK=$::spadmic_ooc_block"
    puts $fh "TOP_MODULE=$::spadmic_ooc_top_module"
    puts $fh "NETLIST=$::spadmic_ooc_netlist"
    puts $fh "SDC=$::spadmic_ooc_sdc"
    puts $fh "BLOCK_ROOT=$::spadmic_ooc_block_root"
    puts $fh "HANDOFF_ROOT=$::spadmic_ooc_handoff_root"
    puts $fh "LAYOUT_AUDIT_DIR=[spadmic_ooc_cfg layout_audit_dir]"
    puts $fh "PIN_PLAN_CSV=[spadmic_ooc_cfg pin_plan_csv]"
    close $fh
}

proc spadmic_ooc_main {} {
    spadmic_ooc_require_file GENUS_NETLIST_INPUT $::spadmic_ooc_netlist
    spadmic_ooc_require_file GENUS_SDC_INPUT $::spadmic_ooc_sdc
    spadmic_ooc_source_libraries
    spadmic_ooc_init_design
    spadmic_ooc_floorplan
    spadmic_ooc_place_pins
    spadmic_ooc_route_layer_setup
    spadmic_ooc_create_pg_pins
    spadmic_ooc_place_design
    spadmic_ooc_cts_design
    spadmic_ooc_add_fillers
    spadmic_ooc_route_pg
    spadmic_ooc_route_design
    spadmic_ooc_postroute_cleanup
    spadmic_ooc_postroute_opt_and_timing
    set min_area_repair_changed [spadmic_ooc_selected_net_min_area_repair]
    set antenna_repair_changed [spadmic_ooc_postroute_antenna_repair]
    if {$min_area_repair_changed || $antenna_repair_changed} {
        spadmic_ooc_post_min_area_repair_timing
    }
    spadmic_ooc_verify_reports
    spadmic_ooc_export_outputs
    spadmic_ooc_copy_handoff
    spadmic_ooc_write_status
}

if {[catch {spadmic_ooc_main} err opts]} {
    spadmic_ooc_status_set RESULT FAIL
    spadmic_ooc_status_set FIRST_ERROR $err
    set error_rpt [file join $::spadmic_ooc_reports_dir ooc_harden_error.rpt]
    set fh [open $error_rpt w]
    puts $fh "ERROR=$err"
    puts $fh "OPTIONS=$opts"
    close $fh
    spadmic_ooc_write_status
    error $err
}

exit
