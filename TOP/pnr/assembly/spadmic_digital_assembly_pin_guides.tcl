# Place Phase-A handoff pins directly over their owning macro terminal. These
# pins expose digital-to-external interfaces without routing into analog/macro
# obstacles. The 19 packet-to-strip nets remain internal and are not listed.

proc spadmic_da_apply_proxy_pins {} {
    if {![info exists ::SPADMIC_DA_PROXY_PINS]} {
        error "SPADMIC_DA_PROXY_PINS_NOT_DEFINED"
    }
    set report [open [file join $::spadmic_da_reports_dir assembly_proxy_pins.rpt] w]
    puts $report "LABEL=SPADMIC_DIGITAL_ASSEMBLY_PROXY_PINS"
    set count 0
    foreach record $::SPADMIC_DA_PROXY_PINS {
        lassign $record pin x y layer width depth owner
        set commands [list \
            [list editPin -pin $pin -assign $x $y -layer $layer -pinWidth $width -pinDepth $depth -fixedPin 1] \
            [list editPin -pin $pin -assign [list $x $y] -layer $layer -pinWidth $width -pinDepth $depth -fixedPin 1]]
        set applied 0
        foreach command $commands {
            if {![catch {uplevel #0 $command} err]} {
                puts $report "PASS=$command owner=$owner"
                set applied 1
                incr count
                break
            }
            puts $report "TRY_FAIL=$command error=$err"
        }
        if {!$applied} {
            close $report
            error "SPADMIC_DA_PROXY_PIN_FAILED: $pin"
        }
    }
    puts $report "PIN_COUNT=$count"
    puts $report "STATUS=PASS"
    close $report
}
