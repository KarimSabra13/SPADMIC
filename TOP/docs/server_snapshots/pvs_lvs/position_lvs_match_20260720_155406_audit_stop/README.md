# Position Exact-GDS LVS Match With Post-Run Audit Stop

This snapshot records the foreground exact-GDS LVS transaction launched on
2026-07-20 from commit
`ea786a6b6f367dcf2a7e30ef1f81b38ef84b98e4`. The immutable roots are:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_execution_20260720_155406
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810/pvs/lvs/position_exact_gds_lvs_20260720_155406
```

The auxiliary same-basename CDL normalization succeeded. The replay contract,
output isolation, external-reference scan, run manifest, package manifest,
source recheck, and diagnostic manifest all passed. PVS executed on the exact
Position inputs and returned an explicit report-level match:

```text
PVS_WRAPPER_RC=0
PVS_TOOL_RC=0
PVS_LVS_STATUS=MATCH
LVS_NEGATIVE_MATCH_COUNT=0
LVS_POSITIVE_MATCH_COUNT=3
PVS_RESULT_EVIDENCE=.../position_exact_gds_lvs_20260720_155406/svdb/matched
```

The driver nevertheless returned `STATUS=FAIL` because one post-run assertion
still required `SVDB_REWRITE_COUNT=1`. That expectation belonged to a scaffold
which already contained one SVDB directive. The accepted scaffold contains no
incoming directive, so replay correctly materialized one run-local directive:

```text
SVDB_DIRECTORY=.../position_exact_gds_lvs_20260720_155406/svdb
SVDB_ACTION=ADDED_MISSING
SVDB_REWRITE_COUNT=0
RUN_AUDIT_GATE_RC=1
```

This is a classification-policy defect after successful PVS execution, not an
LVS mismatch and not a reason to rerun PVS. The corrected audit requires the
exact run-local SVDB path, `ADDED_MISSING`, and rewrite count zero. A separate
read-only review transaction rechecks the immutable run, manifests, comparison
inputs, explicit positive evidence, and absence of negative evidence before
recording `OUTCOME_CLASS=ATTRIBUTABLE_MATCH`.

Position base DRC remains `PASS`. Position density DRC remains `FAIL` with four
whole-extent coverage rules and still blocks promotion/signoff. The accepted
LVS match permits Event coordinator OOC to start while density disposition is
reviewed in parallel.
