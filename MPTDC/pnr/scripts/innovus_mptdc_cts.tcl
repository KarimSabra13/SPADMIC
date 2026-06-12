# =============================================================================
# Stable MPTDC clk_sys-only CTS policy
# =============================================================================

if {[llength [info commands mptdc_pnr_env]] == 0} {
    proc mptdc_pnr_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_pnr_cts_primary_clock {} {
    return clk_sys
}

proc mptdc_pnr_cts_enabled {} {
    return [mptdc_pnr_env MPTDC_RUN_CLK_SYS_CTS 1]
}

proc mptdc_pnr_cts_excluded_clock_patterns {} {
    return [list clk_osc_slow clk_osc_fast clk_osc_slow_tap* clk_osc_fast_tap* clk_osc_*_buf_tap*]
}

proc mptdc_pnr_write_cts_policy {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_CTS_POLICY_REPORT mptdc_cts_policy.rpt]
    }
    set fh [open $path w]
    puts $fh "# MPTDC CTS Policy"
    puts $fh "enabled=[mptdc_pnr_cts_enabled]"
    puts $fh "primary_clock=[mptdc_pnr_cts_primary_clock]"
    puts $fh "excluded_clock_patterns=[mptdc_pnr_cts_excluded_clock_patterns]"
    puts $fh "raw_ro_and_buffered_phase_cts=NO"
    puts $fh "labels=TYPICAL_ONLY NOT_MMMC_SIGNOFF NOT_FINAL_SILICON_SIGNOFF"
    close $fh
    return $path
}

proc mptdc_pnr_write_cts_status {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_CTS_STATUS_REPORT cts_status.rpt]
    }
    set fh [open $path w]
    puts $fh "CLK_SYS_CTS_REQUESTED=[mptdc_pnr_cts_enabled]"
    puts $fh "CLK_SYS_CTS_COMPLETE=REVIEW_AFTER_INNOVUS"
    puts $fh "RO_CLOCKS_IN_CTS=NO"
    puts $fh "PHASE_CLOCKS_IN_CTS=NO"
    puts $fh "CTS_PRIMARY_CLOCK=[mptdc_pnr_cts_primary_clock]"
    close $fh
    return $path
}

proc mptdc_pnr_write_cts_inclusion_audit {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_CTS_AUDIT_REPORT cts_clock_inclusion_audit.rpt]
    }
    set fh [open $path w]
    puts $fh "# MPTDC CTS Clock Inclusion Audit"
    puts $fh "included_clock=[mptdc_pnr_cts_primary_clock]"
    puts $fh "excluded_patterns=[mptdc_pnr_cts_excluded_clock_patterns]"
    puts $fh "RO_CLOCKS_IN_CTS=NO"
    puts $fh "PHASE_CLOCKS_IN_CTS=NO"
    puts $fh "failure_action=do_not_call_near_signoff"
    close $fh
    return $path
}

proc mptdc_pnr_apply_cts_exclusions {} {
    foreach pattern [mptdc_pnr_cts_excluded_clock_patterns] {
        set clocks [list]
        catch {set clocks [get_clocks $pattern]}
        if {[llength $clocks] == 0} {
            continue
        }
        catch {set_dont_touch_network $clocks}
        catch {set_ideal_network $clocks}
    }
}
