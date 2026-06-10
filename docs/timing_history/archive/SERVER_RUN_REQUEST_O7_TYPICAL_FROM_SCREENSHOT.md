# Server Run Request: O7 Typical RO Screenshot Model

Purpose:

Run one Genus feasibility pass using typical standard-cell Liberty and the
guarded screenshot-derived RO uncertainty model.  This is not signoff and must
not be treated as final oscillator timing evidence.

Run ID:

`202606xx_o7_typical_from_screenshot`

## Source Warning

The oscillator values come from manual Virtuoso screenshot extraction, not CSV
or Ocean export.  The screenshots appear labeled `RO_tune3` /
`SPADMIC_RO_tune3_sim2_maestro`; the digital macro is `RO_tune4`.  Equivalence
is not confirmed.

## Command

Run after the O7 collateral is committed and pushed.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only

EXPECTED_HEAD=<FILL_WITH_O7_COMMIT_SHA_AFTER_PUSH>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

git status --short
git log --oneline -5

bash MPTDC/syn/scripts/server_run_genus_o7_typical_from_screenshot.sh 202606xx_o7_typical_from_screenshot
```

## What The Script Uses

- typical standard-cell Liberty only
- `MPTDC_TIMING_VIEW=tc_only`
- `MPTDC_TC_ONLY_VIEW=1`
- no BC/WC MMMC analysis views
- real `RO_tune4` LEF when available
- `RO_tune4` Liberty shell only as a structural shell
- SDC overlay `MPTDC/syn/inputs/mptdc_osc_typical_from_screenshot.sdc`
- slow period `1.000 ns`
- fast period `0.900 ns`
- slow tap step `0.055 ns`
- fast tap step `0.050 ns`
- setup uncertainty `10 ps`
- hold uncertainty `5 ps`

## Required Review Fields

From `results/genus_osc_pd/202606xx_o7_typical_from_screenshot/SUMMARY.md` and
the classification reports, capture:

- `OSC_FAST_REAL` WNS/TNS/path count
- `OSC_SLOW_REAL` WNS/TNS/path count
- `CLK_SYS_REAL` WNS/TNS/path count
- DRV / max-transition summary
- dominant path family
- `RO_tune4` instance count
- `RO_tune4/S[0:7]` clock attachment count
- old fast-counter residue count
- old slow-counter residue count
- `mptdc_osc_stub` residue count

## Commit Results

After the server run finishes, commit only scoped O7 outputs:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git status --short

git add -f \
  results/genus_osc_pd/202606xx_o7_typical_from_screenshot \
  docs/timing_closure/O7_photo_extracted_values.md \
  docs/timing_closure/O7_typical_vs_previous_comparison.md \
  docs/timing_closure/osc_pd_iteration_log.md

git commit -m "server-results: O7 typical RO screenshot model Genus feasibility"
git push
```

If the run fails before producing timing reports, still commit the run directory
and main Genus log for triage.  Do not commit unrelated dirty files.

## Decision

- If O7 strongly improves WNS, treat O4/O5 as likely over-pessimistic and ask
  analog for real RO_tune4 CSV/corner data.
- If O7 remains worse than about `-1 ns`, the standard-cell PD/localtag fabric is
  still structurally too slow.
- If O7 is better than about `-300 ps`, run a higher-effort typical closure pass
  before considering Innovus.
