# Matrix-Side Subblock PnR Session Closeout - 2026-07-09

Status: session closeout for typical-only OOC and assembly-prep evidence.
Nothing in this file is final signoff. PVS, foundry LVS, PEX, MMMC, final PG
hookup, and top-level Virtuoso assembly remain separate gates.

## Ground Rules Used

- Branch: `SPADMIC_test`.
- No full-top Genus or Innovus run.
- No internal MPTDC edits.
- Matrix, DDRs2, TXRX4TDC, pads, PLL, analog macros, and MPTDC internals remain
  black boxes, obstacles, or future abstracts.
- CSR/I2C physical wrapper remains deferred.
- For routed digital OOC blocks, the target collateral is DEF, LEF, abstract
  LEF, GDS, routed netlist, PG netlist, reports, and handoff package.

## Repo Milestones

| Commit | Purpose |
| --- | --- |
| `0488ce46aabefdff1e91f470019402ecf02aa4e9` | Added connected TX fixed-leaf assembly generator. |
| `e8afdf988c7fb6e5976e05fa541bc023f29a80bc` | Added connected assembly Genus/Innovus route-gate wrappers. |
| `cffb29c7081c22f6eee23a8aff92fd80d3e6de80` | Added split TX physical wrappers, OOC filelists/SDCs, and block-by-block plan. |
| `f55dc7c7c00397a3745f27c26d8238cc122f9852` | Tuned split TX OOC route defaults and status-pin placement. |
| `3004a923703dc3d44537f446beba69315efe3388` | Documented split TX OOC server evidence. |
| `6197dc5c235e20b7b1e14f2b08c2db6741aeb5d5` | Added restore-only Innovus GDS re-export helper with XFAB streamout map support. |

## Leaf Abstract Evidence

The four leaf abstracts remain valid fallback/review collateral:

| Block | Top module | Innovus run | Result |
| --- | --- | --- | --- |
| `ddrs2_adapter` | `spadmic_ddrs2_adapter` | `innovus_ooc_harden_ddrs2_adapter_leaf_20260709_1421` | `ABSTRACT_READY_FOR_TOP_REVIEW` |
| `ddr16_pairer` | `spadmic_ddr16_tx_pairer` | `innovus_ooc_harden_ddr16_pairer_leaf_20260709_1422` | `ABSTRACT_READY_FOR_TOP_REVIEW` |
| `output_fifo` | `spadmic_output_fifo_topcfg` | `innovus_ooc_harden_output_fifo_scanfix_20260709_1438` | `ABSTRACT_READY_FOR_TOP_REVIEW` |
| `event_bundle_tx` | `spadmic_event_bundle_tx` | `innovus_ooc_harden_event_bundle_tx_scanfix_20260709_1450` | `ABSTRACT_READY_FOR_TOP_REVIEW` |

All four passed the local OOC abstract gates:

- `INNOVUS_DRC_STATUS=PASS`
- `DRC_MARKER_CLASSIFICATION=PASS`
- `DRC_MARKER_TOTAL=0`
- `REGULAR_CONNECTIVITY_STATUS=PASS`
- `POSTROUTE_SETUP_TIMING=PASS`
- `POSTROUTE_HOLD_TIMING=PASS`
- `EXPORT_DEF_FILE=PASS`
- `EXPORT_LEF_FILE=PASS`
- `EXPORT_GDS_FILE=PASS`
- `HANDOFF_COPY=PASS`
- `PG_CONNECTIVITY_STATUS=DEFERRED_TOP_LEVEL_HOOKUP`
- `SIGNOFF_READY=NO`

Clean standalone `output_fifo` output path:

```text
/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_output_fifo_scanfix_20260709_1438/blocks/output_fifo/outputs
```

Do not confuse this clean standalone FIFO leaf with the currently failing
combined `TX_PACKET_CORE` route.

## Four-Leaf Assembly Evidence

