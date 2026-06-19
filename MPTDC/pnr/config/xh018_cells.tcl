# =============================================================================
# XH018 physical-cell candidates for MPTDC PNR
#
# This is a reviewed per-class policy, not a blanket physical-cell confirmation.
# The 2026-06-19 row-infrastructure audit found no dedicated CORE tap/endcap
# masters in the active JIHD LEF, all PDK LEFs/TLEFs, CDL, or reference-flow
# text. IO ENDCAP/CORNER macros remain rejected for standard-cell rows.
#
# Implementation may proceed only when MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1.
# Final PASS remains blocked until row or block DRC/LVS proves the no-dedicated
# tap/endcap policy is legal for XH018/JIHD.
# =============================================================================

global mptdc_xh018_cells
array set mptdc_xh018_cells {
    status                      REVIEWED_POLICY_NO_CORE_TAP_ENDCAP_PENDING_DRC_LVS
    physical_cell_config_status REVIEWED_POLICY
    confirmed                   0
    implementation_allowed      1
    final_signoff_allowed       0
    row_infra_policy            NO_DEDICATED_CORE_TAP_ENDCAP_PENDING_DRC_LVS
    row_infra_status            PROVISIONAL
    digital_pnr_signoff         PROVISIONAL

    stdcell_site                {core_jihd}
    stdcell_pg_power            {vddi}
    stdcell_pg_ground           {gndi}

    tap_policy                  NO_DEDICATED_MASTER_PENDING_DRC_LVS
    tap                         {}
    endcap_left_policy          NO_DEDICATED_MASTER_PENDING_DRC_LVS
    endcap_left                 {}
    endcap_right_policy         NO_DEDICATED_MASTER_PENDING_DRC_LVS
    endcap_right                {}

    filler_policy               REQUIRED_MASTER
    filler                      {FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD}
    spacer_policy               REQUIRED_MASTER
    spacer                      {FCPE32JIHD FCPE16JIHD FCPE8JIHD FCPE4JIHD FCPE2JIHD FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD}
    decap_policy                REQUIRED_MASTER
    decap                       {DECAP25JIHD DECAP15JIHD DECAP10JIHD DECAP7JIHD DECAP5JIHD DECAP3JIHD}
    antenna_policy              REQUIRED_MASTER
    antenna                     {ANTENNACELLN2JIHD ANTENNACELLNP2JIHD ANTENNACELLP2JIHD}
    tie_high_policy             REQUIRED_MASTER
    tie_high                    {LOGIC1DJIHD LOGIC1LVJIHD}
    tie_low_policy              REQUIRED_MASTER
    tie_low                     {LOGIC0DJIHD LOGIC0LVJIHD}
    cts_buffers_policy          REQUIRED_MASTER
    cts_buffers                 {CLKVBUFJIHD}
    cts_inverters_policy        REQUIRED_MASTER
    cts_inverters               {INJIHDX0 INJIHDX1 INJIHDX2 INJIHDX3 INJIHDX4 INJIHDX6 INJIHDX8 INJIHDX12}
    phase_iso_buffer_policy     REQUIRED_MASTER
    phase_iso_buffer            {BUJIHDX4}
    phase_final_buffer_policy   REQUIRED_MASTER
    phase_final_buffer          {BUJIHDX12}
    phase_buffer_policy         {PREFER_UNIFORM_JIHD_AFTER_FRESH_GENUS_RERUN}

    rejected_core_row_cells     {IO_CORNER IO_ENDCAP PAD_RING_ENDCAP}
    row_cell_policy             {NO_DEDICATED_CORE_TAP_ENDCAP_PENDING_DRC_LVS_REJECT_IO_RING_CORNERS_FOR_CORE_ROWS}
    row_audit                   {20260619_xh018_row_infra_5c24d714}
    strict_tap_count            {0}
    strict_endcap_count         {0}
    core_tap_count              {0}
    core_endcap_count           {0}
    core_filler_count           {24}
    core_spacer_count           {73}
    io_endcap_count             {165}
    source                      {20260618_mptdc_allpdk_discovery_846a580d 20260619_xh018_row_infra_5c24d714 20260619_row_policy_audit}
    evidence_package_status     {EXTERNAL_SERVER_AUDIT_REQUIRED}
    evidence_files              {
        jihd_python_row_summary.rpt
        all_pdk_row_policy_summary.rpt
        pdk_row_policy_keyword_summary.rpt
        jihd_cdl_subckt_summary.rpt
        jihd_layout_netlist_inventory_summary.rpt
    }
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
    if {[mptdc_xh018_cell implementation_allowed] eq "1" &&
        [mptdc_xh018_env_truthy MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY]} {
        return
    }
    if {[mptdc_xh018_cell final_signoff_allowed] eq "1" && $mptdc_xh018_cells(confirmed) eq "1"} {
        return
    }
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

proc mptdc_xh018_env_truthy {name} {
    if {![info exists ::env($name)]} {
        return 0
    }
    set value [string tolower $::env($name)]
    return [expr {$value in {1 yes true on}}]
}

proc mptdc_xh018_cell_policy {class} {
    set policy [mptdc_xh018_cell ${class}_policy]
    if {$policy eq ""} {
        return REQUIRED_MASTER
    }
    return $policy
}

proc mptdc_xh018_policy_classes {} {
    return [list \
        tap \
        endcap_left \
        endcap_right \
        filler \
        spacer \
        decap \
        antenna \
        tie_high \
        tie_low \
        cts_buffers \
        cts_inverters \
        phase_iso_buffer \
        phase_final_buffer]
}

proc mptdc_xh018_validate_policy {{mode implementation}} {
    set missing [list]
    set policy_blocks [list]
    set provisional [list]
    foreach class [mptdc_xh018_policy_classes] {
        set policy [mptdc_xh018_cell_policy $class]
        set values [mptdc_xh018_cell_list $class]
        switch -- $policy {
            REQUIRED_MASTER {
                if {[llength $values] == 0} {
                    lappend missing $class
                }
            }
            NO_DEDICATED_MASTER_PENDING_DRC_LVS {
                if {$mode eq "final"} {
                    lappend policy_blocks $class
                } elseif {![mptdc_xh018_env_truthy MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY]} {
                    lappend policy_blocks $class
                } else {
                    lappend provisional $class
                }
            }
            NO_DEDICATED_MASTER_WITH_DRC_LVS_EVIDENCE {
                lappend provisional $class
            }
            default {
                error "MPTDC_XH018_UNKNOWN_CELL_POLICY: class=$class policy=$policy"
            }
        }
    }
    if {[llength $missing] > 0} {
        error "MPTDC_XH018_REQUIRED_CELL_CLASS_MISSING: classes=$missing"
    }
    if {[llength $policy_blocks] > 0} {
        error "MPTDC_XH018_ROW_POLICY_NOT_ALLOWED: mode=$mode classes=$policy_blocks set MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1 for provisional implementation; final PASS requires DRC/LVS evidence"
    }
    return $provisional
}
