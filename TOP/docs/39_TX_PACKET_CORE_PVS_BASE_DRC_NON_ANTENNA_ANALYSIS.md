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

## 2. Server Classification Result

The first read-only server extraction at commit `44f7ec51` proved that the PVS
run itself is complete and internally coherent. The corrected semantic
analysis at commit `03a430d75fcff3f301440c550c40096ffb3ea775` then passed in
this new external analysis directory:

```text
/sim/ksabra/SPADMIC_work/diagnostics/
tx_packet_pvs_waiver_20260716_130442/drc_analysis/
base_rule_classification_03a430d7_20260716_130727
```

The corrected status is:

```text
LABEL=SPADMIC_PVS_DRC_RULE_ANALYSIS
STATUS=PASS
RESULT=PVS_DRC_RULE_DEBT_CLASSIFIED
PVS_RC=0
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
DECLARED_RULECHECK_COUNT=1277
NONZERO_RULE_COUNT=2
DRC_TOTAL_PRIMARY=135
DRC_TOTAL_EXPANDED=135
RESULT_COUNT_RECONCILIATION=PASS
ASCII_ERROR_GEOMETRY_RECONCILIATION=PASS
SOURCE_RUN_MUTATION_AUTHORIZED=NO
OUTPUT_LOCATION_STATUS=OUTSIDE_IMMUTABLE_SOURCE_RUN
```

The only nonzero rules are:

| Rule | Primary | Share | Foundry description | Raw qualifier |
| --- | ---: | ---: | --- | --- |
| `R2M3P1` | 93 | 68.89% | `Maximum ratio of MET3 area to connected GATE area ... 400` | `(met3 output)` |
| `R1M3P1` | 42 | 31.11% | `Maximum ratio of MET3 area to connected GATE area ... 400` | `(gate output)` |

This description is the antenna mechanism: conductor area accumulated before
a gate connection is divided by the connected gate area and compared with a
maximum ratio. It is not a generic MET3 maximum-area rule and is not a
minimum-area rule.

The raw qualifiers are recorded exactly as emitted by the foundry error
database. They distinguish the two result presentations, but they do not
authorize an unsupported interpretation of the internal `R1` and `R2`
algorithms. The licensed XFAB rule manual or PVS result browser remains
authoritative for that finer distinction.

The corrected semantic partition is therefore:

```text
ANTENNA_RULE_COUNT=2
ANTENNA_PRIMARY_RESULT_COUNT=135
ANTENNA_EXPANDED_RESULT_COUNT=135
ANTENNA_GATE_AREA_RATIO_RULE_COUNT=2
NON_ANTENNA_RULE_COUNT=0
NON_ANTENNA_PRIMARY_RESULT_COUNT=0
NON_ANTENNA_EXPANDED_RESULT_COUNT=0
NON_ANTENNA_RESULT_STATUS=ZERO
```

The exact distinction between the foundry prefixes `R1` and `R2` must not be
guessed from their short names. That distinction requires the licensed XFAB
rule documentation or PVS result-browser metadata. Both rules are safely and
correctly classified as antenna-ratio checks from their executed descriptions.

## 3. Rejected First Classification

The first analyzer revision used this policy:

```text
ANTENNA_EXCLUSION_POLICY=EXPLICIT_RULE_NAME_OR_DESCRIPTION_ONLY
```

Because neither foundry description contains the literal word `antenna`, that
revision incorrectly produced:

```text
EXPLICIT_ANTENNA_PRIMARY_RESULT_COUNT=0
NON_ANTENNA_PRIMARY_RESULT_COUNT=135
```

The parsing, counts, hashes, geometry extraction, spatial bins, and Innovus
correlation from that run remain valid evidence. The semantic class and the
resulting advice to increase connected polygon area are rejected.

The rejected output directory must remain immutable:

```text
/sim/ksabra/SPADMIC_work/diagnostics/
tx_packet_pvs_waiver_20260716_130442/drc_analysis/
base_non_antenna_44f7ec51_20260716_122729
```

A corrected analyzer run must use a new output directory. It must not edit,
delete, or overwrite the rejected report because that report records a real
classification failure and the evidence that exposed it.

## 4. Antenna and Density Controls

There are three different antenna records and they must remain separate:

1. Innovus restored `21` antenna markers. They are an Innovus marker-database
   count and are not numerically equivalent to PVS results.
