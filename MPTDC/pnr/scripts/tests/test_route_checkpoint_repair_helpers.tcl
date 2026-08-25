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
set ::mptdc_test_manual_mode 0
set ::mptdc_test_manual_vias {}
set ::mptdc_test_manual_wires {}
set ::mptdc_test_manual_edit_net ""
set ::mptdc_test_manual_edit_horizontal ""
set ::mptdc_test_manual_edit_vertical ""
set ::mptdc_test_manual_edit_width 0.28
set ::mptdc_test_manual_route_points {}
set ::mptdc_test_manual_command_calls {}
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
    if {$::mptdc_test_manual_mode} {
        if {[llength $args] == 4 && [lindex $args 0] eq "-e" &&
            [lindex $args 1] eq "top.nets.name" && [lindex $args 3] eq "-p"} {
            return [list "net:[lindex $args 2]"]
        }
        set expression [lindex $args 0]
        if {[regexp {^net:(.+)\.vias$} $expression -> net]} {
            set handles {}
            set idx 0
            foreach row $::mptdc_test_manual_vias {
                if {[dict get $row net] eq $net} {
                    lappend handles "mvia:$idx"
                }
                incr idx
            }
            return $handles
        }
        if {[regexp {^net:(.+)\.wires$} $expression -> net]} {
            set handles {}
            set idx 0
            foreach row $::mptdc_test_manual_wires {
                if {[dict get $row net] eq $net} {
                    lappend handles "mwire:$idx"
                }
                incr idx
            }
            return $handles
        }
        if {[regexp {^mvia:([0-9]+)\.(.+)$} $expression -> idx attribute]} {
            set row [lindex $::mptdc_test_manual_vias $idx]
            switch -- $attribute {
                pt { return [dict get $row point] }
                via.name { return [dict get $row name] }
                status { return [dict get $row status] }
                botRects { return [dict get $row bot_rects] }
                cutRects { return [dict get $row cut_rects] }
                topRects { return [dict get $row top_rects] }
                default { return 0x0 }
            }
        }
        if {[regexp {^mwire:([0-9]+)\.(.+)$} $expression -> idx attribute]} {
            set row [lindex $::mptdc_test_manual_wires $idx]
            switch -- $attribute {
                layer.name { return [dict get $row layer] }
                box { return [dict get $row box] }
                width { return [dict get $row width] }
                pts { return [dict get $row points] }
                default { return 0x0 }
            }
        }
        return 0x0
    }
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

proc setEditMode {args} {
    lappend ::mptdc_test_manual_command_calls [linsert $args 0 setEditMode]
    if {[lsearch -exact $args -reset] >= 0} {
        set ::mptdc_test_manual_edit_net ""
        set ::mptdc_test_manual_edit_horizontal ""
        set ::mptdc_test_manual_edit_vertical ""
        set ::mptdc_test_manual_route_points {}
        return
    }
    foreach spec {
        {-nets mptdc_test_manual_edit_net}
        {-layer_horizontal mptdc_test_manual_edit_horizontal}
        {-layer_vertical mptdc_test_manual_edit_vertical}
        {-width_horizontal mptdc_test_manual_edit_width}
    } {
        lassign $spec option variable
        set idx [lsearch -exact $args $option]
        if {$idx >= 0} {
            set ::$variable [lindex $args [expr {$idx + 1}]]
        }
    }
}

proc uiSetTool {tool} {
    lappend ::mptdc_test_manual_command_calls [list uiSetTool $tool]
}

