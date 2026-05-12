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

set pnr(optimization_goal)        [mptdc_env_or_default MPTDC_PNR_OPT_GOAL area_first]
set pnr(aspect_ratio)             [mptdc_env_or_default MPTDC_PNR_ASPECT_RATIO 1.0]
set pnr(core_utilization)         [mptdc_env_or_default MPTDC_PNR_CORE_UTIL 0.78]
set pnr(place_global_max_density) [mptdc_env_or_default MPTDC_PNR_MAX_DENSITY 0.82]
set pnr(core_margin_um)           [mptdc_env_or_default MPTDC_PNR_CORE_MARGIN_UM 20.0]

# XH018 1P4M baseline. For the first estimate, signals are kept on M1-M3 so
# M4 remains available for VDD/VSS straps and top-level power distribution as
# much as practical. Relax this only after IR/route congestion data says so.
set pnr(metal_stack)              [mptdc_env_or_default MPTDC_PNR_METAL_STACK 1P4M]
set pnr(signal_bottom_layer)      [mptdc_env_or_default MPTDC_PNR_SIGNAL_BOTTOM_LAYER M1]
set pnr(signal_top_layer)         [mptdc_env_or_default MPTDC_PNR_SIGNAL_TOP_LAYER M3]
set pnr(power_reserved_layer)     [mptdc_env_or_default MPTDC_PNR_POWER_LAYER M4]

# Direction policy is documented and carried into the run manifest. The tech LEF
# owns the actual preferred direction; the flow reports these expected values so
# any mismatch is visible during review.
set pnr(route_dir_M1)             [mptdc_env_or_default MPTDC_PNR_DIR_M1 horizontal]
set pnr(route_dir_M2)             [mptdc_env_or_default MPTDC_PNR_DIR_M2 vertical]
set pnr(route_dir_M3)             [mptdc_env_or_default MPTDC_PNR_DIR_M3 horizontal]
set pnr(route_dir_M4)             [mptdc_env_or_default MPTDC_PNR_DIR_M4 vertical]

set pnr(do_detail_route)          [mptdc_env_or_default MPTDC_PNR_DO_DETAIL_ROUTE 0]
