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

The block-by-block plan is in `TOP/docs/26_MATRIX_SIDE_SUBBLOCK_PNR_PLAN.md`.

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
