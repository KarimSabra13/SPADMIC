# TX Packet Core Virtuoso Import Handoff

Status: `READY_FOR_CONTROLLED_VIRTUOSO_IMPORT_NOT_FINAL_SIGNOFF`

This document identifies the exact `spadmic_tx_packet_core` GDS that should be
imported into Virtuoso for inspection and manual physical repair. It also
records the complete provenance, supporting collateral, PVS evidence, known
open violations, XStream In settings, and post-import checks.

The central decision is:

```text
USE_EXISTING_IMMUTABLE_STAGED_GDS=YES
CREATE_ANOTHER_INNOVUS_EXPORT_BEFORE_IMPORT=NO
IMPORT_PURPOSE=REVIEW_AND_MANUAL_DRC_REPAIR
FINAL_SIGNOFF_READY=NO
```

Do not re-export the design merely to obtain a newer timestamp. A new export
would have a different hash and would not inherit the existing PVS LVS
`MATCH`. The selected GDS is the most stable available physical candidate
because it is simultaneously:

- generated from the reviewed six-edit Innovus state;
- exported with the official XFAB Innovus streamout map;
- merged with the official JIHD standard-cell GDS;
- accepted by the mapped/merged GDS audit;
- staged in an immutable handoff package;
- used as the exact layout input to an explicit PVS LVS `MATCH`;
- unchanged by the later read-only PVS DRC analysis.

## 1. Exact GDS To Import

The authoritative package is:

```text
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/
spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442
```

The exact GDS is:

```text
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/
spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442/
gds/spadmic_tx_packet_core.gds
```

The identity contract is:

```text
LAYOUT_TOP=spadmic_tx_packet_core
GDS_BYTES=16103546
GDS_SHA256=48bbf0294f49e2f2201a2e86db71547ead33a9d426e43488df940d0c9e8b242e
EXPECTED_SIZE_UM=2066.960000 366.800000
EXPECTED_TOP_TERMINAL_COUNT=156
```

Use top cell `spadmic_tx_packet_core`. Do not select the older
`spadmic_tx_packet_core_HV` top.

## 2. Current Subblock State

The selected GDS is electrically matched but not physically signed off:

```text
IMMUTABLE_HANDOFF_PACKAGE=PASS_CANDIDATE
GDS_FILE_STATUS=PASS
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
PVS_LVS_STATUS=MATCH
PVS_BASE_DRC_STATUS=FAIL
PVS_BASE_ANTENNA_RESULTS=135
PVS_BASE_NON_ANTENNA_RESULTS=0
INNOVUS_MET1_MIN_AREA_RESULTS=4
INNOVUS_REGULAR_CONNECTIVITY_RESULTS=0
INNOVUS_SPECIAL_CONNECTIVITY_RESULTS=0
PVS_DENSITY_DRC_STATUS=NOT_RUN
FINAL_SIGNOFF_READY=NO
BLOCK_PROMOTION_AUTHORIZED=NO
```

The `MATCH` means that PVS found the exact staged GDS electrically equivalent
to the exact staged routed source under the package-local JIHD CDL contract.
It is not a percentage estimate and it is not inferred from a zero process
return code. The report-level result is explicitly `PVS_LVS_STATUS=MATCH`.

The open physical debt is:

1. Four separate Innovus `MET1 / Geometry / Minimal_Area` markers on
   `n_9677`, `n_9693`, `n_9696`, and `n_9697`.
2. PVS base DRC has 135 antenna-ratio results:
   `R2M3P1=93` and `R1M3P1=42`.
3. Density-enabled PVS DRC has not run.

All 135 PVS base results are classified as process-antenna violations because
the executed foundry descriptions constrain the ratio of MET3 conductor area
to connected gate area. There is no residual non-antenna PVS base-rule class.
The four Innovus minimum-area boxes have zero overlap with the PVS antenna
result boxes at the recorded `0.35 um` review margin, so they remain a
separate manual repair class.

