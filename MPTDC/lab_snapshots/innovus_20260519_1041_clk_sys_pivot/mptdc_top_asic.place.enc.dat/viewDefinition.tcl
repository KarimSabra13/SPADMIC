if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name bc_libset\
   -timing\
    [list ${::IMEX::libVar}/mmmc/D_CELLS_HD_LPMOS_fast_1_98V_m40C.lib]
create_library_set -name wc_libset\
   -timing\
    [list ${::IMEX::libVar}/mmmc/D_CELLS_HD_LPMOS_slow_1_62V_125C.lib]
create_library_set -name tc_libset\
   -timing\
    [list ${::IMEX::libVar}/mmmc/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib]
create_rc_corner -name wc_rc\
   -cap_table ${::IMEX::libVar}/mmmc/xh018_xx41_MET4_METMID_max.capTbl\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0
create_rc_corner -name tc_rc\
   -cap_table ${::IMEX::libVar}/mmmc/xh018_xx41_MET4_METMID_typ.capTbl\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0
create_rc_corner -name bc_rc\
   -cap_table ${::IMEX::libVar}/mmmc/xh018_xx41_MET4_METMID_min.capTbl\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0
create_delay_corner -name wc_corner\
   -library_set wc_libset\
   -rc_corner wc_rc
create_delay_corner -name tc_corner\
   -library_set tc_libset\
   -rc_corner tc_rc
create_delay_corner -name bc_corner\
   -library_set bc_libset\
   -rc_corner bc_rc
create_constraint_mode -name functional_mode\
   -sdc_files\
    [list ${::IMEX::dataVar}/mmmc/modes/functional_mode/functional_mode.sdc]
create_analysis_view -name tc_view -constraint_mode functional_mode -delay_corner tc_corner
create_analysis_view -name wc_view -constraint_mode functional_mode -delay_corner wc_corner -latency_file ${::IMEX::dataVar}/mmmc/views/wc_view/latency.sdc
create_analysis_view -name bc_view -constraint_mode functional_mode -delay_corner bc_corner -latency_file ${::IMEX::dataVar}/mmmc/views/bc_view/latency.sdc
set_analysis_view -setup [list wc_view] -hold [list bc_view]
