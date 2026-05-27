# =============================================================================
# O0 oscillator/PD physical timing overlay
# =============================================================================
# PROVISIONAL - NOT ANALOG VERIFIED
#
# This overlay is loaded only when MPTDC_OSC_PD_SDC_OVERLAY points to this file.
# It refines reporting and physical bounds for the oscillator/PD signoff track.
# It must not be merged into the production SDC until lab reports and analog
# macro data prove that it is useful and does not hide real clk_sys timing.
# =============================================================================

proc mptdc_o0_try_get_pins {patterns} {
    set pins [list]
    foreach pattern $patterns {
        set found [get_pins -quiet -hierarchical $pattern]
        if {[llength $found] > 0} {
            set pins [concat $pins $found]
        }
    }
    return $pins
}

proc mptdc_o0_try_get_nets {patterns} {
    set nets [list]
    foreach pattern $patterns {
        set found [get_nets -quiet -hierarchical $pattern]
        if {[llength $found] > 0} {
            set nets [concat $nets $found]
        }
    }
    return $nets
}

proc mptdc_o0_try {label body} {
    if {[catch {uplevel 1 $body} err]} {
        puts "MPTDC_O0_SDC_WARN: $label failed: $err"
    } else {
        puts "MPTDC_O0_SDC_INFO: $label"
    }
}

puts "MPTDC_O0_SDC_INFO: loading provisional oscillator/PD physical overlay"
puts "MPTDC_O0_SDC_INFO: status PROVISIONAL - NOT ANALOG VERIFIED"

# Nominal tap clocks are already created by mptdc.sdc from mptdc.defines.  Keep
# the nominal values visible in the log for report review.
puts "MPTDC_O0_SDC_INFO: slow nominal period ns = $design(OSC_SLOW_PERIOD)"
puts "MPTDC_O0_SDC_INFO: fast nominal period ns = $design(OSC_FAST_PERIOD)"
puts "MPTDC_O0_SDC_INFO: slow tap step ns = $design(OSC_SLOW_TAP_STEP)"
puts "MPTDC_O0_SDC_INFO: fast tap step ns = $design(OSC_FAST_TAP_STEP)"

# Tighten physical reporting on phase nets without changing functional timing.
set mptdc_o0_phase_net_patterns [list]
for {set i 0} {$i < 8} {incr i} {
    lappend mptdc_o0_phase_net_patterns "*slow_phase\\[$i\\]*"
    lappend mptdc_o0_phase_net_patterns "*fast_phase\\[$i\\]*"
    lappend mptdc_o0_phase_net_patterns "*u_osc_slow*phase\\[$i\\]*"
    lappend mptdc_o0_phase_net_patterns "*u_osc_fast*phase\\[$i\\]*"
}
set mptdc_o0_phase_nets [mptdc_o0_try_get_nets $mptdc_o0_phase_net_patterns]
if {[llength $mptdc_o0_phase_nets] > 0} {
    mptdc_o0_try "set max transition on oscillator phase nets" {
        set_max_transition 0.150 $mptdc_o0_phase_nets
    }
    mptdc_o0_try "set provisional max capacitance on oscillator phase nets" {
        set_max_capacitance 0.050 $mptdc_o0_phase_nets
    }
} else {
    puts "MPTDC_O0_SDC_WARN: no oscillator phase nets matched for physical bounds"
}

# Explicit report groups.  These do not cut timing; they only make Genus timing
# reports easier to classify.
set mptdc_o0_pd_cells [get_cells -quiet -hierarchical *gen_pd_row*gen_pd_col*u_pd*]
set mptdc_o0_fast_cells [get_cells -quiet -hierarchical *u_fast_cnt*]
set mptdc_o0_slow_cells [get_cells -quiet -hierarchical *u_slow_cnt*]
set mptdc_o0_bridge_cells [get_cells -quiet -hierarchical *u_hit_capture_bridge*]

if {[llength $mptdc_o0_pd_cells] > 0} {
    mptdc_o0_try "group PD capture endpoints for review" {
        group_path -name OPD_PD_CAPTURE -to $mptdc_o0_pd_cells
    }
}
if {[llength $mptdc_o0_fast_cells] > 0} {
    mptdc_o0_try "group fast counter endpoints for review" {
        group_path -name OPD_REAL_FAST -to $mptdc_o0_fast_cells
    }
}
if {[llength $mptdc_o0_slow_cells] > 0} {
    mptdc_o0_try "group slow counter endpoints for review" {
        group_path -name OPD_REAL_SLOW -to $mptdc_o0_slow_cells
    }
}
if {[llength $mptdc_o0_bridge_cells] > 0} {
    mptdc_o0_try "group held-bus bridge endpoints for review" {
        group_path -name OPD_HELD_BUS_CDC -to $mptdc_o0_bridge_cells
    }
}

# Keep the existing clk_sys backend timing intact.  This overlay intentionally
# adds no false path to mptdc_meas_ctrl, mptdc_context_bank, mptdc_drain_ctrl,
# FIFO, shared readout, or narrow readout.
puts "MPTDC_O0_SDC_INFO: no clk_sys backend timing exceptions added"

# Current exception policy:
#   - slow_phase sampled by fast_phase inside PD is intentional Vernier sampling.
#   - STOP metadata capture and held-bus CDC use the existing main-SDC waivers.
#   - PD/counter async clears use the existing main-SDC waiver and require
#     recovery/removal/protocol review before signoff.
# This overlay only makes those classes visible to scripts/reports.