proc editDelete {args} {
    lappend ::mptdc_test_manual_command_calls [linsert $args 0 editDelete]
    set net_idx [lsearch -exact $args -net]
    set area_idx [lsearch -exact $args -area]
    if {$net_idx < 0 || $area_idx < 0} {
        error "manual fixture requires net and area filters"
    }
    set net [lindex $args [expr {$net_idx + 1}]]
    set area [lindex $args [expr {$area_idx + 1}]]
    lassign $area llx lly urx ury

    if {[lsearch -exact $args -regular_wire_with_drc] >= 0} {
        set layer_idx [lsearch -exact $args -layer]
        set type_idx [lsearch -exact $args -type]
        if {$layer_idx < 0 || $type_idx < 0 ||
            [lindex $args [expr {$type_idx + 1}]] ne "Regular" ||
            [lsearch -exact $args -object_type] >= 0} {
            error "manual fixture requires a bounded regular DRC-wire selector"
        }
        set ::mptdc_test_manual_drc_wire_deleted($net) 1
        return {}
    }

    set object_idx [lsearch -exact $args -object_type]
    if {$object_idx < 0} {
        error "manual fixture requires an object_type filter"
    }
    set object_type [lindex $args [expr {$object_idx + 1}]]

    if {$object_type eq "Wire"} {
        set layer_idx [lsearch -exact $args -layer]
        if {$layer_idx < 0} {
            error "manual fixture requires a layer for wire deletion"
        }
        set layer [lindex $args [expr {$layer_idx + 1}]]
        set retained {}
        foreach row $::mptdc_test_manual_wires {
            set box [dict get $row box]
            set delete_row [expr {
                [dict get $row net] eq $net && [dict get $row layer] eq $layer &&
                [lindex $box 0] >= $llx && [lindex $box 1] >= $lly &&
                [lindex $box 2] <= $urx && [lindex $box 3] <= $ury
            }]
            if {!$delete_row} {
                lappend retained $row
            }
        }
        set ::mptdc_test_manual_wires $retained
        return {}
    }

    if {$object_type ne "Via"} {
        error "manual fixture does not support object_type $object_type"
    }
    set via_cell_idx [lsearch -exact $args -via_cell]
    if {$via_cell_idx < 0} {
        error "manual fixture requires an exact via_cell filter"
    }
    set via_cell [lindex $args [expr {$via_cell_idx + 1}]]
    set retained {}
    foreach row $::mptdc_test_manual_vias {
        set delete_row [expr {
            [dict get $row net] eq $net && [dict get $row name] eq $via_cell
        }]
        if {$delete_row} {
            foreach key {bot_rects cut_rects top_rects} {
                foreach rect [mptdc_ckpt_manual_rects_from_value [dict get $row $key]] {
                    if {[lindex $rect 0] < $llx || [lindex $rect 1] < $lly ||
                        [lindex $rect 2] > $urx || [lindex $rect 3] > $ury} {
                        set delete_row 0
                    }
                }
            }
        }
        if {!$delete_row} {
            lappend retained $row
        }
    }
    set ::mptdc_test_manual_vias $retained
    return {}
}

proc editAddRoute {x y} {
    lappend ::mptdc_test_manual_command_calls [list editAddRoute $x $y]
    lappend ::mptdc_test_manual_route_points [list $x $y]
}

proc editCommitRoute {x y} {
    lappend ::mptdc_test_manual_command_calls [list editCommitRoute $x $y]
    lappend ::mptdc_test_manual_route_points [list $x $y]
    set xs {}
    set ys {}
    foreach point $::mptdc_test_manual_route_points {
        lappend xs [lindex $point 0]
        lappend ys [lindex $point 1]
    }
    set half [expr {$::mptdc_test_manual_edit_width / 2.0}]
    set sorted_xs [lsort -real $xs]
    set sorted_ys [lsort -real $ys]
    set box [list \
        [expr {[lindex $sorted_xs 0] - $half}] \
        [expr {[lindex $sorted_ys 0] - $half}] \
        [expr {[lindex $sorted_xs end] + $half}] \
        [expr {[lindex $sorted_ys end] + $half}]]
    lappend ::mptdc_test_manual_wires [dict create \
        net $::mptdc_test_manual_edit_net \
        layer $::mptdc_test_manual_edit_horizontal \
        box $box \
        width $::mptdc_test_manual_edit_width \
        points $::mptdc_test_manual_route_points]
    set ::mptdc_test_manual_route_points {}
}

