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
- `reports/pvs_drc_density_status.rpt`: the same, with `DENSITY` proven enabled.
- `reports/pvs_lvs_status.rpt`: `PVS_LVS_STATUS=MATCH` with explicit
  report-level match evidence.

Any missing control, stale path, hash mismatch, nonzero report-level DRC total,
or missing explicit LVS MATCH fails closed. These results are a TC-only
physical package gate; they do not claim MMMC timing, IR/EM, PEX, or final
tapeout readiness.
