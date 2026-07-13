# Capture installed Innovus command help without loading or modifying a design.

if {![info exists ::env(SPADMIC_INNOVUS_HELP_ROOT)] ||
    $::env(SPADMIC_INNOVUS_HELP_ROOT) eq ""} {
    error "SPADMIC_INNOVUS_HELP_ROOT is required"
}

set root $::env(SPADMIC_INNOVUS_HELP_ROOT)
set reports [file join $root reports]
file mkdir $reports
set commands {
    addStripe
    sroute
    editPowerVia
    setViaGenMode
    addPowerVia
    editAddVia
    editAddRoute
    addShape
    add_shape
    createShape
    create_shape
    setNanoRouteMode
    getNanoRouteMode
}
array set available {}

foreach command $commands {
    set report [file join $reports "man_${command}.rpt"]
    if {![catch {redirect -file $report [list man $command]} err]} {
        set available($command) MAN
        continue
    }
    if {![catch {redirect -file $report [list help $command]} help_err]} {
        set available($command) HELP
        continue
    }
    set available($command) UNAVAILABLE
    set fh [open $report w]
    puts $fh "MAN_ERROR=$err"
    puts $fh "HELP_ERROR=$help_err"
    close $fh
}

set status [file join $reports command_help_status.rpt]
set fh [open $status w]
puts $fh "LABEL=SPADMIC_INNOVUS_PG_COMMAND_HELP"
puts $fh "POLICY=NO_DESIGN_LOADED_NO_DESIGN_MODIFICATION"
foreach command $commands {
    puts $fh "COMMAND_${command}=$available($command)"
}
if {$available(addStripe) ne "UNAVAILABLE" &&
    $available(sroute) ne "UNAVAILABLE" &&
    $available(editPowerVia) ne "UNAVAILABLE" &&
    $available(setViaGenMode) ne "UNAVAILABLE"} {
    puts $fh "STATUS=PASS"
    puts $fh "RESULT=REQUIRED_COMMAND_HELP_CAPTURED"
    close $fh
    exit 0
}
puts $fh "STATUS=FAIL"
puts $fh "RESULT=REQUIRED_COMMAND_HELP_MISSING"
close $fh
exit 8
