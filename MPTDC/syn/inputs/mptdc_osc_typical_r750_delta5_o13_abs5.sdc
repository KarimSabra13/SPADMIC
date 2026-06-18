# =============================================================================
# O13 abs5 exact PD q1 Vernier exception overlay for R750_delta5 typical run
# =============================================================================
# Typical feasibility only. Not MMMC, not final signoff, and not a tapeout view.
#
# This overlay preserves the O13 abs3 clock/CDC repair, then applies one exact
# measurement exception for the intended Vernier relation:
#
#   buffered slow_phase[ns] -> PD q1_reg/D in row ns, sampled by fast_phase[nf]
#
# The exception is fail-closed and count checked:
#   8 slow buffered sources x 8 fast columns = 64 q1 sampler endpoints.
#
# It does not cut q1->q2, hit_latched, nfast_hit_latched, fast-tag, timestamp
# freeze, slow-Johnson, clk_sys, reset/recovery, or phase-buffer topology paths.
# =============================================================================

puts "MPTDC_O13_ABS5_SDC_INFO: loading O13_ABS5_PD_Q1_EXCEPTION_EXACT_MATCH overlay"
puts "MPTDC_O13_ABS5_SDC_INFO: sourcing O13 abs3 clock/CDC repair overlay first"

set mptdc_o13_abs5_self ""
if {[info exists ::env(MPTDC_OSC_PD_SDC_OVERLAY)] && $::env(MPTDC_OSC_PD_SDC_OVERLAY) ne ""} {
    set mptdc_o13_abs5_self [file normalize $::env(MPTDC_OSC_PD_SDC_OVERLAY)]
} elseif {[info script] ne ""} {
    set mptdc_o13_abs5_self [file normalize [info script]]
}

if {$mptdc_o13_abs5_self eq ""} {
    error "MPTDC_O13_ABS5_SDC_FATAL: cannot determine abs5 overlay path"
}

set mptdc_o13_abs5_dir [file dirname $mptdc_o13_abs5_self]
set mptdc_o13_abs5_abs3_sdc [file join $mptdc_o13_abs5_dir mptdc_osc_typical_r750_delta5_o13_abs3.sdc]
if {![file exists $mptdc_o13_abs5_abs3_sdc]} {
    error "MPTDC_O13_ABS5_SDC_FATAL: missing required abs3 overlay: $mptdc_o13_abs5_abs3_sdc"
}
source $mptdc_o13_abs5_abs3_sdc

proc mptdc_o13_abs5_object_name {obj} {
    set name ""
    if {[catch {set name [get_object_name $obj]}]} {
        if {[catch {set name [get_db $obj .name]}]} {
            set name $obj
        }
    }
    return $name
}

proc mptdc_o13_abs5_collection_to_list {collection} {
    set out [list]
    if {[llength [info commands foreach_in_collection]] > 0} {
        foreach_in_collection obj $collection {
            lappend out $obj
        }
        return $out
    }
    foreach obj $collection {
        lappend out $obj
    }
    return $out
}

proc mptdc_o13_abs5_collect_pins {patterns} {
    set pins [list]
    array set seen {}
    foreach pattern $patterns {
        set found [list]
        catch {set found [get_pins -quiet -hierarchical $pattern]}
        foreach pin [mptdc_o13_abs5_collection_to_list $found] {
            set name [mptdc_o13_abs5_object_name $pin]
            if {![info exists seen($name)]} {
                set seen($name) 1
                lappend pins $pin
            }
        }
    }
    return $pins
}

proc mptdc_o13_abs5_add_unique_pin {pin pins_var seen_var} {
    upvar $pins_var pins
    upvar $seen_var seen
    set name [mptdc_o13_abs5_object_name $pin]
    if {![info exists seen($name)]} {
        set seen($name) 1
        lappend pins $pin
    }
}

