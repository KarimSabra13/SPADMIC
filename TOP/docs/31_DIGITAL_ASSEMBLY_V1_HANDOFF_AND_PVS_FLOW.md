# Digital Assembly V1, Innovus Handoff, and PVS Flow

Status: implemented orchestration and static checks. Server EDA execution is
pending. This flow never launches full-top Genus or full-top Innovus and does
not modify MPTDC internals.

## 1. Scope and Naming

Phase A contains only:

- `spadmic_tx_packet_core`: corrected DIFFCON OA geometry, canonical physical
  and logical name;
- `spadmic_tx_ddr_strip`: newly narrowed OOC hard macro with internal PG;
- 19 stream nets between them;
- shared `clk_sys`, `rst_n`, `clk_160m_i`, and `ddrs2_enable_i` routes.

The stable logical assembly top is `spadmic_digital_assembly_v1`. The OA/GDS
phase top is `spadmic_digital_assembly_v1_p00_tx`. Later phases use new GDS/OA
top names while retaining the stable logical top.

The matrix, DDRs2, TXRX4TDC2, MPTDCs, analog macros, and pad ring remain
obstacles. No route may enter them. MPTDC bboxes receive a 20 um routing halo;
no missing MPTDC pin is invented.

## 2. Implemented Files

Assembly contract:

- `TOP/pnr/assembly/spadmic_digital_assembly_v1.sv`
- `TOP/pnr/assembly/spadmic_digital_assembly_blackboxes.sv`
- `TOP/pnr/assembly/spadmic_digital_assembly_connections.csv`
- `TOP/pnr/assembly/spadmic_digital_assembly_v1.f`
- `TOP/pnr/assembly/spadmic_digital_assembly_phases.csv`
- `TOP/pnr/assembly/spadmic_digital_assembly_floorplan.tcl`
- `TOP/pnr/assembly/spadmic_digital_assembly_blockages.tcl`
- `TOP/pnr/assembly/spadmic_digital_assembly_pin_guides.tcl`
- `TOP/pnr/assembly/spadmic_digital_assembly_p00_tx.hcell`

Assembly execution:

- `TOP/pnr/scripts/gen_spadmic_digital_assembly_v1.py`
- `TOP/pnr/scripts/run_innovus_digital_assembly.sh`
- `TOP/pnr/scripts/run_innovus_digital_assembly.tcl`
- `TOP/pnr/scripts/run_innovus_ooc_pg_only_patch.sh`
- `TOP/pnr/scripts/run_innovus_ooc_pg_only_patch.tcl`

Handoff and PVS:

- `stage_innovus_handoff.py`, `audit_innovus_handoff.py`
- `stage_tx_block_handoffs.sh`, `stage_digital_assembly_handoff.sh`
- `run_pvs_drc_handoff.sh`, `run_pvs_lvs_handoff.sh`
- `prepare_pvs_lvs_source.py`
- `replay_pvs_handoff_template.py`, `parse_pvs_handoff_result.py`
- `collect_pvs_lvs_readonly.py`
- `run_oa_layout_contract_audit.sh`, `compare_oa_lef_contract.py`
- `audit_xstream_gds_export.py`, `audit_innovus_gds_export.py`
- `derive_oa_pg_status.py`
- `build_innovus_handoff_gate.py`, `promote_innovus_handoff.py`

## 3. Immutable Handoff Layout

```text
/sim/ksabra/SPADMIC_work/handoff/innovus/
  _shared/pdk/xh018_1131_jihd_v6_0/
  _source_archive/tx_packet_core/<backup-id>/
  blocks/spadmic_tx_packet_core/<version>/
    gds/ lef/ def/ netlist/ pdk/ reports/ logs/ manifests/ status/ pvs/
  blocks/spadmic_tx_ddr_strip/<version>/
    gds/ lef/ def/ netlist/ reports/ logs/ manifests/ status/ pvs/
  assemblies/spadmic_digital_assembly_v1_p00_tx/<version>/
    gds/ lef/ def/ netlist/ reports/ logs/ manifests/ status/ pvs/
```

An existing version is never overwritten. Every package carries the exact JIHD
CDL used for source preparation and replay. Broader PDK GDS/LEF/typical Liberty
and the XFAB stream map may also be copied once under `_shared`. Foundry rule
installation files are referenced and hashed, not copied.

