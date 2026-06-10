# Server Run Request: O5 Standard-Cell PD Closure

Purpose:

Run one low-cost Genus feasibility matrix for O5. The run must not use Innovus, must not reduce oscillator frequency, and must not false-path the PD timestamp path.

Run ID:

`20260602_o5b_pd_stdcell_discrete_cg`

## O5 First Run Summary

The first run `20260602_o5_pd_stdcell_closure` produced:

- `o5_noreset_ts_fast`: completed, but not promising.
  - `OSC_FAST_REAL` WNS about `-1786 ps`
  - dominant family still `PD_HIT_TO_TS_FREEZE`
  - `CLK_SYS_REAL` WNS about `-1130 ps`
- `o5_clock_gated_ts_fast`: inconclusive.
  - Genus stopped with `POPT-78 Cannot find any usable integrated clock-gating cell`
  - no post-synthesis netlist
  - no timing reports

Do not rerun the original O5 command unchanged. The follow-up command below uses the same RTL but enables discrete clock-gating logic as a feasibility-only test.

## Command

Run after the O5 RTL/scripts/docs patch is committed and pushed.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only

EXPECTED_HEAD=<FILL_WITH_O5_COMMIT_SHA>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

git status --short
git log --oneline -5

O5_RUN_BASE=0 \
O5_RUN_NORESET=0 \
O5_RUN_PVT_AWARE=0 \
O5_RUN_CLOSURE=auto \
MPTDC_CLOCK_GATING_MIN_FLOPS=2 \
bash MPTDC/syn/scripts/server_run_genus_o5_pd_stdcell_closure.sh 20260602_o5b_pd_stdcell_discrete_cg
```

## What The Script Runs

FAST_FEASIBILITY:

1. `20260602_o5_pd_stdcell_closure_o5_noreset_ts_fast`
   - timestamp flops have no reset/clear in RTL
   - PD `dont_touch` relaxed
   - automatic clock gating disabled
   - skipped in the O5b rerun when `O5_RUN_NORESET=0`, because the first O5 run already completed this mode and it was not promising

2. `20260602_o5_pd_stdcell_closure_o5_clock_gated_ts_fast`
   - same RTL
   - PD `dont_touch` relaxed
   - automatic clock gating enabled experimentally
   - ICG `dont_use` override requested
   - clock-gating min flops set to 2
   - discrete clock-gating logic enabled for feasibility because usable ICG cells were not found in the first O5 run

Optional:

- `O5_RUN_PVT_AWARE=1` may be used only if real analog PVT periods/tap steps are supplied:
  - `O5_PVT_SLOW_PERIOD_NS`
  - `O5_PVT_FAST_PERIOD_NS`
  - `O5_PVT_SLOW_TAP_STEP_NS`
  - `O5_PVT_FAST_TAP_STEP_NS`

Closure:

- `O5_RUN_CLOSURE=auto` launches closure only for a promising fast-feasibility mode.
- If no mode is promising, the script should not spend closure-effort license time.

## Required Review Fields

Each result `SUMMARY.md` must report:

- `OSC_FAST_REAL` WNS/TNS/path count
- `OSC_SLOW_REAL` WNS/TNS/path count
- `CLK_SYS_REAL` WNS/TNS/path count
- `PD_HIT_TO_TS_FREEZE` WNS/TNS/path count
- `LOCAL_FAST_TAG_SELF` WNS/TNS/path count
- old fast-counter residue count
- old slow-counter residue count
- `RO_tune4` instance count
- `RO_tune4/S[0:7]` clock attachment count
- timestamp flop reference count
- resettable timestamp flop reference count
- clock-gating cell netlist count
- DRV max-transition count
- UNKNOWN path count

## Commit Results

After the server run finishes, commit only scoped O5 run outputs:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git status --short

git add -f \
  results/genus_osc_pd/20260602_o5b_pd_stdcell_discrete_cg_SUMMARY.md \
  results/genus_osc_pd/20260602_o5b_pd_stdcell_discrete_cg_o5_clock_gated_ts_fast \
  results/genus_osc_pd/20260602_o5b_pd_stdcell_discrete_cg_o5_clock_gated_ts_closure \
  MPTDC/lab_snapshots/genus_osc_pd_20260602_o5b_pd_stdcell_discrete_cg_o5_clock_gated_ts_fast \
  MPTDC/lab_snapshots/genus_osc_pd_20260602_o5b_pd_stdcell_discrete_cg_o5_clock_gated_ts_closure

git commit -m "server-results: 20260602 O5b discrete clock-gating Genus"
git push
```

If closure is not launched, omit the closure directories from `git add`.

Do not commit PDK audit directories or unrelated dirty files.

## Stop Conditions

Do not run Innovus unless O5 Genus shows the PD timestamp path is structurally improved into a plausible range and no conceptual oscillator-domain path remains dominant.

Do not run lower-frequency R500/R400 in this package.

Do not use O5 clock-gated mode as final signoff unless the ICG cells have valid Liberty/LEF treatment and physical loading is reviewed.
