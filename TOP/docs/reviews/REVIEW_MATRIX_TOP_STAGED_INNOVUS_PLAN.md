# Review: Matrix TOP Staged Innovus Plan

## Metadata

- Branch: `SPADMIC_test`
- Reviewed phase: staged Innovus planning infrastructure
- Reviewed files:
  - `TOP/pnr/inputs/matrix_top_pad_policy_template.csv`
  - `TOP/pnr/scripts/gen_matrix_top_floorplan_plan.py`
  - `TOP/pnr/scripts/server_run_innovus_matrix_top_staged_floorplan.sh`
  - `TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh`
  - `TOP/pnr/templates/matrix_top_staged_floorplan.tcl`
  - `TOP/ci/collect_matrix_top_server_snapshot.sh`
  - `TOP/docs/23_MATRIX_TOP_STAGED_INNOVUS_EXECUTION_PLAN.md`
- Signoff status: non-signoff planning infrastructure only

## Builder Summary

Builder added a staged Innovus flow that separates:

- matrix-top geometry planning;
- pad-policy handoff;
- MPTDC placeholder feasibility;
- per-block OOC collateral checking;
- future import/place/preCTS promotion.

No RTL was modified. No protected MPTDC internals were modified.

## Verifier Checks

| Check | Result |
| --- | --- |
| Uses normalized matrix `ll_*` CSV input | PASS |
| Keeps `matrice3` left and vertically centered | PASS |
| Models first die as `3800 um x 2700 um` full die | PASS |
| Models default pad/core keepout as `120 um` | PASS |
| Uses R/Y/B MPTDC placeholder order R top, Y middle, B bottom | PASS |
| Uses three 4:3 MPTDC placeholders, default `1.0 mm^2` each | PASS |
| Stops instead of silently switching to 2+1 MPTDC fallback | PASS |
| Treats `VTUNE` as analog/macro-owned | PASS |
| Defers DDR16 early OOC | PASS |
| Avoids copying MPTDC RO/PD Innovus internals into TOP | PASS |
| No placement/route/CTS/signoff claim | PASS |

## Local Tests

Commands to run locally before commit:

```text
python3 -m py_compile TOP/pnr/scripts/gen_matrix_top_floorplan_plan.py TOP/pnr/scripts/gen_matrix_floorplan_from_csv.py
bash -n TOP/pnr/scripts/server_run_innovus_matrix_top_staged_floorplan.sh
bash -n TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh
bash -n TOP/ci/collect_matrix_top_server_snapshot.sh
python3 TOP/pnr/scripts/gen_matrix_top_floorplan_plan.py --out /tmp/spadmic_matrix_top_fp_smoke --run-id local_smoke
SPADMIC_WORK_ROOT=/tmp/spadmic_stage_wrapper_smoke TOP/pnr/scripts/server_run_innovus_matrix_top_staged_floorplan.sh local_stage_smoke
SPADMIC_WORK_ROOT=/tmp/spadmic_ooc_gate_smoke TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh local_ooc_smoke missing_genus_run
```

The expected top-floorplan smoke result is `STATUS=FAIL` with
`MPTDC_VERTICAL_STACK_EXCEEDS_CORE_HEIGHT` and wrapper exit code `5`. This is
the correct conservative result under the locked first die envelope. The OOC
missing-Genus smoke should exit `6`. A fake-collateral OOC ready-path smoke was
also run under `/tmp` and exited `4`, which means collateral is ready for the
next reviewed import template, not that placement ran.

## Findings

| ID | Severity | Finding | Impact | Required Fix / Response | Status |
| --- | --- | --- | --- | --- | --- |
| STAGED-INNOVUS-001 | NOTE | The new planner reports the locked first geometry as infeasible by height. | Confirms the tool catches the MPTDC placeholder/die-height conflict. | Keep as an explicit planning gate. | VERIFIED |
| STAGED-INNOVUS-002 | MEDIUM | The OOC wrapper validates collateral but does not yet run Innovus import/place/preCTS. | This is intentional to avoid blind copying of MPTDC-specific RO/PD flow, but it means OOC physical evidence is still pending. | Add the reviewed TOP OOC import template after clean Genus and geometry gates. | OPEN |
| STAGED-INNOVUS-003 | MEDIUM | Pad-ring data is still represented by side/order/group policy, not LEF/DEF coordinates. | I/O feasibility is side-level only. | Replace or augment the CSV when pad-ring layout data is available. | OPEN |
| STAGED-INNOVUS-004 | LOW | Default pad keepout is an assumption. | The `109 um` MPTDC stack shortfall can change with real pad/core keepout. | Keep `SPADMIC_MATRIX_TOP_PAD_KEEPOUT_UM` parameterized and report it in every run. | VERIFIED |

## Verifier Status

Accepted for staged planning infrastructure. Not accepted as Innovus placement,
routing, CTS, DRC/LVS, PG, PEX, MMMC, or final top physical feasibility.