## 3. Physical Provenance

### 3.1 Source Checkpoint

The physical reconstruction started from:

```text
/sim/ksabra/SPADMIC_work/innovus/
innovus_ooc_harden_tx_packet_core_canonical_preroute_pg1x1_no_restitch_20260713_124110/
blocks/tx_packet_core/checkpoints/05_postroute_export.enc.dat
```

The restored state had six MET1 minimum-area violations and zero regular or
special connectivity violations.

### 3.2 Reviewed Six Base Edits

The waiver export replayed exactly six validated R6 base edits in one fresh
Innovus process. The resulting state had:

```text
PATCH_ATTEMPTED_COUNT=6
PATCH_APPLIED_COUNT=6
PATCH_CONTRACT_VALIDATED_COUNT=6
COMMAND_PASS_COUNT=24
COMMAND_FAIL_COUNT=0
FINAL_DRC_VIOLATION_COUNT=4
FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0
FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0
FINAL_MIN_AREA_NETS=n_9677 n_9693 n_9696 n_9697
```

The rejected four chained-endpoint R6 edits and the unexecuted R7 experiment
are not present in the exported GDS.

### 3.3 Innovus Export Root

The accepted export block is:

```text
/sim/ksabra/SPADMIC_work/innovus/
innovus_tx_packet_min_area_waiver_export_20260716_130442/
blocks/tx_packet_core
```

Important export artifacts are:

```text
outputs/spadmic_tx_packet_core.gds
outputs/spadmic_tx_packet_core.routed.pg.v
outputs/spadmic_tx_packet_core.abstract.lef
outputs/spadmic_tx_packet_core.def
checkpoints/05_min_area_waiver_export.enc.dat
reports/min_area_waiver_export_status.rpt
reports/temporary_drc_waiver.rpt
reports/temporary_drc_waiver.tsv
reports/gds_export_audit.rpt
reports/canonical_tx_lvs_waiver_gate.rpt
logs/innovus.log
logs/innovus.stdout.log
```

The exact selected GDS was copied from this export root into the immutable
package. The package copy is preferred for import because it is the path
hashed and replayed by PVS.

### 3.4 Stream Map And Standard-Cell Merge

The Innovus export used:

```text
STREAM_MAP=
/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/
TECH_XH018_HD_1131/pnr_streamout.map

STREAM_MAP_SHA256=
4d7b850f74ef193b6bc7b15b1e52fd38ba61cc4a6e1b283c4201343a20ad233d

REQUIRED_MERGE=
/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/
gds_cdl/v6_0_0/gds/xh018_D_CELLS_JIHD.gds
```

The GDS audit reported:

```text
STATUS=PASS
GDS_FILE_STATUS=PASS
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
ERROR_COUNT=0
```

This matters because an earlier packet-core GDS without the official map
imported hierarchy into Virtuoso but lost visible routing. Its raw route
layers did not match the XH018 OA stream-in layer table. The selected GDS is
the corrected mapped and merged export.

## 4. Immutable Package Contents

Set:

```bash
PACKAGE=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442
```

The main package files are:

| Purpose | Package path |
| --- | --- |
| Layout GDS | `gds/spadmic_tx_packet_core.gds` |
| Canonical LVS source | `netlist/spadmic_tx_packet_core.lvs.pg.v` |
| Raw Innovus PG source | `netlist/spadmic_tx_packet_core.innovus.pg.v` |
| Standard-cell CDL | `pdk/xh018_D_CELLS_JIHD.cdl` |
| Abstract LEF | `lef/spadmic_tx_packet_core.abstract.lef` |
| DEF | `def/spadmic_tx_packet_core.def` |
| Package manifest | `manifests/package.json` |
| Package hashes | `manifests/SHA256SUMS` |
| Qualification state | `status/qualification.rpt` |
| Handoff audit | `status/handoff_audit.rpt` |
| LVS source preparation | `reports/lvs_source_preparation.rpt` |
| Waiver gate | `reports/canonical_tx_lvs_waiver_gate.rpt` |
| Temporary waiver summary | `reports/temporary_drc_waiver.rpt` |
| Temporary waiver table | `reports/temporary_drc_waiver.tsv` |
| GDS export audit | `reports/gds_export_audit.rpt` |
| Innovus export status | `reports/min_area_waiver_export_status.rpt` |

