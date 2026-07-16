# TX Packet Core Provisional DRC Waiver And PVS LVS Execution

Status: `IMPLEMENTED_LOCAL_SERVER_EXECUTION_PENDING`

This document defines the deliberate schedule exception used to obtain an
early, hash-bound PVS LVS result for `spadmic_tx_packet_core` while four known
Innovus MET1 minimum-area violations remain open. The exception is narrow,
temporary, and diagnostic. It does not convert the block into a DRC-clean or
signoff-ready state.

The immediate objective is:

```text
OBJECTIVE=EXPORT_EXACT_FOUR_MARKER_STATE_AND_RUN_INDEPENDENT_PVS_DRC_LVS
LVS_ACCEPTANCE=EXPLICIT_REPORT_LEVEL_MATCH_ONLY
```

The non-objectives are equally important:

```text
PVS_DRC_WAIVER=NO
BLOCK_PROMOTION_AUTHORIZED=NO
FINAL_SIGNOFF_READY=NO
```

## 1. Source State And Decision

Step 27 revision R6 proved the following facts in one isolated Innovus
process:

```text
SOURCE_CHECKPOINT=05_postroute_export.enc.dat
BASE_PATCH_ATTEMPTED_COUNT=6
BASE_PATCH_APPLIED_COUNT=6
BASE_DRC_VIOLATION_COUNT=4
BASE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0
BASE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0
BASE_EXCLUDED_ANTENNA_MARKER_COUNT=21
BASE_MARKER_DATABASE_TOTAL=25
BASE_MIN_AREA_NETS=n_9677 n_9693 n_9696 n_9697
```

The later four chained endpoint edits did not remove or change those markers.
The Step 27 database was intentionally not saved or exported. Therefore the
old packet-core GDS does not represent the reviewed four-marker state and
cannot be used for this LVS experiment.

Step 28 revision R7 remains a valid unexecuted repair experiment. It is
skipped for this schedule exception:

```text
STEP28_NORMALIZED_VIA_SIDE_TRIAL=SKIPPED_BY_OPERATOR_TEMPORARY_WAIVER_DECISION
```

This is not evidence that R7 would fail. It records only that the operator
chose early PVS LVS diagnosis before another physical repair trial.

## 2. Exact Temporary Waiver Inventory

The export gate accepts exactly four markers and no wildcard class. Every
marker must be a regular-wire `MET1 / Geometry / Minimal_Area` violation with
actual area `0.17770000 um^2` and required area `0.20200000 um^2`.

| Net | Exact marker box | Actual | Required |
| --- | --- | ---: | ---: |
| `n_9696` | `719.38 158.68 720.07 158.91` | `0.17770000` | `0.20200000` |
| `n_9693` | `209.78 201.73 210.47 201.96` | `0.17770000` | `0.20200000` |
| `n_9697` | `662.82 192.77 663.51 193.00` | `0.17770000` | `0.20200000` |
| `n_9677` | `1666.09 201.73 1666.78 201.96` | `0.17770000` | `0.20200000` |

The waiver identity is:

```text
WAIVER_ID=TX_PACKET_MET1_MIN_AREA_LVS_DIAGNOSTIC_20260716
WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY
WAIVER_MARKER_COUNT=4
WAIVER_NETS=n_9677 n_9693 n_9696 n_9697
EXPIRY_EVENT=BEFORE_FINAL_PVS_DRC_AND_BLOCK_PROMOTION
MANUAL_FIX_REQUIRED=YES
```

Any changed net, box, layer, type, subtype, actual area, marker count,
connectivity count, antenna count, or marker-database total aborts the export.
The flow cannot silently widen the exception.

## 3. Fresh Export Contract

`run_innovus_ooc_min_area_waiver_export.tcl` launches one fresh Innovus
process and restores the original routed checkpoint exactly once. Before any
edit it requires the immutable six-marker baseline:

```text
PRE_DRC_VIOLATION_COUNT=6
PRE_MIN_AREA_NETS=n_9677 n_9693 n_9696 n_9697 n_9706 n_9721
PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0
PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0
PRE_EXCLUDED_ANTENNA_MARKER_COUNT=21
PRE_MARKER_DATABASE_TOTAL=27
```