## 4. Current Geometry Gate

Approved packet placement:

```text
origin = 61.980,2689.624
orient = MY
bbox   = 61.980,2689.624 -> 2128.940,3056.424
```

This leaves 15 um above the matrix, 3.944 um before the matrix-to-MPTDC
corridor, and 4.686 um below the strip.

The old strip is invalid in SPADMIC2 coordinates:

```text
old strip bbox = 61.980,3061.110 -> 3584.940,3241.990
TXRX4TDC2      = 3505.519,464.920 -> 3638.910,3265.795
overlap        = 79.421 x 180.880 um
```

The strip-only OOC rerun completed on 2026-07-10 with core width
`3413.000 um`. The generated abstract is `3433.360 x 180.880 um`; at the
approved origin its bbox is:

```text
narrow strip bbox = 61.980,3061.110 -> 3495.340,3241.990
TXRX4TDC2         = 3505.519,464.920 -> 3638.910,3265.795
x clearance       = 10.179 um
```

Innovus reported zero DRC markers, zero antenna markers, and regular signal
connectivity PASS. VDD and VSS remain unrouted by deliberate P01 policy and
must be handled by the restore-only P02 PG phase. The exact new LEF still has
to pass `gen_spadmic_digital_assembly_v1.py` against the real audit before the
assembly run starts.

The first P02 restore-only PG attempt preserved signal routing and remained
DRC clean, but did not close PG connectivity. `sroute` returned successfully,
while `verifyConnectivity -type special` found 9 violations: 2 unconnected
terminals, 4 disconnected special-wire pieces, and 3 dangling wires. This is
a localized PG topology problem. The run is diagnostic evidence only and its
GDS must not be promoted.

The read-only marker probe localized every violation. The first attempt placed
the stripes 10.080 um east of the intended PG-pin centers because
`-start_offset` was interpreted from the core left edge. Both stripes stopped
at the core top, 6.160 um below the north PG pins. Two VDD followpin rows also
lacked via stacks. A repair must restore the P01 signal checkpoint and create
new geometry with these intended centerlines and extents:

```text
VDD center x =  858.480 um, y = 10.080 -> 180.880 um
VSS center x = 2574.880 um, y = 14.560 -> 180.880 um
```

The exact `addStripe` area syntax must be confirmed from Innovus 22.33 before
the repair run. The failed P02 checkpoint is evidence, not a repair baseline.

The installed Innovus manuals were captured and reviewed. P02-R2 uses
`add_shape` for exact METTP `SPECIALNETS` stripe geometry and uses `sroute`
only for `corePin` stitching. See
`TOP/docs/34_INNOVUS_22_33_PG_ROUTING_COMMAND_NOTES.md`. The R2 scripts are:

- `TOP/pnr/scripts/run_innovus_ooc_pg_geometry_fix.sh`
- `TOP/pnr/scripts/run_innovus_ooc_pg_geometry_fix.tcl`

The first exact-geometry run closed VSS and both boundary terminals but left
the two known VDD rows open. P02-R3 attempted an audited local VDD helper
search, but Innovus rejected the second restore in that process with
`IMPIMEX-7031`; no candidate was evaluated. P02-R4 keeps the same physical
repair and runs each candidate in a fresh Innovus process. A clean candidate is
then replayed from P01 in another fresh process before export. The Innovus
multiple-restore guard must not be disabled.

R4 confirmed the process isolation but rejected all ten local-helper candidates
with the same tuple: PG violations 6, PG markers 6, regular connectivity 0, and
DRC 0. No canonical replay or export ran. The uniform result means that the
bounded helper plus local second `sroute` mechanism must be diagnosed, not
repeated at more X coordinates. See
`TOP/docs/35_INNOVUS_PG_DEBUGGING_PLAYBOOK_AND_FAILURE_LEDGER.md`.

## 5. Server Initialization

Use this shell-safe preamble. Replace the expected commit after these files are
committed and pushed to `SPADMIC_test`.

