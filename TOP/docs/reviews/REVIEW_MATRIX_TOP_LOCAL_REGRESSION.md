# Review Matrix Top Local Regression

Status: Verifier signed off for the local Verilator/open-source Phase 7 scope.

## Metadata

- Branch: `SPADMIC_test`
- Base commit: `5b8d659e184d77d15d45da9d537f0958f4b55dd1`
- Phase: 7, local open-source verification expansion
- Date: `2026-06-28`
- Scope: local Verilator/open-source only. Xcelium, CDC/RDC, Genus, Innovus,
  extracted timing, DDR macro timing, and matrix macro timing were not run.

## Files Reviewed

- `TOP/ci/run_tapeout_readiness.sh`
- `TOP/tb/spadmic_top_matrix_v1_i2c_tasks.svh`
- `TOP/tb/tb_spadmic_i2c_matrix_top_16b_unit.sv`
- `TOP/tb/tb_spadmic_position_modes_unit.sv`
- `TOP/tb/tb_spadmic_position_snapshot_cluster_unit.sv`
- `TOP/tb/tb_spadmic_matrix_cfg_cout_readback_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_both_full_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_skew_campaign.sv`
- `TOP/tb/tb_spadmic_top_reset_during_event_unit.sv`
- `TOP/tb/tb_spadmic_top_reset_during_matrix_cfg_unit.sv`
- `TOP/tb/tb_spadmic_top_mode_transition_unit.sv`
- `TOP/docs/17_VERIFICATION_PLAN_MATRIX_TOP.md`
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`

## Builder Summary

- Added a reusable testbench-only I2C helper include for matrix-top tests.
- Added real-top I2C16, BOTH full, skew-campaign, reset-during-event, and
  mode-transition regressions.
- Added focused position RAW/CLUSTER and snapshot-cluster tests.
- Added a named Cout readback test that proves WRITE_COLUMN_64 readback is
  returned by Dout/Cout, not mirrored WDATA. The broader matrix config unit test
  remains responsible for READ_COLUMN_64, global fill, busy reject, reset abort,
  and missing Cout timeout.
- Expanded the local readiness script to run the standalone matrix unit tests
  and the new Phase 7 matrix-top tests.

## Tests Run

| Test | Result |
| --- | --- |
| `tb_spadmic_top_matrix_v1_both_full_unit` | PASS, 9 pass / 0 fail |
| `tb_spadmic_top_matrix_v1_skew_campaign` | PASS, 60 pass / 0 fail |
| `tb_spadmic_top_reset_during_event_unit` | PASS, 6 pass / 0 fail |
| `tb_spadmic_top_reset_during_matrix_cfg_unit` | PASS, 5 pass / 0 fail |
| `tb_spadmic_top_mode_transition_unit` | PASS, 6 pass / 0 fail |
| `tb_spadmic_i2c_matrix_top_16b_unit` | PASS, 5 pass / 0 fail |
| `tb_spadmic_position_modes_unit` | PASS, 8 pass / 0 fail |
| `tb_spadmic_position_snapshot_cluster_unit` | PASS, 8 pass / 0 fail |
| `tb_spadmic_matrix_cfg_cout_readback_unit` | PASS, 4 pass / 0 fail |
| `bash TOP/ci/run_tapeout_readiness.sh` | PASS, 31 pass / 0 fail / 4 expected local skips |

## Findings

| Severity | Finding | Builder Response | Status |
| --- | --- | --- | --- |
| NOTE | The skew campaign is a directed RTL campaign through the full top START gates, not an extracted timing/skew signoff. | Kept STA/PnR skew closure deferred to CDC/STA/PnR plans. | DEFERRED |
| NOTE | The named Cout-readback regression is intentionally focused on WRITE_COLUMN_64 returned readback. | Broader Cout timeout and READ_COLUMN_64 coverage remains in `tb_spadmic_matrix_cfg_ctrl_unit`. | CLOSED |
| NOTE | Some top tests use hierarchical observations for internal readiness/masks because these are CSR-internal or integration-internal properties. | Kept them local verification only and did not add debug pads. | CLOSED |
| NOTE | `tb_spadmic_top_reset_during_matrix_cfg_unit` is controller-level reset-abort coverage through `spadmic_matrix_cfg_ctrl`, not a full-top I2C integration test. | Documented as controller-level reset-abort coverage; top I2C coverage is provided separately by the CSR/I2C tests. | CLOSED |
| NOTE | Root reference files remain untracked user-owned files and must stay outside the Phase 7 commit. | Commit staging excludes `ParameterDefs.sv`, `multi_ShiftRegisterChain_cfg_v1.sv`, and `pixel_readout.pdf`. | CLOSED |

## Remaining Risks

- Xcelium has not been run locally.
- CDC/RDC has not been signed off by a CDC tool.
- Genus/STA and Innovus have not been run locally.
- Final DDR and matrix macro timing remain external handoff items.

## Verifier Status

Verifier rechecked the Phase 7 working-tree diff after the full readiness gate
passed. No BLOCKER, HIGH, MEDIUM, or LOW findings remain for local
open-source scope. Phase 7 is approved for commit with the explicit limitation
that it is not Xcelium, CDC/RDC, STA, Genus, Innovus, DDR macro, or matrix
macro signoff.