proc mptdc_o13_abs5_collect_slow_source_pins {} {
    set pins [list]
    array set seen {}

    # Use the exact per-tap resolver from abs3.  Abs3 has already proven these
    # BUJIHDX12 Q pins exist by creating clk_osc_slow_buf_tap0..7 on them.
    for {set tap 0} {$tap < 8} {incr tap} {
        set found [list]
        if {[llength [info commands mptdc_o13_abs3_try_get_pins]] > 0 &&
            [llength [info commands mptdc_o13_abs3_stage_pin_patterns]] > 0} {
            catch {
                set found [mptdc_o13_abs3_try_get_pins \
                    [mptdc_o13_abs3_stage_pin_patterns slow $tap u_drv Q]]
            }
        }

        if {[llength $found] == 0} {
            set found [mptdc_o13_abs5_collect_pins [list \
                [format {u_core/u_phase_buf_slow/gen_phase_buf[%d]/u_drv/Q} $tap] \
                [format {u_core/u_phase_buf_slow/gen_phase_buf[%d].u_drv/Q} $tap] \
                [format {u_core_u_phase_buf_slow/gen_phase_buf[%d].u_drv/Q} $tap] \
                [format {u_core_u_phase_buf_slow_gen_phase_buf_%d__u_drv/Q} $tap] \
                [format {*u_phase_buf_slow*gen_phase_buf*%d*u_drv/Q} $tap]]]
        }

        foreach pin [mptdc_o13_abs5_collection_to_list $found] {
            mptdc_o13_abs5_add_unique_pin $pin pins seen
        }
    }

    return $pins
}

proc mptdc_o13_abs5_match_q1_endpoint {name ns_var nf_var} {
    upvar $ns_var ns
    upvar $nf_var nf
    if {[regexp {gen_pd_row\[([0-7])\].*gen_pd_col\[([0-7])\].*u_pd.*q1_reg[^/]*/D$} $name -> ns nf]} {
        return 1
    }
    if {[regexp {gen_pd_row_?([0-7]).*gen_pd_col_?([0-7]).*u_pd.*q1[^/]*/D$} $name -> ns nf]} {
        return 1
    }
    return 0
}

proc mptdc_o13_abs5_match_slow_source {name tap_var} {
    upvar $tap_var tap
    if {[regexp {u_phase_buf_slow.*gen_phase_buf\[([0-7])\].*u_drv/Q$} $name -> tap]} {
        return 1
    }
    if {[regexp {u_phase_buf_slow.*gen_phase_buf_?([0-7]).*u_drv/Q$} $name -> tap]} {
        return 1
    }
    return 0
}

proc mptdc_o13_abs5_join_or_none {items} {
    if {[llength $items] == 0} {
        return "none"
    }
    return [join $items ", "]
}

proc mptdc_o13_abs5_open_report {path} {
    file mkdir [file dirname $path]
    return [open $path w]
}

set mptdc_o13_abs5_expected_endpoints 64
set mptdc_o13_abs5_expected_sources 8

array set mptdc_o13_abs5_q1_pin_by_pair {}
array set mptdc_o13_abs5_q1_name_by_pair {}
array set mptdc_o13_abs5_slow_source_by_tap {}
array set mptdc_o13_abs5_slow_source_name_by_tap {}
array set mptdc_o13_abs5_row_count {}
array set mptdc_o13_abs5_col_count {}
array set mptdc_o13_abs5_source_count {}

for {set idx 0} {$idx < 8} {incr idx} {
    set mptdc_o13_abs5_row_count($idx) 0
    set mptdc_o13_abs5_col_count($idx) 0
    set mptdc_o13_abs5_source_count($idx) 0
}

set mptdc_o13_abs5_q1_candidates [mptdc_o13_abs5_collect_pins [list \
    *gen_pd_row*gen_pd_col*u_pd*/q1_reg*/D \
    *gen_pd_row*gen_pd_col*u_pd*q1*/D \
    *q1_reg*/D]]
set mptdc_o13_abs5_q1_candidate_count [llength $mptdc_o13_abs5_q1_candidates]
set mptdc_o13_abs5_q1_matched_count 0
set mptdc_o13_abs5_q1_duplicate_count 0
set mptdc_o13_abs5_q1_duplicates [list]
set mptdc_o13_abs5_q1_unmatched [list]

