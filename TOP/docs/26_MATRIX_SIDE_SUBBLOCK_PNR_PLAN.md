# Matrix-Side Subblock PnR Plan

Status: planning document for block-by-block digital implementation. This is
not a full-top Genus/Innovus plan and not a signoff claim.

## 1. Current RTL State

The active digital matrix-top core is `TOP/rtl/spadmic_top_matrix_v1.sv`. It is
the digital core, not the final pad-ring wrapper. The current implementation
already has the main matrix event path split into reusable RTL blocks:

| Area | RTL block | Current role |
| --- | --- | --- |
| Matrix activity reduction | `spadmic_matrix_or_tree` | OR-reduces R/Y/B matrix activity vectors for event detection. |
| Matrix snapshot frontend | `spadmic_matrix_snapshot_frontend` | Captures/synchronizes matrix R/Y/B activity close to matrix-side pins. |
| Matrix reset | `spadmic_matrix_reset_ctrl` | Generates active-low Rz/Yz/Bz reset masks from captured snapshots. |
| Matrix config | `spadmic_matrix_cfg_ctrl` | Moves config/readback commands between `clk_sys` and `clk_cfg_40m`; drives Din/Cin and samples Dout/Cout. |
| Position packet | `spadmic_position_snapshot_packetizer` | Converts R/Y/B snapshots into raw or clustered position packets. |
| Event control | `spadmic_event_coordinator` | Opens an event, freezes packet/reset masks, starts reset and bundle transmit. |
| Bundle transmit | `spadmic_event_bundle_tx` | Serializes selected TDC/position packets into one event bundle. |
| Output FIFO | `spadmic_output_fifo` | Buffers 16-bit event words before DDR pairing. |
| DDR16 pairer | `spadmic_ddr16_tx_pairer` | Pairs two 16-bit words into low/high DDR data phases. |
| DDRs2 adapter | `spadmic_ddrs2_adapter` | Expands internal DDR16 stream to the 19-lane DDRs2 macro contract. |
| CSR endpoint | `spadmic_matrix_top_csr` | Owns matrix-top CSR config/status, PLL controls, and SLVS/RX GPIO controls. |
| I2C bridge/slave | `spadmic_i2c_csr_bridge`, `spadmic_i2c_slave` | Digital CSR access path. Physical SDA/SCL pad wrapper is deferred. |

Analog/custom macros stay black boxes: matrix macro, MPTDC hard/provisional
macro, DDRs2, TXRX4TDC, PLL, pad ring, PTAT, and related analog blocks.

## 2. Physical Context

The floorplan intent is fixed by the existing top layout:

- matrix macro is the priority and sits on the left side;
- three MPTDC macros sit to the right of the matrix and stay close together;
- DDRs2/SLVS output macros are north/top;
- PLL, reset/control, I2C/pad-control, and supervision are bottom, bottom-left,
  or west depending on final top layout;
- the digital data path should move from matrix-side capture/control, through
  position/event logic, into FIFO/TX, then north into DDRs2;
- digital blocks must expose pins toward the analog/custom macro they connect
  to, without routing inside that analog/custom macro.

## 3. Block Classification

### A. Soft Or Region-Guided Near The Matrix

Do not harden these first as isolated rectangles. They touch the real matrix pin
map and may need distributed placement:

- `spadmic_matrix_or_tree`;
- `spadmic_matrix_snapshot_frontend` input flops/synchronizers;
- buffers/flops close to R/Y/B matrix inputs;
- Rz/Yz/Bz output flops/buffers;
- Din/Cin flops/drivers;
- Dout/Cout capture;
- position frontend logic that must stay close to matrix pins.

Allowed now:

- Genus OOC for area/timing/structure;
- region guides and pin guides;
- direction documentation for top/manual routing.

Deferred:

- full hard macro abstracts for these elements unless Innovus/top layout proves
  that a hard block is easier.

### B. Hardenable OOC Digital Blocks

These are clean digital blocks that can become layout "legos":