proc editAddVia {x y} {
    lappend ::mptdc_test_manual_command_calls [list editAddVia $x $y]
    set pair [list $::mptdc_test_manual_edit_horizontal $::mptdc_test_manual_edit_vertical]
    switch -- $pair {
        {MET1 MET2} { set name VIA1_MANUAL }
        {MET3 MET2} { set name VIA2_MANUAL }
        default { error "unsupported manual fixture via pair: $pair" }
    }
    lappend ::mptdc_test_manual_vias [dict create \
        net $::mptdc_test_manual_edit_net name $name point [list $x $y] \
        status routed \
        bot_rects [list [list [expr {$x - 0.12}] [expr {$y - 0.12}] \
            [expr {$x + 0.12}] [expr {$y + 0.12}]]] \
        cut_rects [list [list [expr {$x - 0.08}] [expr {$y - 0.08}] \
            [expr {$x + 0.08}] [expr {$y + 0.08}]]] \
        top_rects [list [list [expr {$x - 0.14}] [expr {$y - 0.14}] \
            [expr {$x + 0.14}] [expr {$y + 0.14}]]]]
}

source $helper

if {[mptdc_ckpt_manual_flat_point 220.64] ne {}} {
    error "manual point normalizer accepted a scalar coordinate"
}
if {[llength [mptdc_ckpt_manual_rects_from_value \
        {{{1.0 2.0 3.0 4.0}} {{5.0 6.0 7.0 8.0}}}]] != 2} {
    error "manual rectangle normalizer rejected nested via geometry"
}

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
    {HELP_CAPTURE_PASS_COUNT=15}
    {HELP_CAPTURE_STATUS=PASS}
    {SCHEMA_CAPTURE_PASS_COUNT=7}
    {SCHEMA_CAPTURE_STATUS=PASS}
    {PROBE_STATUS=PASS}
} {
    if {[string first $expected $probe_text] < 0} {
        error "geometry probe report is missing $expected"
    }
}
if {![regexp {CELLTERM_PIN_RECTS_COMMAND=dbGet .*\.cellTerm\.pins\.layerShapeShapes\.shapes\.rect} $probe_text] ||
    [regexp {LIBTERM_PIN_.*_COMMAND=dbGet .*\.term\.pins} $probe_text] ||
    ![regexp {BOTTOM_RECTS_COMMAND=dbGet .*\.botRects} $probe_text]} {
    error "geometry probe did not use the captured instTerm/via schema paths"
}
if {![catch {mptdc_ckpt_probe_target_geometry {u_core_n_57563}} err] ||
    ![string match "*requires u_core_n_66687*or*u_core_n_57960*" $err]} {
    error "geometry probe target-set guard did not fail as expected: $err"
}
set ::mptdc_test_probe_mode 0

set ::mptdc_test_manual_mode 1
set ::mptdc_test_manual_vias [list \
    [dict create net u_core_n_66687 name VIA1_o point {220.64 179.48} status routed \
        bot_rects {{{220.525 179.365 220.755 179.595}}} \
        cut_rects {{{220.58 179.42 220.70 179.54}}} \
        top_rects {{{220.50 179.29 220.76 179.67}}}] \
    [dict create net u_core_n_66687 name VIA2_o point {220.64 179.48} status routed \
        bot_rects {{{220.50 179.29 220.76 179.67}}} \
        cut_rects {{{220.58 179.40 220.70 179.56}}} \
        top_rects {{{220.48 179.25 220.80 179.71}}}] \
    [dict create net u_core_n_66687 name VIA2_o point {224.84 179.48} status routed \
        bot_rects {{{224.70 179.29 224.98 179.67}}} \
        cut_rects {{{224.76 179.40 224.92 179.56}}} \
        top_rects {{{224.68 179.25 225.00 179.71}}}] \
    [dict create net u_core_n_67240 name VIA1_Y_so point {219.80 224.14} status routed \
        bot_rects {{{219.66 223.775 219.94 224.505}}} \
        cut_rects {{{219.72 224.05 219.88 224.23}}} \
        top_rects {{{219.64 223.75 219.96 224.53}}}] \
    [dict create net u_core_n_67240 name VIA2_so point {219.80 224.14} status routed \
        bot_rects {{{219.64 223.75 219.96 224.53}}} \
        cut_rects {{{219.72 224.04 219.88 224.24}}} \
        top_rects {{{219.62 223.73 219.98 224.55}}}] \
    [dict create net u_core_n_67240 name VIA2_o point {229.32 225.40} status routed \
        bot_rects {{{229.18 225.21 229.46 225.59}}} \
        cut_rects {{{229.24 225.32 229.40 225.48}}} \
        top_rects {{{229.16 225.17 229.48 225.63}}}] \
    [dict create net u_core_n_57563 name VIA1_X_so point {364.84 328.44} status routed \
        bot_rects {{{364.72 328.32 364.96 328.56}}} \
        cut_rects {{{364.76 328.36 364.92 328.52}}} \
        top_rects {{{364.70 328.30 364.98 328.58}}}]]