foreach pin $mptdc_o13_abs5_q1_candidates {
    set name [mptdc_o13_abs5_object_name $pin]
    set mptdc_o13_abs5_ns ""
    set mptdc_o13_abs5_nf ""
    if {[mptdc_o13_abs5_match_q1_endpoint $name mptdc_o13_abs5_ns mptdc_o13_abs5_nf]} {
        set key "${mptdc_o13_abs5_ns},${mptdc_o13_abs5_nf}"
        if {[info exists mptdc_o13_abs5_q1_pin_by_pair($key)]} {
            incr mptdc_o13_abs5_q1_duplicate_count
            lappend mptdc_o13_abs5_q1_duplicates $name
            continue
        }
        set mptdc_o13_abs5_q1_pin_by_pair($key) $pin
        set mptdc_o13_abs5_q1_name_by_pair($key) $name
        incr mptdc_o13_abs5_q1_matched_count
        incr mptdc_o13_abs5_row_count($mptdc_o13_abs5_ns)
        incr mptdc_o13_abs5_col_count($mptdc_o13_abs5_nf)
    } else {
        lappend mptdc_o13_abs5_q1_unmatched $name
    }
}

set mptdc_o13_abs5_missing_pairs [list]
for {set mptdc_o13_abs5_ns 0} {$mptdc_o13_abs5_ns < 8} {incr mptdc_o13_abs5_ns} {
    for {set mptdc_o13_abs5_nf 0} {$mptdc_o13_abs5_nf < 8} {incr mptdc_o13_abs5_nf} {
        set key "${mptdc_o13_abs5_ns},${mptdc_o13_abs5_nf}"
        if {![info exists mptdc_o13_abs5_q1_pin_by_pair($key)]} {
            lappend mptdc_o13_abs5_missing_pairs $key
        }
    }
}

set mptdc_o13_abs5_source_candidates [mptdc_o13_abs5_collect_slow_source_pins]
set mptdc_o13_abs5_source_candidate_count [llength $mptdc_o13_abs5_source_candidates]
set mptdc_o13_abs5_source_matched_count 0
set mptdc_o13_abs5_source_duplicate_count 0
set mptdc_o13_abs5_source_duplicates [list]
set mptdc_o13_abs5_source_unmatched [list]

foreach pin $mptdc_o13_abs5_source_candidates {
    set name [mptdc_o13_abs5_object_name $pin]
    set tap ""
    if {[mptdc_o13_abs5_match_slow_source $name tap]} {
        if {[info exists mptdc_o13_abs5_slow_source_by_tap($tap)]} {
            incr mptdc_o13_abs5_source_duplicate_count
            lappend mptdc_o13_abs5_source_duplicates $name
            continue
        }
        set mptdc_o13_abs5_slow_source_by_tap($tap) $pin
        set mptdc_o13_abs5_slow_source_name_by_tap($tap) $name
        incr mptdc_o13_abs5_source_count($tap)
        incr mptdc_o13_abs5_source_matched_count
    } else {
        lappend mptdc_o13_abs5_source_unmatched $name
    }
}

set mptdc_o13_abs5_missing_sources [list]
for {set tap 0} {$tap < 8} {incr tap} {
    if {![info exists mptdc_o13_abs5_slow_source_by_tap($tap)]} {
        lappend mptdc_o13_abs5_missing_sources $tap
    }
}

set mptdc_o13_abs5_endpoint_status FAIL_ENDPOINT_DISCOVERY
if {$mptdc_o13_abs5_q1_matched_count == $mptdc_o13_abs5_expected_endpoints && \
    [llength $mptdc_o13_abs5_missing_pairs] == 0 && \
    $mptdc_o13_abs5_q1_duplicate_count == 0} {
    set mptdc_o13_abs5_endpoint_status PASS_64_ENDPOINTS
}

