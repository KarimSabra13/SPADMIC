# Review Matrix Top Xcelium Plan

Status: Verifier signed off for server-script preparation scope.

## Metadata

- Branch: `SPADMIC_test`
- Base commit: `36ce9d21`
- Phase: 8, Xcelium server script preparation
- Date: `2026-06-28`
- Scope: server execution infrastructure only. Xcelium is not available locally
  in this Codex environment and was not run.

## Files Reviewed

- `TOP/ci/server_run_matrix_top_xcelium.sh`
- `TOP/docs/20_MATRIX_TOP_XCELIUM_SERVER_PLAN.md`
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`

## Builder Summary

- Added a server-facing Xcelium wrapper that writes all generated run collateral
  under `/sim/ksabra/SPADMIC_work/xcelium/<RUN_ID>` by default.
- The script writes `run_manifest.txt`, `xrun_version.txt`,
  `git_status_short.txt`, `test_summary.txt`, per-test logs/tails, and
  `SUMMARY.md`.
- The script refuses to overwrite an existing run directory and fails clearly
  if `xrun` is missing.
- The required Phase 7 matrix-top tests are included together with maintained
  baseline TOP/ARB/I2C/position tests needed for regression context.

## Tests Run

| Check | Result |
| --- | --- |
| Local Xcelium execution | NOT RUN, `xrun` is not available locally |
| `bash -n TOP/ci/server_run_matrix_top_xcelium.sh` | PASS |
| `SPADMIC_WORK_ROOT=/tmp/spadmic_xcelium_plan_smoke bash TOP/ci/server_run_matrix_top_xcelium.sh local_no_xrun_smoke` | EXPECTED FAIL, exit code 3 because `xrun` is not available locally |

## Findings

| Severity | Finding | Builder Response | Status |
| --- | --- | --- | --- |
| LOW | Initial script summary linked version/log-tail files but did not inline command/version/first-error/tail detail required by the plan. | Added command and Xrun version fields to `SUMMARY.md`, plus inline first-error and tail excerpts for failures. | FIXED |
| NOTE | The script is prepared for the Cadence server only. | Documented server command and non-signoff scope. | OPEN pending server run |

## Remaining Risks

- Xcelium compile/elaboration/runtime portability has not been proven until the
  user runs the script on the server.
- The script depends on the existing filelists and Cadence environment loaded on
  the server.

## Verifier Status

Verifier found one LOW reporting-plan mismatch. Builder fixed the summary
content so the server `SUMMARY.md` includes command/version and failure detail.
Verifier rechecked the fix and found no remaining BLOCKER, HIGH, MEDIUM, or LOW
findings. Phase 8 is approved for commit as server-preparation work only.
