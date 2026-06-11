# MPTDC block-level IO constraints for final-typical physical prototype.
#
# Labels: TYPICAL_ONLY, NOT_MMMC_SIGNOFF, NOT_FINAL_SILICON_SIGNOFF.
# This is a provisional block-level load model, not pad-level signoff.

if {![info exists ::env(MPTDC_PNR_IO_LOAD_CLASS)] || $::env(MPTDC_PNR_IO_LOAD_CLASS) eq ""} {
    set ::env(MPTDC_PNR_IO_LOAD_CLASS) medium
}

set mptdc_io_block_load_class $::env(MPTDC_PNR_IO_LOAD_CLASS)
switch -- $mptdc_io_block_load_class {
    light {
        set mptdc_io_block_output_load_pf 0.0128
    }
    medium {
        set mptdc_io_block_output_load_pf 0.0256
    }
    heavy {
        set mptdc_io_block_output_load_pf 0.0512
    }
    default {
        error "MPTDC_IO_BLOCK_CONSTRAINTS_FATAL: unsupported MPTDC_PNR_IO_LOAD_CLASS=$mptdc_io_block_load_class"
    }
}

set mptdc_io_block_output_load_ff [expr {$mptdc_io_block_output_load_pf * 1000.0}]
puts "MPTDC_IO_BLOCK_CONSTRAINTS: class=$mptdc_io_block_load_class load_pf=$mptdc_io_block_output_load_pf load_ff=$mptdc_io_block_output_load_ff non_pad_signoff=YES"

if {[llength [info commands all_outputs]] > 0 && [llength [info commands set_load]] > 0} {
    set mptdc_io_block_outputs [all_outputs]
    if {[llength $mptdc_io_block_outputs] > 0} {
        set_load $mptdc_io_block_output_load_pf $mptdc_io_block_outputs
    }
}
