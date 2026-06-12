# =============================================================================
# Stable MPTDC PD matrix 8x8 placement/audit hook
# =============================================================================

source [file join [file dirname [file normalize [info script]]] pd_matrix_floorplan.tcl]

if {[llength [info commands mptdc_pnr_env]] == 0} {
    proc mptdc_pnr_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_pnr_pd_grid_enabled {} {
    return [mptdc_pnr_env MPTDC_PNR_PLACE_PD_GRID 0]
}

proc mptdc_pnr_fast_tags_by_column_enabled {} {
    return [mptdc_pnr_env MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN 0]
}

proc mptdc_pnr_exact_fast_tag_bits {} {
    return [split [mptdc_pnr_env MPTDC_FAST_TAG_REPAIR_EXACT_BITS "0 5 6"]]
}

proc mptdc_pnr_exact_fast_tag_taps {} {
    return [split [mptdc_pnr_env MPTDC_FAST_TAG_REPAIR_EXACT_TAPS "0 1 2 3 4 5 6 7"]]
}

proc mptdc_pnr_pd_grid_shape {} {
    return [list rows 8 cols 8 cells 64]
}

proc mptdc_pnr_pd_instance_patterns {} {
    if {[info exists ::env(MPTDC_PNR_PD_INSTANCE_PATTERNS)] && $::env(MPTDC_PNR_PD_INSTANCE_PATTERNS) ne ""} {
        return [split $::env(MPTDC_PNR_PD_INSTANCE_PATTERNS)]
    }
    return [list "*gen_pd_row*gen_pd_col*u_pd*" "*mptdc_pd_cell*" "*u_pd*"]
}

proc mptdc_pnr_write_pd_grid_intent {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_PD_GRID_REPORT mptdc_pd_grid_intent.rpt]
    }
    set fh [open $path w]
    puts $fh "# MPTDC PD Grid Intent"
    puts $fh "enabled=[mptdc_pnr_pd_grid_enabled]"
    puts $fh "fast_tags_by_column=[mptdc_pnr_fast_tags_by_column_enabled]"
    puts $fh "exact_fast_tag_taps=[mptdc_pnr_exact_fast_tag_taps]"
    puts $fh "exact_fast_tag_bits=[mptdc_pnr_exact_fast_tag_bits]"
    puts $fh "fast_tag_to_pd_timing_path=TIMED_DO_NOT_FALSE_PATH_DO_NOT_MULTICYCLE"
    puts $fh "shape=[mptdc_pnr_pd_grid_shape]"
    puts $fh "patterns=[mptdc_pnr_pd_instance_patterns]"
    close $fh
    return $path
}

proc mptdc_pnr_write_fast_tag_column_intent {{path ""}} {
    if {$path eq ""} {
        set path [mptdc_pnr_env MPTDC_PNR_FAST_TAG_COLUMN_REPORT mptdc_fast_tag_column_intent.rpt]
    }
    set fh [open $path w]
    puts $fh "# MPTDC Fast-Tag Column Placement Intent"
    puts $fh "enabled=[mptdc_pnr_fast_tags_by_column_enabled]"
    puts $fh "path_family=FAST_TAG_TO_PD_TS"
    puts $fh "route_length_report=reports/fast_tag_to_pd_route_lengths.csv"
    puts $fh "timing_report=reports/fast_tag_to_pd_timing_post_route.rpt"
    puts $fh "decision_field=FAST_TAG_TO_PD_TS_POSTROUTE_CLEAN"
    puts $fh "exact_taps=[mptdc_pnr_exact_fast_tag_taps]"
    puts $fh "exact_bits=[mptdc_pnr_exact_fast_tag_bits]"
    puts $fh "rule=place_each_fast_tag_generator_near_matching_pd_column"
    puts $fh "rule=keep_bits_0_5_6_routes_short_and_local"
    close $fh
    return $path
}

proc mptdc_pnr_apply_pd_grid_placement {} {
    if {![mptdc_pnr_pd_grid_enabled]} {
        return 0
    }
    if {[llength [info commands mptdc_osc_pd_apply_pd_matrix_floorplan]] == 0} {
        error "MPTDC_PNR_PD_GRID_FATAL: missing PD matrix helper"
    }
    return [mptdc_osc_pd_apply_pd_matrix_floorplan]
}
