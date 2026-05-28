SERVER RUN REQUEST - O1C RO_TUNE4 MACRO BINDING

Run ID:
  20260528_o1c_macro_binding_genus

Git branch:
  SPADMIC_TOP

Expected HEAD:
  <AGENT_PROVIDED_SHA>

Purpose:
  Prove that Genus binds the two oscillator wrappers to real RO_tune4 macro
  instances using the real LEF and matching Liberty shell.  This is not Innovus,
  not R800, and not final oscillator signoff.

Do not run:
  H4b backend timing
  O1B R800
  Innovus O1D

Commands:

  cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
  git checkout SPADMIC_TOP
  git pull --ff-only

  EXPECTED_HEAD=<AGENT_PROVIDED_SHA>
  ACTUAL_HEAD="$(git rev-parse HEAD)"
  test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

  git status --short
  git log --oneline -5

  bash MPTDC/syn/scripts/server_run_genus_o1c_macro_binding.sh 20260528_o1c_macro_binding_genus

Expected output directory:

  results/genus_osc_pd/20260528_o1c_macro_binding_genus/

Required result files:

  SUMMARY.md
  genus_20260528_o1c_macro_binding_genus.log
  mptdc_top_asic.postsyn.v
  macro_binding_check.rpt
  report_clocks.rpt
  report_clock_groups.rpt
  report_exceptions.rpt
  check_timing_intent.rpt
  timing_summary.rpt
  timing_violations.rpt
  timing_path_classification.csv
  timing_path_classification_summary.md
  latch_audit.rpt
  cdc_manual_audit.rpt
  report_design_rules.rpt
  report_area.rpt
  report_qor.rpt

Commit/push after the run:

  git add -f \
    results/genus_osc_pd/20260528_o1c_macro_binding_genus \
    docs/timing_closure/O1C_macro_binding_audit.md \
    docs/timing_closure/O1C_fast_count_capture_analysis.md \
    docs/timing_closure/O1C_sdc_binding_notes.md \
    docs/timing_closure/osc_pd_iteration_log.md

  git commit -m "server-results: 20260528 O1C RO_tune4 macro binding Genus"
  git push

If Genus fails:

  Still commit/push the result directory with logs, partial reports, and
  SUMMARY.md.

Expected status:

  O1C_BINDING_STATUS=O1C_ARCH_VALID_BINDING_CANDIDATE

It becomes confirmed only after review shows:

  exactly two RO_tune4 instances
  old oscillator stubs are gone
  slow rstb is driven by osc_slow_en path
  fast rstb is driven by osc_fast_en path
  S[0:7] drive expected phase nets
  code[0:7] is intentionally connected
  generated clocks attach to RO_tune4/S[0:7]
