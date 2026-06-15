# =============================================================================
# O10.2 clk_sys-only CTS stage
# =============================================================================

proc mptdc_o10_clock_count {name} {
    set objs [list]
    catch {set objs [get_clocks $name]}
    return [llength $objs]
}

proc mptdc_o10_select_interactive_constraint_mode {} {
    if {[llength [info commands set_interactive_constraint_modes]] == 0} {
        return [list NOT_AVAILABLE "set_interactive_constraint_modes command not present"]
    }
    if {![catch {set_interactive_constraint_modes functional_mode} err]} {
        return [list OK functional_mode]
    }
    if {[llength [info commands all_constraint_modes]] > 0} {
        set modes [list]
        if {![catch {set modes [all_constraint_modes]}]} {
            foreach mode $modes {
                if {$mode eq "" || $mode eq "0x0"} {
                    continue
                }
                if {![catch {set_interactive_constraint_modes $mode} err]} {
                    return [list OK $mode]
                }
            }
        }
    }
    return [list FAILED $err]
}

proc mptdc_o10_write_interactive_constraint_mode_status {mode_result} {
    global o10
    set fh [open "$o10(reports_dir)/interactive_constraint_mode.rpt" w]
    puts $fh "# O10.2 Interactive Constraint Mode"
    puts $fh ""
    puts $fh "STATUS=[lindex $mode_result 0]"
    puts $fh "DETAIL=[lindex $mode_result 1]"
    puts $fh ""
    puts $fh "This mode is selected before report_constraint commands so report generation does not add nonphysical TCLCMD-1048 noise."
    close $fh
}

proc mptdc_o10_cts_buffer_cells {} {
    set family [string toupper [mptdc_o10_env MPTDC_STDCELL_FAMILY HD]]
    if {$family eq "JIHD"} {
        return [list BUJIHDX1 BUJIHDX2 BUJIHDX3 BUJIHDX4 BUJIHDX6 BUJIHDX8 BUJIHDX12]
    }
    return [list BUHDX1 BUHDX2 BUHDX4 BUHDX6 BUHDX8 BUHDX12]
}

proc mptdc_o10_cts_inverter_cells {} {
    set family [string toupper [mptdc_o10_env MPTDC_STDCELL_FAMILY HD]]
    if {$family eq "JIHD"} {
        return [list INJIHDX1 INJIHDX2 INJIHDX3 INJIHDX4 INJIHDX6 INJIHDX8 INJIHDX12]
    }
    return [list INHDX1 INHDX2 INHDX4 INHDX8 INHDX12]
}

