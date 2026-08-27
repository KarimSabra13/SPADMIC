# MPTDC PVS Replay Flow

These wrappers replay known GUI-generated PVS controls on one immutable MPTDC
layout/source tuple. A zero shell return code is never treated as DRC or LVS
closure by itself.

The full RO6 recovery sequence is documented in
[`MPTDC_RO6_PHYSICAL_FIRST_RECOVERY.md`](../../docs/pnr/MPTDC_RO6_PHYSICAL_FIRST_RECOVERY.md).

## Required Input

Start only from an Innovus `04_route.enc.dat` checkpoint whose route report has:

```text
ROUTE_STATUS=PASS
INNOVUS_VERIFY_DRC_STATUS=PASS
GEOMETRY_DRC_VIOLATIONS=0
SHORTS=0
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_RAW_BAD=0
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
UNROUTED_NETS=0
```

The preparation step also requires an explicitly selected GDS export of the
real `RO_tune6` OA layout. A proxy, LEF-generated shell, or no-RO streamout is
not an acceptable substitute.

For RO6 recovery, export both views afresh into a run-local directory outside
the OA library:

- `RO_tune6/layout` to GDS
- `RO_tune6/schematic` to CDL

The standalone driver rejects artifacts older than 24 hours by default,
fingerprints both OA view directories before and after the run, copies the GDS
and CDL into an immutable result directory, and accepts only an explicit PVS
`Run Result: MATCH` with no blackboxed cells:

```bash
MPTDC/scripts/pvs/server_run_mptdc_ro6_standalone_lvs.sh \
  --source-pvs-run-id "$SOURCE_PVS_RUN" \
  --run-id "$RO6_STANDALONE_RUN" \
  --ro-gds "$RO_GDS" \
  --ro-cdl "$RO_CDL" \
  --expected-head "$EXPECTED_HEAD"
```

This is a macro proof and is deliberately `SIGNOFF_ELIGIBLE=NO`. It authorizes
regenerating the digital physical source with the exact same GDS hash; it does
not authorize a GDS release.

If the standalone comparison reduces to the exact published VDD-only mismatch
(18 layout pins versus 19 source pins, all 190 reduced devices matched, no
blackboxes, and only source `VDD` missing while bound to layout net 12), do not
rerun PVS or edit routing. Run the read-only OA/export-contract probe:

```bash
MPTDC/scripts/pvs/server_probe_mptdc_ro6_oa_vdd_export_contract.sh \
  --source-standalone-run-id "$RO6_STANDALONE_RUN" \
  --run-id "$RO6_OA_VDD_PROBE_RUN" \
  --expected-head "$EXPECTED_HEAD"
```

The probe independently locks the exact `.cls` signature, opens the OA layout
with mode `r`, inventories top terminal pin figures, labels, supply-net shapes,
and shapes overlapping the golden-LEF VDD pin box, correlates their
layer-purpose pairs against the exact zero-error XStream log and XH018/1131
maps, and requires identical OA content and metadata fingerprints before and
after. Classification success is separate from
`OA_TERMINAL_CONTRACT_STATUS`: a complete diagnosis may pass while the observed
OA terminal contract correctly remains `FAIL`. `PASS_REVIEW_EXPORT_CONTRACT`
is diagnostic evidence only. It selects a review action; it is not an LVS pass
and does not authorize an OA write.
Cadence `XSTRM-234` with zero errors is the authoritative translation-complete
record. The separate `strmout completed.` wrapper message is captured when
present but is optional because GUI/CIW output is not always copied into the
XStream log.

## Physical LVS Source Contract

Input preparation now builds LVS source only from Innovus
`saveNetlist -phys -includePowerGround` output. The contract:

- removes module definitions only for exact masters present in the selected
  canonical CDL set, plus the protected `RO_tune6` wrapper;