set mptdc_o13_abs5_source_status FAIL_SOURCE_DISCOVERY
if {$mptdc_o13_abs5_source_matched_count == $mptdc_o13_abs5_expected_sources && \
    [llength $mptdc_o13_abs5_missing_sources] == 0 && \
    $mptdc_o13_abs5_source_duplicate_count == 0} {
    set mptdc_o13_abs5_source_status PASS_8_SLOW_SOURCES
}

set mptdc_o13_abs5_overmatch NO
set mptdc_o13_abs5_undermatch NO
if {$mptdc_o13_abs5_q1_duplicate_count > 0 || $mptdc_o13_abs5_source_duplicate_count > 0 || \
    $mptdc_o13_abs5_q1_matched_count > $mptdc_o13_abs5_expected_endpoints || \
    $mptdc_o13_abs5_source_matched_count > $mptdc_o13_abs5_expected_sources} {
    set mptdc_o13_abs5_overmatch YES
}
if {$mptdc_o13_abs5_q1_matched_count < $mptdc_o13_abs5_expected_endpoints || \
    $mptdc_o13_abs5_source_matched_count < $mptdc_o13_abs5_expected_sources || \
    [llength $mptdc_o13_abs5_missing_pairs] > 0 || \
    [llength $mptdc_o13_abs5_missing_sources] > 0} {
    set mptdc_o13_abs5_undermatch YES
}

set mptdc_o13_abs5_exception_applied NO
set mptdc_o13_abs5_exception_failures 0
set mptdc_o13_abs5_applied_endpoint_count 0
set mptdc_o13_abs5_apply_rows [list]

if {$mptdc_o13_abs5_endpoint_status eq "PASS_64_ENDPOINTS" && \
    $mptdc_o13_abs5_source_status eq "PASS_8_SLOW_SOURCES"} {
    for {set mptdc_o13_abs5_ns 0} {$mptdc_o13_abs5_ns < 8} {incr mptdc_o13_abs5_ns} {
        set to_pins [list]
        for {set mptdc_o13_abs5_nf 0} {$mptdc_o13_abs5_nf < 8} {incr mptdc_o13_abs5_nf} {
            lappend to_pins $mptdc_o13_abs5_q1_pin_by_pair(${mptdc_o13_abs5_ns},${mptdc_o13_abs5_nf})
        }
        set source_pin $mptdc_o13_abs5_slow_source_by_tap($mptdc_o13_abs5_ns)
        if {[catch {set_false_path -from $source_pin -to $to_pins} err]} {
            incr mptdc_o13_abs5_exception_failures
            lappend mptdc_o13_abs5_apply_rows [list $mptdc_o13_abs5_ns FAIL $err]
            puts "MPTDC_O13_ABS5_SDC_WARN: failed exact PD Vernier false path for slow tap $mptdc_o13_abs5_ns: $err"
        } else {
            incr mptdc_o13_abs5_applied_endpoint_count 8
            lappend mptdc_o13_abs5_apply_rows [list $mptdc_o13_abs5_ns OK "applied to 8 q1 endpoints"]
        }
    }
}

if {$mptdc_o13_abs5_exception_failures == 0 && \
    $mptdc_o13_abs5_applied_endpoint_count == $mptdc_o13_abs5_expected_endpoints} {
    set mptdc_o13_abs5_exception_applied YES
}

puts "MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_FOUND_ENDPOINTS=$mptdc_o13_abs5_q1_matched_count"
puts "MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXPECTED_ENDPOINTS=$mptdc_o13_abs5_expected_endpoints"
puts "MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_FOUND_SOURCES=$mptdc_o13_abs5_source_matched_count"
puts "MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXPECTED_SOURCES=$mptdc_o13_abs5_expected_sources"
puts "MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXCEPTION_APPLIED=$mptdc_o13_abs5_exception_applied"
puts "MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_OVERMATCH=$mptdc_o13_abs5_overmatch"
puts "MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_UNDERMATCH=$mptdc_o13_abs5_undermatch"
puts "MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXCEPTION_FAILURES=$mptdc_o13_abs5_exception_failures"