proc mptdc_o10_cts {} {
    global o10 pnr
    mptdc_o10_msg "Running O10.2 CTS policy: clk_sys only, never RO phase clocks"
    if {[llength [info commands mptdc_pnr_apply_physical_effort]] > 0} {
        mptdc_pnr_apply_physical_effort pre_cts
    }

    set ro_clocks [list clk_osc_slow clk_osc_fast]
    for {set i 1} {$i < 8} {incr i} {
        lappend ro_clocks "clk_osc_slow_tap$i"
        lappend ro_clocks "clk_osc_fast_tap$i"
    }

    set clk_sys_objs [list]
    catch {set clk_sys_objs [get_clocks clk_sys]}
    set ro_found 0

    set policy_fh [open "$o10(reports_dir)/cts_policy.rpt" w]
    puts $policy_fh "O10.2 CTS policy"
    puts $policy_fh "================="
    puts $policy_fh "Run CTS for clk_sys only."
    puts $policy_fh "Do not run CTS on RO_tune4/S[0:7] phase clocks."
    puts $policy_fh "clk_sys clock objects: [llength $clk_sys_objs]"

    set guard_fh [open "$o10(reports_dir)/cts_ro_clock_guard.rpt" w]
    puts $guard_fh "O10.2 RO clock CTS guard"
    puts $guard_fh "========================"
    foreach clk $ro_clocks {
        set objs [list]
        catch {set objs [get_clocks $clk]}
        incr ro_found [llength $objs]
        puts $guard_fh "Clock $clk objects: [llength $objs]"
        if {[llength $objs] == 0} {
            puts $guard_fh "  skipped: no clock object"
            continue
        }
        puts $guard_fh "  audited: RO clock is present and excluded from CTS planning"
        puts $guard_fh "  network guard commands not applied: generated clock objects are not top ports"
    }
    close $guard_fh
    puts $policy_fh "RO clock objects found: $ro_found"
    close $policy_fh

    set o10(ro_cts_attempted) "no"
    set o10(cts_status) "CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY"
    set status_fh [open "$o10(reports_dir)/cts_status.rpt" w]
    puts $status_fh "O10.2 CTS status"
    puts $status_fh "================="
    puts $status_fh "clk_sys_count=[llength $clk_sys_objs]"
    puts $status_fh "ro_clock_count=$ro_found"
    puts $status_fh "ro_cts_attempted=no"

    if {$pnr(run_clk_sys_cts) != 1} {
        puts $status_fh "CTS_STATUS=CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY"
        puts $status_fh "reason=MPTDC_O10_RUN_CLK_SYS_CTS is not set to 1; skipping CTS until a version-specific clk_sys-only spec is confirmed"
        set fh [open "$o10(reports_dir)/CTS_SKIPPED.txt" w]
        puts $fh "CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY"
        puts $fh "Default O10.2 route-feasibility run skips CTS to avoid accidentally buffering RO phase clocks."
        puts $fh "Set MPTDC_O10_RUN_CLK_SYS_CTS=1 only after confirming a clk_sys-only CCOpt spec for this Innovus version."
        close $fh
        close $status_fh
    } elseif {[llength $clk_sys_objs] == 0} {
        puts $status_fh "CTS_STATUS=CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY"
        puts $status_fh "reason=clk_sys clock was not found"
        close $status_fh
    } else {
        set mode_result [mptdc_o10_select_interactive_constraint_mode]
        puts $status_fh "interactive_constraint_mode=[lindex $mode_result 0]:[lindex $mode_result 1]"
        set cts_buffers [mptdc_o10_cts_buffer_cells]
        set cts_inverters [mptdc_o10_cts_inverter_cells]
        puts $status_fh "cts_buffer_cells=$cts_buffers"
        puts $status_fh "cts_inverter_cells=$cts_inverters"
        catch {set_ccopt_property buffer_cells $cts_buffers}
        catch {set_ccopt_property inverter_cells $cts_inverters}
        catch {set_ccopt_property target_skew 0.15}
        set spec_created 0
        set spec_path "$o10(work_dir)/clk_sys_cts.spec"
        set cmd [list create_ccopt_clock_tree_spec -file $spec_path]
        if {![catch {{*}$cmd} err]} {
            set spec_created 1
            puts $status_fh "accepted_spec_command=$cmd"
        } else {
            puts $status_fh "rejected_spec_command=$cmd"
            puts $status_fh "  $err"
        }
        set spec_safe 0
        if {$spec_created && [file exists $spec_path]} {
            set sfh [open $spec_path r]
            set spec_text [read $sfh]
            close $sfh
            if {[regexp {clk_sys} $spec_text] && ![regexp {clk_osc_|RO_tune4|u_ro_tune4} $spec_text]} {
                set spec_safe 1
                puts $status_fh "spec_safety=clk_sys_only"
            } else {
                puts $status_fh "spec_safety=ambiguous_or_ro_clock_reference"
            }
        }
        set allow_generic_ccopt [mptdc_o10_env MPTDC_O10_ALLOW_GENERIC_CCOPT 0]
        puts $status_fh "allow_generic_ccopt=$allow_generic_ccopt"
        if {$spec_created && ($spec_safe || $allow_generic_ccopt == 1)} {
            if {!$spec_safe} {
                puts $status_fh "generic_ccopt_override=YES_REVIEW_REQUIRED"
            }
            if {![catch {ccopt_design} err]} {
                set o10(cts_status) "CLK_SYS_ONLY_CTS_COMPLETE"
                puts $status_fh "CTS_STATUS=CLK_SYS_ONLY_CTS_COMPLETE"
            } else {
                puts $status_fh "CTS_STATUS=CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY"
                puts $status_fh "ccopt_design_failed=$err"
                set fh [open "$o10(reports_dir)/CTS_SKIPPED.txt" w]
                puts $fh "CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY"
                puts $fh "clk_sys-only CCOpt failed; generic CCOpt was not run to avoid RO clock trees."
                puts $fh "$err"
                close $fh
            }
        } else {
            puts $status_fh "CTS_STATUS=CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY"
            if {$spec_created} {
                puts $status_fh "reason=clk_sys-only spec could not be proven safe; generic CCOpt was not run"
            } else {
                puts $status_fh "reason=no clk_sys-only create_ccopt_clock_tree_spec command was accepted"
            }
            set fh [open "$o10(reports_dir)/CTS_SKIPPED.txt" w]
            puts $fh "CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY"
            puts $fh "No verified clk_sys-only CTS spec was available; generic CCOpt was not run."
            close $fh
        }
        close $status_fh
    }

    if {$o10(cts_status) eq "CLK_SYS_ONLY_CTS_COMPLETE"} {
        if {[llength [info commands mptdc_pnr_apply_physical_effort]] > 0} {
            mptdc_pnr_apply_physical_effort post_cts
        }
        catch {optDesign -postCTS}
    }
    mptdc_o10_report_stage post_cts
    mptdc_o10_capture_candidates "$o10(reports_dir)/hold_post_cts.rpt" \
        "O10.2 hold post CTS" [list {timeDesign -postCTS -hold} {report_timing -check_type hold -max_paths 100}]
    catch {defOut "$o10(def_dir)/03_cts.def"}
    catch {saveDesign "$o10(checkpoints_dir)/03_cts.enc"}
    mptdc_o10_restore_script 03_cts
    mptdc_o10_screenshot "04_clk_sys_cts.png" "clk_sys CTS or skipped CTS checkpoint"
    mptdc_o10_write_manifest cts
}
