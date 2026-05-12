# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : mptdc_pnr_config.tcl
# Purpose  : First-pass Innovus estimation knobs for the MPTDC macro
# =============================================================================

proc mptdc_env_or_default {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc mptdc_env_list_or_default {name default_list} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return [split $::env($name)]
    }
    return $default_list
}

set pnr(optimization_goal)        [mptdc_env_or_default MPTDC_PNR_OPT_GOAL area_first]
set pnr(aspect_ratio)             [mptdc_env_or_default MPTDC_PNR_ASPECT_RATIO 1.0]
set pnr(core_utilization)         [mptdc_env_or_default MPTDC_PNR_CORE_UTIL 0.78]
set pnr(place_global_max_density) [mptdc_env_or_default MPTDC_PNR_MAX_DENSITY 0.82]
set pnr(core_margin_um)           [mptdc_env_or_default MPTDC_PNR_CORE_MARGIN_UM 20.0]

# XH018 1P4M baseline. For the first estimate, signals are kept on MET1-MET3 so
# METTP remains available for VDD/VSS straps and top-level power distribution as
# much as practical. Relax this only after IR/route congestion data says so.
set pnr(metal_stack)              [mptdc_env_or_default MPTDC_PNR_METAL_STACK 1P4M]
set pnr(signal_bottom_layer)      [mptdc_env_or_default MPTDC_PNR_SIGNAL_BOTTOM_LAYER MET1]
set pnr(signal_top_layer)         [mptdc_env_or_default MPTDC_PNR_SIGNAL_TOP_LAYER MET3]
set pnr(signal_bottom_layer_idx)  [mptdc_env_or_default MPTDC_PNR_SIGNAL_BOTTOM_LAYER_IDX 1]
set pnr(signal_top_layer_idx)     [mptdc_env_or_default MPTDC_PNR_SIGNAL_TOP_LAYER_IDX 3]
set pnr(power_reserved_layer)     [mptdc_env_or_default MPTDC_PNR_POWER_LAYER METTP]
set pnr(connect_pg_pins)          [mptdc_env_or_default MPTDC_PNR_CONNECT_PG_PINS 1]

# Direction policy is documented and carried into the run manifest. The tech LEF
# owns the actual preferred direction; the flow reports these expected values so
# any mismatch is visible during review.
set pnr(route_dir_MET1)           [mptdc_env_or_default MPTDC_PNR_DIR_MET1 horizontal]
set pnr(route_dir_MET2)           [mptdc_env_or_default MPTDC_PNR_DIR_MET2 vertical]
set pnr(route_dir_MET3)           [mptdc_env_or_default MPTDC_PNR_DIR_MET3 horizontal]
set pnr(route_dir_METTP)          [mptdc_env_or_default MPTDC_PNR_DIR_METTP vertical]

set pnr(do_detail_route)          [mptdc_env_or_default MPTDC_PNR_DO_DETAIL_ROUTE 0]

# Phase-detector matrix symmetry preparation. These hooks intentionally stay
# optional until the final oscillator/PD macro LEFs and extraction decks are
# available. They create reviewable grouping/region collateral and a manifest
# report without making the estimate flow depend on macro-specific commands.
set pnr(pd_symmetry_enable)        [mptdc_env_or_default MPTDC_PNR_PD_SYMMETRY_ENABLE 1]
set pnr(pd_symmetry_create_group)  [mptdc_env_or_default MPTDC_PNR_PD_CREATE_GROUP 1]
set pnr(pd_symmetry_create_region) [mptdc_env_or_default MPTDC_PNR_PD_CREATE_REGION 1]
set pnr(pd_symmetry_group)         [mptdc_env_or_default MPTDC_PNR_PD_GROUP mptdc_pd_matrix]
set pnr(pd_rows)                   [mptdc_env_or_default MPTDC_PNR_PD_ROWS 8]
set pnr(pd_cols)                   [mptdc_env_or_default MPTDC_PNR_PD_COLS 8]
set pnr(pd_region_margin_um)       [mptdc_env_or_default MPTDC_PNR_PD_REGION_MARGIN_UM 10.0]
set pnr(pd_instance_patterns)      [mptdc_env_list_or_default MPTDC_PNR_PD_INSTANCE_PATTERNS \
    [list "*gen_pd_row*gen_pd_col*u_pd*" "*mptdc_pd_cell*" "*u_pd*"]]
