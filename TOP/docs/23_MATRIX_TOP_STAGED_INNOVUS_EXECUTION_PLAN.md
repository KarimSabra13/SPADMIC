# Matrix TOP Staged Innovus Execution Plan

Status: implementation plan and server-run contract for the next physical phase.
This is not placement, route, CTS, DRC/LVS, PEX, MMMC, or final signoff.

## Locked Inputs

- Branch: `SPADMIC_test`
- Current implementation target: `TOP/rtl/spadmic_top_matrix_v1.sv`
- Technology stack: XFAB XH018 `xx31`
- Standard-cell family: `JIHD`
- Route layers: `MET1 MET2 MET3 METTP`
- Ordinary signal top layer: `MET3`
- Effective PG/exception layer: `METTP`
- Current full-die envelope: `4293.179 um x 3209.173 um`
- Pad-ring/core physical planning depth: about `164 um`
- BOX_RING/OA source: `/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/SPADMIC`
- Matrix macro: `matrice3`, `1999.91 um x 1725.54 um`
- Matrix placement: left side, vertically centered
- MPTDC placeholders: three vertical boxes, R top, Y middle, B bottom
- MPTDC Scenario A: optimistic core box `1020.88 um x 761.60 um`
- MPTDC Scenario B: required full boundary `1061.20 um x 801.92 um`, `5%`
  dimensional margin, `20 um` halo, `20 um` inter-axis gap
- Clock pads: one external 160 MHz clock only; 40 MHz clocks are internal
  PLL/divider outputs
- DDR16: deferred from early OOC; keep only as a future north-side boundary

## Flow Order

1. Run one clean Genus OOC evidence refresh with the latest scripts.
2. Generate a staged top floorplan plan from the matrix `ll_*` CSV and pad-policy CSV.
3. Stop before Innovus if the geometry is infeasible.
4. Run per-block OOC collateral gates in connectivity-first order.
5. Add a reviewed TOP Innovus import/place/preCTS template only after Genus collateral and top geometry are coherent.

The initial OOC order is:

1. `or64_tree`
2. `matrix_reset_ctrl`
3. `matrix_cfg_ctrl`
4. `position_snapshot`
5. `output_fifo`
6. `event_bundle_tx`
7. `event_coordinator`
8. `matrix_top_csr`
9. `i2c_csr_bridge`
10. `i2c_slave`

`ddr16_pairer` is intentionally excluded unless
`SPADMIC_INNOVUS_INCLUDE_DDR16=1`. Genus OOC also excludes `ddr16_pairer` and
full `spadmic_top_matrix_v1` unless `SPADMIC_GENUS_INCLUDE_DDR16=1` or
`SPADMIC_GENUS_INCLUDE_FULL_TOP=1` is explicitly set.

## New Inputs And Outputs

Pad policy template:

```text
TOP/pnr/inputs/matrix_top_pad_policy_template.csv
```

The template uses side/order/group fields because there is no finalized pad-ring
LEF/DEF yet. Required columns:

```text
side,order,signal_or_group,direction,voltage_domain,notes
```

Top floorplan generator:

```text
TOP/pnr/scripts/gen_matrix_top_floorplan_plan.py
```

Generated outputs under `/sim/ksabra/SPADMIC_work/innovus/<RUN_ID>/generated/`:

```text
top_floorplan_summary.md
feasibility_status.txt
top_floorplan_regions.tcl
matrix_top_region_summary.csv
mptdc_placeholder_summary.csv
mptdc_scenario_summary.csv
pad_policy_summary.csv
matrix_pin_family_summary.csv
matrix_pin_side_summary.csv
matrix_unknown_pins.csv
```

Server wrapper:

```text
TOP/pnr/scripts/server_run_innovus_matrix_top_staged_floorplan.sh
```

This wrapper generates planning collateral and stops before Innovus when
`feasibility_status.txt` is not `STATUS=PASS`.

## Current Expected Geometry Result

