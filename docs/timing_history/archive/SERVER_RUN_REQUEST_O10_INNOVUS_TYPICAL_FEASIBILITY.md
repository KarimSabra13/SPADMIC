# Server Run Request: O10 Innovus Typical Feasibility

Purpose: first Innovus feasibility and visualization run for O9 R750_delta5.

Labels:

- `O10_INNOVUS_TYPICAL_FEASIBILITY`
- `NOT_MMMC_SIGNOFF`
- `NOT_FINAL_SIGNOFF`
- `NOT_TAPEOUT_READY`

## Run

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only
EXPECTED_HEAD=<agent_provided_sha_after_o10_scripts_commit>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"
git status --short
git log --oneline -5

bash MPTDC/pnr/scripts/server_run_innovus_o10_typical_feasibility.sh 20260604_o10_typical_feasibility
```

## Expected Outputs

- `results/innovus/20260604_o10_typical_feasibility/`
- `MPTDC/lab_snapshots/innovus_o10_typical_feasibility_20260604_o10_typical_feasibility/`

Important subdirectories:

- `logs/`
- `reports/`
- `screenshots/`
- `checkpoints/`
- `def/`
- `manager/`
- `manifests/`

## Optional Compact Characterization Collection

This is required before claiming `O9_CHARACTERIZATION_PASS`, but it does not block the first O10 feasibility run.

```bash
bash MPTDC/scripts/analysis/collect_o9_characterization_compact.sh
```

## Commit Curated Outputs

Do not commit huge raw CSVs or Innovus database directories unless explicitly requested.

```bash
git add -f \
  results/innovus/20260604_o10_typical_feasibility \
  MPTDC/lab_snapshots/innovus_o10_typical_feasibility_20260604_o10_typical_feasibility \
  results/o9_char/20260604_o9_r750_delta5_overnight_compact \
  docs/timing_closure/O10_*.md
git commit -m "server-results: O10 Innovus typical feasibility"
git push
```

## Review Notes

- If screenshots are missing, check `screenshots/SCREENSHOT_EXPORT_FAILED.txt` and use the restore script/checkpoint.
- If route or CTS fails, still commit partial reports/logs if they identify the blocker.
- Do not label this tapeout-ready.
