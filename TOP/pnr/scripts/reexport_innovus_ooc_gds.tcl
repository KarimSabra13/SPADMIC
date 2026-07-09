# =============================================================================
# SPADMIC matrix-top -- restore checkpoint and re-export GDS with streamOut map
# =============================================================================

proc spadmic_reexport_env_required {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_REEXPORT_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc spadmic_reexport_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc spadmic_reexport_report_value {value} {
    regsub -all {\s+} $value { } compact
    return [string trim $compact]
}

proc spadmic_reexport_write_report {path lines} {
    set fh [open $path w]
    foreach line $lines {
        puts $fh $line
    }
    close $fh
}

set block_root [spadmic_reexport_env_required SPADMIC_REEXPORT_BLOCK_ROOT]
set top_module [spadmic_reexport_env_required SPADMIC_REEXPORT_TOP_MODULE]
set checkpoint [spadmic_reexport_env_required SPADMIC_REEXPORT_CHECKPOINT]
set out_gds [spadmic_reexport_env_required SPADMIC_REEXPORT_GDS]
set streamout_map [spadmic_reexport_env_required SPADMIC_REEXPORT_STREAMOUT_MAP]
set report [spadmic_reexport_env_required SPADMIC_REEXPORT_REPORT]
set backup [spadmic_reexport_env SPADMIC_REEXPORT_BACKUP ""]

file mkdir [file dirname $report] [file dirname $out_gds]

set base_lines [list \
    "LABEL=REEXPORT_GDS_WITH_STREAMOUT_MAP" \
    "BLOCK_ROOT=$block_root" \
    "TOP_MODULE=$top_module" \
    "CHECKPOINT=$checkpoint" \
    "OUTPUT_GDS=$out_gds" \
    "STREAMOUT_MAP_FILE=$streamout_map" \
    "PREVIOUS_GDS_BACKUP=$backup" \
    "NOTE=Restore checkpoint and streamOut only; no place, CTS, route, DRC repair, PVS, LVS, PEX, or MMMC was run." \
]

if {![file exists $checkpoint]} {
    spadmic_reexport_write_report $report [concat $base_lines [list \
        "STATUS=FAIL" \
        "REASON=checkpoint_missing" \
    ]]
    error "SPADMIC_REEXPORT_CHECKPOINT_MISSING: $checkpoint"
}

if {![file exists $streamout_map]} {
    spadmic_reexport_write_report $report [concat $base_lines [list \
        "STATUS=FAIL" \
        "REASON=streamout_map_missing" \
    ]]
    error "SPADMIC_REEXPORT_STREAMOUT_MAP_MISSING: $streamout_map"
}

if {[catch {restoreDesign $checkpoint $top_module} err]} {
    spadmic_reexport_write_report $report [concat $base_lines [list \
        "RESTORE_STATUS=FAIL" \
        "RESTORE_ERROR=[spadmic_reexport_report_value $err]" \
        "STATUS=FAIL" \
    ]]
    error "SPADMIC_REEXPORT_RESTORE_FAILED: $err"
}

set cmd [list streamOut $out_gds -libName DesignLib -units 1000 -mode ALL -mapFile $streamout_map]
if {[catch {uplevel #0 $cmd} err]} {
    spadmic_reexport_write_report $report [concat $base_lines [list \
        "RESTORE_STATUS=PASS" \
        "COMMAND=$cmd" \
        "STREAMOUT_STATUS=FAIL" \
        "STREAMOUT_ERROR=[spadmic_reexport_report_value $err]" \
        "STATUS=FAIL" \
    ]]
    error "SPADMIC_REEXPORT_STREAMOUT_FAILED: $err"
}

set gds_size 0
if {[file exists $out_gds]} {
    set gds_size [file size $out_gds]
}

set status FAIL
if {$gds_size > 0} {
    set status PASS
}

spadmic_reexport_write_report $report [concat $base_lines [list \
    "RESTORE_STATUS=PASS" \
    "COMMAND=$cmd" \
    "STREAMOUT_STATUS=PASS" \
    "OUTPUT_GDS_SIZE_BYTES=$gds_size" \
    "STATUS=$status" \
]]

if {$status ne "PASS"} {
    error "SPADMIC_REEXPORT_EMPTY_GDS: $out_gds"
}

exit
