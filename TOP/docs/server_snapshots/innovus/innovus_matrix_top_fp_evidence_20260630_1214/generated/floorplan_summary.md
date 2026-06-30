# matrice3 Floorplan Planning Summary

- Run ID: `innovus_matrix_top_fp_evidence_20260630_1214`
- Input CSV: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv`
- Coordinate basis: `ll_*` lower-left-normalized extraction columns
- Pin rows: 565
- Pin shapes reported by CSV: 567
- Matrix macro size used for planning: `1999.910 um x 1725.540 um`
- Pin normalized bbox: `1.790 0.005 1991.780 1725.535`
- Pin normalized span: `1989.990 um x 1725.530 um`
- INTERNAL_NEAREST_RIGHT pins: 184
- INTERNAL_NEAREST_RIGHT bbox: `1991.471 89.935 1991.780 1665.775`

## Family Counts

| Family | Pins | Sides |
| --- | ---: | --- |
| `B` | 64 | `BOTTOM,INTERNAL_NEAREST_RIGHT` |
| `Bz` | 64 | `BOTTOM,INTERNAL_NEAREST_RIGHT` |
| `Cin` | 44 | `BOTTOM` |
| `Cout` | 44 | `TOP` |
| `Din` | 44 | `BOTTOM` |
| `Dout` | 44 | `TOP` |
| `R` | 64 | `INTERNAL_NEAREST_RIGHT,TOP` |
| `Rz` | 64 | `INTERNAL_NEAREST_RIGHT,TOP` |
| `SUPPLY` | 4 | `LEFT,TOP` |
| `UNKNOWN` | 1 | `LEFT` |
| `Y` | 64 | `INTERNAL_NEAREST_RIGHT` |
| `Yz` | 64 | `INTERNAL_NEAREST_RIGHT` |

## Required Planning Notes

- Place `matrice3` on the left side of the chip, vertically centered.
- Place three MPTDC axes to the right of the matrix and close together.
- Reserve the `internal_nearest_right_corridor` when present.
- Place FIFO/bundle/DDR north or north-east because final DDR pins are north.
- Place control/reset/supervision logic below the matrix.
- Treat all regions as planning guides, not signoff coordinates.