```bash
set +e

cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
CD_RC=$?
RUN_OK=1
echo "CD_RC=$CD_RC"
if [ "$CD_RC" -ne 0 ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: repository missing"
    RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    git checkout SPADMIC_test
    git pull --ff-only origin SPADMIC_test
    PULL_RC=$?
    ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
    EXPECTED_HEAD=<IMPLEMENTATION_COMMIT>
    echo "PULL_RC=$PULL_RC"
    echo "ACTUAL_HEAD=$ACTUAL_HEAD"
    echo "EXPECTED_HEAD=$EXPECTED_HEAD"
    if [ "$PULL_RC" -ne 0 ] || [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: branch/head mismatch"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    source /eda/cadence/eda_2023-2024
    export EXPECTED_HEAD="$EXPECTED_HEAD"
    export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
    export SPADMIC_INNOVUS_HANDOFF_ROOT="$SPADMIC_WORK_ROOT/handoff/innovus"
    export SPADMIC_LAYOUT_AUDIT_DIR="$PWD/TOP/docs/layout_audits/SPADMIC2_20260709_072331"
    export MPTDC_XH018_STACK=xx31
    export MPTDC_STDCELL_FAMILY=JIHD
    export MPTDC_PNR_ROUTE_LAYER_NAMES="MET1 MET2 MET3 METTP"
    export SPADMIC_CADENCE_PVS_BIN=/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs
fi
```

## 6. Packet Core Canonical Promotion

The historical fixed source is
`SPADMIC_DIGITAL_BLOCKS_VIS_20260709/spadmic_tx_packet_core_HV/layout`. It is not
the final canonical cell name. Before changing OA, close writable Virtuoso
sessions and back up both OA cells plus the fixed GDS:

```bash
if [ "$RUN_OK" -eq 1 ]; then
    OA_LIBRARY_ROOT=<absolute-directory-mapped-to-SPADMIC_DIGITAL_BLOCKS_VIS_20260709>
    HV_GDS=/sim/ksabra/SPADMIC_work/oa_signoff/tx_packet_core_HV_20260710_105525/gds/spadmic_tx_packet_core_HV_fixed_DIffcon.gds
    BACKUP_ID=tx_packet_oa_backup_$(date +%Y%m%d_%H%M%S)
    bash TOP/pnr/scripts/backup_tx_packet_oa_before_promotion.sh \
      "$OA_LIBRARY_ROOT" "$HV_GDS" "$BACKUP_ID"
    OA_BACKUP_RC=$?
    echo "OA_BACKUP_RC=$OA_BACKUP_RC"
    if [ "$OA_BACKUP_RC" -ne 0 ]; then RUN_OK=0; fi
fi
```

Then, manually in Virtuoso:

1. Copy the corrected `_HV/layout` view onto
   `spadmic_tx_packet_core/layout` after confirming the backup.
2. Keep the original bbox and all 156 signal/PG terminals.
3. Complete internal VDD/VSS rail stitching to the existing METTP boundary
   pins. Do not alter signal routing or DIFFCON fixes.
4. Run PVS DRC in the canonical cell.
5. XStream Out top `spadmic_tx_packet_core` with the project XH018 layer table.
   Save the GDS and full XStream log in a new timestamped directory.

The old `_HV` DRC evidence cannot be attached automatically to the canonical
GDS: the known template GDS and handoff GDS have different SHA256 hashes.

A candidate historical LVS run for the corrected `_HV` layout is registered
at:

```text
/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PvsLVS/spadmic_tx_packet_core_HV
```

It must be inventoried read-only before its result or inputs are trusted. This
parallel P03/P04 investigation does not block the strip-only P02 PG patch.
The evidence policy and mismatch taxonomy are defined in
`TOP/docs/33_TX_PACKET_CORE_HV_PVS_LVS_TRIAGE.md`.

Audit the canonical OA and export:

```bash
PACKET_AUDIT_ROOT="$SPADMIC_INNOVUS_HANDOFF_ROOT/_source_archive/tx_packet_core/canonical_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$PACKET_AUDIT_ROOT"/{reports,gds,logs}
PACKET_LEF=/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_packet_core_fix1_20260709_1814/blocks/tx_packet_core/outputs/tx_packet_core.abstract.lef
PACKET_GDS="$PACKET_AUDIT_ROOT/gds/spadmic_tx_packet_core.gds"
PACKET_XSTREAM_LOG="$PACKET_AUDIT_ROOT/logs/xstream_out.log"
VIRT_MAP=/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0/.xkit/setup/xh018/cadence/PDK/TECH_XH018_1131/strmInOut.layertable

bash TOP/pnr/scripts/run_oa_layout_contract_audit.sh \
  SPADMIC_DIGITAL_BLOCKS_VIS_20260709 spadmic_tx_packet_core \
  "$PACKET_AUDIT_ROOT/reports/oa_contract.rpt"
OA_AUDIT_RC=$?

python3 TOP/pnr/scripts/compare_oa_lef_contract.py \
  --oa-report "$PACKET_AUDIT_ROOT/reports/oa_contract.rpt" \
  --lef "$PACKET_LEF" \
  --status "$PACKET_AUDIT_ROOT/reports/oa_lef_contract_status.rpt"
CONTRACT_RC=$?

python3 TOP/pnr/scripts/audit_xstream_gds_export.py \
  --gds "$PACKET_GDS" --log "$PACKET_XSTREAM_LOG" --layer-table "$VIRT_MAP" \
  --status "$PACKET_AUDIT_ROOT/reports/gds_layer_map_status.rpt"
LAYER_RC=$?
echo "OA_AUDIT_RC=$OA_AUDIT_RC CONTRACT_RC=$CONTRACT_RC LAYER_RC=$LAYER_RC"
```

## 7. Narrow Strip and Restore-Only PG

Reuse the successful Genus result. Only this OOC block is rerun:

```bash
if [ "$RUN_OK" -eq 1 ]; then
    GENUS_RUN_ID=genus_ooc_matrix_side_split_20260709_1735
    export SPADMIC_OOC_CORE_WIDTH_UM=3413.000
    export SPADMIC_OOC_REQUIRE_DRC_SAFE_FILLER=1
    export SPADMIC_OOC_ENABLE_MIN_AREA_REPAIR=1
    unset SPADMIC_OOC_ENABLE_PG_SROUTE
    unset SPADMIC_OOC_ROUTE_PROFILE

    STRIP_SIGNAL_RUN=innovus_ooc_harden_tx_ddr_strip_narrow_$(date +%Y%m%d_%H%M%S)
    bash TOP/pnr/scripts/run_innovus_ooc_block.sh \
      tx_ddr_strip "$GENUS_RUN_ID" "$STRIP_SIGNAL_RUN"
    STRIP_SIGNAL_RC=$?
    STRIP_SIGNAL_ROOT="$SPADMIC_WORK_ROOT/innovus/$STRIP_SIGNAL_RUN/blocks/tx_ddr_strip"
    echo "STRIP_SIGNAL_RC=$STRIP_SIGNAL_RC"
    cat "$STRIP_SIGNAL_ROOT/reports/ooc_harden_status.rpt" 2>/dev/null || echo "MISSING STATUS"
fi

if [ "$RUN_OK" -eq 1 ] && [ "$STRIP_SIGNAL_RC" -eq 0 ]; then
    STRIP_PG_RUN=innovus_ooc_pg_only_tx_ddr_strip_$(date +%Y%m%d_%H%M%S)
    bash TOP/pnr/scripts/run_innovus_ooc_pg_only_patch.sh \
      "$STRIP_SIGNAL_ROOT" tx_ddr_strip "$STRIP_PG_RUN"
    STRIP_PG_RC=$?
    STRIP_PG_ROOT="$SPADMIC_WORK_ROOT/innovus/$STRIP_PG_RUN"
    echo "STRIP_PG_RC=$STRIP_PG_RC"
    cat "$STRIP_PG_ROOT/reports/pg_only_patch_status.rpt" 2>/dev/null || echo "MISSING PG STATUS"
    cat "$STRIP_PG_ROOT/reports/verify_connectivity_pg.rpt" 2>/dev/null || echo "MISSING PG CONNECTIVITY"
    cat "$STRIP_PG_ROOT/reports/verify_drc_post_pg.rpt" 2>/dev/null || echo "MISSING DRC"
fi
```

The first P02 run ID was
`innovus_ooc_pg_only_tx_ddr_strip_20260710_135413` and returned 8. Do not
repeat the same PG command without first inspecting its special-net geometry.

