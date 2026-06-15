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

if {![info exists mptdc_report_helper_failures]} {
    set mptdc_report_helper_failures [list]
}

proc mptdc_record_report_helper_failure {label rpt_file err} {
    global mptdc_report_helper_failures
    lappend mptdc_report_helper_failures [list $label $rpt_file $err]
}

proc mptdc_reset_report_helper_failures {} {
    global mptdc_report_helper_failures
    set mptdc_report_helper_failures [list]
}

proc mptdc_write_report_helper_status {rpt_file} {
    global mptdc_report_helper_failures
    set fh [open $rpt_file w]
    puts $fh "# MPTDC Report Helper Status"
    puts $fh ""
    puts $fh "REPORT_HELPER_FAILURE_COUNT=[llength $mptdc_report_helper_failures]"
    if {[llength $mptdc_report_helper_failures] == 0} {
        puts $fh "REPORT_HELPERS_STATUS=PASS"
    } else {
        puts $fh "REPORT_HELPERS_STATUS=REVIEW_REQUIRED"
        puts $fh ""
        puts $fh "## Failing Reports"
        foreach failure $mptdc_report_helper_failures {
            set label [lindex $failure 0]
            set rpt_file [lindex $failure 1]
            set err [lindex $failure 2]
            puts $fh ""
            puts $fh "REPORT_HELPER_FAILURE=$label"
            puts $fh "REPORT_FILE=$rpt_file"
            puts $fh "ERROR=$err"
        }
    }
    close $fh
}

proc mptdc_write_report_failure {rpt_file title err} {
    set fh [open $rpt_file w]
    puts $fh "$title could not be generated."
    puts $fh ""
    puts $fh $err
    close $fh
}

proc mptdc_write_recorded_report_failure {rpt_file title err} {
    mptdc_record_report_helper_failure $title $rpt_file $err
    mptdc_write_report_failure $rpt_file $title $err
}

proc mptdc_run_report {cmd rpt_file title} {
    if {[catch {eval $cmd > $rpt_file} err]} {
        mptdc_record_report_helper_failure $title $rpt_file $err
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

    mptdc_record_report_helper_failure $title $rpt_file [join $errors "\n\n"]
    mptdc_write_report_failure $rpt_file $title [join $errors "\n\n"]
}

proc mptdc_run_nonfatal_report_step {label cmd report_dir} {
    if {[catch {uplevel 1 $cmd} err opts]} {
        mptdc_message "$label failed; continuing so synthesis can reach export: $err" high
        file mkdir $report_dir
        set safe_label [string map {" " "_" "/" "_" ":" "_"} [string tolower $label]]
        set fh [open "$report_dir/${safe_label}_failure.rpt" w]
        puts $fh "$label failed."
        puts $fh ""
        puts $fh $err
        if {[dict exists $opts -errorinfo]} {
            puts $fh ""
            puts $fh "Tcl error info:"
            puts $fh [dict get $opts -errorinfo]
        }
        close $fh
        mptdc_record_report_helper_failure $label "$report_dir/${safe_label}_failure.rpt" $err
        return 0
    }
    return 1
}

proc mptdc_write_report_substitute {rpt_file title unavailable_cmds evidence_files note} {
    set fh [open $rpt_file w]
    puts $fh "# $title"
    puts $fh ""
    puts $fh "REPORT_STATUS=UNSUPPORTED_NATIVE_COMMAND_SUBSTITUTED"
    puts $fh ""
    puts $fh "The active Genus build does not provide the native command(s) this"
    puts $fh "report previously tried to call. This file is written deliberately"
    puts $fh "instead of emitting an invalid-command failure."
    puts $fh ""
    puts $fh "Unavailable commands:"
    foreach cmd $unavailable_cmds {
        puts $fh "  - $cmd"
    }
    puts $fh ""
    puts $fh "Substitute evidence to review:"
    foreach file $evidence_files {
        puts $fh "  - $file"
    }
    if {$note ne ""} {
        puts $fh ""
        puts $fh $note
    }
    close $fh
}

proc mptdc_collection_to_list {collection} {
    set out [list]
    if {$collection eq ""} {
        return $out
    }
    # Genus commands can return either a native collection handle or an already
    # expanded Tcl list of object handles.  foreach_in_collection emits noisy
    # "Invalid list of objects" diagnostics on Tcl lists even when wrapped in
    # catch, so use Tcl iteration first when the value is visibly a list.
    if {![catch {set token_count [llength $collection]}] && $token_count > 1} {
        foreach obj $collection {
            lappend out $obj
        }
        return $out
    }
    if {[llength [info commands foreach_in_collection]] > 0} {
        if {![catch {
            foreach_in_collection obj $collection {
                lappend out $obj
            }
        }]} {
            return $out
        }
        set out [list]
    }
    if {![catch {
        foreach obj $collection {
            lappend out $obj
        }
    }]} {
        return $out
    }
    return [list]
}

proc mptdc_object_name {obj} {
    if {$obj eq ""} {
        return ""
    }
    if {![catch {set name [get_object_name $obj]}]} {
        return $name
    }
    if {[regexp {^0x[0-9a-fA-F]+$} $obj]} {
        return $obj
    }
    if {![catch {set name [get_db $obj .name]}]} {
        return $name
    }
    return $obj
}

proc mptdc_o13_abs3_enabled {} {
    return [expr {[info exists ::env(MPTDC_O13_ABS3_CLOCK_CDC_REPAIR)] && \
        $::env(MPTDC_O13_ABS3_CLOCK_CDC_REPAIR) ne "0" || \
        [info exists ::env(MPTDC_O13_ABS4_PD_VERNIER_CLASSIFICATION)] && \
        $::env(MPTDC_O13_ABS4_PD_VERNIER_CLASSIFICATION) ne "0" || \
        [info exists ::env(MPTDC_O13_ABS5_PD_Q1_EXCEPTION_EXACT)] && \
        $::env(MPTDC_O13_ABS5_PD_Q1_EXCEPTION_EXACT) ne "0"}]
}

proc mptdc_o13_abs5_enabled {} {
    return [expr {[info exists ::env(MPTDC_O13_ABS5_PD_Q1_EXCEPTION_EXACT)] && \
        $::env(MPTDC_O13_ABS5_PD_Q1_EXCEPTION_EXACT) ne "0"}]
}

proc mptdc_o13_abs4_enabled {} {
    return [expr {[info exists ::env(MPTDC_O13_ABS4_PD_VERNIER_CLASSIFICATION)] && \
        $::env(MPTDC_O13_ABS4_PD_VERNIER_CLASSIFICATION) ne "0"}]
}

proc mptdc_o13_abs4_or_abs5_enabled {} {
    return [expr {[mptdc_o13_abs4_enabled] || [mptdc_o13_abs5_enabled]}]
}

proc mptdc_o13_abs3_expected_clock_names {kind} {
    set names [list]
    switch -- $kind {
        raw {
            foreach family {slow fast} {
                lappend names "clk_osc_${family}"
                for {set tap 1} {$tap < 8} {incr tap} {
                    lappend names "clk_osc_${family}_tap${tap}"
                }
            }
        }
        buffer {
            foreach family {slow fast} {
                for {set tap 0} {$tap < 8} {incr tap} {
                    lappend names "clk_osc_${family}_buf_tap${tap}"
                }
            }
        }
        fast_buffer {
            for {set tap 0} {$tap < 8} {incr tap} {
                lappend names "clk_osc_fast_buf_tap${tap}"
            }
        }
        slow_buffer {
            for {set tap 0} {$tap < 8} {incr tap} {
                lappend names "clk_osc_slow_buf_tap${tap}"
            }
        }
        default {
            return [list]
        }
    }
    return $names
}

proc mptdc_o13_abs3_clock_collection {clock_names} {
    set clocks [list]
    foreach clock_name $clock_names {
        set found [get_clocks -quiet $clock_name]
        foreach clk [mptdc_collection_to_list $found] {
            if {[lsearch -exact $clocks $clk] < 0} {
                lappend clocks $clk
            }
        }
    }
    return $clocks
}

proc mptdc_o13_abs3_pin_collection {patterns} {
    if {[llength [info commands mptdc_o13_pin_object_list]] > 0} {
        return [mptdc_o13_pin_object_list $patterns]
    }

    set pins [list]
    array set seen {}
    foreach pattern $patterns {
        set found [get_pins -quiet -hierarchical $pattern]
        foreach pin [mptdc_collection_to_list $found] {
            set name [mptdc_object_name $pin]
            foreach item $name {
                if {![info exists seen($item)]} {
                    set seen($item) 1
                    lappend pins $pin
                }
            }
        }
    }
    return $pins
}

proc mptdc_o13_abs3_append_file {fh path} {
    if {[file exists $path]} {
        set in [open $path r]
        puts $fh [read $in]
        close $in
    } else {
        puts $fh "FAILED: expected temporary report was not written: $path"
    }
}

proc mptdc_o13_abs3_run_timing_report {rpt_file title from_objs to_objs {max_paths 100}} {
    if {[llength $from_objs] == 0} {
        mptdc_write_recorded_report_failure $rpt_file $title "No launch/source objects matched."
        return
    }
    if {[llength $to_objs] == 0} {
        mptdc_write_recorded_report_failure $rpt_file $title "No endpoint objects matched."
        return
    }
    set errors [list]
    foreach path_type [list full_clock full {}] {
        if {$path_type eq ""} {
            if {![catch {report_timing -from $from_objs -to $to_objs -max_paths $max_paths > $rpt_file} err]} {
                return
            }
            lappend errors "report_timing -max_paths $max_paths: $err"
        } else {
            if {![catch {report_timing -from $from_objs -to $to_objs -max_paths $max_paths -path_type $path_type > $rpt_file} err]} {
                return
            }
            lappend errors "report_timing -max_paths $max_paths -path_type $path_type: $err"
        }
    }
    mptdc_write_recorded_report_failure $rpt_file $title [join $errors "\n\n"]
}

proc mptdc_o13_abs3_write_clock_model_check {rpt_file} {
    set raw_names [mptdc_o13_abs3_expected_clock_names raw]
    set buf_names [mptdc_o13_abs3_expected_clock_names buffer]
    set raw_clocks [mptdc_o13_abs3_clock_collection $raw_names]
    set buf_clocks [mptdc_o13_abs3_clock_collection $buf_names]
    set clk_sys [get_clocks -quiet clk_sys]

    set fh [open $rpt_file w]
    puts $fh "# O13 abs3 Clock Model Check"
    puts $fh ""
    puts $fh "RAW_RO_CLOCKS_FOUND=[llength $raw_clocks]"
    puts $fh "BUFFER_PHASE_CLOCKS_FOUND=[llength $buf_clocks]"
    puts $fh "BUFFER_PHASE_CLOCKS_EXPECTED=16"
    puts $fh "CLK_SYS_CLOCKS_FOUND=[llength $clk_sys]"
    puts $fh "OSCILLATOR_CLOCKS_TOTAL=[expr {[llength $raw_clocks] + [llength $buf_clocks]}]"
    puts $fh "BUFFER_PHASE_CLOCKS_IN_ASYNC_GROUP=SEE_REPORT_CLOCK_GROUPS"
    puts $fh "CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS=SEE_REPORT_CLOCK_GROUPS"
    puts $fh ""
    puts $fh "## Raw RO clocks"
    foreach name $raw_names {
        puts $fh "- $name: [llength [get_clocks -quiet $name]]"
    }
    puts $fh ""
    puts $fh "## Final buffer phase clocks"
    foreach name $buf_names {
        puts $fh "- $name: [llength [get_clocks -quiet $name]]"
    }
    puts $fh ""
    puts $fh "Intent:"
    puts $fh "- clk_sys is asynchronous to raw RO clocks and final buffer phase clocks."
    puts $fh "- Raw RO clocks and final buffer phase clocks are in one oscillator group, so phase-buffer/generator relationships remain visible."
    puts $fh "- This is typical-only feasibility evidence, not final signoff."
    close $fh
}

proc mptdc_o13_abs3_write_cdc_async_review {rpt_file} {
    set sys_clocks [get_clocks -quiet clk_sys]
    set raw_clocks [mptdc_o13_abs3_clock_collection [mptdc_o13_abs3_expected_clock_names raw]]
    set buf_clocks [mptdc_o13_abs3_clock_collection [mptdc_o13_abs3_expected_clock_names buffer]]
    set osc_clocks [concat $raw_clocks $buf_clocks]

    set fh [open $rpt_file w]
    puts $fh "# O13 abs3 CDC Async Review"
    puts $fh ""
    puts $fh "Expected: report_timing from clk_sys to oscillator clocks and back should show no ordinary synchronous timing paths after clock grouping."
    puts $fh ""
    puts $fh "clk_sys clocks: [llength $sys_clocks]"
    puts $fh "raw oscillator clocks: [llength $raw_clocks]"
    puts $fh "buffer oscillator clocks: [llength $buf_clocks]"
    puts $fh ""

    foreach item [list \
        [list "clk_sys_to_osc" $sys_clocks $osc_clocks] \
        [list "osc_to_clk_sys" $osc_clocks $sys_clocks] \
    ] {
        set label [lindex $item 0]
        set from_objs [lindex $item 1]
        set to_objs [lindex $item 2]
        puts $fh "## $label"
        if {[llength $from_objs] == 0 || [llength $to_objs] == 0} {
            puts $fh "FAILED: empty from/to clock collection"
            puts $fh ""
            continue
        }
        set tmp "${rpt_file}.${label}.tmp"
        if {[catch {report_timing -from $from_objs -to $to_objs -max_paths 20 > $tmp} err]} {
            puts $fh "FAILED: report_timing -from <[llength $from_objs]> -to <[llength $to_objs]> -max_paths 20"
            puts $fh $err
        } else {
            mptdc_o13_abs3_append_file $fh $tmp
        }
        catch {file delete $tmp}
        puts $fh ""
    }
    close $fh
}

proc mptdc_o13_abs4_first_name {cmd} {
    set names [mptdc_collect_names $cmd]
    if {[llength $names] == 0} {
        return "UNKNOWN"
    }
    return [lindex $names 0]
}

proc mptdc_o13_abs4_first_pin_pattern {patterns} {
    foreach pattern $patterns {
        set count [llength [get_pins -quiet -hierarchical $pattern]]
        if {$count > 0} {
            return [list $pattern $count]
        }
    }
    return [list "" 0]
}

proc mptdc_o13_abs4_stage_pin_patterns {family tap inst pin} {
    return [list \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d]/%s/%s} $family $tap $inst $pin] \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d].%s/%s} $family $tap $inst $pin] \
        [format {u_core_u_phase_buf_%s/gen_phase_buf[%d].%s/%s} $family $tap $inst $pin] \
        [format {u_core_u_phase_buf_%s_gen_phase_buf_%d__%s/%s} $family $tap $inst $pin] \
        [format {*u_phase_buf_%s*gen_phase_buf*%d*%s/%s} $family $tap $inst $pin]]
}

proc mptdc_o13_abs4_raw_pin_patterns {family tap} {
    return [list \
        [format {u_core/u_osc_%s/u_ro_tune4/S[%d]} $family $tap] \
        [format {u_core_u_osc_%s_u_ro_tune4/S[%d]} $family $tap] \
        [format {*u_osc_%s*u_ro_tune4/S[%d]} $family $tap]]
}

proc mptdc_o13_abs4_q1_patterns {tap} {
    return [list \
        [format {*gen_pd_row[%d].gen_pd_col*.u_pd/q1_reg*/D} $tap] \
        [format {*gen_pd_row[%d]*gen_pd_col*u_pd*/q1_reg*/D} $tap] \
        [format {*gen_pd_row_%d__gen_pd_col*u_pd*/q1_reg*/D} $tap]]
}

proc mptdc_o13_pd_match_q1_name {name ns_var nf_var} {
    upvar $ns_var ns
    upvar $nf_var nf
    set lname [string tolower $name]
    if {[regexp {gen_pd_row\[([0-7])\].*gen_pd_col\[([0-7])\].*u_pd.*q1_reg[^/]*/d$} $lname -> ns nf]} {
        return 1
    }
    if {[regexp {gen_pd_row_?([0-7]).*gen_pd_col_?([0-7]).*u_pd.*q1[^/]*/d$} $lname -> ns nf]} {
        return 1
    }
    return 0
}

proc mptdc_o13_pd_match_slow_source_name {name tap_var} {
    upvar $tap_var tap
    set lname [string tolower $name]
    if {[regexp {u_phase_buf_slow.*gen_phase_buf\[([0-7])\].*u_drv/q$} $lname -> tap]} {
        return 1
    }
    if {[regexp {u_phase_buf_slow.*gen_phase_buf_?([0-7]).*u_drv/q$} $lname -> tap]} {
        return 1
    }
    return 0
}

proc mptdc_o13_pd_q1_endpoint_matrix {} {
    array set by_pair {}
    array set row_count {}
    array set col_count {}
    for {set idx 0} {$idx < 8} {incr idx} {
        set row_count($idx) 0
        set col_count($idx) 0
    }

    set candidates [mptdc_collect_names [list get_pins -quiet -hierarchical *q1_reg*/D]]
    set candidates [concat $candidates [mptdc_collect_names [list get_pins -quiet -hierarchical *q1_reg*/d]]]
    set candidates [mptdc_unique_list $candidates]
    set matched 0
    set duplicates 0
    set unmatched [list]
    foreach name $candidates {
        set ns ""
        set nf ""
        if {[mptdc_o13_pd_match_q1_name $name ns nf]} {
            set key "${ns},${nf}"
            if {[info exists by_pair($key)]} {
                incr duplicates
                continue
            }
            set by_pair($key) $name
            incr matched
            incr row_count($ns)
            incr col_count($nf)
        } else {
            lappend unmatched $name
        }
    }

    set missing [list]
    for {set ns 0} {$ns < 8} {incr ns} {
        for {set nf 0} {$nf < 8} {incr nf} {
            set key "${ns},${nf}"
            if {![info exists by_pair($key)]} {
                lappend missing $key
            }
        }
    }

    return [list \
        candidates [llength $candidates] \
        matched $matched \
        duplicates $duplicates \
        missing $missing \
        unmatched $unmatched \
        by_pair [array get by_pair] \
        row_count [array get row_count] \
        col_count [array get col_count]]
}

