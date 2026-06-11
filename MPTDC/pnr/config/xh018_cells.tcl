# =============================================================================
# XH018 physical-cell placeholders for MPTDC PNR
#
# These values are intentionally unconfirmed. Do not use them for insertion
# until the names are discovered from the actual LEF/Liberty set in the lab
# environment and reviewed.
# =============================================================================

array set mptdc_xh018_cells {
    status              UNCONFIRMED_PLACEHOLDERS
    confirmed           0
    tap                 {}
    endcap_left         {}
    endcap_right        {}
    filler              {}
    decap               {}
    antenna             {}
    tie_high            {}
    tie_low             {}
    source              {}
}

proc mptdc_xh018_cells_confirmed {} {
    global mptdc_xh018_cells
    return $mptdc_xh018_cells(confirmed)
}

proc mptdc_xh018_cell {class} {
    global mptdc_xh018_cells
    if {![info exists mptdc_xh018_cells($class)]} {
        return ""
    }
    return $mptdc_xh018_cells($class)
}

proc mptdc_xh018_require_confirmed_cells {} {
    global mptdc_xh018_cells
    if {$mptdc_xh018_cells(confirmed) ne "1"} {
        error "MPTDC_XH018_CELLS_UNCONFIRMED: run discover_xh018_physical_cells.sh and review MPTDC/pnr/config/xh018_cells.tcl before insertion"
    }
}