if {[info exists ::env(MPTDC_O13_PD_VERNIER_ENDPOINT_DISCOVERY_RPT)] && $::env(MPTDC_O13_PD_VERNIER_ENDPOINT_DISCOVERY_RPT) ne ""} {
    set fh [mptdc_o13_abs5_open_report $::env(MPTDC_O13_PD_VERNIER_ENDPOINT_DISCOVERY_RPT)]
    puts $fh "# O13 abs5 PD q1 Endpoint Discovery"
    puts $fh ""
    puts $fh "TOTAL_CANDIDATES=$mptdc_o13_abs5_q1_candidate_count"
    puts $fh "TOTAL_MATCHED=$mptdc_o13_abs5_q1_matched_count"
    puts $fh "EXPECTED_MATCHED=64"
    puts $fh "DUPLICATES=$mptdc_o13_abs5_q1_duplicate_count"
    puts $fh "MISSING_PAIRS=[mptdc_o13_abs5_join_or_none $mptdc_o13_abs5_missing_pairs]"
    puts $fh "FINAL_STATUS=$mptdc_o13_abs5_endpoint_status"
    puts $fh ""
    puts $fh "## Per-row count"
    for {set mptdc_o13_abs5_ns 0} {$mptdc_o13_abs5_ns < 8} {incr mptdc_o13_abs5_ns} {
        puts $fh "row_${mptdc_o13_abs5_ns}=$mptdc_o13_abs5_row_count($mptdc_o13_abs5_ns)"
    }
    puts $fh ""
    puts $fh "## Per-column count"
    for {set mptdc_o13_abs5_nf 0} {$mptdc_o13_abs5_nf < 8} {incr mptdc_o13_abs5_nf} {
        puts $fh "col_${mptdc_o13_abs5_nf}=$mptdc_o13_abs5_col_count($mptdc_o13_abs5_nf)"
    }
    puts $fh ""
    puts $fh "## Endpoints"
    for {set mptdc_o13_abs5_ns 0} {$mptdc_o13_abs5_ns < 8} {incr mptdc_o13_abs5_ns} {
        for {set mptdc_o13_abs5_nf 0} {$mptdc_o13_abs5_nf < 8} {incr mptdc_o13_abs5_nf} {
            set key "${mptdc_o13_abs5_ns},${mptdc_o13_abs5_nf}"
            if {[info exists mptdc_o13_abs5_q1_name_by_pair($key)]} {
                puts $fh "q1_endpoint($key)=$mptdc_o13_abs5_q1_name_by_pair($key)"
            } else {
                puts $fh "q1_endpoint($key)=MISSING"
            }
        }
    }
    puts $fh ""
    puts $fh "## Duplicate matches"
    foreach name $mptdc_o13_abs5_q1_duplicates {
        puts $fh "- $name"
    }
    puts $fh ""
    puts $fh "## Unmatched q1 candidates"
    foreach name $mptdc_o13_abs5_q1_unmatched {
        puts $fh "- $name"
    }
    close $fh
}

