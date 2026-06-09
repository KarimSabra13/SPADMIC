# =============================================================================
# SPADMIC XLIBD typical cell values
#
# Reference-only values extracted from D_CELLS_HD_LPMOS_typ_1.80V_25C.
# Genus and Innovus still use the full Liberty file for timing and
# optimization.  This file is for reporting, interpretation, and documented
# feasibility assumptions.
# =============================================================================

if {[info exists ::mptdc_xlibd_config_loaded] && $::mptdc_xlibd_config_loaded} {
    return
}
set ::mptdc_xlibd_config_loaded 1

array set ::mptdc_xlibd {
    source.library D_CELLS_HD_LPMOS_typ_1.80V_25C
    source.vdd_v 1.8
    source.temperature_c 25
    source.cap_unit pf_ff
    source.time_unit ns
    source.input_slope_ref_ns 0.6210

    analog.ro_strict_d_load_ff 58.72
    analog.ro_cn_like_load_ff 75.59

    cell.BUHDX4.type BUFFER
    cell.BUHDX4.area_um2 20.07
    cell.BUHDX4.input_cap_ff 10.56
    cell.BUHDX4.output_max_cap_ff 3227
    cell.BUHDX4.output_max_fanout 1357
    cell.BUHDX4.timing.load_0p8075_pf.rise_transition_ns 1.1716
    cell.BUHDX4.timing.load_0p8075_pf.fall_transition_ns 0.8442

    cell.BUHDX6.type BUFFER
    cell.BUHDX6.area_um2 27.60
    cell.BUHDX6.input_cap_ff 16.23
    cell.BUHDX6.output_max_cap_ff 4769
    cell.BUHDX6.output_max_fanout 2006

    cell.BUHDX8.type BUFFER
    cell.BUHDX8.area_um2 35.12
    cell.BUHDX8.input_cap_ff 21.70
    cell.BUHDX8.output_max_cap_ff 6452
    cell.BUHDX8.output_max_fanout 2714
    cell.BUHDX8.timing.load_0p8074_pf.rise_transition_ns 0.5964
    cell.BUHDX8.timing.load_0p8074_pf.fall_transition_ns 0.4280

    cell.BUHDX12.type BUFFER
    cell.BUHDX12.area_um2 50.18
    cell.BUHDX12.input_cap_ff 32.24
    cell.BUHDX12.output_max_cap_ff 9678
    cell.BUHDX12.output_max_fanout 4071
    cell.BUHDX12.timing.load_0p6058_pf.rise_transition_ns 0.3080
    cell.BUHDX12.timing.load_0p6058_pf.fall_transition_ns 0.2295
    cell.BUHDX12.timing.load_1p2106_pf.rise_transition_ns 0.5955
    cell.BUHDX12.timing.load_1p2106_pf.fall_transition_ns 0.4391

    cell.INHDX4.type INVERTER
    cell.INHDX4.area_um2 15.05
    cell.INHDX4.input_cap_ff 18.70
    cell.INHDX4.output_max_cap_ff 2877
    cell.INHDX4.output_max_fanout 1210

    cell.INHDX6.type INVERTER
    cell.INHDX6.area_um2 20.07
    cell.INHDX6.input_cap_ff 27.89
    cell.INHDX6.output_max_cap_ff 4483
    cell.INHDX6.output_max_fanout 1885

    cell.INHDX12.type INVERTER
    cell.INHDX12.area_um2 35.12
    cell.INHDX12.input_cap_ff 55.64
    cell.INHDX12.output_max_cap_ff 8679
    cell.INHDX12.output_max_fanout 3651

    cell.DFRRQHDX2.type POSEDGE_DFF_RESET
    cell.DFRRQHDX2.area_um2 60.21
    cell.DFRRQHDX2.clock_cap_ff 3.45
    cell.DFRRQHDX2.d_cap_ff 3.20
    cell.DFRRQHDX2.reset_cap_ff 6.51
    cell.DFRRQHDX2.output_max_cap_ff 1587
    cell.DFRRQHDX2.output_max_fanout 667
    cell.DFRRQHDX2.recovery_rn_to_c_rise_ns 2.5845
    cell.DFRRQHDX2.removal_rn_to_c_rise_ns 0.2017
    cell.DFRRQHDX2.min_width_rn_low_ns 0.5535

    cell.DFRRQHDX4.type POSEDGE_DFF_RESET
    cell.DFRRQHDX4.area_um2 65.23
    cell.DFRRQHDX4.clock_cap_ff 3.60
    cell.DFRRQHDX4.d_cap_ff 3.19
    cell.DFRRQHDX4.reset_cap_ff 6.37
    cell.DFRRQHDX4.output_max_cap_ff 3025
    cell.DFRRQHDX4.output_max_fanout 1272
    cell.DFRRQHDX4.recovery_rn_to_c_rise_ns 2.9060
    cell.DFRRQHDX4.removal_rn_to_c_rise_ns 0.2062
    cell.DFRRQHDX4.min_width_rn_low_ns 0.7096

    cell.SDFFQHDX2.type NEGEDGE_DFF_SCAN_SINGLE_Q
    cell.SDFFQHDX2.dont_use true
    cell.SDFFQHDX2.clock_cap_ff 3.80
    cell.SDFFQHDX2.d_cap_ff 3.33
    cell.SDFFQHDX2.scan_d_cap_ff 2.98
    cell.SDFFQHDX2.scan_enable_cap_ff 5.89
    cell.SDFFQHDX2.output_max_cap_ff 1587
    cell.SDFFQHDX2.output_max_fanout 667

    cell.SDFFQHDX4.type NEGEDGE_DFF_SCAN_SINGLE_Q
    cell.SDFFQHDX4.dont_use true
    cell.SDFFQHDX4.clock_cap_ff 3.80
    cell.SDFFQHDX4.d_cap_ff 3.33
    cell.SDFFQHDX4.scan_d_cap_ff 2.99
    cell.SDFFQHDX4.scan_enable_cap_ff 5.89
    cell.SDFFQHDX4.output_max_cap_ff 3163
    cell.SDFFQHDX4.output_max_fanout 1330
}

