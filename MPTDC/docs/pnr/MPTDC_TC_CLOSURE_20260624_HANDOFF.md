# MPTDC TC-Only Closure Handoff - 2026-06-24

Author: Karim Sabra

This note records the active MPTDC digital-PNR closure work so a future session
can resume without repeating the same experiments. The scope is deliberately
TC-only. This is not MMMC signoff, final digital signoff, or tapeout readiness.

```text
TC_ONLY_NOT_MMMC_NOT_FINAL_SIGNOFF
READY_FOR_TAPEOUT=NO until row/block DRC/LVS and non-TC-only timing are closed
```

## Branch State

- Working branch: `SPADMIC_test`.
- Row-legal orientation v1 source commit:
  `6117bf1e778f49e211975cfc8c60fd3238e912c7`.
- Documentation-only handoff commit:
  `bb6443bea629`.
- Previous aggressive fast-tag commit:
  `ba9abf8a3eb8854680ee6b977c3047d63ae961a6`.
- Genus handoff run:
  `20260623_1207_mptdc_axis_core_typical_closed_ba2b2932`.
- Genus handoff directory:
  `/sim/ksabra/SPADMIC_work/handoff/genus_typical/20260623_1207_mptdc_axis_core_typical_closed_ba2b2932_handoff`.
- Innovus work root: `/sim/ksabra/SPADMIC_work/innovus`.

Keep the three local untracked files out of this closure work unless they are
explicitly reviewed: `ParameterDefs.sv`, `multi_ShiftRegisterChain_cfg_v1.sv`,
and `pixel_readout.pdf`.

## What Was Tried

### Baseline TC Closure Runs

The earlier TC-only closure run reached placement, CTS, route, extraction, and
hold timing. It did not close setup.

Known status from the latest complete reports before the aggressive fixes:

- PD matrix / placement / CTS were passing.
- `TC_HOLD_STATUS=PASS`.
- Route status was provisional because route DRC review was allowed.
- DRC was non-short geometry only, with clean regular/special connectivity,
  no unroute, and zero shorts.
- Final signoff remained provisional because the run was TC-only and DRC/LVS
  were deferred.

### Fast-Tag Column Run

Run:
`20260624_mptdc_digital_signoff_tc_clkcts_8a323c74_fasttagcol1`.

Important evidence:

- Fast tags were preplaced in 8 vertical column bands.
- `FAST_TAG_COLUMN_SIDE=east`.
- `FAST_TAG_COLUMN_RECORDS=56`.
- CTS passed.
- Hold passed.
- Route DRC showed `2` raw MET1 `Mar` violations, zero shorts, clean
  connectivity, and no unrouted nets.
- Setup still failed:
  `SETUP_STATUS_TC=FAIL`, WNS about `-0.090 ns`, TNS about `-10.253 ns`, and
  hundreds of violating paths.
- Top setup paths were fast-tag/context paths into PD-local
  `nfast_hit_latched` logic.
- The huge DRV report hit the Innovus object-name length limit:
  `exceeds the max length 8193 of object name`.

Conclusion: the fast-tag problem was real enough to justify placement/timing
focus, but east-side fast-tag placement was not enough and the verbose DRV
collection itself needed bounding.

### Aggressive Center/Fast-Tag Patch

Commit:
`ba9abf8a3eb8854680ee6b977c3047d63ae961a6`.

Purpose:

- Add `MPTDC_PNR_FAST_TAG_COLUMN_SIDE=center`.
- Add opt-in fast-tag timing focus without false paths or multicycles.
- Bound verbose DRV all-violator reporting to avoid the Innovus object-name
  limit.
- Make post-filler route cleanup require clean router transcript plus clean
  `verify_drc` before calling route clean.

This commit passed source-only Tcl checks locally and was pushed.

### Center-Final Failure

Run:
`20260624_mptdc_digital_signoff_tc_clkcts_ba9abf8a_centerfinal1`.

The run failed early at phase-buffer placement:

```text
MPTDC_RO_PHASE_OVERLAP_GATE_FAILED:
reason=checkplace_reports_overlap
stage=phase_buffer_placement
```

The log showed many `IMPFP-10137` / `IMPFP-9996` warnings. The common pattern
was that custom preplacement forced orientation `R0` onto JIHD standard cells
whose LEF site symmetry only allowed Y-axis flipping. The affected placement
paths included PD tile leaves, fast-tag registers, and phase-buffer drivers.

Conclusion: this was not a timing result. It proved the preplacement scripts
were forcing an illegal orientation for `core_jihd` rows.

### Row-Legal Orientation Patch

Commit:
`6117bf1e778f49e211975cfc8c60fd3238e912c7`.

Purpose:

- Add `MPTDC/pnr/scripts/innovus_mptdc_place_utils.tcl`.
- Add `mptdc_pnr_place_instance_row_legal`.
- Change PD tile leaf preplacement default to `MPTDC_PNR_PD_TILE_ORIENT=AUTO`.
- Change fast-tag column preplacement default to
  `MPTDC_PNR_FAST_TAG_COLUMN_ORIENT=AUTO`.
- Change phase-buffer placement default to `MPTDC_PNR_PHASE_BUF_ORIENT=AUTO`.
- Preserve explicit override support for experiments, but make AUTO the safe
  default for JIHD row legality.

The helper first tries placement without a forced orientation, allowing Innovus
to choose a row-compatible orientation. Only if an explicit orientation is
requested does it attempt the requested orient list. This is the intended fix
for the R0/site-symmetry warning cascade.

Local checks passed:

```bash
MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY=1 \
MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1 \
tclsh MPTDC/pnr/scripts/innovus_mptdc_digital_signoff.tcl

tclsh source checks for:
  MPTDC/pnr/scripts/innovus_mptdc_place_utils.tcl
  MPTDC/pnr/scripts/pd_matrix_floorplan.tcl
  MPTDC/pnr/scripts/innovus_mptdc_pd_matrix_place.tcl
  MPTDC/pnr/scripts/innovus_o13_phase_buffer_place.tcl

git diff --check
```

### Autoorient1 Failure And V2 Fix

Run:
`20260624_mptdc_digital_signoff_tc_clkcts_6117bf1e_autoorient1`.

The v1 AUTO-orientation patch did not fix the server run. It produced a better
report, but the same illegal-orientation signature remained.

Important evidence:

- `FAST_TAG_COLUMN_ORIENT=AUTO`.
- Fast-tag placement report commands still looked like
  `placeInstance {inst} x y -fixed`, with no explicit orientation.
- Innovus defaulted those un-oriented `placeInstance` calls to `R0`.
- The log still contained `IMPFP-10137` and `IMPFP-9996` warnings for PD tile
  leaves, fast-tag registers, and fast phase-buffer drivers.
- The helper also printed `IMPTCM-48` errors because it tried an invalid
  placement-status command before the valid syntax.
- `extracted_timing_status.rpt` and `route_status.rpt` were not produced because
  the run stopped at `phase_buffer_placement`.

The RO/phase-buffer geometry itself did not show a real overlap in the audit:

- `SLOW_RO_PHASE_PLACEMENT_STATUS=PASS`.
- `FAST_RO_PHASE_PLACEMENT_STATUS=PASS`.
- `SLOW_RO_PHASE_BUFFER_OVERLAP_AREA=0.000000`.
- `FAST_RO_PHASE_BUFFER_OVERLAP_AREA=0.000000`.
- `RO_PHASE_MIN_CLEARANCE_UM=10.67`.

The final status still failed:

```text
RO_PHASE_PLACEMENT_STATUS=FAIL
RO_PHASE_PLACEMENT_REASON=checkplace_reports_overlap
```

Interpretation: this failure should be treated as a remaining row-orientation /
checkPlace-cleanliness blocker, not as a proven physical RO/phase-buffer bbox
overlap.