The leaf manifest package was created and validated:

- Assembly inputs ID: `tx_egress_leaf_assembly_inputs_20260709_1515`
- Assembly inputs root:
  `/sim/ksabra/SPADMIC_work/assembly/tx_egress_leaf_assembly_inputs_20260709_1515`
- Manifest:
  `/sim/ksabra/SPADMIC_work/assembly/tx_egress_leaf_assembly_inputs_20260709_1515/tx_leaf_manifest.csv`
- Result: `ALL_OK=1`, `READY_FOR_TRUE_FIXED_LEAF_ASSEMBLY=1`

The deterministic fixed-leaf placement proposal was generated:

- Plan ID: `tx_egress_leaf_assembly_plan_20260709_1526`
- Plan root:
  `/sim/ksabra/SPADMIC_work/assembly/tx_egress_leaf_assembly_plan_20260709_1526`
- Result: `FIXED_LEAF_ASSEMBLY_PLAN_READY_FOR_REVIEW`
- Local assembly size: `3449.600 x 746.560 um`
- Top absolute placement: `REVIEW_REQUIRED`

Local proposed placements:

| Block | BBox in local assembly | Status |
| --- | --- | --- |
| `event_bundle_tx` | `(2109.360, 0.000) - (2449.280, 240.240)` | fixed proposal |
| `output_fifo` | `(2479.280, 0.000) - (3219.600, 540.400)` | fixed proposal |
| `ddr16_pairer` | `(3249.600, 570.400) - (3389.600, 670.640)` | fixed proposal |
| `ddrs2_adapter` | `(0.000, 700.640) - (3449.600, 746.560)` | fixed proposal |

This tall vertical stack is not the final top physical strategy. It proved
macro import/placement mechanics, but it is too tall for the shallow DDRs2
strip.

## Assembly Smoke And Connected Package

Initial macro-only smoke exposed a row-policy guard:

- Run: `innovus_tx_egress_leaf_assembly_smoke_20260709_1537`
- Failure: `MPTDC_XH018_ROW_POLICY_NOT_ALLOWED`
- Resolution: provisional smoke run allows the no-core tap/endcap policy through
  `MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1`.

Clean macro-only smoke evidence:

- Run: `innovus_tx_egress_leaf_assembly_smoke_parserfix_20260709_1553`
- Result: `FIXED_LEAF_ASSEMBLY_SMOKE_PLACED`
- `CHECK_PLACE_STATUS=PASS`
- `CHECK_PLACE_OUT_OF_CORE_COUNT=0`
- `CHECK_PLACE_UNPLACED_COUNT=0`
- Local assembly size: `3449.600 x 746.560 um`
- `SIGNOFF_READY=NO`

Connected assembly package:

- Run ID: `tx_egress_connected_assembly_20260709_1604`
- Root:
  `/sim/ksabra/SPADMIC_work/assembly/tx_egress_connected_assembly_20260709_1604`
- Status: `PASS`
- Result: `CONNECTED_LEAF_ASSEMBLY_READY_FOR_GENUS_GLUE_SYNTH`
- Top module: `spadmic_tx_egress_leaf_assembly`
- Filelist:
  `tx_egress_leaf_connected_assembly.f`
- RTL wrapper:
  `tx_egress_leaf_connected_assembly.sv`
- Black boxes:
  `tx_egress_leaf_blackboxes.sv`
- Connection manifest:
  `tx_egress_leaf_connected_assembly_connections.csv`

The connected package is not a routed assembly result. It still needs Genus glue
synthesis, Innovus route feasibility, PG hookup, PVS, LVS, PEX, MMMC, and final
top/Virtuoso assembly review.

## Final Physical Split Decision

The accepted physical direction is split TX, not one monolithic/tall TX hard
macro:

- `TX_DDR_STRIP`: `spadmic_ddr16_tx_pairer` +
  `spadmic_ddrs2_adapter`, placed under DDRs2 in the wide strip.
