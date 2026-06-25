# MPTDC TC-Only Provisional Baseline - 2026-06-25

Author: Karim Sabra

This note records the current MPTDC digital-PNR baseline from the Innovus run
at commit `010285dc`. It is a useful base for continuing physical closure, but
it is not final digital signoff, not MMMC signoff, and not tapeout readiness.

```text
TC_ONLY_PROVISIONAL_BASELINE
NOT_MMMC_SIGNOFF=YES
READY_FOR_TAPEOUT=NO
```

## Run Binding

| Item | Value |
| --- | --- |
| Branch | `SPADMIC_test` |
| Source commit | `010285dc` |
| Genus handoff run | `20260623_1207_mptdc_axis_core_typical_closed_ba2b2932` |
| Genus handoff directory | `/sim/ksabra/SPADMIC_work/handoff/genus_typical/20260623_1207_mptdc_axis_core_typical_closed_ba2b2932_handoff` |
| Innovus run | `20260625_mptdc_tc_fullclosure_010285dc_postfiller1` |
| Innovus result directory | `/sim/ksabra/SPADMIC_work/innovus/20260625_mptdc_tc_fullclosure_010285dc_postfiller1` |
| Status report | `/sim/ksabra/SPADMIC_work/innovus/20260625_mptdc_tc_fullclosure_010285dc_postfiller1/reports/digital_pnr_signoff_status.rpt` |
| Review bundle | `/tmp/20260625_mptdc_tc_fullclosure_010285dc_postfiller1_review_bundle.tgz` |

## Baseline Verdict

The run completed the TC-only package and produced usable routed, filled,
extracted, and timed evidence. The status remains provisional because physical
implementation gates are still open:

- `MPTDC_TC_PNR_CLOSURE=DEFERRED`
- `DIGITAL_PNR_SIGNOFF=PROVISIONAL`
- `MPTDC_TC_PHYSICAL_SIGNOFF=NO`
- `TC_ONLY_TAPEOUT_EXCEPTION_READY=NO`
- `READY_FOR_TAPEOUT=NO`

The execution label
`COMPLETE_TC_ONLY_PROVISIONAL_TIMING_NOT_CLOSED` should be read as an umbrella
state for incomplete implementation/signoff gates. The extracted TC setup and
hold gates themselves passed in this run.

## Passing Evidence

The following gates are clean enough to keep this run as the working baseline:

- Genus handoff and pre-PNR source gate: `PASS`.
- RO import and effective SDC audit: `PASS`.
- Floorplan, IO, RO macro, RO phase placement, phase buffers: `PASS`.
- Placement and CTS: `PASS`.
- PG connectivity: `PASS`.
- Filler insertion: `PASS`, with `19897` `FEED*JIHD` fillers added.
- Extraction: `PASS`.
- Post-route DRV: `PASS`.
- Extracted TC setup: `PASS`, WNS `0.000 ns`, TNS `0.000 ns`, violating paths
  `0`.
- Extracted TC hold: `PASS`, WNS `0.048 ns`, TNS `0.000 ns`, violating paths
  `0`.
- Route connectivity: regular opens `0`, special opens `0`, unroutes `0`,
  shorts `0`.
- Phase load and RC symmetry status: `ACCEPTED` for this TC-only exception.

## Open Gates

These items prevent stronger closure language:

- Route status is `PROVISIONAL` because independent `verify_drc` still reports
  `2` geometry violations.
- Innovus `verify_drc` reports `2` `MET1` `Mar` violations in sub-area
  `{206.080 390.080 412.160 585.120}`.
- Router transcript reports can show `0` DRCs after cleanup, but those reports
  are not sufficient for the gate because the independent `verify_drc` remains
  at `2`.
- `DRC_STATUS=DEFERRED` and `LVS_STATUS=DEFERRED`; foundry-qualified DRC/LVS
  has not been run.
- Row infrastructure remains provisional until DRC/LVS proves legal row edges
  and no well/tap issue.
- Antenna is provisional pending LEF antenna completeness and signoff deck
  evidence.
- `PD_MATRIX_STATUS=REVIEW_REQUIRED` and
  `PD_PHYSICAL_MATRIX_STATUS=REVIEW_REQUIRED`.
