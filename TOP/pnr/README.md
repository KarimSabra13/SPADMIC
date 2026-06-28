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

