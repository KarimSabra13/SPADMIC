# Review Matrix Top Innovus Floorplan Plan

Status: Verifier signed off for Innovus/floorplan planning infrastructure scope.

## Metadata

- Branch: `SPADMIC_test`
- Base commit: `be992f06`
- Phase: 11, Innovus floorplan planning infrastructure
- Date: `2026-06-28`
- Scope: CSV-driven floorplan collateral and server wrapper preparation only.
  Innovus is not available locally and was not run.

## Files Reviewed

- `TOP/pnr/scripts/gen_matrix_floorplan_from_csv.py`
- `TOP/pnr/scripts/server_run_innovus_matrix_top_floorplan.sh`
- `TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh`
- `TOP/pnr/templates/matrix_top_floorplan_seed.tcl`
- `TOP/pnr/README.md`
- `TOP/pnr/.gitignore`
- `TOP/docs/22_MATRIX_TOP_INNOVUS_FLOORPLAN_PLAN.md`
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`

## Builder Summary

- Added a Python generator that requires and uses `ll_*` normalized coordinates.
- Added pin-family, side, unknown-pin, internal-right corridor, and planning
  region outputs.
- Added a server floorplan wrapper that generates collateral under
  `/sim/ksabra/SPADMIC_work/innovus/<RUN_ID>/generated/`.
- Added an Innovus planning seed that sources generated regions and records
  floorplan-region reports when Innovus is available.
- Added an OOC placeholder wrapper that refuses to fabricate a pass without
  block netlist/MMMC handoff.

## Tests Run

| Check | Result |
| --- | --- |
| `python3 TOP/pnr/scripts/gen_matrix_floorplan_from_csv.py --out /tmp/spadmic_pnr_plan_smoke/generated_v2 --run-id local_generator_smoke_v2` | PASS |
| `bash -n TOP/pnr/scripts/server_run_innovus_matrix_top_floorplan.sh` | PASS |
| `bash -n TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh` | PASS |
| `SPADMIC_WORK_ROOT=/tmp/spadmic_innovus_plan_smoke bash TOP/pnr/scripts/server_run_innovus_matrix_top_floorplan.sh local_no_innovus_smoke_v2` | EXPECTED FAIL, exit code 3 because Innovus is not available locally; CSV collateral generated |
| `SPADMIC_WORK_ROOT=/tmp/spadmic_innovus_plan_smoke_fix bash TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh local_no_innovus_ooc_smoke_v3` | EXPECTED FAIL, exit code 3 because Innovus is not available locally; output root uses `/innovus/<RUN_ID>` |
| Local Innovus execution | NOT RUN, Innovus is not available locally |

## Findings

| Severity | Finding | Builder Response | Status |
| --- | --- | --- | --- |
| LOW | Initial OOC wrapper used `/innovus_ooc/<RUN_ID>` instead of the requested `/innovus/<RUN_ID>` output convention. | Updated `server_run_innovus_matrix_ooc.sh` to use `$SPADMIC_WORK_ROOT/innovus/<RUN_ID>`. | FIXED |
| NOTE | Infrastructure is planning-only and server-facing. | Documented as non-signoff and generated-output-only. | OPEN pending server run |

## Remaining Risks

- Innovus command compatibility must be proven on the server.
- Generated regions are relative planning guides, not final die coordinates.
- Full placement/routing requires netlist/MMMC/macro collateral not produced by
  this local Codex session.

## Verifier Status

Verifier found one LOW path-convention issue in the initial OOC wrapper.
Builder fixed the OOC run root to match the requested `/innovus/<RUN_ID>`
convention. Verifier rechecked the fix and found no remaining BLOCKER, HIGH,
MEDIUM, or LOW findings. Innovus execution and physical closure remain server
gates, not local signoff.