- `EMPTY_SPACE_AUDIT_STATUS=REVIEW_REQUIRED`.
- `PG_PHYSICAL_STATUS=PROVISIONAL`.
- `PHASE_TO_PD_GEOMETRY_STATUS=PROVISIONAL`.
- `BACKEND_CROSSING_STATUS=PROVISIONAL`.
- WC setup, BC hold, and RO 1 GHz stress remain deferred by TC-only scope.

## Route And Filler Detail

The route gate is narrow and specific:

```text
ROUTE_STATUS=PROVISIONAL
INNOVUS_VERIFY_DRC_STATUS=FAIL
GEOMETRY_DRC_VIOLATIONS=2
SHORTS=0
REGULAR_NET_OPENS=0
SPECIAL_NET_OPENS=0
UNROUTED_NETS=0
ROUTE_DRC_REVIEW_CLASS=NONSHORT_GEOMETRY_DRC_WITH_CLEAN_CONNECTIVITY
```

Post-filler cleanup attempted `ecoRoute -target`, `ecoRoute`, and
`globalDetailRoute`. Those attempts cleared router-transcript DRC counts in
some stages and removed process antenna violations in the route transcript, but
the final independent `verify_drc` reports still show:

```text
Verification Complete : 2 Viols.
MET1 Mar 2
```

Keep `verify_drc` as the route gate evidence until the two markers are
classified and either fixed or waived by a foundry-qualified rule owner.

## Timing Detail

The official extracted TC timing reports are clean:

```text
timing_tc_nominal.rpt: WNS 0.000 ns, TNS 0.000 ns, violating paths 0
timing_tc_hold.rpt:    WNS 0.048 ns, TNS 0.000 ns, violating paths 0
```

There is still a report discrepancy to resolve before claiming anything beyond
the official TC gate. `fast_tag_timing_focus.rpt` reports the focus gate as
`PASS`, and it records:

```text
FAST_TAG_TO_PD_TS_FALSE_PATH=NO
FAST_TAG_TO_PD_TS_MULTICYCLE=NO
GROUP_PATH_STATUS=PASS
```

However, `fast_tag_to_pd_timing_focus.rpt` still contains command-specific
negative setup paths, with the worst shown slack around `-0.065 ns` from
`u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[6]/Q` to
`u_core_gen_pd_row[3].gen_pd_col[1].u_pd/nfast_hit_latched_reg[6]/D`.

Treat this as a follow-up audit item: either the focused report is intentionally
outside the official TC gate/path-group accounting, or the focus-gate parser is
masking a real residual path family. Do not hide it by adding false paths or
multicycles.

## Inspection Commands

Use these commands on the Cadence server to re-open the evidence without
rerunning Innovus:

```bash
export SIGNOFF_RUN=20260625_mptdc_tc_fullclosure_010285dc_postfiller1
export SIGNOFF_DIR=/sim/ksabra/SPADMIC_work/innovus/$SIGNOFF_RUN
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

for f in \
  digital_pnr_signoff_status.rpt \
  acceptance_matrix.rpt \
  physical_verification_status.md \
  route_status.rpt \
  filler_status.rpt \
  route_recovery_status.rpt \
  drv_status.rpt \
  extracted_timing_status.rpt \
  timing_tc_nominal.rpt \
  timing_tc_hold.rpt
do
  printf '\n===== %s =====\n' "$f"
  if test -f "$SIGNOFF_DIR/reports/$f"; then
    sed -n '1,220p' "$SIGNOFF_DIR/reports/$f"
  else
    printf 'MISSING\n'
  fi
done | tee "/tmp/${SIGNOFF_RUN}_status_deep.txt"
```

DRC and route cleanup evidence:

```bash
export SIGNOFF_RUN=20260625_mptdc_tc_fullclosure_010285dc_postfiller1
export SIGNOFF_DIR=/sim/ksabra/SPADMIC_work/innovus/$SIGNOFF_RUN

sed -n '1,260p' "$SIGNOFF_DIR/reports/route_drc.rpt"

grep -nEi \
  'viol|drc|short|mar|enc|spacing|overlap|bbox|box|layer|MET|Totals' \
  "$SIGNOFF_DIR/reports/route_drc.rpt" \
  "$SIGNOFF_DIR/reports"/post_filler_* \
  "$SIGNOFF_DIR/reports"/route_recovery_* 2>/dev/null | head -300
```

