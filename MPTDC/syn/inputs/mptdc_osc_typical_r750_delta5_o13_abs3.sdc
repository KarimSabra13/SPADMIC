# =============================================================================
# O13 abs3 clock/CDC repair overlay for R750_delta5 typical experiment
# =============================================================================
# Typical feasibility only. Not MMMC, not final signoff, and not a tapeout view.
#
# This overlay is loaded after mptdc.sdc.  The base SDC creates raw RO clocks on
# RO_tune4/S[0:7].  This overlay creates final digital phase clocks on the
# BUJIHDX12 driver outputs, adds those clocks to the oscillator clock collection,
# and re-applies the clk_sys-vs-oscillator asynchronous clock relationship.
# =============================================================================

puts "MPTDC_O13_ABS3_SDC_INFO: loading O13_ABS3_CLOCK_CDC_CONSTRAINT_REPAIR overlay"
puts "MPTDC_O13_ABS3_SDC_INFO: signoff status = TYPICAL_ONLY_NOT_MMMC_NOT_FINAL_SIGNOFF"
puts "MPTDC_O13_ABS3_SDC_INFO: expected RTL define = MPTDC_PHASE_BUFFER_TOPO_BUJIHDX4_BUJIHDX12"

set mptdc_o13_setup_uncertainty_ns 0.010
set mptdc_o13_hold_uncertainty_ns 0.005

proc mptdc_o13_abs3_try_get_pins {patterns} {
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

proc mptdc_o13_abs3_raw_clock_name {family tap} {
    if {$tap == 0} {
        return "clk_osc_${family}"
    }
    return "clk_osc_${family}_tap${tap}"
}

proc mptdc_o13_abs3_buffer_clock_name {family tap} {
    return [format {clk_osc_%s_buf_tap%d} $family $tap]
}

proc mptdc_o13_abs3_raw_pin_patterns {family tap} {
    return [list \
        [format {u_core/u_osc_%s/u_ro_tune4/S[%d]} $family $tap] \
        [format {u_core_u_osc_%s_u_ro_tune4/S[%d]} $family $tap]]
}

proc mptdc_o13_abs3_stage_pin_patterns {family tap inst pin} {
    return [list \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d]/%s/%s} $family $tap $inst $pin] \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d].%s/%s} $family $tap $inst $pin] \
        [format {u_core_u_phase_buf_%s/gen_phase_buf[%d].%s/%s} $family $tap $inst $pin] \
        [format {u_core_u_phase_buf_%s_gen_phase_buf_%d__%s/%s} $family $tap $inst $pin] \
        [format {*u_phase_buf_%s*gen_phase_buf*%d*%s/%s} $family $tap $inst $pin]]
}

proc mptdc_o13_abs3_clock_collection {clock_names} {
    set clocks [list]
    foreach clock_name $clock_names {
        set found [get_clocks -quiet $clock_name]
        foreach clk $found {
            if {[lsearch -exact $clocks $clk] < 0} {
                lappend clocks $clk
            }
        }
    }
    return $clocks
}

proc mptdc_o13_abs3_apply_clock_uncertainty {clock_names} {
    global mptdc_o13_setup_uncertainty_ns mptdc_o13_hold_uncertainty_ns
    foreach clock_name $clock_names {
        set clocks [get_clocks -quiet $clock_name]
        if {[llength $clocks] == 0} {
            puts "MPTDC_O13_ABS3_SDC_WARN: clock $clock_name not found for uncertainty"
            continue
        }
        catch {set_clock_uncertainty -setup $mptdc_o13_setup_uncertainty_ns $clocks}
        catch {set_clock_uncertainty -hold  $mptdc_o13_hold_uncertainty_ns  $clocks}
    }
}