It then replays only the six validated R6 base edits:

| Net | Start | End | Requested width |
| --- | --- | --- | ---: |
| `n_9696` | `719.88 158.76` | `719.32 158.76` | `0.28` |
| `n_9693` | `210.28 201.88` | `209.72 201.88` | `0.28` |
| `n_9697` | `663.32 192.92` | `662.76 192.92` | `0.28` |
| `n_9677` | `1666.28 201.88` | `1666.84 201.88` | `0.28` |
| `n_9721` | `1792.84 212.52` | `1792.28 212.52` | `0.28` |
| `n_9706` | `1827.00 212.52` | `1827.56 212.52` | `0.28` |

All six contracts must validate the original marker, `VIA1_o`, MET2 endpoint,
source Q pin, direction, and source-instance containment. Acceptance requires
six applied edits, 24 successful Wire Editor commands, no command failure,
the exact four-marker inventory above, and zero regular and special
connectivity violations.

Only after those gates pass does the process:

1. Write `temporary_drc_waiver.rpt` and
   `temporary_drc_waiver.tsv`.
2. Save `05_min_area_waiver_export.enc`.
3. Export DEF, routed netlist, power-ground netlist, LEF, and abstract LEF.
4. Stream mapped GDS with the official stream map and merged JIHD GDS.
5. Run the mapped/merged GDS audit.
6. Emit `canonical_tx_lvs_waiver_gate.rpt`.

The exported state does not include the rejected R6 chained edits or the
unexecuted R7 edits.

## 4. Immutable Package Contract

The package uses qualification profile `canonical_tx_lvs_waiver`. Staging
requires all of the following:

```text
TEMPORARY_DRC_WAIVER_STATUS=PASS
TEMPORARY_DRC_WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY
TEMPORARY_DRC_WAIVER_MARKER_COUNT=4
PVS_DRC_WAIVER=NO
LVS_DIAGNOSTIC_ONLY=YES
MANUAL_DRC_FIX_REQUIRED=YES
BLOCK_PROMOTION_AUTHORIZED=NO
GDS_LAYER_MAP_STATUS=PASS
SIGNOFF_READY=NO
```

`package.json` records the waiver metadata and hashes of:

- `canonical_tx_lvs_waiver_gate.rpt`;
- `temporary_drc_waiver.rpt`;
- `gds_export_audit.rpt`;
- the exported GDS;
- the raw PG netlist;
- the canonical filtered LVS source;
- the package-local official JIHD CDL;
- every other copied report and log.

`audit_innovus_handoff.py` independently rechecks those fields and hashes.
The package is immutable. A failed package or PVS run is retained; corrected
inputs require a new session/version.

## 5. PVS DRC Is Independent And Unwaived

The provisional Innovus waiver is not translated into a PVS rule waiver,
marker filter, or pass override. PVS base DRC runs against the exact staged
GDS and reports its real result:

```text
PVS_DRC_WAIVER=NO
```

The Phase 3 driver distinguishes:

```text
PVS_BASE_DRC_ZERO
PVS_BASE_DRC_NONZERO_RECORDED_LVS_STILL_AUTHORIZED
PVS_BASE_DRC_EXECUTION_OR_CLASSIFICATION_FAILED
```

The second result means the DRC replay completed and produced an explicit
nonzero result. It does not mean PVS DRC passed. It authorizes only the
independent LVS diagnostic. A missing result, unknown result, failed replay
contract, or stale artifact does not authorize advancement.

Density DRC is outside this fast diagnostic sequence. It remains required
after the four markers are physically fixed and the waiver is retired.

## 6. LVS Is Independent Of DRC

LVS depends on the immutable staged package, not on PVS DRC zero. It compares:

```text
layout GDS   package/gds/spadmic_tx_packet_core.gds
layout top   spadmic_tx_packet_core
source       package/netlist/spadmic_tx_packet_core.lvs.pg.v
source top   spadmic_tx_packet_core
cell CDL     package/pdk/xh018_D_CELLS_JIHD.cdl
```

Create a fresh canonical PVS LVS GUI template from these exact package
artifacts. Do not reuse the historical `spadmic_tx_packet_core_HV` LVS
template unchanged. The historical template had different top names and
artifact paths and did not prove the new package-local source/CDL contract.

