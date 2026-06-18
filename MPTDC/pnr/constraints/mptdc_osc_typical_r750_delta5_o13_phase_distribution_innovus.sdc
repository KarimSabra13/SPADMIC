# =============================================================================
# O13 Innovus-safe phase-distribution oscillator overlay
# =============================================================================
# Typical feasibility only. Not MMMC signoff, not final silicon signoff, and not
# tapeout-ready.  Raw RO_tune4/S pins remain analog load-check source pins;
# generated clocks at final BUHDX12 outputs model downstream digital phase
# clocks.
# =============================================================================

puts "MPTDC_O13_INNOVUS_SDC_INFO: loading O13_PHASE_DISTRIBUTION_TREE_CLEANUP overlay"
puts "MPTDC_O13_INNOVUS_SDC_INFO: labels = O13_PHASE_DISTRIBUTION_TREE_CLEANUP TYPICAL_ONLY NOT_FINAL_SIGNOFF"

set mptdc_o13_fast_period_typ_ns 1.333
set mptdc_o13_slow_period_typ_ns 1.430
if {[info exists ::env(MPTDC_RO_FAST_PERIOD_NS)] && $::env(MPTDC_RO_FAST_PERIOD_NS) ne ""} {
    set mptdc_o13_fast_period_typ_ns $::env(MPTDC_RO_FAST_PERIOD_NS)
}
if {[info exists ::env(MPTDC_RO_SLOW_PERIOD_NS)] && $::env(MPTDC_RO_SLOW_PERIOD_NS) ne ""} {
    set mptdc_o13_slow_period_typ_ns $::env(MPTDC_RO_SLOW_PERIOD_NS)
}
set mptdc_o13_setup_uncertainty_ns 0.010
set mptdc_o13_hold_uncertainty_ns 0.005

proc mptdc_o13_sdc_get_pins {patterns} {
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

proc mptdc_o13_sdc_get_clock {name} {
    set clocks [list]
    catch {set clocks [get_clocks -quiet $name]}
    return $clocks
}

proc mptdc_o13_sdc_raw_pin_patterns {family tap} {
    return [list \
        [format {u_core/u_osc_%s/u_ro_tune4/S[%d]} $family $tap] \
        [format {u_core_u_osc_%s_u_ro_tune4/S[%d]} $family $tap]]
}

proc mptdc_o13_sdc_stage_pin_patterns {family tap inst pin} {
    return [list \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d]/%s/%s} $family $tap $inst $pin] \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d].%s/%s} $family $tap $inst $pin] \
        [format {u_core_u_phase_buf_%s/gen_phase_buf[%d].%s/%s} $family $tap $inst $pin] \
        [format {u_core_u_phase_buf_%s_gen_phase_buf_%d__%s/%s} $family $tap $inst $pin] \
        [format {*u_phase_buf_%s*gen_phase_buf*%d*%s/%s} $family $tap $inst $pin]]
}

proc mptdc_o13_sdc_create_clock_if_missing {clock_name period pin} {
    set clocks [mptdc_o13_sdc_get_clock $clock_name]
    if {[llength $clocks] > 0} {
        puts "MPTDC_O13_INNOVUS_SDC_INFO: existing clock $clock_name count = [llength $clocks]"
        return 1
    }
    if {$pin eq ""} {
        puts "MPTDC_O13_INNOVUS_SDC_WARN: cannot create $clock_name; no pin matched"
        return 0
    }
    if {[catch {create_clock -name $clock_name -period $period $pin} err]} {
        puts "MPTDC_O13_INNOVUS_SDC_WARN: create_clock $clock_name failed: $err"
        return 0
    }
    puts "MPTDC_O13_INNOVUS_SDC_INFO: created raw clock $clock_name on $pin period=$period"
    return 1
}

proc mptdc_o13_sdc_apply_uncertainty {clock_name} {
    global mptdc_o13_setup_uncertainty_ns mptdc_o13_hold_uncertainty_ns
    set clocks [mptdc_o13_sdc_get_clock $clock_name]
    if {[llength $clocks] == 0} {
        puts "MPTDC_O13_INNOVUS_SDC_WARN: clock $clock_name not found for uncertainty"
        return 0
    }
    catch {set_clock_uncertainty -setup $mptdc_o13_setup_uncertainty_ns $clocks}
    catch {set_clock_uncertainty -hold  $mptdc_o13_hold_uncertainty_ns  $clocks}
    return 1
}

