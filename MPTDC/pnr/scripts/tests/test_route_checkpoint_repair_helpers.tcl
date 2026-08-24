set script_dir [file dirname [file normalize [info script]]]
set helper [file normalize [file join $script_dir .. innovus_mptdc_route_checkpoint_repair.tcl]]

set ::env(MPTDC_CHECKPOINT_REPAIR_SOURCE_ONLY) 1
set ::mptdc_test_fail_db_attributes {}
set ::mptdc_test_set_db_calls {}
set ::mptdc_test_set_attribute_calls {}

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

puts "MPTDC_ROUTE_CHECKPOINT_REPAIR_HELPERS_TEST=PASS"
