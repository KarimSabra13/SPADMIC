# Position Density PVS DRC Classified-Debt Snapshot

- Diagnostic ID: `position_pvs_drc_density_execution_20260720_133314`
- Diagnostic root:
  `/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_drc_density_execution_20260720_133314`
- Repository branch: `SPADMIC_test`
- Repository commit: `d327be8596fccc8a60d46d5cd0138b93b6c2f03e`
- Accepted Position GDS SHA-256:
  `ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1`
- Execution method: one foreground density PVS DRC transaction

## Transaction And Physical Result

The transaction is attributable and complete, but the density result is not
clean. The PVS executable returned RC `0`, three report-level observations
agreed on the physical result `4 (4)`, all rule and geometry totals
reconciled, and all source, package, run, and diagnostic manifests passed.

```text
DENSITY_DRC_RC=0
STATUS=PASS
RESULT=PVS_DENSITY_DRC_NONZERO_RULE_DEBT_CLASSIFIED
OUTCOME_CLASS=ATTRIBUTABLE_NONZERO_RESULTS
PVS_WRAPPER_RC=8
PVS_TOOL_RC=0
PVS_BASE_DRC_STATUS=PASS
PVS_DENSITY_DRC_STATUS=FAIL
DRC_TOTAL_PRIMARY=4
DRC_TOTAL_EXPANDED=4
RULE_ANALYSIS_STATUS=PASS
DIAGNOSTIC_MANIFEST_RC=0
```

Transaction `PASS` means the nonzero result was captured and classified. It
does not convert the physical density gate to `PASS`.

## Correct Density Interpretation

The four results are `R1M1`, `R1M2`, `R1M3`, and `R1MT`, one each on MET1,
MET2, MET3, and METTP. Each requires at least 30 percent metal area relative
to the complete `951.440 x 659.680 um` layout extent, and each result polygon
is that complete extent. These are whole-window density checks, not four
localized minimum-area defects.

The immutable source analyzer output is preserved verbatim and labels these
rows `AREA` with generic localized repair guidance. That label is superseded
by this review. The analyzer now recognizes `ratio ... EXTENT area` as
`DENSITY` and directs the debt to the foundry fill and assembled chip-level
policy. No local polygon edit, comparison with TX MET1 markers, virtual
`DUMMY_FILL`, or density rerun is authorized by this snapshot.

The foundry semantic evidence classifies density as default-off,
post-fill/chip-level checking. The Position debt therefore remains open for a
formal assembled-fill disposition or an explicit waiver; it is not silently
closed and block promotion remains forbidden.

## Decision

Base DRC remains an attributable `0 (0)` PASS. Density remains an attributable
four-result FAIL. Exact-GDS LVS is an independent electrical gate and proceeds
immediately using the unchanged GDS, canonical package source, and package CDL.
If that comparison matches, Event OOC work may start while Position density
disposition remains tracked; Position promotion and signoff still require all
three independent contracts.
