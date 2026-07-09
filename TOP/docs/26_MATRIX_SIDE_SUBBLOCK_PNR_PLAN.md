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
| Output FIFO | `spadmic_output_fifo_topcfg` wrapper over `spadmic_output_fifo` | Buffers top-configured 17-bit entries: 16 data bits plus ordered flush marker before DDR pairing. |
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
| 6 | `output_fifo` | `spadmic_output_fifo_topcfg` wrapper over `spadmic_output_fifo` | North/north-east TX region, close to pairer. |
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

Current collateral-gate status: this validates Genus collateral and creates
per-block Innovus directories. It does not import/place/route.

First hardening entry point:

- `TOP/pnr/scripts/run_innovus_ooc_harden_block.sh <block> <GENUS_RUN_ID> [RUN_ID]`

Current hardening scope:

- v1 supports only `ddr16_pairer`;
- local abstract floorplan, not absolute top placement;
- generated pin plan from `TOP/docs/layout_audits/SPADMIC2_20260709_072331`;
- ordinary signal routing limited to `MET1`-`MET3`;
- one north `VDD` and one north `VSS` access pin on `METTP`;
- local special PG routing disabled by default, with exported `METTP`
  `VDD`/`VSS` pins handed to the top-level hookup flow
  (`SPADMIC_OOC_ENABLE_PG_SROUTE=1` enables an experimental local PG route);
- place, CTS, route, filler, post-route setup/hold/DRV, Innovus DRC, and
  Innovus connectivity reports;
- DEF, LEF/abstract LEF, GDS, routed netlist, status report, and handoff package.

The output label is `ABSTRACT_READY_FOR_TOP_REVIEW` only when the Innovus OOC
wrapper reaches the export/handoff gate. It is not `SIGNOFF_READY`; PVS, PEX,
MMMC, foundry LVS, and direct OA import are deferred.

Expected Innovus hardening output per supported hardenable block:

- placed/routed DEF;
- LEF abstract;
- GDS;
- pin placement report;
- setup and hold timing reports;
- congestion/routability report;
- Innovus DRC/connectivity reports;
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
| `TOP/pnr/scripts/gen_ooc_block_harden_plan.py` | Generate first-block local floorplan/pin-plan collateral from the SPADMIC2 layout audit CSVs. |
| `TOP/pnr/scripts/run_innovus_ooc_harden_block.sh` | Run one supported block through real Innovus OOC hardening. |
| `TOP/pnr/scripts/run_innovus_ooc_harden_block.tcl` | Innovus import/place/CTS/route/filler/export template for supported OOC hardening blocks. |

Still missing before final signoff:

- PVS DRC/LVS replay for the exported GDS/source;
- extraction/PEX handoff;
- MMMC signoff views;
- final top-level OA import validation.

## 8. First Hardening Command: `ddr16_pairer`

Run this on the server using a clean Genus OOC `ddr16_pairer` run, for example
`genus_ooc_ddr16_pairer_20260709_0705`.

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
export SPADMIC_LAYOUT_AUDIT_DIR="$PWD/TOP/docs/layout_audits/SPADMIC2_20260709_072331"

GENUS_RUN_ID=genus_ooc_ddr16_pairer_20260709_0705
PNR_RUN_ID=innovus_ooc_harden_ddr16_pairer_$(date +%Y%m%d_%H%M)

bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh ddr16_pairer "$GENUS_RUN_ID" "$PNR_RUN_ID"
PNR_RC=$?

PNR_ROOT="$SPADMIC_WORK_ROOT/innovus/$PNR_RUN_ID"
BLOCK_ROOT="$PNR_ROOT/blocks/ddr16_pairer"
cat "$PNR_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/reports/ooc_harden_status.rpt"
cat "$PNR_ROOT/reports/ooc_harden_manifest.csv"
find "$BLOCK_ROOT/outputs" -maxdepth 1 -type f -print | sort

echo "PNR_RC=$PNR_RC"
echo "PNR_RUN_ID=$PNR_RUN_ID"
echo "PNR_ROOT=$PNR_ROOT"
```

If `RESULT=ABSTRACT_READY_FOR_TOP_REVIEW`, copy the handoff root from the
summary into the top-layout review flow. If the result is
`INNOVUS_TC_OOC_REVIEW_REQUIRED`, inspect the named reports first; do not
advance it as a clean abstract.

## 9. Earlier Collateral-Only Commands: `matrix_reset_ctrl`

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

## 11. Recorded Server Result: `matrix_reset_ctrl`

Server result recorded from the first staged block run on July 8, 2026.

| Item | Value |
| --- | --- |
| Source commit | `017de251a41765f188ccf179554ff03c2abe0195` |
| Unit test | `tb_spadmic_matrix_reset_ctrl_unit` |
| Unit test result | PASS, `15 pass / 0 fail`, `TB_RC=0` |
| Unit test log | `TOP/build/directed/tb_spadmic_matrix_reset_ctrl_unit/run.log` |
| Genus run ID | `genus_ooc_matrix_reset_ctrl_20260708_1424` |
| Genus run root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_matrix_reset_ctrl_20260708_1424` |
| Genus block root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_matrix_reset_ctrl_20260708_1424/matrix_reset_ctrl` |
| Genus result | PASS, 1 block, 0 failed |
| Innovus OOC gate run ID | `innovus_ooc_matrix_reset_ctrl_20260708_1426` |
| Innovus OOC gate root | `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_matrix_reset_ctrl_20260708_1426` |
| Innovus OOC gate result | `READY_FOR_NEXT_IMPORT_TEMPLATE`, `PNR_RC=0` |

Genus warning classification:

- `tool_error count=0`;
- `unresolved count=0`;
- `inferred_latch count=0`;
- `design_rule count=0`;
- `no_clock_waveform count=0`;
- `missing_external_delay count=2`, accepted for this relaxed OOC stage;
- `tool_warning count=2`, bounded `MESG-11` print-count warnings;
- `undriven count=8` is a classifier false positive because the first matching
  report line says `Undriven Port(s) 0`.

Area and timing:

- cell area: `18542.541 um^2` = `0.018543 mm^2`;
- net area: `9428.707 um^2` = `0.009429 mm^2`;
- total estimated area: `27971.248 um^2` = `0.027971 mm^2`;
- worst shown relaxed setup slack: `+2494 ps` at `clk_sys = 6.25 ns`.

Generated Genus outputs:

```text
/sim/ksabra/SPADMIC_work/genus/genus_ooc_matrix_reset_ctrl_20260708_1424/matrix_reset_ctrl/outputs/matrix_reset_ctrl.postsyn.sdc
/sim/ksabra/SPADMIC_work/genus/genus_ooc_matrix_reset_ctrl_20260708_1424/matrix_reset_ctrl/outputs/matrix_reset_ctrl.postsyn.sdf
/sim/ksabra/SPADMIC_work/genus/genus_ooc_matrix_reset_ctrl_20260708_1424/matrix_reset_ctrl/outputs/matrix_reset_ctrl.postsyn.v
```

Conclusion for this stage: `matrix_reset_ctrl` is valid Genus OOC collateral
for the next real Innovus import/template step. It is not a routed block and not
signoff.

## 12. Next Server Commands: `matrix_cfg_ctrl`

`matrix_cfg_ctrl` is the next block because it is the next matrix-control block
in the planned order. It is more sensitive than reset because it has:

- `clk_sys` and `clk_cfg_40m`;
- stable-bus/toggle CDC between the two domains;
- 44 `matrix_cout_i` pulse-clocked samplers;
- matrix-facing Din/Cin/Dout/Cout pins that may remain soft or region-guided
  at final top assembly.

Run from the server checkout:

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
```