The exact PVS comparison inputs were:

```text
GDS_SHA256=
48bbf0294f49e2f2201a2e86db71547ead33a9d426e43488df940d0c9e8b242e

SOURCE_SHA256=
c45e663b7a1591f02911f2b3efec79fbb988bec072b75ab9a2ddb7ebfee11cb3

STDCELL_CDL_SHA256=
5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf
```

The source-preparation report also proved:

```text
PIN_PARITY_STATUS=PASS
SOURCE_TOP_PORT_COUNT=156
LEF_PIN_COUNT=156
REFERENCED_MASTER_COUNT=97
CDL_RESOLVED_MASTER_COUNT=97
UNRESOLVED_MASTER_COUNT=0
```

## 5. PVS Evidence Locations

### 5.1 Explicit LVS Match

The authoritative LVS run is:

```text
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/
spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442/
pvs/lvs/tx_packet_pvs_waiver_20260716_130442_pvs_lvs_execinputs_5bcaaf7d
```

Important evidence:

```text
pvs_lvs_status.rpt
replay_contract_status.rpt
output_isolation.rpt
external_references.rpt
pvs_result_evidence_inventory.rpt
spadmic_tx_packet_core_lvs.sum
spadmic_tx_packet_core_erc.sum
pvs.stdout.log
svdb/matched
```

The accepted tuple is:

```text
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
PVS_RC=0
PARSE_RC=0
PVS_LVS_STATUS=MATCH
LVS_NEGATIVE_MATCH_COUNT=0
LVS_POSITIVE_MATCH_COUNT=3
```

### 5.2 Base PVS DRC

The authoritative base-DRC run is:

```text
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/
spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442/
pvs/drc/tx_packet_pvs_waiver_20260716_130442_pvs_drc_base_outputiso_13cc2e14
```

Important evidence:

```text
pvs_drc_status.rpt
replay_contract_status.rpt
output_isolation.rpt
external_references.rpt
pvsdrcctl
spadmic_tx_packet_core_drc.sum
spadmic_tx_packet_core_drc.err
pvs_result_evidence_inventory.rpt
```

The classified result is:

```text
PVS_RC=0
PVS_DRC_STATUS=FAIL
DRC_TOTAL_PRIMARY=135
DRC_TOTAL_EXPANDED=135
```

### 5.3 Corrected DRC Rule Analysis

The corrected read-only analysis is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/
tx_packet_pvs_waiver_20260716_130442/drc_analysis/
base_rule_classification_03a430d7_20260716_130727
```

Important files:

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

The corrected classification is:

```text
R2M3P1=93
R1M3P1=42
ANTENNA_PRIMARY_RESULT_COUNT=135
NON_ANTENNA_PRIMARY_RESULT_COUNT=0
```

## 6. Read-Only Verification Before Import

Run this on the server before opening Virtuoso. It does not edit the package
or rerun Innovus/PVS.

```bash
set +e

cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
CD_RC=$?

PACKAGE=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442
GDS="$PACKAGE/gds/spadmic_tx_packet_core.gds"
LEF="$PACKAGE/lef/spadmic_tx_packet_core.abstract.lef"
SOURCE="$PACKAGE/netlist/spadmic_tx_packet_core.lvs.pg.v"
CDL="$PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl"