The replay wrapper requires exact path/top replacements and a passing replay
contract. PVS return code, empty error log, extracted-net counts, or DRC zero
cannot substitute for the LVS report.

Only this result passes:

```text
PVS_LVS_STATUS=MATCH
RESULT=PVS_LVS_EXPLICIT_MATCH
```

`MISMATCH`, `UNKNOWN`, missing report, missing CDL, stale path, or replay
contract failure remains a failed LVS gate.

## 7. Result Matrix

| PVS DRC | PVS LVS | Interpretation |
| --- | --- | --- |
| zero | `MATCH` | Early LVS objective achieved; Innovus waiver still open; no promotion |
| nonzero | `MATCH` | Early LVS objective achieved with DRC debt open; no promotion |
| zero | `MISMATCH` | Connectivity/source/layout root cause required before closure |
| nonzero | `MISMATCH` | Both DRC debt and LVS mismatch are open |
| not run/unknown | `MATCH` | LVS diagnostic may be recorded; PVS DRC still mandatory |
| any | unknown/missing | LVS objective not achieved |

No row in this table is final signoff while the four-marker waiver exists.

## 8. Server Execution Gates

The flow is intentionally separate from canonical Phase 2:

```text
00_init
01_waiver_export
02_stage_handoff
03_pvs_drc_base
04_pvs_lvs
05_summary
```

Run one command per gate:

```bash
bash TOP/ci/server_run_tx_packet_pvs_waiver.sh init <expected-head>
bash TOP/ci/server_run_tx_packet_pvs_waiver.sh waiver-export
bash TOP/ci/server_run_tx_packet_pvs_waiver.sh stage
bash TOP/ci/server_run_tx_packet_pvs_waiver.sh pvs-drc-base
```

Before LVS, create the fresh GUI template and export:

```bash
export SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE=/absolute/fresh/template
```

If the template embeds paths or top names different from the staged package,
also export the exact old values found in the template:

```bash
export SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE_GDS=/old/embedded/layout.gds
export SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE_SOURCE=/old/embedded/source.v
export SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE_LAYOUT_TOP=old_layout_top
export SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE_SOURCE_TOP=old_source_top
export SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE_CDL=/old/embedded/cells.cdl
```

Then run:

```bash
bash TOP/ci/server_run_tx_packet_pvs_waiver.sh pvs-lvs
bash TOP/ci/server_run_tx_packet_pvs_waiver.sh summary
```

The LVS command requires only `02_stage_handoff=PASS`; it does not require
`03_pvs_drc_base=PASS`.

## 9. Manual Repair And Waiver Retirement

The temporary exception expires before any block promotion. Closure requires
all of these steps:

1. Fix all four MET1 minimum-area violations physically.
2. Confirm Innovus DRC zero with no waiver record.
3. Confirm regular and special connectivity zero.
4. Export a new mapped/merged GDS and PG netlist from the repaired state.
5. Stage a new immutable package using the normal `canonical_tx` profile.
6. Run PVS base DRC and require explicit zero.
7. Run PVS density DRC and require explicit zero.
8. Rerun PVS LVS against the repaired package and require explicit `MATCH`.
9. Archive the provisional package as diagnostic evidence.
10. Mark the waiver retired and only then evaluate block promotion.

An LVS `MATCH` from the provisional package is useful evidence that logical
connectivity is aligned before manual geometry work. It does not transfer to
the repaired GDS hash; LVS must be rerun after the physical fix.

## 10. Commands And Conclusions Not To Reuse

- Do not run PVS on the old packet-core GDS and call it the four-marker state.
- Do not export the rejected Step 27 chained state.
- Do not infer that Step 28 is unnecessary or ineffective; it was skipped.
- Do not turn the four Innovus markers into a PVS DRC waiver.
- Do not blanket-waive all MET1 minimum-area results.
- Do not call a completed nonzero PVS DRC run `PASS`; call it classified
  nonzero evidence.
- Do not infer LVS `MATCH` from process return code.
- Do not reuse an LVS result after changing the GDS, netlist, CDL, or replay
  controls.
- Do not promote `spadmic_tx_packet_core` while
  `WAIVER_RETIREMENT_REQUIRED=YES`.
