# MPTDC O13 Phase Quality Review For Density65

Status: `O13_RAW_RO_LOAD_SAFE`, `TOPOLOGY_MATCHED`,
`PHASE_QUALITY_REVIEW_REQUIRED`, `NOT_FINAL_SIGNOFF`

## Scope

This note interprets the O13 phase-distribution evidence for the density65
candidate. O13 is physical feasibility/debug evidence for the phase tree:

```text
RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric
```

It does not waive timing, phase matching, characterization, power, or final
signoff.

## Current Density65 Clean Evidence

From `mptdc_final_typical_pnr_density65_clean_20260612_171922_o13_phase_report`:

- O13 wrapper completed with `REPORT_COMPLETE=YES`.
- Raw RO rows: 16.
- Matched raw RO rows: 16.
- Missing raw RO rows: 0.
- Raw fanout-1 rows: 16.
- Final driver output rows: 16.
- Matched final driver output rows: 16.
- Topology match: 16 of 16.
- Raw RO load label: 16 `OK_STRICT`.
- Max measured raw RO source load: reported as `0.00 fF`.
- Max measured final driver output load: about `753.00 fF` at fast tap 4.

## Interpretation

The large `753 fF` value is on the `BUHDX12` final driver output. It is not the
raw analog RO source load. That distinction is central:

- raw RO load is the analog-sensitive constraint;
- raw RO load is fixed and fanout-1 in the current evidence;
- final-driver output load is the digital phase-fabric load driven by BUHDX12;
- high final-driver load may affect transition, delay, skew, power, and phase
  matching, but it is not by itself an RO macro overload.

Therefore the O13 result should not be rejected just because final-driver output
capacitance is much larger than the raw RO budget.

## Required Phase-Quality Checks

Before using O13 evidence in a closure statement, review:

| Item | Required evidence | Reject if |
|---|---|---|
| Raw RO source load | `ro_phase_raw_pin_loads*.csv` | missing rows, fanout > 1, over strict budget |
| Topology | `phase_buffer_topology_summary.md` | not 16/16 BUHDX4 -> BUHDX12 |
| Final-driver output transition | `drv_max_transition.rpt`, O13 output load CSV | transition violates DRV or is unknown at decision time |
| Tap-to-tap load balance | `phase_buffer_output_loads_xlibd.csv` | mismatch is too large for phase-quality assumptions |
| Slow/fast symmetry | O13 placement and route summaries | systematic slow0 or fast tap asymmetry is unexplained |
| Route length/skew | `phase_buffer_route_summary.csv` | route mismatch is incompatible with phase assumptions |
| Placement | `phase_buffer_placement.csv` and summary | placement rows missing or topology not physically localized |
| DRV max cap/fanout | `drv_max_cap.rpt`, `drv_max_fanout.rpt` | final driver violates library limits without reviewed rationale |

## Current Review Items

The current O13 summary still reports:

```text
PLACEMENT_QUANTIFIED=NO
TIMING_DECISION_QUALITY=NO
```

That means the phase tree is topologically correct and raw RO safe, but not yet
a full phase-quality signoff package.

The final-driver output budget labels are not clean:

- `WARN_OVER_CN`: observed in some rows;
- `FAIL_HIGH_LOAD`: observed in some rows;
- `CRITICAL`: observed in several rows.

These labels should drive transition/load-balance review, not a rollback to the
old raw RO topology.

## Current Decision

```text
O13_RAW_RO_LOAD_SAFE=YES
O13_TOPOLOGY_MATCHED=YES
O13_PHASE_QUALITY_SIGNOFF=NO
```

Use O13 as positive physical evidence for the density65 candidate, while keeping
phase-quality review open until transition, load balance, route symmetry, and
placement quantification are explicitly reviewed.
