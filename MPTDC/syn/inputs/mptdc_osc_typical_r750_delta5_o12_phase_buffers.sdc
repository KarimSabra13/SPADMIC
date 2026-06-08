# =============================================================================
# O12 phase-isolation buffer overlay for R750_delta5 typical experiment
# =============================================================================
# Typical feasibility only. Not MMMC, not final signoff, and not a tapeout view.
# This overlay is loaded after mptdc.sdc.  It keeps the existing RO_tune4/S clocks
# as the analog source-pin load contract, then adds generated clocks at the
# matched phase-buffer outputs for downstream digital timing review.
# =============================================================================

puts "MPTDC_O12_SDC_INFO: loading O12_PHASE_ISOLATION_BUFFER_EXPERIMENT overlay"
puts "MPTDC_O12_SDC_INFO: signoff status = TYPICAL_ONLY_NOT_MMMC_NOT_FINAL_SIGNOFF"
puts "MPTDC_O12_SDC_INFO: expected RTL defines = MPTDC_FREQ_R750_DELTA5 + MPTDC_PHASE_BUFFER_USE_BUHDX4"

set mptdc_o12_fast_period_typ_ns 1.333
set mptdc_o12_slow_period_typ_ns 1.430
set mptdc_o12_setup_uncertainty_ns 0.010
set mptdc_o12_hold_uncertainty_ns 0.005

proc mptdc_o12_try_get_pins {patterns} {
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

proc mptdc_o12_clock_names {family} {
    set names [list "clk_osc_${family}"]
    for {set tap 1} {$tap < 8} {incr tap} {
        lappend names "clk_osc_${family}_tap${tap}"
    }
    return $names
}

proc mptdc_o12_raw_pin_patterns {family tap} {
    return [list \
        [format {u_core/u_osc_%s/u_ro_tune4/S[%d]} $family $tap] \
        [format {u_core_u_osc_%s_u_ro_tune4/S[%d]} $family $tap]]
}

proc mptdc_o12_buf_pin_patterns {family tap pin} {
    return [list \
        [format {u_core/u_phase_buf_%s/gen_phase_buf[%d]/u_buf/%s} $family $tap $pin] \
        [format {u_core_u_phase_buf_%s_gen_phase_buf_%d__u_buf/%s} $family $tap $pin] \
        [format {*u_phase_buf_%s*gen_phase_buf*%d*u_buf/%s} $family $tap $pin]]
}

proc mptdc_o12_apply_clock_uncertainty {clock_name} {
    global mptdc_o12_setup_uncertainty_ns mptdc_o12_hold_uncertainty_ns
    set clocks [get_clocks -quiet $clock_name]
    if {[llength $clocks] == 0} {
        puts "MPTDC_O12_SDC_WARN: clock $clock_name not found for uncertainty"
        return
    }
    catch {set_clock_uncertainty -setup $mptdc_o12_setup_uncertainty_ns $clocks}
    catch {set_clock_uncertainty -hold  $mptdc_o12_hold_uncertainty_ns  $clocks}
}

proc mptdc_o12_create_buffer_generated_clock {family tap raw_pin buf_q_pin} {
    set raw_clock [lindex [mptdc_o12_clock_names $family] $tap]
    set buf_clock [format {clk_osc_%s_buf_tap%d} $family $tap]
    if {[llength [get_clocks -quiet $buf_clock]] > 0} {
        puts "MPTDC_O12_SDC_INFO: existing generated clock $buf_clock"
        mptdc_o12_apply_clock_uncertainty $buf_clock
        return 1
    }
    if {$raw_pin eq "" || $buf_q_pin eq ""} {
        puts "MPTDC_O12_SDC_WARN: cannot create $buf_clock; raw_pin='$raw_pin' buf_q_pin='$buf_q_pin'"
        return 0
    }
    if {[catch {create_generated_clock -name $buf_clock -source $raw_pin -divide_by 1 $buf_q_pin} err]} {
        puts "MPTDC_O12_SDC_WARN: create_generated_clock $buf_clock failed: $err"
        return 0
    }
    mptdc_o12_apply_clock_uncertainty $raw_clock
    mptdc_o12_apply_clock_uncertainty $buf_clock
    puts "MPTDC_O12_SDC_INFO: created $buf_clock from $raw_pin to $buf_q_pin"
    return 1
}

set mptdc_o12_raw_pin_count 0
set mptdc_o12_buf_a_count 0
set mptdc_o12_buf_q_count 0
set mptdc_o12_generated_clock_count 0

foreach family {slow fast} {
    for {set tap 0} {$tap < 8} {incr tap} {
        set raw_pins [mptdc_o12_try_get_pins [mptdc_o12_raw_pin_patterns $family $tap]]
        set buf_a_pins [mptdc_o12_try_get_pins [mptdc_o12_buf_pin_patterns $family $tap A]]
        set buf_q_pins [mptdc_o12_try_get_pins [mptdc_o12_buf_pin_patterns $family $tap Q]]
        incr mptdc_o12_raw_pin_count [llength $raw_pins]
        incr mptdc_o12_buf_a_count [llength $buf_a_pins]
        incr mptdc_o12_buf_q_count [llength $buf_q_pins]
        if {[mptdc_o12_create_buffer_generated_clock $family $tap [lindex $raw_pins 0] [lindex $buf_q_pins 0]]} {
            incr mptdc_o12_generated_clock_count
        }
    }
}

puts "MPTDC_O12_SDC_INFO: matched raw RO pins = $mptdc_o12_raw_pin_count"
puts "MPTDC_O12_SDC_INFO: matched phase buffer input pins = $mptdc_o12_buf_a_count"
puts "MPTDC_O12_SDC_INFO: matched phase buffer output pins = $mptdc_o12_buf_q_count"
puts "MPTDC_O12_SDC_INFO: generated buffer clocks = $mptdc_o12_generated_clock_count"
if {$mptdc_o12_raw_pin_count != 16 || $mptdc_o12_buf_a_count != 16 || $mptdc_o12_buf_q_count != 16 || $mptdc_o12_generated_clock_count != 16} {
    puts "MPTDC_O12_SDC_WARN: expected 16 raw pins, 16 buffer input pins, 16 buffer output pins, and 16 generated clocks"
}

puts "MPTDC_O12_SDC_INFO: RO S pins remain the analog load-check source pins"
puts "MPTDC_O12_SDC_INFO: buffer Q pins are the downstream digital phase-clock sources"
puts "MPTDC_O12_SDC_INFO: no broad oscillator-domain false paths added"
