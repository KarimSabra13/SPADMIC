# Replay the validated six base edits, record exactly four temporary Innovus
# MET1 minimum-area waivers, and export a provisional PVS DRC/LVS package.

proc mw_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_MIN_AREA_WAIVER_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc mw_value {value} {
    if {$value eq ""} { return NONE }
    return [string map [list "\n" " " "\r" " " "\t" " "] $value]
}

proc mw_read_kv {path} {
    array set values {}
    set fh [open $path r]
    while {[gets $fh line] >= 0} {
        set at [string first = $line]
        if {$at <= 0} { continue }
        set key [string range $line 0 [expr {$at - 1}]]
        set values($key) [string range $line [expr {$at + 1}] end]
    }
    close $fh
    return [array get values]
}

proc mw_flat_values {raw} {
    set values [list]
    foreach item $raw {
        if {[llength $item] > 1} {
            foreach nested [mw_flat_values $item] { lappend values $nested }
        } else {
            lappend values $item
        }
    }
    return $values
}

proc mw_flat_box {raw} {
    set values [mw_flat_values $raw]
    if {[llength $values] < 4} {
        return [list UNKNOWN UNKNOWN UNKNOWN UNKNOWN]
    }
    return [lrange $values 0 3]
}

proc mw_close {actual expected {tolerance 0.001}} {
    if {![string is double -strict $actual] ||
        ![string is double -strict $expected]} {
        return 0
    }
    return [expr {abs($actual - $expected) <= $tolerance}]
}

proc mw_box_matches {actual expected} {
    if {[llength $actual] != 4 || [llength $expected] != 4} { return 0 }
    foreach lhs $actual rhs $expected {
        if {![mw_close $lhs $rhs]} { return 0 }
    }
    return 1
}

proc mw_point_matches {raw expected_x expected_y} {
    set values [mw_flat_values $raw]
    if {[llength $values] < 2} { return 0 }
    return [expr {
        [mw_close [lindex $values 0] $expected_x] &&
        [mw_close [lindex $values 1] $expected_y]
    }]
}

proc mw_has_endpoint {raw expected_x expected_y} {
    set values [mw_flat_values $raw]
    for {set index 0} {$index + 1 < [llength $values]} {incr index 2} {
        if {[mw_close [lindex $values $index] $expected_x] &&
            [mw_close [lindex $values [expr {$index + 1}]] $expected_y]} {
            return 1
        }
    }
    return 0
}

proc mw_point_in_box {x y box} {
    if {[llength $box] != 4} { return 0 }
    lassign $box llx lly urx ury
    foreach value $box {
        if {![string is double -strict $value]} { return 0 }
    }
    return [expr {
        $x >= $llx - 0.001 && $x <= $urx + 0.001 &&
        $y >= $lly - 0.001 && $y <= $ury + 0.001
    }]
}

proc mw_valid_handles {raw} {
    set handles [list]
    foreach handle $raw {
        if {$handle eq "" || $handle eq "0x0" || $handle eq "NULL"} { continue }
        if {[lsearch -exact $handles $handle] < 0} { lappend handles $handle }
    }
    return $handles
}

proc mw_is_antenna {type subtype message} {
    return [expr {
        [string equal -nocase $type "Antenna"] ||
        [regexp -nocase {Antenna|Ant.*Area|ProcessAntenna} $subtype] ||
        [regexp -nocase {Antenna|S[.]PAR|Antenna[[:space:]]+Side[[:space:]]+Area} $message]
    }]
}

proc mw_is_min_area {layer type subtype message} {
    return [expr {
        [string equal -nocase $layer "MET1"] &&
        [string equal -nocase $type "Geometry"] &&
        ([regexp -nocase {Minimal_Area|Minimum[[:space:]]+Area|Mar} $subtype] ||
         [regexp -nocase {Minimum[[:space:]]+Area|Minimal_Area} $message])
    }]
}

proc mw_capture {path body} {
    if {[catch {redirect -file $path $body} err]} {
        set fh [open $path w]
        puts $fh "CAPTURE_STATUS=FAIL"
        puts $fh "ERROR=[mw_value $err]"
        close $fh
        return 0
    }
    return 1
}

