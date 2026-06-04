# =============================================================================
# O10.2 screenshot helpers
# =============================================================================

proc mptdc_o10_screenshot_file_valid {path} {
    return [expr {[file exists $path] && [file size $path] > 0}]
}

proc mptdc_o10_write_gui_instructions {} {
    global o10
    set path "$o10(manager_dir)/GUI_SCREENSHOT_INSTRUCTIONS.md"
    set fh [open $path w]
    puts $fh "# O10.2 Manual GUI Screenshot Instructions"
    puts $fh ""
    puts $fh "Automatic screenshot export may be unavailable in Innovus `-nowin` mode."
    puts $fh ""
    puts $fh "```bash"
    puts $fh "cd $o10(repo_root)"
    puts $fh "git checkout SPADMIC_localtag"
    puts $fh "git pull --ff-only"
    puts $fh "innovus -gui -init results/innovus/$o10(run_id)/checkpoints/restore_latest.tcl"
    puts $fh "```"
    puts $fh ""
    puts $fh "After restore, use the GUI to zoom full, enable desired layers, highlight RO/PD/phase nets if needed, and export manager PNGs manually."
    close $fh
}

proc mptdc_o10_try_screenshot_cmd {path} {
    set cmds [list \
        [list saveImage $path] \
        [list save_image $path] \
        [list dumpToGIF $path] \
        [list write_image $path] \
    ]
    foreach cmd $cmds {
        catch {file delete -force $path}
        set err ""
        if {![catch {{*}$cmd} err] && [mptdc_o10_screenshot_file_valid $path]} {
            return "ok: $cmd"
        }
    }
    return ""
}

proc mptdc_o10_screenshot {name title} {
    global o10
    set path "$o10(screenshots_dir)/$name"
    set status ""
    if {$o10(screenshot_mode) eq "gui"} {
        set status [mptdc_o10_try_screenshot_cmd $path]
    } else {
        set status [mptdc_o10_try_screenshot_cmd $path]
    }
    if {$status ne "" && [mptdc_o10_screenshot_file_valid $path]} {
        set fh [open "$o10(screenshots_dir)/SCREENSHOT_STATUS.txt" a]
        puts $fh "$name: $status"
        close $fh
        return
    }

    set fail "$o10(screenshots_dir)/SCREENSHOT_EXPORT_FAILED.txt"
    set fh [open $fail a]
    puts $fh "$name: automatic export failed for view '$title'"
    puts $fh "Screenshot mode: $o10(screenshot_mode)"
    puts $fh "Manual fallback:"
    puts $fh "  cd $o10(repo_root)"
    puts $fh "  git checkout SPADMIC_localtag"
    puts $fh "  git pull --ff-only"
    puts $fh "  innovus -gui -init results/innovus/$o10(run_id)/checkpoints/restore_latest.tcl"
    puts $fh ""
    close $fh
    mptdc_o10_write_gui_instructions
}

proc mptdc_o10_restore_script {checkpoint_name} {
    global o10 design
    set checkpoint "$o10(checkpoints_dir)/${checkpoint_name}.enc.dat"
    if {![file exists $checkpoint]} {
        set checkpoint "$o10(checkpoints_dir)/${checkpoint_name}.enc"
    }
    set latest "$o10(checkpoints_dir)/restore_latest.tcl"
    set specific "$o10(checkpoints_dir)/restore_${checkpoint_name}.tcl"
    foreach restore [list $latest $specific] {
        set fh [open $restore w]
        puts $fh "restoreDesign $checkpoint $design(TOPLEVEL)"
        puts $fh "puts {Restored O10.2 checkpoint $checkpoint_name}"
        close $fh
    }
    if {$checkpoint_name eq "02_place"} {
        file copy -force $specific "$o10(checkpoints_dir)/restore_place.tcl"
    }
    if {$checkpoint_name eq "04_route"} {
        file copy -force $specific "$o10(checkpoints_dir)/restore_route.tcl"
    }
}
