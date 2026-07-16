# TX Packet Core Provisional DRC Waiver And PVS LVS Execution

Status: `PROVISIONAL_LVS_MATCH_ACHIEVED_DRC_DEBT_OPEN`

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

Prefer a fresh canonical PVS LVS GUI template from these exact package
artifacts. Do not reuse the historical `spadmic_tx_packet_core_HV` LVS
template unchanged. The historical template had different top names and
artifact paths and did not prove the new package-local source/CDL contract.

For the urgent diagnostic only, the immutable historical template may be used
as a rule-launch scaffold after the current replay code force-rewrites and
proves every executable layout/source/CDL/top/output path. This exception does
not reuse the historical GDS, source, results, or verdict.

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

Before LVS, select the immutable GUI template and export:

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

## 11. First Server Attempt Failure And Repair

The first `01_waiver_export` attempt used report-driver head
`b8fa0c8c30e5b1513e39d921421333a6d12e7aa7` and immutable run root:

```text
/sim/ksabra/SPADMIC_work/innovus/
innovus_tx_packet_min_area_waiver_export_20260716_123932
```

The source checkpoint restored, but no waiver status report, GDS, netlist,
LEF, or DEF was produced. The wrapper therefore correctly emitted:

```text
STATUS=FAIL
RESULT=PROVISIONAL_WAIVER_EXPORT_NOT_ACCEPTED
GDS_AUDIT_RC=NOT_RUN
```

The root cause was in `mw_validate_rows`. A dynamic regular expression was
placed in Tcl double quotes:

```text
"Actual:[[:space:]]+..."
```

Tcl interprets square brackets inside double quotes as command substitution.
The POSIX regex class was therefore executed as command `:space:`, producing:

```text
invalid command name ":space:"
```

This was a control-script failure, not a design, DRC, connectivity, GDS, or
PVS result. Nothing from the failed run is eligible for staging.

The repair:

1. Uses a braced static regex to extract numeric actual and required areas.
2. Compares the extracted values numerically at `1e-9` tolerance.
3. Catches pre- and post-edit marker-classification errors.
4. Writes phase status before restore, verification, replay, and export.
5. Preserves a nonzero child-driver shell status when a gate fails.
6. Adds a direct `tclsh` regression reproducing the marker message.

The failed run remains immutable negative evidence. Rerun from a new Phase 3
session and new run/package identifiers; do not delete or reuse the failed
directory.

## 12. First PVS DRC Replay Reference-Scanner Failure

The corrected export and immutable staging both passed in Phase 3 session:

```text
tx_packet_pvs_waiver_20260716_124911
```

The package audit, source preparation, pin parity, standard-cell CDL
resolution, mapped/merged GDS audit, and strict DRC replay contract all
passed. The first `03_pvs_drc_base` attempt then stopped before invoking PVS:

```text
STATUS=FAIL
RESULT=PVS_BASE_DRC_EXECUTION_OR_CLASSIFICATION_FAILED
PVS_WRAPPER_RC=1
PVS_DRC_STATUS=MISSING
REPLAY_CONTRACT_STATUS=PASS
```

The external-reference scanner searched every copied text file for absolute
paths but did not remove PVS/C comments first. A rule-deck separator beginning
with `//===` was therefore interpreted as absolute path `//===`. The
reference report recorded:

```text
DIRECTORY=//
MISSING=//===
```

`spadmic_pvs_require_external_references` correctly rejected the apparent
missing path, so `run.pvs` was never executed and no `pvs_drc_status.rpt` was
created. This tuple is not DRC-zero, DRC-nonzero, or a deck result. It is a
pre-execution replay-control failure.

The repair removes `//` line comments and `/* ... */` block comments before
absolute-path extraction, preserves quoted live paths, and defensively
rejects double-slash tokens from the reference set. The regression fixture
contains both an exact separator and commented-out missing paths and requires
that none appear in `external_references.rpt`.

The failed PVS run directory remains immutable negative evidence. Because the
active Phase 3 session is bound to its original report-driver head and fixed
run identifier, the corrected driver must start a fresh Phase 3 session with
new export, package, and PVS run identifiers.

## 13. Second PVS DRC Replay Output-Isolation Failure