proc mptdc_o13_pd_slow_source_matrix {} {
    array set by_tap {}
    array set tap_count {}
    for {set tap 0} {$tap < 8} {incr tap} {
        set tap_count($tap) 0
    }

    set candidates [list]
    array set seen {}
    for {set tap 0} {$tap < 8} {incr tap} {
        foreach pattern [mptdc_o13_abs4_stage_pin_patterns slow $tap u_drv Q] {
            foreach name [mptdc_collect_names [list get_pins -quiet -hierarchical $pattern]] {
                if {![info exists seen($name)]} {
                    set seen($name) 1
                    lappend candidates $name
                }
            }
        }
    }

    set matched 0
    set duplicates 0
    set unmatched [list]
    foreach name $candidates {
        set tap ""
        if {[mptdc_o13_pd_match_slow_source_name $name tap]} {
            if {[info exists by_tap($tap)]} {
                incr duplicates
                continue
            }
            set by_tap($tap) $name
            incr tap_count($tap)
            incr matched
        } else {
            lappend unmatched $name
        }
    }

    set missing [list]
    for {set tap 0} {$tap < 8} {incr tap} {
        if {![info exists by_tap($tap)]} {
            lappend missing $tap
        }
    }

    return [list \
        candidates [llength $candidates] \
        matched $matched \
        duplicates $duplicates \
        missing $missing \
        unmatched $unmatched \
        by_tap [array get by_tap] \
        tap_count [array get tap_count]]
}

proc mptdc_o13_pin_object_name {obj} {
    return [mptdc_object_name $obj]
}

proc mptdc_append_unique_names {raw_names names_var seen_var} {
    upvar $names_var names
    upvar $seen_var seen
    foreach name $raw_names {
        if {$name eq ""} {
            continue
        }
        if {![info exists seen($name)]} {
            set seen($name) 1
            lappend names $name
        }
    }
}

proc mptdc_o13_pin_object_list {patterns} {
    set pins [list]
    array set seen {}

    foreach pattern $patterns {
        set found [get_pins -quiet -hierarchical $pattern]
        foreach pin [mptdc_collection_to_list $found] {
            set raw_names [mptdc_o13_pin_object_name $pin]
            foreach name $raw_names {
                if {$name eq "" || [info exists seen($name)]} {
                    continue
                }
                set seen($name) 1
                lappend pins $pin
            }
        }
    }

    return $pins
}

proc mptdc_o13_abs5_q1_pin_object_matrix {} {
    array set by_pair {}
    array set name_by_pair {}
    array set row_count {}
    array set col_count {}
    for {set idx 0} {$idx < 8} {incr idx} {
        set row_count($idx) 0
        set col_count($idx) 0
    }

    set candidates [mptdc_o13_pin_object_list [list \
        *gen_pd_row*gen_pd_col*u_pd*/q1_reg*/D \
        *gen_pd_row*gen_pd_col*u_pd*q1*/D \
        *q1_reg*/D \
        *gen_pd_row*gen_pd_col*u_pd*/q1_reg*/d \
        *gen_pd_row*gen_pd_col*u_pd*q1*/d \
        *q1_reg*/d]]

    set matched 0
    set duplicates 0
    set unmatched [list]
    foreach pin $candidates {
        set name [mptdc_o13_pin_object_name $pin]
        set ns ""
        set nf ""
        if {[mptdc_o13_pd_match_q1_name $name ns nf]} {
            set key "${ns},${nf}"
            if {[info exists by_pair($key)]} {
                incr duplicates
                continue
            }
            set by_pair($key) $pin
            set name_by_pair($key) $name
            incr matched
            incr row_count($ns)
            incr col_count($nf)
        } else {
            lappend unmatched $name
        }
    }

    set missing [list]
    for {set ns 0} {$ns < 8} {incr ns} {
        for {set nf 0} {$nf < 8} {incr nf} {
            set key "${ns},${nf}"
            if {![info exists by_pair($key)]} {
                lappend missing $key
            }
        }
    }

    return [list \
        candidates [llength $candidates] \
        matched $matched \
        duplicates $duplicates \
        missing $missing \
        unmatched $unmatched \
        by_pair [array get by_pair] \
        name_by_pair [array get name_by_pair] \
        row_count [array get row_count] \
        col_count [array get col_count]]
}

proc mptdc_o13_abs5_slow_source_object_matrix {} {
    array set by_tap {}
    array set name_by_tap {}
    array set tap_count {}
    for {set tap 0} {$tap < 8} {incr tap} {
        set tap_count($tap) 0
    }

    set patterns [list]
    for {set tap 0} {$tap < 8} {incr tap} {
        foreach pattern [mptdc_o13_abs4_stage_pin_patterns slow $tap u_drv Q] {
            lappend patterns $pattern
        }
    }
    set candidates [mptdc_o13_pin_object_list $patterns]

    set matched 0
    set duplicates 0
    set unmatched [list]
    foreach pin $candidates {
        set name [mptdc_o13_pin_object_name $pin]
        set tap ""
        if {[mptdc_o13_pd_match_slow_source_name $name tap]} {
            if {[info exists by_tap($tap)]} {
                incr duplicates
                continue
            }
            set by_tap($tap) $pin
            set name_by_tap($tap) $name
            incr tap_count($tap)
            incr matched
        } else {
            lappend unmatched $name
        }
    }

    set missing [list]
    for {set tap 0} {$tap < 8} {incr tap} {
        if {![info exists by_tap($tap)]} {
            lappend missing $tap
        }
    }

    return [list \
        candidates [llength $candidates] \
        matched $matched \
        duplicates $duplicates \
        missing $missing \
        unmatched $unmatched \
        by_tap [array get by_tap] \
        name_by_tap [array get name_by_tap] \
        tap_count [array get tap_count]]
}

proc mptdc_o13_abs5_write_exception_report {rpt_file stage endpoints_list sources_list apply_rows applied_endpoint_count exception_applied exception_failures overmatch undermatch mode_status mode_detail} {
    array set endpoints $endpoints_list
    array set sources $sources_list
    array set row_count $endpoints(row_count)
    array set name_by_pair $endpoints(name_by_pair)
    array set name_by_tap $sources(name_by_tap)

    set fh [open $rpt_file w]
    puts $fh "# O13 abs5 PD Vernier Exception Check"
    puts $fh ""
    puts $fh "PD_VERNIER_EXPECTED_ENDPOINTS=64"
    puts $fh "PD_VERNIER_FOUND_ENDPOINTS=$endpoints(matched)"
    puts $fh "PD_VERNIER_FOUND_SOURCES=$sources(matched)"
    puts $fh "PD_VERNIER_EXCEPTION_APPLIED=$exception_applied"
    puts $fh "PD_VERNIER_OVERMATCH=$overmatch"
    puts $fh "PD_VERNIER_UNDERMATCH=$undermatch"
    puts $fh "PD_VERNIER_EXCEPTION_FAILURES=$exception_failures"
    puts $fh "PD_VERNIER_APPLIED_ENDPOINTS=$applied_endpoint_count"
    puts $fh "PD_VERNIER_APPLICATION_STAGE=$stage"
    puts $fh "PD_VERNIER_APPLICATION_METHOD=POST_ELAB_EXACT_PIN_OBJECTS"
    puts $fh "PD_VERNIER_CONSTRAINT_MODE_STATUS=$mode_status"
    puts $fh "PD_VERNIER_CONSTRAINT_MODE_DETAIL=$mode_detail"
    puts $fh ""
    puts $fh "PD_VERNIER_EXCEPTION_ENDPOINTS_FOUND=$endpoints(matched)"
    puts $fh "PD_VERNIER_EXCEPTION_EXPECTED=64"
    puts $fh "PD_VERNIER_SOURCE_CLOCKS_FOUND=$sources(matched)"
    puts $fh "PD_VERNIER_EXCEPTION_OVERMATCH=$overmatch"
    puts $fh ""
    puts $fh "## Per-row exception"
    puts $fh "| slow_tap | source_pin | endpoint_count | exception_status | detail |"
    puts $fh "|---:|---|---:|---|---|"
    for {set tap 0} {$tap < 8} {incr tap} {
        set source_name "MISSING"
        if {[info exists name_by_tap($tap)]} {
            set source_name $name_by_tap($tap)
        }
        set row_status "NOT_APPLIED"
        set row_detail "endpoint/source discovery failed"
        foreach row $apply_rows {
            if {[lindex $row 0] == $tap} {
                set row_status [lindex $row 1]
                set row_detail [lindex $row 2]
            }
        }
        puts $fh "| $tap | `$source_name` | $row_count($tap) | $row_status | $row_detail |"
        for {set nf 0} {$nf < 8} {incr nf} {
            set key "${tap},${nf}"
            if {[info exists name_by_pair($key)]} {
                puts $fh "  - endpoint($key): `$name_by_pair($key)`"
            } else {
                puts $fh "  - endpoint($key): `MISSING`"
            }
        }
    }
    puts $fh ""
    puts $fh "## Scope"
    puts $fh "- Cuts only buffered slow phase final-driver output pins into same-row PD q1 sampler D pins."
    puts $fh "- Does not cut q1->q2, q1/q2->hit_latched, nfast_tag->timestamp, slow Johnson, clk_sys, reset/recovery, or phase-buffer topology paths."
    puts $fh "- This is a measurement classification exception, not final signoff."
    close $fh
}

proc mptdc_o13_abs5_select_constraint_mode {} {
    if {[llength [info commands set_interactive_constraint_modes]] == 0} {
        return [list NOT_AVAILABLE "set_interactive_constraint_modes command not present"]
    }

    set candidates [list]
    foreach query {
        {get_db constraint_modes functional_mode}
        {get_db constraint_modes *functional_mode*}
        {all_constraint_modes}
    } {
        set found [list]
        catch {set found [eval $query]}
        foreach item [mptdc_collection_to_list $found] {
            if {$item ne "" && [lsearch -exact $candidates $item] < 0} {
                lappend candidates $item
            }
        }
    }
    if {[llength $candidates] == 0} {
        return [list NOT_FOUND "no constraint modes visible yet"]
    }

    set errors [list]
    foreach mode $candidates {
        if {![catch {set_interactive_constraint_modes $mode} err]} {
            return [list OK $mode]
        }
        lappend errors "$mode: $err"
    }

    return [list FAIL [join $errors " | "]]
}

proc mptdc_o13_abs5_apply_exact_q1_exception {{rpt_file ""}} {
    global this_run

    if {![mptdc_o13_abs5_enabled]} {
        return 0
    }

    array set endpoints [mptdc_o13_abs5_q1_pin_object_matrix]
    array set sources [mptdc_o13_abs5_slow_source_object_matrix]
    array set endpoint_by_pair $endpoints(by_pair)
    array set source_by_tap $sources(by_tap)

    set overmatch NO
    set undermatch NO
    if {$endpoints(duplicates) > 0 || $sources(duplicates) > 0 || \
        $endpoints(matched) > 64 || $sources(matched) > 8} {
        set overmatch YES
    }
    if {$endpoints(matched) < 64 || $sources(matched) < 8 || \
        [llength $endpoints(missing)] > 0 || [llength $sources(missing)] > 0} {
        set undermatch YES
    }

    set exception_applied NO
    set exception_failures 0
    set applied_endpoint_count 0
    set apply_rows [list]
    set mode_status "SKIPPED"
    set mode_detail "exact objects not complete"

    if {$endpoints(matched) == 64 && $sources(matched) == 8 && \
        $endpoints(duplicates) == 0 && $sources(duplicates) == 0 && \
        [llength $endpoints(missing)] == 0 && [llength $sources(missing)] == 0} {
        set mode_result [mptdc_o13_abs5_select_constraint_mode]
        set mode_status [lindex $mode_result 0]
        set mode_detail [lindex $mode_result 1]
        if {$mode_status eq "OK" || $mode_status eq "NOT_AVAILABLE"} {
            for {set tap 0} {$tap < 8} {incr tap} {
                set to_pins [list]
                for {set nf 0} {$nf < 8} {incr nf} {
                    lappend to_pins $endpoint_by_pair(${tap},${nf})
                }
                set source_pin $source_by_tap($tap)
                if {[catch {set_false_path -from $source_pin -to $to_pins} err]} {
                    incr exception_failures
                    lappend apply_rows [list $tap FAIL $err]
                    mptdc_message "O13 abs5 exact PD Vernier false path failed for slow tap $tap: $err" high
                } else {
                    incr applied_endpoint_count 8
                    lappend apply_rows [list $tap OK "applied to 8 q1 endpoints"]
                }
            }
        }
    }

    if {$exception_failures == 0 && $applied_endpoint_count == 64} {
        set exception_applied YES
    }

    set ::mptdc_o13_abs5_last_exception_applied $exception_applied
    set ::mptdc_o13_abs5_last_exception_stage $this_run(stage)
    set ::mptdc_o13_abs5_last_exception_endpoint_count $endpoints(matched)
    set ::mptdc_o13_abs5_last_exception_source_count $sources(matched)
    set ::mptdc_o13_abs5_last_exception_applied_endpoints $applied_endpoint_count

    mptdc_message "O13 abs5 PD Vernier exact exception stage=$this_run(stage) endpoints=$endpoints(matched) sources=$sources(matched) applied=$exception_applied constraint_mode=$mode_status:$mode_detail"

    if {$rpt_file ne ""} {
        mptdc_o13_abs5_write_exception_report \
            $rpt_file \
            $this_run(stage) \
            [array get endpoints] \
            [array get sources] \
            $apply_rows \
            $applied_endpoint_count \
            $exception_applied \
            $exception_failures \
            $overmatch \
            $undermatch \
            $mode_status \
            $mode_detail
    }

    return [expr {$exception_applied eq "YES"}]
}

proc mptdc_o13_join_or_none {items} {
    if {[llength $items] == 0} {
        return "none"
    }
    return [join $items ", "]
}

proc mptdc_o13_write_pd_vernier_discovery_reports {dir} {
    array set endpoints [mptdc_o13_pd_q1_endpoint_matrix]
    array set sources [mptdc_o13_pd_slow_source_matrix]
    array set by_pair $endpoints(by_pair)
    array set row_count $endpoints(row_count)
    array set col_count $endpoints(col_count)
    array set by_tap $sources(by_tap)
    array set tap_count $sources(tap_count)

    set endpoint_status "FAIL_ENDPOINT_DISCOVERY"
    if {$endpoints(matched) == 64 && $endpoints(duplicates) == 0 && [llength $endpoints(missing)] == 0} {
        set endpoint_status "PASS_64_ENDPOINTS"
    }
    set source_status "FAIL_SOURCE_DISCOVERY"
    if {$sources(matched) == 8 && $sources(duplicates) == 0 && [llength $sources(missing)] == 0} {
        set source_status "PASS_8_SLOW_SOURCES"
    }

    set fh [open "$dir/pd_vernier_endpoint_discovery.rpt" w]
    puts $fh "# O13 PD q1 Endpoint Discovery"
    puts $fh ""
    puts $fh "TOTAL_CANDIDATES=$endpoints(candidates)"
    puts $fh "TOTAL_MATCHED=$endpoints(matched)"
    puts $fh "EXPECTED_MATCHED=64"
    puts $fh "DUPLICATES=$endpoints(duplicates)"
    puts $fh "MISSING_PAIRS=[mptdc_o13_join_or_none $endpoints(missing)]"
    puts $fh "FINAL_STATUS=$endpoint_status"
    puts $fh ""
    puts $fh "## Per-row count"
    for {set ns 0} {$ns < 8} {incr ns} {
        puts $fh "row_${ns}=$row_count($ns)"
    }
    puts $fh ""
    puts $fh "## Per-column count"
    for {set nf 0} {$nf < 8} {incr nf} {
        puts $fh "col_${nf}=$col_count($nf)"
    }
    puts $fh ""
    puts $fh "## Endpoints"
    for {set ns 0} {$ns < 8} {incr ns} {
        for {set nf 0} {$nf < 8} {incr nf} {
            set key "${ns},${nf}"
            if {[info exists by_pair($key)]} {
                puts $fh "q1_endpoint($key)=$by_pair($key)"
            } else {
                puts $fh "q1_endpoint($key)=MISSING"
            }
        }
    }
    close $fh

    set fh [open "$dir/pd_vernier_source_discovery.rpt" w]
    puts $fh "# O13 PD slow-source Discovery"
    puts $fh ""
    puts $fh "TOTAL_CANDIDATES=$sources(candidates)"
    puts $fh "MATCHED_SLOW_BUFFER_OUTPUTS=$sources(matched)"
    puts $fh "EXPECTED_SLOW_BUFFER_OUTPUTS=8"
    puts $fh "DUPLICATES=$sources(duplicates)"
    puts $fh "MISSING_TAPS=[mptdc_o13_join_or_none $sources(missing)]"
    puts $fh "FINAL_STATUS=$source_status"
    puts $fh ""
    puts $fh "## Per-tap source"
    for {set tap 0} {$tap < 8} {incr tap} {
        if {[info exists by_tap($tap)]} {
            puts $fh "slow_source($tap)=$by_tap($tap)"
        } else {
            puts $fh "slow_source($tap)=MISSING"
        }
    }
    close $fh
}

