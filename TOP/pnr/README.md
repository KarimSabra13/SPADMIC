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

- full-die envelope: `3800 um x 2700 um`;
- pad/core keepout assumption: `120 um`;
- MPTDC placeholders: three vertical `1.0 mm^2` boxes, `4:3` aspect ratio,
  ordered R/Y/B from top to bottom;
- pad policy template:
  `TOP/pnr/inputs/matrix_top_pad_policy_template.csv`.

Under those defaults the expected result is a controlled feasibility stop:
`MPTDC_VERTICAL_STACK_EXCEEDS_CORE_HEIGHT`. This is useful evidence, not a
tool failure.

## Staged OOC Collateral Gate

After a clean Genus OOC run, validate per-block collateral before adding real
Innovus import/place/preCTS commands:

```bash
OOC_RUN_ID=innovus_matrix_ooc_gate_$(date +%Y%m%d_%H%M)
bash TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh "$OOC_RUN_ID" "$GENUS_RUN_ID"
```

The OOC gate is connectivity-first and excludes DDR16 by default. Set
`SPADMIC_INNOVUS_INCLUDE_DDR16=1` only when the DDR macro boundary is ready for
physical work.

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
- CSR/I2C/control/reset supervision near the matrix bottom.
- PLL placeholder bottom-right.
- Reserve corridors for `INTERNAL_NEAREST_RIGHT` pins.

## Limitations

- Planning coordinates are relative guides, not final die coordinates.
- No local Innovus execution in Codex.
- No placement, CTS, routing, DRC/LVS, PG, extracted timing, or signoff claim.
- Final netlists, MMMC, MPTDC physical collateral, matrix macro timing, and DDR
  macro timing must be integrated before real closure.