| Priority | Block key | Top module | Placement intent |
| ---: | --- | --- | --- |
| 1 | `matrix_reset_ctrl` | `spadmic_matrix_reset_ctrl` | Bottom/left-control region for central FSM; Rz/Yz/Bz boundary flops may remain soft near matrix. |
| 2 | `matrix_cfg_ctrl` | `spadmic_matrix_cfg_ctrl` | Bottom/control region; Din/Cin/Dout/Cout boundary may remain soft or guided. |
| 3 | `position_snapshot` | `spadmic_position_snapshot_packetizer` | Between matrix and TX, preferably upper-right of matrix. |
| 4 | `event_coordinator` | `spadmic_event_coordinator` | Between matrix-control, MPTDC, position, and TX. |
| 5 | `event_bundle_tx` | `spadmic_event_bundle_tx` | North/north-east TX region. |
| 6 | `output_fifo` | `spadmic_output_fifo` | North/north-east TX region, close to pairer. |
| 7 | `ddr16_pairer` | `spadmic_ddr16_tx_pairer` | North, close to DDRs2 adapter/DDRs2. |
| 8 | `ddrs2_adapter` | `spadmic_ddrs2_adapter` | North, directly below DDRs2 macro pins. |
| 9 | `matrix_top_csr` | `spadmic_matrix_top_csr` | Bottom/control region. |

### C. Candidate Combined Blocks

Combination is allowed only when it reduces manual placement complexity without
hiding matrix/analog-sensitive boundaries.

| Combined block | Candidate contents | Why useful | Rule |
| --- | --- | --- | --- |
| `TX_EGRESS_CORE` | `event_bundle_tx`, `output_fifo`, `ddr16_pairer`, `ddrs2_adapter` | Keeps the TX data path internal and exposes a compact DDRs2-facing interface. | Place north/north-east, output pins north. |
| `MATRIX_CONTROL_CORE` | central `event_coordinator`, central `matrix_reset_ctrl`, central `matrix_cfg_ctrl`, optional local CSR | Reduces small bottom-control macros. | Do not trap R/Y/B/Rz/Yz/Bz/Din/Cin/Dout/Cout boundary flops away from matrix pins. |
| `POSITION_CORE` | packet cluster logic and position packetizer | Places packet generation between matrix and TX. | Keep matrix-adjacent capture soft/guided until congestion is known. |

Do not combine matrix analog, MPTDC internals, DDRs2 analog, TXRX4TDC analog, or
pad-ring circuitry into synthesized digital blocks.

## 4. Pin Placement Strategy

Pin orientation is more important than final routing at this stage:

| Block | Important pins | Preferred pin direction |
| --- | --- | --- |
| `matrix_reset_ctrl` | `snapshot_R/Y/B_i`, `Rz/Yz/Bz_o`, `start_i`, `done_o` | Matrix-facing pins west/left; control pins south/east. |
| `matrix_cfg_ctrl` | `matrix_din/cin_o`, `matrix_dout/cout_i`, `clk_cfg_40m`, status/control | Matrix pins west/left; CSR/control pins south/east; clock pins south/central. |
| `position_snapshot` | `snapshot_R/Y/B_i`, packet stream out | Matrix pins west/left; packet stream east/north-east. |
| `event_coordinator` | activity/reset/bundle/status masks | Matrix/control pins west/south; packet/TX pins north/east. |
| `event_bundle_tx` | source streams, `word_*` output | source pins south/west/east by producer; output north toward FIFO/TX. |
| `output_fifo` | push stream, pop stream, watermarks | push south/west; pop north/east. |
| `ddr16_pairer` | FIFO word input, DDR16 L/H output | input south; DDR output north. |
| `ddrs2_adapter` | DDR16 L/H input, DDRs2 19-lane output | input south; DDRs2 output north. |
| `matrix_top_csr` | CSR bus, status inputs, control outputs | CSR/I2C side south/west; control outputs toward bottom/top blocks. |

Final matrix macro connections should be handled in the top assembly/manual
layout. The OOC block abstracts should only make the top routing short and
obvious.

## 5. Genus OOC Strategy

Use typical-only, relaxed constraints first. The existing robust runner remains:

- `TOP/syn/scripts/run_genus_all_matrix_ooc.sh`
- `TOP/syn/scripts/run_genus_matrix_block.tcl`

New single-block entry point:

- `TOP/syn/scripts/run_genus_ooc_block.sh <block-or-top-module> [RUN_ID]`

Per-block manifests were added under:

- `TOP/syn/filelists/ooc/`
- `TOP/syn/constraints/ooc/`

Current runner note: the server runner still uses the filtered `TOP/filelist.f`
path because that is the Genus-proven path. The OOC manifests are the starting
point for the next pruned-filelist implementation.

Expected Genus output per hardenable block:

- mapped netlist: `<block>.postsyn.v`;
- final SDC used: `<block>.postsyn.sdc`;
- optional SDF: `<block>.postsyn.sdf`;
- `reports/qor/report_area.rpt`;
- `reports/qor/report_area_hierarchy.rpt`;
- `reports/timing/report_timing_post_opt.rpt`;
- `reports/timing/check_timing_intent.rpt`;
- `reports/messages/warning_classification.rpt`;
- block `SUMMARY.md`.

Acceptable early warnings:

- placeholder missing external delay warnings;
- bounded `MESG-11` maximum print count warnings;
- non-signoff timing limits caused by relaxed OOC constraints.

Blocking warnings:

- unresolved references;
- inferred latches in blocks where none are expected;
- Genus command failures;
- missing netlist or SDC output;
- `tool_error count` greater than zero;
- `CHECK_DESIGN_UNRESOLVED_FAILED`.

## 6. Innovus OOC Strategy

The current repository has a collateral gate:

- `TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh`

New single-block entry point:

- `TOP/pnr/scripts/run_innovus_ooc_block.sh <block> <GENUS_RUN_ID> [RUN_ID]`

Current status: this validates Genus collateral and creates per-block Innovus
directories. It does not yet import/place/route. The real Innovus OOC template
still needs to be added after the first matrix-side plan review.

Expected future Innovus output per hardenable block:

- placed/routed DEF;
- LEF abstract;
- GDS if available;
- pin placement report;
- timing report;
- congestion/routability report;
- DRC-oriented report;
- power pin report;
- run manifest and block summary.

## 7. Script Inventory

Existing useful scripts:

| Path | Current role |
| --- | --- |
| `TOP/scripts/sim/run_tb.sh` | Unit test runner, including Xcelium on server. |
| `TOP/scripts/sim/resolve_flist.sh` | Resolves relative filelists to absolute paths. |
| `TOP/syn/scripts/run_genus_all_matrix_ooc.sh` | Multi-block Genus OOC feasibility runner. |
| `TOP/syn/scripts/run_genus_matrix_block.tcl` | Maintained Genus block implementation. |
| `TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh` | Genus collateral gate for OOC Innovus preparation. |
| `TOP/pnr/scripts/server_run_innovus_matrix_top_staged_floorplan.sh` | Staged top floorplan feasibility planner. |

Scripts added for this plan:

| Path | Role |
| --- | --- |
| `TOP/syn/scripts/run_genus_ooc_block.sh` | Run one named block through the existing Genus OOC flow. |
| `TOP/syn/scripts/run_genus_ooc_block.tcl` | Compatibility Tcl entry point that sources the maintained Tcl. |
| `TOP/pnr/scripts/run_innovus_ooc_block.sh` | Run one named block through the current Innovus collateral gate. |
| `TOP/pnr/scripts/run_innovus_ooc_block.tcl` | Placeholder for the future reviewed Innovus import/place template. |

Still missing before official block place/route:

- real Innovus OOC import/place/preCTS Tcl template;
- per-block pin placement constraints;
- per-block floorplan dimensions/utilization targets;
- abstract generation commands for LEF/GDS/DEF;
- DRC/LVS-oriented report hooks;
- OA/Virtuoso handoff packaging checklist.

## 8. First Server Commands: `matrix_reset_ctrl`

Run this on the server after the patch is pushed.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test

EXPECTED_HEAD=$(git rev-parse HEAD)
echo "EXPECTED_HEAD=$EXPECTED_HEAD"

