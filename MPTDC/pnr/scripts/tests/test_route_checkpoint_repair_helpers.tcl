set script_dir [file dirname [file normalize [info script]]]
set helper [file normalize [file join $script_dir .. innovus_mptdc_route_checkpoint_repair.tcl]]

set ::env(MPTDC_CHECKPOINT_REPAIR_SOURCE_ONLY) 1
set ::mptdc_test_fail_db_attributes {}
set ::mptdc_test_set_db_calls {}
set ::mptdc_test_set_attribute_calls {}
set ::mptdc_test_route_blockages {}
set ::mptdc_test_create_route_blockage_calls {}
set ::mptdc_test_delete_route_blockage_calls {}
set ::mptdc_test_probe_mode 0
set ::mptdc_test_report_dir [file join [file dirname [file normalize [info script]]] .probe_fixture_reports]

proc mptdc_signoff_report_dir {} {
    return $::mptdc_test_report_dir
}

proc mptdc_signoff_report_value {value} {
    set text "$value"
    regsub -all {[\t\r\n]+} $text { } text
    return $text
}

proc mptdc_signoff_flat_box {value} {
    while {[llength $value] == 1} {
        set value [lindex $value 0]
    }
    if {[llength $value] >= 4} {
        return [lrange $value 0 3]
    }
    return {}
}

proc mptdc_signoff_box_valid {box} {
    if {[llength $box] < 4} {
        return 0
    }
    foreach value [lrange $box 0 3] {
        if {![string is double -strict $value]} {
            return 0
        }
    }
    return [expr {[lindex $box 2] > [lindex $box 0] && [lindex $box 3] > [lindex $box 1]}]
}

proc mptdc_test_redirect_report {kind name args} {
    if {[llength $args] != 2 || [lindex $args 0] ne ">"} {
        error "fixture requires redirected $kind output"
    }
    set path [lindex $args 1]
    set fh [open $path w]
    puts $fh "$kind $name fixture"
    close $fh
}

proc help {name args} {
    mptdc_test_redirect_report HELP $name {*}$args
}

proc dbSchema {name args} {
    mptdc_test_redirect_report SCHEMA $name {*}$args
}

proc get_nets {quiet net} {
    if {$quiet ne "-quiet" || $net eq "missing"} {
        return {}
    }
    return [list "net:$net"]
}

proc set_db {objects attribute value} {
    if {[lsearch -exact $::mptdc_test_fail_db_attributes $attribute] >= 0} {
        error "fixture rejects $attribute"
    }
    lappend ::mptdc_test_set_db_calls [list $objects $attribute $value]
}

proc setAttribute {args} {
    lappend ::mptdc_test_set_attribute_calls $args
}

proc dbGet {args} {
    if {$::mptdc_test_probe_mode} {
        if {[llength $args] == 4 && [lindex $args 0] eq "-e" &&
            [lindex $args 1] eq "top.nets.name" && [lindex $args 3] eq "-p"} {
            return [list "net:[lindex $args 2]"]
        }
        set expression [lindex $args 0]
        if {[string match "net:u_core_n_*.instTerms" $expression]} {
            set net [string range $expression 4 end-10]
            return [list "term:$net:A" "term:$net:Z"]
        }
        if {[string match "net:u_core_n_*.wires" $expression]} {
            set net [string range $expression 4 end-6]
            return [list "wire:$net:1"]
        }
        if {[string match "net:u_core_n_*.vias" $expression]} {
            set net [string range $expression 4 end-5]
            return [list "via:$net:1"]
        }
        if {$expression eq "net:VDD.sWires"} {
            return {swire:VDD:1}
        }
        if {$expression eq "net:VSS.sWires"} {
            return {swire:VSS:1}
        }
        if {$expression eq "swire:VDD:1.box"} {
            return {219.5 223.0 220.5 225.0}
        }
        if {$expression eq "swire:VSS:1.box"} {
            return {220.0 178.0 221.0 181.0}
        }
        if {[string match "*.box" $expression]} {
            return {1.0 2.0 3.0 4.0}
        }
        if {[string match "*.layer.name" $expression]} {
            return MET2
        }
        if {[string match "*.name" $expression]} {
            return [lindex [split $expression .] 0]
        }
        return "fixture:$expression"
    }
    set name [lindex $args end-1]
    set handles {}
    foreach blockage $::mptdc_test_route_blockages {
        if {[lindex $blockage 0] eq $name} {
            lappend handles "route_blockage:$name:[lindex $blockage 1]"
        }
    }
    return $handles
}

proc createRouteBlk {args} {
    set name_idx [lsearch -exact $args -name]
    if {$name_idx < 0} {
        error "fixture requires a named route blockage"
    }
    set name [lindex $args [expr {$name_idx + 1}]]
    foreach blockage $::mptdc_test_route_blockages {
        if {[lindex $blockage 0] eq $name} {
            error "fixture duplicate route blockage: $name"
        }
    }
    set layer_idx [lsearch -exact $args -layer]
    if {$layer_idx < 0} {
        error "fixture requires route blockage layers"
    }
    set layers [lindex $args [expr {$layer_idx + 1}]]
    foreach layer $layers {
        lappend ::mptdc_test_route_blockages [list $name $layer]
    }
    lappend ::mptdc_test_create_route_blockage_calls $args
}

