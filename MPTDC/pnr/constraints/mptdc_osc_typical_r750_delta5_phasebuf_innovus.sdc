# =============================================================================
# O12C phase-buffer Innovus oscillator overlay
# =============================================================================
# This is a feasibility/closure overlay, not signoff.  It preserves the O12
# clock model: RO_tune4/S pins are analog source points, and generated clocks at
# phase-buffer outputs model the downstream digital phase clocks.
# =============================================================================

puts "MPTDC_O12C_INNOVUS_SDC_INFO: loading O12C_PHASE_BUFFER_TOPOLOGY_AND_PLACEMENT_CLOSURE overlay"
puts "MPTDC_O12C_INNOVUS_SDC_INFO: labels = O12C_PHASE_BUFFER_TOPOLOGY_AND_PLACEMENT_CLOSURE TYPICAL_ONLY NOT_FINAL_SIGNOFF"

set mptdc_o12c_overlay_dir [file dirname [file normalize [info script]]]
set mptdc_o12c_o12_overlay "$mptdc_o12c_overlay_dir/mptdc_osc_typical_r750_delta5_o12_phase_buffers_innovus.sdc"

if {![file exists $mptdc_o12c_o12_overlay]} {
    puts "MPTDC_O12C_INNOVUS_SDC_ERROR: missing base O12 phase-buffer overlay: $mptdc_o12c_o12_overlay"
} else {
    source $mptdc_o12c_o12_overlay
}

puts "MPTDC_O12C_INNOVUS_SDC_INFO: phase-buffer delays are visible through generated clocks; no broad false path added"
puts "MPTDC_O12C_INNOVUS_SDC_INFO: do not send RO or buffered phase clocks through normal CTS"
