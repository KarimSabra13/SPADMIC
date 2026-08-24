# =============================================================================
# O10/O10.2 top-level IO pin placement
# =============================================================================

if {[llength [info commands mptdc_o10_env]] == 0} {
    proc mptdc_o10_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_o10_io_pin_enabled {} {
    return [mptdc_o10_env MPTDC_PNR_PLACE_IO_PINS 1]
}

proc mptdc_o10_io_pin_layer {} {
    return [mptdc_o10_env MPTDC_PNR_IO_PIN_LAYER MET3]
}

proc mptdc_o10_io_pin_spacing_um {} {
    return [mptdc_o10_env MPTDC_PNR_IO_PIN_SPACING_UM 2.0]
}

proc mptdc_o10_io_pin_width_um {} {
    return [mptdc_o10_env MPTDC_PNR_IO_PIN_WIDTH_UM 0.4]
}

proc mptdc_o10_io_pin_depth_um {} {
    return [mptdc_o10_env MPTDC_PNR_IO_PIN_DEPTH_UM 0.8]
}

proc mptdc_o10_io_pin_side_for_name {pin_name} {
    foreach south_pin {
        async_rst_n
        reset_n
        rst_n
        ro_slow_tap0_o
        ro_fast_tap0_o
        VDD
        VSS
        vdd
        vss
    } {
        if {$pin_name eq $south_pin} {
            return SOUTH
        }
    }
    foreach west_pin {
        start_spad_async_i
        stop_spad_async_i
        cal_start_async_i
        cal_stop_async_i
    } {
        if {$pin_name eq $west_pin} {
            return WEST
        }
    }
    foreach north_pattern {
        {^pkt_data_o(\[[0-9]+\])?$}
        {^pkt_valid_o$}
        {^pkt_sop_o$}
        {^pkt_eop_o$}
        {^packet_active_o$}
        {^packet_pending_o$}
    } {
        if {[regexp $north_pattern $pin_name]} {
            return NORTH
        }
    }
    return EAST
}

proc mptdc_o10_io_pin_command_side {logical_side} {
    switch -- $logical_side {
        WEST { return LEFT }
        EAST { return RIGHT }
        NORTH { return TOP }
        SOUTH { return BOTTOM }
        default { return $logical_side }
    }
}

proc mptdc_o10_io_unique_append {var_name value} {
    upvar 1 $var_name values
    if {$value eq ""} {
        return
    }
    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}

proc mptdc_o10_io_object_names {objects} {
    set names [list]
    if {[llength $objects] == 0} {
        return $names
    }
    if {[llength [info commands mptdc_o10_object_names]] > 0} {
        foreach name [mptdc_o10_object_names $objects] {
            mptdc_o10_io_unique_append names "$name"
        }
        return $names
    }
    if {![catch {get_object_name $objects} obj_names]} {
        foreach name $obj_names {
            mptdc_o10_io_unique_append names "$name"
        }
        return $names
    }
    if {![catch {get_db $objects .name} obj_names]} {
        foreach name $obj_names {
            mptdc_o10_io_unique_append names "$name"
        }
        return $names
    }
    foreach obj $objects {
        mptdc_o10_io_unique_append names "$obj"
    }
    return $names
}

proc mptdc_o10_io_pin_port_names {} {
    set ports [list]
    if {[catch {set ports [get_ports -quiet *]}]} {
        catch {set ports [get_ports *]}
    }
    return [lsort -dictionary [mptdc_o10_io_object_names $ports]]
}

proc mptdc_o10_io_pin_direction {pin_name} {
    set direction UNKNOWN
    set port [list]
    if {![catch {set port [get_ports -quiet $pin_name]}] && [llength $port] > 0} {
        foreach attr {.direction direction} {
            if {![catch {set value [get_db $port $attr]}] && $value ne ""} {
                set direction $value
                break
            }
        }
    }
    return $direction
}

proc mptdc_o10_io_pin_apply_side {logical_side pins} {
    if {[llength $pins] == 0} {
        return [list SKIPPED "no pins"]
    }

    set side [mptdc_o10_io_pin_command_side $logical_side]
    set side_lc [string tolower $side]
    set layer [mptdc_o10_io_pin_layer]
    set spacing [mptdc_o10_io_pin_spacing_um]
    set width [mptdc_o10_io_pin_width_um]
    set depth [mptdc_o10_io_pin_depth_um]
    set last_err ""

    foreach attempt [list \
        [list $side 1 1] \
        [list $side 1 0] \
        [list $side 0 0] \
        [list $side_lc 1 1] \
        [list $side_lc 1 0] \
        [list $side_lc 0 0] \
    ] {
        set cmd_side [lindex $attempt 0]
        set use_size [lindex $attempt 1]
        set use_fixed [lindex $attempt 2]
        if {$use_size && $use_fixed} {
            if {![catch {
                editPin -pin $pins -side $cmd_side -layer $layer \
                    -spreadType SIDE -spacing $spacing \
                    -pinWidth $width -pinDepth $depth -fixedPin 1
            } err]} {
                return [list OK "editPin sized fixed $cmd_side $layer"]
            }
        } elseif {$use_size} {
            if {![catch {
                editPin -pin $pins -side $cmd_side -layer $layer \
                    -spreadType SIDE -spacing $spacing \
                    -pinWidth $width -pinDepth $depth
            } err]} {
                return [list OK "editPin sized $cmd_side $layer"]
            }
        } else {
            if {![catch {
                editPin -pin $pins -side $cmd_side -layer $layer \
                    -spreadType SIDE -spacing $spacing
            } err]} {
                return [list OK "editPin spread $cmd_side $layer"]
            }
        }
        set last_err $err
    }

    return [list FAILED $last_err]
}

proc mptdc_o10_place_io_pins {} {
    global o10
    file mkdir $o10(reports_dir)
    set csv "$o10(reports_dir)/io_pin_placement.csv"
    set summary "$o10(reports_dir)/io_pin_placement_summary.md"

    set enabled [mptdc_o10_io_pin_enabled]
    set ports [mptdc_o10_io_pin_port_names]
    array set pins_by_side {WEST {} EAST {} NORTH {} SOUTH {}}
    foreach pin $ports {
        set side [mptdc_o10_io_pin_side_for_name $pin]
        lappend pins_by_side($side) $pin
    }

    set statuses [list]
    if {$enabled} {
        foreach side {WEST EAST NORTH SOUTH} {
            set result [mptdc_o10_io_pin_apply_side $side $pins_by_side($side)]
            lappend statuses [list $side [lindex $result 0] [lindex $result 1]]
        }
    } else {
        foreach side {WEST EAST NORTH SOUTH} {
            lappend statuses [list $side SKIPPED "MPTDC_PNR_PLACE_IO_PINS=0"]
        }
    }

    set fh [open $csv w]
    puts $fh "pin,direction,side,layer,status"
    foreach pin $ports {
        set side [mptdc_o10_io_pin_side_for_name $pin]
        if {$enabled} {
            set status REQUESTED
        } else {
            set status SKIPPED
        }
        puts $fh "\"$pin\",[mptdc_o10_io_pin_direction $pin],$side,[mptdc_o10_io_pin_layer],$status"
    }
    close $fh

    set pass 1
    foreach row $statuses {
        if {[lindex $row 1] eq "FAILED"} {
            set pass 0
        }
    }

    set fh [open $summary w]
    puts $fh "# O10.2 IO Pin Placement Summary"
    puts $fh ""
    if {$pass} {
        puts $fh "REPORT_STATUS=OK"
    } else {
        puts $fh "REPORT_STATUS=FAILED"
    }
    puts $fh ""
    puts $fh "- Enabled: `$enabled`"
    puts $fh "- Layer: `[mptdc_o10_io_pin_layer]`"
    puts $fh "- Spacing um: `[mptdc_o10_io_pin_spacing_um]`"
    puts $fh "- Total ports: `[llength $ports]`"
    puts $fh "- West ports: `[llength $pins_by_side(WEST)]`"
    puts $fh "- East ports: `[llength $pins_by_side(EAST)]`"
    puts $fh "- North ports: `[llength $pins_by_side(NORTH)]`"
    puts $fh "- South ports: `[llength $pins_by_side(SOUTH)]`"
    puts $fh ""
    puts $fh "| Side | Status | Notes |"
    puts $fh "|---|---:|---|"
    foreach row $statuses {
        puts $fh "| [lindex $row 0] | [lindex $row 1] | `[lindex $row 2]` |"
    }
    puts $fh ""
    puts $fh "North side carries the product 16-bit packet output bus and packet framing/status stream pins."
    puts $fh "West side is reserved for SPAD and calibration asynchronous detector inputs."
    puts $fh "East side carries clk_sys, packet ready, mode/control, max_hits, and minimal status pins."
    puts $fh "South side carries async reset when present and the two buffered RO tap0 observability pins. VDD/VSS are special power nets handled by the power-grid plan, not ordinary signal IO ports."
    close $fh

    if {!$pass} {
        error "IO pin placement failed; see $summary"
    }
    return $summary
}