Timing cross-check:

```bash
export SIGNOFF_RUN=20260625_mptdc_tc_fullclosure_010285dc_postfiller1
export SIGNOFF_DIR=/sim/ksabra/SPADMIC_work/innovus/$SIGNOFF_RUN

for f in \
  timing_tc_nominal.rpt \
  timing_tc_hold.rpt \
  timing_tc_nominal_top100.rpt \
  timing_tc_hold_top100.rpt \
  fast_tag_timing_focus.rpt \
  fast_tag_to_pd_timing_focus.rpt
do
  printf '\n===== %s =====\n' "$f"
  if test -f "$SIGNOFF_DIR/reports/$f"; then
    grep -nEi 'WNS|TNS|violat|FAST_TAG|false|multi|path|slack|endpoint|beginpoint' \
      "$SIGNOFF_DIR/reports/$f" | head -180
  else
    printf 'MISSING\n'
  fi
done | tee "/tmp/${SIGNOFF_RUN}_timing_crosscheck.txt"
```

Package the review bundle:

```bash
export SIGNOFF_RUN=20260625_mptdc_tc_fullclosure_010285dc_postfiller1
export SIGNOFF_DIR=/sim/ksabra/SPADMIC_work/innovus/$SIGNOFF_RUN

tar -C "$SIGNOFF_DIR" -czf "/tmp/${SIGNOFF_RUN}_review_bundle.tgz" \
  reports manifests logs def checkpoints 2>/dev/null || \
tar -C "$SIGNOFF_DIR" -czf "/tmp/${SIGNOFF_RUN}_review_bundle.tgz" \
  reports manifests logs

ls -lh "/tmp/${SIGNOFF_RUN}_review_bundle.tgz"
```

## Cleanup Policy

Keep this run and its review bundle until a replacement run beats it on every
gate. Do not delete other Innovus runs directly from memory or by broad pattern.
First build an inventory and review it:

```bash
export SIGNOFF_RUN=20260625_mptdc_tc_fullclosure_010285dc_postfiller1
export MPTDC_WORK_ROOT=/sim/ksabra/SPADMIC_work

find "$MPTDC_WORK_ROOT/innovus" -maxdepth 1 -mindepth 1 -type d \
  -printf '%T@ %TY-%Tm-%Td %TH:%TM %p\n' | sort -nr \
  > /tmp/mptdc_innovus_run_inventory.txt

du -sh "$MPTDC_WORK_ROOT/innovus"/* 2>/dev/null | sort -hr \
  > /tmp/mptdc_innovus_run_sizes.txt

grep -v "$SIGNOFF_RUN" /tmp/mptdc_innovus_run_inventory.txt | sed -n '1,160p'
sed -n '1,160p' /tmp/mptdc_innovus_run_sizes.txt
```

After the keep/delete list is reviewed, delete only named stale run
directories. Preserve at minimum:

- `20260625_mptdc_tc_fullclosure_010285dc_postfiller1`;
- the Genus handoff directory named above;
- `/tmp/20260625_mptdc_tc_fullclosure_010285dc_postfiller1_review_bundle.tgz`;
- any run that introduced a source commit still needed for regression
  comparison.

## Next Steps

1. Classify the two `MET1 Mar` `verify_drc` markers by opening the run
   checkpoint in Innovus and dumping marker coordinates, owner shapes, nets,
   and nearby filler instances.
2. Fix or formally waive those two markers; rerun independent `verify_drc`.
3. Resolve the official `timeDesign` versus `fast_tag_to_pd_timing_focus.rpt`
   discrepancy without false paths or broad timing suppression.
4. Run foundry-qualified DRC/LVS and row-infrastructure qualification.
5. Run antenna with complete foundry antenna data.
6. Run PG physical/IR/EM checks, including RO macro current assumptions.
7. Only after those pass, decide whether the TC-only tapeout exception can move
   from `NO` to a reviewed exception-ready state.
