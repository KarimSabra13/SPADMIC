# Review: Matrix TOP Innovus Floorplan Seed innovus_matrix_top_fp_20260630_1107

## Metadata

- Branch: `SPADMIC_test`
- Snapshot commit reviewed locally: `d6f30ddb`
- Server run ID: `innovus_matrix_top_fp_20260630_1107`
- Server run commit: `90004bef8ac5ed889fc0169ee460511b30f7b076`
- Evidence snapshot: `TOP/docs/server_snapshots/innovus/innovus_matrix_top_fp_20260630_1107/`
- Review status: PASS for planning-seed execution only.
- Signoff status: non-signoff; no placement, route, CTS, DRC, LVS, PG, or timing closure.

## Result Reviewed

Innovus launched successfully with the matrix-top floorplan seed and exited with
code 0. The seed loaded:

- matrix LEF: `/group/validmgr/PROJET/Prj_xh018/ksabra/lef/matrice3.lef`
- matrix pin CSV:
  `position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv`
- XH018 stack: `xx31`
- standard-cell family: `JIHD`
- route layers: `MET1 MET2 MET3 METTP`

The run generated region planning collateral but intentionally did not run
`init_design`, placement, routing, CTS, DRC, LVS, extraction, or signoff.

## Matrix Pin Evidence

The CSV parser used lower-left-normalized `ll_*` coordinates.

- Pin rows: 565
- Pin shapes reported by CSV: 567
- Matrix size used for planning: `1999.910 um x 1725.540 um`
- Pin normalized bbox: `1.790 0.005 1991.780 1725.535`
- `INTERNAL_NEAREST_RIGHT` pins: 184
- `INTERNAL_NEAREST_RIGHT` bbox: `1991.471 89.935 1991.780 1665.775`

Family distribution:

| Family | Pins | Sides |
| --- | ---: | --- |
| `R` | 64 | `INTERNAL_NEAREST_RIGHT,TOP` |
| `Rz` | 64 | `INTERNAL_NEAREST_RIGHT,TOP` |
| `Y` | 64 | `INTERNAL_NEAREST_RIGHT` |
| `Yz` | 64 | `INTERNAL_NEAREST_RIGHT` |
| `B` | 64 | `BOTTOM,INTERNAL_NEAREST_RIGHT` |
| `Bz` | 64 | `BOTTOM,INTERNAL_NEAREST_RIGHT` |
| `Din` | 44 | `BOTTOM` |
| `Cin` | 44 | `BOTTOM` |
| `Dout` | 44 | `TOP` |
| `Cout` | 44 | `TOP` |
| `SUPPLY` | 4 | `LEFT,TOP` |
| `UNKNOWN` | 1 | `LEFT` |

## Region Evidence

The seed printed planning regions for:

- matrix halo
- internal-nearest-right routing corridor
- MPTDC cluster to the right of the matrix
- OR64 input banks
- reset driver banks
- distributed position frontend
- position cluster/main logic
- FIFO/bundle/DDR north/north-east
- control/reset/supervision bottom
- PLL placeholder bottom-right

This matches the agreed floorplan direction: `matrice3` left/centered, MPTDCs
right and close together, DDR/TX north/north-east, and control/reset below.

## Verifier Findings

| ID | Severity | Finding | Impact | Builder Response | Status |
| --- | --- | --- | --- | --- | --- |
| INNOVUS-FP-001 | NOTE | Innovus seed execution passed with 0 warnings and 0 errors. | Confirms command compatibility for the seed wrapper and generated region Tcl. | No fix required. | VERIFIED |
| INNOVUS-FP-002 | NOTE | The run used normalized `ll_*` matrix CSV coordinates and captured internal-right corridor planning data. | Confirms the planning flow did not use naive raw LEF coordinates. | No fix required. | VERIFIED |
| INNOVUS-FP-003 | MEDIUM | One pin remains classified as `UNKNOWN` on the left side. | Requires later alias/ownership review before final floorplan constraints and pad-level integration. | Keep open in floorplan checklist. | OPEN |
| INNOVUS-FP-004 | MEDIUM | The seed did not run `init_design`, placement, route, CTS, PG, DRC, LVS, extraction, or timing. | Cannot claim physical feasibility beyond planning Tcl compatibility and matrix pin-region extraction. | Keep documentation explicit. Next Innovus step should use Genus handoff collateral and run a real design import/floorplan feasibility pass. | OPEN |

## Remaining Limitations

- No real cell placement yet.
- No power-grid plan or PG verification yet.
- No routing/congestion result yet.
- No CTS result yet.
- No DRC/LVS/PEX.
- No final die-size/pad-ring contract.
- No final DDR macro placement contract.
- No final MPTDC macro/netlist placement contract in the TOP floorplan.

## Verifier Status

The Innovus run is accepted as a successful floorplan planning-seed execution.
The next physical step must move from seed validation to a real design-import
and floorplan-feasibility run using the current Genus handoff collateral.
