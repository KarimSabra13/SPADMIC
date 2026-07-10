# Restore-only PG connectivity evidence capture. No design command is allowed.

proc probe_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "SPADMIC_PG_PROBE_MISSING_ENV: $name"
    }
    return $::env($name)
}

proc probe_value {value} {
    if {$value eq ""} { return NONE }
    return [string map [list "\n" " " "\r" " " "\t" " "] $value]
}

proc probe_query {fh key command} {
    if {[catch {set value [uplevel #0 $command]} err]} {
        puts $fh "${key}_STATUS=FAIL"
        puts $fh "${key}_ERROR=[probe_value $err]"
        return
    }
    puts $fh "${key}_STATUS=PASS"
    puts $fh "${key}_VALUE=[probe_value $value]"
}

set checkpoint [probe_env SPADMIC_PG_PROBE_CHECKPOINT]
set probe_root [probe_env SPADMIC_PG_PROBE_ROOT]
set top [probe_env SPADMIC_PG_PROBE_TOP]
set reports [file join $probe_root reports]
file mkdir $reports
array set status {
    LABEL SPADMIC_OOC_PG_CONNECTIVITY_PROBE
    POLICY READ_ONLY_RESTORE_AND_REPORT
    DESIGN_MODIFICATION NOT_RUN
    STATUS FAIL
}

if {[catch {restoreDesign $checkpoint $top} err]} {
    set status(RESTORE_DESIGN) FAIL
    set status(ERROR) [probe_value $err]
    set fh [open [file join $reports pg_probe_status.rpt] w]
    foreach key [lsort [array names status]] { puts $fh "$key=$status($key)" }
    close $fh
    error "SPADMIC_PG_PROBE_RESTORE_FAILED: $err"
}
set status(RESTORE_DESIGN) PASS

set detail [file join $reports verify_connectivity_special_detail.rpt]
set console [file join $reports verify_connectivity_special_console.rpt]
set command "verifyConnectivity -type special -nets {VDD VSS} -report \"$detail\""
if {[catch {uplevel #0 "$command > \"$console\""} err]} {
    set status(VERIFY_SPECIAL_REPORT) FAIL
    set status(ERROR) [probe_value $err]
} else {
    set status(VERIFY_SPECIAL_REPORT) PASS
}

set topology [file join $reports pg_topology.rpt]
set fh [open $topology w]
puts $fh "LABEL=SPADMIC_OOC_PG_TOPOLOGY"
probe_query $fh TOP_NAME {dbGet top.name}
probe_query $fh DIE_BOX {dbGet top.fPlan.box}
probe_query $fh CORE_BOX {dbGet top.fPlan.coreBox}
probe_query $fh PG_TERM_NAMES {dbGet top.pgTerms.name}
probe_query $fh PG_TERM_NETS {dbGet top.pgTerms.net.name}
probe_query $fh PG_TERM_LAYERS {dbGet top.pgTerms.pins.allShapes.layer.name}

foreach net {VDD VSS} {
    if {[catch {set term [dbGet top.pgTerms.name $net -p]} err] ||
        $term eq "" || $term eq "0x0"} {
        puts $fh "${net}_PG_TERM_STATUS=FAIL"
        puts $fh "${net}_PG_TERM_ERROR=[probe_value $err]"
    } else {
        puts $fh "${net}_PG_TERM_STATUS=PASS"
        probe_query $fh "${net}_PG_TERM_BOXES" "dbGet $term.pins.allShapes.shapes.box"
        probe_query $fh "${net}_PG_TERM_RECTS" "dbGet $term.pins.allShapes.rect"
    }
}

puts $fh "SWIRE_TABLE_BEGIN"
puts $fh "net\tidx\tshape\tlayer\tstatus\twidth\tgeomType\tbox\tpts"
foreach net {VDD VSS} {
    if {[catch {set net_handle [dbGet top.nets.name $net -p]} err] ||
        $net_handle eq "" || $net_handle eq "0x0"} {
        puts $fh "$net\tERROR\t[probe_value $err]"
        continue
    }
    if {[catch {set swires [dbGet $net_handle.sWires]} err]} {
        puts $fh "$net\tERROR\t[probe_value $err]"
        continue
    }
    set idx 0
    foreach swire $swires {
        if {$swire eq "" || $swire eq "0x0" || $swire eq "NULL"} { continue }
        incr idx
        set shape UNKNOWN
        set layer UNKNOWN
        set wire_status UNKNOWN
        set width UNKNOWN
        set geom UNKNOWN
        set box UNKNOWN
        set pts UNKNOWN
        catch {set shape [dbGet $swire.shape]}
        catch {set layer [dbGet $swire.layer.name]}
        catch {set wire_status [dbGet $swire.status]}
        catch {set width [dbGet $swire.width]}
        catch {set geom [dbGet $swire.geomType]}
        catch {set box [dbGet $swire.box]}
        catch {set pts [dbGet $swire.pts]}
        puts $fh "$net\t$idx\t[probe_value $shape]\t[probe_value $layer]\t[probe_value $wire_status]\t[probe_value $width]\t[probe_value $geom]\t[probe_value $box]\t[probe_value $pts]"
    }
    puts $fh "${net}_SWIRE_COUNT=$idx"
}
puts $fh "SWIRE_TABLE_END"
close $fh

set markers_report [file join $reports pg_connectivity_markers.tsv]
set fh [open $markers_report w]
puts $fh "idx\tmarker_handle\tbox\tlayer\ttype\tsubType\tmessage"
set marker_count 0
if {![catch {set markers [dbGet top.markers]} err]} {
    foreach marker $markers {
        if {$marker eq "" || $marker eq "0x0" || $marker eq "NULL"} { continue }
        incr marker_count
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
        puts $fh "$marker_count\t[probe_value $marker]\t[probe_value $box]\t[probe_value $layer]\t[probe_value $type]\t[probe_value $subtype]\t[probe_value $message]"
    }
}
close $fh

set status(MARKER_COUNT) $marker_count
set status(TOPOLOGY_REPORT) $topology
set status(MARKER_REPORT) $markers_report
set status(VERIFY_DETAIL_REPORT) $detail
set status(VERIFY_CONSOLE_REPORT) $console
if {$status(VERIFY_SPECIAL_REPORT) eq "PASS"} {
    set status(STATUS) PASS
    set status(RESULT) PG_DIAGNOSTIC_CAPTURED
}
set fh [open [file join $reports pg_probe_status.rpt] w]
foreach key [lsort [array names status]] { puts $fh "$key=$status($key)" }
close $fh

if {$status(STATUS) eq "PASS"} { exit 0 }
exit 8
