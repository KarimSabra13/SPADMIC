# SPADMIC Matrix TOP PnR Planning Infrastructure

Status: server-facing floorplan feasibility infrastructure. No local Innovus
run is claimed.

## Matrix CSV Generator

`scripts/gen_matrix_floorplan_from_csv.py` reads:

```text
position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv
```

It requires and uses the normalized `ll_*` columns:

- `ll_center_x`
- `ll_center_y`
- `ll_bbox_x1`
- `ll_bbox_y1`
- `ll_bbox_x2`
- `ll_bbox_y2`

Raw LEF-origin coordinates are not used for planning.

Generated outputs:

```text
matrix_pin_family_summary.csv
matrix_pin_side_summary.csv
matrix_unknown_pins.csv
matrix_floorplan_regions.tcl
floorplan_summary.md
```

`TOP/pnr/generated/` is ignored. Server runs write generated collateral under
`/sim/ksabra/SPADMIC_work/innovus/<RUN_ID>/generated/`.

## Server Floorplan Command

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test
source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
bash TOP/pnr/scripts/server_run_innovus_matrix_top_floorplan.sh matrix_top_fp_<run_id>
```

Default matrix LEF:

```text
/group/validmgr/PROJET/Prj_xh018/ksabra/lef/matrice3.lef
```

Override with `SPADMIC_MATRIX_LEF` or `SPADMIC_MATRIX_PIN_CSV` if needed.

## Staged Top Floorplan Command

The next physical flow should use the staged wrapper before any real top
placement. It generates full-die/core/matrix/MPTDC/pad-policy reports and
intentionally stops before Innovus if the geometry is infeasible.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test
source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_XH018_STACK=xx31
export MPTDC_STDCELL_FAMILY=JIHD
export MPTDC_PNR_ROUTE_LAYER_NAMES="MET1 MET2 MET3 METTP"
RUN_ID=innovus_matrix_top_staged_fp_$(date +%Y%m%d_%H%M)
bash TOP/pnr/scripts/server_run_innovus_matrix_top_staged_floorplan.sh "$RUN_ID"
```

Default planning inputs:

- full-die envelope: `4293.179 um x 3209.173 um`;
- pad-ring/core planning depth: `164 um`;
- BOX_RING/OA source:
  `/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/SPADMIC`;
- MPTDC Scenario B: full DEF/block boundary `1061.20 um x 801.92 um`,
  `5%` dimension margin, `20 um` halo, and `20 um` inter-axis gap, ordered
  R/Y/B from top to bottom;
- pad policy template:
  `TOP/pnr/inputs/matrix_top_pad_policy_template.csv`.
- wrapper/pad contract:
  `TOP/docs/24_MATRIX_TOP_CHIP_WRAPPER_PAD_CONTRACT.md`.

Under those defaults the expected result is a Scenario B geometry pass. Any
failure should stop before Innovus and be reviewed as a geometry issue, not
silently repaired by changing to a 2+1 MPTDC arrangement or increasing die
height.

## Staged OOC Collateral Gate

After a clean Genus OOC run, validate per-block collateral before adding real
Innovus import/place/preCTS commands:

```bash
OOC_RUN_ID=innovus_matrix_ooc_gate_$(date +%Y%m%d_%H%M)
bash TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh "$OOC_RUN_ID" "$GENUS_RUN_ID"
```

For a single block in the staged flow:

```bash
PNR_RUN_ID=innovus_ooc_matrix_reset_ctrl_$(date +%Y%m%d_%H%M)
bash TOP/pnr/scripts/run_innovus_ooc_block.sh matrix_reset_ctrl "$GENUS_RUN_ID" "$PNR_RUN_ID"
```

The OOC gate is connectivity-first and includes `ddr16_pairer` by default,
because the north SLVS row is now part of the staged top contract. Set
`SPADMIC_INNOVUS_EXCLUDE_DDR16=1` only for a narrow debug rerun.

## OOC Hardening Command

The first real block implementation wrapper is separate from the collateral
gate:

```bash
GENUS_RUN_ID=genus_ooc_ddr16_pairer_20260709_0705
PNR_RUN_ID=innovus_ooc_harden_ddr16_pairer_$(date +%Y%m%d_%H%M)
bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh ddr16_pairer "$GENUS_RUN_ID" "$PNR_RUN_ID"
```

