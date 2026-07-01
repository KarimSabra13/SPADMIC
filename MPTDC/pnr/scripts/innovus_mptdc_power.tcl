# =============================================================================
# Stable MPTDC final-typical power intent
# =============================================================================

if {[llength [info commands mptdc_pnr_env]] == 0} {
    proc mptdc_pnr_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_pnr_power_nets {} {
    return [dict create power VDD ground VSS voltage 1.8]
}

proc mptdc_pnr_ro_power_pin_map {} {
    return [dict create VDD VDD VSS VSS]
}

proc mptdc_pnr_unique_append {var_name value} {
    upvar 1 $var_name values
    if {$value eq ""} { return }
    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}

proc mptdc_pnr_object_names {objects} {
    set names [list]
    if {[llength $objects] == 0} {
        return $names
    }
    if {![catch {get_object_name $objects} obj_names]} {
        foreach name $obj_names {
            mptdc_pnr_unique_append names "$name"
        }
        return $names
    }
    if {![catch {get_db $objects .name} obj_names]} {
        foreach name $obj_names {
            mptdc_pnr_unique_append names "$name"
        }
        return $names
    }
    foreach obj $objects {
        mptdc_pnr_unique_append names "$obj"
    }
    return $names
}

proc mptdc_pnr_ro_macro_name {} {
    return [mptdc_pnr_env O1_RO_CELL_NAME RO_tune6]
}

proc mptdc_pnr_collect_ro_instances {} {
    set out [list]
    set macro [mptdc_pnr_ro_macro_name]
    foreach pattern [list *u_ro_tune4* *$macro*] {
        set cells [list]
        catch {set cells [get_cells -quiet -hierarchical $pattern]}
        foreach name [mptdc_pnr_object_names $cells] {
            mptdc_pnr_unique_append out $name
        }
    }
    return $out
}

proc mptdc_pnr_stdcell_power_pins {} {
    set repo_root [file normalize [mptdc_pnr_env MPTDC_REPO_ROOT [file join [file dirname [info script]] ../../..]]]
    set cfg [file join $repo_root MPTDC/pnr/config/xh018_cells.tcl]
    if {[file exists $cfg]} {
        source $cfg
        set pins [mptdc_xh018_cell_list stdcell_pg_power]
        if {[llength $pins] > 0} {
            return $pins
        }
    }
    return [list vddi]
}

proc mptdc_pnr_stdcell_ground_pins {} {
    set repo_root [file normalize [mptdc_pnr_env MPTDC_REPO_ROOT [file join [file dirname [info script]] ../../..]]]
    set cfg [file join $repo_root MPTDC/pnr/config/xh018_cells.tcl]
    if {[file exists $cfg]} {
        source $cfg
        set pins [mptdc_xh018_cell_list stdcell_pg_ground]
        if {[llength $pins] > 0} {
            return $pins
        }
    }
    return [list gndi]
}

proc mptdc_pnr_power_rules {} {
    return [list \
        {digital_domain_uses_1p8v_vdd_vss} \
        {ro_tune6_vdd_uses_vdd_1p8v} \
        {ro_tune6_vdd_bang_is_merged_into_vdd_and_not_exported} \
        {ro_tune6_vss_connects_to_vss} \
        {do_not_connect_ro_tune6_to_vdda_3p3v} \
        {report_unconnected_pg_pins} \
    ]
}

proc mptdc_pnr_write_power_intent {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_POWER_REPORT mptdc_power_intent.rpt]
    }
    set fh [open $path w]
    puts $fh "# MPTDC Power Intent"
    dict for {key value} [mptdc_pnr_power_nets] {
        puts $fh "$key=$value"
    }
    puts $fh "stdcell_power_pins=[mptdc_pnr_stdcell_power_pins]"
    puts $fh "stdcell_ground_pins=[mptdc_pnr_stdcell_ground_pins]"
    puts $fh "ro_pin_map=[mptdc_pnr_ro_power_pin_map]"
    puts $fh "rules=[join [mptdc_pnr_power_rules] {; }]"
    puts $fh "required_reports=power_connectivity.rpt power_intent.rpt unconnected_pg_pins.rpt"
    puts $fh "hard_stop_if_lef_or_analog_contradicts=YES"
    puts $fh "final_em_ir_signoff=NO"
    close $fh
    return $path
}

proc mptdc_pnr_apply_power_connectivity {} {
    set nets [mptdc_pnr_power_nets]
    set power [dict get $nets power]
    set ground [dict get $nets ground]
    set report [mptdc_pnr_env MPTDC_PNR_POWER_CONNECTIVITY_REPORT power_connectivity.rpt]
    file mkdir [file dirname $report]
    set fh [open $report w]
    set failures [list]
    set commands [list]
    foreach pg_pin [mptdc_pnr_stdcell_power_pins] {
        lappend commands [list globalNetConnect $power -type pgpin -pin $pg_pin -inst *]
    }
    foreach pg_pin [mptdc_pnr_stdcell_ground_pins] {
        lappend commands [list globalNetConnect $ground -type pgpin -pin $pg_pin -inst *]
    }
    set ro_macro [mptdc_pnr_ro_macro_name]
    set ro_instances [mptdc_pnr_collect_ro_instances]
    puts $fh "RO_MACRO=$ro_macro"
    puts $fh "RO_TUNE6_INSTANCE_COUNT=[llength $ro_instances]"
    foreach ro $ro_instances {
        puts $fh "RO_TUNE6_INSTANCE=$ro"
    }
    if {[llength $ro_instances] != 2} {
        puts $fh "STATUS=FAIL ERROR=expected_exactly_two_ro_tune6_instances"
        close $fh
        error "MPTDC_PNR_POWER_CONNECTIVITY_FAILED: expected exactly 2 $ro_macro instances, found [llength $ro_instances]"
    }
    foreach ro $ro_instances {
        foreach {pin net} [mptdc_pnr_ro_power_pin_map] {
            lappend commands [list globalNetConnect $net -type pgpin -pin $pin -inst $ro]
        }
    }
    foreach cmd $commands {
        puts $fh "COMMAND=$cmd"
        if {[catch {{*}$cmd} err]} {
            puts $fh "STATUS=FAIL ERROR=$err"
            lappend failures "$cmd: $err"
        } else {
            puts $fh "STATUS=PASS"
        }
    }
    close $fh
    if {[llength $failures] > 0} {
        error "MPTDC_PNR_POWER_CONNECTIVITY_FAILED: $failures"
    }
    return $report
}
