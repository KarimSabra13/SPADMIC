# TX Packet Core PVS Base DRC Non-Antenna Analysis

## 1. Purpose

This document defines the read-only decomposition of the completed packet-core
PVS base DRC run after the provisional PVS LVS comparison reached an explicit
`MATCH`.

The immutable inputs are:

```text
PACKAGE=
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_tx_packet_core/
tx_packet_pvs_waiver_20260716_130442

PVS_BASE_DRC_RUN=
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_tx_packet_core/
tx_packet_pvs_waiver_20260716_130442/pvs/drc/
tx_packet_pvs_waiver_20260716_130442_pvs_drc_base_outputiso_13cc2e14

PVS_LVS_RUN=
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_tx_packet_core/
tx_packet_pvs_waiver_20260716_130442/pvs/lvs/
tx_packet_pvs_waiver_20260716_130442_pvs_lvs_execinputs_5bcaaf7d
```

The established gate state is:

```text
PVS_LVS_STATUS=MATCH
PVS_BASE_DRC_STATUS=FAIL
PVS_BASE_DRC_RESULTS=135
PVS_DENSITY_DRC=NOT_RUN
INNOVUS_TEMPORARY_MET1_MIN_AREA_MARKERS=4
FINAL_SIGNOFF_READY=NO
BLOCK_PROMOTION_AUTHORIZED=NO
```

The LVS match proves electrical equivalence only for the exact compared GDS,
routed source, and package-local standard-cell CDL. It does not waive one PVS
DRC result and does not transfer to a future repaired GDS.

## 2. What Must Be Classified

The PVS run completed successfully:

```text
PVS_RC=0
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
```

Three run-local artifacts agree on:

```text
Total DRC Results : 135 (135)
PVS_DRC_STATUS=FAIL
```

The next task is not another PVS run. It is a read-only decomposition of the
existing `135` into:

- every nonzero foundry rule;
- the rule description from the ASCII error database;
- primary and expanded result counts;
- every result polygon and bounding box in microns;
- semantic class such as area, spacing, enclosure, width, bend, or off-grid;
- spatial concentration;
- overlap with the four known Innovus MET1 minimum-area marker boxes;
- explicit antenna results, if the run contains any.

The source run must remain immutable.

## 3. Antenna Boundary

There are two different antenna contexts and they must not be mixed.

The provisional Innovus export retained `21` antenna markers in the restored
Innovus marker database. Those markers were excluded from the exact
non-antenna Innovus count used to isolate the four MET1 minimum-area errors.
They are not proof that PVS reports 21 antenna violations.

The PVS base control is a separate foundry-deck execution. The historical
template normally contains:

```text
#UNDEFINE DENSITY
#UNDEFINE VAR_ANT_RATIO
```

`VAR_ANT_RATIO` controls the additional variable-ratio antenna check. The
exact executed packet-core `pvsdrcctl` must still be inspected rather than
assumed.

The analysis policy is deliberately conservative:

```text
ANTENNA_EXCLUSION_POLICY=EXPLICIT_RULE_NAME_OR_DESCRIPTION_ONLY
AMBIGUOUS_RULE_POLICY=RETAIN_AS_NON_ANTENNA_REVIEW
```

A rule is removed from the non-antenna repair inventory only when its rule name
or foundry description explicitly contains an antenna term. A rule prefix such
as `A1...`, a ratio value, or a separate `antenna.ratio` artifact is not enough
to exclude it.

If the exact run reports:

```text
VAR_ANT_RATIO_STATE=UNDEFINED
EXPLICIT_ANTENNA_PRIMARY_RESULT_COUNT=0
NON_ANTENNA_PRIMARY_RESULT_COUNT=135
```

then the correct conclusion is that all 135 base-deck results remain in the
non-antenna repair inventory. That conclusion must come from the executed
control and rule descriptions, not from expectation.

## 4. Authoritative Artifacts

The analyzer uses the following run-local evidence:

```text
pvs_drc_status.rpt
replay_contract_status.rpt
output_isolation.rpt
external_references.rpt
pvsdrcctl
spadmic_tx_packet_core_drc.sum
spadmic_tx_packet_core_drc.err
```

`spadmic_tx_packet_core_drc.sum` provides all rule counts and the final total.
The ASCII `spadmic_tx_packet_core_drc.err` provides, for every nonzero rule:

- the rule identifier;
- the foundry description;
- the rule-level count;
- every result geometry in database units.

The first error-database line declares the layout top and database units. The
analyzer converts all result polygons to microns, computes bounding boxes and
centers, and requires the geometry count for each rule to equal the summary
count.

The analysis fails closed if:

- replay or output isolation did not pass;
- PVS tool RC is not zero;
- the run is not the classified nonzero base DRC;
- external references are missing;
- the summary total is not exactly the expected `135 (135)`;
- per-rule counts do not sum to the total;
- a nonzero rule is absent from the ASCII error database;
- a rule header count differs from the summary;
- the number of parsed result polygons differs from the rule count;
- `DENSITY` is not explicitly undefined;
- the requested output directory is inside the immutable PVS run.