if {[info exists ::env(MPTDC_O13_PD_VERNIER_SOURCE_DISCOVERY_RPT)] && $::env(MPTDC_O13_PD_VERNIER_SOURCE_DISCOVERY_RPT) ne ""} {
    set fh [mptdc_o13_abs5_open_report $::env(MPTDC_O13_PD_VERNIER_SOURCE_DISCOVERY_RPT)]
    puts $fh "# O13 abs5 PD slow-source Discovery"
    puts $fh ""
    puts $fh "TOTAL_CANDIDATES=$mptdc_o13_abs5_source_candidate_count"
    puts $fh "MATCHED_SLOW_BUFFER_OUTPUTS=$mptdc_o13_abs5_source_matched_count"
    puts $fh "EXPECTED_SLOW_BUFFER_OUTPUTS=8"
    puts $fh "DUPLICATES=$mptdc_o13_abs5_source_duplicate_count"
    puts $fh "MISSING_TAPS=[mptdc_o13_abs5_join_or_none $mptdc_o13_abs5_missing_sources]"
    puts $fh "FINAL_STATUS=$mptdc_o13_abs5_source_status"
    puts $fh ""
    puts $fh "## Per-tap source"
    for {set tap 0} {$tap < 8} {incr tap} {
        if {[info exists mptdc_o13_abs5_slow_source_name_by_tap($tap)]} {
            puts $fh "slow_source($tap)=$mptdc_o13_abs5_slow_source_name_by_tap($tap)"
        } else {
            puts $fh "slow_source($tap)=MISSING"
        }
    }
    puts $fh ""
    puts $fh "## Duplicate matches"
    foreach name $mptdc_o13_abs5_source_duplicates {
        puts $fh "- $name"
    }
    puts $fh ""
    puts $fh "## Unmatched source candidates"
    foreach name $mptdc_o13_abs5_source_unmatched {
        puts $fh "- $name"
    }
    close $fh
}

if {[info exists ::env(MPTDC_O13_PD_VERNIER_RPT)] && $::env(MPTDC_O13_PD_VERNIER_RPT) ne ""} {
    set fh [mptdc_o13_abs5_open_report $::env(MPTDC_O13_PD_VERNIER_RPT)]
    puts $fh "# O13 abs5 PD Vernier Exception Check"
    puts $fh ""
    puts $fh "PD_VERNIER_EXPECTED_ENDPOINTS=$mptdc_o13_abs5_expected_endpoints"
    puts $fh "PD_VERNIER_FOUND_ENDPOINTS=$mptdc_o13_abs5_q1_matched_count"
    puts $fh "PD_VERNIER_FOUND_SOURCES=$mptdc_o13_abs5_source_matched_count"
    puts $fh "PD_VERNIER_EXCEPTION_APPLIED=$mptdc_o13_abs5_exception_applied"
    puts $fh "PD_VERNIER_OVERMATCH=$mptdc_o13_abs5_overmatch"
    puts $fh "PD_VERNIER_UNDERMATCH=$mptdc_o13_abs5_undermatch"
    puts $fh "PD_VERNIER_EXCEPTION_FAILURES=$mptdc_o13_abs5_exception_failures"
    puts $fh "PD_VERNIER_APPLIED_ENDPOINTS=$mptdc_o13_abs5_applied_endpoint_count"
    puts $fh ""
    puts $fh "PD_VERNIER_EXCEPTION_ENDPOINTS_FOUND=$mptdc_o13_abs5_q1_matched_count"
    puts $fh "PD_VERNIER_EXCEPTION_EXPECTED=$mptdc_o13_abs5_expected_endpoints"
    puts $fh "PD_VERNIER_SOURCE_CLOCKS_FOUND=$mptdc_o13_abs5_source_matched_count"
    puts $fh "PD_VERNIER_EXCEPTION_OVERMATCH=$mptdc_o13_abs5_overmatch"
    puts $fh ""
    puts $fh "## Per-row exception"
    puts $fh "| slow_tap | source_pin | endpoint_count | exception_status | detail |"
    puts $fh "|---:|---|---:|---|---|"
    for {set mptdc_o13_abs5_ns 0} {$mptdc_o13_abs5_ns < 8} {incr mptdc_o13_abs5_ns} {
        set source_name "MISSING"
        if {[info exists mptdc_o13_abs5_slow_source_name_by_tap($mptdc_o13_abs5_ns)]} {
            set source_name $mptdc_o13_abs5_slow_source_name_by_tap($mptdc_o13_abs5_ns)
        }
        set row_status "NOT_APPLIED"
        set row_detail "endpoint/source discovery failed"
        foreach row $mptdc_o13_abs5_apply_rows {
            if {[lindex $row 0] == $mptdc_o13_abs5_ns} {
                set row_status [lindex $row 1]
                set row_detail [lindex $row 2]
            }
        }
        puts $fh "| $mptdc_o13_abs5_ns | `$source_name` | $mptdc_o13_abs5_row_count($mptdc_o13_abs5_ns) | $row_status | $row_detail |"
        for {set mptdc_o13_abs5_nf 0} {$mptdc_o13_abs5_nf < 8} {incr mptdc_o13_abs5_nf} {
            set key "${mptdc_o13_abs5_ns},${mptdc_o13_abs5_nf}"
            if {[info exists mptdc_o13_abs5_q1_name_by_pair($key)]} {
                puts $fh "  - endpoint($key): `$mptdc_o13_abs5_q1_name_by_pair($key)`"
            } else {
                puts $fh "  - endpoint($key): `MISSING`"
            }
        }
    }
    puts $fh ""
    puts $fh "## Scope"
    puts $fh "- Cuts only buffered slow phase final-driver output pins into same-row PD q1 sampler D pins."
    puts $fh "- Does not cut q1->q2, q1/q2->hit_latched, nfast_tag->timestamp, slow Johnson, clk_sys, reset/recovery, or phase-buffer topology paths."
    puts $fh "- This is a measurement classification exception, not final signoff."
    close $fh
}

