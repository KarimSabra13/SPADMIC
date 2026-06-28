# SPADMIC matrix-top Innovus floorplan seed
# Status: feasibility/planning seed, not routed signoff.

set run_root $::env(SPADMIC_INNOVUS_RUN_ROOT)
set matrix_lef $::env(SPADMIC_MATRIX_LEF)
set regions_tcl $::env(SPADMIC_MATRIX_REGIONS_TCL)

puts "SPADMIC_INNOVUS_INFO: run_root=$run_root"
puts "SPADMIC_INNOVUS_INFO: matrix_lef=$matrix_lef"
puts "SPADMIC_INNOVUS_INFO: regions_tcl=$regions_tcl"

file mkdir [file join $run_root reports]
file mkdir [file join $run_root logs]

set summary [open [file join $run_root SUMMARY.md] a]
puts $summary ""
puts $summary "## Innovus Floorplan Seed"
puts $summary ""

if {![file exists $matrix_lef]} {
  puts $summary "- Matrix LEF: MISSING `$matrix_lef`"
  close $summary
  error "matrix LEF missing: $matrix_lef"
}
puts $summary "- Matrix LEF: present `$matrix_lef`"

if {![file exists $regions_tcl]} {
  puts $summary "- Region Tcl: MISSING `$regions_tcl`"
  close $summary
  error "region Tcl missing: $regions_tcl"
}
puts $summary "- Region Tcl: present `$regions_tcl`"
close $summary

source $regions_tcl

set rpt [open [file join $run_root reports matrix_floorplan_regions_from_innovus.rpt] w]
puts $rpt "SPADMIC matrix top floorplan planning regions"
foreach name [lsort [array names spadmic_matrix_fp::regions]] {
  puts $rpt "$name $spadmic_matrix_fp::regions($name)"
}
close $rpt

puts "SPADMIC_INNOVUS_INFO: planning seed completed. No init_design/place/route/signoff was run by this seed."