2. PVS base DRC reports `135` results across two fixed MET3-to-gate antenna
   ratio rules.
3. The PVS control contains `#UNDEFINE VAR_ANT_RATIO`, which disables an
   additional optional variable-ratio rule family.

The executed control also contains:

```text
#UNDEFINE DENSITY
#UNDEFINE VAR_ANT_RATIO
```

The corrected interpretation is:

```text
VAR_ANT_RATIO_STATE=UNDEFINED
VAR_ANT_RATIO_SCOPE=ADDITIONAL_OPTIONAL_RULE_FAMILY_ONLY
DENSITY_STATE=UNDEFINED
PVS_DENSITY_DRC_STATUS=NOT_RUN
```

`VAR_ANT_RATIO=UNDEFINED` does not disable the fixed `R1M3P1` and `R2M3P1`
checks that actually executed. Likewise, the base run cannot establish
density cleanliness because density was explicitly disabled.

The corrected classifier policy is:

```text
ANTENNA_CLASSIFICATION_POLICY=
EXPLICIT_TERM_OR_CONDUCTOR_AREA_TO_CONNECTED_GATE_AREA_RATIO
AMBIGUOUS_RULE_POLICY=RETAIN_AS_NON_ANTENNA_REVIEW
```

This remains conservative. An arbitrary ratio or rule prefix is not enough.
The semantic antenna classification requires either explicit antenna wording
or the specific conductor-area to connected-gate-area mechanism.

## 5. Authoritative Artifacts

The analyzer uses only run-local evidence:

```text
pvs_drc_status.rpt
replay_contract_status.rpt
output_isolation.rpt
external_references.rpt
pvsdrcctl
spadmic_tx_packet_core_drc.sum
spadmic_tx_packet_core_drc.err
```

The server extraction recorded:

```text
SUMMARY_SHA256=
5ac8db9c703410f9705425fe7144695f8e2d2810da68e82d9e9ecd4d888693f4
ASCII_ERROR_DATABASE_SHA256=
27e0b40af9abe5ed8b72a5591bf2eb93489a6120ba61e8063d8ce6a61f19f718
CONTROL_SHA256=
e07c7712ebb7b1b11f36974f67f5d1392e11db74ea41f2bd22bd191b097d968c
```

`spadmic_tx_packet_core_drc.sum` provides all rule counts and the final total.
The ASCII `spadmic_tx_packet_core_drc.err` provides, for every nonzero rule:

- the rule identifier;
- the foundry description;
- the rule-level count;
- every result geometry in database units.

The analyzer converts all result polygons to microns, computes bounding boxes
and centers, and requires each rule's geometry count to equal its summary
count. It fails closed if replay, output isolation, references, totals,
per-rule geometry, base-variant control state, or output immutability do not
reconcile.

## 6. Corrected Read-Only Analyzer Contract

The implementation is:

```text
TOP/pnr/scripts/analyze_pvs_drc_run.py
```

Each run writes a new external analysis directory containing:

```text
pvs_drc_analysis_status.rpt
pvs_drc_rule_inventory.tsv
pvs_drc_antenna_rules.tsv
pvs_drc_non_antenna_rules.tsv
pvs_drc_marker_geometry.tsv
pvs_drc_spatial_bins.tsv
pvs_innovus_marker_correlation.tsv
pvs_drc_non_antenna_analysis.md
```

Every inventory row includes both `classification` and
`classification_basis`. For the packet run, both rule rows must contain:

```text
classification=ANTENNA_RULE
classification_basis=CONDUCTOR_AREA_TO_CONNECTED_GATE_AREA_RATIO
category=ANTENNA
layer_or_object=MET3
```

`pvs_drc_non_antenna_rules.tsv` must contain only its header. Any nonzero data
row in that file is a correction failure for this exact immutable run.

## 7. Four Innovus Minimum-Area Markers

The known Innovus waiver table contains:

```text
n_9677
n_9693
n_9696
n_9697
```

The server analyzer expanded each box by `0.35 um` and found:

```text
INNOVUS_WAIVER_MARKER_COUNT=4
INNOVUS_WAIVER_MARKERS_WITH_PVS_HITS=0
PVS_RESULTS_OVERLAPPING_WAIVER_BOXES=0
```

This proves that none of the 135 PVS antenna-result bounding boxes overlaps
the four known Innovus MET1 minimum-area regions at the selected margin. The
PVS nonzero rule inventory also contains no MET1 minimum-area rule.

