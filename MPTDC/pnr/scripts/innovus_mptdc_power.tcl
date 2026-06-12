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
    return [dict create VDD VDD vdd! VDD VSS VSS]
}

proc mptdc_pnr_power_rules {} {
    return [list \
        {digital_domain_uses_1p8v_vdd_vss} \
        {ro_tune4_vdd_uses_vdd_1p8v} \
        {ro_tune4_vdd_bang_connects_to_vdd} \
        {ro_tune4_vss_connects_to_vss} \
        {do_not_connect_ro_tune4_to_vdda_3p3v} \
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
    foreach cmd [list \
        [list globalNetConnect $power -type pgpin -pin vdd -inst *] \
        [list globalNetConnect $ground -type pgpin -pin gnd -inst *] \
        [list globalNetConnect $power -type pgpin -pin VDD -inst *] \
        [list globalNetConnect $power -type pgpin -pin vdd! -inst *] \
        [list globalNetConnect $ground -type pgpin -pin VSS -inst *] \
    ] {
        catch {{*}$cmd}
    }
}
