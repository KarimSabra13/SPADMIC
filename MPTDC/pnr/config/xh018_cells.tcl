# =============================================================================
# XH018 physical-cell candidates for MPTDC PNR
#
# These values are intentionally not marked confirmed. The current lab
# discovery proves JIHD decap, antenna, tie, CTS-buffer, CTS-inverter,
# phase-buffer, FEED-row filler candidates, and JIHD stdcell PG pin names.
# The exact tap and endcap source is still unresolved: the 2026-06-19 all-LEF
# row audit found no CORE tap/endcap macros, while IO ENDCAP/CORNER macros are
# pad-ring cells and are not accepted as core-row infrastructure.
# Do not use this file for insertion until those classes are discovered from
# approved PDK inputs and reviewed.
# =============================================================================

global mptdc_xh018_cells
array set mptdc_xh018_cells {
    status              JIHD_PHASE_FILLER_PG_CONFIRMED_TAP_ENDCAP_NOT_FOUND_IN_CORE_LEF
    confirmed           0
    tap                 {}
    endcap_left         {}
    endcap_right        {}
    filler              {FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD}
    decap               {DECAP10JIHD DECAP15JIHD DECAP25JIHD DECAP3JIHD DECAP5JIHD DECAP7JIHD}
    antenna             {ANTENNACELLN2JIHD ANTENNACELLNP2JIHD ANTENNACELLP2JIHD}
    tie_high            {LOGIC1DJIHD LOGIC1LVJIHD}
    tie_low             {LOGIC0DJIHD LOGIC0LVJIHD}
    cts_buffers         {CLKVBUFJIHD}
    cts_inverters       {INJIHDX0 INJIHDX1 INJIHDX12 INJIHDX2 INJIHDX3 INJIHDX4 INJIHDX6 INJIHDX8}
    phase_iso_buffer    {BUJIHDX4}
    phase_final_buffer  {BUJIHDX12}
    phase_buffer_policy {PREFER_UNIFORM_JIHD_AFTER_FRESH_GENUS_RERUN}
    row_cell_policy     {ALLOW_APPROVED_NON_JIHD_AFTER_ALL_PDK_DISCOVERY_BUT_REJECT_IO_RING_CORNERS_FOR_CORE_ROWS}
    stdcell_site        {core_jihd}
    stdcell_pg_power    {vddi}
    stdcell_pg_ground   {gndi}
    row_audit           {20260619_xh018_row_infra_5c24d714}
    core_tap_count      {0}
    core_endcap_count   {0}
    core_filler_count   {24}
    io_endcap_count     {165}
    source              {20260618_mptdc_allpdk_discovery_846a580d 20260619_xh018_row_infra_5c24d714}
    source_hashes       {
        e0587511b5bbb47e7d5a96febc83aec9694179c4193f39faae20bbbe235b41b5  /eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/LEF/v6_0_0/xh018_D_CELLS_JIHD.lef
        723d02c5c82480b093072e01f5fc3d57f801d83635b39f778b77b87f39762d61  /eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_fast_1_98V_0C.lib
        c808ba294c090c5cfdbcc39f87537c653f26f85f610646166bbf7e8f8a05d7eb  /eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_fast_1_98V_m40C.lib
        beed736e73753c3feb9e799dd94080e517a77a3b484d524e16cf7230fa1d0113  /eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_slow_1_62V_125C.lib
        a72c04f889f6faed1eb2d7720f9f0920970837eea0709a9011eeb71ee29f4108  /eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_slow_1_62V_150C.lib
        451812f72ad74f6a1ac3369868457da9774afd0955e0d2270bd2234bc5074d69  /eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_slow_1_62V_175C.lib
        51ea154d856df4a7f6272376676abc0f6e900217824a64422d69c531053a7b04  /eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_slow_1_62V_85C.lib
        7162a11babf8472cebd198e3d9b64f7786bd5796d9672a59e1ef19e6a7d2446e  /eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_slow_1_62V_m40C.lib
        405a0b21dc1910cd1c95555c53b374b91f1f637da264dedaf363396b27b7a985  /eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_typ_1_80V_25C.lib
    }
    unresolved_classes  {tap endcap_left endcap_right}
    reviewed_by         {Karim Sabra}
    reviewed_date       {2026-06-19}
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

proc mptdc_xh018_cell_list {class} {
    set value [mptdc_xh018_cell $class]
    if {$value eq ""} {
        return [list]
    }
    return $value
}

proc mptdc_xh018_require_confirmed_cells {} {
    global mptdc_xh018_cells
    if {$mptdc_xh018_cells(confirmed) ne "1"} {
        set status "unknown"
        if {[info exists mptdc_xh018_cells(status)]} {
            set status $mptdc_xh018_cells(status)
        }
        set unresolved [list]
        if {[info exists mptdc_xh018_cells(unresolved_classes)]} {
            set unresolved $mptdc_xh018_cells(unresolved_classes)
        }
        error "MPTDC_XH018_CELLS_UNCONFIRMED: status=$status unresolved_classes=$unresolved; finish physical-cell discovery before insertion"
    }
}

proc mptdc_xh018_require_cell_class {class} {
    set value [mptdc_xh018_cell_list $class]
    if {[llength $value] == 0} {
        error "MPTDC_XH018_CELL_CLASS_MISSING: $class is empty in MPTDC/pnr/config/xh018_cells.tcl"
    }
    return $value
}
