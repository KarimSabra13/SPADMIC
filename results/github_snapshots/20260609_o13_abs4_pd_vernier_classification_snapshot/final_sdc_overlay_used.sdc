# =============================================================================
# O13 abs4 PD Vernier classification overlay for R750_delta5 typical experiment
# =============================================================================
# Typical feasibility only. Not MMMC, not final signoff, and not a tapeout view.
#
# This overlay preserves the O13 abs3 clock/CDC repair, then adds one exact
# measurement exception for the intended Vernier relation:
#
#   buffered slow_phase[ns] -> PD q1_reg/D in row ns, sampled by fast_phase[nf]
#
# The exception is count checked at 8 slow rows x 8 fast columns = 64 endpoints.
# It does not cut q1->q2, fast-tag, timestamp-freeze, slow-Johnson, clk_sys, or
# phase-buffer topology visibility.
# =============================================================================

puts "MPTDC_O13_ABS4_SDC_INFO: loading O13_ABS4_PD_VERNIER_CLASSIFICATION overlay"
puts "MPTDC_O13_ABS4_SDC_INFO: sourcing O13 abs3 clock/CDC repair overlay first"

set mptdc_o13_abs4_self ""
if {[info exists ::env(MPTDC_OSC_PD_SDC_OVERLAY)] && $::env(MPTDC_OSC_PD_SDC_OVERLAY) ne ""} {
    set mptdc_o13_abs4_self [file normalize $::env(MPTDC_OSC_PD_SDC_OVERLAY)]
} elseif {[info script] ne ""} {
    set mptdc_o13_abs4_self [file normalize [info script]]
}

if {$mptdc_o13_abs4_self eq ""} {
    error "MPTDC_O13_ABS4_SDC_FATAL: cannot determine abs4 overlay path"
}

set mptdc_o13_abs4_dir [file dirname $mptdc_o13_abs4_self]
set mptdc_o13_abs4_abs3_sdc [file join $mptdc_o13_abs4_dir mptdc_osc_typical_r750_delta5_o13_abs3.sdc]
if {![file exists $mptdc_o13_abs4_abs3_sdc]} {
    error "MPTDC_O13_ABS4_SDC_FATAL: missing required abs3 overlay: $mptdc_o13_abs4_abs3_sdc"
}
source $mptdc_o13_abs4_abs3_sdc

proc mptdc_o13_abs4_pin_collection {patterns} {
    set pins [list]
    foreach pattern $patterns {
        set found [list]
        catch {set found [get_pins -quiet -hierarchical $pattern]}
        foreach pin $found {
            if {[lsearch -exact $pins $pin] < 0} {
                lappend pins $pin
            }
        }
    }
    return $pins
}

proc mptdc_o13_abs4_q1_patterns {tap} {
    return [list \
        [format {*gen_pd_row[%d].gen_pd_col*.u_pd/q1_reg*/D} $tap] \
        [format {*gen_pd_row[%d]*gen_pd_col*u_pd*/q1_reg*/D} $tap] \
        [format {*gen_pd_row_%d__gen_pd_col*u_pd*/q1_reg*/D} $tap]]
}

proc mptdc_o13_abs4_first_matching_q1_pattern {tap} {
    foreach pattern [mptdc_o13_abs4_q1_patterns $tap] {
        set count [llength [get_pins -quiet -hierarchical $pattern]]
        if {$count > 0} {
            return [list $pattern $count]
        }
    }
    return [list "" 0]
}

set mptdc_o13_abs4_expected_vernier_endpoints 64
set mptdc_o13_abs4_source_clock_count 0
set mptdc_o13_abs4_q1_endpoint_count 0
set mptdc_o13_abs4_applied_endpoint_count 0
set mptdc_o13_abs4_apply_failures 0
set mptdc_o13_abs4_overmatch NO
set mptdc_o13_abs4_applied NO
set mptdc_o13_abs4_rows [list]

foreach tap {0 1 2 3 4 5 6 7} {
    set slow_clock_name [format {clk_osc_slow_buf_tap%d} $tap]
    set slow_clock_count [llength [get_clocks -quiet $slow_clock_name]]
    incr mptdc_o13_abs4_source_clock_count $slow_clock_count

    set pattern_and_count [mptdc_o13_abs4_first_matching_q1_pattern $tap]
    set q1_pattern [lindex $pattern_and_count 0]
    set q1_count [lindex $pattern_and_count 1]
    incr mptdc_o13_abs4_q1_endpoint_count $q1_count
    lappend mptdc_o13_abs4_rows [list $tap $slow_clock_name $slow_clock_count $q1_pattern $q1_count]
}

