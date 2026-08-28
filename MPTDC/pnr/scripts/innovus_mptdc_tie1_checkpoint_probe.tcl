# =============================================================================
# Project  : SPAD_MPTDC
# File     : innovus_mptdc_tie1_checkpoint_probe.tcl
# Purpose  : Read-only tie1 and physical tie-cell inventory from a checkpoint
# =============================================================================

proc mptdc_tie1_probe_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_tie1_probe_value {value} {
    set clean [string map [list "\r" " " "\n" " " "=" ":"] $value]
    regsub -all {[[:space:]]+} [string trim $clean] {_} clean
    if {$clean eq ""} {
        return NONE
    }
    return $clean
}

proc mptdc_tie1_probe_objects {value} {
    if {$value eq "" || $value eq "0x0" || $value eq "NULL"} {
        return {}
    }
    return $value
}

proc mptdc_tie1_probe_count {value} {
    set objects [mptdc_tie1_probe_objects $value]
    if {[catch {llength $objects} count]} {
        return 0
    }
    return $count
}

proc mptdc_tie1_probe_dbget {name required args} {
    set command [linsert $args 0 dbGet]
    if {[catch {uplevel #0 $command} result]} {
        set ::mptdc_tie1_query_status($name) FAIL
        set ::mptdc_tie1_query_error($name) [mptdc_tie1_probe_value $result]
        incr ::mptdc_tie1_query_error_count
        if {$required} {
            incr ::mptdc_tie1_core_query_error_count
        }
        return ""
    }
    set ::mptdc_tie1_query_status($name) PASS
    set ::mptdc_tie1_query_error($name) NONE
    return $result
}

proc mptdc_tie1_probe_item {items index} {
    if {[catch {lindex $items $index} value] || $value eq ""} {
        return NONE
    }
    return [mptdc_tie1_probe_value $value]
}

proc mptdc_tie1_probe_pointer_attr {pointer attribute} {
    set query "${pointer}.${attribute}"
    if {[catch {uplevel #0 [list dbGet $query]} result]} {
        incr ::mptdc_tie1_detail_query_error_count
        return ERROR
    }
    return [mptdc_tie1_probe_value $result]
}

set checkpoint_raw [mptdc_tie1_probe_env MPTDC_TIE1_PROBE_CKPT ""]
if {$checkpoint_raw eq ""} {
    set checkpoint ""
} else {
    set checkpoint [file normalize $checkpoint_raw]
}
set outdir [file normalize [mptdc_tie1_probe_env MPTDC_TIE1_PROBE_OUTDIR /tmp/mptdc_tie1_checkpoint_probe]]
set top_cell [mptdc_tie1_probe_env MPTDC_TIE1_PROBE_TOP mptdc_axis_core]
set tie_master_text [mptdc_tie1_probe_env MPTDC_TIE1_PROBE_MASTERS \
    "LOGIC1DJIHD LOGIC1LVJIHD LOGIC0DJIHD LOGIC0LVJIHD"]
set tie_masters [split [string map {"," " "} $tie_master_text]]

file mkdir [file join $outdir reports]
set status_report [file join $outdir reports tie1_checkpoint_probe_status.rpt]
set master_report [file join $outdir reports tie1_candidate_master_inventory.tsv]
set term_report [file join $outdir reports tie1_inst_term_inventory.tsv]
set flagged_term_report [file join $outdir reports tie_flagged_term_inventory.tsv]
set net_report [file join $outdir reports tie_like_net_inventory.tsv]
set command_report [file join $outdir reports tie_command_availability.rpt]
set schema_report [file join $outdir reports tie1_db_schema_probe.rpt]

array set ::mptdc_tie1_query_status {}
array set ::mptdc_tie1_query_error {}
set ::mptdc_tie1_query_error_count 0
set ::mptdc_tie1_core_query_error_count 0
set ::mptdc_tie1_detail_query_error_count 0

set restore_status FAIL
set restore_error NONE
if {$checkpoint eq "" || ![file exists $checkpoint]} {
    set restore_error MISSING_CHECKPOINT
} elseif {[catch {restoreDesign $checkpoint $top_cell} restore_result]} {
    set restore_error [mptdc_tie1_probe_value $restore_result]
} else {
    set restore_status PASS
}

if {$restore_status ne "PASS"} {
    set fh [open $status_report w]
    puts $fh "STEP=TIE1_CHECKPOINT_PROBE"
    puts $fh "CHECKPOINT=$checkpoint"
    puts $fh "TOP_CELL=$top_cell"
    puts $fh "RESTORE_STATUS=$restore_status"
    puts $fh "RESTORE_ERROR=$restore_error"
    puts $fh "CORE_QUERY_STATUS=NOT_RUN"
    puts $fh "DESIGN_MUTATION_COUNT=0"
    puts $fh "PROBE_STATUS=FAIL"
    close $fh
    puts "MPTDC_TIE1_CHECKPOINT_PROBE_STATUS=FAIL"
    puts "MPTDC_TIE1_CHECKPOINT_PROBE_REPORT=$status_report"
    exit 1
}

set inst_objects_pre [mptdc_tie1_probe_dbget top_insts_pre 1 top.insts]
set net_objects_pre [mptdc_tie1_probe_dbget top_nets_pre 1 top.nets]
set all_net_names [mptdc_tie1_probe_dbget all_net_names 1 top.nets.name]
set tie1_net_ptrs [mptdc_tie1_probe_dbget tie1_net_ptrs 1 top.nets.name tie1 -p]
set tie1_net_ptrs [mptdc_tie1_probe_objects $tie1_net_ptrs]
set tie1_net_count [mptdc_tie1_probe_count $tie1_net_ptrs]

set tie1_terms {}
set tie1_regular_wires {}
set tie1_special_wires {}
set tie1_vias {}
set tie1_term_names {}
set tie1_inst_names {}
set tie1_master_names {}
set tie1_pin_names {}
set tie1_term_nets {}
set tie1_term_is_hi {}
set tie1_term_is_lo {}
if {$tie1_net_count == 1} {
    set tie1_net_ptr [lindex $tie1_net_ptrs 0]
    set tie1_terms [mptdc_tie1_probe_dbget tie1_inst_terms 1 ${tie1_net_ptr}.instTerms]
    set tie1_regular_wires [mptdc_tie1_probe_dbget tie1_regular_wires 1 ${tie1_net_ptr}.wires]
    set tie1_special_wires [mptdc_tie1_probe_dbget tie1_special_wires 1 ${tie1_net_ptr}.sWires]
    set tie1_vias [mptdc_tie1_probe_dbget tie1_vias 0 ${tie1_net_ptr}.vias]
    set tie1_term_names [mptdc_tie1_probe_dbget tie1_term_names 1 ${tie1_net_ptr}.instTerms.name]
    set tie1_inst_names [mptdc_tie1_probe_dbget tie1_inst_names 1 ${tie1_net_ptr}.instTerms.inst.name]
    set tie1_master_names [mptdc_tie1_probe_dbget tie1_master_names 1 ${tie1_net_ptr}.instTerms.inst.cell.name]
    set tie1_pin_names [mptdc_tie1_probe_dbget tie1_pin_names 1 ${tie1_net_ptr}.instTerms.cellTerm.name]
    set tie1_term_nets [mptdc_tie1_probe_dbget tie1_term_nets 1 ${tie1_net_ptr}.instTerms.net.name]
    set tie1_term_is_hi [mptdc_tie1_probe_dbget tie1_term_is_hi 0 ${tie1_net_ptr}.instTerms.isTieHi]
    set tie1_term_is_lo [mptdc_tie1_probe_dbget tie1_term_is_lo 0 ${tie1_net_ptr}.instTerms.isTieLo]
} else {
    set ::mptdc_tie1_query_status(tie1_inst_terms) NOT_RUN_NET_COUNT_$tie1_net_count
    set ::mptdc_tie1_query_error(tie1_inst_terms) NONE
}

set flagged_hi_terms [mptdc_tie1_probe_dbget flagged_hi_terms 1 top.insts.instTerms.isTieHi 1 -p]
set flagged_lo_terms [mptdc_tie1_probe_dbget flagged_lo_terms 1 top.insts.instTerms.isTieLo 1 -p]
set flagged_hi_terms [mptdc_tie1_probe_objects $flagged_hi_terms]
set flagged_lo_terms [mptdc_tie1_probe_objects $flagged_lo_terms]

set flagged_fh [open $flagged_term_report w]
puts $flagged_fh "polarity\tinst_term\tinstance\tmaster\tpin\tnet"
foreach polarity_and_terms [list [list HIGH $flagged_hi_terms] [list LOW $flagged_lo_terms]] {
    set polarity [lindex $polarity_and_terms 0]
    set terms [lindex $polarity_and_terms 1]
    foreach term $terms {
        puts $flagged_fh "$polarity\t[mptdc_tie1_probe_pointer_attr $term name]\t[mptdc_tie1_probe_pointer_attr $term inst.name]\t[mptdc_tie1_probe_pointer_attr $term inst.cell.name]\t[mptdc_tie1_probe_pointer_attr $term cellTerm.name]\t[mptdc_tie1_probe_pointer_attr $term net.name]"
    }
}
close $flagged_fh
if {$::mptdc_tie1_detail_query_error_count > 0} {
    incr ::mptdc_tie1_core_query_error_count $::mptdc_tie1_detail_query_error_count
}

set master_fh [open $master_report w]
puts $master_fh "master\tpolarity\tlibrary_master_count\tphysical_instance_count\tlibrary_status\tinstance_query_status"
set available_master_count 0
set physical_master_count 0
set physical_instance_count 0
foreach master $tie_masters {
    if {$master eq ""} {
        continue
    }
    if {[string match "LOGIC1*" $master]} {
        set polarity HIGH
    } else {
        set polarity LOW
    }
    set lib_query "lib_master_$master"
    set inst_query "physical_instances_$master"
    set lib_ptrs [mptdc_tie1_probe_dbget $lib_query 1 head.libCells.name $master -p]
    set inst_ptrs [mptdc_tie1_probe_dbget $inst_query 1 top.insts.cell.name $master -p2]
    set lib_count [mptdc_tie1_probe_count $lib_ptrs]
    set inst_count [mptdc_tie1_probe_count $inst_ptrs]
    if {$lib_count > 0} {
        incr available_master_count
    }
    if {$inst_count > 0} {
        incr physical_master_count
        incr physical_instance_count $inst_count
    }
    puts $master_fh "$master\t$polarity\t$lib_count\t$inst_count\t$::mptdc_tie1_query_status($lib_query)\t$::mptdc_tie1_query_status($inst_query)"
}
close $master_fh

set term_fh [open $term_report w]
puts $term_fh "index\tinst_term\tinstance\tmaster\tpin\tnet\tis_tie_high\tis_tie_low"
set tie1_term_count [mptdc_tie1_probe_count $tie1_terms]
for {set index 0} {$index < $tie1_term_count} {incr index} {
    puts $term_fh "$index\t[mptdc_tie1_probe_item $tie1_term_names $index]\t[mptdc_tie1_probe_item $tie1_inst_names $index]\t[mptdc_tie1_probe_item $tie1_master_names $index]\t[mptdc_tie1_probe_item $tie1_pin_names $index]\t[mptdc_tie1_probe_item $tie1_term_nets $index]\t[mptdc_tie1_probe_item $tie1_term_is_hi $index]\t[mptdc_tie1_probe_item $tie1_term_is_lo $index]"
}
close $term_fh

set tie_like_nets {}
set net_fh [open $net_report w]
puts $net_fh "net"
foreach net_name $all_net_names {
    if {[regexp -nocase {(tie|logic|const|one|zero)} $net_name]} {
        lappend tie_like_nets $net_name
        puts $net_fh [mptdc_tie1_probe_value $net_name]
    }
}
close $net_fh

set command_fh [open $command_report w]
set available_command_count 0
foreach command {addTieHiLo setTieHiLoMode reportTieHiLo} {
    set count [llength [info commands $command]]
    if {$count > 0} {
        incr available_command_count
        set status AVAILABLE
    } else {
        set status MISSING
    }
    puts $command_fh "${command}_COUNT=$count"
    puts $command_fh "${command}_STATUS=$status"
}
puts $command_fh "AVAILABLE_COMMAND_COUNT=$available_command_count"
close $command_fh

set net_schema [mptdc_tie1_probe_dbget net_schema 0 top.nets.?]
set term_schema [mptdc_tie1_probe_dbget inst_term_schema 0 top.insts.instTerms.?]
set schema_fh [open $schema_report w]
puts $schema_fh "NET_SCHEMA_STATUS=$::mptdc_tie1_query_status(net_schema)"
puts $schema_fh "NET_SCHEMA=[mptdc_tie1_probe_value $net_schema]"
puts $schema_fh "INST_TERM_SCHEMA_STATUS=$::mptdc_tie1_query_status(inst_term_schema)"
puts $schema_fh "INST_TERM_SCHEMA=[mptdc_tie1_probe_value $term_schema]"
close $schema_fh

set inst_objects_post [mptdc_tie1_probe_dbget top_insts_post 1 top.insts]
set net_objects_post [mptdc_tie1_probe_dbget top_nets_post 1 top.nets]
set inst_count_pre [mptdc_tie1_probe_count $inst_objects_pre]
set inst_count_post [mptdc_tie1_probe_count $inst_objects_post]
set net_count_pre [mptdc_tie1_probe_count $net_objects_pre]
set net_count_post [mptdc_tie1_probe_count $net_objects_post]

set design_object_count_status FAIL
set design_mutation_count [expr {abs($inst_count_post - $inst_count_pre) + abs($net_count_post - $net_count_pre)}]
if {$design_mutation_count == 0} {
    set design_object_count_status PASS
}

set core_query_status FAIL
if {$::mptdc_tie1_core_query_error_count == 0} {
    set core_query_status PASS
}
set probe_status FAIL
if {$restore_status eq "PASS" && $core_query_status eq "PASS" && $design_object_count_status eq "PASS"} {
    set probe_status PASS
}

set status_fh [open $status_report w]
puts $status_fh "STEP=TIE1_CHECKPOINT_PROBE"
puts $status_fh "CHECKPOINT=$checkpoint"
puts $status_fh "TOP_CELL=$top_cell"
puts $status_fh "RESTORE_STATUS=$restore_status"
puts $status_fh "RESTORE_ERROR=$restore_error"
puts $status_fh "TIE1_NET_COUNT=$tie1_net_count"
puts $status_fh "TIE1_INST_TERM_COUNT=$tie1_term_count"
puts $status_fh "TIE1_REGULAR_WIRE_COUNT=[mptdc_tie1_probe_count $tie1_regular_wires]"
puts $status_fh "TIE1_SPECIAL_WIRE_COUNT=[mptdc_tie1_probe_count $tie1_special_wires]"
puts $status_fh "TIE1_VIA_COUNT=[mptdc_tie1_probe_count $tie1_vias]"
puts $status_fh "TIE_LIKE_NET_COUNT=[llength $tie_like_nets]"
puts $status_fh "TIE_CANDIDATE_MASTER_COUNT=[llength $tie_masters]"
puts $status_fh "TIE_AVAILABLE_MASTER_COUNT=$available_master_count"
puts $status_fh "PHYSICAL_TIE_MASTER_COUNT=$physical_master_count"
puts $status_fh "PHYSICAL_TIE_INSTANCE_COUNT=$physical_instance_count"
puts $status_fh "FLAGGED_TIE_HIGH_TERM_COUNT=[mptdc_tie1_probe_count $flagged_hi_terms]"
puts $status_fh "FLAGGED_TIE_LOW_TERM_COUNT=[mptdc_tie1_probe_count $flagged_lo_terms]"
puts $status_fh "TOP_INSTANCE_COUNT_PRE=$inst_count_pre"
puts $status_fh "TOP_INSTANCE_COUNT_POST=$inst_count_post"
puts $status_fh "TOP_NET_COUNT_PRE=$net_count_pre"
puts $status_fh "TOP_NET_COUNT_POST=$net_count_post"
puts $status_fh "CORE_QUERY_ERROR_COUNT=$::mptdc_tie1_core_query_error_count"
puts $status_fh "QUERY_ERROR_COUNT=$::mptdc_tie1_query_error_count"
puts $status_fh "FLAGGED_DETAIL_QUERY_ERROR_COUNT=$::mptdc_tie1_detail_query_error_count"
foreach query_name [lsort [array names ::mptdc_tie1_query_status]] {
    puts $status_fh "QUERY_${query_name}_STATUS=$::mptdc_tie1_query_status($query_name)"
    puts $status_fh "QUERY_${query_name}_ERROR=$::mptdc_tie1_query_error($query_name)"
}
puts $status_fh "CORE_QUERY_STATUS=$core_query_status"
puts $status_fh "DESIGN_OBJECT_COUNT_STATUS=$design_object_count_status"
puts $status_fh "DESIGN_MUTATION_COUNT=$design_mutation_count"
puts $status_fh "PROBE_STATUS=$probe_status"
close $status_fh

puts "MPTDC_TIE1_CHECKPOINT_PROBE_STATUS=$probe_status"
puts "MPTDC_TIE1_CHECKPOINT_PROBE_REPORT=$status_report"
puts "MPTDC_TIE1_NET_COUNT=$tie1_net_count"
puts "MPTDC_TIE1_INST_TERM_COUNT=$tie1_term_count"
puts "MPTDC_PHYSICAL_TIE_INSTANCE_COUNT=$physical_instance_count"
puts "MPTDC_TIE1_DESIGN_MUTATION_COUNT=$design_mutation_count"

if {$probe_status eq "PASS"} {
    exit 0
}
exit 1