The v2 helper fix changes AUTO behavior again:

- Do not try un-oriented `placeInstance` first for AUTO.
- Do not use `placeInstance ... -fixed` as the first AUTO attempt.
- Try explicit row-legal candidates first, defaulting to `MY R0 MX R180`.
- Mark fixed cells separately with the valid syntax:
  `setInstancePlacementStatus -status fixed -name <inst>`.
- Allow override through `MPTDC_PNR_ROW_LEGAL_ORIENT_CANDIDATES` if the row
  orientation candidate order needs to change.

Local stub evidence after the v2 fix:

```text
command=placeInstance u0 10.0 20.0 MY
fixed_command=setInstancePlacementStatus -status fixed -name u0
```

### Myorient1 Failure And RO-Audit Fix

Run:
`20260624_mptdc_digital_signoff_tc_clkcts_bb76d407_myorient1`.

The v2 helper did fix explicit preplacement command generation. Evidence:

- Fast-tag commands used explicit `MY`, for example
  `placeInstance {u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[1]} ... MY`.
- Phase-buffer commands used explicit `MY`.
- PD tile leaf commands used explicit `MY`.
- Fast-tag column placement reported `FAST_TAG_COLUMN_PLACEMENT_STATUS=PASS`.
- Phase-buffer count/status reported `PHASE_BUFFER_STATUS=PASS`.

The run still stopped at `phase_buffer_placement`, but the measured
RO/phase-buffer geometry was clean:

```text
SLOW_RO_PHASE_PLACEMENT_STATUS=PASS
FAST_RO_PHASE_PLACEMENT_STATUS=PASS
SLOW_RO_PHASE_BUFFER_OVERLAP_AREA=0.000000
FAST_RO_PHASE_BUFFER_OVERLAP_AREA=0.000000
RO_PHASE_MIN_CLEARANCE_UM=10.67
```

The final status failed only because the audit treated the aggregate global
`checkPlace` summary as a hard RO/phase overlap gate:

```text
CHECKPLACE_OVERLAP_LINE_COUNT=1
RO_PHASE_PLACEMENT_STATUS=FAIL
RO_PHASE_PLACEMENT_REASON=checkplace_reports_overlap
```

The companion `checkPlace` report showed unrelated global placement/fence
issues, not measured RO/phase bbox overlap:

```text
Region/Fence Violation: 357
Overlapping with other instance: 215
Not-of-Fence Violation: 56
```

Interpretation: this is a false hard stop for the RO/phase gate. The audit must
still fail on real RO/phase overlap or clearance below
`MPTDC_RO_PHASE_MIN_CLEARANCE_UM`, but aggregate `checkPlace` overlap text must
be review context by default because it includes unrelated PD/fence violations
at this early placement point.

Fix:

- Add `MPTDC_RO_PHASE_FAIL_ON_GLOBAL_CHECKPLACE_OVERLAP`, default `0`.
- Record `CHECKPLACE_OVERLAP_STATUS=REVIEW_REQUIRED` when global checkPlace
  reports overlap text.
- Keep `RO_PHASE_PLACEMENT_STATUS=PASS` when the measured slow/fast RO/phase
  bbox checks pass and only the aggregate global checkPlace text is dirty.
- For strict experiments, set
  `MPTDC_RO_PHASE_FAIL_ON_GLOBAL_CHECKPLACE_OVERLAP=1`.

The next diagnostic run should explicitly set
`MPTDC_PNR_PD_TILE_FIX_LEAVES=1`. The `bb76d407_myorient1` PD floorplan report
showed `fixed_status=SKIPPED` for PD tile leaves, meaning the server shell had
carried forward the relaxed timing experiment setting
`MPTDC_PNR_PD_TILE_FIX_LEAVES=0`.

### Roauditfix1 Tcl Arity Failure

Run:
`20260624_mptdc_digital_signoff_tc_clkcts_9360dfcd_roauditfix1`.