proc mptdc_o13_abs4_write_phase_buffer_paths {rpt_file} {
    set fh [open $rpt_file w]
    puts $fh "# O13 Phase Buffer Topology Report"
    puts $fh ""
    puts $fh "This report is structural. Generated clocks can make RO->BUHDX4->BUHDX12 invisible as an ordinary data path, so the report traverses expected pins and clocks directly."
    puts $fh ""
    puts $fh "| family | tap | raw_ro_pin | buhdx4_a | buhdx4_q | buhdx12_a | buhdx12_q | raw_clock | buffer_clock | status |"
    puts $fh "|---|---:|---|---|---|---|---|---|---|---|"

    foreach family {slow fast} {
        for {set tap 0} {$tap < 8} {incr tap} {
            set raw_clock [expr {$tap == 0 ? "clk_osc_${family}" : "clk_osc_${family}_tap${tap}"}]
            set buffer_clock [format {clk_osc_%s_buf_tap%d} $family $tap]
            set raw_pin [mptdc_o13_abs4_first_name [list get_pins -quiet -hierarchical [lindex [mptdc_o13_abs4_raw_pin_patterns $family $tap] 0]]]
            if {$raw_pin eq "UNKNOWN"} {
                set raw_pin [mptdc_o13_abs4_first_name [list get_pins -quiet -hierarchical [lindex [mptdc_o13_abs4_raw_pin_patterns $family $tap] 1]]]
            }
            set iso_a [mptdc_o13_abs4_first_name [list get_pins -quiet -hierarchical [lindex [mptdc_o13_abs4_stage_pin_patterns $family $tap u_iso A] 0]]]
            if {$iso_a eq "UNKNOWN"} {
                set iso_a [mptdc_o13_abs4_first_name [list get_pins -quiet -hierarchical [lindex [mptdc_o13_abs4_stage_pin_patterns $family $tap u_iso A] 2]]]
            }
            set iso_q [mptdc_o13_abs4_first_name [list get_pins -quiet -hierarchical [lindex [mptdc_o13_abs4_stage_pin_patterns $family $tap u_iso Q] 0]]]
            if {$iso_q eq "UNKNOWN"} {
                set iso_q [mptdc_o13_abs4_first_name [list get_pins -quiet -hierarchical [lindex [mptdc_o13_abs4_stage_pin_patterns $family $tap u_iso Q] 2]]]
            }
            set drv_a [mptdc_o13_abs4_first_name [list get_pins -quiet -hierarchical [lindex [mptdc_o13_abs4_stage_pin_patterns $family $tap u_drv A] 0]]]
            if {$drv_a eq "UNKNOWN"} {
                set drv_a [mptdc_o13_abs4_first_name [list get_pins -quiet -hierarchical [lindex [mptdc_o13_abs4_stage_pin_patterns $family $tap u_drv A] 2]]]
            }
            set drv_q [mptdc_o13_abs4_first_name [list get_pins -quiet -hierarchical [lindex [mptdc_o13_abs4_stage_pin_patterns $family $tap u_drv Q] 0]]]
            if {$drv_q eq "UNKNOWN"} {
                set drv_q [mptdc_o13_abs4_first_name [list get_pins -quiet -hierarchical [lindex [mptdc_o13_abs4_stage_pin_patterns $family $tap u_drv Q] 2]]]
            }

            set status "OK_CHAIN_FOUND"
            if {$raw_pin eq "UNKNOWN"} { set status "MISSING_RAW_PIN" }
            if {$iso_a eq "UNKNOWN" || $iso_q eq "UNKNOWN"} { set status "MISSING_ISO_BUFFER" }
            if {$drv_a eq "UNKNOWN" || $drv_q eq "UNKNOWN"} { set status "MISSING_DRIVER_BUFFER" }
            if {[llength [get_clocks -quiet $buffer_clock]] == 0} { set status "MISSING_GENERATED_CLOCK" }
            puts $fh "| $family | $tap | `$raw_pin` | `$iso_a` | `$iso_q` | `$drv_a` | `$drv_q` | `$raw_clock` | `$buffer_clock` | $status |"
        }
    }
    puts $fh ""
    puts $fh "Required status for abs4: every row should be OK_CHAIN_FOUND."
    close $fh
}

proc mptdc_o13_abs4_write_pd_vernier_report {rpt_file} {
    array set endpoints [mptdc_o13_pd_q1_endpoint_matrix]
    array set sources [mptdc_o13_pd_slow_source_matrix]
    array set row_count $endpoints(row_count)
    array set by_pair $endpoints(by_pair)
    array set by_tap $sources(by_tap)

    set exception_applied "UNKNOWN"
    if {[mptdc_o13_abs5_enabled]} {
        if {[info exists ::mptdc_o13_abs5_last_exception_applied]} {
            set exception_applied $::mptdc_o13_abs5_last_exception_applied
        }
    }

    set fh [open $rpt_file w]
    puts $fh "# O13 PD Intentional Vernier Paths"
    puts $fh ""
    puts $fh "These are the intended slow buffered phase samples into PD q1 sampler flops. They are measurement crossings, not ordinary synchronous setup paths."
    puts $fh ""
    puts $fh "PD_INTENTIONAL_VERNIER_EXPECTED=64"
    puts $fh "PD_INTENTIONAL_VERNIER_MATCHED=$endpoints(matched)"
    puts $fh "PD_INTENTIONAL_VERNIER_SOURCES=$sources(matched)"
    puts $fh "PD_INTENTIONAL_VERNIER_EXCEPTION_APPLIED=$exception_applied"
    set vernier_status REVIEW_REQUIRED
    if {$endpoints(matched) == 64 && $sources(matched) == 8} {
        if {![mptdc_o13_abs5_enabled] || $exception_applied eq "YES"} {
            set vernier_status OK_INTENTIONAL_MEASUREMENT_CROSSING
        }
    }
    puts $fh "PD_INTENTIONAL_VERNIER_STATUS=$vernier_status"
    puts $fh ""
    puts $fh "| slow_tap | slow_clock | source_pin | q1_endpoint_count | status |"
    puts $fh "|---:|---|---|---:|---|"
    foreach tap {0 1 2 3 4 5 6 7} {
        set slow_clock [format {clk_osc_slow_buf_tap%d} $tap]
        set q1_count $row_count($tap)
        set source_name "MISSING"
        if {[info exists by_tap($tap)]} {
            set source_name $by_tap($tap)
        }
        set status $vernier_status
        if {[llength [get_clocks -quiet $slow_clock]] != 1 || $q1_count != 8 || $source_name eq "MISSING"} {
            set status "REVIEW_REQUIRED"
        }
        puts $fh "| $tap | `$slow_clock` | `$source_name` | $q1_count | $status |"
        for {set nf 0} {$nf < 8} {incr nf} {
            set key "${tap},${nf}"
            if {[info exists by_pair($key)]} {
                puts $fh "  - endpoint($key): `$by_pair($key)`"
            } else {
                puts $fh "  - endpoint($key): `MISSING`"
            }
        }
    }
    close $fh
}

proc mptdc_o13_abs4_write_clk_sys_reports {viol_rpt top_rpt} {
    set clk_sys [get_clocks -quiet clk_sys]
    if {[llength $clk_sys] == 0} {
        mptdc_write_report_failure $viol_rpt "O13 abs4 clk_sys internal violations" "clk_sys clock not found."
        mptdc_write_report_failure $top_rpt "O13 abs4 clk_sys internal top paths" "clk_sys clock not found."
        return
    }

    set tmp "${viol_rpt}.tmp"
    set fh [open $viol_rpt w]
    puts $fh "# O13 abs4 clk_sys Internal Violations"
    puts $fh ""
    if {[catch {report_timing -from $clk_sys -to $clk_sys -max_paths 100 -max_slack 0.0 -path_type full_clock > $tmp} err]} {
        puts $fh "FAILED: report_timing -from clk_sys -to clk_sys -max_paths 100 -max_slack 0.0 -path_type full_clock"
        puts $fh $err
    } else {
        set in [open $tmp r]
        set text [read $in]
        close $in
        if {[string match "*No paths found*" $text]} {
            puts $fh "CLK_SYS_INTERNAL_STATUS=NO_VIOLATIONS_FOUND"
            puts $fh ""
            puts $fh "No negative-slack clk_sys internal setup paths were reported with -max_slack 0.0."
        } else {
            puts $fh $text
        }
    }
    catch {file delete $tmp}
    close $fh

    if {[catch {report_timing -from $clk_sys -to $clk_sys -max_paths 100 -path_type full_clock > $top_rpt} err2]} {
        mptdc_write_report_failure $top_rpt "O13 abs4 clk_sys internal top paths" $err2
    }
}

proc mptdc_report_o13_abs3_timing {dir} {
    set raw_clocks [mptdc_o13_abs3_clock_collection [mptdc_o13_abs3_expected_clock_names raw]]
    set buf_clocks [mptdc_o13_abs3_clock_collection [mptdc_o13_abs3_expected_clock_names buffer]]
    set fast_buf_clocks [mptdc_o13_abs3_clock_collection [mptdc_o13_abs3_expected_clock_names fast_buffer]]
    set clk_sys [get_clocks -quiet clk_sys]

    mptdc_o13_abs3_write_clock_model_check "$dir/o13_clock_model_check.rpt"
    mptdc_o13_abs3_write_cdc_async_review "$dir/timing_cdc_async_review.rpt"
    if {[mptdc_o13_abs4_or_abs5_enabled]} {
        if {[mptdc_o13_abs5_enabled]} {
            mptdc_o13_abs5_apply_exact_q1_exception "$dir/pd_vernier_exception_check.rpt"
        }
        mptdc_o13_write_pd_vernier_discovery_reports $dir
        mptdc_o13_abs4_write_pd_vernier_report "$dir/timing_pd_intentional_vernier.rpt"
    }

    set pd_endpoints [mptdc_o13_abs3_pin_collection [list \
        *gen_pd_row*gen_pd_col*u_pd*/q1_reg*/D \
        *gen_pd_row*gen_pd_col*u_pd*/q1_reg*/d \
        *gen_pd_row*gen_pd_col*u_pd*/q2_reg*/D \
        *gen_pd_row*gen_pd_col*u_pd*/q2_reg*/d \
        *gen_pd_row*gen_pd_col*u_pd*/hit_latched_reg*/D \
        *gen_pd_row*gen_pd_col*u_pd*/hit_latched_reg*/d \
        *gen_pd_row*gen_pd_col*u_pd*/nfast_hit_latched_reg*/D \
        *gen_pd_row*gen_pd_col*u_pd*/nfast_hit_latched_reg*/d]]
    mptdc_o13_abs3_run_timing_report \
        "$dir/timing_pd_capture_hotspots.rpt" \
        "O13 abs3 local PD capture timing report" \
        $fast_buf_clocks \
        $pd_endpoints \
        200

    if {[mptdc_o13_abs4_or_abs5_enabled]} {
        mptdc_o13_abs4_write_clk_sys_reports \
            "$dir/timing_clk_sys_violations.rpt" \
            "$dir/timing_clk_sys_internal_top100.rpt"
    } else {
        mptdc_o13_abs3_run_timing_report \
            "$dir/timing_clk_sys_violations.rpt" \
            "O13 abs3 real clk_sys internal timing report" \
            $clk_sys \
            $clk_sys \
            200
    }

    if {[mptdc_o13_abs4_or_abs5_enabled]} {
        mptdc_o13_abs4_write_phase_buffer_paths "$dir/timing_o13_phase_buffer_paths.rpt"
    } else {
        mptdc_o13_abs3_run_timing_report \
            "$dir/timing_o13_phase_buffer_paths.rpt" \
            "O13 abs3 phase-buffer clock propagation timing report" \
            $raw_clocks \
            $buf_clocks \
            64
    }
}

proc mptdc_collect_names {cmd} {
    set names [list]
    array set seen {}
    if {[catch {set objs [eval $cmd]}]} {
        return $names
    }

    foreach obj [mptdc_collection_to_list $objs] {
        set name [mptdc_object_name $obj]
        mptdc_append_unique_names $name names seen
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
        ] {
            set matches [mptdc_collect_names "get_pins -quiet -hierarchical $pin_pattern"]
            if {[llength $matches] > 0} {
                set names [concat $names $matches]
            }
        }
    }
    return [mptdc_unique_list $names]
}

proc mptdc_glob_escape {text} {
    set map [list {\\} {\\\\} {[} {\[} {]} {\]} {*} {\*} {?} {\?}]
    return [string map $map $text]
}

proc mptdc_normalize_timing_pin_name {text} {
    set out $text
    regsub {^\([RF]\)[[:space:]]+} $out {} out
    return $out
}

proc mptdc_append_pin_matches {matches pins_var seen_var} {
    upvar 1 $pins_var pins
    upvar 1 $seen_var seen
    foreach pin [mptdc_collection_to_list $matches] {
        set pin_name [mptdc_object_name $pin]
        if {$pin_name ne "" && ![info exists seen($pin_name)]} {
            set seen($pin_name) 1
            lappend pins $pin
        }
    }
}

proc mptdc_collect_pin_objects_from_names {pin_names} {
    set pins [list]
    array set seen {}
    set unresolved [list]
    foreach name $pin_names {
        set name [mptdc_normalize_timing_pin_name $name]
        set matches [list]
        foreach query [list $name [mptdc_glob_escape $name]] {
            catch {set matches [get_pins -quiet $query]}
            mptdc_append_pin_matches $matches pins seen
            catch {set matches [get_pins -quiet -hierarchical $query]}
            mptdc_append_pin_matches $matches pins seen
        }
        if {![info exists seen($name)]} {
            lappend unresolved $name
        }
    }

    if {[llength $unresolved] > 0} {
        array set wanted {}
        foreach name $unresolved {
            set wanted($name) 1
        }
        set all_pins [list]
        if {![catch {set all_pins [get_pins -quiet -hierarchical *]}]} {
            foreach pin [mptdc_collection_to_list $all_pins] {
                set pin_name [mptdc_object_name $pin]
                if {[info exists wanted($pin_name)] && ![info exists seen($pin_name)]} {
                    set seen($pin_name) 1
                    lappend pins $pin
                }
            }
        }
    }
    return $pins
}

proc mptdc_write_helper_tcl_selftest {rpt_file} {
    set fh [open $rpt_file w]
    puts $fh "# MPTDC Helper Tcl Selftest"
    puts $fh ""
    puts $fh "Purpose: validate bracket-safe helper string handling inside the active Tcl interpreter."
    puts $fh ""
    set status PASS
    foreach name {
        gen_pd_row[0].gen_pd_col[7].u_pd/q1_reg/D
        gen_phase_buf[7].u_drv/Q
        u_core_gen_fast_tag_col[7].u_fast_tag_tag_o_reg[5]/C
    } {
        if {[catch {set escaped [mptdc_glob_escape $name]} err]} {
            set status FAIL
            puts $fh "NAME=$name"
            puts $fh "ERROR=$err"
            continue
        }
        set normalized [mptdc_normalize_timing_pin_name "(R) $name"]
        puts $fh "NAME=$name"
        puts $fh "ESCAPED=$escaped"
        puts $fh "NORMALIZED=$normalized"
        if {$normalized ne $name} {
            set status FAIL
            puts $fh "NORMALIZE_STATUS=FAIL"
        } else {
            puts $fh "NORMALIZE_STATUS=PASS"
        }
        if {[string first {\[} $escaped] < 0 || [string first {\]} $escaped] < 0} {
            set status FAIL
            puts $fh "BRACKET_ESCAPE_STATUS=FAIL"
        } else {
            puts $fh "BRACKET_ESCAPE_STATUS=PASS"
        }
        puts $fh ""
    }
    puts $fh "HELPER_TCL_SELFTEST_STATUS=$status"
    close $fh
}

proc mptdc_run_timing_to_names {rpt_file title endpoint_names} {
    if {[llength $endpoint_names] == 0} {
        mptdc_write_recorded_report_failure $rpt_file $title "No endpoint names provided."
        return
    }

    set endpoint_objs [mptdc_collect_pin_objects_from_names $endpoint_names]
    if {[llength $endpoint_objs] == 0} {
        mptdc_write_recorded_report_failure $rpt_file $title \
            "No valid timing endpoint pins resolved from [llength $endpoint_names] candidate name(s). report_timing was not run with cell names or raw strings because Genus rejects those objects for -to in this flow."
        return
    }

    set errors [list]
    foreach path_type [list full_clock full endpoint {}] {
        if {$path_type ne ""} {
            if {![catch {report_timing -to $endpoint_objs -max_paths 100 -path_type $path_type > $rpt_file} err]} {
                return
            }
            lappend errors "report_timing -to <[llength $endpoint_names] endpoints> -max_paths 100 -path_type $path_type: $err"
        } else {
            if {![catch {report_timing -to $endpoint_objs -max_paths 100 > $rpt_file} err]} {
                return
            }
            lappend errors "report_timing -to <[llength $endpoint_names] endpoints> -max_paths 100: $err"
        }
    }

    mptdc_write_recorded_report_failure $rpt_file $title [join $errors "\n\n"]
}

