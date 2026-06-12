# =============================================================================
# Stable MPTDC final-typical postroute optimization policy
# =============================================================================

if {[llength [info commands mptdc_pnr_env]] == 0} {
    proc mptdc_pnr_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_pnr_postroute_opt_enabled {} {
    return [mptdc_pnr_env MPTDC_RUN_POSTROUTE_OPT 1]
}

proc mptdc_pnr_phase_root_preserve_patterns {} {
    return [list \
        *u_phase_buf_slow*gen_phase_buf*.u_iso* \
        *u_phase_buf_slow*gen_phase_buf*.u_drv* \
        *u_phase_buf_fast*gen_phase_buf*.u_iso* \
        *u_phase_buf_fast*gen_phase_buf*.u_drv* \
    ]
}

proc mptdc_pnr_postroute_opt_forbidden_actions {} {
    return [list \
        {alter_raw_ro_nets} \
        {resize_or_replace_16_buhdx4_buhdx12_root_phase_drivers} \
        {add_cts_to_raw_ro_or_buffered_phase_clocks} \
        {break_o13_phase_buffer_topology} \
        {apply_global_design_drv_pressure_without_review} \
    ]
}

proc mptdc_pnr_apply_postroute_opt_protections {} {
    foreach pattern [mptdc_pnr_phase_root_preserve_patterns] {
        set cells [list]
        catch {set cells [get_cells -hierarchical $pattern]}
        if {[llength $cells] == 0} {
            continue
        }
        catch {set_dont_touch $cells true}
        catch {set_db $cells .dont_touch true}
    }
    return [mptdc_pnr_phase_root_preserve_patterns]
}

proc mptdc_pnr_write_postroute_opt_status {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_POSTROUTE_OPT_STATUS reports/postroute_opt_status.rpt]
    }
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "POSTROUTE_OPT_REQUESTED=[mptdc_pnr_postroute_opt_enabled]"
    puts $fh "POSTROUTE_OPT_STATUS=REVIEW_AFTER_INNOVUS"
    puts $fh "protected_patterns=[mptdc_pnr_phase_root_preserve_patterns]"
    puts $fh "forbidden_actions=[join [mptdc_pnr_postroute_opt_forbidden_actions] {; }]"
    close $fh
    return $path
}

proc mptdc_pnr_run_postroute_opt {} {
    if {![mptdc_pnr_postroute_opt_enabled]} {
        return SKIPPED
    }
    mptdc_pnr_apply_postroute_opt_protections
    if {[catch {optDesign -postRoute} err]} {
        return "FAILED:$err"
    }
    return COMPLETE
}