Phase 3 session `tx_packet_pvs_waiver_20260716_130442` passed the corrected
reference scanner, waiver export, mapped/merged GDS audit, immutable staging,
source preparation, pin parity, and standard-cell CDL resolution. PVS then
returned zero, but the run-local parser reported:

```text
PVS_RC=0
PVS_DRC_STATUS=UNKNOWN
EVIDENCE=NONE
PARSE_RC=8
RESULT=PVS_BASE_DRC_EXECUTION_OR_CLASSIFICATION_FAILED
```

This is not DRC zero. It is also not a classified nonzero result. The strict
parser found no run-local `Total DRC Results` line and correctly refused to
infer a result from process return code.

The external-reference inventory had no missing paths, but it exposed a
different contract gap. The selected `_HV` template still referred to the
historical sibling execution directory:

```text
/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/
layoutverification/pvs_drc/spadmic_tx_packet_core
```

That directory contained the control file, cell tree, historical DRC error
database, and other GUI-run artifacts. The old replay contract patched the
copied GDS/top text but did not require the GUI-generated absolute `cd`,
`-control`, `-cell_tree`, summary, or result-database paths to point into the
new immutable run. Therefore `PVS_RC=0` could describe execution whose reports
were generated outside the package. With no attributable run-local summary,
the design result remains unknown.

The corrected replay contract now:

1. Discovers both the selected template root and the actual GUI execution
   root embedded in `run.pvs`.
2. Relocates both roots after exact GDS/source/CDL replacements.
3. Forces the working directory, control, cell tree, and rule files to copied
   run-local paths.
4. Copies and hashes an externally referenced cell tree when the selected
   template does not contain one.
5. Forces DRC summary and error-database outputs into the immutable run.
6. Forces LVS report, ERC report/database, SVDB, and extracted SPICE outputs
   into the immutable run.
7. Writes `output_isolation.rpt` and records its PASS state in the replay
   contract.
8. Writes `pvs_result_evidence_inventory.rpt` when parsing results.
9. Rejects conflicting DRC totals instead of choosing one by traversal order.
10. Requires underlying `PVS_RC=0` before a report-level nonzero total can be
    accepted as classified DRC debt.

The immutable `130442` DRC directory remains negative replay evidence. Do not
reparse an external historical summary and attach it to this package.

Because `01_waiver_export` and `02_stage_handoff` both passed and the package
inputs are independently hashed, a replay-only diagnostic retry may reuse the
exact `130442` package without rerunning Innovus. This exception requires:

- the corrected replay commit pinned by `EXPECTED_HEAD`;
- a new immutable PVS run ID;
- a fresh package audit by `run_pvs_drc_handoff.sh`;
- unchanged package GDS/source/CDL hashes;
- no edit or deletion of the failed PVS directory.

The replay-only retry does not rewrite the old Phase 3 status, authorize block
promotion, or create a formal `05_summary`. Use a fresh Phase 3 session later
if a complete driver-owned status chain is required. For the urgent DRC/LVS
diagnostic, require all three independent conditions in the new PVS run:

```text
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
PVS_DRC_STATUS=PASS or FAIL with one unique Total DRC Results count
```

Only after that classification should the operator proceed to the independent
diagnostic LVS gate. The four Innovus MET1 markers remain open manual-fix debt
regardless of the PVS result.

## 14. Replay-Only Base DRC Classification

Commit `13cc2e14d1955dfb294f089d450f285b124c2ac8` was replayed against the
already staged and hash-audited package:

```text
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/
spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442
```

The retry used a new immutable run:

```text
pvs/drc/
tx_packet_pvs_waiver_20260716_130442_pvs_drc_base_outputiso_13cc2e14
```

The replay contract and output-isolation reports both passed. PVS itself
returned zero, and three independently scanned run-local text artifacts
reported the same total:

```text
PVS_RC=0
PVS_DRC_STATUS=FAIL
DRC_TOTAL_MATCH_COUNT=3
DRC_TOTAL_PRIMARY=135
DRC_TOTAL_EXPANDED=135
Total DRC Results : 135 (135)
```