set ::mptdc_test_manual_wires [list \
    [dict create net u_core_n_66687 layer MET1 \
        box {220.525 179.365 220.78 179.595} width 0.23 \
        points {{220.64 179.48} {220.78 179.48}}] \
    [dict create net u_core_n_66687 layer MET3 \
        box {220.45 179.34 225.03 179.62} width 0.28 \
        points {{220.64 179.48} {224.84 179.48}}] \
    [dict create net u_core_n_66687 layer MET2 \
        box {224.70 179.29 224.98 190.82} width 0.28 \
        points {{224.84 179.48} {224.84 190.68}}] \
    [dict create net u_core_n_67240 layer MET3 \
        box {219.66 223.95 219.94 224.42} width 0.28 \
        points {{219.80 224.14} {219.80 224.28}}] \
    [dict create net u_core_n_67240 layer MET3 \
        box {219.66 224.14 221.06 224.42} width 0.28 \
        points {{219.80 224.28} {220.92 224.28}}] \
    [dict create net u_core_n_67240 layer MET3 \
        box {220.78 224.14 221.06 225.54} width 0.28 \
        points {{220.92 224.28} {220.92 225.40}}] \
    [dict create net u_core_n_67240 layer MET3 \
        box {220.78 225.26 229.51 225.54} width 0.28 \
        points {{220.92 225.40} {229.32 225.40}}] \
    [dict create net u_core_n_67240 layer MET2 \
        box {229.18 225.21 229.46 237.35} width 0.28 \
        points {{229.32 225.40} {229.32 237.16}}]]
set ::mptdc_test_manual_command_calls {}
set ::mptdc_test_manual_verify_count 0
array set ::mptdc_test_manual_drc_wire_deleted {
    u_core_n_66687 0
    u_core_n_67240 0
}
set ::mptdc_test_manual_snapshot_tuples [dict create \
    manual_v7_pre {3 1 0} \
    manual_v7_n66687_stack_deleted {3 1 1} \
    manual_v7_n66687_drc_wire_deleted {2 0 1} \
    manual_v7_n66687_reconnected {2 0 0} \
    manual_v7_n67240_stack_deleted {2 0 1} \
    manual_v7_n67240_drc_wire_deleted {1 0 1} \
    manual_v7_n67240_reconnected {1 0 0} \
    manual_v7_post {0 0 0}]