Run the matrix config tests:

```bash
bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_cfg_ctrl_unit --sim xrun
TB_CFG_RC=$?

bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_cfg_cout_readback_unit --sim xrun
TB_COUT_RC=$?

echo "TB_CFG_RC=$TB_CFG_RC"
echo "TB_COUT_RC=$TB_COUT_RC"
echo "TB_CFG_LOG=TOP/build/directed/tb_spadmic_matrix_cfg_ctrl_unit/run.log"
echo "TB_COUT_LOG=TOP/build/directed/tb_spadmic_matrix_cfg_cout_readback_unit/run.log"
```

If both test return codes are zero, run Genus OOC for this block only:

```bash
GENUS_RUN_ID=genus_ooc_matrix_cfg_ctrl_$(date +%Y%m%d_%H%M)

bash TOP/syn/scripts/run_genus_ooc_block.sh matrix_cfg_ctrl "$GENUS_RUN_ID"
GENUS_RC=$?

GENUS_ROOT="$SPADMIC_WORK_ROOT/genus/$GENUS_RUN_ID"
BLOCK_ROOT="$GENUS_ROOT/matrix_cfg_ctrl"

cat "$GENUS_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/reports/messages/warning_classification.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/qor/report_area.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/check_timing_intent.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_clocks.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_timing_post_opt.rpt"
find "$BLOCK_ROOT/outputs" -maxdepth 1 -type f -print | sort

echo "GENUS_RC=$GENUS_RC"
echo "GENUS_RUN_ID=$GENUS_RUN_ID"
echo "GENUS_ROOT=$GENUS_ROOT"
echo "BLOCK_ROOT=$BLOCK_ROOT"
```

Additional report probes for this CDC-heavy block:

```bash
find "$BLOCK_ROOT/reports/timing" \
  -maxdepth 1 -type f \
  \( -name 'report_timing_clk_*' -o -name 'report_timing_unconstrained_clk_*' \) \
  -print -exec sed -n '1,120p' {} \;

grep -RniE 'REPORT_COMMAND_FAILED|ELABORATION_FAILED|CHECK_DESIGN_UNRESOLVED_FAILED|TUI-[0-9]+|(^|[|[:space:]])Error([|[:space:]:]|$)' \
  "$BLOCK_ROOT/reports" || true
```

Expected warning posture:

- `tool_error`, `unresolved`, and `inferred_latch` must stay zero;
- missing external delay warnings are acceptable at this OOC stage;
- `no_clock_waveform` may appear because `matrix_cout_i[43:0]` are pulse
  capture inputs used by `spadmic_matrix_cout_bit_sampler`; review the first
  matching line before accepting it;
- inter-clock timing reports between `clk_sys` and `clk_cfg_40m` should be
  present because this block has both clocks.

If `GENUS_RC=0`, run the current single-block Innovus OOC collateral gate:

```bash
PNR_RUN_ID=innovus_ooc_matrix_cfg_ctrl_$(date +%Y%m%d_%H%M)

bash TOP/pnr/scripts/run_innovus_ooc_block.sh matrix_cfg_ctrl "$GENUS_RUN_ID" "$PNR_RUN_ID"
PNR_RC=$?

PNR_ROOT="$SPADMIC_WORK_ROOT/innovus/$PNR_RUN_ID"
cat "$PNR_ROOT/SUMMARY.md"
cat "$PNR_ROOT/reports/ooc_collateral_manifest.csv"
cat "$PNR_ROOT/blocks/matrix_cfg_ctrl/SUMMARY.md"

echo "PNR_RC=$PNR_RC"
echo "PNR_RUN_ID=$PNR_RUN_ID"
echo "PNR_ROOT=$PNR_ROOT"
```

Paste back after the run:

- `TB_CFG_RC`, `TB_COUT_RC`;
- `GENUS_RC`, `GENUS_RUN_ID`, `GENUS_ROOT`, `BLOCK_ROOT`;
- `warning_classification.rpt`;
- first 180 lines of `report_area.rpt`;
- first 180 lines of `check_timing_intent.rpt`;
- first 180 lines of `report_clocks.rpt`;
- first 180 lines of `report_timing_post_opt.rpt`;
- all inter-clock/unconstrained timing report headers printed by the `find`
  command;
- `PNR_RC`, `PNR_RUN_ID`, `PNR_ROOT`;
- `ooc_collateral_manifest.csv`.

## 13. Recorded Server Result: `matrix_cfg_ctrl`

Server result recorded from the second staged block run on July 8, 2026.

| Item | Value |
| --- | --- |
| Source commit | `017de251a41765f188ccf179554ff03c2abe0195` |
| Unit tests | `tb_spadmic_matrix_cfg_ctrl_unit`, `tb_spadmic_matrix_cfg_cout_readback_unit` |
| Unit test result | PASS, `TB_CFG_RC=0`, `TB_COUT_RC=0` |
| Unit test logs | `TOP/build/directed/tb_spadmic_matrix_cfg_ctrl_unit/run.log`, `TOP/build/directed/tb_spadmic_matrix_cfg_cout_readback_unit/run.log` |
| Genus run ID | `genus_ooc_matrix_cfg_ctrl_20260708_1432` |
| Genus run root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_matrix_cfg_ctrl_20260708_1432` |
| Genus block root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_matrix_cfg_ctrl_20260708_1432/matrix_cfg_ctrl` |
| Genus result | PASS, 1 block, 0 failed, `GENUS_RC=0` |
| Innovus OOC gate run ID | `innovus_ooc_matrix_cfg_ctrl_20260708_1436` |
| Innovus OOC gate root | `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_matrix_cfg_ctrl_20260708_1436` |
| Innovus OOC gate result | `READY_FOR_NEXT_IMPORT_TEMPLATE`, `PNR_RC=0` |

Genus warning classification:

- `tool_error count=0`;
- `unresolved count=0`;
- `inferred_latch count=0`;
- `design_rule count=0`;
- `missing_external_delay count=2`, accepted for this relaxed OOC stage;
- `tool_warning count=2`, bounded `MESG-11` print-count warnings;
- `undriven count=8` is a classifier false positive because the detailed
  Genus check-design text reports `Undriven Port(s) 0`;
- `no_clock_waveform count=89` is accepted only as a documented OOC/CDC item:
  the first lines are the `matrix_cout_i[43:0]` pulse-capture clocks feeding
  `spadmic_matrix_cout_bit_sampler` capture registers. This is not signoff STA
  closure and must be revisited before final CDC/STA signoff.

Area and timing:

- cell count: `2150`;
- cell area: `74383.411 um^2` = `0.074383 mm^2`;
- net area: `30670.329 um^2` = `0.030670 mm^2`;
- total estimated area: `105053.740 um^2` = `0.105054 mm^2`;
- clocks reported: `clk_sys` at `6250 ps`, `clk_cfg_40m` at `25000 ps`;
- worst shown relaxed setup slack in `report_timing_post_opt.rpt`: `+3490 ps`.

CDC and unconstrained timing notes:

- reports for `clk_sys` to/from `clk_cfg_40m` were generated;
- the unconstrained report shows expected relaxed-OOC paths through the
  stable-bus/toggle CDC structure, for example `wdata_hold_sys_reg` to
  `wdata_cfg_reg` and return readback/status paths;
- the grep probe that included bare `Error` matched signal names such as
  `error_o` and `last_error_o`; it did not show an actual tool error because
  `tool_error count=0` and the block summary was PASS.

Generated Genus outputs:

```text
/sim/ksabra/SPADMIC_work/genus/genus_ooc_matrix_cfg_ctrl_20260708_1432/matrix_cfg_ctrl/outputs/matrix_cfg_ctrl.postsyn.sdc
/sim/ksabra/SPADMIC_work/genus/genus_ooc_matrix_cfg_ctrl_20260708_1432/matrix_cfg_ctrl/outputs/matrix_cfg_ctrl.postsyn.sdf
/sim/ksabra/SPADMIC_work/genus/genus_ooc_matrix_cfg_ctrl_20260708_1432/matrix_cfg_ctrl/outputs/matrix_cfg_ctrl.postsyn.v
```

Conclusion for this stage: `matrix_cfg_ctrl` is valid Genus OOC collateral for
the current staged plan and is ready for the next real Innovus import/template
development step. It is not a routed block, not CDC signoff, and not final STA
signoff.

## 14. Next Server Commands: `position_snapshot`

`position_snapshot` is next because it is the first position-data block between
the matrix-facing snapshot frontend and the TX/event path. Keep it OOC for
logic/area/timing evidence, but remember that final placement should still be
guided by the real matrix pin map and top-level region planning.

Run from the server checkout:

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
```

Run the position packetizer tests:

```bash
bash TOP/scripts/sim/run_tb.sh tb_spadmic_position_snapshot_packetizer_unit --sim xrun
TB_POS_PKT_RC=$?

bash TOP/scripts/sim/run_tb.sh tb_spadmic_position_snapshot_cluster_unit --sim xrun
TB_POS_CLUSTER_RC=$?

bash TOP/scripts/sim/run_tb.sh tb_spadmic_position_modes_unit --sim xrun
TB_POS_MODES_RC=$?

echo "TB_POS_PKT_RC=$TB_POS_PKT_RC"
echo "TB_POS_CLUSTER_RC=$TB_POS_CLUSTER_RC"
echo "TB_POS_MODES_RC=$TB_POS_MODES_RC"
echo "TB_POS_PKT_LOG=TOP/build/directed/tb_spadmic_position_snapshot_packetizer_unit/run.log"
echo "TB_POS_CLUSTER_LOG=TOP/build/directed/tb_spadmic_position_snapshot_cluster_unit/run.log"
echo "TB_POS_MODES_LOG=TOP/build/directed/tb_spadmic_position_modes_unit/run.log"
```

If all three test return codes are zero, run Genus OOC for this block only:

```bash
GENUS_RUN_ID=genus_ooc_position_snapshot_$(date +%Y%m%d_%H%M)

bash TOP/syn/scripts/run_genus_ooc_block.sh position_snapshot "$GENUS_RUN_ID"
GENUS_RC=$?

GENUS_ROOT="$SPADMIC_WORK_ROOT/genus/$GENUS_RUN_ID"
BLOCK_ROOT="$GENUS_ROOT/position_snapshot"

cat "$GENUS_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/reports/messages/warning_classification.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/qor/report_area.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/check_timing_intent.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_clocks.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_timing_post_opt.rpt"
find "$BLOCK_ROOT/outputs" -maxdepth 1 -type f -print | sort

grep -RniE 'REPORT_COMMAND_FAILED|ELABORATION_FAILED|CHECK_DESIGN_UNRESOLVED_FAILED|TUI-[0-9]+|(^|[|[:space:]])Error([|[:space:]:]|$)' \
  "$BLOCK_ROOT/reports" || true

echo "GENUS_RC=$GENUS_RC"
echo "GENUS_RUN_ID=$GENUS_RUN_ID"
echo "GENUS_ROOT=$GENUS_ROOT"
echo "BLOCK_ROOT=$BLOCK_ROOT"
```

Expected warning posture:

- `tool_error`, `unresolved`, and `inferred_latch` must stay zero;
- missing external delay warnings are acceptable for this relaxed OOC stage;
- `no_clock_waveform` should normally stay zero for this block; if it appears,
  inspect the first matching line before accepting the run;
- `clk_ref_40m` and `clk_cfg_40m` inter-clock reports are not expected because
  this block is a `clk_sys` packetizer.

If `GENUS_RC=0`, run the current single-block Innovus OOC collateral gate:

```bash
PNR_RUN_ID=innovus_ooc_position_snapshot_$(date +%Y%m%d_%H%M)

bash TOP/pnr/scripts/run_innovus_ooc_block.sh position_snapshot "$GENUS_RUN_ID" "$PNR_RUN_ID"
PNR_RC=$?

PNR_ROOT="$SPADMIC_WORK_ROOT/innovus/$PNR_RUN_ID"
cat "$PNR_ROOT/SUMMARY.md"
cat "$PNR_ROOT/reports/ooc_collateral_manifest.csv"
cat "$PNR_ROOT/blocks/position_snapshot/SUMMARY.md"

echo "PNR_RC=$PNR_RC"
echo "PNR_RUN_ID=$PNR_RUN_ID"
echo "PNR_ROOT=$PNR_ROOT"
```

Paste back after the run:

- `TB_POS_PKT_RC`, `TB_POS_CLUSTER_RC`, `TB_POS_MODES_RC`;
- `GENUS_RC`, `GENUS_RUN_ID`, `GENUS_ROOT`, `BLOCK_ROOT`;
- `warning_classification.rpt`;
- first 180 lines of `report_area.rpt`;
- first 180 lines of `check_timing_intent.rpt`;
- first 180 lines of `report_clocks.rpt`;
- first 180 lines of `report_timing_post_opt.rpt`;
- `PNR_RC`, `PNR_RUN_ID`, `PNR_ROOT`;
- `ooc_collateral_manifest.csv`.

## 15. Recorded Server Result: `position_snapshot`

Server result recorded from the third staged block run on July 8, 2026.

| Item | Value |
| --- | --- |
| Source commit | `017de251a41765f188ccf179554ff03c2abe0195` |
| Unit tests | `tb_spadmic_position_snapshot_packetizer_unit`, `tb_spadmic_position_snapshot_cluster_unit`, `tb_spadmic_position_modes_unit` |
| Unit test result | PASS, `TB_POS_PKT_RC=0`, `TB_POS_CLUSTER_RC=0`, `TB_POS_MODES_RC=0` |
| Genus run ID | `genus_ooc_position_snapshot_20260708_1441` |
| Genus run root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_position_snapshot_20260708_1441` |
| Genus block root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_position_snapshot_20260708_1441/position_snapshot` |
| Genus result | PASS, 1 block, 0 failed, `GENUS_RC=0` |
| Innovus OOC gate run ID | `innovus_ooc_position_snapshot_20260708_1455` |
| Innovus OOC gate root | `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_position_snapshot_20260708_1455` |
| Innovus OOC gate result | `READY_FOR_NEXT_IMPORT_TEMPLATE`, `PNR_RC=0` |

Genus warning classification:

- `tool_error count=0`;
- `unresolved count=0`;
- `inferred_latch count=0`;
- `design_rule count=0`;
- `no_clock_waveform count=0`;
- `missing_external_delay count=2`, accepted for this relaxed OOC stage;
- `tool_warning count=2`, bounded `MESG-11` print-count warnings;
- `undriven count=8` is a classifier false positive because the detailed
  Genus check-design text reports `Undriven Port(s) 0`.

Area and timing:

- cell count: `6988`;
- cell area: `182191.565 um^2` = `0.182192 mm^2`;
- net area: `105578.406 um^2` = `0.105578 mm^2`;
- total estimated area: `287769.971 um^2` = `0.287770 mm^2`;
- clock reported: `clk_sys` at `6250 ps`, `2437` registers;
- worst shown relaxed setup slack in `report_timing_post_opt.rpt`: `+7 ps`.

Timing risk:

- The run is technically passing for this relaxed typical-only Genus OOC stage,
  but the worst path is effectively at the edge of the `160 MHz` budget.
- The critical path is in the cluster scan logic, for example from
  `u_*_cluster_scan_gap_threshold_q_reg` into cluster `hi` registers.
- Before claiming physical readiness for a hardened `POSITION_CORE`, review
  whether the cluster scan needs pipelining, reduced fanout, a slower mode, or
  a region-guided soft placement rather than immediate hardening.

Generated Genus outputs:

```text
/sim/ksabra/SPADMIC_work/genus/genus_ooc_position_snapshot_20260708_1441/position_snapshot/outputs/position_snapshot.postsyn.sdc
/sim/ksabra/SPADMIC_work/genus/genus_ooc_position_snapshot_20260708_1441/position_snapshot/outputs/position_snapshot.postsyn.sdf
/sim/ksabra/SPADMIC_work/genus/genus_ooc_position_snapshot_20260708_1441/position_snapshot/outputs/position_snapshot.postsyn.v
```

Conclusion for this stage: `position_snapshot` is valid Genus OOC collateral
and the current Innovus collateral gate found all required files. It is not a
routed block and should not be treated as timing-closed until the cluster-scan
critical path is addressed or physically proven with real Innovus implementation.

## 16. Next Server Commands: `event_coordinator`

`event_coordinator` is next because it is the mode-aware control block between
matrix activity, calibration activity, reset acknowledgement, position/TDC
packet availability, and bundle transmit start. It is single-clock `clk_sys`,
so this should be a cleaner OOC run than `matrix_cfg_ctrl` and
`position_snapshot`.

Run from the server checkout:

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
```

