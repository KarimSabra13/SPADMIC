# SPADMIC Matrix TOP Innovus Floorplan Plan

Status: server-side product-like floorplan feasibility plan. No Innovus run has been performed locally.

## Metadata

- Branch: `SPADMIC_test`
- Baseline commit for this plan: `5cdf489fbfb0a13e1a5ee7f5a253002e023602ac`
- Server repo path: `/home/validmgr/ksabra/2026_SPAD/SPADMIC`
- Cadence environment: `source /eda/cadence/eda_2023-2024`
- Work root: `/sim/ksabra/SPADMIC_work`
- Innovus output root: `/sim/ksabra/SPADMIC_work/innovus/<RUN_ID>/`
- Matrix LEF on server: `/group/validmgr/PROJET/Prj_xh018/ksabra/lef/matrice3.lef`
- Matrix pin CSV in repo: `position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv`

## Floorplan Intent

- Place `matrice3` on the left side of the chip, roughly centered vertically.
- Place three MPTDC axis blocks to the right of `matrice3`, close together.
- Place OR64 input logic per axis near the corresponding matrix pin access regions and final START buffers near MPTDC START inputs.
- Place reset output registers/buffers close to Rz/Yz/Bz pin banks.
- Place Din/Cin drivers near bottom matrix config pins.
- Place Dout/Cout capture/sampler logic near top matrix config pins.
- Place distributed position frontend registers/AOR/preprocessing near matrix pins, then route to a main cluster/packet block to the right.
- Place arbiter/output FIFO/bundle/TX north or north-east because final DDR outputs are on the north side.
- Place CSR/I2C/control/reset/supervision toward the bottom of the matrix.
- Reserve bottom-right PLL placeholder.

## CSV Requirements

The generator must read:

```text
position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv
```

and use normalized columns:

- `ll_center_x`
- `ll_center_y`
- `ll_bbox_*`

It must not use raw LEF coordinates without accounting for the non-zero LEF origin.

## Pin Classification

The script must classify:

- `R`
- `Rz`
- `Y`
- `Yz`
- `B`
- `Bz`
- `Din`
- `Cin`
- `Dout`
- `Cout`
- supply/analog/unknown pins

It must also report side/region distribution and identify `INTERNAL_NEAREST_RIGHT` pins. Prior extraction shows several R/B/Rz/Bz pins and all Y/Yz pins in the internal-right access class, so corridors must be planned rather than assuming all pins are on outer edges.

## Generated Planning Artifacts

The planned Python generator should create:

```text
TOP/pnr/generated/<RUN_ID>/
  matrix_pin_family_summary.csv
  matrix_pin_side_summary.csv
  matrix_floorplan_regions.tcl
  floorplan_summary.md
```

`TOP/pnr/generated/` should be ignored or treated as generated output, not source hand-authored collateral.

## Innovus OOC And Top Runs

OOC feasibility order:

1. OR64 three-axis wrapper.
2. Matrix reset controller.
3. Matrix configuration controller and Cout sampler.
4. Output FIFO/bundle path.
5. Position path.
6. Control/CSR.
7. Product-like matrix-top floorplan.

## Required Reports

- macro placement report;
- pin/corridor report;
- obstruction/halo note;
- congestion report;
- timing pre-route/post-route if route is attempted;
- clock report;
- CTS report if CTS is attempted;
- route summary;
- DRC summary if available;
- power/PG notes;
- `SUMMARY.md`.

## Server Command

The wrapper script `TOP/pnr/scripts/server_run_innovus_matrix_top_floorplan.sh`
is now present. After review, the intended server command is:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test
source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
bash TOP/pnr/scripts/server_run_innovus_matrix_top_floorplan.sh "$RUN_ID"
```

The script first generates CSV-derived planning collateral from normalized
`ll_*` coordinates, then runs an Innovus planning seed if Innovus is available.
It fails clearly if Innovus is missing and does not claim placement/routing
signoff.

## Negative Claims

An Innovus floorplan feasibility run is not:

- final routed signoff;
- DRC/LVS/PEX;
- final PG signoff;
- final MPTDC physical signoff;
- final DDR timing;
- final matrix macro timing;
- final top-chip tapeout readiness.
