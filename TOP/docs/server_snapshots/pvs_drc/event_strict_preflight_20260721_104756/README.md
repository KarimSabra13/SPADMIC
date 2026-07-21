# Event PVS DRC Strict Preflight Success Snapshot

- Diagnostic ID: `event_pvs_drc_strict_preflight_20260721_104756`
- Diagnostic root:
  `/sim/ksabra/SPADMIC_work/diagnostics/event_pvs_drc_strict_preflight_20260721_104756`
- Repository branch: `SPADMIC_test`
- Repository commit: `9223b07d86273d6e66c11c49691a8d1a2219bfd3`
- Event GDS SHA-256:
  `837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857`
- Collection method: foreground base-plus-density strict dry-run
- PVS execution: not attempted

## Accepted Evidence

The repository, handoff staging, package, seed-control, PDK, GDS hierarchy,
selector, replay, output-isolation, external-reference, and post-preflight
identity gates all passed. The complete diagnostic manifest reproduced with
35 checked files.

```text
PREFLIGHT_RC=0
GDS_LAYER_COLLECTOR_RC=0
GDS_LAYER_APPLICABILITY_GATE_RC=0
BASE_DRY_RUN_RC=0
DENSITY_DRY_RUN_RC=0
RUN_AUDIT_GATE_RC=0
SOURCE_POST_RECHECK_RC=0
SOURCE_STAGING_POST_MANIFEST_RC=0
PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=0
EVENT_STRICT_DRY_RUN_PREFLIGHT_STATUS=PASS
DIAGNOSTIC_MANIFEST_RC=0
PVS_EXECUTED=NO
```

All 86 structures are reachable from `spadmic_event_coordinator`. PAD 19/0,
PIMIDE 221/5, and NOPIM 46/0 each have zero reachable geometry and text
elements. The Event OOC policy therefore leaves PIMIDE undefined. Base and
density controls differ only in the DENSITY selector; both leave POPPING and
DUMMY_FILL undefined and keep VAR_ANT_RATIO defined.

The applicability collector records a recommendation and deliberately leaves
its local authorization fields at `NO`. The enclosing hash-bound preflight is
the authorization gate: after validating the collector and both dry-runs, it
authorizes exactly one base replay and leaves density execution unauthorized.

## Decision

This snapshot proves only that the controls for the exact staged Event GDS
are attributable and ready. It does not contain a DRC result. The only next
EDA transaction is one foreground base PVS DRC invocation through
`TOP/ci/server_run_event_coordinator_pvs_base_drc.sh`.

The driver accepts a report-level zero directly. An attributable nonzero
result must reconcile the summary, ASCII error geometry, replay contract, and
run manifest before it is classified as physical rule debt. Density DRC, LVS,
promotion, and assembly remain separate gates in either case.
