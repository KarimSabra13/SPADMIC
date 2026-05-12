# Compatibility entry point for launching the MPTDC Innovus estimate from
# MPTDC/syn/scripts after a Genus run.
source [file normalize [file join [file dirname [info script]] .. .. pnr scripts innovus_estimate.tcl]]