proc mw_violation_count {path} {
    if {![file exists $path]} { return UNKNOWN }
    set fh [open $path r]
    set report [read $fh]
    close $fh
    set counts [list]
    if {[regexp -nocase {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viol} $report -> count]} {
        lappend counts $count
    }
    if {[regexp -nocase {([0-9]+)[[:space:]]+Problem\(s\)[[:space:]]+\(IMPVFC-200\):[[:space:]]+Special Wires:} $report -> count]} {
        lappend counts $count
    }
    if {[llength $counts] == 0} { return UNKNOWN }
    set unique [lsort -unique $counts]
    if {[llength $unique] != 1} { return CONFLICT }
    return [lindex $unique 0]
}

proc mw_write_marker_dump {path} {
    set markers [list]
    catch {set markers [dbGet top.markers]}
    set fh [open $path w]
    puts $fh "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\tlayer\ttype\tsubType\tmessage"
    set idx 0
    set raw_count 0
    set antenna_count 0
    set connectivity_count 0
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} { continue }
        incr raw_count
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
        if {[mw_is_antenna $type $subtype $message]} {
            incr antenna_count
            continue
        }
        if {[string equal -nocase $type "Connectivity"]} {
            incr connectivity_count
            continue
        }
        incr idx
        lassign [mw_flat_box $box] llx lly urx ury
        set cx UNKNOWN
        set cy UNKNOWN
        if {[string is double -strict $llx] && [string is double -strict $urx]} {
            set cx [format %.6f [expr {($llx + $urx) / 2.0}]]
        }
        if {[string is double -strict $lly] && [string is double -strict $ury]} {
            set cy [format %.6f [expr {($lly + $ury) / 2.0}]]
        }
        puts $fh "$idx\t[mw_value $marker]\t[mw_value $box]\t$llx\t$lly\t$urx\t$ury\t$cx\t$cy\t[mw_value $layer]\t[mw_value $type]\t[mw_value $subtype]\t[mw_value $message]"
    }
    close $fh
    return [list $idx $raw_count $antenna_count $connectivity_count]
}

proc mw_min_area_rows {} {
    set rows [list]
    set markers [list]
    catch {set markers [dbGet top.markers]}
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} { continue }
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
        if {![mw_is_min_area $layer $type $subtype $message]} { continue }
        if {![regexp -nocase {Regular[[:space:]]+Wire[[:space:]]+of[[:space:]]+Net[[:space:]]+([^[:space:]]+)} $message -> net]} {
            continue
        }
        lappend rows [list $net $marker [mw_flat_box $box] [mw_value $message]]
    }
    return $rows
}

proc mw_row_nets {rows} {
    set nets [list]
    foreach row $rows {
        set net [lindex $row 0]
        if {[lsearch -exact $nets $net] < 0} { lappend nets $net }
    }
    return [lsort $nets]
}

proc mw_validate_rows {rows expected_boxes actual_area} {
    array set by_net {}
    foreach row $rows {
        set net [lindex $row 0]
        if {[info exists by_net($net)]} { return 0 }
        set by_net($net) $row
    }
    foreach spec $expected_boxes {
        lassign $spec net expected_box
        if {![info exists by_net($net)]} { return 0 }
        set row $by_net($net)
        if {![mw_box_matches [lindex $row 2] $expected_box]} { return 0 }
        set message [lindex $row 3]
        if {![regexp -nocase \
            "Actual:[[:space:]]+$actual_area[[:space:]]+Required:[[:space:]]+0[.]20200000" \
            $message]} {
            return 0
        }
    }
    return [expr {[array size by_net] == [llength $expected_boxes]}]
}

proc mw_write_status {} {
    global status reports
    set fh [open [file join $reports min_area_waiver_export_status.rpt] w]
    foreach key [lsort [array names status]] {
        puts $fh "$key=$status($key)"
    }
    close $fh
}

proc mw_abort {reason {detail ""}} {
    global status command_fh
    set status(STATUS) FAIL
    set status(RESULT) $reason
    if {$detail ne ""} { set status(ERROR) [mw_value $detail] }
    if {[info exists command_fh] && $command_fh ne ""} {
        catch {flush $command_fh}
        catch {close $command_fh}
        set command_fh ""
    }
    mw_write_status
    puts stderr "SPADMIC_MIN_AREA_WAIVER_ABORT: $reason: [mw_value $detail]"
    exit 8
}

set command_pass_count 0
set command_fail_count 0

