# Position PVS DRC Strict Preflight Initial Failure Snapshot

- Diagnostic ID: `position_pvs_drc_strict_preflight_20260720_111548`
- Diagnostic root:
  `/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_drc_strict_preflight_20260720_111548`
- Repository branch: `SPADMIC_test`
- Repository commit: `3d8c0e025cbaa6caa300e7efc2290983bcec90e2`
- Accepted Position GDS SHA-256:
  `ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1`
- Collection method: foreground strict dry-run, no PVS execution

## Passed Gates

Repository attribution, every pinned R10 input hash and status, the R10 SHA
manifest, accepted package/GDS identity, package SHA manifest, and every pinned
packet-core seed-control hash passed. The base controls were copied and patched
far enough to produce a passing replay contract and explicit
`#UNDEFINE DENSITY` evidence.

## Failure

The external-reference gate rejected two paths created by replacement order:

```text
MISSING=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_position_core
MISSING=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_position_core/PIPO1.LOG
ERROR: patched PVS template has missing external references
BASE_DRY_RUN_RC=1
DENSITY_DRY_RUN_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=1
```

The old scalar top name was replaced before the longer absolute execution
root containing that same token. The resulting false Position-named path no
longer matched the inferred packet-core root relocation. The replay helper is
corrected by applying longer replacement sources first, with a regression for
the exact collision.

The old failure path also required a complete density artifact set even though
density was deliberately not run after the base failure. That produced the
secondary `DIAGNOSTIC_COPY_GATE_RC=1`. The corrected driver copies available
partial evidence and requires completeness only for variants whose dry-run
returned zero.

## Classification

This is a local replay-tool defect. It is not evidence of a PVS failure, a
Position geometry failure, a changed seed, or a changed package. Source and
package rechecks passed, `PVS_EXECUTED=NO`, and both DRC variants remain
`NOT_RUN`. The failed diagnostic is preserved; the corrected rerun must use a
fresh timestamped run directory.