The active geometry gate is Scenario B, not the older abstract `1.0 mm^2`,
`4:3` placeholder. Scenario B reserves the full MPTDC DEF/block boundary with
margin and halo:

- die: `4293.179 um x 3209.173 um`
- pad-ring/core planning depth: `164 um`
- MPTDC boundary: `1061.20 um x 801.92 um`
- dimensional margin: `5%`
- halo: `20 um` around each MPTDC
- effective per-axis planning envelope: about `1154 um x 882 um`
- MPTDC vertical order: R, Y, B
- inter-axis gap: `20 um`

Local generator probing shows this Scenario B geometry is expected to pass the
planning gate in the real envelope. If it fails on the server, treat that as a
geometry issue to review, not as permission to silently switch to 2+1 MPTDC
placement or increase die height.

## Historical Geometry Failure

Server run `innovus_matrix_top_staged_fp_20260630_1628` confirmed the expected
default failure:

- return code: `5`
- status: `FAIL`
- issue: `MPTDC_VERTICAL_STACK_EXCEEDS_CORE_HEIGHT`
- height excess: `109.038 um`
- max per-axis MPTDC placeholder area at the default 4:3 aspect: `0.839170 mm^2`

That old failure remains useful historical evidence only. It is superseded by
the current full-boundary Scenario B using the larger custom TOP die and the
layout-derived pad-ring depth.

## Server Commands

Clean Genus gate:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test

EXPECTED_HEAD=<pushed_head_from_codex>
test "$(git rev-parse HEAD)" = "$EXPECTED_HEAD" || {
  echo "HEAD mismatch"
  git rev-parse HEAD
  exit 2
}

source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_XH018_STACK=xx31
export MPTDC_STDCELL_FAMILY=JIHD
export MPTDC_PNR_ROUTE_LAYER_NAMES="MET1 MET2 MET3 METTP"
export SPADMIC_GENUS_INCLUDE_DDR16=0
export SPADMIC_GENUS_INCLUDE_FULL_TOP=0

GENUS_RUN_ID=genus_matrix_ooc_clean2_$(date +%Y%m%d_%H%M)
bash TOP/syn/scripts/run_genus_all_matrix_ooc.sh "$GENUS_RUN_ID"
GENUS_RC=$?
TOP/ci/collect_matrix_top_server_snapshot.sh genus "$GENUS_RUN_ID"
```

Staged top floorplan:

```bash
RUN_ID=innovus_matrix_top_staged_fp_$(date +%Y%m%d_%H%M)
bash TOP/pnr/scripts/server_run_innovus_matrix_top_staged_floorplan.sh "$RUN_ID"
INNOVUS_FP_RC=$?
TOP/ci/collect_matrix_top_server_snapshot.sh innovus "$RUN_ID"
```

Connectivity-first OOC collateral gate:

```bash
OOC_RUN_ID=innovus_matrix_ooc_gate_$(date +%Y%m%d_%H%M)
bash TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh "$OOC_RUN_ID" "$GENUS_RUN_ID"
INNOVUS_OOC_RC=$?
TOP/ci/collect_matrix_top_server_snapshot.sh innovus "$OOC_RUN_ID"
```

Expected early return codes:

- staged floorplan returns `5` if Scenario B geometry is infeasible;
- OOC gate returns `4` when all required Genus collateral exists and the next
  reviewed import template is needed;
- neither return code is a placement/signoff pass.

## Promotion Gates

Do not proceed to real top `init_design/place/preCTS` until:

- clean Genus evidence has no tool-option errors;
- top floorplan geometry is `STATUS=PASS` or the feasibility failure is waived
  in the decision log;
- MPTDC placeholder dimensions are consistent with the latest MPTDC physical
  handoff or explicitly marked provisional;
- pad policy CSV has at least side/order/group ownership for north/south pins;
- matrix analog pins, especially `VTUNE`, remain analog-owned;
- no protected MPTDC internals are modified.
