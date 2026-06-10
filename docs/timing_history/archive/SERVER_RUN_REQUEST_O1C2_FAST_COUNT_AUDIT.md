SERVER RUN REQUEST - O1C2 FAST COUNT AUDIT

Run ID:
  20260601_o1c2_fast_count_audit_genus

Git branch:
  SPADMIC_TOP

Expected HEAD:
  <COMMIT_SHA_AFTER_PUSHING_O1C2_PREP>

Purpose:
  Re-run Genus once after O1C macro binding with the O1C SDC cleanup and focused
  fast-counter to PD nfast_hit reports.  This is intended to make the expensive
  Genus run answer the next architecture question before Innovus, R800, or H4b.

Do not run:
  H4b backend timing
  O1B R800
  Innovus O1D

Commands:

  cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
  git checkout SPADMIC_TOP
  git pull --ff-only

  EXPECTED_HEAD=<COMMIT_SHA_AFTER_PUSHING_O1C2_PREP>
  ACTUAL_HEAD="$(git rev-parse HEAD)"
  test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

  git status --short
  git log --oneline -5

  bash MPTDC/syn/scripts/server_run_genus_o1c_macro_binding.sh 20260601_o1c2_fast_count_audit_genus

Expected output directory:

  results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/

Required result files:

  SUMMARY.md
  genus_20260601_o1c2_fast_count_audit_genus.log
  mptdc_top_asic.postsyn.v
  macro_binding_check.rpt
  report_clocks.rpt
  report_clock_groups.rpt
  report_exceptions.rpt
  check_timing_intent.rpt
  timing_summary.rpt
  timing_violations.rpt
  timing_fast_count_to_nfast_hit.rpt
  fast_count_capture_endpoint_audit.rpt
  fast_count_capture_paths.csv
  fast_count_capture_summary.md
  timing_path_classification.csv
  timing_path_classification_summary.md
  latch_audit.rpt
  cdc_manual_audit.rpt
  report_design_rules.rpt
  report_area.rpt
  report_qor.rpt

Commit/push after the run:

  git add -f \
    results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus \
    docs/timing_closure/osc_pd_iteration_log.md

  git commit -m "server-results: 20260601 O1C2 fast count audit Genus"
  git push

If Genus fails:

  Still commit/push the result directory with logs, partial reports, and
  SUMMARY.md.

Expected status:

  O1C_BINDING_STATUS=O1C_ARCH_VALID_BINDING_CANDIDATE
  O1C_SDC_CLEAN_STATUS=PASS

Decision after run:

  If fast-counter to nfast_hit remains around -3 ns and the report confirms it
  is same-cycle clk_osc_fast to fast tap capture, do not run Innovus for timing
  closure.  Move to an architecture decision on previous-count capture, Gray
  count, phase-local count staging, or an analog-approved derate.
