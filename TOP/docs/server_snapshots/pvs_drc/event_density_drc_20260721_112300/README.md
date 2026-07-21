# Event Coordinator Density PVS DRC Classified-Debt Snapshot

- Diagnostic ID: `event_pvs_drc_density_execution_20260721_112300`
- Diagnostic root:
  `/sim/ksabra/SPADMIC_work/diagnostics/event_pvs_drc_density_execution_20260721_112300`
- Repository branch: `SPADMIC_test`
- Repository commit: `66ea5eb65de37387a023a77fc4239f1dfab6c6cf`
- Accepted Event GDS SHA-256:
  `837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857`
- Execution method: one foreground density PVS DRC transaction

## Transaction And Physical Result

The transaction completed normally and all result, source, package, run, and
diagnostic checks passed. The physical density gate did not pass: PVS reported
four primary and four expanded results.

```text
STATUS=PASS
RESULT=EVENT_PVS_DENSITY_DRC_NONZERO_RULE_DEBT_CLASSIFIED
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

Transaction `PASS` means the nonzero result was attributable and fully
classified. It does not convert the density physical gate to `PASS`.

## Rule Classification

The four results are `R1M1`, `R1M2`, `R1M3`, and `R1MT`, one each on MET1,
MET2, MET3, and METTP. Each checks a minimum 30 percent metal-area ratio over
the complete Event extent, and each result has aggregate bounding box
`0.000000 0.000000 237.360000 219.520000` um. They are whole-window density
debt, not four localized minimum-area defects. Antenna results remain zero.

No local geometry repair, DRC rerun, virtual dummy fill, or waiver is
authorized here. The debt remains open for assembled-fill disposition or a
formal exact-rule waiver. Exact-GDS LVS is a separate electrical-equivalence
gate and may run once against the unchanged package GDS, canonical LVS source,
and standard-cell CDL. Promotion and signoff remain unauthorized.
