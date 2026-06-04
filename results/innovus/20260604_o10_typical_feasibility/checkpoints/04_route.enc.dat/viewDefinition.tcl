if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name tc_libset\
   -timing\
    [list ${::IMEX::libVar}/mmmc/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib\
    ${::IMEX::libVar}/mmmc/RO_tune4_real_abstract_shell.lib]
create_rc_corner -name tc_rc\
   -cap_table ${::IMEX::libVar}/mmmc/xh018_xx41_MET4_METMID_typ.capTbl\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0
create_delay_corner -name tc_corner\
   -library_set tc_libset\
   -rc_corner tc_rc
create_constraint_mode -name functional_mode\
   -sdc_files\
    [list ${::IMEX::dataVar}/mmmc/modes/functional_mode/functional_mode.sdc]
create_analysis_view -name tc_view -constraint_mode functional_mode -delay_corner tc_corner -latency_file ${::IMEX::dataVar}/mmmc/views/tc_view/latency.sdc
set_analysis_view -setup [list tc_view] -hold [list tc_view]