The P02-R4 command restores the successful narrow P01 run. The wrapper
creates one immutable trial directory per X candidate and performs a separate
canonical replay only after a trial has PG, regular-connectivity, and DRC counts
of zero:

```bash
P01_ROOT=/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_ddr_strip_narrow_20260710_133516/blocks/tx_ddr_strip
R4_RUN=innovus_ooc_pg_geometry_fix_r4_tx_ddr_strip_$(date +%Y%m%d_%H%M%S)

bash TOP/pnr/scripts/run_innovus_ooc_pg_geometry_fix.sh \
  "$P01_ROOT" tx_ddr_strip "$R4_RUN"
R4_RC=$?
R4_ROOT="$SPADMIC_WORK_ROOT/innovus/$R4_RUN"

echo "R4_RC=$R4_RC"
echo "R4_ROOT=$R4_ROOT"
cat "$R4_ROOT/reports/vdd_helper_candidate_summary.tsv" 2>/dev/null
cat "$R4_ROOT/reports/pg_geometry_fix_status.rpt" 2>/dev/null
cat "$R4_ROOT/reports/pg_geometry_fix_wrapper_status.rpt" 2>/dev/null
```

The measured R4 run was
`innovus_ooc_pg_geometry_fix_r4_tx_ddr_strip_20260710_161123`; all ten trials
were rejected with six PG markers, so the canonical replay and all parent
outputs were correctly skipped. Do not rerun this candidate list with the same
helper mechanism. The next command is read-only marker/log extraction from the
existing trial directories.

Do not use the PG output if `INTERNAL_PG_STATUS`, regular connectivity, or
Innovus DRC is not `PASS`. The exported strip GDS explicitly merges the JIHD
standard-cell GDS so that PVS sees transistor geometry rather than LEF-only
cell abstracts.

## 8. Stage the Two Blocks

```bash
PACKET_OLD_ROOT=/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_packet_core_fix1_20260709_1814/blocks/tx_packet_core
TX_VERSION=tx_blocks_$(date +%Y%m%d_%H%M%S)

bash TOP/pnr/scripts/stage_tx_block_handoffs.sh \
  "$PACKET_OLD_ROOT" "$PACKET_GDS" "$PACKET_AUDIT_ROOT" \
  "$STRIP_PG_ROOT" "$TX_VERSION"
STAGE_RC=$?
PACKET_PACKAGE="$SPADMIC_INNOVUS_HANDOFF_ROOT/blocks/spadmic_tx_packet_core/$TX_VERSION"
STRIP_PACKAGE="$SPADMIC_INNOVUS_HANDOFF_ROOT/blocks/spadmic_tx_ddr_strip/$TX_VERSION"
echo "STAGE_RC=$STAGE_RC"
echo "PACKET_PACKAGE=$PACKET_PACKAGE"
echo "STRIP_PACKAGE=$STRIP_PACKAGE"
```

## 9. PVS DRC and LVS

Each block needs a GUI-generated template for that same hierarchy. Templates
are read-only. Replays are created inside each package. Never invoke bare
`pvs`, because PATH may resolve `/usr/sbin/pvs`.

Packet DRC replay can use the existing same-hierarchy template after canonical
path/top patching:

```bash
PACKET_DRC_TEMPLATE=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_tx_packet_core_HV
PACKET_DRC_TEMPLATE_GDS="$PACKET_DRC_TEMPLATE/spadmic_tx_packet_core_HV.gds"

bash TOP/pnr/scripts/run_pvs_drc_handoff.sh \
  --package "$PACKET_PACKAGE" \
  --template "$PACKET_DRC_TEMPLATE" \
  --template-gds "$PACKET_DRC_TEMPLATE_GDS" \
  --template-top spadmic_tx_packet_core_HV \
  --variant base
PACKET_BASE_DRC_RC=$?

bash TOP/pnr/scripts/run_pvs_drc_handoff.sh \
  --package "$PACKET_PACKAGE" \
  --template "$PACKET_DRC_TEMPLATE" \
  --template-gds "$PACKET_DRC_TEMPLATE_GDS" \
  --template-top spadmic_tx_packet_core_HV \
  --variant density
PACKET_DENSITY_DRC_RC=$?

find "$PACKET_PACKAGE/pvs/drc" -name pvs_drc_status.rpt -type f -print -exec cat {} \;
```