The evidence sources were `.drcSummaryReport`, `pvs.stdout.log`, and
`spadmic_tx_packet_core_drc.sum`. The parser therefore classified an
attributable nonzero base-DRC result rather than an infrastructure failure.
Wrapper RC `8` is the expected fail-closed classification for nonzero DRC.

This result is not the four-marker Innovus waiver translated into PVS. The
PVS foundry deck independently reports `135` results over the exported GDS.
No PVS waiver or result filter was used. The rule-by-rule distribution still
needs separate review, density DRC has not run, and:

```text
PVS_DRC_WAIVER=NO
MANUAL_DRC_FIX_REQUIRED=YES
FINAL_SIGNOFF_READY=NO
BLOCK_PROMOTION_AUTHORIZED=NO
```

The shell probe also attempted to tail a nonexistent
`drcSummaryReport.txt`. That message is harmless; the real generated summary
is `spadmic_tx_packet_core_drc.sum`, and its `135 (135)` total agrees with the
two other run-local evidence sources.

Per the approved result matrix, classified nonzero base DRC authorizes the
independent diagnostic LVS. It does not authorize density DRC omission,
waiver retirement, signoff, or promotion.

## 15. Historical LVS Template Executable-Input Gap

The immutable historical LVS template is:

```text
/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/
PvsLVS/spadmic_tx_packet_core_HV
```

Its executable `pvslvsctl` contains one Verilog source:

```text
schematic_path ".../tx_packet_core.routed.pg.v" verilog;
```

It does not contain an executable Spice/CDL `schematic_path`. The GUI preset
mentions an OA-generated `spadmic_tx_packet_core_HV.cdl`, but that preset
field is not proof that batch `pvslvsctl` reads the package-local official
JIHD CDL. Merely finding a CDL path anywhere in the copied template was
therefore an insufficient replay contract.

The exact historical values are:

```text
TEMPLATE_GDS=
/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PvsLVS/
spadmic_tx_packet_core_HV/spadmic_tx_packet_core_HV.gds

TEMPLATE_SOURCE=
/sim/ksabra/SPADMIC_work/oa_signoff/tx_packet_core_HV_20260710_105525/
netlist/tx_packet_core.routed.pg.v

TEMPLATE_LAYOUT_TOP=spadmic_tx_packet_core_HV
TEMPLATE_SOURCE_TOP=spadmic_tx_packet_core

TEMPLATE_PRESET_CDL=
./PvsLVS/spadmic_tx_packet_core_HV/spadmic_tx_packet_core_HV.cdl
```

`TEMPLATE_PRESET_CDL` is replaced only to remove the stale GUI preset value.
The new executable Spice directive is independently forced from the staged
package path; it is not inferred from that old preset.

The corrected replay now:

1. Forces exactly one executable `layout_path` to the staged canonical GDS.
2. Requires exactly one executable Verilog `schematic_path` and rewrites it
   to `spadmic_tx_packet_core.lvs.pg.v`.
3. Requires exactly one executable Spice/CDL `schematic_path`.
4. Inserts the package-local `xh018_D_CELLS_JIHD.cdl` directive when the
   historical control has none.
5. Rejects multiple Verilog or Spice/CDL directives instead of guessing which
   inputs define the comparison.
6. Records the exact input paths and `REPLACED_EXISTING` or `ADDED_MISSING`
   actions in `output_isolation.rpt`.
7. Rechecks that the executable control contains only the canonical source
   and CDL paths before PVS starts.

This makes the historical directory usable only as an immutable foundry-rule
launcher. The replay still replaces layout top
`spadmic_tx_packet_core_HV` with `spadmic_tx_packet_core`, source top remains
`spadmic_tx_packet_core`, all generated outputs stay in a new package-local
run, and only an explicit report-level `MATCH` passes.

## 16. Explicit Provisional LVS Match

Commit `5bcaaf7de91286729b9ef1e81a966004d7e6d699` ran the corrected executable-
input replay against the already staged, hash-audited package:

```text
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/
spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442
```

The new immutable LVS run is:

```text
pvs/lvs/
tx_packet_pvs_waiver_20260716_130442_pvs_lvs_execinputs_5bcaaf7d
```

The exact compared artifacts were:

