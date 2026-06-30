# SPADMIC Matrix TOP Staged Floorplan Plan

- Run ID: `innovus_matrix_top_staged_fp_20260630_1628`
- Input matrix CSV: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv`
- Pad policy CSV: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/pnr/inputs/matrix_top_pad_policy_template.csv`
- Coordinate basis: absolute planning coordinates in um; matrix pins use normalized `ll_*` source columns
- Status: `FAIL`
- Issues: `MPTDC_VERTICAL_STACK_EXCEEDS_CORE_HEIGHT`
- Die: `3800.000 um x 2700.000 um` (10.260 mm^2)
- Pad/core keepout assumption: `120.000 um`
- Core planning box: `120.000 120.000 3680.000 2580.000`
- Matrix placement: `120.000 487.230 2119.910 2212.770`
- Matrix area: `3.450925 mm^2`
- MPTDC placeholder area per axis: `1.000000 mm^2`
- MPTDC placeholder aspect ratio: `1.333333`
- MPTDC placeholder width/height: `1154.701 um x 866.025 um`
- MPTDC vertical stack height including gaps: `2678.076 um`
- MPTDC width excess beyond core: `0.000 um`
- MPTDC height excess beyond core: `109.038 um`
- Maximum MPTDC placeholder area per axis that fits current vertical stack: `0.839170 mm^2`
- Horizontal extension allowed: `5.000%`, width after extension `3990.000 um`
- Horizontal extension can fix width issue: `True`

## Axis Placeholder Order

| Axis | Placement intent | Pin centroid y from CSV |
| --- | --- | ---: |
| `R` | `2219.910 1823.013 3374.611 2689.038` | 1635.515 |
| `Y` | `2219.910 916.987 3374.611 1783.013` | 878.135 |
| `B` | `2219.910 10.962 3374.611 876.987` | 102.216 |

## Pin Evidence

- Matrix pin rows: `565`
- Pin normalized bbox: `1.790 0.005 1991.780 1725.535`
- INTERNAL_NEAREST_RIGHT pins: `184`
- INTERNAL_NEAREST_RIGHT normalized bbox: `1991.471 89.935 1991.780 1665.775`
- Unknown/analog rows are reported in `matrix_unknown_pins.csv`.

## Pad Policy

- Policy rows: `14`
- Current policy is side/order/group only because pad-ring LEF/DEF is not final.
- DDR16 entries are north-side placeholders and intentionally low priority.
- `VTUNE` and matrix supplies are analog/macro-owned and not digital route claims.

## Promotion Rule

- If `Status` is `FAIL`, the server Innovus wrapper must stop after generating reports.
- Do not silently switch to a 2+1 MPTDC arrangement.
- Do not claim placement, route, CTS, DRC/LVS, PG, PEX, MMMC, or final signoff from this plan.