LVS_RUN="$PACKAGE/pvs/lvs/tx_packet_pvs_waiver_20260716_130442_pvs_lvs_execinputs_5bcaaf7d"
DRC_RUN="$PACKAGE/pvs/drc/tx_packet_pvs_waiver_20260716_130442_pvs_drc_base_outputiso_13cc2e14"

LAYER_TABLE=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/.xkit/setup/xh018/cadence/PDK/TECH_XH018_1131/strmInOut.layertable
OBJECT_MAP=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/.xkit/setup/xh018/cadence/PDK/TECH_XH018_1131/strmOutObjects.map

EXPECTED_GDS_SHA256=48bbf0294f49e2f2201a2e86db71547ead33a9d426e43488df940d0c9e8b242e
EXPECTED_SOURCE_SHA256=c45e663b7a1591f02911f2b3efec79fbb988bec072b75ab9a2ddb7ebfee11cb3
EXPECTED_CDL_SHA256=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf
EXPECTED_LAYER_TABLE_SHA256=3198c31b841a29b1126206f7962632fd7f6dc239c53931962cd57327d2320869
EXPECTED_OBJECT_MAP_SHA256=151695165c1679190e1f95aa0ccb854de233c7a7e3f589a5ac83c93c0c487c7c

echo "CD_RC=$CD_RC"
echo "PACKAGE=$PACKAGE"

echo
echo "===== REQUIRED FILES ====="

for FILE in \
    "$GDS" \
    "$LEF" \
    "$SOURCE" \
    "$CDL" \
    "$PACKAGE/def/spadmic_tx_packet_core.def" \
    "$PACKAGE/manifests/package.json" \
    "$PACKAGE/manifests/SHA256SUMS" \
    "$PACKAGE/status/qualification.rpt" \
    "$PACKAGE/status/handoff_audit.rpt" \
    "$LVS_RUN/pvs_lvs_status.rpt" \
    "$LVS_RUN/svdb/matched" \
    "$DRC_RUN/pvs_drc_status.rpt" \
    "$LAYER_TABLE" \
    "$OBJECT_MAP"
do
    if [ -s "$FILE" ]; then
        ls -lh "$FILE"
    else
        echo "MISSING_OR_EMPTY=$FILE"
    fi
done

echo
echo "===== EXPLICIT HASHES ====="

ACTUAL_GDS_SHA256="$(sha256sum "$GDS" 2>/dev/null | awk '{print $1}')"
ACTUAL_SOURCE_SHA256="$(sha256sum "$SOURCE" 2>/dev/null | awk '{print $1}')"
ACTUAL_CDL_SHA256="$(sha256sum "$CDL" 2>/dev/null | awk '{print $1}')"
ACTUAL_LAYER_TABLE_SHA256="$(sha256sum "$LAYER_TABLE" 2>/dev/null | awk '{print $1}')"
ACTUAL_OBJECT_MAP_SHA256="$(sha256sum "$OBJECT_MAP" 2>/dev/null | awk '{print $1}')"

printf 'GDS=%s\nSOURCE=%s\nCDL=%s\nLAYER_TABLE=%s\nOBJECT_MAP=%s\n' \
    "$ACTUAL_GDS_SHA256" \
    "$ACTUAL_SOURCE_SHA256" \
    "$ACTUAL_CDL_SHA256" \
    "$ACTUAL_LAYER_TABLE_SHA256" \
    "$ACTUAL_OBJECT_MAP_SHA256"

if [ "$ACTUAL_GDS_SHA256" = "$EXPECTED_GDS_SHA256" ] && \
   [ "$ACTUAL_SOURCE_SHA256" = "$EXPECTED_SOURCE_SHA256" ] && \
   [ "$ACTUAL_CDL_SHA256" = "$EXPECTED_CDL_SHA256" ] && \
   [ "$ACTUAL_LAYER_TABLE_SHA256" = "$EXPECTED_LAYER_TABLE_SHA256" ] && \
   [ "$ACTUAL_OBJECT_MAP_SHA256" = "$EXPECTED_OBJECT_MAP_SHA256" ]; then
    echo "EXPLICIT_HASH_GATE=PASS"
