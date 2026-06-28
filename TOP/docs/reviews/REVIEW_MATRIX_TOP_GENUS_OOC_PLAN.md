# Review Matrix Top Genus OOC Plan

Status: Verifier signed off for Genus OOC server-infrastructure scope.

## Metadata

- Branch: `SPADMIC_test`
- Base commit: `410a7745`
- Phase: 10, Genus OOC server infrastructure
- Date: `2026-06-28`
- Scope: script and documentation preparation only. Genus is not available
  locally and was not run.

## Files Reviewed

- `TOP/syn/scripts/run_genus_matrix_block.tcl`
- `TOP/syn/scripts/run_genus_all_matrix_ooc.sh`
- `TOP/syn/constraints/matrix_top_ooc_common.sdc`
- `TOP/syn/README.md`
- `TOP/docs/21_MATRIX_TOP_GENUS_OOC_PLAN.md`
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`

## Builder Summary

- Added a parameterized Genus Tcl runner for one OOC block.
- Added a server wrapper that iterates matrix-top blocks and writes results
  under `/sim/ksabra/SPADMIC_work/genus/<RUN_ID>/<BLOCK>/`.
- Added common typical-only OOC constraints for `clk_sys`, `clk_cfg_40m`, and
  `clk_ref_40m`.
- The scripts fail if Genus is missing and do not generate success summaries for
  missing Cadence tools.
- The scripts keep MPTDC internals as existing filelist inputs and do not modify
  protected MPTDC RTL.

## Tests Run

| Check | Result |
| --- | --- |
| `bash -n TOP/syn/scripts/run_genus_all_matrix_ooc.sh` | PASS |
| `SPADMIC_WORK_ROOT=/tmp/spadmic_genus_plan_smoke bash TOP/syn/scripts/run_genus_all_matrix_ooc.sh local_no_genus_smoke_v3` | EXPECTED FAIL, exit code 3 because Genus is not available locally |
| Local Genus execution | NOT RUN, Genus is not available locally |

## Findings

| Severity | Finding | Builder Response | Status |
| --- | --- | --- | --- |
| HIGH | Initial Tcl did not make `check_design -all` fatal and could continue to netlist export after check failure. | `run_report` now supports a fatal mode, and `check_design -all` uses it before synthesis/netlist export. | FIXED |
| HIGH | Initial report helper risked writing Tcl return values instead of Genus report stdout. | `run_report` now uses Genus/Tcl output redirection so reports receive actual report bodies. | FIXED |
| MEDIUM | Initial scripts did not classify required warning classes. | Added `reports/messages/warning_classification.rpt` generation for unresolved, latch, unconstrained/no-path, false-path/no-path, blackbox, design-rule, and drive/connectivity patterns. | FIXED |
| NOTE | This infrastructure is typical-only and server-facing. | Documented as non-signoff in README, plan, and review. | OPEN pending server run |

## Remaining Risks

- Tcl command compatibility must be proven on the server Genus version.
- Library path assumptions reuse MPTDC XH018 collateral and must be checked in
  server logs.
- Full top may require intentional blackboxes or MPTDC collateral decisions in a
  later review.

## Verifier Status

Verifier found two HIGH findings and one MEDIUM finding in the initial script.
Builder fixed fatal check gating, report redirection, and warning
classification. Verifier rechecked the fixes and found no remaining BLOCKER,
HIGH, MEDIUM, or LOW findings. Actual Genus command compatibility and report
content still need to be proven on the Cadence server.
