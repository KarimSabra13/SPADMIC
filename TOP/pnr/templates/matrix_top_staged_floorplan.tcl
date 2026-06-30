# SPADMIC matrix-top staged floorplan seed
# Status: planning/import preparation only.  This template does not run place,
# route, CTS, DRC/LVS, PG signoff, extraction, or final timing.

set run_root $::env(SPADMIC_INNOVUS_RUN_ROOT)
set matrix_lef $::env(SPADMIC_MATRIX_LEF)
set top_regions_tcl $::env(SPADMIC_MATRIX_TOP_REGIONS_TCL)

puts "SPADMIC_INNOVUS_INFO: run_root=$run_root"
puts "SPADMIC_INNOVUS_INFO: matrix_lef=$matrix_lef"
puts "SPADMIC_INNOVUS_INFO: top_regions_tcl=$top_regions_tcl"

file mkdir [file join $run_root reports]
file mkdir [file join $run_root logs]

set summary [open [file join $run_root SUMMARY.md] a]
puts $summary ""
puts $summary "## Innovus Staged Floorplan Seed"
puts $summary ""

if {![file exists $matrix_lef]} {
  puts $summary "- Matrix LEF: MISSING `$matrix_lef`"
  close $summary
  error "matrix LEF missing: $matrix_lef"
}
puts $summary "- Matrix LEF: present `$matrix_lef`"

if {![file exists $top_regions_tcl]} {
  puts $summary "- Top region Tcl: MISSING `$top_regions_tcl`"
  close $summary
  error "top region Tcl missing: $top_regions_tcl"
}
puts $summary "- Top region Tcl: present `$top_regions_tcl`"
close $summary

source $top_regions_tcl

set region_rpt [open [file join $run_root reports matrix_top_floorplan_regions_from_innovus.rpt] w]
puts $region_rpt "SPADMIC matrix top staged floorplan planning regions"
puts $region_rpt "status=$spadmic_matrix_top_fp::status"
puts $region_rpt "issues=$spadmic_matrix_top_fp::issue_list"
foreach name [lsort [array names spadmic_matrix_top_fp::regions]] {
  puts $region_rpt "$name $spadmic_matrix_top_fp::regions($name)"
}
close $region_rpt

set status_rpt [open [file join $run_root reports matrix_top_floorplan_status.rpt] w]
puts $status_rpt "STATUS=$spadmic_matrix_top_fp::status"
puts $status_rpt "ISSUES=$spadmic_matrix_top_fp::issue_list"
puts $status_rpt "DIE_WIDTH_UM=$spadmic_matrix_top_fp::die_width_um"
puts $status_rpt "DIE_HEIGHT_UM=$spadmic_matrix_top_fp::die_height_um"
puts $status_rpt "PAD_KEEPOUT_UM=$spadmic_matrix_top_fp::pad_keepout_um"
puts $status_rpt "MPTDC_AREA_UM2=$spadmic_matrix_top_fp::mptdc_area_um2"
puts $status_rpt "MPTDC_ASPECT_RATIO=$spadmic_matrix_top_fp::mptdc_aspect_ratio"
puts $status_rpt "MPTDC_AXIS_ORDER=$spadmic_matrix_top_fp::mptdc_axis_order"
puts $status_rpt "SIGNOFF=NO"
close $status_rpt

if {$spadmic_matrix_top_fp::status ne "PASS"} {
  error "SPADMIC_MATRIX_TOP_FLOORPLAN_INFEASIBLE: $spadmic_matrix_top_fp::issue_list"
}

puts "SPADMIC_INNOVUS_INFO: staged floorplan plan completed. No init_design/place/route/signoff was run by this seed."