proc mptdc_ckpt_verify_snapshot {tag} {
    incr ::mptdc_test_manual_verify_count
    if {![dict exists $::mptdc_test_manual_snapshot_tuples $tag]} {
        error "manual fixture received unexpected snapshot tag: $tag"
    }
    if {$tag eq "manual_v7_n66687_drc_wire_deleted" &&
        !$::mptdc_test_manual_drc_wire_deleted(u_core_n_66687)} {
        error "n66687 DRC-wire snapshot occurred before the bounded deletion"
    }
    if {$tag eq "manual_v7_n67240_drc_wire_deleted" &&
        !$::mptdc_test_manual_drc_wire_deleted(u_core_n_67240)} {
        error "n67240 DRC-wire snapshot occurred before the bounded deletion"
    }
    lassign [dict get $::mptdc_test_manual_snapshot_tuples $tag] drc shorts regular
    return [dict create \
        total_violations $drc shorts $shorts regular_bad $regular \
        special_non_ro_failures 0]
}
if {![catch {mptdc_ckpt_manual_three_marker_eco_v4} err] ||
    ![string match "*retired*" $err]} {
    error "manual V4 retirement guard did not fail as expected: $err"
}
if {![catch {mptdc_ckpt_manual_three_marker_eco_v5} err] ||
    ![string match "*retired*" $err]} {
    error "manual V5 retirement guard did not fail as expected: $err"
}
if {![catch {mptdc_ckpt_manual_three_marker_eco_v6} err] ||
    ![string match "*retired*" $err]} {
    error "manual V6 retirement guard did not fail as expected: $err"
}
set manual [mptdc_ckpt_manual_three_marker_eco_v7]
if {[dict get $manual status] ne "PASS" || ![file exists [dict get $manual report]]} {
    error "manual three-marker ECO helper did not pass: $manual"
}
if {$::mptdc_test_manual_verify_count != 8} {
    error "manual ECO expected eight staged verification tuples, found $::mptdc_test_manual_verify_count"
}
if {[llength [mptdc_ckpt_manual_vias_at u_core_n_66687 {220.64 179.48}]] != 0 ||
    [llength [mptdc_ckpt_manual_vias_at u_core_n_67240 {219.80 224.14}]] != 0} {
    error "manual ECO retained an old offending via stack"
}
foreach spec {
    {u_core_n_66687 {221.20 178.92}}
    {u_core_n_67240 {221.20 223.58}}
} {
    lassign $spec net point
    set rows [mptdc_ckpt_manual_vias_at $net $point]
    lassign [mptdc_ckpt_manual_via_name_classes $rows] via1_count via2_count
    if {[llength $rows] != 1 || $via1_count != 1 || $via2_count != 0} {
        error "manual ECO did not create exactly one VIA1 for $net at $point: $rows"
    }
}
foreach spec {
    {u_core_n_66687 {224.84 179.48}}
    {u_core_n_67240 {229.32 225.40}}
} {
    lassign $spec net point
    if {[mptdc_ckpt_manual_via_names_at $net $point] ne {}} {
        error "manual ECO retained obsolete remote VIA2_o for $net at $point"
    }
}
if {[mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET2 {220.64 179.48}] ||
    [mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET2 {219.80 224.14}]} {
    error "manual ECO retained an offending old MET2 landing"
}
if {![mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET2 {221.20 178.92}] ||
    ![mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET2 {224.84 179.48}] ||
    ![mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET2 {221.20 223.58}] ||
    ![mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET2 {229.32 225.40}]} {
    error "manual ECO did not create both remote-MET2 bridges"
}
if {[mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET3 {220.64 179.48}] ||
    [mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET3 {224.84 179.48}] ||
    [mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET3 {219.80 224.14}] ||
    [mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET3 {229.32 225.40}]} {
    error "manual ECO retained an obsolete MET3 branch"
}
if {![mptdc_ckpt_manual_wire_covers_point u_core_n_57563 MET1 {365.12 328.44}]} {
    error "manual ECO did not create the MET1 minimum-area landing patch"
}
set fh [open [dict get $manual report] r]
set manual_text [read $fh]
close $fh
foreach expected {
    {MANUAL_ECO_MODE=STAGED_BOUNDED_DRC_WIRE_DELETE_AND_MET2_TRUNK_SPLICE}
    {VIA_DELETE_MODE=FULL_GEOMETRY_BOX_AND_EXACT_VIA_CELL}
    {OLD_MET2_LANDING_DELETE_MODE=BOUNDED_REGULAR_WIRE_WITH_DRC}
    {OBSOLETE_MET3_DELETE_MODE=BOUNDED_REGULAR_WIRE_ONLY}
    {VIA_INSERT_MODE=SINGLE_VIA1_ONLY}
    {STAGED_TUPLE_GATES=ENABLED}
    {REMOTE_VIA2_DELETE=u_core_n_66687:VIA2_o@224.84,179.48;u_core_n_67240:VIA2_o@229.32,225.40}
    {REMOTE_MET2_TRUNK_SPLICE=u_core_n_66687:224.84,179.48;u_core_n_67240:229.32,225.40}
    {N66687_STACK_DELETED_DRC=3}
    {N66687_DRC_WIRE_DELETED_DRC=2}
    {N66687_RECONNECTED_REGULAR_CONNECTIVITY_BAD=0}
    {N67240_STACK_DELETED_DRC=2}
    {N67240_DRC_WIRE_DELETED_DRC=1}
    {N67240_RECONNECTED_REGULAR_CONNECTIVITY_BAD=0}
    {PG_EDIT_POLICY=NO_PG_SHAPES_MODIFIED}
    {PLACEMENT_EDIT_POLICY=NO_INSTANCES_MOVED}
    {POST_DRC=0}
    {POST_SHORTS=0}
    {MANUAL_ECO_STATUS=PASS}
} {
    if {[string first $expected $manual_text] < 0} {
        error "manual ECO report is missing $expected"
    }
}
set delete_call_count 0
set via_delete_call_count 0
set wire_delete_call_count 0
set drc_wire_delete_call_count 0
set drc_wire_delete_calls {}
set via_add_call_count 0
foreach call $::mptdc_test_manual_command_calls {
    if {[lindex $call 0] eq "editDelete"} {
        incr delete_call_count
        if {[lsearch -exact $call -regular_wire_with_drc] >= 0} {
            incr drc_wire_delete_call_count
            lappend drc_wire_delete_calls $call
            if {[lsearch -exact $call -layer] < 0 ||
                [lsearch -exact $call -area] < 0 ||
                [lsearch -exact $call -net] < 0 ||
                [lsearch -exact $call -object_type] >= 0} {
                error "manual ECO DRC-wire deletion was not exactly bounded: $call"
            }
            continue
        }
        set object_idx [lsearch -exact $call -object_type]
        set object_type [lindex $call [expr {$object_idx + 1}]]
        if {$object_type eq "Via"} {
            incr via_delete_call_count
            if {[lsearch -exact $call -via_cell] < 0} {
                error "manual ECO via deletion omitted exact via_cell filter: $call"
            }
        } elseif {$object_type eq "Wire"} {
            incr wire_delete_call_count
            if {[lsearch -exact $call -layer] < 0 ||
                [lsearch -exact $call -via_cell] >= 0} {
                error "manual ECO wire deletion was not layer-bounded: $call"
            }
        } else {
            error "manual ECO used unexpected delete object type: $call"
        }
    }
    if {[lindex $call 0] eq "editAddVia"} {
        incr via_add_call_count
    }
    if {[lindex $call 0] in {routeDesign globalDetailRoute detailRoute ecoRoute createRouteBlk editPowerVia}} {
        error "manual ECO invoked a prohibited broad or PG command: $call"
    }
}
if {$delete_call_count != 10 || $via_delete_call_count != 6 ||
    $wire_delete_call_count != 2 || $drc_wire_delete_call_count != 2} {
    error "manual ECO expected six via, two visible-wire, and two DRC-wire deletions; found $via_delete_call_count/$wire_delete_call_count/$drc_wire_delete_call_count"
}
set expected_drc_wire_delete_calls [list \
    [list editDelete -net u_core_n_66687 -layer MET2 \
        -area {220.45 179.25 220.85 180.05} \
        -type Regular -regular_wire_with_drc] \
    [list editDelete -net u_core_n_67240 -layer MET2 \
        -area {219.62 223.73 219.98 224.55} \
        -type Regular -regular_wire_with_drc]]
