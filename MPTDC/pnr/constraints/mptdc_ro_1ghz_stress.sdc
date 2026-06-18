# =============================================================================
# Project  : SPAD_MPTDC
# File     : mptdc_ro_1ghz_stress.sdc
# Purpose  : Report-only 1 GHz oscillator-domain stress overlay
# Author   : Karim Sabra
# =============================================================================
# This overlay is for robustness reporting only. It must not replace the
# nominal TC/WC/BC functional views or relax any functional constraint.
# =============================================================================

puts "MPTDC_RO_STRESS_SDC_INFO: loading report-only 1 GHz oscillator stress overlay"

set mptdc_ro_stress_period_ns 1.000
if {[info exists ::env(MPTDC_RO_STRESS_PERIOD_NS)] && $::env(MPTDC_RO_STRESS_PERIOD_NS) ne ""} {
    set mptdc_ro_stress_period_ns $::env(MPTDC_RO_STRESS_PERIOD_NS)
}

proc mptdc_ro_stress_get_pins {patterns} {
    set pins [list]
    foreach pattern $patterns {
        set found [list]
        catch {set found [get_pins -quiet -hierarchical $pattern]}
        if {[llength $found] == 0} {
            catch {set found [get_pins -quiet $pattern]}
        }
        foreach pin $found {
            if {[lsearch -exact $pins $pin] < 0} {
                lappend pins $pin
            }
        }
    }
    return $pins
}

proc mptdc_ro_stress_raw_pin_patterns {family tap} {
    return [list \
        [format {u_core/u_osc_%s/u_ro_tune4/S[%d]} $family $tap] \
        [format {u_core_u_osc_%s_u_ro_tune4/S[%d]} $family $tap]]
}

proc mptdc_ro_stress_stage_pin_patterns {family tap inst pin} {
    return [list \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d]/%s/%s} $family $tap $inst $pin] \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d].%s/%s} $family $tap $inst $pin] \
        [format {u_core_u_phase_buf_%s/gen_phase_buf[%d].%s/%s} $family $tap $inst $pin] \
        [format {u_core_u_phase_buf_%s_gen_phase_buf_%d__%s/%s} $family $tap $inst $pin] \
        [format {*u_phase_buf_%s*gen_phase_buf*%d*%s/%s} $family $tap $inst $pin]]
}

proc mptdc_ro_stress_remove_clock {clock_name} {
    set clocks [list]
    catch {set clocks [get_clocks -quiet $clock_name]}
    if {[llength $clocks] > 0} {
        catch {remove_clock $clocks}
    }
}

set mptdc_ro_stress_raw_clock_count 0
set mptdc_ro_stress_buf_clock_count 0

foreach family {slow fast} {
    for {set tap 0} {$tap < 8} {incr tap} {
        set raw_clock [expr {$tap == 0 ? "clk_osc_${family}" : "clk_osc_${family}_tap${tap}"}]
        set buf_clock [format {clk_osc_%s_buf_tap%d} $family $tap]
        set raw_pin [lindex [mptdc_ro_stress_get_pins [mptdc_ro_stress_raw_pin_patterns $family $tap]] 0]
        set drv_q_pin [lindex [mptdc_ro_stress_get_pins [mptdc_ro_stress_stage_pin_patterns $family $tap u_drv Q]] 0]

        mptdc_ro_stress_remove_clock $buf_clock
        mptdc_ro_stress_remove_clock $raw_clock

        if {$raw_pin ne ""} {
            if {![catch {create_clock -name $raw_clock -period $mptdc_ro_stress_period_ns $raw_pin}]} {
                incr mptdc_ro_stress_raw_clock_count
            }
        }
        if {$raw_pin ne "" && $drv_q_pin ne ""} {
            if {![catch {create_generated_clock -name $buf_clock -source $raw_pin -divide_by 1 $drv_q_pin}]} {
                incr mptdc_ro_stress_buf_clock_count
            }
        }
    }
}

puts "MPTDC_RO_STRESS_SDC_INFO: stress_period_ns=$mptdc_ro_stress_period_ns"
puts "MPTDC_RO_STRESS_SDC_INFO: raw_clocks=$mptdc_ro_stress_raw_clock_count"
puts "MPTDC_RO_STRESS_SDC_INFO: buffered_clocks=$mptdc_ro_stress_buf_clock_count"
if {$mptdc_ro_stress_raw_clock_count != 16 || $mptdc_ro_stress_buf_clock_count != 16} {
    puts "MPTDC_RO_STRESS_SDC_WARN: expected 16 raw and 16 buffered stress clocks"
}
