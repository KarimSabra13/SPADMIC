# =============================================================================
# O3 raw epoch / PD capture cleanup oscillator/PD overlay
# =============================================================================
# REAL PHYSICAL LEF AVAILABLE, LIBERTY SHELL ONLY.
#
# This overlay is loaded after mptdc.sdc for the O3 Genus experiment. It keeps
# the O1C RO_tune4 clock binding model and adds report-only hierarchy checks for
# the O3 measurement-fabric cleanup. It intentionally does not add broad false
# paths and does not hide real clk_sys or oscillator-domain logic.
# =============================================================================

proc mptdc_o3_try_get_pins {patterns} {
    set pins [list]
    foreach pattern $patterns {
        set found [get_pins -quiet -hierarchical $pattern]
        if {[llength $found] > 0} {
            set pins [concat $pins $found]
        }
    }
    return $pins
}

puts "MPTDC_O3_SDC_INFO: loading raw epoch / PD capture cleanup overlay"
puts "MPTDC_O3_SDC_INFO: slow period ns = $design(OSC_SLOW_PERIOD)"
puts "MPTDC_O3_SDC_INFO: fast period ns = $design(OSC_FAST_PERIOD)"
puts "MPTDC_O3_SDC_INFO: slow tap step ns = $design(OSC_SLOW_TAP_STEP)"
puts "MPTDC_O3_SDC_INFO: fast tap step ns = $design(OSC_FAST_TAP_STEP)"

set mptdc_o3_slow_pins [mptdc_o3_try_get_pins [list \
    {u_core/u_osc_slow/u_ro_tune4/S[0]} \
    {u_core/u_osc_slow/u_ro_tune4/S[1]} \
    {u_core/u_osc_slow/u_ro_tune4/S[2]} \
    {u_core/u_osc_slow/u_ro_tune4/S[3]} \
    {u_core/u_osc_slow/u_ro_tune4/S[4]} \
    {u_core/u_osc_slow/u_ro_tune4/S[5]} \
    {u_core/u_osc_slow/u_ro_tune4/S[6]} \
    {u_core/u_osc_slow/u_ro_tune4/S[7]} \
]]

set mptdc_o3_fast_pins [mptdc_o3_try_get_pins [list \
    {u_core/u_osc_fast/u_ro_tune4/S[0]} \
    {u_core/u_osc_fast/u_ro_tune4/S[1]} \
    {u_core/u_osc_fast/u_ro_tune4/S[2]} \
    {u_core/u_osc_fast/u_ro_tune4/S[3]} \
    {u_core/u_osc_fast/u_ro_tune4/S[4]} \
    {u_core/u_osc_fast/u_ro_tune4/S[5]} \
    {u_core/u_osc_fast/u_ro_tune4/S[6]} \
    {u_core/u_osc_fast/u_ro_tune4/S[7]} \
]]

puts "MPTDC_O3_SDC_INFO: matched slow RO_tune4 S pins = [llength $mptdc_o3_slow_pins]"
puts "MPTDC_O3_SDC_INFO: matched fast RO_tune4 S pins = [llength $mptdc_o3_fast_pins]"
if {[llength $mptdc_o3_slow_pins] != 8 || [llength $mptdc_o3_fast_pins] != 8} {
    puts "MPTDC_O3_SDC_WARN: expected 8 slow and 8 fast RO_tune4 S pins"
}

set mptdc_o3_pd_cells [get_cells -quiet -hierarchical *gen_pd_row*gen_pd_col*u_pd*]
set mptdc_o3_fast_tags [get_cells -quiet -hierarchical *gen_fast_tag_col*u_fast_tag*]
set mptdc_o3_slow_epoch [get_cells -quiet -hierarchical *u_slow_epoch*]
set mptdc_o3_stop_epoch [get_cells -quiet -hierarchical *u_stop_epoch_capture*]
set mptdc_o3_old_slow [get_cells -quiet -hierarchical *u_slow_cnt*]
set mptdc_o3_old_fast [get_cells -quiet -hierarchical *u_fast_cnt*]
set mptdc_o3_bridge [get_cells -quiet -hierarchical *u_hit_capture_bridge*]

puts "MPTDC_O3_SDC_INFO: matched PD cells = [llength $mptdc_o3_pd_cells]"
puts "MPTDC_O3_SDC_INFO: matched fast local tags = [llength $mptdc_o3_fast_tags]"
puts "MPTDC_O3_SDC_INFO: matched slow Johnson epoch cells = [llength $mptdc_o3_slow_epoch]"
puts "MPTDC_O3_SDC_INFO: matched STOP epoch capture cells = [llength $mptdc_o3_stop_epoch]"
puts "MPTDC_O3_SDC_INFO: old u_slow_cnt cells = [llength $mptdc_o3_old_slow]"
puts "MPTDC_O3_SDC_INFO: old u_fast_cnt cells = [llength $mptdc_o3_old_fast]"
puts "MPTDC_O3_SDC_INFO: matched hit-capture bridge cells = [llength $mptdc_o3_bridge]"

puts "MPTDC_O3_SDC_INFO: no O3 clk_sys exceptions added"
puts "MPTDC_O3_SDC_INFO: no O3 broad oscillator-domain false paths added"