```text
LAYOUT_TOP=spadmic_tx_packet_core
SOURCE_TOP=spadmic_tx_packet_core

GDS_SHA256=
48bbf0294f49e2f2201a2e86db71547ead33a9d426e43488df940d0c9e8b242e

SOURCE_SHA256=
c45e663b7a1591f02911f2b3efec79fbb988bec072b75ab9a2ddb7ebfee11cb3

STDCELL_CDL_SHA256=
5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf
```

The replay and result tuple is:

```text
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
SCHEMATIC_VERILOG_ACTION=REPLACED_EXISTING
SCHEMATIC_CDL_ACTION=ADDED_MISSING
PVS_RC=0
PARSE_RC=0
PVS_LVS_STATUS=MATCH
LVS_NEGATIVE_MATCH_COUNT=0
LVS_POSITIVE_MATCH_COUNT=3
EVIDENCE=svdb/matched
```

The three positive indicators are corroborating artifacts from one
comparison, not three separate LVS runs:

```text
pvs.stdout.log
spadmic_tx_packet_core_lvs.sum.cls
svdb/matched
```

No negative mismatch pattern was found in the 55 scanned run-local text
artifacts. The source-preparation contract had already proved `156/156`
top-pin parity, resolution of all 97 referenced standard-cell masters through
the package-local JIHD CDL, and zero unresolved masters.

This is the strongest PVS comparison verdict available: the layout and source
circuits match under this exact rule deck and input contract. PVS does not
emit a useful percentage for this result, so the precise engineering
statement is `PVS_LVS_STATUS=MATCH`, not a derived numeric score. In ordinary
language, it is a complete LVS match for the compared package.

It is not a complete signoff result. The same package still has:

```text
INNOVUS_TEMPORARY_MET1_MIN_AREA_MARKERS=4
PVS_BASE_DRC_RESULTS=135
PVS_DENSITY_DRC=NOT_RUN
MANUAL_DRC_FIX_REQUIRED=YES
FINAL_LVS_RERUN_AFTER_MANUAL_FIX_REQUIRED=YES
BLOCK_PROMOTION_AUTHORIZED=NO
FINAL_SIGNOFF_READY=NO
```

The match proves that the provisional GDS and routed source agree
electrically before manual DRC repair. It does not waive the 135 PVS results,
retire the four-marker exception, or transfer to a future repaired GDS hash.

### 16.1 Safe GUI Review

Do not start `pvsgui` or `lvsbrowser` directly in the immutable run. Cadence
review tools may write lock files, GUI presets, indexes, or browser state.
Use the guarded helper, which validates the explicit match and creates a
disposable relocated copy under `/tmp` before launching a GUI.

Open the actual comparison result first:

```bash
RUN_DIR=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442/pvs/lvs/tx_packet_pvs_waiver_20260716_130442_pvs_lvs_execinputs_5bcaaf7d

bash TOP/pnr/scripts/open_pvs_lvs_gui_review.sh \
    --run-dir "$RUN_DIR" \
    --view results
```

This starts `lvsbrowser` in the copied run directory. A matched run may have
empty mismatch/error tabs; that is expected. The comparison report and
matched database are the positive evidence.

After closing the result browser, inspect the copied setup:

```bash
bash TOP/pnr/scripts/open_pvs_lvs_gui_review.sh \
    --run-dir "$RUN_DIR" \
    --view setup
```

This starts `pvsgui` with the copied `.preset.autosave`. Verify visibly:

```text
layout GDS   package/gds/spadmic_tx_packet_core.gds
layout top   spadmic_tx_packet_core
source       package/netlist/spadmic_tx_packet_core.lvs.pg.v
source top   spadmic_tx_packet_core
cell CDL     package/pdk/xh018_D_CELLS_JIHD.cdl
run/output   disposable GUI review directory
```

Do not press Run and then treat the disposable GUI copy as new evidence. The
authoritative verdict remains the immutable run and its hashes above.

The shell-launched `lvsbrowser` is not automatically associated with an
already-open Virtuoso layout window. It can inspect the result database and
comparison, but cross-probing into Virtuoso requires launching the debug
environment from the corresponding Virtuoso layout session. That integration
is optional review work and does not strengthen the existing `MATCH`.