proc deleteRouteBlk {args} {
    set name_idx [lsearch -exact $args -name]
    if {$name_idx >= 0} {
        set name [lindex $args [expr {$name_idx + 1}]]
    } else {
        set name [lindex $args 0]
    }
    set retained {}
    set removed 0
    foreach blockage $::mptdc_test_route_blockages {
        if {[lindex $blockage 0] eq $name} {
            incr removed
        } else {
            lappend retained $blockage
        }
    }
    if {$removed == 0} {
        error "fixture missing route blockage: $name"
    }
    set ::mptdc_test_route_blockages $retained
    lappend ::mptdc_test_delete_route_blockage_calls $args
}

source $helper

set result [mptdc_ckpt_set_net_route_layers u_net_a MET3 MET3]
if {[dict get $result bottom_layer] ne "MET3" || [dict get $result top_layer] ne "MET3"} {
    error "set_db path returned the wrong route-layer result: $result"
}
if {[llength $::mptdc_test_set_db_calls] != 3 || [llength $::mptdc_test_set_attribute_calls] != 0} {
    error "set_db path did not apply exactly three attributes"
}

set ::mptdc_test_fail_db_attributes {
    .bottom_preferred_routing_layer
    .preferred_routing_layer_effort
}
set ::mptdc_test_set_db_calls {}
set ::mptdc_test_set_attribute_calls {}
set result [mptdc_ckpt_set_net_route_layers u_net_b MET2 MET3]
if {[dict get $result bottom_layer] ne "MET2" || [dict get $result top_layer] ne "MET3"} {
    error "legacy fallback returned the wrong route-layer result: $result"
}
if {[llength $::mptdc_test_set_db_calls] != 1 || [llength $::mptdc_test_set_attribute_calls] != 2} {
    error "legacy fallback did not cover the rejected set_db attributes"
}

if {![catch {mptdc_ckpt_set_net_route_layers missing MET2 MET3} err] ||
    ![string match "*found no net object*" $err]} {
    error "missing-net guard did not fail as expected: $err"
}

set blockage [mptdc_ckpt_create_route_blockage TEST_RBLK {MET1 MET2} {1.0 2.0 3.0 4.0}]
if {[dict get $blockage expected_count] != 2 || [dict get $blockage count] != 2 ||
    [llength $::mptdc_test_route_blockages] != 2} {
    error "route blockage creation was not verified: $blockage"
}
if {![catch {mptdc_ckpt_create_route_blockage TEST_RBLK {MET1} {1.0 2.0 3.0 4.0}} err] ||
    ![string match "*already exists*" $err]} {
    error "duplicate route blockage guard did not fail as expected: $err"
}

set deleted [mptdc_ckpt_delete_route_blockage TEST_RBLK]
if {[dict get $deleted count] != 0 || [llength $::mptdc_test_route_blockages] != 0} {
    error "route blockage deletion was not verified: $deleted"
}
if {![catch {mptdc_ckpt_delete_route_blockage TEST_RBLK} err] ||
    ![string match "*expected at least one*" $err]} {
    error "missing route blockage delete guard did not fail as expected: $err"
}
if {![catch {mptdc_ckpt_create_route_blockage BAD-NAME {MET1} {1.0 2.0 3.0 4.0}} err] ||
    ![string match "*safe non-empty name*" $err]} {
    error "unsafe route blockage name guard did not fail as expected: $err"
}

file delete -force $::mptdc_test_report_dir
file mkdir $::mptdc_test_report_dir
set ::mptdc_test_probe_mode 1
set probe [mptdc_ckpt_probe_target_geometry {u_core_n_66687 u_core_n_67240 u_core_n_57563}]
if {[dict get $probe status] ne "PASS" || ![file exists [dict get $probe report]]} {
    error "read-only geometry probe did not pass: $probe"
}
set fh [open [dict get $probe report] r]
set probe_text [read $fh]
close $fh
foreach expected {
    {TARGET_NET_COUNT=3}
    {TARGET_NET_WITH_INSTTERMS_COUNT=3}
    {TARGET_NET_WITH_PIN_GEOMETRY_COUNT=3}
    {TARGET_INSTTERM_COUNT=6}
    {TARGET_INSTTERM_PIN_GEOMETRY_COUNT=6}
    {TARGET_WIRE_COUNT=3}
    {TARGET_VIA_COUNT=3}
    {NEARBY_PG_SHAPE_COUNT=2}
    {HELP_CAPTURE_STATUS=PASS}
    {SCHEMA_CAPTURE_STATUS=PASS}
    {PROBE_STATUS=PASS}
} {
    if {[string first $expected $probe_text] < 0} {
        error "geometry probe report is missing $expected"
    }
}
if {![catch {mptdc_ckpt_probe_target_geometry {u_core_n_57563}} err] ||
    ![string match "*exact bounded target set*" $err]} {
    error "geometry probe target-set guard did not fail as expected: $err"
}
set ::mptdc_test_probe_mode 0
file delete -force $::mptdc_test_report_dir

puts "MPTDC_ROUTE_CHECKPOINT_REPAIR_HELPERS_TEST=PASS"
