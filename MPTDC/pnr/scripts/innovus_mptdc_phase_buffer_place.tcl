# =============================================================================
# Stable MPTDC O13 phase-buffer placement hook
# =============================================================================

set ::env(MPTDC_O13_SOURCE_ONLY) 1
source [file join [file dirname [file normalize [info script]]] innovus_o13_phase_buffer_place.tcl]

if {[llength [info commands mptdc_pnr_env]] == 0} {
    proc mptdc_pnr_env {name default_value} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default_value
    }
}

proc mptdc_pnr_phase_buffer_expected_topology {} {
    return {RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric}
}

proc mptdc_pnr_phase_buffer_apply_env_fallbacks {} {
    foreach {stable legacy} {
        MPTDC_PNR_PHASE_BUF_PITCH_UM MPTDC_O13_PHASE_BUF_PITCH_UM
        MPTDC_PNR_PHASE_BUF_ORIENT   MPTDC_O13_PHASE_BUF_ORIENT
        MPTDC_PNR_SLOW_ISO_X         MPTDC_O13_SLOW_ISO_X
        MPTDC_PNR_SLOW_ISO_Y         MPTDC_O13_SLOW_ISO_Y
        MPTDC_PNR_SLOW_DRV_X         MPTDC_O13_SLOW_DRV_X
        MPTDC_PNR_SLOW_DRV_Y         MPTDC_O13_SLOW_DRV_Y
        MPTDC_PNR_FAST_ISO_X         MPTDC_O13_FAST_ISO_X
        MPTDC_PNR_FAST_ISO_Y         MPTDC_O13_FAST_ISO_Y
        MPTDC_PNR_FAST_DRV_X         MPTDC_O13_FAST_DRV_X
        MPTDC_PNR_FAST_DRV_Y         MPTDC_O13_FAST_DRV_Y
    } {
        if {[info exists ::env($stable)] && $::env($stable) ne "" && ![info exists ::env($legacy)]} {
            set ::env($legacy) $::env($stable)
        }
    }
}

proc mptdc_pnr_apply_phase_buffer_placement {{mode final_typical}} {
    mptdc_pnr_phase_buffer_apply_env_fallbacks
    if {[llength [info commands mptdc_o13_apply_phase_buffer_placement]] == 0} {
        error "MPTDC_PNR_PHASE_BUFFER_FATAL: missing O13 phase-buffer placement helper"
    }
    return [mptdc_o13_apply_phase_buffer_placement $mode]
}
