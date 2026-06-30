# =============================================================================
# Project  : SPAD_MPTDC
# File     : probe_mptdc_ro_pg_checkpoint.tcl
# Purpose  : Read-only RO PG topology probe for a saved Innovus checkpoint
# =============================================================================

proc mptdc_ro_pg_probe_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

set repo_root [file normalize [mptdc_ro_pg_probe_env MPTDC_REPO_ROOT [file join [file dirname [info script]] ../../..]]]
set ckpt [mptdc_ro_pg_probe_env CKPT [mptdc_ro_pg_probe_env MPTDC_RO_PG_PROBE_CKPT ""]]
set outdir [file normalize [mptdc_ro_pg_probe_env OUTDIR [mptdc_ro_pg_probe_env MPTDC_RO_PG_PROBE_OUTDIR /tmp/mptdc_ro_pg_probe]]]
set top_cell [mptdc_ro_pg_probe_env TOP_CELL [mptdc_ro_pg_probe_env MPTDC_TOP_CELL mptdc_axis_core]]

if {$ckpt eq "" || ![file exists $ckpt]} {
    puts "MPTDC_RO_PG_PROBE_ERROR=missing_checkpoint"
    puts "MPTDC_RO_PG_PROBE_CKPT=$ckpt"
    exit 1
}

set ::env(MPTDC_REPO_ROOT) $repo_root
set ::env(MPTDC_SIGNOFF_RESULT_DIR) $outdir
set ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY) 1
source [file join $repo_root MPTDC/pnr/scripts/innovus_mptdc_digital_signoff.tcl]

file mkdir [file join $outdir reports]
mptdc_signoff_apply_recovery_defaults
mptdc_signoff_mkdirs
catch {set_db get_db_display_limit [mptdc_signoff_env_int MPTDC_DB_DISPLAY_LIMIT 50000]}

restoreDesign $ckpt $top_cell

set probe_rpt [mptdc_signoff_ro_pg_probe \
    [file join [mptdc_signoff_report_dir] ro_pg_checkpoint_probe.rpt] \
    CHECKPOINT_RO_PG_PROBE]
set topology_rpt [mptdc_signoff_dump_pg_topology \
    [file join [mptdc_signoff_report_dir] ro_pg_checkpoint_topology.rpt] \
    CHECKPOINT_RO_PG_TOPOLOGY]
set verify_rpt [file join [mptdc_signoff_report_dir] ro_pg_checkpoint_verify_special.rpt]
set verify_console [file join [mptdc_signoff_report_dir] ro_pg_checkpoint_verify_special.console.rpt]

if {[catch {uplevel #0 "verifyConnectivity -type special -nets {VDD VSS} -report \"$verify_rpt\" > \"$verify_console\""} err]} {
    set verify_status FAIL
    set verify_error $err
} else {
    set verify_status PASS
    set verify_error ""
}

puts "MPTDC_RO_PG_PROBE_STATUS=PASS"
puts "MPTDC_RO_PG_PROBE_CKPT=$ckpt"
puts "MPTDC_RO_PG_PROBE_OUTDIR=$outdir"
puts "MPTDC_RO_PG_PROBE_REPORT=$probe_rpt"
puts "MPTDC_RO_PG_TOPOLOGY_REPORT=$topology_rpt"
puts "MPTDC_RO_PG_VERIFY_SPECIAL_REPORT=$verify_rpt"
puts "MPTDC_RO_PG_VERIFY_SPECIAL_STATUS=$verify_status"
if {$verify_error ne ""} {
    puts "MPTDC_RO_PG_VERIFY_SPECIAL_ERROR=[mptdc_signoff_report_value $verify_error]"
}

exit
