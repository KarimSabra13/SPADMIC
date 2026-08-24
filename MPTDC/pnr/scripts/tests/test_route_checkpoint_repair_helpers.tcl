set script_dir [file dirname [file normalize [info script]]]
set helper [file normalize [file join $script_dir .. innovus_mptdc_route_checkpoint_repair.tcl]]

set ::env(MPTDC_CHECKPOINT_REPAIR_SOURCE_ONLY) 1
set ::mptdc_test_fail_db_attributes {}
set ::mptdc_test_set_db_calls {}
set ::mptdc_test_set_attribute_calls {}
set ::mptdc_test_route_blockages {}
set ::mptdc_test_create_route_blockage_calls {}
set ::mptdc_test_delete_route_blockage_calls {}

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
    set name [lindex $args end-1]
    if {[lsearch -exact $::mptdc_test_route_blockages $name] >= 0} {
        return [list "route_blockage:$name"]
    }
    return {}
}

proc createRouteBlk {args} {
    set name_idx [lsearch -exact $args -name]
    if {$name_idx < 0} {
        error "fixture requires a named route blockage"
    }
    set name [lindex $args [expr {$name_idx + 1}]]
    if {[lsearch -exact $::mptdc_test_route_blockages $name] >= 0} {
        error "fixture duplicate route blockage: $name"
    }
    lappend ::mptdc_test_route_blockages $name
    lappend ::mptdc_test_create_route_blockage_calls $args
}

proc deleteRouteBlk {args} {
    set name_idx [lsearch -exact $args -name]
    if {$name_idx >= 0} {
        set name [lindex $args [expr {$name_idx + 1}]]
    } else {
        set name [lindex $args 0]
    }
    set idx [lsearch -exact $::mptdc_test_route_blockages $name]
    if {$idx < 0} {
        error "fixture missing route blockage: $name"
    }
    set ::mptdc_test_route_blockages [lreplace $::mptdc_test_route_blockages $idx $idx]
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
if {[dict get $blockage count] != 1 || [llength $::mptdc_test_route_blockages] != 1} {
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
    ![string match "*expected exactly one*" $err]} {
    error "missing route blockage delete guard did not fail as expected: $err"
}
if {![catch {mptdc_ckpt_create_route_blockage BAD-NAME {MET1} {1.0 2.0 3.0 4.0}} err] ||
    ![string match "*safe non-empty name*" $err]} {
    error "unsafe route blockage name guard did not fail as expected: $err"
}

puts "MPTDC_ROUTE_CHECKPOINT_REPAIR_HELPERS_TEST=PASS"
