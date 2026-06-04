# =============================================================================
# O10.1 Innovus-safe O9 R750/R700 delta-preserving oscillator overlay
# =============================================================================
# Typical feasibility only. Not MMMC signoff, not final silicon signoff, and
# not tapeout-ready. This overlay is self-contained for Innovus and must not
# rely on Genus-side design(...) Tcl variables.
# =============================================================================

puts "MPTDC_O10_1_SDC_INFO: loading Innovus-safe O9_R750_DELTA5 overlay"
puts "MPTDC_O10_1_SDC_INFO: labels = O10_INNOVUS_TYPICAL_FEASIBILITY NOT_MMMC_SIGNOFF NOT_FINAL_SIGNOFF"

set mptdc_o10_fast_period_typ_ns 1.333
set mptdc_o10_slow_period_typ_ns 1.430
set mptdc_o10_fast_tap_step_typ_ns 0.074
set mptdc_o10_slow_tap_step_typ_ns 0.079
set mptdc_o10_setup_uncertainty_ns 0.010
set mptdc_o10_hold_uncertainty_ns 0.005

proc mptdc_o10_sdc_get_pins {patterns} {
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

proc mptdc_o10_sdc_get_clock {name} {
    set clocks [list]
    catch {set clocks [get_clocks -quiet $name]}
    return $clocks
}

proc mptdc_o10_sdc_apply_uncertainty {clock_name} {
    global mptdc_o10_setup_uncertainty_ns mptdc_o10_hold_uncertainty_ns
    set clocks [mptdc_o10_sdc_get_clock $clock_name]
    if {[llength $clocks] == 0} {
        puts "MPTDC_O10_1_SDC_WARN: clock $clock_name not found for uncertainty"
        return 0
    }
    catch {set_clock_uncertainty -setup $mptdc_o10_setup_uncertainty_ns $clocks}
    catch {set_clock_uncertainty -hold  $mptdc_o10_hold_uncertainty_ns  $clocks}
    return 1
}

proc mptdc_o10_sdc_create_clock_if_missing {clock_name period pins} {
    set clocks [mptdc_o10_sdc_get_clock $clock_name]
    if {[llength $clocks] > 0} {
        puts "MPTDC_O10_1_SDC_INFO: existing clock $clock_name count = [llength $clocks]"
        return [llength $clocks]
    }
    if {[llength $pins] == 0} {
        puts "MPTDC_O10_1_SDC_WARN: cannot create $clock_name; no pins matched"
        return 0
    }
    if {[catch {create_clock -name $clock_name -period $period [lindex $pins 0]} err]} {
        puts "MPTDC_O10_1_SDC_WARN: create_clock $clock_name failed: $err"
        return 0
    }
    puts "MPTDC_O10_1_SDC_INFO: created clock $clock_name on [lindex $pins 0] period=$period"
    return 1
}

set mptdc_o10_slow_clock_names [list clk_osc_slow]
set mptdc_o10_fast_clock_names [list clk_osc_fast]
for {set i 1} {$i < 8} {incr i} {
    lappend mptdc_o10_slow_clock_names "clk_osc_slow_tap$i"
    lappend mptdc_o10_fast_clock_names "clk_osc_fast_tap$i"
}

set mptdc_o10_slow_pin_patterns [list \
    {u_core/u_osc_slow/u_ro_tune4/S[0]} \
    {u_core/u_osc_slow/u_ro_tune4/S[1]} \
    {u_core/u_osc_slow/u_ro_tune4/S[2]} \
    {u_core/u_osc_slow/u_ro_tune4/S[3]} \
    {u_core/u_osc_slow/u_ro_tune4/S[4]} \
    {u_core/u_osc_slow/u_ro_tune4/S[5]} \
    {u_core/u_osc_slow/u_ro_tune4/S[6]} \
    {u_core/u_osc_slow/u_ro_tune4/S[7]} \
    {u_core_u_osc_slow_u_ro_tune4/S[0]} \
    {u_core_u_osc_slow_u_ro_tune4/S[1]} \
    {u_core_u_osc_slow_u_ro_tune4/S[2]} \
    {u_core_u_osc_slow_u_ro_tune4/S[3]} \
    {u_core_u_osc_slow_u_ro_tune4/S[4]} \
    {u_core_u_osc_slow_u_ro_tune4/S[5]} \
    {u_core_u_osc_slow_u_ro_tune4/S[6]} \
    {u_core_u_osc_slow_u_ro_tune4/S[7]} \
]

set mptdc_o10_fast_pin_patterns [list \
    {u_core/u_osc_fast/u_ro_tune4/S[0]} \
    {u_core/u_osc_fast/u_ro_tune4/S[1]} \
    {u_core/u_osc_fast/u_ro_tune4/S[2]} \
    {u_core/u_osc_fast/u_ro_tune4/S[3]} \
    {u_core/u_osc_fast/u_ro_tune4/S[4]} \
    {u_core/u_osc_fast/u_ro_tune4/S[5]} \
    {u_core/u_osc_fast/u_ro_tune4/S[6]} \
    {u_core/u_osc_fast/u_ro_tune4/S[7]} \
    {u_core_u_osc_fast_u_ro_tune4/S[0]} \
    {u_core_u_osc_fast_u_ro_tune4/S[1]} \
    {u_core_u_osc_fast_u_ro_tune4/S[2]} \
    {u_core_u_osc_fast_u_ro_tune4/S[3]} \
    {u_core_u_osc_fast_u_ro_tune4/S[4]} \
    {u_core_u_osc_fast_u_ro_tune4/S[5]} \
    {u_core_u_osc_fast_u_ro_tune4/S[6]} \
    {u_core_u_osc_fast_u_ro_tune4/S[7]} \
]

set mptdc_o10_slow_pins [mptdc_o10_sdc_get_pins $mptdc_o10_slow_pin_patterns]
set mptdc_o10_fast_pins [mptdc_o10_sdc_get_pins $mptdc_o10_fast_pin_patterns]

puts "MPTDC_O10_1_SDC_INFO: matched slow RO_tune4 S pins = [llength $mptdc_o10_slow_pins]"
puts "MPTDC_O10_1_SDC_INFO: matched fast RO_tune4 S pins = [llength $mptdc_o10_fast_pins]"

for {set i 0} {$i < 8} {incr i} {
    set slow_clk [lindex $mptdc_o10_slow_clock_names $i]
    set fast_clk [lindex $mptdc_o10_fast_clock_names $i]
    set slow_pin [list]
    set fast_pin [list]
    if {[llength $mptdc_o10_slow_pins] > $i} { set slow_pin [list [lindex $mptdc_o10_slow_pins $i]] }
    if {[llength $mptdc_o10_fast_pins] > $i} { set fast_pin [list [lindex $mptdc_o10_fast_pins $i]] }
    mptdc_o10_sdc_create_clock_if_missing $slow_clk $mptdc_o10_slow_period_typ_ns $slow_pin
    mptdc_o10_sdc_create_clock_if_missing $fast_clk $mptdc_o10_fast_period_typ_ns $fast_pin
    mptdc_o10_sdc_apply_uncertainty $slow_clk
    mptdc_o10_sdc_apply_uncertainty $fast_clk
}

set mptdc_o10_ro_clock_count 0
foreach clk [concat $mptdc_o10_slow_clock_names $mptdc_o10_fast_clock_names] {
    if {[llength [mptdc_o10_sdc_get_clock $clk]] > 0} {
        incr mptdc_o10_ro_clock_count
    }
}
puts "MPTDC_O10_1_SDC_INFO: RO clock count after overlay = $mptdc_o10_ro_clock_count"
if {$mptdc_o10_ro_clock_count != 16} {
    puts "MPTDC_O10_1_SDC_WARN: expected 16 RO clocks in O9 R750_delta5 Innovus view"
}

puts "MPTDC_O10_1_SDC_INFO: fast period ns = $mptdc_o10_fast_period_typ_ns"
puts "MPTDC_O10_1_SDC_INFO: slow period ns = $mptdc_o10_slow_period_typ_ns"
puts "MPTDC_O10_1_SDC_INFO: fast tap step ns = $mptdc_o10_fast_tap_step_typ_ns"
puts "MPTDC_O10_1_SDC_INFO: slow tap step ns = $mptdc_o10_slow_tap_step_typ_ns"
puts "MPTDC_O10_1_SDC_INFO: setup uncertainty ns = $mptdc_o10_setup_uncertainty_ns"
puts "MPTDC_O10_1_SDC_INFO: hold uncertainty ns = $mptdc_o10_hold_uncertainty_ns"