source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_XH018_STACK=xx31
export MPTDC_STDCELL_FAMILY=JIHD
export MPTDC_PNR_ROUTE_LAYER_NAMES="MET1 MET2 MET3 METTP"

bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_reset_ctrl_unit --sim xrun
TB_RC=$?
echo "TB_RC=$TB_RC"
```

If `TB_RC=0`, run Genus for only `matrix_reset_ctrl`:

```bash
GENUS_RUN_ID=genus_ooc_matrix_reset_ctrl_$(date +%Y%m%d_%H%M)

bash TOP/syn/scripts/run_genus_ooc_block.sh matrix_reset_ctrl "$GENUS_RUN_ID"
GENUS_RC=$?

GENUS_ROOT="$SPADMIC_WORK_ROOT/genus/$GENUS_RUN_ID"
cat "$GENUS_ROOT/SUMMARY.md"
cat "$GENUS_ROOT/matrix_reset_ctrl/SUMMARY.md"
cat "$GENUS_ROOT/matrix_reset_ctrl/reports/messages/warning_classification.rpt"
sed -n '1,120p' "$GENUS_ROOT/matrix_reset_ctrl/reports/qor/report_area.rpt"
sed -n '1,120p' "$GENUS_ROOT/matrix_reset_ctrl/reports/timing/report_timing_post_opt.rpt"
find "$GENUS_ROOT/matrix_reset_ctrl/outputs" -maxdepth 1 -type f -print | sort

echo "GENUS_RC=$GENUS_RC"
echo "GENUS_RUN_ID=$GENUS_RUN_ID"
```

If `GENUS_RC=0`, run the current Innovus OOC collateral gate for only
`matrix_reset_ctrl`:

```bash
PNR_RUN_ID=innovus_ooc_matrix_reset_ctrl_$(date +%Y%m%d_%H%M)

bash TOP/pnr/scripts/run_innovus_ooc_block.sh matrix_reset_ctrl "$GENUS_RUN_ID" "$PNR_RUN_ID"
PNR_RC=$?

PNR_ROOT="$SPADMIC_WORK_ROOT/innovus/$PNR_RUN_ID"
cat "$PNR_ROOT/SUMMARY.md"
cat "$PNR_ROOT/reports/ooc_collateral_manifest.csv"
cat "$PNR_ROOT/blocks/matrix_reset_ctrl/SUMMARY.md"

echo "PNR_RC=$PNR_RC"
echo "PNR_RUN_ID=$PNR_RUN_ID"
```

Files Karim should paste back after the first run:

- `GENUS_RC`, `GENUS_RUN_ID`;
- `TB_RC`;
- `matrix_reset_ctrl/reports/messages/warning_classification.rpt`;
- first 120 lines of `report_area.rpt`;
- first 120 lines of `report_timing_post_opt.rpt`;
- `PNR_RC`, `PNR_RUN_ID`, and `reports/ooc_collateral_manifest.csv`.

## 9. Reuse In Top Layout

Each hardenable block should become a reusable digital lego only after its OOC
netlist and physical abstract are clean enough. Top layout integration should
then:

1. place matrix macro first;
2. reserve MPTDC macro regions at the matrix right side;
3. place matrix-adjacent soft/guided logic near the matrix pins;
4. place control/CSR blocks in bottom/west control region;
5. place position/event/TX blocks progressively toward north/north-east;
6. connect DDRs2-facing pins north into the DDRs2 macro;
7. route or manually assist analog/custom and PG connections at top level.

## 10. Next Block Order

After `matrix_reset_ctrl`:

1. `matrix_cfg_ctrl`;
2. `position_snapshot`;
3. `event_coordinator`;
4. `event_bundle_tx`;
5. `output_fifo`;
6. `ddr16_pairer`;
7. `ddrs2_adapter`;
8. `matrix_top_csr`;
9. candidate `TX_EGRESS_CORE` wrapper after the separate blocks are understood.

Do not start from full top, I2C pad-wrapper, OR64 hard macro, or analog/custom
macro synthesis.