proc mptdc_o13_abs3_create_final_generated_clock {family tap raw_pin final_q_pin} {
    set raw_clock [mptdc_o13_abs3_raw_clock_name $family $tap]
    set final_clock [mptdc_o13_abs3_buffer_clock_name $family $tap]
    if {[llength [get_clocks -quiet $final_clock]] > 0} {
        puts "MPTDC_O13_ABS3_SDC_INFO: existing generated clock $final_clock"
        mptdc_o13_abs3_apply_clock_uncertainty [list $final_clock]
        return 1
    }
    if {$raw_pin eq "" || $final_q_pin eq ""} {
        puts "MPTDC_O13_ABS3_SDC_WARN: cannot create $final_clock; raw_pin='$raw_pin' final_q_pin='$final_q_pin'"
        return 0
    }
    if {[catch {create_generated_clock -name $final_clock -source $raw_pin -divide_by 1 $final_q_pin} err]} {
        puts "MPTDC_O13_ABS3_SDC_WARN: create_generated_clock $final_clock failed: $err"
        return 0
    }
    mptdc_o13_abs3_apply_clock_uncertainty [list $raw_clock $final_clock]
    puts "MPTDC_O13_ABS3_SDC_INFO: created $final_clock from $raw_pin to $final_q_pin"
    return 1
}

set mptdc_o13_abs3_raw_clock_names [list]
set mptdc_o13_abs3_buffer_clock_names [list]
set mptdc_o13_abs3_slow_buffer_clock_names [list]
set mptdc_o13_abs3_fast_buffer_clock_names [list]
set mptdc_o13_abs3_raw_pin_count 0
set mptdc_o13_abs3_iso_a_count 0
set mptdc_o13_abs3_iso_q_count 0
set mptdc_o13_abs3_drv_a_count 0
set mptdc_o13_abs3_drv_q_count 0
set mptdc_o13_abs3_generated_clock_count 0

foreach family {slow fast} {
    for {set tap 0} {$tap < 8} {incr tap} {
        set raw_clock [mptdc_o13_abs3_raw_clock_name $family $tap]
        set buf_clock [mptdc_o13_abs3_buffer_clock_name $family $tap]
        lappend mptdc_o13_abs3_raw_clock_names $raw_clock
        lappend mptdc_o13_abs3_buffer_clock_names $buf_clock
        if {$family eq "slow"} {
            lappend mptdc_o13_abs3_slow_buffer_clock_names $buf_clock
        } else {
            lappend mptdc_o13_abs3_fast_buffer_clock_names $buf_clock
        }

        set raw_pins [mptdc_o13_abs3_try_get_pins [mptdc_o13_abs3_raw_pin_patterns $family $tap]]
        set iso_a_pins [mptdc_o13_abs3_try_get_pins [mptdc_o13_abs3_stage_pin_patterns $family $tap u_iso A]]
        set iso_q_pins [mptdc_o13_abs3_try_get_pins [mptdc_o13_abs3_stage_pin_patterns $family $tap u_iso Q]]
        set drv_a_pins [mptdc_o13_abs3_try_get_pins [mptdc_o13_abs3_stage_pin_patterns $family $tap u_drv A]]
        set drv_q_pins [mptdc_o13_abs3_try_get_pins [mptdc_o13_abs3_stage_pin_patterns $family $tap u_drv Q]]
        incr mptdc_o13_abs3_raw_pin_count [llength $raw_pins]
        incr mptdc_o13_abs3_iso_a_count [llength $iso_a_pins]
        incr mptdc_o13_abs3_iso_q_count [llength $iso_q_pins]
        incr mptdc_o13_abs3_drv_a_count [llength $drv_a_pins]
        incr mptdc_o13_abs3_drv_q_count [llength $drv_q_pins]
        if {[mptdc_o13_abs3_create_final_generated_clock $family $tap [lindex $raw_pins 0] [lindex $drv_q_pins 0]]} {
            incr mptdc_o13_abs3_generated_clock_count
        }
    }
}

set mptdc_o13_abs3_raw_clocks [mptdc_o13_abs3_clock_collection $mptdc_o13_abs3_raw_clock_names]
set mptdc_o13_abs3_buffer_clocks [mptdc_o13_abs3_clock_collection $mptdc_o13_abs3_buffer_clock_names]
set mptdc_o13_abs3_all_osc_clocks [concat $mptdc_o13_abs3_raw_clocks $mptdc_o13_abs3_buffer_clocks]
set mptdc_o13_abs3_clk_sys [get_clocks -quiet $design(CLK_NAME)]