The correct gate separation is:

```text
INNOVUS_MET1_MIN_AREA_DEBT=4
PVS_BASE_ANTENNA_DEBT=135
PVS_BASE_NON_ANTENNA_DEBT=0
```

The zero correlation does not waive or prove physical repair of the four
Innovus markers. It proves that they are not the source of the 135-result PVS
failure and must be repaired and rechecked through their own Innovus/export
path.

## 8. Current Subblock State

For the exact provisional package:

```text
PVS_LVS_STATUS=MATCH
PVS_BASE_DRC_STATUS=FAIL
PVS_BASE_ANTENNA_RESULTS=135
PVS_BASE_NON_ANTENNA_RESULTS=0
PVS_DENSITY_DRC_STATUS=NOT_RUN
INNOVUS_MET1_MIN_AREA_MARKERS=4
FINAL_SIGNOFF_READY=NO
BLOCK_PROMOTION_AUTHORIZED=NO
```

The gate-by-gate interpretation is:

| Gate | State | Meaning |
| --- | --- | --- |
| Immutable handoff package | `PASS/CANDIDATE` | GDS, routed source, LEF, CDL preparation, pin parity, stream map, and standard-cell merge were audited |
| PVS LVS | `MATCH` | The exact provisional GDS and exact routed source are electrically equivalent |
| Innovus regular connectivity | `0` | No regular open or short was reported in the exported provisional state |
| Innovus special connectivity | `0` | No special-net connectivity violation was reported |
| PVS base non-antenna DRC | `0` | The executed base deck has no non-antenna result to repair |
| PVS base antenna DRC | `135 OPEN` | Two MET3-to-connected-gate ratio rules remain: 93 `R2M3P1` and 42 `R1M3P1` |
| Innovus MET1 minimum area | `4 OPEN` | Nets `n_9677`, `n_9693`, `n_9696`, and `n_9697` still require manual physical repair |
| PVS density | `NOT_RUN` | Density cleanliness is unknown because `DENSITY` was undefined |
| Final signoff | `NO` | Nonzero antenna, four Innovus markers, and missing density proof prevent promotion |

This is useful progress:

- electrical equivalence is proven for the exact compared package;
- no non-antenna PVS base-rule class remains to debug;
- the four Innovus minimum-area markers are isolated from the PVS antenna
  population;
- the remaining physical work is now separated into antenna, Innovus
  minimum-area, and density gates.

It is not signoff. The current PVS base DRC result remains a failure because
the 135 antenna results are real foundry-deck results.

The `MATCH` and antenna failure can coexist without contradiction. LVS checks
whether the extracted layout connectivity and devices agree with the source.
The antenna rules check whether manufacturing charge exposure is acceptable.
A net can be connected exactly as intended and still violate an antenna
ratio. Likewise, the four Innovus minimum-area shapes can remain electrically
connected while being too small for the routing rule.

## 9. Closure Sequence

If antenna is deferred for the immediate milestone, record that as a scoped
milestone exception, not as PVS base DRC clean. Then:

1. Preserve the matched GDS/source/CDL hashes as the electrical baseline.
2. Manually repair the four Innovus MET1 minimum-area markers in a new design
   state.
3. Re-export with the audited XH018 stream map and required JIHD merge.
4. Rerun Innovus DRC/connectivity and prove the four-marker exception retired.
5. Rerun PVS base DRC and classify antenna separately; final closure still
   requires zero unless an approved signoff waiver exists.
6. Run the density-enabled PVS variant and require zero.
7. Rerun LVS against the repaired GDS and require a new explicit `MATCH`.
8. Archive the new hashes and retire the provisional package.

For antenna closure, inspect `R1M3P1` and `R2M3P1` in the PVS result browser
and foundry documentation before editing. Candidate remedies include legal
route segmentation or layer hopping, antenna-diode insertion, reduced
pre-gate conductor area, or additional connected diffusion. The permitted
remedy is process- and library-dependent.

## 10. Required Final State

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
PVS_BASE_DRC_DEBT=OPEN_135_ANTENNA
PVS_BASE_NON_ANTENNA_DEBT=0
INNOVUS_MANUAL_MIN_AREA_FIX_REQUIRED=YES
BLOCK_PROMOTION_AUTHORIZED=NO
```
