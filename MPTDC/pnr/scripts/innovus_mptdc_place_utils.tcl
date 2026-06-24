# =============================================================================
# Shared Innovus placement helpers
# =============================================================================

proc mptdc_pnr_place_env_truthy {name {default_value 0}} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        set value [string tolower $::env($name)]
    } else {
        set value [string tolower $default_value]
    }
    return [expr {$value in {1 yes true on}}]
}

proc mptdc_pnr_place_unique_cmd {var_name cmd} {
    upvar 1 $var_name cmds
    foreach existing $cmds {
        if {$existing eq $cmd} {
            return
        }
    }
    lappend cmds $cmd
}

proc mptdc_pnr_place_mark_fixed {inst} {
    set errors [list]
    foreach cmd [list \
        [list setInstancePlacementStatus -status fixed -name $inst] \
        [list set_db [list $inst] .place_status fixed]] {
        if {![catch {uplevel 1 $cmd} err]} {
            return [dict create status PASS command $cmd errors $errors]
        }
        lappend errors "$cmd: $err"
    }

    set ptr ""
    if {![catch {set ptr [dbGet top.insts.name $inst -p]} err] && $ptr ne "" && $ptr ne "0x0"} {
        if {![catch {dbSet ${ptr}.pStatus fixed} err2]} {
            return [dict create status PASS command [list dbSet ${ptr}.pStatus fixed] errors $errors]
        }
        lappend errors "dbSet ${ptr}.pStatus fixed: $err2"
    } else {
        lappend errors "dbGet top.insts.name $inst -p: $err"
    }

    return [dict create status REVIEW_REQUIRED command "" errors $errors]
}

proc mptdc_pnr_place_orient_candidates {orient} {
    set orient [string toupper [string trim $orient]]
    if {$orient eq ""} { set orient AUTO }

    set fallback [list MY R0 MX R180]
    if {[info exists ::env(MPTDC_PNR_ROW_LEGAL_ORIENT_CANDIDATES)] && \
        $::env(MPTDC_PNR_ROW_LEGAL_ORIENT_CANDIDATES) ne ""} {
        set fallback [list]
        foreach item $::env(MPTDC_PNR_ROW_LEGAL_ORIENT_CANDIDATES) {
            set item [string toupper [string trim $item]]
            if {$item ne ""} { lappend fallback $item }
        }
    }

    if {$orient in {AUTO ROW ROW_LEGAL LEGAL}} {
        return $fallback
    }

    set candidates [list $orient]
    foreach item $fallback {
        if {$item ni $candidates} {
            lappend candidates $item
        }
    }
    return $candidates
}

proc mptdc_pnr_place_instance_row_legal {inst x y {orient AUTO} {fixed 0}} {
    set orient [string toupper [string trim $orient]]
    if {$orient eq ""} { set orient AUTO }
    set fixed [expr {$fixed ? 1 : 0}]

    set cmds [list]
    foreach alt [mptdc_pnr_place_orient_candidates $orient] {
        mptdc_pnr_place_unique_cmd cmds [list placeInstance $inst $x $y $alt]
    }
    if {$orient ni {AUTO ROW ROW_LEGAL LEGAL}} {
        mptdc_pnr_place_unique_cmd cmds [list placeInstance $inst $x $y]
    }

    set errors [list]
    foreach cmd $cmds {
        if {[catch {uplevel 1 $cmd} err]} {
            lappend errors "$cmd: $err"
            continue
        }
        set fixed_status SKIPPED
        set fixed_command ""
        set fixed_errors [list]
        if {$fixed} {
            set fixed_result [mptdc_pnr_place_mark_fixed $inst]
            set fixed_status [dict get $fixed_result status]
            set fixed_command [dict get $fixed_result command]
            set fixed_errors [dict get $fixed_result errors]
        }
        return [dict create \
            status PASS \
            command $cmd \
            fixed_status $fixed_status \
            fixed_command $fixed_command \
            fixed_errors $fixed_errors \
            errors $errors]
    }

    return [dict create \
        status FAIL \
        command "" \
        fixed_status SKIPPED \
        fixed_command "" \
        fixed_errors [list] \
        errors $errors]
}
