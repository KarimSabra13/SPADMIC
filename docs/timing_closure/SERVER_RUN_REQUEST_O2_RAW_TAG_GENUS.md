SERVER RUN REQUEST - O2 RAW TAG GENUS

Run ID:
  20260601_o2_raw_tag_genus

Git branch:
  SPADMIC_localtag

Expected HEAD:
  <fill after commit>

Purpose:
  Check that O2 raw local fast-tag RTL removes the impossible global binary fast-count-to-PD path without adding RTL decode timing.

Prerequisites:
  - Local Verilator lint/smoke pass.
  - Python raw-tag decoder tests pass.
  - O2 raw-tag characterization smoke passes.
  - Preferably, `SERVER_RUN_REQUEST_O2_RAW_TAG_OVERNIGHT_CHARAC.md` has passed or produced reviewable evidence.

Do not run:
  Innovus, R800, H4b, or cell-sizing from this request.

Commands:

  cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
  git checkout SPADMIC_localtag
  git pull --ff-only

  EXPECTED_HEAD=<fill after commit>
  ACTUAL_HEAD="$(git rev-parse HEAD)"
  test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

  git status --short
  git log --oneline -5

  bash MPTDC/syn/scripts/server_run_genus_o2_raw_tag.sh 20260601_o2_raw_tag_genus

Expected output directory:

  results/genus_osc_pd/20260601_o2_raw_tag_genus/

Key files:

  SUMMARY.md
  genus_20260601_o2_raw_tag_genus.log
  mptdc_top_asic.postsyn.v
  o2_raw_tag_check.rpt
  timing_summary.rpt
  timing_violations.rpt
  timing_path_classification.csv
  timing_path_classification_summary.md
  report_clocks.rpt
  report_clock_groups.rpt
  report_exceptions.rpt
  check_timing_intent.rpt
  report_design_rules.rpt
  latch_audit.rpt
  cdc_manual_audit.rpt
  report_area.rpt
  report_qor.rpt

Questions this run must answer:

  - Does the post-synthesis netlist still contain exactly two `RO_tune4` instances?
  - Are old oscillator stubs absent?
  - Is `u_fast_cnt` absent from the PD capture path?
  - Is global `nfast_src_count` no longer feeding 64 PD cells?
  - Are the new fast paths local tag-generator paths only?
  - Is there zero RTL tag-decode residue in the netlist?
  - Does `OSC_FAST_REAL` improve materially?
  - Are there no new `UNKNOWN_REVIEW_REQUIRED` path classes?

Files to commit/push after run:

  git add -f \
    results/genus_osc_pd/20260601_o2_raw_tag_genus \
    docs/timing_closure/osc_pd_iteration_log.md

  git commit -m "server-results: 20260601 O2 raw-tag Genus"
  git push

If run fails, still commit/push:

  - `SUMMARY.md`
  - Genus log
  - partial netlist/report files
  - `o2_raw_tag_check.rpt`