Create the packet LVS template once in the PVS GUI with:

- layout GDS: canonical package GDS;
- layout top: `spadmic_tx_packet_core`;
- source: `netlist/spadmic_tx_packet_core.lvs.pg.v`;
- source top: `spadmic_tx_packet_core`;
- JIHD CDL from package `pdk/xh018_D_CELLS_JIHD.cdl`;
- explicit VDD/VSS handling matching the netlist.

Then replay it. `OLD_*` values must be the exact paths/names embedded in that
GUI template:

```bash
PACKET_LVS_TEMPLATE=<packet-GUI-LVS-run-directory>
OLD_PACKET_GDS=<GDS-path-embedded-in-template>
OLD_PACKET_SOURCE=<source-path-embedded-in-template>
OLD_PACKET_CDL=<CDL-path-embedded-in-template>

bash TOP/pnr/scripts/run_pvs_lvs_handoff.sh \
  --package "$PACKET_PACKAGE" --template "$PACKET_LVS_TEMPLATE" \
  --template-gds "$OLD_PACKET_GDS" --template-source "$OLD_PACKET_SOURCE" \
  --template-layout-top spadmic_tx_packet_core \
  --template-source-top spadmic_tx_packet_core \
  --template-cdl "$OLD_PACKET_CDL"
PACKET_LVS_RC=$?
PACKET_LVS_STATUS="$(find "$PACKET_PACKAGE/pvs/lvs" -name pvs_lvs_status.rpt -type f | sort | tail -1)"
cat "$PACKET_LVS_STATUS" 2>/dev/null || echo "MISSING PACKET LVS STATUS"
```

Repeat the same GUI-template/replay sequence for `spadmic_tx_ddr_strip`. Do not
reuse the packet `cell_tree.txt` for the strip. For the assembly, use the
provided HCell mapping and map both children to themselves.

For the strip, import its package GDS once into the OA library under canonical
cell `spadmic_tx_ddr_strip`, then run the same read-only OA/LEF contract audit.
The layer-map evidence comes from the PG-patch Innovus log:

```bash
STRIP_LEF="$STRIP_PACKAGE/lef/tx_ddr_strip.abstract.lef"
STRIP_GDS="$STRIP_PACKAGE/gds/spadmic_tx_ddr_strip.gds"
STRIP_AUDIT_ROOT="$STRIP_PACKAGE/status/oa_contract_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$STRIP_AUDIT_ROOT"

bash TOP/pnr/scripts/run_oa_layout_contract_audit.sh \
  SPADMIC_DIGITAL_BLOCKS_VIS_20260709 spadmic_tx_ddr_strip \
  "$STRIP_AUDIT_ROOT/oa_contract.rpt"

python3 TOP/pnr/scripts/compare_oa_lef_contract.py \
  --oa-report "$STRIP_AUDIT_ROOT/oa_contract.rpt" --lef "$STRIP_LEF" \
  --status "$STRIP_AUDIT_ROOT/oa_lef_contract_status.rpt"

python3 TOP/pnr/scripts/audit_innovus_gds_export.py \
  --gds "$STRIP_GDS" --log "$STRIP_PG_ROOT/logs/innovus.log" \
  --stream-map /eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map \
  --status "$STRIP_AUDIT_ROOT/gds_layer_map_status.rpt"
```

After creating same-strip GUI DRC/LVS templates, replay them exactly as follows:

```bash
STRIP_DRC_TEMPLATE=<strip-GUI-DRC-run-directory>
OLD_STRIP_DRC_GDS=<GDS-path-embedded-in-DRC-template>
bash TOP/pnr/scripts/run_pvs_drc_handoff.sh \
  --package "$STRIP_PACKAGE" --template "$STRIP_DRC_TEMPLATE" \
  --template-gds "$OLD_STRIP_DRC_GDS" --template-top spadmic_tx_ddr_strip \
  --variant base
STRIP_BASE_DRC_RC=$?
bash TOP/pnr/scripts/run_pvs_drc_handoff.sh \
  --package "$STRIP_PACKAGE" --template "$STRIP_DRC_TEMPLATE" \
  --template-gds "$OLD_STRIP_DRC_GDS" --template-top spadmic_tx_ddr_strip \
  --variant density
STRIP_DENSITY_DRC_RC=$?

STRIP_LVS_TEMPLATE=<strip-GUI-LVS-run-directory>
OLD_STRIP_LVS_GDS=<GDS-path-embedded-in-LVS-template>
OLD_STRIP_SOURCE=<source-path-embedded-in-LVS-template>
OLD_STRIP_CDL=<CDL-path-embedded-in-LVS-template>
bash TOP/pnr/scripts/run_pvs_lvs_handoff.sh \
  --package "$STRIP_PACKAGE" --template "$STRIP_LVS_TEMPLATE" \
  --template-gds "$OLD_STRIP_LVS_GDS" --template-source "$OLD_STRIP_SOURCE" \
  --template-layout-top spadmic_tx_ddr_strip \
  --template-source-top spadmic_tx_ddr_strip \
  --template-cdl "$OLD_STRIP_CDL"
STRIP_LVS_RC=$?
STRIP_LVS_STATUS="$(find "$STRIP_PACKAGE/pvs/lvs" -name pvs_lvs_status.rpt -type f | sort | tail -1)"
echo "STRIP_BASE_DRC_RC=$STRIP_BASE_DRC_RC STRIP_DENSITY_DRC_RC=$STRIP_DENSITY_DRC_RC STRIP_LVS_RC=$STRIP_LVS_RC"
find "$STRIP_PACKAGE/pvs/drc" -name pvs_drc_status.rpt -type f -print -exec cat {} \;
cat "$STRIP_LVS_STATUS" 2>/dev/null || echo "MISSING STRIP LVS STATUS"
```

## 10. Assembly Preflight and Route

The old strip package is expected to fail this command. The narrowed strip may
proceed only when the conflict CSV is empty:

```bash
ASSEMBLY_RUN=innovus_digital_assembly_v1_p00_tx_$(date +%Y%m%d_%H%M%S)
bash TOP/pnr/scripts/run_innovus_digital_assembly.sh \
  "$PACKET_PACKAGE" "$STRIP_PACKAGE" "$ASSEMBLY_RUN"
ASSEMBLY_RC=$?
ASSEMBLY_ROOT="$SPADMIC_WORK_ROOT/innovus/$ASSEMBLY_RUN"
echo "ASSEMBLY_RC=$ASSEMBLY_RC"
cat "$ASSEMBLY_ROOT/generated/assembly_plan_status.rpt" 2>/dev/null || echo "MISSING PLAN STATUS"
cat "$ASSEMBLY_ROOT/generated/assembly_geometry_conflicts.csv" 2>/dev/null || echo "MISSING CONFLICT REPORT"
cat "$ASSEMBLY_ROOT/reports/digital_assembly_status.rpt" 2>/dev/null || echo "MISSING ASSEMBLY STATUS"
```

Acceptance is Innovus DRC 0 plus reviewed selected-net connectivity. Timing and
assembly PG remain explicitly deferred. In Virtuoso, create a separate
`spadmic_digital_assembly_v1_p00_tx_pg` child for manual METTP PG and a phase
top that instantiates signal overlay plus PG overlay. Export that phase top to
GDS, then stage it with `stage_digital_assembly_handoff.sh` and run PVS DRC/LVS.

## 11. Promotion Gate

Generate OA/LEF, layer-map, PVS and PG evidence first. For packet PG, derive the
gate only after LVS MATCH:

```bash
python3 TOP/pnr/scripts/derive_oa_pg_status.py \
  --oa-report "$PACKET_PACKAGE/reports/oa_contract.rpt" \
  --lvs-status "$PACKET_LVS_STATUS" \
  --status "$PACKET_PACKAGE/status/packet_internal_pg_gate.rpt"

python3 TOP/pnr/scripts/build_innovus_handoff_gate.py \
  --package "$PACKET_PACKAGE" \
  --drc-status "$PACKET_DRC_STATUS" --lvs-status "$PACKET_LVS_STATUS" \
  --pg-status "$PACKET_PACKAGE/status/packet_internal_pg_gate.rpt" \
  --contract-status "$PACKET_PACKAGE/reports/oa_lef_contract_status.rpt" \
  --layer-status "$PACKET_PACKAGE/reports/gds_layer_map_status.rpt"
GATE_RC=$?
PACKET_GATE="$(find "$PACKET_PACKAGE/status" -name 'gate_*.rpt' -type f | sort | tail -1)"

if [ "$GATE_RC" -eq 0 ]; then
    python3 TOP/pnr/scripts/promote_innovus_handoff.py \
      "$PACKET_PACKAGE" --gate-status "$PACKET_GATE"
fi
```

Promotion means block-level physical collateral is approved for assembly. It
does not mean full-chip signoff, MMMC closure, PEX completion, or pad/analog PG
closure.

## 12. Later Phases

Only an approved Phase A checkpoint may seed Phase B. The order remains:

1. `p00_tx`: packet + DDR strip.
2. `p01_position`: add hard `spadmic_position_core`; keep snapshot frontend soft.
3. `p02_event_control`: add soft event coordinator and central control regions.
4. `p03_matrix_interface`: guided snapshot/reset/config/OR64 boundary logic.
5. `p04_mptdc_frontend`: wrapper/frontend logic around MPTDC blockages.
6. `p05_csr_i2c`: CSR/I2C physical wrapper last.

Every phase gets a new immutable package, phase top, OA PG child, DRC run, LVS
run, and approval gate. Failed packages remain preserved for diagnosis.

## 13. Canonical TX Rebuild Supersession

The restore-only strip PG sequence in Sections 7-8 is retained as historical
evidence, not as the current execution path. After P02-R4 proved the bounded
helper method X-invariant, the active flow returned to fresh RTL, Genus, and
Innovus implementations.

Current source contracts:

```text
TOP/rtl/interfaces/tx_src_data_flat.csv
TOP/pnr/interfaces/tx_packet_strip_pin_contract.csv
```

The packet is rebuilt and qualified first. Only after packet Xcelium, Genus,
Innovus regular/special connectivity, Innovus DRC, mapped/merged GDS audit,
PVS base DRC, PVS density DRC, and PVS LVS are classified may the strip be
rebuilt with the same paired stream coordinates. The final assembly step routes
the 19 aligned links on MET2/MET3 and keeps assembly PG deferred.

Before staging either TX block, require
`reports/canonical_tx_ooc_gate.rpt` and pass it to
`stage_innovus_handoff.py --qualification-profile canonical_tx --report ...`.
This gate may label antenna deferred for the PVS milestone, but it never labels
the final handoff ready.

Do not stage the historical `_HV` GDS, the P01 signal-only strip, or any R1-R4
PG trial as a canonical block. Do not transfer PVS results across GDS hashes.
The detailed implementation and closure order are in
`TOP/docs/36_TX_PACKET_CORE_CANONICAL_REBUILD_AND_PVS_CLOSURE.md`.

## 14. Current Packet R1 Stop and R2 Entry Gate

The first canonical packet implementation is preserved for diagnosis and must
not be staged. It has clean regular connectivity, positive setup/hold slack,
and an audited mapped/merged GDS, but it also has four VDD special-connectivity
findings, seven MET1 minimum-area violations, and 19 uniformly shifted stream
pins. PVS remains `NOT_RUN` by policy.

The restore-only probe proved that the PG findings are three VDD row components
plus one aggregate VDD component; VSS is clean. The R2 entry sequence is now:

1. Generate a compact SWIRE/row overlap analysis from immutable probe text.
2. Capture installed `editPowerVia` command help with no design loaded.
3. Run one no-save/no-export VDD via method in one fresh restore process.
4. If that method passes report-level connectivity and DRC gates, integrate it
   into a new canonical run together with the `-0.280 um` guided-pin command
   compensation.
5. Use a different, evidence-driven minimum-area repair; the old selected-net
   delete plus reroute sequence recreated all seven markers and is retired.

Do not run PVS after a via trial, even if PG reaches zero. A trial is not a
candidate handoff, and the seven minimum-area markers remain independently
blocking until a complete new canonical artifact passes every OOC gate.
