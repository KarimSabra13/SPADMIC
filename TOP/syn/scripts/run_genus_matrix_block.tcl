# SPADMIC matrix-top OOC Genus block runner
# Status: server-facing typical-only feasibility script, not signoff.

proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    puts stderr "ERROR: required environment variable $name is not set"
    exit 2
  }
  return $::env($name)
}

proc run_report {cmd out_file {fatal 0}} {
  file mkdir [file dirname $out_file]
  # Genus report commands print to stdout. Use the tool/Tcl redirection form so
  # the file receives the actual report body, not only the Tcl return value.
  if {[catch {uplevel #0 "$cmd > $out_file"} result]} {
    set fh [open $out_file w]
    puts $fh "REPORT_COMMAND_FAILED: $cmd"
    puts $fh $result
    close $fh
    puts "WARN: report failed: $cmd"
    if {$fatal} {
      puts stderr "ERROR: fatal report/check failed: $cmd"
      exit 10
    }
    return 0
  }
  return 1
}

proc maybe_run_clock_report {from_clock to_clock out_file} {
  if {[llength [get_clocks $from_clock -quiet]] == 0} {
    return
  }
  if {[llength [get_clocks $to_clock -quiet]] == 0} {
    return
  }
  run_report "report_timing -from \[get_clocks $from_clock\] -to \[get_clocks $to_clock\] -max_paths 20" $out_file
}

proc maybe_run_unconstrained_clock_report {from_clock to_clock out_file} {
  if {[llength [get_clocks $from_clock -quiet]] == 0} {
    return
  }
  if {[llength [get_clocks $to_clock -quiet]] == 0} {
    return
  }
  run_report "report_timing -unconstrained -from \[get_clocks $from_clock\] -to \[get_clocks $to_clock\] -max_paths 20" $out_file
}

proc classify_reports {run_dir} {
  set out_file [file join $run_dir reports messages warning_classification.rpt]
  file mkdir [file dirname $out_file]
  set files [list]
  foreach rel {
    reports/elaboration/check_design_post_elab.rpt
    reports/timing/check_timing_intent.rpt
    reports/timing/report_timing_pre_synth.rpt
    reports/timing/report_timing_post_opt.rpt
    reports/qor/report_design_rules.rpt
    reports/messages/report_messages.rpt
  } {
    set file [file join $run_dir $rel]
    if {[file exists $file]} {
      lappend files $file
    }
  }
  array set patterns {
    unresolved              {unresolved reference[^s]|unresolved module[^s]|cannot resolve|not found}
    inferred_latch          {Latch inferred|inferred latch}
    no_clock_waveform       {no clock waveform|Unclocked source}
    missing_external_delay  {primary inputs have no clocked external delays|primary outputs have no clocked external delays}
    design_rule             {max.transition|max.cap|max.fanout|design rule}
    undriven                {undriven|unconnected|multiply driven|multi.?driven}
    tool_error              {(^|[^A-Za-z])Error[[:space:]]*:|\|[^|]+\|Error[[:space:]]*\|}
    tool_warning            {(^|[^A-Za-z])Warning[[:space:]]*:|\|[^|]+\|Warning[[:space:]]*\|}
  }
  set fh [open $out_file w]
  puts $fh "# Warning Classification"
  puts $fh ""
  puts $fh "Scope: curated report files only. Script echoes, library variable names, and raw stdout text are excluded to avoid false positives."
  puts $fh ""
  foreach key [lsort [array names patterns]] {
    set count 0
    set first ""
    foreach file $files {
      if {[catch {set in [open $file r]}]} {
        continue
      }
      while {[gets $in line] >= 0} {
        if {[regexp -nocase {no violations|No unresolved references|No empty modules|Unresolved References & Empty Modules|Undriven Port\(s\)/Pin\(s\)|Multidriven Port\(s\)/Pin\(s\)|Unloaded Pin\(s\), Port\(s\)|no unloaded port|^No .*undriven|^No .*unconnected|^No .*multiply driven|^No .*multi.?driven} $line]} {
          continue
        }
        if {[regexp -nocase $patterns($key) $line]} {
          incr count
          if {$first eq ""} {
            set first "[file tail $file]: $line"
          }
        }
      }
      close $in
    }
    puts $fh "$key count=$count"
    if {$first ne ""} {
      puts $fh "  first=$first"
    }
  }
  close $fh
}

set REPO_ROOT       [require_env SPADMIC_REPO_ROOT]
set TOP_ROOT        [require_env SPADMIC_TOP_ROOT]
set MPTDC_ROOT      [require_env SPADMIC_MPTDC_ROOT]
set RUN_DIR         [require_env GENUS_RUN_DIR]
set TOP_MODULE      [require_env GENUS_TOP_MODULE]
set BLOCK_NAME      [require_env GENUS_BLOCK_NAME]
set MPTDC_FILELIST  [require_env GENUS_MPTDC_FILELIST]
set TOP_FILELIST    [require_env GENUS_TOP_FILELIST]
set COMMON_SDC      [require_env GENUS_COMMON_SDC]

set REPORT_DIR [file join $RUN_DIR reports]
set OUT_DIR    [file join $RUN_DIR outputs]
set LOG_DIR    [file join $RUN_DIR logs]
file mkdir $REPORT_DIR $OUT_DIR $LOG_DIR
foreach subdir {elaboration timing qor messages} {
  file mkdir [file join $REPORT_DIR $subdir]
}

puts "================================================================"
puts "SPADMIC matrix-top OOC Genus"
puts "Block: $BLOCK_NAME"
puts "Top module: $TOP_MODULE"
puts "Constraint file: $COMMON_SDC"
puts "Run directory: $RUN_DIR"
puts "================================================================"

# Reuse the verified XH018 path discovery from the MPTDC collateral, but keep
# this run typical-only and separate from MPTDC signoff.
set design(project_root) $MPTDC_ROOT
source [file join $MPTDC_ROOT syn libraries libraries.xh018.tcl]
source [file join $MPTDC_ROOT syn libraries libraries.xh018-stdcells.tcl]

set spadmic_expected_stack "xx31"
if {[info exists ::env(SPADMIC_TOP_EXPECTED_XH018_STACK)] && $::env(SPADMIC_TOP_EXPECTED_XH018_STACK) ne ""} {
  set spadmic_expected_stack $::env(SPADMIC_TOP_EXPECTED_XH018_STACK)
}
set spadmic_expected_stdcell "JIHD"
if {[info exists ::env(SPADMIC_TOP_EXPECTED_STDCELL_FAMILY)] && $::env(SPADMIC_TOP_EXPECTED_STDCELL_FAMILY) ne ""} {
  set spadmic_expected_stdcell [string toupper $::env(SPADMIC_TOP_EXPECTED_STDCELL_FAMILY)]
}
if {![info exists tech(XH018_STACK)] || [string tolower $tech(XH018_STACK)] ne [string tolower $spadmic_expected_stack]} {
  puts stderr "ERROR: matrix-top Genus stack mismatch: got [expr {[info exists tech(XH018_STACK)] ? $tech(XH018_STACK) : {unset}}], expected $spadmic_expected_stack"
  exit 11
}
if {![info exists tech(STANDARD_CELL_FAMILY)] || [string toupper $tech(STANDARD_CELL_FAMILY)] ne $spadmic_expected_stdcell} {
  puts stderr "ERROR: matrix-top Genus stdcell mismatch: got [expr {[info exists tech(STANDARD_CELL_FAMILY)] ? $tech(STANDARD_CELL_FAMILY) : {unset}}], expected $spadmic_expected_stdcell"
  exit 12
}
puts "INFO: matrix-top stack aligned: XH018=$tech(XH018_STACK) stdcell=$tech(STANDARD_CELL_FAMILY) route_layers=$::env(MPTDC_PNR_ROUTE_LAYER_NAMES) signal_top=$::env(MPTDC_PNR_SIGNAL_TOP_LAYER)"

if {[info exists tech_files(ALL_TC_LIBS)] && [llength $tech_files(ALL_TC_LIBS)] > 0} {
  puts "INFO: reading typical Liberty files: $tech_files(ALL_TC_LIBS)"
  read_libs $tech_files(ALL_TC_LIBS)
} else {
  puts stderr "ERROR: no typical Liberty files were found"
  exit 3
}

if {[info exists tech_files(ALL_LEFS)] && [llength $tech_files(ALL_LEFS)] > 0} {
  set available_lefs [list]
  foreach lef $tech_files(ALL_LEFS) {
    if {[file exists $lef]} {
      lappend available_lefs $lef
    } else {
      puts "WARN: LEF missing, not loaded: $lef"
    }
  }
  if {[llength $available_lefs] > 0} {
    catch {read_physical -lef $available_lefs} lef_result
    puts "INFO: read_physical result: $lef_result"
  }
}

set_db hdl_language sv
set_db hdl_undriven_signal_value 0
set_db information_level 7

puts "INFO: reading MPTDC filelist $MPTDC_FILELIST"
read_hdl -sv -f $MPTDC_FILELIST
puts "INFO: reading TOP filelist $TOP_FILELIST"
read_hdl -sv -f $TOP_FILELIST

puts "INFO: elaborating $TOP_MODULE"
if {[catch {elaborate $TOP_MODULE} elab_err]} {
  set fh [open [file join $REPORT_DIR elaboration check_design_post_elab.rpt] w]
  puts $fh "ELABORATION_FAILED"
  puts $fh $elab_err
  close $fh
  puts stderr "ERROR: elaboration failed: $elab_err"
  exit 4
}

current_design $TOP_MODULE

puts "INFO: reading SDC $COMMON_SDC"
if {[catch {read_sdc $COMMON_SDC} sdc_err]} {
  puts stderr "ERROR: read_sdc failed: $sdc_err"
  exit 5
}

if {[catch {check_design -unresolved} unresolved_err]} {
  set fh [open [file join $REPORT_DIR elaboration check_design_post_elab.rpt] w]
  puts $fh "CHECK_DESIGN_UNRESOLVED_FAILED"
  puts $fh $unresolved_err
  close $fh
  puts stderr "ERROR: check_design -unresolved failed: $unresolved_err"
  exit 6
}

run_report {check_design -all} [file join $REPORT_DIR elaboration check_design_post_elab.rpt] 1
run_report {check_timing_intent -verbose} [file join $REPORT_DIR timing check_timing_intent.rpt]
run_report {report_clocks} [file join $REPORT_DIR timing report_clocks.rpt]
maybe_run_clock_report clk_sys clk_cfg_40m [file join $REPORT_DIR timing report_timing_clk_sys_to_clk_cfg_40m.rpt]
maybe_run_clock_report clk_cfg_40m clk_sys [file join $REPORT_DIR timing report_timing_clk_cfg_40m_to_clk_sys.rpt]
maybe_run_clock_report clk_sys clk_ref_40m [file join $REPORT_DIR timing report_timing_clk_sys_to_clk_ref_40m.rpt]
maybe_run_clock_report clk_ref_40m clk_sys [file join $REPORT_DIR timing report_timing_clk_ref_40m_to_clk_sys.rpt]
maybe_run_unconstrained_clock_report clk_sys clk_cfg_40m [file join $REPORT_DIR timing report_timing_unconstrained_clk_sys_to_clk_cfg_40m.rpt]
maybe_run_unconstrained_clock_report clk_cfg_40m clk_sys [file join $REPORT_DIR timing report_timing_unconstrained_clk_cfg_40m_to_clk_sys.rpt]
maybe_run_unconstrained_clock_report clk_sys clk_ref_40m [file join $REPORT_DIR timing report_timing_unconstrained_clk_sys_to_clk_ref_40m.rpt]
maybe_run_unconstrained_clock_report clk_ref_40m clk_sys [file join $REPORT_DIR timing report_timing_unconstrained_clk_ref_40m_to_clk_sys.rpt]
run_report {report_timing -max_paths 20} [file join $REPORT_DIR timing report_timing_pre_synth.rpt]

if {[catch {syn_generic} generic_err]} {
  puts stderr "ERROR: syn_generic failed: $generic_err"
  exit 7
}
run_report {report_timing -max_paths 20} [file join $REPORT_DIR timing report_timing_post_generic.rpt]

if {[catch {syn_map} map_err]} {
  puts stderr "ERROR: syn_map failed: $map_err"
  exit 8
}
run_report {report_timing -max_paths 20} [file join $REPORT_DIR timing report_timing_post_map.rpt]

if {[catch {syn_opt} opt_err]} {
  puts stderr "ERROR: syn_opt failed: $opt_err"
  exit 9
}
run_report {report_timing -max_paths 20} [file join $REPORT_DIR timing report_timing_post_opt.rpt]

run_report {report_qor} [file join $REPORT_DIR qor report_qor.rpt]
run_report {report_area} [file join $REPORT_DIR qor report_area.rpt]
# Genus 22.13 in the server environment rejects report_area -hierarchical
# with TUI-204. The default report_area output already includes hierarchy rows
# where hierarchy exists, so capture that format under the hierarchy filename
# instead of polluting the message database with an unsupported option.
run_report {report_area} [file join $REPORT_DIR qor report_area_hierarchy.rpt]
run_report {report_design_rules} [file join $REPORT_DIR qor report_design_rules.rpt]

if {[catch {write_hdl > [file join $OUT_DIR ${BLOCK_NAME}.postsyn.v]} write_hdl_err]} {
  puts "WARN: write_hdl failed: $write_hdl_err"
}
if {[catch {write_sdc > [file join $OUT_DIR ${BLOCK_NAME}.postsyn.sdc]} write_sdc_err]} {
  puts "WARN: write_sdc failed: $write_sdc_err"
}
if {[catch {write_sdf > [file join $OUT_DIR ${BLOCK_NAME}.postsyn.sdf]} write_sdf_err]} {
  puts "WARN: write_sdf failed: $write_sdf_err"
}

run_report {report_messages} [file join $REPORT_DIR messages report_messages.rpt]
classify_reports $RUN_DIR

set summary [open [file join $RUN_DIR SUMMARY.md] w]
puts $summary "# Genus OOC Block Summary"
puts $summary ""
puts $summary "- Block: `$BLOCK_NAME`"
puts $summary "- Top module: `$TOP_MODULE`"
puts $summary "- Constraint file: `$COMMON_SDC`"
puts $summary "- Run directory: `$RUN_DIR`"
puts $summary "- Status: completed tool flow; review reports before claiming closure"
puts $summary "- Signoff: non-signoff, typical-only feasibility"
puts $summary ""
puts $summary "## Required Reports"
foreach rel {
  reports/elaboration/check_design_post_elab.rpt
  reports/timing/check_timing_intent.rpt
  reports/timing/report_clocks.rpt
  reports/timing/report_timing_clk_sys_to_clk_cfg_40m.rpt
  reports/timing/report_timing_clk_cfg_40m_to_clk_sys.rpt
  reports/timing/report_timing_clk_sys_to_clk_ref_40m.rpt
  reports/timing/report_timing_clk_ref_40m_to_clk_sys.rpt
  reports/timing/report_timing_unconstrained_clk_sys_to_clk_cfg_40m.rpt
  reports/timing/report_timing_unconstrained_clk_cfg_40m_to_clk_sys.rpt
  reports/timing/report_timing_unconstrained_clk_sys_to_clk_ref_40m.rpt
  reports/timing/report_timing_unconstrained_clk_ref_40m_to_clk_sys.rpt
  reports/timing/report_timing_pre_synth.rpt
  reports/timing/report_timing_post_generic.rpt
  reports/timing/report_timing_post_map.rpt
  reports/timing/report_timing_post_opt.rpt
  reports/qor/report_qor.rpt
  reports/qor/report_area.rpt
  reports/qor/report_area_hierarchy.rpt
  reports/qor/report_design_rules.rpt
  reports/messages/report_messages.rpt
  reports/messages/warning_classification.rpt
} {
  if {[file exists [file join $RUN_DIR $rel]]} {
    puts $summary "- present: `$rel`"
  } else {
    puts $summary "- missing: `$rel`"
  }
}
close $summary

puts "INFO: completed $BLOCK_NAME"
exit 0
