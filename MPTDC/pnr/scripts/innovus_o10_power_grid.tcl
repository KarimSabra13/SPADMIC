# =============================================================================
# O10/O10.2 dry-run power grid and connectivity
# =============================================================================

if {[llength [info commands mptdc_o10_env]] == 0} {
    proc mptdc_o10_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_o10_power_enabled {} {
    return [mptdc_o10_env MPTDC_PNR_BUILD_POWER_GRID 1]
}

proc mptdc_o10_power_nets {} {
    return [list VDD VSS]
}

proc mptdc_o10_power_try {fh label cmd} {
    puts $fh ""
    puts $fh "## $label"
    puts $fh "command=$cmd"
    if {![catch {{*}$cmd} err]} {
        puts $fh "status=OK"
        return 1
    }
    puts $fh "status=FAILED"
    puts $fh "reason=$err"
    return 0
}

proc mptdc_o10_apply_power_plan {} {
    global o10 tech
    file mkdir $o10(reports_dir)

    set intent "$o10(reports_dir)/power_intent.rpt"
    set status "$o10(reports_dir)/power_grid_status.rpt"
    set connectivity "$o10(reports_dir)/power_connectivity.rpt"
    set nets [mptdc_o10_power_nets]
    set enabled [mptdc_o10_power_enabled]

    set fh [open $intent w]
    puts $fh "# O10.2 Power Intent"
    puts $fh "POWER_NET=VDD"
    puts $fh "GROUND_NET=VSS"
    puts $fh "NOMINAL_VOLTAGE=1.8"
    puts $fh "RO_TUNE4_VDD=VDD"
    puts $fh "RO_TUNE4_VDD_BANG=VDD"
    puts $fh "RO_TUNE4_VSS=VSS"
    puts $fh "BUILD_POWER_GRID=$enabled"
    puts $fh "FINAL_EM_IR_SIGNOFF=NO"
    close $fh

    foreach cmd [list \
        [list globalNetConnect $tech(STANDARD_CELL_VDD) -type pgpin -pin vdd -inst *] \
        [list globalNetConnect $tech(STANDARD_CELL_GND) -type pgpin -pin gnd -inst *] \
        [list globalNetConnect $tech(STANDARD_CELL_VDD) -type pgpin -pin VDD -inst *] \
        [list globalNetConnect $tech(STANDARD_CELL_GND) -type pgpin -pin VSS -inst *] \
    ] {
        catch {{*}$cmd}
    }

    set fh [open $status w]
    puts $fh "# O10.2 Power Grid Status"
    puts $fh ""
    puts $fh "BUILD_POWER_GRID=$enabled"
    puts $fh "POWER_NETS=$nets"
    puts $fh "SIGNOFF_EM_IR=NO"

    set ring_ok 0
    set stripe_ok 0
    set sroute_ok 0
    if {$enabled} {
        foreach cmd [list \
            [list addRing -nets $nets -type core_rings -follow core -layer {top MET3 bottom MET3 left METTP right METTP} -width {top 2 bottom 2 left 2 right 2} -spacing {top 1 bottom 1 left 1 right 1} -offset {top 2 bottom 2 left 2 right 2}] \
            [list addRing -nets $nets -follow core -layer {top MET3 bottom MET3 left METTP right METTP} -width 2 -spacing 1 -offset 2] \
            [list addRing -nets $nets -type core_rings -layer {top MET3 bottom MET3 left METTP right METTP} -width 2 -spacing 1 -offset 2] \
        ] {
            if {[mptdc_o10_power_try $fh addRing $cmd]} {
                set ring_ok 1
                break
            }
        }
        foreach cmd [list \
            [list addStripe -nets $nets -layer METTP -direction vertical -width 2 -spacing 2 -set_to_set_distance 80 -start_from left -start_offset 20] \
            [list addStripe -nets $nets -layer MET3 -direction horizontal -width 2 -spacing 2 -set_to_set_distance 80 -start_from bottom -start_offset 20] \
        ] {
            if {[mptdc_o10_power_try $fh addStripe $cmd]} {
                set stripe_ok 1
            }
        }
        foreach cmd [list \
            [list sroute -connect {corePin blockPin padPin} -nets $nets] \
            [list sroute -nets $nets] \
        ] {
            if {[mptdc_o10_power_try $fh sroute $cmd]} {
                set sroute_ok 1
                break
            }
        }
    }

    puts $fh ""
    puts $fh "RING_CREATED=$ring_ok"
    puts $fh "STRIPE_CREATED=$stripe_ok"
    puts $fh "SROUTE_DONE=$sroute_ok"
    if {!$enabled || ($ring_ok && $sroute_ok)} {
        puts $fh "POWER_GRID_STATUS=OK"
    } else {
        puts $fh "POWER_GRID_STATUS=FAILED"
    }
    close $fh

    set fh [open $connectivity w]
    puts $fh "# O10.2 Power Connectivity"
    puts $fh ""
    puts $fh "POWER_NET=VDD"
    puts $fh "GROUND_NET=VSS"
    puts $fh "STANDARD_CELL_VDD_PINS=$tech(STANDARD_CELL_VDD_PINS)"
    puts $fh "STANDARD_CELL_GND_PINS=$tech(STANDARD_CELL_GND_PINS)"
    puts $fh "RO_POWER_PIN_MAP=VDD->VDD VSS->VSS"
    close $fh

    foreach report_cmd [list \
        {verifyConnectivity -type special} \
        {verifyConnectivity} \
        {report_power} \
    ] {
        set fh [open $connectivity a]
        puts $fh ""
        puts $fh "## COMMAND: $report_cmd"
        close $fh
        if {[catch {eval "$report_cmd >> \"$connectivity\""} err]} {
            set fh [open $connectivity a]
            puts $fh "FAILED_COMMAND=$report_cmd"
            puts $fh "FAILED_REASON=$err"
            close $fh
        }
    }

    return $status
}