if {$drc_wire_delete_calls ne $expected_drc_wire_delete_calls} {
    error "manual ECO DRC-wire commands changed scope: $drc_wire_delete_calls"
}
if {$via_add_call_count != 2} {
    error "manual ECO expected exactly two single-VIA1 insertions, found $via_add_call_count"
}

set ::mptdc_test_manual_vias [list \
    [dict create net u_core_n_57960 name VIA1_o point {363.72 358.12} status routed \
        bot_rects {{{363.53 357.98 363.91 358.26}}} \
        cut_rects {{{363.59 357.99 363.85 358.25}}} \
        top_rects {{{363.58 357.93 363.86 358.31}}}] \
    [dict create net u_core_n_57556 name VIA1_o point {385.56 328.44} status routed \
        bot_rects {{{385.37 328.30 385.75 328.58}}} \
        cut_rects {{{385.43 328.31 385.69 328.57}}} \
        top_rects {{{385.42 328.25 385.70 328.63}}}]]
set ::mptdc_test_manual_wires {}
set ::mptdc_test_manual_command_calls {}
set ::mptdc_test_manual_verify_count 0
set ::mptdc_test_manual_snapshot_tuples [dict create \
    minarea_v1_pre {2 0 0} \
    minarea_v1_post {0 0 0}]

