# =============================================================================
# Project  : SPAD_MPTDC
# File     : innovus_mptdc_digital_signoff.tcl
# Purpose  : Digital block signoff entrypoint for mptdc_axis_core
# Author   : Karim Sabra
# =============================================================================

proc mptdc_signoff_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_signoff_repo_root {} {
    return [file normalize [mptdc_signoff_env MPTDC_REPO_ROOT [file join [file dirname [info script]] ../../..]]]
}

proc mptdc_signoff_result_dir {} {
    return [file normalize [mptdc_signoff_env MPTDC_SIGNOFF_RESULT_DIR work/innovus/mptdc_digital_signoff]]
}

proc mptdc_signoff_status_keys {} {
    return [list \
        RTL_INTERFACE_STATUS \
        GENUS_HANDOFF_STATUS \
        FLOORPLAN_STATUS \
        IO_STATUS \
        RO_MACRO_STATUS \
        PHASE_BUFFER_STATUS \
        PD_MATRIX_STATUS \
        PHASE_RC_SYMMETRY_STATUS \
        POWER_GRID_STATUS \
        CTS_STATUS \
        ROUTE_STATUS \
        SETUP_STATUS_TC \
        SETUP_STATUS_WC \
        HOLD_STATUS_BC \
        RO_1GHZ_STRESS_STATUS \
        DRV_STATUS \
        ANTENNA_STATUS \
        EXTRACTION_STATUS \
        DRC_STATUS \
        LVS_STATUS \
        RO_INTERNAL_SIGNOFF_STATUS \
        DELIVERABLE_STATUS \
        DIGITAL_PNR_SIGNOFF]
}

proc mptdc_signoff_write_initial_status {{path ""}} {
    if {$path eq ""} {
        set path [file join [mptdc_signoff_result_dir] reports digital_pnr_signoff_status.rpt]
    }
    file mkdir [file dirname $path]
    set fh [open $path w]
    puts $fh "# MPTDC Digital PNR Signoff Status"
    puts $fh "Author: Karim Sabra"
    puts $fh "STATUS_SCHEMA=PASS_FAIL_EXTERNAL_DEFERRED_PROVISIONAL"
    foreach key [mptdc_signoff_status_keys] {
        puts $fh "$key=DEFERRED evidence=not_run"
    }
    close $fh
    return $path
}

proc mptdc_signoff_require_confirmed_physical_cells {} {
    set repo [mptdc_signoff_repo_root]
    source [file join $repo MPTDC/pnr/config/xh018_cells.tcl]
    mptdc_xh018_require_confirmed_cells
    foreach class {
        tap
        endcap_left
        endcap_right
        filler
        decap
        antenna
        tie_high
        tie_low
        cts_buffers
        cts_inverters
        phase_iso_buffer
        phase_final_buffer
    } {
        mptdc_xh018_require_cell_class $class
    }
}

proc mptdc_signoff_source_check {} {
    mptdc_signoff_require_confirmed_physical_cells
    set status_path [mptdc_signoff_write_initial_status]
    puts "MPTDC_DIGITAL_SIGNOFF_SOURCE_CHECK=PASS"
    puts "MPTDC_DIGITAL_SIGNOFF_STATUS_TEMPLATE=$status_path"
}

if {[info exists ::env(MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY)] && $::env(MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY)} {
    mptdc_signoff_source_check
    return
}

mptdc_signoff_source_check

# The first executable signoff implementation must be added as explicit stages
# below: init/import, floorplan, power, place, CTS, route, extraction, STA,
# physical verification, and deliverable export. Do not silently delegate to a
# feasibility wrapper and call it signoff.
error "MPTDC_DIGITAL_SIGNOFF_EXECUTION_NOT_IMPLEMENTED: source gates passed, but final signoff stages must be implemented explicitly before launch"