else
    echo "STOP_HERE_DO_NOT_CONTINUE: explicit hash mismatch"
fi

echo
echo "===== PACKAGE MANIFEST HASHES ====="

if [ -d "$PACKAGE" ] && [ -r "$PACKAGE/manifests/SHA256SUMS" ]; then
    (
        cd "$PACKAGE"
        sha256sum -c manifests/SHA256SUMS
    )
    PACKAGE_HASH_RC=$?
else
    PACKAGE_HASH_RC=1
fi

echo "PACKAGE_HASH_RC=$PACKAGE_HASH_RC"

echo
echo "===== GDS AND HANDOFF AUDIT ====="

grep -E \
    '^(STATUS|GDS_FILE_STATUS|GDS_LAYER_MAP_STATUS|GDS_MERGE_STATUS|GDS_BYTES|GDS_SHA256|STREAM_MAP|STREAM_MAP_SHA256|REQUIRED_MERGE|ERROR_COUNT)=' \
    "$PACKAGE/reports/gds_export_audit.rpt" 2>/dev/null

grep -E \
    '^(STATUS|CANONICAL_NAME|LAYOUT_TOP|SOURCE_TOP|LVS_SOURCE_PREPARATION_STATUS|PIN_PARITY_STATUS|STDCELL_CDL_STATUS|TEMPORARY_DRC_WAIVER_STATUS|PVS_DRC_WAIVER|LVS_DIAGNOSTIC_ONLY|FINAL_SIGNOFF_READY|ERROR_COUNT)=' \
    "$PACKAGE/status/handoff_audit.rpt" 2>/dev/null

echo
echo "===== LVS VERDICT ====="

cat "$LVS_RUN/pvs_lvs_status.rpt" 2>/dev/null

echo
echo "===== BASE DRC VERDICT ====="

cat "$DRC_RUN/pvs_drc_status.rpt" 2>/dev/null

echo
echo "STOP_AFTER_READ_ONLY_IMPORT_GATE=YES"
```

Required result:

```text
EXPLICIT_HASH_GATE=PASS
PACKAGE_HASH_RC=0
GDS_FILE_STATUS=PASS
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
PVS_LVS_STATUS=MATCH
PVS_DRC_STATUS=FAIL
DRC_TOTAL_PRIMARY=135
```

The DRC failure is expected for this provisional import. A hash mismatch,
missing GDS, missing `svdb/matched`, or non-MATCH LVS status is not expected
and must stop the import.

## 7. Optional Controlled Copy

Virtuoso can read the immutable package GDS directly. That preserves the
shortest provenance chain and is preferred.

If project access rules require a local copy, copy it to a new timestamped
import directory and prove that the hash is unchanged:

```bash
set +e

SOURCE_GDS=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442/gds/spadmic_tx_packet_core.gds
IMPORT_ROOT="/absolute/new/project/import/directory"
IMPORT_GDS="$IMPORT_ROOT/spadmic_tx_packet_core_20260716_130442.gds"
EXPECTED_GDS_SHA256=48bbf0294f49e2f2201a2e86db71547ead33a9d426e43488df940d0c9e8b242e

mkdir -p "$IMPORT_ROOT"
MKDIR_RC=$?

if [ "$MKDIR_RC" -eq 0 ] && [ -s "$SOURCE_GDS" ] && [ ! -e "$IMPORT_GDS" ]; then
    cp -p "$SOURCE_GDS" "$IMPORT_GDS"
    COPY_RC=$?
else
    COPY_RC=1
    echo "STOP_HERE_DO_NOT_CONTINUE: copy destination exists or source is missing"
fi

COPIED_GDS_SHA256="$(sha256sum "$IMPORT_GDS" 2>/dev/null | awk '{print $1}')"

