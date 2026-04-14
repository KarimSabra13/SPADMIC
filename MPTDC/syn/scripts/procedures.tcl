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

# ─────────────────────────────────────────────────────────────────────────────
# mptdc_report_timing — Generate timing reports for current stage
# ─────────────────────────────────────────────────────────────────────────────
# Generates setup/hold/summary reports into the current stage directory.
proc mptdc_report_timing {report_dir} {
    global this_run

    set stage $this_run(stage)
    set dir "$report_dir/$stage"
    file mkdir $dir

    mptdc_message "Generating timing reports → $dir"

    # Setup timing — 20 worst paths
    catch { report_timing -max_paths 20 -late  > "$dir/timing_setup.rpt" }
    # Hold timing — 20 worst paths
    catch { report_timing -max_paths 20 -early > "$dir/timing_hold.rpt" }
    # Summary
    catch { report_timing -summary > "$dir/timing_summary.rpt" }
    # Violations only
    catch { report_timing -slack_lesser_than 0.0 > "$dir/timing_violations.rpt" }
}

# ─────────────────────────────────────────────────────────────────────────────
# mptdc_default_cost_groups — Define reg2reg, in2reg, reg2out, in2out
# ─────────────────────────────────────────────────────────────────────────────
# Cost groups help Genus focus optimization effort on critical path types.
proc mptdc_default_cost_groups {} {
    global design

    mptdc_message "Defining cost groups (reg2reg, in2reg, reg2out, in2out)"

    # Remove existing cost groups if any
    catch { delete_obj [get_db cost_groups] }

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

    # Standard reports
    set report_list [list \
        report_area \
        report_gates \
        report_hierarchy \
        report_design_rules \
        report_qor \
    ]

    foreach rpt $report_list {
        mptdc_message "  $rpt" low
        catch { $rpt > "$dir/${rpt}.rpt" }
    }

    # Power (may not work without switching activity)
    catch { report_power > "$dir/report_power.rpt" }

    # Clocks
    catch { report_clocks > "$dir/report_clocks.rpt" }

    # Constraints
    catch { report_constraints > "$dir/report_constraints.rpt" }

    # Latch audit
    mptdc_latch_audit $dir
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
    puts "   [ ] Area fits within budget"
    puts "   [ ] No critical DRV violations"
    puts "   [ ] Gate count reasonable for 180 nm"
    puts "================================================================"
}