Run the event coordinator test:

```bash
bash TOP/scripts/sim/run_tb.sh tb_spadmic_event_coordinator_modes_unit --sim xrun
TB_EVT_RC=$?

echo "TB_EVT_RC=$TB_EVT_RC"
echo "TB_EVT_LOG=TOP/build/directed/tb_spadmic_event_coordinator_modes_unit/run.log"
```

If the test return code is zero, run Genus OOC for this block only:

```bash
GENUS_RUN_ID=genus_ooc_event_coordinator_$(date +%Y%m%d_%H%M)

bash TOP/syn/scripts/run_genus_ooc_block.sh event_coordinator "$GENUS_RUN_ID"
GENUS_RC=$?

GENUS_ROOT="$SPADMIC_WORK_ROOT/genus/$GENUS_RUN_ID"
BLOCK_ROOT="$GENUS_ROOT/event_coordinator"

cat "$GENUS_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/reports/messages/warning_classification.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/qor/report_area.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/check_timing_intent.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_clocks.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_timing_post_opt.rpt"
find "$BLOCK_ROOT/outputs" -maxdepth 1 -type f -print | sort

grep -RniE 'REPORT_COMMAND_FAILED|ELABORATION_FAILED|CHECK_DESIGN_UNRESOLVED_FAILED|TUI-[0-9]+|(^|[|[:space:]])Error([|[:space:]:]|$)' \
  "$BLOCK_ROOT/reports" || true

echo "GENUS_RC=$GENUS_RC"
echo "GENUS_RUN_ID=$GENUS_RUN_ID"
echo "GENUS_ROOT=$GENUS_ROOT"
echo "BLOCK_ROOT=$BLOCK_ROOT"
```

Expected warning posture:

- `tool_error`, `unresolved`, and `inferred_latch` must stay zero;
- missing external delay warnings are acceptable for this relaxed OOC stage;
- `no_clock_waveform` should stay zero because this block is single-clock
  `clk_sys`;
- `clk_ref_40m` and `clk_cfg_40m` inter-clock reports are not expected.

If `GENUS_RC=0`, run the current single-block Innovus OOC collateral gate:

```bash
PNR_RUN_ID=innovus_ooc_event_coordinator_$(date +%Y%m%d_%H%M)

bash TOP/pnr/scripts/run_innovus_ooc_block.sh event_coordinator "$GENUS_RUN_ID" "$PNR_RUN_ID"
PNR_RC=$?

PNR_ROOT="$SPADMIC_WORK_ROOT/innovus/$PNR_RUN_ID"
cat "$PNR_ROOT/SUMMARY.md"
cat "$PNR_ROOT/reports/ooc_collateral_manifest.csv"
cat "$PNR_ROOT/blocks/event_coordinator/SUMMARY.md"

echo "PNR_RC=$PNR_RC"
echo "PNR_RUN_ID=$PNR_RUN_ID"
echo "PNR_ROOT=$PNR_ROOT"
```

Paste back after the run:

- `TB_EVT_RC`;
- `GENUS_RC`, `GENUS_RUN_ID`, `GENUS_ROOT`, `BLOCK_ROOT`;
- `warning_classification.rpt`;
- first 180 lines of `report_area.rpt`;
- first 180 lines of `check_timing_intent.rpt`;
- first 180 lines of `report_clocks.rpt`;
- first 180 lines of `report_timing_post_opt.rpt`;
- `PNR_RC`, `PNR_RUN_ID`, `PNR_ROOT`;
- `ooc_collateral_manifest.csv`.

## 17. Recorded Server Result: `event_coordinator`

Server result recorded from the fourth staged block run on July 8, 2026.

| Item | Value |
| --- | --- |
| Source commit | `017de251a41765f188ccf179554ff03c2abe0195` |
| Unit test | `tb_spadmic_event_coordinator_modes_unit` |
| Unit test result | PASS, `24 pass / 0 fail`, `TB_EVT_RC=0` |
| Unit test log | `TOP/build/directed/tb_spadmic_event_coordinator_modes_unit/run.log` |
| Genus run ID | `genus_ooc_event_coordinator_20260708_1506` |
| Genus run root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_event_coordinator_20260708_1506` |
| Genus block root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_event_coordinator_20260708_1506/event_coordinator` |
| Genus result | PASS, 1 block, 0 failed, `GENUS_RC=0` |
| Innovus OOC gate run ID | `innovus_ooc_event_coordinator_20260708_1510` |
| Innovus OOC gate root | `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_event_coordinator_20260708_1510` |
| Innovus OOC gate result | `READY_FOR_NEXT_IMPORT_TEMPLATE`, `PNR_RC=0` |

Genus warning classification:

- `tool_error count=0`;
- `unresolved count=0`;
- `inferred_latch count=0`;
- `design_rule count=0`;
- `no_clock_waveform count=0`;
- `missing_external_delay count=2`, accepted for this relaxed OOC stage;
- `tool_warning count=2`, bounded `MESG-11` print-count warnings;
- `undriven count=8` is a classifier false positive because the detailed
  Genus check-design text reports `Undriven Port(s) 0`.

Area and timing:

- cell count: `156`;
- cell area: `4904.704 um^2` = `0.004905 mm^2`;
- net area: `2525.235 um^2` = `0.002525 mm^2`;
- total estimated area: `7429.939 um^2` = `0.007430 mm^2`;
- clock reported: `clk_sys` at `6250 ps`, `51` registers;
- worst shown relaxed setup slack in `report_timing_post_opt.rpt`: `+1969 ps`.

Generated Genus outputs:

```text
/sim/ksabra/SPADMIC_work/genus/genus_ooc_event_coordinator_20260708_1506/event_coordinator/outputs/event_coordinator.postsyn.sdc
/sim/ksabra/SPADMIC_work/genus/genus_ooc_event_coordinator_20260708_1506/event_coordinator/outputs/event_coordinator.postsyn.sdf
/sim/ksabra/SPADMIC_work/genus/genus_ooc_event_coordinator_20260708_1506/event_coordinator/outputs/event_coordinator.postsyn.v
```