The run confirmed that `MPTDC_PNR_PD_TILE_FIX_LEAVES=1` was active. The PD
floorplan report changed from `fixed_status=SKIPPED` to `fixed_status=PASS`
for PD tile leaves.

The run stopped before the RO/phase audit files were created:

```text
PHASE_BUFFER_STATUS=FAIL
MPTDC_DIGITAL_SIGNOFF_STAGE_FAILED: stage=phase_buffer_placement
error=wrong # args: should be "mptdc_signoff_env_truthy name"
```

Cause: newer code called `mptdc_signoff_env_truthy` with an optional default
argument, but the helper still accepted only one argument. The fix is to make
`mptdc_signoff_env_truthy` accept `{default_value 0}` and route through
`mptdc_signoff_env`.

## Active Server Run To Watch

Previous failed run:
`20260624_mptdc_digital_signoff_tc_clkcts_9360dfcd_roauditfix1`.

Next intended run after pulling the Tcl arity fix:
`20260624_mptdc_digital_signoff_tc_clkcts_<new_short_sha>_truthyfix1`.

Launch state expected on the server:

```bash
cd ~/2026_SPAD/SPADMIC
source .venv/bin/activate
git checkout SPADMIC_test
git pull --ff-only
git rev-parse --short=12 HEAD

export MPTDC_PNR_PD_TILE_ORIENT=AUTO
export MPTDC_PNR_PD_TILE_FIX_LEAVES=1
export MPTDC_PNR_FAST_TAG_COLUMN_ORIENT=AUTO
export MPTDC_PNR_PHASE_BUF_ORIENT=AUTO
export MPTDC_PNR_ROW_LEGAL_ORIENT_CANDIDATES="MY R0 MX R180"
export MPTDC_RO_PHASE_FAIL_ON_GLOBAL_CHECKPLACE_OVERLAP=0
export SIGNOFF_RUN=20260624_mptdc_digital_signoff_tc_clkcts_$(git rev-parse --short=8 HEAD)_truthyfix1

bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  "$SIGNOFF_RUN" \
  --mode full_signoff \
  --genus-run-id "$MPTDC_GENUS_RUN_ID" \
  --handoff-dir "$MPTDC_GENUS_HANDOFF_DIR"
```

The first thing to confirm is that the prior `IMPFP-9996`, `IMPFP-10137`, and
`RO_PHASE_OVERLAP_GATE_FAILED` failure signature is gone or materially reduced.
Also confirm the placement reports still show explicit `MY` orientation in
`placeInstance` commands, not `placeInstance ... -fixed` without an
orientation. If the RO/phase
gate passes, inspect placement, route, extraction, and timing. If the same
illegal-orientation warning remains on PD leaves, inspect whether
`MPTDC_PNR_PD_TILE_FIX_LEAVES=1` reached Innovus and whether PD leaf report
entries changed from `fixed_status=SKIPPED` to `fixed_status=PASS`.

## Environment Variables And Reasons

Core approval and scope:

| Variable | Value | Reason |
| --- | --- | --- |
| `MPTDC_DIGITAL_SIGNOFF_APPROVED` | `1` | Allows the full Innovus implementation launch. |
| `MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY` | `1` | Explicitly accepts the current provisional row-infrastructure policy while no dedicated CORE tap/endcap master has been qualified. |
| `MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG` | `1` | Allows the provisional preplace/PG path to continue during TC-only closure. |
| `MPTDC_INNOVUS_WORK` | `/sim/ksabra/SPADMIC_work/innovus` | Server output root for Innovus run directories. |

TC timing closure effort:

| Variable | Value | Reason |
| --- | --- | --- |
| `MPTDC_ENABLE_POSTROUTE_OPT` | `1` | Enables post-route optimization. |
| `MPTDC_ENABLE_TC_CLOSURE` | `1` | Requests the TC-only closure loop. |
| `MPTDC_POSTROUTE_SETUP_OPT_PASSES` | `12` | Aggressive setup repair budget for this final TC attempt. |
| `MPTDC_POSTROUTE_SETUP_TARGET_SLACK_NS` | `0.200` | Positive setup target so the tool keeps optimizing beyond barely zero slack. |
| `MPTDC_POSTROUTE_HOLD_OPT_PASSES` | `3` | Bounded hold cleanup after setup repair. |
| `MPTDC_POSTROUTE_HOLD_TARGET_SLACK_NS` | `0.050` | Small positive hold target to avoid trading into hold failure. |

PD matrix and row legality:

| Variable | Value | Reason |
| --- | --- | --- |
| `MPTDC_PNR_PD_TILE_PREPLACE_LEAVES` | `1` | Keeps PD tile leaf placement structured by matrix tile. |
| `MPTDC_PNR_PD_TILE_FIX_LEAVES` | `1` | Keeps row-legal PD leaf placements fixed during this diagnostic run, avoiding later illegal `R0` attempts from a carried-over relaxed timing experiment. |
| `MPTDC_PNR_PD_TILE_USE_FENCE` | `1` | Keeps PD tile logic inside the intended matrix regions. |
| `MPTDC_PNR_PD_TILE_ORIENT` | `AUTO` | Avoids illegal forced `R0`; lets Innovus choose row-compatible orientation. |
| `MPTDC_PNR_ROW_LEGAL_ORIENT_CANDIDATES` | `MY R0 MX R180` | Explicit candidate order for AUTO placement; `MY` first matches the JIHD row/site warning that cells can only flip about Y-axis. |
| `MPTDC_RO_PHASE_FAIL_ON_GLOBAL_CHECKPLACE_OVERLAP` | `0` | Keeps the RO/phase gate tied to measured RO/phase bbox overlap and clearance; aggregate global `checkPlace` overlap text is review context unless this is explicitly set to `1`. |

Fast-tag placement and timing focus:

| Variable | Value | Reason |
| --- | --- | --- |
| `MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN` | `1` | Enables explicit fast-tag column placement. |
| `MPTDC_PNR_FAST_TAG_COLUMN_BITS` | `ALL` | Places all fast-tag bits, not only a subset. |
| `MPTDC_PNR_FAST_TAG_COLUMN_SIDE` | `center` | Moves the fast-tag column from east to center to reduce PD-local timing distance. |
| `MPTDC_PNR_FAST_TAG_COLUMN_STRIP_WIDTH_UM` | `32.0` | Width of the fast-tag placement strip. |
| `MPTDC_PNR_FAST_TAG_COLUMN_GAP_UM` | `2.0` | Gap between the PD box and the fast-tag strip. |
| `MPTDC_PNR_FAST_TAG_COLUMN_Y_MARGIN_UM` | `1.0` | Vertical margin inside each matching PD column band. |
| `MPTDC_PNR_FAST_TAG_COLUMN_PREPLACE` | `1` | Enables physical preplacement of fast-tag registers. |
| `MPTDC_PNR_FAST_TAG_COLUMN_FIX` | `1` | Fixes fast-tag registers after placement for this aggressive experiment. |
| `MPTDC_PNR_FAST_TAG_COLUMN_ORIENT` | `AUTO` | Avoids illegal forced `R0`; lets Innovus select row-legal orientation. |
| `MPTDC_PNR_FAST_TAG_TIMING_FOCUS` | `1` | Adds timing focus reports and critical ranges for fast-tag to PD-local paths. |
| `MPTDC_PNR_FAST_TAG_CRITICAL_RANGE_NS` | `0.080` | Pulls near-critical fast-tag paths into optimization focus. |
| `MPTDC_PNR_FAST_TAG_MAX_TRANSITION_NS` | `0.350` | Keeps fast-tag path transition targets aligned with CTS/timing policy. |

Phase-buffer placement:

| Variable | Value | Reason |
| --- | --- | --- |
| `MPTDC_PNR_PHASE_BUF_ORIENT` | `AUTO` | Avoids illegal forced `R0` for phase-buffer standard cells. |