if {[info exists design(OSC_ALL_CLOCKS)]} {
    set design(OSC_ALL_CLOCKS) [concat $design(OSC_ALL_CLOCKS) $mptdc_o13_abs3_buffer_clock_names]
}
set design(O13_BUFFER_PHASE_CLOCKS) $mptdc_o13_abs3_buffer_clock_names
set design(O13_SLOW_BUFFER_PHASE_CLOCKS) $mptdc_o13_abs3_slow_buffer_clock_names
set design(O13_FAST_BUFFER_PHASE_CLOCKS) $mptdc_o13_abs3_fast_buffer_clock_names

mptdc_o13_abs3_apply_clock_uncertainty [concat $mptdc_o13_abs3_raw_clock_names $mptdc_o13_abs3_buffer_clock_names]

set mptdc_o13_abs3_async_status NO
if {[llength $mptdc_o13_abs3_clk_sys] == 0} {
    error "MPTDC_O13_ABS3_SDC_FATAL: clk_sys clock was not found"
}
if {[llength $mptdc_o13_abs3_buffer_clocks] != 16} {
    error "MPTDC_O13_ABS3_SDC_FATAL: expected 16 final buffer clocks, found [llength $mptdc_o13_abs3_buffer_clocks]"
}
if {[llength $mptdc_o13_abs3_raw_clocks] != 16} {
    puts "MPTDC_O13_ABS3_SDC_WARN: expected 16 raw RO clocks, found [llength $mptdc_o13_abs3_raw_clocks]"
}
if {[catch {
    set_clock_groups -asynchronous \
        -group $mptdc_o13_abs3_clk_sys \
        -group $mptdc_o13_abs3_all_osc_clocks
} async_err]} {
    error "MPTDC_O13_ABS3_SDC_FATAL: failed to set clk_sys async to O13 oscillator clocks: $async_err"
} else {
    set mptdc_o13_abs3_async_status YES
}

puts "MPTDC_O13_ABS3_SDC_INFO: matched raw RO pins = $mptdc_o13_abs3_raw_pin_count"
puts "MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX4 iso A pins = $mptdc_o13_abs3_iso_a_count"
puts "MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX4 iso Q pins = $mptdc_o13_abs3_iso_q_count"
puts "MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX12 driver A pins = $mptdc_o13_abs3_drv_a_count"
puts "MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX12 driver Q pins = $mptdc_o13_abs3_drv_q_count"
puts "MPTDC_O13_ABS3_SDC_INFO: raw clock count = [llength $mptdc_o13_abs3_raw_clocks]"
puts "MPTDC_O13_ABS3_SDC_INFO: buffer slow clock count = [llength [mptdc_o13_abs3_clock_collection $mptdc_o13_abs3_slow_buffer_clock_names]]"
puts "MPTDC_O13_ABS3_SDC_INFO: buffer fast clock count = [llength [mptdc_o13_abs3_clock_collection $mptdc_o13_abs3_fast_buffer_clock_names]]"
puts "MPTDC_O13_ABS3_SDC_INFO: generated final-driver clocks = $mptdc_o13_abs3_generated_clock_count"
puts "MPTDC_O13_ABS3_SDC_INFO: oscillator clocks in async group = [llength $mptdc_o13_abs3_all_osc_clocks]"
puts "MPTDC_O13_ABS3_SDC_INFO: clk_sys async to raw+buffer oscillator clocks = $mptdc_o13_abs3_async_status"
puts "MPTDC_O13_ABS3_SDC_INFO: raw RO clocks remain analog load-check source clocks"
puts "MPTDC_O13_ABS3_SDC_INFO: BUJIHDX12 Q clocks are downstream digital phase-clock sources"
puts "MPTDC_O13_ABS3_SDC_INFO: phase-buffer chain and same-domain oscillator paths remain timed"