if {$mptdc_o13_abs4_source_clock_count != 8 || $mptdc_o13_abs4_q1_endpoint_count != $mptdc_o13_abs4_expected_vernier_endpoints} {
    set mptdc_o13_abs4_overmatch YES
    puts "MPTDC_O13_ABS4_SDC_WARN: PD Vernier exception not applied; expected 8 slow clocks and 64 q1 endpoints, found clocks=$mptdc_o13_abs4_source_clock_count endpoints=$mptdc_o13_abs4_q1_endpoint_count"
} else {
    foreach row $mptdc_o13_abs4_rows {
        set tap [lindex $row 0]
        set slow_clock_name [lindex $row 1]
        set q1_pattern [lindex $row 3]
        set q1_count [lindex $row 4]

        if {[catch {
            set_false_path \
                -from [get_clocks -quiet $slow_clock_name] \
                -to   [get_pins -quiet -hierarchical $q1_pattern]
        } err]} {
            incr mptdc_o13_abs4_apply_failures
            puts "MPTDC_O13_ABS4_SDC_WARN: failed PD Vernier false path for slow tap $tap: $err"
        } else {
            incr mptdc_o13_abs4_applied_endpoint_count $q1_count
        }
    }
    if {$mptdc_o13_abs4_apply_failures == 0 && $mptdc_o13_abs4_applied_endpoint_count == $mptdc_o13_abs4_expected_vernier_endpoints} {
        set mptdc_o13_abs4_applied YES
    }
}

puts "MPTDC_O13_ABS4_SDC_INFO: PD_VERNIER_EXCEPTION_ENDPOINTS_FOUND=$mptdc_o13_abs4_q1_endpoint_count"
puts "MPTDC_O13_ABS4_SDC_INFO: PD_VERNIER_EXCEPTION_EXPECTED=$mptdc_o13_abs4_expected_vernier_endpoints"
puts "MPTDC_O13_ABS4_SDC_INFO: PD_VERNIER_EXCEPTION_APPLIED=$mptdc_o13_abs4_applied"
puts "MPTDC_O13_ABS4_SDC_INFO: PD_VERNIER_EXCEPTION_OVERMATCH=$mptdc_o13_abs4_overmatch"
puts "MPTDC_O13_ABS4_SDC_INFO: PD_VERNIER_EXCEPTION_FAILURES=$mptdc_o13_abs4_apply_failures"

if {[info exists ::env(MPTDC_O13_PD_VERNIER_RPT)] && $::env(MPTDC_O13_PD_VERNIER_RPT) ne ""} {
    set fh [open $::env(MPTDC_O13_PD_VERNIER_RPT) w]
    puts $fh "# O13 abs4 PD Vernier Exception Check"
    puts $fh ""
    puts $fh "PD_VERNIER_EXCEPTION_ENDPOINTS_FOUND=$mptdc_o13_abs4_q1_endpoint_count"
    puts $fh "PD_VERNIER_EXCEPTION_EXPECTED=$mptdc_o13_abs4_expected_vernier_endpoints"
    puts $fh "PD_VERNIER_SOURCE_CLOCKS_FOUND=$mptdc_o13_abs4_source_clock_count"
    puts $fh "PD_VERNIER_EXCEPTION_APPLIED=$mptdc_o13_abs4_applied"
    puts $fh "PD_VERNIER_EXCEPTION_OVERMATCH=$mptdc_o13_abs4_overmatch"
    puts $fh "PD_VERNIER_EXCEPTION_FAILURES=$mptdc_o13_abs4_apply_failures"
    puts $fh ""
    puts $fh "## Per-row match"
    puts $fh "| slow_tap | slow_clock | clock_count | q1_pattern | q1_endpoint_count | status |"
    puts $fh "|---:|---|---:|---|---:|---|"
    foreach row $mptdc_o13_abs4_rows {
        set tap [lindex $row 0]
        set slow_clock_name [lindex $row 1]
        set slow_clock_count [lindex $row 2]
        set q1_pattern [lindex $row 3]
        set q1_count [lindex $row 4]
        set status "OK"
        if {$slow_clock_count != 1 || $q1_count != 8} {
            set status "REVIEW_REQUIRED"
        }
        puts $fh "| $tap | `$slow_clock_name` | $slow_clock_count | `$q1_pattern` | $q1_count | $status |"
    }
    puts $fh ""
    puts $fh "## Scope"
    puts $fh "- Cuts only buffered slow phase source clocks into same-row PD q1 sampler D pins."
    puts $fh "- Does not cut q1->q2, q1/q2->hit_latched, nfast_tag->timestamp, slow Johnson, clk_sys, or phase-buffer topology paths."
    puts $fh "- This is a measurement classification exception, not final signoff."
    close $fh
}
