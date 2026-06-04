# =============================================================================
# O10.2 GUI screenshot export entrypoint
# =============================================================================

proc mptdc_o10_2_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ../../..]]
set run_id [mptdc_o10_2_env MPTDC_O10_RUN_ID 20260604_o10_2_pnr_repair]
set result_dir [mptdc_o10_2_env MPTDC_O10_RESULT_DIR "$repo_root/results/innovus/$run_id"]
set restore_script "$result_dir/checkpoints/restore_latest.tcl"
set screenshots_dir "$result_dir/screenshots"
file mkdir $screenshots_dir

if {![file exists $restore_script]} {
    puts "MPTDC_O10_2_GUI_ERROR: missing restore script: $restore_script"
    exit 1
}

source $restore_script

proc mptdc_o10_2_gui_export {name} {
    global screenshots_dir
    set path "$screenshots_dir/$name"
    foreach cmd [list \
        [list saveImage $path] \
        [list save_image $path] \
        [list dumpToGIF $path] \
        [list write_image $path] \
    ] {
        catch {file delete -force $path}
        if {![catch {{*}$cmd} err] && [file exists $path] && [file size $path] > 0} {
            puts "MPTDC_O10_2_GUI_INFO: wrote $path using $cmd"
            return 1
        }
    }
    puts "MPTDC_O10_2_GUI_WARN: could not export $name"
    return 0
}

catch {zoomBox}
catch {fit}
catch {redraw}

set ok 0
foreach img {
    01_floorplan_overview.png
    02_macros_pd_matrix.png
    03_placed_design.png
    04_clk_sys_cts.png
    05_routed_design.png
    06_congestion.png
    07_phase_nets_highlight.png
    08_final_manager_view.png
} {
    incr ok [mptdc_o10_2_gui_export $img]
}

if {$ok == 0} {
    set fh [open "$screenshots_dir/SCREENSHOT_EXPORT_FAILED.txt" a]
    puts $fh "gui_screenshot mode could not export any nonempty PNG."
    close $fh
    exit 2
}

puts "MPTDC_O10_2_GUI_INFO: exported $ok screenshot(s)"
