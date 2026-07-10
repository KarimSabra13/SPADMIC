# Create route blockages from the read-only SPADMIC2 layout audit. Macro
# placement overlap is rejected by the Python preflight before this file runs.

proc spadmic_da_apply_blockages {} {
    if {![info exists ::SPADMIC_DA_OBSTACLES]} {
        error "SPADMIC_DA_OBSTACLES_NOT_DEFINED"
    }
    set report [open [file join $::spadmic_da_reports_dir assembly_blockages.rpt] w]
    puts $report "LABEL=SPADMIC_DIGITAL_ASSEMBLY_BLOCKAGES"
    set count 0
    foreach record $::SPADMIC_DA_OBSTACLES {
        lassign $record name kind box layers
        set safe_name [regsub -all {[^A-Za-z0-9_]} $name {_}]
        foreach layer $layers {
            set blockage_name "DA_${safe_name}_${layer}"
            set commands [list \
                [list createRouteBlk -name $blockage_name -layer $layer -box $box] \
                [list createRouteBlk -name $blockage_name -layer $layer -rect $box]]
            set applied 0
            foreach command $commands {
                if {![catch {uplevel #0 $command} err]} {
                    puts $report "PASS=$command"
                    set applied 1
                    incr count
                    break
                }
                puts $report "TRY_FAIL=$command error=$err"
            }
            if {!$applied} {
                close $report
                error "SPADMIC_DA_ROUTE_BLOCKAGE_FAILED: $blockage_name"
            }
        }
    }
    puts $report "BLOCKAGE_COUNT=$count"
    puts $report "STATUS=PASS"
    close $report
}