proc mw_run_command {fh label command} {
    global command_pass_count command_fail_count
    puts $fh "${label}=[mw_value $command]"
    if {[catch {uplevel #0 $command} err]} {
        incr command_fail_count
        puts $fh "${label}_STATUS=FAIL"
        puts $fh "${label}_ERROR=[mw_value $err]"
        flush $fh
        return 0
    }
    incr command_pass_count
    puts $fh "${label}_STATUS=PASS"
    flush $fh
    return 1
}

set checkpoint [mw_env SPADMIC_MIN_AREA_WAIVER_CHECKPOINT]
set root [mw_env SPADMIC_MIN_AREA_WAIVER_ROOT]
set top [mw_env SPADMIC_MIN_AREA_WAIVER_TOP]
set step27_analysis [mw_env SPADMIC_MIN_AREA_WAIVER_STEP27_ANALYSIS]
set stream_map [mw_env SPADMIC_MIN_AREA_WAIVER_STREAM_MAP]
set stdcell_gds [mw_env SPADMIC_MIN_AREA_WAIVER_STDCELL_GDS]
set reports [file join $root reports]
set outputs [file join $root outputs]
set checkpoints [file join $root checkpoints]
file mkdir $reports $outputs $checkpoints
set command_fh ""

array set status {
    LABEL SPADMIC_TX_PACKET_MIN_AREA_WAIVER_EXPORT
    POLICY ONE_FRESH_PROCESS_ONE_RESTORE_EXACT_SIX_BASE_EDITS_EXACT_FOUR_MARKER_WAIVER_EXPORT
    STATUS FAIL
    RESULT EXPORT_INCOMPLETE
    RESTORE_DESIGN NOT_RUN
    PATCH_CONTRACT_STATUS NOT_RUN
    PATCH_ATTEMPTED_COUNT 0
    PATCH_APPLIED_COUNT 0
    COMMAND_PASS_COUNT 0
    COMMAND_FAIL_COUNT 0
    SAVE_DESIGN NOT_RUN
    EXPORT NOT_RUN
    GDS_LAYER_MAP_STATUS PENDING_EXTERNAL_AUDIT
    PVS NOT_RUN
    PVS_DRC_WAIVER NO
    LVS_DIAGNOSTIC_ONLY YES
    MANUAL_FIX_REQUIRED YES
    BLOCK_PROMOTION_AUTHORIZED NO
    FINAL_SIGNOFF_READY NO
}
set status(SOURCE_CHECKPOINT) $checkpoint
set status(SOURCE_STEP27_ANALYSIS) $step27_analysis
set status(WAIVER_SCOPE) EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY
set status(WAIVER_ID) TX_PACKET_MET1_MIN_AREA_LVS_DIAGNOSTIC_20260716

array set source_values [mw_read_kv $step27_analysis]
array set expected_source {
    LABEL SPADMIC_TX_PACKET_MIN_AREA_CHAINED_LANDING_ANALYSIS
    POLICY ISOLATED_IN_MEMORY_SIX_BASE_THEN_FOUR_CHAINED_ENDPOINT_CLASSIFICATION
    STATUS PASS
    RESULT MIN_AREA_CHAINED_LANDING_TRIAL_CLASSIFIED
    TRIAL_REVISION R6
    TRIAL_PROCESS_STATUS FAIL
    TRIAL_PROCESS_RESULT CHAINED_ENDPOINT_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
    METHOD_STATUS REJECTED_OR_INCOMPLETE
    PATCH_CONTRACT_STATUS PASS_EXACT_SIX_BASE_AND_FOUR_CHAIN_ENDPOINTS
    BASE_STAGE_STATUS PASS_EXACT_FOUR_0P1777_SURVIVORS
    BASE_DRC_VIOLATION_COUNT 4
    BASE_DRC_MARKER_COUNT 4
    BASE_MIN_AREA_NETS {n_9677 n_9693 n_9696 n_9697}
    BASE_REGULAR_CONNECTIVITY_VIOLATION_COUNT 0
    BASE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT 0
    BASE_EXCLUDED_ANTENNA_MARKER_COUNT 21
    BASE_MARKER_DATABASE_TOTAL 25
    BASE_CANONICAL_FIXED_STUB_NET_COUNT 6
    CHAIN_ENDPOINT_CONTRACT_STATUS PASS_EXACT_FOUR_ACTUAL_CANONICAL_ENDPOINTS
    CHAIN_ENDPOINT_CONTRACT_VALIDATED_COUNT 4
    CHAIN_STAGE_STATUS APPLIED_EXACT_FOUR
    BASE_PATCH_ATTEMPTED_COUNT 6
    BASE_PATCH_APPLIED_COUNT 6
    CHAIN_PATCH_ATTEMPTED_COUNT 4
    CHAIN_PATCH_APPLIED_COUNT 4
    PATCH_ATTEMPTED_COUNT 10
    PATCH_APPLIED_COUNT 10
    COMMAND_PASS_COUNT 40
    COMMAND_FAIL_COUNT 0
    FINAL_DRC_VIOLATION_COUNT 4
    FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT 0
    FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT 0
    FINAL_EXCLUDED_ANTENNA_MARKER_COUNT 21
    FINAL_MARKER_DATABASE_TOTAL 25
    FINAL_MIN_AREA_NETS {n_9677 n_9693 n_9696 n_9697}
    SAVE_DESIGN NOT_RUN
    EXPORT NOT_RUN
    IMMUTABLE_PVS_STAGING NOT_RUN
    PVS_DECISION DO_NOT_RUN
    CANONICAL_RERUN_DECISION DO_NOT_RUN_FROM_THIS_STEP
    ERROR_COUNT 0
}
foreach key [array names expected_source] {
    set actual MISSING
    if {[info exists source_values($key)]} { set actual $source_values($key) }
    if {$actual ne $expected_source($key)} {
        mw_abort SOURCE_STEP27_ANALYSIS_NOT_ACCEPTED \
            "$key=$actual expected=$expected_source($key)"
    }
}

if {[catch {restoreDesign $checkpoint $top} restore_error]} {
    mw_abort RESTORE_FAILED $restore_error
}
set status(RESTORE_DESIGN) PASS

set expected_pre_boxes [list \
    [list n_9696 {719.69 158.62 720.07 158.90}] \
    [list n_9693 {210.09 201.74 210.47 202.02}] \
    [list n_9697 {663.13 192.78 663.51 193.06}] \
    [list n_9677 {1666.09 201.74 1666.47 202.02}] \
    [list n_9721 {1792.65 212.38 1793.03 212.66}] \
    [list n_9706 {1826.81 212.38 1827.19 212.66}]]
set expected_pre_nets {n_9677 n_9693 n_9696 n_9697 n_9706 n_9721}

set pre_drc [file join $reports verify_drc_pre_waiver_replay.rpt]
set pre_markers [file join $reports drc_markers_pre_waiver_replay.tsv]
set pre_regular [file join $reports verify_connectivity_regular_pre_waiver_replay.rpt]
set pre_special [file join $reports verify_connectivity_special_pre_waiver_replay.rpt]
if {![mw_capture $pre_drc {verify_drc}]} { mw_abort BASELINE_DRC_CAPTURE_FAILED }
if {[catch {
    lassign [mw_write_marker_dump $pre_markers] \
        pre_marker_count pre_database_total pre_antenna_count pre_connectivity_count
} marker_error]} {
    mw_abort BASELINE_MARKER_DUMP_FAILED $marker_error
}
set pre_rows [mw_min_area_rows]
set pre_nets [mw_row_nets $pre_rows]
if {![mw_capture $pre_regular {verifyConnectivity -type regular}] ||
    ![mw_capture $pre_special {verifyConnectivity -type special -nets {VDD VSS}}]} {
    mw_abort BASELINE_CONNECTIVITY_CAPTURE_FAILED
}
set pre_drc_count [mw_violation_count $pre_drc]
set pre_regular_count [mw_violation_count $pre_regular]
set pre_special_count [mw_violation_count $pre_special]
set status(PRE_DRC_VIOLATION_COUNT) $pre_drc_count
set status(PRE_DRC_MARKER_COUNT) $pre_marker_count
set status(PRE_MARKER_DATABASE_TOTAL) $pre_database_total
set status(PRE_EXCLUDED_ANTENNA_MARKER_COUNT) $pre_antenna_count
set status(PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $pre_connectivity_count
set status(PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $pre_regular_count
set status(PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $pre_special_count
set status(PRE_MIN_AREA_NETS) [join $pre_nets { }]

if {![string is integer -strict $pre_drc_count] || $pre_drc_count != 6 ||
    $pre_marker_count != 6 || [llength $pre_rows] != 6 ||
    $pre_nets ne $expected_pre_nets ||
    ![mw_validate_rows $pre_rows $expected_pre_boxes {0[.]10640000}] ||
    $pre_regular_count != 0 || $pre_special_count != 0 ||
    $pre_database_total != 27 || $pre_antenna_count != 21 ||
    $pre_connectivity_count != 0} {
    mw_abort BASELINE_PRECONDITION_FAILED \
        "drc=$pre_drc_count markers=$pre_marker_count rows=[llength $pre_rows] nets=$pre_nets regular=$pre_regular_count special=$pre_special_count database=$pre_database_total antenna=$pre_antenna_count connectivity=$pre_connectivity_count"
}

# net marker-box start-x start-y end-x width source-Q source-Q-x source-Q-y
set patch_contract [list \
    [list n_9696 {719.69 158.62 720.07 158.90} 719.88 158.76 719.32 0.28 g14627__2802/Q 716.61 159.02] \
    [list n_9693 {210.09 201.74 210.47 202.02} 210.28 201.88 209.72 0.28 g14630__8246/Q 207.01 201.62] \
    [list n_9697 {663.13 192.78 663.51 193.06} 663.32 192.92 662.76 0.28 g14626__1617/Q 660.05 192.66] \
    [list n_9677 {1666.09 201.74 1666.47 202.02} 1666.28 201.88 1666.84 0.28 g14646__2398/Q 1669.55 201.62] \
    [list n_9721 {1792.65 212.38 1793.03 212.66} 1792.84 212.52 1792.28 0.28 g14602__8246/Q 1789.57 212.78] \
    [list n_9706 {1826.81 212.38 1827.19 212.66} 1827.00 212.52 1827.56 0.28 g14617__5477/Q 1830.27 212.78]]

array set pre_row_by_net {}
foreach row $pre_rows { set pre_row_by_net([lindex $row 0]) $row }
set contract_path [file join $reports min_area_waiver_patch_contract.tsv]
set contract_fh [open $contract_path w]
puts $contract_fh "net\tmarker_box\tstart_x\tstart_y\tend_x\tend_y\tlength_um\twidth_um\tsource_q\tsource_q_point\tmarker_status\tvia1_status\tmet2_endpoint_status\tsource_q_status\tinside_source_inst_status\tcontract_status"
set contract_validated_count 0
set contract_failures [list]
foreach contract $patch_contract {
    lassign $contract net expected_box start_x start_y end_x patch_width source_q source_q_x source_q_y
    set marker_status FAIL
    set via_status FAIL
    set met2_status FAIL
    set source_status FAIL
    set inside_status FAIL
    set net_handles [list]
    catch {set net_handles [mw_valid_handles [dbGet top.nets.name $net -p]]}
    set net_handle ""
    if {[llength $net_handles] == 1} { set net_handle [lindex $net_handles 0] }
    if {[info exists pre_row_by_net($net)] &&
        [mw_box_matches [lindex $pre_row_by_net($net) 2] $expected_box]} {
        set marker_status PASS
    }
    if {$net_handle ne ""} {
        set vias [list]
        catch {set vias [mw_valid_handles [dbGet "${net_handle}.vias"]]}
        foreach via $vias {
            set via_name UNKNOWN
            set via_point UNKNOWN
            catch {set via_name [dbGet "${via}.via.name"]}
            if {$via_name eq "" || $via_name eq "0x0" || $via_name eq "UNKNOWN"} {
                catch {set via_name [dbGet "${via}.name"]}
            }
            catch {set via_point [dbGet "${via}.pt"]}
            if {$via_name eq "VIA1_o" && [mw_point_matches $via_point $start_x $start_y]} {
                set via_status PASS
                break
            }
        }
        set wires [list]
        catch {set wires [mw_valid_handles [dbGet "${net_handle}.wires"]]}
        foreach wire $wires {
            set layer UNKNOWN
            set width UNKNOWN
            set points UNKNOWN
            catch {set layer [dbGet "${wire}.layer.name"]}
            catch {set width [dbGet "${wire}.width"]}
            catch {set points [dbGet "${wire}.pts"]}
            if {$layer eq "MET2" && [mw_close $width 0.28] &&
                [mw_has_endpoint $points $start_x $start_y]} {
                set met2_status PASS
                break
            }
        }
        set iterms [list]
        catch {set iterms [mw_valid_handles [dbGet "${net_handle}.instTerms"]]}
        foreach iterm $iterms {
            set iterm_name UNKNOWN
            catch {set iterm_name [dbGet "${iterm}.name"]}
            if {$iterm_name ne $source_q} { continue }
            set source_point UNKNOWN
            set source_box UNKNOWN
            catch {set source_point [dbGet "${iterm}.pt"]}
            catch {set source_box [dbGet "${iterm}.inst.box"]}
            set direction_matches [expr {
                ($end_x < $start_x && $source_q_x < $start_x) ||
                ($end_x > $start_x && $source_q_x > $start_x)
            }]
            if {[mw_point_matches $source_point $source_q_x $source_q_y] &&
                $direction_matches} {
                set source_status PASS
            }
            set source_box [mw_flat_box $source_box]
            if {[mw_point_in_box $start_x [expr {$start_y - 0.14}] $source_box] &&
                [mw_point_in_box $start_x [expr {$start_y + 0.14}] $source_box] &&
                [mw_point_in_box $end_x [expr {$start_y - 0.14}] $source_box] &&
                [mw_point_in_box $end_x [expr {$start_y + 0.14}] $source_box]} {
                set inside_status PASS
            }
            break
        }
    }
    set contract_status FAIL
    if {$marker_status eq "PASS" && $via_status eq "PASS" &&
        $met2_status eq "PASS" && $source_status eq "PASS" &&
        $inside_status eq "PASS" &&
        [mw_close [expr {abs($end_x - $start_x)}] 0.56]} {
        set contract_status PASS
        incr contract_validated_count
    } else {
        lappend contract_failures \
            "$net:marker=$marker_status:via=$via_status:met2=$met2_status:source=$source_status:inside=$inside_status"
    }
    puts $contract_fh "$net\t[join $expected_box { }]\t[format %.2f $start_x]\t[format %.2f $start_y]\t[format %.2f $end_x]\t[format %.2f $start_y]\t0.56\t[format %.2f $patch_width]\t$source_q\t[format {%.2f %.2f} $source_q_x $source_q_y]\t$marker_status\t$via_status\t$met2_status\t$source_status\t$inside_status\t$contract_status"
}
close $contract_fh
set status(PATCH_CONTRACT_VALIDATED_COUNT) $contract_validated_count
if {$contract_validated_count != 6 || [llength $contract_failures] != 0} {
    mw_abort PATCH_CONTRACT_PRECONDITION_FAILED [join $contract_failures {,}]
}
set status(PATCH_CONTRACT_STATUS) PASS_EXACT_SIX_VALIDATED_BASE_EDITS

set command_path [file join $reports min_area_waiver_patch_commands.rpt]
set command_fh [open $command_path w]
puts $command_fh "LABEL=SPADMIC_TX_PACKET_MIN_AREA_WAIVER_PATCH_COMMANDS"
puts $command_fh "POLICY=EXACT_SIX_VALIDATED_BASE_EDITS_NO_CHAIN_STAGE"
puts $command_fh "PATCH_WIDTH_UM=0.28"
puts $command_fh "PATCH_LENGTH_UM=0.56"
puts $command_fh "PATCH_DIRECTION=ALL_TOWARD_SOURCE"
puts $command_fh "CONTRACT_VALIDATED_COUNT=$contract_validated_count"
set patch_attempted_count 0
set patch_applied_count 0
foreach contract $patch_contract {
    lassign $contract net expected_box start_x start_y end_x patch_width source_q source_q_x source_q_y
    incr patch_attempted_count
    set label "PATCH_${net}"
    puts $command_fh "${label}_START=[format {%.2f %.2f} $start_x $start_y]"
    puts $command_fh "${label}_END=[format {%.2f %.2f} $end_x $start_y]"
    puts $command_fh "${label}_WIDTH_UM=[format %.2f $patch_width]"
    set setup_command [list setEditMode \
        -nets $net \
        -shape None \
        -force_regular 1 \
        -layer_horizontal MET1 \
        -layer_vertical MET1 \
        -snap_to_track_regular 0 \
        -width_horizontal $patch_width \
        -width_vertical $patch_width]
    if {![mw_run_command $command_fh "${label}_SET_EDIT_MODE" $setup_command] ||
        ![mw_run_command $command_fh "${label}_SET_TOOL" {uiSetTool addWire}] ||
        ![mw_run_command $command_fh "${label}_ADD_ROUTE" [list editAddRoute $start_x $start_y]] ||
        ![mw_run_command $command_fh "${label}_COMMIT_ROUTE" [list editCommitRoute $end_x $start_y]]} {
        break
    }
    incr patch_applied_count
    puts $command_fh "${label}_APPLIED=YES"
}
catch {uiSetTool select}
catch {setEditMode -reset}
puts $command_fh "PATCH_ATTEMPTED_COUNT=$patch_attempted_count"
puts $command_fh "PATCH_APPLIED_COUNT=$patch_applied_count"
puts $command_fh "COMMAND_PASS_COUNT=$command_pass_count"
puts $command_fh "COMMAND_FAIL_COUNT=$command_fail_count"
close $command_fh
set command_fh ""
set status(PATCH_ATTEMPTED_COUNT) $patch_attempted_count
set status(PATCH_APPLIED_COUNT) $patch_applied_count
set status(COMMAND_PASS_COUNT) $command_pass_count
set status(COMMAND_FAIL_COUNT) $command_fail_count
if {$patch_attempted_count != 6 || $patch_applied_count != 6 ||
    $command_pass_count != 24 || $command_fail_count != 0} {
    mw_abort PATCH_COMMAND_FAILED \
        "attempted=$patch_attempted_count applied=$patch_applied_count pass=$command_pass_count fail=$command_fail_count"
}

set expected_final_boxes [list \
    [list n_9696 {719.38 158.68 720.07 158.91}] \
    [list n_9693 {209.78 201.73 210.47 201.96}] \
    [list n_9697 {662.82 192.77 663.51 193.00}] \
    [list n_9677 {1666.09 201.73 1666.78 201.96}]]
set expected_final_nets {n_9677 n_9693 n_9696 n_9697}
set final_drc [file join $reports verify_drc_post_waiver_replay.rpt]
set final_markers [file join $reports drc_markers_post_waiver_replay.tsv]
set final_regular [file join $reports verify_connectivity_regular_post_waiver_replay.rpt]
set final_special [file join $reports verify_connectivity_special_post_waiver_replay.rpt]
if {![mw_capture $final_drc {verify_drc}]} { mw_abort FINAL_DRC_CAPTURE_FAILED }
if {[catch {
    lassign [mw_write_marker_dump $final_markers] \
        final_marker_count final_database_total final_antenna_count final_connectivity_count
} marker_error]} {
    mw_abort FINAL_MARKER_DUMP_FAILED $marker_error
}
set final_rows [mw_min_area_rows]
set final_nets [mw_row_nets $final_rows]
if {![mw_capture $final_regular {verifyConnectivity -type regular}] ||
    ![mw_capture $final_special {verifyConnectivity -type special -nets {VDD VSS}}]} {
    mw_abort FINAL_CONNECTIVITY_CAPTURE_FAILED
}
set final_drc_count [mw_violation_count $final_drc]
set final_regular_count [mw_violation_count $final_regular]
set final_special_count [mw_violation_count $final_special]
set status(FINAL_DRC_VIOLATION_COUNT) $final_drc_count
set status(FINAL_DRC_MARKER_COUNT) $final_marker_count
set status(FINAL_MARKER_DATABASE_TOTAL) $final_database_total
set status(FINAL_EXCLUDED_ANTENNA_MARKER_COUNT) $final_antenna_count
set status(FINAL_EXCLUDED_CONNECTIVITY_MARKER_COUNT) $final_connectivity_count
set status(FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT) $final_regular_count
set status(FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT) $final_special_count
set status(FINAL_MIN_AREA_NETS) [join $final_nets { }]

if {![string is integer -strict $final_drc_count] || $final_drc_count != 4 ||
    $final_marker_count != 4 || [llength $final_rows] != 4 ||
    $final_nets ne $expected_final_nets ||
    ![mw_validate_rows $final_rows $expected_final_boxes {0[.]17770000}] ||
    $final_regular_count != 0 || $final_special_count != 0 ||
    $final_database_total != 25 || $final_antenna_count != 21 ||
    $final_connectivity_count != 0} {
    mw_abort EXACT_FOUR_MARKER_WAIVER_STATE_NOT_REPRODUCED \
        "drc=$final_drc_count markers=$final_marker_count rows=[llength $final_rows] nets=$final_nets regular=$final_regular_count special=$final_special_count database=$final_database_total antenna=$final_antenna_count connectivity=$final_connectivity_count"
}

array set final_row_by_net {}
foreach row $final_rows { set final_row_by_net([lindex $row 0]) $row }
set waiver_tsv [file join $reports temporary_drc_waiver.tsv]
set waiver_fh [open $waiver_tsv w]
puts $waiver_fh "waiver_id\tnet\tlayer\ttype\tsubtype\tmarker_handle\tmarker_box\tactual_area_um2\trequired_area_um2\tdisposition\tmanual_fix_required"
foreach spec $expected_final_boxes {
    lassign $spec net expected_box
    set row $final_row_by_net($net)
    puts $waiver_fh "TX_PACKET_MET1_MIN_AREA_LVS_DIAGNOSTIC_20260716\t$net\tMET1\tGeometry\tMinimal_Area\t[mw_value [lindex $row 1]]\t[join [lindex $row 2] { }]\t0.17770000\t0.20200000\tTEMPORARILY_ACCEPTED_FOR_PVS_LVS_DIAGNOSTIC_ONLY\tYES"
}
close $waiver_fh

set waiver_report [file join $reports temporary_drc_waiver.rpt]
set waiver_rpt_fh [open $waiver_report w]
puts $waiver_rpt_fh "LABEL=SPADMIC_TX_PACKET_TEMPORARY_DRC_WAIVER"
puts $waiver_rpt_fh "STATUS=PASS"
puts $waiver_rpt_fh "RESULT=EXACT_FOUR_MARKERS_RECORDED"
puts $waiver_rpt_fh "WAIVER_ID=TX_PACKET_MET1_MIN_AREA_LVS_DIAGNOSTIC_20260716"
puts $waiver_rpt_fh "WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY"
puts $waiver_rpt_fh "WAIVER_MARKER_COUNT=4"
puts $waiver_rpt_fh "WAIVER_NETS=n_9677 n_9693 n_9696 n_9697"
puts $waiver_rpt_fh "ALLOWED_LAYER=MET1"
puts $waiver_rpt_fh "ALLOWED_TYPE=Geometry"
puts $waiver_rpt_fh "ALLOWED_SUBTYPE=Minimal_Area"
puts $waiver_rpt_fh "ACTUAL_AREA_UM2=0.17770000"
puts $waiver_rpt_fh "REQUIRED_AREA_UM2=0.20200000"
puts $waiver_rpt_fh "REGULAR_CONNECTIVITY_STATUS=PASS"
puts $waiver_rpt_fh "SPECIAL_CONNECTIVITY_STATUS=PASS"
puts $waiver_rpt_fh "PVS_DRC_WAIVER=NO"
puts $waiver_rpt_fh "LVS_EXECUTION_AUTHORIZED=YES_DIAGNOSTIC_ONLY"
puts $waiver_rpt_fh "LVS_DIAGNOSTIC_ONLY=YES"
puts $waiver_rpt_fh "MANUAL_FIX_REQUIRED=YES"
puts $waiver_rpt_fh "EXPIRY_EVENT=BEFORE_FINAL_PVS_DRC_AND_BLOCK_PROMOTION"
puts $waiver_rpt_fh "BLOCK_PROMOTION_AUTHORIZED=NO"
puts $waiver_rpt_fh "FINAL_SIGNOFF_READY=NO"
puts $waiver_rpt_fh "WAIVER_TABLE=$waiver_tsv"
close $waiver_rpt_fh

set checkpoint_out [file join $checkpoints 05_min_area_waiver_export.enc]
if {[catch {saveDesign $checkpoint_out} save_error]} {
    mw_abort SAVE_DESIGN_FAILED $save_error
}
set status(SAVE_DESIGN) PASS
set status(SAVED_CHECKPOINT) "${checkpoint_out}.dat"

set base [file join $outputs $top]
if {[catch {
    defOut "${base}.def"
    saveNetlist "${base}.routed.v"
    saveNetlist -includePowerGround "${base}.routed.pg.v"
    if {[catch {write_lef_abstract "${base}.lef"}]} {
        lefOut "${base}.lef"
    }
    file copy -force "${base}.lef" "${base}.abstract.lef"
    streamOut "${base}.gds" -libName DesignLib -units 1000 -mode ALL \
        -mapFile $stream_map -merge [list $stdcell_gds]
} export_error]} {
    mw_abort EXPORT_FAILED $export_error
}
foreach required [list \
    "${base}.def" \
    "${base}.routed.v" \
    "${base}.routed.pg.v" \
    "${base}.lef" \
    "${base}.abstract.lef" \
    "${base}.gds"] {
    if {![file exists $required] || [file size $required] <= 0} {
        mw_abort EXPORT_OUTPUT_MISSING $required
    }
}

set status(EXPORT) PASS
set status(GDS) "${base}.gds"
set status(NETLIST_PG) "${base}.routed.pg.v"
set status(LEF) "${base}.abstract.lef"
set status(DEF) "${base}.def"
set status(INNOVUS_DRC_STATUS) PASS_WITH_EXACT_TEMPORARY_WAIVER
set status(STATUS) PASS
set status(RESULT) EXACT_FOUR_MARKER_WAIVER_STATE_EXPORTED_FOR_PROVISIONAL_PVS
mw_write_status
exit 0
