# Compatibility entry point for reviewed OOC block synthesis.
#
# The maintained Genus implementation is TOP/syn/scripts/run_genus_matrix_block.tcl.
# Use TOP/syn/scripts/run_genus_ooc_block.sh for normal server runs; it sets the
# required environment and calls the maintained Tcl through the multi-block
# wrapper with a one-block override.

source [file join [file dirname [info script]] run_genus_matrix_block.tcl]
