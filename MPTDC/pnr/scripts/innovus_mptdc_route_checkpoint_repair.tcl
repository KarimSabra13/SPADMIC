# =============================================================================
# Project  : SPAD_MPTDC
# File     : innovus_mptdc_route_checkpoint_repair.tcl
# Purpose  : Restore an Innovus route checkpoint, run targeted repair commands,
#            and capture DRC/connectivity evidence without a full rerun.
# =============================================================================

proc mptdc_ckpt_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_ckpt_required_env {name} {
    set value [mptdc_ckpt_env $name ""]
    if {$value eq ""} {
        error "missing required environment variable $name"
    }
    return $value
}

proc mptdc_ckpt_write_text {path text} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts -nonewline $fh $text
    close $fh
}

proc mptdc_ckpt_sanitize {value} {
    regsub -all {[^[:alnum:]_./:+-]+} $value {_} safe
    set safe [string trim $safe _]
    if {$safe eq ""} {
        set safe command
    }
    return $safe
}

proc mptdc_ckpt_capture {label command path} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "# $label"
    puts $fh "COMMAND=$command"
    close $fh
    if {[catch {uplevel #0 "$command >> \"$path\""} err opts]} {
        set fh [open $path a]
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh "ERROR=$err"
        if {[dict exists $opts -errorcode]} {
            puts $fh "ERRORCODE=[dict get $opts -errorcode]"
        }
        if {[dict exists $opts -errorinfo]} {
            puts $fh "ERRORINFO_BEGIN"
            puts $fh [dict get $opts -errorinfo]
            puts $fh "ERRORINFO_END"
        }
        close $fh
        return [list 0 $err]
    }
    set fh [open $path a]
    puts $fh "REPORT_STATUS=PASS"
    close $fh
    return [list 1 ""]
}

proc mptdc_ckpt_command_file_commands {path} {
    if {$path eq ""} {
        return {}
    }
    set fh [open $path r]
    set text [read $fh]
    close $fh
    set commands {}
    foreach line [split $text "\n"] {
        set trimmed [string trim $line]
        if {$trimmed eq ""} {
            continue
        }
        if {[string index $trimmed 0] eq "#"} {
            continue
        }
        lappend commands $trimmed
    }
    return $commands
}

proc mptdc_ckpt_env_commands {} {
    set raw [mptdc_ckpt_env MPTDC_CHECKPOINT_REPAIR_COMMANDS ""]
    if {$raw eq ""} {
        return {}
    }
    if {![catch {llength $raw}]} {
        return $raw
    }
    return [list $raw]
}

proc mptdc_ckpt_verify_snapshot {tag} {
    set report_dir [mptdc_signoff_report_dir]
    set drc_rpt [file join $report_dir ${tag}_verify_drc.rpt]
    set regular_rpt [file join $report_dir ${tag}_verify_connectivity_regular.rpt]
    set special_rpt [file join $report_dir ${tag}_verify_connectivity_special.rpt]
    set marker_rpt [file join $report_dir ${tag}_drc_markers.tsv]
    mptdc_ckpt_capture "$tag verify_drc" {verify_drc} $drc_rpt
    mptdc_signoff_dump_drc_markers $marker_rpt
    mptdc_ckpt_capture "$tag regular connectivity" {verifyConnectivity -type regular} $regular_rpt
    mptdc_ckpt_capture "$tag special connectivity" {verifyConnectivity -type special -nets {VDD VSS}} $special_rpt
    set parsed [mptdc_signoff_parse_verify_drc_report $drc_rpt]
    return [list $drc_rpt $marker_rpt [dict get $parsed total_violations] [dict get $parsed shorts]]
}

if {[mptdc_ckpt_env MPTDC_CHECKPOINT_REPAIR_SOURCE_ONLY 0]} {
    return
}

set source_checkpoint [mptdc_ckpt_required_env MPTDC_CHECKPOINT_REPAIR_SOURCE_CHECKPOINT]
set result_dir [mptdc_ckpt_required_env MPTDC_SIGNOFF_RESULT_DIR]
set top_cell [mptdc_ckpt_env MPTDC_CHECKPOINT_REPAIR_TOP mptdc_axis_core]
set commands_file [mptdc_ckpt_env MPTDC_CHECKPOINT_REPAIR_COMMANDS_FILE ""]
set repo_root [file normalize [mptdc_ckpt_env MPTDC_REPO_ROOT [file join [file dirname [info script]] ../../..]]]

file mkdir $result_dir
set ::env(MPTDC_REPO_ROOT) $repo_root
set ::env(MPTDC_DIGITAL_SIGNOFF_LIBRARY_ONLY) 1
source [file join [file dirname [info script]] innovus_mptdc_digital_signoff.tcl]
mptdc_signoff_mkdirs

set status_rpt [file join [mptdc_signoff_report_dir] checkpoint_repair_status.rpt]
set status_fh [open $status_rpt w]
puts $status_fh "# MPTDC Route Checkpoint Repair"
puts $status_fh "SOURCE_CHECKPOINT=$source_checkpoint"
puts $status_fh "RESULT_DIR=$result_dir"
puts $status_fh "TOP_CELL=$top_cell"
puts $status_fh "COMMANDS_FILE=$commands_file"
flush $status_fh

if {![file exists $source_checkpoint]} {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=FAIL"
    puts $status_fh "CHECKPOINT_REPAIR_REASON=missing_source_checkpoint"
    close $status_fh
    error "missing source checkpoint: $source_checkpoint"
}

puts "MPTDC_CHECKPOINT_REPAIR_RESTORE=$source_checkpoint"
restoreDesign $source_checkpoint $top_cell
catch {set_db get_db_display_limit 50000}

set command_list [mptdc_ckpt_command_file_commands $commands_file]
foreach cmd [mptdc_ckpt_env_commands] {
    lappend command_list $cmd
}
if {[llength $command_list] == 0} {
    lappend command_list {ecoRoute -fix_drc}
}

lassign [mptdc_ckpt_verify_snapshot 00_initial] initial_drc_rpt initial_marker_rpt initial_drc initial_shorts
puts $status_fh "INITIAL_DRC=$initial_drc"
puts $status_fh "INITIAL_SHORTS=$initial_shorts"
puts $status_fh "INITIAL_DRC_REPORT=$initial_drc_rpt"
puts $status_fh "INITIAL_MARKER_REPORT=$initial_marker_rpt"

set idx 0
set final_drc $initial_drc
set final_shorts $initial_shorts
foreach command $command_list {
    incr idx
    set tag [format "%02d_after_command" $idx]
    set safe [mptdc_ckpt_sanitize $command]
    set cmd_rpt [file join [mptdc_signoff_report_dir] [format "%02d_command_%s.rpt" $idx $safe]]
    puts $status_fh ""
    puts $status_fh "COMMAND_${idx}=$command"
    puts $status_fh "COMMAND_${idx}_REPORT=$cmd_rpt"
    flush $status_fh
    lassign [mptdc_ckpt_capture "checkpoint repair command $idx" $command $cmd_rpt] ok err
    puts $status_fh "COMMAND_${idx}_STATUS=[expr {$ok ? "PASS" : "FAIL"}]"
    if {!$ok} {
        puts $status_fh "COMMAND_${idx}_ERROR=$err"
    }
    lassign [mptdc_ckpt_verify_snapshot $tag] drc_rpt marker_rpt final_drc final_shorts
    puts $status_fh "COMMAND_${idx}_VERIFY_DRC=$final_drc"
    puts $status_fh "COMMAND_${idx}_VERIFY_SHORTS=$final_shorts"
    puts $status_fh "COMMAND_${idx}_DRC_REPORT=$drc_rpt"
    puts $status_fh "COMMAND_${idx}_MARKER_REPORT=$marker_rpt"
    flush $status_fh
}

set final_def [file join [mptdc_signoff_def_dir] repaired_route.def]
set final_ckpt [file join [mptdc_signoff_checkpoint_dir] repaired_route.enc]
set final_ckpt_dat "${final_ckpt}.dat"
catch {defOut $final_def}
catch {saveDesign $final_ckpt}

puts $status_fh ""
puts $status_fh "FINAL_DRC=$final_drc"
puts $status_fh "FINAL_SHORTS=$final_shorts"
puts $status_fh "FINAL_DEF=$final_def"
puts $status_fh "FINAL_CHECKPOINT=$final_ckpt"
puts $status_fh "FINAL_CHECKPOINT_DAT=$final_ckpt_dat"
puts $status_fh "FINAL_CHECKPOINT_DAT_EXISTS=[expr {[file isdirectory $final_ckpt_dat] ? 1 : 0}]"
if {$final_drc ne "UNKNOWN" && $final_shorts ne "UNKNOWN" && $final_drc == 0 && $final_shorts == 0} {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY"
} else {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=REVIEW_REQUIRED"
}
close $status_fh

puts "MPTDC_CHECKPOINT_REPAIR_STATUS_REPORT=$status_rpt"
