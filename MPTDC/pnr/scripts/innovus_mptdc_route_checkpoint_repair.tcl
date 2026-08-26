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

proc mptdc_ckpt_command_is_helper {command} {
    if {[catch {set head [lindex $command 0]}]} {
        return 0
    }
    return [string match "mptdc_ckpt_*" $head]
}

proc mptdc_ckpt_capture {label command path} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "# $label"
    puts $fh "COMMAND=$command"
    close $fh
    set is_helper [mptdc_ckpt_command_is_helper $command]
    if {$is_helper} {
        set invoke $command
    } else {
        set invoke "$command >> \"$path\""
    }
    if {[catch {uplevel #0 $invoke} result opts]} {
        set fh [open $path a]
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh "ERROR=$result"
        if {[dict exists $opts -errorcode]} {
            puts $fh "ERRORCODE=[dict get $opts -errorcode]"
        }
        if {[dict exists $opts -errorinfo]} {
            puts $fh "ERRORINFO_BEGIN"
            puts $fh [dict get $opts -errorinfo]
            puts $fh "ERRORINFO_END"
        }
        close $fh
        return [list 0 $result]
    }
    set fh [open $path a]
    if {$is_helper} {
        puts $fh "HELPER_RESULT=$result"
    }
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

proc mptdc_ckpt_continue_after_command_fail {} {
    return [mptdc_ckpt_env MPTDC_CHECKPOINT_REPAIR_KEEP_GOING 0]
}

proc mptdc_ckpt_source_tcl {path} {
    if {[string trim $path] eq ""} {
        error "mptdc_ckpt_source_tcl requires a Tcl file path"
    }
    if {![file exists $path]} {
        error "mptdc_ckpt_source_tcl file does not exist: $path"
    }
    if {![file readable $path]} {
        error "mptdc_ckpt_source_tcl file is not readable: $path"
    }
    puts "MPTDC_CKPT_SOURCE_TCL=$path"
    source $path
    return $path
}

proc mptdc_ckpt_select_nets {nets} {
    if {[llength $nets] == 0} {
        error "mptdc_ckpt_select_nets requires at least one net"
    }
    catch {deselectAll}
    set selected {}
    set failures {}
    foreach net $nets {
        set net [string trim $net]
        if {$net eq ""} {
            continue
        }
        if {[catch {selectNet $net} err]} {
            lappend failures "$net:$err"
        } else {
            lappend selected $net
        }
    }
    puts "MPTDC_CKPT_SELECTED_NETS=[join $selected { }]"
    if {[llength $failures] > 0} {
        error "mptdc_ckpt_select_nets failed: [join $failures {; }]"
    }
    if {[llength $selected] == 0} {
        error "mptdc_ckpt_select_nets selected zero nets"
    }
    return $selected
}

proc mptdc_ckpt_set_net_route_layers {net bottom_layer top_layer} {
    set net [string trim $net]
    set bottom_layer [string trim $bottom_layer]
    set top_layer [string trim $top_layer]
    if {$net eq "" || $bottom_layer eq "" || $top_layer eq ""} {
        error "mptdc_ckpt_set_net_route_layers requires net, bottom layer, and top layer"
    }

    set objects {}
    if {[catch {set objects [get_nets -quiet $net]} err] || [llength $objects] == 0} {
        error "mptdc_ckpt_set_net_route_layers found no net object for $net: $err"
    }

    set methods {}
    set failures {}
    foreach spec [list \
        [list BOTTOM .bottom_preferred_routing_layer -bottom_preferred_routing_layer $bottom_layer] \
        [list TOP .top_preferred_routing_layer -top_preferred_routing_layer $top_layer] \
        [list EFFORT .preferred_routing_layer_effort -preferred_routing_layer_effort high]] {
        lassign $spec label db_attribute legacy_option value
        if {![catch {set_db $objects $db_attribute $value} db_err]} {
            lappend methods "$label:set_db"
            continue
        }
        if {![catch {setAttribute -net $net $legacy_option $value} legacy_err]} {
            lappend methods "$label:setAttribute"
            continue
        }
        lappend failures "$label:set_db={$db_err};setAttribute={$legacy_err}"
    }

    puts "MPTDC_CKPT_ROUTE_LAYER_NET=$net"
    puts "MPTDC_CKPT_ROUTE_LAYER_BOTTOM=$bottom_layer"
    puts "MPTDC_CKPT_ROUTE_LAYER_TOP=$top_layer"
    puts "MPTDC_CKPT_ROUTE_LAYER_METHODS=[join $methods ,]"
    if {[llength $failures] > 0} {
        error "failed to apply preferred routing layers for $net: [join $failures {; }]"
    }
    return [dict create \
        net $net \
        bottom_layer $bottom_layer \
        top_layer $top_layer \
        methods $methods]
}

proc mptdc_ckpt_query_named_route_blockage {name} {
    set errors {}
    foreach cmd [list \
        [list dbGet -e top.fPlan.rBlkgs.name $name -p] \
        [list dbGet top.fPlan.rBlkgs.name $name -p] \
        [list dbGet -e top.fplan.rBlkgs.name $name -p] \
        [list get_db route_blockages -if ".name == $name"]] {
        if {[catch {set raw [uplevel #0 $cmd]} err]} {
            lappend errors "$cmd: $err"
            continue
        }
        set handles {}
        foreach handle $raw {
            if {$handle ni {"" 0x0 NULL null nil}} {
                lappend handles $handle
            }
        }
        return [dict create status PASS command $cmd handles $handles errors $errors]
    }
    return [dict create status UNKNOWN command {} handles {} errors $errors]
}

proc mptdc_ckpt_create_route_blockage {name layers box} {
    set name [string trim $name]
    if {$name eq "" || ![regexp {^[A-Za-z0-9_]+$} $name]} {
        error "mptdc_ckpt_create_route_blockage requires a safe non-empty name"
    }
    if {[llength $layers] == 0} {
        error "mptdc_ckpt_create_route_blockage requires at least one layer"
    }
    if {[llength $box] != 4} {
        error "mptdc_ckpt_create_route_blockage requires box {x1 y1 x2 y2}"
    }
    foreach value $box {
        if {![string is double -strict $value]} {
            error "mptdc_ckpt_create_route_blockage box must be numeric: $box"
        }
    }
    lassign $box llx lly urx ury
    if {$llx >= $urx || $lly >= $ury} {
        error "mptdc_ckpt_create_route_blockage requires an ordered box: $box"
    }

    set before [mptdc_ckpt_query_named_route_blockage $name]
    if {[dict get $before status] ne "PASS"} {
        error "cannot query route blockage $name before creation: [dict get $before errors]"
    }
    if {[llength [dict get $before handles]] != 0} {
        error "route blockage already exists: $name"
    }

    set attempts [list \
        [concat [list createRouteBlk -name $name -box] $box [list -layer $layers]] \
        [list createRouteBlk -name $name -box $box -layer $layers]]
    set used {}
    set errors {}
    foreach cmd $attempts {
        if {![catch {uplevel #0 $cmd} err]} {
            set used $cmd
            break
        }
        lappend errors "$cmd: $err"
    }
    if {$used eq ""} {
        error "failed to create route blockage $name: [join $errors {; }]"
    }

    set after [mptdc_ckpt_query_named_route_blockage $name]
    set count [llength [dict get $after handles]]
    set expected_count [llength $layers]
    puts "MPTDC_CKPT_ROUTE_BLOCKAGE_NAME=$name"
    puts "MPTDC_CKPT_ROUTE_BLOCKAGE_LAYERS=$layers"
    puts "MPTDC_CKPT_ROUTE_BLOCKAGE_BOX=$box"
    puts "MPTDC_CKPT_ROUTE_BLOCKAGE_CREATE_COMMAND=$used"
    puts "MPTDC_CKPT_ROUTE_BLOCKAGE_CREATE_EXPECTED_COUNT=$expected_count"
    puts "MPTDC_CKPT_ROUTE_BLOCKAGE_CREATE_COUNT=$count"
    if {[dict get $after status] ne "PASS" || $count != $expected_count} {
        error "route blockage creation could not be verified for $name: status=[dict get $after status] expected=$expected_count count=$count"
    }
    return [dict create name $name layers $layers box $box command $used expected_count $expected_count count $count]
}

proc mptdc_ckpt_delete_route_blockage {name} {
    set name [string trim $name]
    if {$name eq "" || ![regexp {^[A-Za-z0-9_]+$} $name]} {
        error "mptdc_ckpt_delete_route_blockage requires a safe non-empty name"
    }

    set before [mptdc_ckpt_query_named_route_blockage $name]
    set before_count [llength [dict get $before handles]]
    if {[dict get $before status] ne "PASS" || $before_count < 1} {
        error "expected at least one route blockage before deleting $name: status=[dict get $before status] count=$before_count"
    }

    set used {}
    set errors {}
    foreach cmd [list \
        [list deleteRouteBlk -name $name] \
        [list deleteRouteBlk $name]] {
        if {![catch {uplevel #0 $cmd} err]} {
            set used $cmd
            break
        }
        lappend errors "$cmd: $err"
    }
    if {$used eq ""} {
        error "failed to delete route blockage $name: [join $errors {; }]"
    }

    set after [mptdc_ckpt_query_named_route_blockage $name]
    set after_count [llength [dict get $after handles]]
    puts "MPTDC_CKPT_ROUTE_BLOCKAGE_DELETE_NAME=$name"
    puts "MPTDC_CKPT_ROUTE_BLOCKAGE_DELETE_COMMAND=$used"
    puts "MPTDC_CKPT_ROUTE_BLOCKAGE_DELETE_BEFORE_COUNT=$before_count"
    puts "MPTDC_CKPT_ROUTE_BLOCKAGE_DELETE_COUNT=$after_count"
    if {[dict get $after status] ne "PASS" || $after_count != 0} {
        error "route blockage deletion could not be verified for $name: status=[dict get $after status] count=$after_count"
    }
    return [dict create name $name command $used before_count $before_count count $after_count]
}

proc mptdc_ckpt_probe_valid_handles {values} {
    set out {}
    foreach value $values {
        if {$value ni {"" 0x0 NULL null nil}} {
            lappend out $value
        }
    }
    return $out
}

proc mptdc_ckpt_probe_value_has_data {value} {
    set text [string trim $value]
    return [expr {$text ne "" && $text ni {0x0 NULL null nil {}}}]
}

proc mptdc_ckpt_probe_dbget {fh key expression} {
    set command [list dbGet $expression]
    puts $fh "${key}_COMMAND=$command"
    if {[catch {set value [uplevel #0 $command]} err]} {
        puts $fh "${key}_STATUS=FAIL"
        puts $fh "${key}_ERROR=[mptdc_signoff_report_value $err]"
        return [dict create status FAIL value {} error $err]
    }
    puts $fh "${key}_STATUS=PASS"
    puts $fh "${key}_VALUE=[mptdc_signoff_report_value $value]"
    return [dict create status PASS value $value error {}]
}

proc mptdc_ckpt_probe_handle {fh prefix handle attributes} {
    puts $fh "${prefix}_HANDLE=[mptdc_signoff_report_value $handle]"
    foreach spec $attributes {
        lassign $spec key attribute
        mptdc_ckpt_probe_dbget $fh "${prefix}_${key}" "${handle}.${attribute}"
    }
}

proc mptdc_ckpt_probe_capture_redirect {kind name command path} {
    file mkdir [file dirname $path]
    set ok 1
    set err ""
    if {[catch {uplevel #0 "$command > \"$path\""} err]} {
        set ok 0
        mptdc_ckpt_write_text $path "# $kind $name\nCOMMAND=$command\nREPORT_STATUS=FAIL\nERROR=[mptdc_signoff_report_value $err]\n"
    } elseif {![file exists $path] || [file size $path] == 0} {
        set ok 0
        set err "command produced no report"
        mptdc_ckpt_write_text $path "# $kind $name\nCOMMAND=$command\nREPORT_STATUS=FAIL\nERROR=$err\n"
    }
    return [dict create status [expr {$ok ? "PASS" : "FAIL"}] path $path error $err]
}

proc mptdc_ckpt_probe_boxes_overlap {lhs rhs} {
    set lhs [mptdc_signoff_flat_box $lhs]
    set rhs [mptdc_signoff_flat_box $rhs]
    if {![mptdc_signoff_box_valid $lhs] || ![mptdc_signoff_box_valid $rhs]} {
        return 0
    }
    return [expr {
        [lindex $lhs 0] <= [lindex $rhs 2] &&
        [lindex $lhs 2] >= [lindex $rhs 0] &&
        [lindex $lhs 1] <= [lindex $rhs 3] &&
        [lindex $lhs 3] >= [lindex $rhs 1]
    }]
}

proc mptdc_ckpt_probe_target_geometry {nets} {
    set legacy_nets {u_core_n_66687 u_core_n_67240 u_core_n_57563}
    set min_area_nets {u_core_n_57960 u_core_n_57556}
    set marker_boxes [dict create]
    set marker_centers [dict create]
    if {$nets eq $legacy_nets} {
        set probe_profile LEGACY_THREE_MARKER
        set probe_basename route_geometry
        set windows [dict create \
            u_core_n_66687 {214.0 173.0 226.0 185.0} \
            u_core_n_67240 {214.0 218.0 226.0 230.0} \
            u_core_n_57563 {359.0 323.0 371.0 334.0}]
        set require_pin_geometry 1
        set require_nearby_pg 1
    } elseif {$nets eq $min_area_nets} {
        set probe_profile HALO10_TWO_MET1_MIN_AREA
        set probe_basename route_min_area
        set windows [dict create \
            u_core_n_57960 {358.0 352.0 369.0 364.0} \
            u_core_n_57556 {380.0 322.0 391.0 335.0}]
        set marker_boxes [dict create \
            u_core_n_57960 {363.53 357.98 363.91 358.26} \
            u_core_n_57556 {385.37 328.30 385.75 328.58}]
        set marker_centers [dict create \
            u_core_n_57960 {363.72 358.12} \
            u_core_n_57556 {385.56 328.44}]
        set require_pin_geometry 0
        set require_nearby_pg 0
    } else {
        error "mptdc_ckpt_probe_target_geometry requires $legacy_nets or $min_area_nets"
    }
    set expected_nets $nets

    set report_dir [mptdc_signoff_report_dir]
    set probe_rpt [file join $report_dir ${probe_basename}_target_probe.rpt]
    set help_status_rpt [file join $report_dir ${probe_basename}_command_help_status.rpt]
    set schema_status_rpt [file join $report_dir ${probe_basename}_db_schema_status.rpt]
    set fh [open $probe_rpt w]
    puts $fh "# MPTDC Read-Only Route Geometry Probe"
    puts $fh "PROBE_MODE=READ_ONLY_NO_ROUTE_EDITS"
    puts $fh "PROBE_PROFILE=$probe_profile"
    puts $fh "PROBE_REQUIRE_PIN_GEOMETRY=$require_pin_geometry"
    puts $fh "PROBE_REQUIRE_NEARBY_PG=$require_nearby_pg"
    puts $fh "TARGET_NETS=[join $nets ,]"

    set target_net_count 0
    set target_with_instterms_count 0
    set target_with_pin_geometry_count 0
    set target_instterm_count 0
    set target_instterm_pin_geometry_count 0
    set target_wire_count 0
    set target_via_count 0

    foreach net $nets {
        set token [string toupper $net]
        puts $fh ""
        puts $fh "TARGET_${token}_BEGIN"
        puts $fh "TARGET_${token}_WINDOW=[dict get $windows $net]"
        if {[dict exists $marker_boxes $net]} {
            puts $fh "TARGET_${token}_MARKER_LAYER=MET1"
            puts $fh "TARGET_${token}_MARKER_SUBTYPE=Minimal_Area"
            puts $fh "TARGET_${token}_MARKER_BOX=[dict get $marker_boxes $net]"
            puts $fh "TARGET_${token}_MARKER_CENTER=[dict get $marker_centers $net]"
        }
        set handles {}
        puts $fh "TARGET_${token}_LOOKUP_COMMAND=dbGet -e top.nets.name $net -p"
        if {[catch {set raw [dbGet -e top.nets.name $net -p]} err]} {
            puts $fh "TARGET_${token}_LOOKUP_STATUS=FAIL"
            puts $fh "TARGET_${token}_LOOKUP_ERROR=[mptdc_signoff_report_value $err]"
        } else {
            set handles [mptdc_ckpt_probe_valid_handles $raw]
            puts $fh "TARGET_${token}_LOOKUP_STATUS=PASS"
            puts $fh "TARGET_${token}_LOOKUP_HANDLES=[mptdc_signoff_report_value $handles]"
        }
        if {[llength $handles] != 1} {
            puts $fh "TARGET_${token}_STATUS=FAIL_NET_HANDLE_COUNT_[llength $handles]"
            puts $fh "TARGET_${token}_END"
            continue
        }

        incr target_net_count
        set nh [lindex $handles 0]
        mptdc_ckpt_probe_handle $fh "TARGET_${token}_NET" $nh {
            {NAME name}
            {OBJTYPE objType}
            {BOX box}
            {INPUT_TERM_COUNT numInputTerms}
            {OUTPUT_TERM_COUNT numOutputTerms}
            {STATUS status}
            {BOTTOM_PREFERRED_LAYER bottomPreferredLayer.name}
            {TOP_PREFERRED_LAYER topPreferredLayer.name}
        }

        set instterms_result [mptdc_ckpt_probe_dbget $fh "TARGET_${token}_INSTTERMS" "${nh}.instTerms"]
        set instterms {}
        if {[dict get $instterms_result status] eq "PASS"} {
            set instterms [mptdc_ckpt_probe_valid_handles [dict get $instterms_result value]]
        }
        puts $fh "TARGET_${token}_INSTTERM_COUNT=[llength $instterms]"
        if {[llength $instterms] > 0} {
            incr target_with_instterms_count
            incr target_instterm_count [llength $instterms]
        }
        set term_idx 0
        set net_has_pin_geometry 0
        foreach term $instterms {
            incr term_idx
            mptdc_ckpt_probe_handle $fh "TARGET_${token}_INSTTERM_${term_idx}" $term {
                {NAME name}
                {NET_NAME net.name}
                {PT pt}
                {LAYER layer.name}
                {INST_NAME inst.name}
                {INST_CELL inst.cell.name}
                {INST_ORIENT inst.orient}
                {INST_PT inst.pt}
                {INST_BOX inst.box}
                {CELLTERM_NAME cellTerm.name}
                {EFFECTIVE_STACK_VIA effectiveStackVia}
                {STACK_VIA_REQUIRED stackViaRequired}
                {STACK_VIA_RULE_REQUIRED stackViaRuleRequired}
                {STACK_VIA_RULE stackViaRule.name}
            }
            set term_has_pin_geometry 0
            foreach spec {
                {CELLTERM_PIN_LAYERS cellTerm.pins.allShapes.layer.name 0}
                {CELLTERM_PIN_RECTS cellTerm.pins.layerShapeShapes.shapes.rect 1}
                {CELLTERM_PIN_POLYGONS cellTerm.pins.layerShapeShapes.shapes.polyPts 1}
            } {
                lassign $spec key attribute is_geometry
                set result [mptdc_ckpt_probe_dbget $fh \
                    "TARGET_${token}_INSTTERM_${term_idx}_${key}" \
                    "${term}.${attribute}"]
                if {$is_geometry && [dict get $result status] eq "PASS" &&
                    [mptdc_ckpt_probe_value_has_data [dict get $result value]]} {
                    set term_has_pin_geometry 1
                }
            }
            puts $fh "TARGET_${token}_INSTTERM_${term_idx}_PIN_GEOMETRY_STATUS=[expr {$term_has_pin_geometry ? "PASS" : "FAIL"}]"
            if {$term_has_pin_geometry} {
                incr target_instterm_pin_geometry_count
                set net_has_pin_geometry 1
            }
        }
        if {$net_has_pin_geometry} {
            incr target_with_pin_geometry_count
        }

        foreach route_kind {wires vias} {
            set route_result [mptdc_ckpt_probe_dbget $fh "TARGET_${token}_[string toupper $route_kind]" "${nh}.${route_kind}"]
            set route_handles {}
            if {[dict get $route_result status] eq "PASS"} {
                set route_handles [mptdc_ckpt_probe_valid_handles [dict get $route_result value]]
            }
            puts $fh "TARGET_${token}_[string toupper $route_kind]_COUNT=[llength $route_handles]"
            if {$route_kind eq "wires"} {
                incr target_wire_count [llength $route_handles]
                set attributes {
                    {NET_NAME net.name}
                    {LAYER layer.name}
                    {BOX box}
                    {PTS pts}
                    {WIDTH width}
                    {STATUS status}
                    {SHAPE shape}
                    {RULE rule.name}
                }
            } else {
                incr target_via_count [llength $route_handles]
                set attributes {
                    {NET_NAME net.name}
                    {VIA_NAME via.name}
                    {PT pt}
                    {BOTTOM_RECTS botRects}
                    {CUT_RECTS cutRects}
                    {TOP_RECTS topRects}
                    {STATUS status}
                    {RULE rule.name}
                }
            }
            set route_idx 0
            foreach route_handle $route_handles {
                incr route_idx
                mptdc_ckpt_probe_handle $fh \
                    "TARGET_${token}_[string toupper $route_kind]_${route_idx}" \
                    $route_handle $attributes
            }
        }
        puts $fh "TARGET_${token}_STATUS=PASS"
        puts $fh "TARGET_${token}_END"
    }

    set nearby_pg_shape_count 0
    puts $fh ""
    puts $fh "NEARBY_PG_SHAPES_BEGIN"
    foreach pg_net {VDD VSS} {
        set pg_handles {}
        if {![catch {set raw [dbGet -e top.nets.name $pg_net -p]}]} {
            set pg_handles [mptdc_ckpt_probe_valid_handles $raw]
        }
        foreach pg_handle $pg_handles {
            set swires {}
            if {![catch {set raw [dbGet ${pg_handle}.sWires]}]} {
                set swires [mptdc_ckpt_probe_valid_handles $raw]
            }
            set swire_idx 0
            foreach swire $swires {
                incr swire_idx
                set box {}
                catch {set box [mptdc_signoff_flat_box [dbGet ${swire}.box]]}
                set matches {}
                foreach net $nets {
                    if {[mptdc_ckpt_probe_boxes_overlap $box [dict get $windows $net]]} {
                        lappend matches $net
                    }
                }
                if {[llength $matches] == 0} {
                    continue
                }
                incr nearby_pg_shape_count
                set prefix "NEARBY_PG_${pg_net}_${nearby_pg_shape_count}"
                puts $fh "${prefix}_TARGET_WINDOWS=[join $matches ,]"
                mptdc_ckpt_probe_handle $fh $prefix $swire {
                    {NET_NAME net.name}
                    {LAYER layer.name}
                    {BOX box}
                    {PTS pts}
                    {WIDTH width}
                    {STATUS status}
                    {SHAPE shape}
                    {GEOM_TYPE geomType}
                }
            }
        }
    }
    puts $fh "NEARBY_PG_SHAPES_END"
    puts $fh "TARGET_NET_COUNT=$target_net_count"
    puts $fh "TARGET_NET_WITH_INSTTERMS_COUNT=$target_with_instterms_count"
    puts $fh "TARGET_NET_WITH_PIN_GEOMETRY_COUNT=$target_with_pin_geometry_count"
    puts $fh "TARGET_INSTTERM_COUNT=$target_instterm_count"
    puts $fh "TARGET_INSTTERM_PIN_GEOMETRY_COUNT=$target_instterm_pin_geometry_count"
    puts $fh "TARGET_WIRE_COUNT=$target_wire_count"
    puts $fh "TARGET_VIA_COUNT=$target_via_count"
    puts $fh "NEARBY_PG_SHAPE_COUNT=$nearby_pg_shape_count"
    close $fh

    set help_fh [open $help_status_rpt w]
    puts $help_fh "# Installed Innovus command help capture"
    set help_pass_count 0
    set help_fail_count 0
    foreach command_name {
        dbCreateWire dbCreateVia editAddRoute editCommitRoute editAddVia
        setViaEdit setEdit setEditMode uiSetTool editDelete setAttribute
        create_route_rule set_route_attributes routeDesign dbQuery
    } {
        set safe [mptdc_ckpt_sanitize $command_name]
        set path [file join $report_dir "help_${safe}.rpt"]
        set result [mptdc_ckpt_probe_capture_redirect HELP $command_name [list help $command_name] $path]
        puts $help_fh "HELP_${safe}_STATUS=[dict get $result status]"
        puts $help_fh "HELP_${safe}_REPORT=$path"
        if {[dict get $result status] eq "PASS"} {
            incr help_pass_count
        } else {
            incr help_fail_count
            puts $help_fh "HELP_${safe}_ERROR=[mptdc_signoff_report_value [dict get $result error]]"
        }
    }
    puts $help_fh "HELP_CAPTURE_PASS_COUNT=$help_pass_count"
    puts $help_fh "HELP_CAPTURE_FAIL_COUNT=$help_fail_count"
    puts $help_fh "HELP_CAPTURE_STATUS=[expr {$help_pass_count > 0 ? "PASS" : "FAIL"}]"
    close $help_fh

    set schema_fh [open $schema_status_rpt w]
    puts $schema_fh "# Installed Innovus DB schema capture"
    set schema_pass_count 0
    set schema_fail_count 0
    foreach object_name {net wire viaInst instTerm pin pinShape sWire} {
        set safe [mptdc_ckpt_sanitize $object_name]
        set path [file join $report_dir "schema_${safe}.rpt"]
        set result [mptdc_ckpt_probe_capture_redirect SCHEMA $object_name [list dbSchema $object_name] $path]
        puts $schema_fh "SCHEMA_${safe}_STATUS=[dict get $result status]"
        puts $schema_fh "SCHEMA_${safe}_REPORT=$path"
        if {[dict get $result status] eq "PASS"} {
            incr schema_pass_count
        } else {
            incr schema_fail_count
            puts $schema_fh "SCHEMA_${safe}_ERROR=[mptdc_signoff_report_value [dict get $result error]]"
        }
    }
    puts $schema_fh "SCHEMA_CAPTURE_PASS_COUNT=$schema_pass_count"
    puts $schema_fh "SCHEMA_CAPTURE_FAIL_COUNT=$schema_fail_count"
    puts $schema_fh "SCHEMA_CAPTURE_STATUS=[expr {$schema_pass_count > 0 ? "PASS" : "FAIL"}]"
    close $schema_fh

    set pin_geometry_ok [expr {
        $require_pin_geometry ?
            ($target_with_pin_geometry_count == [llength $expected_nets]) :
            ($target_instterm_count > 0)
    }]
    set nearby_pg_ok [expr {!$require_nearby_pg || $nearby_pg_shape_count > 0}]
    set probe_status [expr {
        $target_net_count == [llength $expected_nets] &&
        $target_with_instterms_count == [llength $expected_nets] &&
        $pin_geometry_ok &&
        $target_wire_count > 0 &&
        $nearby_pg_ok &&
        $help_pass_count > 0 &&
        $schema_pass_count > 0
    }]
    set fh [open $probe_rpt a]
    puts $fh "HELP_STATUS_REPORT=$help_status_rpt"
    puts $fh "HELP_CAPTURE_PASS_COUNT=$help_pass_count"
    puts $fh "HELP_CAPTURE_STATUS=[expr {$help_pass_count > 0 ? "PASS" : "FAIL"}]"
    puts $fh "SCHEMA_STATUS_REPORT=$schema_status_rpt"
    puts $fh "SCHEMA_CAPTURE_PASS_COUNT=$schema_pass_count"
    puts $fh "SCHEMA_CAPTURE_STATUS=[expr {$schema_pass_count > 0 ? "PASS" : "FAIL"}]"
    puts $fh "PROBE_STATUS=[expr {$probe_status ? "PASS" : "FAIL"}]"
    close $fh

    if {!$probe_status} {
        error "route geometry probe evidence is incomplete: report=$probe_rpt"
    }
    puts "MPTDC_CKPT_ROUTE_GEOMETRY_PROBE_REPORT=$probe_rpt"
    return [dict create status PASS report $probe_rpt]
}

proc mptdc_ckpt_manual_flat_point {value} {
    while {[llength $value] == 1} {
        set nested [lindex $value 0]
        if {$nested eq $value} {
            return {}
        }
        set value $nested
    }
    if {[llength $value] < 2} {
        return {}
    }
    return [lrange $value 0 1]
}

proc mptdc_ckpt_manual_flat_values {value} {
    if {[llength $value] == 0} {
        return {}
    }
    if {[llength $value] == 1} {
        set nested [lindex $value 0]
        if {$nested eq $value} {
            return [list $value]
        }
        return [mptdc_ckpt_manual_flat_values $nested]
    }
    set values {}
    foreach item $value {
        foreach nested [mptdc_ckpt_manual_flat_values $item] {
            lappend values $nested
        }
    }
    return $values
}

proc mptdc_ckpt_manual_close {lhs rhs {tolerance 0.001}} {
    if {![string is double -strict $lhs] || ![string is double -strict $rhs]} {
        return 0
    }
    return [expr {abs(double($lhs) - double($rhs)) <= $tolerance}]
}

proc mptdc_ckpt_manual_point_equal {lhs rhs {tolerance 0.001}} {
    set lhs [mptdc_ckpt_manual_flat_point $lhs]
    set rhs [mptdc_ckpt_manual_flat_point $rhs]
    if {[llength $lhs] != 2 || [llength $rhs] != 2} {
        return 0
    }
    return [expr {
        [mptdc_ckpt_manual_close [lindex $lhs 0] [lindex $rhs 0] $tolerance] &&
        [mptdc_ckpt_manual_close [lindex $lhs 1] [lindex $rhs 1] $tolerance]
    }]
}

proc mptdc_ckpt_manual_net_handle {net} {
    set handles {}
    if {[catch {set handles [mptdc_ckpt_probe_valid_handles [dbGet -e top.nets.name $net -p]]} err]} {
        error "failed to query net $net: $err"
    }
    if {[llength $handles] != 1} {
        error "expected one net handle for $net, found [llength $handles]"
    }
    return [lindex $handles 0]
}

proc mptdc_ckpt_manual_vias_at {net point} {
    set nh [mptdc_ckpt_manual_net_handle $net]
    set rows {}
    foreach handle [mptdc_ckpt_probe_valid_handles [dbGet ${nh}.vias]] {
        set actual_point [mptdc_ckpt_manual_flat_point [dbGet ${handle}.pt]]
        if {![mptdc_ckpt_manual_point_equal $actual_point $point]} {
            continue
        }
        set via_name [lindex [dbGet ${handle}.via.name] 0]
        lappend rows [dict create handle $handle name $via_name point $actual_point]
    }
    return $rows
}

proc mptdc_ckpt_manual_rects_from_value {value} {
    while {[llength $value] == 1} {
        set nested [lindex $value 0]
        if {$nested eq $value} {
            return {}
        }
        set value $nested
    }

    set value_count [llength $value]
    set all_numeric [expr {$value_count >= 4 && ($value_count % 4) == 0}]
    if {$all_numeric} {
        foreach item $value {
            if {![string is double -strict $item]} {
                set all_numeric 0
                break
            }
        }
    }
    if {$all_numeric} {
        set rects {}
        for {set idx 0} {$idx < $value_count} {incr idx 4} {
            set rect [lrange $value $idx [expr {$idx + 3}]]
            if {[mptdc_signoff_box_valid $rect]} {
                lappend rects $rect
            }
        }
        return $rects
    }

    set rects {}
    foreach item $value {
        foreach rect [mptdc_ckpt_manual_rects_from_value $item] {
            lappend rects $rect
        }
    }
    return $rects
}

proc mptdc_ckpt_manual_via_geometry {handle} {
    set rects {}
    set attribute_counts {}
    foreach attribute {botRects cutRects topRects} {
        if {[catch {set raw [dbGet ${handle}.${attribute}]} err]} {
            error "failed to query $attribute for via $handle: $err"
        }
        set attribute_rects [mptdc_ckpt_manual_rects_from_value $raw]
        dict set attribute_counts $attribute [llength $attribute_rects]
        foreach rect $attribute_rects {
            lappend rects $rect
        }
    }
    if {[llength $rects] == 0} {
        error "via $handle has no queryable botRects/cutRects/topRects geometry"
    }

    set first [lindex $rects 0]
    lassign $first llx lly urx ury
    foreach rect [lrange $rects 1 end] {
        set llx [expr {min($llx, [lindex $rect 0])}]
        set lly [expr {min($lly, [lindex $rect 1])}]
        set urx [expr {max($urx, [lindex $rect 2])}]
        set ury [expr {max($ury, [lindex $rect 3])}]
    }
    return [dict create \
        box [list $llx $lly $urx $ury] \
        rect_count [llength $rects] \
        attribute_counts $attribute_counts]
}

proc mptdc_ckpt_manual_wire_rows {net} {
    set nh [mptdc_ckpt_manual_net_handle $net]
    set rows {}
    foreach handle [mptdc_ckpt_probe_valid_handles [dbGet ${nh}.wires]] {
        set layer [lindex [dbGet ${handle}.layer.name] 0]
        set box [mptdc_signoff_flat_box [dbGet ${handle}.box]]
        set width [lindex [dbGet ${handle}.width] 0]
        set pts [dbGet ${handle}.pts]
        lappend rows [dict create handle $handle layer $layer box $box width $width pts $pts]
    }
    return $rows
}

proc mptdc_ckpt_manual_wire_covers_point {net layer point} {
    set point [mptdc_ckpt_manual_flat_point $point]
    if {[llength $point] != 2} {
        return 0
    }
    lassign $point x y
    foreach row [mptdc_ckpt_manual_wire_rows $net] {
        if {[dict get $row layer] ne $layer} {
            continue
        }
        set box [dict get $row box]
        if {[mptdc_signoff_box_valid $box] &&
            $x >= [lindex $box 0] && $x <= [lindex $box 2] &&
            $y >= [lindex $box 1] && $y <= [lindex $box 3]} {
            return 1
        }
    }
    return 0
}

proc mptdc_ckpt_manual_log_command {fh label command} {
    puts $fh "${label}_COMMAND=$command"
    flush $fh
    if {[catch {set result [uplevel #0 $command]} err opts]} {
        puts $fh "${label}_STATUS=FAIL"
        puts $fh "${label}_ERROR=[mptdc_signoff_report_value $err]"
        flush $fh
        return -options $opts $err
    }
    puts $fh "${label}_STATUS=PASS"
    puts $fh "${label}_RESULT=[mptdc_signoff_report_value $result]"
    flush $fh
    return $result
}

proc mptdc_ckpt_manual_delete_via_stack {fh label net point expected_names} {
    set rows [mptdc_ckpt_manual_vias_at $net $point]
    set names {}
    foreach row $rows {
        lappend names [dict get $row name]
    }
    puts $fh "${label}_PRE_VIA_NAMES=[join [lsort $names] ,]"
    if {[lsort $names] ne [lsort $expected_names]} {
        error "$label expected via names $expected_names at $point, found $names"
    }

    foreach expected_name [lsort $expected_names] {
        set current_rows [mptdc_ckpt_manual_vias_at $net $point]
        set matching_rows {}
        foreach row $current_rows {
            if {[dict get $row name] eq $expected_name} {
                lappend matching_rows $row
            }
        }
        if {[llength $matching_rows] != 1} {
            error "$label expected exactly one $expected_name at $point before deletion"
        }

        set row [lindex $matching_rows 0]
        set handle [dict get $row handle]
        set status [string tolower [lindex [dbGet ${handle}.status] 0]]
        if {$status ne "routed"} {
            error "$label expected routed status for $expected_name, found $status"
        }
        set geometry [mptdc_ckpt_manual_via_geometry $handle]
        set box [dict get $geometry box]
        lassign $point point_x point_y
        set box_width [expr {[lindex $box 2] - [lindex $box 0]}]
        set box_height [expr {[lindex $box 3] - [lindex $box 1]}]
        if {$point_x < [lindex $box 0] || $point_x > [lindex $box 2] ||
            $point_y < [lindex $box 1] || $point_y > [lindex $box 3] ||
            $box_width > 2.0 || $box_height > 2.0} {
            error "$label rejected unexpected geometry box $box for $expected_name at $point"
        }
        set margin 0.02
        set area [list \
            [expr {[lindex $box 0] - $margin}] \
            [expr {[lindex $box 1] - $margin}] \
            [expr {[lindex $box 2] + $margin}] \
            [expr {[lindex $box 3] + $margin}]]
        set token [string toupper [mptdc_ckpt_sanitize $expected_name]]
        puts $fh "${label}_${token}_HANDLE=$handle"
        puts $fh "${label}_${token}_STATUS=$status"
        puts $fh "${label}_${token}_RECT_COUNT=[dict get $geometry rect_count]"
        puts $fh "${label}_${token}_ATTRIBUTE_COUNTS=[dict get $geometry attribute_counts]"
        puts $fh "${label}_${token}_GEOMETRY_BOX=$box"
        puts $fh "${label}_${token}_GEOMETRY_WIDTH=$box_width"
        puts $fh "${label}_${token}_GEOMETRY_HEIGHT=$box_height"
        puts $fh "${label}_${token}_DELETE_AREA=$area"
        set pre_count [llength $current_rows]
        mptdc_ckpt_manual_log_command $fh "${label}_${token}_DELETE" \
            [list editDelete -net $net -area $area -type Regular \
                -object_type Via -via_cell $expected_name]
        set remaining [mptdc_ckpt_manual_vias_at $net $point]
        set remaining_name_count 0
        foreach remaining_row $remaining {
            if {[dict get $remaining_row name] eq $expected_name} {
                incr remaining_name_count
            }
        }
        puts $fh "${label}_${token}_POST_DELETE_VIA_COUNT=[llength $remaining]"
        puts $fh "${label}_${token}_POST_DELETE_NAME_COUNT=$remaining_name_count"
        if {$remaining_name_count != 0 || [llength $remaining] != ($pre_count - 1)} {
            error "$label failed to delete exact via cell $expected_name at $point"
        }
    }

    set remaining [mptdc_ckpt_manual_vias_at $net $point]
    puts $fh "${label}_POST_DELETE_VIA_COUNT=[llength $remaining]"
    if {[llength $remaining] != 0} {
        error "$label failed to delete the exact via stack at $point"
    }
}

proc mptdc_ckpt_manual_add_wire_path {fh label net layer width points} {
    if {[llength $points] < 2} {
        error "$label requires at least two route points"
    }
    set setup [list setEditMode \
        -nets $net \
        -shape None \
        -force_regular 1 \
        -layer_horizontal $layer \
        -layer_vertical $layer \
        -snap_to_track_regular 0 \
        -width_horizontal $width \
        -width_vertical $width]
    mptdc_ckpt_manual_log_command $fh "${label}_SET_EDIT_MODE" $setup
    mptdc_ckpt_manual_log_command $fh "${label}_SET_TOOL" {uiSetTool addWire}
    set start [lindex $points 0]
    mptdc_ckpt_manual_log_command $fh "${label}_START" \
        [list editAddRoute {*}$start]
    set point_idx 0
    foreach point [lrange $points 1 end-1] {
        incr point_idx
        mptdc_ckpt_manual_log_command $fh "${label}_CORNER_${point_idx}" \
            [list editAddRoute {*}$point]
    }
    set finish [lindex $points end]
    mptdc_ckpt_manual_log_command $fh "${label}_COMMIT" \
        [list editCommitRoute {*}$finish]
    catch {uiSetTool select}
    catch {setEditMode -reset}
}

proc mptdc_ckpt_manual_via_name_classes {rows} {
    set via1 0
    set via2 0
    foreach row $rows {
        set name [dict get $row name]
        if {[string match "VIA1*" $name]} {
            incr via1
        }
        if {[string match "VIA2*" $name]} {
            incr via2
        }
    }
    return [list $via1 $via2]
}

proc mptdc_ckpt_manual_via_names_at {net point} {
    set names {}
    foreach row [mptdc_ckpt_manual_vias_at $net $point] {
        lappend names [dict get $row name]
    }
    return [lsort $names]
}

proc mptdc_ckpt_manual_assert_via_names {fh label net point expected_names} {
    set names [mptdc_ckpt_manual_via_names_at $net $point]
    puts $fh "${label}_VIA_NAMES=[join $names ,]"
    if {$names ne [lsort $expected_names]} {
        error "$label expected via names $expected_names at $point, found $names"
    }
    return $names
}

proc mptdc_ckpt_manual_assert_single_via1 {fh label net point} {
    set rows [mptdc_ckpt_manual_vias_at $net $point]
    lassign [mptdc_ckpt_manual_via_name_classes $rows] via1_count via2_count
    set names {}
    foreach row $rows {
        lappend names [dict get $row name]
    }
    puts $fh "${label}_VIA_NAMES=[join [lsort $names] ,]"
    puts $fh "${label}_VIA1_COUNT=$via1_count"
    puts $fh "${label}_VIA2_COUNT=$via2_count"
    if {[llength $rows] != 1 || $via1_count != 1 || $via2_count != 0} {
        error "$label expected exactly one VIA1 at $point, found $names"
    }
    return $rows
}

proc mptdc_ckpt_manual_wire_rows_in_area {net layer area} {
    if {![mptdc_signoff_box_valid $area]} {
        error "wire-area query requires a valid bounded area"
    }
    lassign $area llx lly urx ury
    set matches {}
    foreach row [mptdc_ckpt_manual_wire_rows $net] {
        set box [dict get $row box]
        if {[dict get $row layer] eq $layer &&
            [mptdc_signoff_box_valid $box] &&
            [lindex $box 0] >= $llx && [lindex $box 1] >= $lly &&
            [lindex $box 2] <= $urx && [lindex $box 3] <= $ury} {
            lappend matches $row
        }
    }
    return $matches
}

proc mptdc_ckpt_manual_delete_regular_wire_area {fh label net layer area min_before} {
    if {![mptdc_signoff_box_valid $area]} {
        error "$label requires a valid bounded deletion area"
    }
    set before [mptdc_ckpt_manual_wire_rows_in_area $net $layer $area]
    puts $fh "${label}_PRE_DELETE_WIRE_COUNT=[llength $before]"
    if {[llength $before] < $min_before} {
        error "$label expected at least $min_before bounded wire before deletion"
    }
    mptdc_ckpt_manual_log_command $fh "${label}_DELETE" \
        [list editDelete -net $net -layer $layer -area $area \
            -type Regular -object_type Wire]
    set after [mptdc_ckpt_manual_wire_rows_in_area $net $layer $area]
    puts $fh "${label}_POST_DELETE_WIRE_COUNT=[llength $after]"
    if {[llength $after] != 0} {
        error "$label failed to delete all bounded $layer wire objects"
    }
}

proc mptdc_ckpt_manual_delete_drc_wire_area {fh label net layer area} {
    if {![mptdc_signoff_box_valid $area]} {
        error "$label requires a valid bounded DRC-wire deletion area"
    }
    mptdc_ckpt_manual_log_command $fh "${label}_DELETE" \
        [list editDelete -net $net -layer $layer -area $area \
            -type Regular -regular_wire_with_drc]
}

proc mptdc_ckpt_manual_assert_snapshot_tuple {fh label snapshot expected_drc expected_shorts expected_regular} {
    set actual_drc [dict get $snapshot total_violations]
    set actual_shorts [dict get $snapshot shorts]
    set actual_regular [dict get $snapshot regular_bad]
    set actual_special_non_ro [dict get $snapshot special_non_ro_failures]
    puts $fh "${label}_DRC=$actual_drc"
    puts $fh "${label}_SHORTS=$actual_shorts"
    puts $fh "${label}_REGULAR_CONNECTIVITY_BAD=$actual_regular"
    puts $fh "${label}_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=$actual_special_non_ro"
    if {$actual_drc != $expected_drc ||
        $actual_shorts != $expected_shorts ||
        $actual_regular != $expected_regular ||
        $actual_special_non_ro != 0} {
        error "$label expected tuple DRC=$expected_drc SHORTS=$expected_shorts REGULAR=$expected_regular SPECIAL_NON_RO=0, found DRC=$actual_drc SHORTS=$actual_shorts REGULAR=$actual_regular SPECIAL_NON_RO=$actual_special_non_ro"
    }
    return $snapshot
}

proc mptdc_ckpt_manual_assert_minarea_marker {
        fh label snapshot expected_box expected_actual} {
    if {![dict exists $snapshot marker_rpt]} {
        error "$label snapshot has no marker report"
    }
    set marker_rpt [dict get $snapshot marker_rpt]
    if {![file readable $marker_rpt]} {
        error "$label marker report is not readable: $marker_rpt"
    }

    set geometry_count 0
    set target_count 0
    set target_box {}
    set target_actual UNKNOWN
    set target_required UNKNOWN
    set input [open $marker_rpt r]
    while {[gets $input line] >= 0} {
        set fields [split $line \t]
        if {[llength $fields] < 7 || [lindex $fields 4] ne "Geometry"} {
            continue
        }
        incr geometry_count
        set layer [lindex $fields 3]
        set subtype [lindex $fields 5]
        set message [join [lrange $fields 6 end] \t]
        if {$layer ne "MET1" || $subtype ne "Minimal_Area" ||
            ![regexp {Regular Wire of Net u_core_n_57556[[:space:]]+Actual:[[:space:]]*([0-9.]+)[[:space:]]+Required:[[:space:]]*([0-9.]+)} \
                $message -> actual required]} {
            continue
        }
        set box [mptdc_signoff_flat_box [lindex $fields 2]]
        if {![mptdc_signoff_box_valid $box]} {
            close $input
            error "$label found u_core_n_57556 marker with invalid box: $box"
        }
        incr target_count
        set target_box $box
        set target_actual $actual
        set target_required $required
    }
    close $input

    set box_matches [expr {[llength $target_box] == 4}]
    if {$box_matches} {
        foreach actual $target_box expected $expected_box {
            if {![mptdc_ckpt_manual_close $actual $expected]} {
                set box_matches 0
                break
            }
        }
    }
    set marker_status [expr {
        $geometry_count == 1 && $target_count == 1 && $box_matches &&
        [mptdc_ckpt_manual_close $target_actual $expected_actual 0.00000001] &&
        [mptdc_ckpt_manual_close $target_required 0.20200000 0.00000001]
    }]
    puts $fh "${label}_GEOMETRY_COUNT=$geometry_count"
    puts $fh "${label}_REPORT=$marker_rpt"
    puts $fh "${label}_TARGET_COUNT=$target_count"
    puts $fh "${label}_NET=u_core_n_57556"
    puts $fh "${label}_BOX=$target_box"
    puts $fh "${label}_ACTUAL=$target_actual"
    puts $fh "${label}_REQUIRED=$target_required"
    puts $fh "${label}_STATUS=[expr {$marker_status ? "PASS" : "FAIL"}]"
    if {!$marker_status} {
        error "$label expected the sole geometry marker to be u_core_n_57556 MET1 minimum area $expected_actual/0.202 at $expected_box"
    }
    return $target_box
}

proc mptdc_ckpt_manual_assert_minarea_01064_marker {fh label snapshot} {
    return [mptdc_ckpt_manual_assert_minarea_marker \
        $fh $label $snapshot {385.37 328.3 385.75 328.58} 0.10640000]
}

proc mptdc_ckpt_manual_assert_minarea_01777_marker {fh label snapshot} {
    return [mptdc_ckpt_manual_assert_minarea_marker \
        $fh $label $snapshot {385.06 328.29 385.75 328.52} 0.17770000]
}

proc mptdc_ckpt_manual_find_canonical_via_side_stub {
        fh label net marker_box via_point source_direction_sign} {
    if {$source_direction_sign ni {-1 1}} {
        error "$label source direction must be -1 or 1"
    }
    lassign [mptdc_ckpt_manual_flat_point $via_point] via_x via_y
    if {![string is double -strict $via_x] || ![string is double -strict $via_y]} {
        error "$label requires a numeric via point"
    }

    set candidates {}
    set wire_count 0
    set local_wire_count 0
    set attribute_fail_count 0
    foreach row [mptdc_ckpt_manual_wire_rows $net] {
        incr wire_count
        set handle [dict get $row handle]
        set box [dict get $row box]
        set layer [dict get $row layer]
        set width [dict get $row width]
        set status UNKNOWN
        set shape UNKNOWN
        set length UNKNOWN
        set attribute_failed 0
        foreach attribute {status shape length} {
            if {[catch {set value [lindex [dbGet ${handle}.${attribute}] 0]}]} {
                set attribute_failed 1
            } else {
                set $attribute $value
            }
        }
        if {$attribute_failed} {
            incr attribute_fail_count
        }
        if {$layer ne "MET1" ||
            ![mptdc_ckpt_probe_boxes_overlap $box $marker_box]} {
            continue
        }
        incr local_wire_count
        set row_label [format "%s_LOCAL_ROW_%02d" $label $local_wire_count]
        puts $fh "${row_label}_HANDLE=$handle"
        puts $fh "${row_label}_BOX=$box"
        puts $fh "${row_label}_STATUS=$status"
        puts $fh "${row_label}_SHAPE=$shape"
        puts $fh "${row_label}_WIDTH=$width"
        puts $fh "${row_label}_LENGTH=$length"
        puts $fh "${row_label}_POINTS=[dict get $row pts]"
        if {$attribute_failed || ![string equal -nocase $status fixed] ||
            $shape ne "0x0" ||
            ![mptdc_ckpt_manual_close $width 0.23] ||
            ![mptdc_ckpt_manual_close $length 0.385]} {
            continue
        }

        set points [mptdc_ckpt_manual_flat_values [dict get $row pts]]
        if {[llength $points] < 4} {
            continue
        }
        lassign [lrange $points 0 3] x1 y1 x2 y2
        if {![mptdc_ckpt_manual_close $y1 $y2]} {
            continue
        }
        set near1 [expr {
            [mptdc_ckpt_manual_close $x1 $via_x] && abs($y1 - $via_y) <= 0.050
        }]
        set near2 [expr {
            [mptdc_ckpt_manual_close $x2 $via_x] && abs($y2 - $via_y) <= 0.050
        }]
        if {$near1 == $near2} {
            continue
        }
        if {$near1} {
            set near [list $x1 $y1]
            set far [list $x2 $y2]
        } else {
            set near [list $x2 $y2]
            set far [list $x1 $y1]
        }
        set far_x [lindex $far 0]
        if {($source_direction_sign < 0 && $far_x >= $via_x) ||
            ($source_direction_sign > 0 && $far_x <= $via_x)} {
            continue
        }
        lappend candidates [dict create \
            handle $handle box $box width $width length $length \
            points $points near $near far $far]
    }

    puts $fh "${label}_WIRE_COUNT=$wire_count"
    puts $fh "${label}_LOCAL_WIRE_COUNT=$local_wire_count"
    puts $fh "${label}_ATTRIBUTE_FAIL_COUNT=$attribute_fail_count"
    puts $fh "${label}_CANDIDATE_COUNT=[llength $candidates]"
    if {[llength $candidates] != 1} {
        puts $fh "${label}_STATUS=FAIL"
        error "$label expected exactly one normalized fixed MET1 stub, found [llength $candidates]"
    }
    set candidate [lindex $candidates 0]
    puts $fh "${label}_HANDLE=[dict get $candidate handle]"
    puts $fh "${label}_BOX=[dict get $candidate box]"
    puts $fh "${label}_WIDTH=[dict get $candidate width]"
    puts $fh "${label}_LENGTH=[dict get $candidate length]"
    puts $fh "${label}_POINTS=[dict get $candidate points]"
    puts $fh "${label}_NEAR=[dict get $candidate near]"
    puts $fh "${label}_FAR=[dict get $candidate far]"
    puts $fh "${label}_STATUS=PASS"
    return $candidate
}

proc mptdc_ckpt_manual_add_single_via1 {fh label net point} {
    if {[llength [mptdc_ckpt_manual_vias_at $net $point]] != 0} {
        error "$label expected no existing vias at the new point $point"
    }
    set setup [list setEditMode \
        -nets $net \
        -shape None \
        -force_regular 1 \
        -layer_horizontal MET1 \
        -layer_vertical MET2 \
        -snap_to_track_regular 0 \
        -width_horizontal 0.28 \
        -width_vertical 0.28]
    mptdc_ckpt_manual_log_command $fh "${label}_SET_EDIT_MODE" $setup
    mptdc_ckpt_manual_log_command $fh "${label}_SET_TOOL" {uiSetTool addWire}
    mptdc_ckpt_manual_log_command $fh "${label}_ADD_VIA" \
        [list editAddVia {*}$point]
    catch {uiSetTool select}
    catch {setEditMode -reset}
    set rows [mptdc_ckpt_manual_vias_at $net $point]
    lassign [mptdc_ckpt_manual_via_name_classes $rows] via1_count via2_count
    set names {}
    foreach row $rows {
        lappend names [dict get $row name]
    }
    puts $fh "${label}_VIA_COUNT=[llength $rows]"
    puts $fh "${label}_VIA1_COUNT=$via1_count"
    puts $fh "${label}_VIA2_COUNT=$via2_count"
    puts $fh "${label}_FINAL_VIA_NAMES=[join [lsort $names] ,]"
    if {[llength $rows] != 1 || $via1_count != 1 || $via2_count != 0} {
        error "$label expected exactly one VIA1 at $point, found $names"
    }
}

proc mptdc_ckpt_manual_two_minarea_landing_patch_v1 {} {
    set report_dir [mptdc_signoff_report_dir]
    set report [file join $report_dir min_area_landing_patch_v1.rpt]
    set fh [open $report w]
    puts $fh "# MPTDC Exact Two-Via-Landing Minimum-Area Patch V1"
    puts $fh "MANUAL_ECO_MODE=EXACT_TWO_VIA_LANDING_MIN_AREA_STUBS"
    puts $fh "SOURCE_BASELINE=DRC_2_SHORTS_0_REGULAR_0_SPECIAL_NON_RO_0"
    puts $fh "TARGET_NETS=u_core_n_57960,u_core_n_57556"
    puts $fh "TARGET_VIA_POLICY=u_core_n_57960:VIA1_o@363.72,358.12;u_core_n_57556:VIA1_o@385.56,328.44"
    puts $fh "REPAIR_STUB_POLICY=u_core_n_57960:MET1:363.72,358.12->364.56,358.12;u_core_n_57556:MET1:385.56,328.44->384.72,328.44;width=0.28"
    puts $fh "PIN_CONTAINMENT_EVIDENCE=u_core_g71301/A:NO2JIHDX4:MY;FE_RC_5_0/Q:NO6I5JIHDX2:R180"
    puts $fh "VIA_EDIT_POLICY=NO_VIAS_MODIFIED"
    puts $fh "PG_EDIT_POLICY=NO_PG_SHAPES_MODIFIED"
    puts $fh "PLACEMENT_EDIT_POLICY=NO_INSTANCES_MOVED"

    set body_status [catch {
        set baseline [mptdc_ckpt_verify_snapshot minarea_v1_pre]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh PRE $baseline 2 0 0

        mptdc_ckpt_manual_assert_via_names $fh N57960_LANDING_PRE \
            u_core_n_57960 {363.72 358.12} {VIA1_o}
        mptdc_ckpt_manual_assert_via_names $fh N57556_LANDING_PRE \
            u_core_n_57556 {385.56 328.44} {VIA1_o}

        if {[mptdc_ckpt_manual_wire_covers_point \
                u_core_n_57960 MET1 {364.14 358.12}]} {
            error "u_core_n_57960 target stub midpoint is already covered"
        }
        if {[mptdc_ckpt_manual_wire_covers_point \
                u_core_n_57556 MET1 {385.14 328.44}]} {
            error "u_core_n_57556 target stub midpoint is already covered"
        }

        mptdc_ckpt_manual_add_wire_path $fh N57960_MET1_LANDING_PATCH \
            u_core_n_57960 MET1 0.28 \
            {{363.72 358.12} {364.56 358.12}}
        mptdc_ckpt_manual_add_wire_path $fh N57556_MET1_LANDING_PATCH \
            u_core_n_57556 MET1 0.28 \
            {{385.56 328.44} {384.72 328.44}}

        if {![mptdc_ckpt_manual_wire_covers_point \
                u_core_n_57960 MET1 {364.14 358.12}]} {
            error "u_core_n_57960 MET1 landing patch did not materialize"
        }
        if {![mptdc_ckpt_manual_wire_covers_point \
                u_core_n_57556 MET1 {385.14 328.44}]} {
            error "u_core_n_57556 MET1 landing patch did not materialize"
        }

        mptdc_ckpt_manual_assert_via_names $fh N57960_LANDING_POST \
            u_core_n_57960 {363.72 358.12} {VIA1_o}
        mptdc_ckpt_manual_assert_via_names $fh N57556_LANDING_POST \
            u_core_n_57556 {385.56 328.44} {VIA1_o}

        set final [mptdc_ckpt_verify_snapshot minarea_v1_post]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh POST $final 0 0 0
    } body_error body_opts]

    catch {uiSetTool select}
    catch {setEditMode -reset}
    if {$body_status} {
        puts $fh "MANUAL_ECO_STATUS=FAIL"
        puts $fh "MANUAL_ECO_ERROR=[mptdc_signoff_report_value $body_error]"
        close $fh
        return -options $body_opts $body_error
    }
    puts $fh "MANUAL_ECO_STATUS=PASS"
    puts $fh "MANUAL_ECO_REPORT=$report"
    close $fh
    puts "MPTDC_CKPT_MIN_AREA_LANDING_PATCH_V1_REPORT=$report"
    return [dict create status PASS report $report]
}

proc mptdc_ckpt_manual_two_minarea_landing_patch_v2 {} {
    error "minimum-area V2 is retired after Innovus absorbed the u_core_n_57556 VIA1 handle into normalized route geometry; use mptdc_ckpt_manual_two_minarea_landing_patch_v4"
}

proc mptdc_ckpt_manual_two_minarea_landing_patch_v3 {} {
    error "minimum-area V3 is retired because the DRC-box center y=328.405 is not the routed VIA1 anchor y=328.44 and the final Wire Editor command was a no-op; use mptdc_ckpt_manual_two_minarea_landing_patch_v4"
}

proc mptdc_ckpt_manual_two_minarea_landing_patch_v4 {} {
    set report_dir [mptdc_signoff_report_dir]
    set report [file join $report_dir min_area_landing_patch_v4.rpt]
    set fh [open $report w]
    puts $fh "# MPTDC Staged VIA1-Anchored Outward Minimum-Area Patch V4"
    puts $fh "MANUAL_ECO_MODE=PROVEN_N57960_STUB_THEN_DIRECT_N57556_VIA1_OUTWARD_EXTENSION"
    puts $fh "SOURCE_BASELINE=DRC_2_SHORTS_0_REGULAR_0_SPECIAL_NON_RO_0"
    puts $fh "BASE_EXPECTATION=DRC_1_SHORTS_0_REGULAR_0_U_CORE_N_57556_0.1064_OF_0.202"
    puts $fh "TARGET_NETS=u_core_n_57960,u_core_n_57556"
    puts $fh "BASE_STUB_POLICY=u_core_n_57960:MET1:363.72,358.12->364.56,358.12;width=0.28"
    puts $fh "OUTWARD_PATCH_POLICY=u_core_n_57556:VIA1_o@385.56,328.44->386.12,328.44;width=0.28"
    puts $fh "ANCHOR_POLICY=USE_ORIGINAL_ROUTED_VIA1_CENTER_NOT_DRC_RECTANGLE_CENTER"
    puts $fh "VIA_EDIT_POLICY=NO_EXPLICIT_VIA_COMMANDS"
    puts $fh "PG_EDIT_POLICY=NO_PG_SHAPES_MODIFIED"
    puts $fh "PLACEMENT_EDIT_POLICY=NO_INSTANCES_MOVED"
    puts $fh "ROUTE_OPTIMIZER_POLICY=NO_BROAD_OR_TARGETED_ROUTER_COMMANDS"

    set body_status [catch {
        set baseline [mptdc_ckpt_verify_snapshot minarea_v4_pre]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh PRE $baseline 2 0 0

        mptdc_ckpt_manual_assert_via_names $fh N57960_LANDING_PRE \
            u_core_n_57960 {363.72 358.12} {VIA1_o}
        mptdc_ckpt_manual_assert_via_names $fh N57556_LANDING_PRE \
            u_core_n_57556 {385.56 328.44} {VIA1_o}

        set outward_probe {385.84 328.44}
        set outward_precovered [mptdc_ckpt_manual_wire_covers_point \
            u_core_n_57556 MET1 $outward_probe]
        puts $fh "BASE_OUTWARD_PATCH_PRECOVERED=$outward_precovered"
        if {$outward_precovered} {
            error "u_core_n_57556 outward patch probe is already covered"
        }

        mptdc_ckpt_manual_add_wire_path $fh N57960_BASE_MET1_LANDING_PATCH \
            u_core_n_57960 MET1 0.28 \
            {{363.72 358.12} {364.56 358.12}}

        set base [mptdc_ckpt_verify_snapshot minarea_v4_base]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh BASE $base 1 0 0
        mptdc_ckpt_manual_assert_minarea_01064_marker \
            $fh BASE_MINAREA_MARKER $base
        mptdc_ckpt_manual_assert_via_names $fh N57556_BASE_ANCHOR \
            u_core_n_57556 {385.56 328.44} {VIA1_o}
        puts $fh "BASE_VIA_ANCHOR_STATUS=PASS"

        mptdc_ckpt_manual_add_wire_path $fh N57556_OUTWARD_MET1_PATCH \
            u_core_n_57556 MET1 0.28 \
            {{385.56 328.44} {386.12 328.44}}

        set outward_postcovered [mptdc_ckpt_manual_wire_covers_point \
            u_core_n_57556 MET1 $outward_probe]
        puts $fh "POST_OUTWARD_PATCH_COVERED=$outward_postcovered"
        if {!$outward_postcovered} {
            error "u_core_n_57556 direct VIA1-anchored outward patch did not materialize"
        }

        set final [mptdc_ckpt_verify_snapshot minarea_v4_post]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh POST $final 0 0 0
    } body_error body_opts]

    catch {uiSetTool select}
    catch {setEditMode -reset}
    if {$body_status} {
        puts $fh "MANUAL_ECO_STATUS=FAIL"
        puts $fh "MANUAL_ECO_ERROR=[mptdc_signoff_report_value $body_error]"
        close $fh
        return -options $body_opts $body_error
    }
    puts $fh "MANUAL_ECO_STATUS=PASS"
    puts $fh "MANUAL_ECO_REPORT=$report"
    close $fh
    puts "MPTDC_CKPT_MIN_AREA_LANDING_PATCH_V4_REPORT=$report"
    return [dict create status PASS report $report]
}

proc mptdc_ckpt_manual_three_marker_eco_v4 {} {
    error "manual geometry ECO V4 is retired after editDelete selected no vias; use mptdc_ckpt_manual_three_marker_eco_v7"
}

proc mptdc_ckpt_manual_three_marker_eco_v5 {} {
    error "manual geometry ECO V5 is retired after coincident VIA2 insertion was a no-op; use mptdc_ckpt_manual_three_marker_eco_v7"
}

proc mptdc_ckpt_manual_three_marker_eco_v6 {} {
    error "manual geometry ECO V6 is retired after net.wires could not see the DRC-owned MET2 shape; use mptdc_ckpt_manual_three_marker_eco_v7"
}

proc mptdc_ckpt_manual_three_marker_eco_v7 {} {
    set report_dir [mptdc_signoff_report_dir]
    set report [file join $report_dir manual_geometry_eco_v7.rpt]
    set fh [open $report w]
    puts $fh "# MPTDC Exact Three-Marker Manual Geometry ECO V7"
    puts $fh "MANUAL_ECO_MODE=STAGED_BOUNDED_DRC_WIRE_DELETE_AND_MET2_TRUNK_SPLICE"
    puts $fh "VIA_DELETE_MODE=FULL_GEOMETRY_BOX_AND_EXACT_VIA_CELL"
    puts $fh "OLD_MET2_LANDING_DELETE_MODE=BOUNDED_REGULAR_WIRE_WITH_DRC"
    puts $fh "OBSOLETE_MET3_DELETE_MODE=BOUNDED_REGULAR_WIRE_ONLY"
    puts $fh "VIA_INSERT_MODE=SINGLE_VIA1_ONLY"
    puts $fh "STAGED_TUPLE_GATES=ENABLED"
    puts $fh "REMOTE_VIA2_DELETE=u_core_n_66687:VIA2_o@224.84,179.48;u_core_n_67240:VIA2_o@229.32,225.40"
    puts $fh "REMOTE_MET2_TRUNK_SPLICE=u_core_n_66687:224.84,179.48;u_core_n_67240:229.32,225.40"
    puts $fh "SOURCE_BASELINE=DRC_3_SHORTS_1_REGULAR_0_SPECIAL_NON_RO_0"
    puts $fh "PG_EDIT_POLICY=NO_PG_SHAPES_MODIFIED"
    puts $fh "PLACEMENT_EDIT_POLICY=NO_INSTANCES_MOVED"
    puts $fh "TARGET_NETS=u_core_n_66687,u_core_n_67240,u_core_n_57563"

    set body_status [catch {
        set baseline [mptdc_ckpt_verify_snapshot manual_v7_pre]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh PRE $baseline 3 1 0

        if {![mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET1 {220.64 179.48}] ||
            ![mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET2 {224.84 179.48}] ||
            ![mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET3 {224.84 179.48}]} {
            error "u_core_n_66687 source/remote wire anchors do not match the probe"
        }
        if {![mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET2 {229.32 225.40}] ||
            ![mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET3 {229.32 225.40}]} {
            error "u_core_n_67240 remote wire anchor does not match the probe"
        }
        mptdc_ckpt_manual_assert_via_names $fh N66687_REMOTE_VIA2 \
            u_core_n_66687 {224.84 179.48} {VIA2_o}
        mptdc_ckpt_manual_assert_via_names $fh N67240_REMOTE_VIA2 \
            u_core_n_67240 {229.32 225.40} {VIA2_o}

        mptdc_ckpt_manual_delete_via_stack $fh N66687_OLD_STACK \
            u_core_n_66687 {220.64 179.48} {VIA1_o VIA2_o}
        set n66687_stack_deleted [mptdc_ckpt_verify_snapshot \
            manual_v7_n66687_stack_deleted]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh N66687_STACK_DELETED \
            $n66687_stack_deleted 3 1 1
        mptdc_ckpt_manual_delete_drc_wire_area $fh N66687_OLD_MET2_LANDING \
            u_core_n_66687 MET2 {220.45 179.25 220.85 180.05}
        set n66687_landing_deleted [mptdc_ckpt_verify_snapshot \
            manual_v7_n66687_drc_wire_deleted]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh N66687_DRC_WIRE_DELETED \
            $n66687_landing_deleted 2 0 1
        mptdc_ckpt_manual_delete_via_stack $fh N66687_REMOTE_VIA2 \
            u_core_n_66687 {224.84 179.48} {VIA2_o}
        mptdc_ckpt_manual_delete_regular_wire_area $fh N66687_OBSOLETE_MET3 \
            u_core_n_66687 MET3 {220.43 179.32 225.05 179.64} 1
        mptdc_ckpt_manual_add_wire_path $fh N66687_MET1_ESCAPE \
            u_core_n_66687 MET1 0.23 \
            {{220.64 179.48} {220.64 178.92} {221.20 178.92}}
        mptdc_ckpt_manual_add_single_via1 $fh N66687_NEW_VIA1 \
            u_core_n_66687 {221.20 178.92}
        mptdc_ckpt_manual_add_wire_path $fh N66687_MET2_REMOTE_BRIDGE \
            u_core_n_66687 MET2 0.28 \
            {{221.20 178.92} {224.84 178.92} {224.84 179.48}}
        mptdc_ckpt_manual_assert_single_via1 $fh N66687_NEW_VIA1_POST \
            u_core_n_66687 {221.20 178.92}
        mptdc_ckpt_manual_assert_via_names $fh N66687_REMOTE_VIA2_POST \
            u_core_n_66687 {224.84 179.48} {}
        if {![mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET1 {221.20 178.92}] ||
            ![mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET2 {221.20 178.92}] ||
            ![mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET2 {224.84 179.48}] ||
            [mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET3 {220.64 179.48}] ||
            [mptdc_ckpt_manual_wire_covers_point u_core_n_66687 MET3 {224.84 179.48}]} {
            error "u_core_n_66687 staged remote-MET2 splice did not materialize"
        }
        set n66687_reconnected [mptdc_ckpt_verify_snapshot \
            manual_v7_n66687_reconnected]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh N66687_RECONNECTED \
            $n66687_reconnected 2 0 0

        mptdc_ckpt_manual_delete_via_stack $fh N67240_OLD_STACK \
            u_core_n_67240 {219.80 224.14} {VIA1_Y_so VIA2_so}
        set n67240_stack_deleted [mptdc_ckpt_verify_snapshot \
            manual_v7_n67240_stack_deleted]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh N67240_STACK_DELETED \
            $n67240_stack_deleted 2 0 1
        mptdc_ckpt_manual_delete_drc_wire_area $fh N67240_OLD_MET2_LANDING \
            u_core_n_67240 MET2 {219.62 223.73 219.98 224.55}
        set n67240_landing_deleted [mptdc_ckpt_verify_snapshot \
            manual_v7_n67240_drc_wire_deleted]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh N67240_DRC_WIRE_DELETED \
            $n67240_landing_deleted 1 0 1
        mptdc_ckpt_manual_delete_via_stack $fh N67240_REMOTE_VIA2 \
            u_core_n_67240 {229.32 225.40} {VIA2_o}
        mptdc_ckpt_manual_delete_regular_wire_area $fh N67240_OBSOLETE_MET3 \
            u_core_n_67240 MET3 {219.64 223.93 229.53 225.56} 1
        mptdc_ckpt_manual_add_wire_path $fh N67240_MET1_ESCAPE \
            u_core_n_67240 MET1 0.23 \
            {{219.80 224.14} {219.80 223.58} {221.20 223.58}}
        mptdc_ckpt_manual_add_single_via1 $fh N67240_NEW_VIA1 \
            u_core_n_67240 {221.20 223.58}
        mptdc_ckpt_manual_add_wire_path $fh N67240_MET2_REMOTE_BRIDGE \
            u_core_n_67240 MET2 0.28 \
            {{221.20 223.58} {229.32 223.58} {229.32 225.40}}
        mptdc_ckpt_manual_assert_single_via1 $fh N67240_NEW_VIA1_POST \
            u_core_n_67240 {221.20 223.58}
        mptdc_ckpt_manual_assert_via_names $fh N67240_REMOTE_VIA2_POST \
            u_core_n_67240 {229.32 225.40} {}
        if {![mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET1 {221.20 223.58}] ||
            ![mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET2 {221.20 223.58}] ||
            ![mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET2 {229.32 225.40}] ||
            [mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET3 {219.80 224.14}] ||
            [mptdc_ckpt_manual_wire_covers_point u_core_n_67240 MET3 {229.32 225.40}]} {
            error "u_core_n_67240 staged remote-MET2 splice did not materialize"
        }
        set n67240_reconnected [mptdc_ckpt_verify_snapshot \
            manual_v7_n67240_reconnected]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh N67240_RECONNECTED \
            $n67240_reconnected 1 0 0

        set min_area_vias [mptdc_ckpt_manual_vias_at u_core_n_57563 {364.84 328.44}]
        set min_area_names {}
        foreach row $min_area_vias {
            lappend min_area_names [dict get $row name]
        }
        puts $fh "N57563_LANDING_VIA_NAMES=[join [lsort $min_area_names] ,]"
        if {[lsort $min_area_names] ne {VIA1_X_so}} {
            error "u_core_n_57563 landing via does not match the probe: $min_area_names"
        }
        mptdc_ckpt_manual_add_wire_path $fh N57563_MET1_LANDING_PATCH \
            u_core_n_57563 MET1 0.28 {{364.84 328.44} {365.40 328.44}}

        if {![mptdc_ckpt_manual_wire_covers_point u_core_n_57563 MET1 {365.12 328.44}]} {
            error "u_core_n_57563 MET1 landing patch did not materialize"
        }

        set final [mptdc_ckpt_verify_snapshot manual_v7_post]
        mptdc_ckpt_manual_assert_snapshot_tuple $fh POST $final 0 0 0
    } body_error body_opts]

    catch {uiSetTool select}
    catch {setEditMode -reset}
    if {$body_status} {
        puts $fh "MANUAL_ECO_STATUS=FAIL"
        puts $fh "MANUAL_ECO_ERROR=[mptdc_signoff_report_value $body_error]"
        close $fh
        return -options $body_opts $body_error
    }
    puts $fh "MANUAL_ECO_STATUS=PASS"
    puts $fh "MANUAL_ECO_REPORT=$report"
    close $fh
    puts "MPTDC_CKPT_MANUAL_GEOMETRY_ECO_V7_REPORT=$report"
    return [dict create status PASS report $report]
}

proc mptdc_ckpt_route_selected_nets_with_commands {nets route_commands route_label} {
    set selected [mptdc_ckpt_select_nets $nets]
    puts "MPTDC_CKPT_ROUTE_SELECTED_NET_COUNT=[llength $selected]"
    puts "MPTDC_CKPT_ROUTE_SELECTED_STRATEGY=$route_label"

    # The via-in-pin route modes exposed by Innovus make this checkpoint report
    # thousands of Via_In_Pin DRCs on already-routed std-cell nets. Keep this
    # surgical repair on the selected-net path only.
    catch {setNanoRouteMode -route_with_via_in_pin false}
    catch {setNanoRouteMode -route_with_via_only_for_block_cell_pin false}

    if {[catch {setNanoRouteMode -route_selected_net_only true} err]} {
        error "failed to enable selected-net routing: $err"
    }

    set route_err ""
    set route_status [catch {
        foreach route_command $route_commands {
            puts ""
            puts $route_command
            uplevel #0 $route_command
        }
    } route_err]

    catch {setNanoRouteMode -route_selected_net_only false}
    if {$route_status} {
        error "selected-net route failed: $route_err"
    }
    catch {deselectAll}
    return $selected
}

proc mptdc_ckpt_route_selected_nets {nets} {
    return [mptdc_ckpt_route_selected_nets_with_commands \
        $nets \
        [list {globalDetailRoute -select} {detailRoute -select}] \
        global_detail_plus_detail]
}

proc mptdc_ckpt_route_selected_nets_route_design {nets} {
    return [mptdc_ckpt_route_selected_nets_with_commands \
        $nets \
        [list {routeDesign -selected}] \
        route_design_selected]
}

proc mptdc_ckpt_route_selected_nets_detail_only {nets} {
    return [mptdc_ckpt_route_selected_nets_with_commands \
        $nets \
        [list {detailRoute -select}] \
        detail_only_selected]
}

proc mptdc_ckpt_route_selected_nets_legacy {nets} {
    return [mptdc_ckpt_route_selected_nets_with_commands \
        $nets \
        [list {routeSelectedNet}] \
        route_selected_net_legacy]
}

proc mptdc_ckpt_delete_regular_net_area {net layer box} {
    if {[string trim $net] eq ""} {
        error "mptdc_ckpt_delete_regular_net_area requires a net"
    }
    if {[string trim $layer] eq ""} {
        error "mptdc_ckpt_delete_regular_net_area requires a layer"
    }
    if {[llength $box] != 4} {
        error "mptdc_ckpt_delete_regular_net_area requires box {x1 y1 x2 y2}"
    }
    puts "MPTDC_CKPT_DELETE_REGULAR_NET_AREA_NET=$net"
    puts "MPTDC_CKPT_DELETE_REGULAR_NET_AREA_LAYER=$layer"
    puts "MPTDC_CKPT_DELETE_REGULAR_NET_AREA_BOX=$box"
    editDelete -net $net -layer $layer -area $box -type Regular
    return $box
}

proc mptdc_ckpt_delete_regular_drc_wires {net} {
    if {[string trim $net] eq ""} {
        error "mptdc_ckpt_delete_regular_drc_wires requires a net"
    }
    puts "MPTDC_CKPT_DELETE_REGULAR_DRC_WIRES_NET=$net"
    editDelete -net $net -regular_wire_with_drc
    return $net
}

proc mptdc_ckpt_assert_geometry_clean {} {
    global mptdc_ckpt_inline_assert_idx
    if {![info exists mptdc_ckpt_inline_assert_idx]} {
        set mptdc_ckpt_inline_assert_idx 0
    }
    incr mptdc_ckpt_inline_assert_idx
    set tag [format "inline_%02d_assert_geometry" $mptdc_ckpt_inline_assert_idx]
    set snapshot [mptdc_ckpt_verify_snapshot $tag]
    set total [dict get $snapshot total_violations]
    set shorts [dict get $snapshot shorts]
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_DRC=$total"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_SHORTS=$shorts"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REPORT=[dict get $snapshot drc_rpt]"
    if {$total eq "UNKNOWN" || $shorts eq "UNKNOWN" || $total != 0 || $shorts != 0} {
        error "geometry is not clean after checkpoint repair command: DRC=$total SHORTS=$shorts report=[dict get $snapshot drc_rpt]"
    }
    return $snapshot
}

proc mptdc_ckpt_assert_geometry_regular_clean {} {
    global mptdc_ckpt_inline_assert_idx
    if {![info exists mptdc_ckpt_inline_assert_idx]} {
        set mptdc_ckpt_inline_assert_idx 0
    }
    incr mptdc_ckpt_inline_assert_idx
    set tag [format "inline_%02d_assert_geometry_regular" $mptdc_ckpt_inline_assert_idx]
    set snapshot [mptdc_ckpt_verify_snapshot $tag]
    set total [dict get $snapshot total_violations]
    set shorts [dict get $snapshot shorts]
    set regular_bad [dict get $snapshot regular_bad]
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_DRC=$total"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_SHORTS=$shorts"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_BAD=$regular_bad"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_BAD_LINES=[dict get $snapshot regular_bad_lines]"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_SPECIAL_BAD=[dict get $snapshot special_bad]"
    puts "MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_REPORT=[dict get $snapshot drc_rpt]"
    if {$total eq "UNKNOWN" || $shorts eq "UNKNOWN" || $regular_bad eq "UNKNOWN" || $total != 0 || $shorts != 0 || $regular_bad != 0} {
        error "geometry/regular connectivity is not clean after checkpoint repair command: DRC=$total SHORTS=$shorts REGULAR_BAD=$regular_bad report=[dict get $snapshot drc_rpt]"
    }
    return $snapshot
}

proc mptdc_ckpt_verify_snapshot {tag} {
    set report_dir [mptdc_signoff_report_dir]
    set drc_rpt [file join $report_dir ${tag}_verify_drc.rpt]
    set regular_rpt [file join $report_dir ${tag}_verify_connectivity_regular.rpt]
    set special_rpt [file join $report_dir ${tag}_verify_connectivity_special.rpt]
    set report_route_rpt [file join $report_dir ${tag}_report_route.rpt]
    mptdc_signoff_capture_route_gate_reports $drc_rpt $regular_rpt $special_rpt $report_route_rpt
    lassign [mptdc_signoff_read_route_gate_reports \
        $drc_rpt $regular_rpt $special_rpt $report_route_rpt] drc_data regular_bad special_bad unrouted
    set marker_rpt [file rootname $drc_rpt]_markers.tsv
    if {[dict exists $drc_data marker_report]} {
        set marker_rpt [dict get $drc_data marker_report]
    }
    set unrouted_source UNKNOWN
    if {[dict exists $drc_data unrouted_source]} {
        set unrouted_source [dict get $drc_data unrouted_source]
    }
    set route_gate_pass [mptdc_signoff_route_gate_is_pass \
        $drc_data $regular_bad $special_bad $unrouted]
    return [dict create \
        drc_rpt $drc_rpt \
        regular_rpt $regular_rpt \
        special_rpt $special_rpt \
        report_route_rpt $report_route_rpt \
        marker_rpt $marker_rpt \
        total_violations [dict get $drc_data total_violations] \
        shorts [dict get $drc_data shorts] \
        drc_status [dict get $drc_data status] \
        regular_bad [lindex $regular_bad 0] \
        regular_bad_lines [lindex $regular_bad 1] \
        special_bad [lindex $special_bad 0] \
        special_bad_lines [lindex $special_bad 1] \
        special_raw_bad [lindex $special_bad 2] \
        special_filter_status [lindex $special_bad 3] \
        special_filtered_ro_terminals [lindex $special_bad 4] \
        special_non_ro_failures [lindex $special_bad 5] \
        special_filter_report [lindex $special_bad 6] \
        unrouted $unrouted \
        unrouted_source $unrouted_source \
        route_gate_pass $route_gate_pass]
}

proc mptdc_ckpt_write_snapshot_status {fh prefix snapshot} {
    puts $fh "${prefix}_DRC=[dict get $snapshot total_violations]"
    puts $fh "${prefix}_SHORTS=[dict get $snapshot shorts]"
    puts $fh "${prefix}_DRC_STATUS=[dict get $snapshot drc_status]"
    puts $fh "${prefix}_REGULAR_CONNECTIVITY_BAD=[dict get $snapshot regular_bad]"
    puts $fh "${prefix}_REGULAR_CONNECTIVITY_BAD_LINES=[dict get $snapshot regular_bad_lines]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_BAD=[dict get $snapshot special_bad]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_BAD_LINES=[dict get $snapshot special_bad_lines]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_RAW_BAD=[dict get $snapshot special_raw_bad]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_FILTER_STATUS=[dict get $snapshot special_filter_status]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_FILTERED_RO_TERMINALS=[dict get $snapshot special_filtered_ro_terminals]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=[dict get $snapshot special_non_ro_failures]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_FILTER_REPORT=[dict get $snapshot special_filter_report]"
    puts $fh "${prefix}_UNROUTED_NETS=[dict get $snapshot unrouted]"
    puts $fh "${prefix}_UNROUTED_NETS_SOURCE=[dict get $snapshot unrouted_source]"
    puts $fh "${prefix}_ROUTE_GATE_PASS=[dict get $snapshot route_gate_pass]"
    puts $fh "${prefix}_DRC_REPORT=[dict get $snapshot drc_rpt]"
    puts $fh "${prefix}_REGULAR_CONNECTIVITY_REPORT=[dict get $snapshot regular_rpt]"
    puts $fh "${prefix}_SPECIAL_CONNECTIVITY_REPORT=[dict get $snapshot special_rpt]"
    puts $fh "${prefix}_REPORT_ROUTE=[dict get $snapshot report_route_rpt]"
    puts $fh "${prefix}_MARKER_REPORT=[dict get $snapshot marker_rpt]"
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

set initial_snapshot [mptdc_ckpt_verify_snapshot 00_initial]
mptdc_ckpt_write_snapshot_status $status_fh INITIAL $initial_snapshot

set idx 0
set final_snapshot $initial_snapshot
set command_failure 0
set command_failure_index 0
set command_failure_error ""
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
    set final_snapshot [mptdc_ckpt_verify_snapshot $tag]
    mptdc_ckpt_write_snapshot_status $status_fh COMMAND_${idx}_VERIFY $final_snapshot
    puts $status_fh "COMMAND_${idx}_DRC_REPORT=[dict get $final_snapshot drc_rpt]"
    puts $status_fh "COMMAND_${idx}_MARKER_REPORT=[dict get $final_snapshot marker_rpt]"
    flush $status_fh
    if {!$ok && ![mptdc_ckpt_continue_after_command_fail]} {
        set command_failure 1
        set command_failure_index $idx
        set command_failure_error $err
        break
    }
}

set final_def [file join [mptdc_signoff_def_dir] repaired_route.def]
set final_ckpt [file join [mptdc_signoff_checkpoint_dir] repaired_route.enc]
set final_ckpt_dat "${final_ckpt}.dat"
catch {defOut $final_def}
catch {saveDesign $final_ckpt}

puts $status_fh ""
set final_drc [dict get $final_snapshot total_violations]
set final_shorts [dict get $final_snapshot shorts]
puts $status_fh "FINAL_DRC=$final_drc"
puts $status_fh "FINAL_SHORTS=$final_shorts"
puts $status_fh "FINAL_DRC_STATUS=[dict get $final_snapshot drc_status]"
puts $status_fh "FINAL_REGULAR_CONNECTIVITY_BAD=[dict get $final_snapshot regular_bad]"
puts $status_fh "FINAL_REGULAR_CONNECTIVITY_BAD_LINES=[dict get $final_snapshot regular_bad_lines]"
puts $status_fh "FINAL_SPECIAL_CONNECTIVITY_BAD=[dict get $final_snapshot special_bad]"
puts $status_fh "FINAL_SPECIAL_CONNECTIVITY_BAD_LINES=[dict get $final_snapshot special_bad_lines]"
puts $status_fh "FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=[dict get $final_snapshot special_raw_bad]"
puts $status_fh "FINAL_SPECIAL_CONNECTIVITY_FILTER_STATUS=[dict get $final_snapshot special_filter_status]"
puts $status_fh "FINAL_SPECIAL_CONNECTIVITY_FILTERED_RO_TERMINALS=[dict get $final_snapshot special_filtered_ro_terminals]"
puts $status_fh "FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=[dict get $final_snapshot special_non_ro_failures]"
puts $status_fh "FINAL_SPECIAL_CONNECTIVITY_FILTER_REPORT=[dict get $final_snapshot special_filter_report]"
puts $status_fh "FINAL_UNROUTED_NETS=[dict get $final_snapshot unrouted]"
puts $status_fh "FINAL_UNROUTED_NETS_SOURCE=[dict get $final_snapshot unrouted_source]"
puts $status_fh "FINAL_ROUTE_GATE_PASS=[dict get $final_snapshot route_gate_pass]"
puts $status_fh "FINAL_DRC_REPORT=[dict get $final_snapshot drc_rpt]"
puts $status_fh "FINAL_DRC_MARKER_REPORT=[dict get $final_snapshot marker_rpt]"
puts $status_fh "FINAL_REGULAR_CONNECTIVITY_REPORT=[dict get $final_snapshot regular_rpt]"
puts $status_fh "FINAL_SPECIAL_CONNECTIVITY_REPORT=[dict get $final_snapshot special_rpt]"
puts $status_fh "FINAL_REPORT_ROUTE=[dict get $final_snapshot report_route_rpt]"
puts $status_fh "FINAL_DEF=$final_def"
puts $status_fh "FINAL_CHECKPOINT=$final_ckpt"
puts $status_fh "FINAL_CHECKPOINT_DAT=$final_ckpt_dat"
puts $status_fh "FINAL_CHECKPOINT_DAT_EXISTS=[expr {[file isdirectory $final_ckpt_dat] ? 1 : 0}]"
if {$command_failure} {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=FAIL_COMMAND"
    puts $status_fh "CHECKPOINT_REPAIR_FAILED_COMMAND_INDEX=$command_failure_index"
    puts $status_fh "CHECKPOINT_REPAIR_FAILED_COMMAND_ERROR=$command_failure_error"
    puts $status_fh "CHECKPOINT_REPAIR_KEEP_GOING_ENV=MPTDC_CHECKPOINT_REPAIR_KEEP_GOING"
} elseif {[dict get $final_snapshot route_gate_pass]} {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=PASS_ROUTE_GATE"
} elseif {$final_drc ne "UNKNOWN" && $final_shorts ne "UNKNOWN" && $final_drc == 0 && $final_shorts == 0} {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY_REVIEW_CONNECTIVITY"
} else {
    puts $status_fh "CHECKPOINT_REPAIR_STATUS=REVIEW_REQUIRED"
}
close $status_fh

puts "MPTDC_CHECKPOINT_REPAIR_STATUS_REPORT=$status_rpt"
exit 0
