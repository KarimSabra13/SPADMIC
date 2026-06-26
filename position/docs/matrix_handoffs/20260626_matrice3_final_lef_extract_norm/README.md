# Matrice3 Final Matrix Extraction

## Source

- Original read-only matrix OA:
  `/group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL/matrice3/layout/layout.oa`
- Safe editable copy used for Abstract Generator:
  `/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/matrice3/layout/layout.oa`
- Final LEF used for extraction:
  `/group/validmgr/PROJET/Prj_xh018/ksabra/lef/matrice3.lef`
- LEF export log:
  `/group/validmgr/PROJET/Prj_xh018/ksabra/lef/logs/lefout_matrice3.log`
- Extraction run:
  `20260626_matrice3_final_lef_extract_norm`

## Key Extracted Facts

From the final LEF:

- Macro name: `matrice3`
- Macro size: `1999.91 um x 1725.54 um`
- LEF origin: `51.395 um, 65.86 um`
- Symmetry: `X Y R90`
- Pin count: `565`
- Pin shape count: `567`
- OBS shape count: `1916`
- Pin layers observed: `MET2`, `MET3`

## Coordinate Convention

The original LEF contains non-zero origin. Therefore two coordinate systems are kept:

- `bbox_*` and `center_*`: raw LEF pin coordinates.
- `ll_bbox_*` and `ll_center_*`: lower-left-normalized macro coordinates, where macro lower-left is `0,0`.

For position PnR planning, prefer the `ll_*` coordinates.

## Main Artifacts

- `matrice3_pin_coordinates.csv`: one row per pin with raw and normalized coordinates.
- `lef_extracts/*/matrix_pin_summary.csv`: full parser pin summary.
- `lef_extracts/*/matrix_pin_shapes.csv`: one row per pin shape.
- `lef_extracts/*/matrix_macro_summary.json`: full machine-readable macro payload.
- `lef_extracts/*/matrix_pin_map.svg`: visual pin map.
- `lef_extracts/*/position_pnr_seed.tcl`: Tcl seed for future Innovus position floorplan.
- `FINAL_MATRIX_EXTRACTION_SUMMARY.md`: top-level extraction summary.
- `logs/final_layout_extract.log`: reproducibility log.