proc mptdc_o13_sdc_create_generated_clock {family tap raw_pin final_q_pin} {
    set raw_clock [expr {$tap == 0 ? "clk_osc_${family}" : "clk_osc_${family}_tap${tap}"}]
    set final_clock [format {clk_osc_%s_buf_tap%d} $family $tap]
    if {[llength [mptdc_o13_sdc_get_clock $final_clock]] > 0} {
        puts "MPTDC_O13_INNOVUS_SDC_INFO: existing generated clock $final_clock"
        mptdc_o13_sdc_apply_uncertainty $final_clock
        return 1
    }
    if {$raw_pin eq "" || $final_q_pin eq ""} {
        puts "MPTDC_O13_INNOVUS_SDC_WARN: cannot create $final_clock; raw_pin='$raw_pin' final_q_pin='$final_q_pin'"
        return 0
    }
    if {[catch {create_generated_clock -name $final_clock -source $raw_pin -divide_by 1 $final_q_pin} err]} {
        puts "MPTDC_O13_INNOVUS_SDC_WARN: create_generated_clock $final_clock failed: $err"
        return 0
    }
    mptdc_o13_sdc_apply_uncertainty $raw_clock
    mptdc_o13_sdc_apply_uncertainty $final_clock
    puts "MPTDC_O13_INNOVUS_SDC_INFO: created $final_clock from $raw_pin to $final_q_pin"
    return 1
}

set mptdc_o13_raw_pin_count 0
set mptdc_o13_iso_a_count 0
set mptdc_o13_iso_q_count 0
set mptdc_o13_drv_a_count 0
set mptdc_o13_drv_q_count 0
set mptdc_o13_raw_clock_count 0
set mptdc_o13_generated_clock_count 0

foreach family {slow fast} {
    set period [expr {$family eq "slow" ? $mptdc_o13_slow_period_typ_ns : $mptdc_o13_fast_period_typ_ns}]
    for {set tap 0} {$tap < 8} {incr tap} {
        set raw_clock [expr {$tap == 0 ? "clk_osc_${family}" : "clk_osc_${family}_tap${tap}"}]
        set raw_pins [mptdc_o13_sdc_get_pins [mptdc_o13_sdc_raw_pin_patterns $family $tap]]
        set iso_a_pins [mptdc_o13_sdc_get_pins [mptdc_o13_sdc_stage_pin_patterns $family $tap u_iso A]]
        set iso_q_pins [mptdc_o13_sdc_get_pins [mptdc_o13_sdc_stage_pin_patterns $family $tap u_iso Q]]
        set drv_a_pins [mptdc_o13_sdc_get_pins [mptdc_o13_sdc_stage_pin_patterns $family $tap u_drv A]]
        set drv_q_pins [mptdc_o13_sdc_get_pins [mptdc_o13_sdc_stage_pin_patterns $family $tap u_drv Q]]
        incr mptdc_o13_raw_pin_count [llength $raw_pins]
        incr mptdc_o13_iso_a_count [llength $iso_a_pins]
        incr mptdc_o13_iso_q_count [llength $iso_q_pins]
        incr mptdc_o13_drv_a_count [llength $drv_a_pins]
        incr mptdc_o13_drv_q_count [llength $drv_q_pins]
        if {[mptdc_o13_sdc_create_clock_if_missing $raw_clock $period [lindex $raw_pins 0]]} {
            incr mptdc_o13_raw_clock_count
        }
        if {[mptdc_o13_sdc_create_generated_clock $family $tap [lindex $raw_pins 0] [lindex $drv_q_pins 0]]} {
            incr mptdc_o13_generated_clock_count
        }
    }
}

puts "MPTDC_O13_INNOVUS_SDC_INFO: matched raw RO pins = $mptdc_o13_raw_pin_count"
puts "MPTDC_O13_INNOVUS_SDC_INFO: matched BUHDX4 iso A pins = $mptdc_o13_iso_a_count"
puts "MPTDC_O13_INNOVUS_SDC_INFO: matched BUHDX4 iso Q pins = $mptdc_o13_iso_q_count"
puts "MPTDC_O13_INNOVUS_SDC_INFO: matched BUHDX12 driver A pins = $mptdc_o13_drv_a_count"
puts "MPTDC_O13_INNOVUS_SDC_INFO: matched BUHDX12 driver Q pins = $mptdc_o13_drv_q_count"
puts "MPTDC_O13_INNOVUS_SDC_INFO: raw clocks = $mptdc_o13_raw_clock_count"
puts "MPTDC_O13_INNOVUS_SDC_INFO: generated final-driver clocks = $mptdc_o13_generated_clock_count"
if {$mptdc_o13_raw_pin_count != 16 || $mptdc_o13_iso_a_count != 16 || $mptdc_o13_iso_q_count != 16 || $mptdc_o13_drv_a_count != 16 || $mptdc_o13_drv_q_count != 16 || $mptdc_o13_generated_clock_count != 16} {
    puts "MPTDC_O13_INNOVUS_SDC_WARN: expected complete 16-tap two-stage phase-buffer clock model"
}

puts "MPTDC_O13_INNOVUS_SDC_INFO: no broad oscillator-domain false paths added"
puts "MPTDC_O13_INNOVUS_SDC_INFO: do not send RO or phase-buffer clocks through normal CTS"
