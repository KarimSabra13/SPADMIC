# Review: Matrix TOP Innovus Floorplan Evidence Run innovus_matrix_top_fp_evidence_20260630_1214

## Metadata

- Branch: `SPADMIC_test`
- Snapshot commit reviewed locally: `3603455e`
- Server run ID: `innovus_matrix_top_fp_evidence_20260630_1214`
- Server run commit: `49cf7f35ed83dcf707d330aac8db06f98086d3b6`
- Evidence snapshot: `TOP/docs/server_snapshots/innovus/innovus_matrix_top_fp_evidence_20260630_1214/`
- Review status: PASS for floorplan seed execution.
- Signoff status: non-signoff planning seed only.

## Result

Innovus ran the matrix-top floorplan seed and exited with `INNOVUS_RC=0`.

The run used:

- matrix LEF: `/group/validmgr/PROJET/Prj_xh018/ksabra/lef/matrice3.lef`
- matrix CSV:
  `position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv`
- XH018 stack: `xx31`
- standard-cell family: `JIHD`
- route layers: `MET1 MET2 MET3 METTP`
- ordinary signal top layer: `MET3`
- effective top floor layer: `METTP`

This run did not perform design import, placement, routing, CTS, PG, extraction,
DRC, LVS, or timing closure.

## Matrix Pin Evidence

The generator used normalized `ll_*` CSV coordinates.

- Pin rows: 565
- Pin shapes: 567
- Matrix macro size: `1999.910 um x 1725.540 um`
- Pin normalized bbox: `1.790 0.005 1991.780 1725.535`
- `INTERNAL_NEAREST_RIGHT` pins: 184
- `INTERNAL_NEAREST_RIGHT` bbox: `1991.471 89.935 1991.780 1665.775`

Pin-family distribution remains:

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
| `Y` | 64 | `INTERNAL_NEAREST_RIGHT` |
| `Yz` | 64 | `INTERNAL_NEAREST_RIGHT` |
| `SUPPLY` | 4 | `LEFT,TOP` |
| `UNKNOWN` | 1 | `LEFT` |

The only unknown pin is:

| Pin | Direction | Use | Side | ll_center_x | ll_center_y |
| --- | --- | --- | --- | ---: | ---: |
| `VTUNE` | `INOUT` | `ANALOG` | `LEFT` | 1.93 | 61.725 |

## Verifier Findings

| ID | Severity | Finding | Impact | Builder Response | Status |
| --- | --- | --- | --- | --- | --- |
| INNOVUS-EVID-001 | NOTE | Floorplan seed command compatibility is proven at current branch state. | Confirms the wrapper and generated region Tcl execute on the server. | No fix required. | VERIFIED |
| INNOVUS-EVID-002 | NOTE | CSV parsing uses `ll_*` coordinates and captures the internal-right corridor. | Confirms floorplan planning did not use raw LEF-origin coordinates. | No fix required. | VERIFIED |
| INNOVUS-EVID-003 | LOW | `VTUNE` is classified as `UNKNOWN` by the digital grouping logic, but the CSV marks it as `INOUT/ANALOG/LEFT`. | Not a digital R/Y/B/config/reset pin issue, but it needs analog ownership and keepout treatment in the top floorplan. | Document `VTUNE` as analog-owned and keep it out of digital pin-family counts. | OPEN |
| INNOVUS-EVID-004 | MEDIUM | This is still only a seed; no design import, placement, route, CTS, PG, DRC/LVS, extraction, or timing happened. | Cannot claim product-like physical feasibility yet. | Next phase must be a real top floorplan/import feasibility run using Genus collateral or explicit block blackboxes. | OPEN |

## Next Physical Step

Move from seed validation to a real top floorplan feasibility run:

- import `matrice3.lef`;
- import the matrix-top synthesized netlist or controlled blackboxes;
- place `matrice3` left/centered;
- reserve internal-right corridors;
- instantiate planning regions for MPTDC, OR64, reset drivers, matrix config,
  position frontend/main, FIFO/bundle/DDR, CSR/I2C/control, and PLL placeholder;
- run at least design import, floorplan creation, early placement feasibility,
  congestion, and basic report collection.

## Verifier Status

Accepted as floorplan-seed execution evidence only. Not accepted as placement,
routing, CTS, PG, DRC/LVS, extraction, timing closure, or signoff.
