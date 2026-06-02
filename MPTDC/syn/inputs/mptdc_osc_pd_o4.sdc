# =============================================================================
# O4 muxless tags + R600 what-if oscillator/PD overlay
# =============================================================================
# REAL PHYSICAL LEF AVAILABLE, LIBERTY SHELL ONLY.
#
# This overlay is loaded after mptdc.sdc for O4. It keeps the O1C RO_tune4
# clock binding model, reports the local-tag/slow-Johnson hierarchy, and does
# not add broad exceptions. R600 is selected only by environment overrides in
# mptdc.defines; this file intentionally has no hidden frequency change.
# =============================================================================

proc mptdc_o4_try_get_pins {patterns} {
    set pins [list]
    foreach pattern $patterns {
        set found [get_pins -quiet -hierarchical $pattern]
        if {[llength $found] > 0} {
            set pins [concat $pins $found]
        }
    }
    return $pins
}

puts "MPTDC_O4_SDC_INFO: loading muxless-tags/R600 overlay"
set mptdc_o4_timing_mode "nominal"
if {[info exists ::env(O4_TIMING_MODE)] && $::env(O4_TIMING_MODE) ne ""} {
    set mptdc_o4_timing_mode $::env(O4_TIMING_MODE)
}
puts "MPTDC_O4_SDC_INFO: run flavor = $mptdc_o4_timing_mode"
puts "MPTDC_O4_SDC_INFO: slow period ns = $design(OSC_SLOW_PERIOD)"
puts "MPTDC_O4_SDC_INFO: fast period ns = $design(OSC_FAST_PERIOD)"
puts "MPTDC_O4_SDC_INFO: slow tap step ns = $design(OSC_SLOW_TAP_STEP)"
puts "MPTDC_O4_SDC_INFO: fast tap step ns = $design(OSC_FAST_TAP_STEP)"

set mptdc_o4_slow_pins [mptdc_o4_try_get_pins [list \
    {u_core/u_osc_slow/u_ro_tune4/S[0]} \
    {u_core/u_osc_slow/u_ro_tune4/S[1]} \
    {u_core/u_osc_slow/u_ro_tune4/S[2]} \
    {u_core/u_osc_slow/u_ro_tune4/S[3]} \
    {u_core/u_osc_slow/u_ro_tune4/S[4]} \
    {u_core/u_osc_slow/u_ro_tune4/S[5]} \
    {u_core/u_osc_slow/u_ro_tune4/S[6]} \
    {u_core/u_osc_slow/u_ro_tune4/S[7]} \
]]

set mptdc_o4_fast_pins [mptdc_o4_try_get_pins [list \
    {u_core/u_osc_fast/u_ro_tune4/S[0]} \
    {u_core/u_osc_fast/u_ro_tune4/S[1]} \
    {u_core/u_osc_fast/u_ro_tune4/S[2]} \
    {u_core/u_osc_fast/u_ro_tune4/S[3]} \
    {u_core/u_osc_fast/u_ro_tune4/S[4]} \
    {u_core/u_osc_fast/u_ro_tune4/S[5]} \
    {u_core/u_osc_fast/u_ro_tune4/S[6]} \
    {u_core/u_osc_fast/u_ro_tune4/S[7]} \
]]

puts "MPTDC_O4_SDC_INFO: matched slow RO_tune4 S pins = [llength $mptdc_o4_slow_pins]"
puts "MPTDC_O4_SDC_INFO: matched fast RO_tune4 S pins = [llength $mptdc_o4_fast_pins]"
if {[llength $mptdc_o4_slow_pins] != 8 || [llength $mptdc_o4_fast_pins] != 8} {
    puts "MPTDC_O4_SDC_WARN: expected 8 slow and 8 fast RO_tune4 S pins"
}

set mptdc_o4_pd_cells [get_cells -quiet -hierarchical *gen_pd_row*gen_pd_col*u_pd*]
set mptdc_o4_fast_tags [get_cells -quiet -hierarchical *gen_fast_tag_col*u_fast_tag*]
set mptdc_o4_slow_epoch [get_cells -quiet -hierarchical *u_slow_epoch*]
set mptdc_o4_stop_epoch [get_cells -quiet -hierarchical *u_stop_epoch_capture*]
set mptdc_o4_old_slow [get_cells -quiet -hierarchical *u_slow_cnt*]
set mptdc_o4_old_fast [get_cells -quiet -hierarchical *u_fast_cnt*]
set mptdc_o4_bridge [get_cells -quiet -hierarchical *u_hit_capture_bridge*]

puts "MPTDC_O4_SDC_INFO: matched PD cells = [llength $mptdc_o4_pd_cells]"
puts "MPTDC_O4_SDC_INFO: matched fast local tags = [llength $mptdc_o4_fast_tags]"
puts "MPTDC_O4_SDC_INFO: matched slow Johnson epoch cells = [llength $mptdc_o4_slow_epoch]"
puts "MPTDC_O4_SDC_INFO: matched STOP epoch capture cells = [llength $mptdc_o4_stop_epoch]"
puts "MPTDC_O4_SDC_INFO: old u_slow_cnt cells = [llength $mptdc_o4_old_slow]"
puts "MPTDC_O4_SDC_INFO: old u_fast_cnt cells = [llength $mptdc_o4_old_fast]"
puts "MPTDC_O4_SDC_INFO: matched hit-capture bridge cells = [llength $mptdc_o4_bridge]"

puts "MPTDC_O4_SDC_INFO: no O4 clk_sys exceptions added"
puts "MPTDC_O4_SDC_INFO: no O4 broad oscillator-domain false paths added"