set minarea [mptdc_ckpt_manual_two_minarea_landing_patch_v1]
if {[dict get $minarea status] ne "PASS" || ![file exists [dict get $minarea report]]} {
    error "two-landing minimum-area helper did not pass: $minarea"
}
if {$::mptdc_test_manual_verify_count != 2} {
    error "minimum-area helper expected two verification tuples, found $::mptdc_test_manual_verify_count"
}
if {![mptdc_ckpt_manual_wire_covers_point u_core_n_57960 MET1 {364.14 358.12}] ||
    ![mptdc_ckpt_manual_wire_covers_point u_core_n_57556 MET1 {385.14 328.44}]} {
    error "minimum-area helper did not create both inward MET1 landing stubs"
}
if {[mptdc_ckpt_manual_via_names_at u_core_n_57960 {363.72 358.12}] ne {VIA1_o} ||
    [mptdc_ckpt_manual_via_names_at u_core_n_57556 {385.56 328.44}] ne {VIA1_o}} {
    error "minimum-area helper modified a target VIA1_o landing"
}

set fh [open [dict get $minarea report] r]
set minarea_text [read $fh]
close $fh
foreach expected {
    {MANUAL_ECO_MODE=EXACT_TWO_VIA_LANDING_MIN_AREA_STUBS}
    {TARGET_VIA_POLICY=u_core_n_57960:VIA1_o@363.72,358.12;u_core_n_57556:VIA1_o@385.56,328.44}
    {REPAIR_STUB_POLICY=u_core_n_57960:MET1:363.72,358.12->364.56,358.12;u_core_n_57556:MET1:385.56,328.44->384.72,328.44;width=0.28}
    {VIA_EDIT_POLICY=NO_VIAS_MODIFIED}
    {PG_EDIT_POLICY=NO_PG_SHAPES_MODIFIED}
    {PLACEMENT_EDIT_POLICY=NO_INSTANCES_MOVED}
    {PRE_DRC=2}
    {PRE_SHORTS=0}
    {POST_DRC=0}
    {POST_SHORTS=0}
    {MANUAL_ECO_STATUS=PASS}
} {
    if {[string first $expected $minarea_text] < 0} {
        error "minimum-area helper report is missing $expected"
    }
}
set route_start_count 0
set route_commit_count 0
foreach call $::mptdc_test_manual_command_calls {
    if {[lindex $call 0] eq "editAddRoute"} {
        incr route_start_count
    }
    if {[lindex $call 0] eq "editCommitRoute"} {
        incr route_commit_count
    }
    if {[lindex $call 0] in {editDelete editAddVia routeDesign globalDetailRoute detailRoute ecoRoute createRouteBlk editPowerVia}} {
        error "minimum-area helper invoked a prohibited command: $call"
    }
}
if {$route_start_count != 2 || $route_commit_count != 2} {
    error "minimum-area helper expected two bounded wire starts/commits, found $route_start_count/$route_commit_count"
}
set ::mptdc_test_manual_mode 0
file delete -force $::mptdc_test_report_dir

puts "MPTDC_ROUTE_CHECKPOINT_REPAIR_HELPERS_TEST=PASS"
