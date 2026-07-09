# =============================================================================
# SPADMIC matrix-top -- dump DRC markers from an OOC Innovus checkpoint
# =============================================================================

proc spadmic_ooc_env_required {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_OOC_MARKER_DUMP_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc spadmic_ooc_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc spadmic_ooc_report_value {value} {
    regsub -all {\s+} $value { } compact
    return [string trim $compact]
}

proc spadmic_ooc_flat_box {raw} {
    set values [list]
    foreach item $raw {
        foreach value $item {
            lappend values $value
        }
    }
    if {[llength $values] < 4} {
        return [list UNKNOWN UNKNOWN UNKNOWN UNKNOWN]
    }
    return [lrange $values 0 3]
}

proc spadmic_ooc_numeric_or_unknown {value} {
    if {[string is double -strict $value]} {
        return $value
    }
    return UNKNOWN
}

proc spadmic_ooc_write_marker_dump {path} {
    file mkdir [file dirname $path]
    set schema_rpt [file rootname $path]_schema.rpt
    catch {dbSchema marker > $schema_rpt}
    catch {help marker >> $schema_rpt}

    set markers [list]
    catch {set markers [dbGet top.markers]}

    set fh [open $path w]
    puts $fh "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\tlayer\ttype\tsubType\tmessage"
    set idx 0
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} {
            continue
        }
        incr idx
        set box UNKNOWN
        set layer UNKNOWN
        set type UNKNOWN
        set subtype UNKNOWN
        set message UNKNOWN
        catch {set box [dbGet $marker.box]}
        catch {set layer [dbGet $marker.layer.name]}
        catch {set type [dbGet $marker.type]}
        catch {set subtype [dbGet $marker.subType]}
        catch {set message [dbGet $marker.message]}

        lassign [spadmic_ooc_flat_box $box] llx lly urx ury
        set llx [spadmic_ooc_numeric_or_unknown $llx]
        set lly [spadmic_ooc_numeric_or_unknown $lly]
        set urx [spadmic_ooc_numeric_or_unknown $urx]
        set ury [spadmic_ooc_numeric_or_unknown $ury]
        set cx UNKNOWN
        set cy UNKNOWN
        if {$llx ne "UNKNOWN" && $urx ne "UNKNOWN"} {
            set cx [format %.6f [expr {($llx + $urx) / 2.0}]]
        }
        if {$lly ne "UNKNOWN" && $ury ne "UNKNOWN"} {
            set cy [format %.6f [expr {($lly + $ury) / 2.0}]]
        }

        puts $fh "$idx\t[spadmic_ooc_report_value $marker]\t[spadmic_ooc_report_value $box]\t$llx\t$lly\t$urx\t$ury\t$cx\t$cy\t[spadmic_ooc_report_value $layer]\t[spadmic_ooc_report_value $type]\t[spadmic_ooc_report_value $subtype]\t[spadmic_ooc_report_value $message]"
    }
    close $fh
    return $idx
}

set block_root [spadmic_ooc_env_required SPADMIC_INNOVUS_BLOCK_ROOT]
set top_module [spadmic_ooc_env_required SPADMIC_INNOVUS_TOP_MODULE]
set checkpoint [spadmic_ooc_env SPADMIC_INNOVUS_CHECKPOINT [file join $block_root checkpoints 05_postroute_export.enc.dat]]
set reports_dir [file join $block_root reports]
file mkdir $reports_dir

set summary [file join $reports_dir drc_marker_dump_summary.rpt]
set fh [open $summary w]
puts $fh "BLOCK_ROOT=$block_root"
puts $fh "TOP_MODULE=$top_module"
puts $fh "CHECKPOINT=$checkpoint"

if {![file exists $checkpoint]} {
    puts $fh "STATUS=FAIL"
    puts $fh "REASON=checkpoint_missing"
    close $fh
    error "SPADMIC_OOC_MARKER_DUMP_CHECKPOINT_MISSING: $checkpoint"
}

restoreDesign $checkpoint $top_module
puts $fh "RESTORE_STATUS=PASS"
close $fh

set verify_rpt [file join $reports_dir verify_drc_marker_dump.rpt]
if {[catch {redirect -file $verify_rpt {verify_drc}} err]} {
    set fh [open $summary a]
    puts $fh "VERIFY_DRC_STATUS=FAIL"
    puts $fh "VERIFY_DRC_ERROR=[spadmic_ooc_report_value $err]"
    close $fh
    error "SPADMIC_OOC_MARKER_DUMP_VERIFY_FAILED: $err"
}

set marker_tsv [file join $reports_dir verify_drc_post_route_markers.tsv]
set marker_count [spadmic_ooc_write_marker_dump $marker_tsv]

set fh [open $summary a]
puts $fh "VERIFY_DRC_STATUS=PASS"
puts $fh "VERIFY_DRC_REPORT=$verify_rpt"
puts $fh "MARKER_TSV=$marker_tsv"
puts $fh "MARKER_COUNT=$marker_count"
puts $fh "STATUS=PASS"
close $fh

exit