## 5. Read-Only Analyzer

The implementation is:

```text
TOP/pnr/scripts/analyze_pvs_drc_run.py
```

It writes a new external analysis directory containing:

```text
pvs_drc_analysis_status.rpt
pvs_drc_rule_inventory.tsv
pvs_drc_non_antenna_rules.tsv
pvs_drc_explicit_antenna_rules.tsv
pvs_drc_marker_geometry.tsv
pvs_drc_spatial_bins.tsv
pvs_innovus_marker_correlation.tsv
pvs_drc_non_antenna_analysis.md
```

The generated Markdown report is the human review document. The TSV files are
the source of truth for sorting, filtering, coordinate review, and scripted
correlation.

## 6. Rule Interpretation

The analyzer derives a repair-oriented category from the foundry description.
The category is an investigation aid, not a foundry-rule replacement.

| Category | Meaning | First review action |
| --- | --- | --- |
| `AREA` | Polygon area below a minimum | Compare with the four known MET1 boxes; add connected area locally |
| `SPACING_OR_NOTCH` | Gap or notch below minimum | Inspect both sides of the flagged polygon before moving metal |
| `ENCLOSURE` | Via or stripe lacks surrounding metal | Extend the correct enclosing layer or regenerate the via construct |
| `WIDTH_OR_SIZE` | Wire, via, or stripe has illegal dimensions | Check streamout shape semantics and regenerate the exact object |
| `BEND_OR_ANGLE` | Polygon or stripe has an illegal corner | Replace the originating malformed geometry, not broad routing |
| `OFFGRID` | Geometry is not on the manufacturing grid | Snap the source geometry and re-export with the same stream map |
| `SKEW_EDGE` | Edge angle is illegal | Replace with an allowed orthogonal or foundry-approved angle |
| `CONNECTIVITY` | Short or related electrical geometry defect | Treat separately from spacing-only repair |
| `DENSITY` | Fill/density rule | Handle only in the later density-enabled variant |
| `OTHER_PHYSICAL_RULE` | No safe generic category | Use the exact foundry description and result browser |

Repair priority is not simply the largest count. A high-count repeated rule
inside merged standard cells may indicate a streamout, merge, or rule-deck
configuration problem. A low-count top-routing rule may be the fastest real
manual repair. The spatial bins and repeated coordinates help distinguish
those cases.

## 7. Innovus Four-Marker Correlation

The known temporary Innovus waiver table is:

```text
/sim/ksabra/SPADMIC_work/innovus/
innovus_tx_packet_min_area_waiver_export_20260716_130442/
blocks/tx_packet_core/reports/temporary_drc_waiver.tsv
```

It contains these four nets:

```text
n_9677
n_9693
n_9696
n_9697
```

The analyzer expands each Innovus box by a small review margin and checks every
PVS result bounding box for overlap. A hit is direct spatial evidence that a
PVS result is associated with that local region.

A zero overlap does not prove that the Innovus error disappeared. The PVS deck
may flag a different polygon footprint, enclosure, or neighboring edge.
Therefore correlation is evidence for review, not an acceptance gate.

## 8. Manual Repair Sequence

After the server analysis is generated:

1. Confirm count reconciliation and the exact antenna/density control state.
2. Read `pvs_drc_non_antenna_rules.tsv` sorted by result count.
3. Inspect `pvs_drc_spatial_bins.tsv` for repeated structures and hotspots.
4. Inspect `pvs_innovus_marker_correlation.tsv` for the four known MET1 areas.
5. Review each foundry rule and coordinate in the PVS result browser.
6. Determine whether each class originates in top routing, generated vias,
   merged standard cells, labels, or streamout configuration.
7. Fix one physical rule class at a time in a new design state.
8. Re-export GDS with the audited XH018 stream map and JIHD merge.
9. Run base PVS DRC and require explicit zero.
10. Run density-enabled PVS DRC and require explicit zero.
11. Rerun LVS against the repaired GDS and require a new explicit `MATCH`.
12. Retire the four-marker Innovus exception only after the repaired state
    passes its own Innovus and PVS gates.

The current LVS run remains valuable baseline evidence. It proves that any
later LVS mismatch was introduced after the provisional matched GDS, but it
cannot sign off the repaired GDS.

## 9. Required Final State

The packet core is not promotable until a future state proves:

```text
INNOVUS_NON_ANTENNA_DRC=0
PVS_BASE_DRC=0
PVS_DENSITY_DRC=0
PVS_LVS_STATUS=MATCH
TEMPORARY_DRC_WAIVER_RETIRED=YES
FINAL_SIGNOFF_READY=YES
```

Until then:

```text
LVS_ELECTRICAL_EQUIVALENCE_BASELINE=MATCH
PVS_BASE_DRC_DEBT=OPEN
MANUAL_DRC_FIX_REQUIRED=YES
BLOCK_PROMOTION_AUTHORIZED=NO
```
