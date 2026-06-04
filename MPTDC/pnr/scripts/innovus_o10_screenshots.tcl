# =============================================================================
# O10 screenshot helpers
# =============================================================================

proc mptdc_o10_try_screenshot_cmd {path} {
    set cmds [list \
        [list saveImage $path] \
        [list save_image $path] \
        [list dumpToGIF $path] \
        [list write_image $path] \
    ]
    foreach cmd $cmds {
        if {![catch {{*}$cmd} err]} {
            return "ok: $cmd"
        }
    }
    return ""
}

proc mptdc_o10_screenshot {name title} {
    global o10
    set path "$o10(screenshots_dir)/$name"
    set status [mptdc_o10_try_screenshot_cmd $path]
    if {$status ne ""} {
        set fh [open "$o10(screenshots_dir)/SCREENSHOT_STATUS.txt" a]
        puts $fh "$name: $status"
        close $fh
        return
    }

    set fail "$o10(screenshots_dir)/SCREENSHOT_EXPORT_FAILED.txt"
    set fh [open $fail a]
    puts $fh "$name: automatic export failed for view '$title'"
    puts $fh "Manual fallback:"
    puts $fh "  cd $o10(repo_root)"
    puts $fh "  innovus -init $o10(checkpoints_dir)/restore_latest.tcl"
    puts $fh "  zoomBox or zoom_full in GUI, enable desired layers, then export PNG manually."
    puts $fh ""
    close $fh
}

proc mptdc_o10_restore_script {checkpoint_name} {
    global o10 design
    set restore "$o10(checkpoints_dir)/restore_latest.tcl"
    set fh [open $restore w]
    puts $fh "restoreDesign $o10(checkpoints_dir)/${checkpoint_name}.enc.dat $design(TOPLEVEL)"
    puts $fh "puts {Restored O10 checkpoint $checkpoint_name}"
    close $fh
}
