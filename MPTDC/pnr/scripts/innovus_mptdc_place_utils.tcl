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

proc mptdc_pnr_place_db_ptr {inst} {
    set ptr ""
    catch {set ptr [dbGet top.insts.name $inst -p]}
    if {$ptr eq "" || $ptr eq "0x0" || $ptr eq "NULL"} {
        return ""
    }
    return $ptr
}

proc mptdc_pnr_place_query_attr {inst attrs} {
    set ptr [mptdc_pnr_place_db_ptr $inst]
    foreach attr $attrs {
        if {$ptr ne "" && ![catch {set value [dbGet ${ptr}.${attr}]}] && $value ne "" && $value ne "0x0"} {
            return $value
        }
        if {![catch {set value [get_db inst:$inst .$attr]}] && $value ne "" && $value ne "0x0"} {
            return $value
        }
    }
    return UNKNOWN
}

proc mptdc_pnr_place_status_is_placed {status} {
    set value [string tolower [string trim $status]]
    return [expr {$value in {placed fixed cover softfixed soft_fixed}}]
}

proc mptdc_pnr_place_status_is_fixed {status} {
    set value [string tolower [string trim $status]]
    return [expr {$value in {fixed cover}}]
}

proc mptdc_pnr_place_postcheck {inst requested_x requested_y requested_orient fixed} {
    set errors [list]
    set actual_status [mptdc_pnr_place_query_attr $inst {pStatus place_status status}]
    set actual_orient [mptdc_pnr_place_query_attr $inst {orient orientation}]
    set actual_origin [mptdc_pnr_place_query_attr $inst {pt origin location}]
    set actual_box [mptdc_pnr_place_query_attr $inst {box bbox}]

    if {$actual_status eq "UNKNOWN"} {
        lappend errors "actual placement status unavailable"
    } elseif {![mptdc_pnr_place_status_is_placed $actual_status]} {
        lappend errors "instance not placed after placeInstance: actual_status=$actual_status"
    }

    if {$fixed && $actual_status ne "UNKNOWN" && ![mptdc_pnr_place_status_is_fixed $actual_status]} {
        lappend errors "fixed placement requested but actual_status=$actual_status"
    }

    set orient_request [string toupper [string trim $requested_orient]]
    if {$orient_request ne "" && $orient_request ni {AUTO ROW ROW_LEGAL LEGAL} && $actual_orient ne "UNKNOWN"} {
        set allowed [mptdc_pnr_place_orient_candidates $orient_request]
        if {[string toupper $actual_orient] ni $allowed} {
            lappend errors "actual orientation $actual_orient not in requested candidates $allowed"
        }
    }

    return [dict create \
        status [expr {[llength $errors] == 0 ? "PASS" : "FAIL"}] \
        actual_status $actual_status \
        actual_orient $actual_orient \
        actual_origin $actual_origin \
        actual_box $actual_box \
        requested_origin [list $requested_x $requested_y] \
        errors $errors]
}

proc mptdc_pnr_place_orient_candidates {orient} {
    set orient [string toupper [string trim $orient]]
    if {$orient eq ""} { set orient AUTO }

    # Prefer the orientations that have been legal on the XH018 JIHD rows in
    # recent Innovus runs.  Keep the older candidates as fallbacks because row
    # orientation can alternate after floorplan changes.
    set fallback [list MX R180 MY R0]
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
        set postcheck [mptdc_pnr_place_postcheck $inst $x $y $alt $fixed]
        if {[dict get $postcheck status] ne "PASS"} {
            lappend errors "$cmd postcheck failed: [dict get $postcheck errors]"
            continue
        }
        return [dict create \
            status PASS \
            command $cmd \
            fixed_status $fixed_status \
            fixed_command $fixed_command \
            fixed_errors $fixed_errors \
            postcheck_status [dict get $postcheck status] \
            actual_status [dict get $postcheck actual_status] \
            actual_orient [dict get $postcheck actual_orient] \
            actual_origin [dict get $postcheck actual_origin] \
            actual_box [dict get $postcheck actual_box] \
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
