# =============================================================================
# O10.2 clk_sys-only CTS stage
# =============================================================================

proc mptdc_o10_clock_count {name} {
    set objs [list]
    catch {set objs [get_clocks $name]}
    return [llength $objs]
}

proc mptdc_o10_cts {} {
    global o10
    mptdc_o10_msg "Running O10.2 CTS policy: clk_sys only, never RO phase clocks"

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
        foreach cmd [list \
            [list set_dont_touch_network $objs] \
            [list set_ideal_network $objs] \
        ] {
            if {![catch {{*}$cmd} err]} {
                puts $guard_fh "  applied: $cmd"
            } else {
                puts $guard_fh "  skipped: $cmd"
                puts $guard_fh "    $err"
            }
        }
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

    if {[llength $clk_sys_objs] == 0} {
        puts $status_fh "CTS_STATUS=CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY"
        puts $status_fh "reason=clk_sys clock was not found"
        close $status_fh
    } else {
        catch {set_ccopt_property buffer_cells {BUHDX1 BUHDX2 BUHDX4 BUHDX6}}
        catch {set_ccopt_property inverter_cells {INHDX1 INHDX2 INHDX4}}
        catch {set_ccopt_property target_skew 0.15}
        set spec_created 0
        set spec_path "$o10(work_dir)/clk_sys_cts.spec"
        foreach cmd [list \
            [list create_ccopt_clock_tree_spec -file $spec_path -clock_tree clk_sys] \
            [list create_ccopt_clock_tree_spec -file $spec_path -clock_trees [list clk_sys]] \
            [list create_ccopt_clock_tree_spec -file $spec_path -clocks [list clk_sys]] \
        ] {
            if {![catch {{*}$cmd} err]} {
                set spec_created 1
                puts $status_fh "accepted_spec_command=$cmd"
                break
            }
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
        if {$spec_created && $spec_safe} {
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
        catch {optDesign -postCTS}
    }
    mptdc_o10_report_stage post_cts
    mptdc_o10_capture_candidates "$o10(reports_dir)/hold_post_cts.rpt" \
        "O10.2 hold post CTS" [list {report_timing -check_type hold -max_paths 100} {timeDesign -postCTS -hold}]
    catch {defOut "$o10(def_dir)/03_cts.def"}
    catch {saveDesign "$o10(checkpoints_dir)/03_cts.enc"}
    mptdc_o10_restore_script 03_cts
    mptdc_o10_screenshot "04_clk_sys_cts.png" "clk_sys CTS or skipped CTS checkpoint"
    mptdc_o10_write_manifest cts
}
