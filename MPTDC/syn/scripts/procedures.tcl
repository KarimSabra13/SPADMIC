# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : procedures.tcl
# Purpose  : Reusable helper procedures for synthesis and PnR flows
# Author   : Karim Sabra
# =============================================================================
# Inspired by enics-labs/rtl2gds-demo procedures.
# Provides: stage tracking, message formatting, timing report helpers,
#           cost group definitions, and debug utilities.
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# Global stage tracking
# ─────────────────────────────────────────────────────────────────────────────
if {![info exists this_run]} {
    array set this_run {
        stage       "init"
        stage_count 0
        start_time  0
    }
    set this_run(start_time) [clock seconds]
}

# ─────────────────────────────────────────────────────────────────────────────
# mptdc_start_stage — Mark the beginning of a flow stage
# ─────────────────────────────────────────────────────────────────────────────
# Usage: mptdc_start_stage "synthesis"
# Creates report subdirectory and prints a banner.
proc mptdc_start_stage {stage_name} {
    global this_run design

    incr this_run(stage_count)
    set this_run(stage) $stage_name

    set elapsed [expr {[clock seconds] - $this_run(start_time)}]
    set mins [expr {$elapsed / 60}]
    set secs [expr {$elapsed % 60}]

    puts ""
    puts "================================================================"
    puts " Stage $this_run(stage_count): [string toupper $stage_name]"
    puts " Elapsed: ${mins}m ${secs}s"
    puts "================================================================"

    # Create report subdirectory for this stage
    if {[info exists design(synthesis_reports)]} {
        file mkdir "$design(synthesis_reports)/$stage_name"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# mptdc_message — Formatted info/warning message
# ─────────────────────────────────────────────────────────────────────────────
# Usage: mptdc_message "Loading libraries" [low|medium|high]
proc mptdc_message {msg {level "medium"}} {
    set prefix "MPTDC_INFO"
    switch $level {
        low     { set prefix "MPTDC_DEBUG" }
        medium  { set prefix "MPTDC_INFO" }
        high    { set prefix "MPTDC_WARN" }
    }
    puts "$prefix: $msg"
}

proc mptdc_write_report_failure {rpt_file title err} {
    set fh [open $rpt_file w]
    puts $fh "$title could not be generated."
    puts $fh ""
    puts $fh $err
    close $fh
}

proc mptdc_run_report {cmd rpt_file title} {
    if {[catch {eval $cmd > $rpt_file} err]} {
        mptdc_write_report_failure $rpt_file $title $err
    }
}

proc mptdc_run_report_candidates {cmds rpt_file title} {
    set errors [list]
    foreach cmd $cmds {
        if {![catch {eval $cmd > $rpt_file} err]} {
            return
        }
        lappend errors "$cmd: $err"
    }

    mptdc_write_report_failure $rpt_file $title [join $errors "\n\n"]
}

proc mptdc_collect_names {cmd} {
    set names [list]
    if {[catch {set objs [eval $cmd]}]} {
        return $names
    }

    if {[llength [info commands foreach_in_collection]] > 0} {
        foreach_in_collection obj $objs {
            if {[catch {set name [get_object_name $obj]}]} {
                if {[catch {set name [get_db $obj .name]}]} {
                    set name $obj
                }
            }
            lappend names $name
        }
        return $names
    }

    foreach obj $objs {
        if {[catch {set name [get_object_name $obj]}]} {
            if {[catch {set name [get_db $obj .name]}]} {
                set name $obj
            }
        }
        lappend names $name
    }
    return $names
}

proc mptdc_unique_list {items} {
    set out [list]
    array set seen {}
    foreach item $items {
        if {![info exists seen($item)]} {
            set seen($item) 1
            lappend out $item
        }
    }
    return $out
}

proc mptdc_collect_pin_names {patterns} {
    set names [list]
    foreach pattern $patterns {
        foreach pin_pattern [list \
            "${pattern}*/D" \
            "${pattern}*/d" \
            "${pattern}*/*D*" \
            "${pattern}*/*d*" \
        ] {
            set matches [mptdc_collect_names "get_pins -quiet -hierarchical $pin_pattern"]
            if {[llength $matches] > 0} {
                set names [concat $names $matches]
            }
        }
    }
    return [mptdc_unique_list $names]
}

proc mptdc_run_timing_to_names {rpt_file title endpoint_names} {
    if {[llength $endpoint_names] == 0} {
        mptdc_write_report_failure $rpt_file $title "No endpoint names provided."
        return
    }

    set errors [list]
    foreach path_type [list full_clock full endpoint {}] {
        if {$path_type ne ""} {
            if {![catch {eval [list report_timing -to $endpoint_names -max_paths 100 -path_type $path_type] > $rpt_file} err]} {
                return
            }
            lappend errors "report_timing -to <[llength $endpoint_names] endpoints> -max_paths 100 -path_type $path_type: $err"
        } else {
            if {![catch {eval [list report_timing -to $endpoint_names -max_paths 100] > $rpt_file} err]} {
                return
            }
            lappend errors "report_timing -to <[llength $endpoint_names] endpoints> -max_paths 100: $err"
        }
    }

    mptdc_write_report_failure $rpt_file $title [join $errors "\n\n"]
}

proc mptdc_run_fast_clock_to_names {rpt_file title endpoint_names {max_paths 300}} {
    if {[llength $endpoint_names] == 0} {
        mptdc_write_report_failure $rpt_file $title "No endpoint names provided."
        return
    }

    set fast_clocks [get_clocks -quiet clk_osc_fast]
    if {[llength $fast_clocks] == 0} {
        mptdc_write_report_failure $rpt_file $title "Clock clk_osc_fast was not found."
        return
    }

    set errors [list]
    foreach path_type [list full_clock full endpoint {}] {
        if {$path_type ne ""} {
            if {![catch {eval [list report_timing -from $fast_clocks -to $endpoint_names -max_paths $max_paths -path_type $path_type] > $rpt_file} err]} {
                return
            }
            lappend errors "report_timing -from clk_osc_fast -to <[llength $endpoint_names] endpoints> -max_paths $max_paths -path_type $path_type: $err"
        } else {
            if {![catch {eval [list report_timing -from $fast_clocks -to $endpoint_names -max_paths $max_paths] > $rpt_file} err]} {
                return
            }
            lappend errors "report_timing -from clk_osc_fast -to <[llength $endpoint_names] endpoints> -max_paths $max_paths: $err"
        }
    }

    mptdc_write_report_failure $rpt_file $title [join $errors "\n\n"]
}

proc mptdc_try_set_db {objects attr value} {
    if {[llength $objects] == 0} {
        return
    }
    catch {set_db $objects $attr $value}
}

proc mptdc_try_preserve_cells {cells} {
    if {[llength $cells] == 0} {
        return
    }
    # Genus can emit noisy errors when preserve/dont_touch is applied to
    # partially mapped hierarchy.  Keep this helper intentionally conservative:
    # try leaf-safe attributes, but do not let preservation hygiene dominate the
    # real timing log.
    catch {set_dont_touch $cells true}
    catch {set_db $cells .dont_touch true}
    catch {set_db $cells .ungroup_ok false}
}

proc mptdc_bool_env {name default_value} {
    if {![info exists ::env($name)]} {
        return $default_value
    }
    set value [string tolower $::env($name)]
    return [expr {$value eq "1" || $value eq "true" || $value eq "yes" || $value eq "on"}]
}

proc mptdc_try_keep_hierarchy_cells {cells} {
    if {[llength $cells] == 0} {
        return
    }
    catch {set_db $cells .ungroup_ok false}
}

proc mptdc_collect_icg_lib_cells {} {
    set cells [list]
    foreach pattern {
        LGCNHDX* LGCPHDX*
        LSGCNHDX* LSGCPHDX*
        LSOGCNHDX* LSOGCPHDX*
    } {
        set matches [list]
        catch {set matches [get_db lib_cells $pattern]}
        if {[llength $matches] > 0} {
            set cells [concat $cells $matches]
        }
    }
    return $cells
}

proc mptdc_allow_icg_lib_cells {} {
    set icg_cells [mptdc_collect_icg_lib_cells]
    mptdc_message "O5 ICG audit: matched [llength $icg_cells] candidate clock-gating lib cells"
    if {[llength $icg_cells] == 0} {
        return
    }
    foreach cell $icg_cells {
        catch {set_db $cell .dont_use false}
        catch {set_db $cell .avoid false}
    }
}

proc mptdc_report_hotspot_timing {rpt_file title patterns} {
    set endpoint_names [mptdc_collect_pin_names $patterns]
    if {[llength $endpoint_names] > 0} {
        mptdc_run_timing_to_names $rpt_file $title $endpoint_names
        return
    }

    set cells [list]
    foreach pattern $patterns {
        set matches [list]
        catch {set matches [get_cells -quiet -hierarchical $pattern]}
        if {[llength $matches] > 0} {
            set cells [concat $cells $matches]
        }
    }

    if {[llength $cells] == 0} {
        mptdc_write_report_failure $rpt_file $title \
            "No cells matched endpoint patterns: $patterns"
        return
    }

    set cell_names [list]
    foreach cell $cells {
        if {![catch {set name [get_object_name $cell]}]} {
            lappend cell_names $name
        } elseif {![catch {set name [get_db $cell .name]}]} {
            lappend cell_names $name
        }
    }

    mptdc_run_timing_to_names $rpt_file $title [mptdc_unique_list $cell_names]
}

proc mptdc_collect_cell_objects {patterns} {
    set cells [list]
    foreach pattern $patterns {
        set matches [list]
        catch {set matches [get_cells -quiet -hierarchical $pattern]}
        if {[llength $matches] > 0} {
            set cells [concat $cells $matches]
        }
    }
    return $cells
}

proc mptdc_try_backend_cost_group {group_name patterns} {
    set cells [mptdc_collect_cell_objects $patterns]
    if {[llength $cells] == 0} {
        mptdc_message "Cost group $group_name skipped; no endpoint cells matched $patterns" high
        return
    }

    catch {create_cost_group -name $group_name}
    if {[catch {path_group -to $cells -group $group_name} err]} {
        mptdc_message "Cost group $group_name skipped: $err" high
    }
}

proc mptdc_add_backend_cost_groups {} {
    mptdc_try_backend_cost_group PD_CAPTURE_GRP {
        *gen_pd_row*gen_pd_col*u_pd*
        *u_pd*
    }
    mptdc_try_backend_cost_group OSC_COUNTER_GRP {
        *u_fast_cnt*
        *u_slow_cnt*
        *nfast_src_count*
        *start_wdt_cnt*
        *start_timeout_latched*
    }
    mptdc_try_backend_cost_group READOUT_SHARED_GRP {
        *u_narrow_tx*
        *acq*
        *fifo*
    }
}

proc mptdc_write_fast_feasibility_audit {rpt_file} {
    global design

    set fh [open $rpt_file w]
    puts $fh "MPTDC fast-domain feasibility audit"
    puts $fh "==================================="
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    puts $fh "Purpose"
    puts $fh "-------"
    puts $fh "Desk-check the physical plausibility of treating oscillator-domain"
    puts $fh "standard-cell registers as ordinary single-cycle synchronous logic."
    puts $fh ""
    puts $fh "Timing equation"
    puts $fh "---------------"
    puts $fh "A same-clock register-to-register path must satisfy:"
    puts $fh "  Tclk >= Tcq_launch + Tcomb + Tsetup_capture + uncertainty - useful_skew"
    puts $fh ""
    puts $fh "Current targets"
    puts $fh "---------------"
    if {[info exists design(OSC_FAST_PERIOD)]} {
        puts $fh "  clk_osc_fast period: $design(OSC_FAST_PERIOD) ns"
    }
    if {[info exists design(OSC_SLOW_PERIOD)]} {
        puts $fh "  clk_osc_slow period: $design(OSC_SLOW_PERIOD) ns"
    }
    if {[info exists design(OSC_CLOCK_UNCERTAINTY_SETUP)]} {
        puts $fh "  oscillator setup uncertainty: $design(OSC_CLOCK_UNCERTAINTY_SETUP) ns"
    }
    puts $fh ""
    puts $fh "Review rule"
    puts $fh "-----------"
    puts $fh "If reported library Tcq plus setup and uncertainty approaches or"
    puts $fh "exceeds the target oscillator period before combinational delay, RTL"
    puts $fh "pipeline slicing cannot close the path. The architecture must either"
    puts $fh "move the affected logic to a slower clock, use custom/analog latch"
    puts $fh "macros with a real Liberty contract, or explicitly classify the path"
    puts $fh "as measurement fabric rather than ordinary synthesized reg-to-reg logic."
    puts $fh ""
    puts $fh "Evidence to inspect"
    puts $fh "-------------------"
    puts $fh "  timing_pd_capture_hotspots.rpt"
    puts $fh "  timing_osc_counter_hotspots.rpt"
    puts $fh "  timing_osc_fast_full_clock.rpt"
    puts $fh "  timing_meas_ctrl_hotspots.rpt"
    puts $fh "  timing_context_bank_hotspots.rpt"
    puts $fh "  Innovus preCTS/postRoute full_clock timing reports"
    close $fh
}

proc mptdc_write_fast_count_capture_endpoint_audit {rpt_file capture_pins} {
    global design

    set fh [open $rpt_file w]
    puts $fh "MPTDC fast-count to nfast_hit endpoint audit"
    puts $fh "=========================================="
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    puts $fh "Purpose"
    puts $fh "-------"
    puts $fh "Count and bucket PD nfast_hit capture endpoints before running focused"
    puts $fh "timing reports.  These paths remain real timing candidates until the"
    puts $fh "architecture proves the fast counter value is intentionally sampled as a"
    puts $fh "stable previous-cycle value."
    puts $fh ""

    puts $fh "Current oscillator model"
    puts $fh "------------------------"
    if {[info exists design(OSC_FAST_PERIOD)]} {
        puts $fh "  fast period ns: $design(OSC_FAST_PERIOD)"
    }
    if {[info exists design(OSC_FAST_TAP_STEP)]} {
        puts $fh "  fast tap step ns: $design(OSC_FAST_TAP_STEP)"
    }
    if {[info exists design(OSC_CLOCK_UNCERTAINTY_SETUP)]} {
        puts $fh "  oscillator setup uncertainty ns: $design(OSC_CLOCK_UNCERTAINTY_SETUP)"
    }
    puts $fh ""

    puts $fh "Endpoint count: [llength $capture_pins]"
    puts $fh ""

    array set by_tap {}
    array set by_row {}
    array set by_bit {}
    foreach pin $capture_pins {
        set tap "unknown"
        set row "unknown"
        set bit "unknown"
        regexp {gen_pd_col\[([0-9]+)\]} $pin -> tap
        regexp {gen_pd_row\[([0-9]+)\]} $pin -> row
        regexp {nfast_hit_latched_reg\[([0-9]+)\]} $pin -> bit
        incr by_tap($tap)
        incr by_row($row)
        incr by_bit($bit)
    }

    puts $fh "By fast tap / PD column"
    puts $fh "-----------------------"
    foreach tap [lsort -dictionary [array names by_tap]] {
        puts $fh [format "  tap %-8s %s" $tap $by_tap($tap)]
    }
    puts $fh ""

    puts $fh "By PD row / slow tap"
    puts $fh "--------------------"
    foreach row [lsort -dictionary [array names by_row]] {
        puts $fh [format "  row %-8s %s" $row $by_row($row)]
    }
    puts $fh ""

    puts $fh "By nfast_hit bit"
    puts $fh "----------------"
    foreach bit [lsort -dictionary [array names by_bit]] {
        puts $fh [format "  bit %-8s %s" $bit $by_bit($bit)]
    }
    puts $fh ""

    puts $fh "First 40 endpoint pins"
    puts $fh "----------------------"
    set count 0
    foreach pin [lsort -dictionary $capture_pins] {
        puts $fh "  $pin"
        incr count
        if {$count >= 40} {
            break
        }
    }
    close $fh
}

proc mptdc_report_fast_count_capture {dir} {
    set capture_pins [mptdc_collect_names [list get_pins -quiet -hierarchical *nfast_hit_latched_reg*/D]]
    if {[llength $capture_pins] == 0} {
        set capture_pins [mptdc_collect_names [list get_pins -quiet -hierarchical *nfast_hit_latched_reg*/*D*]]
    }

    mptdc_write_fast_count_capture_endpoint_audit \
        "$dir/fast_count_capture_endpoint_audit.rpt" \
        $capture_pins

    mptdc_run_fast_clock_to_names \
        "$dir/timing_fast_count_to_nfast_hit.rpt" \
        "fast counter clock to PD nfast_hit capture timing report" \
        $capture_pins \
        300
}

proc mptdc_write_high_fanout_report {rpt_file {limit 100} {threshold 20}} {
    set fh [open $rpt_file w]
    puts $fh "MPTDC high-fanout net audit"
    puts $fh "==========================="
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh "Threshold: fanout >= $threshold"
    puts $fh ""

    if {[catch {set nets [get_db nets]} err]} {
        puts $fh "Could not query nets with get_db nets: $err"
        close $fh
        return
    }

    set rows [list]
    foreach net $nets {
        set name "<unknown>"
        catch {set name [get_db $net .name]}

        set fanout -1
        foreach attr {.num_loads .fanout} {
            if {![catch {set value [get_db $net $attr]}] && [string is integer -strict $value]} {
                set fanout $value
                break
            }
        }
        if {$fanout < 0} {
            foreach attr {.loads .load_pins .pins} {
                if {![catch {set loads [get_db $net $attr]}]} {
                    set fanout [llength $loads]
                    break
                }
            }
        }

        if {$fanout >= $threshold} {
            set driver ""
            if {![catch {set drv [get_db $net .driver]}] && [llength $drv] > 0} {
                catch {set driver [get_db $drv .name]}
            }
            lappend rows [list $fanout $name $driver]
        }
    }

    set rows [lsort -integer -decreasing -index 0 $rows]
    puts $fh [format "%-10s %-80s %s" "Fanout" "Net" "Driver"]
    puts $fh [string repeat "-" 140]
    set count 0
    foreach row $rows {
        puts $fh [format "%-10s %-80s %s" [lindex $row 0] [lindex $row 1] [lindex $row 2]]
        incr count
        if {$count >= $limit} {
            break
        }
    }
    puts $fh ""
    puts $fh "Reported $count of [llength $rows] nets at or above threshold."
    close $fh
}

proc mptdc_preserve_physical_hierarchy {} {
    set relax_pd [mptdc_bool_env MPTDC_RELAX_PD_PRESERVE false]
    if {$relax_pd} {
        mptdc_message "Preserving reset synchronizer hierarchy; O5 relaxes PD dont_touch for internal optimization"
    } else {
        mptdc_message "Preserving reset synchronizer and PD matrix hierarchy"
    }

    foreach pattern {
        *u_rst*sync*
    } {
        set cells [list]
        catch {set cells [get_cells -quiet -hierarchical $pattern]}
        if {[llength $cells] > 0} {
            mptdc_try_preserve_cells $cells
        }
    }

    foreach pattern {
        *gen_pd_row*gen_pd_col*u_pd*
        *u_pd*
    } {
        set cells [list]
        catch {set cells [get_cells -quiet -hierarchical $pattern]}
        if {[llength $cells] > 0} {
            if {$relax_pd} {
                mptdc_try_keep_hierarchy_cells $cells
            } else {
                mptdc_try_preserve_cells $cells
            }
        }
    }

    foreach module_pattern {
        *mptdc_reset_sync*
    } {
        set modules [list]
        catch {set modules [get_db modules $module_pattern]}
        mptdc_try_set_db $modules .dont_touch true
        mptdc_try_set_db $modules .ungroup_ok false
    }

    set pd_modules [list]
    catch {set pd_modules [get_db modules *mptdc_pd_cell*]}
    if {$relax_pd} {
        mptdc_try_set_db $pd_modules .ungroup_ok false
    } else {
        mptdc_try_set_db $pd_modules .dont_touch true
        mptdc_try_set_db $pd_modules .ungroup_ok false
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# mptdc_report_timing — Generate timing reports for current stage
# ─────────────────────────────────────────────────────────────────────────────
# Generates timing reports into the current stage directory using only
# report_timing options supported by the lab-server Genus 22.13 build.
proc mptdc_report_timing {report_dir} {
    global this_run

    set stage $this_run(stage)
    set dir "$report_dir/$stage"
    file mkdir $dir

    mptdc_message "Generating timing reports → $dir"

    # Worst paths in the active view (setup-oriented in the current MMMC setup).
    if {[catch { report_timing -max_paths 20 > "$dir/timing_setup.rpt" } err]} {
        mptdc_write_report_failure "$dir/timing_setup.rpt" "Setup timing report" $err
    }

    # This Genus build does not accept -early/-late on report_timing. Keep a
    # placeholder report so downstream checklisting remains deterministic.
    set fh [open "$dir/timing_hold.rpt" w]
    puts $fh "Hold report not generated by the checked-in bring-up helper."
    puts $fh "The active Genus 22.13 build rejects report_timing -early/-late."
    puts $fh "Use report_constraints or an interactive hold-specific query if"
    puts $fh "you need dedicated hold analysis while bring-up is still in progress."
    close $fh

    # Use QoR as a compact timing summary on this build.
    if {[catch { report_qor > "$dir/timing_summary.rpt" } err]} {
        mptdc_write_report_failure "$dir/timing_summary.rpt" "Timing summary report" $err
    }

    # Violations only: max_slack filters to paths with slack < 0.
    if {[catch { report_timing -max_paths 200 -max_slack 0.0 > "$dir/timing_violations.rpt" } err]} {
        mptdc_write_report_failure "$dir/timing_violations.rpt" "Timing violations report" $err
    }

    mptdc_run_report_candidates [list \
        "report_timing -from \[get_clocks clk_osc_fast\] -to \[get_clocks clk_osc_fast\] -max_paths 100 -path_type full_clock" \
        "report_timing -from \[get_clocks clk_osc_fast\] -to \[get_clocks clk_osc_fast\] -max_paths 100" \
    ] "$dir/timing_osc_fast_full_clock.rpt" "fast oscillator-domain timing report"

    mptdc_run_report_candidates [list \
        "report_timing -from \[get_clocks clk_sys\] -to \[get_clocks clk_sys\] -max_paths 100 -max_slack 0.0 -path_type full_clock" \
        "report_timing -from \[get_clocks clk_sys\] -to \[get_clocks clk_sys\] -max_paths 100 -max_slack 0.0" \
        "report_timing -from \[get_clocks clk_sys\] -to \[get_clocks clk_sys\] -max_paths 100 -path_type full_clock" \
        "report_timing -from \[get_clocks clk_sys\] -to \[get_clocks clk_sys\] -max_paths 100" \
    ] "$dir/timing_clk_sys_violations.rpt" "clk_sys violating timing report"

    mptdc_run_report_candidates [list \
        "report_timing -from \[get_clocks clk_sys\] -to \[get_clocks clk_sys\] -max_paths 100 -path_type full_clock" \
        "report_timing -from \[get_clocks clk_sys\] -to \[get_clocks clk_sys\] -max_paths 100" \
    ] "$dir/timing_clk_sys_full_clock.rpt" "clk_sys full-clock timing report"

    mptdc_report_hotspot_timing "$dir/timing_pd_capture_hotspots.rpt" \
        "phase-detector capture timing report" \
        [list *gen_pd_row*gen_pd_col*u_pd* *u_pd*]

    mptdc_report_hotspot_timing "$dir/timing_osc_counter_hotspots.rpt" \
        "oscillator support-counter timing report" \
        [list *u_fast_cnt* *u_slow_cnt* *u_slow_epoch* *u_stop_epoch_capture* \
              *gen_fast_tag_col* *u_fast_tag* *nfast_src_count* \
              *start_wdt_cnt* *start_timeout_latched*]

    mptdc_report_fast_count_capture $dir

    mptdc_report_hotspot_timing "$dir/timing_meas_ctrl_hotspots.rpt" \
        "measurement-controller hotspot timing report" \
        [list *u_meas_ctrl* *u_meas_ctrl*/*]

    mptdc_report_hotspot_timing "$dir/timing_context_bank_hotspots.rpt" \
        "context-bank hotspot timing report" \
        [list *u_ctx_bank* *u_ctx_bank*/*]

    mptdc_report_hotspot_timing "$dir/timing_hit_capture_bridge_hotspots.rpt" \
        "hit-capture bridge hotspot timing report" \
        [list *u_hit_capture_bridge* *u_hit_capture_bridge*/*]

    mptdc_report_hotspot_timing "$dir/timing_drain_ctrl_hotspots.rpt" \
        "drain controller hotspot timing report" \
        [list *u_drain_ctrl* *u_drain_ctrl*/*]

    mptdc_report_hotspot_timing "$dir/timing_fifo_hotspots.rpt" \
        "FIFO/readout hotspot timing report" \
        [list *u_fifo* *u_sync_fifo* *u_narrow_tx* *u_tconv*]

    mptdc_write_fast_feasibility_audit "$dir/fast_domain_feasibility_audit.rpt"
}

# ─────────────────────────────────────────────────────────────────────────────
# mptdc_default_cost_groups — Define reg2reg, in2reg, reg2out, in2out
# ─────────────────────────────────────────────────────────────────────────────
# Cost groups help Genus focus optimization effort on critical path types.
proc mptdc_default_cost_groups {} {
    global design

    mptdc_message "Defining cost groups (reg2reg, in2reg, reg2out, in2out)"

    if {[llength [info commands create_cost_group]] == 0 || \
        [llength [info commands path_group]] == 0} {
        mptdc_message \
            "Genus build lacks create_cost_group/path_group; keeping default clock-derived cost groups" \
            high
        return
    }

    if {[catch {
        # Register-to-register (internal paths — usually the tightest)
        create_cost_group -name reg2reg
        path_group -from [all_registers] -to [all_registers] -group reg2reg

        # Input-to-register
        create_cost_group -name in2reg
        path_group -from [all_inputs] -to [all_registers] -group in2reg

        # Register-to-output
        create_cost_group -name reg2out
        path_group -from [all_registers] -to [all_outputs] -group reg2out

        # Input-to-output (combinational feedthrough)
        create_cost_group -name in2out
        path_group -from [all_inputs] -to [all_outputs] -group in2out
    } cost_group_err]} {
        mptdc_message \
            "Could not define custom cost groups ($cost_group_err); keeping default clock-derived cost groups" \
            high
    }

    mptdc_add_backend_cost_groups
}

# ─────────────────────────────────────────────────────────────────────────────
# mptdc_latch_audit — Check that only expected latches exist
# ─────────────────────────────────────────────────────────────────────────────
proc mptdc_write_latch_report {rpt_file} {
    set fh [open $rpt_file w]
    set latches [get_db insts -if {.base_cell.is_latch==true}]

    puts $fh "MPTDC latch report"
    puts $fh "=================="
    puts $fh "Count: [llength $latches]"
    puts $fh ""
    puts $fh [format "%-80s %s" "Instance" "Base cell"]
    puts $fh [string repeat "-" 120]

    foreach inst $latches {
        set inst_name [get_db $inst .name]
        set base_name [get_db $inst .base_cell.name]
        puts $fh [format "%-80s %s" $inst_name $base_name]
    }

    close $fh
    return [llength $latches]
}

proc mptdc_latch_audit {report_dir} {
    global design

    set rpt_file "$report_dir/latch_audit.rpt"
    mptdc_message "Latch audit → $rpt_file"

    # Count latches
    set latch_count [mptdc_write_latch_report $rpt_file]
    set expected $design(EXPECTED_LATCH_COUNT)

    if {$latch_count == $expected} {
        mptdc_message "LATCH AUDIT PASS: $latch_count latches (expected $expected)"
    } elseif {$latch_count > $expected} {
        mptdc_message "LATCH AUDIT FAIL: $latch_count latches found (expected $expected) — investigate!" high
    } else {
        mptdc_message "LATCH AUDIT WARNING: $latch_count latches (expected $expected) — some may have been optimized" high
    }

    return $latch_count
}

# ─────────────────────────────────────────────────────────────────────────────
# mptdc_full_reports — Generate all post-synthesis reports
# ─────────────────────────────────────────────────────────────────────────────
proc mptdc_full_reports {report_dir} {
    global this_run design

    set stage $this_run(stage)
    set dir "$report_dir/$stage"
    file mkdir $dir

    mptdc_message "Generating full report set → $dir"

    mptdc_run_report "report_area" \
        "$dir/report_area.rpt" "report_area"
    mptdc_run_report_candidates [list \
        "report_area -depth 20" \
        "report_area -hier" \
        "report_area -hierarchy" \
    ] "$dir/report_area_hier.rpt" "hierarchical area report"
    mptdc_run_report "report_gates" \
        "$dir/report_gates.rpt" "report_gates"
    mptdc_run_report_candidates [list \
        "report_gates -depth 20" \
        "report_gates -hier" \
        "report_gates -hierarchy" \
    ] "$dir/report_gates_hier.rpt" "hierarchical gate report"
    mptdc_run_report "report_hierarchy" \
        "$dir/report_hierarchy.rpt" "report_hierarchy"
    mptdc_run_report "report_design_rules" \
        "$dir/report_design_rules.rpt" "report_design_rules"
    mptdc_run_report_candidates [list \
        "report_design_rules -violators" \
        "report_design_rules -all_violators" \
        "report_design_rules -verbose" \
        "report_design_rules" \
    ] "$dir/report_design_rules_verbose.rpt" "verbose design-rule report"
    mptdc_write_high_fanout_report "$dir/report_high_fanout.rpt" 200 20
    mptdc_run_report "report_qor" \
        "$dir/report_qor.rpt" "report_qor"

    # Power is vectorless unless a later flow reads switching activity.
    mptdc_run_report "report_power" \
        "$dir/report_power.rpt" "report_power"
    mptdc_run_report "report_power -by_hierarchy" \
        "$dir/report_power_hier.rpt" "report_power -by_hierarchy"

    mptdc_run_report "report_clocks" \
        "$dir/report_clocks.rpt" "report_clocks"
    mptdc_run_report "report_constraints" \
        "$dir/report_constraints.rpt" "report_constraints"
    mptdc_run_report_candidates [list \
        "report_clock_groups" \
        "report_clock_groups -verbose" \
        "report_clocks" \
    ] "$dir/report_clock_groups.rpt" "clock-group report"
    mptdc_run_report_candidates [list \
        "report_exceptions" \
        "report_exceptions -verbose" \
        "report_constraints -exceptions" \
        "report_constraints" \
    ] "$dir/report_exceptions.rpt" "timing-exception report"
    mptdc_run_report_candidates [list \
        "report_clocks -generated" \
        "report_clocks" \
    ] "$dir/report_clocks_generated.rpt" "generated/all clock report"
    mptdc_run_report_candidates [list \
        "check_timing_intent -verbose" \
        "check_timing_intent" \
    ] "$dir/check_timing_intent_post_synth.rpt" "post-synthesis timing-intent report"

    # Latch audit
    mptdc_latch_audit $dir
    mptdc_cdc_audit $dir

    mptdc_write_qor_manifest $dir
}

proc mptdc_cdc_audit {dir} {
    set rpt_file "$dir/cdc_manual_audit.rpt"
    set fh [open $rpt_file w]

    puts $fh "MPTDC manual CDC/signoff audit"
    puts $fh "=============================="
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""
    puts $fh "Purpose"
    puts $fh "-------"
    puts $fh "First-cleanup evidence because no dedicated CDC signoff tool is assumed."
    puts $fh "Review this alongside check_timing_intent and timing reports."
    puts $fh ""

    set classes [list \
        [list "Reset synchronizers" \
            "async assertion / sync deassertion per local clock domain" \
            "manual waiver if only the first stage sees async reset crossing" \
            "*u_rst*sync*"] \
        [list "Gray counter synchronizers" \
            "oscillator counter snapshot/continuous CDC" \
            "manual waiver plus bounded source-to-first-stage and async-clear review" \
            "*gray*ff*" "*u_slow_cnt*" "*u_fast_cnt*"] \
        [list "Context drain synchronizers" \
            "async drain flag into clk_sys before static context-bus read" \
            "2FF sync plus static-bus-after-handshake waiver" \
            "*ctx_drain_sync_ff*"] \
        [list "Rejected START event latch" \
            "async rejected START pulse is held until clk_sys counts overflow" \
            "pending-latch plus 2FF sync/ack; verify rejected pulses are not silently dropped" \
            "*start_rejected_pending*" "*rejected_sync_pipe*"] \
        [list "Async frontend latches" \
            "START/STOP event ownership and context allocation" \
            "intentional latch waiver; no setup/hold relation to clk_sys" \
            "*u_frontend*"] \
        [list "STOP boundary capture" \
            "STOP-edge measurement metadata capture" \
            "intentional event-boundary waiver; verify no accidental normal sync path" \
            "*u_stop_capture*"] \
        [list "PD measurement fabric" \
            "fast tap clocks sample slow tap signals for Vernier measurement" \
            "intentional clock-as-data structure; verify all taps are modeled" \
            "*gen_pd_row*gen_pd_col*u_pd*"] \
        [list "Hit capture bridge" \
            "held PD/counter levels sampled into clk_sys after STOP/PD latch" \
            "static-bus-after-handshake waiver; pd_clear must occur only after bridge sample and context commit" \
            "*u_hit_capture_bridge*"] \
    ]

    foreach class $classes {
        set title [lindex $class 0]
        set contract [lindex $class 1]
        set evidence [lindex $class 2]
        set patterns [lrange $class 3 end]

        puts $fh $title
        puts $fh [string repeat "-" [string length $title]]
        puts $fh "Contract: $contract"
        puts $fh "Required evidence: $evidence"
        foreach pattern $patterns {
            set names [mptdc_collect_names "get_cells -quiet -hierarchical $pattern"]
            puts $fh "Pattern $pattern matched [llength $names] cells"
            foreach name [lsort $names] {
                puts $fh "  $name"
            }
        }
        puts $fh ""
    }

    puts $fh "Reviewer checklist"
    puts $fh "------------------"
    puts $fh "  [ ] Every async-looking endpoint in check_timing_intent is in one class above."
    puts $fh "  [ ] No ordinary clk_sys logic appears only because of a broad false path."
    puts $fh "  [ ] Held PD/counter bus is sampled only after STOP visibility and before pd_clear."
    puts $fh "  [ ] Context-bank readout occurs only after capture commit and drain synchronization."
    puts $fh "  [ ] Gray-counter async clears are covered by the teardown-ordering waiver."
    puts $fh "  [ ] PD cell clock/data warnings are limited to intentional Vernier sampling."
    close $fh
}

proc mptdc_write_qor_manifest {dir} {
    global design tech tech_files paths METAL_STACK TRACKS
    global mptdc_optimization_goal mptdc_enable_clock_gating
    global ramstyle_note clock_gating_note

    set fh [open "$dir/run_manifest.rpt" w]
    puts $fh "MPTDC Genus run manifest"
    puts $fh "========================"
    puts $fh "Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"
    puts $fh ""

    puts $fh "Design"
    puts $fh "------"
    foreach key {
        TOPLEVEL FULLCHIP_OR_MACRO CLK_PERIOD OSC_SLOW_PERIOD OSC_FAST_PERIOD
        OSC_SLOW_TAP_STEP OSC_FAST_TAP_STEP CLOCK_UNCERTAINTY
        OSC_CLOCK_UNCERTAINTY_SETUP OSC_CLOCK_UNCERTAINTY_HOLD
        PRODUCTION_SHARED_READOUT INPUT_DELAY_MACRO
        OUTPUT_DELAY_MACRO OUTPUT_LOAD_MACRO MAX_FANOUT MAX_TRANSITION
        RESET_MAX_FANOUT RESET_MAX_TRANSITION
        EXPECTED_LATCH_COUNT selected_setup_analysis_views
        selected_hold_analysis_views OSC_TOPOLOGY OSC_SLOW_ANALOG_PINS
        OSC_FAST_ANALOG_PINS
    } {
        if {[info exists design($key)]} {
            puts $fh [format "  %-32s %s" $key $design($key)]
        }
    }

    puts $fh ""
    puts $fh "Optimization"
    puts $fh "------------"
    foreach item {
        mptdc_optimization_goal mptdc_enable_clock_gating
        ramstyle_note clock_gating_note
    } {
        if {[info exists $item]} {
            puts $fh [format "  %-32s %s" $item [set $item]]
        }
    }

    puts $fh ""
    puts $fh "Technology"
    puts $fh "----------"
    foreach item {METAL_STACK TRACKS} {
        if {[info exists $item]} {
            puts $fh [format "  %-32s %s" $item [set $item]]
        }
    }
    foreach key {
        STANDARD_CELL_SITE STANDARD_CELL_VDD STANDARD_CELL_GND row_height
        grid_unit HAS_QRC_TECH cts_top_routing_layer_top
        cts_bottom_routing_layer_top OSC_SLOW_MACRO OSC_FAST_MACRO OSC_VDD OSC_GND
        PD_DECAP
    } {
        if {[info exists tech($key)]} {
            puts $fh [format "  %-32s %s" $key $tech($key)]
        }
    }

    puts $fh ""
    puts $fh "Library and physical files"
    puts $fh "--------------------------"
    foreach key {
        PDK_ROOT SC_ROOT LIB_DIR TECH_LEF_DIR QRC_ROOT
    } {
        if {[info exists paths($key)]} {
            puts $fh [format "  %-32s %s" $key $paths($key)]
        }
    }
    foreach key {
        STDCELLS_BC_LIB STDCELLS_TC_LIB STDCELLS_WC_LIB TECHNOLOGY_LEF
        STDCELLS_LEF MPTDC_OSC_LEF MPTDC_OSC_BB_LIB
        QRCTECH_BC QRCTECH_TC QRCTECH_WC
    } {
        if {[info exists tech_files($key)]} {
            puts $fh [format "  %-32s %s" $key $tech_files($key)]
        }
    }

    puts $fh ""
    puts $fh "Review checklist"
    puts $fh "----------------"
    puts $fh "  [ ] timing_violations.rpt contains no real violations"
    puts $fh "  [ ] report_area_hier.rpt identifies dominant blocks"
    puts $fh "  [ ] report_power.rpt/report_power_hier.rpt are understood as vectorless or activity-backed"
    puts $fh "  [ ] latch_audit.rpt matches the intentional async-frontend latch count"
    puts $fh "  [ ] cdc_manual_audit.rpt covers all intentional async/mixed-domain structures"
    puts $fh "  [ ] timing_pd_capture_hotspots.rpt reports PD capture WNS separately from aggregate WNS"
    puts $fh "  [ ] timing_osc_counter_hotspots.rpt reports u_fast_cnt/u_slow_cnt/start watchdog support-counter WNS separately"
    puts $fh "  [ ] timing_meas_ctrl_hotspots.rpt and timing_context_bank_hotspots.rpt identify logic-vs-wire blockers"
    puts $fh "  [ ] report_design_rules.rpt has no critical transition/fanout/capacitance issues"
    close $fh
}

# ─────────────────────────────────────────────────────────────────────────────
# mptdc_print_summary — Print a final summary banner
# ─────────────────────────────────────────────────────────────────────────────
proc mptdc_print_summary {} {
    global this_run design

    set elapsed [expr {[clock seconds] - $this_run(start_time)}]
    set mins [expr {$elapsed / 60}]
    set secs [expr {$elapsed % 60}]

    puts ""
    puts "================================================================"
    puts " MPTDC SYNTHESIS COMPLETE"
    puts " Design:  $design(TOPLEVEL)"
    puts " Stages:  $this_run(stage_count)"
    puts " Runtime: ${mins}m ${secs}s"
    puts "================================================================"
    puts ""
    puts " Post-synthesis checklist:"
    puts "   [ ] timing_violations.rpt is empty"
    puts "   [ ] Latch audit: exactly $design(EXPECTED_LATCH_COUNT) latches"
    puts "   [ ] report_area_hier.rpt identifies the first area targets"
    puts "   [ ] run_manifest.rpt captures the exact PDK/MMMC/settings baseline"
    puts "   [ ] PD capture and oscillator-counter timing reports are reviewed separately"
    puts "   [ ] No critical DRV violations"
    puts "   [ ] Power report is tagged as vectorless or activity-backed"
    puts "================================================================"
}