Conclusion for this stage: `event_coordinator` is clean OOC collateral for the
current staged plan. It is small, single-clock, and has comfortable relaxed
timing margin. It is still not routed Innovus implementation or signoff.

## 18. Next Server Commands: `event_bundle_tx`

`event_bundle_tx` is next because it starts the TX egress chain. It serializes
the selected TDC/position packet sources into one event stream before the output
FIFO and DDR16/DDRs2 path.

Run from the server checkout:

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
```

Run the bundle transmitter test:

```bash
bash TOP/scripts/sim/run_tb.sh tb_spadmic_event_bundle_tx_unit --sim xrun
TB_BUNDLE_RC=$?

echo "TB_BUNDLE_RC=$TB_BUNDLE_RC"
echo "TB_BUNDLE_LOG=TOP/build/directed/tb_spadmic_event_bundle_tx_unit/run.log"
```

If the test return code is zero, run Genus OOC for this block only:

```bash
GENUS_RUN_ID=genus_ooc_event_bundle_tx_$(date +%Y%m%d_%H%M)

bash TOP/syn/scripts/run_genus_ooc_block.sh event_bundle_tx "$GENUS_RUN_ID"
GENUS_RC=$?

GENUS_ROOT="$SPADMIC_WORK_ROOT/genus/$GENUS_RUN_ID"
BLOCK_ROOT="$GENUS_ROOT/event_bundle_tx"

cat "$GENUS_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/reports/messages/warning_classification.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/qor/report_area.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/check_timing_intent.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_clocks.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_timing_post_opt.rpt"
find "$BLOCK_ROOT/outputs" -maxdepth 1 -type f -print | sort

grep -RniE 'REPORT_COMMAND_FAILED|ELABORATION_FAILED|CHECK_DESIGN_UNRESOLVED_FAILED|TUI-[0-9]+|(^|[|[:space:]])Error([|[:space:]:]|$)' \
  "$BLOCK_ROOT/reports" || true

echo "GENUS_RC=$GENUS_RC"
echo "GENUS_RUN_ID=$GENUS_RUN_ID"
echo "GENUS_ROOT=$GENUS_ROOT"
echo "BLOCK_ROOT=$BLOCK_ROOT"
```

Expected warning posture:

- `tool_error`, `unresolved`, and `inferred_latch` must stay zero;
- missing external delay warnings are acceptable for this relaxed OOC stage;
- `no_clock_waveform` should stay zero because this block is single-clock
  `clk_sys`;
- `clk_ref_40m` and `clk_cfg_40m` inter-clock reports are not expected.

If `GENUS_RC=0`, run the current single-block Innovus OOC collateral gate:

```bash
PNR_RUN_ID=innovus_ooc_event_bundle_tx_$(date +%Y%m%d_%H%M)

bash TOP/pnr/scripts/run_innovus_ooc_block.sh event_bundle_tx "$GENUS_RUN_ID" "$PNR_RUN_ID"
PNR_RC=$?

PNR_ROOT="$SPADMIC_WORK_ROOT/innovus/$PNR_RUN_ID"
cat "$PNR_ROOT/SUMMARY.md"
cat "$PNR_ROOT/reports/ooc_collateral_manifest.csv"
cat "$PNR_ROOT/blocks/event_bundle_tx/SUMMARY.md"

echo "PNR_RC=$PNR_RC"
echo "PNR_RUN_ID=$PNR_RUN_ID"
echo "PNR_ROOT=$PNR_ROOT"
```

Paste back after the run:

- `TB_BUNDLE_RC`;
- `GENUS_RC`, `GENUS_RUN_ID`, `GENUS_ROOT`, `BLOCK_ROOT`;
- `warning_classification.rpt`;
- first 180 lines of `report_area.rpt`;
- first 180 lines of `check_timing_intent.rpt`;
- first 180 lines of `report_clocks.rpt`;
- first 180 lines of `report_timing_post_opt.rpt`;
- `PNR_RC`, `PNR_RUN_ID`, `PNR_ROOT`;
- `ooc_collateral_manifest.csv`.

## 19. Recorded Server Result: `event_bundle_tx`

Karim ran step 5 on the server on branch `SPADMIC_test`, source commit
`017de251a41765f188ccf179554ff03c2abe0195`.

| Item | Result |
| --- | --- |
| Xcelium test | `tb_spadmic_event_bundle_tx_unit`: `14 pass / 0 fail` |
| Xcelium return code | `TB_BUNDLE_RC=0` |
| Xcelium log | `TOP/build/directed/tb_spadmic_event_bundle_tx_unit/run.log` |
| Genus run ID | `genus_ooc_event_bundle_tx_20260708_1529` |
| Genus run root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_event_bundle_tx_20260708_1529` |
| Genus block root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_event_bundle_tx_20260708_1529/event_bundle_tx` |
| Genus result | PASS, 1 block, 0 failed, `GENUS_RC=0` |
| Innovus OOC gate run ID | `innovus_ooc_event_bundle_tx_20260708_1531` |
| Innovus OOC gate root | `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_event_bundle_tx_20260708_1531` |
| Innovus OOC gate result | `READY_FOR_NEXT_IMPORT_TEMPLATE`, `PNR_RC=0` |

Genus warning classification:

- `tool_error count=0`;
- `unresolved count=0`;
- `inferred_latch count=0`;
- `design_rule count=0`;
- `no_clock_waveform count=0`;
- `missing_external_delay count=2`, accepted for this relaxed OOC stage;
- `tool_warning count=2`, bounded `MESG-11` print-count warnings;
- `undriven count=8` is a classifier false positive because the detailed
  Genus check-design text reports `Undriven Port(s) 0`.

Area and timing:

- cell count: `132`;
- cell area: `3590.093 um^2` = `0.003590 mm^2`;
- net area: `2687.726 um^2` = `0.002688 mm^2`;
- total estimated area: `6277.819 um^2` = `0.006278 mm^2`;
- clock reported: `clk_sys` at `6250 ps`, `28` registers;
- worst shown relaxed setup slack in `report_timing_post_opt.rpt`: `+2799 ps`.

Generated Genus outputs:

```text
/sim/ksabra/SPADMIC_work/genus/genus_ooc_event_bundle_tx_20260708_1529/event_bundle_tx/outputs/event_bundle_tx.postsyn.sdc
/sim/ksabra/SPADMIC_work/genus/genus_ooc_event_bundle_tx_20260708_1529/event_bundle_tx/outputs/event_bundle_tx.postsyn.sdf
/sim/ksabra/SPADMIC_work/genus/genus_ooc_event_bundle_tx_20260708_1529/event_bundle_tx/outputs/event_bundle_tx.postsyn.v
```

Conclusion for this stage: `event_bundle_tx` is clean OOC collateral for the
current staged plan. It is small, single-clock, and has comfortable relaxed
timing margin. It is still not routed Innovus implementation or signoff.

## 20. Next Server Commands: `output_fifo`

`output_fifo` is next in the TX egress chain. The OOC target is intentionally
`spadmic_output_fifo_topcfg`, not the raw parameter defaults of
`spadmic_output_fifo`. The wrapper matches the matrix-top integration:

- `DATA_W = mptdc_pkg::NARROW_W + 1`, so entries are 17-bit;
- `DEPTH = SPADMIC_OUTPUT_FIFO_DEPTH = 256`;
- `RESERVE_WORDS = SPADMIC_OUTPUT_FIFO_RESERVE_ENTRIES = 129`;
- `LEVEL_W = SPADMIC_OUTPUT_FIFO_LEVEL_W = $clog2(257)`.

Before running this step on the server, pull the patch that adds
`TOP/rtl/spadmic_output_fifo_topcfg.sv` to `TOP/filelist.f` and maps
`output_fifo` to the wrapper in the OOC scripts. The Genus summary should show
top module `spadmic_output_fifo_topcfg`.

Run from the server checkout:

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
```