- `TX_PACKET_CORE`: `spadmic_event_bundle_tx` +
  `spadmic_output_fifo_topcfg`, placed in the larger packet/FIFO region above
  the matrix and below the DDR strip.
- Matrix-facing OR/snapshot/reset/config boundary logic remains soft or
  region-guided around matrix top/east/south.

Reason: the `output_fifo` abstract is too tall for the DDRs2 strip, while the
DDRs2 adapter/pairer path must stay wide, low, and aligned to DDRs2 bottom pins.

## Genus Split-Block Evidence

Genus run:

```text
/sim/ksabra/SPADMIC_work/genus/genus_ooc_matrix_side_split_20260709_1735
```

Commit: `cffb29c7081c22f6eee23a8aff92fd80d3e6de80`

Result: `PASS`, typical-only, not MMMC, not signoff.

Blocks passed:

- `tx_ddr_strip` / `spadmic_tx_ddr_strip`
- `tx_packet_core` / `spadmic_tx_packet_core`
- `matrix_reset_ctrl` / `spadmic_matrix_reset_ctrl`
- `matrix_cfg_ctrl` / `spadmic_matrix_cfg_ctrl`
- `position_snapshot` / `spadmic_position_snapshot_packetizer`
- `event_coordinator` / `spadmic_event_coordinator`

## Innovus Split-Block Evidence

### TX_DDR_STRIP

Accepted top-review abstract:

- Run: `innovus_ooc_harden_tx_ddr_strip_fix1_20260709_1812`
- Commit: `f55dc7c7c00397a3745f27c26d8238cc122f9852`
- Run root:
  `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_ddr_strip_fix1_20260709_1812`
- Block root:
  `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_ddr_strip_fix1_20260709_1812/blocks/tx_ddr_strip`
- Handoff root:
  `/sim/ksabra/SPADMIC_work/handoff/abstracts/tx_ddr_strip/innovus_ooc_harden_tx_ddr_strip_fix1_20260709_1812`
- Result: `ABSTRACT_READY_FOR_TOP_REVIEW`
- `INNOVUS_DRC_STATUS=PASS`
- `DRC_MARKER_TOTAL=0`
- `REGULAR_CONNECTIVITY_STATUS=PASS`
- `PG_CONNECTIVITY_STATUS=DEFERRED_TOP_LEVEL_HOOKUP`
- `SIGNOFF_READY=NO`

`TX_DDR_STRIP` can be used as top-review abstract collateral, but not as signoff
collateral.

### TX_PACKET_CORE

Active debug run:

- Run: `innovus_ooc_harden_tx_packet_core_fix1_20260709_1814`
- Commit: `f55dc7c7c00397a3745f27c26d8238cc122f9852`
- Run root:
  `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_packet_core_fix1_20260709_1814`
- Block root:
  `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_packet_core_fix1_20260709_1814/blocks/tx_packet_core`
- Outputs:
  `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_packet_core_fix1_20260709_1814/blocks/tx_packet_core/outputs`
- Reports:
  `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_packet_core_fix1_20260709_1814/blocks/tx_packet_core/reports`
- Result: `INNOVUS_TC_OOC_REVIEW_REQUIRED`
- `ROUTE_PROFILE=met2_first_antenna`
- `SIGNAL_ROUTE_LAYERS=MET2-MET3`
- `PLACE_MAX_DENSITY=0.64`
- `DRC_MARKER_TOTAL=68`
- `MET1_MIN_AREA_MARKER_COUNT=10`
- `ANTENNA_MARKER_COUNT=58`
- `OTHER_MARKER_COUNT=0`
- `REGULAR_CONNECTIVITY_STATUS=PASS`
- `PG_CONNECTIVITY_STATUS=DEFERRED_TOP_LEVEL_HOOKUP`
- `SIGNOFF_READY=NO`

Primary debug reports:

- `reports/ooc_harden_status.rpt`
- `reports/verify_drc_post_route.rpt`
- `reports/verify_drc_post_route_markers.tsv`
- `reports/DRC_MARKER_CLASSIFICATION.rpt`
- `reports/POSTROUTE_MIN_AREA_REPAIR.rpt`

Do not use `TX_PACKET_CORE` as clean top abstract collateral yet.

## Virtuoso GDS Import Issue

The `tx_packet_core` GDS initially streamed out without the official XFAB PnR
streamout map. Innovus exported route layers such as:

- `22:0`
- `32:0`
- `43:0`
- `53:0`

The active Virtuoso XH018 stream-in layer table expects:

- `MET1 = 16:0`
- `MET2 = 18:0`
- `MET3 = 28:0`
- `METTP = 33:0`

Result: Virtuoso imported hierarchy but dropped routing. Treat this as an
incomplete OA import, not as proof that Innovus has no routing.

Implemented fix:

- Script: `TOP/pnr/scripts/run_innovus_ooc_reexport_gds.sh`
- Tcl: `TOP/pnr/scripts/reexport_innovus_ooc_gds.tcl`
- Default stream map:
  `/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map`
- Commit: `6197dc5c235e20b7b1e14f2b08c2db6741aeb5d5`

The helper restores the saved `05_postroute_export.enc.dat` checkpoint and runs
`streamOut` only. It does not rerun placement, CTS, route, DRC repair, PVS, LVS,
PEX, or MMMC. The server-side re-export/re-import result was not yet pasted
back in this session, so that verification remains open.

## Next Open Gates

1. Run the restore-only GDS re-export for `tx_packet_core` with the official
   XFAB PnR streamout map.
2. Re-import the regenerated GDS in Virtuoso and confirm route layers are
   visible on `MET1/MET2/MET3/METTP`.
3. After the OA import is complete, debug the real `tx_packet_core` markers:
   10 MET1 minimum-area markers and 58 antenna markers.
4. Keep `tx_ddr_strip` available as clean top-review abstract collateral.
5. Do not consume `tx_packet_core` as clean abstract collateral until
   `DRC_MARKER_TOTAL=0`.
6. Continue matrix/interface work block-by-block; keep matrix boundary logic
   region-guided unless a clean hardening split is proven.

## Useful Inspection Commands

Use shell-safe inspection blocks on the server. Do not use fail-fast `exit`
while debugging an SSH session.

```bash
set +e

export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work

TX_PACKET_ROOT="$SPADMIC_WORK_ROOT/innovus/innovus_ooc_harden_tx_packet_core_fix1_20260709_1814/blocks/tx_packet_core"
TX_DDR_ROOT="$SPADMIC_WORK_ROOT/innovus/innovus_ooc_harden_tx_ddr_strip_fix1_20260709_1812/blocks/tx_ddr_strip"
FIFO_ROOT="$SPADMIC_WORK_ROOT/innovus/innovus_ooc_harden_output_fifo_scanfix_20260709_1438/blocks/output_fifo"

echo "===== TX_PACKET_CORE STATUS ====="
cat "$TX_PACKET_ROOT/reports/ooc_harden_status.rpt" 2>/dev/null || echo "MISSING TX_PACKET_CORE STATUS"

echo "===== TX_PACKET_CORE MARKERS ====="
cat "$TX_PACKET_ROOT/reports/DRC_MARKER_CLASSIFICATION.rpt" 2>/dev/null || echo "MISSING TX_PACKET_CORE MARKERS"

echo "===== TX_DDR_STRIP STATUS ====="
cat "$TX_DDR_ROOT/reports/ooc_harden_status.rpt" 2>/dev/null || echo "MISSING TX_DDR_STRIP STATUS"

echo "===== CLEAN STANDALONE FIFO OUTPUTS ====="
find "$FIFO_ROOT/outputs" -maxdepth 1 -type f | sort
```