proc mptdc_run_fast_clock_to_names {rpt_file title endpoint_names {max_paths 300}} {
    if {[llength $endpoint_names] == 0} {
        mptdc_write_recorded_report_failure $rpt_file $title "No endpoint names provided."
        return
    }

    set fast_clocks [get_clocks -quiet clk_osc_fast]
    if {[llength $fast_clocks] == 0} {
        catch {set fast_clocks [get_clocks -quiet clk_osc_fast_buf_tap*]}
    }
    if {[llength $fast_clocks] == 0} {
        catch {set fast_clocks [get_clocks -quiet clk_osc_fast_raw_tap*]}
    }
    if {[llength $fast_clocks] == 0} {
        mptdc_write_recorded_report_failure $rpt_file $title \
            "No fast oscillator clocks were found. Tried clk_osc_fast, clk_osc_fast_buf_tap*, and clk_osc_fast_raw_tap*."
        return
    }

    set endpoint_objs [mptdc_collect_pin_objects_from_names $endpoint_names]
    if {[llength $endpoint_objs] == 0} {
        mptdc_write_recorded_report_failure $rpt_file $title \
            "No valid timing endpoint pins resolved from [llength $endpoint_names] candidate name(s). report_timing was not run with cell names or raw strings because Genus rejects those objects for -to in this flow."
        return
    }

    set errors [list]
    foreach path_type [list full_clock full endpoint {}] {
        if {$path_type ne ""} {
            if {![catch {report_timing -from $fast_clocks -to $endpoint_objs -max_paths $max_paths -path_type $path_type > $rpt_file} err]} {
                return
            }
            lappend errors "report_timing -from clk_osc_fast -to <[llength $endpoint_names] endpoints> -max_paths $max_paths -path_type $path_type: $err"
        } else {
            if {![catch {report_timing -from $fast_clocks -to $endpoint_objs -max_paths $max_paths > $rpt_file} err]} {
                return
            }
            lappend errors "report_timing -from clk_osc_fast -to <[llength $endpoint_names] endpoints> -max_paths $max_paths: $err"
        }
    }

    mptdc_write_recorded_report_failure $rpt_file $title [join $errors "\n\n"]
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

proc mptdc_try_release_cells_for_repair {label patterns fh} {
    set cells [mptdc_collect_cell_objects $patterns]
    puts $fh "${label}_MATCHED_CELLS=[llength $cells]"
    if {[llength $cells] == 0} {
        return
    }
    catch {set_dont_touch $cells false} err1
    catch {set_db $cells .dont_touch false} err2
    catch {set_db $cells .preserve false} err3
    puts $fh "${label}_DONT_TOUCH_RELEASE=set_dont_touch:$err1 set_db_dont_touch:$err2 set_db_preserve:$err3"
}

proc mptdc_try_unavoid_lib_cells {label patterns fh} {
    set cells [list]
    foreach pattern $patterns {
        set matches [list]
        catch {set matches [get_db lib_cells $pattern]}
        foreach cell [mptdc_collection_to_list $matches] {
            lappend cells $cell
        }
    }
    set cells [mptdc_unique_list $cells]
    puts $fh "${label}_LIB_CELLS=[llength $cells]"
    foreach cell $cells {
        catch {set_db $cell .avoid false} err1
        catch {set_db $cell .dont_use false} err2
        puts $fh "${label}_LIB_CELL=[mptdc_object_name $cell] avoid:$err1 dont_use:$err2"
    }
}

proc mptdc_try_avoid_lib_cells {label patterns fh} {
    set cells [list]
    foreach pattern $patterns {
        set matches [list]
        catch {set matches [get_db lib_cells $pattern]}
        foreach cell [mptdc_collection_to_list $matches] {
            lappend cells $cell
        }
    }
    set cells [mptdc_unique_list $cells]
    puts $fh "${label}_AVOID_LIB_CELLS=[llength $cells]"
    foreach cell $cells {
        catch {set_db $cell .avoid true} err1
        puts $fh "${label}_AVOID_LIB_CELL=[mptdc_object_name $cell] avoid:$err1"
    }
}

proc mptdc_repair_collect_pins {patterns} {
    set pins [list]
    array set seen {}
    foreach pattern $patterns {
        set matches [list]
        catch {set matches [get_pins -quiet -hierarchical $pattern]}
        foreach pin [mptdc_collection_to_list $matches] {
            set name [mptdc_object_name $pin]
            if {$name ne "" && ![info exists seen($name)]} {
                set seen($name) 1
                lappend pins $pin
            }
        }
    }
    return $pins
}

proc mptdc_repair_parse_index_list {value default_value} {
    set raw $value
    if {$raw eq ""} {
        set raw $default_value
    }
    set raw [string map [list "," " "] $raw]
    set out [list]
    foreach item [split $raw] {
        set item [string trim $item]
        if {$item eq ""} {
            continue
        }
        if {![regexp {^[0-9]+$} $item]} {
            continue
        }
        lappend out $item
    }
    return [mptdc_unique_list $out]
}

proc mptdc_repair_index_in_list {value values} {
    return [expr {[lsearch -exact $values $value] >= 0}]
}

proc mptdc_repair_csv_quote {value} {
    set escaped [string map {"\"" "\"\""} $value]
    return "\"$escaped\""
}

proc mptdc_repair_fast_tag_pin_info {role name pin_name} {
    set lname [string tolower $name]
    set lpin [string tolower $pin_name]
    if {![regexp -- [format {/%s$} $lpin] $lname]} {
        return ""
    }

    if {$role eq "source"} {
        if {[regexp {gen_fast_tag_col\[([0-9]+)\].*tag_o_reg\[([0-9]+)\]/([a-z]+)$} $lname -> tap bit pin]} {
            return [dict create role source tap $tap bit $bit pin $pin]
        }
        if {[regexp {gen_fast_tag_col_?([0-9]+)([^0-9].*)?tag_o_reg_?([0-9]+)([^0-9].*)?/([a-z]+)$} $lname -> tap _ bit _ pin]} {
            return [dict create role source tap $tap bit $bit pin $pin]
        }
        return ""
    }

    if {$role eq "endpoint"} {
        if {[regexp {gen_pd_row\[([0-9]+)\].*gen_pd_col\[([0-9]+)\].*nfast_hit_latched_reg\[([0-9]+)\]/([a-z]+)$} $lname -> row tap bit pin]} {
            return [dict create role endpoint row $row tap $tap bit $bit pin $pin]
        }
        if {[regexp {gen_pd_row_?([0-9]+)([^0-9].*)?gen_pd_col_?([0-9]+)([^0-9].*)?nfast_hit_latched_reg_?([0-9]+)([^0-9].*)?/([a-z]+)$} $lname -> row _ tap _ bit _ pin]} {
            return [dict create role endpoint row $row tap $tap bit $bit pin $pin]
        }
        return ""
    }

    return ""
}

proc mptdc_repair_collect_exact_fast_tag_pin_records {role taps bits pin_name} {
    set patterns [list]
    if {$role eq "source"} {
        lappend patterns [format {*tag_o_reg*/%s} $pin_name]
        lappend patterns [format {*fast_tag*tag_o_reg*/%s} $pin_name]
        lappend patterns [format {*gen_fast_tag_col*u_fast_tag*tag_o_reg*/%s} $pin_name]
    } elseif {$role eq "endpoint"} {
        lappend patterns [format {*nfast_hit_latched_reg*/%s} $pin_name]
        lappend patterns [format {*gen_pd_row*gen_pd_col*nfast_hit_latched_reg*/%s} $pin_name]
        lappend patterns [format {*gen_pd_col*nfast_hit_latched_reg*/%s} $pin_name]
    } else {
        return [list]
    }

    set records [list]
    array set seen {}
    foreach pin [mptdc_repair_collect_pins $patterns] {
        set name [mptdc_object_name $pin]
        if {$name eq "" || [info exists seen($name)]} {
            continue
        }
        set info [mptdc_repair_fast_tag_pin_info $role $name $pin_name]
        if {$info eq ""} {
            continue
        }
        set tap [dict get $info tap]
        set bit [dict get $info bit]
        if {![mptdc_repair_index_in_list $tap $taps] || ![mptdc_repair_index_in_list $bit $bits]} {
            continue
        }
        dict set info object $pin
        dict set info name $name
        set seen($name) 1
        lappend records $info
    }
    return $records
}

proc mptdc_repair_collect_exact_fast_tag_pins {role taps bits pin_name} {
    set pins [list]
    foreach rec [mptdc_repair_collect_exact_fast_tag_pin_records $role $taps $bits $pin_name] {
        lappend pins [dict get $rec object]
    }
    return $pins
}

proc mptdc_repair_pin_instance_name {pin_name} {
    if {[regexp {^(.+)/[^/]+$} $pin_name -> inst_name]} {
        return $inst_name
    }
    return ""
}

proc mptdc_repair_resolve_cell_from_instance_name {inst_name} {
    if {$inst_name eq ""} {
        return ""
    }
    foreach query [list [mptdc_glob_escape $inst_name] $inst_name] {
        foreach cmd [list \
            [list get_cells -quiet $query] \
            [list get_cells -quiet -hierarchical $query]] {
            set matches [list]
            catch {set matches [eval $cmd]}
            foreach cell [mptdc_collection_to_list $matches] {
                set cell_name [mptdc_object_name $cell]
                if {$cell_name eq $inst_name} {
                    return $cell
                }
            }
        }
    }
    set all_cells [list]
    catch {set all_cells [get_cells -quiet -hierarchical *]}
    foreach cell [mptdc_collection_to_list $all_cells] {
        if {[mptdc_object_name $cell] eq $inst_name} {
            return $cell
        }
    }
    return ""
}

proc mptdc_repair_collect_cells_from_pin_records {records} {
    set cells [list]
    array set seen {}
    foreach rec $records {
        set pin_name [dict get $rec name]
        set inst_name [mptdc_repair_pin_instance_name $pin_name]
        set cell [mptdc_repair_resolve_cell_from_instance_name $inst_name]
        if {$cell eq ""} {
            continue
        }
        set cell_name [mptdc_object_name $cell]
        if {$cell_name ne "" && ![info exists seen($cell_name)]} {
            set seen($cell_name) 1
            lappend cells $cell
        }
    }
    return $cells
}

proc mptdc_repair_cell_base_name {cell} {
    foreach attr {.base_cell.base_name .base_cell.name .lib_cell.base_name .lib_cell.name .ref_name .cell.name .name} {
        if {![catch {set value [get_db $cell $attr]}] && $value ne ""} {
            return [file tail $value]
        }
    }
    return "UNKNOWN"
}

proc mptdc_repair_find_lib_cell {cell_name} {
    if {$cell_name eq ""} {
        return ""
    }
    set matches [list]
    foreach pattern [list $cell_name "*$cell_name" "*/$cell_name"] {
        set found [list]
        catch {set found [get_db lib_cells $pattern]}
        foreach cell [mptdc_collection_to_list $found] {
            set base "UNKNOWN"
            foreach attr {.base_name .name} {
                if {![catch {set value [get_db $cell $attr]}] && $value ne ""} {
                    set base [file tail $value]
                    break
                }
            }
            if {$base eq $cell_name || [file tail [mptdc_object_name $cell]] eq $cell_name} {
                lappend matches $cell
            }
        }
    }
    set matches [mptdc_unique_list $matches]
    if {[llength $matches] > 0} {
        return [lindex $matches 0]
    }
    return ""
}

proc mptdc_repair_count_cells_with_base {cells base_name} {
    set count 0
    foreach cell $cells {
        if {[mptdc_repair_cell_base_name $cell] eq $base_name} {
            incr count
        }
    }
    return $count
}

proc mptdc_repair_default_exact_source_cell_result {target_cell} {
    return [dict create \
        requested [expr {$target_cell ne "" ? {YES} : {NO}}] \
        target_cell $target_cell \
        target_lib_cells_found 0 \
        source_cells_found 0 \
        source_cells_target_count 0 \
        method SKIPPED \
        status SKIPPED_SOURCE_CELL_NOT_REQUESTED \
        source_cell_mode [expr {$target_cell eq "POLARITY_AWARE" ? {POLARITY_AWARE} : {SINGLE_TARGET}}] \
        reset0_source_count 0 \
        set1_source_count 0 \
        unsupported_polarity_count 0 \
        selected_reset0_target NA \
        selected_set1_target NA \
        drrqhdx4_target_count 0 \
        dfrsqhdx4_target_count 0 \
        dfrsqhdx2_target_count 0 \
        drrqjihdx4_target_count 0 \
        dfrsjihdx4_target_count 0 \
        dfrsjihdx2_target_count 0 \
        polarity_preserved_count 0 \
        polarity_failed_count 0 \
        freeze_result SKIPPED]
}

proc mptdc_repair_source_polarity_from_cell {base_cell} {
    if {[regexp {^(S)?DFRRQHDX[0-9]+$} $base_cell] ||
        [regexp {^(S)?DFRRQJIHDX[0-9]+$} $base_cell]} {
        return RESET0
    }
    if {[regexp {^(S)?DFRSQHDX[0-9]+$} $base_cell] ||
        [regexp {^(S)?DFRSJIHDX[0-9]+$} $base_cell]} {
        return SET1
    }
    return UNKNOWN
}

proc mptdc_repair_source_record_cell_info {rec} {
    set pin_name [dict get $rec name]
    set inst_name [mptdc_repair_pin_instance_name $pin_name]
    set cell [mptdc_repair_resolve_cell_from_instance_name $inst_name]
    set base "UNRESOLVED"
    if {$cell ne ""} {
        set base [mptdc_repair_cell_base_name $cell]
    }
    dict set rec inst $inst_name
    dict set rec cell $cell
    dict set rec current_cell $base
    dict set rec polarity [mptdc_repair_source_polarity_from_cell $base]
    return $rec
}

proc mptdc_repair_write_exact_source_cell_csv_rows {report_dir rows} {
    set fh [open "$report_dir/fast_tag_exact_source_cell_repair.csv" a]
    if {[tell $fh] == 0} {
        puts $fh "stage,source_instance,tap,bit,original_cell,target_cell,command,command_status,final_cell,polarity_preserved,notes"
    }
    foreach row $rows {
        puts $fh "[dict get $row stage],[mptdc_repair_csv_quote [dict get $row source_instance]],[dict get $row tap],[dict get $row bit],[dict get $row original_cell],[dict get $row target_cell],[mptdc_repair_csv_quote [dict get $row command]],[mptdc_repair_csv_quote [dict get $row command_status]],[dict get $row final_cell],[dict get $row polarity_preserved],[mptdc_repair_csv_quote [dict get $row notes]]"
    }
    close $fh
}

proc mptdc_repair_write_exact_source_cell_csv {report_dir stage source_records target_cell source_cells} {
    set cell_by_inst [dict create]
    foreach cell $source_cells {
        set cell_name [mptdc_object_name $cell]
        if {$cell_name ne ""} {
            dict set cell_by_inst $cell_name [mptdc_repair_cell_base_name $cell]
        }
    }
    set rows [list]
    foreach rec $source_records {
        set pin_name [dict get $rec name]
        set inst_name [mptdc_repair_pin_instance_name $pin_name]
        set current_cell "UNRESOLVED"
        set status "UNRESOLVED"
        if {[dict exists $cell_by_inst $inst_name]} {
            set current_cell [dict get $cell_by_inst $inst_name]
            set status [expr {$current_cell eq $target_cell ? {TARGET_MATCH} : {TARGET_PENDING}}]
        }
        lappend rows [dict create \
            stage $stage \
            source_instance $inst_name \
            tap [dict get $rec tap] \
            bit [dict get $rec bit] \
            original_cell $current_cell \
            target_cell $target_cell \
            command "single_target_status" \
            command_status $status \
            final_cell $current_cell \
            polarity_preserved NA \
            notes "legacy_single_target"]
    }
    mptdc_repair_write_exact_source_cell_csv_rows $report_dir $rows
}

proc mptdc_repair_write_exact_source_legal_cells_report {report_dir stage reset0_found set1_4_found set1_2_found selected_reset0 selected_set1} {
    set fh [open "$report_dir/fast_tag_exact_source_cell_legal_cells.rpt" a]
    puts $fh "STAGE=$stage"
    puts $fh "DFRRQHDX4_FOUND=$reset0_found"
    puts $fh "DFRSQHDX4_FOUND=$set1_4_found"
    puts $fh "DFRSQHDX2_FOUND=$set1_2_found"
    puts $fh "SELECTED_RESET0_TARGET=$selected_reset0"
    puts $fh "SELECTED_SET1_TARGET=$selected_set1"
    puts $fh ""
    close $fh
}

proc mptdc_repair_command_text {cmd} {
    set parts [list]
    foreach item $cmd {
        if {[catch {set text [mptdc_object_name $item]}] || $text eq ""} {
            set text $item
        }
        lappend parts $text
    }
    return [join $parts " "]
}

proc mptdc_repair_cell_change_attempts {cell target_lib target_cell} {
    set attempts [list]
    if {[llength [info commands change_link]] > 0} {
        lappend attempts [list change_link_object [list change_link $cell $target_lib]]
        lappend attempts [list change_link_name [list change_link $cell $target_cell]]
    }
    if {[llength [info commands size_cell]] > 0} {
        lappend attempts [list size_cell_name [list size_cell $cell $target_cell]]
    }
    if {[llength [info commands resize_cell]] > 0} {
        lappend attempts [list resize_cell_name [list resize_cell $cell $target_cell]]
    }
    if {[llength [info commands set_attribute]] > 0} {
        lappend attempts [list set_attribute_lib_cell_object [list set_attribute lib_cell $target_lib $cell]]
        lappend attempts [list set_attribute_lib_cell_name [list set_attribute lib_cell $target_cell $cell]]
    }
    if {[llength [info commands set_db]] > 0} {
        lappend attempts [list set_db_lib_cell [list set_db $cell .lib_cell $target_lib]]
        lappend attempts [list set_db_base_cell [list set_db $cell .base_cell $target_lib]]
    }
    if {[llength [info commands eco_change_cell]] > 0} {
        lappend attempts [list eco_change_cell_object [list eco_change_cell -inst $cell -cell $target_lib]]
        lappend attempts [list eco_change_cell_name [list eco_change_cell -inst $cell -cell $target_cell]]
    }
    if {[llength [info commands replace_cell]] > 0} {
        lappend attempts [list replace_cell_name [list replace_cell $cell $target_cell]]
    }
    return $attempts
}

proc mptdc_repair_try_change_exact_source_cell {stage rec target_cell target_lib ladder_fh} {
    set cell [dict get $rec cell]
    set inst_name [dict get $rec inst]
    set original_cell [dict get $rec current_cell]
    set final_cell $original_cell
    set best_command "NO_COMMAND"
    set best_status "NO_SUPPORTED_CELL_CHANGE_COMMAND"
    if {$cell eq "" || $target_lib eq ""} {
        return [dict create command $best_command status "NO_CELL_OR_TARGET_LIB" final_cell $final_cell]
    }
    foreach attempt [mptdc_repair_cell_change_attempts $cell $target_lib $target_cell] {
        set label [lindex $attempt 0]
        set cmd [lindex $attempt 1]
        set command_text [mptdc_repair_command_text $cmd]
        set rc [catch {eval $cmd} err]
        set final_cell [mptdc_repair_cell_base_name $cell]
        set status [expr {$rc == 0 ? {COMMAND_ACCEPTED} : $err}]
        puts $ladder_fh "STAGE=$stage INSTANCE=$inst_name ORIGINAL=$original_cell TARGET=$target_cell COMMAND=$label TEXT=[mptdc_repair_csv_quote $command_text] STATUS=[mptdc_repair_csv_quote $status] FINAL=$final_cell"
        set best_command $label
        set best_status $status
        if {$rc == 0 && $final_cell eq $target_cell} {
            return [dict create command $label status OK final_cell $final_cell]
        }
    }
    return [dict create command $best_command status $best_status final_cell $final_cell]
}

proc mptdc_repair_apply_exact_source_cell_polarity_aware {stage source_records report_dir fh} {
    set result [mptdc_repair_default_exact_source_cell_result POLARITY_AWARE]
    dict set result requested YES
    dict set result source_cell_mode POLARITY_AWARE
    set skip_unsupported [mptdc_bool_env MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED false]

    set reset0_target [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL DFRRQHDX4]
    set set1_requested [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL ""]
    set reset0_lib [mptdc_repair_find_lib_cell $reset0_target]
    if {[string match *JIHD* $reset0_target]} {
        set default_set1_4 DFRSJIHDX4
        set default_set1_2 DFRSJIHDX2
    } else {
        set default_set1_4 DFRSQHDX4
        set default_set1_2 DFRSQHDX2
    }
    set set1_4_lib [mptdc_repair_find_lib_cell $default_set1_4]
    set set1_2_lib [mptdc_repair_find_lib_cell $default_set1_2]
    set selected_set1 "NA"
    set selected_set1_lib ""
    if {$set1_requested ne ""} {
        set selected_set1 $set1_requested
        set selected_set1_lib [mptdc_repair_find_lib_cell $set1_requested]
    } elseif {$set1_4_lib ne ""} {
        set selected_set1 $default_set1_4
        set selected_set1_lib $set1_4_lib
    } elseif {$set1_2_lib ne ""} {
        set selected_set1 $default_set1_2
        set selected_set1_lib $set1_2_lib
    }
    mptdc_repair_write_exact_source_legal_cells_report \
        $report_dir \
        $stage \
        [expr {$reset0_lib ne "" ? {YES} : {NO}}] \
        [expr {$set1_4_lib ne "" ? {YES} : {NO}}] \
        [expr {$set1_2_lib ne "" ? {YES} : {NO}}] \
        $reset0_target \
        $selected_set1

    dict set result selected_reset0_target $reset0_target
    dict set result selected_set1_target $selected_set1
    dict set result target_lib_cells_found [expr {($reset0_lib ne "" ? 1 : 0) + ($selected_set1_lib ne "" ? 1 : 0)}]
    if {$reset0_lib ne ""} {
        catch {set_db $reset0_lib .avoid false}
        catch {set_db $reset0_lib .dont_use false}
    }
    if {$selected_set1_lib ne ""} {
        catch {set_db $selected_set1_lib .avoid false}
        catch {set_db $selected_set1_lib .dont_use false}
    }

    set resolved_records [list]
    foreach rec $source_records {
        lappend resolved_records [mptdc_repair_source_record_cell_info $rec]
    }
    dict set result source_cells_found [llength $resolved_records]

    set reset0_count 0
    set set1_count 0
    set unsupported_count 0
    foreach rec $resolved_records {
        set polarity [dict get $rec polarity]
        if {$polarity eq "RESET0"} {
            incr reset0_count
        } elseif {$polarity eq "SET1"} {
            incr set1_count
        } else {
            incr unsupported_count
        }
    }
    dict set result reset0_source_count $reset0_count
    dict set result set1_source_count $set1_count
    dict set result unsupported_polarity_count $unsupported_count

    if {$stage ne "post_map_pre_opt"} {
        dict set result status SKIPPED_UNTIL_POST_MAP_PRE_OPT
        return $result
    }
    if {$reset0_lib eq "" || $selected_set1_lib eq ""} {
        dict set result status FAIL_TARGET_LIB_CELL_NOT_FOUND
        return $result
    }
    if {[llength $resolved_records] == 0 || ($unsupported_count > 0 && !$skip_unsupported)} {
        dict set result status FAIL_UNSUPPORTED_SOURCE_POLARITY
        return $result
    }

    set ladder_fh [open "$report_dir/fast_tag_exact_source_cell_command_ladder.rpt" a]
    puts $ladder_fh "STAGE=$stage"
    set rows [list]
    set target_cells [list]
    set target_count 0
    set drrq4_count 0
    set dfrsq4_count 0
    set dfrsq2_count 0
    set drrqjihd4_count 0
    set dfrsjihd4_count 0
    set dfrsjihd2_count 0
    set polarity_preserved 0
    set polarity_failed 0
    array set seen_cells {}
    set known_polarity_count [expr {$reset0_count + $set1_count}]
    foreach rec $resolved_records {
        set polarity [dict get $rec polarity]
        set original_cell [dict get $rec current_cell]
        if {$polarity eq "UNKNOWN"} {
            lappend rows [dict create \
                stage $stage \
                source_instance [dict get $rec inst] \
                tap [dict get $rec tap] \
                bit [dict get $rec bit] \
                original_cell $original_cell \
                target_cell SKIPPED_UNSUPPORTED_POLARITY \
                command SKIPPED \
                command_status SKIPPED_UNSUPPORTED_POLARITY \
                final_cell $original_cell \
                polarity_preserved NA \
                notes "unsupported_polarity_left_unchanged"]
            continue
        }
        set target_cell $reset0_target
        set target_lib $reset0_lib
        if {$polarity eq "SET1"} {
            set target_cell $selected_set1
            set target_lib $selected_set1_lib
        }
        set change_result [mptdc_repair_try_change_exact_source_cell $stage $rec $target_cell $target_lib $ladder_fh]
        set final_cell [dict get $change_result final_cell]
        set final_polarity [mptdc_repair_source_polarity_from_cell $final_cell]
        set preserved [expr {$final_polarity eq $polarity ? {YES} : {NO}}]
        if {$preserved eq "YES"} {
            incr polarity_preserved
        } else {
            incr polarity_failed
        }
        if {$final_cell eq $target_cell} {
            incr target_count
            set cell [dict get $rec cell]
            set cell_name [mptdc_object_name $cell]
            if {$cell_name ne "" && ![info exists seen_cells($cell_name)]} {
                set seen_cells($cell_name) 1
                lappend target_cells $cell
            }
        }
        if {$final_cell eq "DFRRQHDX4"} { incr drrq4_count }
        if {$final_cell eq "DFRSQHDX4"} { incr dfrsq4_count }
        if {$final_cell eq "DFRSQHDX2"} { incr dfrsq2_count }
        if {$final_cell eq "DFRRQJIHDX4"} {
            incr drrq4_count
            incr drrqjihd4_count
        }
        if {$final_cell eq "DFRSJIHDX4"} {
            incr dfrsq4_count
            incr dfrsjihd4_count
        }
        if {$final_cell eq "DFRSJIHDX2"} {
            incr dfrsq2_count
            incr dfrsjihd2_count
        }
        lappend rows [dict create \
            stage $stage \
            source_instance [dict get $rec inst] \
            tap [dict get $rec tap] \
            bit [dict get $rec bit] \
            original_cell $original_cell \
            target_cell $target_cell \
            command [dict get $change_result command] \
            command_status [dict get $change_result status] \
            final_cell $final_cell \
            polarity_preserved $preserved \
            notes [expr {$final_cell eq $target_cell ? {final_verified} : {target_not_verified}}]]
    }
    puts $ladder_fh ""
    close $ladder_fh
    mptdc_repair_write_exact_source_cell_csv_rows $report_dir $rows

    dict set result source_cells_target_count $target_count
    dict set result drrqhdx4_target_count $drrq4_count
    dict set result dfrsqhdx4_target_count $dfrsq4_count
    dict set result dfrsqhdx2_target_count $dfrsq2_count
    dict set result drrqjihdx4_target_count $drrqjihd4_count
    dict set result dfrsjihdx4_target_count $dfrsjihd4_count
    dict set result dfrsjihdx2_target_count $dfrsjihd2_count
    dict set result polarity_preserved_count $polarity_preserved
    dict set result polarity_failed_count $polarity_failed
    dict set result method POLARITY_AWARE_COMMAND_LADDER

    set freeze_fh [open "$report_dir/fast_tag_exact_source_freeze.rpt" a]
    puts $freeze_fh "STAGE=$stage"
    puts $freeze_fh "FAST_TAG_EXACT_SOURCE_FREEZE_REQUESTED=NO"
    puts $freeze_fh "FAST_TAG_EXACT_SOURCE_FREEZE_CELLS=0"
    puts $freeze_fh "FAST_TAG_EXACT_SOURCE_FREEZE_RESULT=SKIPPED_NOT_FINAL_VERIFIED"
    if {$known_polarity_count > 0 && $target_count == $known_polarity_count && $polarity_failed == 0} {
        close $freeze_fh
        set freeze_fh [open "$report_dir/fast_tag_exact_source_freeze.rpt" a]
        puts $freeze_fh "STAGE=$stage"
        puts $freeze_fh "FAST_TAG_EXACT_SOURCE_FREEZE_REQUESTED=YES"
        puts $freeze_fh "FAST_TAG_EXACT_SOURCE_FREEZE_CELLS=[llength $target_cells]"
        mptdc_try_preserve_cells $target_cells
        foreach cell $target_cells {
            puts $freeze_fh "FAST_TAG_EXACT_SOURCE_FREEZE_CELL=[mptdc_object_name $cell] cell=[mptdc_repair_cell_base_name $cell]"
        }
        puts $freeze_fh "FAST_TAG_EXACT_SOURCE_FREEZE_RESULT=OK"
        dict set result freeze_result OK
        if {$unsupported_count > 0} {
            dict set result status PASS_PARTIAL_UNSUPPORTED_SKIPPED
        } else {
            dict set result status PASS_FINAL_VERIFIED
        }
    } else {
        dict set result freeze_result SKIPPED_NOT_FINAL_VERIFIED
        dict set result status FAIL_NOT_APPLIED
    }
    puts $freeze_fh ""
    close $freeze_fh
    return $result
}

proc mptdc_repair_apply_exact_source_cell {stage source_records target_cell report_dir fh} {
    set result [mptdc_repair_default_exact_source_cell_result $target_cell]

    set requested_mode [string toupper [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE ""]]
    if {$target_cell eq "POLARITY_AWARE" || $requested_mode eq "POLARITY_AWARE" || [mptdc_bool_env MPTDC_GENUS_REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE false]} {
        return [mptdc_repair_apply_exact_source_cell_polarity_aware $stage $source_records $report_dir $fh]
    }

    if {$target_cell eq ""} {
        return [mptdc_repair_default_exact_source_cell_result $target_cell]
    }
    if {$stage ne "post_map_pre_opt"} {
        dict set result status SKIPPED_UNTIL_POST_MAP_PRE_OPT
        return $result
    }

    set source_cells [mptdc_repair_collect_cells_from_pin_records $source_records]
    dict set result source_cells_found [llength $source_cells]
    set target_lib [mptdc_repair_find_lib_cell $target_cell]
    if {$target_lib ne ""} {
        dict set result target_lib_cells_found 1
        catch {set_db $target_lib .avoid false}
        catch {set_db $target_lib .dont_use false}
    }
    if {[llength $source_cells] == 0} {
        dict set result status NO_EXACT_SOURCE_CELLS
        return $result
    }
    if {$target_lib eq ""} {
        mptdc_repair_write_exact_source_cell_csv $report_dir $stage $source_records $target_cell $source_cells
        dict set result status TARGET_LIB_CELL_NOT_FOUND
        return $result
    }

    set method_result "NO_SUPPORTED_CELL_CHANGE_COMMAND"
    set method_used "NONE"
    set attempts [list]
    if {[llength [info commands change_link]] > 0} {
        lappend attempts [list change_link_object [list change_link $source_cells $target_lib]]
        lappend attempts [list change_link_name [list change_link $source_cells $target_cell]]
    }
    if {[llength [info commands eco_change_cell]] > 0} {
        lappend attempts [list eco_change_cell_object [list eco_change_cell -inst $source_cells -cell $target_lib]]
        lappend attempts [list eco_change_cell_name [list eco_change_cell -inst $source_cells -cell $target_cell]]
    }
    if {[llength [info commands size_cell]] > 0} {
        lappend attempts [list size_cell_name [list size_cell $source_cells $target_cell]]
    }
    if {[llength [info commands replace_cell]] > 0} {
        lappend attempts [list replace_cell_name [list replace_cell $source_cells $target_cell]]
    }
    foreach attempt $attempts {
        set label [lindex $attempt 0]
        set cmd [lindex $attempt 1]
        set rc [catch {eval $cmd} err]
        lappend method_result "$label:$err"
        if {$rc == 0} {
            set method_used $label
            break
        }
    }

    set target_count [mptdc_repair_count_cells_with_base $source_cells $target_cell]
    dict set result source_cells_target_count $target_count
    dict set result method $method_used
    mptdc_repair_write_exact_source_cell_csv $report_dir $stage $source_records $target_cell $source_cells
    if {$target_count == [llength $source_cells]} {
        dict set result status OK
    } elseif {$method_used ne "NONE"} {
        dict set result status COMMAND_ACCEPTED_VERIFY_AFTER_OPT
    } else {
        dict set result status $method_result
    }
    return $result
}

proc mptdc_repair_apply_exact_full_path_max_delay {delay from_pins to_pins} {
    set mode_result [mptdc_o13_abs5_select_constraint_mode]
    set mode_status [lindex $mode_result 0]
    set mode_detail [lindex $mode_result 1]
    if {$mode_status ne "OK" && $mode_status ne "NOT_AVAILABLE"} {
        return [dict create result "CONSTRAINT_MODE_FAIL:$mode_detail" mode_status $mode_status mode_detail $mode_detail]
    }
    set rc [catch {
        set_max_delay $delay \
            -from $from_pins \
            -to $to_pins
    } err]
    return [dict create \
        result [expr {$rc == 0 ? {OK} : $err}] \
        mode_status $mode_status \
        mode_detail $mode_detail]
}

proc mptdc_repair_write_fast_tag_exact_csvs {report_dir taps bits source_records endpoint_records pair_records} {
    set fh [open "$report_dir/fast_tag_exact_source_discovery.csv" w]
    puts $fh "tap,bit,pin_name,object"
    foreach rec $source_records {
        puts $fh "[dict get $rec tap],[dict get $rec bit],[dict get $rec pin],[mptdc_repair_csv_quote [dict get $rec name]]"
    }
    close $fh

    set fh [open "$report_dir/fast_tag_exact_endpoint_discovery.csv" w]
    puts $fh "row,col,bit,pin_name,object"
    foreach rec $endpoint_records {
        puts $fh "[dict get $rec row],[dict get $rec tap],[dict get $rec bit],[dict get $rec pin],[mptdc_repair_csv_quote [dict get $rec name]]"
    }
    close $fh

    set fh [open "$report_dir/fast_tag_exact_path_pairs.csv" w]
    puts $fh "col,bit,row,source_pin,endpoint_pin,status"
    foreach rec $pair_records {
        puts $fh "[dict get $rec tap],[dict get $rec bit],[dict get $rec row],[mptdc_repair_csv_quote [dict get $rec source]],[mptdc_repair_csv_quote [dict get $rec endpoint]],[dict get $rec status]"
    }
    close $fh
}

proc mptdc_repair_set_numeric_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_repair_net_fanout {net} {
    foreach attr {.num_loads .fanout} {
        if {![catch {set value [get_db $net $attr]}] && [string is integer -strict $value]} {
            return $value
        }
    }
    foreach attr {.loads .load_pins .pins} {
        if {![catch {set loads [get_db $net $attr]}]} {
            return [llength [mptdc_collection_to_list $loads]]
        }
    }
    return -1
}

proc mptdc_repair_net_load_names {net} {
    set out [list]
    foreach attr {.loads .load_pins .pins} {
        if {[catch {set loads [get_db $net $attr]}]} {
            continue
        }
        foreach load [mptdc_collection_to_list $loads] {
            set name [mptdc_object_name $load]
            if {$name ne ""} {
                lappend out $name
            }
        }
        if {[llength $out] > 0} {
            break
        }
    }
    return $out
}

proc mptdc_collect_exact_control_root_nets {
    min_fanout
    fh
    {require_pd_sinks false}
    {allow_reset_roots true}
    {driver_regex ""}
    {net_regex ""}
    {max_roots 0}
} {
    set selected [list]
    set rows [list]
    if {![string is integer -strict $max_roots]} {
        set max_roots 0
    }
    puts $fh "EXACT_CONTROL_ROOT_REQUIRE_PD_SINKS=$require_pd_sinks"
    puts $fh "EXACT_CONTROL_ROOT_ALLOW_RESET_ROOTS=$allow_reset_roots"
    puts $fh "EXACT_CONTROL_ROOT_DRIVER_REGEX=$driver_regex"
    puts $fh "EXACT_CONTROL_ROOT_NET_REGEX=$net_regex"
    puts $fh "EXACT_CONTROL_ROOT_MAX_ROOTS=$max_roots"
    if {[catch {set nets [get_db nets]} err]} {
        puts $fh "EXACT_CONTROL_ROOT_QUERY_ERROR=$err"
        return $selected
    }
    foreach net [mptdc_collection_to_list $nets] {
        set net_name [mptdc_object_name $net]
        if {$net_name eq ""} {
            set net_name "UNKNOWN"
        }
        set low_name [string tolower $net_name]
        if {[string match *clk* $low_name] ||
            [string match *clock* $low_name] ||
            [string match *phase* $low_name] ||
            [string match *ro_tune4* $low_name]} {
            continue
        }
        set fanout [mptdc_repair_net_fanout $net]
        if {$fanout < $min_fanout} {
            continue
        }
        set pd_sink_count 0
        set reset_sink_count 0
        foreach load_name [mptdc_repair_net_load_names $net] {
            set low_load [string tolower $load_name]
            if {[string match *gen_pd_row* $low_load] && [string match *u_pd* $low_load]} {
                incr pd_sink_count
            }
            if {[string match *rst* $low_load] || [string match */rn $low_load] || [string match */reset* $low_load]} {
                incr reset_sink_count
            }
        }
        if {$pd_sink_count == 0 && $reset_sink_count == 0} {
            continue
        }
        if {$require_pd_sinks && $pd_sink_count == 0} {
            continue
        }
        if {!$allow_reset_roots && $reset_sink_count > 0} {
            continue
        }
        set driver ""
        if {![catch {set drv [get_db $net .driver]}] && [llength $drv] > 0} {
            set driver [mptdc_object_name $drv]
        }
        if {$driver_regex ne "" && ![regexp -- $driver_regex $driver]} {
            continue
        }
        if {$net_regex ne "" && ![regexp -- $net_regex $net_name]} {
            continue
        }
        lappend rows [list $fanout $net_name $driver $pd_sink_count $reset_sink_count $net]
    }
    set rows [lsort -integer -decreasing -index 0 $rows]
    set emitted 0
    foreach row $rows {
        if {$max_roots > 0 && $emitted >= $max_roots} {
            break
        }
        lappend selected [lindex $row 5]
        incr emitted
    }
    set selected [mptdc_unique_list $selected]
    puts $fh "EXACT_CONTROL_ROOT_NETS=[llength $selected]"
    set emitted 0
    foreach row $rows {
        if {$max_roots > 0 && $emitted >= $max_roots} {
            break
        }
        puts $fh "EXACT_CONTROL_ROOT_NET=[lindex $row 1] fanout=[lindex $row 0] driver=[lindex $row 2] pd_sinks=[lindex $row 3] reset_sinks=[lindex $row 4]"
        incr emitted
    }
    return $selected
}

proc mptdc_apply_final_typical_repair_1 {stage} {
    global design
    set fast_repair [mptdc_bool_env MPTDC_GENUS_REPAIR_FAST_TAG_PD false]
    set drv_repair [mptdc_bool_env MPTDC_GENUS_REPAIR_DRV_TRANSITION false]
    set repair4_exact_source_drive [mptdc_bool_env MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE false]
    set repair5_exact_close [mptdc_bool_env MPTDC_GENUS_REPAIR5_EXACT_FAST_TAG_CLOSE false]
    set repair6_localtag_preserve_close [mptdc_bool_env MPTDC_GENUS_REPAIR6_LOCALTAG_PRESERVE_CLOSE false]
    set repair7_polarity_source_upgrade [mptdc_bool_env MPTDC_GENUS_REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE false]
    set repair8_jihd_exact_close [mptdc_bool_env MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE false]
    if {$repair6_localtag_preserve_close || $repair7_polarity_source_upgrade || $repair8_jihd_exact_close} {
        set repair4_exact_source_drive true
        set repair5_exact_close true
    }
    set strong_fast_flops [mptdc_bool_env MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS false]
    set strong_control_drv [mptdc_bool_env MPTDC_GENUS_REPAIR_STRONG_CONTROL_DRV false]
    set control_bias_stage [string tolower [mptdc_repair_set_numeric_env MPTDC_GENUS_REPAIR_CONTROL_CELL_BIAS_STAGE all]]
    set control_avoid_inhdx8 [mptdc_bool_env MPTDC_GENUS_REPAIR_CONTROL_AVOID_INHDX8 true]
    set exact_control_roots [mptdc_bool_env MPTDC_GENUS_REPAIR_EXACT_CONTROL_ROOTS false]
    set exact_control_min_fanout [mptdc_repair_set_numeric_env MPTDC_CONTROL_REPAIR_EXACT_MIN_FANOUT 64]
    set exact_control_require_pd_sinks [mptdc_bool_env MPTDC_CONTROL_REPAIR_EXACT_REQUIRE_PD_SINKS false]
    set exact_control_allow_reset_roots [mptdc_bool_env MPTDC_CONTROL_REPAIR_EXACT_ALLOW_RESET_ROOTS true]
    set exact_control_driver_regex [mptdc_repair_set_numeric_env MPTDC_CONTROL_REPAIR_EXACT_DRIVER_REGEX ""]
    set exact_control_net_regex [mptdc_repair_set_numeric_env MPTDC_CONTROL_REPAIR_EXACT_NET_REGEX ""]
    set exact_control_max_roots [mptdc_repair_set_numeric_env MPTDC_CONTROL_REPAIR_EXACT_MAX_ROOTS 0]
    set apply_fast_tag_q_constraints [mptdc_bool_env MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS true]
    set apply_broad_control_nets [mptdc_bool_env MPTDC_GENUS_REPAIR_APPLY_BROAD_CONTROL_NETS true]
    set fast_tag_max_fanout [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_MAX_FANOUT 16]
    set fast_tag_max_transition [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_MAX_TRANSITION_NS 0.50]
    set exact_fast_tag_data_paths [mptdc_bool_env MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS false]
    set exact_fast_tag_taps [mptdc_repair_parse_index_list [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_EXACT_TAPS ""] ""]
    set exact_fast_tag_bits [mptdc_repair_parse_index_list [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_EXACT_BITS ""] ""]
    set exact_fast_tag_max_fanout [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT 4]
    set exact_fast_tag_max_transition [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS 0.35]
    set exact_fast_tag_max_delay [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS ""]
    set enable_exact_fast_tag_max_delay [expr {
        [mptdc_bool_env MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY false] ||
        [mptdc_bool_env MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE false]
    }]
    set exact_fast_tag_source_cell [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL ""]
    set exact_fast_tag_source_cell_mode [string toupper [mptdc_repair_set_numeric_env MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE ""]]
    if {$repair7_polarity_source_upgrade && $exact_fast_tag_source_cell eq ""} {
        set exact_fast_tag_source_cell POLARITY_AWARE
        set exact_fast_tag_source_cell_mode POLARITY_AWARE
    }
    set endpoint_transition_tight [mptdc_bool_env MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT false]
    set control_max_fanout [mptdc_repair_set_numeric_env MPTDC_CONTROL_REPAIR_MAX_FANOUT 16]
    set control_max_transition [mptdc_repair_set_numeric_env MPTDC_CONTROL_REPAIR_MAX_TRANSITION_NS 0.50]
    set design_drv_repair [mptdc_bool_env MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV false]
    if {$repair4_exact_source_drive} {
        set exact_fast_tag_data_paths true
        if {![mptdc_bool_env MPTDC_GENUS_REPAIR4_ALLOW_BROAD_FAST_TAG_Q false]} {
            set apply_fast_tag_q_constraints false
        }
        set endpoint_transition_tight false
    }
    if {$repair5_exact_close || $exact_fast_tag_source_cell ne ""} {
        set exact_fast_tag_data_paths true
        set apply_fast_tag_q_constraints false
        set endpoint_transition_tight false
    }
    if {!$fast_repair && !$drv_repair} {
        return
    }

    file mkdir $design(reports_dir)
    set rpt_file "$design(reports_dir)/final_typical_genus_repair_1.rpt"
    set fh [open $rpt_file a]
    puts $fh "# FINAL_TYPICAL_GENUS_REPAIR_1"
    puts $fh "STAGE=$stage"
    puts $fh "FAST_TAG_PD_REPAIR=$fast_repair"
    puts $fh "DRV_TRANSITION_REPAIR=$drv_repair"
    puts $fh "REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE=$repair4_exact_source_drive"
    puts $fh "REPAIR5_EXACT_FAST_TAG_CLOSE=$repair5_exact_close"
    puts $fh "REPAIR6_LOCALTAG_PRESERVE_CLOSE=$repair6_localtag_preserve_close"
    puts $fh "REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE=$repair7_polarity_source_upgrade"
    puts $fh "REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE=$repair8_jihd_exact_close"
    puts $fh "STRONG_FAST_TAG_FLOPS=$strong_fast_flops"
    puts $fh "STRONG_CONTROL_DRV=$strong_control_drv"
    puts $fh "CONTROL_CELL_BIAS_STAGE=$control_bias_stage"
    puts $fh "CONTROL_AVOID_INHDX8=$control_avoid_inhdx8"
    puts $fh "EXACT_CONTROL_ROOT_REPAIR=$exact_control_roots"
    puts $fh "EXACT_CONTROL_ROOT_MIN_FANOUT=$exact_control_min_fanout"
    puts $fh "EXACT_CONTROL_ROOT_REQUIRE_PD_SINKS=$exact_control_require_pd_sinks"
    puts $fh "EXACT_CONTROL_ROOT_ALLOW_RESET_ROOTS=$exact_control_allow_reset_roots"
    puts $fh "EXACT_CONTROL_ROOT_DRIVER_REGEX=$exact_control_driver_regex"
    puts $fh "EXACT_CONTROL_ROOT_NET_REGEX=$exact_control_net_regex"
    puts $fh "EXACT_CONTROL_ROOT_MAX_ROOTS=$exact_control_max_roots"
    puts $fh "FAST_TAG_APPLY_Q_CONSTRAINTS=$apply_fast_tag_q_constraints"
    puts $fh "CONTROL_APPLY_BROAD_NETS=$apply_broad_control_nets"
    puts $fh "FAST_TAG_MAX_FANOUT=$fast_tag_max_fanout"
    puts $fh "FAST_TAG_MAX_TRANSITION_NS=$fast_tag_max_transition"
    puts $fh "FAST_TAG_EXACT_DATA_PATHS=$exact_fast_tag_data_paths"
    puts $fh "FAST_TAG_EXACT_TAPS=[join $exact_fast_tag_taps {,}]"
    puts $fh "FAST_TAG_EXACT_BITS=[join $exact_fast_tag_bits {,}]"
    puts $fh "FAST_TAG_EXACT_MAX_FANOUT=$exact_fast_tag_max_fanout"
    puts $fh "FAST_TAG_EXACT_MAX_TRANSITION_NS=$exact_fast_tag_max_transition"
    puts $fh "FAST_TAG_EXACT_MAX_DELAY_NS=$exact_fast_tag_max_delay"
    puts $fh "FAST_TAG_EXACT_ENABLE_MAX_DELAY=$enable_exact_fast_tag_max_delay"
    puts $fh "FAST_TAG_EXACT_SOURCE_CELL=$exact_fast_tag_source_cell"
    puts $fh "FAST_TAG_EXACT_SOURCE_CELL_MODE=$exact_fast_tag_source_cell_mode"
    puts $fh "ENDPOINT_TRANSITION_TIGHT=$endpoint_transition_tight"
    puts $fh "CONTROL_MAX_FANOUT=$control_max_fanout"
    puts $fh "CONTROL_MAX_TRANSITION_NS=$control_max_transition"
    puts $fh "APPLY_DESIGN_DRV_REPAIR=$design_drv_repair"
    puts $fh "TIMESTAMP=[clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %Z}]"

    if {$fast_repair} {
        mptdc_message "FINAL_TYPICAL_GENUS_REPAIR_1: enabling targeted fast-tag to PD timing repair"
        mptdc_try_release_cells_for_repair FAST_TAG_PATH {
            *gen_fast_tag_col*
            *u_fast_tag*
        } $fh
        puts $fh "NFAST_CAPTURE_PATH_DONT_TOUCH_RELEASE=SKIPPED_PRESERVE_PD_FABRIC"
        mptdc_try_unavoid_lib_cells FAST_TAG_SOURCE_FLOP_CANDIDATES {
            *DFRRQHDX4*
            *DFRRQHDX2*
            *DFRSQHDX4*
            *DFRSQHDX2*
            *DFRHDX2*
            *DFRQHDX2*
            *DFRRQJIHDX4*
            *DFRRQJIHDX2*
            *DFRJIHDX4*
            *DFRJIHDX2*
            *DFRSJIHDX2*
        } $fh
        if {$strong_fast_flops} {
            mptdc_try_avoid_lib_cells FAST_TAG_WEAK_RESET_FLOPS {
                */DFRRQHDX1
                */SDFRRQHDX1
                */DFRSQHDX1
                */SDFRSQHDX1
                */DFRRQHDX2
                */SDFRRQHDX2
            } $fh
            mptdc_try_unavoid_lib_cells FAST_TAG_PREFERRED_RESET_FLOPS {
                *DFRRQHDX4*
                *DFRSQHDX4*
                *DFRSQHDX2*
            } $fh
        }

        set fast_tag_q_pins [mptdc_repair_collect_pins {
            *gen_fast_tag_col*u_fast_tag*tag_o_reg*/Q
            *u_fast_tag_tag_o_reg*/Q
            *u_fast_tag*tag_o_reg*/Q
        }]
        set fast_tag_c_pins [mptdc_repair_collect_pins {
            *gen_fast_tag_col*u_fast_tag*tag_o_reg*/C
            *u_fast_tag_tag_o_reg*/C
            *u_fast_tag*tag_o_reg*/C
        }]
        set nfast_capture_d_pins [mptdc_repair_collect_pins {
            *gen_pd_row*gen_pd_col*u_pd*nfast_hit_latched_reg*/D
            *nfast_hit_latched_reg*/D
        }]
        puts $fh "FAST_TAG_Q_PINS=[llength [mptdc_collection_to_list $fast_tag_q_pins]]"
        puts $fh "FAST_TAG_C_PINS=[llength [mptdc_collection_to_list $fast_tag_c_pins]]"
        puts $fh "NFAST_CAPTURE_D_PINS=[llength [mptdc_collection_to_list $nfast_capture_d_pins]]"
        if {[llength $fast_tag_q_pins] > 0} {
            if {$apply_fast_tag_q_constraints} {
                set fanout_rc [catch {set_max_fanout $fast_tag_max_fanout $fast_tag_q_pins} err_fanout]
                set trans_rc [catch {set_max_transition $fast_tag_max_transition $fast_tag_q_pins} err_trans]
                puts $fh "FAST_TAG_Q_SET_MAX_FANOUT=[expr {$fanout_rc == 0 ? {OK} : $err_fanout}]"
                puts $fh "FAST_TAG_Q_SET_MAX_TRANSITION=[expr {$trans_rc == 0 ? {OK} : $err_trans}]"
            } else {
                puts $fh "FAST_TAG_Q_SET_MAX_FANOUT=SKIPPED_FAST_TAG_Q_CONSTRAINTS_DISABLED"
                puts $fh "FAST_TAG_Q_SET_MAX_TRANSITION=SKIPPED_FAST_TAG_Q_CONSTRAINTS_DISABLED"
            }
        }
        if {[llength $fast_tag_c_pins] > 0} {
            if {[llength [info commands set_critical_range]] > 0} {
                catch {set_critical_range 0.050 $fast_tag_c_pins} err_crit
                puts $fh "FAST_TAG_C_SET_CRITICAL_RANGE_0P050=[expr {$err_crit eq {} ? {OK} : $err_crit}]"
            } else {
                puts $fh "FAST_TAG_C_SET_CRITICAL_RANGE_0P050=NOT_SUPPORTED_BY_THIS_GENUS_VERSION"
            }
        }
        if {[llength $fast_tag_q_pins] > 0 && [llength $nfast_capture_d_pins] > 0 && \
            [info exists ::env(MPTDC_FAST_TAG_REPAIR_MAX_DELAY_NS)] && \
            $::env(MPTDC_FAST_TAG_REPAIR_MAX_DELAY_NS) ne ""} {
            catch {
                set_max_delay $::env(MPTDC_FAST_TAG_REPAIR_MAX_DELAY_NS) \
                    -from $fast_tag_q_pins \
                    -to $nfast_capture_d_pins
            } err_delay
            puts $fh "FAST_TAG_TO_NFAST_CAPTURE_SET_MAX_DELAY_NS=$::env(MPTDC_FAST_TAG_REPAIR_MAX_DELAY_NS)"
            puts $fh "FAST_TAG_TO_NFAST_CAPTURE_SET_MAX_DELAY_RESULT=$err_delay"
        }
        if {$exact_fast_tag_data_paths} {
            if {[llength $exact_fast_tag_taps] == 0 || [llength $exact_fast_tag_bits] == 0} {
                puts $fh "FAST_TAG_EXACT_STATUS=SKIPPED_EMPTY_TAPS_OR_BITS"
                set status_fh [open "$design(reports_dir)/fast_tag_exact_repair_status.rpt" a]
                puts $status_fh "STAGE=$stage"
                puts $status_fh "EXACT_FAST_TAG_REPAIR_STATUS=REVIEW_REQUIRED"
                puts $status_fh "EXACT_FAST_TAG_REPAIR_APPLIED=NO"
                puts $status_fh "EXACT_FAST_TAG_REVIEW_REASON=EMPTY_TAPS_OR_BITS"
                close $status_fh
            } else {
                set exact_rows {0 1 2 3 4 5 6 7}
                set exact_source_q_records [mptdc_repair_collect_exact_fast_tag_pin_records source $exact_fast_tag_taps $exact_fast_tag_bits Q]
                set exact_source_c_records [mptdc_repair_collect_exact_fast_tag_pin_records source $exact_fast_tag_taps $exact_fast_tag_bits C]
                set exact_endpoint_d_records [mptdc_repair_collect_exact_fast_tag_pin_records endpoint $exact_fast_tag_taps $exact_fast_tag_bits D]
                set exact_source_q_pins [list]
                foreach rec $exact_source_q_records { lappend exact_source_q_pins [dict get $rec object] }
                set exact_source_c_pins [list]
                foreach rec $exact_source_c_records { lappend exact_source_c_pins [dict get $rec object] }
                set exact_endpoint_d_pins [list]
                foreach rec $exact_endpoint_d_records { lappend exact_endpoint_d_pins [dict get $rec object] }
                set exact_source_expected [expr {[llength $exact_fast_tag_taps] * [llength $exact_fast_tag_bits]}]
                set exact_endpoint_expected [expr {[llength $exact_rows] * [llength $exact_fast_tag_taps] * [llength $exact_fast_tag_bits]}]
                set exact_pair_expected $exact_endpoint_expected
                array set source_by_key {}
                foreach rec $exact_source_q_records {
                    set key "[dict get $rec tap],[dict get $rec bit]"
                    set source_by_key($key) [dict get $rec name]
                }
                array set endpoint_by_key {}
                foreach rec $exact_endpoint_d_records {
                    set key "[dict get $rec tap],[dict get $rec bit],[dict get $rec row]"
                    set endpoint_by_key($key) [dict get $rec name]
                }
                set pair_records [list]
                set exact_pair_found 0
                foreach tap $exact_fast_tag_taps {
                    foreach bit $exact_fast_tag_bits {
                        set source_key "$tap,$bit"
                        foreach row $exact_rows {
                            set endpoint_key "$tap,$bit,$row"
                            if {[info exists source_by_key($source_key)] && [info exists endpoint_by_key($endpoint_key)]} {
                                incr exact_pair_found
                                lappend pair_records [dict create tap $tap bit $bit row $row source $source_by_key($source_key) endpoint $endpoint_by_key($endpoint_key) status FOUND]
                            } else {
                                set source_name ""
                                set endpoint_name ""
                                if {[info exists source_by_key($source_key)]} { set source_name $source_by_key($source_key) }
                                if {[info exists endpoint_by_key($endpoint_key)]} { set endpoint_name $endpoint_by_key($endpoint_key) }
                                lappend pair_records [dict create tap $tap bit $bit row $row source $source_name endpoint $endpoint_name status MISSING]
                            }
                        }
                    }
                }
                mptdc_repair_write_fast_tag_exact_csvs $design(reports_dir) $exact_fast_tag_taps $exact_fast_tag_bits $exact_source_q_records $exact_endpoint_d_records $pair_records
                puts $fh "FAST_TAG_EXACT_SOURCE_Q_PINS=[llength [mptdc_collection_to_list $exact_source_q_pins]]"
                puts $fh "FAST_TAG_EXACT_SOURCE_C_PINS=[llength [mptdc_collection_to_list $exact_source_c_pins]]"
                puts $fh "FAST_TAG_EXACT_ENDPOINT_D_PINS=[llength [mptdc_collection_to_list $exact_endpoint_d_pins]]"
                puts $fh "FAST_TAG_EXACT_SOURCES_EXPECTED=$exact_source_expected"
                puts $fh "FAST_TAG_EXACT_SOURCES_FOUND=[llength $exact_source_q_records]"
                puts $fh "FAST_TAG_EXACT_ENDPOINTS_EXPECTED=$exact_endpoint_expected"
                puts $fh "FAST_TAG_EXACT_ENDPOINTS_FOUND=[llength $exact_endpoint_d_records]"
                puts $fh "FAST_TAG_EXACT_PATH_PAIRS_EXPECTED=$exact_pair_expected"
                puts $fh "FAST_TAG_EXACT_PATH_PAIRS_FOUND=$exact_pair_found"
                foreach pin [mptdc_collection_to_list $exact_source_q_pins] {
                    puts $fh "FAST_TAG_EXACT_SOURCE_Q_PIN=[mptdc_object_name $pin]"
                }
                foreach pin [mptdc_collection_to_list $exact_endpoint_d_pins] {
                    puts $fh "FAST_TAG_EXACT_ENDPOINT_D_PIN=[mptdc_object_name $pin]"
                }
                set exact_counts_ok [expr {
                    [llength $exact_source_q_records] == $exact_source_expected &&
                    [llength $exact_source_c_records] == $exact_source_expected &&
                    [llength $exact_endpoint_d_records] == $exact_endpoint_expected &&
                    $exact_pair_found == $exact_pair_expected
                }]
                set exact_group_result "SKIPPED"
                set exact_fanout_result "SKIPPED"
                set exact_trans_result "SKIPPED"
                set exact_endpoint_trans_result "SKIPPED_ENDPOINT_TRANSITION_TIGHT_DISABLED"
                set exact_delay_result "SKIPPED_EXACT_MAX_DELAY_DISABLED"
                set exact_delay_mode_status "SKIPPED"
                set exact_delay_mode_detail "SKIPPED"
                set exact_source_cell_result [mptdc_repair_default_exact_source_cell_result $exact_fast_tag_source_cell]
                if {$exact_counts_ok && [llength $exact_source_c_pins] > 0 && [llength $exact_endpoint_d_pins] > 0} {
                    if {[llength [info commands group_path]] > 0} {
                        set group_rc [catch {
                            group_path -name FAST_TAG_TO_PD_TS_EXACT_B056 \
                                -from $exact_source_c_pins \
                                -to $exact_endpoint_d_pins \
                                -weight 8 \
                                -critical_range 0.080
                        } group_err]
                        if {$group_rc != 0} {
                            set group_rc [catch {
                                group_path -name FAST_TAG_TO_PD_TS_EXACT_B056 \
                                    -from $exact_source_c_pins \
                                    -to $exact_endpoint_d_pins
                            } group_err]
                        }
                        set exact_group_result [expr {$group_rc == 0 ? {OK} : $group_err}]
                    } else {
                        set exact_group_result "NOT_SUPPORTED_BY_THIS_GENUS_VERSION"
                    }
                }
                if {$exact_counts_ok && [llength $exact_source_q_pins] > 0} {
                    set exact_fanout_rc [catch {set_max_fanout $exact_fast_tag_max_fanout $exact_source_q_pins} exact_fanout_err]
                    set exact_trans_rc [catch {set_max_transition $exact_fast_tag_max_transition $exact_source_q_pins} exact_trans_err]
                    set exact_fanout_result [expr {$exact_fanout_rc == 0 ? {OK} : $exact_fanout_err}]
                    set exact_trans_result [expr {$exact_trans_rc == 0 ? {OK} : $exact_trans_err}]
                    puts $fh "FAST_TAG_EXACT_Q_SET_MAX_FANOUT=$exact_fanout_result"
                    puts $fh "FAST_TAG_EXACT_Q_SET_MAX_TRANSITION=$exact_trans_result"
                } else {
                    if {!$exact_counts_ok} {
                        puts $fh "FAST_TAG_EXACT_Q_SET_MAX_FANOUT=SKIPPED_EXACT_COUNTS_MISMATCH"
                        puts $fh "FAST_TAG_EXACT_Q_SET_MAX_TRANSITION=SKIPPED_EXACT_COUNTS_MISMATCH"
                    } else {
                        puts $fh "FAST_TAG_EXACT_Q_SET_MAX_FANOUT=SKIPPED_NO_SOURCE_Q_PINS"
                        puts $fh "FAST_TAG_EXACT_Q_SET_MAX_TRANSITION=SKIPPED_NO_SOURCE_Q_PINS"
                    }
                }
                if {$exact_counts_ok && $endpoint_transition_tight && [llength $exact_endpoint_d_pins] > 0} {
                    set exact_endpoint_trans_rc [catch {set_max_transition $exact_fast_tag_max_transition $exact_endpoint_d_pins} exact_endpoint_trans_err]
                    set exact_endpoint_trans_result [expr {$exact_endpoint_trans_rc == 0 ? {OK} : $exact_endpoint_trans_err}]
                    puts $fh "FAST_TAG_EXACT_D_SET_MAX_TRANSITION=$exact_endpoint_trans_result"
                } else {
                    puts $fh "FAST_TAG_EXACT_D_SET_MAX_TRANSITION=$exact_endpoint_trans_result"
                }
                if {$exact_counts_ok && $stage eq "post_map_pre_opt"} {
                    set exact_source_cell_result [mptdc_repair_apply_exact_source_cell \
                        $stage \
                        $exact_source_q_records \
                        $exact_fast_tag_source_cell \
                        $design(reports_dir) \
                        $fh]
                }
                if {$exact_counts_ok && $enable_exact_fast_tag_max_delay && [llength $exact_source_c_pins] > 0 && [llength $exact_endpoint_d_pins] > 0 && $exact_fast_tag_max_delay ne ""} {
                    set delay_dict [mptdc_repair_apply_exact_full_path_max_delay \
                        $exact_fast_tag_max_delay \
                        $exact_source_c_pins \
                        $exact_endpoint_d_pins]
                    set exact_delay_result [dict get $delay_dict result]
                    set exact_delay_mode_status [dict get $delay_dict mode_status]
                    set exact_delay_mode_detail [dict get $delay_dict mode_detail]
                }
                puts $fh "FAST_TAG_EXACT_GROUP_PATH_RESULT=$exact_group_result"
                puts $fh "FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_NS=$exact_fast_tag_max_delay"
                puts $fh "FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT=$exact_delay_result"
                puts $fh "FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE=$exact_delay_mode_status:$exact_delay_mode_detail"
                puts $fh "FAST_TAG_EXACT_SOURCE_CELL_TARGET=[dict get $exact_source_cell_result target_cell]"
                puts $fh "FAST_TAG_EXACT_SOURCE_CELL_REQUESTED=[dict get $exact_source_cell_result requested]"
                puts $fh "FAST_TAG_EXACT_SOURCE_CELL_LIB_CELLS_FOUND=[dict get $exact_source_cell_result target_lib_cells_found]"
                puts $fh "FAST_TAG_EXACT_SOURCE_CELL_COUNT=[dict get $exact_source_cell_result source_cells_found]"
                puts $fh "FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT=[dict get $exact_source_cell_result source_cells_target_count]"
                puts $fh "FAST_TAG_EXACT_SOURCE_CELL_METHOD=[dict get $exact_source_cell_result method]"
                puts $fh "FAST_TAG_EXACT_SOURCE_CELL_RESULT=[dict get $exact_source_cell_result status]"
                puts $fh "FAST_TAG_EXACT_SOURCE_CELL_MODE=[dict get $exact_source_cell_result source_cell_mode]"
                puts $fh "FAST_TAG_EXACT_RESET0_SOURCE_COUNT=[dict get $exact_source_cell_result reset0_source_count]"
                puts $fh "FAST_TAG_EXACT_SET1_SOURCE_COUNT=[dict get $exact_source_cell_result set1_source_count]"
                puts $fh "FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT=[dict get $exact_source_cell_result unsupported_polarity_count]"
                puts $fh "FAST_TAG_EXACT_SELECTED_RESET0_TARGET=[dict get $exact_source_cell_result selected_reset0_target]"
                puts $fh "FAST_TAG_EXACT_SELECTED_SET1_TARGET=[dict get $exact_source_cell_result selected_set1_target]"
                puts $fh "FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT=[dict get $exact_source_cell_result drrqhdx4_target_count]"
                puts $fh "FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT=[dict get $exact_source_cell_result dfrsqhdx4_target_count]"
                puts $fh "FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT=[dict get $exact_source_cell_result dfrsqhdx2_target_count]"
                puts $fh "FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT=[dict get $exact_source_cell_result drrqjihdx4_target_count]"
                puts $fh "FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT=[dict get $exact_source_cell_result dfrsjihdx4_target_count]"
                puts $fh "FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT=[dict get $exact_source_cell_result dfrsjihdx2_target_count]"
                puts $fh "FAST_TAG_EXACT_SOURCE_POLARITY_PRESERVED_COUNT=[dict get $exact_source_cell_result polarity_preserved_count]"
                puts $fh "FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT=[dict get $exact_source_cell_result polarity_failed_count]"
                puts $fh "FAST_TAG_EXACT_SOURCE_FREEZE_RESULT=[dict get $exact_source_cell_result freeze_result]"

                set exact_repair_applied "NO"
                set exact_repair_status "REVIEW_REQUIRED"
                set exact_review_reason "EXACT_COUNTS_MISMATCH"
                if {$exact_counts_ok} {
                    set source_cell_ok true
                    if {$exact_fast_tag_source_cell ne "" && $stage eq "post_map_pre_opt"} {
                        set source_cell_status [dict get $exact_source_cell_result status]
                        set source_cell_ok [expr {$source_cell_status eq "OK" || $source_cell_status eq "PASS_FINAL_VERIFIED" || $source_cell_status eq "PASS_PARTIAL_UNSUPPORTED_SKIPPED"}]
                    }
                    set max_delay_ok true
                    if {$enable_exact_fast_tag_max_delay} {
                        set max_delay_ok [expr {$exact_delay_result eq "OK"}]
                    }
                    if {$exact_fanout_result eq "OK" && $exact_trans_result eq "OK" && $source_cell_ok && $max_delay_ok} {
                        set exact_repair_applied "YES"
                        set exact_repair_status "PASS"
                        set exact_review_reason "NONE"
                    } else {
                        set exact_review_reason "EXACT_REPAIR_COMMAND_FAILURE"
                    }
                }
                set status_fh [open "$design(reports_dir)/fast_tag_exact_repair_status.rpt" a]
                puts $status_fh "STAGE=$stage"
                puts $status_fh "REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE=$repair4_exact_source_drive"
                puts $status_fh "REPAIR5_EXACT_FAST_TAG_CLOSE=$repair5_exact_close"
                puts $status_fh "REPAIR6_LOCALTAG_PRESERVE_CLOSE=$repair6_localtag_preserve_close"
                puts $status_fh "REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE=$repair7_polarity_source_upgrade"
                puts $status_fh "REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE=$repair8_jihd_exact_close"
                puts $status_fh "FAST_TAG_EXACT_SOURCES_EXPECTED=$exact_source_expected"
                puts $status_fh "FAST_TAG_EXACT_SOURCES_FOUND=[llength $exact_source_q_records]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_CLOCK_PINS_FOUND=[llength $exact_source_c_records]"
                puts $status_fh "FAST_TAG_EXACT_ENDPOINTS_EXPECTED=$exact_endpoint_expected"
                puts $status_fh "FAST_TAG_EXACT_ENDPOINTS_FOUND=[llength $exact_endpoint_d_records]"
                puts $status_fh "FAST_TAG_EXACT_PATH_PAIRS_EXPECTED=$exact_pair_expected"
                puts $status_fh "FAST_TAG_EXACT_PATH_PAIRS_FOUND=$exact_pair_found"
                puts $status_fh "FAST_TAG_EXACT_REPAIR_APPLIED=$exact_repair_applied"
                puts $status_fh "FAST_TAG_EXACT_REPAIR_STATUS=$exact_repair_status"
                puts $status_fh "FAST_TAG_EXACT_REVIEW_REASON=$exact_review_reason"
                puts $status_fh "FAST_TAG_EXACT_GROUP_PATH_RESULT=$exact_group_result"
                puts $status_fh "FAST_TAG_EXACT_Q_SET_MAX_FANOUT=$exact_fanout_result"
                puts $status_fh "FAST_TAG_EXACT_Q_SET_MAX_TRANSITION=$exact_trans_result"
                puts $status_fh "FAST_TAG_EXACT_D_SET_MAX_TRANSITION=$exact_endpoint_trans_result"
                puts $status_fh "FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_NS=$exact_fast_tag_max_delay"
                puts $status_fh "FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT=$exact_delay_result"
                puts $status_fh "FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE=$exact_delay_mode_status:$exact_delay_mode_detail"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_CELL_TARGET=[dict get $exact_source_cell_result target_cell]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_CELL_REQUESTED=[dict get $exact_source_cell_result requested]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_CELL_LIB_CELLS_FOUND=[dict get $exact_source_cell_result target_lib_cells_found]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_CELL_COUNT=[dict get $exact_source_cell_result source_cells_found]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT=[dict get $exact_source_cell_result source_cells_target_count]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_CELL_METHOD=[dict get $exact_source_cell_result method]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_CELL_RESULT=[dict get $exact_source_cell_result status]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_CELL_MODE=[dict get $exact_source_cell_result source_cell_mode]"
                puts $status_fh "FAST_TAG_EXACT_RESET0_SOURCE_COUNT=[dict get $exact_source_cell_result reset0_source_count]"
                puts $status_fh "FAST_TAG_EXACT_SET1_SOURCE_COUNT=[dict get $exact_source_cell_result set1_source_count]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT=[dict get $exact_source_cell_result unsupported_polarity_count]"
                puts $status_fh "FAST_TAG_EXACT_SELECTED_RESET0_TARGET=[dict get $exact_source_cell_result selected_reset0_target]"
                puts $status_fh "FAST_TAG_EXACT_SELECTED_SET1_TARGET=[dict get $exact_source_cell_result selected_set1_target]"
                puts $status_fh "FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT=[dict get $exact_source_cell_result drrqhdx4_target_count]"
                puts $status_fh "FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT=[dict get $exact_source_cell_result dfrsqhdx4_target_count]"
                puts $status_fh "FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT=[dict get $exact_source_cell_result dfrsqhdx2_target_count]"
                puts $status_fh "FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT=[dict get $exact_source_cell_result drrqjihdx4_target_count]"
                puts $status_fh "FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT=[dict get $exact_source_cell_result dfrsjihdx4_target_count]"
                puts $status_fh "FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT=[dict get $exact_source_cell_result dfrsjihdx2_target_count]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_POLARITY_PRESERVED_COUNT=[dict get $exact_source_cell_result polarity_preserved_count]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT=[dict get $exact_source_cell_result polarity_failed_count]"
                puts $status_fh "FAST_TAG_EXACT_SOURCE_FREEZE_RESULT=[dict get $exact_source_cell_result freeze_result]"
                puts $status_fh "EXACT_FAST_TAG_SOURCES_EXPECTED=$exact_source_expected"
                puts $status_fh "EXACT_FAST_TAG_SOURCES_FOUND=[llength $exact_source_q_records]"
                puts $status_fh "EXACT_FAST_TAG_ENDPOINTS_EXPECTED=$exact_endpoint_expected"
                puts $status_fh "EXACT_FAST_TAG_ENDPOINTS_FOUND=[llength $exact_endpoint_d_records]"
                puts $status_fh "EXACT_FAST_TAG_DATAPATHS_EXPECTED=$exact_pair_expected"
                puts $status_fh "EXACT_FAST_TAG_DATAPATHS_FOUND=$exact_pair_found"
                puts $status_fh "EXACT_FAST_TAG_REPAIR_APPLIED=$exact_repair_applied"
                puts $status_fh "EXACT_FAST_TAG_REPAIR_STATUS=$exact_repair_status"
                puts $status_fh ""
                close $status_fh
            }
        }
    }

    if {$drv_repair} {
        mptdc_message "FINAL_TYPICAL_GENUS_REPAIR_1: enabling targeted high-fanout control-net DRV repair"
        mptdc_try_unavoid_lib_cells CONTROL_DRV_CANDIDATES {
            *INHDX12*
            *INHDX8*
            *BUHDX12*
            *BUHDX8*
            *BUHDX6*
        } $fh
        set apply_control_cell_bias [expr {
            $strong_control_drv &&
            ($control_bias_stage eq "all" ||
             $control_bias_stage eq $stage ||
             ($control_bias_stage eq "post_map_only" && $stage eq "post_map_pre_opt"))
        }]
        puts $fh "CONTROL_CELL_BIAS_APPLIED=$apply_control_cell_bias"
        if {$apply_control_cell_bias} {
            set weak_control_inverters {
                */INHDX0
                */INHDX1
                */INHDX2
                */INHDX3
                */INHDX4
                */INHDX6
            }
            if {$control_avoid_inhdx8} {
                lappend weak_control_inverters */INHDX8
            }
            mptdc_try_avoid_lib_cells CONTROL_WEAK_INVERTERS $weak_control_inverters $fh
            mptdc_try_unavoid_lib_cells CONTROL_PREFERRED_INVERTERS {
                */INHDX12
            } $fh
        }
        if {$exact_control_roots && $stage eq "post_map_pre_opt"} {
            set exact_control_nets [mptdc_collect_exact_control_root_nets \
                $exact_control_min_fanout \
                $fh \
                $exact_control_require_pd_sinks \
                $exact_control_allow_reset_roots \
                $exact_control_driver_regex \
                $exact_control_net_regex \
                $exact_control_max_roots]
            if {[llength $exact_control_nets] > 0} {
                set exact_fanout_rc [catch {set_max_fanout $control_max_fanout $exact_control_nets} err_exact_fanout]
                puts $fh "EXACT_CONTROL_SET_MAX_FANOUT=[expr {$exact_fanout_rc == 0 ? {OK} : $err_exact_fanout}]"
                puts $fh "EXACT_CONTROL_SET_MAX_TRANSITION=SKIPPED_NET_OBJECTS_UNSUPPORTED_BY_THIS_GENUS_MODE"
            }
        } elseif {$exact_control_roots} {
            puts $fh "EXACT_CONTROL_ROOT_STAGE=SKIPPED_UNTIL_POST_MAP_PRE_OPT"
        }
        if {$apply_broad_control_nets} {
            set control_nets [list]
            foreach pattern {
                *meas_pd_clear*
                *detect_en*
                *clear_window*
                *rst_core_n*
            } {
                catch {set matches [get_nets -quiet -hierarchical $pattern]}
                foreach net [mptdc_collection_to_list $matches] {
                    lappend control_nets $net
                }
            }
            set control_nets [mptdc_unique_list $control_nets]
            puts $fh "CONTROL_REPAIR_NETS=[llength $control_nets]"
            if {[llength $control_nets] > 0} {
                set ctrl_fanout_rc [catch {set_max_fanout $control_max_fanout $control_nets} err_ctrl_fanout]
                puts $fh "CONTROL_SET_MAX_FANOUT=[expr {$ctrl_fanout_rc == 0 ? {OK} : $err_ctrl_fanout}]"
                puts $fh "CONTROL_SET_MAX_TRANSITION=SKIPPED_NET_OBJECTS_UNSUPPORTED_BY_THIS_GENUS_MODE"
            }
        } else {
            puts $fh "CONTROL_REPAIR_NETS=SKIPPED_BROAD_CONTROL_NETS_DISABLED"
            puts $fh "CONTROL_SET_MAX_FANOUT=SKIPPED_BROAD_CONTROL_NETS_DISABLED"
            puts $fh "CONTROL_SET_MAX_TRANSITION=SKIPPED_BROAD_CONTROL_NETS_DISABLED"
        }
        if {$design_drv_repair} {
            catch {set_max_fanout $control_max_fanout [current_design]} err_design_fanout
            catch {set_max_transition $control_max_transition [current_design]} err_design_trans
            puts $fh "DESIGN_SET_MAX_FANOUT_FOR_DRV_REPAIR=$err_design_fanout"
            puts $fh "DESIGN_SET_MAX_TRANSITION_FOR_DRV_REPAIR=$err_design_trans"
        } else {
            puts $fh "DESIGN_SET_MAX_FANOUT_FOR_DRV_REPAIR=SKIPPED_TARGETED_NETS_ONLY"
            puts $fh "DESIGN_SET_MAX_TRANSITION_FOR_DRV_REPAIR=SKIPPED_TARGETED_NETS_ONLY"
        }
    }
    puts $fh ""
    close $fh
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

    # Some Genus builds do not match lib-cell glob patterns directly with
    # get_db.  Fall back to scanning all lib-cell names so the audit reflects
    # what the loaded Liberty actually contains.
    set all_cells [list]
    catch {set all_cells [get_db lib_cells]}
    foreach cell $all_cells {
        set name ""
        catch {set name [get_db $cell .base_name]}
        if {$name eq ""} {
            catch {set name [get_db $cell .name]}
        }
        foreach pattern {
            LGCNHDX* LGCPHDX*
            LSGCNHDX* LSGCPHDX*
            LSOGCNHDX* LSOGCPHDX*
        } {
            if {[string match $pattern $name]} {
                lappend cells $cell
                break
            }
        }
    }
    return [mptdc_unique_list $cells]
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
        mptdc_write_recorded_report_failure $rpt_file $title \
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

    mptdc_write_recorded_report_failure $rpt_file $title \
        "Matched [llength [mptdc_unique_list $cell_names]] cell(s), but no D/d endpoint pins matched the report patterns. report_timing was not run with cell names because this Genus flow rejects non-endpoint objects for -to. Patterns: $patterns"
}

proc mptdc_collect_cell_objects {patterns} {
    set cells [list]
    array set seen {}
    foreach pattern $patterns {
        set matches [list]
        catch {set matches [get_cells -quiet -hierarchical $pattern]}
        foreach cell [mptdc_collection_to_list $matches] {
            set name [mptdc_object_name $cell]
            if {$name ne "" && ![info exists seen($name)]} {
                set seen($name) 1
                lappend cells $cell
            }
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
    foreach net [mptdc_collection_to_list $nets] {
        set name "<unknown>"
        set obj_name [mptdc_object_name $net]
        if {$obj_name ne ""} {
            set name $obj_name
        }

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
            mptdc_try_keep_hierarchy_cells $cells
        }
    }

    foreach pattern {
        *u_phase_buf_slow*
        *u_phase_buf_fast*
        *u_phase_buf*
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
        mptdc_try_set_db $modules .ungroup_ok false
    }

    foreach module_pattern {
        *mptdc_phase_buffer_bank*
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

    if {[mptdc_o13_abs5_enabled]} {
        # The MMMC SDC overlay is read before mapped q1_reg/D pins exist.  Re-apply
        # the exact row-scoped Vernier exception as soon as those pins are visible
        # so later synthesis stages and final reports do not chase the measurement
        # crossing as normal setup timing.
        mptdc_o13_abs5_apply_exact_q1_exception
    }

    # Worst paths in the active view (setup-oriented in the current MMMC setup).
    if {[catch { report_timing -max_paths 20 > "$dir/timing_setup.rpt" } err]} {
        mptdc_write_recorded_report_failure "$dir/timing_setup.rpt" "Setup timing report" $err
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
        mptdc_write_recorded_report_failure "$dir/timing_summary.rpt" "Timing summary report" $err
    }

    # Violations only: max_slack filters to paths with slack < 0.
    if {[catch { report_timing -max_paths 200 -max_slack 0.0 > "$dir/timing_violations.rpt" } err]} {
        mptdc_write_recorded_report_failure "$dir/timing_violations.rpt" "Timing violations report" $err
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

    if {$stage ne "post_synthesis"} {
        foreach file {
            timing_pd_capture_hotspots.rpt
            timing_osc_counter_hotspots.rpt
            timing_meas_ctrl_hotspots.rpt
            timing_context_bank_hotspots.rpt
            timing_hit_capture_bridge_hotspots.rpt
            timing_drain_ctrl_hotspots.rpt
            timing_fifo_hotspots.rpt
            timing_fast_count_to_nfast_hit.rpt
            timing_cdc_async_review.rpt
            timing_o13_phase_buffer_paths.rpt
            pd_vernier_endpoint_discovery.rpt
            pd_vernier_source_discovery.rpt
            pd_vernier_exception_check.rpt
            timing_pd_intentional_vernier.rpt
        } {
            mptdc_write_report_failure "$dir/$file" "Deferred detailed report" \
                "Detailed focused timing reports are generated at post_synthesis only. Stage $stage keeps a lightweight timing snapshot so reporting cannot block optimization."
        }
        mptdc_write_fast_feasibility_audit "$dir/fast_domain_feasibility_audit.rpt"
        return
    }

    if {![mptdc_o13_abs3_enabled]} {
        mptdc_run_nonfatal_report_step "PD capture hotspot timing" \
            [list mptdc_report_hotspot_timing "$dir/timing_pd_capture_hotspots.rpt" \
                "phase-detector capture timing report" \
                [list \
                    *gen_pd_row*gen_pd_col*u_pd*q1_reg* \
                    *gen_pd_row*gen_pd_col*u_pd*q2_reg* \
                    *gen_pd_row*gen_pd_col*u_pd*hit_latched_reg* \
                    *gen_pd_row*gen_pd_col*u_pd*nfast_hit_latched_reg*]] $dir
    }

    mptdc_run_nonfatal_report_step "oscillator support-counter hotspot timing" \
        [list mptdc_report_hotspot_timing "$dir/timing_osc_counter_hotspots.rpt" \
            "oscillator support-counter timing report" \
            [list *u_fast_cnt* *u_slow_cnt* *u_slow_epoch* *u_stop_epoch_capture* \
                  *gen_fast_tag_col* *u_fast_tag* *nfast_src_count* \
                  *start_wdt_cnt* *start_timeout_latched*]] $dir

    mptdc_run_nonfatal_report_step "fast-count capture timing" \
        [list mptdc_report_fast_count_capture $dir] $dir

    mptdc_run_nonfatal_report_step "measurement-controller hotspot timing" \
        [list mptdc_report_hotspot_timing "$dir/timing_meas_ctrl_hotspots.rpt" \
            "measurement-controller hotspot timing report" \
            [list *u_meas_ctrl* *u_meas_ctrl*/*]] $dir

    mptdc_run_nonfatal_report_step "context-bank hotspot timing" \
        [list mptdc_report_hotspot_timing "$dir/timing_context_bank_hotspots.rpt" \
            "context-bank hotspot timing report" \
            [list *u_ctx_bank* *u_ctx_bank*/*]] $dir

    mptdc_run_nonfatal_report_step "hit-capture bridge hotspot timing" \
        [list mptdc_report_hotspot_timing "$dir/timing_hit_capture_bridge_hotspots.rpt" \
            "hit-capture bridge hotspot timing report" \
            [list *u_hit_capture_bridge* *u_hit_capture_bridge*/*]] $dir

    mptdc_run_nonfatal_report_step "drain-controller hotspot timing" \
        [list mptdc_report_hotspot_timing "$dir/timing_drain_ctrl_hotspots.rpt" \
            "drain controller hotspot timing report" \
            [list *u_drain_ctrl* *u_drain_ctrl*/*]] $dir

    mptdc_run_nonfatal_report_step "FIFO/readout hotspot timing" \
        [list mptdc_report_hotspot_timing "$dir/timing_fifo_hotspots.rpt" \
            "FIFO/readout hotspot timing report" \
            [list *u_fifo* *u_sync_fifo* *u_narrow_tx* *u_tconv*]] $dir

    if {[mptdc_o13_abs3_enabled] && $stage eq "post_synthesis"} {
        if {[mptdc_o13_abs5_enabled]} {
            mptdc_message "Generating O13 abs5 exact PD q1 Vernier exception timing reports"
        } elseif {[mptdc_o13_abs4_enabled]} {
            mptdc_message "Generating O13 abs4 PD Vernier classification timing reports"
        } else {
            mptdc_message "Generating O13 abs3 clock/CDC repair timing reports"
        }
        mptdc_run_nonfatal_report_step "O13 stable clock and PD timing reports" \
            [list mptdc_report_o13_abs3_timing $dir] $dir
    }

    mptdc_run_nonfatal_report_step "fast-domain feasibility audit" \
        [list mptdc_write_fast_feasibility_audit "$dir/fast_domain_feasibility_audit.rpt"] $dir
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
    set latch_list [mptdc_collection_to_list $latches]

    puts $fh "MPTDC latch report"
    puts $fh "=================="
    puts $fh "Count: [llength $latch_list]"
    puts $fh ""
    puts $fh [format "%-80s %s" "Instance" "Base cell"]
    puts $fh [string repeat "-" 120]

    foreach inst $latch_list {
        set inst_name [get_db $inst .name]
        set base_name [get_db $inst .base_cell.name]
        puts $fh [format "%-80s %s" $inst_name $base_name]
    }

    close $fh
    return [llength $latch_list]
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
    mptdc_run_report "report_hierarchy" \
        "$dir/report_hierarchy.rpt" "report_hierarchy"
    mptdc_write_report_substitute \
        "$dir/report_gates_hier.rpt" \
        "Hierarchical Gate Report Substitute" \
        [list "report_gates -depth 20" "report_gates -hier" "report_gates -hierarchy"] \
        [list "report_gates.rpt" "report_hierarchy.rpt" "report_area_hier.rpt"] \
        "Genus 22.13 on the lab server rejects the hierarchical report_gates options seen in the 124954 log. The plain gate, hierarchy, and hierarchical area reports are kept as the supported evidence set."
    mptdc_run_report "report_design_rules" \
        "$dir/report_design_rules.rpt" "report_design_rules"
    mptdc_run_report "report_design_rules" \
        "$dir/report_design_rules_verbose.rpt" "design-rule report duplicate for parser compatibility"
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
    if {[llength [info commands report_constraints]] > 0} {
        mptdc_run_report "report_constraints" \
            "$dir/report_constraints.rpt" "report_constraints"
    } else {
        mptdc_write_report_substitute \
            "$dir/report_constraints.rpt" \
            "Constraint Report Substitute" \
            [list "report_constraints"] \
            [list \
                "mptdc_axis_core.postsyn.sdc" \
                "final_sdc_overlay_used.sdc" \
                "check_timing_intent_post_synth.rpt" \
                "sdc_command_failures.md" \
            ] \
            "Native constraint reporting is unavailable in this Genus build. The exported post-synthesis SDC and timing-intent report are the authoritative constraint evidence for this run."
    }
    mptdc_run_report_candidates [list \
        "report_clock_groups" \
        "report_clock_groups -verbose" \
        "report_clocks" \
    ] "$dir/report_clock_groups.rpt" "clock-group report"
    if {[llength [info commands report_exceptions]] > 0} {
        mptdc_run_report_candidates [list \
            "report_exceptions" \
            "report_exceptions -verbose" \
        ] "$dir/report_exceptions.rpt" "timing-exception report"
    } else {
        mptdc_write_report_substitute \
            "$dir/report_exceptions.rpt" \
            "Timing Exception Report Substitute" \
            [list "report_exceptions" "report_constraints -exceptions"] \
            [list \
                "mptdc_axis_core.postsyn.sdc" \
                "pd_vernier_exception_check.rpt" \
                "timing_pd_intentional_vernier.rpt" \
                "check_timing_intent_post_synth.rpt" \
            ] \
            "Native exception reporting is unavailable in this Genus build. For O13 abs5, pd_vernier_exception_check.rpt is the exact count-checked proof for the intentional slow-phase-to-q1 exception."
    }
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
    mptdc_write_report_helper_status "$dir/report_helpers_status.rpt"
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
        INPUT_DELAY_MACRO
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
        STANDARD_CELL_FAMILY STANDARD_CELL_LIBRARY STANDARD_CELL_SITE
        STANDARD_CELL_VDD STANDARD_CELL_GND row_height
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
    puts "   [ ] timing_violations.rpt has no real setup violations"
    puts "   [ ] Latch audit: exactly $design(EXPECTED_LATCH_COUNT) latches"
    puts "   [ ] report_area_hier.rpt identifies the first area targets"
    puts "   [ ] run_manifest.rpt captures the exact PDK/MMMC/settings baseline"
    puts "   [ ] PD capture and oscillator-counter timing reports are reviewed separately"
    puts "   [ ] No critical DRV violations"
    puts "   [ ] Power report is tagged as vectorless or activity-backed"
    puts "================================================================"
}