Run the FIFO directed tests:

```bash
bash TOP/scripts/sim/run_tb.sh tb_spadmic_output_fifo_unit --sim xrun
TB_FIFO_RC=$?

bash TOP/scripts/sim/run_tb.sh tb_spadmic_output_fifo_ddr_marker_unit --sim xrun
TB_FIFO_MARKER_RC=$?

echo "TB_FIFO_RC=$TB_FIFO_RC"
echo "TB_FIFO_MARKER_RC=$TB_FIFO_MARKER_RC"
echo "TB_FIFO_LOG=TOP/build/directed/tb_spadmic_output_fifo_unit/run.log"
echo "TB_FIFO_MARKER_LOG=TOP/build/directed/tb_spadmic_output_fifo_ddr_marker_unit/run.log"
```

If both test return codes are zero, run Genus OOC for this block only:

```bash
GENUS_RUN_ID=genus_ooc_output_fifo_$(date +%Y%m%d_%H%M)

bash TOP/syn/scripts/run_genus_ooc_block.sh output_fifo "$GENUS_RUN_ID"
GENUS_RC=$?

GENUS_ROOT="$SPADMIC_WORK_ROOT/genus/$GENUS_RUN_ID"
BLOCK_ROOT="$GENUS_ROOT/output_fifo"

cat "$GENUS_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/reports/messages/warning_classification.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/qor/report_area.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/check_timing_intent.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_clocks.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_timing_post_opt.rpt"
find "$BLOCK_ROOT/outputs" -maxdepth 1 -type f -print | sort

grep -RniE 'REPORT_COMMAND_FAILED|ELABORATION_FAILED|CHECK_DESIGN_UNRESOLVED_FAILED|TUI-[0-9]+|(^|[|[:space:]])Error([|[:space:]:]|$)' \
  "$BLOCK_ROOT/reports" || true

echo "GENUS_RC=$GENUS_RC"
echo "GENUS_RUN_ID=$GENUS_RUN_ID"
echo "GENUS_ROOT=$GENUS_ROOT"
echo "BLOCK_ROOT=$BLOCK_ROOT"
```

Expected warning posture:

- `tool_error`, `unresolved`, and `inferred_latch` must stay zero;
- `no_clock_waveform` should stay zero because this block is single-clock
  `clk_sys`;
- missing external delay warnings are acceptable for this relaxed OOC stage;
- `clk_ref_40m` and `clk_cfg_40m` inter-clock reports are not expected;
- if the top module is reported as raw `spadmic_output_fifo`, stop and pull the
  wrapper patch before trusting the result.

If `GENUS_RC=0`, run the current single-block Innovus OOC collateral gate:

```bash
PNR_RUN_ID=innovus_ooc_output_fifo_$(date +%Y%m%d_%H%M)

bash TOP/pnr/scripts/run_innovus_ooc_block.sh output_fifo "$GENUS_RUN_ID" "$PNR_RUN_ID"
PNR_RC=$?

PNR_ROOT="$SPADMIC_WORK_ROOT/innovus/$PNR_RUN_ID"
cat "$PNR_ROOT/SUMMARY.md"
cat "$PNR_ROOT/reports/ooc_collateral_manifest.csv"
cat "$PNR_ROOT/blocks/output_fifo/SUMMARY.md"

echo "PNR_RC=$PNR_RC"
echo "PNR_RUN_ID=$PNR_RUN_ID"
echo "PNR_ROOT=$PNR_ROOT"
```

Paste back after the run:

- `TB_FIFO_RC` and `TB_FIFO_MARKER_RC`;
- `GENUS_RC`, `GENUS_RUN_ID`, `GENUS_ROOT`, `BLOCK_ROOT`;
- `warning_classification.rpt`;
- first 180 lines of `report_area.rpt`;
- first 180 lines of `check_timing_intent.rpt`;
- first 180 lines of `report_clocks.rpt`;
- first 180 lines of `report_timing_post_opt.rpt`;
- `PNR_RC`, `PNR_RUN_ID`, `PNR_ROOT`;
- `ooc_collateral_manifest.csv`.

## 21. Recorded Server Result: `output_fifo`

Karim ran the `output_fifo` tests, Genus OOC step, and Innovus OOC collateral
gate on the server on branch `SPADMIC_test`.

| Item | Result |
| --- | --- |
| Source commit for Xcelium/Genus | `eccd432b9801f8781c16ef5fa7494eded08ff77c` |
| Xcelium tests | `tb_spadmic_output_fifo_unit`, `tb_spadmic_output_fifo_ddr_marker_unit` |
| Xcelium return codes | `TB_FIFO_RC=0`, `TB_FIFO_MARKER_RC=0` |
| DDR marker test result | `17 pass / 0 fail` |
| Genus run ID | `genus_ooc_output_fifo_20260709_0653` |
| Genus run root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_output_fifo_20260709_0653` |
| Genus block root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_output_fifo_20260709_0653/output_fifo` |
| Genus top module | `spadmic_output_fifo_topcfg` |
| Genus result | PASS, 1 block, 0 failed, `GENUS_RC=0` |
| Innovus OOC gate commit | `412e14a65cccef1b3a44d41074e21c099df3d133` |
| Innovus OOC gate run ID | `innovus_ooc_output_fifo_20260709_0700` |
| Innovus OOC gate root | `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_output_fifo_20260709_0700` |
| Innovus OOC gate result | `READY_FOR_NEXT_IMPORT_TEMPLATE`, missing collateral count `0`, `PNR_RC=0` |

The run correctly used the matrix-top-configured wrapper
`spadmic_output_fifo_topcfg`, not the raw FIFO defaults.

Genus warning classification:

- `tool_error count=0`;
- `unresolved count=0`;
- `inferred_latch count=0`;
- `design_rule count=0`;
- `no_clock_waveform count=0`;
- `missing_external_delay count=2`, accepted for this relaxed OOC stage;
- `tool_warning count=2`, bounded `MESG-11` print-count warnings;
- `undriven count=8` is a classifier false positive because the detailed
  Genus check-design text reports `Undriven Port(s) 0`.

Area and timing:

- cell count: `7828`;
- cell area: `328421.990 um^2` = `0.328422 mm^2`;
- net area: `130970.578 um^2` = `0.130971 mm^2`;
- total estimated area: `459392.568 um^2` = `0.459393 mm^2`;
- clock reported: `clk_sys` at `6250 ps`, `4378` registers;
- worst shown relaxed setup slack in `report_timing_post_opt.rpt`: `+542 ps`.

Generated Genus outputs:

```text
/sim/ksabra/SPADMIC_work/genus/genus_ooc_output_fifo_20260709_0653/output_fifo/outputs/output_fifo.postsyn.sdc
/sim/ksabra/SPADMIC_work/genus/genus_ooc_output_fifo_20260709_0653/output_fifo/outputs/output_fifo.postsyn.sdf
/sim/ksabra/SPADMIC_work/genus/genus_ooc_output_fifo_20260709_0653/output_fifo/outputs/output_fifo.postsyn.v
```

Innovus OOC collateral manifest:

```text
output_fifo,/sim/ksabra/SPADMIC_work/genus/genus_ooc_output_fifo_20260709_0653/output_fifo/outputs/output_fifo.postsyn.v,/sim/ksabra/SPADMIC_work/genus/genus_ooc_output_fifo_20260709_0653/output_fifo/outputs/output_fifo.postsyn.sdc,/sim/ksabra/SPADMIC_work/genus/genus_ooc_output_fifo_20260709_0653/output_fifo/SUMMARY.md,READY,ready_for_next_import_template
```

Conclusion for this stage: `output_fifo` passed the intended matrix-top wrapper
synthesis gate, but it is a large flop-based FIFO and the relaxed timing margin
is much tighter than the small TX control blocks. This is acceptable for the
current non-signoff OOC collateral stage, but the final implementation should
prefer a memory-macro or custom SRAM/FIFO option if available. The Innovus gate
is still only a collateral-readiness check; it does not run placement, route,
CTS, PG, DRC/LVS, PEX, MMMC, or signoff.

## 22. Recorded Server Result: `ddr16_pairer`

Karim ran the `ddr16_pairer` test, Genus OOC step, and Innovus OOC collateral
gate on the server on branch `SPADMIC_test`, source commit
`bb6a8b8cd66e4954efced5cfbfd20c27c213e608`.

| Item | Result |
| --- | --- |
| Xcelium test | `tb_spadmic_ddr16_tx_pairer_unit`: `14 pass / 0 fail` |
| Xcelium return code | `TB_DDR16_PAIRER_RC=0` |
| Genus run ID | `genus_ooc_ddr16_pairer_20260709_0705` |
| Genus run root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddr16_pairer_20260709_0705` |
| Genus block root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddr16_pairer_20260709_0705/ddr16_pairer` |
| Genus top module | `spadmic_ddr16_tx_pairer` |
| Genus result | PASS, 1 block, 0 failed, `GENUS_RC=0` |
| Innovus OOC gate run ID | `innovus_ooc_ddr16_pairer_20260709_0706` |
| Innovus OOC gate root | `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_ddr16_pairer_20260709_0706` |
| Innovus OOC gate result | `READY_FOR_NEXT_IMPORT_TEMPLATE`, missing collateral count `0`, `PNR_RC=0` |

Genus warning classification:

- `tool_error count=0`;
- `unresolved count=0`;
- `inferred_latch count=0`;
- `design_rule count=0`;
- `no_clock_waveform count=0`;
- `missing_external_delay count=2`, accepted for this relaxed OOC stage;
- `tool_warning count=2`, bounded `MESG-11` print-count warnings;
- `undriven count=8` is a classifier false positive because the detailed
  Genus check-design text reports `Undriven Port(s) 0`.

Area and timing:

- cell count: `109`;
- cell area: `4029.133 um^2` = `0.004029 mm^2`;
- net area: `1656.809 um^2` = `0.001657 mm^2`;
- total estimated area: `5685.942 um^2` = `0.005686 mm^2`;
- clock reported: `clk_sys` at `6250 ps`, `51` registers;
- worst shown relaxed setup slack in `report_timing_post_opt.rpt`: `+3496 ps`.

Generated Genus outputs:

```text
/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddr16_pairer_20260709_0705/ddr16_pairer/outputs/ddr16_pairer.postsyn.sdc
/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddr16_pairer_20260709_0705/ddr16_pairer/outputs/ddr16_pairer.postsyn.sdf
/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddr16_pairer_20260709_0705/ddr16_pairer/outputs/ddr16_pairer.postsyn.v
```

Innovus OOC collateral manifest:

```text
ddr16_pairer,/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddr16_pairer_20260709_0705/ddr16_pairer/outputs/ddr16_pairer.postsyn.v,/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddr16_pairer_20260709_0705/ddr16_pairer/outputs/ddr16_pairer.postsyn.sdc,/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddr16_pairer_20260709_0705/ddr16_pairer/SUMMARY.md,READY,ready_for_next_import_template
```

Conclusion for this stage: `ddr16_pairer` is clean OOC collateral for the
current staged TX path plan. It is small, single-clock, and has comfortable
relaxed timing margin. The Innovus gate is still only a collateral-readiness
check; it does not run placement, route, CTS, PG, DRC/LVS, PEX, MMMC, or signoff.

## 23. Next Server Commands: `ddrs2_adapter`

`ddrs2_adapter` is next because it maps the DDR16 L/H pair interface into the
19-lane DDRs2 macro contract. It should sit directly below or near the DDRs2
custom macro in the north/north-east TX region, with DDRs2-facing pins oriented
north.

This block has a local OOC SDC update for its `clk_160m_i` port. Pull the latest
`SPADMIC_test` commit before running this step.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test

source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_XH018_STACK=xx31
export MPTDC_STDCELL_FAMILY=JIHD
export MPTDC_PNR_ROUTE_LAYER_NAMES="MET1 MET2 MET3 METTP"
```

Run the DDRs2 adapter test:

```bash
bash TOP/scripts/sim/run_tb.sh tb_spadmic_ddrs2_adapter_unit --sim xrun
TB_DDRS2_ADAPTER_RC=$?

echo "TB_DDRS2_ADAPTER_RC=$TB_DDRS2_ADAPTER_RC"
echo "TB_DDRS2_ADAPTER_LOG=TOP/build/directed/tb_spadmic_ddrs2_adapter_unit/run.log"
```

If the test return code is zero, run Genus OOC for this block only:

```bash
GENUS_RUN_ID=genus_ooc_ddrs2_adapter_$(date +%Y%m%d_%H%M)

bash TOP/syn/scripts/run_genus_ooc_block.sh ddrs2_adapter "$GENUS_RUN_ID"
GENUS_RC=$?

GENUS_ROOT="$SPADMIC_WORK_ROOT/genus/$GENUS_RUN_ID"
BLOCK_ROOT="$GENUS_ROOT/ddrs2_adapter"

cat "$GENUS_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/reports/messages/warning_classification.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/qor/report_area.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/check_timing_intent.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_clocks.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_timing_post_opt.rpt"
find "$BLOCK_ROOT/outputs" -maxdepth 1 -type f -print | sort

grep -RniE 'REPORT_COMMAND_FAILED|ELABORATION_FAILED|CHECK_DESIGN_UNRESOLVED_FAILED|TUI-[0-9]+|(^|[|[:space:]])Error([|[:space:]:]|$)' \
  "$BLOCK_ROOT/reports" || true

echo "GENUS_RC=$GENUS_RC"
echo "GENUS_RUN_ID=$GENUS_RUN_ID"
echo "GENUS_ROOT=$GENUS_ROOT"
echo "BLOCK_ROOT=$BLOCK_ROOT"
```

Expected warning posture:

- `tool_error`, `unresolved`, and `inferred_latch` must stay zero;
- `no_clock_waveform` should stay zero after the local `clk_160m_i` OOC SDC
  update;
- missing external delay warnings are acceptable for this relaxed OOC stage;
- the adapter is mostly combinational, so timing reports can be short and may
  not resemble register-to-register control blocks.

If `GENUS_RC=0`, run the current single-block Innovus OOC collateral gate:

```bash
PNR_RUN_ID=innovus_ooc_ddrs2_adapter_$(date +%Y%m%d_%H%M)

bash TOP/pnr/scripts/run_innovus_ooc_block.sh ddrs2_adapter "$GENUS_RUN_ID" "$PNR_RUN_ID"
PNR_RC=$?

PNR_ROOT="$SPADMIC_WORK_ROOT/innovus/$PNR_RUN_ID"
cat "$PNR_ROOT/SUMMARY.md"
cat "$PNR_ROOT/reports/ooc_collateral_manifest.csv"
cat "$PNR_ROOT/blocks/ddrs2_adapter/SUMMARY.md"

