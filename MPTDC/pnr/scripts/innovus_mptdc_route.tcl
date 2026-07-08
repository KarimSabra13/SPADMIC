# =============================================================================
# Stable MPTDC final-typical route intent and report hooks
# =============================================================================

if {[llength [info commands mptdc_pnr_env]] == 0} {
    proc mptdc_pnr_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_pnr_env_truthy {name default_value} {
    set value [mptdc_pnr_env $name $default_value]
    switch -nocase -- $value {
        1 - true - yes - on { return 1 }
        default { return 0 }
    }
}

proc mptdc_pnr_route_signal_bottom_layer {} {
    return [mptdc_pnr_env MPTDC_PNR_SIGNAL_BOTTOM_LAYER MET1]
}

proc mptdc_pnr_route_signal_top_layer {} {
    return [mptdc_pnr_env MPTDC_PNR_SIGNAL_TOP_LAYER [mptdc_pnr_route_default_signal_top_layer]]
}

proc mptdc_pnr_route_effective_top_floor_layer {} {
    return [mptdc_pnr_env MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER METTP]
}

proc mptdc_pnr_promote_signal_top_to_effective_floor {} {
    return [mptdc_pnr_env_truthy MPTDC_PNR_PROMOTE_SIGNAL_TOP_TO_EFFECTIVE_FLOOR 1]
}

proc mptdc_pnr_allow_special_route_above_signal_top {} {
    return [mptdc_pnr_env_truthy MPTDC_PNR_ALLOW_SPECIAL_ROUTE_ABOVE_SIGNAL_TOP 0]
}

proc mptdc_pnr_keep_router_top_at_effective_floor {} {
    return [mptdc_pnr_env_truthy MPTDC_PNR_KEEP_ROUTER_TOP_AT_EFFECTIVE_FLOOR_FOR_EXISTING_ROUTES 0]
}

proc mptdc_pnr_route_stack_key {} {
    set stack [string tolower [mptdc_pnr_env MPTDC_XH018_STACK xx31]]
    switch -glob -- $stack {
        xx31 - 1131 - xh018_1131 - xh018_xx31 - 1p3m { return xx31 }
        xx33 - 1133 - xh018_1133 - xh018_xx33 { return xx33 }
        xx41 - 1141 - xh018_1141 - xh018_xx41 - 1p4m { return xx41 }
        xx43 - 1143 - xh018_1143 - xh018_xx43 { return xx43 }
        xx51 - 1151 - xh018_1151 - xh018_xx51 - 1p5m { return xx51 }
        default { return $stack }
    }
}

proc mptdc_pnr_route_default_layers_for_stack {} {
    switch -- [mptdc_pnr_route_stack_key] {
        xx31 { return {MET1 MET2 MET3 METTP} }
        xx33 { return {MET1 MET2 MET3 METTP METTHK} }
        xx41 { return {MET1 MET2 MET3 MET4 METTP} }
        xx43 { return {MET1 MET2 MET3 MET4 METTP METTHK} }
        xx51 { return {MET1 MET2 MET3 MET4 MET5 METTP} }
        default { return {MET1 MET2 MET3 METTP} }
    }
}

proc mptdc_pnr_route_known_layer_names {} {
    set env_layers [mptdc_pnr_env MPTDC_PNR_ROUTE_LAYER_NAMES ""]
    if {$env_layers ne ""} {
        return [split $env_layers]
    }
    return [mptdc_pnr_route_default_layers_for_stack]
}

proc mptdc_pnr_route_default_signal_top_layer {} {
    switch -- [mptdc_pnr_route_stack_key] {
        xx31 - xx33 { return MET3 }
        xx41 - xx43 { return MET4 }
        xx51 { return MET5 }
        default { return MET3 }
    }
}

proc mptdc_pnr_route_normalize_layer_value {layer} {
    set value [string trim $layer]
    if {[regexp -nocase {^(layer|route_layer|routing_layer):(.+)$} $value -> _ suffix]} {
        set value [string trim $suffix]
    }
    return [string toupper $value]
}

proc mptdc_pnr_route_layer_index {layer} {
    set value [mptdc_pnr_route_normalize_layer_value $layer]
    if {[string is integer -strict $value]} {
        return $value
    }
    set idx 1
    foreach name [mptdc_pnr_route_known_layer_names] {
        if {[mptdc_pnr_route_normalize_layer_value $name] eq $value} {
            return $idx
        }
        incr idx
    }
    return $layer
}

proc mptdc_pnr_route_layer_name {layer} {
    set value [mptdc_pnr_route_normalize_layer_value $layer]
    if {![string is integer -strict $value]} {
        return $value
    }
    set layers [mptdc_pnr_route_known_layer_names]
    if {$value >= 1 && $value <= [llength $layers]} {
        return [lindex $layers [expr {$value - 1}]]
    }
    return $layer
}

proc mptdc_pnr_route_max_layer_index {} {
    return [llength [mptdc_pnr_route_known_layer_names]]
}

proc mptdc_pnr_route_layer_is_valid {layer} {
    set idx [mptdc_pnr_route_layer_index $layer]
    if {![string is integer -strict $idx]} {
        return 0
    }
    return [expr {$idx >= 1 && $idx <= [mptdc_pnr_route_max_layer_index]}]
}

proc mptdc_pnr_route_layer_value_status {value} {
    if {$value eq "" || $value eq "UNKNOWN"} {
        return UNKNOWN
    }
    return [expr {[mptdc_pnr_route_layer_is_valid $value] ? "PASS" : "FAIL"}]
}

proc mptdc_pnr_route_effective_top_layer {requested_top} {
    set requested_idx [mptdc_pnr_route_layer_index $requested_top]
    set floor [mptdc_pnr_route_effective_top_floor_layer]
    set floor_idx [mptdc_pnr_route_layer_index $floor]
    set effective $requested_top
    set effective_idx $requested_idx
    set reason requested
    set promote_to_floor [mptdc_pnr_promote_signal_top_to_effective_floor]
    if {$promote_to_floor &&
        [string is integer -strict $requested_idx] &&
        [string is integer -strict $floor_idx] &&
        $requested_idx < $floor_idx} {
        set effective $floor
        set effective_idx $floor_idx
        set reason promoted_to_post_cts_existing_route_floor
    } elseif {!$promote_to_floor &&
              [string is integer -strict $requested_idx] &&
              [string is integer -strict $floor_idx] &&
              $requested_idx < $floor_idx} {
        set reason requested_signal_top_preserved
    }
    return [list top $effective top_index $effective_idx reason $reason requested_top $requested_top requested_top_index $requested_idx floor_top $floor floor_top_index $floor_idx promote_signal_top_to_effective_floor $promote_to_floor]
}

proc mptdc_pnr_route_command_top_layer {requested_top} {
    set effective_top [mptdc_pnr_route_effective_top_layer $requested_top]
    set router_top [dict get $effective_top top]
    set router_top_idx [dict get $effective_top top_index]
    set router_reason [dict get $effective_top reason]
    set keep_floor [mptdc_pnr_keep_router_top_at_effective_floor]
    set floor [dict get $effective_top floor_top]
    set floor_idx [dict get $effective_top floor_top_index]
    if {$keep_floor &&
        [string is integer -strict [dict get $effective_top top_index]] &&
        [string is integer -strict $floor_idx] &&
        [dict get $effective_top top_index] < $floor_idx} {
        set router_top $floor
        set router_top_idx $floor_idx
        set router_reason existing_route_floor_required_by_nanroute
    }
    return [dict merge $effective_top [list router_top $router_top router_top_index $router_top_idx router_top_reason $router_reason keep_router_top_at_effective_floor $keep_floor]]
}

proc mptdc_pnr_route_try_command {commands} {
    set errors [list]
    foreach cmd $commands {
        if {![catch {uplevel #0 $cmd} err]} {
            return [dict create status PASS command $cmd errors $errors]
        }
        lappend errors "$cmd: $err"
    }
    return [dict create status FAIL command "" errors $errors]
}

proc mptdc_pnr_route_apply_limit {kind value value_idx} {
    if {$kind eq "bottom"} {
        set design_opt -bottomRoutingLayer
        set nano_opt -routeBottomRoutingLayer
        set nano_legacy_opt -route_bottom_routing_layer
    } else {
        set design_opt -topRoutingLayer
        set nano_opt -routeTopRoutingLayer
        set nano_legacy_opt -route_top_routing_layer
    }
    return [mptdc_pnr_route_try_command [list \
        [list setDesignMode $design_opt $value_idx] \
        [list setDesignMode $design_opt $value] \
        [list setNanoRouteMode $nano_opt $value_idx] \
        [list setNanoRouteMode $nano_legacy_opt $value_idx]]]
}

proc mptdc_pnr_route_flatten_values {value} {
    set out [list]
    foreach item $value {
        if {[llength $item] > 1} {
            foreach sub [mptdc_pnr_route_flatten_values $item] {
                lappend out $sub
            }
        } else {
            lappend out $item
        }
    }
    return $out
}

proc mptdc_pnr_route_update_max_layer {var_name values} {
    upvar 1 $var_name max_idx
    foreach value [mptdc_pnr_route_flatten_values $values] {
        set idx [mptdc_pnr_route_layer_index $value]
        if {[string is integer -strict $idx] && $idx > $max_idx && $idx <= [mptdc_pnr_route_max_layer_index]} {
            set max_idx $idx
        }
    }
}

proc mptdc_pnr_route_query_existing_layer_values {fh {include_special 1}} {
    set max_idx 0
    set query_count 0
    puts $fh "EXISTING_LAYER_QUERY_INCLUDE_SPECIAL=$include_special"
    set commands [list \
        {dbGet top.nets.wires.layer.name} \
        {dbGet top.nets.wires.layer.num}]
    if {$include_special} {
        lappend commands \
            {dbGet top.nets.sWires.layer.name} \
            {dbGet top.nets.sWires.layer.num} \
            {dbGet top.nets.shapes.layer.name}
    }
    foreach cmd $commands {
        if {[catch {set values [uplevel #0 $cmd]} err] || $values eq "" || $values eq "0x0"} {
            puts $fh "EXISTING_LAYER_QUERY_STATUS=SKIPPED command={$cmd} error={$err}"
            continue
        }
        incr query_count
        mptdc_pnr_route_update_max_layer max_idx $values
        puts $fh "EXISTING_LAYER_QUERY_STATUS=PASS command={$cmd} values_seen=[llength [mptdc_pnr_route_flatten_values $values]]"
    }
    if {$max_idx <= 0} {
        return [dict create max_index UNKNOWN max_layer UNKNOWN query_count $query_count]
    }
    return [dict create max_index $max_idx max_layer [mptdc_pnr_route_layer_name $max_idx] query_count $query_count]
}

proc mptdc_pnr_route_audit_value {fh invalid_var label value} {
    upvar 1 $invalid_var invalid
    set status [mptdc_pnr_route_layer_value_status $value]
    puts $fh "LAYER_VALUE label={$label} value={$value} status=$status"
    if {$status eq "FAIL"} {
        lappend invalid "$label=$value"
    }
}

proc mptdc_pnr_route_db_attrs_for {object} {
    global mptdc_pnr_route_attr_cache
    if {$object eq ""} { return [list] }
    set key "$object"
    if {[info exists mptdc_pnr_route_attr_cache($key)]} {
        return $mptdc_pnr_route_attr_cache($key)
    }

    set attrs [list]
    if {![catch {set raw_attrs [get_db $object .?]}]} {
        if {[catch {
            foreach raw $raw_attrs {
                set token [string trim [lindex $raw 0]]
                if {$token eq ""} { continue }
                lappend attrs $token
            }
        }]} {
            foreach raw [split "$raw_attrs" "\n"] {
                set token [string trim $raw]
                if {$token eq ""} { continue }
                lappend attrs $token
            }
        }
    }
    set mptdc_pnr_route_attr_cache($key) $attrs
    return $attrs
}

proc mptdc_pnr_route_db_attr_supported {object attr} {
    set attr_name [string trimleft $attr .]
    if {$attr_name eq ""} { return 0 }
    set parent [lindex [split $attr_name "."] 0]
    foreach raw_attr [mptdc_pnr_route_db_attrs_for $object] {
        set norm [string trimleft $raw_attr .]
        if {$norm eq $attr_name} {
            return 1
        }
        if {[string first "." $attr_name] >= 0 && $norm eq $parent} {
            return 1
        }
    }
    return 0
}

proc mptdc_pnr_route_audit_object_attrs {fh invalid_var object_label objects attrs {limit 20000}} {
    upvar 1 $invalid_var invalid
    set scanned 0
    foreach obj $objects {
        incr scanned
        if {$scanned > $limit} {
            puts $fh "OBJECT_AUDIT_TRUNCATED object_type=$object_label limit=$limit"
            break
        }
        set obj_name $obj
        catch {set obj_name [get_db $obj .name]}
        foreach attr $attrs {
            if {![mptdc_pnr_route_db_attr_supported $obj $attr]} {
                continue
            }
            if {[catch {set value [get_db $obj $attr]} err] || $value eq "" || $value eq "0x0"} {
                continue
            }
            foreach flat_value [mptdc_pnr_route_flatten_values $value] {
                mptdc_pnr_route_audit_value $fh invalid "${object_label}:${obj_name}:${attr}" $flat_value
            }
        }
    }
    puts $fh "OBJECT_AUDIT_COUNT object_type=$object_label scanned=$scanned"
}

proc mptdc_pnr_audit_route_layers {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_ROUTE_LAYER_AUDIT_REPORT route_layer_audit.rpt]
    }
    file mkdir [file dirname $path]
    set fh [open $path w]
    set invalid [list]
    set requested_bottom [mptdc_pnr_route_signal_bottom_layer]
    set requested_top [mptdc_pnr_route_signal_top_layer]
    set effective_top [mptdc_pnr_route_effective_top_layer $requested_top]
    puts $fh "# MPTDC Route Layer Audit"
    puts $fh "KNOWN_ROUTE_LAYERS=[mptdc_pnr_route_known_layer_names]"
    puts $fh "ORDINARY_SIGNAL_PREFERRED_TOP_LAYER=$requested_top"
    puts $fh "GLOBAL_ROUTE_TOP_LAYER=[dict get $effective_top top]"
    puts $fh "GLOBAL_ROUTE_TOP_LAYER_INDEX=[dict get $effective_top top_index]"
    puts $fh "GLOBAL_ROUTE_TOP_REASON=[dict get $effective_top reason]"
    puts $fh "SIGNAL_TOP_PROMOTION_TO_EFFECTIVE_FLOOR=[dict get $effective_top promote_signal_top_to_effective_floor]"
    set allow_special_above [mptdc_pnr_allow_special_route_above_signal_top]
    puts $fh "SPECIAL_ROUTE_ABOVE_SIGNAL_TOP_ALLOWED=$allow_special_above"
    mptdc_pnr_route_audit_value $fh invalid requested_signal_bottom_layer $requested_bottom
    mptdc_pnr_route_audit_value $fh invalid requested_signal_top_layer $requested_top
    mptdc_pnr_route_audit_value $fh invalid effective_global_top_layer [dict get $effective_top top]

    set existing [mptdc_pnr_route_query_existing_layer_values $fh [expr {!$allow_special_above}]]
    puts $fh "HIGHEST_EXISTING_ROUTE_LAYER=[dict get $existing max_layer]"
    puts $fh "HIGHEST_EXISTING_ROUTE_LAYER_INDEX=[dict get $existing max_index]"
    set existing_idx [dict get $existing max_index]
    set effective_top_idx [dict get $effective_top top_index]
    puts $fh "EXISTING_ROUTE_ABOVE_GLOBAL_TOP_STATUS=PASS"
    if {$existing_idx ne "UNKNOWN" &&
        [string is integer -strict $effective_top_idx] &&
        $existing_idx > $effective_top_idx} {
        if {$allow_special_above} {
            puts $fh "EXISTING_ROUTE_ABOVE_GLOBAL_TOP_STATUS=ALLOWED_SPECIAL_TOP_METAL"
            puts $fh "EXISTING_ROUTE_ABOVE_GLOBAL_TOP_REASON=simple_pg_metTP_shapes_may_be_reported_by_top_nets_wires"
        } else {
            puts $fh "EXISTING_ROUTE_ABOVE_GLOBAL_TOP_STATUS=FAIL"
            lappend invalid "existing_route_layer_above_global_top=[dict get $existing max_layer]"
        }
    }

    set attrs [list \
        .top_preferred_routing_layer \
        .bottom_preferred_routing_layer \
        .top_preferred_layer \
        .bottom_preferred_layer \
        .route_top_layer \
        .route_bottom_layer \
        .top_layer \
        .bottom_layer]
    set scan_limit [mptdc_pnr_env MPTDC_PNR_ROUTE_LAYER_AUDIT_MAX_OBJECTS 20000]
    foreach item [list \
        [list nets {get_db nets}] \
        [list timing_nets {get_nets -quiet *}] \
        [list route_types {get_db route_types}]] {
        set label [lindex $item 0]
        set cmd [lindex $item 1]
        if {[catch {set objects [uplevel #0 $cmd]} err] || $objects eq "" || $objects eq "0x0"} {
            puts $fh "OBJECT_AUDIT_STATUS=SKIPPED object_type=$label command={$cmd} error={$err}"
            continue
        }
        puts $fh "OBJECT_AUDIT_STATUS=PASS object_type=$label object_count=[llength $objects]"
        mptdc_pnr_route_audit_object_attrs $fh invalid $label $objects $attrs $scan_limit
    }

    set status [expr {[llength $invalid] == 0 ? "PASS" : "FAIL"}]
    puts $fh "ROUTE_LAYER_AUDIT_STATUS=$status"
    puts $fh "INVALID_ROUTE_LAYER_ATTRIBUTE_COUNT=[llength $invalid]"
    foreach item $invalid {
        puts $fh "INVALID_ROUTE_LAYER_ATTRIBUTE=$item"
    }
    close $fh
    return [dict create status $status report $path invalid $invalid highest_existing_layer [dict get $existing max_layer] highest_existing_layer_index [dict get $existing max_index] effective_top [dict get $effective_top top] effective_top_index [dict get $effective_top top_index]]
}

proc mptdc_pnr_route_power_top_policy {} {
    return {reserve_top_metal_mainly_for_power}
}

proc mptdc_pnr_route_protection_rules {} {
    return [list \
        {do_not_false_path_fast_tag_to_pd_ts} \
        {do_not_multicycle_fast_tag_to_pd_ts} \
        {keep_fast_tag_bits_0_5_6_routes_short} \
        {avoid_wide_clk_sys_backend_routes_over_pd_island} \
        {do_not_buffer_raw_ro_nets} \
        {do_not_resize_or_replace_buhdx4_buhdx12_phase_root_drivers_without_review} \
        "use_[mptdc_pnr_route_signal_bottom_layer]_through_[mptdc_pnr_route_signal_top_layer]_for_signal_routing" \
        [mptdc_pnr_route_power_top_policy] \
    ]
}

proc mptdc_pnr_write_route_intent {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_ROUTE_INTENT_REPORT mptdc_route_intent.rpt]
    }
    set effective_top [mptdc_pnr_route_effective_top_layer [mptdc_pnr_route_signal_top_layer]]
    set route_top [mptdc_pnr_route_command_top_layer [mptdc_pnr_route_signal_top_layer]]
    set fh [open $path w]
    puts $fh "# MPTDC Final Typical Route Intent"
    puts $fh "xh018_stack=[mptdc_pnr_route_stack_key]"
    puts $fh "known_route_layers=[mptdc_pnr_route_known_layer_names]"
    puts $fh "signal_bottom_layer=[mptdc_pnr_route_signal_bottom_layer]"
    puts $fh "signal_top_layer=[mptdc_pnr_route_signal_top_layer]"
    puts $fh "effective_route_top_layer=[dict get $effective_top top]"
    puts $fh "effective_route_top_layer_index=[dict get $effective_top top_index]"
    puts $fh "effective_route_top_reason=[dict get $effective_top reason]"
    puts $fh "promote_signal_top_to_effective_floor=[dict get $effective_top promote_signal_top_to_effective_floor]"
    puts $fh "allow_special_route_above_signal_top=[mptdc_pnr_allow_special_route_above_signal_top]"
    puts $fh "router_command_top_layer=[dict get $route_top router_top]"
    puts $fh "router_command_top_layer_index=[dict get $route_top router_top_index]"
    puts $fh "router_command_top_reason=[dict get $route_top router_top_reason]"
    puts $fh "keep_router_top_at_effective_floor=[dict get $route_top keep_router_top_at_effective_floor]"
    puts $fh "top_metal_policy=[mptdc_pnr_route_power_top_policy]"
    puts $fh "FAST_TAG_TO_PD_TS_TIMED=YES"
    puts $fh "FAST_TAG_TO_PD_TS_POSTROUTE_CLEAN=REVIEW_AFTER_ROUTE"
    puts $fh "route_length_report=reports/fast_tag_to_pd_route_lengths.csv"
    puts $fh "timing_report=reports/fast_tag_to_pd_timing_post_route.rpt"
    puts $fh "rules=[join [mptdc_pnr_route_protection_rules] {; }]"
    close $fh
    return $path
}

proc mptdc_pnr_apply_route_layer_limits {} {
    set bottom [mptdc_pnr_route_signal_bottom_layer]
    set top [mptdc_pnr_route_signal_top_layer]
    set bottom_idx [mptdc_pnr_route_layer_index $bottom]
    set route_top [mptdc_pnr_route_command_top_layer $top]
    set top_idx [dict get $route_top router_top_index]
    set router_top_layer [dict get $route_top router_top]
    if {![mptdc_pnr_route_layer_is_valid $bottom] || ![mptdc_pnr_route_layer_is_valid $router_top_layer]} {
        error "MPTDC_ROUTE_LAYER_LIMIT_INVALID: bottom=$bottom router_top=$router_top_layer"
    }
    set bottom_apply [mptdc_pnr_route_apply_limit bottom $bottom $bottom_idx]
    set top_apply [mptdc_pnr_route_apply_limit top $router_top_layer $top_idx]
    set bottom_apply_status [dict get $bottom_apply status]
    set top_apply_status [dict get $top_apply status]
    if {$bottom_apply_status ne "PASS" || $top_apply_status ne "PASS"} {
        error "MPTDC_ROUTE_LAYER_LIMIT_APPLY_FAILED: bottom_errors=[dict get $bottom_apply errors] top_errors=[dict get $top_apply errors]"
    }
    return [dict merge $route_top [list \
        bottom $bottom \
        bottom_index $bottom_idx \
        bottom_apply_command [dict get $bottom_apply command] \
        top_apply_command [dict get $top_apply command] \
        ordinary_signal_top $top \
        ordinary_signal_top_index [mptdc_pnr_route_layer_index $top] \
        top $router_top_layer \
        top_index $top_idx \
        reason [dict get $route_top router_top_reason]]]
}

proc mptdc_pnr_write_fast_tag_route_lengths_template {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_FAST_TAG_ROUTE_LENGTHS reports/fast_tag_to_pd_route_lengths.csv]
    }
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "tap,bit,source register,endpoint PD cell,endpoint row,endpoint col,route length,cap,transition,slack,path class"
    puts $fh "NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,REPORT_AFTER_ROUTE"
    close $fh
    return $path
}

proc mptdc_pnr_write_fast_tag_timing_template {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_FAST_TAG_TIMING_REPORT reports/fast_tag_to_pd_timing_post_route.rpt]
    }
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "FAST_TAG_TO_PD_TS_POSTROUTE_CLEAN=REVIEW_AFTER_ROUTE"
    puts $fh "FAST_TAG_TO_PD_TS_FALSE_PATH=NO"
    puts $fh "FAST_TAG_TO_PD_TS_MULTICYCLE=NO"
    puts $fh {required_path=fast_tag_col[nf][bit] -> PD nfast_hit_latched[bit]}
    close $fh
    return $path
}