- preserves top-level instances, including physical tie instances;
- rejects unresolved active and tie masters;
- scalarizes only `u_core_u_osc_fast_u_ro_tune4` and
  `u_core_u_osc_slow_u_ro_tune4` to exact same-index escaped pins `code<0>`
  through `code<7>` and `S<0>` through `S<7>`;
- emits a matching 19-pin scalar `RO_tune6` wrapper and rejects positional RO
  instances.

The boundary replay does not use position-based bus mapping and does not hide
`tie1`. A diagnostic continuation is valid only for either an explicit top
`MATCH` or the exact four-open `RO6_PG_OPEN_ONLY` remainder with zero bus,
tie, net, and instance mismatch residue.

The only dirty-checkpoint exception is explicit diagnostic mode:

```bash
MPTDC/scripts/pvs/server_run_mptdc_ro6_recovery_pvs.sh \
  --pnr-run-id 20260826_mptdc_bufftap0_route_minarea_patch_trial_v6r_180659 \
  --ro-gds "$RO_GDS" \
  --expected-head "$EXPECTED_HEAD" \
  --diagnostic-deferred-minarea
```

That mode admits only the tracked failed-V6R one-MET1-minimum-area signature,
runs base DRC plus LVS, skips density, and always reports
`PVS_RUN_CLASS=DIAGNOSTIC_NOT_SIGNOFF` and `MPTDC_TC_PVS_CLOSED=NO`.

## Replay Sequence

Run in the foreground after sourcing the Cadence environment:

```bash
set +e

MPTDC/scripts/pvs/00_prepare_pvs_inputs_from_checkpoint.sh \
  --checkpoint "$SOURCE_CKPT" \
  --run-id "$PVS_RUN_ID" \
  --ro-gds "$RO_GDS" \
  --strict-attribution \
  --expected-head "$EXPECTED_HEAD"
PREP_RC=$?

PVS_DIR="$MPTDC_INNOVUS_WORK/$PVS_RUN_ID"

if [ "$PREP_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/01_audit_pvs_templates.sh \
    --result-dir "$PVS_DIR" \
    --expected-head "$EXPECTED_HEAD"
  AUDIT_RC=$?
else
  AUDIT_RC=99
fi

if [ "$AUDIT_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/02_replay_pvs_drc_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --variant base \
    --expected-head "$EXPECTED_HEAD"
  DRC_BASE_RC=$?
else
  DRC_BASE_RC=99
fi

if [ "$DRC_BASE_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/02_replay_pvs_drc_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --variant density \
    --expected-head "$EXPECTED_HEAD"
  DRC_DENSITY_RC=$?
else
  DRC_DENSITY_RC=99
fi

if [ "$DRC_BASE_RC" -eq 0 ] && [ "$DRC_DENSITY_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/03_replay_pvs_lvs_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --expected-head "$EXPECTED_HEAD"
  LVS_RC=$?
else
  LVS_RC=99
fi
```

## Passing Evidence

- `reports/tap_pin_contract.rpt`: exactly one slow and one fast buffered tap-0
  top pin, both output pins on MET3.
- `manifests/pvs_input_hashes.rpt`: exact GDS, source, CDL, HCell, DEF, map,
  and real-RO hashes.
- `reports/pvs_drc_base_status.rpt`: `PVS_DRC_STATUS=PASS` and both totals zero.
- `reports/pvs_drc_base_nonzero_rules.tsv`: complete rule-level inventory when
  diagnostic base DRC is nonzero; it is evidence of debt, never a pass.
- `reports/pvs_drc_density_status.rpt`: the same, with `DENSITY` proven enabled.
- `reports/pvs_lvs_status.rpt`: `PVS_LVS_STATUS=MATCH` with explicit
  report-level match evidence.

Any missing control, stale path, hash mismatch, nonzero report-level DRC total,
or missing explicit LVS MATCH fails closed. These results are a TC-only
physical package gate; they do not claim MMMC timing, IR/EM, PEX, or final
tapeout readiness.