echo "PNR_RC=$PNR_RC"
echo "PNR_RUN_ID=$PNR_RUN_ID"
echo "PNR_ROOT=$PNR_ROOT"
```

Paste back after the run:

- `TB_DDRS2_ADAPTER_RC`;
- `GENUS_RC`, `GENUS_RUN_ID`, `GENUS_ROOT`, `BLOCK_ROOT`;
- `warning_classification.rpt`;
- first 180 lines of `report_area.rpt`;
- first 180 lines of `check_timing_intent.rpt`;
- first 180 lines of `report_clocks.rpt`;
- first 180 lines of `report_timing_post_opt.rpt`;
- `PNR_RC`, `PNR_RUN_ID`, `PNR_ROOT`;
- `ooc_collateral_manifest.csv`.

## 24. Server Result: `ddrs2_adapter` Initial OOC Run

Server run summary for the first DDRs2 adapter pass:

| Item | Result |
| --- | --- |
| Source commit | `ed09a90dab7b260dcc4b07cb9dc7350754c399fa` |
| Xcelium test | `tb_spadmic_ddrs2_adapter_unit: 17 pass / 0 fail` |
| Test return code | `TB_DDRS2_ADAPTER_RC=0` |
| Genus run | `genus_ooc_ddrs2_adapter_20260709_0710` |
| Genus block root | `/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddrs2_adapter_20260709_0710/ddrs2_adapter` |
| Genus return code | `GENUS_RC=0` |
| Genus top module | `spadmic_ddrs2_adapter` |
| Innovus OOC gate | `innovus_ooc_ddrs2_adapter_20260709_0710` |
| Innovus return code | `PNR_RC=0` |
| Innovus result | `READY_FOR_NEXT_IMPORT_TEMPLATE`, missing collateral count `0` |

Functional and collateral status:

- the DDRs2 adapter unit test passed all lane mapping, valid-lane, spare-lane,
  enable, forwarded-clock polarity, and inverted-instance checks;
- Genus produced `ddrs2_adapter.postsyn.v`, `ddrs2_adapter.postsyn.sdc`, and
  `ddrs2_adapter.postsyn.sdf`;
- the Innovus OOC collateral wrapper found the Genus netlist and SDC and created
  the per-block run directory.

Genus report details from the first run:

- warning classification: `design_rule=0`, `inferred_latch=0`,
  `tool_error=0`, `unresolved=0`, `no_clock_waveform=0`,
  `missing_external_delay=2`, `tool_warning=3`, `undriven=7`;
- the `undriven` count is the known heading-count false positive class, with
  the first line still reporting `Undriven Port(s) 0`;
- area: cell count `34`, cell area `426.496 um^2`, net area `677.248 um^2`,
  total area `1103.744 um^2`;
- `report_clocks.rpt` said `No clocks to report`;
- `report_timing_post_opt.rpt` reported only unconstrained-path text.

Conclusion for this first pass: the RTL behavior and collateral handoff are good,
but this is not acceptable clocked Genus timing evidence. The local DDRs2 adapter
SDC existed, but the Genus OOC wrapper was still passing only the common
`matrix_top_ooc_common.sdc`; therefore the local `clk_160m_i` clock was not
sourced. The next run must use the updated wrapper that selects
`TOP/syn/constraints/ooc/spadmic_ddrs2_adapter.sdc` for this block.

Innovus OOC collateral manifest from the first run:

```text
ddrs2_adapter,/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddrs2_adapter_20260709_0710/ddrs2_adapter/outputs/ddrs2_adapter.postsyn.v,/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddrs2_adapter_20260709_0710/ddrs2_adapter/outputs/ddrs2_adapter.postsyn.sdc,/sim/ksabra/SPADMIC_work/genus/genus_ooc_ddrs2_adapter_20260709_0710/ddrs2_adapter/SUMMARY.md,READY,ready_for_next_import_template
```

## 25. Next Server Commands: `ddrs2_adapter` Clocked Constraint Rerun

Do not rerun full-top Genus or Innovus. This is a narrow DDRs2 adapter rerun to
prove that the per-block SDC is sourced and that `clk_160m_i` appears in the
clock report.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test
git rev-parse HEAD

source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_XH018_STACK=xx31
export MPTDC_STDCELL_FAMILY=JIHD
export MPTDC_PNR_ROUTE_LAYER_NAMES="MET1 MET2 MET3 METTP"
```

Run Genus OOC for the adapter only:

```bash
GENUS_RUN_ID=genus_ooc_ddrs2_adapter_clocked_$(date +%Y%m%d_%H%M)

bash TOP/syn/scripts/run_genus_ooc_block.sh ddrs2_adapter "$GENUS_RUN_ID"
GENUS_RC=$?

GENUS_ROOT="$SPADMIC_WORK_ROOT/genus/$GENUS_RUN_ID"
BLOCK_ROOT="$GENUS_ROOT/ddrs2_adapter"

cat "$GENUS_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/SUMMARY.md"
cat "$BLOCK_ROOT/selected_sdc.txt"
cat "$BLOCK_ROOT/reports/messages/warning_classification.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/qor/report_area.rpt"
sed -n '1,220p' "$BLOCK_ROOT/reports/timing/check_timing_intent.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_clocks.rpt"
sed -n '1,180p' "$BLOCK_ROOT/reports/timing/report_timing_post_opt.rpt"
find "$BLOCK_ROOT/outputs" -maxdepth 1 -type f -print | sort

grep -nE 'clk_160m_i|No clocks to report' "$BLOCK_ROOT/reports/timing/report_clocks.rpt" || true
grep -RniE 'REPORT_COMMAND_FAILED|ELABORATION_FAILED|CHECK_DESIGN_UNRESOLVED_FAILED|TUI-[0-9]+|(^|[|[:space:]])Error([|[:space:]:]|$)' \
  "$BLOCK_ROOT/reports" || true

echo "GENUS_RC=$GENUS_RC"
echo "GENUS_RUN_ID=$GENUS_RUN_ID"
echo "GENUS_ROOT=$GENUS_ROOT"
echo "BLOCK_ROOT=$BLOCK_ROOT"
```

Expected after this patch:

- `cat "$BLOCK_ROOT/selected_sdc.txt"` prints the absolute path to
  `TOP/syn/constraints/ooc/spadmic_ddrs2_adapter.sdc`;
- `cat "$BLOCK_ROOT/SUMMARY.md"` contains the same constraint file path;
- `report_clocks.rpt` reports `clk_160m_i`, not `No clocks to report`;
- `tool_error`, `unresolved`, and `inferred_latch` remain zero.

If `GENUS_RC=0` and `report_clocks.rpt` reports `clk_160m_i`, run the current
single-block Innovus OOC collateral gate:

```bash
PNR_RUN_ID=innovus_ooc_ddrs2_adapter_clocked_$(date +%Y%m%d_%H%M)

bash TOP/pnr/scripts/run_innovus_ooc_block.sh ddrs2_adapter "$GENUS_RUN_ID" "$PNR_RUN_ID"
PNR_RC=$?

PNR_ROOT="$SPADMIC_WORK_ROOT/innovus/$PNR_RUN_ID"
cat "$PNR_ROOT/SUMMARY.md"
cat "$PNR_ROOT/reports/ooc_collateral_manifest.csv"
cat "$PNR_ROOT/blocks/ddrs2_adapter/SUMMARY.md"

echo "PNR_RC=$PNR_RC"
echo "PNR_RUN_ID=$PNR_RUN_ID"
echo "PNR_ROOT=$PNR_ROOT"
```

Stop and paste back if `report_clocks.rpt` still says `No clocks to report`.