The hardening wrapper supports TX leaf hardening (`event_bundle_tx`,
`output_fifo`, `ddr16_pairer`, `ddrs2_adapter`) plus the legacy/assembly
`tx_egress_core` path. It imports the Genus OOC netlist/SDC, generates a local
abstract plan from
`TOP/docs/layout_audits/SPADMIC2_20260709_072331`, places pins, creates one
north `VDD` and one north `VSS` `METTP` access pin, runs placement, CTS,
route, filler insertion, post-route setup/hold/DRV reports, Innovus DRC and
connectivity reports, then exports DEF/LEF/GDS collateral under the Innovus run
root and `/sim/ksabra/SPADMIC_work/handoff/abstracts/<block>/<RUN_ID>/`.
Local special PG routing is disabled by default: the exported METTP VDD/VSS
pins are a top-level hookup contract. Set `SPADMIC_OOC_ENABLE_PG_SROUTE=1`
only for an experimental local PG special-route run.

The preferred TX recovery path is now four clean leaf abstracts followed by a
local TX assembly review. Run the DDRs2 adapter first because it owns the wide,
CSV-aligned north pins under the DDRs2 macro:

```bash
export SPADMIC_OOC_REQUIRE_DRC_SAFE_FILLER=1
export SPADMIC_OOC_ENABLE_MIN_AREA_REPAIR=1
unset SPADMIC_GENUS_ALLOW_SCAN_CELLS
unset SPADMIC_OOC_IGNORE_UNDEFINED_SCAN
unset SPADMIC_OOC_ENABLE_PG_SROUTE

GENUS_RUN_ID=genus_ooc_tx_leafs_$(date +%Y%m%d_%H%M)
export SPADMIC_GENUS_OOC_BLOCKS="ddrs2_adapter:spadmic_ddrs2_adapter ddr16_pairer:spadmic_ddr16_tx_pairer output_fifo:spadmic_output_fifo_topcfg event_bundle_tx:spadmic_event_bundle_tx"
bash TOP/syn/scripts/run_genus_all_matrix_ooc.sh "$GENUS_RUN_ID"
unset SPADMIC_GENUS_OOC_BLOCKS
bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh ddrs2_adapter "$GENUS_RUN_ID" \
  innovus_ooc_harden_ddrs2_adapter_$(date +%Y%m%d_%H%M)
```

Then harden `ddr16_pairer`, `output_fifo`, and `event_bundle_tx` from the same
Genus run. The stop gate for moving on to OR tree/snapshot/position work is zero
non-PG `verify_drc` markers, regular connectivity PASS, setup/hold PASS, and PG
explicitly deferred to top-level hookup. Do not use the wide monolithic
`tx_egress_core` route profile loop as the primary closure path unless the
leaf/assembly path needs a regression comparison.

The OOC Genus runner avoids scan-capable sequential cells by default because
these prototype abstracts do not have scan-chain DEF. The Innovus wrapper also
sets scan placement to ignore undefined scan-chain ordering. Use
`SPADMIC_GENUS_ALLOW_SCAN_CELLS=1` or `SPADMIC_OOC_IGNORE_UNDEFINED_SCAN=0`
only for an explicit scan/DFT debug rerun.

This is typical-only OOC implementation for top-review handoff. PVS, PEX,
MMMC, foundry LVS, and direct OA import remain separate later gates.

The block-by-block plan is in `TOP/docs/26_MATRIX_SIDE_SUBBLOCK_PNR_PLAN.md`.

## TX Fixed-Leaf Assembly Plan

After the four TX leaves are validated, freeze their manifest and generate the
true fixed-leaf assembly planning package:

```bash
MANIFEST=/sim/ksabra/SPADMIC_work/assembly/tx_egress_leaf_assembly_inputs_20260709_1515/tx_leaf_manifest.csv
RUN_ID=tx_egress_leaf_assembly_plan_$(date +%Y%m%d_%H%M)
bash TOP/pnr/scripts/run_tx_egress_leaf_assembly_plan.sh "$MANIFEST" "$RUN_ID"
```

This writes:

```text
/sim/ksabra/SPADMIC_work/assembly/<RUN_ID>/README.md
/sim/ksabra/SPADMIC_work/assembly/<RUN_ID>/tx_egress_leaf_assembly_sources.csv
/sim/ksabra/SPADMIC_work/assembly/<RUN_ID>/tx_egress_leaf_assembly_placements.csv
/sim/ksabra/SPADMIC_work/assembly/<RUN_ID>/tx_egress_leaf_assembly_place.tcl
/sim/ksabra/SPADMIC_work/assembly/<RUN_ID>/tx_egress_leaf_assembly_status.rpt
```

The generated plan is a fixed-leaf import/placement review artifact. It does
not replace top assembly, PG hookup, PVS, LVS, PEX, or MMMC. If the local stack
does not fit the prior shallow TX corridor, keep the lower TX leaves soft or
region-guided until the top placement proves there is physical room.

Run the guarded Innovus smoke step before building any connected top route:

```bash
PLAN_ROOT=/sim/ksabra/SPADMIC_work/assembly/tx_egress_leaf_assembly_plan_20260709_1526
SMOKE_RUN_ID=innovus_tx_egress_leaf_assembly_smoke_$(date +%Y%m%d_%H%M)
bash TOP/pnr/scripts/run_innovus_tx_egress_leaf_assembly_smoke.sh "$PLAN_ROOT" "$SMOKE_RUN_ID"
```

The smoke wrapper generates a macro-only Verilog top with no-port black-box leaf
modules, imports the four abstract LEFs, applies the fixed placement Tcl, writes
check-place and instance-summary reports, and stops before route. It proves
macro import, floorplan capacity, and fixed placement mechanics only. A clean
smoke gate requires `CHECK_PLACE_STATUS=PASS`, including zero out-of-core and
zero unplaced macro instances; it intentionally leaves signal connectivity, PG
hookup, PVS, LVS, PEX, and MMMC for later gates.

After the smoke gate is clean, generate the connected fixed-leaf assembly
package:

```bash
PLAN_ROOT=/sim/ksabra/SPADMIC_work/assembly/tx_egress_leaf_assembly_plan_20260709_1526
SMOKE_ROOT=/sim/ksabra/SPADMIC_work/innovus/innovus_tx_egress_leaf_assembly_smoke_parserfix_20260709_1553
CONNECTED_RUN_ID=tx_egress_connected_assembly_$(date +%Y%m%d_%H%M)
bash TOP/pnr/scripts/run_tx_egress_connected_assembly.sh "$PLAN_ROOT" "$SMOKE_ROOT" "$CONNECTED_RUN_ID"
```

This package emits a renamed `spadmic_tx_egress_leaf_assembly` RTL wrapper,
black-box declarations for the four fixed leaves, a Genus-ready filelist, and a
connection/glue manifest. It preserves the small flush-token glue logic from
`spadmic_tx_egress_core`; it does not synthesize, route, hook PG, or claim
signoff.

## Floorplan Intent

- `matrice3` on the left, vertically centered.
- Three MPTDC axis blocks to the right of the matrix and close together.
- OR64 input logic grouped by R/Y/B axis near matrix pin access regions, with
  final START buffers near the MPTDC inputs.
- Reset registers/buffers near Rz/Yz/Bz pin access regions.
- Din/Cin drivers near bottom configuration pins.
- Dout/Cout capture near top/returned-pin regions.
- Distributed position frontend near matrix pins; cluster/packet logic grouped
  further right.
- FIFO/bundle/DDR north or north-east because final DDR outputs are north.
- North SLVS row: 16 data drivers plus one forwarded-clock driver and one valid
  driver.
- CSR/I2C/control/reset supervision near the matrix bottom.
- I2C pad reset `i2c_RST` maps to active-high core `i2c_rst_i` and resets only
  the I2C transport.
- PLL placeholder/clock wrapper bottom-right; PLL analog pad inputs remain
  wrapper-owned while CSR outputs drive the documented PLL selection bits.
- Reserve corridors for `INTERNAL_NEAREST_RIGHT` pins.

## Limitations

- Planning coordinates are relative guides, not final die coordinates.
- No local Innovus execution in Codex.
- No placement, CTS, routing, DRC/LVS, PG, extracted timing, or signoff claim.
- Final netlists, MMMC, MPTDC physical collateral, matrix macro timing, and DDR
  macro timing must be integrated before real closure.