if {[info exists ::env(MPTDC_O13_PD_VERNIER_INTENT_RPT)] && $::env(MPTDC_O13_PD_VERNIER_INTENT_RPT) ne ""} {
    set fh [mptdc_o13_abs5_open_report $::env(MPTDC_O13_PD_VERNIER_INTENT_RPT)]
    puts $fh "# O13 abs5 PD Intentional Vernier Proof"
    puts $fh ""
    puts $fh "PD_INTENTIONAL_VERNIER_EXPECTED=64"
    puts $fh "PD_INTENTIONAL_VERNIER_MATCHED=$mptdc_o13_abs5_q1_matched_count"
    puts $fh "PD_INTENTIONAL_VERNIER_SOURCES=$mptdc_o13_abs5_source_matched_count"
    puts $fh "PD_INTENTIONAL_VERNIER_EXCEPTION_APPLIED=$mptdc_o13_abs5_exception_applied"
    puts $fh "PD_INTENTIONAL_VERNIER_OVERMATCH=$mptdc_o13_abs5_overmatch"
    puts $fh "PD_INTENTIONAL_VERNIER_UNDERMATCH=$mptdc_o13_abs5_undermatch"
    set mptdc_o13_abs5_intent_status REVIEW_REQUIRED
    if {$mptdc_o13_abs5_exception_applied eq "YES"} {
        set mptdc_o13_abs5_intent_status OK_INTENTIONAL_MEASUREMENT_CROSSING
    }
    puts $fh "PD_INTENTIONAL_VERNIER_STATUS=$mptdc_o13_abs5_intent_status"
    puts $fh ""
    puts $fh "## Matrix"
    for {set mptdc_o13_abs5_ns 0} {$mptdc_o13_abs5_ns < 8} {incr mptdc_o13_abs5_ns} {
        set source_name "MISSING"
        if {[info exists mptdc_o13_abs5_slow_source_name_by_tap($mptdc_o13_abs5_ns)]} {
            set source_name $mptdc_o13_abs5_slow_source_name_by_tap($mptdc_o13_abs5_ns)
        }
        puts $fh "slow_tap=$mptdc_o13_abs5_ns source=$source_name"
        for {set mptdc_o13_abs5_nf 0} {$mptdc_o13_abs5_nf < 8} {incr mptdc_o13_abs5_nf} {
            set key "${mptdc_o13_abs5_ns},${mptdc_o13_abs5_nf}"
            if {[info exists mptdc_o13_abs5_q1_name_by_pair($key)]} {
                puts $fh "  fast_col=$mptdc_o13_abs5_nf endpoint=$mptdc_o13_abs5_q1_name_by_pair($key)"
            } else {
                puts $fh "  fast_col=$mptdc_o13_abs5_nf endpoint=MISSING"
            }
        }
    }
    close $fh
}
