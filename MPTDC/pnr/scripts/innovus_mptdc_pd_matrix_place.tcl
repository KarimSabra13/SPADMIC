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
    puts $fh "shape=[mptdc_pnr_pd_grid_shape]"
    puts $fh "patterns=[mptdc_pnr_pd_instance_patterns]"
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