Route/DRC continuation:

| Variable | Value | Reason |
| --- | --- | --- |
| `MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE` | `1` | Lets route continue only when DRC is bounded and classified for review. |
| `MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS` | `10` | Caps allowed review DRC count for provisional continuation. |
| `MPTDC_DISABLE_ROUTE_GATE_RECOVERY` | `0` | Keeps route-gate recovery enabled. |
| `MPTDC_SKIP_VERBOSE_DRV_ALL_VIOLATORS` | `1` | Avoids building overlong Innovus object-name lists in verbose DRV reporting. |

Owner-accepted TC-only exception:

| Variable | Value | Reason |
| --- | --- | --- |
| `MPTDC_PHASE_RC_ACCEPT_ASYMMETRY` | `1` | Accepts current phase RC asymmetry for this TC-only attempt only. |
| `MPTDC_PHASE_RC_ACCEPT_REASON` | `owner_accepted_phase_rc_asymmetry_for_tc_only_final_attempt_20260624` | Documents why RC symmetry is not blocking this TC-only run. |

Handoff binding:

| Variable | Value | Reason |
| --- | --- | --- |
| `MPTDC_GENUS_RUN_ID` | `20260623_1207_mptdc_axis_core_typical_closed_ba2b2932` | Selects the Genus run used as the Innovus netlist/timing handoff. |
| `MPTDC_GENUS_HANDOFF_DIR` | `/sim/ksabra/SPADMIC_work/handoff/genus_typical/20260623_1207_mptdc_axis_core_typical_closed_ba2b2932_handoff` | Points Innovus at the exact handoff package. |

## Post-Run Inspection Commands

Run these when the current server run finishes:

```bash
export SIGNOFF_DIR="$MPTDC_INNOVUS_WORK/$SIGNOFF_RUN"

sed -n '1,220p' "$SIGNOFF_DIR/reports/ro_phase_overlap_audit.rpt"
sed -n '1,180p' "$SIGNOFF_DIR/reports/fast_tag_column_placement.rpt"
sed -n '1,180p' "$SIGNOFF_DIR/reports/extracted_timing_status.rpt"
sed -n '1,180p' "$SIGNOFF_DIR/reports/route_status.rpt"
sed -n '1,220p' "$SIGNOFF_DIR/reports/route_drc.rpt"
sed -n '1,220p' "$SIGNOFF_DIR/reports/digital_pnr_signoff_status.rpt"

grep -R "IMPFP-9996\\|IMPFP-10137\\|RO_PHASE_OVERLAP_GATE_FAILED\\|exceeds the max length 8193" \
  "$SIGNOFF_DIR" 2>/dev/null | sed -n '1,160p'
```

Expected interpretation:

- If `IMPFP-9996` / `IMPFP-10137` disappear and placement passes, commit
  `6117bf1e` fixed the row-orientation blocker.
- If route DRC is still only bounded non-short geometry with clean connectivity,
  keep the result provisional and inspect whether timing closed.
- If setup still fails, use the new fast-tag timing focus reports before adding
  any new constraint. Do not solve this with false paths or broad timing
  disables.
- If setup and hold pass in TC, call it TC-only closure evidence. Do not call it
  MMMC signoff or tapeout-ready signoff.

## Do Not Redo

- Do not re-run the east-side fast-tag experiment as a first response; it already
  showed setup was still bad.
- Do not treat `ba9abf8a_centerfinal1` as a timing failure; it failed before the
  real timing stages because of forced orientation.
- Do not remove the AUTO orientation defaults unless a report proves Innovus is
  choosing an illegal orientation.
- Do not add false paths or multicycles for the fast-tag-to-PD paths. The current
  flow intentionally reports:
  `FAST_TAG_TO_PD_TS_FALSE_PATH=NO` and
  `FAST_TAG_TO_PD_TS_MULTICYCLE=NO`.
