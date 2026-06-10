SERVER RUN REQUEST - O2 RAW TAG OVERNIGHT CHARACTERIZATION

Run ID:
  20260601_o2_raw_tag_overnight_charac

Git branch:
  SPADMIC_localtag

Expected HEAD:
  <fill after commit>

Purpose:
  Validate O2 raw-tag packet semantics and software decode before spending a Genus license run.

Do not run:
  Genus, Innovus, R800, H4b, or cell-sizing experiments from this request.

Commands:

  cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
  git checkout SPADMIC_localtag
  git pull --ff-only

  EXPECTED_HEAD=<fill after commit>
  ACTUAL_HEAD="$(git rev-parse HEAD)"
  test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

  git status --short
  git log --oneline -5

  python3 tools/mptdc_decode/test_fast_tag_decode.py
  python3 MPTDC/scripts/analysis/o2_raw_tag_charac_smoke.py --run-id 20260601_o2_raw_tag_charac_smoke_server

  # Step 1: cheap characterization smoke after the campaign-collector O2 fix.
  bash MPTDC/scripts/sim/run_vip_overnight.sh \
    --sim xcelium \
    --stages char \
    --smoke \
    --jobs 8 \
    --out-dir results/o2_raw_tag/20260601_o2_raw_tag_char_smoke_retry \
    --char-nfast-encoding raw_lfsr_tag \
    --rerun-char \
    --clean

  # Step 2: full run. If the earlier VIP stage already passed, run char only
  # against the original output root so the completed VIP evidence is retained.
  bash MPTDC/scripts/sim/run_vip_overnight.sh \
    --sim xcelium \
    --stages char \
    --jobs 32 \
    --out-dir results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac \
    --char-seeds 64 \
    --char-n-conv 100000 \
    --char-train-seeds 48 \
    --char-out-mode raw_features \
    --char-nfast-encoding raw_lfsr_tag \
    --fixed-delay-seeds 8 \
    --fixed-delay-n-conv 5000 \
    --rerun-char

Expected output directories:

  results/local_software/20260601_o2_raw_tag_charac_smoke_server/
  MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_char_smoke_retry/
  MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac/

Expected key files:

  results/local_software/20260601_o2_raw_tag_charac_smoke_server/SUMMARY.md
  results/local_software/20260601_o2_raw_tag_charac_smoke_server/metadata.json
  MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_char_smoke_retry/overnight_manifest.json
  MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_char_smoke_retry/characterization/characterization_manifest.json
  MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac/overnight_manifest.json
  MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac/vip/vip_summary.json
  MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac/characterization/characterization_manifest.json

What to inspect before Genus:

  - packet parsing works
  - `nfast_encoding = raw_lfsr_tag` metadata is present in software decode outputs
  - all `nf` columns appear
  - raw tags decode without unknown states
  - no tag wrap ambiguity appears within the tested conversion window
  - calibration/analysis scripts do not silently treat raw tags as legacy binary counts

Files to commit/push after run:

  git add -f \
    results/local_software/20260601_o2_raw_tag_charac_smoke_server \
    MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_char_smoke_retry \
    MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac \
    docs/timing_closure/osc_pd_iteration_log.md

  git commit -m "server-results: 20260601 O2 raw-tag overnight characterization"
  git push

If run fails, still commit/push:

  - logs
  - summaries
  - failing seed artifacts
  - partial CSV/JSON outputs