## 17. Read-Only Base DRC Rule Classification

The next step after the explicit LVS match is not another PVS execution. The
existing immutable base-DRC run already contains an attributable
`135 (135)` failure and must first be decomposed rule by rule.

Use:

```text
TOP/pnr/scripts/analyze_pvs_drc_run.py
```

The analyzer requires the passed replay/output-isolation reports, PVS tool RC
zero, the exact classified nonzero DRC status, one summary, and one ASCII DRC
error database. It reconciles every rule count and every result polygon before
writing a separate analysis directory.

The first analyzer revision used an explicit-word-only antenna policy:

```text
ANTENNA_EXCLUSION_POLICY=EXPLICIT_RULE_NAME_OR_DESCRIPTION_ONLY
```

The server run proved that this policy was incomplete. Both nonzero rules have
the foundry description:

```text
Maximum ratio of MET3 area to connected GATE area ... 400
```

That is the antenna mechanism even though the literal word `antenna` is
absent. The corrected policy is:

```text
ANTENNA_CLASSIFICATION_POLICY=
EXPLICIT_TERM_OR_CONDUCTOR_AREA_TO_CONNECTED_GATE_AREA_RATIO
AMBIGUOUS_RULE_POLICY=RETAIN_AS_NON_ANTENNA_REVIEW
```

The executed packet result is:

```text
R2M3P1=93
R1M3P1=42
ANTENNA_PRIMARY_RESULT_COUNT=135
NON_ANTENNA_PRIMARY_RESULT_COUNT=0
VAR_ANT_RATIO_STATE=UNDEFINED
DENSITY_STATE=UNDEFINED
```

`VAR_ANT_RATIO=UNDEFINED` disables an additional optional variable-ratio rule
family; it does not disable the fixed metal-to-connected-gate antenna rules
that produced the 135 results.

The generated evidence includes rule inventory, every result location in
microns, spatial bins, overlap with the four Innovus temporary-waiver boxes,
and a detailed Markdown report. The four Innovus MET1 marker boxes have zero
overlap with all PVS result boxes at the `0.35 um` review margin, so the gate
state is four separate Innovus minimum-area markers plus 135 PVS antenna
results, not 135 non-antenna PVS errors.

The first `44f7ec51` analysis directory remains immutable negative evidence:
its parsing and geometry are valid, but its semantic class and generic area
repair guidance are rejected. The corrected analyzer must write a new
directory and report:

```text
ANTENNA_RULE_COUNT=2
ANTENNA_PRIMARY_RESULT_COUNT=135
NON_ANTENNA_RULE_COUNT=0
NON_ANTENNA_PRIMARY_RESULT_COUNT=0
```

The corrected server execution at commit
`03a430d75fcff3f301440c550c40096ffb3ea775` passed and wrote:

```text
/sim/ksabra/SPADMIC_work/diagnostics/
tx_packet_pvs_waiver_20260716_130442/drc_analysis/
base_rule_classification_03a430d7_20260716_130727
```

The raw foundry error database qualifies the two result groups as:

```text
R1M3P1=42  "(gate output)"
R2M3P1=93  "(met3 output)"
```

Both use the same executed rule description, so all `135` are antenna-ratio
process violations. The corrected non-antenna TSV contains only its header,
and all four Innovus MET1 waiver boxes have zero PVS-result overlap.

This does not contradict the explicit LVS `MATCH`. LVS proves connectivity and
device equivalence for the exact compared package; antenna checks constrain
manufacturing charge exposure. The package is electrically matched but still
fails base PVS DRC, still has four separate Innovus minimum-area markers, and
still lacks density-enabled PVS evidence.

The full protocol and repair interpretation are documented in:

```text
TOP/docs/39_TX_PACKET_CORE_PVS_BASE_DRC_NON_ANTENNA_ANALYSIS.md
```

This analysis can classify DRC debt but cannot make the design pass:

```text
PVS_DRC_STATUS=FAIL
PVS_DENSITY_DRC=NOT_RUN
LVS_MATCH_STATUS=UNCHANGED_SEPARATE_GATE
FINAL_SIGNOFF_READY=NO
BLOCK_PROMOTION_AUTHORIZED=NO
```