printf 'MKDIR_RC=%s\nCOPY_RC=%s\nIMPORT_GDS=%s\nCOPIED_GDS_SHA256=%s\n' \
    "$MKDIR_RC" \
    "$COPY_RC" \
    "$IMPORT_GDS" \
    "$COPIED_GDS_SHA256"

if [ "$COPY_RC" -eq 0 ] && \
   [ "$COPIED_GDS_SHA256" = "$EXPECTED_GDS_SHA256" ]; then
    echo "CONTROLLED_COPY_STATUS=PASS"
else
    echo "STOP_HERE_DO_NOT_CONTINUE: copied GDS hash mismatch"
fi
```

Do not rename the top cell inside the GDS. The destination filename may be
timestamped; the internal top remains `spadmic_tx_packet_core`.

## 8. Virtuoso XStream In Setup

### 8.1 Destination Library

Create a new empty OA library for the first import, for example:

```text
SPADMIC_TX_PACKET_IMPORT_20260716_130442
```

Attach it to the same XH018 technology library used by the active project.
The recorded historical project preset used:

```text
TECH_XH018
```

Use `TECH_XH018` when that is the technology library already defined by the
project `cds.lib`. If the active project is instead explicitly attached to a
different approved XH018 technology library, confirm that project setup before
import. Do not infer the OA technology-library name from the string
`TECH_XH018_HD_1131` in the Innovus streamout-map path.

Do not import directly over an existing canonical
`spadmic_tx_packet_core/layout` on the first pass. The selected GDS includes
the merged JIHD hierarchy, so a fresh library also prevents accidental
standard-cell name collisions or overwrite decisions from being hidden.

### 8.2 Stream In Paths

Use:

```text
Stream file:
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/
spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442/
gds/spadmic_tx_packet_core.gds

Top cell:
spadmic_tx_packet_core

Layer map:
/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/
.xkit/setup/xh018/cadence/PDK/TECH_XH018_1131/
strmInOut.layertable

Object map:
/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/
.xkit/setup/xh018/cadence/PDK/TECH_XH018_1131/
strmOutObjects.map
```

The map identities are:

```text
LAYER_TABLE_SHA256=
3198c31b841a29b1126206f7962632fd7f6dc239c53931962cd57327d2320869

OBJECT_MAP_SHA256=
151695165c1679190e1f95aa0ccb854de233c7a7e3f589a5ac83c93c0c487c7c
```

The layer table is known to contain:

```text
MET1 drawing 16 0
MET2 drawing 18 0
MET3 drawing 28 0
METTP drawing 33 0
```

### 8.3 Recorded Import Options

The historical XStream In preset for this project used:

```text
case="preserve"
convertDot="node"
convertPin="geometryAndText"
hierDepth=32
labelCase="preserve"
labelDepth=32
maxVertices=2048
pinAttNum=0
strmVersion=5
view="layout"
enableColoring=YES
```

Use those settings with these current replacements:

```text
library=<NEW_EMPTY_IMPORT_LIBRARY>
techLib=<ACTIVE_PROJECT_XH018_TECH_LIBRARY>
topCell=spadmic_tx_packet_core
strmFile=<EXACT_SELECTED_GDS>
runDir=<NEW_TIMESTAMPED_IMPORT_LOG_DIRECTORY>
logFile=<NEW_TIMESTAMPED_IMPORT_LOG_FILE>
```

In the Virtuoso GUI this is normally under `File -> Import -> Stream` or the
site-equivalent `XStream In` form.

### 8.4 Via-Map Caveat

The historical project import did not use a `viaMap` and emitted Cadence
warning `XSTRM-162`. Do not guess a via-map file. Without an approved via map,
some streamed vias can remain imported geometry rather than native OA via
instances. This does not invalidate the existing GDS or its PVS LVS match,
but it matters for OA round trips and interactive editing.

For the first review import:

- use the known layer and object maps above;
- record the complete XStream log;
- inspect via representation before relying on native-via editing;
- use only a PDK-approved via map if the project owner supplies the exact file.

## 9. Immediate Checks In Virtuoso

After XStream In completes, verify:

1. The import log ends with zero translation errors.
2. The top cell is exactly `spadmic_tx_packet_core/layout`.
3. The top bounding box is `2066.960 x 366.800 um`.
4. There are 156 top terminals and the bus names are preserved.
5. Routing is visibly present on `MET1`, `MET2`, `MET3`, and `METTP`.
6. JIHD standard-cell hierarchy resolves without missing-master boxes.
7. VDD/VSS shapes and boundary pins are visible.
8. No existing project cell was overwritten.
9. The XStream log contains no unmapped-layer, duplicate-cell overwrite, or
   missing-master error that changes the imported physical meaning.

The earlier unmapped-GDS failure looked like valid hierarchy with missing
routing. Therefore route-layer visibility is a mandatory import check, not a
cosmetic review.

## 10. OA Versus LEF Contract Check

After importing into the new library, run the read-only OA audit. Replace only
`OA_LIBRARY` with the library name created in Virtuoso.

```bash
set +e

cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
CD_RC=$?

PACKAGE=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442
OA_LIBRARY=SPADMIC_TX_PACKET_IMPORT_20260716_130442
OA_CELL=spadmic_tx_packet_core
OA_VIEW=layout
AUDIT_ROOT=/sim/ksabra/SPADMIC_work/diagnostics/tx_packet_oa_import_$(date -u +%Y%m%d_%H%M%S)

if [ "$CD_RC" -eq 0 ]; then
    source /eda/cadence/eda_2023-2024
    SOURCE_RC=$?
else
    SOURCE_RC=1
fi

if [ "$SOURCE_RC" -eq 0 ]; then
    bash TOP/pnr/scripts/run_oa_layout_contract_audit.sh \
        "$OA_LIBRARY" \
        "$OA_CELL" \
        "$AUDIT_ROOT/oa_contract.rpt" \
        "$OA_VIEW"
    OA_AUDIT_RC=$?
else
    OA_AUDIT_RC=NOT_RUN
fi

if [ "$OA_AUDIT_RC" = "0" ]; then
    python3 TOP/pnr/scripts/compare_oa_lef_contract.py \
        --oa-report "$AUDIT_ROOT/oa_contract.rpt" \
        --lef "$PACKAGE/lef/spadmic_tx_packet_core.abstract.lef" \
        --status "$AUDIT_ROOT/oa_lef_contract_status.rpt"
    OA_LEF_RC=$?
else
    OA_LEF_RC=NOT_RUN
fi

printf 'CD_RC=%s\nSOURCE_RC=%s\nOA_AUDIT_RC=%s\nOA_LEF_RC=%s\nAUDIT_ROOT=%s\n' \
    "$CD_RC" \
    "$SOURCE_RC" \
    "$OA_AUDIT_RC" \
    "$OA_LEF_RC" \
    "$AUDIT_ROOT"

for REPORT in \
    "$AUDIT_ROOT/oa_contract.rpt" \
    "$AUDIT_ROOT/oa_contract.virtuoso.log" \
    "$AUDIT_ROOT/oa_lef_contract_status.rpt"
do
    printf '\n===== %s =====\n' "$REPORT"
    if [ -r "$REPORT" ]; then
        cat "$REPORT"
    else
        echo "MISSING=$REPORT"
    fi
done

echo
echo "STOP_AFTER_OA_IMPORT_AUDIT=YES"
```

Required contract result:

```text
STATUS=PASS
BBOX_PARITY_STATUS=PASS
PIN_PARITY_STATUS=PASS
OA_SIZE_UM=2066.960000 366.800000
LEF_SIZE_UM=2066.960000 366.800000
OA_PIN_COUNT=156
LEF_PIN_COUNT=156
```

This check proves bbox and terminal parity. It does not prove DRC, density,
LVS, or route-layer completeness, so retain the visual and XStream-log checks.

## 11. Optional LVS GUI Review

To inspect the exact comparison that produced the `MATCH`, open only a
disposable relocated copy:

```bash
set +e

cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

RUN_DIR=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442/pvs/lvs/tx_packet_pvs_waiver_20260716_130442_pvs_lvs_execinputs_5bcaaf7d

bash TOP/pnr/scripts/open_pvs_lvs_gui_review.sh \
    --run-dir "$RUN_DIR" \
    --view results
RESULTS_GUI_RC=$?

echo "RESULTS_GUI_RC=$RESULTS_GUI_RC"
```

After closing the result browser:

```bash
bash TOP/pnr/scripts/open_pvs_lvs_gui_review.sh \
    --run-dir "$RUN_DIR" \
    --view setup
SETUP_GUI_RC=$?

echo "SETUP_GUI_RC=$SETUP_GUI_RC"
```

These are foreground GUI commands and require a working X11 `DISPLAY`. The
helper copies the immutable run under `/tmp` before launching Cadence. Do not
open the authoritative run directory directly because GUI tools can create
locks, indexes, presets, and browser state.

## 12. Files Not To Use As The New Authority

Do not substitute any of the following for the selected package GDS:

- the historical
  `PvsLVS/spadmic_tx_packet_core_HV/spadmic_tx_packet_core_HV.gds`;
- the historical `_HV` OA signoff GDS;
- the earlier unmapped packet-core GDS that lost routing during Virtuoso
  import;
- the `tx_packet_pvs_waiver_20260716_124911` package;
- any failed PVS replay directory;
- a new ad hoc OA XStream Out generated before the imported layout is audited.

The old `_HV` template was used only as a foundry-rule launch scaffold after
the replay code replaced and proved all executable GDS/source/CDL/top/output
paths. Its historical GDS was not the compared layout.

## 13. Editing And Re-Signoff Rule

The current `MATCH` belongs only to the exact selected GDS hash:

```text
48bbf0294f49e2f2201a2e86db71547ead33a9d426e43488df940d0c9e8b242e
```

The first OA import should therefore be preserved as an unedited reference
cell or library. Make manual DRC repairs in a copied cell or a new versioned
library. Record every physical edit.

After any Virtuoso edit:

1. XStream Out to a new timestamped GDS.
2. Preserve the complete XStream output log and layer-table identity.
3. Hash the new GDS.
4. Run the OA/LEF bbox and terminal audit.
5. Run Innovus-equivalent or PVS checks for the four MET1 minimum-area
   locations.
6. Run PVS base DRC and require zero for final signoff.
7. Run density-enabled PVS DRC and require zero.
8. Rerun PVS LVS with the new GDS and require a new explicit `MATCH`.
9. Archive the new GDS/source/CDL hashes and retire the temporary waiver.

Do not attach the old `MATCH` to the edited OA cell or its new GDS. Electrical
equivalence must be reproven after the physical state changes.

## 14. Import Acceptance Gate

The Virtuoso import is accepted for review only when:

```text
SOURCE_GDS_SHA256_MATCH=YES
XSTREAM_TRANSLATION_ERRORS=0
TOP_CELL=spadmic_tx_packet_core
ROUTING_LAYERS_VISIBLE=MET1_MET2_MET3_METTP
OA_BBOX_PARITY=PASS
OA_PIN_PARITY=PASS
EXISTING_CANONICAL_CELL_OVERWRITTEN=NO
IMPORT_READY_FOR_MANUAL_REPAIR=YES
FINAL_SIGNOFF_READY=NO
```

That state gives a controlled OA representation of the strongest available
packet-core GDS while preserving the exact evidence chain that produced the
PVS LVS `MATCH`.
