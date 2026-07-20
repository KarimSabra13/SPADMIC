# Position PVS DRC Strict Preflight Success Snapshot

- Diagnostic ID: `position_pvs_drc_strict_preflight_20260720_113452`
- Diagnostic root:
  `/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_drc_strict_preflight_20260720_113452`
- Repository branch: `SPADMIC_test`
- Repository commit: `130954a9ddd074633cea0e612fd4ea7355a44b84`
- Accepted Position GDS SHA-256:
  `ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1`
- Collection method: foreground base-plus-density strict dry-run
- PVS execution: not attempted

## Accepted Evidence

All repository, R10, package, GDS, seed-control, replay, output-isolation,
external-reference, and post-run identity gates passed. The complete diagnostic
manifest also reproduced with 24 checked files.

```text
PREFLIGHT_RC=0
BASE_DRY_RUN_RC=0
DENSITY_DRY_RUN_RC=0
RUN_AUDIT_GATE_RC=0
DIAGNOSTIC_COPY_GATE_RC=0
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=0
STRICT_DRY_RUN_PREFLIGHT_STATUS=PASS
DIAGNOSTIC_MANIFEST_RC=0
PVS_EXECUTED=NO
```

## Variant Contract

Both fresh run-local control sets bind the same exact Position GDS and top.
The base control contains one `#UNDEFINE DENSITY`; the density control contains
one `#DEFINE DENSITY`. Both preserve `POPPING`, `PIMIDE`, and `DUMMY_FILL` as
undefined and `VAR_ANT_RATIO` as defined.

Every external reference is a resolved file. There are no `MISSING=` records.
The prior false `.../spadmic_position_core/PIPO1.LOG` path is absent, proving
the longest-source-first replay repair on the actual server scaffold.

## Decision

This is the final dry-run gate. It authorizes one fresh foreground base PVS DRC
execution using the same pinned seed as a control scaffold. It does not imply a
zero-result DRC verdict, authorize density execution automatically, establish
LVS, or permit block promotion.

The authorized execution wrapper is
`TOP/ci/server_run_position_core_pvs_base_drc.sh`. It runs PVS exactly once in
the foreground. A report-level zero is recorded directly; an attributable
nonzero result is reconciled and classified by rule in the same transaction.
Both accepted outcomes move directly to the independent density run. Tool,
replay, output-isolation, or report-classification failures stop without a PVS
rerun.
