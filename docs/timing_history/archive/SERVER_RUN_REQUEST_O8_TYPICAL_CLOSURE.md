# Server Run Request: O8 Typical Fast Closure

Purpose:

Run O8A high-effort Genus closure in the same typical-only view as O7.  This is
not MMMC, not final signoff, and not an Innovus request.

Run ID:

`20260604_o8_typical_closure`

## Required Command

Run after the O8 collateral is committed and pushed.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only origin SPADMIC_localtag

EXPECTED_HEAD=<FILL_WITH_O8_COMMIT_SHA_AFTER_PUSH>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

git status --short
git log --oneline -5

bash MPTDC/syn/scripts/server_run_genus_o8_typical_closure.sh 20260604_o8_typical_closure
```

## What O8A Uses

O8A intentionally keeps the O7 timing view:

- typical standard-cell Liberty only
- `MPTDC_TIMING_VIEW=tc_only`
- no BC/WC MMMC views
- real `RO_tune4` LEF
- `RO_tune4` Liberty shell only as a structural shell
- SDC overlay `MPTDC/syn/inputs/mptdc_osc_typical_from_screenshot.sdc`
- slow period `1.000 ns`
- fast period `0.900 ns`
- slow tap step `0.055 ns`
- fast tap step `0.050 ns`
- setup uncertainty `10 ps`
- hold uncertainty `5 ps`
- `raw_lfsr_tag`
- unchanged packet format

O8A changes optimization effort only:

- `GENUS_EFFORT=closure`
- `syn_generic_effort=high`
- `syn_map_effort=high`
- `syn_opt_effort=extreme`
- `design_power_effort=high`

These are the existing checked-in Genus effort knobs in
`MPTDC/syn/scripts/settings.tcl`.

## Optional Follow-Up Modes

Run these only after reviewing O8A.

O8B preserve relaxation:

```bash
O8_MODE=relax_fast_tag_preserve \
bash MPTDC/syn/scripts/server_run_genus_o8_typical_closure.sh 20260604_o8b_typical_relax_fast_tag_preserve
```

O8C raw Galois timing what-if:

```bash
O8_MODE=raw_galois_tag \
bash MPTDC/syn/scripts/server_run_genus_o8_typical_closure.sh 20260604_o8_typical_raw_galois
```

O8C is not final adoption.  If it improves timing, run Xcelium Stage 1/Stage 2
characterization before considering production use.

## Required Review Fields

From `results/genus_osc_pd/20260604_o8_typical_closure/SUMMARY.md` and detailed
reports, record:

- `OSC_FAST_REAL` WNS/TNS/path count
- `OSC_SLOW_REAL` WNS/TNS/path count
- `CLK_SYS_REAL` WNS/TNS/path count
- `FAST_TAG_TO_PD_TS` WNS/TNS/path count
- `PD_HIT_TO_TS_FREEZE` WNS/TNS/path count
- `LOCAL_FAST_TAG_SELF` WNS/TNS/path count
- top 10 paths
- DRV max-transition count
- area
- QoR
- `RO_tune4` instance count
- `RO_tune4/S[0:7]` clock attachment count
- old oscillator stub residue
- old fast-counter residue
- old slow-counter residue
- unknown path count

## Result Commit

After the run finishes:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

git status --short

git add -f results/genus_osc_pd/20260604_o8_typical_closure
if [ -d MPTDC/lab_snapshots/genus_osc_pd_20260604_o8_typical_closure ]; then
  git add -f MPTDC/lab_snapshots/genus_osc_pd_20260604_o8_typical_closure
fi
git add docs/timing_closure/O8_o7_remaining_path_analysis.md
git add docs/timing_closure/osc_pd_iteration_log.md 2>/dev/null || true

git status --short
git commit -m "server-results: O8 typical closure Genus"
git push origin SPADMIC_localtag
```

## Interpretation

- `WNS >= 0`: stop architecture changes; prepare typical Innovus feasibility.
- `-50 ps` to `-150 ps`: very promising; consider one targeted incremental
  closure run.
- `-150 ps` to `-300 ps`: check path family; O8B/O8C may be justified.
- worse than `-300 ps`: high-effort closure did not solve enough; do not run
  Innovus.
