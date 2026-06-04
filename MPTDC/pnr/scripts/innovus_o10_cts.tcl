# =============================================================================
# O10 clk_sys CTS stage
# =============================================================================

proc mptdc_o10_cts {} {
    global o10
    mptdc_o10_msg "Running CTS for clk_sys only"
    set policy_fh [open "$o10(reports_dir)/cts_policy.rpt" w]
    puts $policy_fh "O10 CTS policy"
    puts $policy_fh "=============="
    puts $policy_fh "Run CTS for clk_sys only."
    puts $policy_fh "RO_tune4/S[0:7] clocks are source-clock phase nets and must not be CTS trees."
    puts $policy_fh "The script applies best-effort ignore/dont-touch guards to RO clocks and reports the result."
    close $policy_fh

    set ro_clocks [list clk_osc_slow clk_osc_fast]
    for {set i 1} {$i < 8} {incr i} {
        lappend ro_clocks "clk_osc_slow_tap$i"
        lappend ro_clocks "clk_osc_fast_tap$i"
    }
    set guard_fh [open "$o10(reports_dir)/cts_ro_clock_guard.rpt" w]
    puts $guard_fh "O10 RO clock CTS guard"
    puts $guard_fh "======================"
    foreach clk $ro_clocks {
        set objs [list]
        catch {set objs [get_clocks $clk]}
        puts $guard_fh "Clock $clk objects: [llength $objs]"
        foreach cmd [list \
            [list set_dont_touch_network $objs] \
            [list set_ideal_network $objs] \
        ] {
            if {[llength $objs] == 0} {
                puts $guard_fh "  skipped $cmd: no clock object"
                continue
            }
            if {![catch {{*}$cmd} err]} {
                puts $guard_fh "  applied: $cmd"
            } else {
                puts $guard_fh "  skipped: $cmd"
                puts $guard_fh "    $err"
            }
        }
    }
    close $guard_fh

    if {[catch {set_ccopt_property target_skew 0.15} err]} {
        mptdc_o10_msg "set_ccopt_property skipped: $err"
    }
    set spec_created 0
    foreach cmd [list \
        [list create_ccopt_clock_tree_spec -file "$o10(work_dir)/clk_sys_cts.spec" -clock_tree clk_sys] \
        [list create_ccopt_clock_tree_spec -file "$o10(work_dir)/clk_sys_cts.spec" -clock_trees [list clk_sys]] \
        [list create_ccopt_clock_tree_spec -file "$o10(work_dir)/clk_sys_cts.spec"] \
    ] {
        if {![catch {{*}$cmd} err]} {
            set spec_created 1
            mptdc_o10_msg "CTS spec command accepted: $cmd"
            break
        }
        mptdc_o10_msg "CTS spec command skipped: $cmd : $err"
    }
    if {!$spec_created} {
        mptdc_o10_msg "No create_ccopt_clock_tree_spec variant was accepted"
    }
    if {[catch {ccopt_design} err]} {
        mptdc_o10_msg "ccopt_design failed or unavailable, trying legacy clockDesign: $err"
        if {[catch {clockDesign} err2]} {
            mptdc_o10_msg "clockDesign also failed: $err2"
        }
    }
    catch {optDesign -postCTS}
    mptdc_o10_report_stage post_cts
    mptdc_o10_capture_candidates "$o10(reports_dir)/hold_post_cts.rpt" \
        "O10 hold post CTS" [list {report_timing -check_type hold -max_paths 100} {timeDesign -postCTS -hold}]
    catch {defOut "$o10(def_dir)/03_cts.def"}
    catch {saveDesign "$o10(checkpoints_dir)/03_cts.enc"}
    mptdc_o10_restore_script 03_cts
    mptdc_o10_screenshot "04_clk_sys_cts.png" "clk_sys CTS"
    mptdc_o10_write_manifest cts
}
