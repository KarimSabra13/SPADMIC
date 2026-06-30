# REVIEW_MATRIX_TOP_STACK_ALIGNMENT

Status: Builder/Verifier stack-alignment review for the next server execution
loop.

## Scope

Files reviewed/updated:

- `TOP/syn/scripts/run_genus_all_matrix_ooc.sh`
- `TOP/syn/scripts/run_genus_matrix_block.tcl`
- `TOP/pnr/scripts/server_run_innovus_matrix_top_floorplan.sh`
- `TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh`
- `TOP/ci/collect_matrix_top_server_snapshot.sh`
- `TOP/docs/server_snapshots/README.md`
- `TOP/docs/19_MATRIX_TOP_NEXT_STEPS_TO_ASIC.md`
- `TOP/docs/20_MATRIX_TOP_XCELIUM_SERVER_PLAN.md`
- `TOP/docs/21_MATRIX_TOP_GENUS_OOC_PLAN.md`
- `TOP/docs/22_MATRIX_TOP_INNOVUS_FLOORPLAN_PLAN.md`
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`

## Builder Changes

- TOP Genus and Innovus server wrappers now default to the same stack policy as
  the mature MPTDC physical baseline:
  - `MPTDC_XH018_STACK=xx31`
  - `MPTDC_STDCELL_FAMILY=JIHD`
  - route layer list `MET1 MET2 MET3 METTP`
  - ordinary signal top layer `MET3`
  - effective top floor/power/phase layer `METTP`
- `run_genus_matrix_block.tcl` checks the sourced MPTDC library state and fails
  early if the matrix-top Genus run silently drifts away from `xx31/JIHD`.
- Server manifests and summaries now record stack, stdcell family, route layers,
  and top-layer policy.
- Added `TOP/ci/collect_matrix_top_server_snapshot.sh` so the server operator can
  push small evidence snapshots under `TOP/docs/server_snapshots/` without
  committing raw tool work directories.

## Verifier Checks

- Protected MPTDC RTL internals are not modified.
- `TOP/rtl/spadmic_top_v1.sv` is not modified.
- The stack policy matches the current MPTDC physical documentation:
  `xx31 / XH018_1131 / 1P3M_MET3_METMID`, ordinary signal routing through
  `MET3`, and `METTP` reserved for PG/CTS/reviewed exceptions.
- TOP Genus does not silently default to HD when MPTDC is using JIHD.
- Snapshot collection excludes raw `*.log`, simulator work libraries, databases,
  netlists, SPEF/SDF, waves, and tarballs.

## Required Local Checks

| Check | Result |
| --- | --- |
| `git diff --check` | PASS |
| `bash -n TOP/syn/scripts/run_genus_all_matrix_ooc.sh` | PASS |
| `bash -n TOP/pnr/scripts/server_run_innovus_matrix_top_floorplan.sh` | PASS |
| `bash -n TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh` | PASS |
| `bash -n TOP/ci/collect_matrix_top_server_snapshot.sh` | PASS |
| local Genus wrapper smoke without Cadence | EXPECTED FAIL, reports `genus not found` and records `xx31/JIHD` |
| local Innovus floorplan wrapper smoke without Cadence | EXPECTED FAIL, reports `innovus not found`, generates CSV collateral, and records `xx31/JIHD` |
| local Innovus OOC wrapper smoke without Cadence | EXPECTED FAIL, reports `innovus not found` and records `xx31/JIHD` |
| `bash TOP/ci/run_tapeout_readiness.sh` | PASS, 33 pass / 0 fail / 4 expected skips |

## Findings

| Severity | Finding | Status |
| --- | --- | --- |
| NOTE | This patch prepares server flow alignment only. It does not run Cadence locally and does not claim Xcelium/Genus/Innovus pass. | OPEN until server logs are reviewed |
| NOTE | TOP Innovus floorplan seed still does not run `init_design/place/route`; it is a planning seed. | DOCUMENTED |
| NOTE | Local readiness passes under Verilator. Xcelium remains a server gate. | DOCUMENTED |

## Signoff Boundary

This review is not CDC/RDC signoff, Genus timing closure, Innovus routed
closure, DRC/LVS/PEX, MMMC, matrix timing, or DDR timing signoff.