array set ::mptdc_xlibd_io_load_classes {
    light.d_inputs 4
    light.load_ff 12.8
    light.load_pf 0.0128
    medium.d_inputs 8
    medium.load_ff 25.6
    medium.load_pf 0.0256
    heavy.d_inputs 16
    heavy.load_ff 51.2
    heavy.load_pf 0.0512
    very_heavy.d_inputs 32
    very_heavy.load_ff 102.4
    very_heavy.load_pf 0.1024
}

proc mptdc_xlibd_get {key {default ""}} {
    if {[info exists ::mptdc_xlibd($key)]} {
        return $::mptdc_xlibd($key)
    }
    return $default
}

proc mptdc_xlibd_cell {cell field {default ""}} {
    return [mptdc_xlibd_get "cell.${cell}.${field}" $default]
}

proc mptdc_xlibd_analog_budget_ff {kind} {
    if {$kind eq "strict"} {
        return [mptdc_xlibd_get analog.ro_strict_d_load_ff 58.72]
    }
    if {$kind eq "cn"} {
        return [mptdc_xlibd_get analog.ro_cn_like_load_ff 75.59]
    }
    return ""
}

proc mptdc_xlibd_ratio {cap_ff budget_ff} {
    if {![string is double -strict $cap_ff] || ![string is double -strict $budget_ff] || $budget_ff <= 0.0} {
        return ""
    }
    return [format "%.2f" [expr {$cap_ff / $budget_ff}]]
}

proc mptdc_xlibd_equivalent_loads {cap_ff pin_kind} {
    set unit_ff ""
    switch -- $pin_kind {
        d  { set unit_ff [mptdc_xlibd_cell DFRRQHDX2 d_cap_ff] }
        c  { set unit_ff [mptdc_xlibd_cell DFRRQHDX2 clock_cap_ff] }
        rn { set unit_ff [mptdc_xlibd_cell DFRRQHDX2 reset_cap_ff] }
        default { return "" }
    }
    if {![string is double -strict $cap_ff] || ![string is double -strict $unit_ff] || $unit_ff <= 0.0} {
        return ""
    }
    return [format "%.1f" [expr {$cap_ff / $unit_ff}]]
}

proc mptdc_xlibd_io_load_class_value {class field {default ""}} {
    set key "${class}.${field}"
    if {[info exists ::mptdc_xlibd_io_load_classes($key)]} {
        return $::mptdc_xlibd_io_load_classes($key)
    }
    return $default
}

proc mptdc_xlibd_normalize_io_load_class {class} {
    if {$class eq ""} {
        return "medium"
    }
    if {[info exists ::mptdc_xlibd_io_load_classes(${class}.load_pf)]} {
        return $class
    }
    return "medium"
}
